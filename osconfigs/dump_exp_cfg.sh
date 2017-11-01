if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    exit
fi


dir=$1

if [ ! -d "$dir" ]; then
    mkdir $dir
fi
cd $dir

cat /proc/cmdline > exp-cmdline.txt

cat /sys/devices/system/cpu/intel_pstate/no_turbo >  exp-noturbo.txt
cat /sys/module/processor/parameters/ignore_ppc > exp-ignore_ppc.txt
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > exp-scaling_governors.txt
cat /sys/devices/system/cpu/*/cpufreq/scaling_min_freq > exp-scaling_min_freq.txt
cat /sys/devices/system/cpu/*/cpufreq/scaling_max_freq > exp-scaling_max_freq.txt
cat /sys/devices/system/cpu/*/cpuidle/state[1-9]/disable >  exp-scaling_cstate_disable.txt
cat /sys/bus/workqueue/devices/writeback/numa > exp-writeback_numa.txt

#dump services
chkconfig --list > exp-chkconfig_services.txt
systemctl list-unit-files >  exp-unit_files_services.txt

cat /proc/irq/default_smp_affinity >  exp-default_smp_affinity.txt
cat /proc/irq/*/smp_affinity >  exp-smp_affinity.txt
cat /sys/class/net/*/queues/*/*cpus >  exp-queues_cpu_affinity.txt
cat /proc/sys/kernel/nmi_watchdog > exp-nmi_watchdog.txt
cat /proc/sys/kernel/numa_balancing > exp-numa_balancing.txt
cat /sys/devices/system/cpu/intel_pstate/min_perf_pct > exp-pstate_min.txt
cat /sys/bus/workqueue/devices/writeback/cpumask >  exp-writeback_cpumask.txt
cat /sys/bus/workqueue/devices/writeback/numa >  exp-writeback_numa.txt
cat /opt/linux-4.4.35/.config > exp-kernel_config.txt


