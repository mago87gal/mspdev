;******************************************************************************
;  MSP430F21x2 Demo - Timer0_A3, Toggle P1.1/TA0_0, Up Mode, 32kHz ACLK
;
;  Description: Toggle P1.1 using hardware TA0_0 output. Timer0_A3 is configured
;  for up mode with TA0CCR0 defining period, TA1_0 also output on P1.1. In this
;  example, TA0CCR0 is loaded with 10-1 and TA0_0 will toggle P1.1 at TA0CLK/10.
;  Thus the output frequency on P1.1 will be the TA0CLK/20. No CPU or software
;  resources required. Normal operating mode is LPM3.
;  ACLK = TA0CLK = 32kHz, MCLK = default DCO ~1.2MHz
;  ;* External watch crystal installed on XIN XOUT is required for ACLK *;
;  As coded with TA0CLK = ACLK, P1.1 output frequency = 32768/20 = 1.6384kHz
;
;           MSP430F21x2
;         -----------------
;     /|\|              XIN|-
;      | |                 | 32kHz
;      --|RST          XOUT|-
;        |                 |
;        |       P1.1/TA0_0|--> ACLK/20
;
;  JL Bile
;  Texas Instruments Inc.
;  May 2008
;  Built with Code Composer Essentials: v3 FET
;*******************************************************************************
 .cdecls C,LIST, "msp430x21x2.h"
;-------------------------------------------------------------------------------
 			.text							; Program Start
;-------------------------------------------------------------------------------
RESET       mov.w   #025Fh,SP         		; Initialize stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
SetupP1     bis.b   #002h,&P1DIR            ; P1.1 output
            bis.b   #002h,&P1SEL            ; P1.1 option slect
SetupC0     mov.w   #OUTMOD_4,&TA0CCTL0      ; TACCR0 toggle mode
            mov.w   #10-1,&TA0CCR0           ;
SetupTA     mov.w   #TASSEL_1+MC_1,&TA0CTL   ; ACLK, upmode
                                            ;
Mainloop    bis.w   #LPM3,SR                ; Enter LPM3
            nop                             ; Required only for debugger
                                            ;
;-------------------------------------------------------------------------------
;			Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect	".reset"				; MSP430 RESET Vector
            .short	RESET                   ;
            .end
