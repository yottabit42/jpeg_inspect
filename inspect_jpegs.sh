#!/bin/env bash
#

if [ "${1}" == "" ]; then
  echo
  echo "This script uses jpeginfo to scan for defects in JPEG files. The list"
  echo "further filters out any files starting with 0x00 as these are usually"
  echo "misnamed PNG files, and files with 'burst' in the filename as these"
  echo "are typically flagged as corrupt by jpeginfo even when they are not."
  echo "Note that other less common extensions of the JPEG format may also"
  echo "result in false positives. If there is a commonality in the filename"
  echo "or in the jpeginfo output, further filter criteria can be added by"
  echo "additional grep commands in the filter pipeline."
  echo
  echo "Usage:"
  echo "  ${0} <directory>"
  exit
fi

echo
echo "For each file passing through the filter list, the filename will be"
echo "printed, all thumbnails extracted and written into the same directory"
echo "as the source file, and ristretto will display the original file."
echo
echo "While ristretto is open, you can optionally <DEL> the original, <RIGHT>"
echo "to see the created thumbnail(s), and <CTRL>+<Q> to quit Ristretto (which"
echo "will proceed to process the next file)."
echo
echo "If you want to stop at any time, use <CTRL>+<C> on this script,"
echo "including now."
echo
read -p "Press Enter to continue, or <CTRL>+<C> to abort."

which find > /dev/null 2>&1 || \
  ( echo "find missing from path. Please install or correct."; exit )
which xargs > /dev/null 2>&1 || \
  ( echo "xargs missing from path. Please install or correct."; exit )
which pv > /dev/null 2>&1 || \
  ( echo "pv missing from path. Please install or correct."; exit )
which grep > /dev/null 2>&1 || \
  ( echo "grep missing from path. Please install or correct."; exit )
which jpeginfo > /dev/null 2>&1 || \
  ( echo "jpeginfo missing from path. Please install or correct."; exit )
which ristretto > /dev/null 2>&1 || \
  ( echo "ristretto missing from path. Please install or correct."; exit )
which exiftool > /dev/null 2>&1  || \
  ( echo "exiftool missing from path. Please install or correct."; exit )

IFS=$'\n'
set -euo pipefail

echo
echo "Inspecting files..."

for f in $( \
  find "${1}" -iname "*.jpg" -print0 | \
    xargs -0 jpeginfo -c -i -v | \
    pv -l | \
    grep -e WARNING -e ERROR | \
    grep -v 'starts with 0x00 0x00' | \
    grep -iv 'burst' | \
    grep -Poe '.*.jpg'); do
  echo "${f}"
  exiftool -a -b -W "%d%f_%t%-c.%s" -preview:all "${f}"
  ristretto "${f}"
done

echo "Finished."
