;******************************************************************************
;   MSP-FET430P140 Demo - USART1, UART 115200 Echo ISR, XT2 HF XTAL SMCLK
;
;   Description: This program will echo a received character, RX interrupt
;   service used. XT2 oscillator used in this example.
;   ACLK = MCLK = SMCLK = UCLK1 = XT2 = 8MHz
;   Baud rate divider with 8MHz XTAL @115200 = 8MHz/115200 = 69.44(0045 2Ch)
;   //* An external 8MHz XTAL on X2IN X2OUT is required for ACLK *//	
;
;                MSP430F149
;             -----------------
;         /|\|             X2IN|-
;          | |                 | 8MHz
;          --|RST         X2OUT|-
;            |                 |
;            |             P3.6|------------>
;            |                 | 115200 - 8N1
;            |             P3.7|<------------
;
;   M. Buccini / G. Morton
;   Texas Instruments Inc.
;   May 2005
;   Built with Code Composer Essentials Version: 1.0
;******************************************************************************
 .cdecls C,LIST,  "msp430x14x.h"
;------------------------------------------------------------------------------
            .text                           ; Progam Start
;------------------------------------------------------------------------------
RESET       mov.w   #0A00h,SP               ; Initialize stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
SetupP3     bis.b   #0C0h,&P3SEL            ; P3.6,7 = USART1 option select
SetupBC     bic.b   #XT2OFF,&BCSCTL1        ; XT2on
SetupOsc    bic.b   #OFIFG,&IFG1            ; Clear OSC fault flag
            mov.w   #0FFh,R15               ; R15 = Delay
SetupOsc1   dec.w   R15                     ; Additional delay to ensure start
            jnz     SetupOsc1               ;
            bit.b   #OFIFG,&IFG1            ; OSC fault flag set?
            jnz     SetupOsc                ; OSC Fault, clear flag again
            bis.b   #SELM_2+SELS,BCSCTL2    ; MCLK = SMCLK = XT2
SetupUART1  bis.b   #UTXE1+URXE1,&ME2       ; Enable USART1 TXD/RXD
            bis.b   #CHAR,&UCTL1            ; 8-bit characters
            mov.b   #SSEL1,&UTCTL1          ; UCLK = SMCLK
            mov.b   #045h,&UBR01            ; 8MHz/115200 - 69.44
            mov.b   #000h,&UBR11            ;
            mov.b   #02Ch,&UMCTL1           ; Modulation
            bic.b   #SWRST,&UCTL1           ; **Initialize USART state machine**
            bis.b   #URXIE1,&IE2            ; Enable USART1 RX interrupt
                                            ;
Mainloop    bis.b   #CPUOFF+GIE,SR          ; Enter LPM0, interrupts enabled
            nop                             ; Needed only for debugger
                                            ;
;------------------------------------------------------------------------------
USART1RX_ISR;  Echo back RXed character, confirm TX buffer is ready first
;------------------------------------------------------------------------------
TX2         bit.b   #UTXIFG1,&IFG2          ; USART1 TX buffer ready?
            jz      TX2                     ; Jump is TX buffer not ready
            mov.b   &RXBUF1,&TXBUF1         ; TX -> RXed character
            reti                            ;
                                            ;
;------------------------------------------------------------------------------
;           Interrupt Vectors Used MSP430x13x/14x/15x/16x
;------------------------------------------------------------------------------
            .sect   ".reset"                ;
            .short  RESET                   ; POR, ext. Reset, Watchdog
            .sect   ".int03"                ;
            .short  USART1RX_ISR            ; USART1 Receive
            .end