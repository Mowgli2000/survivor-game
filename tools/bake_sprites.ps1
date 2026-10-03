# Bakes the sprite atlas and the arena art from the drawn SVGs (assets_src/drawn/,
# regenerate with python tools/art/make_sprites.py and tools/art/make_map.py).
# Usage: powershell -ExecutionPolicy Bypass -File tools/bake_sprites.ps1
# Override the Godot path with the GODOT_BIN environment variable.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$godot = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "C:\Program Files\Godot\Godot.exe" }
New-Item -ItemType Directory -Force "$root\assets\sprites" | Out-Null
$steps = @(
    @("-s", "res://tools/sprites/bake_sprites.gd", "--", "--phase=images"),
    @("-s", "res://tools/art/bake_map.gd", "--", "--phase=images"),
    @("--import"),
    @("-s", "res://tools/sprites/bake_sprites.gd", "--", "--phase=resources"),
    @("-s", "res://tools/art/bake_map.gd", "--", "--phase=resources")
)
foreach ($step in $steps) {
    $p = Start-Process -FilePath $godot -ArgumentList (@("--headless", "--path", "`"$root`"") + $step) -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -ne 0) {
        Write-Host "bake_sprites failed at: $step" -ForegroundColor Red
        exit $p.ExitCode
    }
}
Write-Host "Sprites baked." -ForegroundColor Green
