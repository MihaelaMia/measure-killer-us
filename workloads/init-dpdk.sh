wget http://dpdk.org/browse/dpdk/snapshot/dpdk-17.02.tar.gz
tar -xvzf dpdk-17.02.tar.gz
rm dpdk-17.02.tar.gz
cd dpdk-17.02
make install T=x86_64-native-linuxapp-gcc -j
