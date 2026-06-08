# Privacy

Daymark is local-first software. It does not transmit notes or usage data.

## Stored data

Goals, tasks, reflections, and archives are stored in
`~/Library/Application Support/Daymark/daymark.json`. A separate JSON backup is
created only when the user selects **Export private data**.

## Email and Codex

Email is intentionally not built into Daymark. Users may configure their own Codex automation and their own email connector. Those credentials and messages are governed by the user's chosen tools, not by Daymark.

## Network behavior

The application code makes no network requests. GitHub distributes the public
source code only; productivity data stays on the user's Mac.

## Deletion

Deleting `~/Library/Application Support/Daymark` removes the app's complete
local record. Exported JSON files must be deleted separately by the user.
