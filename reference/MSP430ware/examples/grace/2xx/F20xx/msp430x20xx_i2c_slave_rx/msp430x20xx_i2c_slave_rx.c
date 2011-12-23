//******************************************************************************
//  MSP430F20xx Demo - I2C Slave Receiver, single byte
//
//  Description: I2C Slave communicates with I2C Master using
//  the USI. Master data should increment from 0x00 with each transmitted byte
//  which is verified by the slave.
//  LED off for address or data Ack; LED on for address or data NAck.d by the slave.
//  ACLK = n/a, MCLK = SMCLK = Calibrated 1MHz
//
//  ***THIS IS THE SLAVE CODE***
//
//                  Slave                      Master
//                                      (msp430x20xx_i2c_master_tx.c)
//               MSP430F20x2/3              MSP430F20x2/3
//             -----------------          -----------------
//         /|\|              XIN|-    /|\|              XIN|-
//          | |                 |      | |                 |
//          --|RST          XOUT|-     --|RST          XOUT|-
//            |                 |        |                 |
//      LED <-|P1.0             |        |                 |
//            |                 |        |             P1.0|-> LED
//            |         SDA/P1.7|<-------|P1.7/SDA         |
//            |         SCL/P1.6|<-------|P1.6/SCL         |
//
//  Note: internal pull-ups are used in this example for SDA & SCL
//
/*
 * ======== Standard MSP430 includes ========
 */
#include <msp430.h>

/*
 * ======== Grace related includes ========
 */
#include <ti/mcu/msp430/csl/CSL.h>

char MST_Data = 0;                     // Variable for received data
char SLV_Addr = 0x90;                  // Address is 0x48<<1 for R/W
int I2C_State = 0;                     // State variable


/*
 *  ======== main ========
 */
void main(int argc, char *argv[])
{
    CSL_init();

    USICTL0 &= ~USISWRST;                // Enable USI
	USICTL1 &= ~USIIFG;                  // Clear pending flag
	_EINT();

	while(1)
	{
		LPM0;                              // CPU off, await USI interrupt
		_NOP();                            // Used for IAR
	}
}
void USI_TXRX(void)
{
	  if (USICTL1 & USISTTIFG)             // Start entry?
	  {
	    P1OUT |= 0x01;                     // LED on: sequence start
	    I2C_State = 2;                     // Enter 1st state on start
	  }

	  switch(I2C_State)
	    {
	      case 0: // Idle, should not get here
	              break;

	      case 2: // RX Address
	              USICNT = (USICNT & 0xE0) + 0x08; // Bit counter = 8, RX address
	              USICTL1 &= ~USISTTIFG;   // Clear start flag
	              I2C_State = 4;           // Go to next state: check address
	              break;

	      case 4: // Process Address and send (N)Ack
	              if (USISRL & 0x01)       // If read...
	                SLV_Addr++;            // Save R/W bit
	              USICTL0 |= USIOE;        // SDA = output
	              if (USISRL == SLV_Addr)  // Address match?
	              {
	                USISRL = 0x00;         // Send Ack
	                P1OUT &= ~0x01;        // LED off
	                I2C_State = 8;         // Go to next state: RX data
	              }
	              else
	              {
	                USISRL = 0xFF;         // Send NAck
	                P1OUT |= 0x01;         // LED on: error
	                I2C_State = 6;         // Go to next state: prep for next Start
	              }
	              USICNT |= 0x01;          // Bit counter = 1, send (N)Ack bit
	              break;

	      case 6: // Prep for Start condition
	              USICTL0 &= ~USIOE;       // SDA = input
	              SLV_Addr = 0x90;         // Reset slave address
	              I2C_State = 0;           // Reset state machine
	              break;

	      case 8: // Receive data byte
	              USICTL0 &= ~USIOE;       // SDA = input
	              USICNT |=  0x08;         // Bit counter = 8, RX data
	              I2C_State = 10;          // Go to next state: Test data and (N)Ack
	              break;

	      case 10:// Check Data & TX (N)Ack
	              USICTL0 |= USIOE;        // SDA = output
	              if (USISRL == MST_Data)  // If data valid...
	              {
	                USISRL = 0x00;         // Send Ack
	                MST_Data++;            // Increment Master data
	                P1OUT &= ~0x01;        // LED off
	              }
	              else
	              {
	                USISRL = 0xFF;         // Send NAck
	                P1OUT |= 0x01;         // LED on: error
	              }
	              USICNT |= 0x01;          // Bit counter = 1, send (N)Ack bit
	              I2C_State = 6;           // Go to next state: prep for next Start
	              break;
	    }

	  USICTL1 &= ~USIIFG;                  // Clear pending flags
}