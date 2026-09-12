# The former Hetzner firewall resource is intentionally disabled.
# resource "hcloud_firewall" "wireguard_fw" {
#   name = "wireguard-firewall"
#
#   rule {
#     description = "SSH from my home IP"
#     direction   = "in"
#     protocol    = "tcp"
#     port        = "22"
#     source_ips = [
#       "${var.my_home_ip}/32",
#     ]
#   }
#
#   rule {
#     description = "WireGuard VPN"
#     direction   = "in"
#     protocol    = "udp"
#     port        = "51820"
#     source_ips = [
#       "0.0.0.0/0",
#       "::/0",
#     ]
#   }
#
#   rule {
#     description = "Allow ping"
#     direction   = "in"
#     protocol    = "icmp"
#     source_ips = [
#       "0.0.0.0/0",
#       "::/0",
#     ]
#   }
# }
