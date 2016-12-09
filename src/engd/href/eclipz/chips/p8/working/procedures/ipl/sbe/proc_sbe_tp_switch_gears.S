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
#include "common_ecids.H"
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


//------------------------------------------------------------------------------
// Procedure
//-----------------------------------------------------------------------------

        .global _tcb_gears_switched

        .procedure proc_sbe_tp_switch_gears, ipl, "$Revision: 1.3 $"
        POREVE_INF("<proc_sbe_tp_switch_gears> : *** Speed up the pervasive world ***\n")

// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************

        // On proc entry, P1 points to STBY_CHIPLET_0x00000000

tcb_start:
	
// ********************************************************
// **      Check if we need XBUS PLL workaround          **
// ********************************************************
	//skip workaround if in sim
        ##@fapi::ReturnCode rc;
        ##@uint8_t is_sim = 0;
        ##@rc = FAPI_ATTR_GET( ATTR_IS_SIMULATION, &i_target, is_sim);
        ##@if( !rc.ok() ) {
        ##@  return rc;
        ##@}
        ##@if( is_sim ) {
	##@  FAPI_INF("SKIPPING XBUS PLL MURANO DD1.X WORKAROUND\n");
        ##@  io_pore.forceBranch("seeprom::tcb_no_xbus_workaround");
        ##@}
	##@return hookOk;
	
	ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P1, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
        cmpibrane D0, tcb_no_xbus_workaround,       (CFAM_CHIP_ID_MURANO    | CFAM_CHIP_ID_MAJOR_EC_1 )

// ********************************************************
// **      XBUS Murano DD1.x workaround                  **
// ********************************************************
        // 1. scan x, clear CCALFMIN bit, scan y (but don't do setpulse yet)
        // 2. drop bypass before setpulse, to allow logic to get started with wrong settings
        // 3. do setpulse to change PLL to new scan value
        // idial TPFLEX.PLLXB.CCALFMIN {
        //  ring perv_bndy_pll {
        //  1    684    176 0 TPFLEX.PLLXB.PLLCTL.C_PLL_CNTRL_LEAF.CFG_LAT.NLC.L2(56)

        POREVE_INF("<proc_sbe_tp_switch_gears> : Branching to PIBMEM to switch gears (with workaround) ...\n")
        lpcs    P0, TP_CHIPLET_0x01000000 

        //Select PLL ring
        sti     TP_CLK_SCANSEL_0x01030007, P0, BIT(11)|BIT(28)
        
        //Scan rotate, flip bit, rotate back in (but do the dropping of bypass and the setpulse in the PIBMEM)
        sti     GENERIC_CLK_SCANDATA0_0x00038000, P0, 0xA5A55A5A00000000
        ldandi  D0, (GENERIC_CLK_SCANDATA0_0x00038000 + 684), P0, ~BIT(0)
        std     D0, (GENERIC_CLK_SCANDATA0_0x00038000 + 177), P0
        ld      D0, GENERIC_CLK_SCANDATA0_0x00038000, P0
        cmpibrane D0, xbus_pll_workaround_header_check_fail, 0xA5A55A5A00000000

     // Branch to PIBMEM to drop bypass, modify PLL (setpulse), poll for lock, and adjust I2C speed
        bsria   PORE_SPACE_PIBMEM, _sw_start_xbus_workaround
        bra     _tcb_gears_switched

	.global tcb_no_xbus_workaround
tcb_no_xbus_workaround:      
// ********************************************************
// **      Branch to PIBMEM to switch gears              **
// ********************************************************

     // Branch to PIBMEM to switch from refclock to PLL and adjust I2C speed
        POREVE_INF("<proc_sbe_tp_switch_gears> : Branching to PIBMEM to switch gears ...\n")
        bsria   PORE_SPACE_PIBMEM, _sw_start


_tcb_gears_switched:

// ********************************************************
// **      Done                                          **
// ********************************************************

     // We are now at full speed (switched from refclock to PLL and adjusted PIB I2CM speed)
        POREVE_INF("<proc_sbe_tp_switch_gears> : Gears switched ... now back in SEEPROM ...\n")

        POREVE_INF("<proc_sbe_tp_switch_gears> : *** End of procedure ***\n")
        .end_procedure proc_sbe_tp_switch_gears

xbus_pll_workaround_header_check_fail:
        POREVE_ERR("X-Bus -> Murano DD1.x workaround header check fail") ;
        reqhalt RC_SBE_TP_SWITCH_GEARS_XBUS_HEADER_CHECK_FAIL
