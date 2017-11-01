#!/bin/bash

for cpuf in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo -n performance >  $cpuf; done

MAX_FREQ=`cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq`
#MAX_FREQ=2201000
echo $MAX_FREQ
for cf in /sys/devices/system/cpu/*/cpufreq/scaling_min_freq; do echo -n $MAX_FREQ > $cf; done
for cf in /sys/devices/system/cpu/*/cpufreq/scaling_max_freq; do echo -n $MAX_FREQ > $cf; done

