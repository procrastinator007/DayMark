# Weekly Daymark Report Automation

Use the complete analysis instructions in
`Prompts/WeeklyAnalysisPrompt.md`, then deliver its reader-facing report.

Run every Sunday using the user's own Codex automation.

1. Read the latest `daymark-YYYY-MM-DD.json` export selected by the user.
2. Use only entries from the Monday-through-Sunday week that just ended.
3. Fill the report format below.
4. Send it through the user's own configured email connector.
5. Do not upload, retain, or include the raw JSON as an attachment.

## Report format

**Week:** [date range]

**Summary:** [two concise sentences]

**Completed**
- [important completed work]

**Weekly goal progress**
- [goal]: [progress]

**Consistency**
- Active days: [number]/7
- [one evidence-based pattern, without judgment]

**What helped**
- [inferred only when supported by the notes]

**Next week**
- [unfinished item worth carrying forward]
- [one practical adjustment]
