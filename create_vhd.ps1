param(
    [Parameter(Mandatory=$true)][string]$filename,
    [Parameter(Mandatory=$true)][string]$kernel
)
"create vdisk file='$PSScriptRoot\$filename' maximum=10" | diskpart.exe
if ($LASTEXITCODE -eq 0) {
    $ErrorActionPreference = "Stop"
    $img = Mount-DiskImage -ImagePath "$PSScriptRoot\$filename" -PassThru -NoDriveLetter
    Initialize-Disk -Number $img.Number
    $part = New-Partition -DiskNumber $img.Number -UseMaximumSize
    Format-Volume -Partition $part -FileSystem exFAT -NewFileSystemLabel "OSDEV" -Full -Force
    New-Item -ItemType Directory -Path "$PSScriptRoot\mnt_$filename"
    Add-PartitionAccessPath -DiskNumber $img.Number -PartitionNumber 1 -AccessPath "$PSScriptRoot\mnt_$filename"
    Copy-Item -Path "$PSScriptRoot\$kernel" -Destination "$PSScriptRoot\mnt_$filename"
    Dismount-DiskImage -InputObject $img
    Remove-Item -Force -Path "$PSScriptRoot\mnt_$filename"
} else {
    exit $LASTEXITCODE
}
