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
