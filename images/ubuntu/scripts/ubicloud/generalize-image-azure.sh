#!/bin/bash -xe

source $HELPER_SCRIPTS/os.sh

# To able run this image in Ubicloud, we need to remove some Azure specific
# configurations

sleep 30

# It's Hyper-V Key Value Pair daemon, which is not needed in Ubicloud
# It blocks booting the VM if it's not disabled
systemctl disable hv-kvp-daemon.service

# Remove Hyper-V line from chrony config file
sed -i 's/^refclock PHC \/dev\/ptp_hyperv/# &/' /etc/chrony/chrony.conf
systemctl restart chronyd

# Delete the Azure Linux Agent
apt -y purge walinuxagent
rm -rf /var/lib/waagent
rm -f /var/log/waagent.log

# Delete Azure specific cloud-init config files
rm -rf /etc/cloud/cloud.cfg.d/90-azure.cfg
rm -rf /etc/cloud/cloud.cfg.d/10-azure-kvp.cfg

# Delete Azure specific grub config files
rm -rf /etc/default/grub.d/40-force-partuuid.cfg
rm -rf /etc/default/grub.d/50-cloudimg-settings.cfg
