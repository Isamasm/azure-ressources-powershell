# Azure VM Deployment Guide - PowerShell

## Prerequisites

- Azure subscription
- Azure PowerShell module installed: `Install-Module -Name Az -AllowClobber -Scope CurrentUser`
- Logged into Azure: `Connect-AzAccount`

## Step 1: Set Variables

Define all the variables for your deployment:

```powershell
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
```

## Step 2: Create Resource Group

```powershell
New-AzResourceGroup -Name $resourceGroup -Location $location
```

## Step 3: Create Network Security Group (NSG)

Create NSG with rules for RDP (Windows) or SSH (Linux):

```powershell
# Create RDP rule (for Windows VMs)
$rdpRule = New-AzNetworkSecurityRuleConfig `
    -Name "AllowRDP" `
    -Description "Allow RDP" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1000 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 3389

# For Linux VMs, create SSH rule instead:
# $sshRule = New-AzNetworkSecurityRuleConfig `
#     -Name "AllowSSH" `
#     -Description "Allow SSH" `
#     -Access Allow `
#     -Protocol Tcp `
#     -Direction Inbound `
#     -Priority 1000 `
#     -SourceAddressPrefix Internet `
#     -SourcePortRange * `
#     -DestinationAddressPrefix * `
#     -DestinationPortRange 22

# Create HTTP rule (optional)
$httpRule = New-AzNetworkSecurityRuleConfig `
    -Name "AllowHTTP" `
    -Description "Allow HTTP" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1001 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 80

# Create HTTPS rule (optional)
$httpsRule = New-AzNetworkSecurityRuleConfig `
    -Name "AllowHTTPS" `
    -Description "Allow HTTPS" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1002 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 443

# Create the NSG
$nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -Name $nsgName `
    -SecurityRules $rdpRule,$httpRule,$httpsRule
```

## Step 4: Create Virtual Network and Subnet

```powershell
# Create subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -AddressPrefix $subnetAddressPrefix `
    -NetworkSecurityGroup $nsg

# Create virtual network
$vnet = New-AzVirtualNetwork `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -Name $vnetName `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $subnetConfig
```

## Step 5: Create Public IP Address

```powershell
$publicIp = New-AzPublicIpAddress `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -Name $publicIpName `
    -AllocationMethod Static `
    -Sku Standard
```

## Step 6: Create Network Interface Card (NIC)

```powershell
# Get the subnet
$subnet = Get-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -VirtualNetwork $vnet

# Create NIC
$nic = New-AzNetworkInterface `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -Name $nicName `
    -SubnetId $subnet.Id `
    -PublicIpAddressId $publicIp.Id `
    -NetworkSecurityGroupId $nsg.Id
```

## Step 7: Create Virtual Machine Configuration

```powershell
# Create VM configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize

# Set operating system
$vmConfig = Set-AzVMOperatingSystem `
    -VM $vmConfig `
    -Windows `
    -ComputerName $vmName `
    -Credential $credential `
    -ProvisionVMAgent `
    -EnableAutoUpdate

# For Linux VMs, use this instead:
# $vmConfig = Set-AzVMOperatingSystem `
#     -VM $vmConfig `
#     -Linux `
#     -ComputerName $vmName `
#     -Credential $credential `
#     -DisablePasswordAuthentication

# Set source image
$vmConfig = Set-AzVMSourceImage `
    -VM $vmConfig `
    -PublisherName $publisherName `
    -Offer $offer `
    -Skus $skus `
    -Version $version

# Add NIC to VM
$vmConfig = Add-AzVMNetworkInterface `
    -VM $vmConfig `
    -Id $nic.Id

# Set OS disk
$vmConfig = Set-AzVMOSDisk `
    -VM $vmConfig `
    -CreateOption FromImage `
    -StorageAccountType "Standard_LRS"
```

## Step 8: Create the Virtual Machine

```powershell
New-AzVM `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -VM $vmConfig
```

## Step 9: Verify Deployment

```powershell
# Get VM details
Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName

# Get public IP address
Get-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $publicIpName | Select-Object IpAddress

# Get VM status
Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName -Status
```

## Single-Line Command (One-Liner)

Here's the entire deployment as a single PowerShell command. Just change the variables at the beginning:

```powershell
Connect-AzAccount; $resourceGroup = "myResourceGroup"; $location = "eastus"; $vnetName = "myVNet"; $vnetAddressPrefix = "10.0.0.0/16"; $subnetName = "mySubnet"; $subnetAddressPrefix = "10.0.1.0/24"; $nsgName = "myNSG"; $publicIpName = "myPublicIP"; $nicName = "myNIC"; $vmName = "myVM"; $vmSize = "Standard_B2s"; $adminUsername = "azureadmin"; $adminPassword = ConvertTo-SecureString "YourSecurePassword123!" -AsPlainText -Force; $credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword); New-AzResourceGroup -Name $resourceGroup -Location $location; $rdpRule = New-AzNetworkSecurityRuleConfig -Name "AllowRDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389; $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name $nsgName -SecurityRules $rdpRule; $subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix -NetworkSecurityGroup $nsg; $vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location -Name $vnetName -AddressPrefix $vnetAddressPrefix -Subnet $subnetConfig; $publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $location -Name $publicIpName -AllocationMethod Static -Sku Standard; $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet; $nic = New-AzNetworkInterface -ResourceGroupName $resourceGroup -Location $location -Name $nicName -SubnetId $subnet.Id -PublicIpAddressId $publicIp.Id -NetworkSecurityGroupId $nsg.Id; $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize; $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $credential -ProvisionVMAgent -EnableAutoUpdate; $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2022-Datacenter" -Version "latest"; $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id; $vmConfig = Set-AzVMOSDisk -VM $vmConfig -CreateOption FromImage -StorageAccountType "Standard_LRS"; New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig; Get-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $publicIpName | Select-Object IpAddress
```

## Single Command for Linux VM

For a Linux VM with SSH:

```powershell
Connect-AzAccount; $resourceGroup = "myResourceGroup"; $location = "eastus"; $vnetName = "myVNet"; $vnetAddressPrefix = "10.0.0.0/16"; $subnetName = "mySubnet"; $subnetAddressPrefix = "10.0.1.0/24"; $nsgName = "myNSG"; $publicIpName = "myPublicIP"; $nicName = "myNIC"; $vmName = "myVM"; $vmSize = "Standard_B2s"; $adminUsername = "azureadmin"; $adminPassword = ConvertTo-SecureString "YourSecurePassword123!" -AsPlainText -Force; $credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword); New-AzResourceGroup -Name $resourceGroup -Location $location; $sshRule = New-AzNetworkSecurityRuleConfig -Name "AllowSSH" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22; $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name $nsgName -SecurityRules $sshRule; $subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix -NetworkSecurityGroup $nsg; $vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location -Name $vnetName -AddressPrefix $vnetAddressPrefix -Subnet $subnetConfig; $publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $location -Name $publicIpName -AllocationMethod Static -Sku Standard; $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet; $nic = New-AzNetworkInterface -ResourceGroupName $resourceGroup -Location $location -Name $nicName -SubnetId $subnet.Id -PublicIpAddressId $publicIp.Id -NetworkSecurityGroupId $nsg.Id; $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize; $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Linux -ComputerName $vmName -Credential $credential; $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-jammy" -Skus "22_04-lts-gen2" -Version "latest"; $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id; $vmConfig = Set-AzVMOSDisk -VM $vmConfig -CreateOption FromImage -StorageAccountType "Standard_LRS"; New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig; Get-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $publicIpName | Select-Object IpAddress
```

## Complete Script (Multi-line for readability)

If you prefer the complete script format:

```powershell
# Login to Azure
Connect-AzAccount

# Variables
$resourceGroup = "myResourceGroup"
$location = "eastus"
$vnetName = "myVNet"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetName = "mySubnet"
$subnetAddressPrefix = "10.0.1.0/24"
$nsgName = "myNSG"
$publicIpName = "myPublicIP"
$nicName = "myNIC"
$vmName = "myVM"
$vmSize = "Standard_B2s"
$adminUsername = "azureadmin"
$adminPassword = ConvertTo-SecureString "YourSecurePassword123!" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword)

# Create Resource Group
New-AzResourceGroup -Name $resourceGroup -Location $location

# Create NSG Rules
$rdpRule = New-AzNetworkSecurityRuleConfig -Name "AllowRDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389

# Create NSG
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name $nsgName -SecurityRules $rdpRule

# Create Subnet
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix -NetworkSecurityGroup $nsg

# Create VNet
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location -Name $vnetName -AddressPrefix $vnetAddressPrefix -Subnet $subnetConfig

# Create Public IP
$publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $location -Name $publicIpName -AllocationMethod Static -Sku Standard

# Create NIC
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet
$nic = New-AzNetworkInterface -ResourceGroupName $resourceGroup -Location $location -Name $nicName -SubnetId $subnet.Id -PublicIpAddressId $publicIp.Id -NetworkSecurityGroupId $nsg.Id

# Create VM Config
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize
$vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $credential -ProvisionVMAgent -EnableAutoUpdate
$vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2022-Datacenter" -Version "latest"
$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id
$vmConfig = Set-AzVMOSDisk -VM $vmConfig -CreateOption FromImage -StorageAccountType "Standard_LRS"

# Create VM
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig

# Get Public IP
Get-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $publicIpName | Select-Object IpAddress
```

## Cleanup (Optional)

To remove all resources:

```powershell
Remove-AzResourceGroup -Name $resourceGroup -Force
```
