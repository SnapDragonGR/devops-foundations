# /proc pseudo-filesystem usage
* top, htop, or ps - all use a virtual file system - proc at proc/  
* proc/ holds info abt processes
* "files" are updated on the fly
* statm shows memory used (inside "directory" which is a file in proc)
* strace for advanced process info tracing