---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git restore:*), Bash(git show:*)
description: Stage meaningful diffs and create Conventional Commits with WHY-focused messages
model: sonnet
---

## Current Git Context

### Working Directory Status

!`git status --short`

### Unstaged Changes (Summary)

!`git diff --stat`

### Staged Changes (Summary)

!`git diff --cached --stat`

### Recent Commits (for context and style reference)

!`git log --oneline -10`

### Current Branch

!`git branch --show-current`

## Task: Create a Meaningful Commit

You are a commit crafting assistant following these principles:

### 1. Conventional Commits 1.0.0 Specification

Format:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types** (choose the most appropriate):

- `fix:` - Bug fix (PATCH in SemVer)
- `feat:` - New feature (MINOR in SemVer)
- `build:` - Build system or external dependencies
- `chore:` - Maintenance tasks, no production code change
- `ci:` - CI configuration changes
- `docs:` - Documentation only
- `style:` - Code style (formatting, whitespace, etc.)
- `refactor:` - Code restructuring without behavior change
- `perf:` - Performance improvement
- `test:` - Adding or correcting tests

**Breaking Changes**: Use `feat!:` or `fix!:` only. Other types (refactor, style, docs, chore) cannot be breaking by definition—if behavior changed, recategorize as feat or fix.

### 2. Commit Message Philosophy (t-wada's Principle)

- **Code** describes HOW
- **Tests** describe WHAT happens
- **Commit log** describes **WHY**
- **Code comments** describe WHY NOT

The commit message body should explain the **reasoning** and **motivation** behind the change, not just repeat what the diff shows.

### 3. Workflow

#### Step 1: Analyze Changes

- Review all unstaged and staged changes
- If needed, show detailed diffs: `git diff [file]` or `git diff --cached [file]`
- Identify logical groupings of related changes

#### Step 2: Plan Staging Strategy

- Group changes that belong together conceptually
- Separate unrelated changes into different commits
- Consider: Does this change serve a single purpose?

#### Step 3: Stage Meaningfully

- Use `git add -p <file>` for partial staging when a file contains multiple logical changes
- Use `git add <file>` for complete file staging
- Verify staged content with `git diff --cached`

#### Step 4: Determine Commit Type

Analyze the staged changes:

- Is it fixing a bug? -> `fix:`
- Is it adding new functionality? -> `feat:`
- Is it restructuring without behavior change? -> `refactor:`
- Is it improving performance? -> `perf:`
- Is it adding/fixing tests? -> `test:`
- Is it documentation? -> `docs:`
- etc.

#### Step 5: Craft the Commit Message

```text
<type>[scope]: <imperative description under 50 chars>

<body: explain WHY this change was necessary>
- What problem does this solve?
- What was the motivation?
- Why was this approach chosen over alternatives?

[optional footer]
```

#### Step 6: Execute Commit

```bash
git commit -m "<type>[scope]: <description>" -m "<body explaining WHY>"
```

Or for complex messages, use the editor:

```bash
git commit
```

### 4. Quality Checklist

Before committing, verify:

- [ ] Staged changes are logically cohesive (single purpose)
- [ ] Commit type accurately reflects the change nature
- [ ] Description is imperative mood, under 50 characters
- [ ] Body explains WHY, not just WHAT
- [ ] No unrelated changes are included
- [ ] Breaking changes are properly indicated

### 5. Examples of Good WHY-focused Messages

```text
feat(auth): add OAuth2 support for GitHub login

Users requested GitHub authentication to avoid creating yet another
account. OAuth2 was chosen over OAuth1 for its simpler flow and
better security model with short-lived tokens.

Closes #142
```

```text
fix(parser): handle empty input without panic

The parser assumed non-empty input, causing crashes in edge cases
reported by users processing automated pipelines where empty files
occasionally appear. Defensive handling was added rather than
requiring callers to validate, following the robustness principle.

Fixes #87
```

```text
refactor(db): extract connection pooling to dedicated module

The database module had grown to 800+ lines, making it difficult
to test connection logic in isolation. Extraction enables unit
testing of pool behavior and prepares for upcoming multi-database
support.
```

## Begin

1. First, show me the detailed diff of changes that need to be committed
2. Help me identify logical groupings
3. Stage the appropriate changes
4. Craft a WHY-focused commit message
5. Execute the commit

If there are multiple logical change sets, we'll create multiple commits, one at a time.
