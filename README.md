check-folder
============

This small bash script (not optimized) check a folder for new docs and notify this to the user via notifiy-send.
It works as root and use only notify-send to notify to every user logged in (if non root user is used, it will ask for a password to execute notify-send) for it was conceived as a cron task.

Usage: check-folder [-ahu]
  Check a folder for new files and notify this to the user via notifiy-send. 
  If ran as root it will notify every user logged in (useful as cron task).
   a  notify even if no new document are found
   h	this help
   u	notify only the user running the script (for root so that other users do not get bored) 
