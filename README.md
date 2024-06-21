# powershell-mtp-file-transfer
Powershell scripts to to back up folders from an MTP-connected device (such as a smartphone or tablet) to a specified directory on your Windows local machine. The lastest script, `Backup-MTPDeviceRecursive.ps1`, dynamically enumerates available devices and folders, providing an interactive menu for the user to select what to back up and where to save it.

## TL;DR
Uses `Shell.Application` object to interact with Windows explorer API to copy from device connected via MTP Protocol.

## New Features
- Dynamically lists connected devices.
- Allows the user to select which device to back up.
- Enumerates folders on the selected device and allows the user to choose which ones to back up.
- Prompts the user to specify a destination directory for the backup.
- Confirms if the destination directory is non-empty before proceeding.
- Recursively copies the selected folders to the specified destination.

## Requirements
- Windows PowerShell
- An Android device connected via MTP (Media Transfer Protocol)

## Example Usage

### Backup-MTPDeviceRecursive.ps1

  1. **Connect your device** to your computer via USB and ensure it is set to MTP mode.
  2. **Run the script** in PowerShell.
  
  ```powershell
  .\Backup-MTPDeviceRecursive.ps1
  ```
  
  3. **Follow the prompts**:
     - Select the device you want to back up.
     - Select the folders you want to back up.
     - Enter the root directory for the backup on your local machine.
     - Confirm if the destination directory is non-empty.
  
  4. The script will copy the selected folders from your device to the specified destination directory.
  
  ## Script Breakdown
  
  ### Functions
  
  - **`Create-Dir`**: Checks if a directory exists and creates it if it doesn't.
  - **`Get-SubFolders`**: Retrieves subfolders of a specified folder.
  - **`Get-PhoneMainDir`**: Lists connected devices and allows the user to select one.
  - **`Get-FullPathOfMtpDir`**: Constructs the full path of an MTP directory.
  - **`Copy-FromPhoneSource-ToBackup`**: Copies content from a phone source directory to a backup destination.
  - **`Show-Menu`**: Displays a menu of options and allows the user to make a selection.
  - **`Confirm-NonEmptyDir`**: Checks if a directory is non-empty and prompts the user for confirmation.
  
  ## Example
  
  Here is a sample interaction with `Backup-MTPDeviceRecursive.ps1`:
  
  ```
  Please select an option (or press Enter to finish)
  1: Galaxy Tab S3
  2: Phone
  1
  Please select an option (or press Enter to finish)
  1: DCIM
  2: Pictures
  3: Music
  1
  Please enter the root directory for the backup
  E:\GalaxyTabBackup
  The destination directory 'E:\GalaxyTabBackup' is not empty. Do you want to continue? (y/n)
  y
  Copying from: 'Galaxy Tab S3\DCIM\' to 'E:\GalaxyTabBackup\DCIM\'
  ...
  ```
  *(Device name and backup directory shown above are for demonstration purposes and will likely differ for each user)*



### TODO

 - **Usage instructions for older scripts**

## Notes
- Ensure your device is properly connected and set to MTP mode before running the script.
- The script assumes the device's directories are accessible via MTP.
- Sometimes the  `Shell.Application` doesn't detect all files unless the folder on phone to be backed up was opened in Windows Explorer previously

