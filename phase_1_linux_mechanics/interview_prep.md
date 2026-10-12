# Phase 1: Linux Kernel & Systems Engineering — Interview Technical Preparation

This document outlines core Linux failure modes, kernel mechanics, and operational triage workflows frequently targeted in systems engineering and infrastructure technical interviews.

---

## 1. Process Lifecycle, Signals & Kernel Scheduling

### Scenario 1.1: The Zombie Process (`Z` State)
* **Interview Prompt:** *"You run `top` and notice a high zombie count. Can you terminate a zombie process with `kill -9 <PID>`? Why or why not, and how do you clear it from the process table without rebooting?"*
* **Target Architectural Concept:** Process lifecycle, `task_struct`, the `wait()` syscall, and PID 1 orphan adoption.
* **My Answer / Explanation:** the process can't be simply killed with `kill -9` since it is already terminated. POSIX requires the parent to do `wait()` to reap the exit code. Need to find and kill the parent. Zombie turns to oprhan.  
Kernel re-parent the orphan to PID 1, which then issues the wait() and reaps the dead `task_struct` from the kernel process table.
* **Diagnostic & Remediation Commands:**
  `ps -ef --forest` or `pstree -p -s <zombie_pid>` - note PPID
  `kill <PPID>` or `kill -9` if unresponsive

### Scenario 1.2: Uninterruptible Sleep (`D` State) vs. CPU Load
* **Interview Prompt:** *"A server alerts on high Load Average (e.g., 40.0 on an 8-core CPU), but CPU idle time is 95%. What process state explains this, why does `kill -9` fail to terminate the thread, and what is the recovery path?"*
* **Target Architectural Concept:** `TASK_UNINTERRUPTIBLE`, kernel scheduler signal deferral, kernel-space I/O wait, and load average calculation.
* **My Answer / Explanation:**
  There is process in a deep sleep `D` state. It's waiting for some I/O operation to finish. Kill -9 is not allowed since interuppting mid I/O can cause data corruption. Kernel blocks the asynchronous signals.  
  Load Average includes both `TASK_RUNNING` and `TASK_UNINTERRUPTIBLE (D)`. Cpu does 0 work, the kernel still thinks those threads are blocked.
* **Diagnostic Commands:**
  `ps -eo pid,user,stat,comm | awk '$3 ~ /D/'` to find D state processes
  `cat /proc/PID/wchan` to inspect the kernel wait channel
  `sudo cat /proc/PID/stack` to see the raw kernel call stack
  `sudo reboot` or restore connectivity to the storage device.

### Scenario 1.3: Signal Trapping vs. Kernel Termination
* **Interview Prompt:** *"Explain the mechanical difference between `SIGTERM` (15) and `SIGKILL` (9). Why might an application ignore `kill <PID>`, and what occurs at the kernel level when you pass `-9`?"*
* **Target Architectural Concept:** User-space signal vector tables/handlers vs. kernel-space task scheduler destruction.
* **My Answer / Explanation:**
  `SIGTERM` is a graceful user-space way of terminating a process. It gently tells the process to terminate, without forcing it.  
  `SIGKILL` is a brute-force kernel level way of killing the process. It directly sends the terminate request to it, without waiting. Abrupt and sometimes dangerous way.
* **Diagnostic Commands:**
  `kill <PID>` for `SIGTERM` (15) & `kill -9 <PID>` for `SIGKILL` (9)

### Scenario 1.4: OOM Killer Mechanics & Memory Protection
* **Interview Prompt:** *"How does the Linux kernel determine which process to terminate during an out-of-memory event, and how can you protect a critical daemon from being killed?"*
* **Target Architectural Concept:** `/proc/<PID>/oom_score`, `/proc/<PID>/oom_score_adj`, and memory cgroups/watermarks.
* **My Answer / Explanation:**
  oom_killer forcibly shoots down a process and frees up needed memory. Victim is chosen by "badness" score from 0 to 1000 for every process in `/proc/<PID>/oom_score.  
  High score = first to die. Lower = kept alive.  
  Daemon can be protected by tuning the priority in /proc/<PID>/oom_score_adj. From -1000 (never kill) to 1000 (kill first).
* **Diagnostic & Configuration Commands:**
  `cat /proc/<PID>/oom_score` & `echo <value> | sudo tee /proc/<PID>/oom_score_adj  
  or `OOMScoreAdjust=<value>` in a service config.
---

## 2. Virtual File System (VFS) & Storage Failures

### Scenario 2.1: Inode Depletion vs. Disk Capacity
* **Interview Prompt:** *"An application writes to disk and crashes with `No space left on device` (`ENOSPC`), but `df -h` shows 40% free capacity. What is the root cause, and how do you resolve it?"*
* **Target Architectural Concept:** Filesystem metadata (Inodes) vs. physical data blocks, directory entry allocation.
* **My Answer / Explanation:**
  Multiple small 0-byte files take up the inode space. Resolved by deleting them thru find command to avoid the `ARG_MAX`
* **Diagnostic & Remediation Commands:**
  `df -i` in the suspected directory. `find /path/to/dir -type f -delete` to remove.

### Scenario 2.2: Ghost Disk Space & Open Unlinked Files
* **Interview Prompt:** *"A monitoring system alerts that `/var/log` is 100% full. You delete a 20GB log file using `rm`, but `df` still reports the disk at 100% capacity. Why did disk space not free up, and how do you reclaim it without rebooting or stopping the daemon?"*
* **Target Architectural Concept:** VFS two-reference rule (dentry/hard link count vs. kernel file descriptor reference count).
* **My Answer / Explanation:**
  Hard link count dropped to 0, but the process reference count was larger than 0. Need to reclaim the blocks while process remains online by live-truncating the file descriptor via `/proc`.
* **Diagnostic & Remediation Commands:**
  `sudo lsof +aL1` or `sudo lsof -a +L1 /mount_point`, `sudo su` & `> /proc/<PID>/fd/3`. `cd /path/to/dir` & `df -h` to confirm.

### Scenario 2.3: Ephemeral Mounts vs. Persistent Mount Table (`/etc/fstab`)
* **Interview Prompt:** *"Explain what happens under the hood when a filesystem is mounted via `mount` vs. configured in `/etc/fstab`. Break down the 6 fields of an `/etc/fstab` record."*
* **Target Architectural Concept:** VFS mount table reconstruction during boot, systemd mount generators, filesystem integrity checks (`fsck`).
* **My Answer / Explanation:**
  Mount works only in the current session. If rebooted - it's gone. `/etc/fstab` entry makes it permanent, at boot `systemd-fstab-generator` parses it to make native systemd `.mount` units.  
  Fields:  
  Device / Spec: `dev/sda1`, `/tmp/backup.img`, `UUID=...` or label  
  Mount Point: `/var/backups`  
  Filesystem: `ext4`
  Mount Options: `defaults,loop,noatime,ro,rw`
  Dump: `0`
  Pass / Fsck Order: `0` or `1` or `2`
* **Persistence Syntax Example:**
  `echo "/tmp/backup-vol.img /var/backups ext4 loop,defaults 0 0" | sudo tee -a

---

## 3. System Supervision & Process Boundaries (`systemd`)

### Scenario 3.1: Service Restart Loops & Diagnostics
* **Interview Prompt:** *"A critical `systemd` service is caught in a flapping restart loop. What is your systematic triage procedure to locate the failure origin?"*
* **Target Architectural Concept:** `systemd` supervision, execution barriers, and journal log aggregation.
* **My Answer / Explanation:**
I would check the systemctl status and read the journalctl logs, perhaps with `watch`.
* **Diagnostic Commands:**
`systemctl status <service>`, `sudo journalctl -u  <service>`, `systemctl restart <service>`, `sudo systemctl edit --full <service>.service` to edit smth in the service config.
### Scenario 3.2: Principle of Least Privilege & Runtime Boundaries
* **Interview Prompt:** *"An application service running under `User=nobody` fails when creating a PID or lockfile under `/etc` or `/var/run`. Why is running it as `root` an anti-pattern, and what is the proper production architecture to provide a writable runtime path?"*
* **Target Architectural Concept:** POSIX filesystem permissions, Filesystem Hierarchy Standard (FHS), and systemd `RuntimeDirectory`.
* **My Answer / Explanation:**
if run as Root, malicious actor can run anything in the directory, including some dangerous binaries or scripts that would affect the whole system.  
Better to isolate by using non-root dirs.
* **Unit Configuration Snippet:**
`sudo systemctl edit --full <service>.service`, append under [Service] `RuntimeDirectory=<service>`, change script to write in the `/run/<service>/service.lock`
---

## 4. Shell Primitives & Kernel Limits

### Scenario 4.1: The `ARG_MAX` Barrier
* **Interview Prompt:** *"You attempt to clear a directory containing 500,000 files by running `rm -rf *`, and the shell returns `Argument list too long`. Why does this occur, and how do you resolve it?"*
* **Target Architectural Concept:** Kernel execution limit (`ARG_MAX`), glob expansion in user space, and native directory iteration.
* **My Answer / Explanation:**  
Wildcards are not expaneded by commands like `rm`. Expanded by `bash` instead (shell).  
Bash then attempts to pass the massive array of strings into `execve()` to do `rm`.  
Linux kernel has a limit of arguments and env variables passed to a new process - `ARG_MAX`. (2 - 6 MB).  
If string array > buffer, kernel aborts the `execve()` with `Argument list too long`.  
`find` uses `opendir()` sys call, reads entry by `readdir()` and issues `unlink()`.  
* **Remediation Command:**
  `sudo find /path/to/dir -type f -delete`