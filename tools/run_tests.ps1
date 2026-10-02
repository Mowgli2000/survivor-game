# Runs the whole GUT test suite headless.
# Usage: powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1
# Override the Godot path with the GODOT_BIN environment variable.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$godot = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "C:\Program Files\Godot\Godot.exe" }

# Import first so new assets/translations are available in a fresh clone.
$import = Start-Process -FilePath $godot -ArgumentList "--headless", "--path", "`"$root`"", "--import" -NoNewWindow -Wait -PassThru
if ($import.ExitCode -ne 0) {
    Write-Host "Import failed (exit $($import.ExitCode))" -ForegroundColor Red
    exit $import.ExitCode
}

$tests = Start-Process -FilePath $godot -ArgumentList "--headless", "--path", "`"$root`"", "-s", "res://addons/gut/gut_cmdln.gd" -NoNewWindow -Wait -PassThru
if ($tests.ExitCode -eq 0) {
    Write-Host "All tests passed." -ForegroundColor Green
} else {
    Write-Host "Tests FAILED (exit $($tests.ExitCode))" -ForegroundColor Red
}
exit $tests.ExitCode
