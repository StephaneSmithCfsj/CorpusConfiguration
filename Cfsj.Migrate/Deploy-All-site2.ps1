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
    [PSCredential]$Cred,

    [Parameter(Mandatory = $true, HelpMessage="Optional execution mode  credentials")][ValidateSet("true","false")]
    [string]$DebugModeSting="true"
)



begin{

    Import-Module Sharegate
    $oldTargetSiteUrl=""
    $AllsiteFileMigrate="./Load Data/AllSite-DataMigrate.txt"
    $AllsiteFileDelete="./Load Data/AllSite-DataDelete.txt"
    
    $debugMode = $false
    switch($DebugModeSting.ToLower()){
    "true"{$debugMode=$true}
    default {$debugMode=$false}
    }
    
    #Load Array of Association for Site migration

    $ArrSC = @{}
    Get-Content     $AllsiteFileMigrate | ? { ($_ -like '*=*') -and ($_[0] -ne '#') } | % {
      $key, $value = $_ -split '\s*=\s*', 2
      $ArrSC[$key] = $value
    }


    $ArrSCDelete = @{}
    Get-Content     $AllsiteFileDelete | ? { ($_ -like '*=*') -and ($_[0] -ne '#') } | % {
     $key, $value = $_ -split '\s*=\s*', 2
      $ArrSCDelete[$key] = $value
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
    Write-Host -ForegroundColor White "|   Migrating data                                     |"
    if ($debugMode)  {    Write-Host -ForegroundColor red "|   ****************DEBUG MODE ON                      |"}

    Write-Host -ForegroundColor White "--------------------------------------------------------"
    if (-not ($debugMode))  {}
    Write-Host -ForegroundColor Yellow "Main Content Target Site : $targetSiteUrl"

    try
    {
        foreach($i in $ArrSC.GetEnumerator())
        {
            write-host "$($i.Name):$($i.Value -replace "%site%",$targetSiteUrl )"
            try
            {
                Connect-SPOnline  -Url $($i.Value -replace "%site%",$targetSiteUrl) -Credentials $cred

                $srcSite = Connect-Site -Url $($i.Name)
                $dstSite = Connect-Site -Url $($i.Value -replace "%site%",$targetSiteUrl)

                if (-not ($debugMode)) {Copy-Site -Site $srcSite -DestinationSite $dstSite -Merge -Subsites -InsaneMode }

            }
            Catch
            {
                write-host -ForegroundColor Red " no site destination found: $($i.Value -replace "%site%",$targetSiteUrl )"
            }            
        }
        Write-Host -ForegroundColor Green "Migrating Data deployment succeeded"

        foreach($i in $ArrSCDelete.GetEnumerator())
        {
            write-host "----- Connecting to  $($i.Value -replace "%site%",$targetSiteUrl)"
            try
            {
                Connect-SPOnline  -Url $($i.Value -replace "%site%",$targetSiteUrl) -Credentials $cred

            #Getall Subweb and find the subSite to remove
                write-host "   Try removing Site to  $($i.Name -replace "%site%",$targetSiteUrl )"
                $SiteName = Get-SPOSubWebs| where-Object {$_.url -eq $($i.Name -replace "%site%",$targetSiteUrl)}| Select-Object ID,Title
            
                if($SiteName.id) {
                    if (-not ($debugMode)) {RemoveSubWebRecurse -webIdentity $SiteName.ID}
                }
                else
                {
                    Write-Host -ForegroundColor Red "   No WEB to remove($($i.Name -replace "%site%",$targetSiteUrl ))"
                }
            Disconnect-SPOnline
            }
            catch
            {
                write-host -ForegroundColor Red " *****  Unable to remove Site $($i.Name -replace "%site%",$targetSiteUrl )"                
                Write-Host -ForegroundColor Red "Exception occurred!" 
                Write-Host -ForegroundColor Red "Exception Type: $($_.Exception.GetType().FullName)"
                Write-Host -ForegroundColor Red "Exception Message: $($_.Exception.Message)"
            }
            
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