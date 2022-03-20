## Backup Server to External NTFS Drives

$Bkp0_Label="Aux"
$Bkp0_Letter = Get-Volume -FileSystemLabel "$Bkp0_Label" | % DriveLetter

## 128GB Flash Drive I
$Bkp1_Label="Bkp128-I"
$Bkp1_Letter = Get-Volume -FileSystemLabel "$Bkp1_Label" | % DriveLetter
if (Test-Path -Path "${Bkp1_Letter}:\Ben"){
  echo "Starting backup on $Bkp1_Label..."
  robocopy \\files\Ben ${Bkp1_Letter}:\Ben /MIR /XJD /FFT /R:3 /W:10 /Z /XD `
    "\\files\Ben\ProOS\.ssh" "\\files\Ben\ProOS\.git" "\\files\Ben\ProOS\pve\vmbkps" "\\files\Ben\Software"
}else{
  echo "$Bkp1_Label not connected."
}
echo ""

## 128GB Flash Drive II
$Bkp2_Label="Bkp128-II"
$Bkp2_Letter = Get-Volume -FileSystemLabel "$Bkp2_Label" | % DriveLetter
if (Test-Path -Path "${Bkp2_Letter}:\Ben"){
  echo "Starting backup on $Bkp2_Label..."
  robocopy \\files\Ben ${Bkp2_Letter}:\Ben /MIR /XJD /FFT /R:3 /W:10 /Z /XD `
    "\\files\Ben\ProOS\.ssh" "\\files\Ben\ProOS\.git" "\\files\Ben\ProOS\pve\vmbkps" "\\files\Ben\Software"
}else{
  echo "$Bkp2_Label not connected."
}
echo ""

## 4TB Western Digital Red
$Bkp3_Label="Bkp4TBRed"
$Bkp3_Letter = Get-Volume -FileSystemLabel "$Bkp3_Label" | % DriveLetter
if (Test-Path -Path "${Bkp3_Letter}:\Ben"){
  echo "Starting backup on $Bkp3_Label..."
  robocopy \\files\Media ${Bkp3_Letter}:\Media /MIR /XJD /FFT /R:3 /W:10 /Z
  robocopy \\files\Ben ${Bkp3_Letter}:\Ben /MIR /XJD /FFT /R:3 /W:10 /Z /XD `
    "\\files\Ben\ProOS\.ssh" "\\files\Ben\ProOS\.git"
}else{
  echo "$Bkp3_Label not connected."
}
echo ""

exit

