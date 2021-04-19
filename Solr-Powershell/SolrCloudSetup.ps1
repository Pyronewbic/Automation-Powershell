param(
    [Parameter(Mandatory=$true)]
    [Int]$noNode,
    [Parameter(Mandatory=$true)]
    [Int]$curNode,
    [Parameter(Mandatory=$true)]
    [Int]$zkInitLimit,
    [Parameter(Mandatory=$true)]
    [Int]$zkSyncLimit,
    [Parameter(Mandatory=$true)]
    [String]$certPass,
    [Parameter(Mandatory=$true)]
    [String]$envType,
    $jdkVer = "11.0.3",
    $solrVersion = "7.2.1",
    $nssmVersion = "2.24",
    $zkVer = "3.4.14",
    $installFolder = "E:",
    $zkPort = "8080",
    $solrPort = "443"
)

# Directory Details
$solrName = "solr-$solrVersion"
$zkName = "zk-$zkVer"

$tempFolder = "$installFolder\temp"
$7zipPackage = "$tempFolder\7zip.msi"
$jdk64Package = "$tempFolder\jdk-$jdkVer.exe"
$solrPackage = "$tempFolder\$solrName.zip"
$nssmPackage = "$tempFolder\nssm-$nssmVersion.zip"
$zkPackage = "$tempFolder\zookeeper$zkVer.tar.gz"
$certPath = "$tempFolder\cert.pfx"

$7zipRoot = "$installFolder\7-zip"
$jdk64Root= "$installFolder\Java\x64\jdk$jdkVer"
$jre64Root= "$installFolder\Java\x64\jre$jdkVer"
$solrRoot = "$installFolder\$solrName"
$nssmRoot = "$installFolder\nssm-$nssmVersion"
$zkRoot = "$installFolder\$zkName"

# Blob Urls
$jdk64Url = "https://xyz.blob.core.windows.net/app1721kmpkgs/packages/jdk-${jdkVer}_windows-x64_bin.exe?st=2019-05-08T08%3A43%3A06Z&se=2019-07-31T08%3A43%3A00Z&sp=rl&sv=2018-03-28&sr=b&sig=dxjhqBHScYXD53VtL1ooQCoiV50ysp6VaNPUZovC0So%3D"
$7zipUrl = "https://xyz.blob.core.windows.net/app1721kmpkgs/packages/7zip.msi?st=2019-05-08T07%3A56%3A00Z&se=2019-07-05T07%3A56%3A00Z&sp=rl&sv=2018-03-28&sr=b&sig=adCk5mR17ZxCloYpDKJsMp8A27OPhIicljCb4sKB5js%3D"
$zkUrl = "https://xyz.blob.core.windows.net/app1721kmpkgs/packages/zookeeper-$zkVer.tar.gz?st=2019-05-08T08%3A56%3A42Z&se=2019-07-31T08%3A56%3A00Z&sp=rl&sv=2018-03-28&sr=b&sig=dWKNfj8JNEpC1RSiX%2FkMSHy6KLdxP6WRHjLWjlfWYZ0%3D"
$solrUrl = "https://xyz.blob.core.windows.net/app1721kmpkgs/packages/${solrName}.zip?st=2019-05-08T08%3A55%3A50Z&se=2019-07-31T08%3A55%3A00Z&sp=rl&sv=2018-03-28&sr=b&sig=zO0zg34MSCmZe13Waa0fKIjUd6UiveeD%2F8Qt%2FZ3q42M%3D"
$nssmUrl = "https://xyz.blob.core.windows.net/app1721kmpkgs/packages/nssm-$nssmVersion.zip?st=2019-05-08T08%3A54%3A44Z&se=2019-07-31T08%3A54%3A00Z&sp=rl&sv=2018-03-28&sr=b&sig=dXBES%2FA1Sf6YI255z4ZXTWsZAiAb%2BryDtIUATjIAb4w%3D"
$certUrl = "https://xyz.blob.core.windows.net/app1721kmpkgs/resources/solr_cert.pfx?st=2019-05-09T07%3A33%3A03Z&se=2019-08-31T07%3A33%3A00Z&sp=rl&sv=2018-03-28&sr=b&sig=cRFN8kSXtU4pOgOGnO7pxLNch1QiDqNp%2FOW39Ca5dcs%3D"

try{
# Check for Admin
$elevated = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
if($elevated -eq $false)
{
    throw "In order to install Services, run this script with elevated permissions"
}

if (!(Test-Path $tempFolder)) {
    Write-Host "Creating Temp Directory $tempFolder"
    mkdir $tempFolder
}

if (!(Test-Path $installFolder)) {
    Write-Host "Creating Temp Directory $installFolder"
    mkdir $installFolder
}
# Install Java 
Write-Host "Checking if Java is already installed"
if ((Test-Path "$jdk64Root")) {
    Write-Host "No need to Install Java"
}else{
    Write-Host "Downloading x64 to $jdk64Package"
    Start-BitsTransfer -Source $jdk64Url -Destination $jdk64Package
    if (!(Test-Path $jdk64Package)) {
        Write-Host "Downloading JDK-x64 failed"
    }

    Write-Host "Installing JDK-x64"
    $jdk64Install = Start-Process -FilePath $jdk64Package -ArgumentList "/s INSTALLDIR=$jdk64Root /INSTALLDIRPUBJRE=$jre64Root" -Wait -PassThru
    $jdk64Install.WaitForExit()
    if($jdk64Install.ExitCode -ne 0){
        Throw "$jdk64Package install failed"
    }

    Write-Host "JDK-x64 Installation Done"
 
    if (Test-Path "$jdk64Root") {
        Write-Host "Java installed successfully"
    }

    Write-Host "Setting up Path variables."
    [System.Environment]::SetEnvironmentVariable("JAVA_HOME", "$jdk64Root", "Machine")
    [System.Environment]::SetEnvironmentVariable("PATH", $env:Path + ";$jdk64Root\bin", "Machine")

    Write-Host "JAVA_HOME is $env:JAVA_HOME"
    Write-Host "PATH is $env:PATH`n"
    
    java -version
}

# Install Zookeper
Write-Host "Checking if Zookeper is already Installed"
if ((Test-Path "$zkRoot")) {
    Write-Host "No need to Install Zookeper"
}else{
    Write-Host "Checking if 7-zip is already Installed" 
    if (!(Test-Path $7zipRoot)) {
        Start-BitsTransfer -Source $7zipUrl -Destination $7zipPackage
        $7zipInstall = Start-Process -FilePath $7zipPackage -ArgumentList "/q INSTALLDIR=$7zipRoot" -Wait -PassThru
        $7zipInstall.WaitForExit()
        if($7zipInstall.ExitCode -ne 0){
            Throw "$7zipPackage install failed"
        }

        Write-Host "7zip installed to $7zipRoot"
    }else{
        Write-Host "7zip is already installed"
    }

    Write-Host "Checking if Zookeeper is already Installed" 
    if (!(Test-Path $zkRoot)) {
    Write-Host "Downloading zookeeper-$zkVer tar.gz"
    Start-BitsTransfer -Source $zkUrl -Destination $zkPackage

    &"$7zipRoot\7z.exe" "x" "$zkPackage" "-o$tempFolder\zookeeper$zkVer"
    &"$7zipRoot\7z.exe" "x" "$tempFolder\zookeeper$zkVer\zookeeper$zkVer.tar" "-o$tempFolder\zk$zkVer"

    Move-Item -Path "$tempFolder\zk$zkVer\zookeeper-$zkVer" -Destination $zkRoot
    Write-Host "Zookeeper Installed to $zkRoot"
    }
    else{
        Write-Host "Zookeeper Installed to $zkRoot"
    }
}

$servString = "" 
for($i=1; $i -le $noNode; $i++){
    $servString = $servString + "server$i=app1721-$envType-km-solr-vm$i.tax.deloitteresources.com:2888:3888`n"
}

Write-Host "Writing $zkRoot\conf\zoo.cfg"

Set-Content -Path "$zkRoot\conf\zoo.cfg" -Value "#The number of milliseconds of each tick 
tickTime=2000 
# The number of ticks that the initial  synchronization phase can take 
initLimit=$zkInitLimit 
# The number of ticks that can pass between sending a request and getting an acknowledgement 
syncLimit=$zkSyncLimit
# the directory where the snapshot is stored. 
dataDir=$installFolder/$zkName/data 
# the port at which the clients will connect 
clientPort=$zkPort 
# the maximum number of client connections. 
# increase this if you need to handle more clients 
#maxClientCnxns=60 
# 
# Be sure to read the maintenance section of the administrator guide before turning on autopurge. 
# 
# http://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_maintenance 
# 
# The number of snapshots to retain in dataDir 
#autopurge.snapRetainCount=3 
# Purge task interval in hours 
# Set to 0 to disable auto purge feature 
#autopurge.purgeInterval=1 
$servString"

mkdir "$zkRoot\data"

Set-Content -Path "$zkRoot\data\myid" -Value $curNode

#Solr
Write-Host "Checking if Solr is already installed"
if ((Test-Path "$solrRoot")) {
    Write-Host "No need to Install Solr"
}else{
    Start-BitsTransfer -Source $solrUrl -Destination $solrPackage

    Write-Host "Extracting $solrName to $solrRoot"
    Expand-Archive $solrPackage -DestinationPath "$installFolder\"
}

# Import Cert
Start-BitsTransfer -Source $certUrl -Destination $certPath
$certPassSec = ConvertTo-SecureString $certPass -AsPlainText -Force
Import-PfxCertificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\My -Password $certPassSec

Write-Host "Rewriting solr config"
$zkString = ""
for($i=1; $i -le $noNode; $i++){
    if($i -ne $noNode){
        $zkString = $zkString + "app1721-$envType-km-solr-vm$i.tax.deloitteresources.com:$zkPort,"
    }
    else{
        $zkString = $zkString + "app1721-$envType-km-solr-vm$i.tax.deloitteresources.com:$zkPort"
    } 
}   

$solrHost = "app1721-$envType-km-solr-vm$curNode.tax.deloitteresources.com"

Write-Host "Copying $certPath to $solrRoot\server\etc\cert.pfx"
Copy-Item $certPath "$solrRoot\server\etc\cert.pfx" 

Write-Host "Copying Modified solr.cmd"
Remove-Item -Path "$solrRoot\bin\solr.cmd"
Copy-Item $PSScriptRoot\solr.cmd "$solrRoot\bin\solr.cmd"

Write-Host "Making Changes to solr.in.cmd"
Rename-Item "$solrRoot\bin\solr.in.cmd" "$solrRoot\bin\solr.in.cmd.old"
$cfg = Get-Content "$solrRoot\bin\solr.in.cmd.old"
$newCfg = $cfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=$solrRoot\server\etc\cert.pfx" }
$newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", "set SOLR_SSL_KEY_STORE_PASSWORD=$certPass" }
$newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE_TYPE=JKS", "set SOLR_SSL_KEY_STORE_TYPE=PKCS12" }
$newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_ENABLED=true", "set SOLR_SSL_ENABLED=true" }
$newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=$solrRoot\server\etc\cert.pfx" }
$newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", "set SOLR_SSL_TRUST_STORE_PASSWORD=$certPass" }
$newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE_TYPE=JKS", "set SOLR_SSL_TRUST_STORE_TYPE=PKCS12" }
$newCfg = $newCfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$solrHost" }
$newCfg = $newCfg | % { $_ -replace "REM set ZK_HOST=", "set ZK_HOST=$zkString" }
$newCfg = $newCfg | % { $_ -replace "REM set SOLR_JAVA_MEM=-Xms512m -Xmx512m", "set SOLR_JAVA_MEM=-Xms8g -Xmx8g" }
$newCfg | Set-Content "$solrRoot\bin\solr.in.cmd"

Set-Content "$solrRoot\startSolr.bat" -Value "$solrRoot\bin\solr.cmd start -f -p $solrPort -cloud"

#Nssm
Write-Host "Checking if Nssm is already installed"
if ((Test-Path "$nssmRoot")) {
    Write-Host "No need to Install Nssm"
}else{
    Start-BitsTransfer -Source $nssmUrl -Destination $nssmPackage
    
    Write-Host "Extracting nssm-$nssmVersion to $nssmRoot"
    Expand-Archive $nssmPackage -DestinationPath "$installFolder\"
}

Write-Host "Cleaning Leftover Files and Packages from $tempFolder"
Remove-Item -Recurse -Force $tempFolder
}
catch 
{
	Write-Error $_.Exception.Message
	Break 
}