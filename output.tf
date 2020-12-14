output "public_ip_address" {
  value = "${azurerm_public_ip.media.ip_address}"
}
