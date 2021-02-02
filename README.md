# Summary
This script takes an array of computer names and polls each one to find out if it has all of the KB patches installed which are pre-requisites for compatibility with Windows 7 extended security updates (ESUs).  

# Pre-requsites and logic
These pre-reqs are documented here:  
https://techcommunity.microsoft.com/t5/windows-it-pro-blog/how-to-get-extended-security-updates-for-eligible-windows/ba-p/917807  

The logic for which KBs are required is documented in the script comments. It should be noted that one of the KBs is a monthly rollup (from 2019-10-08).  
If a computer has a newer monthly rollup installed, the 2019-10-08 rollup KB will not be present on the machine, but it should still be compatible, since rollups are cumulative in nature.  
As of this script's creation (2020-01-30), I've coded the script to check for all rollups which I found to succeed the required rollup.  
That rollup chain is also documented in the script, but I couldn't find a way to programatically identify a given rollup's "decendants", so more may need to be added if this script is used in the future.  
The best way I found to identify descendant rollups was simply to browse the rollups listed on the left side of [this page](https://support.microsoft.com/en-us/help/4519976/windows-7-update-kb4519976) and manually confirm which newer rollups contain which older ones.  
If more need to be added, they can simply be added as a new string to the $MRS array, near the top of the script.  

# Behavior
The script ignores non Win7 SP1 machines (i.e. v6.1.7601).  
The script gracefully (more or less) handles machines which do not respond over the network, and which return access denied or other errors when polling for the OS version.

# Output
The script generates step-by-step output to the console while polling each computer and outputs a table of results for all computers at the end.  
Ultimately, you're interested in the true/false "compatible" column.  
All output is duplicated in a log file generated (unique-per-run) in the current working directory when running the script.  

# Usage
- Download the PS1 file
- Open a Powershell prompt running as a user with sufficient permssions to the remote machines
- Run the script: e.g.:
    - `.\Validate-Win7ESUCompat.ps1 -Hosts "computername1"`
    - `.\Validate-Win7ESUCompat.ps1 -Hosts "computername1","computername2"`

# Parameters

## -Hosts
An array of strings, representing hostnames

## -Log
Optional. Path to log file. Defaults to `.\Validate-Win7ESUCompat_<date-and-time>.log`.

# Example output
```
mseng3@ENGRIT-MSENG3 C:\>.\Validate-Win7ESUCompat.ps1 -Hosts "TL-201-10","KH-218-02","ESB-6105-TEST","ESB-5101-01","bogusname"
[2020-01-30 16:43:20] Pulling info for host "TL-201-10"...
[2020-01-30 16:43:20]     Checking network response...
[2020-01-30 16:43:23]     Responded.
[2020-01-30 16:43:23]     Checking OS...
[2020-01-30 16:43:23]     Host is Win7 SP1.
[2020-01-30 16:43:23]     Querying host for list of installed KBs...
[2020-01-30 16:43:26]     Done.
[2020-01-30 16:43:26]     Checking existence of KBs...
[2020-01-30 16:43:26]         Checking "KB4490628"... Found 1 matching KB.
[2020-01-30 16:43:26]         Checking "KB4474419"... Found 1 matching KB.
[2020-01-30 16:43:27]         Checking "KB4516655"... Found 1 matching KB.
[2020-01-30 16:43:27]         Checking "KB4519976"... Found 0 matching KBs!
[2020-01-30 16:43:27]         Checking "KB4519972"... Found 0 matching KBs!
[2020-01-30 16:43:27]         Checking "KB4525235"... Found 0 matching KBs!
[2020-01-30 16:43:27]         Checking "KB4525251"... Found 0 matching KBs!
[2020-01-30 16:43:27]         Checking "KB4530734"... Found 0 matching KBs!
[2020-01-30 16:43:28]         Checking "KB4534310"... Found 1 matching KB.
[2020-01-30 16:43:28]     Done.

[2020-01-30 16:43:28] Pulling info for host "KH-218-02"...
[2020-01-30 16:43:28]     Checking network response...
[2020-01-30 16:43:31]     Responded.
[2020-01-30 16:43:31]     Checking OS...
[2020-01-30 16:43:31]     Host is Win7 SP1.
[2020-01-30 16:43:31]     Querying host for list of installed KBs...
[2020-01-30 16:43:35]     Done.
[2020-01-30 16:43:35]     Checking existence of KBs...
[2020-01-30 16:43:35]         Checking "KB4490628"... Found 1 matching KB.
[2020-01-30 16:43:35]         Checking "KB4474419"... Found 1 matching KB.
[2020-01-30 16:43:35]         Checking "KB4516655"... Found 0 matching KBs!
[2020-01-30 16:43:35]         Checking "KB4519976"... Found 0 matching KBs!
[2020-01-30 16:43:36]         Checking "KB4519972"... Found 0 matching KBs!
[2020-01-30 16:43:36]         Checking "KB4525235"... Found 0 matching KBs!
[2020-01-30 16:43:36]         Checking "KB4525251"... Found 0 matching KBs!
[2020-01-30 16:43:36]         Checking "KB4530734"... Found 0 matching KBs!
[2020-01-30 16:43:36]         Checking "KB4534310"... Found 1 matching KB.
[2020-01-30 16:43:36]     Done.

[2020-01-30 16:43:36] Pulling info for host "ESB-6105-TEST"...
[2020-01-30 16:43:36]     Checking network response...
[2020-01-30 16:43:39]     Responded.
[2020-01-30 16:43:39]     Checking OS...
[2020-01-30 16:43:40]     Host's OS is not Win7 SP1! (It's "10.0.18362")

[2020-01-30 16:43:40] Pulling info for host "ESB-5101-01"...
[2020-01-30 16:43:40]     Checking network response...
[2020-01-30 16:43:43]     Responded.
[2020-01-30 16:43:43]     Checking OS...
[2020-01-30 16:43:43]     Host's OS is unknown!

[2020-01-30 16:43:43] Pulling info for host "bogusname"...
[2020-01-30 16:43:43]     Checking network response...
[2020-01-30 16:43:55]     Did not respond!

[2020-01-30 16:43:55]
name          online os             kb1  kb2   kb3   mr compatible
----          ------ --             ---  ---   ---   -- ----------
TL-201-10       True 6.1.7601      True True  True True       True
KH-218-02       True 6.1.7601      True True False True      False
ESB-6105-TEST   True 10.0.18362       -    -     -    -          -
ESB-5101-01     True Access denied    -    -     -    -          -
bogusname      False -                -    -     -    -          -

mseng3@ENGRIT-MSENG3 C:\>
```

# Notes
- You can easily grab a list of computer names from a given AD OU with the following command syntax:
    - `Get-ADComputer -SearchBase "OU=ECEB 3016,OU=ECE,OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu" -Filter "*" | Select Name`
- You can easily grab a list of computer names from a given SCCM collection with the following command syntax (in a Powershell prompt opened from the SCCM console app's top left dropdown):
    - `Get-CMCollectionMember -CollectionName "UIUC-ENGR-EWS Windows 7" | select Name`
- The lists can be munged into an array format with your favorite text editor.
- I'm not entirely sure what remote permissions are sufficient for this script, but localadmin should work.
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.
