;*******************************************************************************
;   MSP430F21x2 Demo - ADC10, DTC Sample A0 2-Blk Cont. Mode, AVcc, HF XTAL
;
;   Description: For non-low power applications HF XTAL can source ACLK and be
;   used also for CPU MCLK, as in this example. DTC always uses MCLK for data
;   transfer. Though not required, ADC10 can also clock from HF XTAL as in this
;   example using MCLK.
;   MCLK = ACLK = ADC10CLK = HF XTAL in this example.
;   DTC used to sample A0 with reference to AVcc. Software writes once to
;   ADC10SC to trigger continous sampling. DTC configured to transfer code
;   into two 16-word blocks at RAM 200h - 240h. Mainloop jumps to itself.
;   MCLK times sample period (8x) and conversion (13x). For demostration
;   puspose, ADC10_ISR(DTC) used to set P1.1 at completion of first block
;   transfer, reset at completion of second block transfer. Toggle rate on P1.1
;   is then calculated as MCLK/(21*16*2)
;   //* HF XTAL NOT INSTALLED ON FET *//
;   //* Min Vcc required varies with MCLK frequency - refer to datasheet *//
;
;                MSP430F21x2
;             -----------------
;         /|\|              XIN|-
;          | |                 | HF XTAL (3  16MHz crystal or resonator)
;          --|RST          XOUT|-
;            |                 |
;        >---|P2.0/A0      P1.1|-->MCLK/672
;
;  JL Bile
;  Texas Instruments Inc.
;  May 2008
;  Built with Code Composer Essentials: v3 FET
;*******************************************************************************
 .cdecls C,LIST, "msp430x21x2.h"
;-------------------------------------------------------------------------------
 			.text							;Program Start
;-------------------------------------------------------------------------------
RESET       mov.w   #025Fh,SP   		    ; Initialize stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
SetupBC     bis.b   #XTS,&BCSCTL1           ; LFXT1 = HF XTAL
            bis.b   #LFXT1S1,&BCSCTL3       ; 3  16MHz crystal or resonator
SetupOsc    bic.b   #OFIFG,&IFG1            ; Clear OSC fault flag
            mov.w   #0FFh,R15               ; R15 = Delay
SetupOsc1   dec.w   R15                     ; Additional delay to ensure start
            jnz     SetupOsc1               ;
            bit.b   #OFIFG,&IFG1            ; OSC fault flag set?
            jnz     SetupOsc                ; OSC Fault, clear flag again
            bis.b   #SELM_3,&BCSCTL2        ; MCLK = LFXT1
SetupADC10  mov.w   #ADC10SSEL_2+CONSEQ_2,&ADC10CTL1 ;
            mov.w   #ADC10SHT_1+MSC+ADC10ON+ADC10IE,&ADC10CTL0 ;
            bis.b   #01h,&ADC10AE0          ; P2.0 ADC option select
            bis.b   #ADC10TB+ADC10CT,&ADC10DTC0  ; Continous two block transfers
            mov.b   #010h,&ADC10DTC1        ; 16*2 conversions
SetupP1     bis.b   #002h,&P1DIR            ; P1.1 output
            mov.w   #0200h,&ADC10SA         ; Data buffer start
            bis.w   #ENC+ADC10SC,&ADC10CTL0 ; Start sampling continously
            eint                            ; Enable interrupts
                                            ;
Mainloop    jmp     Mainloop                ; Do nothing (and keep MCLK alive)
                                            ;
;-------------------------------------------------------------------------------
ADC10_ISR;
;-------------------------------------------------------------------------------
            bit.b   #ADC10B1,&ADC10DTC0     ; Jump -> Block 2 complete
            jnc     ADC10_2                 ;
            bis.b   #002h,&P1OUT            ; P1.1 = 1
            reti                            ;
ADC10_2     bic.b   #002h,&P1OUT            ; P1.1 = 0
            reti                            ;
                                            ;
;-------------------------------------------------------------------------------
;			Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".int05"            	; ADC10 Vector
            .short  ADC10_ISR
            .sect   ".reset"	            ; POR, ext. Reset
            .short  RESET
            .end
 