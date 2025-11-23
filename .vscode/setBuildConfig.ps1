Write-Host "Select build config:"
Write-Host "1. test"
Write-Host "2. production"
$choice = Read-Host "Enter choice (1 or 2)"

if ($choice -eq "1") {
    $config = "test"
} elseif ($choice -eq "2") {
    $config = "production"
} else {
    Write-Host "Invalid choice"
    exit 1
}

$settingsPath = ".vscode\settings.json"
if (Test-Path $settingsPath) {
    $content = Get-Content $settingsPath -Raw
    $settings = $content | ConvertFrom-Json
} else {
    $settings = @{}
}

$settings | Add-Member -NotePropertyName "buildConfig" -NotePropertyValue $config -Force
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath

# Update task labels in tasks.json
$tasksPath = ".vscode\tasks.json"
if (Test-Path $tasksPath) {
    $tasksContent = Get-Content $tasksPath -Raw
    $tasks = $tasksContent | ConvertFrom-Json
    foreach ($task in $tasks.tasks) {
        if ($task.label -like "Build Config*") {
        
        # Update statusbar.label if it exists and contains #...#
        if ($task.options -and $task.options.statusbar -and $task.options.statusbar.label) {
            $statusLabel = $task.options.statusbar.label
            if ($statusLabel -match '#([^#]*)#') {
                $newLabel = $statusLabel -replace '#[^#]*#', "#$config#"
                $task.options.statusbar.label = $newLabel
            }
        }
        }
    }
    $tasks | ConvertTo-Json -Depth 10 | Set-Content $tasksPath
}

# Touch marker file to trigger CMake reconfiguration
$markerFile = "build_config_marker.txt"
Set-Content -Path $markerFile -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Write-Host "Build config set to: $config"

