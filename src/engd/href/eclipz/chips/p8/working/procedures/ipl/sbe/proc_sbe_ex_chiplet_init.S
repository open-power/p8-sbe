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
// constant declaration
//------------------------------------------------------------------------------



//------------------------------------------------------------------------------
// preprocessor directives
//------------------------------------------------------------------------------
#define SIM_PLL
#define SIM_SPEEDUP
// #define SCAN0_DISABLE
//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom

        .set STEP_CHIPLET_INIT_0,   0x0     // Resetting DPLL
        .set STEP_CHIPLET_INIT_1,   0x1     // Core+ECO glmux switch (IPL/Winkle)
        .set STEP_CHIPLET_INIT_2,   0x2     // Core glmux switch (Sleep)
        .set STEP_CHIPLET_INIT_3,   0x3     // Before Func flush for IPL/Winkle
        .set STEP_CHIPLET_INIT_4,   0x4     // After Func flush for IPL/Winkle
        .set STEP_CHIPLET_INIT_5,   0x5     // After Func flush for IPL/Winkle
        .set STEP_CHIPLET_INIT_6,   0x6     // Before Core GPTR flush for Sleep
        .set STEP_CHIPLET_INIT_7,   0x7     // After Core GPTR flush for Sleep
        .set STEP_CHIPLET_INIT_8,   0x8     // Before Core Func flush for Sleep
        .set STEP_CHIPLET_INIT_9,   0x9     // After Core Func flush for Sleep
        .set STEP_CHIPLET_INIT_A,   0xA     // Before Core Func flush for Sleep
        .set STEP_CHIPLET_INIT_B,   0xB     // After Core Func flush for Sleep
        
        .set PORE_REFCLK_CYCLES,    1       // \todo need real value for hdw
        .set DPLL_LOCK_DELAY,       8192*PORE_REFCLK_CYCLES

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_ex_chiplet_init, slw, "$Revision: 1.23 $"

        POREVE_INF("<proc_sbe_ex_chiplet_init>: Entering procedure ... \n");


    // Look for PSCOM error on any chip, fail if we find one

    // scan0 flush all configured chiplet rings except EX DPLL
    // call ex_scan0_module(  )

    ifsleep D0, sleep

    // IPL/Winkle scan flush - all except vital

       // Hook to bypass in Sim
        hooki 0, 0xFF02
        ifslwcntlbitset PROC_SLW_SKIP_FLUSH,1f          
        
        POREVE_DBG("EX Init: Scan0 Module executed: Scan all except vital, DPL, GPTR, and TIME scan chains\n");       
        updatestep STEP_CHIPLET_INIT_6, D0, P1               
        
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
        ex_scan0 SCAN_ALL_BUT_VITALDPLLGPTRTIME, SCAN_CLK_ALLEXDPLL
        .endr
      
        updatestep STEP_CHIPLET_INIT_7, D0, P1

1:         
        bra end_of_routine
sleep:

//      // Sleep GPTR flush - core only
// 
//      // This is done after the swing of the Glitchless Mux above
// 
//      // Hook to bypass in sim while providing a trace
//         hooki 0, 0xFF03
//         ifslwcntlbitset PROC_SLW_SKIP_FLUSH,1f       
//         
//         POREVE_DBG("EX Reset: Scan0 Module executed for Sleep: Scan the GPTR/TIME/REP rings\n");        
//         updatestep STEP_CHIPLET_INIT_8, D0, P1
//         
//          .rept PROC_SCAN0_GPTR_REPEAT
//         ex_scan0 SCAN_CORE_GPTR_TIME_REP, SCAN_CLK_CORE_ONLY
//         .endr
//         
//         updatestep STEP_CHIPLET_INIT_9, D0, P1
// 1:    

    // Hook to bypass in sim while providing a trace
        hooki 0, 0xFF04
        ifslwcntlbitset PROC_SLW_SKIP_FLUSH,1f

        POREVE_DBG("EX Reset: Scan0 Module executed for Sleep: Scan the all but GPTR/TIME/REP rings\n");

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
        
        updatestep STEP_CHIPLET_INIT_A, D0, P1
      
        .rept PROC_SCAN0_FUNC_REPEAT
        ex_scan0 SCAN_CORE_ALL_BUT_GPTRTIMEREP, SCAN_CLK_CORE_ONLY
        .endr
        
         updatestep STEP_CHIPLET_INIT_B, D0, P1
1:                
 
end_of_routine:
        POREVE_INF("<proc_sbe_ex_chiplet_init>: Exiting procedure ... \n");

        .end_procedure proc_sbe_ex_chiplet_init
