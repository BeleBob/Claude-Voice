<div align="center">
  <h1>claude-voice</h1>
  <p>A voice for Claude Code: it speaks and listens in Discord and Steam voice chats, with all audio processed locally.</p>
  <p>
    <img src="https://img.shields.io/badge/Linux-PipeWire-455a64?style=flat-square&amp;logo=linux&amp;logoColor=white" alt="Linux and PipeWire">
    <img src="https://img.shields.io/badge/Claude_Code-voice-D97757?style=flat-square&amp;logo=claude&amp;logoColor=white" alt="Claude Code">
    <img src="https://img.shields.io/badge/whisper.cpp-Vulkan-AC162C?style=flat-square&amp;logo=vulkan&amp;logoColor=white" alt="whisper.cpp on Vulkan">
    <img src="https://img.shields.io/badge/Piper-TTS-455a64?style=flat-square" alt="Piper speech synthesis">
    <img src="https://img.shields.io/badge/Python-3-3776AB?style=flat-square&amp;logo=python&amp;logoColor=white" alt="Python 3">
    <img src="https://img.shields.io/badge/root-not_required-2E7D32?style=flat-square" alt="No root required">
  </p>
  <p><a href="README.md">Русский</a> · <strong>English</strong></p>
</div>

claude-voice lets [Claude Code](https://claude.com/claude-code) take part in
Discord and Steam voice chats on Linux with PipeWire. Claude speaks into the
"Claude Mic" virtual microphone and hears the others through the "Voice Chat"
output device. Speech is synthesized by
[Piper](https://github.com/OHF-Voice/piper1-gpl) and recognized by
[whisper.cpp](https://github.com/ggml-org/whisper.cpp) on Vulkan, both running
on this machine.

```text
your mic ───┐
            ├─► Claude Mic ──► Discord / Steam (input)
claude-say ─┘        (also played in your headphones)

Discord / Steam (output) ──► Voice Chat ──► your headphones
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

## Features
- **Virtual devices.** A separate PipeWire instance creates "Claude Mic" and
  "Voice Chat"; the main PipeWire is never restarted, so an ongoing call is not
  dropped. Your real microphone is mixed into Claude Mic, so the channel hears
  both you and Claude.
- **Local recognition.** `claude-hear` listens to Voice Chat and your mic,
  splits audio into phrases with a simple VAD and sends them to whisper-server
  (large-v3-turbo model, Vulkan). The text
  is appended to `~/.local/state/claude-voice/transcript.jsonl`.
- **Local synthesis.** `claude-say` speaks text with a Piper voice; four Russian
  voices are installed.
- **Wake word.** `claude-listen` waits for a phrase with a wake word
  ("Claude, …") and prints it with the last minute of context.
- **One command to start.** `claude-chat` turns the devices on and opens Claude
  Code already in voice chat mode.
- **No root.** Everything is installed into your home directory and runs as
  systemd user units.

## Usage

### Requirements
- Linux with PipeWire.
- `uv`, `git`, `cmake`, `ninja`, `glslc`, `curl`, `python3`.
- A GPU with a Vulkan driver.
- [Claude Code](https://claude.com/claude-code).

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

In Discord and Steam set the input device to **Claude Mic** and the output
device to **Voice Chat**. `claude-voice off` removes the virtual devices; switch
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

### Voice chat from Claude Code
Open Claude Code in the project directory (or run `claude-chat`) and ask it to
join the voice chat. [CLAUDE.md](../CLAUDE.md) describes the loop: Claude waits
for a wake word with `claude-listen`, answers with `claude-say` and listens
again. Expect a few seconds of delay per reply: recognition, the model's answer
and speech synthesis add up.

### Privacy
Recognition is local, but the transcribed speech of everyone in the channel is
sent to Claude as part of the conversation. Tell the people in the channel.

## Development

### Layout
```
claude-voice/
  bin/            # claude-voice, claude-chat, claude-say, claude-hear, claude-listen
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

Data lives in `~/.local/share/claude-voice`, settings in
`~/.config/claude-voice`, the transcript in `~/.local/state/claude-voice`.

## Testing
After changes, check the syntax, reinstall and restart the services:

```sh
bash -n install.sh bin/claude-voice bin/claude-chat bin/claude-say
python3 -m py_compile bin/claude-hear bin/claude-listen
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
[Issues](https://github.com/BeleBob/claude-voice/issues). Changes are proposed as
pull requests to `main`; run the steps from [Testing](#testing) before sending
one.

## To do
- [x] Virtual devices without restarting the main PipeWire
- [x] Local recognition with whisper.cpp on Vulkan
- [x] Wake word and the last minute of context
- [x] Your own mic is mixed into Claude Mic and transcribed too
- [x] One command to start — `claude-chat`
- [ ] Speaker names in the transcript
- [ ] Other languages: Piper voices and the whisper-server language are Russian for now

## Third-party components
- [Piper](https://github.com/OHF-Voice/piper1-gpl) and
  [Piper voices](https://huggingface.co/rhasspy/piper-voices) — speech synthesis.
- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) and the Whisper
  large-v3-turbo model — speech recognition.
- [PipeWire](https://pipewire.org) — virtual devices.

The components are downloaded by the installer and come under their own
licenses.
