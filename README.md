# Group Scholar Handoff Dossier

A Guile Scheme CLI for logging scholar handoff notes, triage status, and follow-up ownership across cohort transitions.

## Features
- Log handoff notes with priority, due dates, and ownership
- List, filter, and inspect handoff items
- Close notes when resolved
- Status rollups for quick triage
- PostgreSQL-backed persistence with seeded data

## Setup

### Requirements
- Guile (`guile`)
- PostgreSQL client (`psql`)

### Environment
Set the database connection variables:

```
export GS_DB_HOST="db-acupinir.groupscholar.com"
export GS_DB_PORT="23947"
export GS_DB_USER="ralph"
export GS_DB_PASSWORD="<password>"
export GS_DB_NAME="postgres"
```

## Usage

Initialize the database schema:

```
./bin/gs-handoff.scm init-db
```

Seed the database with sample data:

```
./bin/gs-handoff.scm seed
```

Add a handoff note:

```
./bin/gs-handoff.scm add \
  --scholar "Amina Noor" \
  --cohort "2026 Spring" \
  --priority "High" \
  --summary "Finalize FAFSA verification and confirm missing tax transcript." \
  --owner "S. Patel" \
  --due "2026-02-18"
```

List recent handoff notes:

```
./bin/gs-handoff.scm list --status "Open" --limit 10
```

Show a specific note:

```
./bin/gs-handoff.scm show 3
```

Close a note:

```
./bin/gs-handoff.scm close 3
```

Review status counts:

```
./bin/gs-handoff.scm stats
```

## Tests

```
guile tests/query-builder.scm
```

## Tech
- Guile Scheme
- PostgreSQL
