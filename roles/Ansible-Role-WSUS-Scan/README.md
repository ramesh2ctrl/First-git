# Synopsis

This role (patch scanner) is designed to detect patch status reports on WSUS target group servers. This role generates a zip file which includes each server report in csv file and uploads it to the SFS server.

# Variables

Parameter        | Default | Comments
-----------------|---------|---------------
api_auth_by | password | Authentication SFS and Tower data. Provide password (or) token.
installationstates	| 'NotInstalled, Installed, NotApplicable' | WSUS Scan patch status. SME has to provide any of example 'NotInstalled, Installed, NotApplicable' (or) 'NotInstalled, Installed'(or)'NotInstalled, Installed, NotApplicableDownloaded, Failed, InstalledPendingReboot'.
resultfolder |	"C:\\\temp\\\Reports" | The folder C:\temp\Reports - must exist on WSUS server. Note: Delete the csv files in folder before the execution. And this role uses ansible modules, so the input must have a double backslash.
results_dir_base |	/data/targets/secscan/win_scan | The tower path where data is stored. SME must set the path according to the environment. Tower path can be provided by the Tower Admin. Example - /data/targets/secscan/win_scan
resultziplocation |	"C:\\\temp\\\report.zip" |	The folder - C:\temp - must exist on WSUS server. Note: This role uses ansible modules, so the input must have a double backslash.
upload_results |	- | SME must specify 'true' or 'false' for SFS upload.
upload_url |	- | (if upload_results: 'true') SME must specify SFS url for SFS Upload. Example - https://ibmtansible7a1.test.de.sni.ibm.com:9443/files.
wsusport |	8530 | WSUS server port number. Note: If the WSUS server supports secure connection, use the port number 8531.
wsusserver | [Hostname of WSUS Server] |	If WSUS server supports secure connection, SME must specify [Hostname of WSUS Server].  In case of non secure connection, SME must use [localhost].
secureconnection | True | Use this variable only if WSUS server supports secure connection.
wsustargetgroup |	[Group in WSUS] | WSUS server targetgroup name. All Computers (or) [Group in WSUS].
changeid | 123456 | SME can provide a ticket change number.


# Results from execution

Return Code Group        | Return Code | Comments
-------------------------|-------------|------------
misconfiguration         | 301 | Missing Ansible Tower credentials in Job template. Modify your Job template and add Ansible Tower credentials.
misconfiguration         | 201 | Mandatory input variables are missing for WSUS scan run. Refer to `Variables` and check the error message to determine which variable has incorrect format or is missing. Check for - `wsusserver`, `wsustargetgroup`, `resultfolder`, `resultziplocation`, `installationstates` parameters.
service_issue            | 202 | Scan report for WSUS output has errors. Refer to error log and verify the exact error. Check if `wsusserver`, `wsustargetgroup` are provided in tower template correctly.
service_issue            | 203 | Secure scan report for WSUS output has errors. Refer to error log and verify exact error. Check if `wsusserver`, `wsustargetgroup` are provided in tower template correctly.
misconfiguration         | 204 | Fetch command failed to copy the scan result file from endpoint to Tower. Check the WSUS scan results file under the `resultziplocation` section on the endpoint. Refer to error log file for more details.
misconfiguration         | 101 | For SFS preparation, the getting current inventory from Tower failed. Tower credentials in the Job template can be incorrect. Check if there is correct Ansible Tower hostname value and login values. Other common problem is insufficient Tower user permissions. Problem: in configuration of credentials for access AT API -> corrective action is that the account must check those credentials or AT API is not accessible -> corrective action is to open incident ticket to HST team (team which manages Ansible Tower infrastructure).
misconfiguration         | 102 | For SFS preparation, the getting template details from Tower failed. Problem: in configuration of credentials for access AT API -> corrective action is that the account must check those credentials or AT API is not accessible -> corrective action is to open incident ticket to HST team (team which manages Ansible Tower infrastructure).
misconfiguration         | 103 | For SFS preparation, the creation of temporary folder on Tower failed. Corrective action is to open incident ticket to HST team (team which manages Ansible Tower infrastructure).
component_playbook       | 104 | The error of the data upload. Directory not defined. Error while displaying temporary folder stats. Corrective action is to open incident ticket to HST team (team which manages Ansible Tower infrastructure).
component_playbook       | 105 | Error while the Report Zip folder rename task. Corrective action is to open incident ticket to HST team (team which manages Ansible Tower infrastructure).
component_playbook       | 106 | The upload of compressed data from Tower to SFS failed. Error while compressing data on Tower. Corrective action is to open incident ticket to HST team (team which manages Ansible Tower infrastructure).


# Procedure

This role copy the powershell script (wsus_scan.ps1) to the WSUS server.
When the scan is complete, each server will create csv files. These files are in format - (endpoint-hostname).csv and are located in the "resultfolder", which is given as script variable. All zipped csv files on each server are stored in the "resultziplocation" location, which is also given as script variable.

## Patch Reports

CSV file format:

The columns contains the identifiers for structure being presented in csv file. The scan outputs the information to a csv file.
Figure 1-0 shows an example of how this output format looks:

Status         | Description
---------------|------------------------------
"*"            | Means that there are multiple advisory available under the patch update and the patch needs to be installed.
"I"            | The advisory/patch is already installed.
"NA"           | The advisory/patch is Not Applicable to Server.

  * Device - computer name of the endpoint.
  * FixNumber - Microsoft KB number.
  * InstallDate - The date is wsus client's report time to wsus server which is always recent as client keep update information to wsus server within short interval.
  * Title - Description of patch advisory.

Figure 1-0 scanner view CSV File Output Example
![report](https://github.Ramesh Technologies.net/Continuous-Engineering/ansible_collection_patching_windows_wsus/blob/master/roles/Ansible-Role-WSUS-Scan/tests/result.jpg)

# Deployment

**Tower Job Template and Project settings:**

Note: settings are example purpose, user change values according to client environments

Settings Name   | Possible Values| Mandatory | Comments
-----------------|-----------------|--------|---------------
Name| tricodeofclient_project_patchscan_wsus| Yes| This represents the Project name on Ansible Tower. Create project on AT.
Organization| Configured Organization name| Yes| Select your organization name in AT.
SCM Type| Git | Yes| Select Git as it uses the github.
SCM URL| https://github.Ramesh Technologies.net/Continuous-Engineering/ansible_collection_patching_windows_wsus.git| Yes| Provide link to the WSUS scan repository from github.
Name | tricodeofclient_jobtemplate_patchscan_wsus |Yes| AT Job template name (user can give any job name for their choices).
JobType|Run|Yes| Select Run under job type.
Inventory| WSUS server should be part of Inventory|Yes| Provide the correct Inventory according to your environment.
Project| tricodeofclient_project_patchscan_wsus |Yes| Project name format has to follow in order to SFS file upload to work.
Playbook|scan_for_patches_wsus.yaml|Yes| Playbook name which need to be executed.
Credentials| Tower Credentials, WSUS endpoint Credentials, jump host Credentials|Yes| Credentials for Job template.
Limit|WSUS server endpoint name,localhost|Yes| Job has to run only WSUS endpoint,Tower server hence we limit job to run on WSUS endpoint,Tower server (example wsus1,localhost if wsus1 is wsusservername).
Extra Variables| specified values in Variables section has to pass | Yes| Provide mandatory variable as listed under `Variable` section.
Verbosity| 0 (Normal) | Yes| Job run Verbosity level.

# Support

 * This is a CACM managed solution, please raise any requests or issues at: [COMMON REPOSITORY](https://github.Ramesh Technologies.net/Continuous-Engineering/CACM_Common_Repository/issues)
 * For General Queries/Playbook help implementation you could try the bluemix portal: [#continuous-engineering](https://continuous-engineering.eu-de.mybluemix.net/cacm)
 * Author Information: Ravi Kumar Puneti, Laszlo Papp and Ponit Kaur

# Known problems and limitations

  * Windows 2008 and higher (minimum windows O\S version for Ansible).
  * Script only run on WSUS server.
  * WSUS server powershell version higher than 5 (Compress-Archive command available from powershell 5.0).

# Prerequisites

  * Standard Ansible prerequisites (winrm on target machine) on WSUS server.
  * In order for this Socks Tunnel to work, JumpHost Credential Types, Credentials and specific variables need to be setup in Inventory Groups.
  * Ansible Tower user(s) with the role of at least a System Auditor to be used in the credentials of the type of Ansible Tower to be passed to the template. There can be one user for the whole tower or one user for each organization or several organization in the tower.
  * Direct access to the Windows Update service.
  * Pass All Parameters in tower job template.

# Examples

**Example parameters: (Normal WSUS connection)**

* api_auth_by: password
* installationstates: 'NotInstalled, Installed, NotApplicable'
* resultfolder: 'C:\\\temp\\\Reports'
* results_dir_base: /data/targets/secscan/win_scan
* resultziplocation: 'C:\\\temp\\\report.zip'
* upload_results: 'true'
* upload_url: 'https://ibmtansible7a1.test.de.sni.ibm.com:9443/files'
* wsusport: 8530
* wsusserver: localhost
* wsustargetgroup: All Computers
* changeid: 123456

**Example parameters: (Secure WSUS connection)**

* api_auth_by: password
* installationstates: 'NotInstalled, Installed, NotApplicable'
* resultfolder: 'C:\\\temp\\\Reports'
* results_dir_base: /data/targets/secscan/win_scan
* resultziplocation: 'C:\\\temp\\\report.zip'
* upload_results: 'true'
* upload_url: 'https://ibmtansible7a1.test.de.sni.ibm.com:9443/files'
* wsusport: 8531
* wsusserver: wsus1.domain.com
* secureconnection: True
* wsustargetgroup: All Computers
* changeid: 123456

# License
[Ramesh Technologies Intellectual Property](https://github.Ramesh Technologies.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)
