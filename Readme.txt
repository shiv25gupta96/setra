It might be due to various issues.I cant say which one is there in your case.

Below given reasons may be there:
- DCOM is not enabled in host PC or target PC or on both.
- Your Firewall or even your antivirus is preventing the access.
- Any WMI related service is disabled.

Some WMI related services are as given:
- Remote Access Auto Connection Manager
- Remote Access Connection Manager
- Remote Procedure Call (RPC)
- Remote Procedure Call (RPC) Locator
- Remote Registry

For DCOM setting refer:

Key: HKLM\Software\Microsoft\OLE, Value: EnableDCOM
The value should be set to 'Y'

---------------------------------------------------------------------------
I noticed I could run the script from another VM in the same WORKGROUP when I disabled the firewall but still couldn't do it from a machine on the domain. Those two things along with Stackflow suggestions is what brought me to the following solution:

Note: Change these settings at your own risk. You should understand the security implications of these changes before applying them.

On the remote machine:

Make sure you re-enable your Firewall if you've disabled it during testing.
Run Enable-PSRemoting from PowerShell with success
Go into wf.msc (Windows Firewall with Advanced Security)
Confirm the Private/Public inbound 'Windows Management Instrumentation (DCOM-In)' rule is enabled AND make sure the 'Remote Address' property is 'Any' or something more secure.
Confirm the Private/Public inbound 'Windows Management Instrumentation (WMI-In)' rule is enabled AND make sure the 'Remote Address' property is 'Any' or something more secure.
Optional: You may also need to perform the following if you want to run commands like 'Enter-PSSession'.

Confirm the Private/Public inbound 'Windows Management Instrumentation (ASync-In)' rule is enabled AND make sure the 'Remote Address' property is 'Any' or something more secure.
Open up an Inbound TCP port to 5985
IMPORTANT! - It's taking my remote VM about 2 minutes or so after it reboots to respond to the 'Enter-PSSession' command even though other networking services are starting up without problems. Give it a couple minutes and then try.

Side Note: Before I changed the 'Remote Address' property to 'Any', both of the rules were set to 'Local subnet'.