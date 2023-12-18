param (
    [string]$ZimmermanTools,
    [string]$InputPath,
    [string]$OutputPath
)

function Get-ToolExecutablePath {
    param (
        [string]$ToolsPath,
        [string]$ExecutableName
    )

    $exePath = Join-Path $ToolsPath $ExecutableName

    if (-not (Test-Path $exePath -PathType Leaf)) {
        Write-Host "Error: $ExecutableName not found at $exePath"
        exit 1
    }

    return $exePath
}

# Function to process Recent folders in each directory inside "$InputPath\Users"
function Process-RecentFolders {
    param (
        [string]$usersPath,
        [string]$jlecmd,
        [string]$OutputUsers
    )

    $userDirectories = Get-ChildItem -Path $usersPath -Directory

    foreach ($userDirectory in $userDirectories) {
        # Construct the full path to the Recent folder in each user directory
        $recentFolderPath = Join-Path $userDirectory.FullName "Recent"

        $outputFolder = Join-Path $OutputUsers $userDirectory.Name
        
        $jlecmd_cmd = "$jlecmd -d $recentFolderPath --csv $outputFolder"

        Write-Host "Running Jump List scan for $($userDirectory.Name)..."
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $jlecmd_cmd" -Wait

        # Output the full path to the Recent folder
        Write-Host "Recent folder path for $($userDirectory.Name): $recentFolderPath"
    }
}

# Check if folder paths are provided
if (-not $ZimmermanTools -or -not $InputPath -or -not $OutputPath) {
    Write-Host "Usage: process.ps1 -ZimmermanTools <path> -InputPath <path> -OutputPath <path>"
    exit 1
}

# Check if the output path exists
if (Test-Path -Path $OutputPath -PathType Container) {
    # Ask for confirmation before deleting contents of the output path
    $confirmation = Read-Host "Output path $OutputPath exists. Do you want to proceed and delete its contents? (Y/N)"

    if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
        # Delete contents of the output path
        Remove-Item -Path $OutputPath\* -Force -Recurse
    } else {
        Write-Host "Operation aborted. No changes made to $OutputPath."
        exit 1
    }
} 

$RECmdPath = Join-Path $ZimmermanTools "RECmd"
$usersPath = Join-Path $InputPath "Users"
$OutputUsers = Join-Path $OutputPath "Users"
$recmd = Get-ToolExecutablePath -ToolsPath $RECmdPath -ExecutableName "ReCmd.exe"

$RECmdPathKroll_Batch = Join-Path $RECmdPath "BatchExamples\Kroll_Batch.reb"

$recmd_cmd = "$recmd --bn $RECmdPathKroll_Batch -d $usersPath --csv $OutputUsers"

$KrollBatch = Join-Path -Path $RECmdPath -ChildPath "BatchExamples" | Join-Path -ChildPath "Kroll_Batch.reb"

if (-not (Test-Path $KrollBatch -PathType Leaf)) {
    Write-Host "Error: Kroll Batch file is missing from $KrollBatch"
    exit 1
}

$globalPath = Join-Path $InputPath "Global"
$OutputGlobal = Join-Path $OutputPath "Global"

$recmd_globalcmd = "$recmd --bn $RECmdPathKroll_Batch -d $globalPath --csv $OutputGlobal"


$amcacheparser = Get-ToolExecutablePath -ToolsPath $ZimmermanTools -ExecutableName "AmCacheParser.exe"

$OutputAmcache = Join-Path $OutputGlobal "AmcacheParserReport"

$AmCacheParser_cmd = "$amcacheparser -f $globalPath\Amcache.hve -i --csv $OutputAmcache"

$jlecmd = Get-ToolExecutablePath -ToolsPath $ZimmermanTools -ExecutableName "JLEcmd.exe"


# Record the start time
$startTime = Get-Date

Process-RecentFolders -usersPath $usersPath -jlecmd $jlecmd -OutputUsers $OutputUsers

# Start the process
Write-Host "Running Kroll Batch scan for all users..."
Start-Process -FilePath "cmd.exe" -ArgumentList "/c $recmd_cmd" -Wait

Write-Host "Running Kroll Batch scan for global registry files..."
Start-Process -FilePath "cmd.exe" -ArgumentList "/c $recmd_globalcmd" -Wait

Write-Host "Running AmCache Parser..."
Start-Process -FilePath "cmd.exe" -ArgumentList "/c $AmCacheParser_cmd" -Wait

Write-Host "Done!"

# Record the end time
$endTime = Get-Date

# Calculate and output the duration
$duration = $endTime - $startTime
Write-Host "Script execution time: $([math]::Round($duration.TotalSeconds, 0)) seconds"