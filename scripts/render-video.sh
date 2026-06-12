#!/usr/bin/env bash
#
# render-video.sh — produce an X-spec mp4 from a video source.
#
# Source types (by extension):
#   .cast         asciinema recording  (requires agg)
#   .tape         VHS script           (requires vhs; tape must declare an
#                                       Output ending in .mp4 or .gif)
#   .slides.txt   text slides separated by a line containing only "---",
#                 rendered with ffmpeg drawtext (no extra dependencies)
#   .mp4 / .mov / .gif   existing footage — normalized only
#
# Output (default videos/<base>.mp4) is normalized to X upload spec:
#   1280x720 letterboxed, 30fps, H.264 yuv420p, faststart, no audio.
#   (X limits: H.264+AAC only, <=140s and <=512MB on a standard account.
#    SOP targets ~15s; the script warns above 30s and fails above 140s.)
#
# Usage:
#   scripts/render-video.sh <source> [output.mp4]
#   SLIDE_SECONDS=4 scripts/render-video.sh videos/topic.slides.txt
#
# Naming convention: give the source the draft's basename without the
# language suffix (drafts/2026-06-15-topic-en.md -> videos/2026-06-15-topic.*)
# so watch-and-publish.sh can pair them automatically.

set -euo pipefail

SRC="${1:?Usage: $0 <source> [output.mp4]}"
[[ -f "$SRC" ]] || { echo "Error: source not found: $SRC" >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo "Error: ffmpeg not found in PATH" >&2; exit 1; }
command -v ffprobe >/dev/null || { echo "Error: ffprobe not found in PATH" >&2; exit 1; }

name=$(basename "$SRC")
base=$name
for ext in .slides.txt .cast .tape .mp4 .mov .gif; do
  base=${base%"$ext"}
done
OUT="${2:-videos/$base.mp4}"
mkdir -p "$(dirname "$OUT")"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

case "$name" in
  *.cast)
    command -v agg >/dev/null || { echo "Error: .cast source needs agg (asciinema gif generator)" >&2; exit 1; }
    agg "$SRC" "$TMP/raw.gif"
    RAW="$TMP/raw.gif"
    ;;
  *.tape)
    command -v vhs >/dev/null || { echo "Error: .tape source needs vhs (charmbracelet)" >&2; exit 1; }
    TAPE_OUT=$(grep -oE '^Output[[:space:]]+[^[:space:]]+\.(mp4|gif)' "$SRC" | awk '{print $2}' | head -1)
    [[ -n "$TAPE_OUT" ]] || { echo "Error: tape must declare an Output ending in .mp4 or .gif" >&2; exit 1; }
    vhs "$SRC"
    [[ -f "$TAPE_OUT" ]] || { echo "Error: vhs did not produce $TAPE_OUT" >&2; exit 1; }
    RAW="$TAPE_OUT"
    ;;
  *.slides.txt)
    mkdir -p "$TMP/slides"
    awk -v dir="$TMP/slides" '
      /^---[[:space:]]*$/ { n++; next }
      { print > (dir "/" sprintf("%03d", n) ".txt") }
    ' n=0 "$SRC"
    SLIDE_FILES=("$TMP"/slides/*.txt)
    [[ -s "${SLIDE_FILES[0]}" ]] || { echo "Error: no slides parsed from $SRC" >&2; exit 1; }
    DUR=${SLIDE_SECONDS:-3}
    : > "$TMP/concat.txt"
    for s in "${SLIDE_FILES[@]}"; do
      seg="$TMP/seg-$(basename "$s" .txt).mp4"
      ffmpeg -y -v error -f lavfi -i "color=c=0x0d1117:s=1280x720:d=$DUR,fps=30" \
        -vf "drawtext=textfile='$s':font='${FONT:-DejaVu Sans}':fontcolor=0xe6edf3:fontsize=40:line_spacing=14:x=(w-text_w)/2:y=(h-text_h)/2" \
        -c:v libx264 -pix_fmt yuv420p -an "$seg"
      echo "file '$seg'" >> "$TMP/concat.txt"
    done
    ffmpeg -y -v error -f concat -safe 0 -i "$TMP/concat.txt" -c copy "$TMP/raw.mp4"
    RAW="$TMP/raw.mp4"
    ;;
  *.mp4|*.mov|*.gif)
    RAW="$SRC"
    ;;
  *)
    echo "Error: unsupported source type: $name" >&2
    exit 1
    ;;
esac

# Normalize to X spec: 720p letterbox, 30fps, H.264 yuv420p, no audio.
# If the raw file is already at the output path (e.g. a tape that declares
# Output videos/<base>.mp4), move it aside first — ffmpeg can't read and
# write the same file.
if [[ "$RAW" -ef "$OUT" ]]; then
  mv "$RAW" "$TMP/inplace-raw.mp4"
  RAW="$TMP/inplace-raw.mp4"
fi
ffmpeg -y -v error -i "$RAW" \
  -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:color=black,fps=30,format=yuv420p" \
  -c:v libx264 -preset medium -crf 23 -movflags +faststart -an "$OUT"

DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")
DUR_INT=${DURATION%.*}
SIZE=$(du -h "$OUT" | cut -f1)

if [[ ${DUR_INT:-0} -gt 140 ]]; then
  echo "Error: ${DURATION}s exceeds X's 140s limit for standard accounts — shorten the source." >&2
  exit 1
elif [[ ${DUR_INT:-0} -gt 30 ]]; then
  echo "Warning: ${DURATION}s is above the SOP target of ~15s (max recommended 30s)." >&2
fi

echo "Rendered: $OUT (${DURATION}s, $SIZE, 1280x720 h264/yuv420p 30fps)"
echo "Safety check before publishing: scrub frames for tokens, secrets, private paths (safety.md)."