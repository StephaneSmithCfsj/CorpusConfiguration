
 function sql($sqlText, $database = "master", $server = ".")
{

#    $connection = new-object System.Data.SqlClient.SQLConnection("Data Source=$server;Integrated Security=SSPI;Initial Catalog=$database");

    $connection = new-object System.Data.SqlClient.SQLConnection("Data Source=$server;Integrated Security=falsel;Integrated Security=False;User Id=cfsj_datareader;Password=Cf5j5ql!;Initial Catalog=$database");
    $cmd = new-object System.Data.SqlClient.SqlCommand($sqlText, $connection);

    $connection.Open();
    $reader = $cmd.ExecuteReader()

    $results = @()
    while ($reader.Read())
    {

        $fileStream = New-Object System.IO.FileStream ($Dest + $reader.GetString(0)), Create, Write            

        $binaryWriter = New-Object System.IO.BinaryWriter $fileStream            
               
        $start = 0            

        $received = $reader.GetBytes(1, $start, $out, 0, $bufferSize - 1)            
       #$photo = [byte[]](Get-Content "C:\temp\crusoe.jpg" -Encoding byte)            
         Set-ADUser sp16_install -Replace @{thumbnailPhoto= $received}
        While ($received -gt 0)            
        {            
            $binaryWriter.Write($out, 0, $received)            
            $binaryWriter.Flush()            
            $start += $received            
            $received = $reader.GetBytes(1, $start, $out, 0, $bufferSize - 1)            
         }   
         
        
         
            
        $binaryWriter.Close()    

        
        $fileStream.Close()    




        $row = @{}
        for ($i = 0; $i -lt $reader.FieldCount; $i++)
        {


            $row[$reader.GetName($i)] = $reader.GetValue($i)

###Extract-picture

  



        }
        $results += new-object psobject -property $row            
    }
    $connection.Close();

    $results
}

##import-module ActiveDirectory 
 
#Set the domain to search at the Server parameter. Run powershell as a user with privilieges in that domain to pass different credentials to the command. 
#Searchbase is the OU you want to search. By default the command will also search all subOU's. To change this behaviour, change the searchscope parameter. Possible values: Base, onelevel, subtree 
#Ignore the filter and properties parameters 
 
$SearchBase = "OU=ti,OU=Users,OU=CFSJ,DC=cfsj,DC=qc,DC=ca"


#Get Admin accountb credential

#$GetAdminact = Get-Credential

#Define variable for a server with AD web services installed

$ADServer = 'CFSJDC3'

#Find users that are not disabled
#To test, I moved the following users to the OU=ADMigration:
#Philip Steventon (kingston.gov.uk/RBK Users/ICT Staff/Philip Steventon) - Disabled account
#Joseph Martins (kingston.gov.uk/RBK Users/ICT Staff/Joseph Martins) - Disabled account
#may have to get accountb status with another AD object

#Define "Account Status" 
#Added the Where-Object clause on 23/07/2014
#Requested by the project team. This 'flag field' needs
#updated in the import script when users fields are updated
#The word 'Migrated' is added in the Notes field, on the Telephone tab.
#The LDAB object name for Notes is 'info'. 





#$AllADUsers = Get-ADUser -server $ADServer -Filter * -Properties enabled,title,description,DisplayName,department,lastlogondate,manager,telephoneNumber,DistinguishedName,Company | Where-Object {$_.Company -eq 'CFSJ'} #ensures that updated users are never exported.

# Create a byte array for the stream.            
$out = [array]::CreateInstance('Byte', $bufferSize) 


 #Import-Module "sqlps" -DisableNameChecking#
 $SQLQueryTxt= 'SELECT top 5 Filename, Picture FROM          [vCFSJ_AlbumEmployeExport]'
 $databasetxt='SALTO_RW'
 $ServerTxt='CFSJSQL3'

 $Dest = "e:\Export\"             
 $bufferSize = 8192       


    sql -sqlText $SQLQueryTxt -database $databasetxt -server $ServerTxt

