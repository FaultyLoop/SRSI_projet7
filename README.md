# SRSI_projet7
Repo about something like blockcain, fragmentation, ssl and other stuff, a student project<br>

Note about spliter.sh

Initial release :
    ! Not protection about user input at this state, need to check what kind of stubid stuff i can do before
    * Grab file (remote support via scp and a basic, non-viable check)
    * Split files (via split command) into defined block size
    * Rename files with the coresponding hash (md5 or arg)
    * Create a index for recovering (futur sticker.sh)
    * Basic command line with :
      -b/--block    : Set the block size
      -e/--err      : Stderr -> errfile (*spliter.err if unspecified*)
      -h/--help     : Do nothing, i'm lazy about doing it but at least it's here
      -i/--input    : Input file to split (support n file/remote)
      -l/--log      : Stdout -> logfile (*spliter.log if unspecified*)
      -n/--no       : Decline mode (when prompt ask)
      -t/--timeout  : Timeout for remote file 
      -u/--unit     : Display file size unit (cosmetic)
      -v/--verbose  : Useless for the moment
      -y/--yes      : Allowed mode (when promp ask)
      --hash-method : Hash Specific (md5 by default), use openssl
      --strict      : If one file is not present exit with error
