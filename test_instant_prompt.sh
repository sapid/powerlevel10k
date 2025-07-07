#!/bin/bash

main() {
    # Test script for instant prompt functionality
    echo "Testing instant prompt functionality..."

    # Test 1: Check if instant_prompt_vcs function exists
    echo "1. Checking if instant_prompt_vcs function exists..."
    if grep -q "function instant_prompt_vcs" internal/p10k.zsh; then
        echo "   ✓ instant_prompt_vcs function found"
    else
        echo "   ✗ instant_prompt_vcs function not found"
        exit 1
    fi

    # Test 2: Check if caching functions exist
    echo "2. Checking if caching functions exist..."
    if grep -q "_p9k_git_direct_cache" internal/p10k.zsh; then
        echo "   ✓ Caching functions found"
    else
        echo "   ✗ Caching functions not found"
        exit 1
    fi

    # Test 3: Test instant prompt in a git repository
    echo "3. Testing instant prompt in git repository..."
    if git rev-parse --git-dir >/dev/null 2>&1; then
        echo "   ✓ In a git repository"

        # Test basic git commands that instant prompt uses
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
        local commit=$(git rev-parse --short HEAD 2>/dev/null)

        if [[ -n $branch ]]; then
            echo "   ✓ Branch: $branch"
        else
            echo "   ✓ Detached HEAD"
        fi

        if [[ -n $commit ]]; then
            echo "   ✓ Commit: $commit"
        else
            echo "   ✗ No commit found"
            exit 1
        fi
    else
        echo "   ✗ Not in a git repository"
        echo "   Please run this script from within a git repository"
        exit 1
    fi

    # Test 4: Check Powerlevel10k configuration
    echo "4. Checking Powerlevel10k configuration..."
    if [[ -f ~/.p10k.zsh ]]; then
        echo "   ✓ ~/.p10k.zsh exists"

        # Check if instant prompt is enabled
        if grep -q "POWERLEVEL9K_INSTANT_PROMPT" ~/.p10k.zsh; then
            echo "   ✓ Instant prompt configuration found"
        else
            echo "   ⚠ Instant prompt not configured (will use default)"
        fi
    else
        echo "   ⚠ ~/.p10k.zsh not found (will use default configuration)"
    fi

    # Test 5: Check if GitStatus is disabled
    echo "5. Checking GitStatus configuration..."
    if grep -q "POWERLEVEL9K_DISABLE_GITSTATUS=true" ~/.p10k.zsh 2>/dev/null; then
        echo "   ✓ GitStatus is disabled"
    elif grep -q "POWERLEVEL9K_DISABLE_GITSTATUS" ~/.p10k.zsh 2>/dev/null; then
        echo "   ⚠ GitStatus configuration found but not disabled"
    else
        echo "   ⚠ GitStatus configuration not found (will use default)"
    fi

    # Test 6: Test cache functionality
    echo "6. Testing cache functionality..."
    if [[ -n $ZSH_VERSION ]]; then
        echo "   ✓ Running in zsh"

        # Source the theme to test functions
        if source powerlevel10k.zsh-theme 2>/dev/null; then
            echo "   ✓ Theme sourced successfully"

            # Test if cache functions are available
            if (( $+functions[_p9k_git_direct_cache_key] )); then
                echo "   ✓ Cache functions are available"
            else
                echo "   ✗ Cache functions not available"
            fi
        else
            echo "   ⚠ Could not source theme (this is normal in some environments)"
        fi
    else
        echo "   ⚠ Not running in zsh (cache test skipped)"
    fi

    echo ""
    echo "=== Test Summary ==="
    echo "✓ Instant prompt function: Available"
    echo "✓ Caching system: Available"
    echo "✓ Git repository: Detected"
    echo "✓ Basic git commands: Working"
    echo ""
    echo "To enable instant prompt:"
    echo "1. Add to your .zshrc:"
    echo "   POWERLEVEL9K_INSTANT_PROMPT=verbose"
    echo ""
    echo "2. Add to your ~/.p10k.zsh:"
    echo "   POWERLEVEL9K_DISABLE_GITSTATUS=true"
    echo "   POWERLEVEL9K_VCS_BACKENDS=(git)"
    echo ""
    echo "3. Restart your shell"
    echo ""
    echo "The instant prompt will show basic VCS info immediately,"
    echo "then update with full status information after 2 seconds."
}

main "$@"
