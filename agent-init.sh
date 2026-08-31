#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# agent-init
#
# Interactive project scaffolder for AI coding harnesses.
#
# Supports:
#   - Claude Code
#   - Codex
# -----------------------------------------------------------------------------

VERSION="1.0.0"

trim() {
    echo "$1" | sed \
        -e 's/^[[:space:]]*//' \
        -e 's/[[:space:]]*$//'
}

is_yes() {
    local v
    v="$(trim "${1:-}")"
    [[ "$v" =~ ^[yY]([eE][sS])?$ ]]
}

title_from_slug() {
    echo "$1" | awk -F- '{
        for (i = 1; i <= NF; i++) {
            $i = toupper(substr($i, 1, 1)) substr($i, 2)
        }
        print
    }' OFS=' '
}

selected() {
    local wanted="$1"
    local item

    IFS=',' read -r -a items <<< "$COMPONENT_SELECTION"

    for item in "${items[@]}"; do
        item="$(trim "$item")"

        if [[ "$item" == "$wanted" ]] || { [[ "$item" == "7" ]] && [[ "$wanted" != "8" ]]; }; then
            return 0
        fi
    done

    return 1
}

ensure_dir() {
    local dir="$1"

    if [[ -d "$dir" ]]; then
        echo "  exists  $dir"
        return 0
    fi

    mkdir -p "$dir"
    echo "  created $dir"
}

write_new_file() {
    local file="$1"

    if [[ -e "$file" ]]; then
        cat >/dev/null
        echo "  exists  $file"
        return 0
    fi

    mkdir -p "$(dirname "$file")"
    cat > "$file"
    echo "  created $file"
}

support_dir_selected() {
    local wanted="$1"
    local item

    IFS=',' read -r -a items <<< "$SUPPORT_DIR_SELECTION"

    for item in "${items[@]}"; do
        item="$(trim "$item")"
        if [[ "$item" == "$wanted" || "$item" == "4" ]]; then
            return 0
        fi
    done

    return 1
}

ensure_skill_support_dirs() {
    local skill_dir="$1"
    local dirs_to_create=()
    local all_exist=1
    local sub

    support_dir_selected "1" && dirs_to_create+=("scripts")
    support_dir_selected "2" && dirs_to_create+=("references")
    support_dir_selected "3" && dirs_to_create+=("assets")

    [[ ${#dirs_to_create[@]} -eq 0 ]] && return 0

    for sub in "${dirs_to_create[@]}"; do
        if [[ ! -d "$skill_dir/$sub" ]]; then
            all_exist=0
        fi
    done

    for sub in "${dirs_to_create[@]}"; do
        mkdir -p "$skill_dir/$sub"
    done

    local dir_list
    dir_list=$(IFS=,; echo "${dirs_to_create[*]}")

    if [[ "$all_exist" -eq 1 ]]; then
        echo "  exists  $skill_dir/{$dir_list}"
    else
        echo "  created $skill_dir/{$dir_list}"
    fi
}

add_support_dirs_for_harness() {
    local harness="$1"
    local skills_root
    local skill_dir
    local found=0

    case "$harness" in
        claude)
            skills_root=".claude/skills"
            ;;
        codex)
            skills_root=".agents/skills"
            ;;
    esac

    [[ -d "$skills_root" ]] || return 0

    for skill_dir in "$skills_root"/*/; do
        [[ -d "$skill_dir" ]] || continue
        found=1
        ensure_skill_support_dirs "${skill_dir%/}"
    done

    if [[ "$found" -eq 0 ]]; then
        echo "  note: no skills found under $skills_root"
    fi
}

create_skill_definition() {
    local skills_root="$1"
    local name="$2"
    local skill_dir="$skills_root/$name"
    local title
    title="$(title_from_slug "$name")"

    mkdir -p "$skill_dir"

    write_new_file "$skill_dir/SKILL.md" <<EOF
---
name: $name
description: <What this skill does and when to use it>
---

# $title

<Write the instructions this skill should follow.>
EOF
}

create_agent_definition() {
    local agents_root="$1"
    local name="$2"
    local title
    title="$(title_from_slug "$name")"

    mkdir -p "$agents_root"

    write_new_file "$agents_root/$name.md" <<EOF
---
name: $name
description: <When to use this agent>
---

# $title

<Write the system prompt for this agent.>
EOF
}

create_skill_definitions_for_harness() {
    local harness="$1"
    local skills_root
    local name

    [[ ${#SKILL_NAMES[@]} -eq 0 ]] && return 0

    case "$harness" in
        claude)
            skills_root=".claude/skills"
            ;;
        codex)
            skills_root=".agents/skills"
            ;;
    esac

    mkdir -p "$skills_root"

    for name in "${SKILL_NAMES[@]}"; do
        create_skill_definition "$skills_root" "$name"
    done
}

create_agent_definitions_for_harness() {
    local harness="$1"
    local agents_root
    local name

    [[ ${#AGENT_NAMES[@]} -eq 0 ]] && return 0

    case "$harness" in
        claude)
            agents_root=".claude/agents"
            ;;
        codex)
            agents_root=".codex/agents"
            ;;
    esac

    mkdir -p "$agents_root"

    for name in "${AGENT_NAMES[@]}"; do
        create_agent_definition "$agents_root" "$name"
    done
}

create_claude_structure() {
    echo
    echo "Setting up Claude Code..."

    mkdir -p ".claude"

    if selected "1"; then
        ensure_dir ".claude/skills"
    fi

    if selected "2" || [[ ${#AGENT_NAMES[@]} -gt 0 ]]; then
        ensure_dir ".claude/agents"
    fi

    if selected "3"; then
        write_new_file ".mcp.json" <<'EOF'
{
  "mcpServers": {}
}
EOF
    fi

    if selected "4"; then
        write_new_file ".claude/settings.json" <<'EOF'
{
  "permissions": {
    "allow": [],
    "ask": [],
    "deny": []
  }
}
EOF
    fi

    if selected "5"; then
        write_new_file "CLAUDE.md" <<'EOF'
# Project Instructions

## Project

<Describe the project.>>

## Development Guidelines

- <Guideline>

## Architecture

- <Overview>

## Security

- <Secrets, permissions, and files the agent must not touch>
EOF
    fi

    if selected "6"; then
        ensure_dir ".claude/commands"
        write_new_file ".claude/commands/example.md" <<'EOF'
---
description: <What this command does>
argument-hint: "[optional args]"
---

<Write the prompt this command should run.>

Use $ARGUMENTS for any user-supplied input.
EOF
    fi
}

create_codex_structure() {
    echo
    echo "Setting up Codex..."

    mkdir -p ".codex"

    if selected "1"; then
        ensure_dir ".agents/skills"
    fi

    if selected "2" || [[ ${#AGENT_NAMES[@]} -gt 0 ]]; then
        ensure_dir ".codex/agents"
    fi

    if selected "3" || selected "4"; then
        write_new_file ".codex/config.toml" <<'EOF'
# Project-scoped Codex configuration.

# model = "gpt-5.3-codex"
# approval_policy = "on-request"
# sandbox_mode = "workspace-write"

# Example MCP server:
#
# [mcp_servers.example]
# command = "npx"
# args = ["-y", "example-mcp-server"]
EOF
    fi

    if selected "5"; then
        write_new_file "AGENTS.md" <<'EOF'
# Project Instructions

## Project

<Describe the project.>

## Commands

- build: <command>
- test: <command>
- lint: <command>

## Development Guidelines

- <Guideline>

## Architecture

- <Overview>

## Security

- <Secrets, permissions, and files the agent must not touch>
EOF
    fi

    if selected "6"; then
        ensure_dir ".codex/commands"
        write_new_file ".codex/commands/example.md" <<'EOF'
---
description: <What this command does>
argument-hint: "[optional args]"
---

<Write the prompt this command should run.>

Use $ARGUMENTS for any user-supplied input.
EOF
    fi
}

# -----------------------------------------------------------------------------
# Usage
# -----------------------------------------------------------------------------

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: agent-init [directory]"
    echo
    echo "Create Claude Code and/or Codex harness files in the given directory."
    echo "Omit directory or pass . for the current directory."
    echo "Existing files are left unchanged."
    exit 0
fi

if [[ "${1:-}" == "-v" || "${1:-}" == "--version" ]]; then
    echo "agent-init $VERSION"
    exit 0
fi

if [[ $# -gt 1 ]]; then
    echo "Usage: agent-init [directory]"
    exit 1
fi

# -----------------------------------------------------------------------------
# Project
# -----------------------------------------------------------------------------

echo
echo "AI Agent Project Initializer"
echo "============================"
echo

PROJECT_DIR="${1:-.}"

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

PROJECT_ROOT="$(pwd)"

echo
echo "Project: $PROJECT_ROOT"

# -----------------------------------------------------------------------------
# Harness
# -----------------------------------------------------------------------------

echo
echo "Select harness:"
echo
echo "  1) Claude Code"
echo "  2) Codex"
echo "  3) Both"
echo

read -rp "Harness [1-3]: " HARNESS_SELECTION

case "$HARNESS_SELECTION" in
    1)
        HARNESSES="claude"
        ;;
    2)
        HARNESSES="codex"
        ;;
    3)
        HARNESSES="claude codex"
        ;;
    *)
        echo "Invalid harness selection."
        exit 1
        ;;
esac

# -----------------------------------------------------------------------------
# Components
# -----------------------------------------------------------------------------

echo
echo "What should be initialized?"
echo
echo "  1) Skills directory"
echo "  2) Agents directory"
echo "  3) MCP configuration"
echo "  4) Harness settings / config"
echo "  5) Project instruction file"
echo "  6) Commands"
echo "  7) Everything"
echo "  8) Custom directory"
echo
echo "Enter one or more numbers separated by commas."
echo

read -rp "Components: " COMPONENT_SELECTION

HAS_VALID_COMPONENT=0
IFS=',' read -r -a COMPONENT_ITEMS <<< "$COMPONENT_SELECTION"

for item in "${COMPONENT_ITEMS[@]}"; do
    item="$(trim "$item")"
    if [[ "$item" =~ ^[1-8]$ ]]; then
        HAS_VALID_COMPONENT=1
        break
    fi
done

if [[ "$HAS_VALID_COMPONENT" -eq 0 ]]; then
    echo "Invalid component selection."
    exit 1
fi

# -----------------------------------------------------------------------------
# Custom directory
# -----------------------------------------------------------------------------

CUSTOM_DIR=""

if selected "8"; then
    echo
    read -rp "Custom directory path: " CUSTOM_DIR

    if [[ -z "$CUSTOM_DIR" ]]; then
        echo "No directory specified."
        exit 1
    fi
fi

# -----------------------------------------------------------------------------
# Skill and agent definitions
# -----------------------------------------------------------------------------

SKILL_NAMES=()
AGENT_NAMES=()
SUPPORT_DIR_SELECTION=""

if selected "1"; then
    echo
    read -rp "Create skill definitions now? [y/N]: " CREATE_SKILLS_REPLY

    if is_yes "$CREATE_SKILLS_REPLY"; then
        read -rp "Skill names, comma-separated: " SKILL_NAMES_RAW

        IFS=',' read -r -a SKILL_NAME_ITEMS <<< "$SKILL_NAMES_RAW"
        for name in "${SKILL_NAME_ITEMS[@]}"; do
            name="$(trim "$name")"
            [[ -n "$name" ]] && SKILL_NAMES+=("$name")
        done

        if [[ ${#SKILL_NAMES[@]} -eq 0 ]]; then
            echo "No skill names provided."
        fi
    fi

    echo
    read -rp "Create scripts/references/assets inside each skill? [y/N]: " SUPPORT_DIRS_REPLY

    if is_yes "$SUPPORT_DIRS_REPLY"; then
        SUPPORT_DIR_SELECTION="4"
    fi
fi

if selected "2"; then
    echo
    read -rp "Create agent definitions now? [y/N]: " CREATE_AGENTS_REPLY

    if is_yes "$CREATE_AGENTS_REPLY"; then
        read -rp "Agent names, comma-separated: " AGENT_NAMES_RAW

        IFS=',' read -r -a AGENT_NAME_ITEMS <<< "$AGENT_NAMES_RAW"
        for name in "${AGENT_NAME_ITEMS[@]}"; do
            name="$(trim "$name")"
            [[ -n "$name" ]] && AGENT_NAMES+=("$name")
        done

        if [[ ${#AGENT_NAMES[@]} -eq 0 ]]; then
            echo "No agent names provided."
        fi
    fi
fi

# -----------------------------------------------------------------------------
# Build base structure
# -----------------------------------------------------------------------------

for harness in $HARNESSES; do
    case "$harness" in
        claude)
            create_claude_structure
            ;;
        codex)
            create_codex_structure
            ;;
    esac
done

# -----------------------------------------------------------------------------
# Skill definitions
# -----------------------------------------------------------------------------

if [[ ${#SKILL_NAMES[@]} -gt 0 ]]; then
    for harness in $HARNESSES; do
        create_skill_definitions_for_harness "$harness"
    done
fi

# -----------------------------------------------------------------------------
# Skill support dirs
# -----------------------------------------------------------------------------

if selected "1" && [[ -n "$SUPPORT_DIR_SELECTION" ]]; then
    for harness in $HARNESSES; do
        add_support_dirs_for_harness "$harness"
    done
fi

# -----------------------------------------------------------------------------
# Agent definitions
# -----------------------------------------------------------------------------

if [[ ${#AGENT_NAMES[@]} -gt 0 ]]; then
    for harness in $HARNESSES; do
        create_agent_definitions_for_harness "$harness"
    done
fi

# -----------------------------------------------------------------------------
# Custom directory
# -----------------------------------------------------------------------------

if selected "8" && [[ -n "$CUSTOM_DIR" ]]; then
    ensure_dir "$CUSTOM_DIR"
fi

# -----------------------------------------------------------------------------
# Result
# -----------------------------------------------------------------------------

echo
echo "Project initialized."
echo
echo "Structure:"
echo

find . \
    -maxdepth 4 \
    ! -path './.git/*' \
    ! -path './node_modules/*' \
    | sort

echo
echo "Done."
echo
