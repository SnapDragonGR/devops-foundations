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
