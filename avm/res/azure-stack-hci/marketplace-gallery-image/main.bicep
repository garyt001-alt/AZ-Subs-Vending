metadata name = 'Azure Stack HCI Marketplace Gallery Image'
metadata description = 'This module deploys an Azure Stack HCI Marketplace Gallery Image.'

@description('Required. Name of the resource to create.')
param name string

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object?

@description('Required. Resource ID of the associated custom location.')
param customLocationResourceId string

@description('Optional. Enable/Disable usage telemetry for module.')
param enableTelemetry bool = true

@description('Required. The properties of the marketplace gallery image.')
param marketplaceGalleryImageProperties marketplaceGalleryImagePropertiesType

import { roleAssignmentType } from 'br/public:avm/utl/types/avm-common-types:0.5.1'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

var builtInRoleNames = {
  // Add other relevant built-in roles here for your resource as per BCPNFR5
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'User Access Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
  )
  'Role Based Access Control Administrator (Preview)': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'f58310d9-a9f6-439a-9e8d-f62e7b41a168'
  )
}

var formattedRoleAssignments = [
  for (roleAssignment, index) in (roleAssignments ?? []): union(roleAssignment, {
    roleDefinitionId: builtInRoleNames[?roleAssignment.roleDefinitionIdOrName] ?? (contains(
        roleAssignment.roleDefinitionIdOrName,
        '/providers/Microsoft.Authorization/roleDefinitions/'
      )
      ? roleAssignment.roleDefinitionIdOrName
      : subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionIdOrName))
  })
]

// ============== //
// Resources      //
// ============== //

#disable-next-line no-deployments-resources
resource avmTelemetry 'Microsoft.Resources/deployments@2024-03-01' = if (enableTelemetry) {
  name: '46d3xbcp.res.azurestackhci-virtualharddisk.${replace('-..--..-', '.', '-')}.${substring(uniqueString(deployment().name, location), 0, 4)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
      outputs: {
        telemetry: {
          type: 'String'
          value: 'For more information, see https://aka.ms/avm/TelemetryInfo'
        }
      }
    }
  }
}

resource marketplaceGalleryImages 'Microsoft.AzureStackHCI/marketplaceGalleryImages@2024-10-01-preview' = {
  extendedLocation: {
    name: customLocationResourceId
    type: 'CustomLocation'
  }
  location: location
  name: name
  properties: marketplaceGalleryImageProperties
  tags: tags
}

resource marketplaceGalleryImages_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(
      marketplaceGalleryImages.id,
      roleAssignment.principalId,
      roleAssignment.roleDefinitionId
    )
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: marketplaceGalleryImages
  }
]

// ============ //
// Outputs      //
// ============ //

@description('The name of the virtual hard disk.')
output name string = marketplaceGalleryImages.name

@description('The resource ID of the virtual hard disk.')
output resourceId string = marketplaceGalleryImages.id

@description('The resource group of the virtual hard disk.')
output resourceGroupName string = resourceGroup().name

@description('The location of the virtual hard disk.')
output location string = marketplaceGalleryImages.location

// =============== //
//   Definitions   //
// =============== //

type galleryOSDiskImageType = {
  // Note: The API definition shows this as empty, so I'm defining it as an empty object
}

type galleryImageVersionStorageProfileType = {
  @description('Required. This is the OS disk image.')
  osDiskImage: galleryOSDiskImageType
}

type galleryImageVersionPropertiesType = {
  @description('Required. This is the storage profile of a Gallery Image Version.')
  storageProfile: galleryImageVersionStorageProfileType
}

type galleryImageVersionType = {
  @description('Required. This is the version of the gallery image.')
  name: string

  @description('Optional. Describes the properties of a gallery image version.')
  properties: galleryImageVersionPropertiesType?
}

type galleryImageIdentifierType = {
  @description('Required. The name of the gallery image definition publisher.')
  publisher: string

  @description('Required. The name of the gallery image definition offer.')
  offer: string

  @description('Required. The name of the gallery image definition SKU.')
  sku: string
}

@export()
type marketplaceGalleryImagePropertiesType = {
  @description('Optional. The container ID.')
  cloudInitDataSource: ('Azure' | 'NoCloud')?
  @description('Optional. The container ID.')
  containerId: string?
  @description('Required. The container URI.')
  hyperVGeneration: ('V1' | 'V2')
  @description('Required. The identifier of the gallery image.')
  identifier: galleryImageIdentifierType
  @description('Required. The OS type of the gallery image.')
  osType: 'Linux' | 'Windows'
  @description('Required. The version of the gallery image.')
  version: galleryImageVersionType
}
