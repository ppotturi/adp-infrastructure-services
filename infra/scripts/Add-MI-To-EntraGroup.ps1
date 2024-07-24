<#
.SYNOPSIS
Add Service Managed Identity to Entra group

.DESCRIPTION
Add Service Managed Identity to Entra group

.PARAMETER ServiceMIList
Mandatory. ServiceMIList

.PARAMETER MIPrefix
Mandatory. Managed Identity Prefix

.EXAMPLE
.\Add-MI-To-EntraGroup -GroupMIList <string> -MIPrefix <string> 
#> 

[CmdletBinding()]
param(
    
    [Parameter(Mandatory)] 
    [string]$GroupMIList,

    [Parameter(Mandatory)] 
    [string]$MIPrefix
)

Set-StrictMode -Version 3.0

[string]$functionName = $MyInvocation.MyCommand
[datetime]$startTime = [datetime]::UtcNow

[int]$exitCode = -1
[bool]$setHostExitCode = (Test-Path -Path ENV:TF_BUILD) -and ($ENV:TF_BUILD -eq "true")
[bool]$enableDebug = (Test-Path -Path ENV:SYSTEM_DEBUG) -and ($ENV:SYSTEM_DEBUG -eq "true")

Set-Variable -Name ErrorActionPreference -Value Continue -scope global
Set-Variable -Name InformationPreference -Value Continue -Scope global

if ($enableDebug) {
    Set-Variable -Name VerbosePreference -Value Continue -Scope global
    Set-Variable -Name DebugPreference -Value Continue -Scope global
}

Write-Host "${functionName} started at $($startTime.ToString('u'))"
Write-Debug "${functionName}:GroupMIList=$GroupMIList"
Write-Debug "${functionName}:MIPrefix=$MIPrefix"

try {

    $groupMiListObj = ConvertFrom-Json $GroupMIList    
    
    foreach ($groupMiObj in $groupMiListObj) {

        $group = Get-AzADGroup -DisplayName $groupMiObj.groupName -ErrorAction SilentlyContinue
        if ($null -eq $group) {
            Write-Warning "Group $($groupMiObj.groupName) not found"
            continue
        }

        $groupid = $group.id

        [array]$serviceMIList = $groupMiObj.miSuffixList -split ','
        [array]$members = @()
        
        foreach ($serviceMI in $serviceMIList) {
            $principalName = "$MIPrefix-$serviceMI"
            try {
                $miObjectID = (Get-AzADServicePrincipal -DisplayName $principalName).id
                if ($null -eq $miObjectID) {
                    Write-Warning "Managed Identity $principalName not found"
                } else {
                    Write-Debug "Managed Identity $principalName found with id $miObjectID"
                    $members += $miObjectID
                }
            } catch {
                Write-Warning "Error retrieving Managed Identity ${principalName}: $_"
            }
        }

        if ($null -ne $members) {
            Write-Debug "Adding members $($members -join ',') to group $groupid"
            Add-AzADGroupMember -TargetGroupObjectId $groupid -MemberObjectId $members
        }

    }

    $exitCode = 0
}
catch {
    $exitCode = -2
    Write-Error $_.Exception.ToString()
    throw $_.Exception
}
finally {
    [DateTime]$endTime = [DateTime]::UtcNow
    [Timespan]$duration = $endTime.Subtract($startTime)

    Write-Host "${functionName} finished at $($endTime.ToString('u')) (duration $($duration -f 'g')) with exit code $exitCode"
    if ($setHostExitCode) {
        Write-Debug "${functionName}:Setting host exit code"
        $host.SetShouldExit($exitCode)
    }
    exit $exitCode
}