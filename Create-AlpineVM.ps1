#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Automates the creation of a Hyper-V virtual machine for Alpine Linux with Dynamic Memory.
#>

# --- 1. CONFIGURE YOUR VM VARIABLES HERE ---
$VMName = "AlpineLinux-PS"
$VHDPath = "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks"
$ISOPath = "C:\Users\ifirdaus\Downloads\alpine-standard-3.22.1-x86_64.iso"
$StartupMemory = 512MB            # Startup memory for the VM
$MinimumMemory = 512MB            # Minimum memory for Dynamic Memory
$MaximumMemory = 2GB              # Maximum memory for Dynamic Memory
$VHDSize = 10GB                 # Size of the virtual disk
$SwitchName = "Default Switch"  # Name of the virtual switch to use

# --- 2. SCRIPT EXECUTION ---

# Construct the full path for the VHDX file
$FullVHDPath = Join-Path -Path $VHDPath -ChildPath "$($VMName).vhdx"

# Check if the VHD directory exists, create if not
if (-not (Test-Path -Path $VHDPath -PathType Container)) {
    Write-Host "Creating directory for VHD at $VHDPath..."
    New-Item -Path $VHDPath -ItemType Directory | Out-Null
}

Write-Host "Creating a $($VHDSize / 1GB)GB fixed virtual hard disk at $($FullVHDPath)..."
# Create a new fixed-size VHD for better performance
New-VHD -Path $FullVHDPath -SizeBytes $VHDSize -Fixed

Write-Host "Creating Virtual Machine '$($VMName)'..."
# Create the Generation 2 VM
New-VM -Name $VMName `
    -MemoryStartupBytes $StartupMemory `
    -Generation 2 `
    -VHDPath $FullVHDPath `
    -SwitchName $SwitchName

Write-Host "Enabling and configuring Dynamic Memory for '$($VMName)'..."
# Enable Dynamic Memory and set the minimum and maximum values
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes $MinimumMemory -MaximumBytes $MaximumMemory -StartupBytes $StartupMemory

Write-Host "Disabling Secure Boot for '$($VMName)'..."
# Disable Secure Boot (required for Alpine Linux)
Set-VMFirmware -VMName $VMName -EnableSecureBoot Off

Write-Host "Attaching ISO file '$($ISOPath)'..."
# Add a DVD drive and mount the Alpine ISO
Add-VMDvdDrive -VMName $VMName
Set-VMDvdDrive -VMName $VMName -Path $ISOPath

Write-Host "Setting boot order to DVD Drive..."
# Get the DVD drive object to set it as the first boot device
$DvdDrive = Get-VMDvdDrive -VMName $VMName
Set-VMFirmware -VMName $VMName -FirstBootDevice $DvdDrive

# --- 3. COMPLETION ---
Write-Host -ForegroundColor Green "VM '$($VMName)' created successfully with Dynamic Memory!"
Write-Host "You can now start the VM in Hyper-V Manager and run the 'setup-alpine' command to install."