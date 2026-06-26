#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
#  PAPERSTACK — One-command AI company infrastructure
#  Installs: Paperclip + Hermes Agent + DeepSeek LLM
#  Usage:    curl -fsSL https://raw.githubusercontent.com/yeaminlabs/paperstack/main/install.sh | bash
# ─────────────────────────────────────────────────────────────

PAPERSTACK_VERSION="1.0.0"

# ── TTY detection ────────────────────────────────────────────
# When piped from curl, stdin is the pipe and stdout may not be a tty.
# Reopen stdin from /dev/tty so interactive prompts work.
if [[ ! -t 0 ]] && [[ -e /dev/tty ]]; then
    exec 3</dev/tty || true
else
    exec 3<&0
fi
TTY_FD=3

# ── Colors & Formatting ─────────────────────────────────────
# Enable colors if /dev/tty exists (even when stdout is piped through)
if command -v tput &>/dev/null && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]; then
    RST="\033[0m"
    BOLD="\033[1m"
    DIM="\033[2m"
    ITAL="\033[3m"
    ULINE="\033[4m"
    # Palette
    CYAN="\033[38;5;87m"
    BLUE="\033[38;5;33m"
    PURPLE="\033[38;5;141m"
    PINK="\033[38;5;218m"
    GREEN="\033[38;5;114m"
    YELLOW="\033[38;5;221m"
    RED="\033[38;5;203m"
    ORANGE="\033[38;5;209m"
    WHITE="\033[38;5;255m"
    GRAY="\033[38;5;245m"
    DARK="\033[38;5;238m"
    # Backgrounds
    BG_BLUE="\033[48;5;17m"
    BG_GREEN="\033[48;5;22m"
    BG_RED="\033[48;5;52m"
    BG_PURPLE="\033[48;5;53m"
else
    RST="" BOLD="" DIM="" ITAL="" ULINE=""
    CYAN="" BLUE="" PURPLE="" PINK="" GREEN="" YELLOW="" RED="" ORANGE="" WHITE="" GRAY="" DARK=""
    BG_BLUE="" BG_GREEN="" BG_RED="" BG_PURPLE=""
fi

# ── Symbols ──────────────────────────────────────────────────
S_CHECK="${GREEN}✓${RST}"
S_CROSS="${RED}✗${RST}"
S_ARROW="${CYAN}▸${RST}"
S_DOT="${GRAY}·${RST}"
S_BOLT="${YELLOW}⚡${RST}"
S_GEAR="${PURPLE}⚙${RST}"
S_KEY="${ORANGE}🔑${RST}"
S_ROCKET="${PINK}🚀${RST}"
S_SHIELD="${BLUE}🛡${RST}"
S_BOX="${CYAN}◆${RST}"
S_PIPE="${DARK}│${RST}"
S_CORNER="${DARK}└${RST}"
S_TEE="${DARK}├${RST}"

# ── Layout Helpers ───────────────────────────────────────────
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
[[ $TERM_WIDTH -gt 90 ]] && TERM_WIDTH=90

hr() {
    local char="${1:-─}"
    printf "${DARK}"
    printf '%*s' "$TERM_WIDTH" '' | tr ' ' "$char"
    printf "${RST}\n"
}

banner() {
    clear 2>/dev/null || true
    echo ""
    printf "${CYAN}${BOLD}"
    cat << 'LOGO'
    ██████╗  █████╗ ██████╗ ███████╗██████╗ ███████╗████████╗ █████╗  ██████╗██╗  ██╗
    ██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝
    ██████╔╝███████║██████╔╝█████╗  ██████╔╝███████╗   ██║   ███████║██║     █████╔╝
    ██╔═══╝ ██╔══██║██╔═══╝ ██╔══╝  ██╔══██╗╚════██║   ██║   ██╔══██║██║     ██╔═██╗
    ██║     ██║  ██║██║     ███████╗██║  ██║███████║   ██║   ██║  ██║╚██████╗██║  ██╗
    ╚═╝     ╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
LOGO
    printf "${RST}"
    echo ""
    printf "    ${DIM}${WHITE}The one-command AI company infrastructure${RST}"
    printf "  ${DARK}v${PAPERSTACK_VERSION}${RST}\n"
    printf "    ${DARK}Paperclip · Hermes Agent · DeepSeek LLM${RST}\n"
    echo ""
    hr
    echo ""
}

section() {
    echo ""
    printf "  ${BOLD}${PURPLE}▎${RST} ${BOLD}${WHITE}%s${RST}\n" "$1"
    printf "  ${DARK}%s${RST}\n" "$2"
    echo ""
}

step() {
    printf "  ${S_ARROW} ${WHITE}%s${RST}" "$1"
}

step_ok() {
    printf "\r  ${S_CHECK} ${WHITE}%s${RST}${DIM} %s${RST}\n" "$1" "${2:-}"
}

step_fail() {
    printf "\r  ${S_CROSS} ${RED}%s${RST} ${DIM}%s${RST}\n" "$1" "${2:-}"
}

step_warn() {
    printf "\r  ${S_BOLT} ${YELLOW}%s${RST} ${DIM}%s${RST}\n" "$1" "${2:-}"
}

info() {
    printf "  ${S_PIPE} ${GRAY}%b${RST}\n" "$1"
}

detail() {
    printf "  ${S_PIPE}   ${DIM}%s${RST}\n" "$1"
}

prompt_input() {
    local label="$1" var_name="$2" default="${3:-}" secret="${4:-false}"
    local value=""
    echo ""
    if [[ "$secret" == "true" ]]; then
        printf "  ${S_KEY} ${BOLD}${WHITE}%s${RST}\n" "$label"
        [[ -n "$default" ]] && printf "  ${S_PIPE} ${DIM}Press enter to keep existing key${RST}\n"
        printf "  ${S_PIPE} ${CYAN}▸ ${RST}"
        read -rs value <&${TTY_FD}
        echo ""
    else
        printf "  ${S_GEAR} ${BOLD}${WHITE}%s${RST}\n" "$label"
        [[ -n "$default" ]] && printf "  ${S_PIPE} ${DIM}Default: %s${RST}\n" "$default"
        printf "  ${S_PIPE} ${CYAN}▸ ${RST}"
        read -r value <&${TTY_FD}
    fi
    value="${value:-$default}"
    eval "$var_name='$value'"
}

prompt_select() {
    local label="$1" var_name="$2"
    shift 2
    local options=("$@")
    local selected=0
    local count=${#options[@]}

    echo ""
    printf "  ${S_GEAR} ${BOLD}${WHITE}%s${RST}\n" "$label"

    # If no tty available, default to first option
    if ! exec 2>/dev/null <&${TTY_FD}; then
        eval "$var_name='${options[0]}'"
        printf "  ${S_PIPE} ${DIM}Auto-selected: ${options[0]}${RST}\n"
        return
    fi

    while true; do
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                printf "\r  ${S_PIPE} ${CYAN}● ${BOLD}%s${RST}\n" "${options[$i]}"
            else
                printf "\r  ${S_PIPE} ${GRAY}○ %s${RST}\n" "${options[$i]}"
            fi
        done

        read -rsn1 key <&${TTY_FD}
        case "$key" in
            A) ((selected > 0)) && ((selected--)) ;;  # Up
            B) ((selected < count - 1)) && ((selected++)) ;;  # Down
            '') break ;;
        esac

        # Move cursor back up to redraw
        printf "\033[${count}A"
    done

    eval "$var_name='${options[$selected]}'"
}

spinner() {
    local pid=$1 msg="$2"
    local frames=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${PURPLE}${frames[$i]}${RST} ${WHITE}%s${RST}  " "$msg"
        i=$(( (i + 1) % ${#frames[@]} ))
        sleep 0.1
    done
    wait "$pid" 2>/dev/null
    return $?
}

progress_bar() {
    local current=$1 total=$2 label="${3:-}"
    local width=40
    local pct=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "\r  ${S_PIPE} ${GRAY}%s ${RST}" "$label"
    printf "${CYAN}"
    printf '%*s' "$filled" '' | tr ' ' '█'
    printf "${DARK}"
    printf '%*s' "$empty" '' | tr ' ' '░'
    printf "${RST} ${WHITE}${BOLD}%3d%%${RST}" "$pct"
}

summary_box() {
    local title="$1"
    shift
    local lines=("$@")
    local max_len=0

    for line in "${lines[@]}"; do
        local stripped
        stripped=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        [[ ${#stripped} -gt $max_len ]] && max_len=${#stripped}
    done
    ((max_len += 4))
    [[ $max_len -lt 50 ]] && max_len=50

    echo ""
    printf "  ${CYAN}╭─${BOLD} %s ${RST}${CYAN}" "$title"
    printf '%*s' "$((max_len - ${#title} - 2))" '' | tr ' ' '─'
    printf "╮${RST}\n"

    for line in "${lines[@]}"; do
        local stripped
        stripped=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        local pad=$((max_len - ${#stripped}))
        printf "  ${CYAN}│${RST} %b%*s ${CYAN}│${RST}\n" "$line" "$pad" ""
    done

    printf "  ${CYAN}╰"
    printf '%*s' "$((max_len + 2))" '' | tr ' ' '─'
    printf "╯${RST}\n"
    echo ""
}

# ── Dependency Checks ────────────────────────────────────────
check_command() {
    command -v "$1" &>/dev/null
}

detect_os() {
    local os=""
    case "$(uname -s)" in
        Linux*)  os="linux" ;;
        Darwin*) os="macos" ;;
        *)       os="unknown" ;;
    esac
    echo "$os"
}

detect_arch() {
    local arch=""
    case "$(uname -m)" in
        x86_64|amd64) arch="x64" ;;
        aarch64|arm64) arch="arm64" ;;
        *)             arch="unknown" ;;
    esac
    echo "$arch"
}

detect_pkg_manager() {
    if check_command apt-get; then echo "apt"
    elif check_command yum; then echo "yum"
    elif check_command dnf; then echo "dnf"
    elif check_command pacman; then echo "pacman"
    elif check_command brew; then echo "brew"
    elif check_command apk; then echo "apk"
    else echo "unknown"
    fi
}

# ── Install Functions ────────────────────────────────────────
install_node() {
    local os
    os=$(detect_os)
    step "Installing Node.js..."

    if check_command node; then
        local node_ver
        node_ver=$(node -v 2>/dev/null | sed 's/v//')
        local major
        major=$(echo "$node_ver" | cut -d. -f1)
        if [[ $major -ge 20 ]]; then
            step_ok "Node.js" "v${node_ver} (already installed)"
            return 0
        fi
    fi

    case "$os" in
        linux)
            if check_command apt-get; then
                (curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs) &>/dev/null &
            elif check_command yum || check_command dnf; then
                (curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash - && sudo yum install -y nodejs) &>/dev/null &
            elif check_command apk; then
                (sudo apk add --no-cache nodejs npm) &>/dev/null &
            fi
            ;;
        macos)
            if check_command brew; then
                (brew install node) &>/dev/null &
            else
                (curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash && export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh" && nvm install 22) &>/dev/null &
            fi
            ;;
    esac

    spinner $! "Installing Node.js (this may take a minute)..."

    if check_command node; then
        step_ok "Node.js" "v$(node -v | sed 's/v//')"
    else
        step_fail "Node.js" "installation failed"
        return 1
    fi
}

install_python() {
    step "Checking Python..."

    if check_command python3; then
        local py_ver
        py_ver=$(python3 --version 2>/dev/null | awk '{print $2}')
        local major minor
        major=$(echo "$py_ver" | cut -d. -f1)
        minor=$(echo "$py_ver" | cut -d. -f2)
        if [[ $major -ge 3 && $minor -ge 10 ]]; then
            step_ok "Python" "v${py_ver}"
            return 0
        fi
    fi

    local os
    os=$(detect_os)
    case "$os" in
        linux)
            if check_command apt-get; then
                (sudo apt-get update -qq && sudo apt-get install -y -qq python3 python3-pip python3-venv) &>/dev/null &
            elif check_command yum || check_command dnf; then
                (sudo dnf install -y python3 python3-pip) &>/dev/null &
            elif check_command apk; then
                (sudo apk add --no-cache python3 py3-pip) &>/dev/null &
            fi
            ;;
        macos)
            if check_command brew; then
                (brew install python@3.12) &>/dev/null &
            fi
            ;;
    esac

    spinner $! "Installing Python 3..."

    if check_command python3; then
        step_ok "Python" "v$(python3 --version | awk '{print $2}')"
    else
        step_fail "Python" "installation failed"
        return 1
    fi
}

install_pipx() {
    step "Checking pipx..."

    if check_command pipx; then
        step_ok "pipx" "$(pipx --version 2>/dev/null)"
        return 0
    fi

    local os
    os=$(detect_os)
    case "$os" in
        linux)
            (python3 -m pip install --user pipx 2>/dev/null || sudo apt-get install -y -qq pipx 2>/dev/null || sudo dnf install -y pipx 2>/dev/null) &>/dev/null &
            ;;
        macos)
            (brew install pipx) &>/dev/null &
            ;;
    esac

    spinner $! "Installing pipx..."

    # Ensure PATH
    pipx ensurepath &>/dev/null 2>&1 || true
    export PATH="$HOME/.local/bin:$PATH"

    if check_command pipx; then
        step_ok "pipx" "installed"
    else
        step_fail "pipx" "installation failed — install manually: python3 -m pip install --user pipx"
        return 1
    fi
}

install_paperclip() {
    step "Installing Paperclip..."

    (npm install -g paperclipai 2>/dev/null || npx paperclipai --version) &>/dev/null &
    spinner $! "Installing Paperclip (AI company platform)..."

    step_ok "Paperclip" "$(npx paperclipai --version 2>/dev/null || echo 'latest')"
}

install_hermes() {
    step "Installing Hermes Agent..."

    (pipx install hermes-agent 2>/dev/null || pipx upgrade hermes-agent 2>/dev/null) &>/dev/null &
    spinner $! "Installing Hermes Agent (Nous Research)..."

    export PATH="$HOME/.local/bin:$PATH"

    if check_command hermes || [[ -f "$HOME/.local/bin/hermes" ]]; then
        local hermes_bin
        hermes_bin=$(which hermes 2>/dev/null || echo "$HOME/.local/bin/hermes")
        step_ok "Hermes Agent" "$($hermes_bin --version 2>/dev/null || echo 'installed')"
    else
        step_fail "Hermes Agent" "installation failed"
        return 1
    fi
}

configure_hermes() {
    local provider="$1" api_key="$2" model="$3"
    local hermes_bin
    hermes_bin=$(which hermes 2>/dev/null || echo "$HOME/.local/bin/hermes")

    step "Configuring Hermes..."

    "$hermes_bin" config set provider "$provider" &>/dev/null
    "$hermes_bin" config set api_key "$api_key" &>/dev/null
    [[ -n "$model" ]] && "$hermes_bin" config set model "$model" &>/dev/null

    # Also write to .env for tools that read from there
    mkdir -p "$HOME/.hermes"
    local env_key_name
    env_key_name=$(echo "${provider}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    cat > "$HOME/.hermes/.env" <<EOF
${env_key_name}_API_KEY=${api_key}
EOF

    step_ok "Hermes configured" "provider=${provider} model=${model}"
}

configure_paperclip() {
    step "Configuring Paperclip..."

    (npx paperclipai onboard --yes) &>/dev/null &
    spinner $! "Running Paperclip onboard (database + config)..."

    if [[ -f "$HOME/.paperclip/instances/default/config.json" ]]; then
        step_ok "Paperclip configured" "$HOME/.paperclip"
    else
        step_warn "Paperclip config" "may need manual setup: npx paperclipai configure"
    fi
}

# ── Provider Configs ─────────────────────────────────────────
declare -A PROVIDER_MODELS
PROVIDER_MODELS=(
    ["deepseek"]="deepseek-v4-flash deepseek-r1 deepseek-chat deepseek-coder"
    ["anthropic"]="claude-sonnet-4-6 claude-opus-4-8 claude-haiku-4-5"
    ["openai"]="gpt-4.1 gpt-4.1-mini o4-mini"
    ["minimax"]="MiniMax-M2 MiniMax-M1"
    ["openrouter"]="auto"
    ["google"]="gemini-2.5-pro gemini-2.5-flash"
)

declare -A PROVIDER_KEY_URLS
PROVIDER_KEY_URLS=(
    ["deepseek"]="https://platform.deepseek.com/api-keys"
    ["anthropic"]="https://console.anthropic.com/settings/keys"
    ["openai"]="https://platform.openai.com/api-keys"
    ["minimax"]="https://platform.minimax.io/"
    ["openrouter"]="https://openrouter.ai/keys"
    ["google"]="https://aistudio.google.com/apikey"
)

# ── Main ─────────────────────────────────────────────────────
main() {
    banner

    local os arch pkg
    os=$(detect_os)
    arch=$(detect_arch)
    pkg=$(detect_pkg_manager)

    summary_box "System Detected" \
        "${GRAY}OS${RST}          ${WHITE}${os}${RST}" \
        "${GRAY}Arch${RST}        ${WHITE}${arch}${RST}" \
        "${GRAY}Package Mgr${RST} ${WHITE}${pkg}${RST}" \
        "${GRAY}Shell${RST}       ${WHITE}${SHELL##*/}${RST}" \
        "${GRAY}User${RST}        ${WHITE}$(whoami)${RST}"

    # ── LLM Provider Selection ───────────────────────────────
    section "LLM PROVIDER" "Choose the AI model provider for your agents"

    local providers=("deepseek" "anthropic" "openai" "minimax" "openrouter" "google")
    local provider=""

    if [[ -e /dev/tty ]]; then
        prompt_select "Select LLM Provider (↑/↓ then Enter)" provider "${providers[@]}"
    else
        provider="${PAPERSTACK_PROVIDER:-deepseek}"
        printf "  ${S_ARROW} ${WHITE}Provider: ${CYAN}%s${RST} ${DIM}(from env)${RST}\n" "$provider"
    fi

    # ── API Key ──────────────────────────────────────────────
    local api_key="${PAPERSTACK_API_KEY:-}"
    local key_url="${PROVIDER_KEY_URLS[$provider]:-}"

    if [[ -z "$api_key" ]]; then
        [[ -n "$key_url" ]] && info "Get your key at: ${ULINE}${CYAN}${key_url}${RST}"
        prompt_input "Enter your ${provider} API key" api_key "" true
    fi

    if [[ -z "$api_key" ]]; then
        step_fail "API key required" "Cannot continue without an API key"
        echo ""
        printf "  ${GRAY}Set it via environment variable:${RST}\n"
        printf "  ${DIM}export PAPERSTACK_API_KEY=\"your-key-here\"${RST}\n"
        echo ""
        exit 1
    fi

    # ── Model Selection ──────────────────────────────────────
    local models_str="${PROVIDER_MODELS[$provider]:-auto}"
    local model="${PAPERSTACK_MODEL:-}"

    if [[ -z "$model" ]]; then
        IFS=' ' read -ra model_list <<< "$models_str"
        if [[ -e /dev/tty ]]; then
            prompt_select "Select model" model "${model_list[@]}"
        else
            model="${model_list[0]}"
            printf "  ${S_ARROW} ${WHITE}Model: ${CYAN}%s${RST} ${DIM}(default)${RST}\n" "$model"
        fi
    fi

    # ── Confirm ──────────────────────────────────────────────
    local masked_key="${api_key:0:8}...${api_key: -4}"

    summary_box "Installation Plan" \
        "${S_BOLT} ${WHITE}Provider${RST}    ${CYAN}${provider}${RST}" \
        "${S_GEAR} ${WHITE}Model${RST}       ${CYAN}${model}${RST}" \
        "${S_KEY} ${WHITE}API Key${RST}     ${GRAY}${masked_key}${RST}" \
        "" \
        "${WHITE}Components to install:${RST}" \
        "  ${S_BOX} Node.js ${DIM}(runtime)${RST}" \
        "  ${S_BOX} Python 3 ${DIM}(runtime)${RST}" \
        "  ${S_BOX} pipx ${DIM}(package manager)${RST}" \
        "  ${S_BOX} Paperclip ${DIM}(AI company platform)${RST}" \
        "  ${S_BOX} Hermes Agent ${DIM}(Nous Research agent)${RST}"

    if [[ -e /dev/tty ]]; then
        printf "  ${BOLD}${WHITE}Proceed with installation?${RST} ${DIM}[Y/n]${RST} "
        read -r confirm <&${TTY_FD}
        if [[ "$confirm" =~ ^[Nn] ]]; then
            echo ""
            printf "  ${GRAY}Installation cancelled.${RST}\n\n"
            exit 0
        fi
    fi

    # ── Install Phase ────────────────────────────────────────
    section "INSTALLING DEPENDENCIES" "Setting up runtime environment"

    install_node
    install_python
    install_pipx

    section "INSTALLING CORE SERVICES" "Deploying AI infrastructure"

    install_paperclip
    install_hermes

    section "CONFIGURING" "Wiring up provider credentials"

    configure_hermes "$provider" "$api_key" "$model"
    configure_paperclip

    # ── Find correct hermes path for Paperclip ───────────────
    local hermes_path
    hermes_path=$(which hermes 2>/dev/null || echo "$HOME/.local/bin/hermes")

    # Verify it's the Python hermes, not an npm one
    if file "$hermes_path" 2>/dev/null | grep -q "node\|javascript"; then
        hermes_path="$HOME/.local/bin/hermes"
    fi

    # ── Create launcher script ───────────────────────────────
    section "CREATING LAUNCHER" "Building paperstack command"

    local launcher_path="$HOME/.local/bin/paperstack"
    mkdir -p "$HOME/.local/bin"

    cat > "$launcher_path" << 'LAUNCHER_EOF'
#!/usr/bin/env bash
set -euo pipefail

CYAN="\033[38;5;87m"
WHITE="\033[38;5;255m"
GREEN="\033[38;5;114m"
GRAY="\033[38;5;245m"
PURPLE="\033[38;5;141m"
BOLD="\033[1m"
DIM="\033[2m"
RST="\033[0m"

show_help() {
    echo ""
    printf "${CYAN}${BOLD}  PAPERSTACK${RST} ${DIM}— AI Company Infrastructure${RST}\n"
    echo ""
    printf "  ${WHITE}${BOLD}Commands:${RST}\n"
    printf "    ${GREEN}start${RST}       Start Paperclip server\n"
    printf "    ${GREEN}stop${RST}        Stop all services\n"
    printf "    ${GREEN}status${RST}      Check service status\n"
    printf "    ${GREEN}config${RST}      Show current configuration\n"
    printf "    ${GREEN}doctor${RST}      Run diagnostics\n"
    printf "    ${GREEN}logs${RST}        Tail server logs\n"
    printf "    ${GREEN}hermes${RST}      Run hermes agent directly\n"
    printf "    ${GREEN}ui${RST}          Open Paperclip UI in browser\n"
    printf "    ${GREEN}help${RST}        Show this help\n"
    echo ""
}

case "${1:-help}" in
    start)
        printf "\n  ${PURPLE}▸${RST} ${WHITE}Starting Paperclip server...${RST}\n\n"
        npx paperclipai run
        ;;
    stop)
        printf "\n  ${PURPLE}▸${RST} ${WHITE}Stopping services...${RST}\n"
        pkill -f "paperclipai" 2>/dev/null && printf "  ${GREEN}✓${RST} Paperclip stopped\n" || printf "  ${GRAY}· Not running${RST}\n"
        echo ""
        ;;
    status)
        echo ""
        printf "  ${BOLD}${WHITE}Service Status${RST}\n\n"
        if curl -sf http://127.0.0.1:3100/api/health &>/dev/null; then
            printf "  ${GREEN}●${RST} ${WHITE}Paperclip${RST}     ${GREEN}running${RST} ${DIM}(port 3100)${RST}\n"
        else
            printf "  ${GRAY}○${RST} ${WHITE}Paperclip${RST}     ${GRAY}stopped${RST}\n"
        fi
        local hermes_bin
        hermes_bin=$(which hermes 2>/dev/null || echo "$HOME/.local/bin/hermes")
        if [[ -x "$hermes_bin" ]]; then
            printf "  ${GREEN}●${RST} ${WHITE}Hermes Agent${RST}  ${GREEN}installed${RST} ${DIM}($($hermes_bin --version 2>/dev/null || echo '?'))${RST}\n"
        else
            printf "  ${GRAY}○${RST} ${WHITE}Hermes Agent${RST}  ${GRAY}not found${RST}\n"
        fi
        echo ""
        ;;
    config)
        echo ""
        printf "  ${BOLD}${WHITE}Configuration${RST}\n\n"
        local hermes_bin
        hermes_bin=$(which hermes 2>/dev/null || echo "$HOME/.local/bin/hermes")
        "$hermes_bin" config show 2>/dev/null || printf "  ${GRAY}Hermes not configured${RST}\n"
        echo ""
        ;;
    doctor)
        npx paperclipai doctor
        ;;
    logs)
        local log_dir="$HOME/.paperclip/instances/default/logs"
        if [[ -d "$log_dir" ]]; then
            tail -f "$log_dir"/*.log 2>/dev/null || printf "  ${GRAY}No log files found${RST}\n"
        else
            printf "  ${GRAY}Log directory not found${RST}\n"
        fi
        ;;
    hermes)
        shift
        local hermes_bin
        hermes_bin=$(which hermes 2>/dev/null || echo "$HOME/.local/bin/hermes")
        "$hermes_bin" "$@"
        ;;
    ui|open)
        local url="http://127.0.0.1:3100"
        if command -v xdg-open &>/dev/null; then xdg-open "$url"
        elif command -v open &>/dev/null; then open "$url"
        else printf "  Open: ${CYAN}%s${RST}\n" "$url"
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        printf "\n  ${GRAY}Unknown command: %s${RST}\n" "$1"
        show_help
        exit 1
        ;;
esac
LAUNCHER_EOF

    chmod +x "$launcher_path"
    step_ok "Created paperstack CLI" "$launcher_path"

    # ── Done ─────────────────────────────────────────────────
    echo ""
    hr "═"
    echo ""

    printf "${CYAN}${BOLD}"
    cat << 'DONE_ART'
     ██████╗  ██████╗ ███╗   ██╗███████╗██╗
     ██╔══██╗██╔═══██╗████╗  ██║██╔════╝██║
     ██║  ██║██║   ██║██╔██╗ ██║█████╗  ██║
     ██║  ██║██║   ██║██║╚██╗██║██╔══╝  ╚═╝
     ██████╔╝╚██████╔╝██║ ╚████║███████╗██╗
     ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝
DONE_ART
    printf "${RST}\n"

    summary_box "Quick Start" \
        "${GREEN}paperstack start${RST}    ${DIM}Start the server${RST}" \
        "${GREEN}paperstack status${RST}   ${DIM}Check everything${RST}" \
        "${GREEN}paperstack ui${RST}       ${DIM}Open web dashboard${RST}" \
        "${GREEN}paperstack hermes${RST}   ${DIM}Run Hermes directly${RST}" \
        "" \
        "${GRAY}Web UI:${RST}  ${ULINE}${CYAN}http://127.0.0.1:3100${RST}" \
        "${GRAY}Config:${RST}  ${DIM}~/.paperclip/instances/default/config.json${RST}" \
        "${GRAY}Hermes:${RST}  ${DIM}~/.hermes/config.yaml${RST}"

    printf "  ${DIM}Add to PATH if needed:${RST}\n"
    printf "  ${DARK}export PATH=\"\$HOME/.local/bin:\$PATH\"${RST}\n"
    echo ""

    printf "  ${S_ROCKET} ${BOLD}${WHITE}Your AI company infrastructure is ready.${RST}\n"
    echo ""
}

# ── Entry Point ──────────────────────────────────────────────
main "$@"
