# worktree-cleanup

Git worktree を安全にクリーンアップし、ベースブランチに戻るシェルスクリプトです。

## 機能

- 現在の worktree ディレクトリとブランチを自動検出
- 未コミットの変更がないかチェック（安全性確保）
- worktree を削除し、ベースブランチにチェックアウト
- ローカル・リモートブランチは保持（削除しない）

## インストール

```bash
git clone https://github.com/your-username/worktree-cleanup.git
```

または、`scripts/worktree_cleanup.sh` を任意の場所にコピーして使用できます。

```bash
# PATH の通った場所にコピーする例
cp scripts/worktree_cleanup.sh ~/.local/bin/worktree-cleanup
chmod +x ~/.local/bin/worktree-cleanup
```

## 使い方

worktree ディレクトリ内で実行してください。

```bash
# 基本的な使い方（worktree 内で実行）
bash /path/to/worktree_cleanup.sh

# ベースブランチを指定
bash /path/to/worktree_cleanup.sh --base develop

# 確認プロンプトをスキップ
bash /path/to/worktree_cleanup.sh --yes

# 未コミットの変更を無視（非推奨）
bash /path/to/worktree_cleanup.sh --force
```

## オプション

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--base <branch>` | 戻り先のベースブランチ | `main` |
| `--force` | 未コミットの変更があっても続行（非推奨） | false |
| `--yes` | 確認プロンプトをスキップ | false |
| `--help` | ヘルプメッセージを表示 | - |

## 実行例

```
$ bash worktree_cleanup.sh

[INFO] Current branch: feature/user-auth
[INFO] Worktree path: /path/to/worktrees/user-auth

[WARN] You are about to remove the worktree: user-auth
[INFO] Branch: feature/user-auth
[INFO] Worktree path: /path/to/worktrees/user-auth

Do you want to continue? (y/N): y

[INFO] Confirmation received. Proceeding with cleanup...
[STEP] Removing worktree...
[INFO] Worktree removed successfully
[STEP] Returning to base branch (main)...
[INFO] Now on branch: main
```

## 前提条件

- Git がインストールされていること
- Git worktree ディレクトリ内で実行すること
- すべての変更がコミット済みであること（`--force` で回避可能）

## エラーハンドリング

### 未コミットの変更がある場合
スクリプトは停止し、コミットを促します。`--force` で強制続行できますが非推奨です。

### worktree の削除に失敗した場合
手動での削除手順が表示されます。

### worktree 外で実行した場合
警告が表示され、処理は中止されます。

## 典型的なワークフロー

```bash
# 1. worktree を作成
git worktree add ../my-feature -b feature/my-feature

# 2. worktree で開発
cd ../my-feature
# 開発、テスト、コミット

# 3. push & PR 作成
git push origin feature/my-feature
gh pr create --title "..." --body "..."

# 4. worktree をクリーンアップ
bash /path/to/worktree_cleanup.sh

# 5. PR マージ後にブランチを削除（任意）
git branch -d feature/my-feature
```

## Claude Code Skill として使う場合

このツールは [Claude Code](https://docs.anthropic.com/en/docs/claude-code) のスキルとしても使用できます。詳細は [SKILL.md](SKILL.md) を参照してください。

## 詳細リファレンス

内部処理フロー、トラブルシューティング、ベストプラクティスについては [REFERENCE.md](REFERENCE.md) を参照してください。

## ライセンス

MIT
