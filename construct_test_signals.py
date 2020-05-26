#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon May 25 15:31:56 2020

@author: paulleamy
"""

# 1. Setup directories
import scaper
import numpy as np

# Sound directories
foreground_folder = 'foreground'
background_folder = 'background'

for test_signal in np.arange(1,11):
    
    jamsfile = 'test_signals/soundscape'+str(test_signal)+'.jams'
    audiofile = 'test_signals/soundscape'+str(test_signal)+'.wav'
    print(jamsfile)
    
    # Generate signal from JAMS
    scaper.core.generate_from_jams(jamsfile, 
                               audiofile, 
                               fg_path=foreground_folder, 
                               bg_path=background_folder, 
                               jams_outfile=None, 
                               save_isolated_events=False, 
                               isolated_events_path=None)
