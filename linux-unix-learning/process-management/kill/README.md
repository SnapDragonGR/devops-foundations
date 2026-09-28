# How to use the KILL command?
### What does it do?  
Kill actually sends a signal to a process!
* `pidof nano` to find the process id of a wanted application
* `kill -9 1661 (nano in my case)` - last resort. Kills with no cleanup, done only if have to.
* `kill -15 <pid>` - graceful kill with a cleanup, and is a default option of the kill command. "Will you please close?"
* `kill -2` = interrupt = ctrl + c. 
* `kill -1` = hangup = reread file's config file
* `kill -L` to see the list of all possible signals  
* `kill -3` - quit with a dump file
* `killall -9 nano` - killall gives the option to use process's name 
* `kill -s SIGKILL 12345` - use the actual sig signal (number 9 in this case)
Can target multiple processes as well (usually not used):  
* `kill -15 4923 5343 9021`  
  
* `pgrep <name>` to find the pid as well
* PPID = parent process id. Used to check for orphans (for instance after harsh terminations)
* `ps -ef` to see PPIDs
* `ps auxf` to see the tree structure directly

### Important age case  
Ran `sudo kill -9` on the process, but it won't die and remain visible in ps aux. What is it?  
#### the process is either a zombie process (Z state) or is in an interruptible sleep (D state)
### Z state:
* Already dead, remains in the kernel's process table because its parent process hasn't yet called `wait()` to read its exit code
* Unkillable. Gotta restart the parent process (assigned to init / systemd) or wait for the parent to read the status
### D state:
* Process is waiting directly on Kernel I/O
* The kernel paused it to prevent file corruption
* Have to fix the underlying I/O issue (restore network to the NFS sh are) or reboot the host

