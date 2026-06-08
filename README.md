# Daymark

Daymark is a privacy-first, local productivity app built around three notes:

- weekly goals
- things completed today
- things to do tomorrow

Tomorrow's list becomes today's plan on the next date. A natural-language daily log can complete matching tasks and increment habits such as `Gym 0/7`.

## Privacy contract

- No account, hosted backend, analytics, telemetry, or third-party API.
- Notes stay in the browser's local storage on the user's device.
- Reports are generated locally.
- Users export their own JSON and use their own Codex installation and email connector.
- Daymark never receives Codex credentials, email credentials, or productivity data.

Clearing browser data removes the local record, so regular JSON exports are recommended.

## Run locally

No dependencies need to be installed.

```bash
node server.js
```

Open `http://localhost:4173`.

## Test

```bash
node --test
```

## Personal Codex automation

The repository includes templates in [`automation/`](automation/) for weekly and monthly reports. Each user configures these prompts in their own Codex environment and chooses their own email connector. The automation reads only the user's exported Daymark file.

## Share on GitHub

This repository contains application code only. User data is held in browser storage and is excluded from Git. GitHub Pages can host the static files, but local storage remains scoped to that browser and origin.
