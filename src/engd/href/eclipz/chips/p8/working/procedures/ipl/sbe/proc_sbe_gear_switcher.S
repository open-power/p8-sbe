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
#include "p8_sbe.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .pibmem

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Constant Definitions
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

	.ipl_text

	.global	_sw_start_xbus_workaround

_sw_start_xbus_workaround:

        POREVE_INF("X-Bus -> Drop PLL bypass early for Murano DD1.x workaround" )
        bci     D0, MBOX_GP3MIR_0x0005001B, P1, BIT(5) 

        //Setpulse
        sti     TP_CLK_REGION_0x01030006, P0, 0xC010040000000000
        ls      D0, 0x0
        std     D0, TP_CLK_REGION_0x01030006, P0

poll_for_xbus_pll_lock: 
        POREVE_INF("X-Bus -> Poll PLLLOCKREG" )
        lpcs    P0, XBUS_CHIPLET_0x04000000
        pollbitset D0, X_PLLLOCKREG_0x040F0019, P0, 0, 60, 1000, xbus_nolock
        
	.global	_sw_start

_sw_start:
// ********************************************************
// **      Switch from refclock to real PLL clocking     **
// ********************************************************

     // Switch from refclock to PLL
        POREVE_INF("<proc_sbe_gear_switcher> : Arrived in PIBMEM, switching to XBUS PLL from bypass...\n")
        bci     D0, MBOX_GP3MIR_0x0005001B, P1, BIT(5)

// ********************************************************
// **      Adjust PIB I2CM bit rate divisor              **
// **                                                    **
// ** Assumption: - FSP stored I2C Bit Rate Divisor      **
// **               setting in mailbox reg 0x00050039    **
// ********************************************************

     // Read I2C Bit Rate Divisor setting from mailbox scratch register 0x39
        ldandi  D0, MBOX_SCRATCH_REG1_0x00050039, P1, BITS(16,16)
        rols    D0, D0, 16

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
        ##@     io_pore.forceBranch("pibmem::tb_done");
        ##@ }
        ##@ return hookOk;

     // Adjust the PIB I2CM bit rate divisor for the new PIB speed
        POREVE_INF("<proc_sbe_gear_switcher> : Adjusting PIB I2CM for new PIB speed ...\n")
        std     D0, I2CMS_MEMS0_MODE_0x000A0006, P1

// ********************************************************
// **      Reset I2C interface                           **
// ********************************************************

     // We might want to reset the I2C interface after switching gears ?!

     // Set I2C master enhanced mode
        bsi     D0, I2CMS_MEMS0_MODE_0x000A0006, P1, BIT(28)

     // Set I2C command register to (only stop bit asserted)
        sti     I2CMS_MEMS0_COMMAND_0x000A0005, P1, BIT(3)

tb_poll_i2c_reset:

     // Poll for command complete
        ldandi  D0, I2CMS_MEMS0_STATUS_0x000A000B, P1, BIT(7)
        braz    D0, tb_poll_i2c_reset

     // Reset I2C master enhanced mode bit
        bci     D0, I2CMS_MEMS0_MODE_0x000A0006, P1, BIT(28)


// ********************************************************
// **      Branch back to SEEPROM                        **
// ********************************************************

	.global tb_done
tb_done:
     // Branch to back to SEEPROM
        POREVE_INF("<proc_sbe_gear_switcher> : Branching back to SEEPROM ...\n")
        ret

// ********************************************************
// **      Errors                                        **
// ********************************************************
xbus_nolock:
        POREVE_ERR("X-Bus -> Failed to lock");
        reqhalt RC_SBE_TP_SWITCH_GEARS_XBUS_NOLOCK
