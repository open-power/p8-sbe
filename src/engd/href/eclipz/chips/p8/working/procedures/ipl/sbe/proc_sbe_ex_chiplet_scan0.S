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
// constant declaration
//------------------------------------------------------------------------------

// ##` fapi::ReturnCode rc_ex       ;
.set MAX_FLUSH_LOOPS, 35  // ???


// Sim flush delay calculation
// Maximum flush length = 8191
// Cache clock = 8 sim clocks (4up/4down)
// Cache clocks for full scan0 @ 1:1 scan ratio = 65528 sim cycles
//
// Nest clock = 4 sim clocks (2up/2down)
// Nest clocks to let scan0 cache_clks occur: 131056 (2x cache clocks)
//
// PORE clocks give it runs at nest_clk / 4:  32764 prv_nclks
// 
.set FLUSH_DELAY, 32764  // for scan ratio 1:1 (sim only)
//.set FLUSH_DELAY, 200000  // ??? 1ms @ 200 MHz
//------------------------------------------------------------------------------
// preprocessor directives
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom

//        .set STEP_EX_CHIPLET_SCAN0_1,   0x1
//        .set STEP_EX_CHIPLET_SCAN0_2,   0x2
//        .set STEP_EX_CHIPLET_SCAN0_3,   0x3
//        .set STEP_EX_CHIPLET_SCAN0_SIM, 0x4

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

   
/// ex_scan0_module
///
/// At entry:
///
///     D0 : The scan region
///     D1:  The clock region
/// At exit:
///
///     D0, D1, P1, CTR, A1 : Destroyed
///     P0, A0              : Maintained

        .subroutine ex_scan0_module, slw, "$Revision: 1.7 $"
        
        // Parameterization
        .set    CHIPLET_ALL_WRITE, 0x69
        .set    CHIPLET_ALL_READ_AND, 0x49
        
        
        POREVE_INF("Scan 0 mod for chiplet_id: 0x%02llX "
                 "clk_region:  0x%016llX "
                 "and scan_region: 0x%016llX\n",
                 io_pore.p0.read(), io_pore.d1.read(), io_pore.d0.read())

        // Write ClockControl, Clock Region Register per valued passed via
        // D0 and D1 respecitively.   Vital should not be included in these 
        // values but this is NOT checked here.

        std     D1, GENERIC_CLK_REGION_0x00030006, P0
        std     D0, GENERIC_CLK_SCANSEL_0x00030007, P0

//        updatestep STEP_EX_CHIPLET_SCAN0_1, D0, P1

        POREVE_INF("Option 1 : scan0 regular case executed ...\n")
      
        setp1_mcreadand D0

        ld      D0, GENERIC_OPCG_CNTL0_0x00030002, P1
        andi    D0, D0, ~(BIT(0))            // Use BIST mode
        ori     D0, D0, (BIT(2))            // RUN_SCAN0 bit
        std     D0, GENERIC_OPCG_CNTL0_0x00030002, P0

//        updatestep STEP_EX_CHIPLET_SCAN0_2, D0, P1

        POREVE_DBG("Scan 0 started by SCOM register access...\n")

        // If P0 is the multicast write group CHIPLET_ALL_WRITE, set P1 to the
        // AND-combining read group CHIPLET_ALL_READ_AND, otherwise simply set
        // P1 = P0.  Polling uses P1 as the chiplet ID.

        setp1_mcreador D0
        
        // Check if the OPCG is done with the operation by checking
        // for the "run_scan0" bit deasserting.
        pollbitclr D0, GENERIC_OPCG_CNTL0_0x00030002, P1, 2 \
                MAX_FLUSH_LOOPS, FLUSH_DELAY, poll_timeout

///        \bug this didn't work but needs to be debugged. The above works in EPM.               
///        pollbitset D0, GENERIC_GP1_0x00000001, P1, 15 
///                MAX_FLUSH_LOOPS, FLUSH_DELAY, poll_timeout
        
//        updatestep STEP_EX_CHIPLET_SCAN0_3, D0, P1

        // Write ClockControl, Clock Region Register, clear clock region
        // register

        ls     D0, 0
        std    D0, GENERIC_CLK_SCANSEL_0x00030007, P0
        std    D0, GENERIC_CLK_REGION_0x00030006, P0

        POREVE_DBG("Scan 0 finished successfully.\n")
        bra    exit

poll_timeout:
        POREVE_ERR("Gave up waiting for chiplet scan0 to finish!\n")
        reqhalt RC_SBE_EX_CHIPLET_SCAN0_TIMEOUT

exit:
        .end_subroutine ex_scan0_module
