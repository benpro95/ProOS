# Main root cron timer file.
# for Files VM
# Feel free to adapt it to your needs.
# by Ben Provenzano III
################################################
# Activation Time ##### User ###### Command ####

@hourly       root   /usr/bin/sudo -u ben /usr/bin/savebookmarks
0 11 1 * *    root   /usr/bin/sudo -u ben /usr/bin/camcleanup
