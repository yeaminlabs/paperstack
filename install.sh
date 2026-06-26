#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
#  DEEPSTACK V1 — Deploy DeepSeek with Paperclip CLI Agents
#  Developed by SNBDHOST — For Internal Purposes Only
#  Copyright: yeaminlabs
#  Usage:    curl -fsSL https://raw.githubusercontent.com/yeaminlabs/paperstack/main/install.sh | bash
# ─────────────────────────────────────────────────────────────

DEEPSTACK_VERSION="1.0.0"

# ── Colors ───────────────────────────────────────────────────
RST="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
ULINE="\033[4m"
# Red brand palette
R1="\033[38;5;196m"
R2="\033[38;5;160m"
R3="\033[38;5;124m"
ACCENT="\033[38;5;203m"
GREEN="\033[38;5;114m"
YELLOW="\033[38;5;221m"
RED="\033[38;5;196m"
WHITE="\033[38;5;255m"
GRAY="\033[38;5;245m"
DARK="\033[38;5;238m"

# ── Helpers ──────────────────────────────────────────────────
ok()   { printf "  ${GREEN}✓${RST} ${WHITE}%s${RST} ${DIM}%s${RST}\n" "$1" "${2:-}"; }
fail() { printf "  ${RED}✗${RST} ${RED}%s${RST} ${DIM}%s${RST}\n" "$1" "${2:-}"; }
warn() { printf "  ${YELLOW}⚡${RST} ${YELLOW}%s${RST} ${DIM}%s${RST}\n" "$1" "${2:-}"; }
msg()  { printf "  ${ACCENT}▸${RST} ${WHITE}%s${RST}\n" "$1"; }
line() { printf "  ${R3}────────────────────────────────────────────────────${RST}\n"; }

ask() {
    printf "\n  ${ACCENT}▸${RST} ${BOLD}${WHITE}%s${RST} " "$1"
    read -r REPLY </dev/tty
}

spinner() {
    local pid=$1 label="$2"
    local frames=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${R1}${frames[$i]}${RST} ${WHITE}%s${RST}  " "$label"
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
printf "${R1}${BOLD}"
cat << 'LOGO'
    ██████╗ ███████╗███████╗██████╗ ███████╗██████╗  █████╗  ██████╗██╗  ██╗
    ██╔══██╗██╔════╝██╔════╝██╔══██╗██╔════╝╚═██╔═╝██╔══██╗██╔════╝██║ ██╔╝
    ██║  ██║█████╗  █████╗  ██████╔╝███████╗  ██║  ███████║██║     █████╔╝
    ██║  ██║██╔══╝  ██╔══╝  ██╔═══╝ ╚════██║  ██║  ██╔══██║██║     ██╔═██╗
    ██████╔╝███████╗███████╗██║     ███████║  ██║  ██║  ██║╚██████╗██║  ██╗
    ╚═════╝ ╚══════╝╚══════╝╚═╝     ╚══════╝  ╚═╝  ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
LOGO
printf "${RST}"
printf "${R2}"
cat << 'LOGO2'
                          ██╗   ██╗ ██╗
                          ██║   ██║███║
                          ██║   ██║╚██║
                          ╚██╗ ██╔╝ ██║
                           ╚████╔╝  ██║
                            ╚═══╝   ╚═╝
LOGO2
printf "${RST}\n"
printf "    ${WHITE}${BOLD}DeepStack V1${RST} ${DARK}— Seamlessly deploy DeepSeek with Paperclip CLI Agents${RST}\n"
printf "    ${DARK}Developed by ${WHITE}SNBDHOST${DARK} · For Internal Purposes Only · ${DIM}Copyright: yeaminlabs${RST}\n\n"
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

# ── Resume check ─────────────────────────────────────────────
RESUME_FILE="$HOME/.deepstack/install_config"
RESUMING=false

if [[ -f "$HOME/.deepstack_install_state" ]] && [[ -f "$RESUME_FILE" ]]; then
    echo ""
    printf "  ${YELLOW}⚡${RST} ${BOLD}${WHITE}Previous incomplete install found.${RST}\n"
    source "$RESUME_FILE"
    MASKED="${API_KEY:0:8}...${API_KEY: -4}"
    printf "  ${GRAY}Provider: ${ACCENT}${PROVIDER}${RST}  ${GRAY}Model: ${ACCENT}${MODEL}${RST}  ${GRAY}Key: ${GRAY}${MASKED}${RST}\n"
    ask "Resume? [Y/n]:"
    if [[ ! "${REPLY:-y}" =~ ^[Nn] ]]; then
        RESUMING=true
    fi
fi

if [[ "$RESUMING" == "false" ]]; then

# ══════════════════════════════════════════════════════════════
#  STEP 1 — Choose LLM Provider
# ══════════════════════════════════════════════════════════════
echo ""
printf "  ${BOLD}${R1}STEP 1${RST} ${BOLD}${WHITE}— Choose your LLM provider${RST}\n\n"

printf "    ${ACCENT}1)${RST} ${WHITE}DeepSeek${RST}      ${DIM}deepseek-v4-flash, deepseek-r1${RST}\n"
printf "    ${ACCENT}2)${RST} ${WHITE}Anthropic${RST}     ${DIM}claude-sonnet-4-6, claude-opus-4-8${RST}\n"
printf "    ${ACCENT}3)${RST} ${WHITE}OpenAI${RST}        ${DIM}gpt-4.1, o4-mini${RST}\n"
printf "    ${ACCENT}4)${RST} ${WHITE}MiniMax${RST}       ${DIM}MiniMax-M2, MiniMax-M1${RST}\n"
printf "    ${ACCENT}5)${RST} ${WHITE}Google${RST}        ${DIM}gemini-2.5-pro, gemini-2.5-flash${RST}\n"
printf "    ${ACCENT}6)${RST} ${WHITE}OpenRouter${RST}    ${DIM}auto (routes to best)${RST}\n"

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
printf "  ${BOLD}${R1}STEP 2${RST} ${BOLD}${WHITE}— Enter your API key${RST}\n\n"

case "$PROVIDER" in
    deepseek)   KEY_URL="https://platform.deepseek.com/api-keys" ;;
    anthropic)  KEY_URL="https://console.anthropic.com/settings/keys" ;;
    openai)     KEY_URL="https://platform.openai.com/api-keys" ;;
    minimax)    KEY_URL="https://platform.minimax.io/" ;;
    google)     KEY_URL="https://aistudio.google.com/apikey" ;;
    openrouter) KEY_URL="https://openrouter.ai/keys" ;;
esac

printf "  ${GRAY}Get your key at:${RST} ${ULINE}${ACCENT}%s${RST}\n" "$KEY_URL"

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
printf "  ${BOLD}${R1}STEP 3${RST} ${BOLD}${WHITE}— Choose your model${RST}\n\n"

case "$PROVIDER" in
    deepseek)
        printf "    ${ACCENT}1)${RST} ${WHITE}deepseek-v4-flash${RST}   ${DIM}(fast, recommended)${RST}\n"
        printf "    ${ACCENT}2)${RST} ${WHITE}deepseek-r1${RST}          ${DIM}(reasoning)${RST}\n"
        printf "    ${ACCENT}3)${RST} ${WHITE}deepseek-chat${RST}        ${DIM}(general)${RST}\n"
        printf "    ${ACCENT}4)${RST} ${WHITE}deepseek-coder${RST}       ${DIM}(code)${RST}\n"
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
        printf "    ${ACCENT}1)${RST} ${WHITE}claude-sonnet-4-6${RST}   ${DIM}(balanced, recommended)${RST}\n"
        printf "    ${ACCENT}2)${RST} ${WHITE}claude-opus-4-8${RST}     ${DIM}(most capable)${RST}\n"
        printf "    ${ACCENT}3)${RST} ${WHITE}claude-haiku-4-5${RST}    ${DIM}(fastest)${RST}\n"
        ask "Enter number [1-3]:"
        case "${REPLY:-1}" in
            1) MODEL="claude-sonnet-4-6" ;;
            2) MODEL="claude-opus-4-8" ;;
            3) MODEL="claude-haiku-4-5" ;;
            *) MODEL="claude-sonnet-4-6" ;;
        esac
        ;;
    openai)
        printf "    ${ACCENT}1)${RST} ${WHITE}gpt-4.1${RST}       ${DIM}(most capable)${RST}\n"
        printf "    ${ACCENT}2)${RST} ${WHITE}gpt-4.1-mini${RST}  ${DIM}(fast & cheap)${RST}\n"
        printf "    ${ACCENT}3)${RST} ${WHITE}o4-mini${RST}       ${DIM}(reasoning)${RST}\n"
        ask "Enter number [1-3]:"
        case "${REPLY:-1}" in
            1) MODEL="gpt-4.1" ;;
            2) MODEL="gpt-4.1-mini" ;;
            3) MODEL="o4-mini" ;;
            *) MODEL="gpt-4.1" ;;
        esac
        ;;
    minimax)
        printf "    ${ACCENT}1)${RST} ${WHITE}MiniMax-M2${RST}    ${DIM}(latest)${RST}\n"
        printf "    ${ACCENT}2)${RST} ${WHITE}MiniMax-M1${RST}    ${DIM}(stable)${RST}\n"
        ask "Enter number [1-2]:"
        case "${REPLY:-1}" in
            1) MODEL="MiniMax-M2" ;;
            2) MODEL="MiniMax-M1" ;;
            *) MODEL="MiniMax-M2" ;;
        esac
        ;;
    google)
        printf "    ${ACCENT}1)${RST} ${WHITE}gemini-2.5-pro${RST}    ${DIM}(most capable)${RST}\n"
        printf "    ${ACCENT}2)${RST} ${WHITE}gemini-2.5-flash${RST}  ${DIM}(fast)${RST}\n"
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
printf "  ${BOLD}${R1}STEP 4${RST} ${BOLD}${WHITE}— Confirm & install${RST}\n\n"

printf "    ${GRAY}Provider :${RST}  ${ACCENT}${PROVIDER}${RST}\n"
printf "    ${GRAY}Model    :${RST}  ${ACCENT}${MODEL}${RST}\n"
printf "    ${GRAY}API Key  :${RST}  ${GRAY}${MASKED}${RST}\n\n"

printf "    ${WHITE}Will install:${RST}\n"
printf "    ${ACCENT}◆${RST} Node.js          ${DIM}(runtime)${RST}\n"
printf "    ${ACCENT}◆${RST} Python 3         ${DIM}(runtime)${RST}\n"
printf "    ${ACCENT}◆${RST} pipx             ${DIM}(package manager)${RST}\n"
printf "    ${ACCENT}◆${RST} Paperclip        ${DIM}(AI company platform)${RST}\n"
printf "    ${ACCENT}◆${RST} Hermes Agent     ${DIM}(multi-LLM agent)${RST}\n"
echo ""

ask "Install now? [Y/n]:"
if [[ "${REPLY:-y}" =~ ^[Nn] ]]; then
    printf "\n  ${GRAY}Cancelled.${RST}\n\n"
    exit 0
fi

fi  # end of RESUMING==false block

# ══════════════════════════════════════════════════════════════
#  STATE TRACKING — resume from where we left off
# ══════════════════════════════════════════════════════════════
STATE_FILE="$HOME/.deepstack_install_state"

mark_done()  { echo "$1" >> "$STATE_FILE"; }
is_done()    { [[ -f "$STATE_FILE" ]] && grep -qxF "$1" "$STATE_FILE" 2>/dev/null; }

if [[ -f "$STATE_FILE" ]]; then
    echo ""
    printf "  ${YELLOW}⚡${RST} ${WHITE}Previous install detected — resuming from where it stopped${RST}\n"
fi

# Save config for resume
mkdir -p "$HOME/.deepstack"
cat > "$HOME/.deepstack/install_config" <<EOF
PROVIDER=${PROVIDER}
API_KEY=${API_KEY}
MODEL=${MODEL}
EOF

# ══════════════════════════════════════════════════════════════
#  INSTALLING
# ══════════════════════════════════════════════════════════════
echo ""
line
echo ""
printf "  ${BOLD}${WHITE}Installing...${RST}\n\n"

# ── Node.js ──────────────────────────────────────────────────
if is_done "node"; then
    ok "Node.js" "(done)"
elif check_cmd node; then
    NODE_VER=$(node -v 2>/dev/null | sed 's/v//')
    NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
    if [[ $NODE_MAJOR -ge 20 ]]; then
        ok "Node.js" "v${NODE_VER} (already installed)"
        mark_done "node"
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
    if check_cmd node; then
        ok "Node.js" "v$(node -v | sed 's/v//')"
        mark_done "node"
    else
        fail "Node.js" "install failed"
    fi
fi

# ── Python ───────────────────────────────────────────────────
if is_done "python"; then
    ok "Python" "(done)"
elif check_cmd python3; then
    PY_VER=$(python3 --version | awk '{print $2}')
    ok "Python" "v${PY_VER} (already installed)"
    mark_done "python"
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
    if check_cmd python3; then
        ok "Python" "v$(python3 --version | awk '{print $2}')"
        mark_done "python"
    else
        fail "Python" "install failed"
    fi
fi

# ── pipx ─────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
if is_done "pipx"; then
    ok "pipx" "(done)"
elif check_cmd pipx; then
    ok "pipx" "$(pipx --version 2>/dev/null)"
    mark_done "pipx"
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
    if check_cmd pipx; then
        ok "pipx" "installed"
        mark_done "pipx"
    else
        fail "pipx" "install failed"
    fi
fi

# ── Paperclip ────────────────────────────────────────────────
if is_done "paperclip_install"; then
    ok "Paperclip" "(done)"
else
    msg "Installing Paperclip..."
    (npm install -g paperclipai 2>/dev/null || npx paperclipai --version) &>/dev/null &
    spinner $! "Installing Paperclip..."
    printf "\r"
    ok "Paperclip" "$(npx paperclipai --version 2>/dev/null || echo 'latest')"
    mark_done "paperclip_install"
fi

# ── Hermes Agent ─────────────────────────────────────────────
if is_done "hermes_install"; then
    ok "Hermes Agent" "(done)"
else
    msg "Installing Hermes Agent..."
    (pipx install hermes-agent 2>/dev/null || pipx upgrade hermes-agent 2>/dev/null) &>/dev/null &
    spinner $! "Installing Hermes Agent..."
    printf "\r"
    export PATH="$HOME/.local/bin:$PATH"

    HERMES_BIN=$(which hermes 2>/dev/null || echo "$HOME/.local/bin/hermes")
    if [[ -x "$HERMES_BIN" ]]; then
        ok "Hermes Agent" "$($HERMES_BIN --version 2>/dev/null || echo 'installed')"
        mark_done "hermes_install"
    else
        fail "Hermes Agent" "install failed"
    fi
fi

# ══════════════════════════════════════════════════════════════
#  CONFIGURING
# ══════════════════════════════════════════════════════════════
echo ""
line
echo ""
printf "  ${BOLD}${WHITE}Configuring...${RST}\n\n"

export PATH="$HOME/.local/bin:$PATH"
HERMES_BIN=$(which hermes 2>/dev/null || echo "$HOME/.local/bin/hermes")

# ── Hermes config ────────────────────────────────────────────
if is_done "hermes_config"; then
    ok "Hermes" "(done)"
else
    "$HERMES_BIN" config set provider "$PROVIDER" &>/dev/null 2>&1 || true
    "$HERMES_BIN" config set api_key "$API_KEY" &>/dev/null 2>&1 || true
    "$HERMES_BIN" config set model "$MODEL" &>/dev/null 2>&1 || true

    mkdir -p "$HOME/.hermes"
    ENV_KEY=$(echo "${PROVIDER}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    cat > "$HOME/.hermes/.env" <<EOF
${ENV_KEY}_API_KEY=${API_KEY}
EOF

    ok "Hermes" "provider=${PROVIDER}  model=${MODEL}"
    mark_done "hermes_config"
fi

# ── Paperclip onboard ────────────────────────────────────────
if is_done "paperclip_config"; then
    ok "Paperclip" "(done)"
else
    echo ""
    line
    echo ""
    printf "  ${BOLD}${WHITE}Setting up Paperclip...${RST}\n\n"

    # ── STEP A: Kill anything on port 3100 ──
    pkill -f "paperclipai" 2>/dev/null || true
    if command -v fuser &>/dev/null; then
        fuser -k 3100/tcp 2>/dev/null || true
    elif command -v lsof &>/dev/null; then
        lsof -ti :3100 2>/dev/null | xargs kill 2>/dev/null || true
    fi
    sleep 1

    # ── STEP B: Pre-create config with root Postgres fix ──
    # This MUST happen before onboard so Postgres doesn't choke on root
    INSTANCE_DIR="$HOME/.paperclip/instances/default"
    CONFIG_FILE="$INSTANCE_DIR/config.json"
    mkdir -p "$INSTANCE_DIR/secrets" "$INSTANCE_DIR/logs" "$INSTANCE_DIR/data/storage" "$INSTANCE_DIR/data/backups" "$INSTANCE_DIR/db"

    if [[ "$(whoami)" == "root" ]]; then
        msg "Running as root — pre-configuring Postgres user creation..."

        if [[ -f "$CONFIG_FILE" ]]; then
            # Patch existing config
            node -e "
const fs = require('fs');
const p = '$CONFIG_FILE';
const c = JSON.parse(fs.readFileSync(p, 'utf8'));
c.database = c.database || {};
c.database.createPostgresUser = true;
fs.writeFileSync(p, JSON.stringify(c, null, 2));
" 2>/dev/null
        else
            # Create fresh config with createPostgresUser from the start
            node -e "
const fs = require('fs');
fs.writeFileSync('$CONFIG_FILE', JSON.stringify({
  \"\\\$meta\": { version: 1, updatedAt: new Date().toISOString(), source: 'deepstack' },
  database: {
    mode: 'embedded-postgres',
    embeddedPostgresDataDir: '$INSTANCE_DIR/db',
    embeddedPostgresPort: 54329,
    createPostgresUser: true,
    backup: { enabled: true, intervalMinutes: 60, retentionDays: 30, dir: '$INSTANCE_DIR/data/backups' }
  },
  logging: { mode: 'file', logDir: '$INSTANCE_DIR/logs' },
  server: {
    deploymentMode: 'local_trusted', exposure: 'private',
    bind: 'loopback', host: '127.0.0.1', port: 3100,
    allowedHostnames: [], serveUi: true
  },
  auth: { baseUrlMode: 'auto', disableSignUp: false },
  telemetry: { enabled: true },
  storage: {
    provider: 'local_disk',
    localDisk: { baseDir: '$INSTANCE_DIR/data/storage' }
  },
  secrets: {
    provider: 'local_encrypted', strictMode: false,
    localEncrypted: { keyFilePath: '$INSTANCE_DIR/secrets/master.key' }
  }
}, null, 2));
" 2>/dev/null
        fi
        ok "Root fix" "createPostgresUser enabled in config"
    fi

    # ── STEP C: Run onboard — show output live, kill when server starts ──
    msg "Running Paperclip onboard (output shown below)..."
    echo ""

    # onboard --yes does setup then starts the server (which blocks forever)
    # We pipe through a watcher that kills it once the server starts listening
    npx paperclipai onboard --yes 2>&1 &
    ONBOARD_PID=$!

    # Wait for either: config created + server started, or process exits, or 120s timeout
    WAITED=0
    SERVER_STARTED=false
    while kill -0 "$ONBOARD_PID" 2>/dev/null; do
        # Check if the server is up (means onboard finished, server is running)
        if curl -sf http://127.0.0.1:3100/api/health &>/dev/null; then
            SERVER_STARTED=true
            break
        fi
        sleep 2
        WAITED=$((WAITED + 2))
        if [[ $WAITED -ge 120 ]]; then
            break
        fi
    done

    # Kill the server process — we don't want it running from the installer
    kill "$ONBOARD_PID" 2>/dev/null || true
    wait "$ONBOARD_PID" 2>/dev/null || true
    pkill -f "paperclipai" 2>/dev/null || true
    if command -v fuser &>/dev/null; then
        fuser -k 3100/tcp 2>/dev/null || true
    fi
    sleep 1

    # ── STEP D: Re-apply root fix (onboard may have overwritten config) ──
    if [[ "$(whoami)" == "root" ]] && [[ -f "$CONFIG_FILE" ]]; then
        node -e "
const fs = require('fs');
const p = '$CONFIG_FILE';
const c = JSON.parse(fs.readFileSync(p, 'utf8'));
c.database = c.database || {};
c.database.createPostgresUser = true;
fs.writeFileSync(p, JSON.stringify(c, null, 2));
" 2>/dev/null || true
    fi

    echo ""
    line
    echo ""

    if [[ -f "$CONFIG_FILE" ]]; then
        ok "Paperclip" "onboarded at ~/.paperclip"
        if [[ "$SERVER_STARTED" == "true" ]]; then
            ok "Server test" "health check passed"
        fi
        mark_done "paperclip_config"
    else
        fail "Paperclip onboard failed"
        printf "  ${GRAY}Try manually: npx paperclipai onboard --yes${RST}\n"
    fi
fi

# ── Launcher script ──────────────────────────────────────────
LAUNCHER="$HOME/.local/bin/deepstack"
mkdir -p "$HOME/.local/bin"

cat > "$LAUNCHER" << 'LAUNCHER_EOF'
#!/usr/bin/env bash
set -euo pipefail
RD="\033[38;5;196m" G="\033[38;5;114m" W="\033[38;5;255m" D="\033[2m" B="\033[1m" R="\033[0m" GY="\033[38;5;245m" AC="\033[38;5;203m"

case "${1:-help}" in
    start)   printf "\n  ${RD}▸${R} Starting DeepStack...\n\n"; npx paperclipai run ;;
    stop)    pkill -f "paperclipai" 2>/dev/null && printf "  ${G}✓${R} Stopped\n" || printf "  ${GY}Not running${R}\n" ;;
    status)
        echo ""
        printf "  ${RD}${B}DEEPSTACK V1${R} ${D}— Status${R}\n\n"
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
    ui)      U="http://127.0.0.1:3100"; command -v xdg-open &>/dev/null && xdg-open "$U" || command -v open &>/dev/null && open "$U" || printf "  Open: ${AC}%s${R}\n" "$U" ;;
    *)
        echo ""
        printf "  ${RD}${B}DEEPSTACK V1${R} ${D}— SNBDHOST${R}\n\n"
        printf "    ${AC}start${R}    Start server\n"
        printf "    ${AC}stop${R}     Stop server\n"
        printf "    ${AC}status${R}   Check status\n"
        printf "    ${AC}config${R}   Show config\n"
        printf "    ${AC}doctor${R}   Run diagnostics\n"
        printf "    ${AC}logs${R}     Tail logs\n"
        printf "    ${AC}hermes${R}   Run Hermes\n"
        printf "    ${AC}ui${R}       Open web UI\n"
        echo ""
        ;;
esac
LAUNCHER_EOF

chmod +x "$LAUNCHER"
ok "CLI" "deepstack command created"

# ══════════════════════════════════════════════════════════════
#  DONE
# ══════════════════════════════════════════════════════════════
echo ""
line
echo ""

printf "${R1}${BOLD}"
cat << 'DONE_ART'
     ██████╗ ███████╗ █████╗ ██████╗ ██╗   ██╗██╗
     ██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝██║
     ██████╔╝█████╗  ███████║██║  ██║ ╚████╔╝ ██║
     ██╔══██╗██╔══╝  ██╔══██║██║  ██║  ╚██╔╝  ╚═╝
     ██║  ██║███████╗██║  ██║██████╔╝   ██║   ██╗
     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝   ╚═╝
DONE_ART
printf "${RST}\n"

printf "  ${BOLD}${WHITE}DeepStack V1 deployed successfully!${RST}\n\n"

line
echo ""
printf "  ${BOLD}${WHITE}HOW TO USE${RST}\n\n"

printf "    ${ACCENT}1.${RST} ${WHITE}Start the server:${RST}\n"
printf "       ${GREEN}deepstack start${RST}\n\n"

printf "    ${ACCENT}2.${RST} ${WHITE}Open the web dashboard:${RST}\n"
printf "       ${ULINE}${ACCENT}http://YOUR-SERVER-IP:3100${RST}\n\n"

printf "    ${ACCENT}3.${RST} ${WHITE}Other commands:${RST}\n"
printf "       ${GREEN}deepstack status${RST}   ${DIM}Check if running${RST}\n"
printf "       ${GREEN}deepstack stop${RST}     ${DIM}Stop the server${RST}\n"
printf "       ${GREEN}deepstack config${RST}   ${DIM}View Hermes config${RST}\n"
printf "       ${GREEN}deepstack doctor${RST}   ${DIM}Run diagnostics${RST}\n"
printf "       ${GREEN}deepstack hermes${RST}   ${DIM}Run Hermes directly${RST}\n"

echo ""
line
echo ""

printf "  ${GRAY}Config files:${RST}\n"
printf "    ${DIM}Paperclip : ~/.paperclip/instances/default/config.json${RST}\n"
printf "    ${DIM}Hermes    : ~/.hermes/config.yaml${RST}\n"
printf "    ${DIM}LLM Key   : ~/.hermes/.env${RST}\n\n"

printf "  ${DIM}If 'deepstack' command not found, run:${RST}\n"
printf "  ${DARK}export PATH=\"\$HOME/.local/bin:\$PATH\"${RST}\n\n"

line
printf "  ${R3}SNBDHOST${RST} ${DARK}· Internal Use Only · Copyright yeaminlabs${RST}\n"
line
echo ""

# Clean up state file — install completed successfully
rm -f "$STATE_FILE" 2>/dev/null || true
rm -f "$HOME/.deepstack/install_config" 2>/dev/null || true
