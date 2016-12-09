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
        .list

//------------------------------------------------------------------------------
// preprocessor directives
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .pnor

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Constant Definitions
//------------------------------------------------------------------------------
        .set    CLOCK_START_REGIONS_all,      0x4FE00E0000000000
        .set    EXPECTED_CC_STATUS_START_all, 0x000007FFFFFFFFFF

        .set    STEP_OTHER_CLOCKS_RUNNING,    0x1

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure cen_sbe_tp_chiplet_init3, cen, "$Revision: 1.13 $"
        POREVE_INF( "*** Init. remaining Pervasive Chiplet, "
                   "Start Clocks on Pervasive Region *** " )
//-----------------------------------------------------
//           SBE Address Base Register Setups
//-----------------------------------------------------
        // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

        // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P1, TP_CHIPLET_0x01000000

        // Reset PCB Master interrupt register
        sti     MASTER_PCB_INT_0x000F001A, P0, 0x0000000000000000

        // TP_Chiplet, drop pervasive fence
        bci     D0, TP_GP0_0x01000000, P1, BIT(63)
        // enable PIB trace mode
        bsi     D0, TP_GP0_0x01000000, P1, BIT(23)
        bsi     D0, TP_GP0_0x01000000, P1, BIT(55)

	// Write CC, Clock Start command (all other clock domains)
        sti     TP_CLK_REGION_0x01030006, P1, CLOCK_START_REGIONS_all

        POREVE_INF( "Clock Start command (all other clock domains) " )

        // Read Clock Status Register, check tholds
        ld      D0, TP_CLK_STATUS_0x01030008, P1
        xori    D1, D0, EXPECTED_CC_STATUS_START_all
        branz   D1, error_clock_start          // branch to error

        // Update SBE VITAL register information
        updatestep STEP_OTHER_CLOCKS_RUNNING, D0, P1
        POREVE_INF( "ALL other clocks are running now..." )
        bra     next_init3

error_clock_start:
        POREVE_ERR( "ERROR: Clock Control Register: 0x%016llX "
                    "does not match the expected value: 0x000007FFFFFFFFFF ", io_pore.d1.read() )
        reqhalt RC_MSS_CCREG_MISMATCH

next_init3:
        // Write GP0, clear force_align
  	lpcs	P1, TP_CHIPLET_0x01000000
        bci     D0, TP_GP0_0x01000000, P1, BIT(3)

        // Write GP0, clear flushmode_inhibit
        bci     D0, TP_GP0_0x01000000, P1, BIT(2)

        // Pervasive chiplet drop FSI fence 5 (checkstop, interrupt conditions)
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(26)

        POREVE_INF( "Check FSI2PIB-Status(31) if any clock region is stopped." )
        lpcs    P0, MBOX_FSISTATUS_0x00050007
        ifbitsetscom D0, D0, MBOX_FSISTATUS_0x00050007, P0, 31, stopped_error_status
        bra     all_running

stopped_error_status:
        POREVE_ERR( "FSI Status register bit(31) indicates, not all clocks are running" )
        reqhalt RC_MSS_INIT3_FSISTATUS_FAIL

all_running:
        POREVE_INF( "Setup automatic PCB network, reset on a hang" )
	sti     PRV_PIB_PCBMS_RESET_REG_0x000F001D, P0, 0x2000000000000000

        POREVE_INF( "*** End of Procedure ***" )
        .end_procedure cen_sbe_tp_chiplet_init3
