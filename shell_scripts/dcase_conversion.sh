#!/bin/bash

# Copy each category into its own folder
# Doorslam
mkdir foreground/doorslam
mv dcase2016_task2_train/doorslam*.wav foreground/doorslam

# drawer
mkdir foreground/drawer
mv dcase2016_task2_train/drawer*.wav foreground/drawer

# keysdrop
mkdir foreground/keysdrop
mv dcase2016_task2_train/keysDrop*.wav foreground/keysdrop

# keyboard
mkdir foreground/keyboard
cp dcase2016_task2_train/keyboard*.wav foreground/keydrop
mv dcase2016_task2_train/keyboard*.wav foreground/keyboard

# knock
mkdir foreground/knock
mv dcase2016_task2_train/knock*.wav foreground/knock

# laughter
mkdir foreground/laughter
mv dcase2016_task2_train/laughter*.wav foreground/laughter

# pageturn
mkdir foreground/pageturn
mv dcase2016_task2_train/pageturn*.wav foreground/pageturn

# phone
mkdir foreground/phone
mv dcase2016_task2_train/phone*.wav foreground/phone

# speech
mkdir foreground/speech
mv dcase2016_task2_train/speech*.wav foreground/speech

# Remove dcase directory
#rm -r ./dcase2016_task2_train

