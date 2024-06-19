Role Name
---------
Windows_patch_install

this role connect endpoint servers, try to install patches which are download from wsus server, it perform pre and post check during installation period 

Requirements
------------
WSUS deploy into account

Variables
--------------
### Mondatory Variables
Parameter | Type (Choices) | Default | Comments
----------|----------------|---------|---------
__reboot__ | Boolean |  |  Defines if server require reboot or not 
__wsus_server__ | String |  | WSUS Server http://FQDN:8530 or http://IP:8530

=======
# Key Solutions...
 *  It troubleshoot wsus server and client communication issues, enable the require services if its disabled ( windows update, bits )
 * It does checking C drive space , if free space falls under 5GB , playbook will skip the hosts
 * This Playbook has to met one important criteria before stopping production service and calls for restart 
    * Reboot:yes has to be defined ( if Reboot:no then it won't stop any service)
 * The same play book can be used if server need not be restarted and patches should be applied, In this case, just run job twice
 
       1. first time it will install the patches with reboot=no and 
       2. second time run same job with "reboot=yes "extra variable, this will call prechecks ,reboot and post checks
       
*  It takes services snapshot before restart and compare same snapshot with newly created snapshot after restart then start the service if     its stopped (compares only with automatic service)
* It reports system UP time, services status 





Author
---------
ramesh2azure@gmail.com
