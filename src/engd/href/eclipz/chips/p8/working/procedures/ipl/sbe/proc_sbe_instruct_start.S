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




// Questions before final implementation:
//   1. all threads, or just T0?
//   

//------------------------------------------------------------------------------
// Includes
//------------------------------------------------------------------------------
        .nolist
#include "p8_sbe.H"
#include "p8_slw.H"
#include "proc_sbe_trigger_winkle.H"
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
// Procedure 
//------------------------------------------------------------------------------
        .procedure proc_sbe_instruct_start, ipl, "$Revision: 1.14 $"
        
        // Bring the core out of power saving mode to allow instructions to 
        // start
        POREVE_INF("Taking the core out of power save mode")           

        // PM blocks scom access because it thinks the core is napping
        POREVE_DBG("Setting special wakeup, to allow scom access to the core")
        // Force the hardware to think we're in special wakeup so the SCOMs will
        // succeed to the core due to the init state of Nap.  This does NOT 
        // influence the PM state machines; only the wire to turn clocks on 
        // to the core.
        // Bit 6 enables/disables override; bit 8 controls the Special Wake-up
        sti EX_PMGP1_OR_0x100F0105, P0, BIT(6) | BIT(8)

        // Notify the HB code (via scratch mailbox) which threads will be started
        // by the proc_sbe_trigger_winkle code
        // - Core expects all zeros for all threads, else bitmask of what to start
        // - Since I have to calculate the bitmask anyway, don't use the zero case
        // - proc_sbe_trigger_winkle_control contains the word of what not to start
        //Mask off the other bits, invert, and set bit for T0
        //The result is the threads to start
        POREVE_DBG("Setting EX scratch 7 to tell HB which threads to start") ;
        la      A0, proc_sbe_trigger_winkle_control
        ldandi  D0, 0, A0, BITS(THREAD_START_VECTOR_START, THREAD_START_VECTOR_LENGTH)
        xori    D0, D0, BITS(THREAD_START_VECTOR_START, THREAD_START_VECTOR_LENGTH)
        ori     D0, D0, BIT(THREAD_START_VECTOR_START)
        std     D0, EX_PERV_SCRATCH7_1001328A, P0

        
        POREVE_INF("Starting instructions")   
        sti     EX_PERV_TCTL0_DIRECT_0x10013000, P0, BIT(62) // set SP_START

        setp1_mcreador D1
        ld      D1, EX_PERV_TCTL0_R_STAT_0x10013002, P1      // get RAS status
        ifbitset D0, D1, 54, instr_start_maint_mode          // check maintenance mode
        ifbitclr D0, D1, 12, instr_start_thread0_not_running // check instruct op

        POREVE_INF("Started instructions")

        POREVE_DBG("Clearing special wakeup because core is now running")

        // Remove the special wakeup override to allow the core to re-enter
        // power save "nap".  This does NOT influence the PM state machines.
        // Bit 6 enables/disables override; bit 8 controls the Special Wake-up
        sti EX_PMGP1_AND_0x100F0104, P0, ~(BIT(6) | BIT(8))

        .end_procedure proc_sbe_instruct_start

//ERRORS

instr_start_spwu_failed:
        POREVE_ERR("Failed to special wakeup before instruction start")
        reqhalt RC_SBE_INSTR_START_SPWU_FAILED

instr_start_thread0_not_running:
        POREVE_ERR("Thread is still in nap/sleep/winkle") 
        // Leaves the special wake-up override in place
        reqhalt RC_SBE_INSTR_START_THREAD0_NOT_RUNNING

instr_start_maint_mode:
        POREVE_ERR("Core still in maintenance mode") 
        // Leaves the special wake-up override in place
        reqhalt RC_SBE_INSTR_START_MAINT_MODE
