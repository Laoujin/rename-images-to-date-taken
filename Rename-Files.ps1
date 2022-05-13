$lookIn = '.\'

$CharWhiteList = '[^: \w\/]'
$Shell = New-Object -ComObject shell.application
$i = 1

Get-ChildItem -Path $lookIn -Filter *.jpg -Recurse -File | ForEach-Object {
    $dir = $Shell.Namespace($_.DirectoryName)
    $DateTaken = [DateTime]($dir.GetDetailsOf($dir.ParseName($_.Name),12) -replace $CharWhiteList)
    Rename-Item $_.FullName ('{0:yyyyMMdd HHmm}_{1:0000}.jpg' -f $DateTaken, $i++) # -WhatIf
}
