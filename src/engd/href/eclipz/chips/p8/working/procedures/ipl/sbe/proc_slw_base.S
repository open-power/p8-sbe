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




//
//------------------------------------------------------------------------------
// Includes
//------------------------------------------------------------------------------
        .nolist
#include "p8_sbe.H"
#include "p8_slw.H"
#include "proc_slw.H"
#include "common_ecids.H"

        .list

##`#include<stdio.h>
##`static int transition_number;
##`static int sprg_transition_number;


//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .oci			// This code runs from OCI space to access SLW image
        .rt_text

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

        // Configurable data

        // Cycles of the SLW engine that gives ~1ms delay.  This is set by
        // proc_slw_build based upon the Nest Frequency attribute.

        //  perv_clk    = 1ms * 1000000ns/ms * Nest F (GHz) / 4
        //  ex:  for Nest at 2.4GHz, 1000000 * 2.4 / 4 -> 600000
        //
        //  perv_clk    = 1ms * 1000us/ms * Nest F (MHz) / 4
        //  ex:  for Nest at 2.4GHz, 1000 * 2400 / 4 -> 600000
        //
        //  for sim, set to 16 for a small but not immediate value

        .xip_quad slw_1ms_delay, 16

        // Error injection locations
slw_invalid_instr:
        .long   0x0B000000           // Invalid instruction ("other" class)
        .long   0xFFFFAAAA           // RC word


        // A handler for command termination. If 0, then no handler exists and
        // PORE-SLW simply halts at the exit of each command. When the PORE
        // thread scheduler (PTS) is enabled this will contain the entry point
        // _ptsEntryFromSlw.

        .xip_quad slw_terminator, 0


//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

      /// Macro to condense the calling of individual transition procedures
      .macro slw_transition, type:req

        .global \type\()_ptr
\type\()_ptr:
				
				// Time stamp idle entry a(Soon)ap.
				la			A0, idle_transition_count+0 // Load the generic counter.
        ld      D0, 0, A0
        braz    D0, 1f
        la      A1, idle_transition_count+8 // Load check [read] cntr.
        ld      D1, 0, A1
        adds    D1, D1, 1
        std     D1, 0, A1
        bra     2f
1:
        adds    D0, D0, 1
        std     D0, 0, A0
2:
				la			A0, idle_transition_ts+0*8  // Load the timestamp counter.
				lpcs		P1, TOD_VALUE_REG_00040020
				ld			D0, TOD_VALUE_REG_00040020, P1
				srdi		D0, D0, 4 								// Right-align TOD and shift out WOF.
        ldandi  D1, 0, A0, BITS(0,4)      // Make copy of first nipple in ts cntr.
        braz    D0, 1f
        ori     D1, D1, BIT(3)            // Indicate TOD was non-zero at least once.
        or      D0, D0, D1
				std 		D0, 0, A0 								// Store idle start timestamp.
        bra     2f
1:
        ori     D1, D1, BIT(2)            // Indicate TOD was zero at least once.
        std     D1, 0, A0
2:

        // Call the POREVE breakpoint function to allow hardware state to
        // extracted
        bsr     slw_poreve_breakpoint

        // Set the Error Mask for SLW.  This will disable the error vectors to
        // halt immediately for hardware detected events.
        li      D0, SLW_ERROR_MASK
        mr      EMR, D0

        // Disable the interruptible function of the SLW engine
        lpcs    P1, PORE_SLW_CONTROL_0x00068001
        ld      D0, PORE_SLW_CONTROL_0x00068001, P1
        andi    D0, D0, ~(BIT(13)|BIT(15))
        std     D0, PORE_SLW_CONTROL_0x00068001, P1

        // Decode the start vector in ETR (encoded) and put into a transition
        // vector in SPRG0
        bsr     slw_load_sprg0

        POREVE_INF("Setup the multicast group and set the atomic lock")
        // Setup P0 with the MC setup
	      bsr     proc_slw_prolog

        POREVE_INF("Setup the SPRG0 with Power Enable bits")
        // Requires P0 to be established. Sets P1 to read-or mc.
        bsr     slw_load_sprg0_pwr_en

        // SW243754 (superseeds SW237989)
        //      -->  Save CHTM mode reg on any idle entry,  and
        //           Restore CHTM mode reg on any idle exit.
        // SW237325: Clear 0x10011000(4) CHTM IMA (in-memory trace) on any sleep entry.
        
        mr      D0, SPRG0           // Get SPRG
        andi    D0, D0, (SLW_SPRG0_TV_FSE_MASK|SLW_SPRG0_TV_DSE_MASK) // Mask for sleep entry
        //andi    D0, D0, (SLW_SPRG0_TV_ANYENTRY_MASK) // Mask for any entry
        braz    D0, 1f              // Skip if not an entry.

        // CHTM save and modify - Begin
        
        mr      D1, ETR
        ls      P1, CHIPLET0
        ls      CTR, MAX_CORES
        la      A0, chtm_mode_reg   // Load base chtm mode addr 
        bra     \type\()_end_loop_chtm1

\type\()_begin_loop_chtm1:
        andi    D0, D1, (BIT(32))
        braz    D0, \type\()_cont_loop_chtm1

        // Read, save and modify CHTM mode reg
        ld      D0, EX_CHTM_MODE_REG_0x10011000, P1
        std     D0, 0, A0           // Save chtm mode reg in sram
        andi    D0, D0, ~(BIT(4))   // Clear ima bit4
        std     D0, EX_CHTM_MODE_REG_0x10011000, P1

\type\()_cont_loop_chtm1:
        rols    D1, D1, 1
        adds    P1, P1, 1
        adds    A0, A0, 8           // Incr chtm mode addr

\type\()_end_loop_chtm1:
        loop    \type\()_begin_loop_chtm1

        // CHTM save and modify - End
1:

        // call the procedure to handle the transition, and skip error checks.
        .callproc \type  skiperrorchecks=1
\type\()_exit:

        // SW243754 (superseeds SW237989): 
        //           Save CHTM mode reg on any idle entry,  and
        //      -->  Restore CHTM mode reg on any idle exit.

        mr      D0, SPRG0           // Get SPRG
        andi    D0, D0, (SLW_SPRG0_TV_FSX_MASK|SLW_SPRG0_TV_DSX_MASK) // Mask for sleep exit
        //andi    D0, D0, (SLW_SPRG0_TV_ANYEXIT_MASK) // Mask for any exit
        braz    D0, 2f              // Skip if not an exit.

        // CHTM restore - Begin
        
        mr      D1, ETR
        ls      P1, CHIPLET0
        ls      CTR, MAX_CORES
        la      A0, chtm_mode_reg   // Load base chtm mode addr 
        bra     \type\()_end_loop_chtm2

\type\()_begin_loop_chtm2:
        andi    D0, D1, (BIT(32))
        braz    D0, \type\()_cont_loop_chtm2

        ld      D0, 0, A0           // Get original chtm mode reg from sram
        std     D0, EX_CHTM_MODE_REG_0x10011000, P1

\type\()_cont_loop_chtm2:
        rols    D1, D1, 1
        adds    P1, P1, 1
        adds    A0, A0, 8           // Incr chtm mode addr

\type\()_end_loop_chtm2:
        loop    \type\()_begin_loop_chtm2

        // CHTM restore - End
2:
                                                
        // \Workaround for HW221998 (PMC Timeout Precounter)
        // Set the PORRS_RECOVERY_WRITE bit (21)
        // Get the ECID to apply this to only Murano DD1.x 
        lpcs    P1, STBY_CHIPLET_0x00000000
        ldandi  D1, PCBMS_DEVICE_ID_0x000F000F, P1, BITS(0, 32)
        andi    D0, D1, CFAM_CHIP_ID_CHIP_MAJOR_MASK
        cmpibrane   D0, 1f, CFAM_CHIP_ID_MURANO_1
        
        // read exe trigger into scratch, clear return code bits
        mr      D1, ETR
        andi    D1, D1, SLW_ETR_STATUS_CLEAR
        ori     D1, D1, BIT(21)
        bra     2f

        // \Workaround end

1:
        // read exe trigger into scratch, clear return code bits
        mr      D1, ETR
        andi    D1, D1, SLW_ETR_STATUS_CLEAR

2:
        POREVE_INF("Writing PMC Status Register                 0x%016llX",
                        io_pore.d1.read())
        // write exe trigger value to PMC
        la      A0, OCI_PMC_PORE_REQ_STAT_REG_0x40010480
        std     D1, 0, A0

				// Time stamp idle exit a(Late)ap.
				la			A0, idle_transition_ts+1*8  // Load the timestamp counter.
				lpcs		P1, TOD_VALUE_REG_00040020
				ld			D0, TOD_VALUE_REG_00040020, P1
				srdi		D0, D0, 4 								// Right-align TOD and shift out WOF.
				std 		D0, 0, A0 								// Store idle exit timestamp.

				// Time stamp idle exit a(Late)ap - overhead.
				la			A0, idle_transition_ts+2*8  // Load the timestamp counter.
				lpcs		P1, TOD_VALUE_REG_00040020
				ld			D0, TOD_VALUE_REG_00040020, P1
				srdi		D0, D0, 4 								// Right-align TOD and shift out WOF.
				std 		D0, 0, A0 								// Store idle exit timestamp.

        // Check if the master error injection bit is on
        lpcs    P1, PROC_SLW_ERRINJ_MASTER_ADDR
        ldandi  D0, PROC_SLW_ERRINJ_MASTER_ADDR, P1, PROC_SLW_ERRINJ_MASTER_BIT
        braz    D0, 1f

        // ------------------------------
        // Never reaches halt after update to PMC status reg.
        ifslwcntlbitclr PROC_SLW_ERRINJ_NEVER_REACH_HALT, 1f
        waits 0xffffff
        .long RC_SLW_ERRINJ_NEVER_REACH_HALT

1:
        // If a common routine has been specified to handle command
        // termination, call it.  Otherwise halt. When the PORE thread
        // scheduler (PTS) is enabled slw_terminator will contain the
        // entry point _ptsEntryFromSlw. The slw_terminator entry point does
        // not (must not) return.

        la      A0, slw_terminator
        ld      D0, 0, A0
        braz    D0, 2f
        brad    D0

2:
        // No other handler exists, so halt
        halt
        
        // The following nop will be the address that the SLW PC will point to
        // upon success if no slw_terminator is defined.
        .global \type\()_good_halt
\type\()_good_halt:        
        .xip_address \type\()_good_halt
        nop

      .endm

///------------------------------------------------------------------------------
///  Update Exit Count
///
///  This routine updates the relevant counter location in the PIBMEM.
///


      .macro  slw_count, transition:req
/*
        .pibmem_port (PORE_SPACE_PIBMEM & 0xf)

        lpcs    (\px), PIBMEM0_0x00080000
        ld      D0, (\transition), (\px)
        adds    D0, D0, 1
        std     D0, (\transition), (\px)
*/

        // save away A0
        mr      D0, A0
        la      A0, slw_a0_sr
        std     D0,0, A0

        la      A0, (\transition)
        ld      D0, 0, A0
        adds    D0, D0, 1
        std     D0, 0, A0

        // restore A0
        la      A0, slw_a0_sr
        ld      D1, 0, A0
        mr      A0, D1

      .endm


//------------------------------------------------------------------------------
// Procedures
//------------------------------------------------------------------------------
//
// Create the callprocs for all 8 transition types
//
//------------------------------------------------------------------------------

        slw_transition slw_fast_sleep_enter 	// fse
        slw_transition slw_fast_sleep_exit		// fsx
        slw_transition slw_fast_winkle_enter	// fwe
        slw_transition slw_fast_winkle_exit 	// fwx
        slw_transition slw_deep_sleep_enter 	// dse
        slw_transition slw_deep_sleep_exit		// dsx
        slw_transition slw_deep_winkle_enter	// dwe
        slw_transition slw_deep_winkle_exit 	// dwx


//------------------------------------------------------------------------------
// Fast Sleep Enter
//
//  Register setup:
//      SPRG0:      Setup with the the transition vector

        .set FSE_STEP_MULTICAST_SETUP,      0x0
        .set FSE_STEP_POWER_OFF,            0x1
        .set FSE_STEP_CLEAR_ATOMIC_LOCK,    0x2
        .set FSE_STEP_BABY_STEP_SYNC,       0x3
        .set FSE_STEP_GOTO_CHECK,           0x4
        .set FSE_STEP_GOTO_IDLE,            0x5
        .set FSE_STEP_MULTICAST_TEARDOWN,   0x6

	    .procedure slw_fast_sleep_enter, slw, "$Revision: 1.39 $"

        POREVE_INF("## ---- Start Enter fast sleep. \n ")

        ##@ transition_number = 0; return hookOk;

        POREVE_INF("SLW calling Check Goto.")
        updatestep FSE_STEP_GOTO_CHECK, D0, P1
        li        D1, WAIT_FOR_PORE_DONE
        bsr       slw_check_goto
        branz     D1, fse_exit

	    	POREVE_INF("SLW setting ETR bits for Sleep transition")
        setsleep  D0

	    	// Perform the power transition.  With assisted PFET control, chiplets
        // are done serially (without multicast) for di/dt mananagment.
        // Considers iVRM enablement as to the means to use (babystepper
        // of PFET controller).
        // SPRG0 e has the transition vector
        updatestep FSE_STEP_POWER_OFF, D0, P1
	      bsr slw_power_on_off

        // Clear the atomic lock
        updatestep FSE_STEP_CLEAR_ATOMIC_LOCK, D0, P1
        sti PCBS_ATOMIC_LOCK_0x100F03FF, P0, CLEAR_ATOMIC_LOCK_DATA

        POREVE_INF("SLW DSE GOTO PCBS_GOTO_IDLE")
        updatestep FSE_STEP_GOTO_IDLE, D0, P1
        sti EX_IDLEGOTO_0x100F0114, P0, PCBS_GOTO_IDLE

        POREVE_INF("Tear down the multicast group")
        updatestep FSE_STEP_MULTICAST_TEARDOWN, D0, P1
fse_exit:
        bsr proc_slw_epilog

	    .end_procedure slw_fast_sleep_enter

//------------------------------------------------------------------------------
// Deep Sleep Enter

// TODO:  OCC execution hook for notification of Deep enter
        .set DSE_STEP_POWER_OFF,            0x1
        .set DSE_STEP_CLEAR_ATOMIC_LOCK,    0x2
        .set DSE_STEP_BABY_STEP_SYNC,       0x3
        .set DSE_STEP_GOTO_CHECK,           0x4
        .set DSE_STEP_GOTO_IDLE,            0x5
        .set DSE_STEP_MULTICAST_TEARDOWN,   0x6

	    .procedure slw_deep_sleep_enter, slw, "$Revision: 1.39 $"

				// Time stamp entry.
				la			A0, idle_transition_ts+12*8  // Load the timestamp counter.
				lpcs		P1, TOD_VALUE_REG_00040020
				ld			D0, TOD_VALUE_REG_00040020, P1
				srdi		D0, D0, 4 								// Right-align TOD and shift out WOF.
				std 		D0, 0, A0 								// Store entry timestamp.

	      POREVE_INF("## ---- Start Enter deep sleep. \n ")

        ##@ transition_number = 1; return hookOk;

        POREVE_INF("SLW calling Check Goto.")
        updatestep DSE_STEP_GOTO_CHECK, D0, P1
        li        D1, WAIT_FOR_PORE_DONE
        bsr       slw_check_goto
        branz     D1, dse_exit

        POREVE_INF("SLW setting ETR bits for Sleep transition")
        setsleep  D0

	      // Perform the power transition.  With assisted PFET control, chiplets are done
	      // serially (without multicast) for di/dt mananagment
        // Considers iVRM enablement as to the means to use (babystepper
        // of PFET controller).
        updatestep DSE_STEP_POWER_OFF, D0, P1
	      bsr slw_power_on_off

power_complete_dse:

        // Clear the atomic lock
        updatestep DSE_STEP_CLEAR_ATOMIC_LOCK, D0, P1
        sti PCBS_ATOMIC_LOCK_0x100F03FF, P0, CLEAR_ATOMIC_LOCK_DATA

        POREVE_INF("SLW DSE GOTO PCBS_GOTO_IDLE")
        updatestep DSE_STEP_GOTO_IDLE, D0, P1
        sti EX_IDLEGOTO_0x100F0114, P0, PCBS_GOTO_IDLE

        POREVE_INF("Tear down the multicast group")
        updatestep DSE_STEP_MULTICAST_TEARDOWN, D0, P1
dse_exit:
        bsr proc_slw_epilog

				// Time stamp exit.
				la			A0, idle_transition_ts+13*8  // Load the timestamp counter.
				lpcs		P1, TOD_VALUE_REG_00040020
				ld			D0, TOD_VALUE_REG_00040020, P1
				srdi		D0, D0, 4 								// Right-align TOD and shift out WOF.
				std 		D0, 0, A0 								// Store exit timestamp.

	    .end_procedure slw_deep_sleep_enter

//------------------------------------------------------------------------------
// Fast Sleep Exit

	    .procedure slw_fast_sleep_exit, slw, "$Revision: 1.39 $"

	      POREVE_INF("## ---- Start Exit fast sleep. \n ")

        ##@ transition_number = 2; return hookOk;

        POREVE_INF("SLW calling Check Goto.")
        li        D1, SLEEP_EXIT_WAIT_PORE_GOTO_CMD
        bsr       slw_check_goto
        branz     D1, fsx_exit

        POREVE_INF("SLW setting ETR bits for Sleep transition")
        setsleep  D0

	      // Perform the power transition.  With assisted PFET control, chiplets
        // are done serially (without multicast) for di/dt mananagment.
        // Considers iVRM enablement as to the means to use (babystepper
        // of PFET controller).
	      bsr slw_power_on_off

        // Clear the atomic lock
        sti PCBS_ATOMIC_LOCK_0x100F03FF, P0, CLEAR_ATOMIC_LOCK_DATA

        POREVE_INF("SLW PFET On/Off Storing GOTO PCBS_GOTO_SLEEP_CONT")
        sti EX_IDLEGOTO_0x100F0114, P0, PCBS_GOTO_SLEEP_CONT

        POREVE_INF("Log the event in the SRAM count location")
        slw_count slw_fast_sleep_count

 	      POREVE_INF("Tear down the multicast group")
fsx_exit:
	      bsr proc_slw_epilog

	    .end_procedure slw_fast_sleep_exit

//------------------------------------------------------------------------------
// Deep Sleep Exit

	    // Declare the enter point using the .procedure macro.
	    // This create TOC entries as well as name space

	    .procedure slw_deep_sleep_exit, slw, "$Revision: 1.39 $"

				// Time stamp entry.
				la			A0, idle_transition_ts+14*8  // Load the timestamp counter.
				lpcs		P1, TOD_VALUE_REG_00040020
				ld			D0, TOD_VALUE_REG_00040020, P1
				srdi		D0, D0, 4 								// Right-align TOD and shift out WOF.
				std 		D0, 0, A0 								// Store entry timestamp.

		    POREVE_INF("## ---- Start Exit deep sleep. \n ")

        ##@ transition_number = 3; return hookOk;

        POREVE_INF("SLW calling Check Goto.")
        li        D1, SLEEP_EXIT_WAIT_PORE_GOTO_CMD
        bsr       slw_check_goto
        branz     D1, dsx_exit

        POREVE_INF("SLW setting ETR bits for Sleep transition")
        setsleep  D0

//        bsr proc_slw_check_idle_state

        POREVE_INF("Perform the power transition")
        // With assisted PFET control, chiplets are done
	      // serially (without multicast) for di/dt mananagment
        // Considers iVRM enablement as to the means to use (babystepper
        // of PFET controller).
	      bsr slw_power_on_off

power_complete_dsx:

        POREVE_INF("SLW Set special wake-up via override in PMGP1")
        bsr slw_special_wakeup_override_set

        POREVE_INF("SLW calling EX_INIT. \n ")
	      bra_proc_idle proc_sbe_run_exinit, sleep
        
				bsr slw_ivrm_calibration

// CMO-20130906 - CPM FW is ready. Uncomment next four lines when HW is ready.
//        POREVE_INF("Installing and enabling CPM calibration data.")
//        // Special wakeup MUST be set ahead of the following two calls.
//        bsr  proc_cpm_cal_install
//        bsr  proc_cpm_enable

        // The GOTO is hit BEFORE getting the core established (prestart)
        // and released for processing (clear_maint) so that there is no
        // race between the OHA/PCBS and the next idle operation
        
        POREVE_INF("SLW DSE GOTO PCBS_GOTO_SLEEP_CONT")
        sti EX_IDLEGOTO_0x100F0114, P0, PCBS_GOTO_SLEEP_CONT
        
        // Poll on wake-up is done
        setp1_mcreadand D0
        pollbitset  D0, EX_OHA_RO_STATUS_REG_0x1002000B, P1, \
                        1, \
                        SLW_OHA_SPWKUP_POLLS, \
                        SLW_OHA_SPWKUP_POLL_DELAY, \
                        oha_spwup_timeout
/* CMO-20131021 - Moved to proc_slw_ram.S
        POREVE_INF("Prestart the threads (PC) in sleep")
        bsr slw_pc_prestart_sleep
*/
/* CMO-20131021 - Moved to proc_slw_ram.S
        POREVE_INF("Restoring the threads into their proper pre-sleep entry state")
        bsr proc_slw_sleep_thread_restore
*/
        
        // SW247821: Moved here to clear the race of hypervisor setting up timebase.
        // Clear the atomic lock
        sti PCBS_ATOMIC_LOCK_0x100F03FF, P0, CLEAR_ATOMIC_LOCK_DATA

        POREVE_INF("SLW calling PC Clear Maintenance mode")
        bsr slw_pc_clear_maint

        // Time stamp FSM exit.
				la			A0, idle_transition_ts+15*8  // Load the timestamp counter.
				lpcs		P1, TOD_VALUE_REG_00040020
				ld			D0, TOD_VALUE_REG_00040020, P1
				srdi		D0, D0, 4 								// Right-align TOD and shift out WOF.
				std 		D0, 0, A0 								// Store exit timestamp.

        // Clear the atomic lock (old location)
        //sti PCBS_ATOMIC_LOCK_0x100F03FF, P0, CLEAR_ATOMIC_LOCK_DATA

        POREVE_INF("SLW Clear special wake-up via override in PMGP1")
        // Special wake-up must be cleared after SCOM accesses to the
        // core or else the SCOMs will fail as PC will return to NAP
        // which shuts off the clocks for the SCOM
        bsr slw_special_wakeup_override_clear

        POREVE_INF("SLW Clearing ETR Idle bits")
        clearidle D0

        POREVE_INF("Log the event in the SRAMcount location")
        slw_count slw_deep_sleep_count

	      POREVE_INF("Tear down the multicast group")
dsx_exit:
	      bsr proc_slw_epilog

	    .end_procedure slw_deep_sleep_exit
        
oha_spwup_timeout:
        POREVE_ERR("SLW OHA Special Wake-up Timeout for Deep Sleep")
        reqhalt SLW_RC_OHA_SPWUP_TIMEOUT

//------------------------------------------------------------------------------
// Fast Winkle Enter

        .set FWE_STEP_POWER_OFF,            0x1
        .set FWE_STEP_CLEAR_ATOMIC_LOCK,    0x2
        .set FWE_STEP_BABY_STEP_SYNC,       0x3
        .set FWE_STEP_GOTO_CHECK,           0x4
        .set FWE_STEP_GOTO_IDLE,            0x5
        .set FWE_STEP_MULTICAST_TEARDOWN,   0x6

	    .procedure slw_fast_winkle_enter, slw, "$Revision: 1.39 $"

		    POREVE_INF("## ---- Start Enter fast winkle. \n ")

        ##@ transition_number = 4; return hookOk;

        POREVE_INF("SLW calling Check Goto.")
        updatestep FWE_STEP_GOTO_CHECK, D0, P1
        li        D1, WAIT_FOR_PORE_DONE
        bsr       slw_check_goto
        branz     D1, fwe_exit

        POREVE_INF("SLW setting ETR bits for Winkle transition")
        setwinkle D0

	      // Perform the power transition.  With assisted PFET control, chiplets are done
	      // serially (without multicast) for di/dt mananagment
        // Considers iVRM enablement as to the means to use (babystepper
        // of PFET controller).
        updatestep FWE_STEP_POWER_OFF, D0, P1
  	    bsr slw_power_on_off

        // Clear the atomic lock
        updatestep FWE_STEP_CLEAR_ATOMIC_LOCK, D0, P1
        sti PCBS_ATOMIC_LOCK_0x100F03FF, P0, CLEAR_ATOMIC_LOCK_DATA

        POREVE_INF("SLW FWE GOTO PCBS_GOTO_IDLE")
        updatestep FWE_STEP_GOTO_IDLE, D0, P1
        sti EX_IDLEGOTO_0x100F0114, P0, PCBS_GOTO_IDLE

        POREVE_INF("Tear down the multicast group")
        updatestep FWE_STEP_MULTICAST_TEARDOWN, D0, P1
fwe_exit:
	      bsr proc_slw_epilog

	    .end_procedure slw_fast_winkle_enter

//------------------------------------------------------------------------------
// Deep Winkle Enter

// TODO:  OCC exectution hook for notification of Deep enter

        .set DWE_STEP_POWER_OFF,            0x1
        .set DWE_STEP_CLEAR_ATOMIC_LOCK,    0x2
        .set DWE_STEP_BABY_STEP_SYNC,       0x3
        .set DWE_STEP_GOTO_CHECK,           0x4
        .set DWE_STEP_GOTO_IDLE,            0x5
        .set DWE_STEP_MULTICAST_TEARDOWN,   0x6

 	    .procedure slw_deep_winkle_enter, slw, "$Revision: 1.39 $"

				// Time stamp entry.
				la			A0, idle_transition_ts+16*8  // Load the timestamp counter.
				lpcs		P1, TOD_VALUE_REG_00040020
				ld			D0, TOD_VALUE_REG_00040020, P1
				srdi		D0, D0, 4 								// Right-align TOD and shift out WOF.
				std 		D0, 0, A0 								// Store entry timestamp.

		    POREVE_INF("## ---- Start Enter deep winkle. \n ")

        ##@ transition_number = 5; return hookOk;

        POREVE_INF("SLW calling Check Goto.")
        updatestep DWE_STEP_GOTO_CHECK, D0, P1
        li        D1, WAIT_FOR_PORE_DONE
        bsr       slw_check_goto
        branz     D1, dwe_exit

        POREVE_INF("SLW setting ETR bits for Winkle transition")
        setwinkle D0

        // Read out and save away the High Availability (HA) address write
        // pointer from the L3. This routine will walk the chiplets individually.
//        bsr     proc_slw_ha_write_ptr_save

	      // Perform the power transition.  With assisted PFET control, chiplets
        // are done serially (without multicast) for di/dt mananagment.
        // Considers iVRM enablement as to the means to use (babystepper
        // of PFET controller).
        updatestep DWE_STEP_POWER_OFF, D0, P1
	      bsr slw_power_on_off

power_complete_dwe:

        // Clear the atomic lock
        updatestep DWE_STEP_CLEAR_ATOMIC_LOCK, D0, P1
        sti PCBS_ATOMIC_LOCK_0x100F03FF, P0, CLEAR_ATOMIC_LOCK_DATA

        POREVE_INF("SLW DWE GOTO PCBS_GOTO_IDLE")
        updatestep DWE_STEP_GOTO_IDLE, D0, P1
        sti EX_IDLEGOTO_0x100F0114, P0, PCBS_GOTO_IDLE

        POREVE_INF("Tear down the multicast group")
        updatestep DWE_STEP_MULTICAST_TEARDOWN, D0, P1
dwe_exit:
        bsr proc_slw_epilog

				// Time stamp exit.
				la			A0, idle_transition_ts+17*8  // Load the timestamp counter.
				lpcs		P1, TOD_VALUE_REG_00040020
				ld			D0, TOD_VALUE_REG_00040020, P1
				srdi		D0, D0, 4 								// Right-align TOD and shift out WOF.
				std 		D0, 0, A0 								// Store exit timestamp.

	    .end_procedure slw_deep_winkle_enter


//------------------------------------------------------------------------------
// Fast Winkle Exit	--------

        .set FWX_STEP_POWER_ON,             0x1
        .set FWX_STEP_CLEAR_ATOMIC_LOCK,    0x2
        .set FWX_STEP_BABY_STEP_SYNC,       0x3
        .set FWX_STEP_GOTO_CHECK,           0x4
        .set FWX_STEP_GOTO_IDLE,            0x5
        .set FWX_STEP_MULTICAST_TEARDOWN,   0x6

	    .procedure slw_fast_winkle_exit, slw, "$Revision: 1.39 $"

		    POREVE_INF("## ---- Start Exit fast winkle. \n ")

        ##@ transition_number = 6; return hookOk;

        POREVE_INF("SLW calling Check Goto.")
        updatestep FWX_STEP_GOTO_CHECK, D0, P1
        li        D1, WINKLE_EXIT_WAIT_PORE_GOTO_CMD
        bsr       slw_check_goto
        branz     D1, fwx_exit

        POREVE_INF("SLW setting ETR bits for Winkle transition")
        setwinkle D0

		    // Perform the power transition.  With assisted PFET control, chiplets
        // are done serially (without multicast) for di/dt mananagment.
        // Considers iVRM enablement as to the means to use (babystepper
        // of PFET controller).
        updatestep FWX_STEP_POWER_ON, D0, P1
	      bsr slw_power_on_off

        // Clear the atomic lock
        updatestep FWX_STEP_CLEAR_ATOMIC_LOCK, D0, P1
        sti PCBS_ATOMIC_LOCK_0x100F03FF, P0, CLEAR_ATOMIC_LOCK_DATA

        POREVE_INF("SLW FWX GOTO PCBS_GOTO_WINKLE_CONT")
        updatestep FWX_STEP_GOTO_IDLE, D0, P1
        sti EX_IDLEGOTO_0x100F0114, P0, PCBS_GOTO_WINKLE_CONT

        POREVE_INF("Log the event in the SRAM count location")
        slw_count slw_fast_winkle_count

        POREVE_INF("Tear down the multicast group")
        updatestep FWX_STEP_MULTICAST_TEARDOWN, D0, P1
fwx_exit:
        bsr proc_slw_epilog

	    .end_procedure slw_fast_winkle_exit

//------------------------------------------------------------------------------
// Deep Winkle Exit

        .set DWX_STEP_MULTICAST_SETUP,      0x0
        .set DWX_STEP_POWER_ON,             0x1
        .set DWX_STEP_RUNEX_INIT,           0x2
        .set DWX_STEP_PRESTART_THREADS,     0x3
        .set DWX_STEP_CLEAR_MAINT,          0x4
        .set DWX_STEP_BABY_STEP_SYNC,       0x5
        .set DWX_STEP_GOTO_CHECK,           0x6
        .set DWX_STEP_GOTO_IDLE,            0x7
        .set DWX_STEP_MULTICAST_TEARDOWN,   0x8

	    .procedure slw_deep_winkle_exit, slw, "$Revision: 1.39 $"

				// Time stamp entry.
				la			A0, idle_transition_ts+18*8  // Load the timestamp counter.
				lpcs		P1, TOD_VALUE_REG_00040020
				ld			D0, TOD_VALUE_REG_00040020, P1
				srdi		D0, D0, 4 								// Right-align TOD and shift out WOF.
				std 		D0, 0, A0 								// Store entry timestamp.

	    	POREVE_INF("## ---- Start Exit deep winkle. \n ")

        //hooki 1, 0x45657

        ##@ transition_number = 7; return hookOk;

        POREVE_INF("SLW calling Check Goto.")
        updatestep DWX_STEP_GOTO_CHECK, D0, P1
        // For Deeps, the WINKLE_POWER_UP_EN COULD be set either way
        // Use previously established SPRG0 value
        mr        D0, SPRG0
        andi      D0, D0, SPRG0_WINKLE_POWER_UP_EN_MASK
        POREVE_DBG("SLW Power Up bit: 0x%16llX", io_pore.d0.read())
        cmpibraeq D0, 1f, SPRG0_WINKLE_POWER_UP_EN_BIT
        // Code powered on
        li        D1, WINKLE_EXIT_WAIT_PORE_GOTO_CMD
        POREVE_DBG("SLW expecting WINKLE_EXIT_WAIT_PORE_GOTO_CMD Goto.")
        bra       2f
1:
        // Hardware powered on
        li        D1, WINKLE_EXIT_WAIT_FOR_PORE_DONE
        POREVE_DBG("SLW expecting WINKLE_EXIT_WAIT_FOR_PORE_DONE Goto.")
2:
        // Perform the check
        bsr       slw_check_goto
        branz     D1, dwx_exit

        POREVE_INF("SLW setting ETR bits for Winkle transition")
        setwinkle D0

        POREVE_INF("Perform the power transition")
        // With assisted PFET control, chiplets are done
	      // serially (without multicast) for di/dt mananagment
        // Uses P1 for serialization;  P0 is unmodified
        updatestep DWX_STEP_POWER_ON, D0, P1
	      bsr slw_power_on_off
				
power_complete_dwx:

        POREVE_INF("SLW Set special wake-up via override in PMGP1")
        bsr slw_special_wakeup_override_set

        POREVE_INF("SLW calling EX_INIT.")
        updatestep DWX_STEP_RUNEX_INIT, D0, P1
	    bra_proc_idle proc_sbe_run_exinit, winkle

		bsr slw_ivrm_calibration
                
// CMO-20130906 - CPM FW is ready. Uncomment next four lines when HW is ready.
//        POREVE_INF("Installing and enabling CPM calibration data.")
//        // Special wakeup MUST be set ahead of the following two calls.
//        bsr  proc_cpm_cal_install
//        bsr  proc_cpm_enable

        // Restore the High Availability (HA) address write pointer
        // to the L3.  This routine will walk the chiplets individually.
        // This must be done before instructions are started.
//        bsr     proc_slw_ha_write_ptr_restore

/* CMO-20131021 - Moved to proc_slw_ram.S
        POREVE_INF("Prestart the threads (PC) in winkle")
        updatestep DWX_STEP_PRESTART_THREADS, D0, P1
        bsr slw_pc_prestart_winkle
*/

        // Allow for start pausing to load sreset code to sync with
        // SBE deadman timer (SBE_VITAL restore during IPL) or to
        // load code into L3 for lab purposes
        bsr slw_start_pause

        // SW247821: Moved here to clear the race of hypervisor setting up timebase.
        // Clear the atomic lock
        sti PCBS_ATOMIC_LOCK_0x100F03FF, P0, CLEAR_ATOMIC_LOCK_DATA

        POREVE_INF("SLW calling PC Clear Maintenance mode")
        updatestep DWX_STEP_CLEAR_MAINT, D0, P1
        bsr slw_pc_clear_maint

				// Time stamp FSM exit.
				la			A0, idle_transition_ts+19*8  // Load the timestamp counter.
				lpcs		P1, TOD_VALUE_REG_00040020
				ld			D0, TOD_VALUE_REG_00040020, P1
				srdi		D0, D0, 4 								// Right-align TOD and shift out WOF.
				std 		D0, 0, A0 								// Store exit timestamp.

        // Clear the atomic lock (old location)
        //sti PCBS_ATOMIC_LOCK_0x100F03FF, P0, CLEAR_ATOMIC_LOCK_DATA

        POREVE_INF("SLW DWX GOTO PCBS_GOTO_IDLE")
        updatestep DWX_STEP_GOTO_IDLE, D0, P1
        sti EX_IDLEGOTO_0x100F0114, P0, PCBS_GOTO_IDLE

        POREVE_INF("SLW Clear special wake-up via override in PMGP1")
        // Special wake-up must be cleared after SCOM accesses to the
        // core or else the SCOMs will fail as PC will return to NAP
        // which shuts off the clocks for the SCOM
        bsr slw_special_wakeup_override_clear
        
        // SW254684: Clear the PMERR of induced DPLL_DCO_EMPTY error brought
        // on by the initial locking.  We do this for the following systems:
        //   Murano ==2.x
        //   Venice ==2.x
        //   Naples >=1.0
        POREVE_INF("EX Chiplet -> Clear PMErr Reg of induced DPLL DCO Empty indicator" )
        lpcs    P1, PCBMS_DEVICE_ID_0x000F000F
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P1, CFAM_CHIP_ID_MAJOR_EC_MASK
        cmpibraeq   D0, 1f,                         CFAM_CHIP_ID_MAJOR_EC_2
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P1, CFAM_CHIP_ID_CHIP_MASK
        cmpibrane   D0, 2f,                         CFAM_CHIP_ID_NAPLES
1:
        sti     EX_PMErr_REG_0x100F0109, P0, 0x0       
2:

        POREVE_INF("SLW Clearing ETR Idle bits")
        clearidle D0

        POREVE_INF("Log the event in the SRAM count location")
        slw_count slw_deep_winkle_count

        POREVE_INF("Tear down the multicast group")
        updatestep DWX_STEP_MULTICAST_TEARDOWN, D0, P1
dwx_exit:
        bsr proc_slw_epilog

        // Time stamp deep winkle exit from interrupt routine
        la      A0, idle_transition_ts+3*8  // Load the timestamp counter.
        lpcs    P1, TOD_VALUE_REG_00040020
        ld      D0, TOD_VALUE_REG_00040020, P1
        srdi    D0, D0, 4                 // Right-align TOD and shift out WOF.
        std     D0, 0, A0                 // Store idle exit timestamp.

	    .end_procedure slw_deep_winkle_exit

//------------------------------------------------------------------------------
/// Override special wake-up set
///
/// Force the hardware to think we're in special wakeup.  This does NOT influence
/// the state machines; only the wire indicating special wake-up
///
///
///  Register usage:
/// 		D0: 	Unused
/// 		D1: 	Unused
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast target
/// 		P1: 	Unused
/// 		CTR: 	Unused
///         SPRG0:  Sets 0:7 with the Transition Vector bits

      .subroutine slw_special_wakeup_override_set, slw, "$Revision: 1.39 $"

        // Set special wake-up via override in PMGP1
        // Bit 6 enables/disables override; bit 8 controls the Special Wake-up
        sti EX_PMGP1_OR_0x100F0105, P0, (BIT(6)|BIT(8))

      .end_subroutine slw_special_wakeup_override_set

//------------------------------------------------------------------------------
/// Override special wake-up clear
///
///
///  Register usage:
/// 		D0: 	Unused
/// 		D1: 	Unused
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast target
/// 		P1: 	Unused
/// 		CTR: 	Unused
///         SPRG0:  Sets 0:7 with the Transition Vector bits

      .subroutine slw_special_wakeup_override_clear, slw, "$Revision: 1.39 $"

         // \bug workaround hook to stick PC into special wake-up mode until logic is there
        hooki 0, 0xFF11

        // Clear special wake-up via override in PMGP1
        // Bit 6 enables/disables override; bit 8 controls the Special Wake-up
        sti EX_PMGP1_AND_0x100F0104, P0, ~(BIT(6)|BIT(8))

      .end_subroutine slw_special_wakeup_override_clear

/*
//------------------------------------------------------------------------------
/// PC Threads Prestart Winkle
///
/// Prime PC with the thread state for deep winkle exit.  As all threads had
/// to be in winkle to have entered winkle, all threads are primed with winkle
///
///
///  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	Temporary scratch register
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast target
/// 		P1: 	Unused
/// 		CTR: 	Unused
///         SPRG0:  Sets 0:7 with the Transition Vector bits

      .subroutine slw_pc_prestart_winkle, slw, "$Revision: 1.39 $"

        hooki 0, 0xFF10
        
        // Set regular wake-up via override in OHA 
                
        setp1_mcreadand D0
        
        // Disable the AISS to allow the override 
        ld      D0, EX_OHA_MODE_REG_RWx1002000D, P1
        andi    D0, D0, ~(BIT(1))
        std     D0, EX_OHA_MODE_REG_RWx1002000D, P0   

        // Drop PSCOM fence and set pm_wake-up to PC to allow SCOMs in the 
        // IPL "Nap" state  
        ld      D0, EX_OHA_AISS_IO_REG_0x10020014, P1
        ori     D0, D0, (BIT(15))
        andi    D0, D0, ~(BIT(21))
        std     D0, EX_OHA_AISS_IO_REG_0x10020014, P0
        
        //  Preload the last idle state
        sti     EX_PERV_TCTL0_DIRECT_0x10013000, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL1_DIRECT_0x10013010, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL2_DIRECT_0x10013020, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL3_DIRECT_0x10013030, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL4_DIRECT_0x10013040, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL5_DIRECT_0x10013050, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL6_DIRECT_0x10013060, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL7_DIRECT_0x10013070, P0, BIT(43) // set SP_PRESTART_WINKLE
       
        // Clear regular wake-up and restore PSCOM fence in OHA
				ld      D0, EX_OHA_AISS_IO_REG_0x10020014, P1
        andi    D0, D0, ~(BIT(15))
        ori     D0, D0, BIT(21)
        std     D0, EX_OHA_AISS_IO_REG_0x10020014, P0

        // Enable the AISS to allow further operation
				ld      D0, EX_OHA_MODE_REG_RWx1002000D, P1
        ori     D0, D0, (BIT(1))
        std     D0, EX_OHA_MODE_REG_RWx1002000D, P0 

	    .end_subroutine slw_pc_prestart_winkle
*/

/*
///------------------------------------------------------------------------------
/// PC Threads Prestart Sleep
///
/// Prime PC with the thread state for deep sleep exit.
///
/// For now (as was done in P7+), all the threads are put into Sleep state.
///
/// There is a pending change to read the thread state captured on Deep Sleep Entry
/// (location is TBD - either image memory or OHA register per core) and then
/// this routine will walk the chiplet vector (in ETR), read that chiplet's saved
/// state (8 bit vector indicating Sleep or Winkle per thread), and then hit either
/// bit 42 (Winkle, no its sleep) or bit 43 (Sleep, no its winkle).
///
///
///  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	Temporary scratch register
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast target
/// 		P1: 	Used to walk the chiplets in the ETR (when per thread support comes)
/// 		CTR: 	Unused
///         SPRG0:  Sets 0:7 with the Transition Vector bits

      .subroutine slw_pc_prestart_sleep, slw, "$Revision: 1.39 $"

        // Workaround hook
        hooki 0, 0xFF10
        
        //  Preload the last idle state - currently all to Sleep
        sti     EX_PERV_TCTL0_DIRECT_0x10013000, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL1_DIRECT_0x10013010, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL2_DIRECT_0x10013020, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL3_DIRECT_0x10013030, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL4_DIRECT_0x10013040, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL5_DIRECT_0x10013050, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL6_DIRECT_0x10013060, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL7_DIRECT_0x10013070, P0, BIT(42) // set SP_PRESTART_SLEEP
               
	    .end_subroutine slw_pc_prestart_sleep
*/

///------------------------------------------------------------------------------
/// Clear PC Maintenance Mode
///
///  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	Temporary scratch register
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast target
/// 		P1: 	Unused
/// 		CTR: 	Unused
///         SPRG0:  Sets 0:7 with the Transition Vector bits

      .subroutine slw_pc_clear_maint, slw, "$Revision: 1.39 $"
        
        // For Sleep, the GOTO operation to the PCBS has been done which will
        // handshake with the OHA to complete the PM logic elements.  Thus,
        // fences are already dropped so skip this for the Sleep case.
        ifsleep D0, 1f

        // For Winkle, the OHA is seeing the NAP condition for the core so fences
        // must be dropped to all SCOM to operation        

        setp1_mcreadand D0
        
        // Disable the AISS to allow the override 
        ld      D0, EX_OHA_MODE_REG_RWx1002000D, P1
        andi    D0, D0, ~(BIT(1))
        std     D0, EX_OHA_MODE_REG_RWx1002000D, P0   

        // Drop PSCOM fence and set pm_wake-up to PC to allow SCOMs in the 
        // IPL "Nap" state  
        ld      D0, EX_OHA_AISS_IO_REG_0x10020014, P1
        ori     D0, D0, (BIT(15))
        andi    D0, D0, ~(BIT(21))
        std     D0, EX_OHA_AISS_IO_REG_0x10020014, P0
				
1:

        sti     EX_PERV_TCTL0_DIRECT_0x10013000, P0, BIT(44) // set SP_CLEAR_MAINT
        sti     EX_PERV_TCTL1_DIRECT_0x10013010, P0, BIT(44) // set SP_CLEAR_MAINT
        sti     EX_PERV_TCTL2_DIRECT_0x10013020, P0, BIT(44) // set SP_CLEAR_MAINT
        sti     EX_PERV_TCTL3_DIRECT_0x10013030, P0, BIT(44) // set SP_CLEAR_MAINT
        sti     EX_PERV_TCTL4_DIRECT_0x10013040, P0, BIT(44) // set SP_CLEAR_MAINT
        sti     EX_PERV_TCTL5_DIRECT_0x10013050, P0, BIT(44) // set SP_CLEAR_MAINT
        sti     EX_PERV_TCTL6_DIRECT_0x10013060, P0, BIT(44) // set SP_CLEAR_MAINT
        sti     EX_PERV_TCTL7_DIRECT_0x10013070, P0, BIT(44) // set SP_CLEAR_MAINT

        // See comment above
        ifsleep D0, 2f

        // Clear regular wake-up and restore PSCOM fence in OHA
				// SW257003: Commenting out next four lines to ensure PSCOM fence is down to
        //           avoid race with PHYP's xscom to TOD which otherwise, sometimes,
        //           gets a chiplet offline from same core that requested the xscom.
        //ld      D0, EX_OHA_AISS_IO_REG_0x10020014, P1         
        //andi    D0, D0, ~(BIT(15))
        //ori     D0, D0, BIT(21)
        //std     D0, EX_OHA_AISS_IO_REG_0x10020014, P0

        // Enable the AISS to allow further operation
				ld      D0, EX_OHA_MODE_REG_RWx1002000D, P1
        ori     D0, D0, (BIT(1))
        std     D0, EX_OHA_MODE_REG_RWx1002000D, P0

2:

	    .end_subroutine slw_pc_clear_maint


///------------------------------------------------------------------------------
/// Check Goto
///
///  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	On input: Wait Goto state to check (pre-aligned)
///           On exit:  0: success  non-zero: fail/double entry
/// 		A0: 	Used and destroyed
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast target
/// 		P1: 	Used for MC Read AND
/// 		CTR: 	Polling counter (destroyed)


      .subroutine slw_check_goto, slw, "$Revision: 1.39 $"

				setp1_mcreadand D0

        ls CTR, PCBS_GOTO_POLLS
        POREVE_INF("SLW Check for PCBS proper WAIT GOTO state: 0x%16llX",
                        io_pore.d1.read())
        bra poll_goto_end_loop

poll_goto_loop:

        ldandi  D0, EX_PCBS_FSM_MONITOR2_REG_0x100F0171, P1, PCBS_MONITOR_IFSM_MASK
        POREVE_INF("SLW Check state:  0x%16llX", io_pore.d0.read())

        sub     D0, D0, D1
        braz    D0, poll_goto_success

        waits   PCBS_GOTO_POLL_DELAY

poll_goto_end_loop:
        loop poll_goto_loop

poll_goto_error:

				// Save away anticipated wait state.
				rols		D1, D1, 32
				mr			A0, D1
				
        // Distinguish between Murano 1.x and other systems.
				lpcs    P1, STBY_CHIPLET_0x00000000
        ldandi  D1, PCBMS_DEVICE_ID_0x000F000F, P1, BITS(0,32)
        andi    D0, D1, CFAM_CHIP_ID_CHIP_MAJOR_MASK
        cmpibraeq   D0, poll_goto_error_undo_double_entry, CFAM_CHIP_ID_MURANO_1

				// Hard fail for non-Murano-1.x systems. No timeouts tolerated.
				reqhalt RC_SLW_GOTO_TIMEOUT_ERROR

        // Special handling for Murano 1.x to handle double entry, which most
				//   likely is causing the timeout.
poll_goto_error_undo_double_entry:

				// Restore anticipated wait state.
				mr			D1, A0
				rols		D1, D1, 32
				
				// Update timeout counter for anticipated wait state.
        xori    D0, D1, WAIT_FOR_PORE_DONE              //0x000000B8
        braz    D0, 1f
        xori    D0, D1, SLEEP_EXIT_WAIT_PORE_GOTO_CMD   //0x00000140
        braz    D0, 2f
        xori    D0, D1, WINKLE_EXIT_WAIT_PORE_GOTO_CMD  //0x00000144
        braz    D0, 3f
        xori    D0, D1, WINKLE_EXIT_WAIT_FOR_PORE_DONE  //0x0000015C
        braz    D0, 4f
				reqhalt RC_SLW_GOTO_TIMEOUT_ERROR
1:
        la      A0, slw_check_goto_exhaust_count
        bra     5f
2:
        la      A0, slw_check_goto_exhaust_count+8
        bra     5f
3:
        la      A0, slw_check_goto_exhaust_count+16
        bra     5f
4:
        la      A0, slw_check_goto_exhaust_count+24
        bra     5f
5:
        ld      D0, 0, A0
        adds    D0, D0, 1
        std     D0, 0, A0

				// \Begin - Undo double entry.
				//   Note that we do not know if its a legit timeout from a single entry.
				//   We're merely assuming that it is NOT but rather from a double entry.
				//   It's OK for now, since we're making this only for Murano 1.x.
				sti     PCBS_ATOMIC_LOCK_0x100F03FF, P0, CLEAR_ATOMIC_LOCK_DATA
        ls      D1, 0x1 // Indicate rc=double entry
        bra     poll_goto_exit
				// \End - Undo double entry.

poll_goto_success:
        
        ls      D1, 0x0 // Indicate rc=success

poll_goto_exit:

	    .end_subroutine slw_check_goto


///------------------------------------------------------------------------------
/// Load SPRG0 from ETR
///
/// Called from base to establish SPRG0 with the vectorized Start Vector (eg
//  a Transition Vector (TV) from the encoded Start Vector in ETR
///
//  Prereq:     ETR     Contains the Start Vector and Chiplet Vector
///
//  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	Temporary scratch register
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Unused
/// 		P1: 	Unused
/// 		CTR: 	Unused
///         SPRG0:  Sets 0:7 with the Transition Vector bits
///                 Sets 16:31 with ETR chiplet vector

      .subroutine slw_load_sprg0, slw, "$Revision: 1.39 $"

        POREVE_INF("SLW Loading parmameters into SPRG0")

        // Decode the Start Vector in ETR and set the relevent flag in SPR0 for
        // the transition

        andi D1, D1, 0x0                         # Clear D1
        mr D0, ETR
        andi D0, D0, SLW_ETR_SV_MASK             # Mask the start vector fiel
        srdi D0, D0, SLW_ETR_SV_RALIGN64         # Shift right to low order byte
        POREVE_DBG("     SLW Load SPRG0 D0 aligned ETR          0x%016llX",
                        io_pore.d0.read())

        // Fast Sleep Entry
        cmpibrane d0, 1f, SLW_SV_FSE             # Compare code point
        ori D1, D1, SLW_SPRG0_TV_FSE_MASK        # Set D1
        POREVE_DBG("     SLW Load SPRG0 FSE detected D1")
        ##@ sprg_transition_number = 0; return hookOk;
        bra 2f
1:
        // Deep Sleep Entry
        cmpibrane D0, 1f, SLW_SV_DSE             # Compare code point
        ori D1, D1, SLW_SPRG0_TV_DSE_MASK        # Set D1
        POREVE_DBG("     SLW Load SPRG0 DSE detected")
        ##@ sprg_transition_number = 1; return hookOk;
        bra 2f
1:
        // Fast Sleep Exit
        cmpibrane D0, 1f, SLW_SV_FSX             # Compare code point
        ori D1, D1, SLW_SPRG0_TV_FSX_MASK        # Set D1
        POREVE_DBG("     SLW Load SPRG0 FSX detected")
        ##@ sprg_transition_number = 2; return hookOk;
        bra 2f
1:
        // Deep Sleep Exit
        cmpibrane D0, 1f, SLW_SV_DSX             # Compare code point
        ori D1, D1, SLW_SPRG0_TV_DSX_MASK        # Set D1
        POREVE_DBG("     SLW Load SPRG0 DSX detected")
        ##@ sprg_transition_number = 3; return hookOk;
        bra 2f
1:
        // Fast Winkle Entry
        cmpibrane D0, 1f, SLW_SV_FWE             # Compare code point
        ori D1, D1, SLW_SPRG0_TV_FWE_MASK        # Set D1
        POREVE_DBG("     SLW Load SPRG0 FWE detected")
        ##@ sprg_transition_number = 4; return hookOk;
        bra 2f
1:
        // Deep Winkle Entry
        cmpibrane D0, 1f, SLW_SV_DWE             # Compare code point
        ori D1, D1, SLW_SPRG0_TV_DWE_MASK        # Set D1
        POREVE_DBG("     SLW Load SPRG0 DWE detected")
        ##@ sprg_transition_number = 5; return hookOk;
        bra 2f
1:
        // Fast Winkle Exit
        cmpibrane D0, 1f, SLW_SV_FWX             # Compare code point
        ori D1, D1, SLW_SPRG0_TV_FWX_MASK        # Set D1
        POREVE_DBG("     SLW Load SPRG0 FWX detected")
        ##@ sprg_transition_number = 6; return hookOk;
        bra 2f
1:
        // Deep Winkle Exit
        cmpibrane D0, 1f, SLW_SV_DWX             # Compare code point
        ori D1, D1, SLW_SPRG0_TV_DWX_MASK        # Set D1
        POREVE_DBG("     SLW Load SPRG0 DWX detected")

        ##@ sprg_transition_number = 7; return hookOk;
        bra 2f
1:
        // Unsupported Start Vector
        reqhalt RC_SLW_UNDEFINED_SV
2:
        // D1 contains the transition vector

        POREVE_DBG("     SLW Load SPRG0 Transition Vector       0x%016llX",
                        io_pore.d1.read())
        andi D0, D0, 0x0                         # Clear D0
        or D0, D0, D1                            # Set TV field
        POREVE_DBG("     SLW Load SPRG0 D0 OR TV Mask           0x%016llX",
                        io_pore.d0.read())

        // Put the ETR Chiplet Vector value into SPRG0
        mr D1, ETR                               # Get the ETR (again)
        POREVE_DBG("     SLW Load SPRG0 D1 ETR                  0x%016llX",
                        io_pore.d1.read())
        andi D1, D1, SLW_ETR_CHIPLET_MASK        # Mask for the chiplet vector
        POREVE_DBG("     SLW Load SPRG0 D1 andi chplt           0x%016llX",
                        io_pore.d1.read())
        srdi D1, D1, SLW_ETR_CM_RALIGN64         # Shift right to right justify
        POREVE_DBG("     SLW Load SPRG0 D1 srdi chplt           0x%016llX",
                        io_pore.d1.read())
        or D0, D0, D1                            # Combine
        POREVE_DBG("     SLW Load SPRG0 D0 or D1                0x%016llX",
                        io_pore.d1.read())
        mr SPRG0, D0                             # Save to SPRG0
        POREVE_INF("     SLW Load SPRG0 Register Value          0x%08llX",
                        io_pore.sprg0.read())
3:
      .end_subroutine slw_load_sprg0


///------------------------------------------------------------------------------
/// Load SPRG0 with Power Enable bits from PMGP1
///
/// Called from base to establish SPRG0 with the power enables for proper
/// power control as well as GOTO checking
///
///  Prereq:     ETR     Contains the Start Vector and Chiplet Vector
///
///  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	Temporary scratch register
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Contains the targeted chiplet or MC group
/// 		P1: 	Used
/// 		CTR: 	Unused
///         SPRG0:  Sets 4 bits (2 for each Sleep and Winkle)


      .subroutine slw_load_sprg0_pwr_en, slw, "$Revision: 1.39 $"

        POREVE_INF("SLW Loading parmameters power enables into SPRG0")

        // For Deeps, the power down/up enable bits in PMGP1 COULD be set either
        // way and those setting affect both the power on/off behavior as well
        // as the GOTO checks that are performed.   Use the just built
        // transitions vectors to decide to read the values (deeps only) and
        // store them in the set aside bits in the SPRG for use later on.
        //
        // Do an MC Read AND and then a READ OR to see that all chiplets
        // are setup the same.   If they are not the same, halt as a
        // config error.
        setp1_mcreadand D0
        ldandi  D0, EX_PMGP1_0x100F0103, P1, BIT(0)|BIT(1)|BIT(3)|BIT(4)

        setp1_mcreador D1
        ldandi  D1, EX_PMGP1_0x100F0103, P1, BIT(0)|BIT(1)|BIT(3)|BIT(4)
        sub     D1, D0, D1
        braz    D1, sprg_set_power_en

        reqhalt RC_SLW_PMGP1_ENABLE_CONFIG_ERROR

sprg_set_power_en:
        POREVE_DBG("    SLW Load SPRG0 PwrEn D1             0x%016llX",
                        io_pore.d1.read())

        // Save the PMGP1 *power* bits to SPRG0.
        // Clear D1
        ls      D1, 0
        // Shift to align bit 0 with the first field bit in SPRG0
        // This happens to put the interesting bits in the lower word
        srdi    D0, D0, PMGP1_SPRG0_SLEEP_PWR_ALIGN        
        // Save value to A0 temporarily
        mr      A0, D0        
        // Mask to interesting Sleep bits
        andi    D0, D0, SPRG0_SLEEP_PWR_EN_MASK
        POREVE_DBG("    SLW Load SPRG0 PwrEn D0 Sleep bits  0x%016llX",
                        io_pore.d1.read())        
        // Put the 2 bits into D1
        or     D1, D0, D1
        POREVE_DBG("    SLW Load SPRG0 PwrEn D1 Sleep bits  0x%016llX",
                        io_pore.d1.read())                        
        // Restore the original bits from A0
        mr      D0, A0        
        // Shift D0 left by 1 to remove the Sleep Sel bit
        sldi    D0, D0, 1                
        // Mask to interesting Winkle bits
        andi    D0, D0, SPRG0_WINKLE_PWR_EN_MASK
        POREVE_DBG("    SLW Load SPRG0 PwrEn D0 Winkle bits 0x%016llX",
                        io_pore.d0.read())        
        // Put the the 2 bits into D1
        or     D1, D0, D1
        POREVE_DBG("    SLW Load SPRG0 PwrEn D1 Winkle bits 0x%016llX",
                        io_pore.d1.read())
        mr      D0, SPRG0        
        // Clear the field
        andi    D0, D0, SPRG0_PWR_EN_CLEAR
        POREVE_DBG("    SLW Load SPRG0 PwrEn Clear          0x%016llX",
                        io_pore.d0.read())                        
        // Put the new value in the field
        or      D0, D0, D1
        // Store it back
        mr      SPRG0, D0
        POREVE_DBG("    SLW Load SPRG0 PwrEn Value          0x%016llX",
                        io_pore.d0.read())

      .end_subroutine slw_load_sprg0_pwr_en


///------------------------------------------------------------------------------
///  Start pause
///
///  This routine checks the sw_control_vector bit to allow the SLW engine to take
///  a breakpoint (pause) right before the core is allowed to process pending
///  interrupts so that SRESET vector code may be loaded into L3 or Memory of the
///  chiplet that just came out of an idle (Winkle being the use case)
///
///  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	Temporary scratch register
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast target
/// 		P1: 	Used to perform an PORE_SLW self-SCOM
/// 		CTR: 	Unused
///         SPRG0:  Sets 0:7 with the Transition Vector bits

      .subroutine slw_start_pause, slw, "$Revision: 1.39 $"

        ifslwcntlbitclr PROC_SLW_DEEP_WINKLE_EXIT_PAUSE, 1f

        // Set Control Register bit 11 to enable "stop on trap"
        lpcs    P1, PORE_SLW_CONTROL_0x00068001
        ld      D0, PORE_SLW_CONTROL_0x00068001, P1
        ori     D0, D0, (BIT(11))
        std     D0, PORE_SLW_CONTROL_0x00068001, P1

        // Now that the trap is enabled to stop, execute it
        trap

        // Once restated (externally) clear Control Register bit 11 to disable
        // "stop on trap"
        andi    D0, D0, ~(BIT(11))
        std     D0, PORE_SLW_CONTROL_0x00068001, P1

1:

	    .end_subroutine slw_start_pause


///------------------------------------------------------------------------------
///  Check idle state
///
/// This routine checks whether the chiplets that are about to exit are, in fact,
/// in the correct idle state or, if about to enter are in the 'run' state.
/// This is to prevent any double executions due to PCBM Interrupt Valid issues.
///
///  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	Temporary scratch register
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast target
/// 		P1: 	Used to perform an PORE_SLW self-SCOM
/// 		CTR: 	Unused
///     SPRG0:  Sets 0:7 with the Transition Vector bits

      .subroutine slw_check_idle_state, slw, "$Revision: 1.39 $"

	    .end_subroutine slw_check_idle_state


///------------------------------------------------------------------------------
///  VirtualPORE breakpoint
///
/// Creates a common  point that all transitions will execute to allow to trap
/// SLW state from the hardware so that the image can run on the POREVE.
///
/// Externally, if CTL(11) is set, the trap will halt the hardware so that the
/// state of the SLW can be extracted.
///
///  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	Temporary scratch register
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	MC write
/// 		P1: 	Unicast read and MC read on exit.
/// 		CTR: 	Unused
///         SPRG0:  Unused

      .subroutine slw_poreve_breakpoint, slw, "$Revision: 1.39 $"

        .global slw_poreve_trap
slw_poreve_trap:

        trap

	    .end_subroutine slw_poreve_breakpoint


///------------------------------------------------------------------------------
/// iVRM Calibration
///
/// Conditions ahead of this routine:
/// Clocks must be running ahead of calling this routine.

			.subroutine  slw_ivrm_calibration, slw, "$Revision:&"         

        //
				// If iVRM enabled, do
				// 1 - calibration per chiplet
				// 2 - set and poll the ivrm bs wakeup bit4 using MC.
				//
				setp1_mcreador D0
        ldandi  D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1, BIT(0)
        braz    D0, ivrm_skip_calib_and_bs_wakeup

        POREVE_DBG("Doing iVRM calibration and BS wakeup.")

				// Prepare SPRG0 with chiplet vector
				mr			D1, ETR
				srdi		D1, D1, SLW_ETR_CM_RALIGN64
				mr			D0, SPRG0
				andi		D0, D0, SLW_SPRG0_CHIPLET_CLEAR
				or			D0, D0, D1
				mr			SPRG0, D0
        // Initialize P1 and CTR and execute the PORE for-loop paradigm
        ls  		P1, CHIPLET0
        ls  		CTR, MAX_CORES
        bra ivrm_end_loop

ivrm_chiplet_loop:
				// Check if current chiplet is to be processed.
				mr			D1, SPRG0
				andi		D1, D1, SLW_SPRG0_CHIPLET_TEST
				braz		D1, ivrm_next_loop
				
        // If iVRM enabled, do calibration
        ldandi  D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1, BIT(0)
        braz    D0, ivrm_next_loop

				//-------------------------------//
				// Calibration procedure - Start //
				//-------------------------------//
				
				la			A0, ivrm_parm+0 	// Load ivrm calib counter.
				ld 			D0, 0, A0
				adds		D0, D0, 1
				std 		D0, 0, A0 				// Incr ivrm calib counter.

				// Make sure pfet vref circuit is on.
        ld      D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1
				andi		D1, D0, BIT(3)
				branz		D1, ivrm_cal_vref_done
        ori     D0, D0, BIT(3)
        std     D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1
				la			A0, ivrm_parm+8   // Load the vref-off counter.
				ld			D0, 0, A0
				adds		D0, D0, 1
				std 		D0, 0, A0 				// Incr vref-off counter.
ivrm_cal_vref_done:
				// Whether vref was on or not, let's wait 10us since it may have 
				//   been gated by chiplet-fence.
				waits 	SLW_IVRM_CAL_VREF_DELAY
				
        // Set bit(2) to kick off iVRM calibration (binary search)
        ld      D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1
        ori     D0, D0, BIT(2)
        std     D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1

        // Check for bit(57) set to indicate iVRM calibration is done.
				// ...but first make copy of CTR since pollbit will destroy it.
				mr			A1, CTR
				ls			CTR, (SLW_IVRM_CAL_POLLS-1)
				bra 		ivrm_cal_poll_continue

ivrm_cal_poll_loop:
				waits 	SLW_IVRM_CAL_POLL_DELAY
								
ivrm_cal_poll_continue:
				ldandi	D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1, BIT(57)
				branz 	D0, ivrm_cal_poll_done
				loop  	ivrm_cal_poll_loop
				bra 		ivrm_cal_timeout

ivrm_cal_poll_done:
				// Restore various settings:
        // ...clear bit(2) to stop iVRM calibration.
        ldandi  D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1, ~BIT(2)
        std     D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1
				// ...recover chiplet counter into CTR.
				mr			CTR, A1

ivrm_next_loop:
        // Restore the working chiplet vector to D1 from SPRG0, update chiplet
				//   vector section of SPRG0 and maintain the rest of SPRG0.
        mr  		D1, SPRG0
        sldi  	D1, D1, 1
        andi  	D1, D1, SLW_SPRG0_CHIPLET_MASK
				mr			D0, SPRG0
				andi		D0, D0, SLW_SPRG0_CHIPLET_CLEAR
				or			D0, D0, D1
				mr			SPRG0, D0
				// Update pervasive reg.
        adds  	P1, P1, 1

ivrm_end_loop:
        loop ivrm_chiplet_loop

        // HW273115:  Fix for ivrm-pstate ack bug in winkle.
        //            Fast winkle entry: Do nothing to ivrm nor pfets.
        //            Fast winkle exit: Do nothing to ivrm nor pfets.
        //            Deep winkle entry: Enable force safe mode. Turn off pfets.
        //        --> Deep winkle exit: Turn on pfets. Disable force safe mode.
        la      A0, slw_control_vector
        ldandi  D0, 0, A0, BIT(63)
        braz    D0, ivrm_bs_wakeup
        mr      D1, SPRG0
        andi    D0, D1, SLW_SPRG0_TV_DWX_MASK

        branz   D0, ivrm_skip_bs_wakeup

ivrm_bs_wakeup:
				//
				// Set and poll the ivrm bs wakeup bit4.
				//
				setp1_mcreador D0
        sti EX_IDLEGOTO_0x100F0114, P0, PCBS_GOTO_IVRM_BS_TRIGGER_WAKEUP
        // Poll for bit4=0 to indicate hardware sync.
        pollbitclr  D0, \
										EX_IDLEGOTO_0x100F0114, \
										P1, \
										4, \
                		SLW_IVRM_BS_SYNC_POLLS, \
										SLW_IVRM_BS_SYNC_POLL_DELAY, \
                		ivrm_bssync_timeout

ivrm_skip_bs_wakeup:

ivrm_skip_calib_and_bs_wakeup:

			.end_subroutine  slw_ivrm_calibration


ivrm_cal_timeout:
        POREVE_ERR("SLW iVRM calibration timeout")
        reqhalt RC_SLW_IVRM_CAL_TIMEOUT

ivrm_bssync_timeout:
        POREVE_ERR("SLW Baby Stepper Exit Timeout (after ivrm calib)")
        reqhalt RC_SLW_IVRM_CAL_BS_EXIT_TIMEOUT
