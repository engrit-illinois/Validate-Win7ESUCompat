# Documentation home: https://github.com/engrit-illinois/Validate-Win7ESUCompat
# By mseng3

param(
	[string[]]$Hosts,
	[string]$Log=".\Validate-Win7ESUCompat_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
)

# Requirements for Win7 ESU compatibility:
# https://techcommunity.microsoft.com/t5/windows-it-pro-blog/how-to-get-extended-security-updates-for-eligible-windows/ba-p/917807

$compatible = $false

# Servicing stack update
# https://support.microsoft.com/en-us/help/4490628/servicing-stack-update-for-windows-7-sp1-and-windows-server-2008-r2
$KB1 = "KB4490628"

# SHA-2 code signing update
# https://support.microsoft.com/en-us/help/4474419/sha-2-code-signing-support-update
$KB2 = "KB4474419"

# Servicing stack update #2
# https://support.microsoft.com/en-us/help/4516655/compatibility-update-for-installing-windows-7-sp1-and-server-2008-r2
$KB3 = "KB4516655"

# Oldest compatible monthly rollup
# https://support.microsoft.com/en-us/help/4519976/windows-7-update-kb4519976
$MR0 = "KB4519976"

# List of monthly rollups which contain the oldest compatible rollup (as of 2020-01-30)
# Surely there's a better way to figure this out than how I did it by blindly clicking through KB pages

# KB4519976: 2019-10-08
# 	- included by KB4519972: 2019-10-15 preview
#		- included by KB4525235: 2019-11-12
#			- included by KB4525251: 2019-11-19 preview
#				- included by KB4530734: 2019-12-10
#				- included by KB4534310: 2020-01-14

$MRS = @("KB4519976","KB4519972","KB4525235","KB4525251","KB4530734","KB4534310")

function log {
	param(
		[string]$msg,
		[int]$level=0,
		[switch]$nnl,
		[switch]$nots
	)
	for($i = 0; $i -lt $level; $i += 1) {
		$msg = "    $msg"
	}
	$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
	if(!$nots) {
		$msg = "[$ts] $msg"
	}
	
	if($nnl) {
		Write-Host $msg -NoNewLine
	}
	else {
		Write-Host $msg
	}
	
	if($nnl) {
		$msg | Out-File $Log -Append -NoNewLine
	}
	else {
		$msg | Out-File $Log -Append
	}
	
}

function Get-KB($kb, $kbs) {
	log "Checking `"$kb`"..." -level 2 -nnl
	
	$result = "unknown"
	
	$found = $kbs | select HotFixID,Description,InstalledBy,InstalledOn | where { $_.HotFixID -eq $kb }
	
	$foundCount = @($found).count
	
	if($foundCount -eq 0) {
		log " Found 0 matching KBs!" -nots
		$result = $false
	}
	elseif($foundCount -eq 1) {
		log " Found 1 matching KB." -nots
		#$result = $found
		$result = $true
	}
	else {
		log " Found an unexpected number of matching KBs!" -nots
		$result = "error"
	}
	
	$result
}

$data = @()
foreach($thisHost in $Hosts) {
	$newHost = [ordered]@{
		"name" = $thisHost
		"online" = "-"
		"os" = "-"
		"kbs" = "-"
		"kb1" = "-"
		"kb2" = "-"
		"kb3" = "-"
		"mr" = "-"
		"compatible" = "-"
	}
	
	$online = $false
	$os = $false
	$kbs = $false
	
	log "Pulling info for host `"$($newHost.name)`"..."
	
	log "Checking network response..." -level 1

	$online = Test-Connection $newHost.name -Quiet
	if($online) {
		log "Responded." -level 1
		$newHost.online = $true
		
		log "Checking OS..." -level 1
		
		try {
			$os = (Get-WmiObject -Computer $newHost.name -Class Win32_OperatingSystem).Version
		}
		catch {
			$os = $false
			$osMsg = "Unknown error"
			if($_.Exception.Message.Trim() -eq "Access is denied.") {
				$osMsg = "Access denied"
			}
		}
		
		if($os) {
			$newHost.os = $os
			
			# Win7 SP1 = 6.1.7601
			if($newHost.os -eq "6.1.7601") {
				log "Host is Win7 SP1." -level 1
				
				# Get all KBs now, so we don't have to query over the network multiple times
				log "Querying host for list of installed KBs..." -level 1
				$kbs = Get-Hotfix -ComputerName $newHost.name
				if($kbs) {
					$newHost.kbs = $kbs
					log "Done." -level 1
					
					log "Checking existence of KBs..." -level 1
					# Check individual KBs for presence
					$newHost.kb1 = Get-KB $KB1 $kbs
					$newHost.kb2 = Get-KB $KB2 $kbs
					$newHost.kb3 = Get-KB $KB3 $kbs
					
					# Check that at least one of the compatible MRs are present
					foreach($mr in $MRS) {
						$present = Get-KB $mr $kbs
						if($present -eq $true) {
							$newHost.mr = $true
							break
						}
						$newHost.mr = $false
					}
					
					# Check that all necessary KBs are present (all three individuals, and at least one MR)
					$newHost.compatible = $false
					if($newHost.kb1 -and $newHost.kb2 -and $newHost.kb3 -and $newHost.mr) {
						$newHost.compatible = $true
					}
					
					log "Done." -level 1
				}
				else {
					log "Query for KBs returned no result!" -level 1
				}
			}
			else {
				log "Host's OS is not Win7 SP1! (It's `"$($newHost.os)`")" -level 1
			}
		}
		else {
			log "Host's OS is unknown!" -level 1
			$newHost.os = $osMsg
		}
	}
	else {
		log "Did not respond!" -level 1
		$newHost.online = $false
	}
	
	log " " -nots

	$newHost.Remove("kbs")
	$data += $newHost
}

$final = $data | ForEach {[PSCustomObject]$_} | Format-Table -AutoSize
log ($final | Out-String)
#$data | ConvertTo-Json