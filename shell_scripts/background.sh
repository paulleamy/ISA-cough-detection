#!/bin/bash

# Create directories
mkdir background
mkdir background/noise

# Run youtube_dl to import background audio i .m4a format from batch file
youtube-dl -f 140 --batch-file youtube_links/youtube_background.sh

# Convert to .wav and trim length
for f in *.m4a; do ffmpeg -ss 00:00:00 -t 00:30:00 -i "$f" "${f/%m4a/wav}"; done

# Remove .m4a files
rm *.m4a

# Move to background noise directory
mv *.wav ./background/noise

