;******************************************************************************
;   MSP-FET430P140 Demo  - USART0, SPI Interface to HC164 Shift Register
;
;   Description: This program demonstrates USART0 in SPI mode, interface to a
;   'HC164 shift register, transferring a RAM byte Data from 0200h.  Data
;   value incremented in the mainloop, effectively increment HC164 QA - QH.
;   ACLK = n/a, MCLK = SMCLK = default DCO ~ 800k, UCLK0 = SMCLK/2
;   //**SWRST** please see MSP430x1xx Users Guide for description //
;
;                MSP430F149
;             -----------------
;         /|\|              XIN|-
;          | |                 |     ^      HC164
;          --|RST          XOUT|-    |  -------------
;            |                 |     |-|/CLR,B       |  8
;            |       SIMO0/P3.1|------>|A          Qx|--\->
;            |       UCLK0/P3.3|------>|CLK          |
;            |                 |       |             |
;
Data        .equ    0200h
;
;   M. Buccini / G. Morton
;   Texas Instruments Inc.
;   May 2005
;   Built with Code Composer Essentials Version: 1.0
;******************************************************************************
 .cdecls C,LIST,  "msp430x14x.h"
;-----------------------------------------------------------------------------
            .text                           ; Program Start
;-----------------------------------------------------------------------------
RESET       mov.w   #0A00h,SP               ; Initialize stackpointer
            call    #Init_Sys               ; Initialize system
                                            ;
Mainloop    inc.b   &Data                   ; Increment Date value
            call    #TX_HC164               ; Data --> HC164
            call    #Delay                  ; Wait
            jmp     Mainloop                ; Repeat
                                            ;
;-----------------------------------------------------------------------------
TX_HC164;   SPI Data  --> HC164
;-----------------------------------------------------------------------------
TX0         bit.b   #UTXIFG0,&IFG1          ; USART0 TX buffer ready?
            jz      TX0                     ; Jump --> TX buffer not ready
            mov.b   &0200h,&TXBUF0          ; Byte to SPI TXBUF
            ret                             ; Return from subroutine
                                            ;
;-----------------------------------------------------------------------------
Delay;      Software delay
;-----------------------------------------------------------------------------
            push.w  #0FFFFh                 ; Delay to TOS
L1          dec.w   0(SP)                   ; Decrement TOS
            jnz     L1                      ; Delay over?
            incd.w  SP                      ; Clean TOS
            ret                             ;
                                            ;
;-----------------------------------------------------------------------------
Init_Sys;   Subroutine to Initialize MSP430F149 Peripherials
;-----------------------------------------------------------------------------
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop watchdog timer
SetupP3     bis.b   #0Ah,&P3SEL             ; P3.1,3 SPI option select
            bis.b   #0Ah,&P3DIR             ; P3.1,3 output direction
SetupSPI    bis.b   #040h,&ME1              ; Enable USART0 SPI
            bis.b   #CKPH+SSEL1+SSEL0+STC,&UTCTL0 ;* SMCLK, 3-pin mode
            bis.b   #CHAR+SYNC+MM,&UCTL0    ; 8-bit SPI Master **SWRST**
            mov.b   #02h,&UBR00             ; SMCLK/2 for baud rate
            clr.b   &UBR10                  ;
            clr.b   &UMCTL0                 ; Clear modulation
            bic.b   #SWRST,&UCTL0           ; **Initialize USART state machine**
            mov.b   #0FFh,&Data             ; Load inital data
            ret                             ; Return from subroutine
                                            ;
;-----------------------------------------------------------------------------
;           Interrupt Vectors
;-----------------------------------------------------------------------------
             .sect  ".reset"                ; POR, ext. Reset, Watchdog, Flash
             .short RESET                   ;
             .end

