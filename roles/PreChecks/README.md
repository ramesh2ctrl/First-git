# Synopsis

To perform all configuration for endpoint form WSUS. This role has dependency on the main role "Ansible-Role-WSUS-Scan". Input to this role is taken from the output of the "Ansible-Role-WSUS-Scan" role

# Variables

 This role has dependency on the main role "Ansible-Role-WSUS-Scan".

# Results from execution

 This role has dependency on the main role "Ansible-Role-WSUS-Scan".
 
# Procedure

 This role has dependency on the main role "Ansible-Role-WSUS-Scan". It connects to the endpoint servers, tries to install patches which are downloaded from wsus server, Also performs pre and post check during installation period
 
# Support

 * This is a CACM managed solution, please raise any requests or issues at: [COMMON REPOSITORY](https://github.Ramesh Technologies.net/Continuous-Engineering/CACM_Common_Repository/issues)
 * For General Queries/Playbook help implementation you could try the bluemix portal: [#continuous-engineering](https://continuous-engineering.eu-de.mybluemix.net/cacm)
 * Author Information: Ravi Kumar Puneti, Laszlo Papp and Kundan Singh

# Deployment

In term to execute the playbook from ansible tower there is a requirement to connect Socks-tunnel . There is a requirement.yml through which socks tunnel is working and executing the playbook.

# Known problems and limitations

  * Windows 2008 and higher (minimum windows O\S version for Ansible).
  * Script only run on WSUS server.
  * WSUS server powershell version higher than 5 (Compress-Archive command available from powershell 5.0).

# Prerequisites

Below is the Requirement detail:

a) Add registry entries to endpoints to configure automatic updates settings 
b) Add entries to local hosts file 
c) Import/Install Certificate to Trusted Root Store using Powershell 
d) Create Inbound and Outbound Rule. 
e) Trigger Windows Update for detecting new updates


# Examples

Including an example of how to use your role:

    - hosts: Endpoints
      roles:
         - { Consolidated }

# License
[Ramesh Technologies Intellectual Property](https://github.Ramesh Technologies.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)
