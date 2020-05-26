#!/bin/bash

# Create directories
mkdir coughs

# Run youtube_dl to import background audio i .m4a format from batch file
youtube-dl -f 140 --batch-file youtube_links/youtube_coughs.sh -o '%(id)s.%(ext)s'

# Convert to .wav
for f in *.m4a; do ffmpeg -i "$f" "${f/%m4a/wav}"; done

# Remove .m4a files
rm *.m4a

# Move to background noise directory
mv *.wav ./coughs

# Remove before upload to github
# Convert timestamps to .csv
# for file in ./timestamps/*.txt; do mv "$file" "${file%.txt}.csv"; done