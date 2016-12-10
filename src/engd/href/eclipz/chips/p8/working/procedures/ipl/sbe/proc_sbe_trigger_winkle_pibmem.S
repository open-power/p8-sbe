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
#include "proc_sbe_trigger_winkle.H"
#include "p8_slw.H"
#include "proc_slw.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .pibmem

//------------------------------------------------------------------------------
// Global Data 
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros 
//------------------------------------------------------------------------------

        //  Deadman Counter is set to give a 10 second timeout to cover any 
        //  phase (winkle entry, winkle exit, or host boot completion)
        //
        //  Using a ~1ms polling delay (DEADMAN_DELAY_1), the count needs to be 
        //  10000
              
        // .set DEADMAN_COUNT,  10000
        
        // For simulation, set to the maximum
        .set DEADMAN_COUNT,  0xFFFFFF    
        
        //.DEADMAN_DELAY_ - This value is used to put some PIB spacing into the 
        // "Wait for Deadman Start" step to have the SBE polling relatively fast 
        // while waiting for HostBoot but not fully consuming the PIB in a tight
        // loop while doing so.  
        .set DEADMAN_DELAY_0, 0x100    
        
        // DEADMAN_DELAY_1 - This value should be set to ~1ms between polls.  
        // Winkle is projected to take 5ms so having a 1ms poll time will have 
        // the interrupt available for the restart being adequately fast (within 
        // 1ms of being achieving the Winkle Entered state) without slowing down 
        // the winkle exit time by adding additional PIB traffic.
        
        // For a nest frequency of 2.4GHz, the TP clock time is 1.667ns 
        // [1/ (2.4GHz/4)] -> 1/600MHz -> .001667us -> 1.667ns.
        
        // The maximum count that a PORE waits instruction can have is 2^24.
        // This represents 268435455 * 1.667ns or 447ms.  A count of 600000
        // yields ~1ms.  0d600000 -> 0x927C0
        
        // For simulation where the core is 2up/2dn -> nest 4up/4dn -> PIB 16up/16dn,
        // this delay will take 32 * 16777216 (2^24) => 536,870,912 cycles
        
        // Simulation times:  winkle entry -> ~9M cycles
                 
        //.set DEADMAN_DELAY_1, 0x927C0 // 1ms @ 600MHz 
        .set DEADMAN_DELAY_1, 0x1000 
                
        .set LOCATION_MASK,     BITS(16,16)
        .set DEADMAN_START,     (proc_sbe_trigger_winkle_istep_num << 36 | SUBSTEP_DEADMAN_START << 32)
        .set HOSTBOOT_ALIVE,    (proc_sbe_trigger_winkle_istep_num << 36 | SUBSTEP_HOSTBOOT_ALIVE_AGAIN << 32)
        .set STATE_HIST_MASK,   BITS(0,3)
        .set STATE_HIST_WINKLE, BITS(0,3)
        .set FSM_MASK,          BITS(23,7)

        //This is a bit in the procedure control word
        .set SKIP_IPI_BIT,    8

        // Helper macro to check state of control bits from PIBMEM offset
        .macro ifcntrbitset, offset:req, bitmask:req, target:req
        ldandi  D1, \offset, P1, \bitmask
        branz	D1, \target
        .endm
        
//------------------------------------------------------------------------------
// Procedure - pibmem
//------------------------------------------------------------------------------

	.global	proc_sbe_trigger_winkle_pibmem

        //////////////////////////////////////////////////////////////////////
        // Register usage:
        // P0 - used to store EX chiplet number that was used for booting
        // P1 - used to store Pervasive, PB, and Multicast read chiplet number
        // A0 - used for addressing PIBMEM
        // D0 - used for calculations
        // D1 - used to store the success compare values
        // CTR - used for deadman counter
        //////////////////////////////////////////////////////////////////////

	.subroutine proc_sbe_trigger_winkle_pibmem, pibmem, "$Revision: 1.17 $"
	
	POREVE_INF("proc_sbe_trigger_winkle: Setting up");
//        updatestep_inline SUBSTEP_PROC_ENTRY, D0, P1
        
        //Setup P1
        lpcs    P1, STBY_CHIPLET_0x00000000
        
        POREVE_DBG("Unlocking SEEPROM access because we don't need it anymore") ;
        bci     D0, MBOX_FSIGP4_0x00050013, P1, BIT(20)

        //----------------------------------------------------------------------
        // Substep: Waiting for Deadman Start
        //----------------------------------------------------------------------
              
        POREVE_DBG("proc_sbe_trigger_winkle: Chiplet target via P0 - %02llx", io_pore.p0.read());

        updatestep_inline SUBSTEP_SBE_READY, D0, P1  
        POREVE_DBG("proc_sbe_trigger_winkle: substep 0x%16llx", io_pore.d0.read());    


        //If platform is FSP, then we need to pause and give control back to Cronus
        ##@ fapi::ReturnCode rc;
        ##@ uint8_t platform = 0;
        ##@ rc = FAPI_ATTR_GET( ATTR_EXECUTION_PLATFORM, &i_target, platform );
        ##@ if( !rc.ok() )
        ##@ {
        ##@ return rc;
        ##@ }
        ##@ if( platform == fapi::ENUM_ATTR_EXECUTION_PLATFORM_FSP )
        ##@ {
        ##@ io_pore.forceBranch("pibmem::proc_sbe_trigger_winkle_pause");
        ##@ }
        ##@ return hookOk;
        bra     waiting_for_deadman_start

        .global proc_sbe_trigger_winkle_pause
proc_sbe_trigger_winkle_pause:  
    POREVE_INF("proc_sbe_trigger_winkle: Pause Halt");
        reqhalt RC_SBE_PAUSE_WITH_SUCCESS, D0, P1
        //Cronus will resume from this spot, which means it needs to clear halt code
        ldandi  D0, MBOX_SBEVITAL_0x0005001C, P1, ~(BITS(12,4))
        std     D0, MBOX_SBEVITAL_0x0005001C, P1
        
        .global waiting_for_deadman_start
waiting_for_deadman_start:
    
        //Setup the success compare value that HB is going to write into SBE_VITAL
        li      D1, DEADMAN_START
            
	POREVE_INF("proc_sbe_trigger_winkle: Waiting for deadman start from HB");
        // Having the SBE generically consuming the PIB can collide with other
        // activities possible on the PIB.  In this phase, there isn't really
        // any by design, but having a VERY tight loop pumping out traffic could
        // have unknown ill effects.
dbg_deadman_delay_1_location0:  
        waits   DEADMAN_DELAY_0
    
        POREVE_DBG("proc_sbe_trigger_winkle: waiting_deadman_start:  P0:%02llx  P1:%02llx", io_pore.p0.read(), io_pore.p1.read()); 
        ldandi  D0, MBOX_SBEVITAL_0x0005001C, P1, LOCATION_MASK
        POREVE_DBG("proc_sbe_trigger_winkle: Host Value:             D0 %16llx", io_pore.d0.read());  
        POREVE_DBG("proc_sbe_trigger_winkle: Deadman Value:          D1 %16llx", io_pore.d1.read());     
        sub     D0, D0, D1
        branz   D0, waiting_for_deadman_start

        //----------------------------------------------------------------------
        // Substep: Waiting for Winkle
        //----------------------------------------------------------------------

deadman_started:        
        updatestep_inline SUBSTEP_DEADMAN_WAITING_FOR_WINKLE, D0, P1
        
        
        //Setup Deadman counter
dbg_deadman_count_location:    
        li      CTR, DEADMAN_COUNT
     
        //Setup the winkle success compare value part 1
        li      D1, STATE_HIST_WINKLE

        setp1_mcreadand D0
       
//Note: this loop is decrementing the deadman timer count
waiting_for_winkle_entry:
	POREVE_INF("proc_sbe_trigger_winkle: Waiting for winkle part 1");
        POREVE_DBG("proc_sbe_trigger_winkle: Read PM Hist via P1 - %02llx", io_pore.p1.read());
        ldandi  D0, EX_PMSTATEHISTFSP_REG_0x100F0111, P1, STATE_HIST_MASK
               
        POREVE_DBG("proc_sbe_trigger_winkle: pmhist D0 - %16llx", io_pore.d0.read());
        sub     D0, D0, D1
        branz   D0, dbg_deadman_delay_1_location1
        
    POREVE_INF("proc_sbe_trigger_winkle: Waiting for winkle part 2");
        POREVE_DBG("proc_sbe_trigger_winkle: PCBS FSM va P1 - %02llx", io_pore.p1.read());
        ldandi      D0, EX_PCBS_FSM_MONITOR2_REG_0x100F0171, P1, FSM_MASK
        POREVE_DBG("proc_sbe_trigger_winkle: PCBS FSM D0 - %16llx", io_pore.d0.read());
        braz    D0, trigger_wakeup
                
        // Having the SBE generically consuming the PIB will collide with the 
        // SLW doing its function so a wait is necessary for performance reasons
dbg_deadman_delay_1_location1:  
        waits   DEADMAN_DELAY_1
winkle_entry_end:
        loop    waiting_for_winkle_entry
        bra     xstop_did_not_enter_winkle

trigger_wakeup:        
        
        // branch to success here if the SKIP_IPI control bit is set
        .pibmem_port (PORE_SPACE_PIBMEM & 0xf) 
        lpcs    P1, PIBMEM0_0x00080000
        ifcntrbitset    proc_sbe_trigger_winkle_pibmem_control, \
                        BIT(SKIP_IPI_BIT), \
                        proc_sbe_trigger_winkle_success
                        
	POREVE_INF("proc_sbe_trigger_winkle: Triggering wakeup");

        //----------------------------------------------------------------------
        // Substep: Waiting for Wakeup
        //----------------------------------------------------------------------
        //Restore P1
        lpcs    P1, STBY_CHIPLET_0x00000000
        updatestep_inline SUBSTEP_DEADMAN_WAITING_FOR_WAKEUP, D0, P1
        //Note - do the IPI to trigger wakeup after updatestep, so that updatestep always
        //       happens before winkle wakeup is complete
        
        // SW239845 - clear Block Wake-up Source bit that is set by Hostboot to
        // ensure that winkle entry is seen by the deadman code above
        sti     EX_PMGP0_AND_0x100F0101, P0, ~BIT(53)
    
        // Enable the ICP injection mode
        lpcs    P1, ICP_SYNC_MODE_REG0_0x020109CB
        ld      D0, ICP_SYNC_MODE_REG0_0x020109CB, P1
        
        POREVE_DBG("proc_sbe_trigger_winkle: icp_sync_mode before OR - %16llx", io_pore.d0.read());
        ori     D0, D0, BIT(47)
        std     D0, ICP_SYNC_MODE_REG0_0x020109CB, P1   
        
        POREVE_DBG("proc_sbe_trigger_winkle: icp_sync_mode - %16llx", io_pore.d0.read()); 
        
        //Check for multicast
        mr      D0, P0
        andi    D0, D0, BIT(57)
        braz    D0, single_chiplet

multicast:
        //Multicast - so read gp3 bit 0 from each group in the multicast
        //            and shift into bits 0:15
        // Set P1 to "multicast read bit 0" chiplet
        mr      D0, P0
        andi    D0, D0, ~(BITS(58, 3))
        ori     D0, D0, BIT(59)
        mr      P1, D0
        ld      D0, GENERIC_GP3_0x000F0012, P1
        rols    D1, D0, 16
        bra     do_ipi

single_chiplet:
        //pause deadman so that we can use CTR
        mr      D0, CTR
        //put chiplet number into CTR
        mr      D1, P0
        andi    D1, D1, BITS(60, 4)
        mr      CTR, D1
        //Set bit corresponding to chiplet number in the following loop
        //By rotating a 1 in from the left
        li      D1, BIT(63)
single_chiplet_loop:
        rotrdi  D1, D1, 1
        loop    single_chiplet_loop

        //restore the deadman timer counter
        mr      CTR, D0

do_ipi:
        // Bits 0:15 of D1 are now set for the chiplet(s) to wake up
        POREVE_DBG("proc_sbe_trigger_winkle: Chiplets to wake D1      - %16llx", io_pore.d1.read()); 
        // Wake-up the desired threads with IPI, level 0, priority 0
        // Pull t0:t7 thread mask which indicates the threads NOT to start
        // Note: we always set t0 regardless
        // Note: A0 was previously set to point to the PIBMEM control vector
        lpcs    P1, PIBMEM0_0x00080000
        ldandi  D0, proc_sbe_trigger_winkle_pibmem_control, P1, BITS(THREAD_START_VECTOR_START, THREAD_START_VECTOR_LENGTH)
        POREVE_DBG("proc_sbe_trigger_winkle: Masked control vector D0 - %16llx", io_pore.d0.read());
        
        // As 0s in the mask means the thread is to be interrupted, the mask must
        // be inverted
        xori    D0, D0, BITS(THREAD_START_VECTOR_START, THREAD_START_VECTOR_LENGTH)   
        POREVE_DBG("proc_sbe_trigger_winkle: thread bits D0           - %16llx", io_pore.d0.read());
        or      D1, D0, D1
        ori     D1, D1, BIT(THREAD_START_VECTOR_START)  // Always thread 0
        
        POREVE_DBG("proc_sbe_trigger_winkle: ICP Inject Value D1 -    - %16llx", io_pore.d1.read());
        lpcs    P1, ICP_INTR_INJECT_0x020109CC
        std     D1, ICP_INTR_INJECT_0x020109CC, P1
        
        POREVE_DBG("proc_sbe_trigger_winkle: icp_inject write - %16llx", io_pore.d1.read());
        
        //If platform is FSP, then we need to pause and give control back to Cronus
        ##@ fapi::ReturnCode rc;
        ##@ uint8_t platform = 0;
        ##@ rc = FAPI_ATTR_GET( ATTR_EXECUTION_PLATFORM, &i_target, platform );
        ##@ if( !rc.ok() )
        ##@ {
        ##@ return rc;
        ##@ }
        ##@ if( platform == fapi::ENUM_ATTR_EXECUTION_PLATFORM_FSP )
        ##@ {
        ##@ io_pore.forceBranch("pibmem::proc_sbe_trigger_winkle_success");
        ##@ }
        ##@ return hookOk;
      
        .global waiting_for_winkle_exit
waiting_for_winkle_exit:
        
        // Set P1 to referenence the targeted chiplet
        setp1_mcreadand D0
        
        // State to see that the PORE is working on Winkle Exit
        li      D1, WINKLE_EXIT_WAIT_PORE_GOTO_CMD
               
//Note: this loop is decrementing the deadman timer count       
waiting_for_goto:
	POREVE_INF("proc_sbe_trigger_winkle: Polling for exit of Winkle GOTO- CTR => %08lld", io_pore.ctr.read());
        //Check that PCBS-PM is the "Winkle Exit PORE GOTO" state       
        ldandi      D0, EX_PCBS_FSM_MONITOR2_REG_0x100F0171, P1, FSM_MASK               
        POREVE_DBG("proc_sbe_trigger_winkle: monitor2 D0 - %16llx", io_pore.d0.read());
        sub     D0, D0, D1
        braz   D0, waiting_for_idle
     
        // PIB back-off delay
dbg_deadman_delay_1_location2:  
        waits   DEADMAN_DELAY_1
        loop    waiting_for_goto
        bra     xstop_did_not_see_goto

//Note: this loop is decrementing the deadman timer count       
waiting_for_idle:
	POREVE_INF("proc_sbe_trigger_winkle: Polling for exit of Winkle IDLE - CTR => %08lld", io_pore.ctr.read());
        //Check that PCBS-PM is the "Winkle Exit IDLE" state       
        ldandi      D0, EX_PCBS_FSM_MONITOR2_REG_0x100F0171, P1, FSM_MASK
        POREVE_DBG("proc_sbe_trigger_winkle: PCBS FSM D0 - %16llx", io_pore.d0.read());
        braz    D0, wait_for_hostboot
        
        // PIB back-off delay
dbg_deadman_delay_1_location3:  
        waits   DEADMAN_DELAY_1
        loop    waiting_for_idle
        bra     xstop_did_not_wakeup

wait_for_hostboot:
        //----------------------------------------------------------------------
        // Substep: Waiting for Hostboot
        //----------------------------------------------------------------------
        updatestep_inline SUBSTEP_DEADMAN_WAITING_FOR_HOSTBOOT, D0, P1 
               
        //Setup the success compare value that HB is going to write into SBE_VITAL
        li      D1, HOSTBOOT_ALIVE
        
        // Disable the ICP injection mode to allow HostBoot to use the ICP
        lpcs    P1, ICP_SYNC_MODE_REG0_0x020109CB
        ld      D0, ICP_SYNC_MODE_REG0_0x020109CB, P1
        
        andi     D0, D0, ~BIT(47)
        std     D0, ICP_SYNC_MODE_REG0_0x020109CB, P1   

	lpcs	P1, MBOX_SBEVITAL_0x0005001C

//Note: this loop is decrementing the deadman timer count       
waiting_for_hostboot:
	POREVE_INF("proc_sbe_trigger_winkle: Polling for HB alive again - CTR => %08lld", io_pore.ctr.read());
        //Loop checking for substep_hostboot_alive_again
        ldandi  D0, MBOX_SBEVITAL_0x0005001C, P1, LOCATION_MASK
        sub     D0, D0, D1
        braz    D0, proc_sbe_trigger_winkle_success
        // For the SBE case, having the SBE generically consuming the 
        // PIB will collide with the SLW doing its function so a wait is 
        // necessary for performance reasons
dbg_deadman_delay_1_location4:  
        waits   DEADMAN_DELAY_1
        loop    waiting_for_hostboot
        //Fall through to the xstop when the loop counter is done

xstop_hostboot_did_not_respond: 
        POREVE_ERR("Deadman timer expired before Hostboot responded - xstopping the system") ;
        //Xstop the system
        //Kevin suggests 0x0104000A bit 36
        lpcs    P1, TP_PERV_LFIR_0x0104000A
        bsi     D0, TP_PERV_LFIR_0x0104000A, P1, BIT(36)
        reqhalt RC_SBE_TRIGGER_WINKLE_HOSTBOOT_DID_NOT_RESPOND

xstop_did_not_enter_winkle:
        POREVE_ERR("Deadman timer expired before EX winkled - xstopping the system") ;
        //Xstop the system
        //Kevin suggests 0x0104000A bit 36
        lpcs    P1, TP_PERV_LFIR_0x0104000A
        bsi     D0, TP_PERV_LFIR_0x0104000A, P1, BIT(36)
        reqhalt RC_SBE_TRIGGER_WINKLE_EX_DID_NOT_ENTER_WINKLE

xstop_did_not_see_goto:
        POREVE_ERR("Deadman timer expired before EX wakeup hit GOTO - xstopping the system") ;
        //Xstop the system
        //Kevin suggests 0x0104000A bit 36
        lpcs    P1, TP_PERV_LFIR_0x0104000A
        bsi     D0, TP_PERV_LFIR_0x0104000A, P1, BIT(36)
        reqhalt RC_SBE_TRIGGER_WINKLE_EX_WAKEUP_DID_NOT_HIT_GOTO

xstop_did_not_wakeup:
        POREVE_ERR("Deadman timer expired before EX woke up - xstopping the system") ;
        //Xstop the system
        //Kevin suggests 0x0104000A bit 36
        lpcs    P1, TP_PERV_LFIR_0x0104000A
        bsi     D0, TP_PERV_LFIR_0x0104000A, P1, BIT(36)
        reqhalt RC_SBE_TRIGGER_WINKLE_EX_WAKEUP_DID_NOT_FINISH

        .global proc_sbe_trigger_winkle_success
proc_sbe_trigger_winkle_success:
	##@ FAPI_INF("proc_sbe_trigger_winkle: Success!");
	##@ FAPI_INF("SKIPPING interrupt service loop");
	##@ io_pore.forceBranch("pibmem::proc_sbe_trigger_winkle_halt");
	##@ return hookOk;

     // check mailbox to determine if option is set to skip interrupt service routine
	ifbitsetscom D0, D0, MBOX_SCRATCH_REG3_0x0005003B, P1, 25,  proc_sbe_trigger_winkle_halt

run_intr_service:
	braia   PORE_SPACE_PIBMEM, proc_sbe_intr_service_pibmem

	.global proc_sbe_trigger_winkle_halt
proc_sbe_trigger_winkle_halt:
        reqhalt RC_SBE_SUCCESS, D0, P1

	.end_subroutine proc_sbe_trigger_winkle_pibmem
