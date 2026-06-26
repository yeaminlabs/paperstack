<p align="center">
  <img src="https://img.shields.io/badge/PaperStack-v1.0.0-cyan?style=for-the-badge&labelColor=0d1117" />
  <img src="https://img.shields.io/badge/Paperclip-AI_Platform-purple?style=for-the-badge&labelColor=0d1117" />
  <img src="https://img.shields.io/badge/Hermes-Agent-blue?style=for-the-badge&labelColor=0d1117" />
  <img src="https://img.shields.io/badge/DeepSeek-LLM-green?style=for-the-badge&labelColor=0d1117" />
</p>

<h1 align="center">⚡ PaperStack</h1>
<p align="center"><strong>One command. Full AI company infrastructure.</strong></p>
<p align="center">
  <em>Paperclip + Hermes Agent + DeepSeek — deployed to any VPS in 60 seconds.</em>
</p>

---

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/yeaminlabs/paperstack/main/install.sh | bash
```

Or with environment variables (non-interactive):

```bash
export PAPERSTACK_PROVIDER=deepseek
export PAPERSTACK_API_KEY=sk-your-key-here
export PAPERSTACK_MODEL=deepseek-v4-flash
curl -fsSL https://raw.githubusercontent.com/yeaminlabs/paperstack/main/install.sh | bash
```

## What Gets Installed

| Component | Purpose |
|-----------|---------|
| **Node.js** | Runtime for Paperclip |
| **Python 3** | Runtime for Hermes Agent |
| **pipx** | Python package manager |
| **Paperclip** | AI company orchestration platform |
| **Hermes Agent** | Multi-provider AI agent (Nous Research) |
| **paperstack CLI** | Unified launcher for everything |

## Supported Providers

| Provider | Models |
|----------|--------|
| **DeepSeek** | deepseek-v4-flash, deepseek-r1, deepseek-chat, deepseek-coder |
| **Anthropic** | claude-sonnet-4-6, claude-opus-4-8, claude-haiku-4-5 |
| **OpenAI** | gpt-4.1, gpt-4.1-mini, o4-mini |
| **MiniMax** | MiniMax-M2, MiniMax-M1 |
| **Google** | gemini-2.5-pro, gemini-2.5-flash |
| **OpenRouter** | auto (routes to best available) |

## Usage

```bash
# Start everything
paperstack start

# Check status
paperstack status

# Open web UI
paperstack ui

# Run Hermes directly
paperstack hermes

# View config
paperstack config

# Run diagnostics
paperstack doctor
```

## VPS Quick Deploy

```bash
# SSH into your VPS
ssh user@your-vps-ip

# One-liner install with DeepSeek
PAPERSTACK_PROVIDER=deepseek \
PAPERSTACK_API_KEY=sk-your-key \
PAPERSTACK_MODEL=deepseek-v4-flash \
bash <(curl -fsSL https://raw.githubusercontent.com/yeaminlabs/paperstack/main/install.sh)
```

### Supported Platforms

- Ubuntu 20.04+ / Debian 11+
- CentOS 8+ / RHEL 8+ / Fedora
- Alpine Linux 3.15+
- macOS 12+ (Monterey and later)
- ARM64 and x86_64

## Architecture

```
┌─────────────────────────────────────────┐
│              PaperStack                 │
├─────────────────────────────────────────┤
│                                         │
│   ┌──────────┐     ┌────────────────┐   │
│   │ Paperclip│────▶│  Hermes Agent  │   │
│   │ (Web UI) │     │  (AI Runtime)  │   │
│   └──────────┘     └───────┬────────┘   │
│       :3100                │            │
│                    ┌───────▼────────┐   │
│                    │   LLM Provider │   │
│                    │  (DeepSeek/..) │   │
│                    └────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

## License

MIT

---

<p align="center">
  <sub>Built with 🧠 by <a href="https://github.com/yeaminlabs">yeaminlabs</a></sub>
</p>
