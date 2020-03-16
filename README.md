# SRSI_projet7
Repo about something like blockcain, fragmentation, ssl and other stuff, a student project\n
\n\r
\n
Note about spliter.sh\n
\n
 Initial release :\n
    ! Not protection about user input at this state, need to check what kind of stubid stuff i can do before\n
    * Grab file (remote support via scp and a basic, non-viable check)\n
    * Split files (via split command) into defined block size\n
    * Rename files with the coresponding hash (md5 or arg)\n
    * Create a index for recovering (futur sticker.sh)\n
    * Basic command line with :\n
      -b/--block    : Set the block size\n
      -e/--err      : Stderr -> errfile (*spliter.err if unspecified*)\n
      -h/--help     : Do nothing, i'm lazy about doing it but at least it's here\n
      -i/--input    : Input file to split (support n file/remote)\n
      -l/--log      : Stdout -> logfile (*spliter.log if unspecified*)\n
      -n/--no       : Decline mode (when prompt ask)\n
      -t/--timeout  : Timeout for remote file \n
      -u/--unit     : Display file size unit (cosmetic)\n
      -v/--verbose  : Useless for the moment\n
      -y/--yes      : Allowed mode (when promp ask)\n
      --hash-method : Hash Specific (md5 by default), use openssl\n
      --strict      : If one file is not present exit with error\n\r
