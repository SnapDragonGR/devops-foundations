# Memory and Swap (and OOM Killer)
* `free -m` to show the available memory in MB
* pay attention to "available" filed
* unused ram = wasted ram
* linux tries to cache as much as possible to get quicker access to information (from RAM)
* `available` shows the memory that could be used, but `free` is the actual physical mem available in the moment
* `available` includes free in it too
## Swap
* swap is slow
* "emergency memory"
* exists on the disk - much slower than RAM
* instances within kubernetes don't have swap
* sometimes swap isn't wanted
* using a bit of swap is still fine
* if no swap - and no mem - chaos!
* 'swappiness' - swap variable to decide how much swap to use
* the lower - the less likely it'll be used
* if set to 0 - aggressive avoidance of swap unless has to be used
## OOM Killer
* when no RAM or Swap available, kernel activates oom_killer to forcibly shoot down a process (SIGKILL) and free up mem
* victim chosen by badness score from 0 to 1000 fo every process in `/proc/<PID>/oom_score`
* higher score = first to die. Lower = kept alive
## Protecting Critical Services
* to tune processes's priority: `/proc/<PID>/oom_score_adj`
* values from -1000 (never kill) to 1000 (kill first)
* `echo -1000 | sudo tee /proc/<PID>/oom_score_adj`
* `OOMScoreAdjust=-1000` in a service config
* `sudo dmesg | grep -i "out of memory"` to check for OOM events 
* `sudo journalctl -k | grep -i oom` via systemd
