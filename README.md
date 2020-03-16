# SRSI_projet7
Repo about something like blockcain, fragmentation, ssl and other stuff, a student project<br>
<br>
Note about spliter.sh<br>
<br>
&nbsp;Initial release :<br>
&nbsp;&nbsp;! Not protection about user input at this state, need to check what kind of stubid stuff i can do before<br>
&nbsp;&nbsp;* Grab file (remote support via scp and a basic, non-viable check)<br>
&nbsp;&nbsp;* Split files (via split command) into defined block size<br>
&nbsp;&nbsp;* Rename files with the coresponding hash (md5 or arg)<br>
&nbsp;&nbsp;* Create a index for recovering (futur sticker.sh)<br>
&nbsp;&nbsp;* Basic command line with :<br>
&nbsp;&nbsp;&nbsp;-b/--block    : Set the block size<br>
&nbsp;&nbsp;&nbsp;-e/--err      : Stderr -> errfile (*spliter.err if unspecified*)<br>
&nbsp;&nbsp;&nbsp;-h/--help     : Do nothing, i'm lazy about doing it but at least it's here<br>
&nbsp;&nbsp;&nbsp;-i/--input    : Input file to split (support n file/remote)<br>
&nbsp;&nbsp;&nbsp;-l/--log      : Stdout -> logfile (*spliter.log if unspecified*)<br>
&nbsp;&nbsp;&nbsp;-n/--no       : Decline mode (when prompt ask)<br>
&nbsp;&nbsp;&nbsp;-t/--timeout  : Timeout for remote file <br>
&nbsp;&nbsp;&nbsp;-u/--unit     : Display file size unit (cosmetic)<br>
&nbsp;&nbsp;&nbsp;-v/--verbose  : Useless for the moment<br>
&nbsp;&nbsp;&nbsp;-y/--yes      : Allowed mode (when promp ask)<br>
&nbsp;&nbsp;&nbsp;--hash-method : Hash Specific (md5 by default), use openssl<br>
&nbsp;&nbsp;&nbsp;--strict      : If one file is not present exit with error<br>
