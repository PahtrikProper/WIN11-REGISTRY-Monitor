
# Registry Monitor Script

## Description

This PowerShell script monitors the entire Windows Registry (specifically the HKEY_LOCAL_MACHINE hive) for changes. It logs changes, including MAC and IP addresses, and displays a Windows pop-up notification if an external source might have initiated the change by checking network connectivity.

## Dependencies

### PowerShell Modules

- **BurntToast**: Used to create and display toast notifications on Windows 10 and Windows 11.

### Installation

To install the BurntToast module, run the following command in PowerShell:
```powershell
Install-Module -Name BurntToast -Force -Scope CurrentUser
```

## How the Script Works

1. **Network Information**: The script collects MAC and IP addresses of the network adapters on the machine.
2. **Registry Change Logging**: When a change is detected in the registry, the script logs the change along with network information to a specified log file.
3. **External Connection Check**: The script checks for an active internet connection to determine if the registry change might have been initiated by an external source.
4. **Alert Notification**: If an external connection is detected, the script sends a Windows pop-up notification using the BurntToast module.

## Usage Instructions

1. Replace `C:\path\to\your\logfile.txt` in the script with the desired path for your log file.
2. Save the script as `RegistryMonitor.ps1`.
3. Open PowerShell as an Administrator.
4. Navigate to the directory where you saved `RegistryMonitor.ps1`.
5. Execute the script:
   ```powershell
   .\RegistryMonitor.ps1
   ```

## Script Content

```powershell
# Define the log file path
$logFilePath = "C:\path\to\your\logfile.txt"

# Function to get MAC and IP addresses
function Get-NetworkInfo {
    $networkAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'"
    $networkInfo = @()
    
    foreach ($adapter in $networkAdapters) {
        $networkInfo += [PSCustomObject]@{
            MACAddress = $adapter.MACAddress
            IPAddress = $adapter.IpAddress[0]
        }
    }
    
    return $networkInfo
}

# Function to log information
function Log-RegistryChange {
    param (
        [string]$message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $networkInfo = Get-NetworkInfo
    $networkDetails = $networkInfo | ForEach-Object { "MAC: $_.MACAddress, IP: $_.IPAddress" } | Out-String
    
    $logEntry = "$timestamp - $message`n$networkDetails"
    Add-Content -Path $logFilePath -Value $logEntry
    
    # Check for external connection
    if (Test-Connection -ComputerName www.google.com -Count 1 -Quiet) {
        # Assume this as an external source if connected to the internet
        Send-Alert -message "External source might have initiated a registry change: $message"
    }
}

# Function to send an alert
function Send-Alert {
    param (
        [string]$message
    )
    
    # Show a Windows pop-up notification
    New-BurntToastNotification -Text "Registry Change Alert", $message
}

# Set up a WMI event watcher
$eventWatcher = New-Object System.Management.ManagementEventWatcher
$query = "SELECT * FROM RegistryKeyChangeEvent WHERE Hive='HKEY_LOCAL_MACHINE'"
$eventWatcher.Query = $query
$eventWatcher.Scope = "root\default"

# Define the action to take when an event is detected
$eventWatcher.EventArrived += {
    Log-RegistryChange -message "Registry change detected in HKEY_LOCAL_MACHINE"
}

# Start monitoring
$eventWatcher.Start()

# Keep the script running
while ($true) {
    Start-Sleep -Seconds 10
}
```

## Notes

- Ensure your system's security policies allow the execution of PowerShell scripts and WMI access.
- The script needs to be run with administrative privileges to access the registry and network information.
