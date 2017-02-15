
$tmpRoot = Get-SPWebApplication -Identity portal
$tmpRootColl=$tmpRoot.Sites
#Enumerate through each site collection
for ($index=$tmpRootColl.Count-1 ; $index-ge 0 ; $index–-)
{
  Write-Host "Removing site :" $tmpRootColl.Item($index).Name " : " $tmpRootColl.Item($index).Url 
  #Remove-SPSite -Identity $tmpRootColl.Item($index) -GradualDelete -Confirm:$false
}
Get-SPDeletedSite | Remove-SPDeletedSite

# Remove SP Content Database

$tmpRootColl=Get-SPContentDatabase -webapplication $tmpRoot.Name
#Enumerate through each site collection
for ($index=$tmpRootColl.Count-1 ; $index-ge 0 ; $index–-)
{
  Write-Host "Removing site Content Database :" $tmpRootColl.Item($index).Name " : " $tmpRootColl.Item($index).Url
  #Remove-SPContentDatabase -Identity $tmpRootColl.Item($index).name -Confirm:$false
}
