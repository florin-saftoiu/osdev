param(
    [Parameter(Mandatory=$true)][string]$filename
)
"create vdisk file='$PSScriptRoot\$filename' maximum=10" | diskpart.exe
if ($LASTEXITCODE -eq 0) {
    $ErrorActionPreference = "Stop"
    $img = Mount-DiskImage -ImagePath "$PSScriptRoot\$filename" -PassThru -NoDriveLetter
    Initialize-Disk -Number $img.Number -PartitionStyle MBR
    $part = New-Partition -DiskNumber $img.Number -UseMaximumSize -IsActive
    Format-Volume -Partition $part -FileSystem exFAT -NewFileSystemLabel "OSDEV" -Full -Force
    Dismount-DiskImage -InputObject $img
} else {
    exit $LASTEXITCODE
}
