# ==============================================================================
#  ClaudePeakHoursNotifier.ps1  v2.1
#
#  Based on official Anthropic announcement (@trq212):
#  "During weekdays between 5am-11am PT / 1pm-7pm GMT, you will move through
#   your 5-hour session limits faster than before."
#
#  ALERTS (weekdays only):
#    [!]  10 minutes before peak starts  -- wrap up heavy tasks
#    [>>] When peak hours begin          -- limits deplete faster
#    [OK] When peak hours end            -- safe to run intensive jobs
#
#  COMMANDS:
#    .\ClaudePeakHoursNotifier.ps1              --> Start notifier
#    .\ClaudePeakHoursNotifier.ps1 -Status      --> Show local peak times and exit
#    .\ClaudePeakHoursNotifier.ps1 -Setup       --> Enable auto-startup at Windows login
#    .\ClaudePeakHoursNotifier.ps1 -RemoveSetup --> Disable auto-startup
# ==============================================================================

Set-StrictMode -Off

# -- CONFIGURATION -------------------------------------------------------------
# Official peak hours in UTC (1pm-7pm GMT = 13:00-19:00 UTC)
$PeakStartUTC = "13:00"
$PeakEndUTC   = "19:00"

# Days when peak hours apply
$PeakDays = @("Monday","Tuesday","Wednesday","Thursday","Friday")

# Sound alert ($true / $false)
$PlaySound = $true

# Scheduled task name
$TaskName = "ClaudePeakHoursNotifier"
# ------------------------------------------------------------------------------


# -- TIMEZONE CONVERSION -------------------------------------------------------
function Convert-UTCtoLocal {
    param([string]$hhmm, [datetime]$refDate)
    $parts   = $hhmm -split ":"
    $utcTime = [datetime]::new(
        $refDate.Year, $refDate.Month, $refDate.Day,
        [int]$parts[0], [int]$parts[1], 0,
        [System.DateTimeKind]::Utc)
    return $utcTime.ToLocalTime()
}
# ------------------------------------------------------------------------------


# -- TOAST + SOUND NOTIFICATION ------------------------------------------------
function Show-Toast {
    param(
        [string]$Title,
        [string]$Message,
        [string]$Icon = "Warning"
    )
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        $notify = New-Object System.Windows.Forms.NotifyIcon
        $iconMap = @{
            "Info"    = [System.Drawing.SystemIcons]::Information
            "Warning" = [System.Drawing.SystemIcons]::Warning
            "Error"   = [System.Drawing.SystemIcons]::Error
        }
        $notify.Icon            = $iconMap[$Icon]
        $notify.Visible         = $true
        $notify.BalloonTipTitle = $Title
        $notify.BalloonTipText  = $Message
        $notify.BalloonTipIcon  = $Icon
        $notify.ShowBalloonTip(10000)

        if ($PlaySound) {
            switch ($Icon) {
                "Warning" { [System.Media.SystemSounds]::Exclamation.Play() }
                default   { [System.Media.SystemSounds]::Asterisk.Play() }
            }
        }
        Start-Sleep -Milliseconds 600
        $notify.Dispose()
    }
    catch {
        Write-Host "  [Toast error] $_" -ForegroundColor DarkRed
    }
}
# ------------------------------------------------------------------------------


# -- STARTUP MANAGEMENT --------------------------------------------------------
function Register-Startup {
    $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.ScriptName }
    try {
        $action   = New-ScheduledTaskAction `
                        -Execute  "powershell.exe" `
                        -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
        $trigger  = New-ScheduledTaskTrigger -AtLogOn
        $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -MultipleInstances IgnoreNew

        Register-ScheduledTask `
            -TaskName $TaskName -Action $action `
            -Trigger $trigger -Settings $settings `
            -RunLevel Highest -Force | Out-Null

        Write-Host "  [OK] Auto-startup registered. Runs silently at every Windows login." -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] Failed (try running as Administrator): $_" -ForegroundColor Red
    }
}

function Remove-Startup {
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Host "  [OK] Auto-startup removed." -ForegroundColor Green
    }
    catch {
        Write-Host "  [!] Task not found or already removed." -ForegroundColor Yellow
    }
}

function Is-StartupRegistered {
    return ($null -ne (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue))
}
# ------------------------------------------------------------------------------


# -- COMMAND-LINE PARAMS -------------------------------------------------------
param(
    [switch]$Setup,
    [switch]$RemoveSetup,
    [switch]$Status
)

if ($Setup)       { Register-Startup; exit }
if ($RemoveSetup) { Remove-Startup;   exit }
# ------------------------------------------------------------------------------


# -- HEADER + LOCAL PEAK TIME DISPLAY ------------------------------------------
$now       = Get-Date
$peakStart = Convert-UTCtoLocal $PeakStartUTC $now
$peakEnd   = Convert-UTCtoLocal $PeakEndUTC   $now
$warnTime  = $peakStart.AddMinutes(-10)
$tzName    = [TimeZoneInfo]::Local.Id
$hours     = [int]($peakEnd - $peakStart).TotalHours

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "     Claude Peak Hours Notifier  v2.1                        " -ForegroundColor Cyan
Write-Host "     Based on official Anthropic announcement (@trq212)      " -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [!] During peak hours your 5-hour session limits are" -ForegroundColor Yellow
Write-Host "      consumed FASTER -- affects free, Pro and Max plans." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Your timezone  : $tzName" -ForegroundColor White
Write-Host "  Peak hours     : $($peakStart.ToString('HH:mm')) --> $($peakEnd.ToString('HH:mm'))  ($hours hrs, local time)" -ForegroundColor Red
Write-Host "  GMT/UTC        : 13:00 --> 19:00" -ForegroundColor DarkGray
Write-Host "  Pacific (PT)   : 05:00 --> 11:00" -ForegroundColor DarkGray
Write-Host "  Active on      : Weekdays only" -ForegroundColor White
Write-Host ""
Write-Host "  Notifications scheduled:" -ForegroundColor DarkGray
Write-Host "    [!]  $($warnTime.ToString('HH:mm'))  -- 10-min warning: wrap up heavy tasks" -ForegroundColor Yellow
Write-Host "    [>>] $($peakStart.ToString('HH:mm'))  -- Peak starts: session limits deplete faster" -ForegroundColor Red
Write-Host "    [OK] $($peakEnd.ToString('HH:mm'))  -- Peak ends: run intensive jobs freely" -ForegroundColor Green
Write-Host ""

if ($Status) { exit }


# -- FIRST-RUN: ASK ABOUT STARTUP ----------------------------------------------
if (-not (Is-StartupRegistered)) {
    Write-Host "  ------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "   Start automatically with Windows?" -ForegroundColor Cyan
    Write-Host "" 
    Write-Host "   [1] Yes -- run silently at every login (recommended)" -ForegroundColor Cyan
    Write-Host "   [2] No  -- I will launch it manually when needed" -ForegroundColor Cyan
    Write-Host "  ------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host -NoNewline "  Your choice (1 or 2): "
    $choice = Read-Host

    if ($choice -eq "1") {
        Register-Startup
    }
    else {
        Write-Host "  Manual mode selected." -ForegroundColor Yellow
        Write-Host "  Run with -Setup at any time to enable auto-startup later." -ForegroundColor DarkGray
    }
    Write-Host ""
}
else {
    Write-Host "  [OK] Auto-startup is active.  (run with -RemoveSetup to disable)" -ForegroundColor DarkGray
    Write-Host ""
}

Write-Host "  Notifier is running...  Press Ctrl+C to stop." -ForegroundColor Green
Write-Host ""


# -- MAIN NOTIFICATION LOOP ----------------------------------------------------
$fired = @{}

while ($true) {
    $now       = Get-Date
    $peakStart = Convert-UTCtoLocal $PeakStartUTC $now
    $peakEnd   = Convert-UTCtoLocal $PeakEndUTC   $now
    $warnTime  = $peakStart.AddMinutes(-10)
    $dayName   = $now.DayOfWeek.ToString()

    if ($PeakDays -contains $dayName) {

        $keyW = "warn-$($now.Date)"
        $keyS = "start-$($now.Date)"
        $keyE = "end-$($now.Date)"

        # [!] 10-MINUTE WARNING
        if ($now -ge $warnTime -and $now -lt $peakStart -and -not $fired[$keyW]) {
            $fired[$keyW] = $true
            $title = "Claude peak hours in 10 minutes!"
            $body  = "Peak starts at $($peakStart.ToString('HH:mm')) and lasts $hours hours." + `
                     "`nFinish token-intensive tasks now or shift them to after $($peakEnd.ToString('HH:mm'))."
            Write-Host "  [$($now.ToString('HH:mm'))]  [!] WARNING  -- Peak starts in 10 min" -ForegroundColor Yellow
            Show-Toast -Title $title -Message $body -Icon Warning
        }

        # [>>] PEAK START
        if ($now -ge $peakStart -and $now -lt $peakStart.AddMinutes(1) -and -not $fired[$keyS]) {
            $fired[$keyS] = $true
            $title = "Claude peak hours have started!"
            $body  = "Session limits deplete FASTER until $($peakEnd.ToString('HH:mm'))." + `
                     "`nAffects free, Pro and Max plans." + `
                     "`nTip: avoid heavy background jobs during this window."
            Write-Host "  [$($now.ToString('HH:mm'))]  [>>] START   -- Session limits now depleting faster" -ForegroundColor Red
            Show-Toast -Title $title -Message $body -Icon Warning
        }

        # [OK] PEAK END
        if ($now -ge $peakEnd -and $now -lt $peakEnd.AddMinutes(1) -and -not $fired[$keyE]) {
            $fired[$keyE] = $true
            $title = "Claude peak hours are over!"
            $body  = "Session limits are back to normal." + `
                     "`nGreat time to run token-intensive or background jobs!"
            Write-Host "  [$($now.ToString('HH:mm'))]  [OK] END     -- Off-peak! Run heavy jobs freely." -ForegroundColor Green
            Show-Toast -Title $title -Message $body -Icon Info
        }
    }

    Start-Sleep -Seconds 30
}
