# Musk WebAI self-host

This folder contains a minimal Docker Compose deployment scaffold and project documentation for the Musk WebAI self-hosted Open WebUI instance.

## Documentation

- [Product notes](docs/PRODUCT.md): positioning, homepage starters, branding requirements.
- [Development and operations notes](docs/DEVELOPMENT.md): production deployment, branding patch, prompt maintenance, verification commands.
- [Model optimization technical spec](docs/MODEL_OPTIMIZATION_TECH_SPEC.md): P0 generation integrity guard and P1 context intelligence architecture.
- [Model optimization execution plan](docs/MODEL_OPTIMIZATION_EXECUTION.md): numbered source-level development steps and progress.

## Prerequisites

- Install Docker Desktop or Docker Engine with Docker Compose v2.
- Optional: install and run Ollama on the host if you want local models.

## Start

```sh
cp .env.example .env
```

Edit `.env`, especially `WEBUI_SECRET_KEY` and any provider settings, then run:

```sh
docker compose up -d
```

Open:

```text
http://localhost:3000
```

The first account created becomes the admin account when `WEBUI_AUTH=true`.

## Connect models

- Local Ollama on the same machine: keep `OLLAMA_BASE_URL=http://host.docker.internal:11434`.
- OpenAI or compatible API: set `OPENAI_API_BASE_URL` and `OPENAI_API_KEY`.
- Additional providers can also be configured later in the Open WebUI admin settings.

## Image generation

Image-only models such as `gpt-image-2` must be configured through Open WebUI's Images backend, not selected as the chat model.

The Compose template enables:

```text
ENABLE_IMAGE_GENERATION=true
IMAGE_GENERATION_ENGINE=openai
IMAGE_GENERATION_MODEL=gpt-image-2
ENABLE_IMAGE_PROMPT_GENERATION=false
IMAGE_EDIT_ENGINE=openai
IMAGE_EDIT_MODEL=gpt-image-2
IMAGES_OPENAI_API_BASE_URL=${OPENAI_API_BASE_URL}
IMAGES_OPENAI_API_KEY=${OPENAI_API_KEY}
```

In the chat model selector, keep a text model selected. Then generate images through the image-generation flow/tool so Open WebUI sends the request to `/v1/images/generations` or `/v1/images/edits`.

## Update

```sh
docker compose pull
docker compose up -d
```

For production, pin `WEBUI_DOCKER_TAG` to a specific Open WebUI release instead of `main`.
