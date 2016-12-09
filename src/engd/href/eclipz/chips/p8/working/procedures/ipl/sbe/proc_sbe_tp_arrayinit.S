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
#include "p8_slw.H"
        .list


//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Constant Definitions
//------------------------------------------------------------------------------

     // Procedure Progress Step Definition
        .set STEP_ARRAYINIT_DONE,  0x1

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


        .subroutine seeprom_array_init_module, ipl, "$Revision: 1.32 $"
        POREVE_INF("<subroutine: ARRAY INIT> : *** Subroutine ARRAY INIT was called ***\n")

     // If P1 is a multicast write group, set P0 to the matching OR-combine
     //   read group, otherwise simply set P0 = P1. Polling uses P1 as chiplet ID

        mr      D0, P1
        mr      P0, P1
        andi    D0, D0, 0x0000000000000078
        cmpibrane D0, oaim_start, 0x0000000000000068
        mr      D0, P1
        andi    D0, D0, 0x0000000000000047
        mr      P0, D0

        POREVE_INF("<subroutine: ARRAY INIT> : *INFO* This is a multicast ARRAY INIT *INFO*\n")

oaim_start:

     // Drop Pervasive Fence GP0 Bit 63
        POREVE_INF("<subroutine: ARRAY INIT> : Drop Pervasive Fence ...\n")
        sti     GENERIC_GP0_AND_0x00000004, P1, ~BIT(63)

     // Setup ABISTCLK_MUXSEL, ABIST mode and ABIST mode2
        POREVE_INF("<subroutine: ARRAY INIT> : Setup ABISTMUX_SEL, ABIST mode and ABIST mode2 ...\n")
                
        ifsleep D0, oaim_sleep_abist       
        // Winkle and IPL:  L3 (11), PC/L2 (13)
        sti     GENERIC_GP0_OR_0x00000005, P1, (BIT(0) | BIT(11) | BIT(13))
        bra     oaim_continue 
oaim_sleep_abist:
        POREVE_INF("<subroutine: ARRAY INIT> : Setup ABISTMUX_SEL, ABIST mode and ABIST mode2 for Sleep\n")
        // Sleep:  L3 (11);  Clear PC/L2 (13)
        sti     GENERIC_GP0_AND_0x00000004, P1, ~(BIT(11))
        sti     GENERIC_GP0_OR_0x00000005, P1, (BIT(0) | BIT(13))
oaim_continue:

     // Setup all Clock Domains and Clock Types
        POREVE_INF("<subroutine: ARRAY INIT> : Setup all Clock Domains and Clock Types ...\n")
        std     D1, GENERIC_CLK_REGION_0x00030006, P1

     // Setup loopcount and run-N mode
        POREVE_INF("<subroutine: ARRAY INIT> : Setup loopcount and run-N mode ...\n")
        ld      D1, GENERIC_OPCG_CNTL0_0x00030002, P0
        andi    D1, D1, BITS(0,21)
        ori     D1, D1, 0x80000000000412D0
        std     D1, GENERIC_OPCG_CNTL0_0x00030002, P1

     // Setup IDLE count and OPCG engine start ABIST
        POREVE_INF("<subroutine: ARRAY INIT> : Setup IDLE count and OPCG engine start ABIST ...\n")
        ld      D1, GENERIC_OPCG_CNTL2_0x00030004, P0
        andi    D1, D1, BITS(36,28)
        ori     D1, D1, 0x00000000F0007200
        std     D1, GENERIC_OPCG_CNTL2_0x00030004, P1

     // Issue clock start: Write OPCG CTL0 Register
        POREVE_INF("<subroutine: ARRAY INIT> : Issue Clock Start ...\n")
        ld      D1, GENERIC_OPCG_CNTL0_0x00030002, P0
        ori     D1, D1, BIT(1)
        std     D1, GENERIC_OPCG_CNTL0_0x00030002, P1

     // If P1 is a multicast write group, set P0 to the matching AND-combine
     //   read group, otherwise simply set P0 = P1. Polling uses P1 as chiplet ID
        POREVE_INF("<subroutine: ARRAY INIT> : Poll for OPCG done bit ...\n")

        mr      D0, P1
        mr      P0, P1
        andi    D0, D0, 0x0000000000000078
        cmpibrane D0, oaim_poll, 0x0000000000000068
        mr      D0, P1
        andi    D0, D0, 0x000000000000005f
        mr      P0, D0

oaim_poll:

     // Poll OPCG done bit to check for run-N completeness
        pollbitset D1, GENERIC_GP1_0x00000001, P0, 15, 10000, 8000, oaim_poll_fail                                     //UPDATE: max loop count and wait cycles ?
        bra     oaim_poll_done

oaim_poll_fail:

     // Stopping the SBE due to a polling threshold during array init
        reqhalt RC_SBE_ARRAYINIT_POLL_THRESHOLD

oaim_poll_done:

     // When 'done' then clear OPCG0 settings: Write OPCG CTL0 Register
        POREVE_INF("<subroutine: ARRAY INIT> : OPCG done, clear Run-N mode ...\n")
        ld      D1, GENERIC_OPCG_CNTL0_0x00030002, P0
        andi    D1, D1, 0x7FFFF80000000000
        std     D1, GENERIC_OPCG_CNTL0_0x00030002, P1

     // When 'done', then clear ABISTCLK_MUXSEL, ABIST mode and ABIST mode2
     //   and set Pervasive Fence (GP0 Bit 63) again
        POREVE_INF("<subroutine: ARRAY INIT> : Clear ABISTMUX_SEL, ABIST mode, ABIST mode2 and set Pervasive Fence ...\n")
        sti     GENERIC_GP0_AND_0x00000004, P1, ~(BIT(0) | BIT(11) | BIT(13))                                         //UPDATE: Correct setting ? VBU has 0x7febffffffffffff
        sti     GENERIC_GP0_OR_0x00000005 , P1, BIT(63)

        POREVE_INF("<subroutine: ARRAY INIT> : *** Subroutine ARRAY INIT ends ***\n")
        .end_subroutine seeprom_array_init_module

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_tp_arrayinit, ipl, "$Revision: 1.32 $"
        POREVE_INF("<proc_sbe_tp_arrayinit> :  *** Array Init and SCAN0 cleanup for Pervasive Chiplet ***\n")


tai_setup:

// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************

     // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

     // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P1, TP_CHIPLET_0x01000000

tai_start:

     // Exclude PIBMEM from TP array init
        bsi     D0, PIBMEM_REPAIR_0x00088007, P0, BIT(63)

     // Step 1: Array Init for PRV Cplt
     // ===============================
        POREVE_INF("<proc_sbe_tp_arrayinit> :  Call ARRAY INIT Subroutine for Pervasive Chiplet ...\n")


     // ARRAY INIT module -> see proc_sbe_tp_array_init.S
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
     //
        li      D1, SCAN_TP_ARRAY_INIT_REGIONS
        bsr     seeprom_array_init_module


     // Progress Indicator update
        updatestep STEP_ARRAYINIT_DONE, D0, P0


     // Step 2: Scan0 for PRV Cplt
     // ==========================
        POREVE_INF("<proc_sbe_tp_arrayinit> :  Call SCAN0 Subroutine for Pervasive Chiplet ...\n")

     // Switching on securety mask bit 9
        lpcs    P0, STBY_CHIPLET_0x00000000
        bsi     D0, OTPC_M_SECURITY_SWITCH_0x00010005, P0, BIT(9)

     // SCAN0 module -> see proc_sbe_tp_chiplet_init2.S
     //
     // At entry:
     //
     //    P1 : The chiplet ID
     //    D0 : The clock regions (to be written to Clock Controller, Clock Region Register)
     //    D1 : The scan selects  (to be written to Clock Controller, Scan Select Register)
     //
     // At exit:
     //
     //    P0, D0, D1, CTR  : destroyed
     //    P1, A0, A1       : maintained
     //
        li      D0, SCAN_TP_REGIONS_EXCEPT_PIB_PCB
        li      D1, SCAN_TP_SCAN_SELECTS
        bsr     seeprom_scan0_module

     // Switching off securety mask bit 9
        lpcs    P0, STBY_CHIPLET_0x00000000
	bci	D0, OTPC_M_SECURITY_SWITCH_0x00010005, P0, BIT(14)
        bci     D0, OTPC_M_SECURITY_SWITCH_0x00010005, P0, BIT(9)

     // Add PIBMEM back to TP array init
        bci     D0, PIBMEM_REPAIR_0x00088007, P0, BIT(63)


        POREVE_INF("<proc_sbe_tp_arrayinit> : *** End of procedure ***\n")
        .end_procedure proc_sbe_tp_arrayinit
