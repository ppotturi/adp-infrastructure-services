<#
.SYNOPSIS
Assign RBAC to a KeyVault Secret

.DESCRIPTION
Assign RBAC to a KeyVault Secret

.PARAMETER ServiceName
Mandatory. ServiceName

.PARAMETER KeyvaultName
Mandatory. KeyvaultName

.PARAMETER MIPrefix
Mandatory. Managed Identity Prefix


.EXAMPLE
.\Set-KVSecret-RBAC -ServiceName <string> -KeyvaultName <string> -MIPrefix <string> 
#> 

[CmdletBinding()]
param(

    
    [Parameter(Mandatory)] 
    [string]$ServiceName,
    
    [Parameter(Mandatory)] 
    [string]$KeyvaultName,

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
Write-Debug "${functionName}:ServiceName=$ServiceName"
Write-Debug "${functionName}:KeyvaultName=$KeyvaultName"
Write-Debug "${functionName}:MIPrefix=$MIPrefix"

try {

    $keyvaultResourceID = (Get-AzKeyVault -VaultName $KeyvaultName).ResourceId
    $roleName = "Key Vault Secrets User"
    $principalName = $MIPrefix + "-" + $ServiceName
    $miObjectID = (Get-AzADServicePrincipal -DisplayName $principalName).id
    $clientIDResourceID = $keyvaultResourceID + "/secrets/" + $ServiceName + "-ClientId"
    $clientSecretResourceID = $keyvaultResourceID + "/secrets/" + $ServiceName + "-ClientSecret"
    $currentRoleForClientID = Get-AzRoleAssignment -ObjectId $miObjectID  -Scope $clientIDResourceID
    if (!$currentRoleForClientID -or $currentRoleForClientID.RoleDefinitionName -ne $roleName) {
        New-AzRoleAssignment -RoleDefinitionName $roleName -ObjectId $miObjectID  -Scope $clientIDResourceID
        Write-Output "Role assigned to Client ID"
    }
    else {
        Write-Output "Role already assigned to Client ID"
    }
    $currentRoleForClientSecret = Get-AzRoleAssignment -ObjectId $miObjectID  -Scope $clientSecretResourceID
    if (!$currentRoleForClientSecret -or $currentRoleForClientSecret.RoleDefinitionName -ne $roleName) {
        New-AzRoleAssignment -RoleDefinitionName $roleName -ObjectId $miObjectID  -Scope $clientSecretResourceID
        Write-Output "Role assigned to Client Secret"
    }
    else {
        Write-Output "Role already assigned to Client Secret"
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