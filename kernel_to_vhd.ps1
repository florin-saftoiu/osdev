param(
    [Parameter(Mandatory=$true)][string]$filename,
    [Parameter(Mandatory=$true)][string]$kernel
)
$ErrorActionPreference = "Stop"
$img = Mount-DiskImage -ImagePath "$PSScriptRoot\$filename" -PassThru -NoDriveLetter
New-Item -ItemType Directory -Path "$PSScriptRoot\mnt_$filename"
Add-PartitionAccessPath -DiskNumber $img.Number -PartitionNumber 1 -AccessPath "$PSScriptRoot\mnt_$filename"
$kernelSize = (Get-Item -Path "$PSScriptRoot\$kernel").length
Write-Output "Kernel size = $kernelSize"
$kernelClusters = [int] ($kernelSize / 4096)
if ($kernelSize % 4096 -ne 0) {
    $kernelClusters += 1
}
Write-Output "Kernel clusters = $kernelClusters"
$totalClusters = 2256 - 2 - 1 - 2 # 2 for the root directory, 1 for the allocation bitmap, 2 for the up-case table
$filesClusters = $totalClusters - $kernelClusters
$leftoverClusters = $filesClusters % 42
$fileClusters = ($filesClusters - $leftoverClusters) / 42
Write-Output "Temp 1 clusters = 1"
Write-Output "Files clusters = $filesClusters => $fileClusters per file"
Write-Output "Leftover clusters = $leftoverClusters"
Write-Output "Temp 2 clusters = $($kernelClusters - 1)"
$val = "X" * 4096
New-Item -ItemType file -Path "$PSScriptRoot\mnt_$filename\temp_1.txt" -Value $val
$val = "F" * $fileClusters * 4096
for ($i = 1; $i -le 42; $i++) {
    New-Item -ItemType file -Path "$PSScriptRoot\mnt_$filename\file_$i.txt" -Value $val
}
if ($leftoverClusters -ne 0) {
    $val = "L" * $leftoverClusters * 4096
    New-Item -ItemType file -Path "$PSScriptRoot\mnt_$filename\leftover.txt" -Value $val
}
$val = "Y" * ($kernelClusters - 1) * 4096
New-Item -ItemType file -Path "$PSScriptRoot\mnt_$filename\temp_2.txt" -Value $val
Remove-Item -Path "$PSScriptRoot\mnt_$filename\temp_1.txt"
Remove-Item -Path "$PSScriptRoot\mnt_$filename\temp_2.txt"
Copy-Item -Path "$PSScriptRoot\$kernel" -Destination "$PSScriptRoot\mnt_$filename\kernel.bin"
Dismount-DiskImage -InputObject $img
Remove-Item -Force -Path "$PSScriptRoot\mnt_$filename"
