<#
.SYNOPSIS
Provisions the Negotium Carousel Component.
.EXAMPLE
PS C:\> .\Deploy-Carousel.ps1 -TargetSiteUrl "https://intranet.mydomain.com/sites/targetSite"
.EXAMPLE
PS C:\> $creds = Get-Credential
PS C:\> .\Deploy-Carousel.ps1 -TargetSiteUrl "https://intranet.mydomain.com/sites/targetSite" -Credentials $creds
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, HelpMessage="Enter the URL of the target site collection, e.g. 'https://intranet.mydomain.com/sites/targetSite'")]
    [String]
    $TargetSiteUrl,
    
    [Parameter(Mandatory = $false, HelpMessage="Optional administration credentials")]
    [PSCredential]
    $Credentials,
    
    [Parameter(Mandatory = $false, HelpMessage="Deploy static files only. Ignore SharePonit artifacts")]
    [switch]
    $FilesOnly

)


if($Credentials -eq $null)
{
	$Credentials = Get-Credential -Message "Enter Admin Credentials"
}

Write-Host -ForegroundColor White "--------------------------------------------------------"
Write-Host -ForegroundColor White "|  Intranet Bottin Employee"
Write-Host -ForegroundColor White "|  $PSScriptRoot"
Write-Host -ForegroundColor White "--------------------------------------------------------"

Write-Host -ForegroundColor Yellow "Target Site URL: $targetSiteUrl"

try
{
    Connect-SPOnline -url $targetSiteUrl -Credentials $Credentials
    Apply-SPOProvisioningTemplate -Path .\packages\files.xml
 #  set-spomasterpage -MasterPageSiteRelativeUrl _catalogs/masterpage/FSJ/FSJ.master
    # Remove webpart from page
 #   Set-SPOFileCheckedOut -Url "/recherche/pages/peopleResults.aspx"

  #  Remove-SPOWebpart -Title "Résultats principaux de la recherche de personnes" -ServerRelativePageUrl "/pages/peopleResults.aspx"
  #  Remove-SPOWebpart -Title "Perfectionnement" -ServerRelativePageUrl "/pages/peopleResults.aspx"

    # Add Webparts to page
   # Add-SPOWebPartToWebPartPage -ServerRelativePageUrl "/Pages/PeopleResults.aspx" -Path ".\app\PeopleSearchMain.webpart" -ZoneId "MainZone" -ZoneIndex 5
   # Add-SPOWebPartToWebPartPage -ServerRelativePageUrl "/Pages/PeopleResults.aspx" -Path ".\app\Perfectionnement.webpart" -ZoneId "NavigationZone" -ZoneIndex 1
   # Set-SPOFileCheckedIn -Url "/recherche/pages/peopleResults.aspx"
   # Write-Host -ForegroundColor Green "Intranet Bottin Employee deployment succeeded"
}
catch
{
    Write-Host -ForegroundColor Red "Exception occurred!" 
    Write-Host -ForegroundColor Red "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Host -ForegroundColor Red "Exception Message: $($_.Exception.Message)"
}