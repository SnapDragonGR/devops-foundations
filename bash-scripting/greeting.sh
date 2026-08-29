#!/bin/bash
set -euo pipefail

name="Gleb Razumnyi"
role="DevOps Engineer"
sys_label="Debian VM"

date=$(date)
current_user=$USER
work_dir=$PWD

echo "*--- --- --- ---*"
echo ""
echo "Greetings, $name!"
echo "You are a $role, and this machine is $sys_label."
echo ""
echo "*--- --- --- ---*"
echo ""
echo "The current time and date is $date."
echo "The logged in user is $current_user."
echo "The current working directory is $work_dir."
echo "Enjoy your work session!"
echo ""
echo "*--- --- --- ---*"
echo ""
