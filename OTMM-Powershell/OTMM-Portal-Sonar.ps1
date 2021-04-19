$sonarToken = $env:SONARTOKEN
$sonarUrl = $env:SONARURL
$token = [System.Text.Encoding]::UTF8.GetBytes("${sonarToken}:")
$base64 = [System.Convert]::ToBase64String($token)
$basicAuth = [string]::Format("Basic {0}", $base64)
$headers = @{ Authorization = $basicAuth }

if($env:RUNSONAR -eq "TRUE"){
        Write-Host "Running Sonar Scanner against compiled artifacts (_OTMM-Portal-Sonar)"
        Set-Location -Path "$env:System_DefaultWorkingDirectory\_OTMM-PORTAL\OTMM-Portal-Sonar"
        sonar-scanner
        Write-Host "Sleeping for 15 seconds to generate Sonar Reports"
        Start-Sleep -s 15
        $url = "$sonarUrl/api/qualitygates/project_status?projectKey=edam:sobeysotmmportal"
        $u = Invoke-RestMethod -Uri $url -Headers $headers
        $u.projectStatus.status
        $u.projectStatus.conditions
        if($u.projectStatus.status -eq "ERROR"){
            Write-Host "SobeysOtmmPortal has not passed the Quality Gates!"
            # Exit 1
        }else{
            Write-Host "SobeysOtmmPortal has passed the Quality Gates!"
        }
}