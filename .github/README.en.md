<div align="center">
  <h1>Claude-Voice</h1>
  <p>A voice for Claude Code: it speaks and listens in any voice chat app, with all audio processed locally.</p>
  <p>
    <img src="https://img.shields.io/badge/Linux-PipeWire-455a64?style=flat-square&amp;logo=linux&amp;logoColor=white" alt="Linux and PipeWire">
    <img src="https://img.shields.io/badge/Claude_Code-voice-D97757?style=flat-square&amp;logo=claude&amp;logoColor=white" alt="Claude Code">
    <img src="https://img.shields.io/badge/whisper.cpp-Vulkan-AC162C?style=flat-square&amp;logo=vulkan&amp;logoColor=white" alt="whisper.cpp on Vulkan">
    <img src="https://img.shields.io/badge/Piper-TTS-455a64?style=flat-square" alt="Piper speech synthesis">
    <img src="https://img.shields.io/badge/Python-3-3776AB?style=flat-square&amp;logo=python&amp;logoColor=white" alt="Python 3">
    <img src="https://img.shields.io/badge/root-not_required-2E7D32?style=flat-square" alt="No root required">
    <a href="../LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--or--later-blue?style=flat-square" alt="GPL-3.0-or-later license"></a>
  </p>
  <p><a href="README.md">Русский</a> · <strong>English</strong></p>
</div>

Claude-Voice lets [Claude Code](https://claude.com/claude-code) take part in
voice chats on Linux with PipeWire. Claude speaks into the "Claude Mic" virtual
microphone and hears the others through the "Voice Chat" output device. These
are ordinary system devices, so any app that lets you pick them works: Discord,
Steam, Telegram, TeamSpeak, Mumble, browser calls, games. Speech is synthesized by
[Piper](https://github.com/OHF-Voice/piper1-gpl) and recognized by
[whisper.cpp](https://github.com/ggml-org/whisper.cpp) on Vulkan, both running
on this machine.

```text
your mic ───┐
            ├─► Claude Mic ──► voice chat app (input)
claude-say ─┘        (also played in your headphones)

voice chat app (output) ──► Voice Chat ──► your headphones
                                 └──► claude-hear ──► whisper-server ──► transcript.jsonl
                                                                             │
                                                     Claude Code ◄── claude-listen
```

## Contents
- [Features](#features)
- [Usage](#usage)
- [Development](#development)
- [Testing](#testing)
- [Contributing](#contributing)
- [To do](#to-do)
- [Third-party components](#third-party-components)
- [License](#license)

## Features
- **Virtual devices.** A separate PipeWire instance creates "Claude Mic" and
  "Voice Chat"; the main PipeWire is never restarted, so an ongoing call is not
  dropped. Your real microphone is mixed into Claude Mic, so the channel hears
  both you and Claude.
- **Local recognition.** `claude-hear` listens to Voice Chat and your mic,
  splits audio into phrases with a simple VAD and sends them to whisper-server
  (large-v3-turbo model, Vulkan). The text is appended to
  `~/.local/state/claude-voice/transcript.jsonl`.
- **On-device insult filter.** Before anything is written to the transcript,
  swear words are replaced with `***` and phrases that
  [rubert-tiny-toxicity](https://huggingface.co/cointegrated/rubert-tiny-toxicity)
  scores as insults are dropped. They never reach Claude, and it doesn't answer
  them.
- **Local synthesis.** `claude-say` speaks text with a Piper voice; four Russian
  voices are installed.
- **Wake word.** `claude-listen` waits for a phrase with a wake word
  ("Claude, …") and prints it with the last minute of context.
- **One command to start.** `claude-chat` turns the devices on and opens Claude
  Code already in voice chat mode.
- **Tray icon.** The Claude logo shows the state: off, on, Claude listening,
  Claude speaking. A click brings Claude into the voice chat or turns
  everything off.
- **No root.** Everything is installed into your home directory and runs as
  systemd user units.

## Usage

### Requirements
- Linux with PipeWire.
- `uv`, `git`, `cmake`, `ninja`, `glslc`, `curl`, `python3`.
- A GPU with a Vulkan driver.
- [Claude Code](https://claude.com/claude-code).
- PyQt6 for the tray icon (optional).

### Install
```sh
./install.sh
$EDITOR ~/.config/claude-voice/config   # MIC_SOURCE, VOICE, WAKE_WORDS
./install.sh                            # re-render the PipeWire config
claude-voice on
```

The script installs Piper into its own venv, builds whisper.cpp with Vulkan,
downloads the model and voices, and links the commands into `~/.local/bin` and
the units into `~/.config/systemd/user`. Running it again skips finished steps.
All settings are described in [config.example](../config.example).

In your voice chat app set the input device to **Claude Mic** and the output
device to **Voice Chat**. If the app has no device choice, assign the devices to
it in pavucontrol or the KDE sound settings. Don't make Voice Chat the system
default output: Claude would then transcribe music and videos too.
`claude-voice off` removes the virtual devices; switch
the apps back to your real devices afterwards.

### Main commands
| Command | What it does |
|---|---|
| `claude-voice on\|off\|status` | start/stop the devices, whisper-server and transcriber |
| `claude-chat` | `claude-voice on`, then open Claude Code already in voice chat mode |
| `claude-say "text"` | speak into Claude Mic (and your headphones with `MONITOR=1`) |
| `claude-listen` | wait for a phrase with a wake word, print it with recent context |
| `claude-listen --all` | return on any phrase |
| `claude-listen --recent --context 300` | print the last five minutes |
| `claude-voice-tray` | tray icon (starts by itself when you log in) |

### Tray icon
`install.sh` enables `claude-voice-tray.service`: the icon appears when you log
in, while Claude-Voice itself stays off.

| Icon | State |
|---|---|
| grey | off |
| dim orange | devices on, Claude not listening |
| orange | Claude is listening (`claude-listen`) |
| orange with a green dot | Claude is speaking (`claude-say`) |

Clicking the icon when off runs `claude-chat` in a terminal; when on, it runs
`claude-voice off`. `CLAUDE_CMD` and `TERMINAL` in
`~/.config/claude-voice/config` set the command that starts Claude Code and
the terminal; `CLAUDE_CMD` can be an alias from your shell.

### Voice chat from Claude Code
Open Claude Code in the project directory (or run `claude-chat`) and ask it to
join the voice chat. [CLAUDE.md](../CLAUDE.md) describes the loop: Claude waits
for a wake word with `claude-listen`, answers with `claude-say` and listens
again. Expect a few seconds of delay per reply: recognition, the model's answer
and speech synthesis add up.

### Privacy
Recognition is local, but the transcribed speech of everyone in the channel is
sent to Claude as part of the conversation. Tell the people in the channel.

- While Claude-Voice is on, your microphone is transcribed all the time, even
  outside a call. When it's off (grey icon) the microphone isn't recorded.
- Claude gets phrases only while it listens (`claude-listen`): the phrase with
  the wake word and the minute before it. Anything said more than two minutes
  before `claude-listen` started doesn't count (`--max-age`), so an old
  conversation won't surface the next time it starts.
- The transcript is kept on disk for a day, then deleted
  (`TRANSCRIPT_KEEP_HOURS`).

### Insult filter
The filter runs in `claude-hear` before the transcript is written, so filtered
speech never reaches the file, Claude or Anthropic's servers. The service
journal keeps only a note without the text: `chat: phrase hidden (insult 1.00)`.

- Swear words are replaced with `***` from a word list; the rest of the phrase
  still gets through: "Клод, ***, сколько времени?".
- Insults (`insult`) are dropped whole. Threats (`threat`) are not hidden by
  default: the model mistakes game talk like "убей его, он слева" for them.
- Settings: `FILTER`, `FILTER_LABELS`, `FILTER_THRESHOLD` in
  `~/.config/claude-voice/config`.
- If the model fails to load, `claude-hear` refuses to start instead of writing
  unfiltered text.

The filter isn't perfect: the model sometimes misses an insult or hides a
harmless phrase. It doesn't detect requests for something illegal; Claude
refuses those itself, and the conduct rules for the channel are in
[CLAUDE.md](../CLAUDE.md).

## Development

### Layout
```
Claude-Voice/
  bin/            # claude-voice, claude-chat, claude-say, claude-hear, claude-listen
  lib/            # insult filter for claude-hear
  icons/          # Claude logo for the tray icon
  pipewire/       # virtual devices config template
  systemd/        # user units and claude-voice.target
  config.example  # settings, copied to ~/.config/claude-voice/config
  install.sh      # rootless installer
```

### How it works
`claude-voice.target` groups three units:

- `claude-voice-devices` — the PipeWire instance with Claude Mic and Voice Chat;
- `claude-whisper` — whisper-server on `127.0.0.1:8178`;
- `claude-hear` — records the Voice Chat monitor and transcribes it.

Separately, `claude-voice-tray.service` runs the tray icon with the graphical
session.

Data lives in `~/.local/share/claude-voice`, settings in
`~/.config/claude-voice`, the transcript in `~/.local/state/claude-voice`.

## Testing
After changes, check the syntax, reinstall and restart the services:

```sh
bash -n install.sh bin/claude-voice bin/claude-chat bin/claude-say
python3 -m py_compile bin/claude-hear bin/claude-listen bin/claude-voice-tray lib/speech_filter.py
./install.sh
systemctl --user restart claude-voice.target
```

Hearing and speaking checks:

```sh
# hearing: play a phrase into Voice Chat, expect it back from claude-listen
pw-play --target voice_chat phrase.wav & claude-listen --all --timeout 15
# speaking: record Claude Mic while claude-say talks
pw-record --target claude_mic --rate 16000 --channels 1 --raw /tmp/mic.raw & claude-say "проверка"
```

## Contributing
Bug reports and suggestions go to
[Issues](https://github.com/BeleBob/Claude-Voice/issues). Changes are proposed as
pull requests to `main`; run the steps from [Testing](#testing) before sending
one.

## To do
- [x] Virtual devices without restarting the main PipeWire
- [x] Local recognition with whisper.cpp on Vulkan
- [x] Wake word and the last minute of context
- [x] Your own mic is mixed into Claude Mic and transcribed too
- [x] One command to start — `claude-chat`
- [x] On-device swearing and insult filter
- [x] Tray icon
- [ ] Speaker names in the transcript
- [ ] Other languages: Piper voices and the whisper-server language are Russian for now

## Third-party components
- [Piper](https://github.com/OHF-Voice/piper1-gpl) and
  [Piper voices](https://huggingface.co/rhasspy/piper-voices) — speech synthesis.
- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) and the Whisper
  large-v3-turbo model — speech recognition.
- [rubert-tiny-toxicity](https://huggingface.co/cointegrated/rubert-tiny-toxicity)
  ([ONNX](https://huggingface.co/onnx-community/rubert-tiny-toxicity-ONNX)) —
  insult filter.
- [PipeWire](https://pipewire.org) — virtual devices.
- The Claude logo from [Simple Icons](https://simpleicons.org) (CC0) — tray
  icon. The logo is a trademark of Anthropic.

The components are downloaded by the installer and come under their own
licenses; see [NOTICE](../NOTICE). The `ruslan` voice is trained on a CC
BY-NC-SA 4.0 corpus and is for non-commercial use only.

## License
Distributed under the GNU GPL v3.0 or later: see [LICENSE](../LICENSE),
[COPYRIGHT](../COPYRIGHT) and [NOTICE](../NOTICE).
