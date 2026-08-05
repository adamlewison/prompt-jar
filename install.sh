#!/usr/bin/env bash
# Installs prompt-jar as global Claude Code slash commands.
#
# Usage:
#   ./install.sh                                                   (from a local clone)
#   curl -fsSL https://raw.githubusercontent.com/adamlewison/prompt-jar/main/install.sh | bash   (from anywhere)
#
# Either way, every prompt in prompts/*.md becomes a /<prompt-name> slash
# command available in any Claude Code session, in any project.

set -euo pipefail

REPO_URL="https://github.com/adamlewison/prompt-jar.git"
CLONE_DIR="$HOME/.prompt-jar"
COMMANDS_DIR="$HOME/.claude/commands"

# Figure out where the prompts live: a local checkout if we're running from
# one, otherwise clone (or update) a dedicated copy under $HOME.
script_dir=""
if [ -n "${BASH_SOURCE:-}" ]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
fi

if [ -n "$script_dir" ] && [ -d "$script_dir/prompts" ]; then
  SOURCE_DIR="$script_dir/prompts"
else
  if [ -d "$CLONE_DIR/.git" ]; then
    echo "Updating existing prompt-jar checkout at $CLONE_DIR..."
    git -C "$CLONE_DIR" pull --quiet --ff-only
  else
    echo "Cloning prompt-jar to $CLONE_DIR..."
    git clone --quiet "$REPO_URL" "$CLONE_DIR"
  fi
  SOURCE_DIR="$CLONE_DIR/prompts"
fi

mkdir -p "$COMMANDS_DIR"

installed=()
skipped=()

for prompt in "$SOURCE_DIR"/*.md; do
  name="$(basename "$prompt")"
  [ "$name" = "TEMPLATE.md" ] && continue

  target="$COMMANDS_DIR/$name"

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    skipped+=("$name")
    continue
  fi

  ln -sf "$prompt" "$target"
  installed+=("${name%.md}")
done

echo ""
echo "prompt jar installed."
if [ "${#installed[@]}" -gt 0 ]; then
  echo ""
  echo "Available in any Claude Code session:"
  for cmd in "${installed[@]}"; do
    echo "  /$cmd"
  done
fi
if [ "${#skipped[@]}" -gt 0 ]; then
  echo ""
  echo "Skipped (a non-symlink file already exists at these names in $COMMANDS_DIR):"
  for name in "${skipped[@]}"; do
    echo "  $name"
  done
fi
echo ""
echo "Symlinked from: $SOURCE_DIR"
echo "Start a new Claude Code session for the commands to show up."
