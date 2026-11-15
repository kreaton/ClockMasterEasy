# Generates the app / home-screen icons for Lille Ur-mester: a friendly clock face showing three o'clock,
# the first kind of time the game asks, with red hour numbers and the red and blue hands from the game.
# Run with Windows PowerShell (System.Drawing):  powershell -File tools\make-icons.ps1
param(
    [string]$OutDir = (Join-Path $PSScriptRoot "..\src\ClockMasterEasy\wwwroot\icons"),
    # The front page (KidsGames) shows each game's 512 px icon; pass its billeder folder to update it too.
    [string]$FrontPageDir = (Join-Path $PSScriptRoot "..\..\KidsGames\billeder")
)

Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force $OutDir | Out-Null

function Color([string]$hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
function Brush([string]$hex) { New-Object System.Drawing.SolidBrush (Color $hex) }

function New-Star([float]$cx, [float]$cy, [float]$outer, [float]$inner) {
    $points = for ($i = 0; $i -lt 10; $i++) {
        $r = if ($i % 2 -eq 0) { $outer } else { $inner }
        $a = [Math]::PI * ($i * 36 - 90) / 180
        New-Object System.Drawing.PointF ($cx + $r * [Math]::Cos($a)), ($cy + $r * [Math]::Sin($a))
    }
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddPolygon([System.Drawing.PointF[]]$points)
    return $p
}

# A point on the clock at the given angle (degrees clockwise from 12) and radius.
function At([float]$cx, [float]$cy, [float]$deg, [float]$r) {
    $a = [Math]::PI * $deg / 180
    New-Object System.Drawing.PointF ($cx + $r * [Math]::Sin($a)), ($cy - $r * [Math]::Cos($a))
}

function Draw-Hand($g, [float]$cx, [float]$cy, [float]$deg, [float]$length, [float]$width, [string]$hex) {
    $pen = New-Object System.Drawing.Pen (Color $hex), $width
    $pen.StartCap = 'Round'
    $pen.EndCap = 'Round'
    $g.DrawLine($pen, (New-Object System.Drawing.PointF $cx, $cy), (At $cx $cy $deg $length))
}

# content: 1.0 = full size, 0.78 = keep inside the maskable safe zone
function Draw-Icon([int]$size, [string]$file, [float]$content = 1.0, [bool]$detail = $true) {
    $S = [float]$size
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'

    # Background: the game's sky-to-sun gradient (full square, iOS applies its own rounded mask)
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.PointF 0, 0), (New-Object System.Drawing.PointF 0, $S), (Color '#ffa8c5'), (Color '#fff3a3')
    $g.FillRectangle($bg, 0, 0, $S, $S)

    $cx = $S / 2
    $cy = $S / 2 + $S * 0.02 * $content
    $R = $S * 0.40 * $content

    # Drop shadow, rim and face
    $g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(60, 59, 42, 99))), $cx - $R, $cy - $R + $S * 0.025, 2 * $R, 2 * $R)
    $g.FillEllipse((Brush '#3b2a63'), $cx - $R, $cy - $R, 2 * $R, 2 * $R)
    $face = $R * 0.88
    $g.FillEllipse((Brush '#ffffff'), $cx - $face, $cy - $face, 2 * $face, 2 * $face)

    if ($detail) {
        # Hour marks: big blue dots, with 12, 3, 6 and 9 as numbers
        $font = New-Object System.Drawing.Font 'Arial Rounded MT Bold', ($R * 0.26), ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
        $fmt = New-Object System.Drawing.StringFormat
        $fmt.Alignment = 'Center'
        $fmt.LineAlignment = 'Center'
        for ($h = 1; $h -le 12; $h++) {
            if ($h % 3 -eq 0) {
                $p = At $cx $cy ($h * 30) ($R * 0.66)
                $box = New-Object System.Drawing.RectangleF ($p.X - $R * 0.25), ($p.Y - $R * 0.22), ($R * 0.5), ($R * 0.5)
                $g.DrawString($h.ToString(), $font, (Brush '#e03131'), $box, $fmt)
            }
            else {
                $p = At $cx $cy ($h * 30) ($R * 0.70)
                $d = $R * 0.075
                $g.FillEllipse((Brush '#228be6'), $p.X - $d, $p.Y - $d, 2 * $d, 2 * $d)
            }
        }
    }

    # Three o'clock: the blue minute hand on 12 under the shorter red hour hand on 3
    Draw-Hand $g $cx $cy 0 ($R * 0.48) ($R * 0.10) '#228be6'
    Draw-Hand $g $cx $cy 90 ($R * 0.36) ($R * 0.14) '#fa5252'
    $c = $R * 0.09
    $g.FillEllipse((Brush '#3b2a63'), $cx - $c, $cy - $c, 2 * $c, 2 * $c)

    if ($detail) {
        # Gold "mester" star on the rim, top right
        $sp = At $cx $cy 42 ($R * 0.98)
        $outer = $R * 0.27
        $star = New-Star $sp.X $sp.Y $outer ($outer * 0.48)
        $outline = New-Object System.Drawing.Pen (Color '#e67700'), ($R * 0.04)
        $outline.LineJoin = 'Round'
        $g.FillPath((Brush '#ffd43b'), $star)
        $g.DrawPath($outline, $star)
    }

    $g.Dispose()
    $bmp.Save((Join-Path $OutDir $file), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "  $file"
}

Write-Host "Writing icons to $OutDir"
Draw-Icon 180  'apple-touch-icon.png'
Draw-Icon 167  'apple-touch-icon-167.png'
Draw-Icon 152  'apple-touch-icon-152.png'
Draw-Icon 192  'icon-192.png'
Draw-Icon 512  'icon-512.png'
Draw-Icon 1024 'icon-1024.png'
Draw-Icon 512  'icon-512-maskable.png' 0.78
Draw-Icon 32   'favicon-32.png' 1.0 $false

if (Test-Path $FrontPageDir) {
    Copy-Item (Join-Path $OutDir 'icon-512.png') (Join-Path $FrontPageDir 'clockmastereasy.png')
    Write-Host "Copied icon-512.png to $FrontPageDir\clockmastereasy.png"
}
