<#
.SYNOPSIS
Add Service Managed Identity to RBAC group

.DESCRIPTION
Add Service Managed Identity to RBAC group

.PARAMETER ServiceMIList
Mandatory. ServiceMIList

.PARAMETER MIPrefix
Mandatory. Managed Identity Prefix


.EXAMPLE
.\Add-MI-To-RBACGroup -AccessGroupMiList <string> -MIPrefix <string> 
#> 

[CmdletBinding()]
param(
    
    [Parameter(Mandatory)] 
    [string]$AccessGroupMiList,

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
Write-Debug "${functionName}:AccessGroupMiList=$AccessGroupMiList"
Write-Debug "${functionName}:MIPrefix=$MIPrefix"

try {

    $accessGroupMiListObj = ConvertFrom-Json $AccessGroupMiList    
    
    foreach ($accessGroupMiObj in $accessGroupMiListObj) {
        [array]$ServiceMIList = $accessGroupMiObj.miSuffixList -split ','
        $members = @()
        foreach ($serviceMI in $ServiceMIList) {
            $principalName = $MIPrefix + "-" + $serviceMI                
            $miObjectID = (Get-AzADServicePrincipal -DisplayName $principalName).id
            if ($null -eq $miObjectID) {
                Write-Warning "Managed Identity $principalName not found"
            }
            else {
                Write-Output "miObjectID: $miObjectID"                
                $members += $miObjectID
            }
        }   
        $groupid = (Get-AzADGroup -DisplayName $accessGroupMiObj.groupName).id
        Add-AzADGroupMember -TargetGroupObjectId $groupid -MemberObjectId $members
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