# Old-Epson-Keyboard

These are my studies on that old keyboard.
I desoldered original p8051 microcontroller
and substituted with AT89S52...
and it works :-)

---------------------- following there are some notes:

EPSON Q203A Keyboard
PCB -> N86D
Intel P8051AH
Standard XT  (no AT no new PC's)
board - N86D-4700-R101/01 BUHIN
		HCS-4094
AT89S52-24AU

------DO NO USE avrdude
avrdude -c usbasp -p 89s52 -B 1000 -U flash:r:read_flash.hex:i
---> avrdude -c usbasp -p 89s52 -B 40 -U flash:r:read_flash.hex:i --> faster
------use TL866plus and minipro


-----Linux cmdline param to make it works with 8051 (with 89S52 works without them)

i8042.nopnp=1 i8042.reset=1

echo -n "i8042" | sudo tee /sys/bus/platform/drivers/i8042/unbind
echo -n "i8042" | sudo tee /sys/bus/platform/drivers/i8042/bind

apt install xdotool
xdotool key Caps_Lock


cmp -l originalASM/P8051-ori.bin p8051-AT.bin | gawk '{printf "%08X %02X %02X\n", $1-1, strtonum(0$2), strtonum(0$3)}' | less

Quartz -> CSA 6.00 MT

cmp -l originalASM/P8051-ori.bin originalASM/p8051.bin | gawk '{printf "%08X %02X %02X\n", $1-1, strtonum(0$2), strtonum(0$3)}' | less

