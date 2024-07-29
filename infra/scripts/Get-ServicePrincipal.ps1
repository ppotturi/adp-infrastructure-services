
[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$ServicePrincipalNames
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
Write-Debug "${functionName}:ServicePrincipalNames=$ServicePrincipalNames"

try {

    [array]$servicePrincipalNamesObject = @()

    $ServicePrincipalNames.Split(",") | ForEach-Object {
        $servicePrincipalName = $_.Trim()
        if ($servicePrincipalName) {
            $servicePrincipal = Get-AzADServicePrincipal -DisplayName $servicePrincipalName
            if ($servicePrincipal) {
                $servicePrincipalNamesObject += $servicePrincipal.id
            }
            else {
                throw "Service Principal $($servicePrincipalName) not found"
            }
        }
    }

    Write-Host "##vso[task.setvariable variable=serviceBusEntitiesRbacPrincipalIds;]$($servicePrincipalNamesObject | ConvertTo-Json -AsArray -Compress)"
    Write-Debug "${functionName}:serviceBusEntitiesRbacPrincipalIds=$($servicePrincipalNamesObject | ConvertTo-Json -AsArray -Compress)"

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