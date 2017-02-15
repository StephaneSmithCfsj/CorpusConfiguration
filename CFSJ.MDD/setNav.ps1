param (
    [string]$url,
    [string]$language = "en",
    [string]$file = "mdd_nav",
	[bool]$ConfirmPreference = $true,
    [string]$action = "add",
	[string]$StartMenu
)

if ( (Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null ) {
    Add-PsSnapin "Microsoft.SharePoint.PowerShell"
}
 
function displayHelp($error) {
	if ($error) {
		write-host ""
		write-host -f Red $error
	}

	write-host ""
	write-host "Mega Drop Down Navigation Import Utility"
	write-host "----------------------------------------"
	write-host ""
	write-host "    Imports the Mega Drop Down navigation configuration from a text file to a SharePoint site."
	write-host ""
	write-host "USAGE"
	write-host ""
	write-host "    setNav -Url <site url> [-StartMenu <menu name>] [-Language <two-letter language code>] [-File <import filename>] [-Action < [add] | remove>] [-Confirm true | false]"
	write-host ""
	write-host "DESCRIPTION"
	write-host ""
	write-host "    setNav allows navigation for Mega Drop Down for SharePoint 2013 to be imported to a site."
	write-host "    The contents of the navigation is imported from a text file and the default name for the import file is mdd_nav.txt"
	write-host ""
	write-host "    The Url parameter should be a fully qualified URL to the site where navigation should be imported."
	write-host ""
	write-host "    The (optional) StartMenu parameter specifies the unique menu ID when using multiple Mega Drop Down controls in the same master page."
	write-host "    The value of this parameter is the value you are using in the <sparch:menu StartMenu='' /> declaration."
	write-host ""
	write-host "    The (optional) Language parameter specifies the language that should be used for importing navigation."
	write-host "    The value should be specified in the ISO 639-1 format.   Example: de for German, nl for Dutch, fr for French"
	write-host ""
	write-host "    The (optional) File parameter specifies the name of the import file."
	write-host ""
	write-host "    The (optional) Action parameter should either specify (default) add or remove.  Remove will remove the navigation configuration for the site."
	write-host ""
	write-host "    The (optional) Confirm parameter determines if confirmation prompts should be suppressed.  Example:  -confirm:$true"
	write-host ""
	write-host "    Navigation is stored in the standard JavaScript Object Notation (JSON) format."
	write-host "    URLs defined in Mega Drop Down's UI Designer can be automatically rewritten to imported URL by replacing the base URLs in the"
	write-host "    text file with the token (site) [including parenthesis].  The import file can be edited in a standard text editor such as notepad."
	write-host ""
	write-host "    For example, a List Heading has been defined and currently points to http://portal.example.com/lists/Human Resources Links"
	write-host ""   
	write-host "    The navigation has been exported from http://portal.example.com and is now being imported to http://www.example.com"
	write-host "    Changing http://portal.example.com/lists/Human Resources LInks to (site)lists/Human Resources Links in the text file would import the"
	write-host "    List Heading as http://www.example.com/lists/Human Resources Links"
	write-host ""
	write-host "    The (site) token can be used for any URL that is defined in the import text file."
	write-host ""
	write-host "EXAMPLES"
	write-host ""
	write-host "    .\setNav.ps1 -Url http://portal.example.com"
	write-host "    Imports the navigation from the (default) file mdd_nav.txt to the site at http://portal.example.com"
	write-host ""
	write-host "    .\setNav.ps1 -Url http://portal.example.com -StartMenu leftnav"
	write-host "    Imports the navigation from the (default) file mdd_nav.txt to the menu for the 'leftnav' control at the site http://portal.example.com"
	write-host ""
	write-host "    .\setNav.ps1 -Url http://portal.example.com -File myimport.txt"
	write-host "    Imports the navigation from the file myimport.txt to the site at http://portal.example.com"
	write-host ""
	write-host "    .\setNav.ps1 -Url http://portal.example.com -Language de"
	write-host "    Imports the German navigation from the (default) file mdd_nav.de.txt to the site at http://portal.example.com"
	write-host ""
	write-host "    .\setNav.ps1 -Url http://portal.example.com -Action remove"
	write-host "    Removes the navigation at the site http://portal.example.com"
	write-host ""
	exit
}

function loadMDDNavigation($spWeb, $nav) {
	Write-Host -nonewline "Loading Mega Drop Down Menu configuration..."

	if ($spWeb.AllProperties.ContainsKey($key)) {
		$spWeb.AllProperties[$key] =  $newNav
	}
	else {
		$spWeb.AllProperties.Add($key, $newNav)
	}

	$spWeb.Update()

	Write-Host "Completed."
	write-host ""
}

function deleteNav($spWeb) {
	write-host ""
	write-host -nonewline "Removing Mega Drop Down navigation from $url..."

	if ($spWeb.AllProperties.ContainsKey($key)) {
		$spWeb.AllProperties.Remove($key)
		write-host "Completed"
	}
	else {
		write-host -f Red "Navigation could not be found."
	}

	write-host ""
	
	$spWeb.Update()
}

function confirm($mesg) {
	if ($ConfirmPreference -eq $true) {
		write-host ""
		write-host $mesg
		write-host ""
		
		write-host "Are you sure you want to perform this action?"
		write-host -foregroundcolor yellow -nonewline "[Y] Yes "
		write-host -foregroundcolor white -nonewline "[N] No " 
		$key = read-host "(default is 'N')"
		
		if ($key.ToLower() -eq "y") {
			return $true
		}
		
		if ($key.ToLower() -eq "q") {
			exit
		}
		
		return $false
	}

	return $true
}

$key = "sparch.mdd.3.0.0.0"
$ifn = "mdd_nav"

if (!$url) {displayHelp ""}
if ($url.contains("http") -eq $false) { displayHelp "-url parameter is required"}
if ($language.length -ne 2) { displayHelp "-language parameter should be in two-letter format (e.g. de for German, fr for French, nl for Dutch " }
if (($action -ne "add") -and ($action -ne "remove")) { displayHelp "-action parameter should either be add or remove"}

if ($language -and $language -ne "en") {
	$key += ".$language"
}

if ($StartMenu) {
	$key += ".$StartMenu"
}

$spWeb = get-SPWeb $url

$curDir = Split-Path -parent $MyInvocation.MyCommand.Definition

$ifn = $curDir + "\" + ([io.fileinfo]$file).basename

$ifn += ".txt"

write-host ""
write-host "Mega Drop Down Navigation Import Utility"
write-host ""
write-host "Destination site: $url"
write-host "Navigation Language: $language"

if ($StartMenu) {
	write-host "StartMenu: $StartMenu"
}

if ($action -eq "remove" ) {
	$result = confirm "This operation will remove navigation configuration from $url"
		
	if ($result -eq $true) {
		deleteNav $spWeb
	}
	else {
		write-host "Operation cancelled."
		write-host ""
	}
}
else {
	if ((Test-Path $ifn -erroraction SilentlyContinue) -eq $false) {
		write-host -f Red "Could not find $ifn"
		write-host ""
	}
	else {
		write-host "Navigation file: $ifn"
		write-host ""
		
		$nav = Get-Content $ifn

		$newNav = [regex]::replace($nav, "\(site\)", $url + "/")

		$result = confirm "Importing navgation will overwrite the configuration at $url"
		
		if ($result -eq $true) {
			loadMDDNavigation $spWeb $newNav
		}
		else {
			write-host "Operation cancelled"
			write-host ""
		}
	}
}
