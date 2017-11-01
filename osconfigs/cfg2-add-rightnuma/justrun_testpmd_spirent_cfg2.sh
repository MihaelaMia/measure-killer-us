killall testpmd
: ${HOMEDIR?"Need to set HOMEDIR"}
cd $HOMEDIR/bind
./bind_2p.sh
sleep 2

cd $HOMEDIR/workloads/dpdk

./x86_64-native-linuxapp-gcc/app/testpmd --lcores=27,28,29 -n 4 --master-lcore 27 -w $P1 -w $P2  -- --portmask 0x3 --nb-cores=2 --socket-num=1


