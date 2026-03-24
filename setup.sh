#!/usr/bin/env bash
set -e

DOCTO_DIR="$HOME/Documents/projects/docto"
PROJECTS_DIR="$HOME/Documents/projects"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Docto Claude Setup ==="
echo ""

# 1. Ensure docto/ parent directory exists
mkdir -p "$DOCTO_DIR"

# 2. Move or clone each repo into docto/
REPOS=("docto-api" "docto-app" "docto-nextjs")
REPO_URLS=(
  "git@github.com:jonnyf007/docto-api.git"
  "git@github.com:jonnyf007/docto-app.git"
  "git@github.com:jonnyf007/docto-nextjs.git"
)

for i in "${!REPOS[@]}"; do
  REPO="${REPOS[$i]}"
  URL="${REPO_URLS[$i]}"
  TARGET="$DOCTO_DIR/$REPO"
  OLD_PATH="$PROJECTS_DIR/$REPO"

  if [ -d "$TARGET" ]; then
    echo "  ✓ $REPO already at $TARGET"
  elif [ -d "$OLD_PATH" ]; then
    echo "  → Moving $REPO from $PROJECTS_DIR/ to $DOCTO_DIR/"
    mv "$OLD_PATH" "$TARGET"
    echo "  ✓ Moved $REPO"
  else
    echo "  ? $REPO not found at $OLD_PATH"
    read -p "    Clone $REPO from GitHub? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      git clone "$URL" "$TARGET"
      echo "  ✓ Cloned $REPO"
    else
      echo "  ⚠ Skipped $REPO — some context may be missing"
    fi
  fi
done

# 3. Symlink docto-claude/CLAUDE.md → docto/CLAUDE.md
SYMLINK_TARGET="$DOCTO_DIR/CLAUDE.md"
SYMLINK_SOURCE="$SCRIPT_DIR/CLAUDE.md"

if [ -L "$SYMLINK_TARGET" ]; then
  echo "  ✓ $SYMLINK_TARGET symlink already exists"
elif [ -f "$SYMLINK_TARGET" ]; then
  echo "  ⚠ $SYMLINK_TARGET is a regular file — replacing with symlink"
  rm "$SYMLINK_TARGET"
  ln -s "$SYMLINK_SOURCE" "$SYMLINK_TARGET"
  echo "  ✓ Symlinked CLAUDE.md"
else
  ln -s "$SYMLINK_SOURCE" "$SYMLINK_TARGET"
  echo "  ✓ Symlinked CLAUDE.md → $SYMLINK_SOURCE"
fi

# 4. Copy skills to ~/.claude/skills/
SKILLS_SRC="$SCRIPT_DIR/.claude/skills"
SKILLS_DST="$HOME/.claude/skills"

if [ -d "$SKILLS_SRC" ]; then
  mkdir -p "$SKILLS_DST"
  for skill_dir in "$SKILLS_SRC"/*/; do
    skill_name=$(basename "$skill_dir")
    skill_link="$SKILLS_DST/$skill_name"
    # Remove old copy/symlink and replace with a live symlink
    rm -rf "$skill_link"
    ln -s "$skill_dir" "$skill_link"
    echo "  ✓ Linked skill: /$skill_name → $skill_dir"
  done
else
  echo "  ⚠ No skills directory found at $SKILLS_SRC"
fi

# 5. Symlink workspace file to docto/ so all repos are siblings with ./repo paths
WORKSPACE_LINK="$DOCTO_DIR/docto.code-workspace"
WORKSPACE_SOURCE="$SCRIPT_DIR/docto.code-workspace"

if [ -L "$WORKSPACE_LINK" ] || [ -f "$WORKSPACE_LINK" ]; then
  echo "  ✓ docto.code-workspace already at $WORKSPACE_LINK"
else
  ln -s "$WORKSPACE_SOURCE" "$WORKSPACE_LINK"
  echo "  ✓ Symlinked docto.code-workspace → $WORKSPACE_SOURCE"
fi

# 6. Check Trello MCP
MCP_CONFIG="$HOME/.claude/mcp.json"
if [ -f "$MCP_CONFIG" ] && grep -q "trello\|atlassian" "$MCP_CONFIG" 2>/dev/null ; then
  echo "  ✓ Trello MCP detected in $MCP_CONFIG"
else
  echo ""
  echo "  ⚠ Trello MCP not found in $MCP_CONFIG"
  echo "    The /ticket skill uses Trello MCP to fetch card details."
  echo "    Add your Trello MCP config to $MCP_CONFIG to enable it."
  echo "    See: https://github.com/your-org/trello-mcp for setup instructions"
fi

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Open the multi-repo workspace:"
echo "  cursor $DOCTO_DIR/docto.code-workspace"
echo "  code   $DOCTO_DIR/docto.code-workspace"
echo ""
echo "Available Claude skills: /ticket, /deploy, /pr, /update-context"
