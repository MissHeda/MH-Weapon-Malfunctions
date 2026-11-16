# Unattended test: builds the mod (hemtt dev), starts its own Arma (CBA + ACE, own profile MHWMTest, windowed) straight into
# tools/test/MHWM_Auto.VR, takes a picture of the window (PrintWindow) at every "MHWMTEST SHOT <name>" in the RPT, and stops
# its own Arma at "MHWMTEST DONE" or after the time limit. Prints the MHWMTEST lines and script errors.
#
#   powershell -ExecutionPolicy Bypass -File tools\test\run_auto.ps1 -OutDir <folder for pictures>
param(
    [string]$OutDir = "$env:TEMP\mhwm_auto",
    [int]$TimeoutSec = 420,
    [switch]$NoBuild
)

$ErrorActionPreference = "Stop"
$repo = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$arma = "C:\SteamLibrary\steamapps\common\Arma 3"
$workshop = "C:\SteamLibrary\steamapps\workshop\content\107410"
New-Item -ItemType Directory -Force $OutDir | Out-Null

if (-not $NoBuild) {
    Push-Location $repo
    hemtt dev | Out-Null
    Pop-Location
}

$missions = Join-Path $repo ".hemttout\dev\missions"
New-Item -ItemType Directory -Force $missions | Out-Null
Copy-Item -Recurse -Force (Join-Path $PSScriptRoot "MHWM_Auto.VR") $missions

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MhwmWin {
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int w, int hh, uint f);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    public struct RECT { public int L, T, R, B; }
}
"@
Add-Type -AssemblyName System.Drawing
[MhwmWin]::SetProcessDPIAware() | Out-Null

$rptDir = Join-Path $env:LOCALAPPDATA "Arma 3"
$started = Get-Date
$mods = @("$workshop\450814997", "$workshop\463939057", (Join-Path $repo ".hemttout\dev")) | ForEach-Object { "-mod=`"$_`"" }
$armaArgs = $mods + @("-window", "-noPause", "-skipIntro", "-noSplash", "-filePatching", "-showScriptErrors", "-name=MHWMTest",
    "`"-init=playMission['','\z\mhwm\missions\MHWM_Auto.VR']`"")
$proc = Start-Process -FilePath (Join-Path $arma "arma3_x64.exe") -ArgumentList $armaArgs -PassThru
"PID $($proc.Id)"

function Save-Shot($name) {
    $proc.Refresh()
    $h = $proc.MainWindowHandle
    if ($h -eq [IntPtr]::Zero) { "  no window for $name"; return }
    $r = New-Object MhwmWin+RECT
    [MhwmWin]::GetClientRect($h, [ref]$r) | Out-Null
    $w = $r.R - $r.L; $hh = $r.B - $r.T
    if ($w -le 0 -or $hh -le 0) { "  empty window for $name"; return }
    $bmp = New-Object System.Drawing.Bitmap $w, $hh
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $dc = $g.GetHdc()
    [MhwmWin]::PrintWindow($h, $dc, 3) | Out-Null
    $g.ReleaseHdc($dc); $g.Dispose()
    $file = Join-Path $OutDir "$name.png"
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    "  SHOT $file"
}

$rpt = $null
$seen = 0
$placed = $false
$deadline = $started.AddSeconds($TimeoutSec)

while ((Get-Date) -lt $deadline -and -not $proc.HasExited) {
    Start-Sleep -Milliseconds 400
    if (-not $placed) {
        $proc.Refresh()
        if ($proc.MainWindowHandle -ne [IntPtr]::Zero) {
            [MhwmWin]::ShowWindow($proc.MainWindowHandle, 9) | Out-Null
            [MhwmWin]::SetWindowPos($proc.MainWindowHandle, [IntPtr]::Zero, 300, 140, 1936, 1119, 0x0014) | Out-Null
            $placed = $true
        }
    }
    if (-not $rpt) {
        $rpt = Get-ChildItem $rptDir -Filter "*.rpt" | Where-Object { $_.LastWriteTime -gt $started } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $rpt) { continue }
        "RPT $($rpt.FullName)"
    }
    $lines = Get-Content $rpt.FullName -ErrorAction SilentlyContinue
    if ($lines.Count -le $seen) { continue }
    $new = $lines[$seen..($lines.Count - 1)]
    $seen = $lines.Count
    $done = $false
    for ($i = 0; $i -lt $new.Count; $i++) {
        $line = $new[$i]
        if ($line -match "MHWMTEST SHOT (\S+)") { Save-Shot $Matches[1] }
        elseif ($line -match "MHWMTEST") { $line -replace "^.*MHWMTEST ", "" ; if ($line -match "MHWMTEST DONE") { $done = $true } }
        elseif ($line -match "Error|error in expression|Undefined variable|Bad conversion|Missing ;|Type .*, expected") {
            "RPT: $line"
            for ($j = 1; $j -le 6 -and ($i + $j) -lt $new.Count; $j++) { "RPT:   $($new[$i + $j])" }
        }
    }
    if ($done) { Start-Sleep -Seconds 1; break }
}

if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force }
"ended after $([int]((Get-Date) - $started).TotalSeconds) s"
