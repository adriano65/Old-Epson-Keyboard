#!/bin/sh 
PATH="/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin"
sdcc p8051.c
packihx p8051.ihx > p8051.hex
objcopy -I ihex -O binary p8051.hex p8051.bin

exit 0


case "$1" in
        start)
		while [ 1 ];  do
			bash -c "ulimit -Sv 2000000; amule %u"
			#xhost +si:localuser:name
  		done
		;;
        stop)
		#MYPID=`ps -ef | grep amul | grep -v grep | awk '{print $1}'`
        	#echo $MYPID
  		#kill -9  $MYPID
  		killall -9 amule
  		killall -9 amule.sh
		;;
        *)
        	echo "usage start | stop"
		;;
esac
