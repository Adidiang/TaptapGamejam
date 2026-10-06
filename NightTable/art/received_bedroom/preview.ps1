$projectPath = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$enginePath = Join-Path $projectPath '../Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe'
& $enginePath --path $projectPath --rendering-method forward_plus 'res://art/received_bedroom/bedroom.tscn'
