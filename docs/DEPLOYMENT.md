# Open WebUI Deployment Guide

Deploy Open WebUI as a self-hosted ChatGPT-like interface for [MaverickMCP](https://github.com/arunbcodes/maverick-mcp).

## Overview

Open WebUI provides a web-based chat interface that connects to [MaverickMCP's](https://github.com/arunbcodes/maverick-mcp) 80+ stock analysis tools via the Model Context Protocol (MCP).

```
┌─────────────────────────────────────────────────────────────────┐
│                    Browser (localhost:3001)                      │
│                         Open WebUI                               │
│              "Analyze AAPL stock for me"                         │
└──────────────────────────┬──────────────────────────────────────┘
                           │ MCP (HTTP Streamable)
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                  MaverickMCP (localhost:8003)                    │
│  80+ Tools: Screening, Technical, Portfolio, Research, Risk     │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start (5 minutes)

### Prerequisites

- Docker and Docker Compose installed
- [MaverickMCP](https://github.com/arunbcodes/maverick-mcp) server running (port 8003)
- LLM backend (Ollama or API key)

### Step 1: Start MaverickMCP

```bash
# Clone and start MaverickMCP (https://github.com/arunbcodes/maverick-mcp)
cd ../maverick-mcp
make dev-http
# Or: python -m maverick_server --transport streamable-http --port 8003
```

### Step 2: Start Open WebUI

```bash
cd maverick-openwebui

# Run setup
./scripts/setup.sh standalone
```

### Step 3: Configure MCP Connection

1. Open http://localhost:3001
2. Create an admin account
3. Go to **Admin Settings** → **External Tools**
4. Click **+ Add Server**
5. Configure:
   - **Type**: MCP (Streamable HTTP)
   - **URL**: `http://host.docker.internal:8003/mcp/` (MaverickMCP running natively)
   - **Name**: MaverickMCP

> **Note**: Use `http://mcp:8003/mcp/` if using Full Stack mode (MaverickMCP in Docker).

### Step 4: Start Chatting!

1. Create a new chat
2. Select a model (see LLM Configuration below)
3. Enable **Function Calling** in Advanced Params
4. Try: *"What are the best momentum stocks right now?"*

## LLM Configuration

Open WebUI needs an LLM backend to power conversations. Choose one:

### Option 1: Ollama (Local, Free)

Best for: Privacy, offline use, no API costs

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull a model (choose based on your hardware)
ollama pull llama3.2:3b      # ~2GB, fast, good for most
ollama pull llama3.2:70b     # ~40GB, best quality, needs GPU
ollama pull mixtral:8x7b     # ~26GB, excellent for analysis

# Start Ollama (runs on port 11434)
ollama serve
```

Configure in Open WebUI:
- Settings → Connections → Ollama API URL: `http://localhost:11434`

### Option 2: OpenRouter (Recommended)

Best for: Access to all major models, pay-per-use

1. Get API key at [openrouter.ai](https://openrouter.ai)
2. Configure in Open WebUI:
   - Settings → Connections → OpenRouter API Key: `your-key`
3. Recommended models:
   - `anthropic/claude-3-5-sonnet` - Best for complex analysis
   - `openai/gpt-4o` - Fast and capable
   - `google/gemini-pro-1.5` - Good value

### Option 3: OpenAI Direct

Best for: Existing OpenAI users

1. Get API key at [platform.openai.com](https://platform.openai.com)
2. Configure in Open WebUI:
   - Settings → Connections → OpenAI API Key: `your-key`

## Docker Compose Deployment

### Standalone (Open WebUI Only)

Use `docker-compose.yml` when MaverickMCP runs separately:

```bash
# Set secret key
export WEBUI_SECRET_KEY=$(openssl rand -base64 32)

# Start Open WebUI
docker compose up -d
```

### Full Stack Deployment

Use `docker-compose.full.yml` to run everything together:

```bash
# Clone MaverickMCP if not already done
git clone https://github.com/arunbcodes/maverick-mcp.git ../maverick-mcp

cd maverick-openwebui

# Configure environment
cp .env.example .env
# Edit .env and add TIINGO_API_KEY, WEBUI_SECRET_KEY

# Start full stack (builds MaverickMCP from ../maverick-mcp)
docker compose -f docker-compose.full.yml up -d

# Pull a model for Ollama
docker exec maverick-ollama ollama pull llama3.2:3b
```

> **Note**: Set `MCP_BUILD_CONTEXT` in `.env` if your maverick-mcp is in a different location.

This deploys:
- MaverickMCP Server (port 8003)
- Open WebUI (port 3001)
- Ollama LLM (port 11434)
- PostgreSQL database
- Redis cache

## Custom System Prompts

Create specialized assistants for different use cases. See the `prompts/` directory for:

### Stock Analyst

Specialized for technical analysis and screening:
- Uses screening tools to find momentum stocks
- Provides technical analysis with indicators
- Explains market signals and trends

### Portfolio Advisor

Focused on portfolio tracking and risk:
- Tracks positions with cost basis
- Monitors unrealized P&L
- Analyzes portfolio diversification
- Provides risk assessments

Import these in Open WebUI → Settings → Personalization.

## Troubleshooting

### Open WebUI can't connect to MCP

1. Verify MaverickMCP is running:
   ```bash
   curl http://localhost:8003/health
   ```

2. Check transport type (must be HTTP Streamable):
   ```bash
   python -m maverick_server --transport streamable-http
   ```

3. Verify network connectivity (if using Docker):
   ```bash
   docker network inspect maverick-openwebui_default
   ```

4. For Docker containers, use `host.docker.internal` instead of `localhost`

### Tools not appearing

1. Ensure **Function Calling** is set to **Native** in model settings
2. Use a model that supports function calling (GPT-4, Claude 3, Llama 3.2)
3. Check MCP server logs for errors

### Slow responses

1. Tool execution takes time (especially research tools)
2. Consider using faster models for simple queries
3. Check MaverickMCP audit logs for performance data

### Authentication issues after restart

Open WebUI requires `WEBUI_SECRET_KEY` to be consistent:
```bash
# Save your key permanently in .env
echo "WEBUI_SECRET_KEY=$(openssl rand -base64 32)" >> .env
```

## Security Best Practices

### Production Checklist

- [ ] Set strong `WEBUI_SECRET_KEY`
- [ ] Disable signup: `ENABLE_SIGNUP=false`
- [ ] Use HTTPS with reverse proxy
- [ ] Restrict network access
- [ ] Enable audit logging
- [ ] Set rate limits
- [ ] Regular backups of `webui-data` volume

### HTTPS with Traefik

Add to your docker-compose for SSL termination:

```yaml
services:
  traefik:
    image: traefik:v2.10
    command:
      - "--providers.docker=true"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.le.acme.tlschallenge=true"
      - "--certificatesresolvers.le.acme.email=admin@yourdomain.com"
      - "--certificatesresolvers.le.acme.storage=/letsencrypt/acme.json"
    ports:
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - letsencrypt:/letsencrypt

  open-webui:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.webui.rule=Host(`chat.yourdomain.com`)"
      - "traefik.http.routers.webui.entrypoints=websecure"
      - "traefik.http.routers.webui.tls.certresolver=le"
```

## Resources

- [Open WebUI Documentation](https://docs.openwebui.com/)
- [Open WebUI MCP Guide](https://docs.openwebui.com/features/mcp/)
- [Ollama Model Library](https://ollama.com/library)
- [MaverickMCP](https://github.com/arunbcodes/maverick-mcp) - Stock analysis server (clone to `../maverick-mcp`)
