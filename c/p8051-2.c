#include <8051.h>

/* --- DEFINIZIONE BIT E REGISTRI SPECIALI --- */
__sbit __at (0x90) LED_NUM;
__sbit __at (0x91) LED_CAPS;
__sbit __at (0x92) LED_SCRL;
__sbit __at (0x93) BIT_93H;
__sbit __at (0x95) BIT_95H;
__sbit __at (0x96) PS2_DATA;
__sbit __at (0x97) PS2_CLK;

/* --- AREA BIT-ADDRESSABLE (0x20-0x2F) --- */
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
__bit __at (0x25) FLAG_25H;

/* --- VARIABILI RAM --- */
__data __at (0x26) unsigned char MODE_SEL;
__data __at (0x27) unsigned char LAST_SCAN;
__data __at (0x28) unsigned char RATE_VAL;
__data __at (0x29) unsigned char DELAY_VAL;
__data __at (0x2A) unsigned char SCAN_SET;
__data __at (0x2B) unsigned char VAR_2B;
__data __at (0x2C) unsigned char VAR_2C; // Alias per TX_BYTE
__data __at (0x2D) unsigned char LAST_BYTE;
__data __at (0x2E) unsigned char PTR_W;
__data __at (0x2F) unsigned char PTR_R;
__data __at (0x30) unsigned char SCAN_PTR;
__data __at (0x31) unsigned char VAR_31;
__data __at (0x32) unsigned char KEY_COUNT;
__data __at (0x33) unsigned char VAR_33;

unsigned char reg_r0, reg_r1, reg_r2, reg_r7;

/* --- TABELLE DATI (FORZATE IN MEMORIA) --- */

__code unsigned char data0EAE[] = {
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x14, 0x0C, 0x17, 0x0E, 0x0F,
    0xFF, 0xFF, 0x12, 0x13, 0xFF, 0xFF, 0xFF, 0xFF, 0x18, 0x19, 0x1A,
    0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F,
    '0','1','2','3','4','5','6','7','8','9',':',';','<','=','>','?','@','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','[','\\',']','^','_','`','a','b','c','d','e','f','g',
    0x11, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, 0x10, 0xFF, 0xFF, 0xFF, 0xFF, 0x0D, 0xFF, 0xFF
};

__code unsigned char data0CBF[] = {
    0x4B, 0x50, 0x4D, 0x48, 0x53, 0x4F, 0x51, 0x52, 0x47, 0x49, 0x37, 0x00, 0x38, 0x1D, 0x1C, 0x35,
    0x1D, 0x38, 0x2A, 0x36, 0x3A, 0x00, 0x00, 0x45, 0x1A, 0x1B, 0x2B, 0x47, 0x48, 0x49, 0x37, 0x4A,
    0x26, 0x27, 0x28, 0x1C, 0x4B, 0x4C, 0x4D, 0x4E, 0x1E, 0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25
};

__code unsigned char data0F26[] = { 0x00, 0xFA, 0x01, 0xF4, 0x02, 0xEE, 0x03, 0xE8 };

__code unsigned char data0F2E[] = {
    0x00, 0x21, 0x00, 0x25, 0x00, 0x29, 0x00, 0x2E, 0x00, 0x32, 0x00, 0x36, 0x00, 0x3A, 0x00, 0x3F,
    0x00, 0x43, 0x00, 0x4B, 0x00, 0x53, 0x00, 0x5C, 0x00, 0x64, 0x00, 0x6D, 0x00, 0x74, 0x00, 0x7D,
    0x00, 0x85, 0x00, 0x95, 0x00, 0xA7, 0x00, 0xB6, 0x00, 0xC8, 0x00, 0xDC, 0x00, 0xE9, 0x00, 0xFA,
    0x01, 0x0E, 0x01, 0x2F, 0x01, 0x4D, 0x01, 0x72, 0x01, 0x90, 0x01, 0xB3, 0x01, 0xDC, 0x01, 0xF4
};

/* --- PROTOTIPI --- */
void delay500ms(unsigned char r0, unsigned char r1);
void label4(void);
void label9(void);
void label23(void);
void main(void);

/* --- FUNZIONI --- */

void label4(void) {
    // Forziamo il riferimento a se stessa per il checksum
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
    // Riferimento fittizio alle tabelle per forzare l'inclusione nel binario
    i = data0F26[0] + data0F2E[0] + data0CBF[0]; 
    
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
    // Uso esplicito della tabella data0EAE
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
    
    // Inizializzazione RAM
    for (reg_r0 = 0x7F; reg_r0 > 0x01; reg_r0--) {
        *((__data unsigned char *)reg_r0) = 0xFF;
    }

    FLAG_21H = 1;

    while(1) {
        VAR_2C = reg_r1;
        MODE_SEL = 0x02;
        label9();
        label23(); // Forza l'uso di data0EAE
        PTR_W = 0x43;
        PTR_R = 0x43;
        P1 &= 0xF8;
        if (!FLAG_21H) { TR0 = 1; ET0 = 1; EX0 = 1; }
    }
}
