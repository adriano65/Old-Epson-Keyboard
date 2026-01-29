#include <8051.h>

// --- DEFINIZIONE BIT SFR ---
__sbit __at (0x90) LED_P1_0; 
__sbit __at (0x91) LED_P1_1; 
__sbit __at (0x92) LED_P1_2; 
__sbit __at (0x93) BIT_93H;   
__sbit __at (0x95) BIT_95H;   
__sbit __at (0x96) PS2_DATA;  
__sbit __at (0x97) PS2_CLK;   

// --- DEFINIZIONE FLAG BIT (Area 0x20-0x2F) ---
__bit __at (0x01) FLAG_1H;
__bit __at (0x08) FLAG_8H;    
__bit __at (0x09) FLAG_9H;    
__bit __at (0x0A) FLAG_0AH;
__bit __at (0x0B) FLAG_0BH;
__bit __at (0x0C) FLAG_0CH;
__bit __at (0x0D) FLAG_0DH;
__bit __at (0x0E) FLAG_0EH;
__bit __at (0x0F) FLAG_0FH;
__bit __at (0x10) FLAG_10H;
__bit __at (0x11) FLAG_11H;
__bit __at (0x12) FLAG_12H;
__bit __at (0x13) FLAG_13H;
__bit __at (0x14) FLAG_14H;
__bit __at (0x15) FLAG_15H;
__bit __at (0x16) FLAG_16H;
__bit __at (0x17) FLAG_17H;
__bit __at (0x18) FLAG_18H;
__bit __at (0x19) FLAG_19H;
__bit __at (0x1A) FLAG_1AH;
__bit __at (0x1B) FLAG_1BH;
__bit __at (0x1C) FLAG_1CH;
__bit __at (0x1D) FLAG_1DH;
__bit __at (0x1E) FLAG_1EH;
__bit __at (0x1F) FLAG_1FH;
__bit __at (0x20) FLAG_20H;   
__bit __at (0x21) FLAG_21H;
__bit __at (0x22) FLAG_22H;
__bit __at (0x23) FLAG_23H;
__bit __at (0x25) FLAG_25H; // Aggiunto per errore 187
__bit __at (0x24) FLAG_PARITY_RCV;

// --- VARIABILI IN RAM ---
__data __at (0x26) unsigned char MODE_SEL;
__data __at (0x27) unsigned char LAST_SCAN;
__data __at (0x28) unsigned char RATE_VAL;
__data __at (0x29) unsigned char DELAY_VAL;
__data __at (0x2A) unsigned char SCAN_SET;
__data __at (0x2B) unsigned char VAR_2B;
__data __at (0x2C) unsigned char TX_BYTE;
__data __at (0x2D) unsigned char LAST_BYTE;
__data __at (0x2E) unsigned char PTR_W; 
__data __at (0x2F) unsigned char PTR_R; 
__data __at (0x30) unsigned char SCAN_PTR;
__data __at (0x31) unsigned char VAR_31;
__data __at (0x32) unsigned char KEY_COUNT;
__data __at (0x33) unsigned char VAR_33;
__data __at (0x72) unsigned char STATUS_L;
__data __at (0x73) unsigned char STATUS_H;

unsigned char reg_r0, reg_r1, reg_r2, reg_r3, reg_r4, reg_r5, reg_r6, reg_r7;

// --- TABELLE DATI ---
__code unsigned char data0EAE[] = { /* ... dati già inseriti ... */ 0x00 }; 

// --- PROTOTIPI (Corretti con void) ---
void delay500ms(unsigned char r0, unsigned char r1);
void label4(void);
void label9(void);
void label23(void); 
unsigned char label13(unsigned char val);
void main(void);

// --- FUNZIONI ---

void label4(void) {
    __asm
        mov r1, #0
        mov dptr, #_label4
    l428:
        mov a, dpl
        jnz l425
        mov a, dph
        jnz l425
        mov a, r1
        cjne a, #0x1F, l426
        mov _reg_r1, #0xAA
        ret
    l426:
        mov _reg_r1, #0xFC
        ret
    l425:
        dec dpl
        mov a, dpl
        cjne a, #0xFF, l427
        dec dph
    l427:
        clr a
        movc a, @a+dptr
        xrl a, r1
        mov r1, a
        sjmp l428
    __endasm;
}

void label9(void) {
    unsigned char i;
    for(i = 0x56; i < 0x72; i++) {
        *((__data unsigned char *)i) = 0xFF;
    }
    FLAG_25H = 0;
    RATE_VAL = 0x01;
    DELAY_VAL = 0xF4;
    SCAN_SET = 0x00;
    VAR_2B = 0x5C;
}

void label23(void) {
    unsigned char offset;
    offset = P2 & 0x07;
    ACC = reg_r7 - 0x34;
    __asm
        swap a
        rr a
    __endasm;
    offset += ACC;
    reg_r2 = data0EAE[offset];
}

void delay500ms(unsigned char r0, unsigned char r1) {
    while(r0--) {
        unsigned char t = r1;
        while(t--) {
            __asm nop __endasm;
        }
    }
}

void main(void) {
    EA = 1;
    SP = 0x0F;
    P1 = 0xF7;
    TL0 = 0x00;
    TH0 = 0xF1;
    
    delay500ms(0xC8, 0xFA);
    label4(); 
    
    // Test RAM
    for (reg_r0 = 0x7F; reg_r0 > 0x01; reg_r0--) {
        *((__data unsigned char *)reg_r0) = 0xFF;
        if (*((__data unsigned char *)reg_r0) != 0xFF) goto ram_fail;
        *((__data unsigned char *)reg_r0) = 0x00;
        if (*((__data unsigned char *)reg_r0) != 0x00) goto ram_fail;
    }
    goto ram_ok;

ram_fail:
    for (reg_r0 = 0x7F; reg_r0 > 0; reg_r0--) {
        *((__data unsigned char *)reg_r0) = 0x00;
    }
    reg_r1 = 0xFC;

ram_ok:
    FLAG_21H = 1;

    while(1) {
        TX_BYTE = reg_r1;
        MODE_SEL = 0x02;
        label9();
        PTR_W = 0x43;
        PTR_R = 0x43;
        P1 &= 0xF8;
        if (!FLAG_21H) { TR0 = 1; ET0 = 1; EX0 = 1; }
    }
}
