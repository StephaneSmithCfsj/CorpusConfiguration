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

$ArrSC = @{"approvisionnement"="approvisionnement";
"archives"="DocArchive";
"assurance_qualite"="QA";
"Corporation"="Corporation";
"direction_generale"="DG";
"finances"="finances";
"hebergement"="AccueilHebergement";
"Muse"="MuseFSJ";
"Musee"="MuseFSJ";
"restauration"="OperationRestauration";
"rh"="RH";
"sante_securite"="ComiteSST";
"Securite"="Securite";
"service_projets"="ServiceProjet";
"serviceclient"="ServiceClientele";
"services_techniques"="ServiceTechnique";
"ti"="TI"}


if($WriteToFile -eq $true)
{
$outputPath = "d:\works\AllLinks-Data.json"
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
    

     
#Write-Host "Website"$web.url -ForegroundColor Green 
#if($WriteToFile -eq $true){Add-Content -Path $outputPath -Value "Website $($web.url)"}
    foreach($list in $lists) {
            
        if ( $list.BaseTemplate -contains "Links")
        {

 
            $sourceSPListItemCollection = $list.GetItems(); 

            foreach($srcListItem in $sourceSPListItemCollection){                
                #Recherche les valeurs des champs
                $srcListItem | foreach-object {
                
                    Write-Host $web.url "*************" $listcount 

                    if(($WriteToFile -eq $true) -and ($listcount -gt 0)){Add-Content -Path $outputPath -Value ","}

                
                    $title = $_['Title']
                    if ($_['Title'].length -le 1 ) { 
                        $title = $_['Title']
                        $spliturl = $_['URL'] -split "," 
                        $title = $spliturl[1].Trim() 
                        $title = $title -Replace """" , ""
                    }
                
                
                    #Find $ServiceAssocié
                    $split = $web.url-split '/'               
                    if ($split[3].length -le 1) { $ServiceAssocie = "Corporation"}
                    elseif ($split[4].length -le 1) { $ServiceAssocie = $split[3]}
                    else {$ServiceAssocie = $split[4]}
                
                    #correspondance des fichiers Service Associés
                    $ServiceAssocie = $ArrSC[$ServiceAssocie]
                    
                
                    $directory = $($list.Title) 
                    if ($split[5].length -ge 2){
                        $directory = $($list.Title) + " " + $split[5]
                    }
                                
                    #Find Lien Source
                    $Linksplit = $_['URL'] -split '/'
           
                    #     if ($Linksplit[2] -eq "portal.cfsj.qc.ca") { Write-Host $_['URL']}
                
                
                    $InputURL = $_['URL'] -Replace ',','","'
                                    
                    if($WriteToFile -eq $true){Add-Content -Path $outputPath -Value "{ ""ServiceAssocie"": ""$($ServiceAssocie)"" , ""Directory"": ""$($directory)"", ""LinkTitle"": ""$($Title)"" , ""Url"":[ ""$($InputURL)""] }"}
                    $listcount +=1 
                    
                } #$srcListItem 
            
            }  #ForEach listItem     
            
        } #If Links
    } # ForEach List
          
    

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


I:\SP\PnP>nslookup sp16qa.cfsj.qc.ca
Server:  cfsjdc3.cfsj.qc.ca
Address:  10.0.1.100

Name:    cfsjsp16qa1.cfsj.qc.ca
Address:  10.0.1.214
Aliases:  sp16qa.cfsj.qc.ca

