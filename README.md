# terraform-vmware-matchbox
This setup matchbox provisioner and dnsmasq in vmware for k8s bootstrap. The created VM will provide DHCP, TFTP/HTTP, DNS to help bootstrap a k8s cluster from PXE on vmware/bare-metal.

# Prerequisite
Generate certs and keys in ./asserts for matchbox, please refer to [matchbox document](https://github.com/coreos/matchbox/tree/master/scripts/tls).

# Usage
```bash
git clone https://github.com/bunnyyiu/terraform-vmware-matchbox.git
cd terraform-vmware-matchbox
#edit example.tfvars according to your environemnt

terraform init
terraform plan --var-file=example.tfvars
terraform apply --var-file=example.tfvars
```

# Config dhcp hosts and dns entry
add /etc/dnsmasq/dhcp_hosts/k8s in format mac:hostname:ip:lease_time
```
00:50:56:af:00:01,master-1,192.168.100.101,infinite
00:50:56:af:00:02,master-2,192.168.100.102,infinite
00:50:56:af:00:03,master-3,192.168.100.103,infinite
00:50:56:af:00:04,node-1,192.168.100.104,infinite
00:50:56:af:00:05,node-2,192.168.100.105,infinite
00:50:56:af:00:06,node-3,192.168.100.106,infinite
```

add /etc/dnsmasq/hosts/k8s in format "ip domain_name"
```
192.168.100.101 dev1.cluster.k8s.local
192.168.100.102 dev1.cluster.k8s.local
192.168.100.103 dev1.cluster.k8s.local
192.168.100.101 master-1.dev1.cluster.k8s.local
192.168.100.102 master-2.dev1.cluster.k8s.local
192.168.100.103 master-3.dev1.cluster.k8s.local
192.168.100.104 node-1.dev1.cluster.k8s.local
192.168.100.105 node-2.dev1.cluster.k8s.local
192.168.100.106 node-3.dev1.cluster.k8s.local
```

# Config matchbox to bootstrap k8s.
Please refer to [typhoon example](https://typhoon.psdn.io/bare-metal/).
