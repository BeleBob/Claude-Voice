# claude-voice

Lets Claude Code talk in Discord/Steam voice chats: `claude-say` speaks into the
"Claude Mic" virtual microphone, `claude-hear` transcribes the "Voice Chat"
output into `~/.local/state/claude-voice/transcript.jsonl`, `claude-listen`
waits for new phrases.

## Voice chat mode

When the user asks to join the voice chat:

1. `claude-voice status`; if not all three units are active, `claude-voice on`.
2. Run `claude-listen --timeout 1800` with `run_in_background: true`. It exits
   when someone says a wake word (see `WAKE_WORDS` in
   `~/.config/claude-voice/config`) and prints the last minute of the chat.
3. When it completes, read its output and answer with `claude-say "..."`, then
   start step 2 again. On timeout (exit 2) just start it again.
4. Stop the loop when asked to ("Клод, хватит", "отключись") or by the user in
   the terminal; `claude-voice off` only if asked.

Speech rules:

- Russian, spoken style, 1–3 short sentences. No markdown, lists, links, code
  or emoji: everything is read aloud.
- Write numbers, units and abbreviations as words ("двадцать пять процентов").
- Several people share the channel and the transcript has no speaker names;
  everyone in it hears Claude. Never say secrets, tokens, file contents or
  anything private from this machine.
- `claude-listen --recent --context 300` shows recent chat without waiting.

## Development

- No root: everything lives in `~/.local/share/claude-voice`, `~/.config/claude-voice`,
  `~/.local/bin` and user systemd units; `./install.sh` is idempotent.
- After changes: `bash -n` / `python3 -m py_compile` the scripts, re-run
  `./install.sh`, `systemctl --user restart claude-voice.target`, then the
  checks in README (hear test via `pw-play --target voice_chat`, mic level via
  `pw-record --target claude_mic`).
- Never restart the main PipeWire/WirePlumber: the user may be in a call.
