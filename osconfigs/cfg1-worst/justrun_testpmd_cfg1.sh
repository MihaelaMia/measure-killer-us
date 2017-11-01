killall testpmd
: ${HOMEDIR?"Need to set DPDK_HOMEDIR"}
: ${P1?"Set P1"}
: ${P2?"Set P2"}

cd $HOMEDIR/bind
./bind_2p.sh
sleep 2

cd $HOMEDIR/workloads/dpdk

./x86_64-native-linuxapp-gcc/app/testpmd --lcores=0,1,2 -n 4 --master-lcore 0 -w $P1 -w $P2  -- --portmask 0x3 --nb-cores=2


