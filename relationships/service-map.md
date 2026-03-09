---
type: relationship
status: active
last_updated: 2026-03-06
---

# Service Map

## Services

- [[agent-orchestrator]] — AI agent fleet orchestrator (TypeScript, CLI + web dashboard)
- [[three-sword-style-ai]] — Automated LoRA training pipeline (Python, GCP)

## Infrastructure

- [[homeserver]] — Raspberry Pi running Pi-hole (DNS) + WireGuard (VPN)

## Relationships

```
agent-orchestrator
  `-- Used by three-sword-style-ai for dev agent management

three-sword-style-ai
  `-- Uses agent-orchestrator (agent-orchestrator.yaml)
  `-- Calls GCP (Vertex AI, GCE, GCS, Artifact Registry, Cloud Build)
  `-- Calls Gemini API (Flash, Flash Image, Pro Image)
  `-- Tests on ComfyUI / Replicate / RunComfy
  `-- GCP traffic may route through homeserver VPN

homeserver
  `-- Provides DNS (Pi-hole) for entire LAN
  `-- Provides VPN (WireGuard) for remote access
  `-- VPN clients get ad blocking via Pi-hole DNS routing
```
