//******************************************************************************
//   MSP430F(G)47x Demo - USCI_A0, SPI 3-Wire Master Incremented Data
//
//   Description: SPI master talks to SPI slave using 3-wire mode. Incrementing
//   data is sent by the master starting at 0x01. Received data is expected to
//   be same as the previous transmission.  USCI RX ISR is used to handle
//   communication with the CPU, normally in LPM0. If high, P4.6 indicates
//   valid data reception.  Because all execution after LPM0 is in ISRs,
//   initialization waits for DCO to stabilize against ACLK.
//   ACLK = 32.768kHz, MCLK = SMCLK = DCO ~ 1048kHz.  BRCLK = SMCLK/2
//
//   Use with SPI Slave Data Echo code example.  If slave is in debug mode, P5.2
//   slave reset signal conflicts with slave's JTAG; to work around, use IAR's
//   "Release JTAG on Go" on slave device.  If breakpoints are set in
//   slave RX ISR, master must stopped also to avoid overrunning slave
//   RXBUF.
//
//                   MSP430F(G)47x
//                 -----------------
//             /|\|              XIN|-
//              | |                 |  32kHz xtal
//              --|RST          XOUT|-
//                |                 |
//                |             P2.4|-> Data Out (UCA0SIMO)
//                |                 |
//          LED <-|P4.6         P2.5|<- Data In (UCA0SOMI)
//                |                 |
//                |             P3.0|-> Serial Clock Out (UCA0CLK)
//
//
//  M.Seamen
//  Texas Instruments Inc.
//  September 2008
//  Built with IAR Embedded Workbench V4.11A and CCE V3.2
//******************************************************************************
#include  <msp430xG47x.h>

unsigned char MST_Data,SLV_Data;
int counter;
void main(void)
{
  volatile unsigned int i;

  WDTCTL = WDTPW+WDTHOLD;                   // Stop watchdog timer
  FLL_CTL0 |= XCAP14PF;                     // Configure load caps

  // Wait for xtal to stabilize
  do
  {
    IFG1 &= ~OFIFG;                           // Clear OSCFault flag
    for (i = 0x47FF; i > 0; i--);             // Time for flag to set
  }
  while ((IFG1 & OFIFG));                   // OSCFault flag still set?

  for(i=2100;i>0;i--);                      // Now with stable ACLK, wait for
                                            // DCO to stabilize.
  P5OUT = 0x04;                             // P5 setup for slave reset
  P5DIR |= 0x04;                            //
  
  P4OUT = 0;								//Setup P4.6 for LED output
  P4DIR |= 0x40;

  P2SEL |= BIT4+BIT5;
  P3SEL |= BIT0;
  UCA0CTL0 |= UCMST+UCSYNC+UCCKPL+UCMSB;    //3-pin, 8-bit SPI master
  UCA0CTL1 |= UCSSEL_2;                     // SMCLK
  UCA0BR0 = 0x0F;                           // /2
  UCA0BR1 = 0;                              //
  UCA0MCTL = 0;                             // No modulation
  UCA0CTL1 &= ~UCSWRST;                     // **Initialize USCI state machine**
  IE2 |= UCA0RXIE;                          // Enable USCI_A0 RX interrupt

  P5OUT &= ~0x04;                           // Now with SPI signals initialized,
  P5OUT |= 0x04;                            // reset slave

  for(i=5000;i>0;i--);                      // Wait for slave to initialize

  MST_Data = 0x001;                         // Initialize data values
  SLV_Data = 0x000;                         //

  UCA0TXBUF = MST_Data;                     // Transmit first character
 _BIS_SR(LPM0_bits + GIE);                 // CPU off, enable interrupts
}

#pragma vector=USCIAB0RX_VECTOR
__interrupt void USCIA0RX_ISR (void)
{
  volatile unsigned int i;

  while (!(IFG2 & UCA0TXIFG));              // USART1 TX buffer ready?
  if (UCA0RXBUF==SLV_Data)                  // Test for correct character RX'd
    P4OUT |= 0x40;                          // If correct, light LED
  else
    P4OUT &= ~0x40;                         // If incorrect, clear LED

  MST_Data++;                               // Increment data
  SLV_Data++;
  UCA0TXBUF = MST_Data;                     // Send next value

  for(i=30;i>0;i--);                        // Add time between transmissions to
}   
