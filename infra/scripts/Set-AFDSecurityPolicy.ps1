<#
.SYNOPSIS
Add or Update FrontDoor Security Policy

.DESCRIPTION
Creates a Security Policy if it doesn't exists and add's Custom Domain to the Security Policy

.PARAMETER AfdName
Mandatory. Azure FrontDoor Instance Name
.PARAMETER PolicyName
Mandatory. Security Policy Name
.PARAMETER WafPolicyName
Mandatory. Azure WAF Policy Instance Name
.PARAMETER ResourceGroupName
Mandatory. Resource Group Name
.PARAMETER CustomDomainName
Mandatory. Custom Domain Name to be added to the Security Policy
.PARAMETER SubscriptionId
Mandatory. Azure Subscription Id

.EXAMPLE
.\Set-AFDSecurityPolicy -AfdName <string> -PolicyName <string> -WafPolicyName <string> -ResourceGroupName <string> -CustomDomainName <string> -SubscriptionId <string>
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$AfdName,

    [Parameter()] 
    [string]$PolicyName,
    
    [Parameter(Mandatory)] 
    [string]$WafPolicyName,
    
    [Parameter(Mandatory)] 
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory)] 
    [string]$CustomDomainName,
    
    [Parameter(Mandatory)] 
    [string]$SubscriptionId
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
Write-Debug "${functionName}:AfdName=$AfdName"
Write-Debug "${functionName}:PolicyName=$PolicyName"
Write-Debug "${functionName}:WafPolicyName=$WafPolicyName"
Write-Debug "${functionName}:ResourceGroupName=$ResourceGroupName"
Write-Debug "${functionName}:CustomDomainName=$CustomDomainName"
Write-Debug "${functionName}:SubscriptionId=$SubscriptionId"

try {

    $wafPolicy = Get-AzFrontDoorWafPolicy -ResourceGroupName $ResourceGroupName -Name $WafPolicyName
    $customDomain = Get-AzFrontDoorCdnCustomDomain -ProfileName $AfdName -ResourceGroupName $ResourceGroupName -CustomDomainName $CustomDomainName

    $securityPolicies = Get-AzFrontDoorCdnSecurityPolicy -ResourceGroupName $ResourceGroupName -ProfileName $AfdName -SubscriptionId $SubscriptionId
    $securityPolicy = $securityPolicies | Where-Object { $_.Name -eq $PolicyName }

    if ($securityPolicy) {
        $exists = $false
        $domains = @()
        foreach ($item in $securityPolicy.Parameter.Association[0].Domain) {
            if ($item.Id -eq $customDomain.Id) {
                $exists = $true
            }
            else {
                $domains += @{"Id" = $($item.Id) }
            }
        }
        if (-not $exists) {
            Write-Output "Adding domain '$CustomDomainName' to the Security Policy '$PolicyName'."

            $domains += @{"Id" = $($customDomain.Id) }
            $association = New-AzFrontDoorCdnSecurityPolicyWebApplicationFirewallAssociationObject -PatternsToMatch $securityPolicy.Parameter.Association[0].PatternsToMatch -Domain $domains
            $wafParameter = New-AzFrontDoorCdnSecurityPolicyWebApplicationFirewallParametersObject -Association @($association) -WafPolicyId $securityPolicy.Parameter.WafPolicyId

            Update-AzFrontDoorCdnSecurityPolicy -ResourceGroupName $ResourceGroupName -ProfileName $AfdName -Name $PolicyName -Parameter $wafParameter
        }
        else {
            Write-Output "Domain '$CustomDomainName' is already associated to a security policy '$PolicyName'."
        }
    }
    else {
        Write-Output "Creating new Security Policy '$PolicyName' and adding domain '$CustomDomainName'..."

        $association = New-AzFrontDoorCdnSecurityPolicyWebApplicationFirewallAssociationObject -PatternsToMatch @("/*") -Domain @(@{"Id" = $($customDomain.Id) })
        $wafParameter = New-AzFrontDoorCdnSecurityPolicyWebApplicationFirewallParametersObject -Association @($association) -WafPolicyId $wafPolicy.Id
        New-AzFrontDoorCdnSecurityPolicy -Name $PolicyName -ProfileName $AfdName -ResourceGroupName $ResourceGroupName -Parameter $wafParameter
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