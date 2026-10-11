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