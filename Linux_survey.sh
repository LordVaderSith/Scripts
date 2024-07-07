echo "Starting Script"
date > /tmp/script_output
w >> /tmp/script_output
uname -a >> /tmp/script_output
ps -ef >> /tmp/script_output
netstat -anop >> /tmp/script_output
arp -a >> /tmp/script_output
systemctl status --all >> /tmp/script_output
service --status-all >> /tmp/script_output
ls -la / >> /tmp/script_output
ls -la /var/log >> /tmp/script_output
ls -la /root >> /tmp/script_output
ls -la /home >> /tmp/script_output
ls -la /home/* >> /tmp/script_output
for i in `ls /home`; do  echo "===========================" >> /tmp/script_output; echo $i >> /tmp/script_output; echo "===========================" >> /tmp/script_output; cat /home/$i/.bash_history >> /tmp/script_output; done
echo "===========================" >> /tmp/script_output; echo "root" >> /tmp/script_output; echo "===========================" >> /tmp/script_output; cat /root/.bash_history >> /tmp/script_output
echo "Script Finish"
rm -- "$0"
