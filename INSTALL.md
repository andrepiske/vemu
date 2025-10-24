
Debian dependencies:

apt-get install -y --no-install-recommends ovmf uml-utilities


ip tuntap add dev tap0 mode tap
ip link set dev tap0 master br0
ip link set tap0 up


.vemu/
+- base-images/
|  +- ubuntu-24.04-server-cloudimg-amd64.img
