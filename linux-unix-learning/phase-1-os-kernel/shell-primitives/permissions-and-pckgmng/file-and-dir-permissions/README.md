# File & Directory Permissions
`ls -l`
```console
total 16
drwxrwxr-x 3 gleb gleb 4096 Aug 29 06:07 ansible
drwxrwxr-x 5 gleb gleb 4096 Sep 21 11:11 linux-unix-learning
-rw-rw-r-- 1 gleb gleb   80 Aug 29 06:07 README.md
drwxrwxr-x 4 gleb gleb 4096 Aug 29 06:07 servers
```
## **Explanation:**  
### ansible directory info  
`drwxrwxr-x 3 gleb gleb 4096 Aug 29 06:07 ansible`
#### 1st group: d
* Means it's a directory (also can be '-' = file, or l = link)
#### 2nd group: rwx
* Permissions for the user that owns this object
* r = read (Contents of file or the directory)
* w = write (Content can be added to a file, modify an item, or put smth in the directory)
* x = execute a file (like a bash script), or the right to go inside (cd into) a directory. Without it - could read and and add files to the dir, but can't go into the dir. 
* `chmod +x` to make a file executable for everyone
* `chmod u-x` = subtract 'x' from user - remove executable permission for the user
* `chmod g-x` - remove from user
* `chmod o-x` - remove from other
* `chmod u+x` - add (same with the others)
* `chmod g+rw` - multiple permissions can be added to user / group / other this way
#### 3rd group: rwx
* same letters - apply to the group (also 'gleb'). Scenario: accounting team - financial reports - dont want everyone to see them - only ppl who need to see them - create group 'accounting', give the rights (read only for instance).
#### 4th group: r-x
* apply to OTHERS. Everyone else other than the user and the group.
* if user's (owner's) rights removed - the owner couldn't do anything to its own file, but everyone else could do r-x still.
#### '3':
* Hard link count
* File: number of directory entries point to the file's inode on disk
* Directory: counts the dir itself, internal reference to itself ('.'), and every subdir inside it (thru their '..' parent links)
#### gleb (1st):
* The owner of the object
#### gleb (2nd):
* The group that owns the object (usually named after the user when smth is created)
#### 4096:
* Size of the directory metadata - not the total size of the files stored inside it.

### Numerical representation
* r = 4
* w = 2
* x = 1
* `chmod ??? permissions-test.txt`
* 1st '?' - user, 2nd - group, 3rd - other
* `chmod 770` - 4 + 2 + 1 = 7. Add totals of each, meaning add all permissions for user and group, and no permissions for other
* `chmod -R ??? dir/` - change permissions for everything inside a dir (everything in the dir - not recommended)
* `chmod 600 dir/*` - better way, but better use `find` for specific objects to change permissions of

### Ownership
* `chown -R 'user' dir/` - change ownership of a directory (and everything inside it). Won't work without sudo - have to have permissions to change the ownership. The group won't change tho.
* `chown -R 'user':'user' dir/` - to change the group ownership
* `chown -R 'user': dir/` - colon used with no specification - defaults to the user's group

### Security trick
There is a /shared/ata dir with 777. Inside of it is secret.txt owned by root:root with 400  
A standard user can delete the file even without having write rights since deleting unlinks the filename from the inode only.  
#### Solution:
* Stricky bit
* `chmod +t /dir` - restricts file deletion in shared directories
