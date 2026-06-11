#!/usr/bin/env bash
set -euo pipefail

# Build the site
hugo --minify

# Get repo name for worktree
REPO_DIR="$(git rev-parse --show-toplevel)"
cd "$REPO_DIR"

# Ensure gh-pages branch exists locally
if ! git show-ref --verify --quiet refs/heads/gh-pages; then
  git checkout --orphan gh-pages
  git rm -rf .
  git commit --allow-empty -m "Init gh-pages"
  git checkout main
fi

# Nuke old worktree if it exists
rm -rf "$REPO_DIR/.gh-pages-worktree"
git worktree prune

# Create temp worktree from gh-pages
git worktree add "$REPO_DIR/.gh-pages-worktree" gh-pages

# Copy public/ contents into worktree
rsync -av --delete --exclude .git "$REPO_DIR/public/" "$REPO_DIR/.gh-pages-worktree/"

# Commit and push
cd "$REPO_DIR/.gh-pages-worktree"
touch .nojekyll
git add -A
if git diff --cached --quiet; then
  echo "No changes to deploy."
else
  git commit -m "Deploy $(date -u +'%Y-%m-%d %H:%M UTC')"
  git push origin gh-pages
fi

# Cleanup
cd "$REPO_DIR"
git worktree remove "$REPO_DIR/.gh-pages-worktree"
rm -rf "$REPO_DIR/.gh-pages-worktree"

echo "Deployed to gh-pages."
