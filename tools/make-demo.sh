#!/bin/bash
# Turn a raw screen recording into docs/demo.gif + docs/demo.mp4.
#
#   ./tools/make-demo.sh ~/Downloads/recording.gif [A_IN A_OUT B_IN]
#
# The recording is cut into two pieces so the dead time in the middle goes away:
# A is the capture (hotkey → selection → OCR), B is the paste that proves it worked.
# The last frame is held so the result is readable before the loop restarts.
set -e
cd "$(dirname "$0")/.."

IN=${1:?usage: make-demo.sh RECORDING [A_IN A_OUT B_IN]}
A_IN=${2:-2.6}      # skip the idle mouse at the head
A_OUT=${3:-10.9}    # end just after OCR is clicked
B_IN=${4:-14.1}     # start of the paste

# Crop away the recorder's decorative wallpaper AND the browser's vertical tab strip,
# which otherwise puts your own tab titles in a public repo. Find new numbers by
# eyeballing a frame:  ffmpeg -ss 1 -i IN -frames:v 1 /tmp/f.png
CROP=${CROP:-916:700:130:20}

W=760; FPS=12; COLORS=96   # 43 MB of raw recording lands at ~5 MB with these

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

ffmpeg -v error -y -i "$IN" -filter_complex \
  "[0:v]trim=start=$A_IN:end=$A_OUT,setpts=PTS-STARTPTS[a];\
   [0:v]trim=start=$B_IN,setpts=PTS-STARTPTS[b];\
   [a][b]concat=n=2:v=1,crop=$CROP,tpad=stop_mode=clone:stop_duration=1.8[v]" \
  -map "[v]" -c:v libx264 -preset veryslow -crf 25 -pix_fmt yuv420p \
  -movflags +faststart docs/demo.mp4

# a palette built from frame differences keeps the text crisp at 96 colours
ffmpeg -v error -y -i docs/demo.mp4 \
  -vf "fps=$FPS,scale=$W:-2:flags=lanczos,palettegen=max_colors=$COLORS:stats_mode=diff" "$T/pal.png"
ffmpeg -v error -y -i docs/demo.mp4 -i "$T/pal.png" -lavfi \
  "fps=$FPS,scale=$W:-2:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
  docs/demo.gif

ls -lh docs/demo.gif docs/demo.mp4 | awk '{print $9, $5}'
