# Inodes and Their Mechanism
* a file is a filename and an inode number
* directory has a table of filename-inode pairings
* `ls -i`  to see the bindings
* Inode contains size, location on the disk, permissions, owner, creation date, modification, access time, reference count (hard links)
* `stat <file>` - to see the inode content directly. Thats what `ls` uses
* if inode table is full - new file cant be created
* ton of small files can cause that exhaustion
* amount of inodes is preset once the filesystem is created (ext4)
#### **when writes fail with `No space left on device` but `df -h` shows ample gigabytes available, the very first reflex must be `df -i`**

### Troubleshoting 
* `find` to recursively list the absolute path of every single file
* `| cut` to truncate and extract the parent dir paths
* `| sort` so identical dir paths are grouped together sequentally
* `| uniq -c` to count the adjacent grouped occurrences
* `| sort -n` to sort the list numerically, exposing the directory holding millions of files at the bottom of the output  
  
* `find /path/to/cache -type f -delete` to actually delete those millions of files, since rm would fail (too many arguments)