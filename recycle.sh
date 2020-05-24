#!/bin/sh

# ===================== INITIAL CONFIGS =====================

# Source vars for recycle bin location and restore file and define script path
source config.sh
SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# Init commandline options to false
iopt=false;
vopt=false;
ropt=false;


# ===================== FUNCTIONS =====================

# Function to prompt users in interactive mode
ioptPrompt () {
  # Check script option for interactive mode
  if [ $iopt = true ]; then
    # Prompt y/n with text at arg 2 for this function
    read -p "$2" -n 1 -r
    echo    # move to a new line after user input
    # If user enters anything that doesn't start with y/Y, stop
    if [[ ! $REPLY =~ ^[Yy]$ ]];
      then false
    else
      true
    fi
  else
    # If not interactive, proceed without prompting user
    true
  fi
}


recycle () {
  local fname=$1

  # File being deleted is not recycle script
  if [ "$(greadlink -e "${fname}")" = "$(greadlink -e $SCRIPTPATH)" ]; then
    #TODO: Writen for OSX. Modify to be readlink instead of greadlink for linux/unix
    echo "Attempting to delete recycle script - operation aborted"
    return 1
  fi


  # Directory name provided to handle and recurse on
  if [ -d "${fname}" ]; then
    # Recurse on dir file list if recurse option set
    if [ $ropt = true ]; then
      # Prompt user and exit function if user says anything other than y/Y
      ioptPrompt ${fname} "examine files in directory $1?"
      [[ $? -eq 1 ]] && return 0

      # Change into directory to recycle files in dir
      cd "${fname}"
      for file in *
      do
        # file string could be '*' if directory is empty, so need to check
        [[ -f "$file"  || -d "$file" ]] || continue
        recycle $file
      done

      # Move back out of dir & delete dir itself after recursing
      cd ..
      # Prompt user and exit function if user says anything other than y/Y
      ioptPrompt ${fname} "remove `pwd`/${fname}?"
      [[ $? -eq 1 ]] && return 0;

      # If there are files still in dir, cannot remove dir
      if [[ "$(ls -A ${fname})" ]]; then
        echo "recycle: ${fname}: Directory not empty";
        return 1
      fi

      # Delete dir if there are no files in it
      rm -r "${fname}"
      # Echo fname with path to it if verbose option turned on
      [[ $vopt = true ]] && echo `pwd`/${fname}
      return 0
    else
      # Input is a dir but recursive option not set
      echo "recycle: ${fname}: is a directory"
      return 1
    fi
  fi


  # File does not exist: Display error message, terminate the script.
  if [ ! -f "${fname}" ]; then
    echo "recycle: ${fname}: No such file"
    return 1
  fi

  # Prompt user and exit function if user says anything other than y/Y
  ioptPrompt ${fname} "recycle `pwd`/${fname}?"
  [[ $? -eq 1 ]] && return 0;

  # ---Perform All Recycle Operations for an individual file---

  # Get inode number of fname. This is easier on linux, but OSX operations here
  local inodeNum=`ls -i ${fname} | cut -d ' ' -f 1`

  # Create new recycle filename, parsing filename from dir path if nested in dir
  local recyclefName=`echo ${fname}_${inodeNum} | sed 's:.*/::'`

  # Get absolute path to filename
  local fnameAbsPath=`realpath ${fname}`

  # Create .restore.info file entry
  local restoreEntry=${recyclefName}:${fnameAbsPath}

  # Write restore entry to restoreInfoPath file
  echo $restoreEntry >> ${restoreInfoPath}

  # Move fname to recycleDir renamed to recyclefName
  mv ${fname} ${recycleDir}/${recyclefName}

  # Echo fname with path to it if verbose option turned on
  [[ $vopt = true ]] && echo `pwd`/${fname}

}


# ===================== MAIN =====================

# Make recycle directory if it doesn't already exist
mkdir -p $recycleDir

# Make .restore.info file if it doesn't already exist
if [ ! -f ${restoreInfoPath} ]
then
  touch ${restoreInfoPath}
fi


# Parse out option arguments and exit on invalid option
while getopts ":ivr" opt; do
  case ${opt} in
    i ) iopt=true;
      ;;
    v ) vopt=true;
      ;;
    r ) ropt=true;
      ;;
    \? ) echo "usage: ./recycle [-i | -v | -r] file";
         exit 1;
      ;;
  esac
done

# Shift to next script argument after options
shift $((OPTIND -1))

# Check that there are actually file arguments and exit if not
if [ $# -eq 0 ]; then
  echo "usage: ./recycle [-i | -v | -r] file"
  exit 1
fi


# Loop over remaining script args, attempting recursive recycle
for fileArg in "$@"
do
    recycle $fileArg
done
