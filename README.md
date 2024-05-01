# copy_from_server.sh 
by Mathias Wagner 2024-05-01  

## Disclaimer
This script was part of a bigger project. It was modified to work alone. This is the reason why there is no git history on its development.  

## Description
Script to copy files from a host to your machine in parallel.  
Its usage only makes sense if you have large files to copy. If establishing the ssh connection takes longer than the copy itself, it will be slower than a direct copy using rsync.  

## Installation
You might have to make the script executable before first usage with `chmod u+x copy_from_server.sh`.  
The script needs the programs `rsync` and `sshpass` installed.  

## Usage
Get possible options and their description with `./copy_from_server.sh -h`.  
Either provide a file to the option `-f` that contains one file per line on the remote system, or provide a command to the option `-f2` that prints a list with one file per line when executed on the host.  

**Note:**  
- The option `-i` is intended to allow a copy of files from local to the host, but after the extraction from the bigger project, there was no chance, yet, to test its functionality...  
- The same holds for the options `-C` and `-C2`. Originally, the files had to be copied from a tape storage system to a temporary scratch directory before the `rsync` and were deleted after the copy was completed. This original functionality was generalized to running an arbitrary command before and/or after the copy, but it was not tested in this form, yet.  

## Tipp
- Put the `-h` flag always at the end, then you can see the current values of the provided options in the brackets at the end of each option.  
- The first line of the log-file contains the flags that were used when the log-file was created. This allows for easier rerun of the code.  
- In case the copy of some of the files failed, simply rerun the command. Unless the option `-r` was provided (recopies and replaces all files), it will only copy the missing files. Make sure that all files that had a mismatch in file size are removed beforehand, because otherwise the script will ignore them as well.  

