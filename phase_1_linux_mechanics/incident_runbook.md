# Ghost Disk Space Troubleshooting
### Symptopms
`df -h` shows disk at 100%, but `du -sh /*` shows minimal usage. `df -i` confirms inode usage is low.  
**Root Cause (Ghost Space)**: a large file (typically a log) was deleted with `rm` while a daemon was still writing to it.  
The VFS layer requires both the directory hard link count AND the process reference count to reach zero before returning the blocks to the free pool.
**Diagnosis**:
1. Run `lsof +aL1 /var` to find deleted files with active process locks.
2. Note the target process PID and FD (File Descriptor) number. **Remediation (Live Truncation):**
3. Do not kill the process.
4. Truncate the file directly via the kernel virtual filesystem: `> /proc/<PID>/fd/<FD>

# INCIDENT: prod-worker.service cascading failure
**Date:** 2026-10-11

## 1. Service Diagnostics
*   **Symptom:** `prod-worker.service` was continuously restarting.
*   **Root Cause:** `touch /mnt/prod_data/heartbeat.log` kept failing - filesystem kept rejecting the operation
*   **Remediation Command(s):** `systemctl status prod-worker.service` and `journalctl -u prod-worker.service`

## 2. Storage Remediation (Inode Exhaustion)
*   **Symptom:** `df -h` showed free disk space, but writes failed with `No space left on device`.
*   **Root Cause:** the disk had plenty of space, but zero metadata slots since lots of empty session files piled up the inodes. `df -i` showed it.
*   **Remediation Command(s):** `find /mnt/prod_data/ -type f -delete` to bypass the `ARG_MAX`

## 3. Storage Remediation (Ghost Space)
*   **Symptom:** A 100MB log file was consuming space in `/tmp/`, but `du` could not see it. 
*   **Root Cause:** deleted-but-open file using up the space
*   **Remediation Command(s):** `lsof +aL1 /tmp` `sudo su` and `> /proc/2710/fd/3`

## 4. Ephemeral Mount Persistence
*   **Symptom:** The `/mnt/prod_data` partition was mounted manually and would not survive a reboot.
*   **Root Cause:** The VFS tree is rebuilt entirely on boot. 
*   **Remediation Command(s):** `echo "/tmp/prod-data.img /mnt/prod_data ext4 loop,defaults 0 0" | sudo tee -a /etc/fstab`

# INCIDENT: Phase 1 Outage (Kernel, Storage & Supervision)
**Incident Date:** 2026-10-12
**Severity:** P1 - Critical Outage

## 1. Rogue Process & Kernel Signaling
*   **Symptom:** Core CPU utilization pegged at 100%. Process refused graceful shutdown.
*   **Root Cause:** - rogue process hopped the entire cpu as shown in `top` output. SIGTERM failed due to user-space delivery. Kill -9 is the brutal force here, cant be caught, direct scheduler handling.
*   **Triage & Resolution Commands:**
    *   `top`
    *   `sudo cat /proc/5514/oom_score`
    *   `sudo kill -9 5514`

## 2. Unlinked Open File (Ghost Storage)
*   **Symptom:** 200MB disk capacity held on root partition; invisible to directory scans (`du`).
*   **Root Cause:** hard link count dropped to 0, but the process reference count was greater than 0. Have to kill the process to close the file descriptor.
*   **Triage & Resolution Commands:**
    *   `sudo lsof +aL1`
    *   `sudo su` & `> /proc/5546/fd/3`
    *   `cd /var/log` & `df -h`

## 3. Inode Depletion & Mount Persistence
*   **Symptom:** Writes to `/var/backups` failing with `No space left on device` despite available disk blocks.
*   **Root Cause:** inode exhaustion - too many 0 bite files hogging the inodes
*   **Triage & Resolution Commands:**
    *   `cd /var` & `df -i`
    *   `sudo find /var/backups -type f -delete`
    *   `echo "/tmp/backup-vol.img /var/backups ext4 loop,defaults 0 0" | sudo tee -a /etc/fstab`

## 4. Service Crash-Loop (`systemd` Supervision)
*   **Symptom:** `ecommerce-app.service` failing continuously with exit code status errors.
*   **Root Cause Layer 1 (POSIX File Permissions):** +x flag wasn't in place - had to make it executable to run the script
*   **Root Cause Layer 2 (Least Privilege Violation):** trying to create a file in /etc dir - need root elevation, which is forbidden.
*   **Triage & Resolution Commands:**
    *   `systemctl status ecommerce-app.service` & `sudo journalctl -u ecommerce-app.service`
    *   `chmod +x /usr/local/bin/ecommerce-app.sh`
    *   `sudo systemctl edit --full ecommerce-app.service`, append under [Service] RuntimeDirectory=ecommerce, change script to `touch /run/ecommerce/ecommerce.lock`
    *   `systemctl status ecommerce-app.service` & logs
    *   `● ecommerce-app.service - Critical E-Commerce Backend
     Loaded: loaded (/etc/systemd/system/ecommerce-app.service; disabled; preset: enabled)
     Active: active (running) since Mon 2026-10-12 02:21:12 EDT; 55s ago
 Invocation: bd2bcc450f574f478bbee566f6663e13
   Main PID: 7522 (ecommerce-app.s)
      Tasks: 2 (limit: 2317)
     Memory: 572K (peak: 2M)
        CPU: 6ms
     CGroup: /system.slice/ecommerce-app.service
             ├─7522 /bin/bash /usr/local/bin/ecommerce-app.sh
             └─7525 sleep 300`
