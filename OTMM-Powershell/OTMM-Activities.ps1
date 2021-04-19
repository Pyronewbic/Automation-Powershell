Write-Host "OTMM-Activities Deployment Started onto $env:COMPUTERNAME"
    
Copy-Item -Path "$env:System_DefaultWorkingDirectory\_OTMM-ACTIVITIES\OTMM-Activities\target\*.jar" -Destination "$env:TEAMS_HOME\plugins\" -Verbose -Force
Copy-Item -Path "$env:System_DefaultWorkingDirectory\_OTMM-ACTIVITIES\OTMM-Activities\src\main\resources\*.xml" -Destination "$env:TEAMS_HOME\data\jobs\custom" -Verbose -Force
Copy-Item -Path "$env:System_DefaultWorkingDirectory\_OTMM-ACTIVITIES\OTMM-Activities\src\main\resources\workflowUIMenuDisplayCode\cs-custombatchwf*" -Destination "$env:TEAMS_HOME\ear\artesia\otmmux\ux-html\" -Verbose -Force

Set-Location -Path "E:\MediaManagement\install\ant"
ant deploy-customizations