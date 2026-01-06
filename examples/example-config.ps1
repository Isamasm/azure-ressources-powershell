# Resource Group
$resourceGroup = "myResourceGroup"
$location = "eastus"

# Networking
$vnetName = "myVNet"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetName = "mySubnet"
$subnetAddressPrefix = "10.0.1.0/24"
$nsgName = "myNSG"
$publicIpName = "myPublicIP"
$nicName = "myNIC"

# Virtual Machine
$vmName = "myVM"
$vmSize = "Standard_B2s"
$publisherName = "MicrosoftWindowsServer"
$offer = "WindowsServer"
$skus = "2022-Datacenter"
$version = "latest"

# Credentials
$adminUsername = "azureadmin"
$adminPassword = ConvertTo-SecureString "YourSecurePassword123!" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword)
