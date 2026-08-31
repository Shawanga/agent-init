# agent-init

Interactive scaffolder for AI coding harnesses. Creates project files and folders for **Claude Code**, **Codex**, or both. Project existing files are left unchanged.

## Install

### Homebrew

```bash
brew tap shawanga/agent-init
brew install agent-init
```

### Manual

```bash
mkdir -p ~/.local/bin
cp agent-init.sh ~/.local/bin/agent-init
chmod +x ~/.local/bin/agent-init
```

If `~/.local/bin` is not on your PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Then run `agent-init` from any directory.

## Usage

```bash
agent-init .
agent-init /your/directory/here
```

Choose where to create the harness files. Use `.` for the current directory and select as prompted:

1. **Harness** — Claude Code, Codex, or both
2. **Components** — comma-separated numbers, `7` for everything, or `8` for a custom directory

## Components

| # | Component | Claude Code | Codex |
|---|-----------|-------------|-------|
| 1 | Skills directory | `.claude/skills/` | `.agents/skills/` |
| 2 | Agents directory | `.claude/agents/` | `.codex/agents/` |
| 3 | MCP | `.mcp.json` | `.codex/config.toml` |
| 4 | Settings | `.claude/settings.json` | `.codex/config.toml` |
| 5 | Project instructions | `CLAUDE.md` | `AGENTS.md` |
| 6 | Commands | `.claude/commands/` | `.codex/commands/` |
| 7 | Everything | all of the above | all of the above |
| 8 | Custom directory | user-specified path | user-specified path |

## License

[Apache License 2.0](LICENSE)
