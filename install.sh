#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
#  PAPERSTACK — One-command AI company infrastructure
#  Installs: Paperclip + Hermes Agent + LLM Provider
#  Usage:    curl -fsSL https://raw.githubusercontent.com/yeaminlabs/paperstack/main/install.sh | bash
# ─────────────────────────────────────────────────────────────

PAPERSTACK_VERSION="1.0.0"

# ── Colors ───────────────────────────────────────────────────
RST="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
ULINE="\033[4m"
CYAN="\033[38;5;87m"
PURPLE="\033[38;5;141m"
GREEN="\033[38;5;114m"
YELLOW="\033[38;5;221m"
RED="\033[38;5;203m"
ORANGE="\033[38;5;209m"
WHITE="\033[38;5;255m"
GRAY="\033[38;5;245m"
DARK="\033[38;5;238m"

# ── Helpers ──────────────────────────────────────────────────
ok()   { printf "  ${GREEN}✓${RST} ${WHITE}%s${RST} ${DIM}%s${RST}\n" "$1" "${2:-}"; }
fail() { printf "  ${RED}✗${RST} ${RED}%s${RST} ${DIM}%s${RST}\n" "$1" "${2:-}"; }
warn() { printf "  ${YELLOW}⚡${RST} ${YELLOW}%s${RST} ${DIM}%s${RST}\n" "$1" "${2:-}"; }
msg()  { printf "  ${CYAN}▸${RST} ${WHITE}%s${RST}\n" "$1"; }
line() { printf "  ${DARK}────────────────────────────────────────────────────${RST}\n"; }

ask() {
    printf "\n  ${CYAN}▸${RST} ${BOLD}${WHITE}%s${RST} " "$1"
    read -r REPLY </dev/tty
}

spinner() {
    local pid=$1 label="$2"
    local frames=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${PURPLE}${frames[$i]}${RST} ${WHITE}%s${RST}  " "$label"
        i=$(( (i + 1) % ${#frames[@]} ))
        sleep 0.1
    done
    wait "$pid" 2>/dev/null
    return $?
}

check_cmd() { command -v "$1" &>/dev/null; }

# ── Banner ───────────────────────────────────────────────────
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
printf "${RST}\n"
printf "    ${DIM}${WHITE}One-command AI company infrastructure${RST}  ${DARK}v${PAPERSTACK_VERSION}${RST}\n"
printf "    ${DARK}Paperclip · Hermes Agent · Multi-LLM${RST}\n\n"
line
echo ""

# ── System Info ──────────────────────────────────────────────
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
[[ "$OS" == "darwin" ]] && OS="macos"
ARCH=$(uname -m)
[[ "$ARCH" == "aarch64" ]] && ARCH="arm64"
USER_NAME=$(whoami)

printf "  ${GRAY}System:${RST} ${WHITE}${OS}/${ARCH}${RST}  ${GRAY}User:${RST} ${WHITE}${USER_NAME}${RST}\n\n"
line

# ══════════════════════════════════════════════════════════════
#  STEP 1 — Choose LLM Provider
# ══════════════════════════════════════════════════════════════
echo ""
printf "  ${BOLD}${PURPLE}STEP 1${RST} ${BOLD}${WHITE}— Choose your LLM provider${RST}\n\n"

printf "    ${CYAN}1)${RST} ${WHITE}DeepSeek${RST}      ${DIM}deepseek-v4-flash, deepseek-r1${RST}\n"
printf "    ${CYAN}2)${RST} ${WHITE}Anthropic${RST}     ${DIM}claude-sonnet-4-6, claude-opus-4-8${RST}\n"
printf "    ${CYAN}3)${RST} ${WHITE}OpenAI${RST}        ${DIM}gpt-4.1, o4-mini${RST}\n"
printf "    ${CYAN}4)${RST} ${WHITE}MiniMax${RST}       ${DIM}MiniMax-M2, MiniMax-M1${RST}\n"
printf "    ${CYAN}5)${RST} ${WHITE}Google${RST}        ${DIM}gemini-2.5-pro, gemini-2.5-flash${RST}\n"
printf "    ${CYAN}6)${RST} ${WHITE}OpenRouter${RST}    ${DIM}auto (routes to best)${RST}\n"

ask "Enter number [1-6]:"
PROVIDER_NUM="${REPLY:-1}"

case "$PROVIDER_NUM" in
    1) PROVIDER="deepseek"   ;;
    2) PROVIDER="anthropic"  ;;
    3) PROVIDER="openai"     ;;
    4) PROVIDER="minimax"    ;;
    5) PROVIDER="google"     ;;
    6) PROVIDER="openrouter" ;;
    *) PROVIDER="deepseek"   ;;
esac

ok "Provider" "$PROVIDER"

# ══════════════════════════════════════════════════════════════
#  STEP 2 — Enter API Key
# ══════════════════════════════════════════════════════════════
echo ""
line
echo ""
printf "  ${BOLD}${PURPLE}STEP 2${RST} ${BOLD}${WHITE}— Enter your API key${RST}\n\n"

case "$PROVIDER" in
    deepseek)   KEY_URL="https://platform.deepseek.com/api-keys" ;;
    anthropic)  KEY_URL="https://console.anthropic.com/settings/keys" ;;
    openai)     KEY_URL="https://platform.openai.com/api-keys" ;;
    minimax)    KEY_URL="https://platform.minimax.io/" ;;
    google)     KEY_URL="https://aistudio.google.com/apikey" ;;
    openrouter) KEY_URL="https://openrouter.ai/keys" ;;
esac

printf "  ${GRAY}Get your key at:${RST} ${ULINE}${CYAN}%s${RST}\n" "$KEY_URL"

ask "Paste your ${PROVIDER} API key:"
API_KEY="${REPLY:-}"

if [[ -z "$API_KEY" ]]; then
    fail "No API key entered. Cannot continue."
    echo ""
    printf "  ${GRAY}Tip: You can also run with env vars:${RST}\n"
    printf "  ${DIM}PAPERSTACK_API_KEY=\"sk-xxx\" bash install.sh${RST}\n\n"
    exit 1
fi

MASKED="${API_KEY:0:8}...${API_KEY: -4}"
ok "API Key" "$MASKED"

# ══════════════════════════════════════════════════════════════
#  STEP 3 — Choose Model
# ══════════════════════════════════════════════════════════════
echo ""
line
echo ""
printf "  ${BOLD}${PURPLE}STEP 3${RST} ${BOLD}${WHITE}— Choose your model${RST}\n\n"

case "$PROVIDER" in
    deepseek)
        printf "    ${CYAN}1)${RST} ${WHITE}deepseek-v4-flash${RST}   ${DIM}(fast, recommended)${RST}\n"
        printf "    ${CYAN}2)${RST} ${WHITE}deepseek-r1${RST}          ${DIM}(reasoning)${RST}\n"
        printf "    ${CYAN}3)${RST} ${WHITE}deepseek-chat${RST}        ${DIM}(general)${RST}\n"
        printf "    ${CYAN}4)${RST} ${WHITE}deepseek-coder${RST}       ${DIM}(code)${RST}\n"
        ask "Enter number [1-4]:"
        case "${REPLY:-1}" in
            1) MODEL="deepseek-v4-flash" ;;
            2) MODEL="deepseek-r1" ;;
            3) MODEL="deepseek-chat" ;;
            4) MODEL="deepseek-coder" ;;
            *) MODEL="deepseek-v4-flash" ;;
        esac
        ;;
    anthropic)
        printf "    ${CYAN}1)${RST} ${WHITE}claude-sonnet-4-6${RST}   ${DIM}(balanced, recommended)${RST}\n"
        printf "    ${CYAN}2)${RST} ${WHITE}claude-opus-4-8${RST}     ${DIM}(most capable)${RST}\n"
        printf "    ${CYAN}3)${RST} ${WHITE}claude-haiku-4-5${RST}    ${DIM}(fastest)${RST}\n"
        ask "Enter number [1-3]:"
        case "${REPLY:-1}" in
            1) MODEL="claude-sonnet-4-6" ;;
            2) MODEL="claude-opus-4-8" ;;
            3) MODEL="claude-haiku-4-5" ;;
            *) MODEL="claude-sonnet-4-6" ;;
        esac
        ;;
    openai)
        printf "    ${CYAN}1)${RST} ${WHITE}gpt-4.1${RST}       ${DIM}(most capable)${RST}\n"
        printf "    ${CYAN}2)${RST} ${WHITE}gpt-4.1-mini${RST}  ${DIM}(fast & cheap)${RST}\n"
        printf "    ${CYAN}3)${RST} ${WHITE}o4-mini${RST}       ${DIM}(reasoning)${RST}\n"
        ask "Enter number [1-3]:"
        case "${REPLY:-1}" in
            1) MODEL="gpt-4.1" ;;
            2) MODEL="gpt-4.1-mini" ;;
            3) MODEL="o4-mini" ;;
            *) MODEL="gpt-4.1" ;;
        esac
        ;;
    minimax)
        printf "    ${CYAN}1)${RST} ${WHITE}MiniMax-M2${RST}    ${DIM}(latest)${RST}\n"
        printf "    ${CYAN}2)${RST} ${WHITE}MiniMax-M1${RST}    ${DIM}(stable)${RST}\n"
        ask "Enter number [1-2]:"
        case "${REPLY:-1}" in
            1) MODEL="MiniMax-M2" ;;
            2) MODEL="MiniMax-M1" ;;
            *) MODEL="MiniMax-M2" ;;
        esac
        ;;
    google)
        printf "    ${CYAN}1)${RST} ${WHITE}gemini-2.5-pro${RST}    ${DIM}(most capable)${RST}\n"
        printf "    ${CYAN}2)${RST} ${WHITE}gemini-2.5-flash${RST}  ${DIM}(fast)${RST}\n"
        ask "Enter number [1-2]:"
        case "${REPLY:-1}" in
            1) MODEL="gemini-2.5-pro" ;;
            2) MODEL="gemini-2.5-flash" ;;
            *) MODEL="gemini-2.5-pro" ;;
        esac
        ;;
    openrouter)
        MODEL="auto"
        printf "    ${GREEN}✓${RST} ${WHITE}auto${RST} ${DIM}(routes to best available)${RST}\n"
        ;;
esac

ok "Model" "$MODEL"

# ══════════════════════════════════════════════════════════════
#  STEP 4 — Confirm & Install
# ══════════════════════════════════════════════════════════════
echo ""
line
echo ""
printf "  ${BOLD}${PURPLE}STEP 4${RST} ${BOLD}${WHITE}— Confirm & install${RST}\n\n"

printf "    ${GRAY}Provider :${RST}  ${CYAN}${PROVIDER}${RST}\n"
printf "    ${GRAY}Model    :${RST}  ${CYAN}${MODEL}${RST}\n"
printf "    ${GRAY}API Key  :${RST}  ${GRAY}${MASKED}${RST}\n\n"

printf "    ${WHITE}Will install:${RST}\n"
printf "    ${CYAN}◆${RST} Node.js          ${DIM}(runtime)${RST}\n"
printf "    ${CYAN}◆${RST} Python 3         ${DIM}(runtime)${RST}\n"
printf "    ${CYAN}◆${RST} pipx             ${DIM}(package manager)${RST}\n"
printf "    ${CYAN}◆${RST} Paperclip        ${DIM}(AI company platform)${RST}\n"
printf "    ${CYAN}◆${RST} Hermes Agent     ${DIM}(multi-LLM agent)${RST}\n"
echo ""

ask "Install now? [Y/n]:"
if [[ "${REPLY:-y}" =~ ^[Nn] ]]; then
    printf "\n  ${GRAY}Cancelled.${RST}\n\n"
    exit 0
fi

# ══════════════════════════════════════════════════════════════
#  INSTALLING
# ══════════════════════════════════════════════════════════════
echo ""
line
echo ""
printf "  ${BOLD}${WHITE}Installing...${RST}\n\n"

# ── Node.js ──────────────────────────────────────────────────
if check_cmd node; then
    NODE_VER=$(node -v 2>/dev/null | sed 's/v//')
    NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
    if [[ $NODE_MAJOR -ge 20 ]]; then
        ok "Node.js" "v${NODE_VER} (already installed)"
    fi
else
    msg "Installing Node.js..."
    case "$OS" in
        linux)
            if check_cmd apt-get; then
                (curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs) &>/dev/null &
            elif check_cmd yum || check_cmd dnf; then
                (curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash - && sudo yum install -y nodejs) &>/dev/null &
            elif check_cmd apk; then
                (sudo apk add --no-cache nodejs npm) &>/dev/null &
            fi
            spinner $! "Installing Node.js..."
            ;;
        macos)
            if check_cmd brew; then
                (brew install node) &>/dev/null &
                spinner $! "Installing Node.js..."
            fi
            ;;
    esac
    check_cmd node && ok "Node.js" "v$(node -v | sed 's/v//')" || fail "Node.js" "install failed"
fi

# ── Python ───────────────────────────────────────────────────
if check_cmd python3; then
    PY_VER=$(python3 --version | awk '{print $2}')
    ok "Python" "v${PY_VER} (already installed)"
else
    msg "Installing Python 3..."
    case "$OS" in
        linux)
            if check_cmd apt-get; then
                (sudo apt-get update -qq && sudo apt-get install -y -qq python3 python3-pip python3-venv) &>/dev/null &
            elif check_cmd dnf; then
                (sudo dnf install -y python3 python3-pip) &>/dev/null &
            elif check_cmd apk; then
                (sudo apk add --no-cache python3 py3-pip) &>/dev/null &
            fi
            spinner $! "Installing Python 3..."
            ;;
        macos)
            if check_cmd brew; then
                (brew install python@3.12) &>/dev/null &
                spinner $! "Installing Python 3..."
            fi
            ;;
    esac
    check_cmd python3 && ok "Python" "v$(python3 --version | awk '{print $2}')" || fail "Python" "install failed"
fi

# ── pipx ─────────────────────────────────────────────────────
if check_cmd pipx; then
    ok "pipx" "$(pipx --version 2>/dev/null)"
else
    msg "Installing pipx..."
    case "$OS" in
        linux)
            (python3 -m pip install --user pipx 2>/dev/null || sudo apt-get install -y -qq pipx 2>/dev/null || sudo dnf install -y pipx 2>/dev/null) &>/dev/null &
            ;;
        macos)
            (brew install pipx) &>/dev/null &
            ;;
    esac
    spinner $! "Installing pipx..."
    pipx ensurepath &>/dev/null 2>&1 || true
    export PATH="$HOME/.local/bin:$PATH"
    check_cmd pipx && ok "pipx" "installed" || fail "pipx" "install failed"
fi

# ── Paperclip ────────────────────────────────────────────────
msg "Installing Paperclip..."
(npm install -g paperclipai 2>/dev/null || npx paperclipai --version) &>/dev/null &
spinner $! "Installing Paperclip..."
printf "\r"
ok "Paperclip" "$(npx paperclipai --version 2>/dev/null || echo 'latest')"

# ── Hermes Agent ─────────────────────────────────────────────
msg "Installing Hermes Agent..."
(pipx install hermes-agent 2>/dev/null || pipx upgrade hermes-agent 2>/dev/null) &>/dev/null &
spinner $! "Installing Hermes Agent..."
printf "\r"
export PATH="$HOME/.local/bin:$PATH"

HERMES_BIN=$(which hermes 2>/dev/null || echo "$HOME/.local/bin/hermes")
if [[ -x "$HERMES_BIN" ]]; then
    ok "Hermes Agent" "$($HERMES_BIN --version 2>/dev/null || echo 'installed')"
else
    fail "Hermes Agent" "install failed"
fi

# ══════════════════════════════════════════════════════════════
#  CONFIGURING
# ══════════════════════════════════════════════════════════════
echo ""
line
echo ""
printf "  ${BOLD}${WHITE}Configuring...${RST}\n\n"

# ── Hermes config ────────────────────────────────────────────
"$HERMES_BIN" config set provider "$PROVIDER" &>/dev/null 2>&1 || true
"$HERMES_BIN" config set api_key "$API_KEY" &>/dev/null 2>&1 || true
"$HERMES_BIN" config set model "$MODEL" &>/dev/null 2>&1 || true

mkdir -p "$HOME/.hermes"
ENV_KEY=$(echo "${PROVIDER}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
cat > "$HOME/.hermes/.env" <<EOF
${ENV_KEY}_API_KEY=${API_KEY}
EOF

ok "Hermes" "provider=${PROVIDER}  model=${MODEL}"

# ── Paperclip onboard ────────────────────────────────────────
msg "Setting up Paperclip..."
(npx paperclipai onboard --yes) &>/dev/null &
spinner $! "Running Paperclip onboard..."
printf "\r"

if [[ -f "$HOME/.paperclip/instances/default/config.json" ]]; then
    ok "Paperclip" "configured at ~/.paperclip"
else
    warn "Paperclip" "run: npx paperclipai configure"
fi

# ── Launcher script ──────────────────────────────────────────
LAUNCHER="$HOME/.local/bin/paperstack"
mkdir -p "$HOME/.local/bin"

cat > "$LAUNCHER" << 'LAUNCHER_EOF'
#!/usr/bin/env bash
set -euo pipefail
C="\033[38;5;87m" G="\033[38;5;114m" W="\033[38;5;255m" D="\033[2m" B="\033[1m" R="\033[0m" GY="\033[38;5;245m" P="\033[38;5;141m"

case "${1:-help}" in
    start)   printf "\n  ${P}▸${R} Starting Paperclip...\n\n"; npx paperclipai run ;;
    stop)    pkill -f "paperclipai" 2>/dev/null && printf "  ${G}✓${R} Stopped\n" || printf "  ${GY}Not running${R}\n" ;;
    status)
        echo ""
        curl -sf http://127.0.0.1:3100/api/health &>/dev/null \
            && printf "  ${G}●${R} Paperclip    ${G}running${R} ${D}(port 3100)${R}\n" \
            || printf "  ${GY}○${R} Paperclip    ${GY}stopped${R}\n"
        H=$(which hermes 2>/dev/null || echo "$HOME/.local/bin/hermes")
        [[ -x "$H" ]] \
            && printf "  ${G}●${R} Hermes       ${G}installed${R}\n" \
            || printf "  ${GY}○${R} Hermes       ${GY}not found${R}\n"
        echo ""
        ;;
    config)  H=$(which hermes 2>/dev/null || echo "$HOME/.local/bin/hermes"); "$H" config show 2>/dev/null ;;
    doctor)  npx paperclipai doctor ;;
    logs)    tail -f "$HOME/.paperclip/instances/default/logs"/*.log 2>/dev/null ;;
    hermes)  shift; H=$(which hermes 2>/dev/null || echo "$HOME/.local/bin/hermes"); "$H" "$@" ;;
    ui)      U="http://127.0.0.1:3100"; command -v xdg-open &>/dev/null && xdg-open "$U" || command -v open &>/dev/null && open "$U" || printf "  Open: ${C}%s${R}\n" "$U" ;;
    *)
        echo ""
        printf "  ${C}${B}PAPERSTACK${R}\n\n"
        printf "    ${G}start${R}    Start server\n"
        printf "    ${G}stop${R}     Stop server\n"
        printf "    ${G}status${R}   Check status\n"
        printf "    ${G}config${R}   Show config\n"
        printf "    ${G}doctor${R}   Run diagnostics\n"
        printf "    ${G}logs${R}     Tail logs\n"
        printf "    ${G}hermes${R}   Run Hermes\n"
        printf "    ${G}ui${R}       Open web UI\n"
        echo ""
        ;;
esac
LAUNCHER_EOF

chmod +x "$LAUNCHER"
ok "CLI" "paperstack command created"

# ══════════════════════════════════════════════════════════════
#  DONE
# ══════════════════════════════════════════════════════════════
echo ""
line
echo ""

printf "${GREEN}${BOLD}"
cat << 'DONE_ART'
     ██████╗  ██████╗ ███╗   ██╗███████╗██╗
     ██╔══██╗██╔═══██╗████╗  ██║██╔════╝██║
     ██║  ██║██║   ██║██╔██╗ ██║█████╗  ██║
     ██║  ██║██║   ██║██║╚██╗██║██╔══╝  ╚═╝
     ██████╔╝╚██████╔╝██║ ╚████║███████╗██╗
     ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝
DONE_ART
printf "${RST}\n"

printf "  ${BOLD}${WHITE}Your AI infrastructure is ready!${RST}\n\n"

printf "    ${GREEN}paperstack start${RST}    ${DIM}Start the server${RST}\n"
printf "    ${GREEN}paperstack status${RST}   ${DIM}Check everything${RST}\n"
printf "    ${GREEN}paperstack ui${RST}       ${DIM}Open web dashboard${RST}\n"
printf "    ${GREEN}paperstack hermes${RST}   ${DIM}Run Hermes directly${RST}\n\n"

printf "  ${GRAY}Web UI :${RST}  ${ULINE}${CYAN}http://127.0.0.1:3100${RST}\n"
printf "  ${GRAY}Config :${RST}  ${DIM}~/.hermes/config.yaml${RST}\n\n"

printf "  ${DIM}Add to PATH if needed:${RST}\n"
printf "  ${DARK}export PATH=\"\$HOME/.local/bin:\$PATH\"${RST}\n\n"
