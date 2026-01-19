# Git Workflow Rules

Detailed git workflow rules for AI agents.

---

## "NEW BRANCH" Always Means From Upstream

**THIS ALWAYS MEANS:**
- ✅ Sync with upstream (main repository) FIRST
- ✅ Create branch from LATEST upstream master
- ✅ NEVER continue existing work
- ✅ NEVER assume current branch is correct

**MANDATORY WORKFLOW:**
```bash
git fetch --all
git checkout master
git pull main master
git push origin master
git checkout -b feature/new-task-name
```

---

## After Creating Any Branch - Check Merge Conflicts

**After creating and pushing ANY new branch:**

1. **Verify it can auto-merge into master:**
   ```bash
   git fetch origin
   git merge-base origin/master HEAD
   ```

2. **If NOT cleanly based on latest master:**
   ```bash
   git rebase origin/master
   git push origin <branch-name> --force-with-lease
   ```

**WHY:** User sees "Can't automatically merge" on GitHub otherwise.

---

## New Task = New Branch

**BEFORE STARTING ANY NEW TASK:**
```bash
git fetch --all
git checkout master
git pull main master
git push origin master
git checkout -b fix/descriptive-task-name
```

**APPLIES TO:** Features, bug fixes, config changes, docs, ANY modifications.

---

## Never Reset Changes - Use Stash

**⛔ FORBIDDEN:**
```bash
git reset --hard
git checkout -- .
git clean -fd
```

**✅ CORRECT:**
```bash
git stash push -m "Description of changes"
git stash pop  # to restore
```

**Exception:** Only use reset if user explicitly requests AND confirms data loss.

---

## Never Push Directly to Master/Main

**⛔ FORBIDDEN:**
```bash
git push origin master
```

**✅ CORRECT:**
```bash
git push -u origin feature/my-feature
# Then create Pull Request via GitHub
```

---

## Never Push Without User Confirmation

**⛔ FORBIDDEN:**
- Push branches without user explicitly asking
- Assume user wants changes pushed after commit
- Auto-push as part of "fix" or "implement" workflow

**✅ WORKFLOW:**
1. Make changes
2. Commit locally
3. **STOP and ask:** "Changes committed. Push to remote?"
4. Only push if user explicitly confirms

**Push only if user says:** "push", "create PR", "отправь", "запушь", "создай PR"

---

## New Changes After Push

**⛔ NEVER add new changes to already pushed branches!**

**✅ CORRECT:**
```bash
git fetch --all
git checkout master
git pull main master
git push origin master
git checkout -b fix/additional-improvements
```

**Exception:** Only add to pushed branches if fixing issues in SAME PR discussion.

---

## When User Says "I Merged"

**IMMEDIATE ACTION:**
```bash
git fetch --all
git checkout master
git pull main master
git push origin master
git checkout -b feature/next-improvements
```

---

## Branch Naming Rules

- `feature/short-description` - new features
- `fix/issue-description` - bug fixes  
- `update/component-name` - version/config updates
- `docs/topic` - documentation
- `refactor/component` - refactoring

---

## Fork vs Upstream Remotes

- **origin** = your fork (where you push branches)
- **main** = upstream repository (where PR base branches live)
- **Upstream base branch** = `master` (remote ref: `main/master`)

**If GitHub PR says "Can't automatically merge":**
```bash
git fetch origin
git fetch main
git checkout <your-pr-branch>
git merge --no-ff --no-commit main/master
# Resolve conflicts
git add -A
git commit
git push origin <your-pr-branch>
```

**Rule:** Always check `main/master`, not `origin/master`.
