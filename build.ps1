# dev.html(여러 파일) → index.html(파일 하나) 로 묶기
# 실행: powershell -ExecutionPolicy Bypass -File build.ps1
# js/ 나 css/ 를 고친 뒤에는 이걸 다시 실행하고 index.html 만 올리면 됩니다.
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
$html = [System.IO.File]::ReadAllText((Join-Path $root 'dev.html'), $utf8)

# <link rel="stylesheet" href="로컬 파일"> → <style>내용</style>
$html = [regex]::Replace($html, '<link rel="stylesheet" href="(?!https?:)([^"]+)">', {
  param($m)
  $css = [System.IO.File]::ReadAllText((Join-Path $root $m.Groups[1].Value), $utf8)
  "<style>`n$css`n</style>"
})

# <script src="로컬 파일"></script> → <script>내용</script>  (CDN 주소는 그대로)
$html = [regex]::Replace($html, '<script src="(?!https?:)([^"]+)"></script>', {
  param($m)
  $js = [System.IO.File]::ReadAllText((Join-Path $root $m.Groups[1].Value), $utf8)
  "<script>/* $($m.Groups[1].Value) */`n$js`n</script>"
})

# 아이콘 파일(href="icon.svg" / "icon-180.png") → data: 주소로 넣기 (파일 하나만 올려도 아이콘이 보이도록)
$html = [regex]::Replace($html, 'href="(?!https?:|data:)([^"]+\.(svg|png))"', {
  param($m)
  $bytes = [System.IO.File]::ReadAllBytes((Join-Path $root $m.Groups[1].Value))
  $mime = if ($m.Groups[2].Value -eq 'svg') { 'image/svg+xml' } else { 'image/png' }
  'href="data:' + $mime + ';base64,' + [Convert]::ToBase64String($bytes) + '"'
})

$out = Join-Path $root 'index.html'
[System.IO.File]::WriteAllText($out, $html, $utf8)
Write-Host ("Built index.html ({0:N0} KB)" -f ((Get-Item $out).Length / 1KB))
