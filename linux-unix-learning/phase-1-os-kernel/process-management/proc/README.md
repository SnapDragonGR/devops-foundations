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
