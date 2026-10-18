#!/usr/bin/env bash
# Install claude-voice for the current user. Safe to run again: finished steps
# are skipped. Nothing here needs root.
set -euo pipefail

WHISPER_TAG=v1.9.5
WHISPER_MODEL=ggml-large-v3-turbo.bin

repo=$(cd "$(dirname "$0")" && pwd)
data=${XDG_DATA_HOME:-$HOME/.local/share}/claude-voice
conf_dir=${XDG_CONFIG_HOME:-$HOME/.config}/claude-voice
units=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user
bindir=$HOME/.local/bin

step() { printf '\n==> %s\n' "$*"; }

for cmd in pipewire pw-play pw-record pactl uv git cmake ninja curl glslc python3; do
    command -v "$cmd" >/dev/null || { echo "missing: $cmd" >&2; exit 1; }
done
mkdir -p "$data" "$conf_dir" "$units" "$bindir"

step "config"
if [[ ! -f $conf_dir/config ]]; then
    cp "$repo/config.example" "$conf_dir/config"
    echo "created $conf_dir/config, check MIC_SOURCE in it"
fi
# shellcheck source=/dev/null
. "$conf_dir/config"
pactl list sources short | cut -f2 | grep -qxF "$MIC_SOURCE" ||
    echo "warning: MIC_SOURCE=$MIC_SOURCE is not a current source (pactl list sources short)"
sed "s|@MIC_SOURCE@|$MIC_SOURCE|" "$repo/pipewire/claude-voice.conf.in" >"$conf_dir/pipewire.conf"

step "piper (text to speech)"
if [[ ! -x $data/venv/bin/piper ]]; then
    uv venv -q --python 3.13 "$data/venv"
    uv pip install -q --python "$data/venv/bin/python" piper-tts
fi
mkdir -p "$data/voices"
voice_url=https://huggingface.co/rhasspy/piper-voices/resolve/main/ru/ru_RU
for v in denis dmitri irina ruslan; do
    for ext in onnx onnx.json; do
        f=$data/voices/ru_RU-$v-medium.$ext
        if [[ ! -f $f ]]; then
            curl -fsSL -o "$f.part" "$voice_url/$v/medium/ru_RU-$v-medium.$ext"
            mv "$f.part" "$f"
        fi
    done
done

step "whisper.cpp $WHISPER_TAG with Vulkan (speech to text)"
if [[ ! -x $data/whisper/bin/whisper-server ]]; then
    mkdir -p "$data/src"
    # SPIRV-Headers is needed by the Vulkan backend and is not always installed system-wide.
    [[ -d $data/src/SPIRV-Headers ]] ||
        git clone -q --depth 1 https://github.com/KhronosGroup/SPIRV-Headers.git "$data/src/SPIRV-Headers"
    cmake -S "$data/src/SPIRV-Headers" -B "$data/src/SPIRV-Headers/build" -G Ninja \
        -DCMAKE_INSTALL_PREFIX="$data/deps" -DSPIRV_HEADERS_ENABLE_TESTS=OFF >/dev/null
    cmake --install "$data/src/SPIRV-Headers/build" >/dev/null
    [[ -d $data/src/whisper.cpp ]] ||
        git clone -q --depth 1 --branch "$WHISPER_TAG" https://github.com/ggml-org/whisper.cpp.git "$data/src/whisper.cpp"
    CXXFLAGS="-I$data/deps/include" cmake -S "$data/src/whisper.cpp" -B "$data/src/whisper.cpp/build" -G Ninja \
        -DBUILD_SHARED_LIBS=OFF -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release \
        -DWHISPER_BUILD_TESTS=OFF -DWHISPER_SDL2=OFF \
        -DCMAKE_PREFIX_PATH="$data/deps" -DCMAKE_INSTALL_PREFIX="$data/whisper" >/dev/null
    cmake --build "$data/src/whisper.cpp/build" -j"$(nproc)" >/dev/null
    cmake --install "$data/src/whisper.cpp/build" >/dev/null
fi
mkdir -p "$data/models"
if [[ ! -f $data/models/$WHISPER_MODEL ]]; then
    curl -fL -o "$data/models/$WHISPER_MODEL.part" \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$WHISPER_MODEL"
    mv "$data/models/$WHISPER_MODEL.part" "$data/models/$WHISPER_MODEL"
fi

step "commands and services"
for f in "$repo"/bin/*; do
    ln -sf "$f" "$bindir/$(basename "$f")"
done
for f in "$repo"/systemd/*; do
    ln -sf "$f" "$units/$(basename "$f")"
done
systemctl --user daemon-reload

step "done"
echo "Turn on:  claude-voice on      Turn off: claude-voice off"
