# SRSI_projet7
Repo about something like blockchain, fragmentation, ssl and other stuff, students project<br>
<br>
Note about spliter.sh<br>
<br>

 Rework 1 - no version
  * Code Rework (not finished, not functional)
  
 
 Initial release :<br>
  ! Not protected against user input at this state, need to check what kind of stupid stuff i do before cleanup<br>
  * Grab file (remote support via scp and a basic, non-viable check)<br>
  * Split files (via split command) into defined block size<br>
  * Rename files with the coresponding hash (md5 or arg)<br>
  * Create a index for recovering (futur sticker.sh)<br>
  * Basic command line with :<br>
      -b/--block    : Set the block size<br>
      -e/--err      : Stderr -> errfile (*spliter.err if unspecified*)<br>
      -h/--help     : Do nothing, i'm lazy about doing it but at least it's here<br>
      -i/--input    : Input file to split (support n file/remote)<br>
      -l/--log      : Stdout -> logfile (*spliter.log if unspecified*)<br>
      -n/--no       : Decline mode (when prompt ask)<br>
      -t/--timeout  : Timeout for remote file <br>
      -u/--unit     : Display file size unit (cosmetic)<br>
      -v/--verbose  : Useless for the moment<br>
      -y/--yes      : Allowed mode (when promp ask)<br>
      --hash-method : Hash Specific (md5 by default), use openssl<br>
      --strict      : If one file is not present exit with error<br>
