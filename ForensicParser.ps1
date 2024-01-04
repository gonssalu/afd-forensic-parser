# Declare input parameters
param (
    [string]$ZimmermanTools,
    [string]$InputPath,
    [string]$OutputPath,
    [switch]$DebugMode
)

# Function to get the full path to a tool executable
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

        Run-CommandWithLogging -Command $jlecmd_cmd -Description "Running Jump List scan for $($userDirectory.Name)..."
    }
}

# Function to run a command and log it to the console
function Run-CommandWithLogging {
    param (
        [string]$Command,
        [string]$Description
    )

    Write-Host "Running $Description..."
    if($DebugMode) {
        Write-Host "Command: $Command"
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $Command" -Wait -NoNewWindow
    }else{
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $Command" -Wait -WindowStyle Hidden
    }
}

# Check if folder paths are provided
if (-not $ZimmermanTools -or -not $InputPath -or -not $OutputPath) {
    Write-Host 'Usage: ForensicParser.ps1 -ZimmermanTools "<Path>" -InputPath "<Path>" -OutputPath "<Path>"'
    exit 1
}

# Check if the output path exists
if (Test-Path -Path $OutputPath -PathType Container) {
    # Ask for confirmation before deleting contents of the output path
    $confirmation = Read-Host "Output path $OutputPath exists. Do you want to proceed and delete its contents? (Y/N)"

    if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
        Remove-Item -Path $OutputPath\* -Force -Recurse
    } else {
        Write-Host "Operation aborted. No changes made to $OutputPath."
        exit 1
    }
} 

$usersPath = Join-Path $InputPath "Users"
$OutputUsers = Join-Path $OutputPath "Users"

$RECmdPath = Join-Path $ZimmermanTools "RECmd"
$recmd = Get-ToolExecutablePath -ToolsPath $RECmdPath -ExecutableName "ReCmd.exe"
$KrollBatch = Join-Path -Path $RECmdPath -ChildPath "BatchExamples" | Join-Path -ChildPath "Kroll_Batch.reb"

# Confirm that the Kroll Batch file exists
if (-not (Test-Path $KrollBatch -PathType Leaf)) {
    Write-Host "Error: Kroll Batch file is missing from $KrollBatch"
    exit 1
}

# Crafting the RECmd command for user registry files
$recmd_cmd = "$recmd --bn $KrollBatch -d $usersPath --csv $OutputUsers"

$globalPath = Join-Path $InputPath "Global"
$OutputGlobal = Join-Path $OutputPath "Global"

# Crafting the RECmd command for global registry files
$recmd_globalcmd = "$recmd --bn $KrollBatch -d $globalPath --csv $OutputGlobal"

$amcacheparser = Get-ToolExecutablePath -ToolsPath $ZimmermanTools -ExecutableName "AmCacheParser.exe"
$OutputAmcache = Join-Path $OutputGlobal "AmcacheParserReport"

# Crafting the AmCacheParser command
$AmCacheParser_cmd = "$amcacheparser -f $globalPath\Amcache.hve -i --csv $OutputAmcache"
# Crafting the JLEcmd command
$jlecmd = Get-ToolExecutablePath -ToolsPath $ZimmermanTools -ExecutableName "JLEcmd.exe"

$startTime = Get-Date

Process-RecentFolders -usersPath $usersPath -jlecmd $jlecmd -OutputUsers $OutputUsers

Run-CommandWithLogging -Command $recmd_cmd -Description "Kroll Batch scan for all users"
Run-CommandWithLogging -Command $recmd_globalcmd -Description "Kroll Batch scan for global registry files"
Run-CommandWithLogging -Command $AmCacheParser_cmd -Description "AmCache Parser"

Write-Host "`nConverting CSV files' separator to commas..."

$csvFiles = Get-ChildItem -Path $OutputPath -Filter *.csv -Recurse

foreach ($csvFile in $csvFiles) {
    $content = Get-Content $csvFile.FullName
    $newContent = @("SEP=,") + $content
    $newContent | Set-Content -Path $csvFile.FullName
}

Write-Host "Conversion successfully complete!"

$endTime = Get-Date
$duration = $endTime - $startTime
Write-Host "Script execution time: $([math]::Round($duration.TotalSeconds, 0)) seconds"