# PHASE 1: LINUX KERNEL & OS MECHANICS


### linux-unix-learning/phase-1-os-kernel/process-management/kill/README.md
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


### linux-unix-learning/phase-1-os-kernel/process-management/lab-02-process-diagnostics/SOLUTION.md
# Lab 01: Process & Kernel Mechanics Diagnostics

**Host Machine:** Debian 13 VM  
**Repository:** `devops-foundations`  
**Section:** Linux Operating System & Kernel Mechanics  

---

## 🎯 Lab Objectives
1. Locate and extract content from an unlinked (deleted) file descriptor using the `/proc` pseudo-filesystem.
2. Inspect a running process's OOM badness score (`oom_score`) and adjust its priority (`oom_score_adj`) to protect it from the kernel OOM Killer.
3. Safely terminate background processes using standard process signal termination workflows (`SIGTERM` vs `SIGKILL`).

---

## Task 1: Recover Data from a Deleted File Descriptor

### 1. Scenario Verification
Read the background process ID created by `setup_lab.sh`:
```bash
cat .scenario1_pid
```
* **Target PID:** `9498`

### 2. Inspect File Descriptors
List all file descriptors opened by the target process:
```bash
ls -l /proc/9498/fd/
```

* **Terminal Output:**
```text
total 0
lr-x------ 1 gleb gleb 64 Oct  3 03:33 0 -> /dev/null
l-wx------ 1 gleb gleb 64 Oct  3 03:33 1 -> /dev/null
l-wx------ 1 gleb gleb 64 Oct  3 03:33 2 -> /dev/null
l-wx------ 1 gleb gleb 64 Oct  3 03:33 25 -> /home/gleb/.vscode-server/data/logs/20261003T012835/remoteagent.log
lrwx------ 1 gleb gleb 64 Oct  3 03:33 26 -> /dev/ptmx
lrwx------ 1 gleb gleb 64 Oct  3 03:33 27 -> /dev/ptmx
lrwx------ 1 gleb gleb 64 Oct  3 03:33 28 -> /dev/ptmx
l-wx------ 1 gleb gleb 64 Oct  3 03:33 29 -> /home/gleb/.vscode-server/data/logs/20261003T012835/remoteTelemetry.log
lr-x------ 1 gleb gleb 64 Oct  3 03:33 3 -> '/tmp/lab_secret.log (deleted)'
lr-x------ 1 gleb gleb 64 Oct  3 03:33 4 -> anon_inode:inotify
```

### 3. Recover Deleted File Content
Output the contents of the deleted file directly from memory:
```bash
cat /proc/9498/fd/3
```

* **Recovered Secret Key:**
```text
Confidential API Key: AWS_SECRET_KEY_98765
```

---

## Task 2: Inspect OOM Score and Adjust Priority

### 1. Inspect Initial OOM Score
Read the process ID from `.scenario2_pid` and check its current `oom_score`:
```bash
cat /proc/9500/oom_score
```
* **Initial `oom_score`:** `666`

### 2. Adjust OOM Protection (`oom_score_adj`)
Adjust the badness score priority to `-500` to make the worker process less likely to be targeted by the kernel OOM killer:
```bash
echo -500 | sudo tee /proc/9500/oom_score_adj
```

Verify the adjustment:
```bash
cat /proc/9500/oom_score_adj
```
* **Updated `oom_score_adj`:** `-500`

---

## Task 3: Clean Up Lab Background Processes

### 1. Process Cleanup Commands
Terminate both background processes created during the lab setup:
```bash
kill $(cat .scenario1_pid) $(cat .scenario2_pid)
rm -f .scenario1_pid .scenario2_pid setup_lab.sh
```

### 2. Signal Analysis
* **Which signal was sent by default?** `SIGTERM` (Signal 15)
* **Why send `SIGTERM` (15) before `SIGKILL` (9)?**
  > `SIGTERM` requests a graceful shutdown, allowing the application to release resources, flush buffers to disk, close database connections, and clean up temporary files. `SIGKILL` forcibly halts execution at the kernel level without giving the process any opportunity to handle cleanup operations.

---

## 📌 Key Takeaways
* Files held open by active processes remain readable via `/proc/<PID>/fd/<FD>` even if deleted from the VFS namespace.
* The kernel calculates `/proc/<PID>/oom_score` dynamically to select targets when RAM/Swap are exhausted; `/proc/<PID>/oom_score_adj` configures manual overrides.


### linux-unix-learning/phase-1-os-kernel/process-management/memory-and-swap/README.md
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


### linux-unix-learning/phase-1-os-kernel/process-management/orphans-and-zombies/README.md
# Cheat Sheet generated by Gemini:
![alt text](image.png)

### linux-unix-learning/phase-1-os-kernel/process-management/proc/README.md
# /proc pseudo-filesystem usage
* top, htop, or ps - all use a virtual file system - proc at proc/  
* proc/ holds info abt processes (their PIDs as directories)
* "files" are updated on the fly
* statm shows memory used (inside "directory" which is a file in proc)
* strace for advanced process info tracing
* cd into a process dir and ls - will see more info about it

## use cases:
* reclaim disk space / recover deleted files (`/proc/<PID>/fd/`)
* `> /proc/<PID>/fd/3` to truncate and reclaim space
* live kernel tuning (`/proc/sys`/)
* `/proc/sys/` contains writable interface controls for kernel runtime parameters (backed by the `sysctl` command)
* `echo 1 > /proc/sys/net/ipv4/ip_forward` to enable ipv4 forwarding on the fly
* debugging container and process environments (`/proc/<PID>/environ`)
* every process's exact runtime environment variables are exposed directly by the kernel:
* `xargs -0 -L1 -a /proc/1234/environ` - view env variables of PID 1234 (separated by nulls)


# /dev device folder
* `/dev` is a directory that stores devices (HDD as sda for instance)

# /sys
* kernel settings / OS system settings
* cd into kernel - see the flags


### linux-unix-learning/phase-1-os-kernel/process-management/ps-command/README.md

## 1. the ps command
**Command:** `ps`  
**Output:**
 ```console
    PID TTY          TIME CMD 
   1409 pts/4    00:00:00 bash 
   1866 pts/4    00:00:00 ps
   ```
**Explanation:**  
PID = unique process id  
TTY = terminal device controlling the specific process  
TIME = CPU spent time on the process  
shows processes running in the current session only (since no options)

### Unix-style options of ps

**Command: `ps x`**

**Output:**

```console
PID TTY      STAT   TIME COMMAND
   1112 ?        Ss     0:00 /usr/lib/systemd/systemd --user
   1115 ?        S      0:00 (sd-pam)
   1128 ?        S      0:00 sshd-session: gleb@notty
   1129 ?        Ss     0:00 -bash
   1133 ?        S      0:00 sh
   1151 ?        Sl     0:01 /home/gleb/.vscode-server/code-7debcd0e2acdea1c52de81bf9ee1620444407dda command-
   1186 ?        Ssl    0:00 /home/gleb/.vscode-server/code-7debcd0e2acdea1c52de81bf9ee1620444407dda --cli-da
   1194 ?        S      0:00 sh /home/gleb/.vscode-server/cli/servers/Stable-7debcd0e2acdea1c52de81bf9ee16204
   1198 ?        Sl     0:02 /home/gleb/.vscode-server/cli/servers/Stable-7debcd0e2acdea1c52de81bf9ee16204444
   1222 ?        Sl     0:07 /home/gleb/.vscode-server/cli/servers/Stable-7debcd0e2acdea1c52de81bf9ee16204444
   1233 ?        S      0:00 sh /home/gleb/.vscode-server/cli/servers/Stable-7debcd0e2acdea1c52de81bf9ee16204
   1236 ?        Sl     0:00 /home/gleb/.vscode-server/cli/servers/Stable-7debcd0e2acdea1c52de81bf9ee16204444
   1238 ?        Sl     0:00 /home/gleb/.vscode-server/cli/servers/Stable-7debcd0e2acdea1c52de81bf9ee16204444
   1261 ?        Sl     0:00 /home/gleb/.vscode-server/cli/servers/Stable-7debcd0e2acdea1c52de81bf9ee16204444
   1284 ?        Sl     0:00 /home/gleb/.vscode-server/cli/servers/Stable-7debcd0e2acdea1c52de81bf9ee16204444
   1322 ?        Sl     0:00 /home/gleb/.vscode-server/cli/servers/Stable-7debcd0e2acdea1c52de81bf9ee16204444
   1409 pts/4    Ss     0:00 /usr/bin/bash --init-file /home/gleb/.vscode-server/cli/servers/Stable-7debcd0e2
   1775 ?        Sl     0:00 /home/gleb/.vscode-server/cli/servers/Stable-7debcd0e2acdea1c52de81bf9ee16204444
   2211 ?        S      0:00 sleep 180
   2222 pts/4    R+     0:00 ps x
```

**Explanation:**  
Shows all processes running in the session. ? - started by system.  
Stat = status of the process, R is running, + means foreground process group, S is indefinite sleep, etc.

### Most used variation - ps aux
**Command:** `ps aux`  
**Output:** 
```console
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.6  23548 14080 ?        Ss   08:03   0:00 /sbin/init
root           2  0.0  0.0      0     0 ?        S    08:03   0:00 [kthreadd]
root           3  0.0  0.0      0     0 ?        S    08:03   0:00 [pool_workqueue_release]
root           4  0.0  0.0      0     0 ?        I<   08:03   0:00 [kworker/R-kvfree_rcu_reclaim]
root           5  0.0  0.0      0     0 ?        I<   08:03   0:00 [kworker/R-rcu_gp]
root           6  0.0  0.0      0     0 ?        I<   08:03   0:00 [kworker/R-sync_wq]
root          15  0.0  0.0      0     0 ?        I    08:03   0:00 [rcu_tasks_rude_kthread]
root          16  0.0  0.0      0     0 ?        I    08:03   0:00 [rcu_tasks_trace_kthread]
root          17  0.0  0.0      0     0 ?        S    08:03   0:00 [ksoftirqd/0]
root          18  0.0  0.0      0     0 ?        I    08:03   0:00 [rcu_preempt]
root          19  0.0  0.0      0     0 ?        S    08:03   0:00 [rcu_exp_par_gp_kthread_worker/0]
root          20  0.0  0.0      0     0 ?        S    08:03   0:00 [rcu_exp_gp_kthread_worker]
root          21  0.0  0.0      0     0 ?        S    08:03   0:00 [migration/0]
root          22  0.0  0.0      0     0 ?        S    08:03   0:00 [idle_inject/0]
root          23  0.0  0.0      0     0 ?        S    08:03   0:00 [cpuhp/0]
root          42  0.0  0.0      0     0 ?        S    08:03   0:00 [kcompactd0]
root          43  0.0  0.0      0     0 ?        SN   08:03   0:00 [ksmd]
root          44  0.0  0.0      0     0 ?        SN   08:03   0:00 [khugepaged]
root          45  0.0  0.0      0     0 ?        I<   08:03   0:00 [kworker/R-kintegrityd]
root          46  0.0  0.0      0     0 ?        I<   08:03   0:00 [kworker/R-kblockd]
root          47  0.0  0.0      0     0 ?        I<   08:03   0:00 [kworker/R-blkcg_punt_bio]
root          48  0.0  0.0      0     0 ?        S    08:03   0:00 [irq/9-acpi]
root          50  0.0  0.0      0     0 ?        I<   08:03   0:00 [kworker/R-tpm_dev_wq]
root          51  0.0  0.0      0     0 ?        I<   08:03   0:00 [kworker/R-edac-poller]
root          52  0.0  0.0      0     0 ?        I<   08:03   0:00 [kworker/R-devfreq_wq]
message+     679  0.0  0.2   8368  4808 ?        Ss   08:03   0:00 /usr/bin/dbus-daemon --system --address=sy
root        2079  0.0  0.0      0     0 ?        I    08:18   0:00 [kworker/1:2-cgroup_free]
root        2286  0.0  0.0      0     0 ?        I    08:26   0:00 [kworker/1:0-mm_percpu_wq]
gleb        2327  0.0  0.1   5572  2096 ?        S    08:34   0:00 sleep 180
root        2346  0.0  0.0      0     0 ?        I    08:35   0:00 [kworker/1:1]
gleb        2348  0.0  0.2   9396  4220 pts/4    R+   08:35   0:00 ps aux 
```  
**Explanation:**  
USER = instead of UID, makes easier to understand which user started the process  
%CPU %MEM = how much cpu and mem the process is running (useful for debugging, if system is running slow or smth)  
Start = when the process was started (timezone not set in this case). Also useful for debugging, if smth happened to an old process - would show fresh start time.  
VSZ = virtual memory size. Max memory the process can address  
RSS = actual physical RAM the process occupies rn

### Worth mentioning - ```ps auxf```
* Used for tracing orphan or zombie processes (shows nice hierarchy with parents and children)


### linux-unix-learning/phase-1-os-kernel/process-management/system-load-avg/README.md
# What is System Load Average and How to Utilize It
* measures the avg num of processes that are *demanding exectuion time* over time windows
* `uptime` to quickly check load avg
* `cat /proc/loadavg` - same thing
* shows how busy the server is - state of it
`02:52:33 up  1:24,  1 user,  load average: 0.00, 0.00, 0.00`:  
First 0.00 = load during the past 1 minute  
Second 0.00 = over the past 5 minutes  
Third 0.00 = over the past 15 minutes
* load avg 1 doesn't mean 100% busy
* cpu number is important
* `cat /proc/cpuinfo` to check cpu info
* if load avg becomes equal to the number of cpus (cpu cores) - the server is 100% busy
* if its a light load server - good to keep the load avg low and check if they are
* pay the most attention to the 5 minute one (over the past 5 minutes)
* clerk at a cash register analogy - one clerk (cpu core) handles one customer at a time
* temporary spikes of customers (tasks) are ok
* the more clerks - the more tasks can be handled simultaneously
## Mysterious high load problem
* top shows 0% CPU usage, but the load avg is spiking at 25
* processes are stuck waiting on disk reads/writes or an unresponsive NFS network mount (Uninterruptible Sleep / D state)


### linux-unix-learning/phase-1-os-kernel/process-management/top-htop/README.md
## The top command
**Command:** `top`  
**Output:**  
```console
top - 09:20:20 up  1:16,  1 user,  load average: 0.00, 0.00, 0.00
Tasks: 140 total,   1 running, 139 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.2 us,  0.5 sy,  0.0 ni, 99.3 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st 
MiB Mem :   1973.6 total,    477.9 free,   1169.9 used,    470.2 buff/cache     
MiB Swap:   1101.0 total,   1101.0 free,      0.0 used.    803.7 avail Mem 

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND                               
   1198 gleb      20   0 1836780 183088  53384 S   0.3   9.1   0:03.63 MainThread                            
      1 root      20   0   23548  14088  10592 S   0.0   0.7   0:00.82 systemd                               
      2 root      20   0       0      0      0 S   0.0   0.0   0:00.00 kthreadd                              
      3 root      20   0       0      0      0 S   0.0   0.0   0:00.00 pool_workqueue_release                
      4 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R-kvfree_rcu_reclaim          
      5 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R-rcu_gp                      
      6 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R-sync_wq                     
      7 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R-slub_flushwq                
      8 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R-netns                       
     10 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/0:0H-events_highpri           
     12 root      20   0       0      0      0 I   0.0   0.0   0:00.00 kworker/u8:0-ipv6_addrconf            
     13 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R-mm_percpu_wq                
     14 root      20   0       0      0      0 I   0.0   0.0   0:00.00 rcu_tasks_kthread                     
     15 root      20   0       0      0      0 I   0.0   0.0   0:00.00 rcu_tasks_rude_kthread                
     16 root      20   0       0      0      0 I   0.0   0.0   0:00.00 rcu_tasks_trace_kthread               
     17 root      20   0       0      0      0 S   0.0   0.0   0:00.02 ksoftirqd/0                           
     18 root      20   0       0      0      0 I   0.0   0.0   0:00.03 rcu_preempt                           
     19 root      20   0       0      0      0 S   0.0   0.0   0:00.00 rcu_exp_par_gp_kthread_worker/0       
     20 root      20   0       0      0      0 S   0.0   0.0   0:00.00 rcu_exp_gp_kthread_worker             
     21 root      rt   0       0      0      0 S   0.0   0.0   0:00.01 migration/0                           
     22 root     -51   0       0      0      0 S   0.0   0.0   0:00.00 idle_inject/0                         
     23 root      20   0       0      0      0 S   0.0   0.0   0:00.00 cpuhp/0                               
     24 root      20   0       0      0      0 S   0.0   0.0   0:00.00 cpuhp/1                               
     25 root     -51   0       0      0      0 S   0.0   0.0   0:00.00 idle_inject/1                         
     26 root      rt   0       0      0      0 S   0.0   0.0   0:00.03 migration/1                           
     27 root      20   0       0      0      0 S   0.0   0.0   0:00.02 ksoftirqd/1                           
     29 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/1:0H-events_highpri           
     30 root      20   0       0      0      0 I   0.0   0.0   0:00.03 kworker/u9:0-events_unbound           
     31 root      20   0       0      0      0 I   0.0   0.0   0:00.00 kworker/u10:0-flush-254:0             
     34 root      20   0       0      0      0 S   0.0   0.0   0:00.00 kdevtmpfs     
```  
**Explanation:**  
* up 1:19 - up for 1h 19 min (potentially a problem if a server shows fresh uptime)  
* 1 user - 1 user logged in (me)
* load average: trending performance. However many cpus / cpu cores - thats how many points of load average that would constitute 100% usage. (4 cores => load avg = 4 to mean 100% load). 
* tasks: task status. 1 running does not equal how many things are opened on the screen. It means 1 task is using the CPU at the moment. 
* Zombie: child process is a process started by another process. Zombie means the child terminated, but the parent hasn't read the exit status (wait() syscall). Orphans means parent process closed but child process is waiting for final instruction from the parent => turns into an orphan (re-parented to PID 1) - Harmless in most cases.  
* 0.0 (percentage of time cpu has been used to process task here) us = user space (programs run here), 0.0 sy = kernel space  
* 0.0 ni = niceness (priority value of a process), id = idle, wa = waiting for disk I/O (the higher the worse), hi & si = hardware and software interrupts, st = how much time a virtual cpu has been waiting for a physical cpu  
* Mib Mem: last line - how much mem the cache is using
* MiB Swap: the more used - the higher the resource contention is

* Lower section:  
* PR = priority, VIRT = tot virtual memory used, RES = how much physica mem used
* SHR = shared memory, CPU MEM usage, TIME+ = how much time cpu has spent on the task, COMMAND = which actual command is ran by the task  
Main focus is usually on CPU and MEM usage. (`shift + p` to sort by CPU usage, `shift + m` by mem usage)
* press `K` to kill a process by the process id
* press `D` to change update time for the command

### Important fields to check
* Uptime (unplanned restart?)  
* id (idle field) - the higher the num, the less work is done (underused server might be a problem). Or if fluctuation is too big. 
* Swap is overly-utilized  
* Load avg

### linux-unix-learning/phase-1-os-kernel/shell-primitives/lab-01-shell-automation/SOLUTION.md
# Lab 00: Shell Primitives & Administrative Automation

**Host Machine:** Debian 13 VM  
**Repository:** `devops-foundations`  
**Section:** Shell Primitives & Automation  

---

## 🎯 Lab Objectives
1. Inspect and execute shell scripts using variable expansion, conditional checks, and sourcing (`. /etc/os-release`).
2. Redirect combined output (`&>>`) into log files.
3. Validate privilege checks (`$EUID`) and non-interactive job scheduling via `at` or `cron`.

---

## Task 1: Script Execution & Combined Redirection

### 1. Execute Health Script
Run the generated health logging script twice:
```bash
/tmp/system_health.sh
/tmp/system_health.sh
```

### 2. Inspect the Log Output
View the appended combined output stored in `/tmp/devops_logs/health.log`:
```bash
cat /tmp/devops_logs/health.log
```

* **Terminal Output:**
```text
[Sat Oct  3 04:04:46 AM EDT 2026] Running on Debian GNU/Linux (13)
[Sat Oct  3 04:04:46 AM EDT 2026] Disk Usage: 39%
[Sat Oct  3 04:04:47 AM EDT 2026] Running on Debian GNU/Linux (13)
[Sat Oct  3 04:04:47 AM EDT 2026] Disk Usage: 39%
```

---

## Task 2: Privilege Inspection & Scheduling

### 1. Root Execution Check (`$EUID`)
Explain how a script checks for root privileges non-interactively:
```bash
if [ "$EUID" -ne 0 ]; then
    echo "Error: Must be run as root." >&2
    exit 1
fi
```

"$EUID" is 0 for root users. If not 0, then not root.

### 2. One-off Job Scheduling (`at`)
Schedule the script to run 1 minute from now using the `at` command:
```bash
echo "/tmp/system_health.sh" | at now + 1 minute
```

Verify the job is queued:
```bash
atq
```

* **`atq` Output:**
```text
6       Sat Oct  3 04:09:00 2026 a gleb
```

---

## Task 3: Cleanup

Remove the temporary lab files from the system:
```bash
rm -rf /tmp/devops_logs /tmp/system_health.sh setup_lab.sh
```

---

## 📌 Key Takeaways
* Sourcing files (`. /etc/os-release`) loads environment variables directly into the current execution shell without spawning a child process.
* Using `&>>` appends both Standard Output (stdout, FD 1) and Standard Error (stderr, FD 2) to a target log file.
* Checking `$EUID -ne 0` prevents partial script execution failures caused by missing root privileges during automated runs.

### linux-unix-learning/phase-1-os-kernel/shell-primitives/log-processing/README.md
# Part 1. How to Access and Read Linux Log Files For Information and Troubleshooting
## Accessing Logs
* `/var/log` is where the logs are usually stored
* `last` used to view contents of the wtmp binary log
* `lastb (lastb -adF)` to check bad login attempts of the lastb binary log
* `tail -f /file` - gives last portion of the file and follow immediate changes
* `journalctl -u <name of a unit>` or follow mode `journalctl -fu ssh` - systemd units / services and their logs
* `systemctl start <unit>` - start / stop / enable services
### Fedora:
* `boot.log` - boot log file
* `dnf.log` - history of installed packages
### Ubuntu / Debian-based:
* `auth.log` to see authentication attempts
* `syslog` shows system events (hardware issues)
* `apt/history` - history of installed packages / updates
* `dmesg` or just `sudo dmesg` - similar to sys log, more info on hardware (kernel log file)
# Part 2. Using the Most Common Commands for Parsing.
## Parsing
* `cat <file-name> | grep "smth we're looking for"` - look for a specific word in a file
* add `| cut -d " " -f 11` to the command above to get the specific column of user names who tried to get access to the server in auth.log file
* add `| sort` for alphabetical sorting
* add `| uniq` for getting unique values only, no duplicates
* `wc -l ` - word count (how many lines in the list)
* `grep -v <word>` - dont include a specific word
* `uniq -d` - list of duplicates
## Arch's journalctl parsing
* `journalctl -p <level>` - filet log by priority (emerg, alert, crit, err, warning, notice, info, debug)
* `journalctl -u <unit>` - filter logs from a specific systemd service
* `journalctl --since / -- until` - filter by absolute or relative time ranges (`journalctl --since "1 hour ago"`)
* `journalctl -b` - show logs from the current boot (-b -1 for previous boot)
* `journalctl -o json` - output logs in structured json format for other tools (`journalctl -u sshd -o json`)
## Advanced Field Parsing with `awk`  
`cut` won't work well with variable spacing in logs. `awk` sees multiple whitespaces as one delimiter
### `awk` Mechanics
* Columns: `$1` is column 1, `$2` is column 2, and `$NF` is the very last column
* Printing: `awk '{print $1, $5}'`prints only columns 1 and 5
* Filtering Conditions: `awk '$5 == "ERROR" {print $0}'` only prints lines where column 5 equals "Error"
## Stream Editing with `sed`  
Modifies text as it flows through a pipe (used for stripping sensitive info like passwords or API tokens) or clean up noisy line prefixes before outputting logs
### Basic Substitution Syntax
`sed 's/search_term/replace_term/g`
* `s`: Substitute command
* `g`: Global flag (replace all matches on the line, not just the first)
* `journalctl -b | sed -E 's/192\.168\.[0-9]+\.[0-9]+/XXX.XXX.XXX.XXX/g'` - masks internal ip addresses in a log stream

### linux-unix-learning/phase-1-os-kernel/shell-primitives/permissions-and-pckgmng/file-and-dir-permissions/README.md
# File & Directory Permissions
`ls -l`
```console
total 16
drwxrwxr-x 3 gleb gleb 4096 Aug 29 06:07 ansible
drwxrwxr-x 5 gleb gleb 4096 Sep 21 11:11 linux-unix-learning
-rw-rw-r-- 1 gleb gleb   80 Aug 29 06:07 README.md
drwxrwxr-x 4 gleb gleb 4096 Aug 29 06:07 servers
```
## **Explanation:**  
### ansible directory info  
`drwxrwxr-x 3 gleb gleb 4096 Aug 29 06:07 ansible`
#### 1st group: d
* Means it's a directory (also can be '-' = file, or l = link)
#### 2nd group: rwx
* Permissions for the user that owns this object
* r = read (Contents of file or the directory)
* w = write (Content can be added to a file, modify an item, or put smth in the directory)
* x = execute a file (like a bash script), or the right to go inside (cd into) a directory. Without it - could read and and add files to the dir, but can't go into the dir. 
* `chmod +x` to make a file executable for everyone
* `chmod u-x` = subtract 'x' from user - remove executable permission for the user
* `chmod g-x` - remove from user
* `chmod o-x` - remove from other
* `chmod u+x` - add (same with the others)
* `chmod g+rw` - multiple permissions can be added to user / group / other this way
#### 3rd group: rwx
* same letters - apply to the group (also 'gleb'). Scenario: accounting team - financial reports - dont want everyone to see them - only ppl who need to see them - create group 'accounting', give the rights (read only for instance).
#### 4th group: r-x
* apply to OTHERS. Everyone else other than the user and the group.
* if user's (owner's) rights removed - the owner couldn't do anything to its own file, but everyone else could do r-x still.
#### '3':
* Hard link count
* File: number of directory entries point to the file's inode on disk
* Directory: counts the dir itself, internal reference to itself ('.'), and every subdir inside it (thru their '..' parent links)
#### gleb (1st):
* The owner of the object
#### gleb (2nd):
* The group that owns the object (usually named after the user when smth is created)
#### 4096:
* Size of the directory metadata - not the total size of the files stored inside it.

### Numerical representation
* r = 4
* w = 2
* x = 1
* `chmod ??? permissions-test.txt`
* 1st '?' - user, 2nd - group, 3rd - other
* `chmod 770` - 4 + 2 + 1 = 7. Add totals of each, meaning add all permissions for user and group, and no permissions for other
* `chmod -R ??? dir/` - change permissions for everything inside a dir (everything in the dir - not recommended)
* `chmod 600 dir/*` - better way, but better use `find` for specific objects to change permissions of

### Ownership
* `chown -R 'user' dir/` - change ownership of a directory (and everything inside it). Won't work without sudo - have to have permissions to change the ownership. The group won't change tho.
* `chown -R 'user':'user' dir/` - to change the group ownership
* `chown -R 'user': dir/` - colon used with no specification - defaults to the user's group

### Security trick
There is a /shared/ata dir with 777. Inside of it is secret.txt owned by root:root with 400  
A standard user can delete the file even without having write rights since deleting unlinks the filename from the inode only.  
#### Solution:
* Stricky bit
* `chmod +t /dir` - restricts file deletion in shared directories


### linux-unix-learning/phase-1-os-kernel/shell-primitives/vim/README.md
## Vim Basic Usage  
### 1. Modes  
#### 3 basic modes:
* Normal Mode (Esc) - the default mode for navigation, searching, and text manipulations
* Insert Mode (i / a / A) - for typing text into the file
* Command Mode (:) - for saving, quitting, and file level operations  
### 2. Faster Navigation  
* Go to top of file - `gg`
* Bottom of file - `G`
* Go to line - :<line> or <line>G
* Search for pattern - /<pattern>
* Next match - `n`
* Previous match - `N`
### 3. Editing & Line Management
* Insert Before - `i`
* Append after - `a`
* Append at end - `A`
* Delete / Cut line - `dd`
* Paste below - `p`
* Paste above - `P`
* Undo - `u`
### 4. Saving & Exiting
* Save - `:w`
* Quit (with no unsaved changes) - `:q`
* Save and quit - `:wq` or `:x`
* Force quit - `:q!`


### linux-unix-learning/phase-1-os-kernel/system-supervision-and-storage-mechanics/df-vs-du/README.md
# What's df and du, and How They Are Used
* `df` = disk free
* `df -h` for clear output
* `df -hT` - to see tye file system type of the mount
* `df -hTx tmpfs` - getting rid of tmpfs f or cleaner output
* `watch df -hTx tmpfs` - real time output
* `df` is not really useful for seeing which directory takes up space
* `df -i` to check for node exhaustion

### `du`
* `du /home/gleb` - unreadable line of text
* `du -hx --max-depth 1 /home/gleb | sort -hr` - controls the depth of scanned directories. Easier to read.
* `du -hs <dir> <dir>` to compare usage of two directories. Add `-c` to see total of two.
* `du -hsc /home/gleb/*` to get summary of the whole directory with its subdirs and a total.

### `ncdu`
* `ncdu` gives a nice interactive way of going thru directories

### linux-unix-learning/phase-1-os-kernel/system-supervision-and-storage-mechanics/filesystems-and-mounting/README.md
# File Systems
* controls how data is stored and retrieved
* formatting = bits set to zero, then disk divided into sectors and grouped into clusters or data blocks
* data block is usually 4 kb
* starting blocks are for disk managing info and boot sectors, and second block is for inodes for mapping logical to physical addresses
* then data blocks
### ext4
* journaling file system
* splits disk into equal sectors which are formed into 1kb - 64kb blocks (typically 4kb)
* blocks are then grouped into larger block groups
* blocks are always extended to improve large file perfomance and make contiguous space
* reduced fragmentation
* first block = boot sector
* second - superblock
* third - inode bitmap
* then inodes with pointers
* last - data zone
* journaling - journal contains changes in process, not commited yet
* items from the journal can be rerun in case of errors
* delayed allocation - data is stored in a buffer before data blocks
* better for block allocation
* online defragmentation - no need for unmounting to defragment
### xfs
* enterprise standard
* ideal for large data
* high i/o performance
* journaling 64 bit file system - max file system size is 16 EiB
* disk partitioned into allocation groups - larger than block groups
* max size of allocation group - 1tb. Manages its own inodes and allocation space
* almost like individual filesystems with its own space usage for parallelism (multiple cpus and threads perform at the same time)
* direct i/o - no file cache
* guaranteed i/o - bandwith requested is provided
* online defragmentation
* online resizing
### zfs
* max disk size = 1000 EB
* combined file system - volume managed and a file system
* used in server (ubuntu server)
* max vol size = 256 trillion EB - largest
* all disks available are combined into a large storage pool (SPA)
* filesystems are created under it. Folders and root dirs. All is shared
* One file system for each department for instance. Automatic disk space allocation
* transactional semantics - data is written on a separate buffer - copy on write
* data consistency
* checksums
* snapshosts
* raid-z
* built-in scrub function to repair silent corruption
### btrfs
* COW (copy on write)
* non-proprietary
* replaces ext4 gradually
* uses binary tree for managing file system
* one storage pool with all storage disks
* subvolumes created as partitoin
* 64 bit file system
* single volume snapshots - copy of volume for rolling back to
* transparent file comprassion for optimizing storage capacity
* built-in RAID support
* ssd aware file system
* online defragmentation
* can be converted from ext4
### tmpfs
* temporary filesystem stored in RAM
* super fast
* data destroyed after reboot
* used for ephemeral container caches and stroing temprorary secrets
# Mounting
* process of taking a formatted filesystem and grafting it onto an empty directory
* 500GB `xfs` drive mounted to `/var/lib/postgresql` - any data written to this path is physically written to that ssd
* once unmounted -data is not deleted. Disk is simply disconnected from the tree
* `mount` is temporary. Virtual File System is rebuilt after reboot
* to make mounts persistent, boot manager (`systemd`) reads `/etc/fstab` line by line and does mounts automatically

### linux-unix-learning/phase-1-os-kernel/system-supervision-and-storage-mechanics/node-exhaustion/README.md
# Inodes and Their Mechanism
* a file is a filename and an inode number
* directory has a table of filename-inode pairings
* `ls -i`  to see the bindings
* Inode contains size, location on the disk, permissions, owner, creation date, modification, access time, reference count (hard links)
* `stat <file>` - to see the inode content directly. Thats what `ls` uses
* if inode table is full - new file cant be created
* ton of small files can cause that exhaustion
* amount of inodes is preset once the filesystem is created (ext4)
#### **when writes fail with `No space left on device` but `df -h` shows ample gigabytes available, the very first reflex must be `df -i`**

### Troubleshoting 
* `find` to recursively list the absolute path of every single file
* `| cut` to truncate and extract the parent dir paths
* `| sort` so identical dir paths are grouped together sequentally
* `| uniq -c` to count the adjacent grouped occurrences
* `| sort -n` to sort the list numerically, exposing the directory holding millions of files at the bottom of the output  
  
* `find /path/to/cache -type f -delete` to actually delete those millions of files, since rm would fail (too many arguments)

### linux-unix-learning/phase-1-os-kernel/system-supervision-and-storage-mechanics/systemd-and-services/mini-lab-systemd-service/SOLUTION.md
# Lab 02: System Supervision & Custom `systemd` Service

**Host Machine:** Debian 13 VM  
**Repository:** `devops-foundations`  
**Section:** System Supervision & Storage Mechanics  

---

## 🎯 Lab Objectives
1. Create and configure a custom background daemon script under `/usr/local/bin/`.
2. Write a custom `systemd` service unit file under `/etc/systemd/system/` with automated recovery rules.
3. Validate service management controls (`systemctl start|status|enable`) and stream unit logs via `journalctl`.
4. Test process resilience by forcibly killing the daemon (`SIGKILL`) and observing `systemd` auto-restart behavior.

---

## Task 1: Service Activation & Status Verification

### 1. Start and Enable Service
Start the custom service and enable it to launch automatically at boot:
```bash
sudo systemctl start devops-worker.service
sudo systemctl enable devops-worker.service
```

### 2. Inspect Service Status
Check operational state and running Process ID (PID):
```bash
systemctl status devops-worker.service
```

* **Terminal Output:**
```text
● devops-worker.service - DevOps Worker Background Service
     Loaded: loaded (/etc/systemd/system/devops-worker.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-10-08 12:29:39 EDT; 6min ago
 Invocation: 9db2c3f2049e43ff9e4ad49f3c6f2338
   Main PID: 5939 (devops_worker.s)
      Tasks: 2 (limit: 2317)
     Memory: 580K (peak: 1.8M)
        CPU: 261ms
     CGroup: /system.slice/devops-worker.service
             ├─5939 /bin/bash /usr/local/bin/devops_worker.sh
             └─6321 sleep 3

Oct 08 12:35:57 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:35:57 PM EDT 2026
Oct 08 12:36:01 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:36:01 PM EDT 2026
Oct 08 12:36:04 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:36:04 PM EDT 2026
Oct 08 12:36:07 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:36:07 PM EDT 2026
Oct 08 12:36:10 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:36:10 PM EDT 2026
Oct 08 12:36:13 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:36:13 PM EDT 2026
Oct 08 12:36:16 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:36:16 PM EDT 2026
Oct 08 12:36:19 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:36:19 PM EDT 2026
Oct 08 12:36:22 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:36:22 PM EDT 2026
Oct 08 12:36:25 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:36:25 PM EDT 2026
```

---

## Task 2: Log Streaming & Process Resilience Test

### 1. Stream Logs via Journalctl
Stream live logs specifically generated by the unit file:
```bash
journalctl -u devops-worker.service -n 5 --no-pager
```

* **Logged Entries:**
```text
Hint: You are currently not seeing messages from other users and the system.
      Users in groups 'adm', 'systemd-journal' can see all messages.
      Pass -q to turn off this notice.
Oct 08 12:38:01 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:38:01 PM EDT 2026
Oct 08 12:38:04 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:38:04 PM EDT 2026
Oct 08 12:38:07 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:38:07 PM EDT 2026
Oct 08 12:38:10 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:38:10 PM EDT 2026
Oct 08 12:38:13 debian-vm-lab devops_worker.sh[5939]: [RUNNING] Worker active at Thu Oct  8 12:38:13 PM EDT 2026
```

### 2. Test Process Resiliency (`kill -9`)
Identify the running PID from `status`, then forcibly kill it using `SIGKILL` (9):
```bash
# Note down PID from status (e.g. PID 4520)
sudo kill -9 <PID>
```

Wait 3 seconds, then re-check service status:
```bash
systemctl status devops-worker.service
```

* **Observed Behavior:**
  > What happened to the PID? Did `systemd` automatically restart the service?
  The PID has changed after the abrupt killing. Systemd successfully restarted the service.
```text
● devops-worker.service - DevOps Worker Background Service
     Loaded: loaded (/etc/systemd/system/devops-worker.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-10-08 12:39:06 EDT; 4s ago
 Invocation: 18578125197741059997625caadfbd77
   Main PID: 6569 (devops_worker.s)
      Tasks: 2 (limit: 2317)
     Memory: 572K (peak: 1.8M)
        CPU: 8ms
     CGroup: /system.slice/devops-worker.service
             ├─6569 /bin/bash /usr/local/bin/devops_worker.sh
             └─6573 sleep 3

Oct 08 12:39:06 debian-vm-lab devops_worker.sh[6569]: [INIT] Starting DevOps Worker Daemon (PID: 6569)...
Oct 08 12:39:06 debian-vm-lab devops_worker.sh[6569]: [RUNNING] Worker active at Thu Oct  8 12:39:06 PM EDT 2026
Oct 08 12:39:09 debian-vm-lab devops_worker.sh[6569]: [RUNNING] Worker active at Thu Oct  8 12:39:09 PM EDT 2026
```

---

## Task 3: Cleanup

Stop and disable the unit, then remove custom files created during the lab:
```bash
sudo systemctl stop devops-worker.service
sudo systemctl disable devops-worker.service
sudo rm /etc/systemd/system/devops-worker.service
sudo rm /usr/local/bin/devops_worker.sh
sudo systemctl daemon-reload
```

---

## 📌 Key Takeaways
* Unit files stored in `/etc/systemd/system/` take administrative priority over vendor defaults in `/lib/systemd/system/`.
* `systemctl daemon-reload` must be executed whenever unit configuration files are added or modified on disk.
* Configuring `Restart=always` alongside `RestartSec=` allows systemd (PID 1) to function as a process supervisor, automatically restoring crashed applications.

### linux-unix-learning/phase-1-os-kernel/system-supervision-and-storage-mechanics/systemd-and-services/README.md
# How to Manage Linux Services
* init system is the very first thing that starts - systemd is one of them
* PID1
* manages all other processes
### Working with Units
* Units = resources that are able to be managed by systemd
* services, timers, mounts, etc.
* `systemctl status <unit>` - to check status of a unit
* `sudo systemctl start <unit>` to start
* `sudo systemctl stop <unit>` to stop it
* `sudo systemctl restart <unit>` - restart
* `sudo systemctl enable <unit>` - to make unit start on boot
* `sudo systemctl disable <unit>`
* `sudo systemctl reload <unit>` - more graceful restart withouth abrupting
### Service files 
* instructions for systemd on how to manage a service
* .service extention
* syntax in a file is important
* wants and after = requirements for the service before it's started
* simple type = start up as soon as started
* forking = parent and child kind of startup
* execstart is the process started with the service
* reload  
### Systemd Unit Directories:
* in priority order:
* /etc/systemd/system - the most common, highest priority
* /run/systemd/system - runtime units
* /lib/systemd/system - service files after installing a service are usually here.
### Editing Unit Files
* `systemctl edit <unit-file>`
* special override created file
* changes will be merged into the actual file
* to change it - should be made in the specific section in the file, with no hash comment
* `sudo rm /etc/systemd/system/<service>.service.d/override.conf` to remove the changes made
* `sudo systemctl edit --full <service>.service` - use the entire config file as the base
* /etc/systemd/system - safer for making changes since override the changes from lower priority dirs
* `sudo systemctl daemon-reload` - to re-read unit files after editing or creating anything in /etc/systemd/system/
* `jourlanctl -u <service> -f` - live steram logs

