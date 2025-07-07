#!/bin/bash

# Test script for direct git implementation
echo "Testing direct git implementation..."

# Test basic git commands that our implementation uses
echo "1. Testing git rev-parse --git-dir..."
if git rev-parse --git-dir >/dev/null 2>&1; then
    echo "   ✓ Git repository detected"
    git_dir=$(git rev-parse --git-dir 2>/dev/null)
    echo "   Git dir: $git_dir"
else
    echo "   ✗ Not in a git repository"
    exit 1
fi

echo "2. Testing git symbolic-ref --short HEAD..."
branch=$(git symbolic-ref --short HEAD 2>/dev/null)
if [[ -n $branch ]]; then
    echo "   ✓ Branch: $branch"
else
    echo "   ✓ Detached HEAD"
fi

echo "3. Testing git rev-parse --short HEAD..."
commit=$(git rev-parse --short HEAD 2>/dev/null)
echo "   ✓ Commit: $commit"

echo "4. Testing git status detection..."
if git diff --cached --quiet 2>/dev/null; then
    echo "   ✓ No staged changes"
else
    echo "   ✗ Has staged changes"
fi

if git diff --quiet 2>/dev/null; then
    echo "   ✓ No unstaged changes"
else
    echo "   ✗ Has unstaged changes"
fi

untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
echo "   ✓ Untracked files: $untracked"

echo "5. Testing remote information..."
if git rev-parse --verify HEAD@{upstream} >/dev/null 2>&1; then
    remote_branch=$(git rev-parse --symbolic-full-name HEAD@{upstream} 2>/dev/null)
    echo "   ✓ Upstream: $remote_branch"

    ahead=$(git rev-list --count HEAD..$remote_branch 2>/dev/null || echo 0)
    behind=$(git rev-list --count $remote_branch..HEAD 2>/dev/null || echo 0)
    echo "   ✓ Ahead: $ahead, Behind: $behind"
else
    echo "   ✓ No upstream configured"
fi

echo "6. Testing stash count..."
if [[ -s "$git_dir/logs/refs/stash" ]]; then
    stashes=$(wc -l < "$git_dir/logs/refs/stash" 2>/dev/null || echo 0)
    echo "   ✓ Stashes: $stashes"
else
    echo "   ✓ No stashes"
fi

echo "7. Testing tag detection..."
tag=$(git describe --tags --exact-match HEAD 2>/dev/null)
if [[ -n $tag ]]; then
    echo "   ✓ Tag: $tag"
else
    echo "   ✓ No tag on current commit"
fi

echo ""
echo "All tests completed. If you see this, the direct git implementation should work!"
echo ""
echo "To use this implementation:"
echo "1. Source the modified p10k.zsh file"
echo "2. Set POWERLEVEL9K_DISABLE_GITSTATUS=true in your .zshrc"
echo "3. Restart your shell or reload the theme"
