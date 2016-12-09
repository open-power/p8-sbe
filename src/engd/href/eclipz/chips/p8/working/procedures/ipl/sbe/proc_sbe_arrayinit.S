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


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_arrayinit, ipl, "$Revision: 1.20 $"
        POREVE_INF("<proc_sbe_arrayinit> : *** Array Init and Scan0 Cleanup for good Chiplets ***\n")


cai_setup:

// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************

     // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

     // Setup PRV_BASE_ADDR1; points to MC group 3 (all chiplets except PRV)
        ls      P1, SCAN_CHIPLET_GROUP3

cai_start:

     // Step 1: Array Init for good Chiplets except PRV (MC Group 3)
     // ============================================================
        POREVE_INF("<proc_sbe_arrayinit> : MC Group 3: Calling Array Init Subroutine ...\n")

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
        li      D1, SCAN_ALLREGIONEXVITAL
        bsr     seeprom_array_init_module

     // Step 2: Scan0 for good Chiplets except PRV (MC Group 3)
     // =======================================================
        POREVE_INF("<proc_sbe_arrayinit> : MC Group 3: Calling Scan0 Subroutine ...\n")

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
        li      D0, SCAN_ALLREGIONEXVITAL
        li      D1, SCAN_ALLSCANEXPRV
        bsr     seeprom_scan0_module


        POREVE_INF("<proc_sbe_arrayinit> : *** End of Procedure ***\n")
        .end_procedure proc_sbe_arrayinit
