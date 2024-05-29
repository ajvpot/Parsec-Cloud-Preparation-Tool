# Define the path to the CodeMeter executable
$codeMeterPath = "C:\Program Files (x86)\CodeMeter\Runtime\bin\cmu32.exe"

# Check if the CodeMeter executable exists
if (-Not (Test-Path $codeMeterPath)) {
    Write-Error "CodeMeter executable not found at $codeMeterPath"
    exit 1
}

# Define the script to release all CodeMeter licenses
$releaseLicensesScript = @"
\$licenses = & '$codeMeterPath' --list | Select-String -Pattern 'Serial Number: (\d+)' | ForEach-Object { \$_ -match 'Serial Number: (\d+)' ; \$matches[1] }
foreach (\$serial in \$licenses) {
    & '$codeMeterPath' --delete-cmcloud-credentials --serial \$serial
}
"@

# Define the path to the shutdown script file in the GPO scripts directory
$gpoScriptsPath = "C:\Windows\System32\GroupPolicy\Machine\Scripts\Shutdown"
$shutdownScriptPath = "$gpoScriptsPath\ReleaseCodeMeterLicenses.ps1"

# Ensure the GPO scripts directory exists
if (-Not (Test-Path $gpoScriptsPath)) {
    New-Item -Path $gpoScriptsPath -ItemType Directory -Force
}

# Write the release licenses script to the shutdown script file
Set-Content -Path $shutdownScriptPath -Value $releaseLicensesScript

# Define the path to the GPO shutdown scripts configuration file
$shutdownScriptsIniPath = "C:\Windows\System32\GroupPolicy\Machine\Scripts\scripts.ini"

# Ensure the GPO shutdown scripts configuration file exists
if (-Not (Test-Path $shutdownScriptsIniPath)) {
    New-Item -Path $shutdownScriptsIniPath -ItemType File -Force
}

# Add the shutdown script to the GPO configuration
$shutdownScriptsIniContent = @"
[Shutdown]
0CmdLine=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File `"$shutdownScriptPath`"
0Parameters=
"@

Set-Content -Path $shutdownScriptsIniPath -Value $shutdownScriptsIniContent

Write-Output "Shutdown script to release CodeMeter licenses has been configured successfully."
