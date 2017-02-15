<#
 .SYNOPSIS
    Imports an exported Taxonomy XML file to SharePoint On-Prem or 365 environment.
 
 .DESCRIPTION
    The Import-Taxonomy.ps1 function will read through a given XML File and import Groups, TermSets, Terms 
    into the SharePoint Term Store if they do not exist. Works for Online and On-Prem environments

 .PARAMETER AdminUser
    The user who has adminitrative access to the term store. (e.g On-Prem: Domain\user 365:user@sp.com)

 .PARAMETER AdminPassword
    The password for the Admin User.

 .PARAMETER AdminUrl
    The URL of Central Admin for On-Prem or Admin site for 365

 .PARAMETER FilePathOfExportXMLTerms
    The path you wish to save the XML Output to. This path must exist.

 .PARAMETER PathToSPClientdlls
   The script requires to call the following dlls:
   Microsoft.SharePoint.Client.dll
   Microsoft.SharePoint.Client.Runtime.dll
   Microsoft.SharePoint.Client.Taxonomy.dll

   E.g C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI

 .EXAMPLE
    This imports the XML into the SharePoint term store.
    ./Import-Taxonomy.ps1 -AdminUser user@sp.com -AdminPassword password -AdminUrl https://sp-admin.onmicrosoft.com -FilePathOfExportXMLTerms c:\myTerms\exportedterms.xml -PathToSPClientdlls "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI"

 .EXAMPLE
    This is live imports the XML into the SharePoint term store.
    ./Import-Taxonomy.ps1 -Credential $Credential -Url https://sp16qa.cfsj.qc.c-FilePathOfExportXMLTerms c:\myTerms\exportedterms.xml -PathToSPClientdlls "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI"


 .NOTES
    Created By Paul Matthews, with original input from Luis Manez and Kevin Beckett.

 .LINK 
    http://cannonfodder.wordpress.com -Paul Matthews Blog Post About this.
    http://geeks.ms/blogs/lmanez -Luis Manez Blog

#>


 Param(
    [Parameter(Mandatory = $true, HelpMessage="Optional administration credentials")]
    [PSCredential]
    $Credentials,

    [Parameter(Mandatory=$true)]
    [string]$Url,


    [Parameter(Mandatory=$true)]
    [string]$FilePathOfExportXMLTerms

    
 )

 
function Get-TermStoreInfo($spContext){
 $spTaxSession = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($spContext)
 $spTaxSession.UpdateCache();
 $spContext.Load($spTaxSession)

 try
 {
 $spContext.ExecuteQuery()
 }
 catch
 {
  Write-host "Error while loading the Taxonomy Session " $_.Exception.Message -ForegroundColor Red 
  exit 1
 }

 if($spTaxSession.TermStores.Count -eq 0){
  write-host "The Taxonomy Service is offline or missing" -ForegroundColor Red
  exit 1
 }

 $termStores = $spTaxSession.TermStores
 $spContext.Load($termStores)

 try
 {
  $spContext.ExecuteQuery()
  $termStore = $termStores[0]
  $spcontext.Load($termStore)
  Write-Host "Connected to TermStore: $($termStore.Name) ID: $($termStore.Id)"
 }
 catch
 {
  Write-host "Error details while getting term store ID" $_.Exception.Message -ForegroundColor Red
  exit 1
 }

 return $termStore

}

function Get-TermsToImport($xmlTermsPath){
 [Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq") | Out-Null

 try
 {
     $xDoc = [System.Xml.Linq.XDocument]::Load($xmlTermsPath, [System.Xml.Linq.LoadOptions]::None)
     Write-Host $xDoc.FirstNode
     return $xDoc
 }
 catch
 {
      Write-Host "Unable to read ExportedTermsXML. Exception:$_.Exception.Message" -ForegroundColor Red
      exit 1
 }
}

function Create-Groups($spContext, $termStore, $termsXML){
     foreach($groupNode in $termsXML.Descendants("Group"))
     {
        $name = $groupNode.Attribute("Name").Value
        $description = $groupNode.Attribute("Description").Value;
        $groupId = $groupNode.Attribute("Id").Value;
        $groupGuid = [System.Guid]::Parse($groupId);
        Write-Host "Processing Group: $name ID: $groupId ..." -NoNewline

        $group = $termStore.GetGroup($groupGuid);
        $spContext.Load($group);
        
        try
        {
            $spContext.ExecuteQuery();
        }
        catch
        {
            Write-host "Error while finding if " $name " group already exists. " $_.Exception.Message -ForegroundColor Red 
            exit 1
        }
	
	    if ($group.ServerObjectIsNull) {
            $group = $termStore.CreateGroup($name, $groupGuid);
            $spContext.Load($group);
            try
            {
                $spContext.ExecuteQuery();
		        write-host "Inserted" -ForegroundColor Green
            }
            catch
            {
                Write-host "Error creating new Group " $name " " $_.Exception.Message -ForegroundColor Red 
                exit 1
            }
        }
	    else {
		    write-host "Already exists" -ForegroundColor Yellow
	    }
	
	    Create-TermSets $termsXML $group $termStore $spContext

     }

     try
     {
         $termStore.CommitAll();
         $spContext.ExecuteQuery();
     }
     catch
     {
       Write-Host "Error commiting changes to server. Exception:$_.Exception.Message" -foregroundcolor red
       exit 1
     }
}

function Create-TermSets($termsXML, $group, $termStore, $spContext) {
	
    $termSets = $termsXML.Descendants("TermSet") | Where { $_.Parent.Parent.Attribute("Name").Value -eq $group.Name }

	foreach ($termSetNode in $termSets)
    {
        $errorOccurred = $false

		$name = $termSetNode.Attribute("Name").Value;
        $id = [System.Guid]::Parse($termSetNode.Attribute("Id").Value);
        $description = $termSetNode.Attribute("Description").Value;
        $customSortOrder = $termSetNode.Attribute("CustomSortOrder").Value;
        Write-host "Processing TermSet $name ... " -NoNewLine
		
		$termSet = $termStore.GetTermSet($id);
        $spcontext.Load($termSet);
                
        try
        {
            $spContext.ExecuteQuery();
        }
        catch
        {
            Write-host "Error while finding if " $name " termset already exists. " $_.Exception.Message -ForegroundColor Red 
            exit 1
        }
		
		if ($termSet.ServerObjectIsNull) 
        {
			$termSet = $group.CreateTermSet($name, $id, $termStore.DefaultLanguage);
            $termSet.Description = $description;
            
            if($customSortOrder -ne $null)
            {
                $termSet.CustomSortOrder = $customSortOrder
            }
            
            $termSet.IsAvailableForTagging = [bool]::Parse($termSetNode.Attribute("IsAvailableForTagging").Value);
            $termSet.IsOpenForTermCreation = [bool]::Parse($termSetNode.Attribute("IsOpenForTermCreation").Value);

            if($termSetNode.Element("CustomProperties") -ne $null)
            {
                foreach($custProp in $termSetNode.Element("CustomProperties").Elements("CustomProperty"))
                {
                    $termSet.SetCustomProperty($custProp.Attribute("Key").Value, $custProp.Attribute("Value").Value)
                }
            }
            
            try
            {
                $spContext.ExecuteQuery();
            }
            catch
            {
                Write-host "Error occured while create Term Set" $name $_.Exception.Message -ForegroundColor Red
                $errorOccurred = $true
            }

            write-host "created" -ForegroundColor Green
		}
		else {
			write-host "Already exists" -ForegroundColor Yellow
		}
			
        
        if(!$errorOccurred)
        {
            if ($termSetNode.Element("Terms") -ne $null) 
            {
               foreach ($termNode in $termSetNode.Element("Terms").Elements("Term"))
               {
                  Create-Term $termNode $null  $null $termSet $termStore $termStore.DefaultLanguage $spContext
               }
            }	
        }						
    }
}


function Create-Term($termNode, $parentTerm, $parentTermNode, $termSet, $store, $lcid, $spContext){
    $id = [System.Guid]::Parse($termNode.Attribute("Id").Value)
    $name = $termNode.Attribute("Name").Value;
    $isReused = [bool]::Parse($termNode.Attributes("IsReused").Value);
    $isSourceTerm = [bool]::Parse($termNode.Attributes("IsSourceTerm").Value);
    $term = $termSet.GetTerm($id);
    $sourceTerm = $null;
    $errorOccurred = $false

	write-host "at $id the beginning" $term.Name "term.Name"
   
    $spContext.Load($term);
    
    if($isReused)
    {
     if(!$isSourceTerm)
     {
 Write-Host $name "In Create-Term"
       $sourceTermSetId = [System.Guid]::Parse($ParenttermNode.Attributes("Id").Value);
       $sourceTermId =  [System.Guid]::Parse($termNode.Attributes("Id").Value); 
       $sourceTerm = $store.GetTermInTermSet($sourceTermSetId, $sourceTermId);
       $spContext.Load($sourceTerm);

 Write-Host $sourceTermId $sourceTermSetId "term.Name "

     } 
    }
 



    try
    {
        $spContext.ExecuteQuery();
                write-host "Before ExecuteQuery 1" $term.Name

    }
    catch
    {
        Write-host "Error while finding if " $name " term id already exists. " $_.Exception.Message -ForegroundColor Red 
        exit 1
    }


     write-host "Before ExecuteQuery 2" $term.Name " term.Name"

     write-host "Processing Term $name Before Execute Create Term ..." -NoNewLine 
    if($term.ServerObjectIsNull)
    {
        if($sourceTerm -ne $null)
        {

            if ($parentTerm -ne $null) 
            {

                write-host "ParentTerm Not Null"
                $term = $parentTerm.reuseTerm($sourceTerm, $false);
                Write-Host $term.id "term.ID"

            }
            else 
            {
               $term = $termSet.reuseTerm($sourceTerm, $false);
            }
        }
        elseif ($parentTerm -ne $null) 
        {
            $term = $parentTerm.CreateTerm($name, $lcid, $id);
        }
        else 
        {
        
            $term = $termSet.CreateTerm($name, $lcid, $id);
        }

        write-host "Before ExecuteQuery  99 $term.Description 99" $term.Id " 99 "

        $term.IsAvailableForTagging = [bool]::Parse($termNode.Attribute("IsAvailableForTagging").Value);
        if($customSortOrder -ne $null)
        {
            $term.CustomSortOrder = $customSortOrder
        }

        if($termNode.Element("LocalCustomProperties") -ne $null)
        {
            foreach($localCustProp in $termNode.Element("LocalCustomProperties").Elements("LocalCustomProperty"))
            {
                $term.SetLocalCustomProperty($localCustProp.Attribute("Key").Value, $localCustProp.Attribute("Value").Value)
            }
        }
        if($termNode.Element("Labels") -ne $null)
        {
           foreach($label in $termNode.Element("Labels").Elements("Label"))
           {
            #We ignore the first True Label as this is the default label.
            if([bool]::Parse($label.Attribute("IsDefaultForLanguage").Value) -ne $true)
            {
              $labelTerm = $term.CreateLabel($label.Attribute("Value").Value, [int]$label.Attribute("Language").Value, [bool]::Parse($label.Attribute("IsDefaultForLanguage").Value))
            }
           }
        }

        #Only update if not reused term.
        if($sourceTerm -eq $null){
            $description = $termNode.Element("Descriptions").Element("Description").Attribute("Value").Value;
            $term.SetDescription($description, $lcid);
        
            if($termNode.Element("CustomProperties") -ne $null)
            {
                foreach($custProp in $termNode.Element("CustomProperties").Elements("CustomProperty"))
                {
                    $term.SetCustomProperty($custProp.Attribute("Key").Value, $custProp.Attribute("Value").Value)
                }
            }
        }

        try
        {

        
        write-host "Before ExecuteQuery before Load " $term "99"

            $spContext.Load($term);
                       
        write-host "Before ExecuteQuery after Load " $term.Name $spContext

            $spContext.ExecuteQuery();


	        write-host " created" -ForegroundColor Green	
	    }
        catch
        {
            Write-host "Error occured while create Term"   $name $_.Exception.Message -ForegroundColor Red
            $errorOccurred = $true
        }
    }
    else
    {
     write-host "Already exists" -ForegroundColor Yellow
    }
     
    if(!$errorOccurred)
    {
	    if ($termNode.Element("Terms") -ne $null) 
        {
            foreach ($childTermNode in $termNode.Element("Terms").Elements("Term")) 
            {
                Write-Host "Here first"
                Create-Term $childTermNode $Term $termNode $termSet $store $lcid $spContext
            }
        }

    }
}


### Chargement de la connection SharePoint
function LoadAndConnectToSharePoint($url, $credential, $dllPath){

    #Get SPClient Dlls Path
    $spClientdllsDir = Get-Item $dllPath
    #Add required Client Dlls 
    Add-Type -Path "$($spClientdllsDir.FullName)\Microsoft.SharePoint.Client.dll"
    Add-Type -Path "$($spClientdllsDir.FullName)\Microsoft.SharePoint.Client.Runtime.dll"
    Add-Type -Path "$($spClientdllsDir.FullName)\Microsoft.SharePoint.Client.Taxonomy.dll"

    $spContext = New-Object Microsoft.SharePoint.Client.ClientContext($url)
    
    $spContext.Credentials = $credentials
    $spContext.RequestTimeOut = 5000 * 60 * 10;
    $web = $spContext.Web
    $site = $spContext.Site
    $spContext.Load($web)
    $spContext.Load($site)
    try
    {
        $spContext.ExecuteQuery()
        Write-Host "Established connection to SharePoint at $Url OK" -foregroundcolor Green
    }
    catch
    {
        Write-Host "Not able to connect to SharePoint at $Url. Exception:$_.Exception.Message" -foregroundcolor red
        exit 1
    }

    return $spContext
}

$PathToSPClientdlls = "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI"

$spContext = LoadAndConnectToSharePoint $Url $credential $PathToSPClientdlls
$termStore = Get-TermStoreInfo $spContext
$termsXML = Get-TermsToImport $FilePathOfExportXMLTerms
write-host "Create-groups" -ForegroundColor Green

Create-Groups $spContext $termStore $termsXML

Write-host "Completed" -ForegroundColor Green
