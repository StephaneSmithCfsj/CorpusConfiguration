<#
.SYNOPSIS
Migrate SharPoint Site with ShareGate
.EXAMPLE
PS C:\> .\Migrate-sp-Data.ps1 -TargetSiteUrl "sp16dev1.cfsj.qc.ca"
.EXAMPLE
PS C:\> $creds = Get-Credential
PS C:\> .\Migrate-sp-Data.ps1 -TargetSiteUrl "intranet.mydomain.com" -Credentials $creds
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, HelpMessage="Enter the URL of the target site collection, e.g. 'intranet.mydomain.com'")]
    [String]$TargetSiteUrl,

    [Parameter(Mandatory = $true, HelpMessage="Optional administration credentials")]
    [PSCredential]$Credentials
)

begin{

    Import-Module Sharegate
    $oldTargetSiteUrl=""
    
    #Load Array of Association for Site migration

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

 $ArrSCDelete = @{"http://%site%/finances/approvisionnement"="http://%site%/finances";
 "http://%site%/finances/TI"="http://%site%/finances";
 "http://%site%/OperationRestauration/hebergement"="http://%site%/OperationRestauration";
 "http://%site%/OperationRestauration/serviceclient"="http://%site%/OperationRestauration";
 "http://%site%/rh/Securite"="http://%site%/RH";
 "http://%site%/ServiceProjet/assurance_qualite"="http://%site%/ServiceProjet";
 "http://%site%/ServiceProjet/Muse"="http://%site%/ServiceProjet";
 "http://%site%/Corporation/Rh"="http://%site%/Corporation";
 "http://%site%/Corporation/archives"="http://%site%/Corporation";
 "http://%site%/Corporation/direction_generale"="http://%site%/Corporation";
 "http://%site%/Corporation/Finances"="http://%site%/Corporation";
 "http://%site%/Corporation/restauration"="http://%site%/Corporation";
 "http://%site%/Corporation/service_projets"="http://%site%/Corporation";
 "http://%site%/Corporation/services_techniques"="http://%site%/Corporation";
}

  function RemoveSubWebRecurse {
        [Cmdletbinding()]
        param(
            [parameter(Mandatory=$True)]$webIdentity
        )
        Process {

            $web = Get-spoweb -Identity $webIdentity

            if (Get-SPOSubWebs -web $web ){
                Write-Host -ForegroundColor yellow "   Findding sub WEB for ($($web.Title))"
                Get-SPOSubWebs -web $web | % {write-host -ForegroundColor yellow "     Found Sub Web $($_.Title)"}
                Get-SPOSubWebs -web $web | %{RemoveSubWebRecurse -webIdentity $_.ID} 
             }
             Remove-SPOWeb -Identity $web.Id -force
             Write-Host -ForegroundColor Green "       Removing WEB ($($web.Title))"
            
        }
    }#RemoveSubWeb
 
    
 };#Begin


process{
    <# 
    if($Credentials -eq $null)
    {
        $Credentials = Get-Credential -Message "Enter Admin Credentials"
    } 
    #>

    Write-Host -ForegroundColor White "--------------------------------------------------------"
    Write-Host -ForegroundColor White "|   Migrating data                  |"
    Write-Host -ForegroundColor White "--------------------------------------------------------"

    Write-Host -ForegroundColor Yellow "Main Content Target Site : $targetSiteUrl"

    try
    {
          
        foreach($i in $ArrSC.GetEnumerator())
        {
            write-host "$($i.Name):$($i.Value -replace "%site%",$targetSiteUrl )"


            $srcSite = Connect-Site -Url $($i.Name)
            $dstSite = Connect-Site -Url $($i.Value -replace "%site%",$targetSiteUrl)
            Copy-Site -Site $srcSite -DestinationSite $dstSite -Merge -Subsites -InsaneMode 

            
        }
        Write-Host -ForegroundColor Green "Migrating Data deployment succeeded"

        foreach($i in $ArrSCDelete.GetEnumerator())
        {
            write-host "----- Connecting to  $($i.Value -replace "%site%",$targetSiteUrl)"
            

            Connect-SPOnline  -Url $($i.Value -replace "%site%",$targetSiteUrl) -Credentials $cred
            #Getall Subweb and find the subSite to remove
            write-host "   Try removing Site to  $($i.Name -replace "%site%",$targetSiteUrl )"
            $SiteName = Get-SPOSubWebs| where-Object {$_.url -eq $($i.Name -replace "%site%",$targetSiteUrl)}| Select-Object ID,Title
            
           if($SiteName.id) {
                RemoveSubWebRecurse -webIdentity $SiteName.ID
            }
            else
            {
                Write-Host -ForegroundColor Red "   Not WEB to remove($($i.Name -replace "%site%",$targetSiteUrl ))"
            }
           Disconnect-SPOnline
            
        }
        Write-Host "***Remove Extra Site succeeded"
    }
    catch
    {
        Write-Host -ForegroundColor Red "Exception occurred!" 
        Write-Host -ForegroundColor Red "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Host -ForegroundColor Red "Exception Message: $($_.Exception.Message)"
    }

}