param (
    [string]$url,
    [string]$language = "en",
	[bool]$ConfirmPreference = $true,
    [string]$file = "mdd_nav",
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
	write-host "Mega Drop Down Navigation Export Utility"
	write-host "----------------------------------------"
	write-host ""
	write-host "    Exports the Mega Drop Down navigation configuration from a SharePoint site to a text file."
	write-host ""
	write-host "USAGE"
	write-host ""
	write-host "    getNav -Url <site url> [-StartMenu <name of menu instance>] [-Language <two-letter language code>] [-File <export filename>] -Confirm [true | false]"
	write-host ""
	write-host "DESCRIPTION"
	write-host ""
	write-host "    getNav exports navigation that is used by Mega Drop Down for SharePoint 2013."
	write-host "    The contents of the navigation is exported to a text file and the default export filename is mdd_nav.txt"
	write-host ""
	write-host "    The Url parameter should be a fully qualified URL to the site where navigation should be exported."
	write-host ""
	write-host "    The (optional) Language parameter specifies the language that should be used for exporting navigation."
	write-host "    The value should be specified in the ISO 639-1 format.   Example: de for German, nl for Dutch, fr for French"
	write-host ""
	write-host "    The (optional) File parameter specifies the name of the output file."
	write-host ""
	write-host "    The (optional) StartMenu parameter specifies the unique menu ID when using multiple Mega Drop Down controls in the same master page."
	write-host "    The value of this parameter is the value you are using in the <sparch:menu StartMenu='' /> declaration."
	write-host ""
	write-host "    The (optional) Confirm parameter determines if confirmation prompts should be suppressed.  Example:  -confirm:$true"
	write-host ""
	write-host "EXAMPLES"
	write-host ""
	write-host "    .\getNav.ps1 -Url http://portal.example.com"
	write-host "    Exports the navigation for the default language to a text file using the default filename mdd_nav.txt"
	write-host ""
	write-host "    .\getNav.ps1 -Url http://portal.example.com -StartMenu leftnav"
	write-host "    Exports the navigation for the menu defined as 'leftnav' in the default language to a text file using the default filename mdd_nav.txt"
	write-host ""
	write-host "    .\getNav.ps1 -Url http://portal.example.com -File myimport.txt"
	write-host "    Exports the navigation for the default language to a text file nameed myexport.txt"
	write-host ""
	write-host "    .\getNav.ps1 -Url http://portal.example.com -Language de"
	write-host "    Exports the navigation for German to the file mdd_nav.txt"
	write-host ""
	write-host "    .\getNav.ps1 -Url http://portal.example.com -Action remove"
	write-host "    Removes the navigation at the site http://portal.example.com"
	write-host ""
	exit;
}

function getMDDNavigation($spWeb) {
	Write-Host "Exporting Mega Drop Down Menu configuration..."

	If (Test-Path $ofn){
		$result = confirm "$ofn already exists.  Do you want overwrite this file?"
		
		if ($result -eq $true) {
			Remove-Item $ofn
		}
		else 
		{
			write-host ""
			write-host "Operation aborted."
			write-host ""
			Exit;
		}
	}
	
	if ($spWeb.AllProperties.ContainsKey($key)) {
	
		$nav = $spWeb.AllProperties[$key]
		
		$nav >> $ofn

		write-host ""
		Write-Host "Navigation exported successfully."
		}
	else {
		write-host -f Red "Navigation not found";
	}

	write-host ""
	
}

function confirm($mesg) {
	if ($ConfirmPreference -eq $true) {
		write-host ""
		write-host $mesg
		write-host -foregroundcolor yellow -nonewline "[Y] Yes "
		write-host -foregroundcolor white -nonewline "[N] No " 
		$key = read-host "(default is 'N')"
		
		if ($key.ToLower() -eq "y") {
			return $true;
		}
		
		if ($key.ToLower() -eq "q") {
			exit
		}

		return $false;
	}
	
	return $true;
}

$key = "sparch.mdd.3.0.0.0"
$nav = ""
$pat = "[{0}]" -f ([Regex]::Escape( [System.IO.Path]::GetInvalidFileNameChars() -join '' ))

$curDir = Split-Path -parent $MyInvocation.MyCommand.Definition

$ofn = $curDir + "\" + ([io.fileinfo]$file).basename;

if ($StartMenu) {
	$ofn += "." + $StartMenu
}

if ( ($language) -and ($language -ne "en")){
	$ofn += "." + $language
}

$ofn += ".txt"

$bad = $file -match $pat

if (!$url) {displayHelp ""}
if ($url.contains("http") -eq $false) { displayHelp "-url parameter is required"}
if ($language.length -ne 2) { displayHelp "-language parameter should be in two-letter format (e.g. de for German, fr for French, nl for Dutch " }
if ($bad) { displayHelp "-file parameter contains invalid characters: '$($matches[0])'" }

if ($language) {
	if ($language -ne "en") {
		$key += "." + $language
	}
}

if ($StartMenu) {
	$key += "." + $StartMenu;
}

$spWeb = get-SPWeb $url

write-host ""
write-host "Exporting Navigation from $($url)"

if ($language) {
	write-host "Language: " $language
}

if ($StartMenu) {
	write-host "StartMenu: " $StartMenu
}

write-host "Export File: $ofn"
write-host ""

#$result = confirm "Would you like to continue with navigation export?"
		
#if ($result -eq $true) {
	getMDDNavigation $spWeb
#}
