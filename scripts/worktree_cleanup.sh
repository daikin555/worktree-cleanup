#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Default values
FORCE=false
BASE_BRANCH="main"
YES=false

# Usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Automatically cleans up the worktree and returns to the base branch."
    echo ""
    echo "Options:"
    echo "  --base <branch>        Base branch to return to (default: main)"
    echo "  --force                Continue even with uncommitted changes (not recommended)"
    echo "  --yes                  Skip confirmation prompt"
    echo "  --help                 Show this help message"
    echo ""
    echo "Example:"
    echo "  $0"
    echo "  $0 --base develop"
    echo "  $0 --force"
    exit 1
}

# Parse arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --base)
                if [[ -z "${2:-}" ]]; then
                    log_error "--base requires a branch name"
                    exit 1
                fi
                if [[ "$2" =~ [[:space:]] ]]; then
                    log_error "Branch name cannot contain spaces: '$2'"
                    exit 1
                fi
                if [[ "$2" =~ ^- ]]; then
                    log_error "Invalid branch name: '$2'"
                    exit 1
                fi
                BASE_BRANCH="$2"
                shift 2
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --yes)
                YES=true
                shift
                ;;
            --help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Validate environment
validate_environment() {
    log_step "Validating environment..."

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not a git repository"
        exit 1
    fi

    # Check if we're in a worktree directory
    GIT_DIR=$(git rev-parse --git-dir)
    if [[ ! "$GIT_DIR" =~ \.git/worktrees/ ]]; then
        log_error "Not in a worktree directory"
        log_info "This script must be run from within a git worktree directory"
        exit 1
    fi

    # Get current branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [ -z "$CURRENT_BRANCH" ]; then
        log_error "Cannot determine current branch"
        exit 1
    fi

    # Get repository root
    REPO_ROOT=$(git rev-parse --show-toplevel)

    # Get worktree path
    WORKTREE_PATH=$(pwd)
    WORKTREE_NAME=$(basename "$WORKTREE_PATH")

    log_info "Current branch: $CURRENT_BRANCH"
    log_info "Worktree path: $WORKTREE_PATH"
    log_info "Repository root: $REPO_ROOT"
}

# Check for uncommitted changes
check_uncommitted_changes() {
    log_step "Checking for uncommitted changes..."

    if [ "$(git status --porcelain)" != "" ]; then
        if [ "$FORCE" = false ]; then
            log_error "You have uncommitted changes"
            echo ""
            git status --short
            echo ""
            log_info "Please commit or stash your changes before cleaning up worktree"
            log_info "Or use --force to skip this check (not recommended)"
            exit 1
        else
            log_warn "Uncommitted changes detected (--force specified, continuing anyway)"
        fi
    else
        log_info "No uncommitted changes detected"
    fi
}

# Confirm cleanup
confirm_cleanup() {
    if [ "$YES" = true ]; then
        log_info "Skipping confirmation (--yes specified)"
        return 0
    fi

    echo ""
    log_warn "You are about to remove the worktree: $WORKTREE_NAME"
    log_info "Branch: $CURRENT_BRANCH"
    log_info "Worktree path: $WORKTREE_PATH"
    echo ""
    echo -n "Do you want to continue? (y/N): "
    read -r response
    echo ""

    case "$response" in
        [yY][eE][sS]|[yY])
            log_info "Confirmation received. Proceeding with cleanup..."
            return 0
            ;;
        *)
            log_info "Cleanup cancelled."
            exit 0
            ;;
    esac
}

# Cleanup worktree
cleanup_worktree() {
    log_step "Removing worktree..."

    # Move to repository root
    cd "$REPO_ROOT"

    # Remove worktree
    if git worktree remove "$WORKTREE_PATH"; then
        log_info "Worktree removed successfully: $WORKTREE_PATH"
    else
        log_error "Failed to remove worktree"
        log_info ""
        log_info "You can manually remove it with:"
        log_info "  git worktree remove $WORKTREE_PATH"
        log_info ""
        log_info "Or force remove:"
        log_info "  git worktree remove --force $WORKTREE_PATH"
        exit 1
    fi
}

# Return to base branch
return_to_base() {
    log_step "Returning to base branch ($BASE_BRANCH)..."

    cd "$REPO_ROOT"

    if git checkout "$BASE_BRANCH"; then
        log_info "Now on branch: $BASE_BRANCH"
    else
        log_warn "Failed to checkout $BASE_BRANCH"
        log_info "Current directory: $(pwd)"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN} Worktree Cleanup Completed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Removed worktree: $WORKTREE_NAME"
    echo "Current branch: $BASE_BRANCH"
    echo ""
    echo "Note:"
    echo "  - Local branch ($CURRENT_BRANCH) is preserved"
    echo "  - Remote branch is preserved"
    echo ""
    echo "To delete local branch after PR merge:"
    echo "  git branch -d $CURRENT_BRANCH"
    echo ""
}

# Main
main() {
    parse_arguments "$@"
    validate_environment
    check_uncommitted_changes
    confirm_cleanup
    cleanup_worktree
    return_to_base
    print_summary
}

main "$@"

