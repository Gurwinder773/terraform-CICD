terraform {
  
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.12.0"
    }
  }
}


provider "azurerm" {
  features {}
  subscription_id = "7c4d33cc-5fa6-47d0-9aaa-505138f64d92"
  client_id       = "58ee68b7-b696-4aa1-b586-2f0af1f5098e"
  client_secret   = "jnZ8Q~C2NmMp5OASmOLyvRFn54wK3Gn0efy3nbHk"
  tenant_id       = "3eff799d-0a57-4672-b97f-3690098ef323"
}



 resource "azurerm_resource_group" "azurerm" {
  name     = "rg1"
  location = "Canada East"
}
resource "azurerm_virtual_network" "vnet" {
  name                = "terraformNetwork"
  location            = azurerm_resource_group.azurerm.location
  resource_group_name = azurerm_resource_group.azurerm.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
}
resource "azurerm_subnet" "subnet" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.azurerm.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_network_security_group" "NSG" {
  name                = "TestSecurityGroup"
  location            = azurerm_resource_group.azurerm.location
  resource_group_name = azurerm_resource_group.azurerm.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}
resource "azurerm_public_ip" "publicip" {
  name                = "TestPublicIp"
  resource_group_name = azurerm_resource_group.azurerm.name
  location            = azurerm_resource_group.azurerm.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}
resource "azurerm_network_interface" "nic" {
  name                = "Test-nic"
  location            = azurerm_resource_group.azurerm.location
  resource_group_name = azurerm_resource_group.azurerm.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_virtual_machine" "main" {
  name                  = "Terraform-VM"
  location              = azurerm_resource_group.azurerm.location
  resource_group_name   = azurerm_resource_group.azurerm.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version ="latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password12345"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}
