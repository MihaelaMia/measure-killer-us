cd MoonGen
./build.sh

#possible automake version issues
cd ../netperf
./configure --enable-histogram --enable-burst --enable-intervals
make

cd ../trex-core/linux_dpdk
./b configure
./b build

