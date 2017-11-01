: ${HOMEDIR?"Need to set HOMEDIR"}
: ${P1?"Need to set P1"}
: ${P2?"Need to set P2"}


cd $HOMEDIR/workloads

python dpdk-17.02/tools/dpdk-devbind.py -u 0000:05:00.0 0000:05:00.1 0000:05:00.2 0000:05:00.3 0000:81:00.0 0000:81:00.1 0000:81:00.2 0000:81:00.3 0000:83:00.0 0000:83:00.1 0000:83:00.2 0000:83:00.3 0000:85:00.0 0000:85:00.1 0000:85:00.2 0000:85:00.3

#python dpdk-17.02/tools/dpdk-devbind.py -b uio_pci_generic $P1 $P2
python dpdk-17.02/tools/dpdk-devbind.py -b igb_uio $P1 $P2

