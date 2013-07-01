check-folder
============

This small bash script (not optimized) check a folder for new docs and notify this to the user via notifiy-send.
It works as root and use only notify-send to notify to every user logged in (if non root user is used, it will ask for a password to execute notify-send) for it was conceived as a cron task.
