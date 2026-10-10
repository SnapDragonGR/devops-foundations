# How to Manage Linux Services
* init system is the very first thing that starts - systemd is one of them
* PID1
* manages all other processes
### Working with Units
* Units = resources that are able to be managed by systemd
* services, timers, mounts, etc.
* `systemctl status <unit>` - to check status of a unit
* `sudo systemctl start <unit>` to start
* `sudo systemctl stop <unit>` to stop it
* `sudo systemctl restart <unit>` - restart
* `sudo systemctl enable <unit>` - to make unit start on boot
* `sudo systemctl disable <unit>`
* `sudo systemctl reload <unit>` - more graceful restart withouth abrupting
### Service files 
* instructions for systemd on how to manage a service
* .service extention
* syntax in a file is important
* wants and after = requirements for the service before it's started
* simple type = start up as soon as started
* forking = parent and child kind of startup
* execstart is the process started with the service
* reload  
### Systemd Unit Directories:
* in priority order:
* /etc/systemd/system - the most common, highest priority
* /run/systemd/system - runtime units
* /lib/systemd/system - service files after installing a service are usually here.
### Editing Unit Files
* `systemctl edit <unit-file>`
* special override created file
* changes will be merged into the actual file
* to change it - should be made in the specific section in the file, with no hash comment
* `sudo rm /etc/systemd/system/<service>.service.d/override.conf` to remove the changes made
* `sudo systemctl edit --full <service>.service` - use the entire config file as the base
* /etc/systemd/system - safer for making changes since override the changes from lower priority dirs
* `sudo systemctl daemon-reload` - to re-read unit files after editing or creating anything in /etc/systemd/system/
* `jourlanctl -u <service> -f` - live steram logs

