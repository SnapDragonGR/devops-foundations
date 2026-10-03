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
