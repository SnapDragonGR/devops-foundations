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