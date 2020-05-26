# ISA-cough-detection

Files required to recreate the test signals used in the paper "Audio-based cough counting using independent subspace analysis" submitted to Interspeech 2020.

The follwoing dependancies are required
```
youtube-dl
ffmpeg
sox
scaper
```

Run ```create_dataset.sh``` to initialise the download of the required audio files into the required directories.

Following this, use ```create_test_signals.py``` to create the the 10 test signals presented in the paper.
