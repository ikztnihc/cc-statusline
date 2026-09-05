# cc-statusline

A custom status line for Claude Code. It reads the JSON that Claude Code sends on every render and prints one dense line: context use, cache expiry, rate limits, the model, the effort level, and the repository you are in, with a clickable pull-request link.

## A line at a glance

```
[~/project] [█████████───────────48%|480K/1M|350K] [Sep4 17:40|Exp:19:16] [S:20% 18:00|W:2% TH00] [Claude Opus 4.8 ◑] [owner/repo/worktree #405]
```

Every session picks its own two colors from a hash of the session id, so two sessions side by side never look alike. The line uses those two colors throughout: a lighter one and a darker one.

## Segments, left to right

- **Folder** (`~/project`): the current directory name.
- **Context** (`█████───── 48%|480K/1M|350K`): a 20-character bar, the percent of the context window in use, the used and maximum tokens, and the tokens left before auto-compact. The remaining figure counts down to 83 percent, where auto-compact fires, and it turns red past 60 percent of the window.
- **Date, time, and cache expiry** (`Sep4 17:40|Exp:19:16`): the current date and 24-hour time, then `Exp:`, the local 24-hour time when the prompt cache goes cold. The status line does not tick while idle, so read `Exp:` against your clock rather than as a live countdown. `--:--` means the payload carried no expiry.
- **Rate limits** (`S:20% 18:00|W:2% TH00`): their own group. `S:` is the 5-hour window, `W:` is the 7-day window. Each shows the percent used and the reset time. The percent uses a traffic-light color: green under 25, yellow to 49, orange to 74, then red at 75 and up.
- **Model and effort** (`Claude Opus 4.8 ◑`): the model name, colored per family (Opus, Fable, Sonnet, Haiku), and the reasoning effort as a filling circle: `◌` low, `◔` medium, `◑` high, `◕` xhigh, `●` max. An effort-less model shows `◌`.
- **Repository** (`owner/repo/worktree #405`): the remote owner and repo name, then the git worktree name when you are in one, then the pull-request number when the branch has a PR.

## The clickable PR link

The `#405` is a real hyperlink. Click it to open the pull request. Its color reports the review state, so a new PR is visible at a glance:

- **amber**: the PR exists and is pending, your attention is coming.
- **dim gray**: still a draft.
- **green**: approved.
- **red**: changes requested.

The link uses an OSC 8 escape terminated with BEL. Keep that terminator; the `ESC \` form broke the color codes after the link in testing.

## Install

See [INSTALL.md](INSTALL.md). In short: copy `statusline-command.sh` to `~/.claude/`, merge the block from `settings-statusline-snippet.json` into `~/.claude/settings.json`, and start a new session.

## What each machine needs

- **bash**, to run the script.
- **A working Python** (`python3`, `python`, or `py`). Without one, the folder, date, and time still show, but the data-driven segments fall back to defaults.
- **GNU `date`**, for the reset and cache times. The macOS and BSD `date` use different flags, so install coreutils there or those times read `??` and `--:--`.
- **A truecolor terminal**, since the colors are 24-bit.
