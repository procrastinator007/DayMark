# Daymark for macOS

Daymark is a lightweight, native, privacy-first macOS app made of four movable
sticky windows plus a compact yesterday-score panel:

- Things I need to do today
- Things I need to do tomorrow
- Things I did today
- Things to do this week
- Yesterday's evidence-based score and late-log entry

Tomorrow's editable list becomes today's locked plan on the next date. A
natural-language daily log can complete matching tasks and increment habits
such as `Gym 0/7`.

The weekly sticky is locked during the week. On Sunday it reveals an editable
**Things to do next week** section. That draft locks and becomes the current
week automatically on Monday.

## Privacy contract

- No account, hosted backend, analytics, telemetry, or third-party API.
- Notes stay in `~/Library/Application Support/Daymark/daymark.json`.
- Reports are generated locally.
- Users export their own JSON and use their own Codex installation and email connector.
- Daymark never receives Codex credentials, email credentials, or productivity data.

Regular JSON exports are recommended as private backups.

## Requirements

- macOS 13 or later
- Xcode Command Line Tools or Xcode
- No third-party packages

The first native build may require accepting Apple's Xcode license:

```bash
sudo /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -license accept
```

## Build the app

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open dist/Daymark.app
```

The app appears as a `D` in the menu bar. Use that menu to restore all
stickies, opt into Launch at Login, or export private data and reports.

## Tests

```bash
swift test
```

## Code layout

- `Windows/`: one controller per sticky window
- `Logic/`: rollover, goal parsing, date rules, and progress matching
- `Analytics/`: independent weekly and monthly report generation
- `Scoring/`: replaceable daily scoring logic
- `Storage/`: local JSON persistence
- `Style/`: shared colors, typography, and controls
- `Prompts/`: complete Codex analysis prompts

## Personal Codex automation

The repository includes templates in `automation/` for weekly and monthly
reports. Each user configures these prompts in their own Codex environment and
chooses their own email connector. The automation reads only that user's
exported Daymark file.

## Share on GitHub

This repository contains application code only. Personal productivity data is
stored outside the repository and excluded from Git.
