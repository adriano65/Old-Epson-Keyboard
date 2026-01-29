;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.0 #15242 (Linux)
;--------------------------------------------------------
	.module p8051
	
	.optsdcc -mmcs51 --model-small
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _delay500ms_PARM_2
	.globl _data0EAE
	.globl _PS2_CLK
	.globl _PS2_DATA
	.globl _BIT_95H
	.globl _BIT_93H
	.globl _LED_P1_2
	.globl _LED_P1_1
	.globl _LED_P1_0
	.globl _CY
	.globl _AC
	.globl _F0
	.globl _RS1
	.globl _RS0
	.globl _OV
	.globl _F1
	.globl _P
	.globl _PS
	.globl _PT1
	.globl _PX1
	.globl _PT0
	.globl _PX0
	.globl _RD
	.globl _WR
	.globl _T1
	.globl _T0
	.globl _INT1
	.globl _INT0
	.globl _TXD
	.globl _RXD
	.globl _P3_7
	.globl _P3_6
	.globl _P3_5
	.globl _P3_4
	.globl _P3_3
	.globl _P3_2
	.globl _P3_1
	.globl _P3_0
	.globl _EA
	.globl _ES
	.globl _ET1
	.globl _EX1
	.globl _ET0
	.globl _EX0
	.globl _P2_7
	.globl _P2_6
	.globl _P2_5
	.globl _P2_4
	.globl _P2_3
	.globl _P2_2
	.globl _P2_1
	.globl _P2_0
	.globl _SM0
	.globl _SM1
	.globl _SM2
	.globl _REN
	.globl _TB8
	.globl _RB8
	.globl _TI
	.globl _RI
	.globl _P1_7
	.globl _P1_6
	.globl _P1_5
	.globl _P1_4
	.globl _P1_3
	.globl _P1_2
	.globl _P1_1
	.globl _P1_0
	.globl _TF1
	.globl _TR1
	.globl _TF0
	.globl _TR0
	.globl _IE1
	.globl _IT1
	.globl _IE0
	.globl _IT0
	.globl _P0_7
	.globl _P0_6
	.globl _P0_5
	.globl _P0_4
	.globl _P0_3
	.globl _P0_2
	.globl _P0_1
	.globl _P0_0
	.globl _B
	.globl _ACC
	.globl _PSW
	.globl _IP
	.globl _P3
	.globl _IE
	.globl _P2
	.globl _SBUF
	.globl _SCON
	.globl _P1
	.globl _TH1
	.globl _TH0
	.globl _TL1
	.globl _TL0
	.globl _TMOD
	.globl _TCON
	.globl _PCON
	.globl _DPH
	.globl _DPL
	.globl _SP
	.globl _P0
	.globl _FLAG_PARITY_RCV
	.globl _FLAG_25H
	.globl _FLAG_23H
	.globl _FLAG_22H
	.globl _FLAG_21H
	.globl _FLAG_20H
	.globl _FLAG_1FH
	.globl _FLAG_1EH
	.globl _FLAG_1DH
	.globl _FLAG_1CH
	.globl _FLAG_1BH
	.globl _FLAG_1AH
	.globl _FLAG_19H
	.globl _FLAG_18H
	.globl _FLAG_17H
	.globl _FLAG_16H
	.globl _FLAG_15H
	.globl _FLAG_14H
	.globl _FLAG_13H
	.globl _FLAG_12H
	.globl _FLAG_11H
	.globl _FLAG_10H
	.globl _FLAG_0FH
	.globl _FLAG_0EH
	.globl _FLAG_0DH
	.globl _FLAG_0CH
	.globl _FLAG_0BH
	.globl _FLAG_0AH
	.globl _FLAG_9H
	.globl _FLAG_8H
	.globl _FLAG_1H
	.globl _reg_r7
	.globl _reg_r6
	.globl _reg_r5
	.globl _reg_r4
	.globl _reg_r3
	.globl _reg_r2
	.globl _reg_r1
	.globl _reg_r0
	.globl _STATUS_H
	.globl _STATUS_L
	.globl _VAR_33
	.globl _KEY_COUNT
	.globl _VAR_31
	.globl _SCAN_PTR
	.globl _PTR_R
	.globl _PTR_W
	.globl _LAST_BYTE
	.globl _TX_BYTE
	.globl _VAR_2B
	.globl _SCAN_SET
	.globl _DELAY_VAL
	.globl _RATE_VAL
	.globl _LAST_SCAN
	.globl _MODE_SEL
	.globl _label4
	.globl _label9
	.globl _label23
	.globl _delay500ms
	.globl _main
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
	.area RSEG    (ABS,DATA)
	.org 0x0000
_P0	=	0x0080
_SP	=	0x0081
_DPL	=	0x0082
_DPH	=	0x0083
_PCON	=	0x0087
_TCON	=	0x0088
_TMOD	=	0x0089
_TL0	=	0x008a
_TL1	=	0x008b
_TH0	=	0x008c
_TH1	=	0x008d
_P1	=	0x0090
_SCON	=	0x0098
_SBUF	=	0x0099
_P2	=	0x00a0
_IE	=	0x00a8
_P3	=	0x00b0
_IP	=	0x00b8
_PSW	=	0x00d0
_ACC	=	0x00e0
_B	=	0x00f0
;--------------------------------------------------------
; special function bits
;--------------------------------------------------------
	.area RSEG    (ABS,DATA)
	.org 0x0000
_P0_0	=	0x0080
_P0_1	=	0x0081
_P0_2	=	0x0082
_P0_3	=	0x0083
_P0_4	=	0x0084
_P0_5	=	0x0085
_P0_6	=	0x0086
_P0_7	=	0x0087
_IT0	=	0x0088
_IE0	=	0x0089
_IT1	=	0x008a
_IE1	=	0x008b
_TR0	=	0x008c
_TF0	=	0x008d
_TR1	=	0x008e
_TF1	=	0x008f
_P1_0	=	0x0090
_P1_1	=	0x0091
_P1_2	=	0x0092
_P1_3	=	0x0093
_P1_4	=	0x0094
_P1_5	=	0x0095
_P1_6	=	0x0096
_P1_7	=	0x0097
_RI	=	0x0098
_TI	=	0x0099
_RB8	=	0x009a
_TB8	=	0x009b
_REN	=	0x009c
_SM2	=	0x009d
_SM1	=	0x009e
_SM0	=	0x009f
_P2_0	=	0x00a0
_P2_1	=	0x00a1
_P2_2	=	0x00a2
_P2_3	=	0x00a3
_P2_4	=	0x00a4
_P2_5	=	0x00a5
_P2_6	=	0x00a6
_P2_7	=	0x00a7
_EX0	=	0x00a8
_ET0	=	0x00a9
_EX1	=	0x00aa
_ET1	=	0x00ab
_ES	=	0x00ac
_EA	=	0x00af
_P3_0	=	0x00b0
_P3_1	=	0x00b1
_P3_2	=	0x00b2
_P3_3	=	0x00b3
_P3_4	=	0x00b4
_P3_5	=	0x00b5
_P3_6	=	0x00b6
_P3_7	=	0x00b7
_RXD	=	0x00b0
_TXD	=	0x00b1
_INT0	=	0x00b2
_INT1	=	0x00b3
_T0	=	0x00b4
_T1	=	0x00b5
_WR	=	0x00b6
_RD	=	0x00b7
_PX0	=	0x00b8
_PT0	=	0x00b9
_PX1	=	0x00ba
_PT1	=	0x00bb
_PS	=	0x00bc
_P	=	0x00d0
_F1	=	0x00d1
_OV	=	0x00d2
_RS0	=	0x00d3
_RS1	=	0x00d4
_F0	=	0x00d5
_AC	=	0x00d6
_CY	=	0x00d7
_LED_P1_0	=	0x0090
_LED_P1_1	=	0x0091
_LED_P1_2	=	0x0092
_BIT_93H	=	0x0093
_BIT_95H	=	0x0095
_PS2_DATA	=	0x0096
_PS2_CLK	=	0x0097
;--------------------------------------------------------
; overlayable register banks
;--------------------------------------------------------
	.area REG_BANK_0	(REL,OVR,DATA)
	.ds 8
;--------------------------------------------------------
; internal ram data
;--------------------------------------------------------
	.area DSEG    (DATA)
_MODE_SEL	=	0x0026
_LAST_SCAN	=	0x0027
_RATE_VAL	=	0x0028
_DELAY_VAL	=	0x0029
_SCAN_SET	=	0x002a
_VAR_2B	=	0x002b
_TX_BYTE	=	0x002c
_LAST_BYTE	=	0x002d
_PTR_W	=	0x002e
_PTR_R	=	0x002f
_SCAN_PTR	=	0x0030
_VAR_31	=	0x0031
_KEY_COUNT	=	0x0032
_VAR_33	=	0x0033
_STATUS_L	=	0x0072
_STATUS_H	=	0x0073
_reg_r0::
	.ds 1
_reg_r1::
	.ds 1
_reg_r2::
	.ds 1
_reg_r3::
	.ds 1
_reg_r4::
	.ds 1
_reg_r5::
	.ds 1
_reg_r6::
	.ds 1
_reg_r7::
	.ds 1
;--------------------------------------------------------
; overlayable items in internal ram
;--------------------------------------------------------
	.area	OSEG    (OVR,DATA)
	.area	OSEG    (OVR,DATA)
	.area	OSEG    (OVR,DATA)
_delay500ms_PARM_2:
	.ds 1
;--------------------------------------------------------
; Stack segment in internal ram
;--------------------------------------------------------
	.area SSEG
__start__stack:
	.ds	1

;--------------------------------------------------------
; indirectly addressable internal ram data
;--------------------------------------------------------
	.area ISEG    (DATA)
;--------------------------------------------------------
; absolute internal ram data
;--------------------------------------------------------
	.area IABS    (ABS,DATA)
	.area IABS    (ABS,DATA)
;--------------------------------------------------------
; bit data
;--------------------------------------------------------
	.area BSEG    (BIT)
_FLAG_1H	=	0x0001
_FLAG_8H	=	0x0008
_FLAG_9H	=	0x0009
_FLAG_0AH	=	0x000a
_FLAG_0BH	=	0x000b
_FLAG_0CH	=	0x000c
_FLAG_0DH	=	0x000d
_FLAG_0EH	=	0x000e
_FLAG_0FH	=	0x000f
_FLAG_10H	=	0x0010
_FLAG_11H	=	0x0011
_FLAG_12H	=	0x0012
_FLAG_13H	=	0x0013
_FLAG_14H	=	0x0014
_FLAG_15H	=	0x0015
_FLAG_16H	=	0x0016
_FLAG_17H	=	0x0017
_FLAG_18H	=	0x0018
_FLAG_19H	=	0x0019
_FLAG_1AH	=	0x001a
_FLAG_1BH	=	0x001b
_FLAG_1CH	=	0x001c
_FLAG_1DH	=	0x001d
_FLAG_1EH	=	0x001e
_FLAG_1FH	=	0x001f
_FLAG_20H	=	0x0020
_FLAG_21H	=	0x0021
_FLAG_22H	=	0x0022
_FLAG_23H	=	0x0023
_FLAG_25H	=	0x0025
_FLAG_PARITY_RCV	=	0x0024
;--------------------------------------------------------
; paged external ram data
;--------------------------------------------------------
	.area PSEG    (PAG,XDATA)
;--------------------------------------------------------
; uninitialized external ram data
;--------------------------------------------------------
	.area XSEG    (XDATA)
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
	.area XABS    (ABS,XDATA)
;--------------------------------------------------------
; initialized external ram data
;--------------------------------------------------------
	.area XISEG   (XDATA)
	.area HOME    (CODE)
	.area GSINIT0 (CODE)
	.area GSINIT1 (CODE)
	.area GSINIT2 (CODE)
	.area GSINIT3 (CODE)
	.area GSINIT4 (CODE)
	.area GSINIT5 (CODE)
	.area GSINIT  (CODE)
	.area GSFINAL (CODE)
	.area CSEG    (CODE)
;--------------------------------------------------------
; interrupt vector
;--------------------------------------------------------
	.area HOME    (CODE)
__interrupt_vect:
	ljmp	__sdcc_gsinit_startup
; restartable atomic support routines
	.ds	5
sdcc_atomic_exchange_rollback_start::
	nop
	nop
sdcc_atomic_exchange_pdata_impl:
	movx	a, @r0
	mov	r3, a
	mov	a, r2
	movx	@r0, a
	sjmp	sdcc_atomic_exchange_exit
	nop
	nop
sdcc_atomic_exchange_xdata_impl:
	movx	a, @dptr
	mov	r3, a
	mov	a, r2
	movx	@dptr, a
	sjmp	sdcc_atomic_exchange_exit
sdcc_atomic_compare_exchange_idata_impl:
	mov	a, @r0
	cjne	a, ar2, .+#5
	mov	a, r3
	mov	@r0, a
	ret
	nop
sdcc_atomic_compare_exchange_pdata_impl:
	movx	a, @r0
	cjne	a, ar2, .+#5
	mov	a, r3
	movx	@r0, a
	ret
	nop
sdcc_atomic_compare_exchange_xdata_impl:
	movx	a, @dptr
	cjne	a, ar2, .+#5
	mov	a, r3
	movx	@dptr, a
	ret
sdcc_atomic_exchange_rollback_end::

sdcc_atomic_exchange_gptr_impl::
	jnb	b.6, sdcc_atomic_exchange_xdata_impl
	mov	r0, dpl
	jb	b.5, sdcc_atomic_exchange_pdata_impl
sdcc_atomic_exchange_idata_impl:
	mov	a, r2
	xch	a, @r0
	mov	dpl, a
	ret
sdcc_atomic_exchange_exit:
	mov	dpl, r3
	ret
sdcc_atomic_compare_exchange_gptr_impl::
	jnb	b.6, sdcc_atomic_compare_exchange_xdata_impl
	mov	r0, dpl
	jb	b.5, sdcc_atomic_compare_exchange_pdata_impl
	sjmp	sdcc_atomic_compare_exchange_idata_impl
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area HOME    (CODE)
	.area GSINIT  (CODE)
	.area GSFINAL (CODE)
	.area GSINIT  (CODE)
	.globl __sdcc_gsinit_startup
	.globl __sdcc_program_startup
	.globl __start__stack
	.globl __mcs51_genXINIT
	.globl __mcs51_genXRAMCLEAR
	.globl __mcs51_genRAMCLEAR
	.area GSFINAL (CODE)
	ljmp	__sdcc_program_startup
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area HOME    (CODE)
	.area HOME    (CODE)
__sdcc_program_startup:
	ljmp	_main
;	return from main will return to caller
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area CSEG    (CODE)
;------------------------------------------------------------
;Allocation info for local variables in function 'label4'
;------------------------------------------------------------
;	p8051.c:78: void label4(void) {
;	-----------------------------------------
;	 function label4
;	-----------------------------------------
_label4:
	ar7 = 0x07
	ar6 = 0x06
	ar5 = 0x05
	ar4 = 0x04
	ar3 = 0x03
	ar2 = 0x02
	ar1 = 0x01
	ar0 = 0x00
;	p8051.c:105: __endasm;
	mov	r1, #0
	mov	dptr, #_label4
l428:
	mov	a, dpl
	jnz	l425
	mov	a, dph
	jnz	l425
	mov	a, r1
	cjne	a, #0x1F, l426
	mov	_reg_r1, #0xAA
	ret
l426:
	mov	_reg_r1, #0xFC
	ret
l425:
	dec	dpl
	mov	a, dpl
	cjne	a, #0xFF, l427
	dec	dph
l427:
	clr	a
	movc	a, @a+dptr
	xrl	a, r1
	mov	r1, a
	sjmp	l428
;	p8051.c:106: }
	ret
;------------------------------------------------------------
;Allocation info for local variables in function 'label9'
;------------------------------------------------------------
;i             Allocated to registers r7 
;------------------------------------------------------------
;	p8051.c:108: void label9(void) {
;	-----------------------------------------
;	 function label9
;	-----------------------------------------
_label9:
;	p8051.c:110: for(i = 0x56; i < 0x72; i++) {
	mov	r7,#0x1c
00104$:
;	p8051.c:111: *((__data unsigned char *)i) = 0xFF;
	mov	a,r7
	dec	a
	mov	r6,a
	mov	r1,a
	mov	@r1,#0xff
;	p8051.c:110: for(i = 0x56; i < 0x72; i++) {
	mov	a,r6
	mov	r7,a
	jnz	00104$
;	p8051.c:113: FLAG_25H = 0;
;	assignBit
	clr	_FLAG_25H
;	p8051.c:114: RATE_VAL = 0x01;
	mov	_RATE_VAL,#0x01
;	p8051.c:115: DELAY_VAL = 0xF4;
	mov	_DELAY_VAL,#0xf4
;	p8051.c:116: SCAN_SET = 0x00;
	mov	_SCAN_SET,#0x00
;	p8051.c:117: VAR_2B = 0x5C;
	mov	_VAR_2B,#0x5c
;	p8051.c:118: }
	ret
;------------------------------------------------------------
;Allocation info for local variables in function 'label23'
;------------------------------------------------------------
;offset        Allocated to registers r7 
;------------------------------------------------------------
;	p8051.c:120: void label23(void) {
;	-----------------------------------------
;	 function label23
;	-----------------------------------------
_label23:
;	p8051.c:122: offset = P2 & 0x07;
	mov	a,_P2
	anl	a,#0x07
	mov	r7,a
;	p8051.c:123: ACC = reg_r7 - 0x34;
	mov	a,_reg_r7
	mov	r6,a
	add	a,#0xcc
	mov	_ACC,a
;	p8051.c:127: __endasm;
	swap	a
	rr	a
;	p8051.c:128: offset += ACC;
	mov	a,_ACC
	add	a, r7
;	p8051.c:129: reg_r2 = data0EAE[offset];
	mov	dptr,#_data0EAE
	movc	a,@a+dptr
	mov	_reg_r2,a
;	p8051.c:130: }
	ret
;------------------------------------------------------------
;Allocation info for local variables in function 'delay500ms'
;------------------------------------------------------------
;r1            Allocated with name '_delay500ms_PARM_2'
;r0            Allocated to registers 
;t             Allocated to registers 
;------------------------------------------------------------
;	p8051.c:132: void delay500ms(unsigned char r0, unsigned char r1) {
;	-----------------------------------------
;	 function delay500ms
;	-----------------------------------------
_delay500ms:
	mov	r7, dpl
;	p8051.c:133: while(r0--) {
00104$:
	mov	ar6,r7
	dec	r7
	mov	a,r6
	jz	00107$
;	p8051.c:134: unsigned char t = r1;
	mov	r6,_delay500ms_PARM_2
;	p8051.c:135: while(t--) {
00101$:
	mov	ar5,r6
	dec	r6
	mov	a,r5
	jz	00104$
;	p8051.c:136: __asm nop __endasm;
	nop	
	sjmp	00101$
00107$:
;	p8051.c:139: }
	ret
;------------------------------------------------------------
;Allocation info for local variables in function 'main'
;------------------------------------------------------------
;	p8051.c:141: void main(void) {
;	-----------------------------------------
;	 function main
;	-----------------------------------------
_main:
;	p8051.c:142: EA = 1;
;	assignBit
	setb	_EA
;	p8051.c:143: SP = 0x0F;
	mov	_SP,#0x0f
;	p8051.c:144: P1 = 0xF7;
	mov	_P1,#0xf7
;	p8051.c:145: TL0 = 0x00;
	mov	_TL0,#0x00
;	p8051.c:146: TH0 = 0xF1;
	mov	_TH0,#0xf1
;	p8051.c:148: delay500ms(0xC8, 0xFA);
	mov	_delay500ms_PARM_2,#0xfa
	mov	dpl, #0xc8
	lcall	_delay500ms
;	p8051.c:149: label4(); 
	lcall	_label4
;	p8051.c:152: for (reg_r0 = 0x7F; reg_r0 > 0x01; reg_r0--) {
	mov	_reg_r0,#0x7f
00114$:
;	p8051.c:153: *((__data unsigned char *)reg_r0) = 0xFF;
	mov	r1,_reg_r0
	mov	@r1,#0xff
;	p8051.c:154: if (*((__data unsigned char *)reg_r0) != 0xFF) goto ram_fail;
	mov	r1,_reg_r0
	mov	ar7,@r1
	cjne	r7,#0xff,00106$
;	p8051.c:155: *((__data unsigned char *)reg_r0) = 0x00;
	mov	@r1,#0x00
;	p8051.c:156: if (*((__data unsigned char *)reg_r0) != 0x00) goto ram_fail;
	mov	r1,_reg_r0
	mov	a,@r1
	jnz	00106$
;	p8051.c:152: for (reg_r0 = 0x7F; reg_r0 > 0x01; reg_r0--) {
	dec	_reg_r0
	mov	a,_reg_r0
	add	a,#0xff - 0x01
	jc	00114$
;	p8051.c:158: goto ram_ok;
;	p8051.c:160: ram_fail:
	sjmp	00108$
00106$:
;	p8051.c:161: for (reg_r0 = 0x7F; reg_r0 > 0; reg_r0--) {
	mov	_reg_r0,#0x7f
00116$:
;	p8051.c:162: *((__data unsigned char *)reg_r0) = 0x00;
	mov	r1,_reg_r0
	mov	@r1,#0x00
;	p8051.c:161: for (reg_r0 = 0x7F; reg_r0 > 0; reg_r0--) {
	djnz	_reg_r0,00116$
;	p8051.c:164: reg_r1 = 0xFC;
	mov	_reg_r1,#0xfc
;	p8051.c:166: ram_ok:
00108$:
;	p8051.c:167: FLAG_21H = 1;
;	assignBit
	setb	_FLAG_21H
;	p8051.c:169: while(1) {
00112$:
;	p8051.c:170: TX_BYTE = reg_r1;
	mov	_TX_BYTE,_reg_r1
;	p8051.c:171: MODE_SEL = 0x02;
	mov	_MODE_SEL,#0x02
;	p8051.c:172: label9();
	lcall	_label9
;	p8051.c:173: PTR_W = 0x43;
	mov	_PTR_W,#0x43
;	p8051.c:174: PTR_R = 0x43;
	mov	_PTR_R,#0x43
;	p8051.c:175: P1 &= 0xF8;
	anl	_P1,#0xf8
;	p8051.c:176: if (!FLAG_21H) { TR0 = 1; ET0 = 1; EX0 = 1; }
	jb	_FLAG_21H,00112$
;	assignBit
	setb	_TR0
;	assignBit
	setb	_ET0
;	assignBit
	setb	_EX0
;	p8051.c:178: }
	sjmp	00112$
	.area CSEG    (CODE)
	.area CONST   (CODE)
	.area CONST   (CODE)
_data0EAE:
	.db #0x00	; 0
	.area CSEG    (CODE)
	.area XINIT   (CODE)
	.area CABS    (ABS,CODE)
