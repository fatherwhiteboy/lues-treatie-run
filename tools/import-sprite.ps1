# Convert a sprite PNG into the game's pixel-array text format.
# Prints the palette (auto-assigned chars, by frequency) and the row grid.
# Usage: pwsh tools/import-sprite.ps1 <path-to-png>

param([Parameter(Mandatory = $true)][string]$Path)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$bmp = New-Object System.Drawing.Bitmap $Path
$w = $bmp.Width; $h = $bmp.Height
Write-Output "size: ${w}x${h}"

$alphabet = "tdlnwkogepabcfhijmqrsuvxyz".ToCharArray()
$colors = @{}   # "R,G,B" -> count
$semi = 0
for ($y = 0; $y -lt $h; $y++) {
  for ($x = 0; $x -lt $w; $x++) {
    $p = $bmp.GetPixel($x, $y)
    if ($p.A -eq 0) { continue }
    if ($p.A -lt 255) { $semi++ }
    $key = "$($p.R),$($p.G),$($p.B)"
    $colors[$key] = 1 + ($colors[$key] ?? 0)
  }
}
if ($semi) { Write-Output "WARNING: $semi semi-transparent pixels (treated as opaque)" }

# Cluster near-duplicate colors (editor jitter): any color within a small
# per-channel tolerance of a more frequent one merges into it.
$TOL = 6
$clusters = @()   # each: @{ rgb = int[3]; count = int }
$assignCluster = @{}   # "R,G,B" -> cluster index
foreach ($entry in ($colors.GetEnumerator() | Sort-Object -Property Value -Descending)) {
  $rgb = ($entry.Key -split ",") | ForEach-Object { [int]$_ }
  $found = -1
  for ($ci = 0; $ci -lt $clusters.Count; $ci++) {
    $c = $clusters[$ci].rgb
    if ([Math]::Abs($c[0]-$rgb[0]) -le $TOL -and [Math]::Abs($c[1]-$rgb[1]) -le $TOL -and [Math]::Abs($c[2]-$rgb[2]) -le $TOL) { $found = $ci; break }
  }
  if ($found -lt 0) {
    $clusters += @{ rgb = $rgb; count = $entry.Value }
    $found = $clusters.Count - 1
  } else {
    $clusters[$found].count += $entry.Value
  }
  $assignCluster[$entry.Key] = $found
}
if ($clusters.Count -gt $alphabet.Count) { throw "more than $($alphabet.Count) distinct color clusters" }

$assign = @{}
$clusterChar = @{}
$order = 0
foreach ($ci in (0..($clusters.Count - 1) | Sort-Object { -$clusters[$_].count })) {
  $clusterChar[$ci] = $alphabet[$order]
  $rgb = $clusters[$ci].rgb
  $hex = "#{0:x2}{1:x2}{2:x2}" -f $rgb[0], $rgb[1], $rgb[2]
  Write-Output ("palette: {0}: ""{1}"",   // {2} px" -f $alphabet[$order], $hex, $clusters[$ci].count)
  $order++
}
foreach ($key in $assignCluster.Keys) { $assign[$key] = $clusterChar[$assignCluster[$key]] }

Write-Output "rows:"
for ($y = 0; $y -lt $h; $y++) {
  $sb = New-Object System.Text.StringBuilder
  for ($x = 0; $x -lt $w; $x++) {
    $p = $bmp.GetPixel($x, $y)
    if ($p.A -eq 0) { [void]$sb.Append(".") }
    else { [void]$sb.Append($assign["$($p.R),$($p.G),$($p.B)"]) }
  }
  Write-Output ('    "' + $sb.ToString() + '",')
}
$bmp.Dispose()