<#
.SYNOPSIS
Deploy to all Service Associé SharPoint Site 
.EXAMPLE
PS C:\> .\Deploy-All-Site.ps1 -TargetSiteUrl "sp16dev1.cfsj.qc.ca"
.EXAMPLE
PS C:\> $creds = Get-Credential
PS C:\> .\Migrate-sp-Data.ps1 -TargetSiteUrl "intranet.mydomain.com" -Credentials $creds
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, HelpMessage="Enter the short URL of the target site collection, e.g. 'intranet.mydomain.com'")]
    [String]$TargetSiteUrl
)

Write-Output "******************** $($TargetSiteUrl)"
