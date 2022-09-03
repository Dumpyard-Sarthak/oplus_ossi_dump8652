#!/vendor/bin/sh
#
#ifdef OPLUS_FEATURE_ZRAM_OPT
function configure_read_ahead_kb_values() {
	MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	MemTotal=${MemTotalStr:16:8}
	erofs_ra_kb=128

	dmpts=$(ls /sys/block/*/queue/read_ahead_kb | grep -e dm -e mmc)

	# Set 128 for <= 3GB &
	# set 512 for >= 4GB targets.
	if [ $MemTotal -le 4194304 ]; then
		ra_kb=128
	else
		ra_kb=512
	fi

	if [ -f /sys/block/mmcblk0/bdi/read_ahead_kb ]; then
		echo $ra_kb > /sys/block/mmcblk0/bdi/read_ahead_kb
	fi
	if [ -f /sys/block/mmcblk0rpmb/bdi/read_ahead_kb ]; then
		echo $ra_kb > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
	fi

	for dm in $dmpts; do
		# mtk configure dm-[0-5], so we don't need rewrite here.
		ignore=`echo $dm | grep 'dm-[0-5]/'`
		if [ ! -z "$ignore" ]; then
			continue
		fi

		dm_dev=`echo $dm |cut -d/ -f4`
		if [ "$dm_dev" = "" ]; then
			is_erofs=""
		else
			is_erofs=`mount |grep erofs |grep "${dm_dev} "`
		fi
		if [ "$is_erofs" = "" ]; then
			echo $ra_kb > $dm
		else
			echo $erofs_ra_kb > $dm
		fi
	done
}

    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

    echo lz4 > /sys/block/zram0/comp_algorithm
    echo 160 > /proc/sys/vm/swappiness
    echo 60 > /proc/sys/vm/direct_swappiness
    echo 0 > /proc/sys/vm/page-cluster
    if [ -f /sys/block/zram0/disksize ]; then
        if [ -f /sys/block/zram0/use_dedup ]; then
            echo 1 > /sys/block/zram0/use_dedup
        fi

        if [ $MemTotal -le 524288 ]; then
            #config 384MB zramsize with ramsize 512MB
            echo 402653184 > /sys/block/zram0/disksize
        elif [ $MemTotal -le 1048576 ]; then
            #config 768MB zramsize with ramsize 1GB
            echo 805306368 > /sys/block/zram0/disksize
        elif [ $MemTotal -le 2097152 ]; then
            #config 1GB+256MB zramsize with ramsize 2GB
            echo lz4 > /sys/block/zram0/comp_algorithm
            echo 1342177280 > /sys/block/zram0/disksize
        elif [ $MemTotal -le 3145728 ]; then
            #config 1GB+512MB zramsize with ramsize 3GB
            echo lz4 > /sys/block/zram0/comp_algorithm
            echo 1610612736 > /sys/block/zram0/disksize
        elif [ $MemTotal -le 4194304 ]; then
            #config 2GB zramsize with ramsize 4GB
            echo lz4 > /sys/block/zram0/comp_algorithm
            echo 2147483648 > /sys/block/zram0/disksize
            echo 2 > /proc/sys/vm/kswapd_threads
        elif [ $MemTotal -le 6291456 ]; then
            #config 3GB zramsize with ramsize 6GB
            echo 3221225472 > /sys/block/zram0/disksize
        else
            #config 4GB zramsize with ramsize >=8GB
            echo 4294967296 > /sys/block/zram0/disksize
        fi

	configure_read_ahead_kb_values

        /vendor/bin/mkswap /dev/block/zram0
        /vendor/bin/swapon /dev/block/zram0
    fi

#endif /* OPLUS_FEATURE_ZRAM_OPT */
