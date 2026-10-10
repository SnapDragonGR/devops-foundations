# What's df and du, and How They Are Used
* `df` = disk free
* `df -h` for clear output
* `df -hT` - to see tye file system type of the mount
* `df -hTx tmpfs` - getting rid of tmpfs f or cleaner output
* `watch df -hTx tmpfs` - real time output
* `df` is not really useful for seeing which directory takes up space
* `df -i` to check for node exhaustion

### `du`
* `du /home/gleb` - unreadable line of text
* `du -hx --max-depth 1 /home/gleb | sort -hr` - controls the depth of scanned directories. Easier to read.
* `du -hs <dir> <dir>` to compare usage of two directories. Add `-c` to see total of two.
* `du -hsc /home/gleb/*` to get summary of the whole directory with its subdirs and a total.

### `ncdu`
* `ncdu` gives a nice interactive way of going thru directories