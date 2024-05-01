# copy_from_server.sh 
by Mathias Wagner 2024-05-01  

## Disclaimer
This script was part of a bigger project. It was modified to work alone. This is the reason why there is no git history on its development.  

## Description
Script copy files from a host in parallel on your machine.  
Its usage only makes sense if you have many large files to copy. If establishing the ssh connection takes longer than the copy itself, it will be slower than a direct copy using rsync.  

## Installation
You might have to make the script executable before first usage with `chmod u+x copy_from_server.sh`.  
The script needs the programs `rsync` and `sshpass` installed.  

## Usage
Get possible options and their description with `./copy_from_server.sh -h`.  
Either provide a file to the option `-f` that contains one file per line on the remote system, or provide a command to the option `-f2` that prints a list with one file per line when executed on the host.  
**Note:** The option `-i` is intendet to allow a copy of files from local to the host, but after the extraction from the bigger project, there was no chance, yet, to test its functionality...  

## Tipp
Put the `-h` flag always at the end, then you can see the current values of the provided options in the brackets at the end of each option.  

