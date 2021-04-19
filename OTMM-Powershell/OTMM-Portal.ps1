Write-Host "OTMM-Portal Deployment Started onto $env:COMPUTERNAME"
       
Remove-Item –path "E:\TomEE\webapps\sobeyscustomotmmportal*" –Recurse -Force -ErrorAction Ignore 
Copy-Item -Path "$env:System_DefaultWorkingDirectory\_OTMM-PORTAL\OTMM-Portal\*.war" -Destination "E:\TomEE\webapps\" -Verbose -Force