<#
.SYNOPSIS
Provisions the Negotium events calendar.
.EXAMPLE
PS C:\> .\Deploy-Calendar-Data.ps1 -TargetSiteUrl "https://intranet.mydomain.com/sites/targetSite"
.EXAMPLE
PS C:\> $creds = Get-Credential
PS C:\> .\Deploy-Calendar-Data.ps1 -TargetSiteUrl "https://intranet.mydomain.com/sites/targetSite" -Credentials $creds
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, HelpMessage="Enter the URL of the target site collection, e.g. 'https://intranet.mydomain.com/sites/targetSite'")]
    [String]$TargetSiteUrl,
    [Parameter(Mandatory = $false, HelpMessage="Optional administration credentials")]
    [PSCredential]$Credentials
)

begin{
    $oldFolder=""
    
    #Array des lists a détruire
    $ArrListToDelete=@()

    #Path of execution
    $PackagePath =  ".\packages"

    #Create a variable for the date stamp in the log file
    $LogDate = get-date -f yyyyMMddhhmm

    #Define CSV and log file location variables
    #they have to be on the same location as the script
    $NavlinkFileResult = ".\packages\navlinks_$logDate.xml"

    $NavlinkFile = ".\packages\navlinks.xml"

    #Création de l'array de Valeur par défaut de la taxonomy
    ### Need termID for Corporation
    $ArrTaxoDefault = @{
        "/RH"="-1;#Ressources humaines|872b10c7-f4c8-4b98-ae06-dfafd3fcda23"
        "/EntretienMenager"="-1;#Entretien ménager|9a103d16-7d9b-425a-86dc-e3ad0333be2f"
        "/ServiceProjet"="-1;#Service projets|a1932f15-1b46-4a73-9178-4f1b44fc4100"
        "/ServiceTechnique"="-1;#Service technique|ef34fff4-1e03-43bc-8cd3-bb19ae5fdb10"
        "/QA"="-1;#Assurance qualité|bd0f22be-4c3c-4c70-8cc7-ff4ec7517ca6"
        "/ComiteDirection"="-1;#Comité de direction|e81e6a04-1a74-4789-8a44-f8d34e92f718"
        "/Corporation"="-1;#Corporation|278120a3-7513-4bcc-822d-27139adff803"
        "/CA"="-1;#Conseil d’administration|688f5ed4-fb5f-4c87-ac8b-8a085c340d68"
        "/DG"="-1;#Direction générale|bd277ccc-8f11-48f6-aa7a-1fd399f1c3a4"
        "/DocArchive"="-1;#Documents et archives|896d3910-1812-43a8-a6a9-f1f3ebb78c96"
        "/Finances"="-1;#Finances|c6aa7b79-bbdd-49a4-9266-151c898d8b44"
        "/ComiteEnvironnement"="-1;#Comité environnement|4ffa461f-2251-4bb0-a432-b575d10e9ebb"
        "/EnergieEnvironnement"="-1;#Énergie et environnement|444c5331-3e5c-446e-a4e8-b99eb9ab6448"
        "/MUSEFSJ"="-1;#Musée du Fort Saint-Jean|4092b531-5f67-4290-8725-ad0962df6f3e"
        "/AccueilHebergement"="-1;#Accueil et hébergement|1adf825b-3dca-4e92-bfa6-9f0117f83884"
        "/OperationRestauration"="-1;#Opérations restauration|642ccb4f-594f-4cf8-a3d3-4aeefbe0e0a0"
        "/ServiceClientele"="-1;#Service à la clientèle|aa34ec8e-efdd-4130-9d47-b88ff940d140"
        "/Securite"="-1;#Sécurité|801cfde2-ccf9-4bbf-9727-c4a685e474b7"
        "/Approvisionnement"="-1;#Approvisionnement|9abb491d-7c32-430a-8583-02132a570508"
        "/ComiteSST"="-1;#Comité SST|6ea96ec9-3e21-4667-b984-1511125b2a56"
        "/TI"="-1;#Technologies de l?information|47b2d2aa-8d77-4f8c-bace-80a4b9ec21c4"
    }

    function Convert-PSCustomObject-ToHashtable{
          param(
            [parameter(Mandatory=$True,ValueFromPipeline=$True)]$psObject
            )
        
        process {
            $hashTable = @{}
            Get-Member -InputObject $psObject -MemberType NoteProperty | 
                    ?{ -not [string]::IsNullOrEmpty($psObject."$($_.name)")} | 
                                % {$hashTable.add($_.name,$psObject."$($_.name)")}
            return $hashTable
        }   
    }#Convert-PSCustomObject-ToHashtable

}#Begin

process{
    

    Write-Host -ForegroundColor White "--------------------------------------------------------"
    Write-Host -ForegroundColor White "|   Deploying MDDLinks Lists and data                  |"
    Write-Host -ForegroundColor White "--------------------------------------------------------"

    Write-Host -ForegroundColor Yellow "Target Site URL: $targetSiteUrl"

    if($Credentials -eq $null)
    {
        $Credentials = Get-Credential -Message "Enter Admin Credentials"
    } 
    else 
    {
       Write-Host -ForegroundColor White "--------------------------------------------------------"
       Write-Host -ForegroundColor White "------Connecting ---------------------------------------"

       Connect-SPOnline $targetSiteUrl -Credentials $Credentials
    }

    try
    {

        #Récupération du secteur d'activité 
        $ServiceAssocieValue = get-spoweb|%{$_.ServerRelativeUrl}

        Write-Host -ForegroundColor White "--------------------------------------------------------"
        Write-Host -ForegroundColor White "|                 Mise en place de la Liste MDD         |"
        Write-Host -ForegroundColor White "|                 $NavlinkFileResult                    |"
        Write-Host -ForegroundColor White "--------------------------------------------------------"

        Write-Host -ForegroundColor Yellow "- Mise en place du site : $($ServiceAssocieValue)"
    
        #Create TargetList LiensMDD pour accueillir les liens Pour la librairie ITEM
        (Get-Content $NavlinkFile).replace('{TaxonomyDefaultValue}', $ArrTaxoDefault[$ServiceAssocieValue]) | Set-Content $NavlinkFileResult      
        Apply-SPOProvisioningTemplate -Path $NavlinkFileResult

        Write-Host -ForegroundColor White "--------------------------------------------------------"
        Write-Host -ForegroundColor White "|                 Copie des item des liens             |"
        Write-Host -ForegroundColor White "--------------------------------------------------------"

        Write-Host -ForegroundColor Green "CFSJ Links Update Sample data deployment succeeded"
    }
    catch
    {
        Write-Host -ForegroundColor Red "Exception occurred!" 
        Write-Host -ForegroundColor Red "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Host -ForegroundColor Red "Exception Message: $($_.Exception.Message)"
    }
}
