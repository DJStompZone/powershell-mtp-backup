$ErrorActionPreference = [string]"Continue"
$Summary = [Hashtable]@{NewFilesCount=0; ExistingFilesCount=0}

<#
.SYNOPSIS
  Creates a directory if it does not exist.
.DESCRIPTION
  This function checks if a directory exists at the specified path, and if it does not,
  it creates the directory.
.PARAMETER path
  The path of the directory to check or create.
#>
function Create-Dir($path)
{
  if(! (Test-Path -Path $path))
  {
    Write-Host "Creating: $path"
    New-Item -Path $path -ItemType Directory
  }
  else
  {
    Write-Host "Path $path already exists"
  }
}

<#
.SYNOPSIS
  Retrieves subfolders of a specified folder.
.DESCRIPTION
  This function returns a collection of subfolders for the specified folder.
.PARAMETER folder
  The folder to retrieve subfolders from.
#>
function Get-SubFolders($folder)
{
  $folder.GetFolder.Items() | Where-Object { $_.IsFolder }
}

<#
.SYNOPSIS
  Retrieves the main directory of a connected phone device.
.DESCRIPTION
  This function enumerates connected devices and allows the user to select one for backup.
#>
function Get-PhoneMainDir()
{
  $o = New-Object -com Shell.Application
  $rootComputerDirectory = $o.NameSpace(0x11)
  $devices = $rootComputerDirectory.Items() | Where-Object { $_.IsFolder }

  $deviceOptions = @{}
  $count = 1
  foreach ($device in $devices) {
    $deviceOptions.Add("$count", $device.Name)
    $count++
  }

  $selectedDevice = Show-Menu $deviceOptions
  $deviceDirectory = $rootComputerDirectory.Items() | Where-Object {$_.Name -eq $selectedDevice} | select -First 1
    
  if($deviceDirectory -eq $null)
  {
    throw "Device folder for '$selectedDevice' not found in This computer. Please connect your device as MTP / Media Transfer."
  }
  
  return $deviceDirectory;
}

<#
.SYNOPSIS
  Retrieves the full path of an MTP directory.
.DESCRIPTION
  This function constructs and returns the full path of the specified MTP directory.
.PARAMETER mtpDir
  The MTP directory to retrieve the full path for.
#>
function Get-FullPathOfMtpDir($mtpDir)
{
 $fullDirPath = ""
 $directory = $mtpDir.GetFolder
 while($directory -ne $null)
 {
   $fullDirPath =  -join($directory.Title, '\', $fullDirPath)
   $directory = $directory.ParentFolder;
 }
 return $fullDirPath
}

<#
.SYNOPSIS
  Copies content from a phone source directory to a backup destination.
.DESCRIPTION
  This function copies all files and subfolders from a specified source directory on the phone
  to a specified destination directory on the local machine.
.PARAMETER sourceMtpDir
  The source directory on the phone.
.PARAMETER destDirPath
  The destination directory on the local machine.
#>
function Copy-FromPhoneSource-ToBackup($sourceMtpDir, $destDirPath)
{
 Create-Dir $destDirPath
 $destDirShell = (new-object -com Shell.Application).NameSpace($destDirPath)
 $fullSourceDirPath = Get-FullPathOfMtpDir $sourceMtpDir
 
 Write-Host "Copying from: '" $fullSourceDirPath "' to '" $destDirPath "'"
 
 $copiedCount, $existingCount = 0
 
 foreach ($item in $sourceMtpDir.GetFolder.Items())
  {
   $itemName = ($item.Name)
   $fullFilePath = Join-Path -Path $destDirPath -ChildPath $itemName

   if($item.IsFolder)
   {
      Write-Host $item.Name " is folder, stepping into"
      Copy-FromPhoneSource-ToBackup  $item (Join-Path $destDirPath $item.GetFolder.Title)
   }
   elseif(Test-Path $fullFilePath)
   {
      Write-Host "Element '$itemName' already exists"
      $existingCount++;
   }
   else
   {
     $copiedCount++;
     Write-Host ("Copying #{0}: {1}{2}" -f $copiedCount, $fullSourceDirPath, $item.Name)
     $destDirShell.CopyHere($item)
   }
  }
  $script:Summary.NewFilesCount += $copiedCount 
  $script:Summary.ExistingFilesCount += $existingCount 
  Write-Host "Copied '$copiedCount' elements from '$fullSourceDirPath'"
}

<#
.SYNOPSIS
  Displays a menu of options and allows the user to make a selection.
.DESCRIPTION
  This function displays a list of options and prompts the user to select one.
.PARAMETER options
  A hashtable containing the menu options.
#>
function Show-Menu($options) {
    $options.Keys | ForEach-Object {
        Write-Host "$($_): $($options[$_])"
    }
    $selection = Read-Host "Please select an option (or press Enter to finish)"
    return $options[$selection]
}

<#
.SYNOPSIS
  Confirms if a directory is non-empty and prompts the user for confirmation.
.DESCRIPTION
  This function checks if a specified directory contains any files or subfolders,
  and prompts the user for confirmation if it is not empty.
.PARAMETER path
  The path of the directory to check.
#>
function Confirm-NonEmptyDir($path) {
    if (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue) {
        $confirmation = Read-Host "The destination directory '$path' is not empty. Do you want to continue? (y/n)"
        if ($confirmation -ne 'y') {
            throw "Operation cancelled by user."
        }
    }
}

# Get the device name dynamically
$phoneRootDir = Get-PhoneMainDir

# Dynamically enumerate folders on the device
$subFolders = Get-SubFolders $phoneRootDir
$backupOptions = @{}
$count = 1
foreach ($folder in $subFolders) {
    $backupOptions.Add("$count", $folder.Name)
    $count++
}

$selectedFolders = @()
do {
    $selectedFolder = Show-Menu $backupOptions
    if ($selectedFolder -ne $null -and $selectedFolders -notcontains $selectedFolder) {
        $selectedFolders += $selectedFolder
    }
} while ($selectedFolder -ne $null -and $selectedFolders.Count -lt $backupOptions.Count)

# Ask user for destination directory
$destRootDir = Read-Host "Please enter the root directory for the backup"

# Confirm if destination directory is non-empty
Confirm-NonEmptyDir $destRootDir

foreach ($folderName in $selectedFolders) {
    $destDirPath = Join-Path -Path $destRootDir -ChildPath $folderName # Destination path based on the folder name
    Copy-FromPhoneSource-ToBackup (Get-SubFolder $phoneRootDir $folderName) $destDirPath
}

write-host ($Summary | out-string)
