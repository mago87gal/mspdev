;******************************************************************************
;   MSP-FET430P430 Demo - DMA0, ADC12 A10 Block Xfer to RAM, Timer_B, SMCLK
;
;   Description: A 0x20 word block of data is sampled and recorded into RAM
;   from ADC12 channel 10, the integrated temperature sensor, using the
;   Record function. Timer_B CCR1 begins the ADC12 sample period, CCR0 the
;   hold and conversion start. Timer_B operates in the up mode with CCR0
;   defining the sample period. DMA0 will automatically transfer each ADC12
;   conversion code to memory when complete. At the end of the recording
;   block, DMA0 will issue an interrupt exiting the function.
;   In the example the RAM block use to record the ADC12 data begins at 0x220.
;   P5.1 is toggled during DMA transfer only for demonstration purposes.
;   ACLK = LFXT1 = 32768Hz, MCLK = SMCLK = default DCO = 32 x ACLK = 1048576Hz
;   ;* An external watch crystal between XIN & XOUT is required for ACLK *//	
;
;               MSP430FG439
;            -----------------
;        /|\|              XIN|-
;         | |                 |
;         --|RST          XOUT|-
;           |                 |
;           |A10 (Temp)   P5.1|-->LED
;
;   G. Morton / M. Mitchell
;   Texas Instruments Inc.
;   May 2005
;   Built with Code Composer Essentials Version: 1.0
;******************************************************************************
 .cdecls C,LIST,  "msp430xG43x.h"

;------------------------------------------------------------------------------
            .text                  ; Progam Start
;------------------------------------------------------------------------------
RESET       mov.w   #0A00h,SP               ; Initialize stack pointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop watchdog timer
SetupFLL    bis.b   #XCAP14PF,&FLL_CTL0     ; Configure load caps
                                            ;
SetupP5     bis.b   #02h,&P5DIR             ; Set P5.1 as output
                                            ;
Mainloop    call    #Record                 ; DMA temp to RAM
            nop                             ; set BREAKPOINT HERE
            jmp     Mainloop                ; Again
                                            ;
;------------------------------------------------------------------------------
Record      ; Record temperature in RAM
;------------------------------------------------------------------------------
SetupADC12  mov.b   #SREF_1+INCH_10,&ADC12MCTL0
                                            ; Vr+=Vref+/Vr-=AVss,
                                            ; select temp sensor as input
            mov.w   #SHS_3+CONSEQ_2,&ADC12CTL1
                                            ; Timer_B.OUT1,
                                            ; repeat-single-chan mode
            mov.w   #REF2_5V+REFON+ADC12ON+ENC,&ADC12CTL0
                                            ; 2.5V ref on, ADC12 on,
                                            ; enable conversions
            call    #VrefDly                ; Allow time for 2.5V ref to settle
            mov.w   #0,&ADC12IFG            ; Clear interrupt flags
                                            ;
SetupDMA0   mov.w   #ADC12MEM0,&DMA0SA      ; DMA source address
            mov.w   #0x220,&DMA0DA          ; DMA destination address
            mov.w   #0x20,&DMA0SZ           ; DMA transfer size
            mov.w   #DMA0TSEL_6,&DMACTL0    ; ADC12IFG bit triggers DMA
            mov.w   #DMADSTINCR_3+DMAIE+DMAEN,&DMA0CTL
                                            ; Increment dest addr,
                                            ; enable interrupt,
                                            ; word transfer (default),
                                            ; enable DMA
                                            ;
SetupTB     mov.w   #100,&TBCCR0            ; Set sample period
            mov.w   #100-30,&TBCCR1         ; Set end of sample & hold
            mov.w   #OUTMOD_7,&TBCCTL1      ; Reset/set mode
                                            ;
BeginRec    bis.b   #02h,&P5OUT             ; Set P5.1=1 (LED on)
            mov.w   #TBSSEL_2+MC_1+TBCLR,&TBCTL
                                            ; SMCLK, up mode, clear count
            bis.w   #LPM0+GIE,SR            ; Enter LPM0, enable interrupts
                                            ;
PwrDown     bic.w   #CONSEQ_2,&ADC12CTL1    ; Stop conversion immediately
            bic.w   #ENC,&ADC12CTL0         ; Disable ADC12 conversion
            mov.w   #0,&ADC12CTL0           ; Switch off ADC12 & ref voltage
            mov.w   #0,&TBCTL               ; Disable Timer_B
            bic.b   #02h,&P5OUT             ; set P5.1=0 (LED off)
            ret                             ; Return from subroutine
                                            ;
;------------------------------------------------------------------------------
VrefDly     ; ADC12 Voltage Reference Delay
;------------------------------------------------------------------------------
            push.w  #0FFFh                  ; Push delay on stack
D1          dec.w   0(SP)                   ; Decrement value on stack
            jnz     D1                      ; Is value = 0?, no jump
            incd.w  SP                      ; Clean up stack
            ret                             ; Return from subroutine
                                            ;
;------------------------------------------------------------------------------
DMA_ISR     ; DMA Interrupt Service Routine
;------------------------------------------------------------------------------
            bic.w   #DMAIFG,&DMA0CTL        ; Must clear DMA interrupt flag
            bic.w   #CPUOFF,0(SP)           ; Exit LPM0
            reti                            ; Return from interrupt
                                            ;
;-----------------------------------------------------------------------------
;           Interrupt Vectors
;-----------------------------------------------------------------------------
            .sect   ".reset"                ; RESET Vector
            .short  RESET                   ;
            .sect   ".int03"                ; DMA Vector
            .short  DMA_ISR                 ;
            .end
