#cloud-config

# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

write_files:
  - path: /etc/sysctl.conf
    permissions: "0644"
    owner: root
    content: |
      net.ipv4.ip_forward = 1
      net.ipv6.conf.all.forwarding = 1
      # https://tldp.org/HOWTO/Adv-Routing-HOWTO/lartc.kernel.rpf.html
      net.ipv4.conf.all.rp_filter = 2
package_update: true
package_upgrade: true
package_reboot_if_required: true
packages:
  - iftop
  - tcpdump
runcmd:
  - sysctl -p
  - ip rule add from ${ip_cidr_range} to 35.191.0.0/16 lookup 102
  - ip rule add from ${ip_cidr_range} to 130.211.0.0/22 lookup 102
  - ip route add default via ${cidrhost(ip_cidr_range, 1)} dev ens5 proto static onlink table 102
  - ip route add ${endpoint}/32 via ${cidrhost(ip_cidr_range, 1)} dev ens5
  - iptables -t nat -A POSTROUTING -j MASQUERADE
  - iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination "${endpoint}"  