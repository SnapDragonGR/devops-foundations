
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
