# a working set for gx-scs
#
cloud_provider    = "gx-scs"
availability_zone = "nova"
external          = "ext01"
kind_flavor       = "SCS-2V:4:20"
controller_flavor = "SCS-2V:4:20"
worker_flavor     = "SCS-2V:4:20"
image             = "Ubuntu 20.04"
ssh_username      = "ubuntu"
kube_image_raw    = "true"
dns_nameservers   = ["62.138.222.111", "62.138.222.222"]
#controller_count  = 0
