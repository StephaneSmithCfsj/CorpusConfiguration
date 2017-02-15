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
Write-Host -ForegroundColor White "|                 Deploying Intranet Design    $PSScriptRoot         |"
Write-Host -ForegroundColor White "--------------------------------------------------------"

Write-Host -ForegroundColor Yellow "Target Site URL: $targetSiteUrl"

try
{
    Connect-SPOnline -url $targetSiteUrl -Credentials $Credentials

    Apply-SPOProvisioningTemplate -Path .\packages\files.xml
    
    Add-SPOMasterPage -SourceFilePath "$PSScriptRoot/app/CFSJ-mdd-DEV-TEST.master" -Title "MDD TEST Only " -Description "MasterPage for FSJ Intranet WITH MDD" -DestinationFolderHierarchy "FSJ"   
    Add-SPOMasterPage -SourceFilePath "$PSScriptRoot/app/CFSJ-mdd-DEV.master" -Title "MDD DEV Only " -Description "MasterPage for FSJ Intranet WITH MDD" -DestinationFolderHierarchy "FSJ"   
    Add-SPOMasterPage -SourceFilePath "$PSScriptRoot/app/CFSJ-mdd-responsive.master" -Title "MDD Only " -Description "MasterPage for FSJ Intranet WITH MDD" -DestinationFolderHierarchy "FSJ"
    $articlePageContentTypeID = "0x010100C568DB52D9D0A14D9B2FDCC96666E9F2007948130EC3DB064584E219954237AF3900242457EFB8B24247815D688C526CD44D"
    set-spomasterpage -MasterPageSiteRelativeUrl _catalogs/masterpage/FSJ/CFSJ-mdd-DEV-TEST.master
    Write-Host -ForegroundColor Green "Intranet Design deployment succeeded"
}
catch
{
    Write-Host -ForegroundColor Red "Exception occurred!" 
    Write-Host -ForegroundColor Red "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Host -ForegroundColor Red "Exception Message: $($_.Exception.Message)"
}