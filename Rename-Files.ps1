$lookIn = '.\pics'

$CharWhiteList = '[^: \w\/]'
$Shell = New-Object -ComObject shell.application

$lastDateTaken = Get-Date
$i = 1

Get-ChildItem -Path $lookIn -Filter *.jpg -Recurse -File | ForEach-Object {
    $dir = $Shell.Namespace($_.DirectoryName)
    $dateTakenString = $dir.GetDetailsOf($dir.ParseName($_.Name), 12) -replace $CharWhiteList
    $fileName = $_.FullName

    try {
        $dateTaken = [datetime]::ParseExact($dateTakenString, "dd/MM/yyyy HH:mm", [CultureInfo]::InvariantCulture)
    } catch {
        Write-Host "Could not parse date for '$fileName'. Value was: '$dateTakenString'"
        return
    }

    $fileDetails = [PSCustomObject]@{
        FullName = $_.FullName
        DateTaken = $dateTaken
    }

    $fileDetails

} | Sort-Object DateTaken | ForEach-Object {
    if ($lastDateTaken.Date -ne $_.DateTaken.Date) {
        $i = 1
        $lastDateTaken = $_.DateTaken
    }

    Rename-Item $_.FullName ('{0:yyyyMMdd HHmm}_{1:0000}.jpg' -f $_.DateTaken, $i++) -WhatIf
}
