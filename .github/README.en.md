# claude-voice

**English** | [Русский](README.ru.md)

Let [Claude Code](https://claude.com/claude-code) speak and listen in Discord
and Steam voice chats on Linux with PipeWire. Everything audio-related runs
locally: [Piper](https://github.com/OHF-Voice/piper1-gpl) for speech and
[whisper.cpp](https://github.com/ggml-org/whisper.cpp) (Vulkan) for recognition.

```
your mic ──┐
           ├─► Claude Mic ──► Discord / Steam (input)
claude-say ┘        (also played in your headphones)

Discord / Steam (output) ──► Voice Chat ──► your headphones
                                  └──► claude-hear ──► whisper-server ──► transcript.jsonl
                                                                              │
                                                     Claude Code ◄── claude-listen
```

## Install

Needs PipeWire, `uv`, `git`, `cmake`, `ninja`, `glslc` and a Vulkan GPU driver.
No root required.

```sh
./install.sh
$EDITOR ~/.config/claude-voice/config   # MIC_SOURCE, VOICE, WAKE_WORDS
./install.sh                            # re-render the PipeWire config
claude-voice on
```

In Discord and Steam set the input device to **Claude Mic** and the output
device to **Voice Chat**. Your own voice still goes through: the real
microphone is mixed into Claude Mic.

`claude-voice off` removes the virtual devices; switch the apps back to your
real devices afterwards.

## Commands

| Command | What it does |
|---|---|
| `claude-voice on\|off\|status` | start/stop the devices, whisper-server and transcriber |
| `claude-chat` | `claude-voice on`, then open Claude Code here already listening |
| `claude-say "text"` | speak into Claude Mic (and your headphones with `MONITOR=1`) |
| `claude-listen` | wait for a phrase with a wake word, print it with recent context |
| `claude-listen --all` | return on any phrase |
| `claude-listen --recent --context 300` | print the last five minutes |

## Using it from Claude Code

Open Claude Code in this directory and ask it to join the voice chat;
[CLAUDE.md](CLAUDE.md) tells it how to run the listen/answer loop. Expect a few
seconds of delay per reply: recognition, the model's answer and speech
synthesis add up.

## Privacy

Recognition is local, but the transcribed text of everyone in the channel is
sent to Claude as part of the conversation. Tell the people in the channel.

## Checks

```sh
# hearing: play a phrase into Voice Chat, expect it back from claude-listen
pw-play --target voice_chat phrase.wav & claude-listen --all --timeout 15
# speaking: record Claude Mic while speaking
pw-record --target claude_mic --rate 16000 --channels 1 --raw /tmp/mic.raw & claude-say "проверка"
```
