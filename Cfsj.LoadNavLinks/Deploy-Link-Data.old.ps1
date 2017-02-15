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
    $ArrTaxoDefault = @{
        "Ressources humaines"="48;#Ressources humaines|872b10c7-f4c8-4b98-ae06-dfafd3fcda23"
        "Entretien ménager"="49;#Entretien ménager|9a103d16-7d9b-425a-86dc-e3ad0333be2f"
        "Service projets"="50;#Service projets|a1932f15-1b46-4a73-9178-4f1b44fc4100"
        "Serice Technique"="51;#Service technique|ef34fff4-1e03-43bc-8cd3-bb19ae5fdb10"
        "Assurance Qualité"="52;#Assurance qualité|bd0f22be-4c3c-4c70-8cc7-ff4ec7517ca6"
        "Comité de direction"="53;#Comité de direction|e81e6a04-1a74-4789-8a44-f8d34e92f718"
        "Conseil d’administration"="54;#Conseil d’administration|688f5ed4-fb5f-4c87-ac8b-8a085c340d68"
        "Direction générale"="55;#Direction générale|bd277ccc-8f11-48f6-aa7a-1fd399f1c3a4"
        "Documents et archives"="56;#Documents et archives|896d3910-1812-43a8-a6a9-f1f3ebb78c96"
        "Finances"="57;#Finances|c6aa7b79-bbdd-49a4-9266-151c898d8b44"
        "Comité environnement"="58;#Comité environnement|4ffa461f-2251-4bb0-a432-b575d10e9ebb"
        "Énergie et environnement"="59;#Énergie et environnement|444c5331-3e5c-446e-a4e8-b99eb9ab6448"
        "Musée du Fort Saint-Jean"="60;#Musée du Fort Saint-Jean|4092b531-5f67-4290-8725-ad0962df6f3e"
        "Accueil et hébergement"="61;#Accueil et hébergement|1adf825b-3dca-4e92-bfa6-9f0117f83884"
        "Opérations restauration"="62;#Opérations restauration|642ccb4f-594f-4cf8-a3d3-4aeefbe0e0a0"
        "Service à la clientèle"="63;#Service à la clientèle|aa34ec8e-efdd-4130-9d47-b88ff940d140"
        "Approvisionnement"="64;#Approvisionnement|9abb491d-7c32-430a-8583-02132a570508"
        "Comité SST"="65;#Comité SST|6ea96ec9-3e21-4667-b984-1511125b2a56"
        "Technologies de l’information"="66;#Technologies de l’information|47b2d2aa-8d77-4f8c-bace-80a4b9ec21c4"
    }
    function BuildListems {
        [Cmdletbinding()]
        param(
            [parameter(Mandatory=$True,ValueFromPipeline=$True)]$List
        )
        Process {

            
            $ListItems = @()
            Write-Host "folder" $List.Title
            
            if ($list.title -ne $oldFolder){ 

                $DestinationTargetName = "/Lists/"+$TargetListName+"/"+$List.Title
                
                #Ajout du répertoire 
                Ensure-SPOFolder -SiteRelativePath $DestinationTargetName 

                $oldFolder = $List.title
            }

            $oldListItems = Get-SPOListItem -list $List.Title
            foreach ($Item in $oldListItems ){

                $ListItem = New-Object System.Object
            
                $title = $item.Title
                if ($title.length -le 1 ) { 
                    $spliturl = $item["URL"]
                    $title = $spliturl.Description
                }
                Add-Member -InputObject $ListItem  -MemberType NoteProperty -Name "FolderName" -Value $List.Title        
                Add-Member -InputObject $ListItem  -MemberType NoteProperty -Name "Title" -Value $Title        
                Add-Member -InputObject $ListItem  -MemberType NoteProperty -Name "MDDLinkUrl" -Value $item["URL"]
 #               Add-Member -InputObject $ListItem  -MemberType NoteProperty -Name "MDDDisplayDesc" -Value 1
 #               Add-Member -InputObject $ListItem  -MemberType NoteProperty -Name "MDDLinkHidden"  -Value 1
                Add-Member -InputObject $ListItem  -MemberType NoteProperty -Name "MDDLinkNewWin"  -Value 1
                Write-Host "Adding..." $Title

                $ListItems += $ListItem
            }

            return $ListItems 
        }

    }#BuildListems

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

     #  Connect-SPOnline $targetSiteUrl -Credentials $Credentials
    }
    <# 

    #>

    try
    {

        #Récupération du secteur d'activité 
        $ServiceAssocieValue = get-spoweb|%{$_.Title}

        Write-Host -ForegroundColor White "--------------------------------------------------------"
        Write-Host -ForegroundColor White "|                 Mise en place de la Liste MDD         |"
        Write-Host -ForegroundColor White "|                 $NavlinkFileResult                    |"
        Write-Host -ForegroundColor White "--------------------------------------------------------"

        Write-Host -ForegroundColor Yellow "- Mise en place du site : $($ServiceAssocieValue)"
    
        #Create TargetList LiensMDD pour accueillir les liens Pour la librairie ITEM
        (Get-Content $NavlinkFile).replace('{TaxonomyDefaultValue}', $ArrTaxoDefault[$ServiceAssocieValue]) | Set-Content $NavlinkFileResult      
     #   Apply-SPOProvisioningTemplate -Path $NavlinkFileResult

        $TargetListName = "LiensMDD5"

        Write-Host -ForegroundColor White "--------------------------------------------------------"
        Write-Host -ForegroundColor White "|                 Copie des item des liens             |"
        Write-Host -ForegroundColor White "--------------------------------------------------------"

        # Le fichiers doit etre sans espace en mode short
        $Lists = Get-SPOList | where-object {$_.basetemplate -eq 103 -and $_.Title -ne $TargetListName} 
   
        #Build ListItems 
        $ListItems = $Lists | BuildListems

        $ListItems | Convert-PSCustomObject-ToHashtable | %{ Add-SPOListItem -List $TargetListName -Values $_ -Folder $_.FolderName }


        #Remove List item from Site.
   #     $Lists | % { Remove-SPOList $_.ID } 

        #Remove NavLinksPackage
   #     Remove-item $NavlinkFileResult -Force

        Write-Host -ForegroundColor Green "CFSJ Links Update Sample data deployment succeeded"
    }
    catch
    {
        Write-Host -ForegroundColor Red "Exception occurred!" 
        Write-Host -ForegroundColor Red "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Host -ForegroundColor Red "Exception Message: $($_.Exception.Message)"
    }
}



    #Recuperation 
        #$listitems = get-spolist | %{ if ($_.basetemplate -eq 103){Get-SPOListItem -List $_.Title -Fields "FileLeafRef", "Modified" | %{new-object psobject -property  @{Id = $_.Id; Name = $_["FileLeafRef"]; Modified = $_["Modified"]}}}}
        
        #Get-SPOListItem -List "Style Library" -Fields "FileLeafRef", "Modified" | %{new-object psobject -property  @{Id = $_.Id; Name = $_["FileLeafRef"]; Modified = $_["Modified"]}} | select Id, Name, Modified
        #$lists  = get-spolist | %{ if ($_.basetemplate -eq 103 -and $_.Title -ne "LiensMDD"){Get-SPOListItem -List $_.Title }}

<#
    function Process-Link{
        [Cmdletbinding()]
        param(
            [parameter(Mandatory=$True,ValueFromPipeline=$True)]$List, 
            [parameter(Mandatory=$True)][string]$TargetSite
        )
        
        process {

            $listItems = Get-SPOListItem -List $List.id

            Add-Member -InputObject $Link -MemberType NoteProperty -Name "EventDate" -Value $eventDateTime.ToUniversalTime()         
                            
            Write-Host "Conn `"$($Link.Title)`" in $ServiceAssocieList" -ForegroundColor Yellow
            return $Link 

        }
    }#Process-Link



  #>
