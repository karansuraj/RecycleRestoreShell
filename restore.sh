#!/bin/sh

# ===================== INITIAL CONFIGS =====================

# Source vars for recycle bin location and restore file
source config.sh
fname=$1

# Make recycle directory exists if it doesn't exist
mkdir -p $recycleDir

# Change dir to recycle bin dir
cd ${recycleDir}


#  ===================== HANDLE FILE ARGS =====================

# 1. No filename provided: Display error and set error exit status
if [ $# -eq 0 ]; then
  echo "usage: ./restore file"
  exit 1
fi


# 2. File does not exist: Display error message, terminate the script.
if [ ! -f ${fname} ]; then
  echo "restore: ${fname}: No such file"
  exit 1
fi


# ===================== RESTORE OPERATIONS =====================

# Look for path of file in .restore.info file
recycleEntry=`grep ${fname} ${restoreInfoPath}`
restorePath=${recycleEntry#*:}


# Check if target dir with file path already exists and prompt user for overwrite
if [ -f ${restorePath} ]; then
  read -p "Do you want to overwrite? y/n " -n 1 -r
  echo    # move to a new line after user input
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 0
  fi
fi

# Recursively create original containing dir if it doesn't exist
mkdir -p `dirname ${restorePath}`

# Move file from recycle bin to that original directory
mv ${fname} ${restorePath}

# Remove entry from restore info file
`grep -v ${fname} ${restoreInfoPath} > temp; mv temp ${restoreInfoPath}`
