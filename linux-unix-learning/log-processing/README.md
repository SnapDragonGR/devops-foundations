# Part 1. How to Access and Read Linux Log Files For Information and Troubleshooting
## Accessing Logs
* `/var/log` is where the logs are usually stored
* `last` used to view contents of the wtmp binary log
* `lastb (lastb -adF)` to check bad login attempts of the lastb binary log
* `tail -f /file` - gives last portion of the file and follow immediate changes
* `journalctl -u <name of a unit>` or follow mode `journalctl -fu ssh` - systemd units / services and their logs
* `systemctl start <unit>` - start / stop / enable services
### Fedora:
* `boot.log` - boot log file
* `dnf.log` - history of installed packages
### Ubuntu / Debian-based:
* `auth.log` to see authentication attempts
* `syslog` shows system events (hardware issues)
* `apt/history` - history of installed packages / updates
* `dmesg` or just `sudo dmesg` - similar to sys log, more info on hardware (kernel log file)




