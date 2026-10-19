<div align="center">
  <h1>Claude-Voice</h1>
  <p>Голос для Claude Code: говорит и слушает в любой программе для голосового общения, весь звук обрабатывается локально.</p>
  <p>
    <img src="https://img.shields.io/badge/Linux-PipeWire-455a64?style=flat-square&amp;logo=linux&amp;logoColor=white" alt="Linux и PipeWire">
    <img src="https://img.shields.io/badge/Claude_Code-voice-D97757?style=flat-square&amp;logo=claude&amp;logoColor=white" alt="Claude Code">
    <img src="https://img.shields.io/badge/whisper.cpp-Vulkan-AC162C?style=flat-square&amp;logo=vulkan&amp;logoColor=white" alt="whisper.cpp на Vulkan">
    <img src="https://img.shields.io/badge/Piper-TTS-455a64?style=flat-square" alt="Синтез речи Piper">
    <img src="https://img.shields.io/badge/Python-3-3776AB?style=flat-square&amp;logo=python&amp;logoColor=white" alt="Python 3">
    <img src="https://img.shields.io/badge/root-not_required-2E7D32?style=flat-square" alt="Root не нужен">
    <a href="../LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--or--later-blue?style=flat-square" alt="Лицензия GPL-3.0 или новее"></a>
  </p>
  <p><strong>Русский</strong> · <a href="README.en.md">English</a></p>
</div>

Claude-Voice позволяет [Claude Code](https://claude.com/claude-code) участвовать
в голосовых чатах на Linux с PipeWire. Claude говорит в виртуальный микрофон
«Claude Mic» и слышит собеседников через устройство вывода «Voice Chat». Это
обычные системные устройства, поэтому подходит любая программа, где их можно
выбрать: Discord, Steam, Telegram, TeamSpeak, Mumble, звонки в браузере, игры.
Речь синтезирует [Piper](https://github.com/OHF-Voice/piper1-gpl),
распознаёт [whisper.cpp](https://github.com/ggml-org/whisper.cpp) на Vulkan —
оба работают на этой машине.

```text
твой микрофон ─┐
               ├─► Claude Mic ──► программа для звонков (ввод)
claude-say ────┘        (слышно и в твоих наушниках)

программа для звонков (вывод) ──► Voice Chat ──► твои наушники
                                       └──► claude-hear ──► whisper-server ──► transcript.jsonl
                                                                                    │
                                                          Claude Code ◄── claude-listen
```

## Содержание
- [Возможности](#возможности)
- [Использование](#использование)
- [Разработка](#разработка)
- [Тестирование](#тестирование)
- [Contributing](#contributing)
- [To do](#to-do)
- [Используемые компоненты](#используемые-компоненты)
- [Лицензия](#лицензия)

## Возможности
- **Виртуальные устройства.** Отдельный экземпляр PipeWire создаёт «Claude Mic»
  и «Voice Chat»; основной PipeWire не перезапускается, текущий звонок не
  обрывается. Настоящий микрофон подмешивается в Claude Mic, поэтому
  собеседники слышат и тебя, и Claude.
- **Локальное распознавание.** `claude-hear` слушает Voice Chat и твой
  микрофон, делит звук на фразы простым VAD и отправляет их в whisper-server
  (модель large-v3-turbo, Vulkan). Текст дописывается в
  `~/.local/state/claude-voice/transcript.jsonl`.
- **Фильтр оскорблений на устройстве.** До записи в расшифровку мат заменяется
  на `***`, а фразы, которые модель
  [rubert-tiny-toxicity](https://huggingface.co/cointegrated/rubert-tiny-toxicity)
  считает оскорблением, выбрасываются. Такие фразы не уходят Claude, и он на
  них не отвечает.
- **Локальный синтез.** `claude-say` озвучивает текст голосом Piper; в комплекте
  четыре русских голоса.
- **Обращение по имени.** `claude-listen` ждёт фразу со словом-обращением
  («Клод, …») и выводит её вместе с контекстом последней минуты.
- **Запуск одной командой.** `claude-chat` включает устройства и сразу
  открывает Claude Code в режиме голосового чата.
- **Значок в трее.** Логотип Claude показывает состояние: выключено, включено,
  Claude слушает, Claude говорит. Клик заводит Claude в голосовой чат или
  выключает всё.
- **Без root.** Всё ставится в домашний каталог и запускается user-юнитами
  systemd.

## Использование

### Требования
- Linux с PipeWire.
- `uv`, `git`, `cmake`, `ninja`, `glslc`, `curl`, `python3`.
- Видеокарта с драйвером Vulkan.
- [Claude Code](https://claude.com/claude-code).
- Для значка в трее — PyQt6 (необязательно).

### Установка
```sh
./install.sh
$EDITOR ~/.config/claude-voice/config   # MIC_SOURCE, VOICE, WAKE_WORDS
./install.sh                            # пересобрать конфиг PipeWire
claude-voice on
```

Скрипт ставит Piper в отдельный venv, собирает whisper.cpp с Vulkan, скачивает
модель и голоса, связывает команды в `~/.local/bin` и юниты в
`~/.config/systemd/user`. Повторный запуск пропускает готовые шаги. Все
настройки описаны в [config.example](../config.example).

В программе для звонков выбери устройство ввода **Claude Mic** и устройство
вывода **Voice Chat**. Если в программе нет выбора устройств, назначь их ей в
pavucontrol или в настройках звука KDE. Не делай Voice Chat выходом по умолчанию
для всей системы: тогда Claude будет расшифровывать и музыку, и видео.
`claude-voice off` убирает виртуальные устройства; после этого
верни в программах свои настоящие устройства.

### Основные команды
| Команда | Что делает |
|---|---|
| `claude-voice on\|off\|status` | включить/выключить устройства, whisper-server и распознавание |
| `claude-chat` | `claude-voice on` и сразу Claude Code в режиме голосового чата |
| `claude-say "текст"` | сказать в Claude Mic (и в наушники при `MONITOR=1`) |
| `claude-listen` | ждать фразу с обращением и вывести её с контекстом |
| `claude-listen --all` | ждать любую фразу |
| `claude-listen --recent --context 300` | показать последние пять минут |
| `claude-voice-tray` | значок в трее (запускается сам при входе в систему) |

### Значок в трее
`install.sh` включает `claude-voice-tray.service`: значок появляется при входе
в систему, сам Claude-Voice при этом остаётся выключенным.

| Значок | Состояние |
|---|---|
| серый | выключено |
| приглушённый оранжевый | устройства включены, Claude не в чате |
| оранжевый | Claude слушает (`claude-listen`) |
| оранжевый с зелёной точкой | Claude говорит (`claude-say`) |

Клик по выключенному значку запускает `claude-chat` в терминале, по
включённому — `claude-voice off`. Команду запуска Claude Code и терминал
задают `CLAUDE_CMD` и `TERMINAL` в `~/.config/claude-voice/config`;
`CLAUDE_CMD` может быть и алиасом из твоей оболочки.

### Голосовой чат из Claude Code
Открой Claude Code в каталоге проекта (или запусти `claude-chat`) и попроси
зайти в голосовой чат. Порядок работы описан в [CLAUDE.md](../CLAUDE.md):
Claude ждёт обращения через `claude-listen`, отвечает через `claude-say` и снова
слушает. Задержка ответа — несколько секунд: распознавание, ответ модели и
синтез речи.

### Приватность
Распознавание локальное, но текст речи всех в канале уходит Claude как часть
диалога. Предупреди собеседников.

- Пока Claude-Voice включён, твой микрофон распознаётся всегда, даже вне
  звонка. Выключенный Claude-Voice (серый значок) микрофон не записывает.
- Claude получает фразы, только пока слушает (`claude-listen`): фразу с
  обращением и минуту перед ней. Сказанное больше чем за две минуты до запуска
  `claude-listen` не засчитывается (`--max-age`), так что старый разговор не
  всплывёт при следующем запуске.
- Расшифровка хранится на диске сутки, потом удаляется
  (`TRANSCRIPT_KEEP_HOURS`).

### Фильтр оскорблений
Фильтр работает в `claude-hear` до записи в расшифровку, поэтому
отфильтрованное не попадает ни в файл, ни к Claude, ни на серверы Anthropic.
В журнале сервиса остаётся только отметка без текста:
`chat: phrase hidden (insult 1.00)`.

- Мат заменяется на `***` по списку слов, обычная фраза при этом доходит:
  «Клод, ***, сколько времени?».
- Оскорбления (`insult`) выбрасываются целиком. Угрозы (`threat`) по умолчанию
  не скрываются: модель путает с ними игровые фразы вроде «убей его, он слева».
- Настройки: `FILTER`, `FILTER_LABELS`, `FILTER_THRESHOLD` в
  `~/.config/claude-voice/config`.
- Если модель не загрузилась, `claude-hear` не запускается, а не пишет текст
  без фильтра.

Фильтр не идеален: модель иногда пропускает оскорбление или скрывает обычную
фразу. Просьбы о противозаконном она не распознаёт; на них отказывает сам
Claude, правила поведения в канале описаны в [CLAUDE.md](../CLAUDE.md).

## Разработка

### Структура
```
Claude-Voice/
  bin/            # claude-voice, claude-chat, claude-say, claude-hear, claude-listen
  lib/            # фильтр оскорблений для claude-hear
  icons/          # логотип Claude для значка в трее
  pipewire/       # шаблон конфига виртуальных устройств
  systemd/        # user-юниты и claude-voice.target
  config.example  # настройки, копируются в ~/.config/claude-voice/config
  install.sh      # установка без root
```

### Как устроено
`claude-voice.target` объединяет три юнита:

- `claude-voice-devices` — экземпляр PipeWire с Claude Mic и Voice Chat;
- `claude-whisper` — whisper-server на `127.0.0.1:8178`;
- `claude-hear` — запись монитора Voice Chat и распознавание.

Отдельно от них `claude-voice-tray.service` запускает значок в трее вместе с
графическим сеансом.

Данные лежат в `~/.local/share/claude-voice`, настройки — в
`~/.config/claude-voice`, расшифровка — в `~/.local/state/claude-voice`.

## Тестирование
После изменений проверь синтаксис, переустанови и перезапусти сервисы:

```sh
bash -n install.sh bin/claude-voice bin/claude-chat bin/claude-say
python3 -m py_compile bin/claude-hear bin/claude-listen bin/claude-voice-tray lib/speech_filter.py
./install.sh
systemctl --user restart claude-voice.target
```

Проверка слуха и голоса:

```sh
# слух: проиграть фразу в Voice Chat и дождаться её от claude-listen
pw-play --target voice_chat phrase.wav & claude-listen --all --timeout 15
# голос: записать Claude Mic во время claude-say
pw-record --target claude_mic --rate 16000 --channels 1 --raw /tmp/mic.raw & claude-say "проверка"
```

## Contributing
Сообщения об ошибках и предложения принимаются через
[Issues](https://github.com/BeleBob/Claude-Voice/issues). Изменения предлагаются
через pull request в ветку `main`; перед отправкой пройди шаги из раздела
[Тестирование](#тестирование).

## To do
- [x] Виртуальные устройства без перезапуска основного PipeWire
- [x] Локальное распознавание на whisper.cpp с Vulkan
- [x] Обращение по имени и контекст последней минуты
- [x] Свой микрофон подмешивается в Claude Mic и тоже распознаётся
- [x] Запуск одной командой — `claude-chat`
- [x] Фильтр мата и оскорблений на устройстве
- [x] Значок в трее
- [ ] Имена говорящих в расшифровке
- [ ] Другие языки: голоса Piper и язык whisper-server сейчас русские

## Используемые компоненты
- [Piper](https://github.com/OHF-Voice/piper1-gpl) и
  [голоса Piper](https://huggingface.co/rhasspy/piper-voices) — синтез речи.
- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) и модель Whisper
  large-v3-turbo — распознавание речи.
- [rubert-tiny-toxicity](https://huggingface.co/cointegrated/rubert-tiny-toxicity)
  ([ONNX](https://huggingface.co/onnx-community/rubert-tiny-toxicity-ONNX)) —
  фильтр оскорблений.
- [PipeWire](https://pipewire.org) — виртуальные устройства.
- Логотип Claude из [Simple Icons](https://simpleicons.org) (CC0) — значок в
  трее. Логотип — товарный знак Anthropic.

Компоненты скачиваются установщиком и распространяются по своим лицензиям,
подробности — в [NOTICE](../NOTICE). Голос `ruslan` обучен на корпусе с
лицензией CC BY-NC-SA 4.0 и годится только для некоммерческого использования.

## Лицензия
Распространяется по лицензии GNU GPL v3.0 или более поздней версии: см.
[LICENSE](../LICENSE), [COPYRIGHT](../COPYRIGHT) и [NOTICE](../NOTICE).
