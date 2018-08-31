provider "azurerm" {}

resource "azurerm_resource_group" "main" {
  name = "main"
  location = "Australia South East"

  tags {
    environment = "staging"
  }
}

locals {
  jumphost_name = "jumphost"
  default_username = "admin_user"
}

resource "azurerm_virtual_network" "main" {
  name = "main"
  address_space = ["10.0.0.0/16"]
  location = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  tags {
    environment = "staging"
  }
}

resource "azurerm_subnet" "dmz" {
  name = "dmz"
  resource_group_name = "${azurerm_resource_group.main.name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix = "10.0.1.0/24"
}
  
resource "azurerm_network_interface" "jumphost" {
  name = "${local.jumphost_name}-nic"
  location = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name = "${local.jumphost_name}-ip-config"
    subnet_id = "${azurerm_subnet.dmz.id}"
    private_ip_address_allocation = "static"
    private_ip_address = "10.0.1.4"
  }

  tags {
    environment = "staging"
  }
}

resource "azurerm_virtual_machine" "jumphost" {
  name = "${local.jumphost_name}"
  location = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_interface_ids = [
    "${azurerm_network_interface.jumphost.id}"
  ]
  vm_size = "Standard_A1_v2"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "OpenLogic"
    offer = "CentOS"
    sku = "7.5"
    version = "latest"
  }
  
  storage_os_disk {
    name = "jumphost_osdisk_1"
    caching = "ReadWrite"
    create_option = "FromImage"
    # Use SSDs for OS.
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name = "${local.jumphost_name}"
    admin_username = "${local.default_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = "${file("~/.ssh/id_rsa.pub")}"
      path = "/home/${local.default_username}/.ssh/authorized_keys"
    }
  }

  tags {
    environment = "staging"
  }
}
