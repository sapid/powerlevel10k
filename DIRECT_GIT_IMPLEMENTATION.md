# Direct Git Implementation for Powerlevel10k

This document explains the modifications made to Powerlevel10k to use direct git commands instead of GitStatus or vcs_info for better performance.

## What Was Modified

### 1. **New Function: `_p9k_git_direct()`**
- **Location**: `internal/p10k.zsh` (lines ~4155-4350)
- **Purpose**: Implements VCS information gathering using direct git commands
- **Features**:
  - Branch name detection (including detached HEAD)
  - Commit hash display
  - Remote tracking information
  - Ahead/behind counts
  - Tag detection
  - Stash count
  - Status indicators (staged, unstaged, untracked, conflicted)
  - State determination (CLEAN, MODIFIED, UNTRACKED, CONFLICTED)

### 2. **Modified Function: `prompt_vcs()`**
- **Location**: `internal/p10k.zsh` (lines ~4350-4390)
- **Changes**: Added priority check for direct git implementation
- **Logic**:
  1. First tries `_p9k_git_direct()` if git is in backends
  2. Falls back to original GitStatus/vcs_info implementation

### 3. **Configuration File: `~/.p10k.zsh`**
- **Purpose**: Example configuration to enable direct git implementation
- **Key Settings**:
  - `POWERLEVEL9K_DISABLE_GITSTATUS=true` - Disables GitStatus daemon
  - `POWERLEVEL9K_VCS_BACKENDS=(git)` - Keeps git in backends
  - Various VCS segment configuration options

## Git Commands Used

The implementation uses these direct git commands for maximum performance:

```bash
# Basic repository detection
git rev-parse --git-dir
git rev-parse --show-toplevel

# Branch and commit information
git symbolic-ref --short HEAD
git rev-parse --short HEAD

# Remote tracking
git rev-parse --verify HEAD@{upstream}
git rev-parse --symbolic-full-name HEAD@{upstream}
git config --get remote.$remote_name.url

# Ahead/behind counts
git rev-list --count HEAD..$remote_branch
git rev-list --count $remote_branch..HEAD

# Status detection
git diff --cached --quiet
git diff --cached --name-only
git diff --quiet
git diff --name-only
git ls-files --others --exclude-standard
git ls-files --unmerged

# Tag detection
git describe --tags --exact-match HEAD

# Stash count
wc -l < "$git_dir/logs/refs/stash"
```

## Performance Benefits

1. **No Daemon Overhead**: Eliminates GitStatus daemon process
2. **No vcs_info Overhead**: Bypasses Zsh's vcs_info system
3. **Direct Commands**: Uses git commands directly without intermediate layers
4. **Minimal Caching**: Only caches what's necessary for display
5. **Faster Startup**: No daemon initialization required

## How to Use

### Option 1: Use the Configuration File
1. Copy `~/.p10k.zsh` to your home directory
2. Source it in your `.zshrc`:
   ```bash
   source ~/.p10k.zsh
   ```
3. Restart your shell

### Option 2: Manual Configuration
Add these lines to your `.zshrc`:
```bash
# Disable GitStatus
POWERLEVEL9K_DISABLE_GITSTATUS=true

# Keep git in backends for direct implementation
POWERLEVEL9K_VCS_BACKENDS=(git)

# Optional: Disable GitStatus formatting
POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=true
```

### Option 3: Test the Implementation
Run the test script to verify everything works:
```bash
./test_git_direct.sh
```

## Configuration Options

The implementation respects all existing Powerlevel10k VCS configuration options:

- `POWERLEVEL9K_SHOW_CHANGESET` - Show commit hash
- `POWERLEVEL9K_VCS_HIDE_TAGS` - Hide tag information
- `POWERLEVEL9K_HIDE_BRANCH_ICON` - Hide branch icon
- `POWERLEVEL9K_VCS_CONFLICTED_STATE` - Show conflicted state
- `POWERLEVEL9K_VCS_SHORTEN_LENGTH` - Branch name shortening
- `POWERLEVEL9K_VCS_SHORTEN_STRATEGY` - Shortening strategy
- All the `POWERLEVEL9K_VCS_*_MAX_NUM` options for status indicators

## Troubleshooting

### Issue: VCS segment not showing
- Check that `POWERLEVEL9K_VCS_BACKENDS` includes `git`
- Verify you're in a git repository
- Run `./test_git_direct.sh` to test git commands

### Issue: Still using GitStatus
- Ensure `POWERLEVEL9K_DISABLE_GITSTATUS=true` is set
- Check that the modified `internal/p10k.zsh` is being sourced
- Restart your shell completely

### Issue: Performance not improved
- The direct implementation should be faster, but results may vary
- Check if you have other slow git operations in your prompt
- Profile with `time` command to measure actual performance

## Reverting Changes

To revert to the original implementation:
1. Remove the `_p9k_git_direct()` function from `internal/p10k.zsh`
2. Restore the original `prompt_vcs()` function
3. Set `POWERLEVEL9K_DISABLE_GITSTATUS=false`
4. Restart your shell

## Files Modified

1. `internal/p10k.zsh` - Main theme file with new implementation
2. `~/.p10k.zsh` - Configuration example
3. `test_git_direct.sh` - Test script
4. `DIRECT_GIT_IMPLEMENTATION.md` - This documentation

## Compatibility

- **Zsh**: Compatible with Zsh 5.1+ (same as Powerlevel10k)
- **Git**: Compatible with Git 1.7+ (uses standard git commands)
- **Powerlevel10k**: Compatible with current version
- **Other VCS**: Falls back to original implementation for non-git VCS

The implementation maintains full compatibility with existing Powerlevel10k features while providing better performance for git repositories.
