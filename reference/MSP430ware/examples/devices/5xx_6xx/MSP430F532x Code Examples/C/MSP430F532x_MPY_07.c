//******************************************************************************
//   MSP430F532x Demo - 16x16 Signed Multiply Accumulate
//
//   Description: Hardware multiplier is used to multiply two numbers.
//   The calculation is automatically initiated after the second operand is
//   loaded.  A second multiply-accumulate operation is performed after that.
//   Results are stored in RESLO and RESHI.  SUMEXT contains the extended sign
//   of the result.
//   ACLK = 32.768kHz, MCLK = SMCLK = default DCO
//
//               MSP430F532x
//             -----------------
//         /|\|                 |
//          | |                 |
//          --|RST              |
//            |                 |
//            |                 |
//
//   Bhargavi Nisarga
//   Texas Instruments Inc.
//   April 2009
//   Built with CCSv4 and IAR Embedded Workbench Version: 4.21
//******************************************************************************

#include <msp430f5328.h>

void main(void)
{
  WDTCTL = WDTPW+WDTHOLD;                   // Stop WDT
  MPY = 0x1234;                             // Load first operand -unsigned mult
  OP2 = 0x5678;                             // Load second operand

  MACS = 0x1234;                            // Load first operand -signed MAC
  OP2 = 0x5678;                             // Load second operand

  __bis_SR_register(LPM4_bits);             // Enter LPM4
  __no_operation();                         // For debugger  
}
