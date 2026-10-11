# File Systems
* controls how data is stored and retrieved
* formatting = bits set to zero, then disk divided into sectors and grouped into clusters or data blocks
* data block is usually 4 kb
* starting blocks are for disk managing info and boot sectors, and second block is for inodes for mapping logical to physical addresses
* then data blocks
### ext4
* journaling file system
* splits disk into equal sectors which are formed into 1kb - 64kb blocks (typically 4kb)
* blocks are then grouped into larger block groups
* blocks are always extended to improve large file perfomance and make contiguous space
* reduced fragmentation
* first block = boot sector
* second - superblock
* third - inode bitmap
* then inodes with pointers
* last - data zone
* journaling - journal contains changes in process, not commited yet
* items from the journal can be rerun in case of errors
* delayed allocation - data is stored in a buffer before data blocks
* better for block allocation
* online defragmentation - no need for unmounting to defragment
### xfs
* enterprise standard
* ideal for large data
* high i/o performance
* journaling 64 bit file system - max file system size is 16 EiB
* disk partitioned into allocation groups - larger than block groups
* max size of allocation group - 1tb. Manages its own inodes and allocation space
* almost like individual filesystems with its own space usage for parallelism (multiple cpus and threads perform at the same time)
* direct i/o - no file cache
* guaranteed i/o - bandwith requested is provided
* online defragmentation
* online resizing
### zfs
* max disk size = 1000 EB
* combined file system - volume managed and a file system
* used in server (ubuntu server)
* max vol size = 256 trillion EB - largest
* all disks available are combined into a large storage pool (SPA)
* filesystems are created under it. Folders and root dirs. All is shared
* One file system for each department for instance. Automatic disk space allocation
* transactional semantics - data is written on a separate buffer - copy on write
* data consistency
* checksums
* snapshosts
* raid-z
* built-in scrub function to repair silent corruption
### btrfs
* COW (copy on write)
* non-proprietary
* replaces ext4 gradually
* uses binary tree for managing file system
* one storage pool with all storage disks
* subvolumes created as partitoin
* 64 bit file system
* single volume snapshots - copy of volume for rolling back to
* transparent file comprassion for optimizing storage capacity
* built-in RAID support
* ssd aware file system
* online defragmentation
* can be converted from ext4
### tmpfs
* temporary filesystem stored in RAM
* super fast
* data destroyed after reboot
* used for ephemeral container caches and stroing temprorary secrets
# Mounting
* process of taking a formatted filesystem and grafting it onto an empty directory
* 500GB `xfs` drive mounted to `/var/lib/postgresql` - any data written to this path is physically written to that ssd
* once unmounted -data is not deleted. Disk is simply disconnected from the tree
* `mount` is temporary. Virtual File System is rebuilt after reboot
* to make mounts persistent, boot manager (`systemd`) reads `/etc/fstab` line by line and does mounts automatically