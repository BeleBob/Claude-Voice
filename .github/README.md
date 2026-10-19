# claude-voice

[English](README.md) | **Русский**

Позволяет [Claude Code](https://claude.com/claude-code) говорить и слушать в
голосовых чатах Discord и Steam на Linux с PipeWire. Вся работа со звуком
локальная: [Piper](https://github.com/OHF-Voice/piper1-gpl) для речи и
[whisper.cpp](https://github.com/ggml-org/whisper.cpp) (Vulkan) для распознавания.

## Установка

Нужны PipeWire, `uv`, `git`, `cmake`, `ninja`, `glslc` и драйвер Vulkan. Root не нужен.

```sh
./install.sh
$EDITOR ~/.config/claude-voice/config   # MIC_SOURCE, VOICE, WAKE_WORDS
./install.sh                            # пересобрать конфиг PipeWire
claude-voice on
```

В Discord и Steam выбрать устройство ввода **Claude Mic**, вывода — **Voice Chat**.
Твой голос тоже проходит: настоящий микрофон подмешивается в Claude Mic.

`claude-voice off` убирает виртуальные устройства; после этого верни в
программах свои настоящие устройства.

## Команды

| Команда | Что делает |
|---|---|
| `claude-voice on\|off\|status` | включить/выключить устройства, whisper-server и распознавание |
| `claude-chat` | `claude-voice on` и сразу Claude Code в режиме голосового чата |
| `claude-say "текст"` | сказать в Claude Mic (и в наушники при `MONITOR=1`) |
| `claude-listen` | ждать фразу с обращением («Клод, …») и вывести её с контекстом |
| `claude-listen --all` | ждать любую фразу |
| `claude-listen --recent --context 300` | показать последние пять минут |

## Как пользоваться из Claude Code

Открой Claude Code в этой папке и попроси зайти в голосовой чат — порядок
работы описан в [CLAUDE.md](CLAUDE.md). Задержка ответа — несколько секунд:
распознавание, ответ модели и синтез речи.

## Приватность

Распознавание локальное, но текст речи всех в канале уходит Claude как часть
диалога. Предупреди собеседников.
