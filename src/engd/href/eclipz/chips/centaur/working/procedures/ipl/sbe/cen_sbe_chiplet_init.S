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
#include "cen_sbe.H"
#include "common_ecids.H"
        .list

//------------------------------------------------------------------------------
// Constant Definition
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .pnor

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Constant Definitions
//------------------------------------------------------------------------------
        .set    STEP_PARTIAL_GOOD_READ,     0x1
        .set    STEP_SETUP_MCGRP_DONE,      0x2
        .set    STEP_START_REPAIR,          0x3

	// Repair Loader Constants
	.set REPAIR_COMMAND_VALIDATION_ENTRIES_DD1, 0xFE0             // control words 0-6
	.set REPAIR_COMMAND_VALIDATION_ENTRIES_DD2, 0xFE4             // control words 0-6,9
	.set REPAIR_COMMAND_VALIDATION_ENTRY_TCN_REFR_TIME_DD2, 0x008 // control word 8
	.set REPAIR_COMMAND_START_ADDRESS, 0x27F

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure cen_sbe_chiplet_init, cen, "$Revision: 1.29 $"
        POREVE_INF("*** Initialize good chiplets "
                   "and setup multicast registers ***" )
//-----------------------------------------------------
//           SBE Address Base Register Setups
//-----------------------------------------------------
        // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

        // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P1, TP_CHIPLET_0x01000000

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Set up groups 0 and 3 multicast groups for Centaur
// Multicast Group 0:   All functional chiplets (PRV NST MEM)
// Multicast Group 3:   All functional chiplets, except PRV
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        POREVE_INF( "Initializing multicast group0 (all) and "
                    "group3 (all except PRV)" )
        lpcs    P0, TP_MCGR1_0x010F0001
        sti     TP_MCGR1_0x010F0001, P0, 0xE0001C0000000000

        lpcs    P0, NEST_MCGR1_0x020F0001
        sti     NEST_MCGR1_0x020F0001, P0, 0xE0001C0000000000

        lpcs    P0, MEM_MCGR1_0x030F0001
        sti     MEM_MCGR1_0x030F0001, P0, 0xE0001C0000000000

        lpcs    P0, NEST_MCGR4_0x020F0004
        sti     NEST_MCGR4_0x020F0004, P0, 0xEC001C0000000000

        lpcs    P0, MEM_MCGR4_0x030F0004
        sti     MEM_MCGR4_0x030F0004, P0, 0xEC001C0000000000

        POREVE_INF( "Set unused group registers to broadcast, Group 7" )

        lpcs    P0, TP_MCGR2_0x010F0002
        sti     TP_MCGR2_0x010F0002, P0, 0xFC001C0000000000
        lpcs    P0, TP_MCGR3_0x010F0003
        sti     TP_MCGR3_0x010F0003, P0, 0xFC001C0000000000
        lpcs    P0, TP_MCGR4_0x010F0004
        sti     TP_MCGR4_0x010F0004, P0, 0xFC001C0000000000

        lpcs    P0, NEST_MCGR2_0x020F0002
        sti     NEST_MCGR2_0x020F0002, P0, 0xFC001C0000000000
        lpcs    P0, NEST_MCGR3_0x020F0003
        sti     NEST_MCGR3_0x020F0003, P0, 0xFC001C0000000000

        lpcs    P0, MEM_MCGR2_0x030F0002
        sti     MEM_MCGR2_0x030F0002, P0, 0xFC001C0000000000
        lpcs    P0, MEM_MCGR3_0x030F0003
        sti     MEM_MCGR3_0x030F0003, P0, 0xFC001C0000000000

        POREVE_INF( "Done initializing centaur multicast group0, group3" )
        updatestep STEP_SETUP_MCGRP_DONE, D0, P1

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Chiplet Init (all other pervasive endpoints within the different chiplets)
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        POREVE_INF( "Start pervasive initialization of other chiplets" )
        // Setup PRV_BASE_ADDR1; points to MC group3
        ls      P1, SCAN_CHIPLET_GROUP3

        POREVE_INF( "Reset GP3 for all chiplets" )
        sti     WRITE_ALL_FUNC_GP3_0x6B0F0012, P1, BIT(1)|BIT(11)|BITS(13,2)|BIT(18)     // 0x4016200000000000

        POREVE_INF( "Release endpoint reset for PCB" )
        sti     WRITE_ALL_FUNC_GP3_AND_0x6B0F0013, P1, ~BIT(1)                           // 0xBFFFFFFFFFFFFFFF

        // multicast, WOR codepoint partial good setting
        POREVE_INF( "Partial good setting GP3(00)='1'" )
        bsi     D0, WRITE_ALL_FUNC_GP3_OR_0x6B0F0014, P1, BIT(0)                         // 0x8000000000000000

        ls      P1, SCAN_CHIPLET_MEM
        POREVE_INF( "DEBUG: clear force_to_known_2 (fencing for partial good) " )
        bci     D0, MEM_GP0_0x03000000, P1, BIT(16)

        ls      P1, SCAN_CHIPLET_GROUP3
        POREVE_INF( "PCB slave error reg reset" )
        sti     WRITE_ALL_PCB_SLAVE_ERRREG_0x6B0F001F, P1, BITS(0,64)                    // 0xFFFFFFFFFFFFFFFF

        // call cen_scan0_module( SCAN_CHIPLET_ALL, GPTR_TIME_REP )
        li      D0, SCAN_ALLREGIONEXVITAL		// 0x0FF00E00 bit 4-11,20-22     => 0x01030006
        li      D1, SCAN_GPTR_TIME_REP                  // 0x0FF00230 bit 4-11,22,26-27  => 0x01030007
        bsr     cen_scan0_module

        // call cen_scan0_module( SCAN_CHIPLET_ALL, ALLSCANEXPRV )
        li      D0, SCAN_ALLREGIONEXVITAL               // 0x0FF00E00 bit 4-11,20-22     => 0x01030006
        li      D1, SCAN_ALLSCANEXPRV                   // 0x0FF00DCE bit 4-11,20-21,23-25,28-30  => 0x01030007
        bsr     cen_scan0_module

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repair Loader (exclude TP)
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	POREVE_INF("Invoking repair loader...")
        updatestep STEP_START_REPAIR, D0, P1

	li	A1, REPAIR_COMMAND_START_ADDRESS

	lpcs	P1, STBY_CHIPLET_0x00000000
	ldandi	D0, PCBMS_DEVICE_ID_0x000F000F, P1, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
	cmpibraeq D0, setup_repair_loader_dd1,      (CFAM_CHIP_ID_CENTAUR   | CFAM_CHIP_ID_MAJOR_EC_1)

setup_repair_loader_not_dd1:
        POREVE_DBG("Setting up repair loader for DD2 OTPROM layout");
        li      A0, REPAIR_COMMAND_VALIDATION_ENTRIES_DD2
	bra	run_repair_loader

setup_repair_loader_dd1:
	POREVE_DBG("Setting up repair loader for DD1 OTPROM layout");
        li      A0, REPAIR_COMMAND_VALIDATION_ENTRIES_DD1

run_repair_loader:
	bsr	cen_repair_loader

        // load tcn_refr_time ring with repair loader assist (DD2+ only)
        lpcs    P1, STBY_CHIPLET_0x00000000
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P1, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
        cmpibraeq D0, chiplet_init_done,            (CFAM_CHIP_ID_CENTAUR   | CFAM_CHIP_ID_MAJOR_EC_1)

	// skip load if no repairs are present
	ifbitclrscom D0, D0, ECID_PART_1_0x00010001, P1, 0, chiplet_init_done

	POREVE_DBG("SCANNING tcn_refr_time");
        // inject header and rotate ring to position where repair loader will write data from OTPROM
        // scan 0..210
	lpcs	P0, NEST_CHIPLET_0x02000000
	sti	GENERIC_CLK_SCANSEL_0x00030007, P0, BIT(10)|BIT(27)
	sti	GENERIC_CLK_SCANDATA0_0x00038000, P0, 0xA5A55A5A00000000
	ld	D0, (GENERIC_CLK_SCANDATA0_0x00038000 + 0x6E), P0
	ld	D0, (GENERIC_CLK_SCANDATA0_0x00038000 + 0x65), P0

        // data 211..3006
        li      A1, REPAIR_COMMAND_START_ADDRESS
        li      A0, REPAIR_COMMAND_VALIDATION_ENTRY_TCN_REFR_TIME_DD2
        bsr     cen_repair_loader

        // scan 3007..3208
	lpcs	P0, NEST_CHIPLET_0x02000000
        sti     GENERIC_CLK_SCANSEL_0x00030007, P0, BIT(10)|BIT(27)
        ld      D0, (GENERIC_CLK_SCANDATA0_0x00038000 + 0x6E), P0
        ld      D0, (GENERIC_CLK_SCANDATA0_0x00038000 + 0x5C), P0

        // data 3209..6004
	li	A1, REPAIR_COMMAND_START_ADDRESS
	li	A0, REPAIR_COMMAND_VALIDATION_ENTRY_TCN_REFR_TIME_DD2
	bsr	cen_repair_loader

        // scan 6005..6151
	// check header
        lpcs	P0, NEST_CHIPLET_0x02000000
        sti     GENERIC_CLK_SCANSEL_0x00030007, P0, BIT(10)|BIT(27)
        ld      D0, (GENERIC_CLK_SCANDATA0_0x00038000 + 0x6E), P0
        ld      D0, (GENERIC_CLK_SCANDATA0_0x00038000 + 0x25), P0
	cmpibraeq D0, chiplet_init_done, 0xA5A55A5A00000000

tcn_refr_header_check_fail:
	POREVE_ERR("Error rotating tcn_refr_time ring -- header mismatch!");
	reqhalt RC_CEN_SBE_TCN_REFR_TIME_HEADER_MISMATCH_ERR

chiplet_init_done:

        POREVE_INF( "*** End of procedure ***" )
        .end_procedure cen_sbe_chiplet_init

