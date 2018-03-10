data "template_file" "provisioner_cloud_config" {
  vars {
    ssh_key = "${file("${var.ssh_key_location}")}"
  }

  template = <<EOF
#cloud-config

write_files:
  - encoding: gz+b64
    content: ${base64gzip(file("${var.matchbox_ca_file}"))}
    owner: root:root
    path: /etc/matchbox/ca.crt
    permissions: "0644"

  - encoding: gz+b64
    content: ${base64gzip(file("${var.matchbox_server_cert_file}"))}
    owner: root:root
    path: /etc/matchbox/server.crt
    permissions: "0644"

  - encoding: gz+b64
    content: ${base64gzip(file("${var.matchbox_server_cert_key}"))}
    owner: root:root
    path: /etc/matchbox/server.key
    permissions: "0644"

  - path: /etc/dnsmasq/hosts/${var.provisioner_node_name}
    content: |
      ${var.provisioner_ip} ${var.provisioner_node_name}
    owner: root:root
    permissions: "0644"

coreos:
  units:
    # set static ip
    - name: systemd-networkd.service
      command: stop

    - name: 00-${var.static_network_dev}.network
      runtime: true
      content: |
        [Match]
        Name=${var.static_network_dev}

        [Network]
        DNS=${var.upsteam_dns}
        Address=${var.provisioner_ip}/24
        Gateway=${var.subnet_gateway}

    - name: down-interfaces.service
      command: start
      content: |
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/ip link set ${var.static_network_dev} down
        ExecStart=/usr/bin/ip addr flush dev ${var.static_network_dev}

    - name: systemd-networkd.service
      command: restart

    - name: disable-locksmithd.service
      command: start
      content: |
        [Unit]
        Description=Disable locksmithd.service
        Before=locksmith.service

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/systemctl mask --now locksmithd.service

    - name: matchbox.service
      command: start
      content: |
        [Unit]
        Description=CoreOS matchbox Server
        Documentation=https://github.com/coreos/matchbox
        After=install_matchbox_cache.service

        [Service]
        Environment="IMAGE=quay.io/coreos/matchbox"
        Environment="VERSION=v0.7.0"
        Environment="MATCHBOX_ADDRESS=0.0.0.0:8080"
        Environment="MATCHBOX_RPC_ADDRESS=0.0.0.0:8081"
        ExecStartPre=/usr/bin/mkdir -p /etc/matchbox
        ExecStartPre=/usr/bin/mkdir -p /var/lib/matchbox/assets
        ExecStart=/usr/bin/docker run \
        -p 8080:8080 \
        -p 8081:8081 \
        --rm \
        -v /var/lib/matchbox:/var/lib/matchbox:Z \
        -v /etc/matchbox:/etc/matchbox:Z \
        <dollar>{IMAGE}:<dollar>{VERSION} \
        -address=<dollar>{MATCHBOX_ADDRESS} -rpc-address=<dollar>{MATCHBOX_RPC_ADDRESS} -log-level=debug
        [Install]
        WantedBy=multi-user.target

    - name: dnsmasq.service
      command: start
      content: |
        [Unit]
        Description=CoreOS dnsmasq Server
        Documentation=https://github.com/coreos/matchbox/tree/master/contrib/dnsmasq

        [Service]
        Environment="IMAGE=quay.io/coreos/dnsmasq"
        Environment="VERSION=v0.5.0"
        ExecStartPre=/usr/bin/mkdir -p /etc/dnsmasq/dhcp_hosts
        ExecStartPre=/usr/bin/mkdir -p /etc/dnsmasq/hosts
        ExecStart=/usr/bin/docker run \
        --rm --cap-add=NET_ADMIN --net=host \
        -v /etc/dnsmasq:/etc/dnsmasq:Z \
        <dollar>{IMAGE}:<dollar>{VERSION} \
        --no-daemon \
        --dhcp-range=${var.dhcp_range} \
        --enable-tftp \
        --tftp-root=/var/lib/tftpboot \
        --dhcp-option=3,${var.subnet_gateway} \
        --dhcp-match=set:bios,option:client-arch,0 \
        --dhcp-boot=tag:bios,undionly.kpxe \
        --dhcp-match=set:efi32,option:client-arch,6 \
        --dhcp-boot=tag:efi32,ipxe.efi \
        --dhcp-match=set:efibc,option:client-arch,7 \
        --dhcp-boot=tag:efibc,ipxe.efi \
        --dhcp-match=set:efi64,option:client-arch,9 \
        --dhcp-boot=tag:efi64,ipxe.efi \
        --dhcp-userclass=set:ipxe,iPXE \
        --dhcp-boot=tag:ipxe,http://${var.provisioner_node_name}:8080/boot.ipxe \
        --dhcp-hostsdir=/etc/dnsmasq/dhcp_hosts \
        --hostsdir=/etc/dnsmasq/hosts \
        --address=/${var.provisioner_node_name}/${var.provisioner_ip} \
        --log-queries=extra \
        --log-dhcp
        [Install]
        WantedBy=multi-user.target
ssh_authorized_keys:
  - $${ssh_key}
hostname: ${var.hostname}
EOF
}

resource "null_resource" "cloud_config_file" {
  triggers {
    template = "${data.template_file.provisioner_cloud_config.rendered}"
  }

  provisioner "local-exec" {
    command = "echo \"${data.template_file.provisioner_cloud_config.rendered}\" | sed 's/<dollar>/$$/g' > ${var.cloud_init_filename}"
  }
}

provider "vsphere" {
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_server}"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "${var.vshpere_datacenter}"
}

data "vsphere_datastore" "datastore" {
  name          = "${var.vshpere_datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.vsphere_resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "${var.vsphere_network}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template_from_ovf" {
  name          = "${var.vsphere_template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "provisioner" {
  name             = "${var.hostname}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = "${var.num_cpus}"
  memory   = "${var.memory_size_mb}"
  guest_id = "other26xLinux64Guest"

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template_from_ovf.network_interface_types[0]}"
  }

  disk {
    label = "disk0"
    size  = "${var.disk_size_gb}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template_from_ovf.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template_from_ovf.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template_from_ovf.id}"
  }

  vapp {
    properties {
      "guestinfo.coreos.config.data" = "${base64gzip(file("${var.cloud_init_filename}"))}"
      "guestinfo.coreos.config.data.encoding" = "gz+b64"
    }
  }
}
