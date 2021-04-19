param(  
[Parameter(Mandatory=$true)]
[String]$usrAcct,
[Parameter(Mandatory=$true)]
[String]$usrAcctPwd,
[Parameter(Mandatory=$true)]
[String]$vmFullName1,
[Parameter(Mandatory=$true)]
[String]$vmFullName2,
[Parameter(Mandatory=$true)]
[String]$vmFullName3,
[Parameter(Mandatory=$true)]
[String]$envType,
[Parameter(Mandatory=$true)]
[Int]$noNodes
)

$password = ConvertTo-SecureString $usrAcctPwd -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential($usrAcct,$password)
$s1,$s2,$s3 = New-PSSession -ComputerName $vmFullName1,$vmFullName2,$vmFullName3 -Credential $creds

function Restart-Services(){
   Invoke-Command -Session $s1,$s2,$s3 -ScriptBlock {
      param(
         $solrVersion = "7.2.1",
         $nssmVersion = "2.24",
         $zkVer = "3.4.14",
         $installFolder = "E:"
      )

      Write-Host "Setting Up Services!"

      $solrName = "solr-$solrVersion"
      $zkName = "zk-$zkVer"

      $solrRoot = "$installFolder\$solrName"
      $zkRoot = "$installFolder\$zkName"

      $svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
      if($svc.Status -eq 'Running'){
         Stop-Service $solrName
      }

      $svc = Get-Service $zkName -ErrorAction SilentlyContinue
      if($svc.Status -eq 'Running'){
         Stop-Service $zkName
      }
      if(!($svc)){
         Write-Host "Installing Zk service"
         &"$installFolder\nssm-$nssmVersion\win64\nssm.exe" install "$zkName" "$zkRoot\bin\zkServer.cmd" 
         $svc = Get-Service "$zkName" -ErrorAction SilentlyContinue

         Write-Host "Changing Zk Startup Directory"
         &"$installFolder\nssm-$nssmVersion\win64\nssm.exe" set "$zkName" "AppDirectory" "$zkRoot\bin"
      }
      $svc = Get-Service $zkName -ErrorAction SilentlyContinue
      if($svc.Status -ne "Running"){
         Write-Host "Starting Zookeper service"
         Start-Service "$zkName"
      }

      Write-Host "Waiting six seconds to start Solr Service"
      Start-Sleep -s 6  

      $svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
      if(!($svc)){
         Write-Host "Installing Solr service"
         &"$installFolder\nssm-$nssmVersion\win64\nssm.exe" install "$solrName" "$solrRoot\startSolr.bat" 
         $svc = Get-Service "$solrName" -ErrorAction SilentlyContinue

         Write-Host "Changing Solr Startup Directory"
         &"$installFolder\nssm-$nssmVersion\win64\nssm.exe" set "$solrName" "AppDirectory" "$solrRoot"
      }

      if($svc.Status -ne "Running"){
         Write-Host "Starting Solr service"
         Start-Service "$solrName"
      }

   }

}

function LiveNodes(){
   Write-Host "Waiting 10 seconds to ensure nodes are up"
   Start-Sleep -s 10
   for($i=1; $i -le $noNodes; $i++){
      $u = Invoke-WebRequest -Uri "https://app1721-$envType-km-solr-vm$i.xyz/solr/admin/zookeeper?detail=true&path=%2Flive_nodes" -UseBasicParsing
      if($u.StatusCode -ne 200){
         Write-Host "Solr VM $i Returns a non 200 Status Code"
         Exit 1
      }else{
         Write-Host "Solr VM $i has a 200 Status Code"
      }
   }
   
   Write-Host "Checking out Solr LB"
   $u = Invoke-WebRequest -Uri "https://app1721-$envType-km-solr.xyz/solr/admin/zookeeper?detail=true&path=%2Flive_nodes&fmt=json" -UseBasicParsing
   if($u.StatusCode -ne 200){
      Write-Host "Solr LB Returns a non 200 Status Code"
      Exit 1
   }else{
      Write-Host "Checking for Live-Nodes"
      Write-Host "Current Setup is `n$u.Content`n"
      $val = $u.Content | ConvertFrom-Json
      if($val.znode.prop.children_count -ne $noNodes){
         Write-Host "Some Error in syncing Live-Nodes: Restarting Services on $noNodes $envType SolrCloud VMs again`n"
         Restart-Services
         LiveNodes
      }else{
         Write-Host "solrCloud is correctly setup for $noNodes VMs!"
         Get-PSSession | Remove-PSSession
         Exit 0
      }
   }
}

LiveNodes