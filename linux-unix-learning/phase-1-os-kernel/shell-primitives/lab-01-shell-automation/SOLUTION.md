# Lab 00: Shell Primitives & Administrative Automation

**Host Machine:** Debian 13 VM  
**Repository:** `devops-foundations`  
**Section:** Shell Primitives & Automation  

---

## 🎯 Lab Objectives
1. Inspect and execute shell scripts using variable expansion, conditional checks, and sourcing (`. /etc/os-release`).
2. Redirect combined output (`&>>`) into log files.
3. Validate privilege checks (`$EUID`) and non-interactive job scheduling via `at` or `cron`.

---

## Task 1: Script Execution & Combined Redirection

### 1. Execute Health Script
Run the generated health logging script twice:
```bash
/tmp/system_health.sh
/tmp/system_health.sh
```

### 2. Inspect the Log Output
View the appended combined output stored in `/tmp/devops_logs/health.log`:
```bash
cat /tmp/devops_logs/health.log
```

* **Terminal Output:**
```text
[Sat Oct  3 04:04:46 AM EDT 2026] Running on Debian GNU/Linux (13)
[Sat Oct  3 04:04:46 AM EDT 2026] Disk Usage: 39%
[Sat Oct  3 04:04:47 AM EDT 2026] Running on Debian GNU/Linux (13)
[Sat Oct  3 04:04:47 AM EDT 2026] Disk Usage: 39%
```

---

## Task 2: Privilege Inspection & Scheduling

### 1. Root Execution Check (`$EUID`)
Explain how a script checks for root privileges non-interactively:
```bash
if [ "$EUID" -ne 0 ]; then
    echo "Error: Must be run as root." >&2
    exit 1
fi
```

"$EUID" is 0 for root users. If not 0, then not root.

### 2. One-off Job Scheduling (`at`)
Schedule the script to run 1 minute from now using the `at` command:
```bash
echo "/tmp/system_health.sh" | at now + 1 minute
```

Verify the job is queued:
```bash
atq
```

* **`atq` Output:**
```text
6       Sat Oct  3 04:09:00 2026 a gleb
```

---

## Task 3: Cleanup

Remove the temporary lab files from the system:
```bash
rm -rf /tmp/devops_logs /tmp/system_health.sh setup_lab.sh
```

---

## 📌 Key Takeaways
* Sourcing files (`. /etc/os-release`) loads environment variables directly into the current execution shell without spawning a child process.
* Using `&>>` appends both Standard Output (stdout, FD 1) and Standard Error (stderr, FD 2) to a target log file.
* Checking `$EUID -ne 0` prevents partial script execution failures caused by missing root privileges during automated runs.