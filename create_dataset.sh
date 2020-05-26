#!/bin/bash

# This script execute all individual scripts to construct the dataset

# 1. Background
bash shell_scripts/background.sh

# 2. Cough download - maybe remove the cough folder after done with it.
bash shell_scripts/cough_track_download.sh
bash shell_scripts/csv_extraction.sh

# 3. DCASE directory
bash shell_scripts/dcase_conversion.sh 