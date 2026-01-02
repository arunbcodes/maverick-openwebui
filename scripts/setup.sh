#!/bin/bash
# Setup script for Maverick Open WebUI
# Usage: ./scripts/setup.sh [standalone|full]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available. Please install Docker Compose."
        exit 1
    fi

    log_info "Prerequisites check passed."
}

# Setup environment file
setup_env() {
    if [ ! -f .env ]; then
        log_info "Creating .env file from template..."
        cp .env.example .env

        # Generate secret key
        SECRET_KEY=$(openssl rand -base64 32)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/^WEBUI_SECRET_KEY=$/WEBUI_SECRET_KEY=$SECRET_KEY/" .env
        else
            sed -i "s/^WEBUI_SECRET_KEY=$/WEBUI_SECRET_KEY=$SECRET_KEY/" .env
        fi

        log_warn "Please edit .env and add your API keys (TIINGO_API_KEY is required)"
        log_info "Get a free Tiingo API key at: https://tiingo.com"
    else
        log_info ".env file already exists"
    fi
}

# Pull Ollama model
pull_ollama_model() {
    local model="${1:-llama3.2:3b}"
    log_info "Pulling Ollama model: $model"

    if docker ps | grep -q maverick-ollama; then
        docker exec maverick-ollama ollama pull "$model"
    else
        log_warn "Ollama container not running. Start services first, then run:"
        log_warn "  docker exec maverick-ollama ollama pull $model"
    fi
}

# Start standalone (Open WebUI only, connects to external MaverickMCP)
start_standalone() {
    log_info "Starting Open WebUI (standalone mode)..."
    log_info "Make sure MaverickMCP is running on localhost:8003"

    docker compose up -d

    log_info "Open WebUI is starting..."
    log_info "Access at: http://localhost:${WEBUI_PORT:-3001}"
}

# Start full stack (MaverickMCP + Open WebUI + Ollama + DB)
start_full() {
    log_info "Starting full stack..."

    docker compose -f docker-compose.full.yml up -d

    log_info "Waiting for services to be healthy..."
    sleep 10

    # Pull default model
    pull_ollama_model "llama3.2:3b"

    log_info "Full stack is starting..."
    log_info "Services:"
    log_info "  - Open WebUI:   http://localhost:${WEBUI_PORT:-3001}"
    log_info "  - MaverickMCP:  http://localhost:${MCP_PORT:-8003}"
    log_info "  - Ollama:       http://localhost:${OLLAMA_PORT:-11434}"
}

# Stop services
stop_services() {
    log_info "Stopping services..."
    docker compose down 2>/dev/null || true
    docker compose -f docker-compose.full.yml down 2>/dev/null || true
    log_info "Services stopped."
}

# Show status
show_status() {
    log_info "Service status:"
    docker ps --filter "name=maverick" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Print usage
usage() {
    echo "Maverick Open WebUI Setup"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  standalone    Start Open WebUI only (requires MaverickMCP running externally)"
    echo "  full          Start full stack (MaverickMCP + Open WebUI + Ollama + DB)"
    echo "  stop          Stop all services"
    echo "  status        Show service status"
    echo "  pull-model    Pull an Ollama model (default: llama3.2:3b)"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 standalone          # Start Open WebUI, connect to local MaverickMCP"
    echo "  $0 full                # Start everything"
    echo "  $0 pull-model mixtral  # Pull mixtral model"
}

# Main
main() {
    check_prerequisites
    setup_env

    case "${1:-help}" in
        standalone)
            start_standalone
            ;;
        full)
            start_full
            ;;
        stop)
            stop_services
            ;;
        status)
            show_status
            ;;
        pull-model)
            pull_ollama_model "${2:-llama3.2:3b}"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            log_error "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

main "$@"
