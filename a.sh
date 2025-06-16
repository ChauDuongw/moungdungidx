#!/bin/bash
# curl -sL https://raw.githubusercontent.com/ChauDuongw/moungdungidx/refs/heads/main/a.sh | bash
# --- Configuration ---
$PYTHON_CODE_URL = "https://raw.githubusercontent.com/ChauDuongw/moungdungidx/refs/heads/main/tool.py"
$PYTHON_CODE_FILENAME = "a1.py"

$RUN_SCRIPT_URL = "https://raw.githubusercontent.com/ChauDuongw/moungdungidx/refs/heads/main/run_app.sh"
$RUN_SCRIPT_FILENAME = "run_app.ps1" # Changed to .ps1 for PowerShell execution

$INSTALL_DIR = (Get-Location).Path # Current directory

Write-Host "--- Starting installation and execution process ---"

# --- 1. Download Python code file ---
Write-Host "Downloading $PYTHON_CODE_URL and saving as $($INSTALL_DIR)\$PYTHON_CODE_FILENAME..."
try {
    Invoke-WebRequest -Uri $PYTHON_CODE_URL -OutFile "$($INSTALL_DIR)\$PYTHON_CODE_FILENAME"
    Write-Host "Successfully downloaded and installed $PYTHON_CODE_FILENAME."
}
catch {
    Write-Host "Error: Could not download or save $PYTHON_CODE_FILENAME. Please check the URL or write permissions." -ForegroundColor Red
    exit 1
}

# --- 2. Download the run script (converted for PowerShell) ---
Write-Host "Downloading $RUN_SCRIPT_URL and saving as $($INSTALL_DIR)\$RUN_SCRIPT_FILENAME..."

# This part is tricky: run_app.sh is a bash script.
# If run_app.sh itself contains Python execution or simple commands,
# you might be able to adapt it to PowerShell.
# For simplicity, we'll download it as is and note that it likely needs manual adaptation
# or to be executed via WSL if it's complex.
# For this example, let's assume run_app.sh can be directly translated to run_app.ps1
# or you intend to run it with a WSL call from PowerShell.

try {
    # If run_app.sh is simple, you might be able to just get its content and save it as a .ps1
    # For a direct translation of the *content* of run_app.sh to a .ps1 script:
    $bashScriptContent = Invoke-WebRequest -Uri $RUN_SCRIPT_URL -UseBasicParsing | Select-Object -ExpandProperty Content
    # You would then need to parse $bashScriptContent and convert it to PowerShell syntax
    # This is a placeholder as direct conversion is highly dependent on run_app.sh's content.
    # For demonstration, let's just save the .sh as .ps1, which won't make it directly runnable unless modified.
    $bashScriptContent | Out-File "$($INSTALL_DIR)\$RUN_SCRIPT_FILENAME"

    Write-Host "Successfully downloaded $RUN_SCRIPT_FILENAME."
}
catch {
    Write-Host "Error: Could not download or save $RUN_SCRIPT_FILENAME. Please check the URL or write permissions." -ForegroundColor Red
    exit 1
}

# PowerShell scripts (.ps1) do not require explicit execute permissions like chmod.
# However, you might need to adjust the PowerShell execution policy if you encounter issues.
# Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force # Run this once if needed

# --- 3. Execute the downloaded script (run_app.ps1) ---
Write-Host "Running $($RUN_SCRIPT_FILENAME)..."

Set-Location $INSTALL_DIR
try {
    # If run_app.sh was complex, you might need to run it via WSL from PowerShell:
    # & wsl.exe bash "./$($RUN_SCRIPT_FILENAME)"
    # Or, if run_app.ps1 was correctly rewritten from run_app.sh content:
    & ".\$($RUN_SCRIPT_FILENAME)"

    Write-Host "Successfully ran $($RUN_SCRIPT_FILENAME)."
}
catch {
    Write-Host "Error: Failed to run $($RUN_SCRIPT_FILENAME)." -ForegroundColor Red
    exit 1
}

Write-Host "--- Process complete ---"
