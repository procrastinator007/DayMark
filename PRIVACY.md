# Privacy

Daymark is local-first software. It does not transmit notes or usage data.

## Stored data

Goals, tasks, reflections, and archives are stored in browser `localStorage`. A JSON backup is created only when the user selects **Export data**.

## Email and Codex

Email is intentionally not built into Daymark. Users may configure their own Codex automation and their own email connector. Those credentials and messages are governed by the user's chosen tools, not by Daymark.

## Network behavior

The application code makes no network requests. Hosting the static application on GitHub Pages downloads the public code, but productivity data remains in that browser's storage.

## Deletion

Users can delete individual entries in the interface. Clearing site data in the browser deletes the complete local record. Exported JSON files must be deleted separately by the user.
