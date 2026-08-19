# Task Inbox Workflow

Quick capture system for tasks with smart defaults and Obsidian integration.

## Overview

```
Quick capture → Smart defaults → Obsidian note → Dashboard display → Process/Complete
```

## Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `task-add.sh` | `~/scripts/` | CLI task creation |
| `task-add-obsidian.sh` | `~/scripts/` | Obsidian shell command integration |
| `task-add-dialog.sh` | `~/scripts/` | AppleScript dialog |
| `task-toggle-done.sh` | `~/scripts/` | Toggle completion status |
| Task Inbox folder | `~/obsidian-vault/Inbox/` | Task notes storage |

## Quick Capture

### From Obsidian

`Cmd+Shift+A` opens task creation:

1. Enter title (only required field)
2. System pre-fills defaults from last 5 tasks
3. Optional: priority, due date, AI analysis flag
4. Task appears in dashboard inbox

### From Terminal

```bash
# Basic
~/scripts/task-add.sh "Review the login flow"

# With options
~/scripts/task-add.sh "Fix auth bug" --project i360 --area work --priority high
```

## Task Note Schema

Location: `~/obsidian-vault/Inbox/task-{date}-{id}.md`

Frontmatter:

```yaml
title: "task description"
project: i360              # Auto-defaulted from recent tasks
area: work                 # work|private, auto-defaulted
ai_analysis: false         # Should Claude analyze?
due_date: 2026-01-30       # Optional
priority: medium           # high|medium|low
created: 2026-01-23T19:30:00
status: inbox              # inbox|processed|done
done: false                # Display checkbox
```

## Smart Defaults

`task-add-obsidian.sh` analyzes last 5 tasks to pre-fill:

| Field | Default Logic |
|-------|---------------|
| `project` | Most common project in recent tasks |
| `area` | Most common area (work/private) |
| `priority` | Defaults to "medium" |

## Dashboard Display

`~/obsidian-vault/PRs/Dashboard.md` includes Task Inbox section:

- Dataview query shows unchecked tasks
- Area icons (work/private)
- AI analysis flags
- Quick toggle for done status

## Processing Tasks

### Mark Complete

From Dashboard: Click checkbox (triggers `task-toggle-done.sh`)

From Terminal:
```bash
~/scripts/task-toggle-done.sh ~/obsidian-vault/Inbox/task-2026-01-23-001.md
```

### AI Analysis

Set `ai_analysis: true` in frontmatter to flag for Claude review.

Claude can then:
1. Read task details
2. Suggest breakdown
3. Estimate complexity
4. Identify blockers

## Obsidian Shell Commands

| ID | Shortcut | Action |
|----|----------|--------|
| cmd-10 | `Cmd+Shift+A` | Add task to inbox |
| cmd-12 | (dashboard) | Toggle task done status |

## File Naming

Pattern: `task-{YYYY-MM-DD}-{NNN}.md`

Example: `task-2026-01-23-001.md`

- Date from creation
- Sequential number per day
- Ensures unique, sortable names

## Integration with Dashboard Tasks

The Dashboard "Next Steps" section is separate from Task Inbox:

| System | Purpose |
|--------|---------|
| Next Steps | Immediate actions for current focus |
| Task Inbox | Capture for later processing |

When processing inbox:
1. Review captured tasks
2. Move actionable items to Next Steps
3. Mark non-actionable as done or delete
