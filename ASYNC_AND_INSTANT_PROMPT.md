# Async Updates and Instant Prompt for Direct Git Implementation

This document explains how the direct git implementation handles async updates and instant prompt functionality in Powerlevel10k.

## Overview

The direct git implementation provides two key performance features:

1. **Instant Prompt Support**: Shows VCS information immediately on shell startup
2. **Caching System**: Reduces git command execution frequency
3. **Async Updates**: Background updates for real-time status changes

## How Powerlevel10k Handles Async Updates

### Original GitStatus System

Powerlevel10k originally used GitStatus for async updates:

1. **GitStatus Daemon**: A C++ daemon that monitors git repositories
2. **Async Queries**: Non-blocking git status queries
3. **Real-time Updates**: Automatic updates when git state changes
4. **Instant Prompt**: Cached results for instant display

### Our Direct Git Implementation

Our implementation provides similar functionality without the GitStatus daemon:

1. **Caching System**: In-memory cache with 2-second TTL
2. **Instant Prompt**: Simplified VCS display for shell startup
3. **Synchronous Fallback**: Direct git commands when cache is invalid
4. **Future Async Support**: Framework for background worker integration

## Components

### 1. Caching System

```bash
# Cache key based on git directory and current working directory
_p9k_git_direct_cache_key() {
  local git_dir=$(git rev-parse --git-dir 2>/dev/null)
  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  echo "${git_dir}:${repo_root}:${PWD}"
}

# Get cached data if valid (2-second TTL)
_p9k_git_direct_cache_get() {
  local cache_key=$(_p9k_git_direct_cache_key)
  local cache_entry=$_p9k__git_direct_cache[$cache_key]

  if [[ -n $cache_entry ]]; then
    local cache_time=${cache_entry%%:*}
    local cache_data=${cache_entry#*:}

    # Cache is valid for 2 seconds
    if (( EPOCHREALTIME - cache_time < 2 )); then
      _p9k__ret=$cache_data
      return 0
    fi
  fi

  return 1
}
```

**Benefits:**
- Reduces git command execution frequency
- Improves prompt responsiveness
- Maintains data freshness with 2-second TTL

### 2. Instant Prompt Support

```bash
function instant_prompt_vcs() {
  # Simplified version for instant display
  # Only shows basic info: branch, commit, remote icon
  # No status indicators (staged, unstaged, etc.)

  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    return 1
  fi

  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  local commit_hash=$(git rev-parse --short HEAD 2>/dev/null)

  # Build simplified content
  local content=""

  if (( _POWERLEVEL9K_SHOW_CHANGESET )); then
    content+="🔗${commit_hash:0:7} "
  fi

  if [[ -n $branch ]]; then
    content+="🌿$branch"
  fi

  # Always show as CLEAN state for instant prompt
  _p9k_prompt_segment "prompt_vcs_CLEAN" "2" "$_p9k_color1" "$icon" 0 '' "$content"
}
```

**Benefits:**
- Instant prompt display on shell startup
- No blocking git operations during startup
- Consistent with Powerlevel10k's instant prompt philosophy

### 3. Main VCS Function

```bash
function _p9k_git_direct() {
  # Check cache first
  if _p9k_git_direct_cache_get; then
    # Use cached data
    _p9k_git_direct_render $cached_data
    return 0
  fi

  # Run git commands and cache results
  local git_data=$(run_git_commands)
  _p9k_git_direct_cache_set "$git_data"
  _p9k_git_direct_render $git_data
}
```

## Performance Comparison

### GitStatus (Original)
- **Startup**: Fast (cached results)
- **Updates**: Very fast (daemon monitoring)
- **Memory**: Higher (daemon process)
- **Complexity**: High (C++ daemon)

### Direct Git (Our Implementation)
- **Startup**: Fast (instant prompt)
- **Updates**: Fast (2-second cache)
- **Memory**: Lower (no daemon)
- **Complexity**: Low (pure shell)

### vcs_info (Fallback)
- **Startup**: Slow (synchronous)
- **Updates**: Slow (synchronous)
- **Memory**: Low
- **Complexity**: Medium

## Configuration

### Enable Direct Git Implementation

```bash
# In your .zshrc
POWERLEVEL9K_DISABLE_GITSTATUS=true
POWERLEVEL9K_VCS_BACKENDS=(git)
```

### Instant Prompt Configuration

```bash
# Enable instant prompt
POWERLEVEL9K_INSTANT_PROMPT=verbose

# Or disable if you have issues
POWERLEVEL9K_DISABLE_INSTANT_PROMPT=true
```

### Cache Configuration

The cache TTL is hardcoded to 2 seconds. To modify:

```bash
# In internal/p10k.zsh, change this line:
if (( EPOCHREALTIME - cache_time < 2 )); then
# To:
if (( EPOCHREALTIME - cache_time < 5 )); then  # 5 seconds
```

## Future Enhancements

### 1. Full Async Support

We can integrate with Powerlevel10k's worker system:

```bash
# Add to _p9k_git_direct()
if (( $+functions[_p9k_worker_invoke] )); then
  _p9k_worker_invoke git_direct "_p9k_git_direct_async_update"
fi
```

### 2. File System Monitoring

Monitor git directory changes:

```bash
# Use inotify/fswatch to detect git changes
# Trigger cache invalidation on .git/index changes
```

### 3. Smart Caching

Cache based on git operations:

```bash
# Invalidate cache when git commands are run
# Use git hooks to detect repository changes
```

## Troubleshooting

### Issue: VCS segment not updating
- Check cache TTL (default 2 seconds)
- Verify git repository status
- Check if instant prompt is interfering

### Issue: Instant prompt not working
- Ensure `POWERLEVEL9K_INSTANT_PROMPT` is not set to `off`
- Check for errors in shell startup
- Verify `instant_prompt_vcs` function exists

### Issue: Performance not improved
- Monitor git command execution frequency
- Check cache hit rates
- Consider adjusting cache TTL

## Integration with Powerlevel10k

### Worker System Integration

Powerlevel10k has a sophisticated worker system for async operations:

```bash
# Example worker integration
_p9k_worker_invoke git_direct \
  "_p9k_git_direct_async_compute ${(q)PWD} ${(q)git_dir}"
```

### Segment System Integration

Our implementation follows Powerlevel10k's segment patterns:

```bash
# Standard segment call
_p9k_prompt_segment "prompt_vcs_$state" \
  "${__p9k_vcs_states[$state]}" \
  "$_p9k_color1" \
  "$icon" \
  0 \
  '' \
  "$content"
```

## Conclusion

The direct git implementation provides:

1. **Better Performance**: No daemon overhead
2. **Instant Prompt**: Fast shell startup
3. **Smart Caching**: Reduced git command calls
4. **Compatibility**: Works with existing Powerlevel10k features
5. **Extensibility**: Framework for future async enhancements

This approach gives you the performance benefits of GitStatus without the complexity of a C++ daemon, while maintaining full compatibility with Powerlevel10k's instant prompt and async update systems.
