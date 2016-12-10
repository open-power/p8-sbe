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
#include "proc_sbe_ex_chiplet_scan0.H"
#include "p8_ex_scan0_length.H"
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
        .procedure proc_sbe_ex_arrayinit, ipl, "$Revision: 1.11 $"
        POREVE_INF("<proc_sbe_ex_arrayinit> : *** Array Init and Scan0 Cleanup for EX Chiplets ***\n")


excai_setup:

// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************

     // Setup PRV_BASE_ADDR1; points to selected EX chiplet
        POREVE_INF("<proc_sbe_ex_arrayinit> : Copy selected EX info from P0 to P1 ...\n")
        mr      P1, P0

excai_start:

     // Step 1: Array Init for selected EX chiplet
     // ==========================================
        POREVE_INF("<proc_sbe_ex_arrayinit> : Calling Array Init Subroutine ...\n")

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


      ifsleep D0, excai_sleep_clk_region
        
        // IPL/Winkle
    
        // \bug Need to exclude DPLL ring for IPL/       li      D1, SCAN_ALLREGIONEXVITAL
        li      D1, SCAN_CLK_ALLEXDPLL
        bra     excai_go
        
excai_sleep_clk_region:

        // Sleep
        li      D1, SCAN_CLK_CORE_ONLY
        
excai_go:
       
        // Execute the array init
        bsr     seeprom_array_init_module

     // Restore P0 with selected EX chiplet info
        POREVE_INF("<proc_sbe_ex_arrayinit> : Copy selected EX info back from P1 to P0 ...\n")
        mr      P0, P1

     // Step 2: Scan0 for selected EX chiplet except PRV, GPTR, TIME and DPLL
     // ================================================
        POREVE_INF("<proc_sbe_ex_arrayinit> : Calling Scan0 Subroutine ...\n")

     // taken from proc_sbe_ex_chiplet_init

     ifsleep D0, excai_sleep

        // IPL/Winkle scan flush - all except vital

        // Hook to bypass in Sim
        hooki 0, 0xFF02
        ifslwcntlbitset PROC_SLW_SKIP_FLUSH,1f          
        
        POREVE_DBG("EX Init: Scan0 Module executed: Scan all except vital, DPL, GPTR, and TIME scan chains\n");       
        
        // Each scan0 will rotate the ring 8191 latches (2**13 - 1) and the 
        // the longest ring is defined by PROC_SCAN0_FUNC_REPEAT.  When the design
        // ALWAYS has all stumps less than 8191, the repeat (eg .rept) can be
        // removed.
        //
        // Implementation note:  this is not done in a loop (or included in the
        // ex_scan0_module itself) as the D0 and D1 registers are used in 
        // ex_scan0_module and there is no convenient place to temporaily store 
        // the 2-64b values values. Argueably, PIBMEM could be used for this
        // but was not utilized.
        
        .rept PROC_SCAN0_FUNC_REPEAT
        // \bug remove DPLL ring   ex_scan0 SCAN_ALL_BUT_VITALDPLLGPTRTIME, SCAN_CLK_ALL
        ex_scan0 SCAN_ALL_BUT_VITALDPLLGPTRTIME, SCAN_CLK_ALLEXDPLL
        .endr
      
1:         
        bra 2f
excai_sleep:
        // Sleep scan flush - core only

        // Hook to bypass in Sim
        hooki 0, 0xFF04
        ifslwcntlbitset PROC_SLW_SKIP_FLUSH,2f

        POREVE_DBG("EX ArrayInit: Scan0 Module executed: Scan all core chains except GPTR and TIME\n");                

        // Each scan0 will rotate the ring 8191 latches (2**13 - 1) and the 
        // the longest ring is defined by PROC_SCAN0_FUNC_REPEAT.  When the design
        // ALWAYS has all stumps less than 8191, the repeat (eg .rept) can be
        // removed.
        //
        // Implementation note:  this is not done in a loop (or included in the
        // ex_scan0_module itself) as the D0 and D1 registers are used in 
        // ex_scan0_module and there is no convenient place to temporaily store 
        // the 2-64b values values. Argueably, PIBMEM could be used for this
        // but was not utilized.
       
        .rept PROC_SCAN0_FUNC_REPEAT
        ex_scan0 SCAN_CORE_ALL_BUT_GPTRTIMEREP, SCAN_CLK_CORE_ONLY
        .endr

2:

        POREVE_INF("<proc_sbe_ex_arrayinit> : *** End of Procedure ***\n")
        .end_procedure proc_sbe_ex_arrayinit
