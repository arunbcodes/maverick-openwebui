# Maverick Open WebUI

Deploy [Open WebUI](https://openwebui.com) as a self-hosted ChatGPT-like interface for [MaverickMCP](https://github.com/wshobson/maverick-mcp) stock analysis tools.

## Architecture

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

## Quick Start

### Prerequisites

- Docker and Docker Compose
- [MaverickMCP](https://github.com/wshobson/maverick-mcp) server (for standalone mode)
- Tiingo API key (free at [tiingo.com](https://tiingo.com))

### Option 1: Standalone (Open WebUI only)

Use this if you already have MaverickMCP running.

```bash
# Clone this repo
git clone https://github.com/abalak/maverick-openwebui.git
cd maverick-openwebui

# Setup and start
./scripts/setup.sh standalone
```

Then configure MCP connection in Open WebUI:
1. Open http://localhost:3001
2. Create admin account
3. Go to **Admin Settings** → **External Tools**
4. Add MCP server: `http://host.docker.internal:8003/mcp/`

### Option 2: Full Stack (Everything)

Deploys MaverickMCP + Open WebUI + Ollama + PostgreSQL + Redis.

```bash
# Clone this repo
git clone https://github.com/abalak/maverick-openwebui.git
cd maverick-openwebui

# Configure
cp .env.example .env
# Edit .env and add TIINGO_API_KEY

# Start full stack
./scripts/setup.sh full
```

## Configuration

Copy `.env.example` to `.env` and configure:

```bash
# Required
WEBUI_SECRET_KEY=<generated-automatically>
TIINGO_API_KEY=your-tiingo-key

# Optional - LLM providers
OPENROUTER_API_KEY=your-key  # Access to 400+ models
OPENAI_API_KEY=your-key      # Direct OpenAI access

# Optional - Enhanced features
EXA_API_KEY=your-key         # Web search for research
```

## LLM Configuration

Open WebUI needs an LLM backend. Choose one:

### Ollama (Local, Free)

```bash
# Pull a model
./scripts/setup.sh pull-model llama3.2:3b

# Or pull a larger model for better analysis
./scripts/setup.sh pull-model mixtral:8x7b
```

### OpenRouter (Recommended)

Best for access to all major models with pay-per-use pricing.

1. Get API key at [openrouter.ai](https://openrouter.ai)
2. In Open WebUI: Settings → Connections → Add OpenRouter
3. Recommended models:
   - `anthropic/claude-3-5-sonnet` - Best for complex analysis
   - `openai/gpt-4o` - Fast and capable
   - `google/gemini-pro-1.5` - Good value

### OpenAI Direct

1. Get API key at [platform.openai.com](https://platform.openai.com)
2. In Open WebUI: Settings → Connections → Add OpenAI

## Commands

```bash
./scripts/setup.sh standalone    # Start Open WebUI only
./scripts/setup.sh full          # Start full stack
./scripts/setup.sh stop          # Stop all services
./scripts/setup.sh status        # Show service status
./scripts/setup.sh pull-model    # Pull Ollama model
```

## Custom Prompts

Pre-configured prompts for specialized assistants:

- **[Stock Analyst](prompts/stock-analyst.md)** - Technical analysis and screening
- **[Portfolio Advisor](prompts/portfolio-advisor.md)** - Portfolio tracking and risk management

Import these in Open WebUI → Settings → Personalization.

## MCP Connection Setup

After starting Open WebUI:

1. Go to **Admin Settings** → **External Tools**
2. Click **+ Add Server**
3. Configure:
   - **Type**: MCP (Streamable HTTP)
   - **URL**: `http://host.docker.internal:8003/mcp/` (Docker) or `http://localhost:8003/mcp/` (native)
   - **Name**: MaverickMCP
4. Enable **Function Calling** → **Native** in model settings

## Testing

Try these prompts to verify the connection:

```
What are the best momentum stocks right now?

Show me technical analysis for AAPL

Add 100 shares of NVDA at $450 to my portfolio

What's the correlation between my portfolio holdings?
```

## Troubleshooting

### Open WebUI can't connect to MCP

```bash
# Verify MaverickMCP is running
curl http://localhost:8003/health

# Check container networking
docker network inspect maverick-openwebui_default
```

### Tools not appearing

1. Ensure **Function Calling** is set to **Native** in model settings
2. Use a model that supports function calling (GPT-4, Claude 3, Llama 3.2)
3. Check MCP server logs: `docker logs maverick-mcp`

### Slow responses

1. Research tools can take 2-10 minutes for deep analysis
2. Use faster models for simple queries
3. Check if Ollama model is loaded: `docker exec maverick-ollama ollama list`

## Production Deployment

For production use:

```bash
# In .env
ENABLE_SIGNUP=false
WEBUI_AUTH=true
```

Consider adding:
- HTTPS with reverse proxy (Traefik, nginx)
- Persistent volume backups
- Resource limits in Docker Compose
- Network isolation

## Related Projects

- [MaverickMCP](https://github.com/wshobson/maverick-mcp) - Stock analysis MCP server
- [Open WebUI](https://github.com/open-webui/open-webui) - Self-hosted ChatGPT interface
- [Ollama](https://ollama.com) - Local LLM runtime

## License

MIT
