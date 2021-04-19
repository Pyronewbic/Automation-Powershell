$svc = Get-Service OpenTextMediaManagementService
$svc 
if($svc.Status -eq 'Stopped'){
    Write-Host "OTMM Service is not running! Starting OTMM"
    Start-Service OpenTextMediaManagementService
}
Write-Host "Sleeping for Five Seconds"
Start-Sleep -s 5
$svc = Get-Service OpenTextMediaManagementService
Write-Host "Hostname is $env:COMPUTERNAME"
if($svc.Status -eq 'Stopped'){
    Write-Host "You're in a Fix - the OpenTextMediaManagement Service is stopped and can't be started"
    Write-Host "Killing java.exe instead"
    $Processes = Get-WmiObject -Class Win32_Process -Filter "name='java.exe'"
    if($env:COMPUTERNAME -eq "DEVOTMMWEB"){
        $cmdString = '"E:\Java\jdk1.8.0_202\bin\java.exe"  "-javaagent:E:\TomEE\lib\openejb-javaagent.jar" -DTEAMS_HOME=E:\MediaManagement -Xms1024m -Xmx6144m -Djava.security.policy=../conf/java.policy -Dartesia.use_local_interfaces=Y -Dfile.encoding=UTF-8 -XX:MaxPermSize=512m -XX:+UseConcMarkSweepGC -XX:+CMSPermGenSweepingEnabled -XX:+CMSClassUnloadingEnabled -Dorg.apache.el.parser.SKIP_IDENTIFIER_CHECK=true -DTEAMS_REPOSITORY_HOME=E:\OTMM_Volumes\OTMM_Repository  "-Djdk.tls.ephemeralDHKeySize=2048" -Djava.protocol.handler.pkgs=org.apache.catalina.webresources -Dnop -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager   -classpath "E:\TomEE\bin\bootstrap.jar;E:\TomEE\bin\tomcat-juli.jar" -Dcatalina.base="E:\TomEE" -Dcatalina.home="E:\TomEE" -Djava.io.tmpdir="E:\TomEE\temp" org.apache.catalina.startup.Bootstrap  start'
        $Processes | ForEach-Object {
            if ($_.CommandLine -eq $cmdString){
                Write-Host "Dev OTMM Detected! Killing Selective Java Process"
                $_.Terminate()
                Break
            }
        }
    }else{
        Write-Host "QA/PROD VM Detected! Killing default Java Process"
        $Processes.Terminate()
    }
    Start-Service OpenTextMediaManagementService
    Start-Sleep -s 5
    Get-Service OpenTextMediaManagementService
}