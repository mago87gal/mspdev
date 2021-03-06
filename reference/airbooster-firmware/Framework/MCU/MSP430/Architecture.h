/**
 *  @file Architecture.h
 *
 *  @brief MSP430 architecture public interface definitions for the Clock System
 *  and Flash modules.
 *
 *  @version  1.0
 *
 *  @attention IMPORTANT: Your use of this Software is limited to those specific 
 *             rights granted under the terms of a software license agreement 
 *             between the user who downloaded the software, his/her employer 
 *             (which must be your employer) and Anaren (the "License"). You may
 *             not use this Software unless you agree to abide by the terms of 
 *             the License. The License limits your use, and you acknowledge,
 *             that the Software may not be modified, copied or distributed unless
 *             in connection with an authentic Anaren product. Other than for the 
 *             foregoing purpose, you may not use, reproduce, copy, prepare 
 *             derivative works of, modify, distribute, reverse engineer, decompile,
 *             perform, display or sell this Software and/or its documentation 
 *             for any purpose. 
 *             YOU FURTHER ACKNOWLEDGE AND AGREE THAT THE SOFTWARE AND DOCUMENTATION
 *             ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS 
 *             OR IMPLIED, INCLUDING WITHOUT LIMITATION, ANY  WARRANTY OF 
 *             MERCHANTABILITY, TITLE, NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR 
 *             PURPOSE. IN NO EVENT SHALL ANAREN OR ITS LICENSORS BE LIABLE OR
 *             OBLIGATED UNDER CONTRACT, NEGLIGENCE, STRICT LIABILITY, CONTRIBUTION,
 *             BREACH OF WARRANTY, OR OTHER LEGAL EQUITABLE THEORY ANY DIRECT OR 
 *             INDIRECT DAMAGES OR EXPENSES INCLUDING BUT NOT LIMITED TO ANY 
 *             INCIDENTAL, SPECIAL, INDIRECT, PUNITIVE OR CONSEQUENTIAL DAMAGES, 
 *             LOST PROFITS OR LOST DATA, COST OF PROCUREMENT OF SUBSTITUTE GOODS,
 *             TECHNOLOGY, SERVICES, OR ANY CLAIMS BY THIRD PARTIES (INCLUDING BUT
 *             NOT LIMITED TO ANY DEFENSE THEREOF), OR OTHER SIMILAR COSTS. 
 */
#ifndef __MCU_MSP430_ARCHITECTURE_H
#define	__MCU_MSP430_ARCHITECTURE_H

// Processor configuration
#include "Configuration/MSP430Config.h"

// Peripheral interfaces
#include "Peripherals/Architecture/BasicClockSystemPlus.h"
#include "Peripherals/Architecture/UnifiedClock.h"
#include "Peripherals/Architecture/Flash.h"

/**
 *  @details
 */
typedef struct ClockSystemModule
{
  enum CLOCKPERIPHERAL
  {
    BASICCLOCKSYSTEMPLUS
  } peripheral;
  union CLOCK
  {
    #if defined(__MCU_MSP430_BASICCLOCKSYSTEMPLUS)
      BasicClockSystemPlusPeripheral * pBasicClockSystemPlus;
    #elif
      #error "__HAL_ERROR: Invalid or no system clock defined."
    #endif
  };
} ClockSystemModule;

/**
 *  @details
 */
typedef struct FlashModule
{
  // NOTE: This structure is just a placeholder for implementation.
  union FLASH
  {
    uint8_t placeHolder;  
  };
} FlashModule;

// PUBLIC INTERFACE
////////////////////////////////////////////////////////////////////////////////

/**
 *  @details Sets MCU architecture peripherals to a predetermined state.
 *           These peripherals include: Clock system, Flash
 */
void InitArchitecture(void);

/**
 *  @details Reconfigure MCU architecture peripherals.
 */
void ReconfigureArchitecture(ClockSystemModule * pClockSystemModule, FlashModule * pFlashModule);

/**
 *  @details Sets the clock system to a predetermined state. Helper function
 *           for InitArchitecture().
 */
void InitClockSystem(void);

/** 
 *  @details Reconfigure clock system
 */
void ReconfigureClockSystem(ClockSystemModule * pClockSystemModule);

/**
 *  @details Return the value of clock system register specified by the index.
 */
uint_least8_t GetClockSystemRegister(uint8_t regIndex);

/**
 *  @details Set the value of clock system register specified by the index.
 */
void SetClockSystemRegister(uint8_t regIndex, uint_least8_t value);

/**
 *  @details Sets the flash module to a predetermined state. Helper function
 *           for InitArchitecture().
 */
void InitFlash(void);

/**
 *  @details Reconfigure flash module. This functionality is currently not supported.
 */
void ReconfigureFlash(FlashModule * pFlashModule);

/**
 *  @details Write a character to the flash.
 */
void FlashWriteChar(volatile unsigned char * address, unsigned char value);

#endif	// __MCU_MSP430_ARCHITECTURE_H