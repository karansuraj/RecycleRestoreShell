# Recycle and Restore Shell Scripts

In the terminal of Unix-based systems, there is no 'recycle' command. The scripts in this repo aim to replicate the functionality of the rm command, but instead of deleting files and directories, we will be moving them to a dedicated 'recycle bin' directory. While performing these recycle actions on a file, a record of the original location of the recycled file will be stored in a hidden file in the recycle bin called '.restore.info'. Below is an overview of each script in this repo.

## config.sh
This script is strictly run by the recycle.sh and restore.sh scripts to source common environment variable information and has no use being run directly. The script sets the target directory for the location of the recycle bin on the system, as well as the path to the '.restore.info' file that will contain records of recycled files.

## recycle.sh


    usage: ./recycle [-i | -v | -r] file

    e.g. ./recycle -v some_file.txt

This script recycles multiple files and directories (recursively if the recursive option is set) to the recycle bin directory specified in the config.sh script. In the event of recursive recycling with directories, only the files in the directory and subdirectories are recycled. The directories themselves will all be deleted. Therefore the folder structure of the recycle bin directory will be flat with all recycling operations. There are 3 **optional** arguments:

* -i : Interactive mode option which prompts users for the recycling of all files
* -v : Verbose option which prints out all files being recycled (and directories being removed)
* -r : Recursive option which is required when running the recycle command on any directory and its subdirectories

In the process of recycling files, in order to avoid overlaps in filenames in the recycle bin directory, all recycled files will have their unique inode number appended to their filename when being moved to the recycle bin (this will also be a part of the record in the .restore.info file in the recycle bin).

## restore.sh

    usage: ./restore file

This script restores a file within the recycle bin directory. The files in the recycle bin directory will all have their inode numbers appended in their filenames. For a given file, the script will search for a record of that file's original location, recursively create the directories for the file to be restored to (if they don't already exist), and move the file (with its inode number stripped from the filename) from the recycle bin back to that original location. The record of the formerly recycled file will also be purged from the .restore.info file upon restoring the file.
