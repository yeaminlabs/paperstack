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

# ── Check if already fully installed ─────────────────────────
SKIP_INSTALL=false
PAPERCLIP_HOME="$HOME"
[[ "$(whoami)" == "root" ]] && id -u paperclip &>/dev/null 2>&1 && PAPERCLIP_HOME=$(eval echo ~paperclip 2>/dev/null || echo "/home/paperclip")
EXISTING_CONFIG="$PAPERCLIP_HOME/.paperclip/instances/default/config.json"

if check_cmd node && check_cmd npx && check_cmd pipx && [[ -f "$EXISTING_CONFIG" ]] && (check_cmd hermes || [[ -x "$HOME/.local/bin/hermes" ]] || [[ -x "$PAPERCLIP_HOME/.local/bin/hermes" ]]); then
    ok "Paperclip + Hermes + DeepSeek" "already installed"
    SKIP_INSTALL=true
else
    # ── Clean slate — nuke everything from previous installs ─────
    msg "Cleaning previous installs..."
    pkill -f "paperclipai" 2>/dev/null || true
    pkill -f "pm2" 2>/dev/null || true
    if command -v fuser &>/dev/null; then
        fuser -k 3100/tcp 2>/dev/null || true
        fuser -k 54329/tcp 2>/dev/null || true
    fi
    sleep 1
    rm -rf "$HOME/.deepstack_install_state" "$HOME/.deepstack" "$HOME/.paperclip"
    if id -u paperclip &>/dev/null 2>&1; then
        rm -rf "$PAPERCLIP_HOME/.paperclip" "$PAPERCLIP_HOME/.hermes" 2>/dev/null || true
    fi
    ok "Clean" "previous data removed"
fi
echo ""
line

if [[ "$SKIP_INSTALL" == "false" ]]; then

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

fi  # end SKIP_INSTALL check for prompts

# ══════════════════════════════════════════════════════════════
#  INSTALLING
# ══════════════════════════════════════════════════════════════
if [[ "$SKIP_INSTALL" == "false" ]]; then

echo ""
line
echo ""
printf "  ${BOLD}${WHITE}Installing...${RST}\n\n"

# ── Node.js ──────────────────────────────────────────────────
if check_cmd node; then
    ok "Node.js" "v$(node -v | sed 's/v//') (already installed)"
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
    ok "Python" "v$(python3 --version | awk '{print $2}') (already installed)"
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
export PATH="$HOME/.local/bin:$PATH"
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
[[ -x "$HERMES_BIN" ]] && ok "Hermes Agent" "$($HERMES_BIN --version 2>/dev/null || echo 'installed')" || fail "Hermes Agent" "install failed"

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

    # ── Create paperclip system user if running as root ──
    if [[ "$(whoami)" == "root" ]]; then
        msg "Running as root — creating 'paperclip' system user..."

        if ! id -u paperclip &>/dev/null; then
            useradd --system --create-home --shell /bin/bash paperclip 2>/dev/null || true
        fi

        # Copy node/npm/npx to paperclip user's PATH
        PAPERCLIP_HOME=$(eval echo ~paperclip)

        mkdir -p "$PAPERCLIP_HOME/.local/bin"

        # Fix npm global modules permissions so paperclip user can run paperclipai
        NPM_GLOBAL=$(npm root -g 2>/dev/null || echo "/usr/lib/node_modules")
        if [[ -d "$NPM_GLOBAL/paperclipai" ]]; then
            chmod -R a+rX "$NPM_GLOBAL/paperclipai" 2>/dev/null || true
            # Fix the specific symlink permission issue with embedded-postgres
            find "$NPM_GLOBAL/paperclipai" -name "*.so*" -exec chmod a+r {} \; 2>/dev/null || true
            find "$NPM_GLOBAL/paperclipai" -type d -exec chmod a+rx {} \; 2>/dev/null || true
            # Allow symlink creation in the native lib dirs
            find "$NPM_GLOBAL/paperclipai" -path "*/native/lib" -type d -exec chmod a+rwx {} \; 2>/dev/null || true
            find "$NPM_GLOBAL/paperclipai" -path "*/native" -type d -exec chmod a+rwx {} \; 2>/dev/null || true
        fi

        # Copy hermes + pipx stuff to paperclip user
        if [[ -d "$HOME/.local/share/pipx" ]]; then
            cp -rn "$HOME/.local/share/pipx" "$PAPERCLIP_HOME/.local/share/" 2>/dev/null || true
        fi
        if [[ -f "$HOME/.local/bin/hermes" ]]; then
            cp -n "$HOME/.local/bin/hermes" "$PAPERCLIP_HOME/.local/bin/" 2>/dev/null || true
            cp -n "$HOME/.local/bin/hermes-agent" "$PAPERCLIP_HOME/.local/bin/" 2>/dev/null || true
            cp -n "$HOME/.local/bin/hermes-acp" "$PAPERCLIP_HOME/.local/bin/" 2>/dev/null || true
        fi

        # Copy hermes config
        if [[ -d "$HOME/.hermes" ]]; then
            cp -rn "$HOME/.hermes" "$PAPERCLIP_HOME/" 2>/dev/null || true
        fi

        # Move paperclip data dir to paperclip user's home
        INSTANCE_DIR="$PAPERCLIP_HOME/.paperclip/instances/default"
        CONFIG_FILE="$INSTANCE_DIR/config.json"
        mkdir -p "$INSTANCE_DIR/secrets" "$INSTANCE_DIR/logs" "$INSTANCE_DIR/data/storage" "$INSTANCE_DIR/data/backups" "$INSTANCE_DIR/db"

        # Copy existing paperclip data if it was in root's home
        if [[ -d "$HOME/.paperclip" ]] && [[ "$HOME" != "$PAPERCLIP_HOME" ]]; then
            cp -rn "$HOME/.paperclip/"* "$PAPERCLIP_HOME/.paperclip/" 2>/dev/null || true
        fi

        # Own everything
        chown -R paperclip:paperclip "$PAPERCLIP_HOME" 2>/dev/null || true

        ok "User" "'paperclip' system user ready"
    else
        PAPERCLIP_HOME="$HOME"
    fi

    # ── Write config (bind to 0.0.0.0, no createPostgresUser needed anymore) ──
    INSTANCE_DIR="$PAPERCLIP_HOME/.paperclip/instances/default"
    CONFIG_FILE="$INSTANCE_DIR/config.json"
    mkdir -p "$INSTANCE_DIR/secrets" "$INSTANCE_DIR/logs" "$INSTANCE_DIR/data/storage" "$INSTANCE_DIR/data/backups" "$INSTANCE_DIR/db"

    if [[ -f "$CONFIG_FILE" ]]; then
        node -e "
const fs = require('fs');
const p = '$CONFIG_FILE';
const c = JSON.parse(fs.readFileSync(p, 'utf8'));
c.server = c.server || {};
c.server.bind = 'custom';
c.server.host = '0.0.0.0';
c.server.customBindHost = '0.0.0.0';
c.server.deploymentMode = 'self_hosted';
c.server.exposure = 'private';
fs.writeFileSync(p, JSON.stringify(c, null, 2));
" 2>/dev/null
    else
        node -e "
const fs = require('fs');
fs.writeFileSync('$CONFIG_FILE', JSON.stringify({
  \"\\\$meta\": { version: 1, updatedAt: new Date().toISOString(), source: 'deepstack' },
  database: {
    mode: 'embedded-postgres',
    embeddedPostgresDataDir: '$INSTANCE_DIR/db',
    embeddedPostgresPort: 54329,
    backup: { enabled: true, intervalMinutes: 60, retentionDays: 30, dir: '$INSTANCE_DIR/data/backups' }
  },
  logging: { mode: 'file', logDir: '$INSTANCE_DIR/logs' },
  server: {
    deploymentMode: 'authenticated', exposure: 'private',
    bind: 'lan', host: '0.0.0.0', port: 3100,
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

    if [[ "$(whoami)" == "root" ]]; then
        chown -R paperclip:paperclip "$PAPERCLIP_HOME/.paperclip" 2>/dev/null || true
    fi

    ok "Config" "bound to 0.0.0.0:3100"

    # ── STEP C: Run onboard (setup only, no server start) ──
    msg "Running Paperclip onboard..."
    echo ""

    # Run onboard with a short timeout — it does setup then tries to start
    # the server (which we don't want yet). We kill it after config is created.
    if [[ "$(whoami)" == "root" ]]; then
        su - paperclip -c "export PATH=\"/usr/local/bin:/usr/bin:\$HOME/.local/bin:\$PATH\" && timeout 45 npx paperclipai onboard --yes" 2>&1 || true
    else
        timeout 45 npx paperclipai onboard --yes 2>&1 || true
    fi

    # Kill any server it started
    pkill -f "paperclipai" 2>/dev/null || true
    if command -v fuser &>/dev/null; then
        fuser -k 3100/tcp 2>/dev/null || true
    fi
    sleep 1

    # ── STEP D: Patch config for VPS access (onboard overwrites to local_trusted) ──
    # This MUST run after onboard because onboard always resets to local_trusted/loopback
    CONFIG_FILE="$PAPERCLIP_HOME/.paperclip/instances/default/config.json"
    if [[ -f "$CONFIG_FILE" ]]; then
        node -e "
const fs = require('fs');
const p = '$CONFIG_FILE';
const c = JSON.parse(fs.readFileSync(p, 'utf8'));
c.server = c.server || {};
c.server.deploymentMode = 'authenticated';
c.server.exposure = 'private';
c.server.bind = 'lan';
c.server.host = '0.0.0.0';
c.server.port = 3100;
fs.writeFileSync(p, JSON.stringify(c, null, 2));
" 2>/dev/null || true
        if [[ "$(whoami)" == "root" ]]; then
            chown -R paperclip:paperclip "$PAPERCLIP_HOME/.paperclip" 2>/dev/null || true
        fi
        ok "Network" "patched to authenticated + lan (0.0.0.0:3100)"

        # Auto-add server IP as allowed hostname
        SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || curl -sf ifconfig.me 2>/dev/null || true)
        if [[ -n "$SERVER_IP" ]]; then
            if [[ "$(whoami)" == "root" ]]; then
                su - paperclip -c "export PATH=\"/usr/local/bin:/usr/bin:\$HOME/.local/bin:\$PATH\" && npx paperclipai allowed-hostname $SERVER_IP" 2>&1 || true
            else
                npx paperclipai allowed-hostname "$SERVER_IP" 2>&1 || true
            fi
            ok "Allowed host" "$SERVER_IP"
        fi
    fi

    # ── STEP E: Verify config is valid ──
    echo ""
    msg "Verifying config..."
    if [[ "$(whoami)" == "root" ]]; then
        su - paperclip -c "export PATH=\"/usr/local/bin:/usr/bin:\$HOME/.local/bin:\$PATH\" && npx paperclipai doctor" 2>&1 || true
    else
        npx paperclipai doctor 2>&1 || true
    fi

    # ── STEP F: Create AI Agent ──
    echo ""
    msg "Assigning AI Agent to Paperclip..."
    
    if [[ "$(whoami)" == "root" ]]; then
        COMPANY_ID=$(su - paperclip -c "export PATH=\"/usr/local/bin:/usr/bin:\$HOME/.local/bin:\$PATH\" && npx paperclipai company list --json 2>/dev/null | node -e \"try { console.log(JSON.parse(require('fs').readFileSync(0))[0].id) } catch(e) {}\"" 2>/dev/null || echo "")
    else
        COMPANY_ID=$(npx paperclipai company list --json 2>/dev/null | node -e "try { console.log(JSON.parse(require('fs').readFileSync(0))[0].id) } catch(e) {}" 2>/dev/null || echo "")
    fi

    if [[ -n "$COMPANY_ID" ]]; then
        HERMES_BIN_PATH="$HOME/.local/bin/hermes"
        if [[ "$(whoami)" == "root" ]]; then
            HERMES_BIN_PATH="$PAPERCLIP_HOME/.local/bin/hermes"
        fi

        ENV_KEY=$(echo "${PROVIDER}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')_API_KEY
        
        PAYLOAD=$(cat <<EOF
{
  "name": "AI Assistant",
  "role": "general",
  "adapterType": "hermes_local",
  "adapterConfig": {
    "provider": "${PROVIDER}",
    "model": "${MODEL}",
    "envVars": {
      "${ENV_KEY}": "${API_KEY}"
    },
    "hermesCommand": "${HERMES_BIN_PATH}",
    "dangerouslySkipPermissions": true
  },
  "runtimeConfig": {
    "heartbeat": {
      "enabled": true,
      "wakeOnDemand": true
    }
  },
  "permissions": {
    "canCreateAgents": true
  }
}
EOF
)
        
        if [[ "$(whoami)" == "root" ]]; then
            TMP_PAYLOAD=$(mktemp)
            echo "$PAYLOAD" > "$TMP_PAYLOAD"
            chown paperclip:paperclip "$TMP_PAYLOAD"
            su - paperclip -c "export PATH=\"/usr/local/bin:/usr/bin:\$HOME/.local/bin:\$PATH\" && npx paperclipai agent create -C \"$COMPANY_ID\" --payload-json \"\$(cat $TMP_PAYLOAD)\"" &>/dev/null || true
            rm -f "$TMP_PAYLOAD"
        else
            npx paperclipai agent create -C "$COMPANY_ID" --payload-json "$PAYLOAD" &>/dev/null || true
        fi
        
        ok "Agent" "AI successfully assigned and ready"
    else
        warn "Agent" "Could not assign AI (Company ID missing)"
    fi

    echo ""
    line
    echo ""

    if [[ -f "$CONFIG_FILE" ]]; then
        ok "Paperclip" "onboarded at $PAPERCLIP_HOME/.paperclip"
    else
        fail "Paperclip onboard failed"
        printf "  ${GRAY}Try manually: npx paperclipai onboard --yes${RST}\n"
    fi

fi  # end SKIP_INSTALL

# ══════════════════════════════════════════════════════════════
#  PM2 — Process manager for background running
# ══════════════════════════════════════════════════════════════
echo ""
line
echo ""
printf "  ${BOLD}${WHITE}Setting up PM2 (process manager)...${RST}\n\n"

if ! check_cmd pm2; then
    msg "Installing PM2..."
    npm install -g pm2 &>/dev/null &
    spinner $! "Installing PM2..."
    printf "\r"
fi
check_cmd pm2 && ok "PM2" "$(pm2 --version 2>/dev/null)" || fail "PM2" "install failed"

# Stop any existing deepstack pm2 process
pm2 delete deepstack 2>/dev/null || true

# Determine who runs the server
PAPERCLIP_HOME="$HOME"
RUN_USER=""
if [[ "$(whoami)" == "root" ]] && id -u paperclip &>/dev/null; then
    PAPERCLIP_HOME=$(eval echo ~paperclip)
    RUN_USER="paperclip"
fi

# Create PM2 ecosystem file
PM2_CONFIG="$HOME/.deepstack_pm2.json"
if [[ -n "$RUN_USER" ]]; then
    cat > "$PM2_CONFIG" <<PMEOF
{
  "apps": [{
    "name": "deepstack",
    "script": "npx",
    "args": "paperclipai run",
    "cwd": "$PAPERCLIP_HOME",
    "user": "$RUN_USER",
    "autorestart": true,
    "max_restarts": 10,
    "restart_delay": 5000,
    "env": {
      "PATH": "/usr/local/bin:/usr/bin:$PAPERCLIP_HOME/.local/bin",
      "HOME": "$PAPERCLIP_HOME",
      "PAPERCLIP_HOME": "$PAPERCLIP_HOME/.paperclip"
    }
  }]
}
PMEOF
else
    cat > "$PM2_CONFIG" <<PMEOF
{
  "apps": [{
    "name": "deepstack",
    "script": "npx",
    "args": "paperclipai run",
    "autorestart": true,
    "max_restarts": 10,
    "restart_delay": 5000
  }]
}
PMEOF
fi

# Start with PM2
msg "Starting DeepStack via PM2..."
pm2 start "$PM2_CONFIG" 2>/dev/null
sleep 3

# Check if it's running
if pm2 list 2>/dev/null | grep -q "deepstack.*online"; then
    ok "PM2" "deepstack running in background"
else
    warn "PM2" "deepstack may still be starting — check: pm2 logs deepstack"
fi

# Auto-start PM2 on boot
pm2 save 2>/dev/null || true
pm2 startup 2>/dev/null | grep "sudo" | bash 2>/dev/null || pm2 startup 2>/dev/null || true

ok "PM2" "auto-start on boot enabled"

# Wait for server to be ready
msg "Waiting for server to respond..."
WAITED=0
while ! curl -sf http://127.0.0.1:3100/api/health &>/dev/null; do
    sleep 2
    WAITED=$((WAITED + 2))
    if [[ $WAITED -ge 30 ]]; then
        warn "Server" "still starting — check: pm2 logs deepstack"
        break
    fi
done
if curl -sf http://127.0.0.1:3100/api/health &>/dev/null; then
    ok "Server" "responding on port 3100"
fi

# ── Launcher script ──────────────────────────────────────────
LAUNCHER="$HOME/.local/bin/deepstack"
mkdir -p "$HOME/.local/bin"

cat > "$LAUNCHER" << 'LAUNCHER_EOF'
#!/usr/bin/env bash
set -euo pipefail
RD="\033[38;5;196m" G="\033[38;5;114m" W="\033[38;5;255m" D="\033[2m" B="\033[1m" R="\033[0m" GY="\033[38;5;245m" AC="\033[38;5;203m"

# If running as root, re-exec as the paperclip user
run_as_paperclip() {
    if [[ "$(whoami)" == "root" ]] && id -u paperclip &>/dev/null; then
        su - paperclip -c "export PATH=\"/usr/local/bin:/usr/bin:\$HOME/.local/bin:\$PATH\" && $*"
    else
        eval "$*"
    fi
}

case "${1:-help}" in
    start)
        printf "\n  ${RD}▸${R} Starting DeepStack...\n\n"
        if pm2 list 2>/dev/null | grep -q "deepstack.*online"; then
            printf "  ${G}●${R} Already running\n\n"
        elif [[ -f "$HOME/.deepstack_pm2.json" ]]; then
            pm2 start "$HOME/.deepstack_pm2.json" 2>/dev/null
            sleep 3
            pm2 list 2>/dev/null | grep -q "deepstack.*online" \
                && printf "  ${G}✓${R} Started via PM2 (background)\n" \
                || printf "  ${GY}○${R} Starting... check: pm2 logs deepstack\n"
        else
            run_as_paperclip "npx paperclipai run"
        fi
        echo ""
        ;;
    stop)
        pm2 stop deepstack 2>/dev/null && printf "  ${G}✓${R} Stopped\n" || \
        (pkill -f "paperclipai" 2>/dev/null && printf "  ${G}✓${R} Stopped\n" || printf "  ${GY}Not running${R}\n")
        ;;
    restart)
        pm2 restart deepstack 2>/dev/null && printf "  ${G}✓${R} Restarted\n" || printf "  ${GY}Not running${R}\n"
        ;;
    status)
        echo ""
        printf "  ${RD}${B}DEEPSTACK V1${R} ${D}— Status${R}\n\n"
        if pm2 list 2>/dev/null | grep -q "deepstack.*online"; then
            printf "  ${G}●${R} Paperclip    ${G}running${R} ${D}(PM2, port 3100)${R}\n"
        elif curl -sf http://127.0.0.1:3100/api/health &>/dev/null; then
            printf "  ${G}●${R} Paperclip    ${G}running${R} ${D}(port 3100)${R}\n"
        else
            printf "  ${GY}○${R} Paperclip    ${GY}stopped${R}\n"
        fi
        H=$(which hermes 2>/dev/null || echo "$HOME/.local/bin/hermes")
        [[ -x "$H" ]] \
            && printf "  ${G}●${R} Hermes       ${G}installed${R}\n" \
            || printf "  ${GY}○${R} Hermes       ${GY}not found${R}\n"
        echo ""
        pm2 list 2>/dev/null || true
        echo ""
        ;;
    config)  run_as_paperclip "hermes config show 2>/dev/null" || true ;;
    doctor)  run_as_paperclip "npx paperclipai doctor" ;;
    logs)    pm2 logs deepstack --lines 50 2>/dev/null || printf "  ${GY}No logs found${R}\n" ;;
    restart-fresh)
        printf "\n  ${RD}▸${R} Fresh restart (new database)...\n"
        pm2 stop deepstack 2>/dev/null || true
        pkill -f "paperclipai" 2>/dev/null || true
        PH=$(eval echo ~paperclip 2>/dev/null || echo "$HOME")
        rm -rf "$PH/.paperclip/instances/default/db"
        mkdir -p "$PH/.paperclip/instances/default/db"
        [[ "$(whoami)" == "root" ]] && chown -R paperclip:paperclip "$PH/.paperclip" 2>/dev/null || true
        pm2 restart deepstack 2>/dev/null && printf "  ${G}✓${R} Fresh restart done\n" || printf "  ${GY}○${R} Start with: deepstack start\n"
        echo ""
        ;;
    update)
        printf "\n  ${RD}▸${R} Updating DeepStack...\n\n"
        TMPFILE=$(mktemp)
        curl -fsSL https://raw.githubusercontent.com/yeaminlabs/paperstack/main/install.sh -o "$TMPFILE" 2>/dev/null
        if [[ -s "$TMPFILE" ]]; then
            SELF=$(which deepstack 2>/dev/null || echo "$HOME/.local/bin/deepstack")
            # Extract the launcher from the install script and overwrite
            sed -n '/^cat > "\$LAUNCHER" << '\''LAUNCHER_EOF'\''$/,/^LAUNCHER_EOF$/p' "$TMPFILE" | sed '1d;$d' > "${SELF}.new" 2>/dev/null
            if [[ -s "${SELF}.new" ]]; then
                mv "${SELF}.new" "$SELF"
                chmod +x "$SELF"
                printf "  ${G}✓${R} DeepStack CLI updated\n"
            else
                rm -f "${SELF}.new"
                printf "  ${G}✓${R} CLI already up to date\n"
            fi
            # Update Paperclip
            printf "  ${RD}▸${R} Updating Paperclip...\n"
            npm update -g paperclipai 2>/dev/null && printf "  ${G}✓${R} Paperclip updated\n" || printf "  ${GY}·${R} Paperclip already latest\n"
            # Update Hermes
            printf "  ${RD}▸${R} Updating Hermes Agent...\n"
            run_as_paperclip "pipx upgrade hermes-agent 2>/dev/null" && printf "  ${G}✓${R} Hermes updated\n" || printf "  ${GY}·${R} Hermes already latest\n"
        else
            printf "  ${RD}✗${R} Failed to fetch update from GitHub\n"
        fi
        rm -f "$TMPFILE"
        echo ""
        ;;
    allow-host)
        shift
        if [[ -z "${1:-}" ]]; then
            printf "\n  ${RD}Usage:${R} deepstack allow-host <hostname-or-ip>\n"
            printf "  ${D}Example: deepstack allow-host 46.62.205.66${R}\n\n"
            exit 1
        fi
        run_as_paperclip "npx paperclipai allowed-hostname $1"
        printf "  ${G}✓${R} Allowed hostname: ${AC}$1${R}\n"
        ;;
    hermes)  shift; run_as_paperclip "hermes $*" ;;
    ui)
        IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")
        U="http://${IP}:3100"
        command -v xdg-open &>/dev/null && xdg-open "$U" || \
        command -v open &>/dev/null && open "$U" || \
        printf "  Open: ${AC}%s${R}\n" "$U"
        ;;
    *)
        echo ""
        printf "  ${RD}${B}DEEPSTACK V1${R} ${D}— SNBDHOST${R}\n\n"
        printf "    ${AC}start${R}         Start server (PM2 background)\n"
        printf "    ${AC}stop${R}          Stop server\n"
        printf "    ${AC}restart${R}       Restart server\n"
        printf "    ${AC}restart-fresh${R} Restart with fresh database\n"
        printf "    ${AC}status${R}        Check status + PM2 info\n"
        printf "    ${AC}logs${R}          Show server logs\n"
        printf "    ${AC}update${R}        Update from GitHub + packages\n"
        printf "    ${AC}allow-host${R}    Allow a hostname/IP for access\n"
        printf "    ${AC}config${R}        Show Hermes config\n"
        printf "    ${AC}doctor${R}        Run diagnostics\n"
        printf "    ${AC}hermes${R}        Run Hermes directly\n"
        printf "    ${AC}ui${R}            Open web UI\n"
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

SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || curl -sf ifconfig.me 2>/dev/null || echo "YOUR-SERVER-IP")

printf "    ${GREEN}Server is running in background via PM2${RST}\n"
printf "    ${GREEN}Auto-restarts on crash + survives reboot${RST}\n\n"

printf "    ${ACCENT}1.${RST} ${WHITE}Open the web dashboard (use http, NOT https):${RST}\n"
printf "       ${ULINE}${ACCENT}http://${SERVER_IP}:3100${RST}\n\n"
printf "       ${RED}⚠  Use http:// not https:// — there is no SSL${RST}\n\n"

printf "    ${ACCENT}2.${RST} ${WHITE}Commands:${RST}\n"
printf "       ${GREEN}deepstack status${RST}     ${DIM}Check status${RST}\n"
printf "       ${GREEN}deepstack logs${RST}       ${DIM}View logs${RST}\n"
printf "       ${GREEN}deepstack restart${RST}    ${DIM}Restart server${RST}\n"
printf "       ${GREEN}deepstack stop${RST}       ${DIM}Stop server${RST}\n"
printf "       ${GREEN}deepstack config${RST}     ${DIM}View Hermes config${RST}\n"
printf "       ${GREEN}deepstack update${RST}     ${DIM}Update from GitHub${RST}\n"

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
rm -f "$HOME/.deepstack_install_state" 2>/dev/null || true
rm -f "$HOME/.deepstack/install_config" 2>/dev/null || true
