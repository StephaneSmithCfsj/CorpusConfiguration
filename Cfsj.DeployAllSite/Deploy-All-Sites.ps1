<#
.SYNOPSIS
Deploy to all Service Associé SharPoint Site 
.EXAMPLE
PS C:\> .\Deploy-All-Site.ps1 -TargetSiteUrl "sp16dev1.cfsj.qc.ca"
.EXAMPLE
PS C:\> $creds = Get-Credential
PS C:\> .\Migrate-sp-Data.ps1 -$Environnement "intranet.mydomain.com" -Credentials $creds
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, HelpMessage="Enter the short URL of the target site collection, e.g. 'intranet.mydomain.com'")]
    [String]$Environnement,

    [Parameter(Mandatory = $true, HelpMessage="Optional administration credentials")]
    [PSCredential]$Credentials
)

begin{

    #Path of execution
    $PackagePath =  ".\packages"

    #Create a variable for the date stamp in the log file
    $LogDate = get-date -f yyyyMMddhhmm

    #Define CSV and log file location variables
    #they have to be on the same location as the script
    $NavlinkFileResult = ".\packages\navlinks_$logDate.xml"

    $CurrentLocation =  Get-Location | Split-Path -Parent
    $OrigineLocation = get-location 
    $NavlinkFile = ".\packages\navlinks.xml"

    #Création de l'array de Valeur par défaut de la taxonomy
    $ArrTaxoDefault = @{
        "Ressources humaines"="48;#Ressources humaines|872b10c7-f4c8-4b98-ae06-dfafd3fcda23";
        "Entretien ménager"="49;#Entretien ménager|9a103d16-7d9b-425a-86dc-e3ad0333be2f";
        "Service projets"="50;#Service projets|a1932f15-1b46-4a73-9178-4f1b44fc4100";
        "Serice Technique"="51;#Service technique|ef34fff4-1e03-43bc-8cd3-bb19ae5fdb10";
        "Assurance Qualité"="52;#Assurance qualité|bd0f22be-4c3c-4c70-8cc7-ff4ec7517ca6";
        "Comité de direction"="53;#Comité de direction|e81e6a04-1a74-4789-8a44-f8d34e92f718";
        "Conseil d’administration"="54;#Conseil d’administration|688f5ed4-fb5f-4c87-ac8b-8a085c340d68";
        "Direction générale"="55;#Direction générale|bd277ccc-8f11-48f6-aa7a-1fd399f1c3a4";
        "Documents et archives"="56;#Documents et archives|896d3910-1812-43a8-a6a9-f1f3ebb78c96";
        "Finances"="57;#Finances|c6aa7b79-bbdd-49a4-9266-151c898d8b44";
        "Comité environnement"="58;#Comité environnement|4ffa461f-2251-4bb0-a432-b575d10e9ebb";
        "Énergie et environnement"="59;#Énergie et environnement|444c5331-3e5c-446e-a4e8-b99eb9ab6448";
        "Musée du Fort Saint-Jean"="60;#Musée du Fort Saint-Jean|4092b531-5f67-4290-8725-ad0962df6f3e";
        "Accueil et hébergement"="61;#Accueil et hébergement|1adf825b-3dca-4e92-bfa6-9f0117f83884";
        "Opérations restauration"="62;#Opérations restauration|642ccb4f-594f-4cf8-a3d3-4aeefbe0e0a0";
        "Service à la clientèle"="63;#Service à la clientèle|aa34ec8e-efdd-4130-9d47-b88ff940d140";
        "Approvisionnement"="64;#Approvisionnement|9abb491d-7c32-430a-8583-02132a570508";
        "Comité SST"="65;#Comité SST|6ea96ec9-3e21-4667-b984-1511125b2a56";
        "Technologies de l’information"="66;#Technologies de l’information|47b2d2aa-8d77-4f8c-bace-80a4b9ec21c4"
    }

    $oldTargetSiteUrl=""
    
    #Load Array of Association for Site migration

    $ArrSA1 = @{
        "AccueilHebergement"="http://%site%.cfsj.qc.ca/AccueilHebergement";    
        "Approvisionnement"="http://%site%.cfsj.qc.ca/Approvisionnement";
        "CA"="http://%site%.cfsj.qc.ca/CA";
        "ComiteDirection"="http://%site%.cfsj.qc.ca/ComiteDirection";
        "ComiteEnvironnement"="http://%site%.cfsj.qc.ca/ComiteEnvironnement";   
        "ComiteSST"="http://%site%.cfsj.qc.ca/ComiteSST";
        "Corporation"="http://%site%.cfsj.qc.ca/Corporation";
        "DG"="http://%site%.cfsj.qc.ca/DG";
        "DocArchive"="http://%site%.cfsj.qc.ca/DocArchive";
        "EnergieEnvironnement"="http://%site%.cfsj.qc.ca/EnergieEnvironnement";  
        "EntretienMenager"="http://%site%.cfsj.qc.ca/EntretienMenager";
        "Finances"="http://%site%.cfsj.qc.ca/Finances";
        "MuseFSJ"="http://%site%.cfsj.qc.ca/MuseFSJ";
        "OperationRestauration"="http://%site%.cfsj.qc.ca/OperationRestauration"; 
        "QA"="http://%site%.cfsj.qc.ca/QA";
        "RH"="http://%site%.cfsj.qc.ca/rh";
        "Securite"="http://%site%.cfsj.qc.ca/Securite";
        "ServiceClientele"="http://%site%.cfsj.qc.ca/ServiceClientele";
        "ServiceProjet"="http://%site%.cfsj.qc.ca/ServiceProjet";
        "ServiceTechnique"="http://%site%.cfsj.qc.ca/ServiceTechnique";
        "TI"="http://%site%.cfsj.qc.ca/TI"
    }


    $ArrSA2 = @{
        "OperationRestauration"="http://%site%.cfsj.qc.ca/OperationRestauration"; 
        "QA"="http://%site%.cfsj.qc.ca/QA";
    }

   Function GetUrl($siteAbr,$SiteEnv){
            Write-Host $siteAbr "****""SiteEnv :" $SiteEnv 
       return $iArrSA1.$siteAbr -replace "%site%",$SiteEnv
   }


 };#Begin


process{
    <# 
    if($Credentials -eq $null)
    {
        $Credentials = Get-Credential -Message "Enter Admin Credentials"
    } 
    #>

    Write-Host -ForegroundColor White "--------------------------------------------------------"
    Write-Host -ForegroundColor White "| Deploy-All-Site                                      |"
    Write-Host -ForegroundColor White "--------------------------------------------------------"

    Write-Host -ForegroundColor Yellow "Main Content Target Site : $Environnement"

    foreach($i in $ArrSA1.GetEnumerator())
    {

        Write-Host -ForegroundColor White "--------------------------------------------------------"
        Write-Host -ForegroundColor White "| Start :  $(get-date -f yyyyMMddhhmm  ) for  $($i.Value -replace "%site%",$Environnement)"
        
        $UrlSite = $i.value -replace "%site%", $Environnement

        
        Set-Location -Path $CurrentLocation"\masterpage"
        & .\Deploy-Design.ps1             -TargetSiteUrl $UrlSite -Credentials $Credentials 
        
        Set-Location -Path $CurrentLocation"\Cfsj.ContentType"
        & .\Deploy-CfsjContentType.ps1   -TargetSiteUrl $UrlSite -Credentials $Credentials 
        
        Set-Location -Path $CurrentLocation"\Cfsj.LoadNavLinks"
        & .\Deploy-LinkMDD.ps1           -TargetSiteUrl $UrlSite -Credentials $Credentials 

        Write-Host -ForegroundColor White "| Done  :  $(get-date -f yyyyMMddhhmm  ) for  $($i.Value -replace "%site%",$targetSiteUrl)"
        Write-Host -ForegroundColor White "--------------------------------------------------------"
        Set-location $OrigineLocation  
    }

}