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
        .set MAX_FLUSH_LOOPS, 1000
        .set FLUSH_DELAY, 20000

        .set MULTI_CAST_PATTERN, 0x0000000000000078
        .set MULTI_CAST_COMPARE, 0x0000000000000068
        .set MULTI_CAST_READ_OP, 0x0000000000000047
        .set MULTI_CAST_WAIT_WR, 0x000000000000005F

	// Procedure Progress Step Definitions
        .set STEP_ARRAYINIT_DONE,	0x1

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------
        // ARRAY INIT module
        //
        // At entry:
        //
        //    P1 : The chiplet ID/Multicast Group
        //    D1 : Clock Regions for Array Init
        //
        // At exit:
        //
        //    P0, D0, D1, CTR  : destroyed
        //    P1, A0, A1       : maintained

        .subroutine cen_arrayinit_module, cen, "$Revision"
        POREVE_INF( "<cen_arrayinit> : *** Subroutine ARRAY INIT was called ***" )

        // If P1 is a multicast write group, set P0 to the matching OR-combine
        //   read group, otherwise simply set P0 = P1. Polling uses P1 as chiplet ID
        mr      D0, P1
        mr      P0, P1
        andi    D0, D0, MULTI_CAST_PATTERN
        cmpibrane D0, cen_arri_start, MULTI_CAST_COMPARE
        POREVE_INF( "<cen_arrayinit> : *INFO* This is a multicast ARRAY INIT *INFO*" )
        mr      D0, P1
        andi    D0, D0, MULTI_CAST_READ_OP
        mr      P0, D0

cen_arri_start:
        POREVE_INF( "<cen_arrayinit> : Drop Pervasive Fence" )
        sti     GENERIC_GP0_AND_0x00000004, P1, ~BIT(63)

        POREVE_INF( "<cen_arrayinit> : Setup ABISTMUX_SEL, ABIST mode and ABIST mode2" )
        sti     GENERIC_GP0_OR_0x00000005, P1, (BIT(0) | BIT(11) | BIT(13))

        POREVE_INF( "<cen_arrayinit> : Setup all Clock Domains and Clock Types" )
        std     D1, GENERIC_CLK_REGION_0x00030006, P1

        POREVE_INF( "<cen_arrayinit> : Setup loopcount and run-N mode" )
        ldandi  D1, GENERIC_OPCG_CNTL0_0x00030002, P0, BITS(0,21)
        ori     D1, D1, 0x80000000000412D0
        std     D1, GENERIC_OPCG_CNTL0_0x00030002, P1

        POREVE_INF( "<cen_arrayinit> : Setup IDLE count and OPCG engine start ABIST" )
        ldandi  D1, GENERIC_OPCG_CNTL2_0x00030004, P0, BITS(36,28)
        ori     D1, D1, 0x00000000F0007200
        std     D1, GENERIC_OPCG_CNTL2_0x00030004, P1

        // Issue clock start: Write OPCG CTL0 Register
        POREVE_INF( "<cen_arrayinit> : Issue Clock Start: Write OPCG CTL0 Register" )
        ld      D1, GENERIC_OPCG_CNTL0_0x00030002, P0
        ori     D1, D1, BIT(1)
        std     D1, GENERIC_OPCG_CNTL0_0x00030002, P1

        // If P1 is a multicast write group, set P0 to the matching AND-combine
        // read group, otherwise simply set P0 = P1. Polling uses P1 as chiplet ID
        POREVE_INF( "<cen_arrayinit> : Poll for OPCG done bit" )
        mr      D0, P1
        mr      P0, P1
        andi    D0, D0, MULTI_CAST_PATTERN
        cmpibrane D0, cen_arri_poll, MULTI_CAST_COMPARE
        mr      D0, P1
        andi    D0, D0, MULTI_CAST_WAIT_WR
        mr      P0, D0

cen_arri_poll:
        // Poll OPCG done bit to check for run-N completeness
        pollbitset D1, GENERIC_GP1_0x00000001, P0, 15, \
        MAX_FLUSH_LOOPS, FLUSH_DELAY, cen_arri_poll_fail
        bra     cen_arri_poll_done

cen_arri_poll_fail:
        POREVE_ERR("Centaur arrayinit module timed out polling for OPCG done")
        reqhalt RC_SBE_SCAN0_DONE_POLL_THRESHOLD

cen_arri_poll_done:
        POREVE_INF( "<cen_arrayinit> : OPCG done, clear Run-N mode" )
        ldandi  D1, GENERIC_OPCG_CNTL0_0x00030002, P0, 0x7FFFF80000000000
        std     D1, GENERIC_OPCG_CNTL0_0x00030002, P1

        POREVE_INF( "<cen_arrayinit> : Clear ABISTMUX_SEL, ABIST mode, ABIST mode2 and set Pervasive Fence" )
        sti     GENERIC_GP0_AND_0x00000004, P1, ~(BIT(0) | BIT(11) | BIT(13))                                         //UPDATE: Correct setting ? VBU has 0x7febffffffffffff
        sti     GENERIC_GP0_OR_0x00000005 , P1, BIT(63)

        POREVE_INF( "<cen_arrayinit> : *** Subroutine ARRAY INIT ends ***" )
        .end_subroutine cen_arrayinit_module

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure cen_sbe_tp_arrayinit, cen, "$Revision: 1.22 $"
        POREVE_INF( "*** Array Init and SCAN0 cleanup "
                   "for Pervasive Chiplet ***" )

        // ********************************************************
        // **          SBE Address Base Register Setups          **
        // ********************************************************
	
        // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

        // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P1, TP_CHIPLET_0x01000000

        // Step 1: Array Init for PRV Cplt
        // ===============================
        POREVE_INF( "Call ARRAY INIT Subroutine for Pervasive Chiplet" )
        li      D1, SCAN_TP_ARRAY_INIT_REGIONS		// 0x09000E0000000000 bit 4,7,20-22  => 0x01030006
        bsr     cen_arrayinit_module

        // Progress Indicator update
        updatestep STEP_ARRAYINIT_DONE, D0, P0

        // Step 2: Scan0 for PRV Cplt
        // ==========================
        POREVE_INF( "Call SCAN0 Subroutine for Pervasive Chiplet" )
        li      D0, SCAN_TP_REGIONS_EXCEPT_PIB_PCB	// 0x09E00E00 bit 4,7-10,20-22  => 0x01030006
        li      D1, SCAN_TP_SCAN_SELECTS                // 0x09E00DCE bit 4,7-10,20-21,23-25,28-30  => 0x01030007
        bsr     cen_scan0_module

        POREVE_INF( "*** End of procedure ***" )
        .end_procedure cen_sbe_tp_arrayinit

