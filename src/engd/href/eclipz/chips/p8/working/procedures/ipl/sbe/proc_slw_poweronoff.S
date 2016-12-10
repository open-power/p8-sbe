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



        .nolist
#include "p8_sbe.H"
#include "p8_slw.H"
        .list

#include "proc_slw.H"

// Hook includes
##`#include<stdio.h>
##`static int pfet_pollCount;
##`static int chiplets_processed;


//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
	     .oci		// This code runs from OCI space to access SLW image
         .rt_text

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

// PFVddCntlStat (0x106) layout
//   Control
//                0:1 - core_vdd_pfet_force_state 00: nop; 01: Voff; 10: Vret; 11: Von (4:5 must be 00)
//                2:3 - eco_vdd_pfet_force_state  00: nop; 01: Voff; 10: Vret; 11: Von (6:7 must be 00)
//                4         - core_vdd_pfet_val_override 0: disable; 1: enable  (0 enables 0:1)
//                5         - core_vdd_pfet_sel_override 0: disable; 1: enable        (0 enables 0:1)
//                6         - eco_vdd_pfet_val_override  0: disable; 1: enable  (0 enables 2:3)
//                7         - eco_vdd_pfet_sel_override  0: disable; 1: enable        (0 enables 2:3)
//
//  Status
//                42:45 - core_vdd_pfet_state (42: Idle; 43: Increment; 44: Decrement; 45: Wait)
//                46:49 - not relevant
//                50:53 - eco_vdd_pfet_state (50: Idle; 51: Increment; 52: Decrement; 53: Wait)
//                54:57 - not relevant

// PFVcsCntlStat (0x10E) layout
//                0:1 - core_vcs_pfet_force_state 00: nop; 01: Voff; 10: Vret; 11: Von (4:5 must be 00)
//                2:3 - eco_vcs_pfet_force_state  00: nop; 01: Voff; 10: Vret; 11: Von (6:7 must be 00)
//                4         - core_vcs_pfet_val_override 0: disable; 1: enable  (0 enables 0:1)
//                5         - core_vcs_pfet_sel_override 0: disable; 1: enable        (0 enables 0:1)
//                6         - eco_vcs_pfet_val_override  0: disable; 1: enable  (0 enables 2:3)
//                7         - eco_vcs_pfet_sel_override  0: disable; 1: enable        (0 enables 2:3)
//  Status
//                42:45 - core_vcs_pfet_state (42: Idle; 43: Increment; 44: Decrement; 45: Wait)
//                46:49 - not relevant
//                50:53 - eco_vcs_pfet_state (50: Idle; 51: Increment; 52: Decrement; 53: Wait)
//                54:57 - not relevant


//      .set PCBS_GOTO_IDLE,                            0x4000000000000000 (bits 0:1 = 0b01)
//      .set PCBS_GOTO_SLEEP_CONT,                      0x8000000000000000 (bits 0:1 = 0b10)
//      .set PCBS_GOTO_WINKLE_CONT,                     0xC000000000000000 (bits 0:1 = 0b11)


/// Note for reduced function sleep and winkle where power is not changed, goto_cmd needs to be IDLE


// Force overrides disabled -> 4:7 depending on idle operation
        .set PFET_CNTL_REMV_OVRD_SLEEP,     0x33FFFFFFFFFFFFFF      # Clear bits 0, 1, 4 and 5 (Core)
        .set PFET_CNTL_REMV_OVRD_WINKLE,    0x00FFFFFFFFFFFFFF      # Clear bits 0:7 (Core and ECO)


// PFET CNTL OR Values
//slw_pfet_cntl_loc:
//.quad   0x8000000000000000      # Fast Sleep Enter (FSE)
//.quad   0x4000000000000000      # Deep Sleep Enter (FSE)
//.quad   0xC000000000000000      # Fast Sleep Exit  (DSX)
//.quad   0xC000000000000000      # Deep Sleep Exit  (DSX)
//.quad   0xA000000000000000      # Fast Winkle Enter(FWE)
//.quad   0x5000000000000000      # Deep Winkle Enter(DWE)
//.quad   0xF000000000000000      # Fast Winkle Exit (FWX)
//.quad   0xF000000000000000      # Deep Winkle Exit (DWX)

// Test Value
//slw_test_value_loc:
//.quad   0x8000000000000000      # Fast Sleep Enter (FSE)
//.quad   0x4000000000000000      # Deep Sleep Enter (FSE)
//.quad   0x2000000000000000      # Fast Sleep Exit  (DSX)
//.quad   0x1000000000000000      # Deep Sleep Exit  (DSX)
//.quad   0x0800000000000000      # Fast Winkle Enter(FWE)
//.quad   0x0400000000000000      # Deep Winkle Enter(DWE)
//.quad   0x0200000000000000      # Fast Winkle Exit (FWX)
//.quad   0x0100000000000000      # Deep Winkle Exit (DWX)

// Idle Goto Commands for PCBS
//slw_idle_goto_cmd_loc:
//.quad   0x4000000000000000      # Fast Sleep Enter (FSE)        Go to PCBS_GOTO_IDLE
//.quad   0x4000000000000000      # Deep Sleep Enter (FSE)        Go to PCBS_GOTO_IDLE
//.quad   0x8000000000000000      # Fast Sleep Exit  (DSX)        Go to PCBS_GOTO_SLEEP_CONT
//.quad   0x4000000000000000      # Deep Sleep Exit  (DSX)        Go to PCBS_GOTO_IDLE
//.quad   0x4000000000000000      # Fast Winkle Enter(FWE)        Go to PCBS_GOTO_IDLE
//.quad   0x4000000000000000      # Deep Winkle Enter(DWE)        Go to PCBS_GOTO_IDLE
//.quad   0xC000000000000000      # Fast Winkle Exit (FWX)        Go to PCBS_GOTO_WINKLE_CONT
//.quad   0x4000000000000000      # Deep Winkle Exit (DWX)        Go to PCBS_GOTO_IDLE
// Only Fast Exits are special

// VDD/VCS Power Gate State Mask
//slw_pg_state_mask_loc:
//.quad   0x00000000003C0000      # Fast Sleep Enter (FSE)        # bits 42:45
//.quad   0x00000000003C0000      # Deep Sleep Enter (FSE)        # bits 42:45
//.quad   0x00000000003C0000      # Fast Sleep Exit  (DSX)        # bits 42:45
//.quad   0x00000000003C0000      # Deep Sleep Exit  (DSX)        # bits 42:45
//.quad   0x00000000003C03C0      # Fast Winkle Enter(FWE)        # bits 42:45; 50:53
//.quad   0x00000000003C03C0      # Deep Winkle Enter(DWE)        # bits 42:45; 50:53
//.quad   0x00000000003C03C0      # Fast Winkle Exit (FWX)        # bits 42:45; 50:53
//.quad   0x00000000003C03C0      # Deep Winkle Exit (DWX)        # bits 42:45; 50:53
// Obviously, the Core is always involved; Winkle adds ECO

// VDD Power Gate Idle State
//slw_pg_idle_state_loc:
//.quad   0x0000000000200000      # Fast Sleep Enter (FSE)        # bit 42 = 1
//.quad   0x0000000000200000      # Deep Sleep Enter (FSE)        # bit 42 = 1
//.quad   0x0000000000200000      # Fast Sleep Exit  (DSX)        # bit 42 = 1
//.quad   0x0000000000200000      # Deep Sleep Exit  (DSX)        # bit 42 = 1
//.quad   0x0000000000200200      # Fast Winkle Enter(FWE)        # bit 42 = 1; bit 50 = 1
//.quad   0x0000000000200200      # Deep Winkle Enter(DWE)        # bit 42 = 1; bit 50 = 1
//.quad   0x0000000000200200      # Fast Winkle Exit (FWX)        # bit 42 = 1; bit 50 = 1
//.quad   0x0000000000200200      # Deep Winkle Exit (DWX)        # bit 42 = 1; bit 50 = 1

 // 5 stages for Vret, 6 stages for Voff
// set wait to about delay per stage (256) * #stages = 1536
// put in extra 6000 delay for logic problem
// uint32_t pfetWait=(256*6)+6000;

        .set PFET_WAIT,         256*7

        .set PFET_SLEEP_PG_MASK,                0x00000000003C0000 # 42:45
        .set PFET_SLEEP_PG_CLEAR,               0xFFFFFFFFFFC3FFFF # 42:45


        .set PFET_WINKLE_PG_MASK,               0x00000000003C03C0 # 42:45;50:53
        .set PFET_WINKLE_PG_CLEAR,              0xFFFFFFFFFFC3FC3F # 42:45;50:53


        .set PFET_SLEEP_IDLE_STATUS_MASK,       0x0000000000200000 # 42=1
        .set PFET_WINKLE_IDLE_STATUS_MASK,      0x0000000000200200 # 42=1;50=1

//------------------------------------------------------------------------------
// Local Subroutines
//------------------------------------------------------------------------------


/// Determine the transition type
///
/// \param[in] ETR has been set with the Start Vector and Chiplet Vector
///
/// This subroutine  iterates over the set of chiplets contained in the
///  EXE_Trigger (ETR) register, bits 16:31, as written by the PMC and, if set,
///  calls slw_pfet_seq to perform the PFET sequencing.
///
///  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	Running chiplet mask
/// 		A0: 	Not used
/// 		A1: 	Not used
/// 		P0: 	Chiplet/Multicast ID pointer (unmodified)
/// 		P1: 	Chiplet ID pointer
/// 		CTR: 	Chiplet counter
///         SPRG0:  VDD or VCS rail indication for PFET subroutine
///                 Transition vector (bit vector of encoded Start Vector)
///                 Running chiplet mask save area
///

        .subroutine slw_power_on_off, slw, "$Revision: 1.13 $"

        // Determine if iVRMs are enabled.  If so, based on the transition,
        // launch each baby stepper via P0 based multicast so synchronize. 
        // Note:  if the PMGP1 *power up/ow enable bits are set, the hardware 
        // will perform the respective PFET operation as well.  The PFET control
        // code after this will respect those settings

        //--- If iVRM enabled, use the babystepper
        setp1_mcreador D0
        ldandi  D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1, BIT(0)
        braz    D0, pfet_control

        // if (entry)
        mr  		D1, SPRG0                             // Get SPRG
        andi  	D0, D1, SLW_SPRG0_TV_ANYENTRY_MASK  	// Mask for entry transitions
        branz 	D0, bssync_entry                    	// if 1, do bs_entry
				andi		D0, D1, SLW_SPRG0_TV_ANYFAST_MASK 		// else its an exit, check for fast
				branz 	D0, bssync_exit 											// if 1, do fast bs_exit
        bra   	pfet_control      		               	// else its a deep exit, skip bs.

bssync_entry:

        // Hook for sim trapping
        hooki 0, 0xFF1C

        // Use read OR to wait on all chiplets giving a "clear" indication
        setp1_mcreador D0

        // Based on the transition, provide the baby stepper with the sync value
        andi D0, D1, SLW_SPRG0_TV_ANYSLEEP_MASK   // Mask for sleep transitions
        branz D0, bssync_sleep                    // if 1, do bs_sleep
                                                  // else, do bs_winkle.

bssync_winkle:
        // HW273115:  Fix for ivrm-pstate ack bug in winkle. 
        //        --> Fast winkle entry: Do nothing to ivrm nor pfets.
        //            Fast winkle exit: Do nothing to ivrm nor pfets.
        //        --> Deep winkle entry: Enable force safe mode. Turn off pfets.
        //            Deep winkle exit: Turn on pfets. Disable force safe mode.
        la      A0, slw_control_vector
        ldandi  D0, 0, A0, BIT(63)
        braz    D0, skip_hw273115_fix1
        andi    D0, D1, SLW_SPRG0_TV_FWE_MASK
        branz   D0, exit_power_on_off
        sti     EX_PMGP1_OR_0x100F0105, P0, BIT(13)|BIT(14)
        pollbitclr D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1, 4, \
                      150000, 100, \
                                        forcesm_poll_entry_timeout
        pollbitclr D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1, 6, \
                      150000, 100, \
                                        forcesm_poll_entry_timeout
        pollbitclr D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1, 8, \
                      150000, 100, \
                                        forcesm_poll_entry_timeout
        pollbitclr D0, EX_PCBS_iVRM_Control_Status_Reg_0x100F0154, P1, 10, \
                      150000, 100, \
                                        forcesm_poll_entry_timeout
       
        // Force safe mode complete
        bra     pfet_control

skip_hw273115_fix1:

        // CMO-20130709:  work-around for baby-stepper issue
        // Set winkle power down enable temporarily
        sti     EX_PMGP1_OR_0x100F0105, P0, BIT(3)

        sti     EX_IDLEGOTO_0x100F0114, P0, PCBS_GOTO_IVRM_BS_WINKLE_ENTRY
        // Poll for the bit 3 to go to a 0 to indicate the hardware is in sync
        pollbitclr D0, EX_IDLEGOTO_0x100F0114, P1, 3 \
                SLW_IVRM_BS_SYNC_POLLS, SLW_IVRM_BS_SYNC_POLL_DELAY, \
                bssync_poll_winkle_entry_timeout

        // CMO-20130709:  work-around for baby-stepper issue
        // Clear winkle power down enable back (we got here because this bit wasn't
        // originally set)
        sti     EX_PMGP1_AND_0x100F0104, P0, ~(BIT(3))

        // Sync complete
        bra     pfet_control

bssync_sleep:
        // CMO-20130709:  work-around for baby-stepper issue
        // Set sleep power down enable temporarily
        sti     EX_PMGP1_OR_0x100F0105, P0, BIT(0)

        sti     EX_IDLEGOTO_0x100F0114, P0, PCBS_GOTO_IVRM_BS_SLEEP_ENTRY
        // Poll for the bit 2 to go to a 0 to indicate the hardware is in sync
        pollbitclr D0, EX_IDLEGOTO_0x100F0114, P1, 2 \
                SLW_IVRM_BS_SYNC_POLLS, SLW_IVRM_BS_SYNC_POLL_DELAY, \
                bssync_poll_sleep_entry_timeout

        // CMO-20130709:  work-around for baby-stepper issue
        // Clear sleep power down enable back (we got here because this bit wasn't
        // originally set)
        sti     EX_PMGP1_AND_0x100F0104, P0, ~(BIT(0))

        // Sync complete
        bra     pfet_control

bssync_exit:
        // else (exit)

        // HW273115:  Fix for ivrm-pstate ack bug in winkle. 
        //            Fast winkle entry: Do nothing to ivrm nor pfets.
        //        --> Fast winkle exit: Do nothing to ivrm nor pfets.
        //            Deep winkle entry: Enable force safe mode. Turn off pfets.
        //            Deep winkle exit: Turn on pfets. Disable force safe mode.
        la      A0, slw_control_vector
        ldandi  D0, 0, A0, BIT(63)
        braz    D0, skip_hw273115_fix2
        andi    D0, D1, SLW_SPRG0_TV_FWX_MASK
        branz   D0, exit_power_on_off
        
skip_hw273115_fix2:

        sti EX_IDLEGOTO_0x100F0114, P0, PCBS_GOTO_IVRM_BS_TRIGGER_WAKEUP
        // Poll for bit 4 to go to a 0 to indicate the hardware is in sync
        pollbitclr D0, EX_IDLEGOTO_0x100F0114, P1, 4 \
                SLW_IVRM_BS_SYNC_POLLS, SLW_IVRM_BS_SYNC_POLL_DELAY, \
                bssync_poll_exit_timeout
        // Sync complete

        //-- end of IVRM handling

pfet_control:
        //--- Deal with the PFET controller based on mode bit settings
        
        mr      D0, SPRG0                           # Get SPRG
         
        // For Fasts, these will be off (that is how this code got invoked)
        // so the PFET controls must occur.
        // if (fast)       
        andi    D1, D0, SLW_SPRG0_TV_ANYFAST_MASK   # Mask for fast transitions
        branz   D1, exit_power_on_off               # if not 0, its a fast.
                                                    # do nothing by exiting           
        
        // For Deeps, the enable COULD be set either way for exits so use the 
        // appropriate SPRG0 bit that was set based values read from PMGP1 to 
        // determine the power up action.         
        //
        // For entry, the only way this code gets executed is if the power down 
        // bit is a 0 (PCBS hardware won't send transitions to PMC without the 
        // power_down_en being 0).
        //
        // Determine whether the hardware dealt with the power with SPRG0 bits
        // setup via PMGP1 bits based on entry vs exit and then sleep vs winkle.
        // Remember, we got here only if its a Deep transition so the "ANY"
        // mask use is still valid (ie.  only Deeps will be in the ANY)      

        // if (entry)
        andi    D1, D0, SLW_SPRG0_TV_ANYENTRY_MASK  # Mask for entry transitions
        braz    D1, 1f                              # if 0, its an exit

        // For entry transitions, check the power_dn_en setting
        // if sleep
        andi    D1, D0, SLW_SPRG0_TV_ANYSLEEP_MASK  # Mask for sleep transitions
        braz    D1, 10f                             # if 0, its winkle

        // For Sleep Entry, SLEEP_POWER_DOWN
        andi    D1, D1, SPRG0_SLEEP_POWER_DOWN_EN_MASK
        braz    D1, chiplet_pfet_walk               # = 0 - code must power off
        // This transition is legal
        bra     exit_power_on_off                   # = 1 - hardware so exit
         
10:
        // else (winkle)
                             
        // For Winkle Entry, WINLKE_POWER_DOWN
        andi    D1, D0, SPRG0_WINKLE_POWER_DOWN_EN_MASK
        braz    D1, chiplet_pfet_walk               # = 0 - code must power off               
        
        // Set PMC LFIR bit 38 to indicate that this occured        
        lpcs    P1, PMC_LFIR_OR_0x01010842
        sti     PMC_LFIR_OR_0x01010842, P1, BIT(38)
        
        // As the power is already off and there is a mark on the wall as to 
        // the invalid condition, exit the poweron/off function and let the 
        // caller complete the transition normally (eg clear atomic locks, etc.) 
        // so that the chiplet can be brought back up.
        bra     exit_power_on_off                   

        // end if  (sleep vs winkle)

        // else (exit)
1:
        // For exit transitions, check the power_up_en setting
        // if sleep
        andi    D1, D0, SLW_SPRG0_TV_ANYSLEEP_MASK  # Mask for sleep transitions
        braz    D1, 10f                             # if 0, its winkle

        // For Sleep Exit, SLEEP_POWER_UP
        andi    D1, D0, SPRG0_SLEEP_POWER_UP_EN_MASK
        braz    D1, chiplet_pfet_walk               # = 0 - code must power on
        bra     exit_power_on_off                   # = 1 - hardware so exit
        // \todo check whether hardware really powered on?
        
10:
        // else (winkle)
       
        // For Winkle Entry, WINLKE_POWER_UP
        andi    D1, D0, SPRG0_WINKLE_POWER_UP_EN_MASK
        braz    D1, chiplet_pfet_walk               # = 0 - code must power on
        bra     exit_power_on_off                   # = 1 - hardware so exit
        // \todo check whether hardware really powered on?       

        // end if  (sleep vs winkle)
        // end if (entry vs exit)

chiplet_pfet_walk:
        // Process each chiplet individually
                
        .set MAX_CORES, 16
        .set CHIPLET0, 0x10

        POREVE_INF("SLW PFET On/Off Called with SPRG0           0x%08llX",
                        io_pore.sprg0.read())

        mr D1, SPRG0
        andi D1, D1, SLW_SPRG0_CHIPLET_MASK
        POREVE_DBG(">> SLW PFET On/Off D1 Chiplet Mask          0x%016llX",
                        io_pore.d1.read())

        ##`static uint32_t sprg_chiplet_vector;
        ##`static uint32_t current_chiplet_mask;
        ##`static int i, chiplets;
        ##@ // Put out the transition type
        ##@ sprg_chiplet_vector =  io_pore.sprg0.read();
        ##@ sprg_chiplet_vector =  sprg_chiplet_vector & 0x0000FFFF;
        ##@ for (i=0; i<16; i++) {
        ##@        current_chiplet_mask = sprg_chiplet_vector & 0x00008000;
        ##@        if (current_chiplet_mask > 0) {
        ##@             chiplets++;       // if hit, incr
        ##@        }
        ##@        sprg_chiplet_vector = sprg_chiplet_vector << 1;  // shift left 1
        ##@ }
        ##@ printf ("--> Hook Check: number of chiplets in vector %x\n", chiplets);
        ##@ return hookOk;

        // Initialize P1 and CTR and execute the PORE for-loop paradigm
        ls P1, CHIPLET0
        ls CTR, MAX_CORES
        bra end_loop

chiplet_loop:

        // Check to see if chiplet should be processed

        POREVE_DBG("\n");
        POREVE_DBG("SLW PFET On/Off Begin chiplet loop ctr:     0x%03llX",
                        io_pore.ctr.read());

        // Save the working chiplet vector from D1 to SPRG0 to free up D1
        mr D0, SPRG0                            # Working copy
        andi D0, D0, SLW_SPRG0_CHIPLET_CLEAR    # Clear field
        or D0, D0, D1                           # Store to field
        mr SPRG0, D0
        POREVE_DBG(">> SLW PFET On/Off SPRG0 chplt save         0x%08llX",
                        io_pore.sprg0.read())


        andi D0, D1, SLW_SPRG0_CHIPLET_TEST     # Clear all but the current
        POREVE_DBG(">> SLW PFET On/Off D0 chplt masked          0x%016llX",
                        io_pore.d0.read())
        braz D0, next_loop                      # If bit is 0, skip it

        POREVE_INF("\n");
        POREVE_INF("SLW PFET On/Off Processing chiplet          0x%02llX",
                        io_pore.p1.read());

        ##@  chiplets_processed++; return hookOk;

        // if(TESTMODE==true)
        ifslwcntlbitclr PROC_SLW_TEST_MODE, 1f

        // then
        POREVE_INF("SLW PFET On/Off TEST MODE")
        mr D0, SPRG0
        andi D0, D0, SLW_SPRG0_TV_MASK
        std D0, CORE_SCRATCH_REG0_0x10012683, P1
        POREVE_DBG(">> SLW PFET On/Off TEST MODE wrote 0x%016llX to"
                " CORE_SCRATCH_REG0_0x10012683 with P1 of       0x%02llX ",
                io_pore.d0.read(), io_pore.d0.read() )
        bra next_loop
1:
        // else

        // if (entry)
        mr D0, SPRG0                            # Get SPRG
        li D1, SLW_SPRG0_TV_ANYENTRY_MASK
        andi D0, D0, SLW_SPRG0_TV_ANYENTRY_MASK # Mask for entry transitions
        braz D0, 2f                             # if 0, its an exit

        // Hook for sim trapping
        hooki 0, 0xFF1C

        //--- For entry transitions, power down VDD first, then VCS

        POREVE_DBG("\n");
        POREVE_INF("SLW PFET power down VDD")

        POREVE_DBG("\n");
        POREVE_INF("SLW PFET power down VDD")
        // Set the rail bit in SPRG0 appropriately
        mr D0, SPRG0                            # Working copy
        andi D0, D0, SLW_SPRG0_RAIL_FLAG_CLEAR  # Clear field for VDD
        mr SPRG0, D0                            # Store SPRG0 away

        // Call subroutine to sequence the PFETs for this rail
        bsr slw_pfet_seq

        POREVE_DBG("\n")
        POREVE_INF("SLW PFET power down VCS")
        // Set the rail bit in SPRG0 appropriately
        mr D0 ,SPRG0                            # Working copy
        ori D0, D0, SLW_SPRG0_RAIL_FLAG         # Set field for VCS
        mr SPRG0, D0                            # Store SPRG0 away

        // Call subroutine to sequence the PFETs
        POREVE_INF("SLW PFET calling slw_pfet_seq")
        bsr slw_pfet_seq

        POREVE_INF("SLW PFET Entry Continue Branch")
        bra next_loop

        // else (exit)
2:
        //--- For exit transtions, power up VCS first, then VDD ---

        POREVE_DBG("\n")
        POREVE_INF("SLW PFET power up VCS")
        // Set the rail bit in SPRG0 appropriately
        mr D0, SPRG0                            # Working copy
        ori D0, D0, SLW_SPRG0_RAIL_FLAG         # Set field for VCS
        mr SPRG0, D0                            # Store SPRG0 away

        // Call subroutine to sequence the PFETs for this rail
        POREVE_INF("SLW PFET calling slw_pfet_seq")
        bsr slw_pfet_seq

        POREVE_DBG("\n")
        POREVE_INF("SLW PFET power up VDD")
        // Set the rail bit in SPRG0 appropriately
        mr D0 ,SPRG0                            # Working copy
        andi D0, D0, SLW_SPRG0_RAIL_FLAG_CLEAR  # Clear field for VDD
        mr SPRG0, D0                            # Store SPRG0 away

        // Call subroutine to sequence the PFETs
        POREVE_DBG("\n")
        POREVE_INF("SLW PFET calling slw_pfet_seq")
        bsr slw_pfet_seq

        // end if
next_loop:

        // Restore the working chiplet vector to D1 from SPRG0
        mr D1, SPRG0
        sldi D1, D1, 1 # Shift chiplet vector mask
        andi D1, D1, SLW_SPRG0_CHIPLET_MASK
        POREVE_DBG(">> SLW PFET On/Off D1 rotated 1             0x%016llX",
                        io_pore.d1.read())

        mr D0, P1
        adds D0, D0, 1 # Index next chiplet
        mr P1, D0
        POREVE_DBG(">> SLW PFET On/Off P1 incr chiplet          0x%02llX",
                        io_pore.p1.read())

end_loop:

        loop chiplet_loop

        // HW273115:  Fix for ivrm-pstate ack bug in winkle. 
        //            Fast winkle entry: Do nothing to ivrm nor pfets.
        //            Fast winkle exit: Do nothing to ivrm nor pfets.
        //            Deep winkle entry: Enable force safe mode. Turn off pfets.
        //        --> Deep winkle exit: Turn on pfets. Disable force safe mode.
        mr  		D1, SPRG0
        andi    D0, D1, SLW_SPRG0_TV_DWX_MASK
        braz    D0, exit_power_on_off
        la      A0, slw_control_vector
        ldandi  D0, 0, A0, BIT(63)
        braz    D0, skip_hw273115_fix3
        sti     EX_PMGP1_AND_0x100F0104, P0, ~(BIT(13)|BIT(14))

skip_hw273115_fix3:

exit_power_on_off:


        ##@ printf ("--> Hook Check: number of chiplets processed %x\n", chiplets_processed);
        ##@ if (chiplets == chiplets_processed) {
        ##@     printf ("--> Hook Check: PASS\n");
        ##@ } else {
        ##@     printf ("--> Hook Check: FAIL - Expected chiplets: %d;"
        ##@                "Processed chiplets: %d\n", chiplets,  chiplets_processed);
        ##@ }
        ##@ return hookOk;

        .end_subroutine slw_power_on_off

// Timeout error halts
forcesm_poll_entry_timeout:
        POREVE_ERR("SLW iVRM Force Safe Mode Timeout")
        reqhalt RC_SLW_IVRM_FORCESM_TIMEOUT

bssync_poll_sleep_entry_timeout:
        POREVE_ERR("SLW Baby Stepper Sync Sleep Entry Timeout")
        reqhalt RC_SLW_IVRM_BS_SLEEP_ENTRY_TIMEOUT

bssync_poll_winkle_entry_timeout:
        POREVE_ERR("SLW Baby Stepper Sync Winkle Entry Timeout")
        reqhalt RC_SLW_IVRM_BS_WINKLE_ENTRY_TIMEOUT

bssync_poll_exit_timeout:
        POREVE_ERR("SLW Baby Stepper Exit Timeout")
        reqhalt RC_SLW_IVRM_BS_EXIT_TIMEOUT


/// PFET Sequencing
///
/// Called from slw_power_on_off
///
/// Prereqs:
///             SPRG0:  VDD/VCS rail flag valid
///                     Chiplet Mask valid (not used)
///
//  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	Temporary scratch register
/// 		A0: 	Data pointer
/// 		A1: 	Poll counter
/// 		P0: 	Chiplet/Multicast ID pointer (unmodified)
///         P1: 	Pervasive chiplet ID pointer
/// 		CTR: 	Chiplet counter  (Not used: must be preserved for caller!!)
///         SPRG0:  VDD or VCS rail indication for PFET subroutine
///                     Running chiplet mask save area
///
        .subroutine slw_pfet_seq, slw, "$Revision: 1.13 $"

        // Determine the PFET Control overlay based on the transition
        // Sleep: core only;  Winkle: Core and ECO

        POREVE_INF("\n")
        POREVE_INF("SLW PFET slw_pfet_seq called with SPRG0     0x%08llX",
                        io_pore.sprg0.read())

        POREVE_INF("SLW PFET slw_pfet_seq called with P1        0x%08llX",
                        io_pore.p1.read())


        // Both Fast and Deep Sleep Exit need 0:3 = 0xC
        mr D0, SPRG0
        andi D0, D0, SLW_SPRG0_TV_ANYSX_MASK
        braz D0, 1f                             # If not 0, process

        POREVE_INF("SLW PFET Seq: Fast/Deep Sleep Exit")

        andi D1, D1, 0x0                        # Clear D1
        ori D1, D1, 0xC000000000000000          # Set D1
        bra 2f
1:

        // Both Fast and Deep Winkle Exit need 0:3 = 0xF
        mr D0, SPRG0
        andi D0, D0, SLW_SPRG0_TV_ANYWX_MASK       # If not 0, process
        braz D0, 1f

        POREVE_INF("SLW PFET Seq: Fast/Deep Winkle Exit")

        andi D1, D1, 0x0                         # Clear D1
        ori D1, D1, 0xF000000000000000           # Set D1
        bra 2f
1:
        // Fast Sleep Entry needs 0:3 = 0x8
        mr D0, SPRG0
        andi D0, D0, SLW_SPRG0_TV_FSE_MASK         # If not 0, process
        braz D0, 1f

        POREVE_INF("SLW PFET Seq: Fast Sleep Entry")

        andi D1, D1, 0x0                         # Clear D1
        ori D1, D1, 0x8000000000000000           # Set D1
        bra 2f
1:

        // Deep Sleep Entry needs 0:3 = 0x4
        mr D0, SPRG0
        andi D0, D0, SLW_SPRG0_TV_DSE_MASK         # If not 0, process
        braz D0, 1f

        POREVE_INF("SLW PFET Seq: Deep Sleep Entry")

        andi D1, D1, 0x0                         # Clear D1
        ori D1, D1, 0x4000000000000000           # Set D1
        bra 2f
1:
        // Fast Winkle Entry needs 0:3 = 0xA
        mr D0, SPRG0
        andi D0, D0, SLW_SPRG0_TV_FWE_MASK         # If not 0, process
        braz D0, 1f

        POREVE_INF("SLW PFET Seq: Fast Winkle Entry")

        andi D1, D1, 0x0                         # Clear D1
        ori D1, D1, 0xA000000000000000           # Set D1
        bra 2f
1:
        // Deep Winkle Entry needs 0:3 = 0x5
        mr D0, SPRG0
        andi D0, D0, SLW_SPRG0_TV_DWE_MASK         # If not 0, process
        braz D0, 1f

        POREVE_INF("SLW PFET Seq: Deep Winkle Entry")

        andi D1, D1, 0x0                         # Clear D1
        ori D1, D1, 0x5000000000000000           # Set D1
        bra 2f
1:
        // If we got here, there's a bug.
        POREVE_ERR("ERROR:  Invalid PFET On/Off Decode")
        reqhalt RC_SLW_PFET_DECODE_ERROR
2:
        // At this point, D1 has the overlay value for the either relevant
        // control register

        // Determine which rail to process
        // if (VDD) then
        mr D0, SPRG0                            # Working copy
        andi D0, D0, SLW_SPRG0_RAIL_FLAG        # Mask to the rail bit
        branz D0, slw_pfet_process_vcs          # Rail = 1 indicates VCS

/// VDD --------------------
slw_pfet_process_vdd:

        // setup pfet control/status register
        // clear desired bits for pfet sequencing
        ldandi D0, EX_PFET_CTL_REG_0x100F0106, P1, 0x03FFFFFFFFFFFFFF

        // set desired bits for pfet sequencing
        or D0, D0, D1

        POREVE_DBG(">> SLW VDD PFET Control write               0x%016llX",
                        io_pore.d0.read())
        // write value back to pfet ctl register
        std D0, EX_PFET_CTL_REG_0x100F0106, P1

        // poll until pfet state machine is back to idle
        // set counter for loop

        ##@ pfet_pollCount = 0; return hookOk;

        ls A1, 50

poll_pfet_idle_vdd:

        POREVE_INF("     SLW VDD PFET Control Polling A1        0x%08llX",
                        io_pore.a1.read())

        // read state based on the transition
        // Always include the core

        // if (winkle)
        mr D0, SPRG0                            # Get SPRG0
        cmpibraeq D0, 1f, SLW_SPRG0_TV_ANYWINKLE_MASK   # If not 0, process
        branz D0, 1f

        ld D0, EX_PFET_CTL_REG_0x100F0106, P1      # Get the control reg
        andi D0, D0, PFET_WINKLE_PG_MASK        # Mask to the field

        ##@ // Force D0 to PFET_WINKLE_IDLE_STATUS_MASK to act like hdw
        ##@ io_pore.d0.write(0x0000000000200200);
        ##@ printf ("--> Hook force of VDD Winkle PFET completion\n");
        ##@ return hookOk;

        // branch out of loop if state machine is complete
        cmpibraeq D0, 3f, PFET_WINKLE_IDLE_STATUS_MASK

        bra 2f
        // else (sleep)
1:
        ld D0, EX_PFET_CTL_REG_0x100F0106, P1      # Get the control re
        andi D0, D0, PFET_SLEEP_PG_MASK         # Mask to the field

        ##@ // Force D0 to PFET_SLEEP_IDLE_STATUS_MASK to act like hdw
        ##@ io_pore.d0.write(0x0000000000200000);
        ##@ printf ("--> Hook force of VDD Sleep PFET completion\n");
        ##@ return hookOk;

        // branch out of loop if state machine is complete
        cmpibraeq D0, 3f, PFET_SLEEP_IDLE_STATUS_MASK

        // end if
2:
        POREVE_INF("     SLW VDD PFET Control Read Ctl D0       0x%016llX",
                        io_pore.d1.read())

        // otherwise wait

        waits PFET_WAIT

        // loop back to check state machine again
        mr D0, A1                               # branz only works on D0, D1, and CTR
        subs D0, D0, 1                          # Decrement the count
        mr A1, D0                               # Save for next interation
        ##@ pfet_pollCount++; return hookOk;
        branz D0, poll_pfet_idle_vdd


        // pfet sequencing still not complete and we've finished loop -> Error out
        reqhalt RC_SLW_PFET_VDD_TIMEOUT_ERROR

3:
         POREVE_INF("     SLW VDD PFET Control Completing");

        // clean up pfet sequencing by setting force state back to 00 for the region(s)


        // if (winkle)
        mr D0, SPRG0                            # Get SPRG0
       	andi D0, D0, SLW_SPRG0_TV_ANYWINKLE_MASK # bug fix 01/15/2012
        braz D0, 1f                              # bug fix 01/15/2012


        // \bug to be removed ldandi D0, EX_PFET_CTL_REG_0x100F0106, P1, PFET_WINKLE_PG_CLEAR
        ldandi D0, EX_PFET_CTL_REG_0x100F0106, P1, PFET_CNTL_REMV_OVRD_WINKLE
        POREVE_INF("     SLW VDD PFET Control PFET_WINKLE_PG_CLEAR");

        bra 2f
        // else (sleep)
1:
        // \bug to be removed ldandi D0, EX_PFET_CTL_REG_0x100F0106, P1, PFET_SLEEP_PG_CLEAR
        ldandi D0, EX_PFET_CTL_REG_0x100F0106, P1, PFET_CNTL_REMV_OVRD_SLEEP
        POREVE_INF("     SLW VDD PFET Control PFET_SLEEP_PG_CLEAR");

       // end if
2:

        // write value back to pfet ctl register
        POREVE_INF("     SLW VDD PFET Control Write from D0     0x%016llX",
                        io_pore.d0.read())
        std D0, EX_PFET_CTL_REG_0x100F0106, P1

        // Done with VDD
        bra pfet_completion

/// VCS --------------------
slw_pfet_process_vcs:

        // setup pfet control/status register
        // clear desired bits for pfet sequencing
        ldandi D0, EX_PFET_CTL_REG_0x100F010E, P1, 0x03FFFFFFFFFFFFFF

        // set desired bits for pfet sequencing
        or D0, D0, D1

        POREVE_INF("     SLW VCS PFET Control write             0x%016llX",
                        io_pore.d0.read())
        // write value back to pfet ctl register
        std D0, EX_PFET_CTL_REG_0x100F010E, P1

        // poll until pfet state machine is back to idle
        // set counter for loop
        ls A1, 50

poll_pfet_idle_vcs:

        POREVE_INF("     SLW VCS PFET Control Polling A1        0x%08llX",
                        io_pore.a1.read())

        // read state based on the transition
        // Always include the core



        // if (winkle)
        mr D0, SPRG0                            # Get SPRG0
        cmpibraeq D0, 1f, SLW_SPRG0_TV_ANYWINKLE_MASK   # If not 0, process
        branz D0, 1f

        ld D0, EX_PFET_CTL_REG_0x100F010E, P1   # Get the control reg
        andi D0, D0, PFET_WINKLE_PG_MASK        # Mask to the field

        ##@ // Force D0 to PFET_WINKLE_IDLE_STATUS_MASK to act like hdw
        ##@ io_pore.d0.write(0x0000000000200200);
        ##@ printf ("--> Hook force of VCS Winkle PFET completion\n");
        ##@ return hookOk;

        // branch out of loop if state machine is complete

        cmpibraeq D0, 3f, PFET_WINKLE_IDLE_STATUS_MASK

        bra 2f
        // else (sleep)
1:
        ld D0, EX_PFET_CTL_REG_0x100F010E, P1   # Get the control reg
        andi D0, D0, PFET_SLEEP_PG_MASK         # Mask to the field

        ##@ // Force D0 to PFET_SLEEP_IDLE_STATUS_MASK to act like hdw
        ##@ io_pore.d0.write(0x0000000000200000);
        ##@ printf ("--> Hook force of VCS Sleep PFET completion\n");
        ##@ return hookOk;

        // branch out of loop if state machine is complete
        cmpibraeq D0, 3f, PFET_SLEEP_IDLE_STATUS_MASK

        // end if
2:
        POREVE_INF("     SLW VCS PFET Control Read Ctl D0       0x%016llX",
                        io_pore.d1.read())

        // otherwise wait

        waits PFET_WAIT

        // loop back to check state machine again
        mr D0, A1                               # branz only works on D0, D1, and CTR
        subs D0, D0, 1                          # Decrement the count
        mr A1, D0                               # Save for next interation
        branz D0, poll_pfet_idle_vcs


        // pfet sequencing still not complete and we've finished loop -> Error out
        reqhalt RC_SLW_PFET_VCS_TIMEOUT_ERROR

3:
         POREVE_INF("     SLW VCS PFET Control Completing");

        // clean up pfet sequencing by setting force state back to 00 for the region(s)

        // if (winkle)
        mr D0, SPRG0                            # Get SPRG0
        andi D0, D0, SLW_SPRG0_TV_ANYWINKLE_MASK # bug fix 01/15/2012
        braz D0, 1f                              # bug fix 01/15/2012

        // \bug to be removed ldandi D0, EX_PFET_CTL_REG_0x100F010E, P1, PFET_WINKLE_PG_CLEAR
        ldandi D0, EX_PFET_CTL_REG_0x100F010E, P1, PFET_CNTL_REMV_OVRD_WINKLE
        POREVE_INF("     SLW VDD PFET Control PFET_WINKLE_PG_CLEAR");

        bra 2f
        // else (sleep)
1:
        // \bug to be removed ldandi D0, EX_PFET_CTL_REG_0x100F010E, P1, PFET_SLEEP_PG_CLEAR
        ldandi D0, EX_PFET_CTL_REG_0x100F010E, P1, PFET_CNTL_REMV_OVRD_SLEEP
        POREVE_INF("     SLW VDD PFET Control PFET_SLEEP_PG_CLEAR");

       // end if
2:

        // write value back to pfet ctl register
        POREVE_INF("     SLW VCS PFET Control Write from D0     0x%016llX",
                        io_pore.d0.read())
        std D0, EX_PFET_CTL_REG_0x100F010E, P1

        // Done with VCS

/// Complete ---------------
pfet_completion:
        ##@ printf("PFET poll %d times\n", pfet_pollCount); return hookOk;

/// Exit ---------------
pfet_idle_exit:

        .end_subroutine slw_pfet_seq
