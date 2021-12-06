This Script read the Firewall Rules from a FortiGate Config Backup and Export it to CSV.

# How it's works
1. Download the .ps1 File and save it to your local Computer
2. Run the Script
`RulesToCSV.ps1 -FortiGateConfig <Path to your Backup File>`
3. The Script generate a new CSV File in the Folder from your Backup File

# Configuration
If you need to change the exported columns, check the `$includeColumns` Parameter in the .ps1 File and extend or change your needed Columns.
