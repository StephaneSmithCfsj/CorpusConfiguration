Param
(
#[string] $URL="http://portail.cfsj.qc.ca",
[string] $URL="",
[boolean] $WriteToFile = $true
)

#Get all lists in farm
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

#Counter variables
$webcount = 0
$listcount = 0



#Load Array

$ArrSC = @{"http://portail.cfsj.qc.ca"="http://%site%/Corporation";
 "http://portail.cfsj.qc.ca/archives"="http://%site%/DocArchive";
 "http://portail.cfsj.qc.ca/direction_generale"="http://%site%/DG";
 "http://portail.cfsj.qc.ca/finances"="http://%site%/finances";
 "http://portail.cfsj.qc.ca/finances/approvisionnement"="http://%site%/approvisionnement";
 "http://portail.cfsj.qc.ca/finances/TI"="http://%site%/TI";
 "http://portail.cfsj.qc.ca/restauration"="http://%site%/OperationRestauration";
 "http://portail.cfsj.qc.ca/restauration/hebergement"="http://%site%/AccueilHebergement";
 "http://portail.cfsj.qc.ca/restauration/serviceclient"="http://%site%/ServiceClientele";
 "http://portail.cfsj.qc.ca/rh"="http://%site%/RH";
 "http://portail.cfsj.qc.ca/rh/Securite"="http://%site%/Securite";
 "http://portail.cfsj.qc.ca/service_projets"="http://%site%/ServiceProjet";
 "http://portail.cfsj.qc.ca/service_projets/assurance_qualite"="http://%site%/QA";
 "http://portail.cfsj.qc.ca/service_projets/Muse"="http://%site%/MuseFSJ";
 "http://portail.cfsj.qc.ca/services_techniques"="http://%site%/ServiceTechnique";}


if($WriteToFile -eq $true)
{
$outputPath = ".\AllLinks-Data.json"
}
if(!$URL)
{
#Grab all webs
$webs = (Get-SPSite -limit all | Get-SPWeb -Limit all -ErrorAction SilentlyContinue)
}
else
{
$webs = Get-SPWeb $URL
}
if($webs.count -ge 1 -OR $webs.count -eq $null)
{
    if($WriteToFile -eq $true){Add-Content -Path $outputPath -Value "["}
    
    foreach($web in $webs)
    {
   #Grab all lists in the current web
    $lists = $web.Lists  
    

     
        Write-Host "Website"$web.url -ForegroundColor Green 
        if($WriteToFile -eq $true){Add-Content -Path $outputPath -Value "Website $($web.url)"}
                
               
                                    
        #            if($WriteToFile -eq $true){Add-Content -Path $outputPath -Value "{ ""ServiceAssocie"": ""$($ServiceAssocie)"" , ""Directory"": ""$($directory)"", ""LinkTitle"": ""$($Title)"" , ""Url"":[ ""$($InputURL)""] }"}
                    
    

    $webcount +=1
    $web.Dispose()
    
    } #ForEach Web
    if($WriteToFile -eq $true){Add-Content -Path $outputPath -Value "]"}
#Show total counter for checked webs & lists
Write-Host "Amount of webs checked:"$webcount
Write-Host "Amount of lists:"$listcount
}
else
{
Write-Host "No webs retrieved, please check your permissions" -ForegroundColor Red -BackgroundColor Black
}