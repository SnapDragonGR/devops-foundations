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
# Part 2. Using the Most Common Commands for Parsing.
## Parsing
* `cat <file-name> | grep "smth we're looking for"` - look for a specific word in a file
* add `| cut -d " " -f 11` to the command above to get the specific column of user names who tried to get access to the server in auth.log file
* add `| sort` for alphabetical sorting
* add `| uniq` for getting unique values only, no duplicates
* `wc -l ` - word count (how many lines in the list)
* `grep -v <word>` - dont include a specific word
* `uniq -d` - list of duplicates
## Arch's journalctl parsing
* `journalctl -p <level>` - filet log by priority (emerg, alert, crit, err, warning, notice, info, debug)
* `journalctl -u <unit>` - filter logs from a specific systemd service
* `journalctl --since / -- until` - filter by absolute or relative time ranges (`journalctl --since "1 hour ago"`)
* `journalctl -b` - show logs from the current boot (-b -1 for previous boot)
* `journalctl -o json` - output logs in structured json format for other tools (`journalctl -u sshd -o json`)
## Advanced Field Parsing with `awk`  
`cut` won't work well with variable spacing in logs. `awk` sees multiple whitespaces as one delimiter
### `awk` Mechanics
* Columns: `$1` is column 1, `$2` is column 2, and `$NF` is the very last column
* Printing: `awk '{print $1, $5}'`prints only columns 1 and 5
* Filtering Conditions: `awk '$5 == "ERROR" {print $0}'` only prints lines where column 5 equals "Error"
## Stream Editing with `sed`  
Modifies text as it flows through a pipe (used for stripping sensitive info like passwords or API tokens) or clean up noisy line prefixes before outputting logs
### Basic Substitution Syntax
`sed 's/search_term/replace_term/g`
* `s`: Substitute command
* `g`: Global flag (replace all matches on the line, not just the first)
* `journalctl -b | sed -E 's/192\.168\.[0-9]+\.[0-9]+/XXX.XXX.XXX.XXX/g'` - masks internal ip addresses in a log stream