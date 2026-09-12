# The former Hetzner firewall attachment is intentionally disabled.
# resource "hcloud_firewall_attachment" "wireguard_fw_attachment" {
#   firewall_id = hcloud_firewall.wireguard_fw.id
#   server_ids  = [var.server_id]
# }
