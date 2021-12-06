<#
.SYNOPSIS
Parse-FortiGateRules parses rules from a FortiGate device into a CSV file.
.DESCRIPTION
The Parse-FortiGateRules reads a FortiGate config file and pulls out the rules for each VDOM in the file into a CSV.
.PARAMETER fortigateConfig
[REQUIRED] This is the path to the FortiGate config file
.PARAMETER utf8
[OPTIONAL] This is a switch to parse a config in UTF8 formatting. Optional.
.EXAMPLE
.\Parse-FortiGateRules.ps1 -fortiGateConfig "c:\temp\config.conf"
Parses a FortiGate config file and places the CSV file in the same folder where the config was found.
.NOTES
Author: Drew Hjelm (@drewhjelm)
Last Modified: 01/13/19
#>
Param
(
    [Parameter(Mandatory = $true)]
    [string]$fortigateConfig,
    [switch]$utf8
)

#need some empty items to load config
$includeColumns = "id","name","srcintf","srcaddr","dstintf","dstaddr","service","nat","action","schedule","status","utm-status","ssl-ssh-profile","av-profile","webfilter-profile","application-list","logtraffic","groups"
$loadedConfig;
$workingFolder;
$fileName;

$fileCount = 0;

#checking for fortinet config
if ([System.IO.File]::Exists($fortigateConfig) -eq $false) {
    Write-Output "[!] ERROR: Could not find FortiGate config file at $fortigateConfig."
    exit
}
else {

    if($utf8)
    {
        $loadedConfig = Get-Content $fortigateConfig -Encoding UTF8;
    }
    else {
        $loadedConfig = Get-Content $fortigateConfig;
    }
    $workingFolder = Split-Path $fortigateConfig;
    $fileName = Split-Path $fortigateConfig -Leaf;
}


#initialize an empty item and object array to be used in the loop below
$ruleList = New-Object System.Collections.ArrayList;
$rule;
$policySection = $false;
$vdomConfig = $false;
$vdom;

$modifiedConfig = $loadedConfig;


foreach ($line in $modifiedConfig) {
    #look for the firewall policy section of the config
    if ($line.Trim() -eq "config firewall policy") {
        $policySection = $true;
        continue;
    }
    #look for vdom config
    if ($line.Trim() -match "^config vdom") {
        $vdomConfig = $true;
        continue;
    } 
    #look for vdom name
    if (($line.Trim() -match "^edit") -and ($vdomConfig)) {
        $lineSplit = $line.Trim().Split();
        $vdom = $lineSplit[1];
        $vdomConfig = $false;
        continue;
    }
    #look for the beginning of a firewall rule and create a new rule with an ID of the rule ID
    if (($line.Trim() -match "^edit ") -and ($policySection)) {
        $rule = New-Object System.Object;
        $lineSplit = $line.Trim().Split();
        $rule | Add-Member -MemberType NoteProperty -Name "id" -Value $lineSplit[1];
    }
    #pull the rule property and add that to the rule
    elseif (($line.Trim() -match "^set ") -and ($policySection)) {
        $lineSplit = $line.Trim().Split();
        $value = "$($lineSplit | Select-Object -Skip 2)"
        $rule | Add-Member -MemberType NoteProperty -Name $lineSplit[1] -Value $value;
    }
    #when the rule end is found, add the rule to the list
    elseif (($line.Trim() -match "^next") -and ($policySection)) {
        $ruleList.Add($rule);
    }
    #write all the rules to the CSV for a VDOM and get ready for the next VDOM
    if (($line.Trim() -match "^end") -and ($policySection)) {
        $policySection = $false;
        $date = Get-Date -Format yyyyMMddhhmmss
        
        $ruleList = $ruleList | Select-Object -Skip 1
        if($utf8)
        {
            $ruleList | Select-Object $includeColumns | Export-Csv -Encoding UTF8 "$workingFolder\rules-$fileName-$vdom-$date-$fileCount.csv" -NoTypeInformation;
        }
        else {
            $ruleList | Select-Object $includeColumns | Export-Csv "$workingFolder\rules-$fileName-$vdom-$date-$fileCount.csv" -NoTypeInformation;
        }
        
        $fileCount++;
        $vdom = $null;
        $ruleList = New-Object System.Collections.ArrayList;
    }
}
