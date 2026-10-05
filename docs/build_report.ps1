# Optional Windows helper: make a standalone HTML report and printable PDF.
# Run after run_project. Requires Microsoft Edge for the PDF export only.
$ErrorActionPreference='Stop'
$docsPath=$PSScriptRoot
$sourcePath=Join-Path $docsPath 'engineering_report.md'
$htmlPath=Join-Path $docsPath 'engineering_report.html'
$pdfPath=Join-Path $docsPath 'engineering_report.pdf'
function Format-Inline([string]$value) {
    $escaped=[System.Net.WebUtility]::HtmlEncode($value)
    $escaped=[regex]::Replace($escaped,'`([^`]+)`','<code>$1</code>')
    return [regex]::Replace($escaped,'\[([^\]]+)\]\(([^)]+)\)','<a href="$2">$1</a>')
}
$html=New-Object System.Text.StringBuilder
[void]$html.AppendLine('<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Protection Coordination with Distributed Solar</title><style>body{font-family:Arial,sans-serif;color:#182638;line-height:1.5;max-width:1080px;margin:40px auto;padding:0 20px}h1{font-size:28px;color:#164c75}h2{font-size:20px;color:#164c75;margin-top:30px}p,li{font-size:14px}code{background:#eef3f7;font-size:12px;padding:2px 4px;overflow-wrap:anywhere}table{border-collapse:collapse;width:100%;font-size:11px;margin:16px 0}th,td{border:1px solid #b9c8d4;padding:6px;text-align:left}th{background:#edf3f8}img{width:100%;height:auto}a{color:#164c75}figure{margin:20px 0;break-inside:avoid}figcaption{font-size:12px;color:#536475}@page{size:A4;margin:16mm}@media print{body{margin:0;padding:0;max-width:none}h2{break-after:avoid}p{orphans:3;widows:3}table{break-inside:avoid}a{text-decoration:none}}</style></head><body>')
$inTable=$false; $tableRow=0
foreach($line in [System.IO.File]::ReadAllLines($sourcePath)) {
    if($line.StartsWith('|')) {
        if(-not $inTable){[void]$html.AppendLine('<table>'); $inTable=$true; $tableRow=0}
        if($line -match '^\|[-: |]+\|$'){continue}
        $cells=$line.Trim('|').Split('|'); $tag=if($tableRow -eq 0){'th'}else{'td'}
        [void]$html.Append('<tr>')
        foreach($cell in $cells){[void]$html.Append('<'+$tag+'>'+(Format-Inline $cell.Trim())+'</'+$tag+'>')}
        [void]$html.AppendLine('</tr>'); $tableRow++; continue
    }
    if($inTable){[void]$html.AppendLine('</table>'); $inTable=$false}
    if([string]::IsNullOrWhiteSpace($line)){continue}
    if($line -match '^!\[([^\]]*)\]\(([^)]+)\)$') {
        $caption=$Matches[1]; $imagePath=Join-Path $docsPath $Matches[2]
        $encoded=[Convert]::ToBase64String([System.IO.File]::ReadAllBytes($imagePath))
        [void]$html.AppendLine('<figure><img alt="'+[System.Net.WebUtility]::HtmlEncode($caption)+'" src="data:image/png;base64,'+$encoded+'"><figcaption>'+[System.Net.WebUtility]::HtmlEncode($caption)+'</figcaption></figure>'); continue
    }
    if($line -match '^(#{1,6}) (.*)$') {
        $level=$Matches[1].Length; [void]$html.AppendLine('<h'+$level+'>'+(Format-Inline $Matches[2])+'</h'+$level+'>'); continue
    }
    if($line.StartsWith('- ')){[void]$html.AppendLine('<p>&bull; '+(Format-Inline $line.Substring(2))+'</p>'); continue}
    [void]$html.AppendLine('<p>'+(Format-Inline $line)+'</p>')
}
if($inTable){[void]$html.AppendLine('</table>')}
[void]$html.AppendLine('</body></html>')
[System.IO.File]::WriteAllText($htmlPath,$html.ToString(),(New-Object System.Text.UTF8Encoding($false)))
$edge='C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
if(Test-Path -LiteralPath $edge) {
    $profile=Join-Path $env:TEMP ('solar-protection-report-'+[guid]::NewGuid().ToString())
    $reportUri=(New-Object System.Uri($htmlPath)).AbsoluteUri
    $arguments=@('--headless','--disable-gpu','--no-pdf-header-footer',('--user-data-dir="'+$profile+'"'),('--print-to-pdf="'+$pdfPath+'"'),('"'+$reportUri+'"'))
    $process=Start-Process -FilePath $edge -ArgumentList $arguments -WindowStyle Hidden -PassThru -Wait
    if(-not (Test-Path -LiteralPath $pdfPath)){throw 'PDF export did not produce a file'}
    Write-Output ('Created PDF: '+$pdfPath)
} else {
    Write-Output ('Created standalone HTML: '+$htmlPath+'. Open it in a browser and print to PDF.')
}
