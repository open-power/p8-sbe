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
#include "proc_sbe_enable_pnor.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Constant Definitions
//------------------------------------------------------------------------------

        // master detection constants
	.set IGNORE_MASTER_OVERRIDE, 0x000000000000000
	.set MASTER_CHIP, 0x000000000000002

        // SBE engine parameter settings
        .set I2C_E1_SETTING, 0xB400000300000000

	// LPC HC Firmware Read Access Size = 0xC0012028
	// LPC HC Sync Cycle Counter Value  = 0xC001202C
	.set PROC_LPC_HC_FW_READ_ACCESS_SIZE_SYNC_CYCLE_WRITE_ADDRESS, 0xC0012028
	.set PROC_LPC_HC_FW_READ_ACCESS_SIZE_SYNC_CYCLE_WRITE_DATA, 0x02000000FF000000

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

	// LPC/PNOR access enable subroutine
	// At exit:
	//   P0, A0, D0, D1, CTR: maintained
	//   P1, A1 destroyed
	.subroutine enable_lpc_module, ipl, "$Revision"
	POREVE_INF("<subroutine: enable_lpc> : *** Subroutine enable_lpc was called ***\n")

	lpcs	P1, STBY_CHIPLET_0x00000000
	// remove LPC reset
	POREVE_DBG("<subroutine: enable_lpc> : Removing LPC reset")
	sti	LPC_RESET_0x000B0001, P1, 0x0000000000000000

	// configure PORE engine
	POREVE_DBG("<subroutine: enable_lpc> : Writing SBE I2C E1 to enable PNOR access")
	sti	PORE_SBE_I2C_E1_PARAM_0x000E0018, P1, I2C_E1_SETTING

	// configure processor side LPC HC registers	
        POREVE_DBG("<subroutine: enable_lpc> : Writing PROC LPC HC FW Read Access Size / Sync Cycle Counter registers")
        lia     A1, PORE_SPACE_PNOR, PROC_LPC_HC_FW_READ_ACCESS_SIZE_SYNC_CYCLE_WRITE_ADDRESS
        sti     0, A1, PROC_LPC_HC_FW_READ_ACCESS_SIZE_SYNC_CYCLE_WRITE_DATA

	.end_subroutine enable_lpc_module

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

        .procedure proc_sbe_enable_pnor, ipl, "$Revision: 1.6 $"

	// Call subroutine to determine master status
	li	D0, IGNORE_MASTER_OVERRIDE
	bsr     check_master_module
	cmpibraeq D0, enable_pnor, MASTER_CHIP

        // stop the SBE,re-enable the CFAM I2C master
        POREVE_DBG("Restoring CFAM I2CM and stopping SBE")
	lpcs    P1, STBY_CHIPLET_0x00000000
	// set SBE Vital to the magic number HB looks for
        sti     MBOX_SBEVITAL_0x0005001C, P1, ((PROC_SBE_ENABLE_PNOR_MAGIC_ISTEP_NUM << 4) | SUBSTEP_ENABLE_PNOR_SLAVE_CHIP) << 32
	bci     D0, MBOX_FSIGP4_0x00050013, P1, BIT(20)

	// Cronus doesn't know that the slave chips are done, so just loop on the reqhalt
slave_loop:
        reqhalt RC_SBE_SUCCESS_SLAVE_CHIP, D0, P0
        bra     slave_loop

enable_pnor:
	bsr	enable_lpc_module

        .end_procedure proc_sbe_enable_pnor
