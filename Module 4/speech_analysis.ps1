# Set up logging
$logFile = "speech_analysis_log.txt"
$csvFile = "speech_analysis_results.csv"
$speechFile = "speech.txt"

# Function to write to log file
function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Output $Message
}

# Start logging
Write-Log "=== Speech Analysis Script Started ==="

# Step 1: Check if speech file exists
if (-not (Test-Path $speechFile)) {
    Write-Log "ERROR: Speech file '$speechFile' not found!"
    exit 1
}

Write-Log "Speech file found: $speechFile"

# Step 2: Read the speech from file
Write-Log "Reading speech content from file..."
$speechContent = Get-Content $speechFile -Raw

if (-not $speechContent) {
    Write-Log "ERROR: Could not read speech content or file is empty!"
    exit 1
}

Write-Log "Successfully read speech content"

# Step 3: Analyze the speech content
Write-Log "Analyzing speech content..."

# Get lines, words, and characters
$lineCount = (Get-Content $speechFile | Measure-Object -Line).Lines
$wordCount = ($speechContent -split '\s+' | Where-Object { $_.Trim() -ne "" }).Count
$charCount = $speechContent.Length

# Count occurrences of "The " (with space after it)
$theCount = ([regex]::Matches($speechContent, "The ", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count

# Step 4: Create analysis results object
$analysisResults = [PSCustomObject]@{
    FileName = $speechFile
    NumberOfLines = $lineCount
    NumberOfWords = $wordCount
    NumberOfCharacters = $charCount
    CountOfTheWord = $theCount
    AnalysisDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

Write-Log "Analysis completed successfully"

# Step 5: Display information to screen
Write-Log "=== SPEECH ANALYSIS RESULTS ==="
Write-Log "File Name: $($analysisResults.FileName)"
Write-Log "Number of Lines: $($analysisResults.NumberOfLines)"
Write-Log "Number of Words: $($analysisResults.NumberOfWords)"
Write-Log "Number of Characters: $($analysisResults.NumberOfCharacters)"
Write-Log "Count of 'The ': $($analysisResults.CountOfTheWord)"
Write-Log "Analysis Date: $($analysisResults.AnalysisDate)"

# Step 6: Export to CSV file
Write-Log "Writing results to CSV file: $csvFile"
$analysisResults | Export-Csv -Path $csvFile -NoTypeInformation

if (Test-Path $csvFile) {
    Write-Log "Successfully created CSV file: $csvFile"
} else {
    Write-Log "ERROR: Failed to create CSV file!"
    exit 1
}

# Step 7: Import and display CSV file contents
Write-Log "Importing and displaying CSV file contents..."
$importedData = Import-Csv -Path $csvFile

Write-Log "=== IMPORTED CSV DATA ==="
$importedData | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Log $_.Trim() }

Write-Log "=== Speech Analysis Script Completed Successfully ==="