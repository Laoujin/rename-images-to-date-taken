$lookIn = 'C:\temp\wout-rename\pics'

$CharWhiteList = '[^: \w\/]'
$Shell = New-Object -ComObject shell.application
$dateFormats = "dd/MM/yyyy HH:mm", "d/MM/yyyy HH:mm"

$lastDateTaken = Get-Date
$i = 1

Get-ChildItem -Path $lookIn -Include *.jpeg, *.png, *.gif, *.jpg, *.bmp, *.png, *.mp4 -Recurse -File | ForEach-Object {
    $dir = $Shell.Namespace($_.DirectoryName)

    $lcid = 12 # CLID for 'Date taken'
    if ($_.Extension -eq ".mp4") {
        $lcid = 208 # CLID for 'Media created'
    }

    $dateTakenString = $dir.GetDetailsOf($dir.ParseName($_.Name), $lcid) -replace $CharWhiteList
    $error = $null
    $lastWriteTime = $_.LastWriteTime # Cache values because in a catch, $_ is replaced with the exception?
    $fullName = $_.FullName

    if ([string]::IsNullOrEmpty($dateTakenString)) {
        # TODO: there are also files named: IMG-20220404-WA0000.jpg
        # Try file format 20220320_102830.jpg
        $dateTakenString = $_.Name.Substring(0, 13)
        try {
            $dateTaken = [datetime]::ParseExact($dateTakenString, "yyyyMMdd_HHmm", [CultureInfo]::InvariantCulture)
        } catch {
            $dateTaken = $lastWriteTime
        }

    } else {
        try {
            $dateTaken = [datetime]::ParseExact($dateTakenString, [string[]]$dateFormats, [CultureInfo]::InvariantCulture)
        } catch {
            $error = "Could not parse date for '$fullName'. Value was: '$dateTakenString'"
            return
        }
    }

    $fileDetails = [PSCustomObject]@{
        FullName = $_.FullName
        DateTaken = $dateTaken
        Extension = $_.Extension
        Error = $error
    }

    $fileDetails

} | Where-Object { $_.FullName -ne $null } | Sort-Object DateTaken | ForEach-Object {
    if ($lastDateTaken.Date -ne $_.DateTaken.Date) {
        $i = 1
        $lastDateTaken = $_.DateTaken
    }

    $outputFileName = ("{0:yyyyMMdd HHmm}_{1:0000}" -f $_.DateTaken, $i++)
    # echo "input is $($_.FullName) -- output is $outputFileName$($_.Extension)"

    # TODO: Remove the -WhatIf to actually rename the files:
    Rename-Item $_.FullName "$outputFileName$($_.Extension)" -WhatIf
    if ($_.Error) {
        Write-Host "ERREUR" $_.Error
    }
}
