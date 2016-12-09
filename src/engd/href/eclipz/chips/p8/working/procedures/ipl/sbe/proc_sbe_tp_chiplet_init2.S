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
#include "proc_sbe_initf_common_seeprom.H"
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


//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

     // SCAN0 module
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


        .subroutine seeprom_scan0_module, ipl, "$Revision"
        POREVE_INF("<subroutine: scan0> : *** Subroutine SCAN0 was called ***\n")

     // Write Clock Controler, Clock Region Register, setup according to D0
        POREVE_INF("<subroutine: scan0> : Setting up Clock Regions according to D0 ...\n")
        std     D0, GENERIC_CLK_REGION_0x00030006, P1

     // Write Clock Controler, Scan Select Register, setup according to D1
        POREVE_INF("<subroutine: scan0> : Setting up Scan Selects according to D1 ...\n")
        std     D1, GENERIC_CLK_SCANSEL_0x00030007, P1

     // If P1 is a multicast write group, set P0 to the matching AND-combine
     //   read group, otherwise simply set P0 = P1. Polling uses P1 as chiplet ID
        POREVE_INF("<subroutine: scan0> : Start polling for SCAN0 complete ...\n")

        mr      D0, P1
        mr      P0, P1
        andi    D0, D0, 0x0000000000000078
        cmpibrane D0, osm_start_scan0, 0x0000000000000068

        POREVE_INF("<subroutine: scan0> : *INFO* This is a multicast SCAN0 *INFO*\n")
        mr      D0, P1
        andi    D0, D0, 0x000000000000005f
        mr      P0, D0

osm_start_scan0:

     // Trigger Start of SCAN0 execution (set OPCG CTL0 register bit 2 = '1')
        POREVE_INF("<subroutine: scan0> : Triggering SCAN0 execution ...\n")
        ld      D0, GENERIC_OPCG_CNTL0_0x00030002, P0                                     //AK-WAFER was bsi/bci
        andi    D0, D0, ~BIT(0)                                                           //AK-WAFER was bsi/bci
        ori     D0, D0, BIT(2)                                                            //AK-WAFER was bsi/bci
        std     D0, GENERIC_OPCG_CNTL0_0x00030002, P1                                     //AK-WAFER was bsi/bci

     // Poll OPCG done bit to check for scan0 completeness
        pollbitset D1, GENERIC_GP1_0x00000001, P0, 15, 1000, 800, osm_poll_failed
        bra     osm_poll_done

osm_poll_failed:

     // Stopping the SBE due to a scan0 polling threshold
        reqhalt RC_SBE_SCAN0_DONE_POLL_THRESHOLD

osm_poll_done:

     // When 'done', then clear clock region register and scan select register
        POREVE_INF("<subroutine: scan0> : SCAN0 completed, clearing Clock Regions and Scan Selects ...\n")
        sti     GENERIC_CLK_REGION_0x00030006, P1, 0x0000000000000000
        sti     GENERIC_CLK_SCANSEL_0x00030007, P1, 0x0000000000000000

        POREVE_INF("<subroutine: scan0> : *** Subroutine SCAN0 ends ***\n")

        .end_subroutine seeprom_scan0_module


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

        .procedure proc_sbe_tp_chiplet_init2, ipl, "$Revision: 1.28 $"
        POREVE_INF("<proc_sbe_tp_chiplet_init2> : *** Scan Initialization of Pervasive Chiplet (SCAN0 and Scan Repair) ***\n")


tci2_setup:

// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************

     // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

     // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P1, TP_CHIPLET_0x01000000

     // Setup OCI_BASE_ADDR1; points to PRV Cplt Scan Location Vector
        li      A1, 0x0000000100000810

tci2_start:


     // Initialize Hangcounter 6 for PRV Chiplet
        POREVE_INF("<proc_sbe_tp_chiplet_init2> : Initializing Hangcounter 6 for PRV Cplt. ...\n")
        sti     TP_HANG_P6_0x010F0026, P1, 0x0c00000000000000


     // Scan Repair, Time and GPTR for PRV Cplt
     // =======================================
        POREVE_INF("<proc_sbe_tp_chiplet_init2> : Scan in GPTR/Time/Repair rings for PERV ...\n")

     // *********************************************************
     // ***     Shift GPTR, Repair, Time rings                ***
     // *********************************************************

        lpcs    P0, TP_CHIPLET_0x01000000
	load_ring perv_gptr_perv skipoverride=1
	load_ring perv_gptr_occ  skipoverride=1
	load_ring perv_time      skipoverride=1
	load_ring perv_repr      skipoverride=1

        POREVE_INF("<proc_sbe_tp_chiplet_init2> : *** End of procedure ***\n")
        .end_procedure proc_sbe_tp_chiplet_init2

