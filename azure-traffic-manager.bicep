// Azure Traffic Manager for Cat/Dog Voting App HA
// Provides external load balancing between Azure AKS and On-Premises

@description('Name for the Traffic Manager profile')
param profileName string = 'voting-app-tm'

@description('Resource group location')
param location string = resourceGroup().location

@description('Azure AKS endpoint (when cluster is running)')
param azureEndpoint string = '52.154.54.110'

@description('On-premises endpoint (always available)')
param onpremEndpoint string = '66.242.207.21'

@description('On-premises port')
param onpremPort int = 31514

resource trafficManagerProfile 'Microsoft.Network/trafficManagerProfiles@2022-04-01' = {
  name: profileName
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Priority'
    dnsConfig: {
      relativeName: profileName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
      intervalInSeconds: 30
      toleratedNumberOfFailures: 3
      timeoutInSeconds: 10
    }
    endpoints: [
      {
        name: 'azure-aks-primary'
        type: 'Microsoft.Network/trafficManagerProfiles/externalEndpoints'
        properties: {
          target: azureEndpoint
          endpointStatus: 'Enabled'
          priority: 1
          weight: 100
          endpointMonitorStatus: 'Online'
        }
      }
      {
        name: 'onprem-backup'
        type: 'Microsoft.Network/trafficManagerProfiles/externalEndpoints'  
        properties: {
          target: onpremEndpoint
          endpointStatus: 'Enabled'
          priority: 2
          weight: 100
          customHeaders: [
            {
              name: 'Host'
              value: '${onpremEndpoint}:${onpremPort}'
            }
          ]
          endpointMonitorStatus: 'Online'
        }
      }
    ]
  }
}

// Output the Traffic Manager FQDN
output trafficManagerFqdn string = trafficManagerProfile.properties.dnsConfig.fqdn
output trafficManagerUrl string = 'http://${trafficManagerProfile.properties.dnsConfig.fqdn}'

// Output individual endpoint status
output azureEndpoint string = 'Primary: ${azureEndpoint} (Priority 1)'
output onpremEndpoint string = 'Backup: ${onpremEndpoint}:${onpremPort} (Priority 2)'
