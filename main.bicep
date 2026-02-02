@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the VM instance')
param vmName string

@description('VM size (default tuned for low-cost substrate)')
param vmSize string = 'Standard_B2s'

@description('Optional source image ID. If empty, Ubuntu 22.04 LTS marketplace image is used.')
param sourceImageId string = ''

@description('Source address prefix allowed to SSH')
param sshSourceAddressPrefix string = '0.0.0.0/0'

var ubuntuImageReference = {
  publisher: 'Canonical'
  offer: '0001-com-ubuntu-server-jammy'
  sku: '22_04-lts-gen2'
  version: 'latest'
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 300
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: sshSourceAddressPrefix
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: empty(sourceImageId)
        ? ubuntuImageReference
        : {
            id: sourceImageId
          }
    }
    osProfile: {
      computerName: vmName
      adminUsername: 'azureuser'
      linuxConfiguration: {
        disablePasswordAuthentication: true
      }
    }
    networkProfile: {
      networkInterfaces: []
    }
  }
}
