# SRSI_projet7
Repo about something like blockcain, fragmentation, ssl and other stuff, a student project<br>
<br>
Note about spliter.sh<br>
<br>
&nbsp;Initial release :
&nbsp;&nbsp;! Not protection about user input at this state, need to check what kind of stubid stuff i can do before
&nbsp;&nbsp;* Grab file (remote support via scp and a basic, non-viable check)
&nbsp;&nbsp;* Split files (via split command) into defined block size
&nbsp;&nbsp;* Rename files with the coresponding hash (md5 or arg)
&nbsp;&nbsp;* Create a index for recovering (futur sticker.sh)
&nbsp;&nbsp;* Basic command line with :
&nbsp;&nbsp;&nbsp;-b/--block    : Set the block size
&nbsp;&nbsp;&nbsp;-e/--err      : Stderr -> errfile (*spliter.err if unspecified*)
&nbsp;&nbsp;&nbsp;-h/--help     : Do nothing, i'm lazy about doing it but at least it's here
&nbsp;&nbsp;&nbsp;-i/--input    : Input file to split (support n file/remote)
&nbsp;&nbsp;&nbsp;-l/--log      : Stdout -> logfile (*spliter.log if unspecified*)
&nbsp;&nbsp;&nbsp;-n/--no       : Decline mode (when prompt ask)
&nbsp;&nbsp;&nbsp;-t/--timeout  : Timeout for remote file 
&nbsp;&nbsp;&nbsp;-u/--unit     : Display file size unit (cosmetic)
&nbsp;&nbsp;&nbsp;-v/--verbose  : Useless for the moment
&nbsp;&nbsp;&nbsp;-y/--yes      : Allowed mode (when promp ask)
&nbsp;&nbsp;&nbsp;--hash-method : Hash Specific (md5 by default), use openssl
&nbsp;&nbsp;&nbsp;--strict      : If one file is not present exit with error
