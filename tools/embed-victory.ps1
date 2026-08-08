# Embed art/victory.jpg into index.html as the victory-screen photo.
# Center-crops to the game's 960x540 canvas (honoring EXIF rotation),
# compresses to JPEG, and splices the data URI into the VICTORY_PHOTO
# slot. Rerun any time the photo changes.
# Usage: pwsh tools/embed-victory.ps1 [-Quality 78] [-CropShift 0]
#   -CropShift: vertical crop offset in source pixels (negative = higher)

param([int]$Quality = 78, [int]$CropShift = 0)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent
$srcPath = Join-Path $root "art\victory.jpg"
$htmlPath = Join-Path $root "index.html"

$src = [System.Drawing.Image]::FromFile($srcPath)

# EXIF orientation (phones often store rotation as metadata)
if ($src.PropertyIdList -contains 0x0112) {
  $o = $src.GetPropertyItem(0x0112).Value[0]
  switch ($o) {
    3 { $src.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
    6 { $src.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
    8 { $src.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
  }
}
"source: $($src.Width)x$($src.Height)"

# cover-scale onto 960x540, center crop (+ optional vertical shift)
$W = 960; $H = 540
$scale = [Math]::Max($W / $src.Width, $H / $src.Height)
$nw = [int][Math]::Ceiling($src.Width * $scale)
$nh = [int][Math]::Ceiling($src.Height * $scale)
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($src, [int](($W - $nw) / 2), [int](($H - $nh) / 2 + $CropShift * $scale), $nw, $nh)
$g.Dispose()
$src.Dispose()

# JPEG encode at the requested quality
$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$params = New-Object System.Drawing.Imaging.EncoderParameters 1
$params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)
$ms = New-Object System.IO.MemoryStream
$bmp.Save($ms, $codec, $params)
$bmp.Dispose()
$b64 = [Convert]::ToBase64String($ms.ToArray())
$ms.Dispose()
"embedded jpeg: $([Math]::Round($b64.Length / 1024)) KB base64"

# splice into index.html (replaces the null slot or a previous embed)
$html = Get-Content -Raw $htmlPath
$newDecl = "let VICTORY_PHOTO = new Image();`nVICTORY_PHOTO.src = `"data:image/jpeg;base64,$b64`";"
$pattern = '(?s)let VICTORY_PHOTO = (?:null;|new Image\(\);\s*\nVICTORY_PHOTO\.src = "data:image/jpeg;base64,[^"]*";)'
if ($html -notmatch $pattern) { throw "VICTORY_PHOTO slot not found in index.html" }
$html = [regex]::Replace($html, $pattern, { param($m) $newDecl })
Set-Content -Path $htmlPath -Value $html -NoNewline
"spliced into index.html"