# Obsidian Vault Structure

Location: `~/obsidian-vault/`

## Directory Layout

```
~/obsidian-vault/
├── .obsidian/                    # Obsidian configuration
│   ├── plugins/                  # Installed plugins
│   │   ├── dataview/
│   │   ├── obsidian-shellcommands/
│   │   └── obsidian-excalidraw-plugin/
│   ├── hotkeys.json              # Keyboard shortcuts
│   ├── workspace.json            # Window layout
│   └── community-plugins.json
│
├── .claude/                      # Claude Code integration
│   ├── commands/
│   └── sessions/
│
├── PRs/                          # PR Tracking System
│   ├── Dashboard.md              # Main dashboard (Dataview)
│   ├── authored/                 # PRs I created
│   │   └── pr-{number}.md
│   ├── reviews/                  # PRs assigned for review
│   │   └── pr-{number}.md
│   ├── templates/
│   │   ├── pr-template.md
│   │   └── review-template.md
│   ├── prompts/                  # Claude prompts
│   │   ├── work-on-next-items.md
│   │   └── work-on-plan.md
│   └── sync-status.md            # Last GitHub sync time
│
├── Inbox/                        # Task quick capture
│   └── task-{date}-{id}.md
│
├── Plans/                        # Project plans
│   └── {plan-name}.md
│
├── Reports/                      # Generated reports
│   └── token-usage-*.md
│
├── CLAUDE_CONTEXT.md             # Master reference for CC
├── System Architecture.md        # User-friendly overview
└── Welcome.md                    # Onboarding guide
```

## Key Files

### CLAUDE_CONTEXT.md

Master technical reference (270 lines). Contains:
- Directory structure
- Script descriptions
- Frontmatter schemas
- Naming conventions
- Shell command mappings
- Debugging tips

Claude Code reads this when working in the vault.

### PRs/Dashboard.md

Central hub with Dataview queries showing:
- **Next Steps** checklist
- **Quick Stats** (open PRs, pending reviews, last sync)
- **My Open PRs** table with action buttons
- **PRs Needing Review** table
- **Recently Closed** table
- **Task Inbox** section
- **Quick Actions** buttons
- **Keyboard Shortcuts** reference

### sync-status.md

Tracks last GitHub sync:
```markdown
Last sync: 2026-01-24 12:36
```

Updated by `sync-prs-to-obsidian.sh`.

## PR Note Schema

Location: `PRs/authored/pr-{number}.md` or `PRs/reviews/pr-{number}.md`

```yaml
---
pr_number: 5156
title: "feat: add feature"
repo: i360
url: https://github.com/dcodeit/i360/pull/5156
status: open           # open|merged|closed
draft: false           # optional
type: authored         # authored|review
branch: feature-name
created: 2026-01-22
updated: 2026-01-22
claude_last_review: 2026-01-23T14:30:00
labels: [feature]
reviewers: []
my_review_status: pending  # pending|approved|changes_requested
---
```

## Task Note Schema

Location: `Inbox/task-{date}-{id}.md`

```yaml
---
title: "task description"
project: i360
area: work             # work|private
ai_analysis: false
due_date: 2026-01-30   # optional
priority: medium       # high|medium|low
created: 2026-01-23T19:30:00
status: inbox          # inbox|processed|done
done: false
---
```

## Required Plugins

| Plugin | Purpose |
|--------|---------|
| **Dataview** | Dynamic queries for Dashboard |
| **Shell Commands** | Keyboard shortcuts to scripts |
| **Templater** | Note templates |
| **Advanced URI** | Deep linking |

## Dataview Queries

### My Open PRs

```dataview
TABLE
  pr_number as "PR",
  title as "Title",
  status as "Status"
FROM "PRs/authored"
WHERE status = "open"
SORT updated DESC
```

### Task Inbox

```dataview
TABLE
  title as "Task",
  project as "Project",
  area as "Area"
FROM "Inbox"
WHERE done = false
SORT created DESC
```

## Deep Links

Obsidian URI format for opening notes:
```
obsidian://open?vault=obsidian-vault&file=PRs/authored/pr-5156
```

Used by:
- Dashboard action buttons
- `pr-dashboard.sh` terminal browser
- Automation notifications
