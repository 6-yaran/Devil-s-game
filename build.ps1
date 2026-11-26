# Bundle dev.html (many files) into index.html (one file).
# Run: powershell -ExecutionPolicy Bypass -File build.ps1
# After editing js/ or css/, run this and upload index.html.
# The phone icon files (apple-touch-icon.png, icon-192.png, icon-512.png, icon-maskable-512.png,
# icon.svg, manifest.webmanifest) only need uploading when they change. Keep them all at the top level.
# (Comments are ASCII on purpose: Windows PowerShell 5.1 misreads non-ASCII text in BOM-less scripts.)
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
$html = [System.IO.File]::ReadAllText((Join-Path $root 'dev.html'), $utf8)

# <link rel="stylesheet" href="local file"> -> <style>...</style>
$html = [regex]::Replace($html, '<link rel="stylesheet" href="(?!https?:)([^"]+)">', {
  param($m)
  $css = [System.IO.File]::ReadAllText((Join-Path $root $m.Groups[1].Value), $utf8)
  "<style>`n$css`n</style>"
})

# <script src="local file"></script> -> <script>...</script>  (CDN URLs stay as they are)
$html = [regex]::Replace($html, '<script src="(?!https?:)([^"]+)"></script>', {
  param($m)
  $js = [System.IO.File]::ReadAllText((Join-Path $root $m.Groups[1].Value), $utf8)
  "<script>/* $($m.Groups[1].Value) */`n$js`n</script>"
})

# Inline only the browser-tab icon (href="icon.svg") as a data: URL; the title logo reuses it.
# Phone home-screen icons and the manifest must be real files (phones ignore data: URLs there).
$html = [regex]::Replace($html, 'href="(?!https?:|data:|/)([^"]+\.svg)"', {
  param($m)
  $bytes = [System.IO.File]::ReadAllBytes((Join-Path $root $m.Groups[1].Value))
  'href="data:image/svg+xml;base64,' + [Convert]::ToBase64String($bytes) + '"'
})

$out = Join-Path $root 'index.html'
[System.IO.File]::WriteAllText($out, $html, $utf8)
Write-Host ("Built index.html ({0:N0} KB)" -f ((Get-Item $out).Length / 1KB))
