# Configuration
$outputPath = "C:\Users\dsade\OneDrive\Desktop\Business\AI\xAI\X Election Tracker"
$dataFile = "$outputPath\sentiment_data.json"
$htmlFile = "$outputPath\index.html"

# Function to get sentiment analysis for a topic
function Get-SentimentAnalysis {
    param (
        [string]$topic
    )
    
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer xai-7RlN7T34iX7QWc4G5RqLc7ISb73zWN0mgygTekU2JcPtnW8raoqTgzJSitWqeRgBR5TThOdTKHIdzxop"
    }

    $body = @{
        messages = @(
            @{
                role = "system"
                content = "You are a real-time sentiment analyzer for X content. Provide a sentiment score from 0-100."
            }
            @{
                role = "user"
                content = "Analyze the current sentiment about $topic on X. Return only a number from 0-100 representing the positive sentiment percentage."
            }
        )
        model = "grok-beta"
        temperature = 0.3
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "https://api.x.ai/v1/chat/completions" -Method Post -Headers $headers -Body $body
    return $response.choices[0].message.content
}

# Function to update the dashboard data
function Update-Dashboard {
    Write-Host "Updating sentiment data..."
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $trumpSentiment = Get-SentimentAnalysis "donald trump winning the election"
    $harrisSentiment = Get-SentimentAnalysis "kamala harris winning the election"

    # Load existing data or create new
    if (Test-Path $dataFile) {
        $data = Get-Content $dataFile | ConvertFrom-Json
    } else {
        $data = @{
            timestamps = @()
            trumpSentiment = @()
            harrisSentiment = @()
        }
    }

    # Add new data points
    $data.timestamps += $timestamp
    $data.trumpSentiment += $trumpSentiment
    $data.harrisSentiment += $harrisSentiment

    # Save updated data
    $data | ConvertTo-Json | Set-Content $dataFile
    Write-Host "Data updated successfully!"
    Write-Host "Trump Sentiment: $trumpSentiment"
    Write-Host "Harris Sentiment: $harrisSentiment"
}

# Check if task exists and remove it
Unregister-ScheduledTask -TaskName "X Election Sentiment Analysis" -Confirm:$false -ErrorAction SilentlyContinue

# Create new hourly trigger
$trigger = New-JobTrigger -Once -At (Get-Date) -RepeatIndefinitely -RepetitionInterval (New-TimeSpan -Hours 1)
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$outputPath\update_dashboard.ps1`""

# Register new task
Register-ScheduledTask -TaskName "X Election Sentiment Analysis" -Trigger $trigger -Action $action -Description "Updates sentiment analysis dashboard every hour until Nov 5th 6 AM"

# Run initial update
Update-Dashboard