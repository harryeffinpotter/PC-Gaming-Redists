# PCGR Options Menu - fast arrow key navigation
# Receives current values as args, outputs final values as CSV
param(
    [int]$vcredist = 1,
    [int]$dotnet = 1,
    [int]$aspnet = 1,
    [int]$extras = 0,
    [int]$output = 0,
    [int]$log = 0,
    [int]$clickpause = 0,
    [int]$silent = 1,
    [int]$force = 0,
    [string]$logfile = "log.txt"
)

$e = [char]27
$r = "$e[0m"
$bold = "$e[1m"

# Pastel rainbow colors (same 24 as batch)
$colors = @(
    "$e[38;2;255;182;193m", "$e[38;2;255;190;180m", "$e[38;2;255;200;170m",
    "$e[38;2;255;210;160m", "$e[38;2;255;220;150m", "$e[38;2;255;235;145m",
    "$e[38;2;255;250;150m", "$e[38;2;240;255;155m", "$e[38;2;220;255;165m",
    "$e[38;2;200;255;180m", "$e[38;2;180;255;195m", "$e[38;2;165;255;210m",
    "$e[38;2;155;255;230m", "$e[38;2;155;250;245m", "$e[38;2;160;240;255m",
    "$e[38;2;170;225;255m", "$e[38;2;180;210;255m", "$e[38;2;190;200;255m",
    "$e[38;2;200;195;255m", "$e[38;2;210;190;255m", "$e[38;2;220;188;255m",
    "$e[38;2;230;185;255m", "$e[38;2;240;185;250m", "$e[38;2;250;183;240m"
)

# Display order:
# 0: Install VC++ redists    -> vals[0]
# 1: Install .NET redists    -> vals[1]
# 2: Install ASP.NET         -> vals[2]
# 3: Extras                  -> vals[3]  (0=Enabled, 1=No 7Zip, 2=Disabled)
# 4: Output                  -> vals[4]
# 5: Log                     -> vals[5]
# 6: Log file name           -> logfile (string)
# 7: Allow click to pause    -> vals[6]
# 8: Silent mode             -> vals[7]
# 9: Force reinstall         -> vals[8]  (0=Disabled, 1=VC++, 2=.NET, 3=Extras, 4=ALL)

$optNames = @(
    "Install VC++ redists",
    "Install .NET redists",
    "Install ASP.NET",
    "Extras",
    "Output",
    "Log",
    "Log file name",
    "Allow click to pause",
    "Silent mode (recommended)",
    "Force reinstall"
)

$outLabels = @("DISABLED", "All Output", "All Errors")
$extrasLabels = @("ENABLED", "No 7Zip", "DISABLED")
$forceLabels = @("DISABLED", "VC++", ".NET", "ASP.NET", "Extras", "ALL")

$vals = @($vcredist, $dotnet, $aspnet, $extras, $output, $log, $clickpause, $silent, $force)

$pos = 0
$maxPos = 9
$offset = 0

# Value colors
$colorEnabled  = "$e[38;2;180;240;255m"  # Bright near-white sky blue
$colorDisabled = "$e[38;2;220;20;60m"    # Bright crimson
$colorGreyed   = "$e[38;2;100;100;100m"  # Grey

function Write-Rainbow([string]$text, [int]$off) {
    $out = ""
    for ($i = 0; $i -lt $text.Length; $i++) {
        $ci = ($i + $off) % 24
        if ($ci -lt 0) { $ci += 24 }
        $out += $colors[$ci] + $text[$i]
    }
    return "$out$r"
}

function Write-RainbowSep([int]$off) {
    $out = ""
    for ($i = 0; $i -lt 40; $i++) {
        $ci = ($i + $off) % 24
        if ($ci -lt 0) { $ci += 24 }
        $out += $colors[$ci] + "="
    }
    return "$out$r"
}

function Get-ValStr([int]$displayIdx) {
    switch ($displayIdx) {
        0 { if ($vals[0] -eq 1) { "ENABLED" } else { "DISABLED" } }
        1 { if ($vals[1] -eq 1) { "ENABLED" } else { "DISABLED" } }
        2 { if ($vals[2] -eq 1) { "ENABLED" } else { "DISABLED" } }
        3 { $extrasLabels[$vals[3]] }
        4 { $outLabels[$vals[4]] }
        5 { $outLabels[$vals[5]] }
        6 { $logfile }
        7 { if ($vals[6] -eq 1) { "ENABLED" } else { "DISABLED" } }
        8 { if ($vals[7] -eq 1) { "ENABLED" } else { "DISABLED" } }
        9 { $forceLabels[$vals[8]] }
    }
}

$firstDraw = $true

function Draw-Menu {
    [Console]::CursorVisible = $false
    if ($script:firstDraw) {
        [Console]::Clear()
        $script:firstDraw = $false
    }
    [Console]::SetCursorPosition(0, 0)

    $cl = "$e[K"  # Clear to end of line
    $off = $script:offset
    Write-Host "$cl"
    Write-Host "$(Write-RainbowSep $off)$cl"
    $off++
    $optPad = ' ' * [Math]::Floor((40 - 7) / 2)
    Write-Host "$optPad$bold${colorEnabled}OPTIONS$r$cl"
    $off++
    Write-Host "$(Write-RainbowSep $off)$cl"
    $off++
    Write-Host "$cl"

    for ($i = 0; $i -le $maxPos; $i++) {
        $cursor = "   "
        if ($i -eq $pos) { $cursor = " > " }
        $name = $optNames[$i]
        $valStr = Get-ValStr $i
        $padded = $name.PadRight(30)
        $valPadded = $valStr.PadRight(15)

        # Determine value color
        $valColor = $colorEnabled
        if ($valStr -eq "DISABLED") { $valColor = $colorDisabled }

        # Grey out Log file name when Log is disabled
        if ($i -eq 6 -and $vals[5] -eq 0) {
            Write-Host "$colorGreyed$cursor$padded$valPadded$r"
        # Grey out ASP.NET when .NET is disabled
        } elseif ($i -eq 2 -and $vals[1] -eq 0) {
            Write-Host "$colorGreyed$cursor$padded$valPadded$r"
        } else {
            $rainbowPart = Write-Rainbow "$cursor$padded" $off
            Write-Host "$rainbowPart$bold$valColor$valPadded$r"
        }
        $off++
    }

    Write-Host "$cl"
    Write-Host "$(Write-RainbowSep $off)$cl"
    $off++
    $slash = "$colorDisabled/$r$bold$colorEnabled"
    $dash = "$colorDisabled-$r"
    $f1Pad = ' ' * [Math]::Floor((40 - 24) / 2)
    Write-Host "$f1Pad$bold${colorEnabled}Arrows${slash}WASD$r $dash $(Write-Rainbow 'Navigation' $off)$cl"
    $off++
    $f2Pad = ' ' * [Math]::Floor((40 - 21) / 2)
    Write-Host "$f2Pad$bold${colorEnabled}ESC${slash}Backspace$r $dash $(Write-Rainbow 'Apply' $off)$cl"
    $off++
    $f3Pad = ' ' * [Math]::Floor((40 - 22) / 2)
    Write-Host "$f3Pad$bold${colorEnabled}F5$r $dash $(Write-Rainbow 'Reset to Defaults' $off)$cl"
    $off++
    Write-Host "$(Write-RainbowSep $off)$cl"
    $script:offset++
}

function Toggle-Right([int]$displayIdx) {
    switch ($displayIdx) {
        {$_ -le 2} { $vals[$displayIdx] = 1 - $vals[$displayIdx] }
        3 { $vals[3] = ($vals[3] + 1) % 3 }
        4 { $vals[4] = ($vals[4] + 1) % 3 }
        5 { $vals[5] = ($vals[5] + 1) % 3 }
        7 { $vals[6] = 1 - $vals[6] }
        8 { $vals[7] = 1 - $vals[7] }
        9 { $vals[8] = ($vals[8] + 1) % 6 }
    }
}

function Toggle-Left([int]$displayIdx) {
    switch ($displayIdx) {
        {$_ -le 2} { $vals[$displayIdx] = 1 - $vals[$displayIdx] }
        3 { $vals[3] = ($vals[3] + 2) % 3 }
        4 { $vals[4] = ($vals[4] + 2) % 3 }
        5 { $vals[5] = ($vals[5] + 2) % 3 }
        7 { $vals[6] = 1 - $vals[6] }
        8 { $vals[7] = 1 - $vals[7] }
        9 { $vals[8] = ($vals[8] + 5) % 6 }
    }
}

function Edit-LogFileName {
    if ($vals[5] -eq 0) { return }  # Don't edit if Log is disabled
    [Console]::CursorVisible = $true
    Write-Host ""
    $newName = Read-Host " Log file name"
    if ($newName -ne "") { $script:logfile = $newName }
    [Console]::CursorVisible = $false
}

function Save-And-Exit {
    [Console]::CursorVisible = $true
    # Output: vcredist,dotnet,aspnet,extras,output,log,clickpause,silent,force|logfile
    "$($vals[0]),$($vals[1]),$($vals[2]),$($vals[3]),$($vals[4]),$($vals[5]),$($vals[6]),$($vals[7]),$($vals[8])|$logfile" | Out-File "$env:TEMP\pcgr_menu_result.txt" -Encoding ascii -NoNewline
}

# Main loop
Draw-Menu

while ($true) {
    $key = [Console]::ReadKey($true)

    switch ($key.Key) {
        "UpArrow"    { if ($pos -gt 0) { $pos-- } }
        "DownArrow"  { if ($pos -lt $maxPos) { $pos++ } }
        "W"          { if ($pos -gt 0) { $pos-- } }
        "S"          { if ($pos -lt $maxPos) { $pos++ } }
        "LeftArrow"  { if ($pos -ne 6) { Toggle-Left $pos } }
        "A"          { if ($pos -ne 6) { Toggle-Left $pos } }
        "RightArrow" { if ($pos -ne 6) { Toggle-Right $pos } }
        "D"          { if ($pos -ne 6) { Toggle-Right $pos } }
        "Enter" {
            if ($pos -eq 6) { Edit-LogFileName }
            else { Toggle-Right $pos }
        }
        "Spacebar" {
            if ($pos -eq 6) { Edit-LogFileName }
            else { Toggle-Right $pos }
        }
        "Backspace" {
            Save-And-Exit
            return
        }
        "F5" {
            # Reset to defaults: vc=1,dotnet=1,aspnet=1,extras=0,output=0,log=0,clickpause=0,silent=1,force=0
            $vals = @(1, 1, 1, 0, 0, 0, 0, 1, 0)
            $logfile = "log.txt"
            Save-And-Exit
            return
        }
        "Escape" {
            Save-And-Exit
            return
        }
    }

    Draw-Menu
}
