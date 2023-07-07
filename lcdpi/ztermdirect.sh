#!/bin/bash

## Transmit each character to Z-Terminal
while IFS= read -r -n1 char
do
  # Process the character
  echo "$char" > /dev/zterm
done
