Write-Host -ForegroundColor White "Set the SharePoint 2010 and 2013 Navigation Settings on Sites"

#Set the Site Collection
$SPSite = Get-SPSite -Identity "http://siteurl/"

#Go through each site in the Site Collection
foreach ($SPWeb in $SPSite.AllWebs)
{
    $navSettings = New-Object Microsoft.SharePoint.Publishing.Navigation.WebNavigationSettings($SPWeb)
    $navSettings.ResetToDefaults();
    $navSettings.GlobalNavigation.Source = 1
    $navSettings.Update()

    Write-Host "Navigation updated successfully for site $url"

}