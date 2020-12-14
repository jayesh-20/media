provider "azurerm" {
  #version = "=2.8.0"
  features {}
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

resource "azurerm_resource_group" "mediawiki" {
  name     = "${var.rgname}"
  location = "${var.Locn}"
}

resource "azurerm_virtual_network" "mediawiki" {
  name                = "mediawiki-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.mediawiki.location
  resource_group_name = azurerm_resource_group.mediawiki.name
}

resource "azurerm_subnet" "mediawiki" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.mediawiki.name
  virtual_network_name = azurerm_virtual_network.mediawiki.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "media" {
  name                    = "media-pip"
  location                = "${var.Locn}"
  resource_group_name     = azurerm_resource_group.mediawiki.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_interface" "mediawiki" {
  name                = "mediawiki-nic"
  location            = azurerm_resource_group.mediawiki.location
  resource_group_name = azurerm_resource_group.mediawiki.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mediawiki.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.media.id
  }
}

resource "azurerm_linux_virtual_machine" "mediawiki" {
  name                = "mediawiki-vm"
  resource_group_name = azurerm_resource_group.mediawiki.name
  location            = azurerm_resource_group.mediawiki.location
  size                = "Standard_A2"
  admin_username      = var.VM_Username
  admin_password      = var.VM_Password
  network_interface_ids = [azurerm_network_interface.mediawiki.id]

  #admin_ssh_key {
  #  username   = var.VM_Username
  #  public_key = file("~/.ssh/id_rsa.pub")
  #}

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

 connection {
    type     = "ssh"
    user     = self.admin_username
    host     = self.public_ip_address
    password = self.admin_password
    #private_key = "${file(var.key_path)}"
    port = 22
  }

 provisioner "file" {
    source      = "scripts/.my.cnf"
    destination = "/home/centosad/.my.cnf"
  }

  provisioner "file" {
    source      = "scripts/web.sh"
    destination = "/tmp/web.sh"
  }

  provisioner "file" {
    source      = "scripts/mariadb.sh"
    destination = "/tmp/mariadb.sh"
  }

  provisioner "file" {
    source      = "scripts/media.sh"
    destination = "/tmp/media.sh"
  }



  provisioner "file" {
    content = <<EOF
       yum install epel-release -y
       sed -i 's/enforcing/permissive/g' /etc/selinux/config
       setenforce permissive
       systemctl start firewalld
       systemctl enable firewalld
       yum -y install httpd php php-mysql php-gd php-xml php-mbstring
    EOF
    destination = "/tmp/setup1.sh"
  }

  provisioner "remote-exec" {
    inline = [
	"echo ${var.VM_Password} | sudo --stdin chmod a+x /tmp/*.sh",
        "echo ${var.VM_Password} | sudo -S sh -x /tmp/setup1.sh",
        "sleep 30",
	"echo ${var.VM_Password} | sudo -S sh -x /tmp/mariadb.sh",
        "sleep 30",
	"echo ${var.VM_Password} | sudo -S sh -x /tmp/media.sh",
        "sleep 30",
	"echo ${var.VM_Password} | sudo -S sh -x /tmp/web.sh",
        "echo ${var.VM_Password} | sudo -S init 6"
         ]

    on_failure = "continue"
  }


  identity {
    type = "SystemAssigned"
   }

  disable_password_authentication = false

  tags = {
    Tier              = "App"
    ENV               = "PROD"
    SLA               = "99.99"
   }
}
