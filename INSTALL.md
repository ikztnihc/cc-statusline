# Statusline install

Two files:

- `statusline-command.sh` - the statusline script.
- `settings-statusline-snippet.json` - the `statusLine` block for `settings.json`.

## Install

1. Copy `statusline-command.sh` to `~/.claude/statusline-command.sh` on the target machine.
2. Merge the `statusLine` block from `settings-statusline-snippet.json` into `~/.claude/settings.json`. If that file already has other keys, add `statusLine` alongside them; do not overwrite the whole file.
3. Start a new session (or wait for the next render). The statusline updates on activity, not on an idle timer.

## What it shows

`[~/folder] [ctx bar %|used/max|remaining-to-83%] [Exp:HH:MM] [date time|S:5h% reset|W:week% reset] [Claude <model> <effort>] [owner/name/worktree #PR]`

- Context bar plus tokens remaining until auto-compact (83%).
- `Exp:` = prompt-cache expiry, local 24-hour time. It reflects the last render, so read it against your clock. `--:--` means no cache expiry in the payload.
- `S:` 5-hour and `W:` 7-day rate-limit use plus reset time.
- Model color: Opus, Fable (dark orange), Sonnet, Haiku. Effort glyph: low `o`, medium, high, xhigh, max, absent falls back to white.
- Repo segment: `owner/name` (dark), `/worktree` (light, only in a worktree), ` #PR` (only when the branch has a PR). `#PR` is a clickable OSC 8 link coloured by review state: amber pending, dim draft, green approved, red changes-requested.
- The per-session colour is seeded from the session id, so each session gets its own hue.

## Requirements on the target machine

The script needs all three, or segments degrade to defaults:

1. **bash** - the command runs `bash`.
2. **A working Python** - `python3`, `python`, or `py`. The script probes for one; without it, model, context, rate limits, effort, repo, and cache all fall back to defaults (folder, date, and time still work).
3. **GNU `date`** - the reset and `Exp:` times use `date -d @<epoch>`. BSD/macOS `date` uses different flags, so on macOS install coreutils and adjust, or those times show `??` / `--:--`.

## Colour and clickable-link notes

- Colours are 24-bit truecolor ANSI. The terminal must support truecolor.
- The `#PR` link uses an OSC 8 hyperlink terminated with BEL (`\a`). Do not switch the terminator to `ESC \`; that broke colour escapes after the link in testing. BEL is the working form.
