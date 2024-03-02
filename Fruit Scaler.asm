;
; d@t@_err0r.asm
;
; Created: 18/05/2023 7:07:39 PM
; Author : B?N N?O GI?U TÊN
;

.EQU ADC_PORT = PORTA
.EQU ADC_DR = DDRA
.EQU ADC_PIN = PINA
.EQU LCD=PORTB
.EQU LCD_DR=DDRB
.EQU RS = 0
.EQU RW = 1
.EQU E = 2
.EQU KILO = $300
.EQU GIA = $500
.ORG 0
RJMP BEGIN
.ORG $02
RJMP INT0_ISR
.ORG $04
RJMP INT1_ISR
.ORG $100
BEGIN:

LDI R16,HIGH(RAMEND)
OUT SPH,R16
LDI R16,LOW(RAMEND)
OUT SPL,R16

CBI DDRA,0
SBI PORTA,0
CBI DDRD,2
SBI PORTD,2 ;INT0
CBI DDRD,3
SBI PORTD,3 ;INT1
/*LDI R16,$FF
OUT DDRC,R16*/
CALL UART_INIT
CALL START_PORT
CALL LCD_INIT
CALL CLR_OLD_COST
LDI R16,(1<<REFS0)
STS ADMUX,R16 ;NGUON AVCC
;NGO VAO ADC0
LDI R16,(1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)
STS ADCSRA,R16 ;FOSC/64 CHO PHEP ADC MODE TU KICH

CLR R16
STS $600,R16
STS $601,R16


MAIN: 
		LDI R16,1
		RCALL DELAY
		CBI LCD,0
		LDI R17,$01
		RCALL OUT_LCD
		LDI R16,20
		RCALL DELAY; XOA MAN HINH

		CBI LCD,RS
		LDI R17,$82
		RCALL OUT_LCD;CON TRO VE DONG 1 HANG 1

		LDI ZH,HIGH(TEXT<<1)
		LDI ZL,LOW(TEXT<<1)
DONG1:
		LPM R17,Z+
		CPI R17,$0D
		BREQ DOWN
		LDI R16,1
		RCALL DELAY
		SBI LCD,0
		RCALL OUT_LCD
		RJMP DONG1
DOWN:
		LDI R16,1
		RCALL DELAY
		CBI LCD,0
		LDI R17,$C2 ; HANG 2 DONG 2
		RCALL OUT_LCD

		LDI ZH,HIGH(TEXT1<<1)
		LDI ZL,LOW(TEXT1<<1)

DONG2:
		LPM R17,Z+
		CPI R17,$0D
		BREQ BYE
		LDI R16,1
		RCALL DELAY
		SBI LCD,0
		RCALL OUT_LCD
		RJMP DONG2
BYE:

LDI R16,(1<<ISC01)|(1<<ISC11);NGAT CANH XUONG
STS EICRA,R16
SEI 
SBI EIMSK,INT0
SBI EIMSK,INT1

TRASH: 

;DOC DIEN AP NGO VAO
LDI R16, (1<<REFS0)
STS ADMUX, R16
LDS R18, ADCSRA
ORI R18, (1<<ADSC)
STS ADCSRA, R18

WAIT0:		
LDS R18,ADCSRA
ANDI R18, (1<<ADSC)
CPI R18, (1<<ADSC)
BREQ WAIT0
LDS R22, ADCL 
LDS R23, ADCH 

LDI R16,LOW($65)
LDI R17,HIGH($65)
CLC
SUB R22,R16
SBC R23,R17

STS $200,R22 ;BYTE THAP
STS $201,R23 ;BYTE CAO

CALL CHECK_DUP
BRCS TRASH

;<SO SANH & NHAN CHIA 16BIT TIM SO KG + GIA TIEN>
;SO SANH
;2KG = $B6
;4KG = $16C
;6KG = $222
;10KG = $38E
RCALL SOSANH
LPM R25,Z+; HOLD THE PRICES


;<CALCULATE THE KILO OF THE WEIGHT>
; R23:R22 => WEIGHT IN 10 BITS
; WEIGHT = (R23:R22)*5/1024 *227/100
RCALL WEIGHT

;PRICE = WEIGHT*R25/10
RCALL PRICE

;<OUT LCD> 
RCALL LINE1

;<LINE2: OUT THE PRICE AND THE WEIGHT>
RCALL LINE2

RJMP TRASH

INT0_ISR:
/*CALL CLR_SRAM
;DOC DIEN AP NGO VAO
LDI R16, (1<<REFS0)
STS ADMUX, R16
LDS R18, ADCSRA
ORI R18, (1<<ADSC)
STS ADCSRA, R18

WAIT0:		
LDS R18,ADCSRA
ANDI R18, (1<<ADSC)
CPI R18, (1<<ADSC)
BREQ WAIT0
LDS R22, ADCL 
LDS R23, ADCH 
LDI R16,LOW($65)
LDI R17,HIGH($65)
CLC
SUB R22,R16
SBC R23,R17
STS $200,R22 ;BYTE THAP
STS $201,R23 ;BYTE CAO
;<SO SANH & NHAN CHIA 16BIT TIM SO KG + GIA TIEN>
;SO SANH
;2KG = $B6
;4KG = $16C
;6KG = $222
;10KG = $38E
RCALL SOSANH
LPM R25,Z+; HOLD THE PRICES


;<CALCULATE THE KILO OF THE WEIGHT>
; R23:R22 => WEIGHT IN 10 BITS
; WEIGHT = (R23:R22)*5/1024 *227/100
RCALL WEIGHT

;PRICE = WEIGHT*R25/10
RCALL PRICE

;<OUT LCD> 
RCALL LINE1

;<LINE2: OUT THE PRICE AND THE WEIGHT>
RCALL LINE2*/

RETI
;------------------------------------
CHECK_DUP:
LDS R17,$601
LDS R16,$600
CP R23,R17
BREQ TIEPTUC
RJMP NOTEQUAL
TIEPTUC:
CP R22,R16
BRNE NOTEQUAL
SEC
RJMP STOP
NOTEQUAL:
STS $601,R23
STS $600,R22
CLC
STOP: RET
;------------------------------------
INT1_ISR:
PUSH R16
PUSH R17
PUSH R19
PUSH ZH
PUSH ZL
PUSH XH
PUSH XL

LDI R19,11
LDI ZH,HIGH(TEXT3<<1)
LDI ZL,LOW(TEXT3<<1)

LAP1:
LPM R16,Z+
CALL UART_TRAN
DEC R19
CPI R19,0
BRNE LAP1

LDI XH,HIGH($500)
LDI XL,LOW($500)

LDI R19,5
LAP2:
LD R16,X+
CPI R16,0
BRNE TIEP1
CPI R19,4
BRNE NOTDOT
LDI R16,$2E
RJMP TIEP1
NOTDOT:
LDI R16,$30
TIEP1:
CALL UART_TRAN
DEC R19
CPI R19,0
BRNE LAP2

LDI R16,'$'
CALL UART_TRAN

POP XL
POP XH
POP ZL
POP ZH
POP R19
POP R17
POP R16
RETI
TEXT3: .DB "GIA TIEN: "
;------------------------------------
LCD_INIT:
		;RESET VCC LCD:
		LDI R16,250
		RCALL DELAY
		LDI R16,250
		CBI LCD,0
		LDI R17,$30
		RCALL OUT_LCD
		LDI R16,42
		RCALL DELAY

		CBI LCD,0
		LDI R17,$30
		RCALL OUT_LCD
		LDI R16,2
		RCALL DELAY

		CBI LCD,0
		LDI R17,$32
		RCALL OUT_LCD
		
		LDI R17,$28
		RCALL INIT_LCD4
		LDI R17,$01
		RCALL INIT_LCD4
		LDI R17,$0C
		RCALL INIT_LCD4
		LDI R17,$06
		RCALL INIT_LCD4
		RET
;-----------------------------
START_PORT:
		;KHOI DONG PORT LCD
		LDI R16,$FF
		OUT LCD_DR,R16
		CBI LCD,0
		CBI LCD,1
		CBI LCD,2
		RET
;------------------------------
INIT_LCD4:
		LDI R16,1
		RCALL DELAY
		CBI LCD,0
		RCALL OUT_LCD
		CPI R17,$01
		BREQ MORE
		LDI R16,1
		RCALL DELAY
MORE:	LDI R16,20
		RCALL DELAY
		RET
;-----------------------------------
;BRING DATA IN R17 -> LCD
OUT_LCD:
		LDI R16,1
		RCALL DELAY
		IN R16,LCD
		ANDI R16,(1<<RS)
		PUSH R16
		PUSH R17
		ANDI R17,$F0
		OR R17,R16
		RCALL OUT_LCD4
		LDI R16,1
		RCALL DELAY
		POP R17
		POP R16
		SWAP R17
		ANDI R17,$F0
		OR R17,R16
		RCALL OUT_LCD4
		RET
OUT_LCD4:
		OUT LCD,R17
		SBI LCD,2
		CBI LCD,2
		RET
;-------------------------------------
;TDELAY = R16*100US
DELAY:
		MOV R15,R16
		LDI R16,200
L1:		MOV R14,R16
L2:		DEC R14
		NOP
		BRNE L2
		DEC R15
		BRNE L1
		RET

;-----------------------------------------------
UART_INIT: 
LDI R16,(1<<TXEN0)
STS UCSR0B,R16
LDI R16,(1<<UCSZ01)|(1<<UCSZ00)
STS UCSR0C,R16 ;1 STOP BIT AND 8BIT DATA
CLR R16 ;NO PARITY
STS UBRR0H,R16
LDI R16,51 ;BAURATE = 9600
STS UBRR0L,R16
RET
;----------------------------------------------
UART_TRAN:
		LDS R17,UCSR0A
		SBRS R17,UDRE0
		RJMP UART_TRAN
		STS UDR0,R16
		RET
;----------------------------------------------
SOSANH: ;COMPARE R23:R22 WITH R17:R16
TEN:
LDI R17,HIGH(910)
LDI R16,LOW(910)
CP R23,R17
BRLO SIX
CP R22,R16
BRLO SIX
LDI ZH,HIGH(TENKILO<<1)
LDI ZL,LOW(TENKILO<<1)
RET

SIX:
LDI R17,HIGH(546)
LDI R16,LOW(546)
CP R23,R17
BRLO FOUR
CP R23,R17
BREQ CHECKTIEP1
RJMP CONTI5
CHECKTIEP1:
CP R22,R16
BRLO FOUR
CONTI5:
LDI ZH,HIGH(TENKILO<<1)
LDI ZL,LOW(TENKILO<<1)
RET

FOUR:
LDI R17,HIGH(364)
LDI R16,LOW(364)
CP R23,R17
BRLO TWO
CP R23,R17
BREQ CHECKTIEP
RJMP CONTI4
CHECKTIEP:
CP R22,R16
BRLO TWO
CONTI4:
LDI ZH,HIGH(FOURKILO<<1)
LDI ZL,LOW(FOURKILO<<1)
RET

TWO:
LDI R17,HIGH(182)
LDI R16,LOW(182)
CP R23,R17 
BRSH HAI
AGAIN1:
CP R22,R16
BRLO BELOW2
RJMP CONTI
HAI:
CP R23,R17 
BREQ AGAIN1
CONTI:
LDI ZH,HIGH(TWOKILO<<1)
LDI ZL,LOW(TWOKILO<<1)
RET

BELOW2:
LDI ZH,HIGH(BELOWTWO<<1)
LDI ZL,LOW(BELOWTWO<<1)
RET

;XUAT DONG 1

LINE1:

		LDI R16,1
		RCALL DELAY
		CBI LCD,0
		LDI R17,$01
		RCALL OUT_LCD
		LDI R16,20
		RCALL DELAY; XOA MAN HINH

		CBI LCD,RS
		LDI R17,$80
		RCALL OUT_LCD;CON TRO VE DONG 1 HANG 1

DONG11:
		LPM R17,Z+
		CPI R17,$0D
		BREQ DOWN1
		LDI R16,1
		RCALL DELAY
		SBI LCD,0
		RCALL OUT_LCD
		RJMP DONG11
DOWN1:	RET
;---------------------------------------
.DEF ZERO = R2               ;To hold Zero
.DEF   AL = R16              ;To hold multiplicand
.DEF   AH = R17
.DEF   BL = R18              ;To hold multiplier
.DEF   BH = R19
.DEF ANS1 = R20              ;To hold 32 bit answer
.DEF ANS2 = R21
.DEF ANS3 = R22
.DEF ANS4 = R23

     
MUL16x16:
        CLR ZERO             ;Set R2 to zero
        MUL AH,BH            ;Multiply high bytes AHxBH
        MOVW ANS4:ANS3,R1:R0 ;Move two-byte result into answer

        MUL AL,BL            ;Multiply low bytes ALxBL
        MOVW ANS2:ANS1,R1:R0 ;Move two-byte result into answer

        MUL AH,BL            ;Multiply AHxBL
        ADD ANS2,R0          ;Add result to answer
        ADC ANS3,R1          ;
        ADC ANS4,ZERO        ;Add the Carry Bit

        MUL BH,AL            ;Multiply BHxAL
        ADD ANS2,R0          ;Add result to answer
        ADC ANS3,R1          ;
        ADC ANS4,ZERO        ;Add the Carry Bit
RET
;---------------------------------------

.DEF ANSL = R0            ;To hold low-byte of answer
.DEF ANSH = R1            ;To hold high-byte of answer     
.DEF REML = R2            ;To hold low-byte of remainder
.DEF REMH = R3            ;To hold high-byte of remainder
.DEF   AL = R16           ;To hold low-byte of dividend
.DEF   AH = R17           ;To hold high-byte of dividend
.DEF   BL = R18           ;To hold low-byte of divisor
.DEF   BH = R19           ;To hold high-byte of divisor   
.DEF    C = R20           ;Bit Counter

      
DIV1616:
        MOVW ANSH:ANSL,AH:AL ;Copy dividend into answer
        LDI C,17          ;Load bit counter
        SUB REML,REML     ;Clear Remainder and Carry
        CLR REMH          ;
LOOP:   ROL ANSL          ;Shift the answer to the left
        ROL ANSH          ;
        DEC C             ;Decrement Counter
         BREQ DONE        ;Exit if sixteen bits done
        ROL REML          ;Shift remainder to the left
        ROL REMH          ;
        SUB REML,BL       ;Try to subtract divisor from remainder
        SBC REMH,BH
         BRCC SKIP1        ;If the result was negative then
        ADD REML,BL       ;reverse the subtraction to try again
        ADC REMH,BH       ;
        CLC               ;Clear Carry Flag so zero shifted into A 
         RJMP LOOP        ;Loop Back
SKIP1:   SEC               ;Set Carry Flag to be shifted into A
         RJMP LOOP
DONE:RET
;-------------------------
WEIGHT:
LDI XH, HIGH(KILO)
LDI XL, LOW(KILO)

LDS AH,$201
LDS AL,$200
LDI BL,LOW(90)       ;Load multiplier into BH:BL
LDI BH,HIGH(90)      ;
RCALL DIV1616

;Xuat so xx._
LDI R18,$30
MOV	R16,R0
CPI R16,10
BRSH TACH
MOV R8,R16 ;LOW_BYTE_RES_HIGH
ADD R16,R18
ST X+, R16
CLR R9 ;HIGH_BYTE_RES_HIGH
RJMP CONTI2
TACH:
INC R18
ST X+,R18
DEC R18
ST X+,R18
CLR R8 ;LOW_BYTE_RES_HIGH
CLR R9
INC R9 ;HIGH_BYTE_RES_HIGH
CONTI2:
LDI	R17,46	;dau "."
ST X+, R17

;V= xx.x----------------------
;So du*10
	MOV AL,R2
	MOV AH,R3
	LDI BL,LOW(10)       ;Load multiplier into BH:BL
    LDI BH,HIGH(10)      ;
	RCALL MUL16x16		;Ket qua: R21,R20

	
	;Ketqua: R0:gia tri dung, xuat ra LCD. R2,R3 so du.
	MOV AL,R20
	MOV AH,R21
	LDI BL,LOW(90)       ;Load multiplier into BH:BL
    LDI BH,HIGH(90)      ;
	RCALL DIV1616

	;Xuat so _.x
	MOV		R16,R0
	MOV		R7,R16 ;HIGH_BYTE_RES_LOW
	LDI		R17,0x30
	ADD		R17,R16
	ST		X+, R17

;V=x.xx-----------------
;So du*10
	MOV AL,R2
	MOV AH,R3
	LDI BL,LOW(10)       ;Load multiplier into BH:BL
    LDI BH,HIGH(10)      ;
	RCALL MUL16x16		;Ket qua: R21,R20

	;So du*10/1024
	;Ketqua: R0:gia tri dung, xuat ra LCD. R2,R3 so du.
	MOV AL,R20
	MOV AH,R21
	LDI BL,LOW(90)       ;Load multiplier into BH:BL
    LDI BH,HIGH(90)      ;
	RCALL DIV1616

	;Xuat so _._x
	MOV		R16,R0
	MOV		R6,R16 ;LOW_BYTE_RES_LOW
	LDI		R17,0x30
	ADD		R17,R16
	ST X+, R17

;V=x.xxx------------------
;So du*10
	MOV AL,R2
	MOV AH,R3
	LDI BL,LOW(10)       ;Load multiplier into BH:BL
    LDI BH,HIGH(10)      ;
	RCALL MUL16x16		;Ket qua: R21,R20

	;So du*10/1024
	;Ketqua: R0:gia tri dung, xuat ra LCD. R2,R3 so du.
	MOV AL,R20
	MOV AH,R21
	LDI BL,LOW(90)       ;Load multiplier into BH:BL
    LDI BH,HIGH(90)      ;
	RCALL DIV1616

	;Xuat gia tri _.__x
	MOV		R16,R0
	LDI		R17,0x30
	ADD		R17,R16
	ST X+, R17
	RET
;---------------------------------------
PRICE:
;R9:R8.R7

;RESULT: R17:R16
CLR R17
CLR R16

SBRC R9,0
CALL ADD100
TO10:
LDI R18,0
CP R8,R18
BREQ TO1
CALL ADD10
DEC R8
RJMP TO10

TO1:
LDI R18,0
CP R7,R18
BREQ END1
CLC
LDI R19,1
ADD R16,R19
ADC R17,R18
DEC R7
RJMP TO1


END1: 
STS $400,R16
STS $401,R17

;DI TIM GIA TIEN = (R17:R16)*R25/1000
;(R17:R16)*R25
	LDI XH,HIGH($500)
	LDI XL,LOW($500)

	
	MOV BL,R25     ;Load multiplier into BH:BL
    LDI BH,0     ;
	RCALL MUL16x16		;Ket qua: R21,R20
;----------------
;ANS/10
	MOV AL,R20
	MOV AH,R21
	LDI BL,LOW(100)       ;Load multiplier into BH:BL
    LDI BH,HIGH(100)      ;
	RCALL DIV1616
	 
	;Xuat so x._
	MOV		R16,R0
	ST X,R16
	CPI R16,100
	BRSH TACHSO100
	CPI R16,10
	BRSH TACHSO10

	LDI		R17,0x30
	ADD		R17,R16
	ST X+, R17
	RJMP CONTI3	

	TACHSO100:
	LDI R20,$30
	CLR R19
	CLR R18
	INC R19
	ADD R19,R20
	ST X+,R19 ;SO HANG TRAM
	SUBI R16,100
	
	TACHSO10:
	CLR R18
LOOP3:
	INC R18 ;SO HANG CHUC
	SUBI R16,10
	BRSH LOOP3
	DEC R18
	LDI R17,10
	ADD R16,R17
	LDI R20,$30
	ADD R18,R20
	ST X+,R18 ;SO HANG CHUC
	ADD R16,R20
	ST X+,R16 ;SO HANG DON VI


CONTI3:
	LDI		R17,46	;dau "."
	ST X+, R17
;V=x.x-------------------------
;So du*10
	MOV AL,R2
	MOV AH,R3
	LDI BL,LOW(10)       ;Load multiplier into BH:BL
    LDI BH,HIGH(10)      ;
	RCALL MUL16x16		;Ket qua: R21,R20

	;So du*10/1024
	;Ketqua: R0:gia tri dung, xuat ra LCD. R2,R3 so du.
	MOV AL,R20
	MOV AH,R21
	LDI BL,LOW(100)       ;Load multiplier into BH:BL
    LDI BH,HIGH(100)      ;
	RCALL DIV1616

	;Xuat so _.x
	MOV		R16,R0
	LDI		R17,0x30
	ADD		R17,R16
	ST X+, R17

;V=x.xx------------------------------
;So du*10
	MOV AL,R2
	MOV AH,R3
	LDI BL,LOW(10)       ;Load multiplier into BH:BL
    LDI BH,HIGH(10)      ;
	RCALL MUL16x16		;Ket qua: R21,R20

	;So du*10/100
	;Ketqua: R0:gia tri dung, xuat ra LCD. R2,R3 so du.
	MOV AL,R20
	MOV AH,R21
	LDI BL,LOW(100)       ;Load multiplier into BH:BL
    LDI BH,HIGH(100)      ;
	RCALL DIV1616

	;Xuat so _._x
	MOV		R16,R0
	LDI		R17,0x30
	ADD		R17,R16
	ST X+, R17
	RET

;---------------------------------------
ADD100:
LDI R17,HIGH(100)
LDI R16,LOW(100)
RET
;---------------------------------------
ADD10:
LDI R19,10
CLR R20
CLC
ADD R16,R19
ADC R17,R20
RET
;---------------------------------------
CLR_SRAM:
LDI R16,0
LDI R17,9
LDI XH,HIGH($300)
LDI XL,LOW($300)
LOOP1:
ST Z+,R16
DEC R17
CPI R17,0
BRNE LOOP1
RET
;---------------------------------------
CLR_OLD_COST:
LDI R16,0
LDI R17,9
LDI XH,HIGH($600)
LDI XL,LOW($600)
LOOP111:
ST Z+,R16
DEC R17
CPI R17,0
BRNE LOOP111
RET
;---------------------------------------
LINE2:
			LDI R16,1
			RCALL DELAY
			CBI LCD,0
			LDI R17,$C0 ; HANG 2 DONG 0
			RCALL OUT_LCD

			


			LDI R16,1
			RCALL DELAY
			LDS R17,$500
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD

			LDI R16,1
			RCALL DELAY
			LDS R17,$501
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD

			LDI R16,1
			RCALL DELAY
			LDS R17,$502
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD

			LDI R16,1
			RCALL DELAY
			LDS R17,$503
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD


			LDI R16,1
			RCALL DELAY
			LDS R17,$504
			CPI R17,0
			BRNE CONTI6
			LDI R17,$30
			CONTI6:
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD

			LDI R16,1
			RCALL DELAY
			LDI R17,'$'
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD
		
			
			

			LDI R16,1
			RCALL DELAY
			LDI R17,' '
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD

			LDI R16,1
			RCALL DELAY
			LDI R17,' '
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD

		
			LDI R16,1
			RCALL DELAY
			LDI R17,' '
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD


			LDI R16,1
			RCALL DELAY
			LDS R17,$300
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD

			LDI R16,1
			RCALL DELAY
			LDS R17,$301
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD

			LDI R16,1
			RCALL DELAY
			LDS R17,$302
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD

			LDI R16,1
			RCALL DELAY
			LDS R17,$303
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD

			LDI R16,1
			RCALL DELAY
			LDS R17,$304
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD

			LDI R16,1
			RCALL DELAY
			LDI R17,'K'
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD

			LDI R16,1
			RCALL DELAY
			LDI R17,'G'
			LDI R16,1
			RCALL DELAY
			SBI LCD,RS
			RCALL OUT_LCD

			RET
;---------------------------------------
TEXT: .DB "CAN TRAI CAY",$0D
TEXT1: .DB "BY: NHAT NEM",$0D
BELOWTWO: .DB 100,"     MIT NON",$0D
TWOKILO: .DB 145,"  MIT GAN CHIN",$0D
FOURKILO: .DB 160,"    MIT NGON",$0D
TENKILO: .DB 125,"     MIT GIA",$0D

