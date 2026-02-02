# Worktree Cleanup - Reference

## Command-Line Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `--base <branch>` | Base branch to return to | main |
| `--force` | Continue even with uncommitted changes | false (not recommended) |
| `--yes` | Skip confirmation prompt | false |
| `--help` | Show help message | - |

## Internal Processing Flow

### 1. Environment Validation Phase
```bash
1. Check if running inside a worktree directory
   - Verify .git/worktrees/<name> via git rev-parse --git-dir
2. Get current branch name
   - git branch --show-current
3. Get repository root
   - git rev-parse --show-toplevel
4. Determine worktree path
   - pwd to get current directory
```

### 2. Change Detection Phase
```bash
1. Check for uncommitted changes
   - git status --porcelain
   - Error if output is non-empty (unless --force is specified)
```

### 3. Cleanup Phase
```bash
1. Navigate to repository root
   - cd $REPO_ROOT
2. Remove worktree
   - git worktree remove <worktree-path>
3. Check out base branch
   - git checkout <base-branch>
4. Display completion message
```

## Error Handling Strategy

### Level 1: Immediate Abort (CRITICAL)
- Running outside a worktree
- Not a git repository
- Uncommitted changes present (without --force)
- Invalid --base argument (empty, contains spaces, or starts with -)

### Level 2: Warn and Continue (WARNING)
- Failed to check out base branch (processing continues)

### Level 3: Rollback (ROLLBACK)
- Worktree removal failed: manual removal instructions displayed

## Usage Examples

### Case 1: Basic Usage
```bash
cd /path/to/your-worktree
bash /path/to/worktree_cleanup.sh
# → removes worktree → returns to main
```

### Case 2: Custom Base Branch
```bash
# Return to develop branch
bash /path/to/worktree_cleanup.sh --base develop
```

### Case 3: Ignore Uncommitted Changes (Not Recommended)
```bash
# Use only in emergencies
bash /path/to/worktree_cleanup.sh --force
```

### Case 4: Non-interactive (CI/scripts)
```bash
bash /path/to/worktree_cleanup.sh --yes
```

## Troubleshooting

### Q: Script says there are uncommitted changes
```bash
# Check changes
git status

# Commit them
git add .
git commit -m "commit message"

# Or stash them
git stash
```

### Q: Worktree removal failed
```bash
# Manually remove the worktree
cd /path/to/repo-root
git worktree remove /path/to/worktree

# Force remove
git worktree remove --force /path/to/worktree
```

### Q: Ran the script outside a worktree
```bash
# Navigate to the worktree directory first
cd /path/to/your-worktree

# Run again
bash /path/to/worktree_cleanup.sh
```

### Q: Want to delete the local branch too
```bash
# After worktree removal, manually delete the branch
git branch -d feature/<name>
```

### Q: Want to delete the remote branch too
```bash
# Enable "Automatically delete head branches" on GitHub
# Settings → General → Pull Requests → check the box

# Or manually delete
git push origin --delete feature/<name>
```

### Q: Base branch is not main
```bash
# Use the --base option to specify the base branch
bash worktree_cleanup.sh --base develop
bash worktree_cleanup.sh --base master
```

## Best Practices

### 1. Regular Worktree Cleanup
- Always remove worktrees after development is complete
- Avoid unnecessary disk usage
- Periodically check for stale worktrees with `git worktree list`

### 2. Branch Deletion Timing
- **Local branches**: Delete manually after PR merge (`git branch -d <branch>`)
- **Remote branches**: Enable automatic deletion in GitHub settings (recommended)

### 3. Recommended Worktree Development Flow
```bash
# 1. Create worktree
git worktree add /path/to/worktree -b feature/feature-name

# 2. Develop
cd /path/to/worktree
# develop, test, commit

# 3. Push (if needed)
git push origin feature/feature-name

# 4. Create PR (via GitHub CLI or web UI)
gh pr create --title "..." --body "..."

# 5. Cleanup worktree
bash /path/to/worktree_cleanup.sh

# 6. Post-merge cleanup (optional)
git branch -d feature/feature-name
```

## Security Considerations

### Command Injection Prevention
- User inputs are properly quoted
- `set -euo pipefail` ensures safe execution
- `--base` argument is validated (rejects empty strings, spaces, and `-` prefixed values)

## Performance

### Expected Processing Time
- Environment validation: < 1 second
- Change detection: < 1 second
- Worktree removal: < 1 second
- Total: typically 2-3 seconds

### Notes for Large Repositories
- `git status` is usually fast, but may take a few seconds with tens of thousands of files
- Worktree removal is an O(1) operation and is fast

## Related Documentation

- [README.md](README.md) - Overview and installation
- [SKILL.md](SKILL.md) - Claude Code skill configuration
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree) - Official git worktree documentation
