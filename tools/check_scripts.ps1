# Compiles every GDScript in src/ and tests/ without running the game.
# Usage: powershell -ExecutionPolicy Bypass -File tools/check_scripts.ps1
# Override the Godot path with the GODOT_BIN environment variable.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$godot = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "C:\Program Files\Godot\Godot.exe" }

# Import first so new class_name scripts are registered.
$import = Start-Process -FilePath $godot -ArgumentList "--headless", "--path", "`"$root`"", "--import" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\godot_import.log"
if ($import.ExitCode -ne 0) {
    Write-Host "Import failed (exit $($import.ExitCode))" -ForegroundColor Red
    exit $import.ExitCode
}
$proc = Start-Process -FilePath $godot -ArgumentList "--headless", "--path", "`"$root`"", "-s", "res://tools/check_scripts.gd" -NoNewWindow -Wait -PassThru
exit $proc.ExitCode
