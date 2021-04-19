# $username = "digital\otmmdevautomation"
# $password = ConvertTo-SecureString "Jopu1467" -AsPlainText -Force
# $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

Write-Host "Getting OTMM Service Status"
$svc = Get-Service OpenTextMediaManagementService
$svc 
if($svc.Status -eq 'Running'){
    Write-Host "OTMM Service is running! Stopping OTMM"
    Start-Job -Name "OTMM-SVC-STOP" -ScriptBlock { Stop-Service OpenTextMediaManagementService -Force }

    $timeout = 300
    $interval = 10
    $timespan = new-timespan -Seconds $timeout
    $sw = [diagnostics.stopwatch]::StartNew()
    while ($sw.elapsed -lt $timespan){
        $secs = [math]::Round($sw.elapsed.TotalSeconds,0)
        Write-Host "$secs seconds have passed!"
        $OTMM = Receive-Job -Name "OTMM-SVC-STOP"
        if($OTMM.Status -eq "Stopped"){
            Remove-Job -Name "OTMM-SVC-STOP" -Force
            Write-Host "Details for stopped OTMM Service"
            $sw.elapsed
            Exit 0
        }
        start-sleep -seconds $interval
    }

    $secs = [math]::Round($sw.elapsed.TotalSeconds,0)
    if($secs -ge $timeout){
        Write-Host "The $timeout second timeout has has not been met"
        Remove-Job -Name "OTMM-SVC-STOP" -Force
        Get-Service OpenTextMediaManagementService 
        Write-Host "Service is either Stopping or StopPending. Force killing process!"
        $Services = Get-WmiObject -Class win32_service -Filter "state = 'stop pending'"
        if ($Services) {
            foreach ($service in $Services) {
                if($service.Name -eq "OpenTextMediaManagementService"){
                    $service
                    Stop-Process -Id $service.processid -Force -PassThru -ErrorAction Stop
                    Exit 0
                }
            }
        }
    }
}