# Export the game's pixel-array sprites from index.html to native-resolution
# PNGs (1 image pixel per art pixel) for editing in Piskel/Aseprite.
# Legacy 16x16 dog poses are upscaled x2 to 32x32 so every Lue pose lands on
# the same canvas size the new art should use.
# Usage: pwsh tools/export-sprites.ps1

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root   = Split-Path $PSScriptRoot -Parent
$html   = Get-Content -Raw (Join-Path $root "index.html")
$outDir = Join-Path $root "art\export"
New-Item -ItemType Directory -Force $outDir | Out-Null

# ---- parse PALETTES ----
if ($html -notmatch "(?s)const PALETTES = \{(.*?)\n\};") { throw "PALETTES block not found" }
$palRegion = $Matches[1]
$palettes = @{}
foreach ($m in [regex]::Matches($palRegion, "(\w+):\s*\{([^}]+)\}")) {
  $name = $m.Groups[1].Value
  # case-SENSITIVE keys: palettes distinguish e.g. 'p' from 'P'
  $map = New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal)
  foreach ($pair in [regex]::Matches($m.Groups[2].Value, '(\w+):\s*"(#[0-9a-fA-F]{3,6})"')) {
    $map[$pair.Groups[1].Value] = [System.Drawing.ColorTranslator]::FromHtml($pair.Groups[2].Value)
  }
  $palettes[$name] = $map
}

# ---- parse SPRITES ----
if ($html -notmatch "(?s)const SPRITES = \{(.*?)\n\};") { throw "SPRITES block not found" }
$spriteRegion = $Matches[1]
$spritePattern = '(?s)(\w+):\s*\{\s*palette:\s*"(\w+)",\s*scale:\s*(\d+)(?:,\s*outline:\s*"[^"]*")?,\s*rows:\s*\[(.*?)\]\s*\}'
$exported = @()

foreach ($m in [regex]::Matches($spriteRegion, $spritePattern)) {
  $name    = $m.Groups[1].Value
  $palName = $m.Groups[2].Value
  $rows    = [regex]::Matches($m.Groups[4].Value, '"([.A-Za-z]*)"') | ForEach-Object { $_.Groups[1].Value }
  if (-not $rows) { continue }
  $pal = $palettes[$palName]
  if (-not $pal) { throw "palette $palName missing for $name" }

  $w = $rows[0].Length
  $h = $rows.Count
  # legacy 16x16 dog poses -> upscale x2 onto the 32x32 target canvas
  $up = if ($name -like "dog*" -and $w -eq 16) { 2 } else { 1 }

  $bmp = New-Object System.Drawing.Bitmap ($w * $up), ($h * $up)
  for ($y = 0; $y -lt $h; $y++) {
    $row = $rows[$y]
    for ($x = 0; $x -lt $w; $x++) {
      $ch = $row[$x]
      if ($ch -eq ".") { continue }
      $col = $pal["$ch"]
      if ($null -eq $col) { continue }
      for ($dy = 0; $dy -lt $up; $dy++) {
        for ($dx = 0; $dx -lt $up; $dx++) {
          $bmp.SetPixel($x * $up + $dx, $y * $up + $dy, $col)
        }
      }
    }
  }
  $file = Join-Path $outDir "$name.png"
  $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  $exported += "{0}  {1}x{2}{3}" -f $name, ($w * $up), ($h * $up), $(if ($up -gt 1) { "  (upscaled from ${w}x${h} legacy)" } else { "" })
}

# ---- Lue sprite sheet: all 9 poses side by side, 32x32 cells ----
$dogOrder = @("dogRun0","dogRun1","dogJump","dogSwipe","dogSit","dogPick0","dogPick1","dogEat0","dogEat1")
$cells = $dogOrder | Where-Object { Test-Path (Join-Path $outDir "$_.png") }
if ($cells.Count) {
  $sheet = New-Object System.Drawing.Bitmap (32 * $cells.Count), 32
  $g = [System.Drawing.Graphics]::FromImage($sheet)
  for ($i = 0; $i -lt $cells.Count; $i++) {
    $img = [System.Drawing.Image]::FromFile((Join-Path $outDir "$($cells[$i]).png"))
    $g.DrawImage($img, 32 * $i, 0, $img.Width, $img.Height)
    $img.Dispose()
  }
  $g.Dispose()
  $sheet.Save((Join-Path $outDir "lue-sheet.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $sheet.Dispose()
  $exported += "lue-sheet  $(32 * $cells.Count)x32  (9 frames of 32x32: $($cells -join ', '))"
}

$exported | ForEach-Object { Write-Output $_ }
Write-Output "-> $outDir"
