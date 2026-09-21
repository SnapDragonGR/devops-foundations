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