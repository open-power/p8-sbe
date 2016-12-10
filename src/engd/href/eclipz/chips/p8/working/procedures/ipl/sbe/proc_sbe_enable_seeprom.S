//------------------------------------------------------------------------------
// IBM_PROLOG_BEGIN_TAG
// This is an automatically generated prolog.
//
// OpenPOWER Project
//
// Contributors Listed Below - COPYRIGHT 2012,2016
// [+] International Business Machines Corp.
//
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
// implied. See the License for the specific language governing
// permissions and limitations under the License.
//
// IBM_PROLOG_END_TAG
//------------------------------------------------------------------------------





//------------------------------------------------------------------------------
// Includes
//------------------------------------------------------------------------------
        .nolist
#define __SBE_ONLY__ 1
#include "p8_sbe.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .otprom

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Constant Definitions
//------------------------------------------------------------------------------

        // SBE FI2C parameter settings (to be customized further down for chips):
        .set I2C_E0_SETTING_PRIMARY_IMAGE, 0xC200500500000000

        // SBE VITAL mask for SEEPROM image bit
        .set SBE_VITAL_MASK_SEEPROM_IMAGE, 0x0080000000000000

        // Standalone MBOX1 value
        .set STANDALONE_MBOX1_VALUE,  0x0004002600000000

        // Procedure Progress Step Definition
//      .set STEP_START_I2C_RESET,               0x1
//      .set STEP_MAGIC_NUMBER_CHECK_START,      0x2
//      .set STEP_READY_TO_BRANCH,               0x3

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

        .ipl_text

        .global _sbe_otprom_start
_sbe_otprom_start:

// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************

     // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

     // Setup MEM_BASE_ADDR0; points to SEEPROM via ECCAX
        lia     A0, PORE_SPACE_SEEPROM, SBE_SEEPROM_LOAD_ADDRESS

// ********************************************************
// **  Enable ECC mode in OTPROM                         **
// ********************************************************

     // Enable OTPROM ECC protection
        sti     0x00010008, P0, 0x4000000000000000

// ********************************************************
// **     Initialize SBE Vital Progress Indicator        **
// ********************************************************

     // Initialize SBE_VITAL to start value (Area 1, Procedure 1, Step 0)
        sti     MBOX_SBEVITAL_0x0005001C, P0, 0x0000101000000000


// ********************************************************
// **       Set I2C Speed in I2CM mode register          **
// **                                                    **
// ** Assumption: - FSP stored I2C Bit Rate Divisor      **
// **               setting in mailbox reg 0x00050039    **
// **                                                    **
// **  Layout Scratch 39: xRRR PPPP xxxx xxxx            **
// **                                                    **
// **                     R: Refclock Bit Rate Divisor   **
// **                     P: PLL Clock Bit Rate Divisor  **
// ********************************************************

     // Read I2C Bit Rate Divisor setting from mailbox scratch register 0x39
        ldandi  D0, MBOX_SCRATCH_REG1_0x00050039, P0, BITS(4,12)
        branz   D0, es_use_mbox_value
     // Need the AND mask to mimic the ldandi it's replacing
        li      D0, (STANDALONE_MBOX1_VALUE & BITS(4,12))
es_use_mbox_value: 
     // Update I2CM Bit Rate Divisor Setting in I2CM
        std     D0, I2CMS_MEMS0_MODE_0x000A0006, P0


// ********************************************************
// **  Enable ECC mode in ECCB and set ECC boundaries    **
// ********************************************************

     // Write ECC Address register with ECC start (0x2000) and stop address (0xFFFF)
        sti     ECCB_ECC_ADDR_REG_0x000C0004, P0, 0x0000FFFF00002000


// ********************************************************
// **  SBE setting for FI2C parameter E0 (base setting)  **
// ********************************************************

     // Initialize SBE E0 with settings for the primary image
        sti     PORE_SBE_I2C_E0_PARAM_0x000E0017, P0, I2C_E0_SETTING_PRIMARY_IMAGE

	##@ fapi::ReturnCode rc;
        ##@ uint8_t  seepromAddrBytes = 0;
        ##@ uint64_t data = 0;
        ##@ ModelError me;
        ##@ rc = FAPI_ATTR_GET(ATTR_SBE_SEEPROM_I2C_ADDRESS_BYTES, &i_target, seepromAddrBytes);
        ##@ if (!rc.ok())
        ##@ {
        ##@     return rc;
        ##@ }
        ##@ me = io_pore.registerRead(PORE_I2C_E0_PARAM, data);
        ##@ if(me!=ME_SUCCESS)
        ##@ {
        ##@     FAPI_ERR("Model error getting I2C_E0_PARAM (me=0x%X)",me);
        ##@ }
        ##@ data = (data & 0xF8FFFFFFFFFFFFFFull)|(((uint64_t)seepromAddrBytes) << 56);
        ##@ me = io_pore.registerWrite(PORE_I2C_E0_PARAM, data);
        ##@ if(me!=ME_SUCCESS)
        ##@ {
        ##@     FAPI_ERR("Model error setting I2C_E0_PARAM (me=0x%X)",me);
        ##@ }
        ##@ return hookOk;
        
// ********************************************************
// **  Identify the chip                                 **
// ********************************************************

     // Read FI2C secondary image bit from SBE Vital Register - value used later
        ldandi  D1, MBOX_SBEVITAL_0x0005001C, P0, SBE_VITAL_MASK_SEEPROM_IMAGE

     // Check CFAM ID to select between Murano or Venice or Naples
        ldandi  D0, 0x000F000F, P0, BITS(12,8)
        cmpibraeq D0, es_murano_case, 0x000EF00000000000
        cmpibraeq D0, es_venice_case, 0x000EA00000000000
        cmpibraeq D0, es_venice_case, 0x000D300000000000
        halt

es_murano_case:

     // Murano device ID init
        bsi     D0, PORE_SBE_I2C_E0_PARAM_0x000E0017, P0, 0x0000060000000000

     // Update I2C device for secondary image if needed
        braz    D1, es_reset_i2c_interface
        bsi     D0, PORE_SBE_I2C_E0_PARAM_0x000E0017, P0, 0x0000010000000000
        bra     es_reset_i2c_interface

es_venice_case:

     // Venice device ID init
        bsi     D0, PORE_SBE_I2C_E0_PARAM_0x000E0017, P0, 0x0000010000000000

     // Update I2C device for secondary image if needed
        braz    D1, es_reset_i2c_interface
        bsi     D0, PORE_SBE_I2C_E0_PARAM_0x000E0017, P0, 0x0001000000000000


es_reset_i2c_interface:

// ********************************************************
// **   Prevent FSP I2C communication and reset I2C bus  **
// ********************************************************

     // Lock CFAM I2C interface
        bsi     D0, MBOX_FSIGP4_0x00050013, P0, BIT(20)

     // Update SBE_VITAL (Area 1, Procedure 1, Step 1)
        sti     MBOX_SBEVITAL_0x0005001C, P0, 0x0000101100000000

     // Skip I2C interface manipulation if instructed
	##@ fapi::ReturnCode rc;
        ##@ uint8_t disable_i2c_access = 0;
        ##@ rc = FAPI_ATTR_GET(ATTR_DISABLE_I2C_ACCESS, NULL, disable_i2c_access);
        ##@ if (!rc.ok())
        ##@ {
        ##@     return rc;
        ##@ }
        ##@ if (disable_i2c_access)
        ##@ {
        ##@     io_pore.forceBranch("otprom::es_get_magic_number");
        ##@ }
        ##@ return hookOk;


     // I2C master, bus and slave reset sequence
     // ========================================

     // Set I2C master enhanced mode
        bsi     D0, I2CMS_MEMS0_MODE_0x000A0006, P0, BIT(28)

     // Set I2C command register to (only stop bit asserted)
        sti     I2CMS_MEMS0_COMMAND_0x000A0005, P0, BIT(3)

es_poll_i2c_reset:

     // Poll for command complete
        ldandi  D0, I2CMS_MEMS0_STATUS_0x000A000B, P0, BIT(7)
        braz    D0, es_poll_i2c_reset

     // Reset I2C master enhanced mode bit
        bci     D0, I2CMS_MEMS0_MODE_0x000A0006, P0, BIT(28)

	.global	es_get_magic_number
es_get_magic_number:

// ********************************************************
// **          Checking Magic Number and branch          **
// ********************************************************

     // Update SBE_VITAL (Area 1, Procedure 1, Step 2)
        sti     MBOX_SBEVITAL_0x0005001C, P0, 0x0000101200000000

     // Read and check SEEPROM magic number, A0 already points to this address
        ld      D0, 0x0, A0
        cmpibraeq D0, es_magic_number_passed, SBE_SEEPROM_MAGIC
        halt

es_magic_number_passed:

     // Calculate start of SEEPROM code (Magic Number Address + Offset taken from 8 byte right after Magic Number) and branch
        ld      D0, 0x8, A0
        mr      D1, A0
        add     D0, D0, D1
        ori     D0, D0, 0x0000800000000000

     // Update SBE_VITAL (Area 1, Procedure 1, Step 3)
        sti     MBOX_SBEVITAL_0x0005001C, P0, 0x0000101300000000

     // Branch to Seeprom
        brad    D0

     // Stop in case we ever end up here
        halt
