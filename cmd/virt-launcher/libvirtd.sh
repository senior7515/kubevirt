#!/bin/bash
#
# This file is part of the KubeVirt project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright 2017 Red Hat, Inc.
#

set -xev

mkdir -p /var/log/kubevirt
touch /var/log/kubevirt/qemu-kube.log
chown qemu:qemu /var/log/kubevirt/qemu-kube.log

env >> /var/run/kubevirt/$(date +"%s").environ.log

# If no main interface is specified, take the first non-loopback device
if [[ -z "$LIBVIRTD_DEFAULT_NETWORK_DEVICE" ]]; then
    LIBVIRTD_DEFAULT_NETWORK_DEVICE=$(ip -o -4 a | tr -s ' ' | cut -d' ' -f 2 | grep -v -e '^lo[0-9:]*$' | head -1)
    echo "Selected \"$LIBVIRTD_DEFAULT_NETWORK_DEVICE\" as primary interface"
fi

# We create the network on a file basis to not
# have to wait for libvirtd to come up
if [[ -n "$LIBVIRTD_DEFAULT_NETWORK_DEVICE" ]]; then
    echo "Setting libvirt default network to \"$LIBVIRTD_DEFAULT_NETWORK_DEVICE\""
    mkdir -p /etc/libvirt/qemu/networks/autostart
    # for network_file in /var/run/libvirt/etc/libvirt/qemu/networks/*xml; do
    #     echo "Copying external network file: ${network_file}"
    #     network_file=$(basename ${network_file})
    #     cp "/var/run/kubevirt/etc/libvirt/qemu/networks/${network_file}" "/etc/libvirt/qemu/networks/${network_file}"
    # done
    if [[ -e /var/run/libvirt/nui.xml ]]; then
        cp /var/run/libvirt/nui.xml /etc/libvirt/qemu/networks/
    fi
    for network_file in /etc/libvirt/qemu/networks/*xml; do
        echo "Linking network file: ${network_file}"
        network_file=$(basename ${network_file})
        ln -s -f "/etc/libvirt/qemu/networks/${network_file}" "/etc/libvirt/qemu/networks/autostart/${network_file}"
    done

fi

echo "cgroup_controllers = [ ]" >>/etc/libvirt/qemu.conf

/usr/sbin/libvirtd
