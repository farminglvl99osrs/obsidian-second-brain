---
type: service
status: active
repo: https://github.com/staffdill/three-sword-style-ai
owner: staffdill
tags: [ai, lora, training, gcp, python, image-generation]
last_updated: 2026-03-07
---

# three-sword-style-ai

## Overview

Automated LoRA training pipeline for AI image and video generators (Stable Diffusion XL, Flux, Pony, Wan 2.1). Takes real photos or reference images, runs them through an AI-powered pipeline (categorization, gap-filling, captioning, human review), and submits cloud training jobs on GCP to produce `.safetensors` LoRA model files.

## Tech Stack

- Language / framework: Python 3.10+
- AI APIs: Google Gemini Flash 2.5 (vision/analysis), Gemini Flash Image 2.5 / "Nano Banana" (generation), Gemini Pro Image 3
- Cloud platform: GCP — Vertex AI, GCE spot VMs (L4/A100), Cloud Storage, Artifact Registry, Cloud Build
- Training frameworks: sd-scripts (kohya) for SDXL/Flux, musubi-tuner for Wan 2.1
- Image processing: Pillow, pillow-heif
- Gallery UI: Jinja2 HTML templates (local browser)
- Config: `config.txt` (gitignored, key=value), `default_config.yaml`
- Testing: pytest, ComfyUI API, Replicate API, RunComfy API
- Containerization: Docker (two-layer: base image in Artifact Registry + thin training layer)
- Database: None (JSON state machine: `pipeline_state.json`, `pipeline_checkpoint.json`)

## Key Endpoints / Interfaces

**Entry point:** `scripts/run_pipeline.py`

**Real mode:** `prepare_dataset -> gap-fill -> auto_caption -> preprocess -> gallery_review -> finalize_dataset`

**Synthetic mode:** `base_generator -> dataset_generator_nano_banana -> auto_caption -> preprocess -> gallery_review -> finalize_dataset`

**CLI flags:** `--dry-run`, `--force`, `--force-step <name>`, `--fill-gaps`, `--train-backend sdxl|flux|wan|pony`, `--caption-style`, `--no-approve`, `--continue-training`, `--force-mode real|synthetic`

**Training:** `scripts/training/vertex_train.py` (Vertex AI), `scripts/training/wan_train.py` (GCE spot)

**Training sample flags:** `--trigger-word`, `--sample-prompts`, `--sample-interval`, `--no-samples`, `--sample-at-first`

**Testing:** ComfyUI API (local/RunComfy), Replicate API

## Relationships

- Uses [[agent-orchestrator]] for managing development agents (`agent-orchestrator.yaml` in repo)
- Calls Gemini API (Flash, Flash Image, Pro Image) for all AI operations
- Uploads training data to Google Cloud Storage
- Submits training jobs to GCP Vertex AI and GCE spot VMs
- Tests trained LoRAs via ComfyUI, Replicate, RunComfy
- Downloads base models from HuggingFace
- GCP training runs may route through [[homeserver]] WireGuard VPN

## Architecture Decisions

- **Two pipeline modes** — Real (5+ photos) vs Synthetic (0-4 photos, AI-generated)
- **Auto-mode detection** — based on image count in `references/`
- **State machine with auto-resume** — `pipeline_state.json` per version dir
- **BLAKE2b versioning** — same photos = same version hash
- **Two-layer Docker** — heavy base image cached in Artifact Registry; thin training layer ~1-2 min build
- **GCP-first** — Vertex AI preferred over GCE spot
- **Gemini as single AI dependency** — all vision/generation through Gemini APIs
- **SaaS backend archived** — FastAPI + PostgreSQL + Next.js moved to `archive/`

## Operational Notes

- **Config:** `config.txt` (gitignored) for API keys + GCP settings; see `config.txt.example`
- **Datasets:** `datasets/{name}/references/`, `datasets/{name}/v{N}/`
- **Models:** `models/lora/*.safetensors`, `models/wan/` (~40GB cached base models)
- **GCP setup:** `python scripts/gcp_setup_wizard.py`
- **GPU requirements:** SDXL → L4, Flux → A100, Wan 2.1 → L4
- **Local path:** `~/Documents/github/three-sword-style-ai`

### Training Sample Generation (2026-03-07)

All backends now generate validation samples during training using native framework support (kohya sd-scripts for SDXL/Flux/Pony, musubi-tuner for Wan 2.1). This replaces the deprecated `wan_validation_monitor.py`.

| Backend | Interval | Format |
|---------|----------|--------|
| SDXL | Every epoch | PNG |
| Flux | Every epoch | PNG |
| Pony | Every epoch | PNG |
| Wan 2.1 | Every 500 steps | MP4 + PNG |

- **Enabled by default** with 2 prompts per backend, fixed seeds (42, 123) for cross-epoch comparison
- **Incremental GCS sync** — background `gsutil rsync` uploads samples every 60s to `gs://{bucket}/lora-outputs/{name}/samples/`
- **CLI flags:** `--trigger-word`, `--sample-prompts`, `--sample-interval`, `--no-samples`, `--sample-at-first`
- Wan requires `--vae`, `--text_encoder1`, `--text_encoder2` (auto-passed by entrypoint scripts)
- Design doc: `docs/plans/2026-03-07-training-sample-generation-design.md`
