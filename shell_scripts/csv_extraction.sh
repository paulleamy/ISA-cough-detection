#!/bin/bash

mkdir foreground

OLDIFS=$IFS
IFS=','
for file in ./timestamps/*csv; do
  	# echo "${file##*/}"

  	#INPUT="${file##*/}"		# Input filename
  	INPUT="$file"		# Input filename
  	# echo $INPUT
  	i=0						# Counter for labelling output

  	[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
  	while read col1
  	do
  		
      # Remove carriage return
      col1="$(echo ${col1}|tr -d '\r ')"
      
      if [[ $i -eq 0 ]]; then

        # Create directory for cough sounds
        newdir="foreground/coughs_$col1"
        mkdir $newdir
 
      elif [[ $i -eq 1 ]]; then
          
          # Set input wave file
          col1="$(echo ${col1}|tr -d ' ')"    # Trim white space
          wavfile="coughs/$col1.wav"
          # echo $wavfile

      elif [[ $i -gt 1 ]]; then
        
        #Now extract sections of audio 
        prefix=$((i-1))
        
        # Output name
        outwav="$newdir/$prefix.wav"

        # https://stackoverflow.com/questions/52374260/bash-variable-changes-in-loop-with-ffmpeg
        # ffmp
        ffmpeg -hide_banner -loglevel panic -ss $col1 -t 0.5 -y -i "$wavfile" "$outwav" < /dev/null
        
      fi

    	((i++))

	done < $INPUT

  # Required to parse final line of CSV file
  if [[ $col1 != "" ]] ; then
    
    # Set prefix
    prefix=$((i-1))
    
    # Remove carriage return
    col1="$(echo ${col1}|tr -d '\r ')"

    # Output name
    outwav="$newdir/$prefix.wav"
    
    # Do ffmpeg
    ffmpeg -hide_banner -loglevel panic -ss $col1 -t 0.5 -y -i "$wavfile" "$outwav" < /dev/null

  fi
done
IFS=$OLDIFS