<#
.SYNOPSIS
Get Application Gateway Public IP and pass it to application domain bicep template.

.DESCRIPTION
Get Application Gateway Public IP and set a variable with values which is then used by application domain bicep template.

.PARAMETER ResourceGroupName
Mandatory. Resource Group Name.
.PARAMETER AppGatewayName
Mandatory. Application Gateway Name.

.EXAMPLE
.\Get-AppGatewayFrontendPublicIP.ps1 -ResourceGroupName <ResourceGroupName> -AppGatewayName <AppGatewayName>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string] $ResourceGroupName,
    [Parameter(Mandatory)]
    [string] $AppGatewayName
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
Write-Debug "${functionName}:ResourceGroupName=$ResourceGroupName"
Write-Debug "${functionName}:AppGatewayName=$AppGatewayName"

try {

    $appGateway = Get-AzApplicationGateway -Name $AppGatewayName -ResourceGroupName $ResourceGroupName   

    if($appGateway){
        $gatewayFrontEndIPs= Get-AzApplicationGatewayFrontendIPConfig -ApplicationGateway $appGateway
        foreach($IpObj in $gatewayFrontEndIPs){
            if($IpObj.PrivateIPAddress){
                Write-Host "PrivateIPAddress: " $IpObj.PrivateIPAddress
            }else{
                $publicIpResource = Get-AzResource -ResourceId $IpObj.PublicIPAddress.Id
                $publicIP = Get-AzPublicIpAddress -ResourceGroupName $publicIpResource.ResourceGroupName -Name $publicIpResource.Name
                $publicIpAddress = $publicIP.IpAddress
                Write-Host "##vso[task.setvariable variable=AppGatewayPublicIP]$publicIpAddress"
                Write-Host "PublicIPAddress: "$publicIpAddress
            }
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