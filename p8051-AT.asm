; code for EPSON P8051 microcontroller @ 6MHz
; DO NOT generate binary from IDE, it is broken.
; Instead generate bin from hex from utilities menu !
;
; The PS/2 protocol uses an 11-bit frame (1 start, 8 data, 1 parity, 1 stop) to send bytes
; Host pulls Clock low > 100 uS. (yellow wire, 1,840 seconds here)
; Host pulls Data low, then releases Clock.
; Device generates Clock signals.
; Host sends 8-bit command, 1 parity bit, 1 stop bit.
; Device sends ACK (FAh) to confirm
;
;     Timing Constraints:
;     Clock Frequency: 10 kHz to 16.7 kHz.
;     Clock Period: 60 uS to 100 uS.
;     Clock Inactive/Active Time: 30 uS to 50 uS.
;     Data Transition: Data must be stable 5 uS before and after the falling edge.
;     Response Time: Devices must respond to host commands within 20 ms
; 
;     Port P1, bit 6 (P1.6)           ->   Data output via LS125
;     Port P1, bit 7 (P1.7)           ->   Clock via LS125
;     Port P3, bits 5 (P3.5)          ->   Clock input from PC via LS125
;     INT0 external interrupt (P3.2)  ->   Data input from PC via LS125
; Note: P1.0, P1.1, P1.2 also used for LEDs (active high, inverted by NAND gates)
;     Port P1, bit 4 (P1.4) ->   ADF (Address Function) input from EPSON keyboard encoder IC - NOT USED
;
; AKD (Acknowledge Key Data): 
; This signal is used by the keyboard's internal controller to signal to the host computer that a "Scan Code"
; (the data representing a key press) is ready to be transmitted or has been successfully placed on the data lines.
;
; Timing Constants (6 MHz) Oscillator Frequency
; In the 8051, 1 machine cycle = 12 oscillator periods.
; Machine Cycle Time: 12/6,000,000=2 uS per cycle.
;
; cmp -l originalASM/P8051-ori.bin p8051-AT.bin | gawk '{printf "%08X %02X %02X\n", $1-1, strtonum(0$2), strtonum(0$3)}' | less

disable_ROMchecksum EQU 1
initial_led_blink EQU 1
use_buzzer EQU 1
;---------------------------------------------
BIT_DATA_READY  EQU  8h
byteTosend	equ	32h
VAR_BUFFER_54  EQU  54h
VAR_BUFFER_55  EQU  55h
BAT_CHK_PASSED_2PC  EQU  0AAh
BAT_CHK_FAILED_2PC  EQU  0FCh
ACK_GENERIC_2PC  EQU  0FAh
;STACK_POINTER_POS  EQU  0Fh    ; original
STACK_POINTER_POS  EQU  7Fh   ; NO 

WAIT30uSLOOP MACRO
    MOV R0, #7h
    DJNZ R0, $
ENDM

WAIT62uSLOOP MACRO
    MOV R0, #0Fh
    DJNZ R0, $
ENDM

RESETWD MACRO
    mov  0A6h, #01Eh
    mov  0A6h, #0E1h
ENDM

SETDATALINEHIGH MACRO
    setb	96h
ENDM

SETDATALINELOW MACRO
    clr	96h
ENDM

SETCLOCKHIGH MACRO
    setb	97h
ENDM

SETCLOCKLOW MACRO
    clr	97h
ENDM

LOAD_CMDID_IN_ACC MACRO
    mov A, R2
ENDM

base	equ	0x0000		;location for EPSON

	ORG	base
	ljmp	start
	ORG	base+3          ; Interrupt INT0 (Data from PC)
	ljmp	int0lbl
	ORG	base+11         ; Interrupt Timer 0
	ljmp	int_Timer0
    	
start:	
  setb	EA		; enable INTs
	mov	SP, #STACK_POINTER_POS	; Stack Pointer init
  ; --------------------------------------------- 
ifdef use_buzzer
	mov	P1, #0FFh ; turn OFF LEDs - NAND will invert - P1.6 = Data - floating, P1.7 = Clock - floating - buzzer OFF
else
	mov	P1, #0F7h ; turn ON LEDs - NAND will invert - P1.6 = Data - floating ls125 disabled, P1.7 = Clock - floating ls125 disabled
endif
	mov	TL0, #0h    ;
	mov	TH0, #0F1h  ; 	7.68 ms Timer0 overflow interval
ifdef initial_led_blink
  lcall startup_led_test ; Run the blink sequence  
else
  ; ---------------------------------------------
	;mov	R0, #0C8h         ;501.204 us delay
	;lcall	delayR0x2_5ms
  ; ---------------------------------------------
endif

	lcall	HW_init_return_R1equAA
	mov	R0, #7Fh
	
label6:	
  mov	@R0, #0FFh
	cjne	@R0, #0FFh, label5
	mov	@R0, #0h
	cjne	@R0, #0h, label5
	dec	R0
	cjne	R0, #1h, label6
	sjmp	main_loop
	
label5:
  	mov	R0, #7Fh
label8:
  mov	@R0, #0h
	djnz	R0, label8
	mov	R1, #BAT_CHK_FAILED_2PC

main_loop:
  	setb	21h               ; Set Bit 21h (Bit 1 of RAM Byte 24h)
label362:
	mov	2Ch, R1
	mov	26h, #2h              ; Set System State/Mode to "2"
	lcall	flags_and_vars_init
	mov	2Eh, #43h            ; Load default/init value into 2Eh
	mov	2Fh, #43h            ; Load default/init value into 2Fh
	anl	P1, #0F8h             ; turn OFF LEDs
	jb	21h, retry_data_reception   ; First time is always executed :  check for an incoming command from the PC before enabling interrupts.
	setb	TR0                 ; turn ON Timer0
	setb	ET0                 ; enable Timer0 interrupts
	setb	EX0                 ; enable external INT0
;	
retry_data_reception:
	jnb	BIT_DATA_READY, no_data_received
	push	2Ch
	lcall	data_received
	pop	2Ch
;	
no_data_received:
	mov	A, 2Ch    ; E5 2C - Move 2C ram to accumulator
	lcall	sendAdata
	jnz	retry_data_reception    ; If Accumulator is NOT zero, retry_data_reception
	clr	21h                     ; Clear Bit 21h (Bit 1 of RAM Byte 24h)
	jnb	20h, check_BAT_CompletionOK            ; If Bit 20h is 0, jump to check_BAT_CompletionOK
	mov	26h, #1h                ; If Bit 20h was 1, set RAM Byte 26h to 01h - System State/Mode to "1" (BAT in progress ?)
check_BAT_CompletionOK:
	mov	A, 2Ch
	xrl	A, #BAT_CHK_PASSED_2PC
	jz	begin_normal_operation

waitRAM08h_tohigh:
	jnb	BIT_DATA_READY, $           ; If the bit at RAM address 08h is 0, stay here
	jb	20h, waitRAM08h_tohigh
	lcall	data_received
	sjmp	waitRAM08h_tohigh

begin_normal_operation:
	mov	R7, #34h
	mov	R6, #1h
	clr	F0
	acall	scanning_routine
	nop         ; critical timing nop
	nop         ; critical timing nop

label39:
	jb	T0, label18
	jnb	0Ah, label19
	djnz	R3, label20
	ajmp	label21

label20:
	jnb	0Bh, label22
label19:
	mov	A, R7
	mov	R0, A
	mov	A, R6
	anl	A, @R0
	jz	label22
	setb	0Eh
	acall	label23
	cjne	A, 27h, label24
	lcall	label25
label24:
	mov	A, byteTosend
	add	A, #0F0h
	jnc	RAMcmdIdx
	acall	label27
	sjmp	label22

RAMcmdIdx:
	acall	label28
	acall	label29
	sjmp	label30
label18:
	dec	R3
	acall	label23
	cpl	A
	jz	label22
	setb	F0
	inc	0Eh
	mov	A, R7
	mov	R0, A
	mov	A, R6
	anl	A, @R0
	jnz	label22
	inc	0Fh
	ajmp	label31
label57:
	mov	A, byteTosend
	add	A, #0F0h
	jnc	label32
	acall	label33
	sjmp	label22
label32:
	acall	label34
	acall	label35
	acall	label36
label30:
	acall	label37
label22:
	mov	A, R6
	rl	A
	mov	R6, A
	jb	0E0h, label38
	inc	P2
	nop
	sjmp	label39

label38:
	mov	A, 21h
	anl	A, #3h
	jz	label40
	lcall	Wait_Sync_Pattern
	jnb	1Eh, label40
	clr	1Eh
	anl	21h, #3h
	sjmp	begin_normal_operation

label40:
	acall	label37
	jnb	1h, label42
	inc	R7
	acall	label43
	sjmp	label39

label42:
	jnb	F0, label44
	jb	20h, label45
	;setb	93h     ; set port P1.3 high - unconnected pin AKD 
	sjmp	label45
label44:
	;clr	93h       ; set port P1.3 low - unconnected pin AKD
	lcall	label25
label45:
	ajmp	begin_normal_operation

label21:
	jb	0Fh, label46
	jnb	0Dh, label47
	jb	0Eh, label46
	acall	label33
	acall	label37
label46:
	anl	21h, #3h
	sjmp	label22

label47:
	setb	0Dh
	sjmp	label48
label31:
	jb	0Ah, label49
label53:
	ajmp	label50

label66:
	anl	21h, #3h
	setb	0Ah
	setb	0Fh
	sjmp	label51

label49:
	cjne	R3, #0h, label52
	jbc	0Dh, label53
	jb	0Bh, label54
	clr	0Fh
	lcall	label25
	acall	label55
	jnz	label56
label61:
	anl	21h, #3h
	ajmp	label57

label54:
	jbc	0Ch, label58
	jb	0Eh, label59
	mov	A, 0Fh
	clr	C
	subb	A, 0Ah
	jc	label59
	acall	label55
	jnz	label56
label59:
	setb	0Ch
	sjmp	label48
label58:
	acall	label55
	jnz	label60
	jb	0Eh, label61
	acall	label33
	acall	label37
	sjmp	label61
label60:
	mov	A, 0Fh
	clr	C
	subb	A, 0Ah
	jnc	label56
	jb	0Eh, label56
	acall	label33
	acall	label37
	sjmp	label56
label51:
	clr	0Bh
	sjmp	label62
label56:
	mov	0Ah, 0Fh
	clr	0Eh
label48:
	setb	0Bh
label62:
	mov	R3, #78h
	clr	A
	mov	0Eh, A
	mov	0Fh, A
label52:
	ajmp	label22

label55:
	mov	A, 0Eh
	add	A, #0FCh
	jnc	label55_ret
	mov	A, 0Fh
	dec	A
	jz	label55_ret
	ret
label55_ret:
	clr	A
	ret

label50:
	mov	B, #6h
label65:
	mov	A, 21h
	anl	A, #3h
	jz	label64
	lcall	Wait_Sync_Pattern
	jnb	1Eh, label64
	clr	1Eh
	anl	21h, #3h
	ajmp	begin_normal_operation

label64:
	lcall	label37
	mov	R0, #54h      ; load R0 with 54h (84 decimal)
	djnz	R0, $
	djnz	B, label65
	ajmp	label66

scanning_routine:
	setb	RXD
	setb	95h
	mov	20h, #3h
	mov	A, #0F8h
	mov	P2, A
	mov	R4, A
	mov	P0, #0FFh
	mov	A, #0FEh
	mov	P0, A
	mov	R5, A
	ret

label43:
	mov	P2, #0F8h
	mov	P0, #0FFh
	mov	A, R5
	setb	C
	rlc	A
	mov	P0, A
	mov	R5, A
	mov	A, R4
	mov	0E2h, C
	clr	C
	rlc	A
	mov	P2, A
	mov	R4, A
	mov	A, 20h
	rlc	A
	mov	20h, A
	rrc	A
	mov	95h, C
	rrc	A
	mov	RXD, C
	ret

label28:
	mov	A, R7
	mov	R0, A
	mov	A, R6
	cpl	A
	anl	A, @R0
	mov	@R0, A
	ret

label34:
	mov	A, R7
	mov	R0, A
	mov	A, R6
	orl	A, @R0
	mov	@R0, A
	ret

label35:
	acall	label23
	mov	R1, #80h
	acall	circular_buffer_mngr
	ret

label29:
	acall	label68
	jz	label69
	mov	R1, #0h
	acall	circular_buffer_mngr
label69:
	ret
	
label68:
	acall	label23
	mov	A, 26h
	cjne	A, #3h, label70
	acall	label71
	jz	label72
	dec	A
	jz	label73
	dec	A
	jz	label72
	dec	A
	jz	label73
	LOAD_CMDID_IN_ACC
	add	A, #0F0h
	jnc	label72
	LOAD_CMDID_IN_ACC
	add	A, #0EBh
	jnc	label73
label72:
	clr	A
	ret

label70:
	cjne	R2, #4Fh, label73
	clr	A
	ret

label73:
	mov	A, #0FFh
	ret

label27:
	acall	label68
	jnz	label33
	acall	label28
	ret

label33:
	mov	A, byteTosend
	xrl	A, #11h
	jz	label33_ret
	jb	1Fh, label33_ret
	mov	R2, #0FFh
	mov	R1, #0h
	acall	circular_buffer_mngr
	setb	1Fh
label33_ret:
	ret

circular_buffer_mngr:
	mov	R0, 2Eh       ; loads current Write Pointer from RAM 2Eh
	mov	A, R1
	anl	A, #80h
	orl	A, R2
	mov	@R0, A
	mov	A, R1
	rlc	A
	rlc	A
	mov	A, VAR_BUFFER_55
	rlc	A
	mov	VAR_BUFFER_55, A
	mov	A, VAR_BUFFER_54
	rlc	A
	mov	VAR_BUFFER_54, A
	mov	1Ch, C
	inc	R0          ; Increment write pointer
	cjne	R0, #54h, label75
	mov	R0, #43h
label75:
	mov	2Eh, R0
	inc	byteTosend
	ret
	
label23:
	mov	A, P2           ; load P2 port (keyboard matrix X lines) (A0) into accumulator
	anl	A, #7h          ; read lower bits of P2
	mov	R0, A
	mov	A, R7
	clr	C
	subb	A, #34h
	swap	A               ; swap nibbles within Accumulator
	rr	A
	add	A, R0
	mov	DPTR, #data0EAE   ; load Data Pointer Register with data0EAE address
	movc	A, @A+DPTR      ; load accumulator with DPTR + A pointed data
	mov	R2, A
	ret
	
;-----------------------------
label36:
	mov	A, 26h
	cjne	A, #3h, label76
	acall	label71
	jz	label78_ret
	dec	A
	jz	label78_ret
	dec	A
	jz	label78
	dec	A
	jz	label78
	LOAD_CMDID_IN_ACC
	mov	DPTR, #data0D9F
	movc	A, @A+DPTR      ; load accumulator with DPTR + A pointed data
	cjne	A, #84h, label79
	ret

label79:
	jb	0E7h, label78
	ret

label76:
	cjne	R2, #4Fh, label78
	ret

;-----------------------------
label78:
	mov	27h, R2
	clr	EX0
	clr	ET0
	clr	TR0
	mov	0Ch, 28h
	mov	0Dh, 29h
	clr	9h
	setb	TR0
	setb	ET0
	jb	20h, label78_ret
	setb	EX0
label78_ret:
	ret
	
; ----------------------------------------------------
label71:
	lcall	label80
	mov	A, R0
	anl	A, @R1
	jz	label81
	xrl	A, R0
	jz	label82
	mov	A, R0
	rr	A
	anl	A, R0
	anl	A, @R1
	jz	setAcc_val_to_2
	mov	A, #1h
	ret
	
setAcc_val_to_2:
	mov	A, #2h
	ret
	
label82:
	jnb	25h, label84
	mov	A, #3h
	ret
	
label84:
	mov	A, #4h
label81:
	ret
	
label37:
	jb	BIT_DATA_READY, label37_ret
	mov	A, 33h
	jz	label86
label37_jmp1:
	mov	R0, 30h
	mov	A, @R0
	lcall	label87
	mov	R0, #7Dh
	djnz	R0, $
	jnz	label37_ret
label37_jmp2:
	inc	30h
	dec	33h
	mov	A, 33h
	jz	label37_jmp3
	acall	label89
	jz	label37_jmp1
	sjmp	label37_jmp2
label37_jmp3:
	jnb	1Bh, label92
	mov	30h, #74h
	ajmp	label93

label92:
	dec	byteTosend
	inc	2Fh
	mov	A, 2Fh
	cjne	A, #54h, label86
	mov	2Fh, #43h
label86:
	mov	A, byteTosend
	jz	label37_ret
	mov	30h, #74h
	mov	A, 26h
	cjne	A, #3h, label94
	ajmp	label95
label113:
	setb	1Bh
	sjmp	label96
label100:
	clr	1Bh
label96:
	mov	30h, #74h
	sjmp	label37
label37_ret:
	ret
	
label94:
	mov	R0, 2Fh
	mov	A, @R0
	mov	R2, A
	cjne	A, #0FFh, label97
	acall	label98
	mov	A, #24h
	acall	label99
label104:
	sjmp	label100
label97:
	acall	label101
	jz	label102
	acall	label103
	jnb	1Dh, label104
	jb	15h, label104
	jb	14h, label104
	clr	1Dh
	cjne	R2, #14h, label105
	ajmp	label106
label105:
	cjne	R2, #17h, label107
	ajmp	label108
label107:
	cjne	R2, #4Eh, label104
	ajmp	label109
label102:
	LOAD_CMDID_IN_ACC
	jb	0E7h, label110
	ajmp	label111
label110:
	clr	1Dh
	acall	label112
	mov	A, 33h
	jz	label93
	sjmp	label113

label93:
	mov	R0, 2Fh
	mov	A, @R0
	anl	A, #7Fh
	mov	R2, A
	cjne	R2, #14h, label114
	ajmp	label115
label114:
	cjne	R2, #17h, label116
	ajmp	label117
label116:
	cjne	R2, #4Eh, label118
	ajmp	label119


label118:
	LOAD_CMDID_IN_ACC
	add	A, #0ECh
	jc	label120
	LOAD_CMDID_IN_ACC
	add	A, #0F6h
	jnc	label121

	; --- Begin 3-Byte Math Conversion ---
	LOAD_CMDID_IN_ACC     ; Get the original Command ID
	clr	C
	subb A, #0Ah          ; Subtract the base offset (14h / 2 = 0Ah)
    
	mov  B, #3            ; Multiplier for 3-byte LJMP entries
	mul  AB               ; A = Index * 3
    
	mov	DPTR, #label03A3  ; Point to the new LJMP table
	jmp	@A+DPTR           ; Jump to the calculated offset
	; --- End 3-Byte Math Conversion ---

; --- Updated Table (All entries now 3 bytes) ---
label03A3:
	ljmp	label122    ; Was ajmp
	ljmp	label92     ; Was ajmp
	ljmp	label123    ; Was ajmp
	ljmp	label124    ; Was ajmp
	ljmp	label120    ; Was ajmp
	ljmp	label125    ; Was ajmp
	ljmp	label126    ; Was ajmp
	ljmp	label127    ; Was ajmp
	ljmp	label128    ; Was ajmp
	ljmp	label129    ; Was ajmp


label120:
	acall	label103
	ajmp	label100

label121:
	jnb	23h, label130
	jb	13h, label131
	jb	12h, label131
	acall	label132
	sjmp	label131
label130:
	jnb	13h, label133
	acall	label134
label133:
	jnb	12h, label131
	acall	label135
label131:
	inc	31h
	setb	18h
	acall	label103
	ajmp	label100
label125:
	jnb	13h, label136
	acall	label134
label136:
	jnb	12h, label137
	acall	label135

label137:
	inc	31h
	acall	label103
	ajmp	label100
;
label122:
	jb	17h, label138
	jb	16h, label138
	jb	15h, label139
	jb	14h, label139
	jb	13h, label139
	jb	12h, label139
	acall	label132

label139:
	inc	31h
	setb	19h
	clr	1Ah
	acall	label103
	ajmp	label100
label138:
	inc	31h
	setb	1Ah
	acall	label103
	ajmp	label100
label126:
	acall	label103
	mov	A, #5h

label140:
	acall	label99
	ajmp	label100
label124:
	acall	label103
	mov	A, #4h
	sjmp	label140
label127:
	acall	label103
	mov	A, #7h
	sjmp	label140
label123:
	acall	label103
	mov	A, #6h
	sjmp	label140
label128:
	acall	label103
	mov	A, #1h
	acall	label99
	mov	A, #3h
label142:
	jnb	20h, label141
	jb	94h, label141
	jb	INT1, label141
	acall	label99
	mov	A, #22h
label141:
	sjmp	label140
label129:
	acall	label103
	mov	A, #0h
	lcall	label99
	mov	A, #2h
	sjmp	label142
label115:
	acall	label103
	jnb	20h, label143
	jb	94h, label143
	jb	15h, label144
	jb	14h, label144
label106:
	jb	INT1, label145
	mov	A, #1Ah
	sjmp	label140
label145:
	mov	A, #12h
	sjmp	label140
label144:
	setb	1Dh
label143:
	ajmp	label100
label117:
	acall	label103
	jb	15h, label146
	jb	14h, label146
	mov	A, #13h
	acall	label99
label146:
	jnb	20h, label143
	jb	94h, label143
	jb	15h, label144
	jb	14h, label144
label108:
	mov	A, #11h
	sjmp	label140
label119:
	acall	label103
	jnb	20h, label143
	jb	94h, label143
	jb	15h, label144
	jb	14h, label144
label109:
	mov	A, #10h
	ajmp	label140


label111:
	LOAD_CMDID_IN_ACC
	add	A, #0ECh
	jc	label147
	LOAD_CMDID_IN_ACC
	add	A, #0F6h
	jnc	label148

	; --- Begin 3-Byte Math Conversion for label111 ---
	LOAD_CMDID_IN_ACC     ; Reload Command ID (e.g., 0Ah, 0Bh...)
	clr	C
	subb A, #0Ah          ; Normalize index: original sub 14h (math 2x) becomes sub 0Ah
    
	mov  B, #3            ; Multiplier for 3-byte LJMP table entries
	mul  AB               ; A = Index * 3 (Result low byte in A)
    
	mov	DPTR, #label04AA  ; Load the new 16-bit table address
	jmp	@A+DPTR           ; Jump to calculated offset
	; --- End 3-Byte Math Conversion ---

; --- Updated Table (All AJMP upgraded to LJMP) ---
label04AA:
	ljmp	label149    ; Entry 0
	ljmp	label92     ; Entry 1
	ljmp	label150    ; Entry 2
	ljmp	label151    ; Entry 3
	ljmp	label147    ; Entry 4
	ljmp	label152    ; Entry 5
	ljmp	label153    ; Entry 6
	ljmp	label154    ; Entry 7
	ljmp	label155    ; Entry 8
	ljmp	label156    ; Entry 9


label147:
	acall	label157
	ajmp	label100
label148:
	acall	label157
	mov	A, 31h
	jz	label158
	djnz	31h, label159
label158:
	acall	label112
label159:
	ajmp	label100
label152:
	sjmp	label148
label149:
	sjmp	label148
label153:
	acall	label157
	mov	A, #0Dh
label160:
	acall	label99
	ajmp	label100
label151:
	acall	label157
	mov	A, #0Ch
	sjmp	label160
label154:
	acall	label157
	mov	A, #0Fh
	sjmp	label160
label150:
	acall	label157
	mov	A, #0Eh
	sjmp	label160
label155:
	acall	label157
	mov	A, #9h
	acall	label99
	mov	A, #0Bh
	acall	label99
	jb	12h, label161
label164:
	jnb	18h, label162
	jnb	23h, label161
	sjmp	label163
label162:
	jnb	19h, label161
label163:
	acall	label132
label161:
	ajmp	label100

label156:
	acall	label157
	mov	A, #8h
	acall	label99
	mov	A, #0Ah
	acall	label99
	jnb	13h, label164
	ajmp	label100

label95:
	mov	R0, 2Fh
	mov	A, @R0
	mov	R2, A
	cjne	A, #0FFh, label165
	acall	label98
	mov	A, #24h
	acall	label99
	ajmp	label100

label165:
	acall	label101
	jz	label166
	acall	label103
	ajmp	label100

label166:
	LOAD_CMDID_IN_ACC
	jb	0E7h, label167
	acall	label157
	ajmp	label100

label167:
	anl	A, #7Fh
	mov	R2, A
	acall	label103
	ajmp	label100

label103:
	mov	R1, 26h
	cjne	R1, #3h, label168
	sjmp	label169

label168:
	cjne	R2, #4Fh, label170
	jb	15h, label171
	jb	14h, label171
	cjne	R1, #2h, label172
	mov	DPTR, #data0E19
	mov	R1, #8h
	sjmp	label173
label172:
	mov	DPTR, #data0E0F
	mov	R1, #6h
	sjmp	label173

label171:
	cjne	R1, #2h, label174
	mov	DPTR, #data0E21
	mov	R1, #5h
	sjmp	label173
label174:
	mov	DPTR, #data0E15
	mov	R1, #4h

label173:
	clr	A
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
	lcall	label175          ; CHANGED FROM ACALL TO LCALL
	inc	DPTR
	djnz	R1, label173
	ret


label170:
	LOAD_CMDID_IN_ACC
	add	A, #0F0h
	jc	label176
	cjne	R2, #0Ah, label177
	jnb	1Ah, label177
	cjne	R1, #2h, label178
	mov	A, #84h
	sjmp	label179
label178:
	mov	A, #54h
	sjmp	label179
label177:
	acall	label180

label176:
	mov	DPTR, #data0CBF
	cjne	R1, #2h, label181
	mov	DPTR, #data0D2F

label181:
	LOAD_CMDID_IN_ACC
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
label179:
	acall	label175
	ret

label169:
	LOAD_CMDID_IN_ACC
	mov	DPTR, #data0D9F
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
	cjne	A, #84h, label182
	sjmp	label183
label182:
	anl	A, #7Fh
label183:
	acall	label175
	ret

label157:
	mov	R1, 26h
	cjne	R1, #3h, label184
	sjmp	label185
label184:
	LOAD_CMDID_IN_ACC
	add	A, #0F0h
	jc	label186
	cjne	R2, #0Ah, label187
	jnb	1Ah, label187
	cjne	R1, #2h, label188
	acall	label189
	mov	A, #84h
	sjmp	label190
label188:
	mov	A, #0D4h
	sjmp	label190
label187:
	acall	label180
label186:
	cjne	R1, #2h, label191
	acall	label189

label191:
	mov	DPTR, #data0CBF  
	cjne	R1, #2h, label192
	mov	DPTR, #data0D2F

label192:
	LOAD_CMDID_IN_ACC
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
	cjne	R1, #1h, label190
	orl	A, #80h
label190:
	acall	label175
	ret
label185:
	acall	label189
	sjmp	label169
label98:
	clr	A
	mov	R0, 26h
	cjne	R0, #1h, label193
	cpl	A
label193:
	acall	label175
	ret
label175:
	mov	R0, 30h
	mov	@R0, A
	clr	C
label194:
	mov	A, 73h
	rlc	A
	mov	73h, A
	mov	A, 72h
	rlc	A
	mov	72h, A
	inc	30h
	inc	33h
	ret

label99:
	mov	R0, 30h
	mov	@R0, A
	setb	C
	sjmp	label194
label180:
	mov	A, #0E0h
	sjmp	label175
label189:
	mov	A, #0F0h
	sjmp	label175
label112:
	clr	18h
	clr	19h
	jnb	10h, label195
	jb	12h, label196
	acall	label197
	sjmp	label196
label195:
	jnb	12h, label196
	acall	label135
label196:
	jnb	11h, label198
	jb	13h, label199
	acall	label132
	ret
label198:
	jnb	13h, label199
	acall	label134
label199:
	ret

label132:
	mov	R1, #3h
	acall	label180
	mov	A, #2Ah
	mov	R0, 26h
	cjne	R0, #2h, label200
label202:
	mov	A, #12h
label200:
	acall	label175
	mov	A, R1
	acall	label99
	ret
label134:
	mov	R1, #0Bh
	acall	label180
	mov	R0, 26h
	cjne	R0, #2h, label201
	acall	label189
	sjmp	label202

label201:
	mov	A, #BAT_CHK_PASSED_2PC
	sjmp	label200
label197:
	mov	R1, #2h
	acall	label180
	mov	A, #36h
	mov	R0, 26h
	cjne	R0, #2h, label203
label205:
	mov	A, #59h
label203:
	acall	label175
	mov	A, R1
	acall	label99
	ret

label135:
	mov	R1, #0Ah
	acall	label180
	mov	R0, 26h
	cjne	R0, #2h, label204
	acall	label189
	sjmp	label205
label204:
	mov	A, #0B6h
	sjmp	label203
label89:
	mov	A, 33h
	dec	A
	anl	A, #7h
	mov	DPTR, #data02
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
	mov	R0, A
	mov	A, 33h
	add	A, #0F7h
	jnc	label206
	mov	A, R0
	anl	A, 72h
	jnz	label207
	ret

label206:
	mov	A, R0
	anl	A, 73h
	jnz	label207
	ret
label207:
	mov	R0, 30h
	mov	A, @R0
	jb	0E5h, label208
	jb	0E4h, label209
	jb	0E3h, label210
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
	orl	A, 22h
	mov	22h, A
	ret

label210:
	anl	A, #7h
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
	cpl	A
	anl	A, 22h
	mov	22h, A
	cpl	A
	ret

label209:
	jb	0E3h, label211
	cjne	A, #10h, label212
	cpl	90h
	ret

label212:
	cjne	A, #11h, label213
	cpl	91h
	ret

label213:
	cjne	A, #12h, label214
	cpl	92h
	ret

label214:
	cpl	23h
	ret

label211:
	setb	92h
	ret

label208:
	cjne	A, #22h, label215
	clr	92h
	ret

label215:
	clr	1Fh
	ret

label101:
	mov	A, byteTosend
	dec	A
	anl	A, #7h
	mov	DPTR, #data02
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
	mov	R0, A
	mov	A, byteTosend
	add	A, #0F7h
	jnc	label216
	mov	A, byteTosend
	cjne	A, #11h, label217
	clr	A
	mov	C, 1Ch
	rlc	A
	ret

label217:
	mov	A, R0
	anl	A, VAR_BUFFER_54
	ret

label216:
	mov	A, R0
	anl	A, VAR_BUFFER_55
	ret

data02:
	db 01h
	db 02h
	db 04h
	db 08h
	db 10h
	db 20h
	db 40h
	db 80h

label87:
  	jnb	20h, sendAdata
  	ljmp	Host_RTS_chk

; ------------------------------------------------------------------------
abort_sending:
	ljmp	enableINTs
;
sendAdata:
	mov	2Ch, A
	clr	EX0
	clr	ET0
	clr	TR0
	jb	BIT_DATA_READY, abort_sending     ;jump if 8h is set
	jnb	INT0, abort_sending
	jnb	T1, abort_sending     ; bit address B5h
	mov	R1, #8h
	SETDATALINELOW                   ; set port P1.6 low - enable Data line (via *OE of ls125)
	jnb	T1, abort_sending
	mov	R0, #5h
	djnz	R0, $
	nop
	jnb	T1, abort_sending
	SETCLOCKLOW       ; P1.7 low - clock low
  WAIT30uSLOOP
	nop
	SETCLOCKHIGH    ; P1.7 high - clock floating
	jnb	T1, abort_sending
label225:
	jnb	T1, abort_sending
	mov	R0, #3h
	djnz	R0, $
	jnb	T1, abort_sending
label219:
	rr	A
	jb	0E7h, label223
	SETDATALINELOW           ; set port P1.6 low - enable Data line (via *OE of ls125)
	sjmp	label224
label223:
	SETDATALINEHIGH         ; set port P1.6 high - disable Data line (via *OE of ls125) - pulled high by 2k2 resistor
	nop
	nop
label224:
	jnb	T1, abort_sending
	nop
	mov	R0, #4h
	djnz	R0, $
	jnb	T1, abort_sending
	SETCLOCKLOW    ; P1.7 low - clock low
  WAIT30uSLOOP
	nop
	SETCLOCKHIGH   ; P1.7 high - clock floating
	djnz	R1, label225
	jnb	T1, enableINTs
	mov	R0, #3h
	djnz	R0, $
	nop
	jnb	T1, enableINTs
	jb	P, label226
	SETDATALINEHIGH         ; set port P1.6 high - disable Data line (via *OE of ls125) - pulled high by 2k2 resistor
	sjmp	label227
label226:
	SETDATALINELOW           ; set port P1.6 low - enable Data line (via *OE of ls125)
	nop
	nop
label227:
	jnb	T1, enableINTs
	mov	R0, #4h
	djnz	R0, $
	nop
	jnb	T1, enableINTs
	SETCLOCKLOW         ; P1.7 low - clock low
  WAIT30uSLOOP
	nop
	SETCLOCKHIGH       ; P1.7 high - clock floating
	jnb	T1, enableINTs
	mov	R0, #6h
	djnz	R0, $
	nop
	SETDATALINEHIGH       ; set port P1.6 high - disable Data line (via *OE of ls125) - pulled high by 2k2 resistor
  WAIT30uSLOOP
	nop
	SETCLOCKLOW         ; P1.7 low - clock low
	jb	21h, label228
	mov	R0, #6h
	djnz	R0, $
	nop
	SETCLOCKHIGH       ; P1.7 high - clock floating
label241:
  WAIT30uSLOOP
	sjmp	label229

enableINTs:
	SETDATALINEHIGH       ; set port P1.6 high - disable Data line (via *OE of ls125) - pulled high by 2k2 resistor
	jb	21h, enableINTs_loc
	setb	TR0
	setb	ET0
	setb	EX0
enableINTs_loc:
	mov	A, #0FFh
	ret

label229:
	setb	TR0
	setb	ET0
	setb	EX0
	mov	A, 2Ch
	cjne	A, #0FEh, label231
	ljmp	label232
label231:
	mov	2Dh, A
label232:
	clr	A
	ret
; sendAdata end ---------------------------------------------------------

label228:
	jb	INT0, label233
label237:
	jb	INT0, label234
label239:
	jb	INT0, label235
label240:
	setb	20h
	mov	R0, #2h
	sjmp	label236
label233:
	jnb	INT0, label237
	mov	R0, #3h
	sjmp	label238
label234:
	jnb	INT0, label239
	mov	R0, #2h
	sjmp	label238
label235:
	jnb	INT0, label240
	mov	R0, #1h
	sjmp	label238
label238:
	clr	20h
label236:
	djnz	R0, $
	SETCLOCKHIGH   ; P1.7 high - clock floating
	jnb	20h, label241
	ljmp	label242

;---------------------------------
Host_RTS_chk:
	clr	ET0
	clr	TR0
	mov	R1, #7h
	jb	T1, label243
	ljmp	reenableET0_TR0
;
label243:
	SETCLOCKLOW     ; P1.7 low - clock low
	nop
	nop
	nop
	nop
	nop
	SETDATALINEHIGH   ; P1.6 high - disable Data line (via *OE of ls125) - pulled high by 2k2 resistor
  ; 98 microseconds delay ------------------------
	mov	R0, #18h
	djnz	R0, $
  ; ----------------------------------------------
	mov	R0, #13h

check_INT0_high:
	jb	INT0, INT0_detected_high
	djnz	R0, check_INT0_high
	SETDATALINELOW       ; P1.6 low - Data line low (via *OE of ls125) (Request-to-Send" acknowledgment)
	SETCLOCKHIGH          ; P1.7 high - clock floating 
	ljmp	reenableET0_TR0

INT0_detected_high:
	SETCLOCKHIGH         ; P1.7 high - clock floating - pulled high by 2k2 resistor
  WAIT62uSLOOP
	nop
	SETCLOCKLOW           ; P1.7 low - clock low
	nop
	nop
label249:
	nop
	nop
	nop
	rr	A
	jb	0E7h, label247
	SETDATALINELOW         ; P1.6 low - Data line low (via *OE of ls125)
	sjmp	label248
label247:
	SETDATALINEHIGH       ; P1.6 high - disable Data line (via *OE of ls125) 
	nop
	nop
label248:
	mov	R0, #2h
	djnz	R0, $
	nop
	SETCLOCKHIGH       ; P1.7 high - clock floating
  WAIT62uSLOOP  
	nop
	SETCLOCKLOW         ; P1.7 low - clock low
	djnz	R1, label249
	nop
	nop
	nop
	rr	A
	jb	0E7h, label250
	SETDATALINELOW         ; clear port P1.6 - Data line low (via *OE of ls125) 
	;setb	93h       ; set port P1.3 high - unconnected pin AKD
	sjmp	label251
label250:
	SETDATALINEHIGH       ; set port P1.6 high - disable Data line (via *OE of ls125)
	;setb	93h       ; set port P1.3 high - unconnected pin AKD
	nop
	nop
label251:
	mov	R0, #2h
	djnz	R0, $
	SETCLOCKHIGH    ; P1.7 high - clock floating

label414:
  WAIT62uSLOOP
	nop
	SETCLOCKLOW      ; P1.7 low - clock low
	mov	R0, #3h
	djnz	R0, $
	nop
	SETDATALINELOW    ; P1.6 low - Data line low (via *OE of ls125)
	;clr	93h
	mov	R0, #3h
	djnz	R0, $
	SETCLOCKHIGH   ; P1.7 high - clock floating
label242:
  WAIT62uSLOOP
	setb	TR0
	setb	ET0
	clr	A
	ret

;--------------------------------------
reenableET0_TR0:
	setb	TR0
	setb	ET0
	mov	A, #0FFh
	ret

; ---------------I N T E R R U P T  0 -- Falling edge on Data line -----
int0lbl:
	jnb	20h, waitData  ; if Bit 0 of RAM 24h is 0 -> go on
	ljmp	int0lbl_reti

waitData:
	push	ACC
	push	PSW
	setb	RS0
	clr	F0            ; clear user bit F0
	mov	R1, #8h
label255:
	jb	T1, debouncing_15_cycle_delay
	jnb	INT0, label255
	ljmp	label256
debouncing_15_cycle_delay:
  WAIT62uSLOOP
	jnb	INT0, Bit_Sampling_Loop
	ljmp	label256

Bit_Sampling_Loop:
	SETCLOCKLOW             ; P1.7 low - clock low
  WAIT30uSLOOP
	clr	C
	SETCLOCKHIGH           ; P1.7 high - clock floating
	jb	INT0, label258
	sjmp	label259
label258:
	cpl	F0
	setb	C
label259:
	rrc	A
	nop
	mov	R0, #0Ch
	djnz	R0, $
	djnz	R1, Bit_Sampling_Loop
	SETCLOCKLOW         ; P1.7 low - clock low
  WAIT30uSLOOP
	nop
	SETCLOCKHIGH       ; P1.7 high - clock floating  
	jb	INT0, label260
	sjmp	label261

label260:
	cpl	F0
label424:
	nop
label261:
	mov	R0, #0Eh
	djnz	R0, $
	SETCLOCKLOW      ; P1.7 low - clock low
  WAIT30uSLOOP
	nop
	SETCLOCKHIGH   ; P1.7 high - clock floating
	jb	INT0, label262
	sjmp	label263
label262:
	nop
	nop
label263:
	mov	R0, #5h
	djnz	R0, $
	nop
	SETDATALINELOW       ; P1.6 low - Data line low (via *OE of ls125)
  WAIT30uSLOOP
	nop
	SETCLOCKLOW       ; P1.7 low - clock low
  WAIT30uSLOOP
	nop
	SETCLOCKHIGH     ; P1.7 high - clock floating
  WAIT30uSLOOP
	nop
	SETDATALINEHIGH     ; set port P1.6 high - disable Data line (via *OE of ls125)
	mov	R3, A
	mov	C, F0
	mov	24h, C
	setb	BIT_DATA_READY
	nop
	nop
	nop

label256:
	pop	PSW
	pop	ACC
int0lbl_reti:
	reti

; ---------------T I M E R  1  Int ---------------- every 7.68 ms-----
int_Timer0:
	mov	TL0, #0h
	mov	TH0, #0F1h
	push	PSW
	setb	RS0
	jb	T1, label264
	jnb	20h, label264
	SETDATALINEHIGH           ; set port P1.6 high - disable Data line (via *OE of ls125)
	jnb	INT0, label265
	clr	TR0
	mov	R0, #53h
label267:
	jnb	INT0, label266  ; jump if Data input is low
	jb	T1, label266
	djnz	R0, label267
	SETDATALINELOW             ; clear port P1.6 - Data line low (via *OE of ls125)
	ljmp	reload_defaults

label266:
	setb	TR0
label265:
	SETDATALINELOW             ; clear port P1.6 - Data line low (via *OE of ls125)
label264:
	cjne	R5, #0h, label269
	cjne	R4, #0h, label270
label271:
	pop	PSW
	reti

label269:
	djnz	R5, label271
	cjne	R4, #0h, label271
	setb	9h
	sjmp	label271
label270:
	dec	R4
	dec	R5
	sjmp	label271
; ---------------T I M E R  1 Int -------------END

send0FAh__genericAck:
	mov	A, #ACK_GENERIC_2PC
sendAccumulator:
	lcall	sendAdata
	jz	send_acknowledge_ret    ; return if Accumulator is zero
	jb	BIT_DATA_READY, label273
	mov	A, 2Ch
	sjmp	sendAccumulator
label273:
	mov	A, #0FFh
send_acknowledge_ret:
	ret
; ------------------------------------------------

Wait_Sync_Pattern:
	jb	BIT_DATA_READY, data_received   ; If it's set (Bit 0 of RAM Byte 21h), the keyboard has incoming data from the host and go to process it
	jnb	T1, Interrupt_and_Hardware_Sync        ; If T1 (Clock) is Low (0), jump to interrupt resync
	mov	A, byteTosend
	add	A, #0F0h
	jc	Interrupt_and_Hardware_Sync
	mov	R1, #40h
	mov	R2, 27h
	lcall	circular_buffer_mngr
	lcall	label37
Interrupt_and_Hardware_Sync:
	clr	EX0
	clr	ET0
	clr	TR0
	mov	0Ch, 2Ah
	mov	0Dh, 2Bh
	clr	9h
	setb	TR0
	setb	ET0
	jb	20h, label276
	setb	EX0
label276:
	ret






data_received:
	clr	EX0
	clr	BIT_DATA_READY        ; clear Data Ready flag
	mov	R2, 0Bh
	mov	C, 24h
	setb	EX0
	; Invert logic for JC to use LJMP
	jnc	skip_parse_received
	ljmp parse_received
skip_parse_received:
	ljmp	send0FEh_data  ; CHANGED: AJMP to LJMP

parse_received:
	LOAD_CMDID_IN_ACC
	cjne	A, #0FEh, next_check01
	ljmp	resend_data ; CHANGED: AJMP to LJMP

next_check01:
	cjne	A, #0F1h, next_check02
	; Invert logic for SJMP to use LJMP
	ljmp	set_Typematic_Rate_Delay 

next_check02:
	cjne	A, #0EFh, cmds_range_check
	; Invert logic for SJMP to use LJMP
	ljmp	set_Typematic_Rate_Delay

cmds_range_check:
	add	A, #13h
	; Invert logic for JC to use LJMP
	jnc	skip_checkCMD_ID
	ljmp checkCMD_ID
skip_checkCMD_ID:
	; Invert logic for SJMP to use LJMP
	ljmp	set_Typematic_Rate_Delay


checkCMD_ID:
	mov	25h, #0h          ; Resets a status flag in 25h RAM
	mov	DPTR, #jmptbl9C9
	LOAD_CMDID_IN_ACC         ; R2 is command ID
	cpl	A
	; --- CHANGED: Use MUL AB for 3-byte LJMP table ---
  mov  B, #3          ; Load multiplier for 3-byte LJMP
  mul  AB             ; A = A * 3
  ; --- End of New Math ---
	jmp	@A+DPTR         ; JMP @A+DPTR still works for 64KB range

; --- Updated Table (3 bytes per entry) ---
jmptbl9C9:
	ljmp	label285
	ljmp	exit_cmd_handler
	ljmp	label287
	ljmp	label288
	ljmp	label289
	ljmp	label290
	ljmp	label291
	ljmp	label292
	ljmp	label293
	ljmp	label294
	ljmp	label295
	ljmp	label296
	ljmp	label297
	ljmp	label298
	ljmp	exit_cmd_handler      ; Duplicate entry safe with LJMP
	ljmp	label299
	ljmp	exit_cmd_handler      ; Duplicate entry safe with LJMP
	ljmp	label300
	ljmp	label301

unsupported_cmd:
	jnb	BIT_DATA_READY, $     ; wait until 8h (Data Ready) is cleared
	ljmp	data_received

exit_cmd_handler:
    mov 25h, #0h
    jb  22h, unsupported_cmd
    jnb BIT_DATA_READY, no_more_data   ; If bit 8h is NOT set, jump over the LJMP
    ljmp data_received       ; If bit 8h WAS set, perform a Long Jump
no_more_data:
    ret




set_Typematic_Rate_Delay:
	LOAD_CMDID_IN_ACC               ; loads received byte into A
	jnb	28h, label303
	jb	0E7h, error_prot_violation
	ajmp	label305
label303:
	jnb	29h, label306
	add	A, #0F8h
	jc	error_prot_violation
	ajmp	label307
label306:
	jnb	2Ah, label308
	add	A, #0FCh
	jc	error_prot_violation
	ajmp	label309
label308:
	jnb	2Bh, error_prot_violation
	cjne	A, #83h, label310
	ajmp	recOK_sendACK
label310:
	cjne	A, #84h, label312
label313:
	ajmp	recOK_sendACK
label312:
	jnb	0E7h, label313

error_prot_violation:
	ljmp	send0FEh_data

label285:
	lcall	send0FAh__genericAck
	jnz	label315
	clr	ET0
	clr	TR0
	clr	EX0
	jb	BIT_DATA_READY, enable_timer0_int0
label318:
	jb	T1, label317
	jnb	INT0, enable_timer0_int0
	sjmp	label318
label317:
	mov	R0, #29h
label319:
	jnb	INT0, enable_timer0_int0
	jnb	T1, enable_timer0_int0
label382:
	djnz	R0, label319
	ljmp	label320

enable_timer0_int0:
	setb	TR0
	setb	ET0
	setb	EX0
label315:
	ljmp	exit_cmd_handler

resend_data:
	mov	A, 2Dh
	ajmp	label321
label287:
	clr	26h
	clr	27h
	sjmp	label322
label288:
	clr	26h
	setb	27h
	sjmp	label322
label289:
	setb	26h
	clr	27h
label322:
	acall	send0FAh__genericAck
	jnz	label323
	acall	label324
	setb	22h
	setb	2Bh
	ajmp	unsupported_cmd

recOK_sendACK:
	acall	send0FAh__genericAck
	jnz	label323
	mov	DPTR, #data0E26
	LOAD_CMDID_IN_ACC
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
	cjne	A, #0FFh, supported_cmd
	ajmp	unsupported_cmd

supported_cmd:
	mov	R2, A
	acall	label80
	mov	A, R0
	cpl	A
	anl	A, @R1
	mov	@R1, A
	jb	26h, label326
	jnb	27h, label327
	mov	A, R0
	rr	A
label328:
	anl	A, R0
	orl	A, @R1
	mov	@R1, A
label327:
	ajmp	unsupported_cmd
label326:
	mov	A, R0
	rl	A
	sjmp	label328
label323:
	ljmp	exit_cmd_handler

label290:
	mov	R2, #0FFh
label331:
	acall	send0FAh__genericAck
	jnz	send_0FAh_nok1
	LOAD_CMDID_IN_ACC
	mov	R0, #56h
label330:
	mov	@R0, A
	inc	R0
	cjne	R0, #72h, label330
	setb	25h
	acall	label324
send_0FAh_nok1:
	ljmp	exit_cmd_handler

label291:
	mov	R2, #0h
	sjmp	label331
label292:
	mov	R2, #55h
	sjmp	label331

label293:
	mov	R2, #BAT_CHK_PASSED_2PC
	sjmp	label331

label294:
	acall	send0FAh__genericAck
	jnz	send_0FAh_nok2
	acall	flags_and_vars_init
	acall	label324

send_0FAh_nok2:
	ljmp	exit_cmd_handler

label295:
	acall	send0FAh__genericAck
	jnz	send_0FAh_nok3
	acall	flags_and_vars_init
	acall	label324
	setb	22h         ; scanning enabled flag
send_0FAh_nok3:
	ljmp	exit_cmd_handler

label296:
	acall	send0FAh__genericAck
	jnz	send_0FAh_nok4
	acall	label324
	clr	22h           ; scanning disabled flag
send_0FAh_nok4:
	ljmp	exit_cmd_handler

label297:
	acall	send0FAh__genericAck
	jnz	send_0FAh_nok5
	setb	28h
	ljmp	unsupported_cmd

label305:
	lcall	send0FAh__genericAck
	jnz	send_0FAh_nok5
	mov	DPTR, #data0F26
	LOAD_CMDID_IN_ACC
	anl	A, #60h
	swap	A
	mov	R0, A
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
	mov	28h, A
	inc	R0
	mov	A, R0
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
	mov	29h, A
	mov	DPTR, #data0F2E
	LOAD_CMDID_IN_ACC
	anl	A, #1Fh
	rl	A
	mov	R0, A
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
	mov	2Ah, A
	inc	R0
	mov	A, R0
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
	mov	2Bh, A

send_0FAh_nok5:
	ljmp	exit_cmd_handler

label298:
	lcall	send0FAh__genericAck
	jnz	send_0FAh_nok5
	clr	22h
label342:
	mov	25h, #0h
	mov	A, #0ABh
	lcall	sendAccumulator
	jz	label336
	setb	2Ch
	ajmp	data_received

label336:
	mov	25h, #0h
	mov	A, #83h
	lcall	sendAccumulator
	jz	send_0FAh_nok5
	setb	2Dh
	ajmp	data_received

label299:
	acall	send0FAh__genericAck
	jnz	label337
	acall	label324
	setb	2Ah
	ajmp	unsupported_cmd

label309:
	acall	send0FAh__genericAck
	jnz	label337
	cjne	R2, #0h, label338
label345:
	mov	25h, #0h
	mov	A, 26h
	lcall	sendAccumulator
	jz	label337
	setb	2Eh
	ajmp	data_received
label338:
	mov	26h, R2
label337:
	ljmp	exit_cmd_handler

label300:
	mov	A, #0EEh
	lcall	sendAccumulator

label385:
	ljmp	exit_cmd_handler
label301:
	lcall	send0FAh__genericAck
	jnz	label339
	setb	29h
	ajmp	unsupported_cmd
label307:
	lcall	send0FAh__genericAck
	jnz	label339
	LOAD_CMDID_IN_ACC
	rrc	A
	mov	90h, C
	rrc	A
	mov	91h, C
	mov	23h, C
	rrc	A
label392:
	mov	92h, C
label339:
	ljmp	exit_cmd_handler

send0FEh_data:
	mov	A, #0FEh
label321:
	lcall	sendAccumulator
	jz	label340
	ljmp	data_received

label340:
	jnb	2Ch, label341
	ljmp	label342
label341:
	jnb	2Dh, label343
	ljmp	label336
label343:
	jnb	2Eh, label344
	ljmp	label345
label344:
	mov	A, 25h
	jnz	label346
	ljmp	exit_cmd_handler
label346:
	ljmp	unsupported_cmd

label80:
	LOAD_CMDID_IN_ACC
	anl	A, #3h
	mov	DPTR, #data01
	movc	A, @A+DPTR        ; load accumulator with DPTR + A pointed data
	mov	R0, A
	LOAD_CMDID_IN_ACC
	anl	A, #0FCh
	rr	A
	rr	A
	add	A, #56h
	mov	R1, A
	ret

data01:	
	db 03h
	db 0Ch
	db 30h
	db 0C0h
;	db 78h
;	db 56h


; ----------------------------------------------------------------------------------------------

flags_and_vars_init:	
	mov R0, #56h
label9_loop:	
  mov	@R0, #0FFh
	inc	R0
	cjne	R0, #72h, label9_loop
	clr	25h
	mov	28h, #1h
	mov	29h, #0F4h
	mov	2Ah, #0h
	mov	2Bh, #5Ch
	ret
	
label324:
	jnb	1Eh, label349
	ret
label349:
	mov	R0, #34h
	lcall	scanning_routine

PS2_clock_edge_count:
	mov	A, #40h
label350:
	mov	C, T0
	inc	P2
	rrc	A
	jnc	label350
	mov	C, T0
	rrc	A
	anl	A, @R0
	mov	@R0, A
	jnb	1h, label351
	inc	R0
	lcall	label43
	sjmp	PS2_clock_edge_count

label351:
	mov	2Eh, #43h ; Reset Write Pointer to start of buffer
	mov	2Fh, #43h ; Reset Read Pointer to start of buffer
	clr	A
	mov	byteTosend, A ; Clear the "bytes-to-send" counter
	mov	33h, A
	mov	C, 1Ah
	mov	23h, A
	mov	1Ah, C
	mov	31h, A
	mov	R0, #8h
	mov	A, 34h
label354:
	rrc	A
	jnc	label353
	inc	31h
label353:
	djnz	R0, label354
	mov	A, 35h
	jnb	0E7h, label355
	inc	31h
label355:
	mov	R0, #3h
label357:
	rrc	A
	jnc	label356
	inc	31h
label356:
	djnz	R0, label357
	mov	A, 35h
	mov	C, 0E4h
	mov	16h, C
	mov	A, 36h
	rrc	A
	rrc	A
	rrc	A
	mov	11h, C
	rrc	A
	mov	10h, C
	mov	A, 41h
	rrc	A
	mov	17h, C
	mov	A, 42h
	mov	C, 0E0h
	mov	15h, C
	mov	C, 0E5h
	mov	14h, C
	setb	1Eh
label25:
	mov	0Ch, #0h
	mov	0Dh, #0h
	clr	9h
	ret

label320:
	mov	SP, #STACK_POINTER_POS

ifdef use_buzzer
	mov	P1, #0FFh ; turn ON LEDs - buzzer off
else
	mov	P1, #0F7h ; turn ON LEDs
endif

	mov	TL0, #0h
	mov	TH0, #0F1h
  lcall	HW_init_return_R1equAA
	mov	R0, #7Fh

label359:
	mov	@R0, #0FFh
	cjne	@R0, #0FFh, label358
	mov	@R0, #0h
	cjne	@R0, #0h, label358
	dec	R0
	cjne	R0, #1h, label359
	sjmp	label360
label358:
	mov	R0, #7Fh
label361:
	mov	@R0, #0h
	djnz	R0, label361
	mov	R1, #BAT_CHK_FAILED_2PC
label360:
	clr	21h
	ljmp	label362

reload_defaults:
	clr	ET0
	acall	int0lbl_reti
	mov	SP, #STACK_POINTER_POS

ifdef use_buzzer
	mov	P1, #0BFh ; turn on all leds and put clock p1.6 to low - buzzer off
else
	mov	P1, #0B7h ; turn on all leds (a flash to signal error) and put clock p1.6 to low
endif

	mov	TL0, #0h    ; Timer0 Low
	mov	TH0, #0F1h  ; Timer0 High
	clr	RS0
  lcall	HW_init_return_R1equAA

high_security_memory_wipe:
	mov	R0, #7Fh
label364:
	mov	@R0, #0FFh
	cjne	@R0, #0FFh, label363
	mov	@R0, #0h
	cjne	@R0, #0h, label363
	dec	R0
	cjne	R0, #1h, label364
	sjmp	label365

label363:
	mov	R0, #7Fh
label366:
	mov	@R0, #0h
	djnz	R0, label366
	mov	R1, #BAT_CHK_FAILED_2PC
label365:
	mov	2Ch, R1
	mov	26h, #1h
	acall	flags_and_vars_init
	mov	2Eh, #43h
	mov	2Fh, #43h
	setb	20h

ifdef use_buzzer
	anl	P1, #0FFh ; turn OFF LED and buzzer
else
  anl	P1, #0F8h ; turn OFF LED
endif

	setb	TR0
	setb	ET0
waitClock_high_P3_5:
	jnb	T1, $     ; T1 refers to the external input pin P3.5 - Waits for pin P3.5 to go High
	mov	R0, #1h
	acall	delayR0x2_5ms   ; 2.5ms delay
	mov	A, 2Ch
	lcall	Host_RTS_chk
	jnz	waitClock_high_P3_5
	jnb	T1, waitClock_high_P3_5
	ljmp	check_BAT_CompletionOK
	
delayR0x2_5ms:
  	mov	R1, #0FAh
loopDelay2_5ms:
	nop
	nop
	nop
	djnz	R1, loopDelay2_5ms
	djnz	R0, delayR0x2_5ms
	ret

data0CBF:
        db 4Bh
        db 50h
        db 4Dh
        db 48h  
        db 53h
        db 4Fh
        db 51h
        db 52h
        db 47h
        db 49h  
        db 37h  
        db 00h  
        db 38h  
        db 1Dh  
        db 1Ch  
        db 35h
        db 1Dh
        db 38h  
        db 2Ah  
        db 36h  
        db 3Ah  
        db 00h  
        db 00h  
        db 45h
        db 1Ah
        db 1Bh  
        db 2Bh  
        db 47h  
        db 48h  
        db 49h  
        db 37h  
        db 4Ah  
        db 26h  
        db 27h  
        db 28h  
        db 1Ch  
        db 4Bh  
        db 4Ch  
        db 4Dh  
        db 4Eh  
        db 1Eh  
        db 1Fh  
        db 20h
        db 21h
        db 22h
        db 23h  
        db 24h
        db 25h
        db 2Ch  
        db 2Dh  
        db 2Eh  
        db 2Fh  
        db 30h
        db 31h
        db 32h
        db 33h  
        db 34h
        db 35h
        db 39h  
        db 52h
        db 53h
        db 4Fh  
        db 50h
        db 51h
        db 01h
        db 3Bh
        db 3Ch  
        db 3Dh  
        db 3Eh  
        db 3Fh  
        db 40h
        db 41h
        db 19h  
        db 42h
        db 43h
        db 44h
        db 57h
        db 58h  
        db 46h  

        db 00h
        db 29h
        db 02h
        db 03h
        db 04h
        db 05h
        db 06h
        db 07h
        db 08h
        db 09h
        db 0Ah
        db 0Bh
        db 0Ch
        db 0Dh
        db 0Eh
        db 17h
        db 18h
        db 0Fh
        db 10h
        db 11h
        db 12h
        db 13h
        db 14h
        db 15h
        db 16h
        db 00h
 
        db 2Bh
        db 56h
        db 73h
        db 7Ch
        db 7Dh
        db 78h
        db 7Eh

data0D2F:
        db 6Bh    
        db 72h
        db 74h  
        db 75h
        db 71h
        db 69h
        db 7Ah
        db 70h
        db 6Ch
        db 7Dh
        db 7Ch
        db 00h
        db 11h
        db 14h
        db 5Ah
        db 4Ah
        db 14h
        db 11h
        db 12h
        db 59h
        db 58h
        db 00h
        db 00h
        db 77h
        db 54h
        db 5Bh
        db 5Dh
        db 6Ch
        db 75h
        db 7Dh
        db 7Ch
        db 7Bh
        db 4Bh
        db 4Ch
        db 52h
        db 5Ah
        db 6Bh
        db 73h
        db 74h
        db 79h
        db 1Ch
        db 1Bh
        db 23h
        db 2Bh
        db 34h
        db 33h
        db 3Bh
        db 42h
        db 1Ah
        db 22h
          
label0D61:
        db 21h
        db 2Ah
        db 32h 
        db 31h
        db 3Ah
        db 41h
        db 49h
        db 4Ah 
        db 29h 

label0D6A:
        db 70h
        db 71h
        db 69h
        db 72h
        db 7ah
        db 76h
        db 05h
        db 06h
        db 04h
        db 0Ch
        db 03h
        db 0Bh
        db 83h
        db 4Dh
        db 0Ah
        db 01h
        db 09h
        db 78h
        db 07h
        db 7Eh
        db 00h
        db 0Eh
        db 16h
        db 1Eh
        db 26h
        db 25h
        db 2Eh
        db 36h
        db 3Dh
        db 3Eh
        db 46h
        db 45h
        db 4Eh
        db 55h
        db 66h
        db 43h
        db 44h
        db 0Dh
        db 15h
        db 1Dh
        db 24h
        db 2Dh
        db 2Ch
        db 35h
        db 3Ch
        db 00h
        db 5Dh
        db 61h
        db 51h
        db 68h
        db 6Ah
        db 63h
        db 6Dh

data0D9F:
        db 0E1h
        db 0E0h
        db 0EAh
        db 0E3h
        db 0E4h
        db 65h
        db 6Dh
        db 67h
        db 6Eh
        db 6Fh
        db 57h
        db 00h
        db 39h
        db 58h
        db 79h
        db 77h
        db 11h
        db 19h

        db 12h
        dw 5914h
        db 00
        db 00
        db 76h
        db 0D4h
        db 0DBh
        db 0DCh
        db 6Ch
        db 75h
        db 7Dh
        db 7Eh
        db 84h
        db 0CBh
        db 0CCh
; 0dc1
        db 0d2h
        db 0dah
        dw 06b73h
        dw 074FCh
        db 09ch
        db 09bh
        db 0a3h
; 0DCA
	db 0ABh
	db 0B4h  
	db 0B3h
	db 0BBh
	db 0C2h
	db 9Ah
	db 0A2h
	db 0A1h  
	db 0AAh
	db 0B2h
	db 0B1h
	db 0BAh
	db 0C1h
	db 0C9h
	db 0CAh  
	db 0A9h
	db 70h
	db 71h
	db 69h
; 0DDD
	db 72h
	db 7Ah
	db 08h
	db 07h
	db 0fh
	db 17h
	db 1fh
	db 27h
	db 2fh
	db 37h
	db 0CDh
	db 3Fh
	db 47h
	db 4Fh
	db 56h
	db 5Eh
	db 5Fh
	db 62h
	db 8Eh
	db 96h
	db 9Eh
	db 0A6h
	db 0A5h
	db 0AEh
	db 0B6h
	db 0BDh
	db 0BEh
	db 0C6h
	db 0C5h
	db 0CEh
	db 0D5h
	db 0E6h
	db 0C3h
	db 0C4h
	db 8Dh
	db 95h
	db 9Dh
	db 0A4h
	db 0ADh
	db 0ACh
	db 0B5h
	db 0BCh
	db 00h

; 0E08
	db 0D3h
	db 93h
	db 0D1h
	db 68h
	db 0DDh
	db 78h
	db 0FBh

data0E0F:
	db 0E1h
	db 1Dh
	db 45h
	db 0E1h
	db 9Dh
	db 0C5h

data0E15:
	db 0E0h
	db 46h
	db 0E0h
	db 0C6h

data0E19:
	db 0E1h
	db 14h
	db 77h
	db 0E1h
	db 0F0h
	db 14h
	db 0F0h
	db 77h

data0E21:
	db 0E0h
	db 7Eh
	db 0E0h
	db 0F0h
	db 7Eh

data0E26:
        db 0FFh
        db 0FFh
        db 0FFh
        db 0FFh
        db 0FFh
        db 0FFh
        db 0FFh
        db 41h
        db 40h
        db 0FFh
        db 0FFh
        db 0FFh
        db 0FFh
        db 60h
        db 50h
        db 42h
        db 0FFh
        db 10h
        db 12h
        db 6Ah
        db 14h
        db 61h
        db 51h
        db 43h
        db 0FFh
        db 11h
        db 30h
        db 29h
        db 28h
        db 62h
        db 52h
        db 44h
        db 0FFh
        db 32h

label0E48:
        db 31h
        db 2Ah
        db 63h
        db 54h
        db 53h
        db 45h
        db 0FFh
        db 3Ah
        db 33h
        db 2Bh
        db 65h
        db 64h
        db 55h
        db 46h
        db 0FFh
        db 35h
        db 34h
        db 2Dh
        db 2Ch
        db 66h
        db 56h
        db 47h
        db 0FFh
        db 0Ch
        db 36h
        db 2Eh
        db 67h
        db 57h
        db 58h
        db 49h
        db 0FFh
        db 37h

; -------------------------------------------------------------------------------------------------------

        db 2Fh
        db 5Eh
        db 5Fh
        db 5Ah
        db 59h
        db 4Ah
        db 0FFh
        db 38h
        db 39h
        db 20h
        db 21h
        db 48h
        db 5Bh
        db 4Bh
        db 0FFh
        db 6Bh
        db 22h
        db 69h
        db 18h
        db 5Ch
        db 4Ch
        db 0Ah
        db 0Dh
        db 13h
        db 23h
        db 19h
        db 1Ah
        db 6Dh
        db 4Dh

label401:
        db 4Eh
        db 01h
        db 00h
        db 4Fh
        db 03h
        db 04h
        db 05h
        db 5Dh
        db 07h
        db 6Ch
        db 3Dh
        db 02h
        db 24h
        db 1Bh
; 0E93	
        db 06h
        db 08h
        db 09h
        db 3Bh
        db 3Ch
        db 3Eh
        db 25h
        db 26h
        db 1Ch
        db 17h
; ------------------------        
        db 0Fh
        db 6Eh
; ------------------------        
        db 0Eh
        db 3Fh
        db 6Fh
        db 27h
        db 1Dh
  
        db 1Eh
        db 0FFh
        db 0FFh
        db 0FFh
        db 0FFh
        db 0FFh
        db 01Fh
        db 0FFh
        db 0FFh
        db 0FFh

data0EAE:
        db 00h
        db 01h
        db 02h
        db 03h
        db 04h
        db 05h
        db 06h
        db 07h
        db 08h
        db 09h
        db 0Ah    ; 11
        db 14h    ; 12
        db 0Ch    ; 13
        db 17h    ; 14
        db 0eh    ; 15
        db 0fh    ; 16  - Led 1
        db 0ffh   ; 17  - Led 2
        db 0ffh   ; 18  - Led 3 -> max X rows
        db 12h
        db 13h
        db 0FFh
        db 0FFh
        db 0FFh
        db 0FFh
        db 18h
        db 19h
        db 1Ah
        db 1bh
        db 1ch
        db 1dh
        db 1eh
        db 1fh
        db 20h
        db 21h
        db 22h
        db 23h
        db 24h
        db 25h
        db 26h
        db 27h
        db 28h
        db 29h
        db 2ah
        db 2bh
        db 2ch
        db 2dh
        db 2eh
        db 2fh
;	30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f 40 41 42 43 44 45 46 47 48 49 4a 4b 4c 4d 4e 4f 50 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f 60 61 62 63 64 65 66 67
	db '0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefg'

;	-------------------------------
  db 11h
  db 69h
  db 6Ah
  db 6Bh
  db 6Ch
  db 6Dh
  db 6Eh
  db 6Fh
  db 10h
  db 0FFh
  db 0FFh
  db 0FFh
  db 0FFh
  db 0Dh
  db 0FFh
  db 0FFh

data0F26:
  dw 00FAh  ;	250 ms delay
  dw 01F4h  ;  500 ms delay
  dw 02EEh  ;  750 ms delay
  dw 03E8h  ; 1000 ms delay

data0F2E:
	db 00h
	db 21h
	db 00h
  db 25h
  db 00h
  db 29h
  db 00h
  db 2Eh
  db 00h
  db 32h
       
  db 00h
  db 36h
  db 00h
  db 3Ah
  db 00h
  db 3Fh
  db 00h
  db 43h
  db 00h
  db 4Bh
  db 00h
  db 53h
  db 00h
  db 5Ch
  db 00h
  db 64h
  db 00h
  db 6Dh
  db 00h
  db 74h
  db 00h
  db 7Dh
  db 00h
  db 85h
  db 00h
  db 95h
  db 00h
  db 0A7h
  db 00h

  db 0B6h
  db 00h
  db 0C8h
  db 00h    
  db 0DCh
  db 00h  

; ----------------------
  db 0E9h
  db 00h
  db 0FAh
  db 01h
  db 0Eh
  db 01h
  db 2Fh
  db 01h
  db 4Dh
  db 01h
  db 72h
  db 01h
  db 90h
  db 01h
  db 0B3h
  db 01h
  db 0DCh
  db 01h
  db 0F4h

ifdef disable_ROMchecksum

HW_init_return_R1equAA:
    mov R1, #0AAh  ; Force BAT Success code
    ret            ; Exit immediately

else
HW_init_return_R1equAA:
  mov	R1, #0h
	mov	DPTR, #HW_init_return_R1equAA
label428:
	mov	A, DPL
	jnz	label425
	mov	A, DPH
	jnz	label425
	mov	A, R1
	cjne	A, #1Fh, bat_check_failed           ; checksum (#1Fh) do not match
	mov	R1, #BAT_CHK_PASSED_2PC               ; successful HW init, return 0AAh in R1
	ret

bat_check_failed:
	mov	R1, #BAT_CHK_FAILED_2PC
	ret

label425:
	dec	DPL
	mov	A, DPL
	cjne	A, #0FFh, label427
	dec	DPH

label427:
	clr	A
	movc	A, @A+DPTR      ; load accumulator with DPTR + A pointed data
	xrl	A, R1
	mov	R1, A
	sjmp	label428

endif


; --- Startup LED Sequence for N86D-4700 ---
startup_led_test:

ifdef use_buzzer
    ; LED 1 (P1.0) - Scroll Lock ON - buzzer on
    mov  P1, #0F1h
else
    ; LED 1 (P1.0) - Scroll Lock ON - buzzer off
    mov  P1, #0F9h
endif
    lcall delay_50ms
    
    ; All LEDs OFF - buzzer off
    mov  P1, #0F8h
    lcall delay_100ms

    ; LED 2 (P1.1) - Num Lock - buzzer off
    mov  P1, #0FAh
    lcall delay_50ms
    
    ; All LEDs OFF - buzzer off
    mov  P1, #0F8h
    lcall delay_100ms

ifdef use_buzzer
    ; LED 3 (P1.2) - Caps Lock - buzzer on
    mov  P1, #0F4h
else
    ; LED 3 (P1.2) - Caps Lock - buzzer off
    mov  P1, #0FCh
endif
    lcall delay_50ms
    
    ; All LEDs OFF - buzzer off
    mov  P1, #0F8h
    ; --- End of Sequence
    ret


; --- Precise 200ms Delay for 6 MHz Clock ---
delay_100ms:
    mov  R7, #4         ; Outer loop
d_loop1:
    mov  R6, #100       ; Middle loop
d_loop2:
    mov  R5, #250       ; Inner loop
    djnz R5, $          ; 4us * 250 = 1ms
    djnz R6, d_loop2    ; 1ms * 100 = 100ms
    djnz R7, d_loop1
    ret

delay_50ms:
    ;clr	93h     ; set port P1.3 low - pin AKD - buzzer ON
    mov  R7, #1         ; Outer loop
d50_loop1:
    mov  R6, #100       ; Middle loop
d50_loop2:
    mov  R5, #250       ; Inner loop
    djnz R5, $          ; 4us * 250 = 1ms
    djnz R6, d50_loop2    ; 1ms * 100 = 100ms
    djnz R7, d50_loop1
    ;setb	93h     ; set port P1.3 high - pin AKD - buzzer OFF
    ret

switchON_LEDs_and_stop:
  clr	EA		; disable all interrupts
  mov	P1, #0F7h ; turn ON LEDs
  sjmp $ ; infinite loop

	END
