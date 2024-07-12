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
