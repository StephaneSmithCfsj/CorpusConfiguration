<#
.SYNOPSIS
Provisions the CfsjContentType Component.
.EXAMPLE
PS C:\> .\Deploy-CfsjContentType.ps1 -TargetSiteUrl "https://intranet.mydomain.com/sites/targetSite"
.EXAMPLE
PS C:\> $creds = Get-Credential
PS C:\> .\Deploy-CfsjContentType.ps1 -TargetSiteUrl "https://intranet.mydomain.com/sites/targetSite" -Credentials $creds
#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, HelpMessage="Enter the URL of the target site collection, e.g. 'https://intranet.mydomain.com/sites/targetSite'")]
    [String]
    $TargetSiteUrl,
    
    [Parameter(Mandatory = $false, HelpMessage="Optional administration credentials")]
    [PSCredential]
    $Credentials
    
)

function Get-ScriptDirectory {
    Split-Path -parent $PSCommandPath
}

$ExecutionPath= Get-ScriptDirectory

$DeployComponentName= "Cfsj.ContentType"


if($Credentials -eq $null)
{
	$Credentials = Get-Credential -Message "Enter Admin Credentials"
}

Write-Host -ForegroundColor White "--------------------------------------------------------"
Write-Host -ForegroundColor White "|                 Deploying $DeployComponentName       |"
Write-Host -ForegroundColor White "|                 Deploying From $ExecutionPath        |"
Write-Host -ForegroundColor White "--------------------------------------------------------"

Write-Host -ForegroundColor Yellow "Target Site URL: $targetSiteUrl"

try
{
    Connect-SPOnline $targetSiteUrl -Credentials $Credentials

    Write-Host -ForegroundColor White "--------------------------------------------------------"
    Write-Host -ForegroundColor White "|                 Ajout des content Type               |"
    Write-Host -ForegroundColor White "--------------------------------------------------------"
    
    Apply-SPOProvisioningTemplate -Path .\packages\files.xml

    Write-Host -ForegroundColor Green "$DeployComponentName deployment succeeded"
}
catch
{
    Write-Host -ForegroundColor Red "Exception occurred!" 
    Write-Host -ForegroundColor Red "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Host -ForegroundColor Red "Exception Message: $($_.Exception.Message)"
}