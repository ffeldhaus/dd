function dd {
    [CmdletBinding()]

    PARAM (
        [parameter(
                Mandatory=$True,
                Position=0,
                HelpMessage="Input file.")][String]$InFile,
        [parameter(
                Mandatory=$True,
                Position=1,
                HelpMessage="Output file.")][String]$OutFile,
        [parameter(
                Mandatory=$False,
                Position=2,
                HelpMessage="Block Size.")][String]$BlockSize,
        [parameter(
                Mandatory=$False,
                Position=3,
                HelpMessage="Count.")][String]$Count
    )

    $InFile = $InFile -replace "^if=",""
    $OutFile = $OutFile -replace "^of=",""
    $BlockSize = $BlockSize -replace "^bs=",""
    $BlockSize = $BlockSize -replace "([a-zA-Z])",'$1b'
    $BlockSize = $BlockSize / 1
    $Count = $Count -replace "^count=",""
    $Count = $Count -replace "([a-zA-Z])",'$1b'
    $Count = $Count / 1

    $ByteBuffer = [Byte[]]::new($BlockSize)

    $Duration = Measure-Command {
        if ($InFile -eq "/dev/zero") {
            if (!$BlockSize -or !$Count) {
                Throw "bs and count are required when specifying an input device!"
            }
            $TotalMb = $Count / 1 * $BlockSize / 1MB
            if ($OutFile -eq "/dev/null") {
                for ($i = 0; $i -lt $Count; $i++) {
                    $PercentCompleted = $i / $Count * 100
                    $CopiedMb = $i * $BlockSize / 1MB
                    Write-Progress -Activity "Copy from $OutFile to $InFile in progress" -Status "$($CopiedMb)MiB/$($TotalMb)MiB ($PercentCompleted%)" -PercentComplete $PercentCompleted
                }
            }
            else {
                $null = New-Item -Path $OutFile -Force
                $OutputStream = [System.IO.FileStream]::new($OutFile, [System.IO.FileMode]::Open)
                for ($i = 0; $i -lt $Count; $i++) {
                    $PercentCompleted = $i / $Count * 100
                    $CopiedMb = $i * $BlockSize / 1MB
                    Write-Progress -Activity "Copy from $OutFile to $InFile in progress" -Status "$($CopiedMb)MiB/$($TotalMb)MiB ($PercentCompleted%)" -PercentComplete $PercentCompleted

                    $OutputStream.Write($ByteBuffer, 0, $ByteBuffer.Length)
                }
                $OutputStream.Close()
                $OutputStream.Dispose()
            }
        }
        elseif ($InFile -eq "/dev/random" -or $InFile -eq "/dev/urandom") {
            if (!$BlockSize -or !$Count) {
                Throw "bs and count are required when specifying an input device!"
            }
            $TotalMb = $Count / 1 * $BlockSize / 1MB
            $Random = [System.Random]::new()
            if ($OutFile -eq "/dev/null") {
                for ($i = 0; $i -lt $Count; $i++) {
                    $PercentCompleted = $i / $Count * 100
                    $CopiedMb = $i * $BlockSize / 1MB
                    Write-Progress -Activity "Copy from $OutFile to $InFile in progress" -Status "$($CopiedMb)MiB/$($TotalMb)MiB ($PercentCompleted%)" -PercentComplete $PercentCompleted

                    $Random.NextBytes($ByteBuffer)
                }
            }
            else {
                $null = New-Item -Path $OutFile -Force
                $OutputStream = [System.IO.FileStream]::new($OutFile, [System.IO.FileMode]::Open)
                for ($i = 0; $i -lt $Count; $i++) {
                    $PercentCompleted = $i / $Count * 100
                    $CopiedMb = $i * $BlockSize / 1MB
                    Write-Progress -Activity "Copy from $OutFile to $InFile in progress" -Status "$($CopiedMb)MiB/$($TotalMb)MiB ($PercentCompleted%)" -PercentComplete $PercentCompleted

                    $Random.NextBytes($ByteBuffer)
                    $OutputStream.Write($ByteBuffer, 0, $ByteBuffer.Length)
                }
                $OutputStream.Close()
                $OutputStream.Dispose()
            }
        }
        else {
            $TotalMb = ([System.IO.FileInfo]$InFile).Length / 1MB
            $InputStream = [System.IO.FileStream]::new($InFile, [System.IO.FileMode]::Open)

            if ($OutFile -eq "/dev/null") {
                for ($i = 0; $i -lt $Count; $i++) {
                    $PercentCompleted = $i / $Count * 100
                    $CopiedMb = $i * $BlockSize / 1MB                    
                    Write-Progress -Activity "Copy from $OutFile to $InFile in progress" -Status "$($CopiedMb)MiB/$($TotalMb)MiB ($PercentCompleted%)" -PercentComplete $PercentCompleted

                    $InputStream.Read($ByteBuffer, 0, $ByteBuffer.Length)
                }
            }
            else {
                $null = New-Item -Path $OutFile -Force
                $OutputStream = [System.IO.FileStream]::new($OutFile, [System.IO.FileMode]::Open)
                $InputStream.CopyTo($OutputStream)
            }
            $InputStream.Close()
            $InputStream.Dispose()
            $OutputStream.Close()
            $OutputStream.Dispose()
        }
        Write-Progress -Activity "Copy from $OutFile to $InFile completed" -PercentComplete 100 -Completed
    }
    $Throughput = $TotalMb / $Duration.TotalSeconds
    Write-Host "$($TotalMb)MiB copied, $([Math]::Ceiling($Duration.TotalSeconds))s, $([Math]::Round($Throughput,2))MiB/s"
}
