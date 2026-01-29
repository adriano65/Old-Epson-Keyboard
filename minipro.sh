#!/bin/sh 
PATH="/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin"



case "$1" in
        r)
		/usr/local/src/minipro/minipro -p "AT89S52@DIP40" -i -r p8051-AT-read.bin
		;;
        w)
		/usr/local/src/minipro/minipro -p "AT89S52@DIP40" -i -w p8051-AT.bin -s
		;;
        i)
		/usr/local/src/minipro/minipro -p "AT89S52@DIP40" -i -D
		;;
        m)
		/usr/local/src/minipro/minipro -p "AT89S52@DIP40" -i -m /home/name/Keyboards/p8051-AT.bin -s
		;;
        c)
		cmp -l ~/Downloads/P8051-ori.bin p8051-AT.bin | gawk '{printf "%08X %02X %02X\n", $1-1, strtonum(0$2), strtonum(0$3)}' | less
		;;
        *)
        	echo "usage w (write) | i (identify) | m (verify) | r (read) | c (compare original)"
		;;
esac
exit 0

cmp -l ~/Keyboards/p8051-AT.bin p8051-AT.bin | gawk '{printf "%08X %02X %02X\n", $1-1, strtonum(0$2), strtonum(0$3)}' | less
