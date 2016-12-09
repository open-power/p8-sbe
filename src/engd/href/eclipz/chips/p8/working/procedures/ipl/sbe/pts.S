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




/// \file pts.S
/// \brief PORE Thread Scheduler (PTS). 
///
/// The definition of the core scheduler for the PTS environment.

//------------------------------------------------------------------------------
// Includes
//------------------------------------------------------------------------------

        .nolist
#include "pts.h"
        .list
        
//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------

        .oci

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Text
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////
// Schedeuler
////////////////////////////////////////////////////////////////////////////                

        /////////////////////////////////////////////////////////////////////
        // _ptsSchedule()
        /////////////////////////////////////////////////////////////////////
        //
        // The main entry point of the PTS scheduling loop.
        //
        // Entry
        // -----
        //
        // At entry, interrupts must be disabled. No register parameters are
        // required and there are no other invariants on the state. At entry
        // _ptsSchedule() clears the stack and begins with a 'fresh'
        // context. 
        //
        // PTS is designed such that PTS is guaranteed to check for an
        // external command after each interrupt or thread system call. As
        // currently structured there is no guarantee that threads will ever
        // run in the event of continuous presentation of interrupts. If it
        // were determined that a set of low-letency, high-priority threads
        // must be guaranteed to make progress it would be possible to modify
        // the scheduler to execute what is now step 4 somewhere inside the
        // current step 6.
        //
        //
        // Exit
        // ----
        //
        // This is an infinite loop unless interrupted by an interrupt or
        // exited via resumption of a suspended thread. In either of these
        // cases the interrupt handler or thread will re-enter at
        // _ptsSchedule(), so untimately it is always an infinite loop unless
        // PTS dies. Even when PTS is "stopped" it only stops thread
        // scheduling, not the processing of commands and handling of
        // interrupts.
        //
        // Scheduling Algorithm
        // --------------------
        //
        // 1. Load the engine-specific PtsState address and OCI base address
        // and set the scheduler state to SCHEDULING. Clear the current thread
        // pointer and scheduler flags.
        //
        // 2. Clear the stack. If entered from a context switch, the yielding
        // thread will have already saved its stack context, and reentering a
        // saved context will re-establish that saved stack context. Clearing
        // the stack allows all components of the scheduler loop free use of
        // the stack.
        //
        // 3. The SLW application resets the PBA slave to regain coherence
        // with mainstore in the event a PTS command or external communication
        // with a thread is present. If a command is present it is
        // processed. Running the OCC application from main memory is not
        // supported, however OCC PTS threads can access mainstore as long as
        // they follow the rules.
        //
        // 4. Go interruptible to allow any pending interrupt to fire, and
        // also to install PTS default error mask.
        //
        // 5. If PTS is stopped, branch to step 8 to wait for the maximum
        // wait time.
        //
        // 6. Search the thread table for the first thread ready-to-run,
        // i.e. whose next schedule time is less than the current TOD clock.
        // If one is found, resume it. This is the core
        // time-and-priority-based scheduling paradigm. When the thread
        // yields, terminates, suspends or fails we will reenter the
        // scheduling loop at _ptsSchedule().
        //
        // 7. Having found no threads ready to run, rescan the thread table
        // to find the thread with the minimum next schedule time. Convert
        // this into a delta from the current TOD. Since time has elapsed, a
        // thread may in fact be runnable now, and if so we immediately
        // branch back to _ptsSchedlue(). Note that steps 7, 8 and 9 are an
        // optimization to reduce OCI/PowerBus traffic that would be caused
        // by continuous non-productive polling of an inactive thread table. 
        //
        // 8. Compute the minimum of 1) The delta computed in step 7, and 2)
        // the maximum wait delay. Convert this value into the number of PORE
        // wait loops required to approximate the delay. Step 8 may also be
        // entered from step 5 if PTS is stopped.
        //
        // 9. Wait with interrupts enabled for the amount of time computed in
        // step 8. 
        //
        // 10. If step 9 terminates without an interrupt, disable interrupts
        // and return to _ptsSchedule().
        //
        //
        // Notes
        // -----
        //
        // Note that there are various ways this code could be "optimized" and
        // rendered more complex, including taking different paths based on
        // whether _ptsSchedule() is (re)entered from the interrupt handler or
        // from the scheduling loop. In this implementation we are focussed on
        // correctness and simplicity, although steps 7, 8 and 9 do implement
        // an optimization to eliminate non-productive polling of the thread
        // table.
        
        .ptsGlobalFunction _ptsSchedule
_ptsSchedule:
        
        LOG_DEBUG("_ptsSchedule():Entry\n");

        // 1. Load the engine-specific PtsState address. We always clear the
        // flag indicating that a thread was handling error 0 to allow error
        // 0 recovery.  The scheduler state is set to SCHEDULING and we 
        // clear the current thread pointer.

        _ptsLoadPtsState ptsState=A0, scratch=D0
        bci     D0, PTS_STATE_FLAGS, A0, PTS_STATE_HANDLING_ERROR0

#if CONFIGURE_PTS_STATS

        _ptsIncrStateStat SCHEDULE, ptsState=A0, scratch=D0

        // Save away a TOD timestamp at entry

        lpcs    P0, PTS_TOD
        ld      D1, PTS_TOD, P0
        std     D1, PTS_STATE_STAT_ENTRY_TIME, A0

        // If we were running a thread, compute the maximum latency between
        // system calls usiung the TOD timestamp held in D1 (then moved to D0).

        ld      D0, PTS_STATE_SCHEDULER_STATE, A0
        cmpibrane D0, 1f, PTS_SCHEDULER_STATE_THREAD

                // D0 <- delta T

                ld      D0, PTS_STATE_CURRENT_THREAD, A0
                mr      A1, D0
                mr      D0, D1
                ld      D1, PTS_THREAD_LAST_SCHEDULE, A1
                sub     D0, D0, D1 
                
                // Compute and test for new maximum

                ld      D1, PTS_THREAD_MAX_LATENCY, A1
                sub     D1, D0, D1
                tfbule  D1, 1f

                        std     D0, PTS_THREAD_MAX_LATENCY, A1
1:      

#endif // CONFIGURE_PTS_STATS

        sti     PTS_STATE_SCHEDULER_STATE, A0, PTS_SCHEDULER_STATE_SCHEDULING

        ls      D0, 0                

        std     D0, PTS_STATE_CURRENT_THREAD, A0
        std     D0, PTS_STATE_FLAGS, A0
        
        _ptsGetOciBase ptsState=A0, ociBase=A1, scratch=D0


        // 2. Clear the stack.
        //
        // A0 :  &PtsState
        // A1 :  OCI Base address of engine

        _ptsClearStack ociBase=A1


        // 3. The SLW application resets the PBA slave to regain coherence
        // with mainstore in the event a command is present. If a command is
        // present (i.e., != 0) it is processed. Running the OCC application
        // from main memory is not supported, however OCC PTS threads can
        // access mainstore as long as they follow the rules.
        //
        // A0 :  &PtsState
        // A1 :  OCI Base address of engine

#if CONFIGURE_PTS_SLW

        ptsMainstoreCoherent

        // The PBA reset scratches the register state so we have to
        // re-establish it.

        _ptsLoadPtsState ptsState=A0, scratch=D0
        _ptsGetOciBase ptsState=A0, ociBase=A1, scratch=D0

#endif

        ld      D0, PTS_STATE_COMMAND, A0
        braz    D0, 30f

                bsr     _ptsCommand
30:


        // 4. Go interruptible to allow any pending interrupt to fire, and
        // also to install PTS default error mask.
        //
        // Again, some ugliness as a result of HW271773. It's possible that
        // we've been running up to here with a mask that disables error traps
        // on PIB errors. This is OK because we haven't done any PIB accesses
        // up until now.
        //
        // A0 :  &PtsState
        // A1 :  OCI Base address of engine
        
        sti     PTS_STATE_SCHEDULER_STATE, A0, \
                PTS_SCHEDULER_STATE_INTERRUPTIBLE 
        _ptsEnableInterrupts ociBase=A1, scratch=D0

        li      D0, PTS_DEFAULT_ERROR_MASK
        mr      EMR, D0

        _ptsDisableInterrupts ociBase=A1, scratch=D0
        sti     PTS_STATE_SCHEDULER_STATE, A0, \
                PTS_SCHEDULER_STATE_SCHEDULING

        _ptsIncrStateStat NO_INTERRUPT_PENDING, ptsState=A0, scratch=D0


        // 5. If PTS is stopped, branch to step 8 to wait for the maximum wait
        // time.
        //
        // A0 :  &PtsState
        
        ld      D0, PTS_STATE_STOPPED, A0
        braz    D0, 50f
        
                ld      D0, PTS_STATE_MAX_WAIT, A0
                bra     80f
50:


        // 6. Search the thread table for the first thread ready-to-run,
        // i.e. whose next schedule time is less than the current TOD clock.
        // If one is found, resume it.
        //
        // A0 :  &PtsState
        //
        // Step 6 loop invariants
        //
        // A1  :  The address of each PtsSchedulerThread
        // D1  :  The TOD clock
        // CTR :  Counts down the number of (potentially) valid threads
        //
        // This loop has a special case in that if a thread appears runnable
        // but the thread pointer is 0, we simply mark that entry as
        // terminated without causing an error.

        // Set up loop invariants and loop

        ld      D0, PTS_STATE_THREAD_TABLE, A0
        mr      A1, D0

        lpcs    P0, PTS_TOD
        ld      D1, PTS_TOD, P0

        LOG_DEBUG("_ptsSchedule():Step 6:TOD = " FMT_DX "\n", d1())

        ld      D0, PTS_STATE_VALID_THREADS, A0
        mr      CTR, D0
        bra     63f

60:
                // Check for runnability

                ld      D0, PTS_SCHEDULER_THREAD_NEXT_SCHEDULE, A1
                sub     D0, D0, D1
                tfbugt  D0, 62f
        
                        // The thread appears runnable, so load the thread
                        // pointer to make sure. If the thread is there,
                        // resume it.

                        ld      D0, PTS_SCHEDULER_THREAD_THREAD, A1
                        braz    D0, 61f
        
                                bra     _ptsResumeThread

61:
                        // This thread appeared runnable but the thread
                        // pointer is 0. This is assumed to be an artifact of
                        // initialization.  Fix the problem and move on.

                        sti     PTS_SCHEDULER_THREAD_NEXT_SCHEDULE, A1, \
                                PTS_TERMINATED

62:     
                // Move to the next thread and loop

                adds    A1, A1, SIZE_OF_PTS_SCHEDULER_THREAD    

63:     
                loop    60b


        // 7. Having found no threads ready to run, rescan the thread table
        // to find the thread with the minimum next schedule time. Convert
        // this into a delta from the current TOD. Since time has elapsed, a
        // thread may in fact be runnable now, and if so we immediately
        // branch back to _ptsSchedlue().
        //
        // A0 : &PtsState
        //
        // Step 7 loop invariants
        //
        // A1  :  The address of each PtsSchedulerThread
        // D0  :  The current minimum
        // CTR :  Counts down the number of (potentially) valid threads

        // Establish invariants

        ld      D0, PTS_STATE_THREAD_TABLE, A0
        mr      A1, D0

        li      D0, 0xffffffffffffffff

        ld      D1, PTS_STATE_VALID_THREADS, A0
        mr      CTR, D1
        bra     72f

70:
                // Load this thread's next schedule time into D1 and compute a
                // new minimum into D0. We don't have enough registers to keep
                // from having to reload a new winner.
                
                ld      D1, PTS_SCHEDULER_THREAD_NEXT_SCHEDULE, A1
                sub     D1, D0, D1
                tfbule  D1, 71f
                
                        ld      D0, PTS_SCHEDULER_THREAD_NEXT_SCHEDULE, A1
                
71:             
                // Move to the next thread and loop
                
                adds    A1, A1, SIZE_OF_PTS_SCHEDULER_THREAD

72:
                loop    70b


        // A0 : &PtsState
        // D0 : Minimum next schedule time
        //
        // Compute a delta of the next schedule time from the TOD into D0. If
        // the delta is non-positive we immediately go back to _ptsSchedule().

        lpcs    P0, PTS_TOD
        ld      D1, PTS_TOD, P0
        
        LOG_DEBUG("_ptsSchedule():Step 7:TOD = " FMT_DX 
                  ":Min. next sched. time = " FMT_DX "\n",
                  d1(), d0())

        sub     D0, D0, D1
        tfbule  D1, _ptsSchedule

        
        // 8. Compute the minimum of 1) The delta computed in step 7, and 2)
        // the maximum wait delay. Convert this value into the number of PORE
        // wait loops required to approximate the delay. This step may also be
        // entered at 80: if PTS is stopped.
        //
        // A0 : &PtsState
        // D0 : Thread schedule delay in TOD clocks

        // Note that since PORE comparison is destructive we need to reload
        // the maxWait in the event that it is the minimum.

80:     
        ld      D1, PTS_STATE_MAX_WAIT, A0
        sub     D1, D0, D1
        tfbule  D1, 81f

                ld      D0, PTS_STATE_MAX_WAIT, A0
81:             
        
        // A0 : &PtsState
        // D0 : PTS wait delay in TOD clocks
        //
        // The 2-instruction wait loop takes 20 cycles (!) to execute.  Since
        // it's only 2 x 4-byte instructions it fits in the 8-byte PORE
        // instruction buffer (if aligned) and won't cause any bus traffic
        // while we spin there.
        //
        // In P8 systems the PORE will be clocked at either 500 or 600 MHz,
        // however the delay is given in 512 MHz TOD ticks. Since we don't
        // have a multiplier or a divider what we do here is compute
        //
        //     (delay / 16) - (delay / 64) ~= delay / 20.5
        //
        // using shift and subtract. The error is sufficient to insure that
        // this delay will not overshoot the actual target timeout for either
        // a 500 or 600 MHz PORE clock.
        //
        // 1 ms @ 512MHz with shift/subtract division = 24000 loops
        // (24000 loops * 20 cycles) @ 500 MHz = 0.96 ms
        // (24000 loops * 20 cycles) @ 600 MHz = 0.80 ms
        //
        // For both the 500 and 600 MHz cases, but particularly for
        // the 600 MHz case, the delay-rescan loops will not be precise but
        // will converge rapidly to the target timeout.

        srdi    D0, D0, 4       # D0 = delay / 16
        srdi    D1, D0, 2       # D1 = delay / 64
        sub     D0, D0, D1      # D0 ~= delay / 20.5


        // 9. Wait with interrupts enabled for the amount of time computed in
        // step 8.
        //
        // A0 : &PtsState
        // D0 : PTS wait delay in wait loops

        _ptsGetOciBase ptsState=A0, ociBase=A1, scratch=D1

        sti     PTS_STATE_SCHEDULER_STATE, A0, \
                PTS_SCHEDULER_STATE_INTERRUPTIBLE
                
        _ptsEnableInterrupts ociBase=A1, scratch=D1

        LOG_DEBUG("_ptsSchedule():Wait for " FMT_DX " loops.\n", d0())

#if CONFIGURE_PTS_STATS

        // Compute how long it took to complete this pass of the scheduler

        std     D0, PTS_STATE_TEMP0, A0

        lpcs    P0, PTS_TOD
        ld      D0, PTS_TOD, P0
        ld      D1, PTS_STATE_STAT_ENTRY_TIME, A0
        sub     D0, D0, D1
        std     D0, PTS_STATE_STAT_SCHEDULE_TIME, A0
        
        ld     D0, PTS_STATE_TEMP0, A0

        _ptsIncrStateStat ENTER_WAIT, ptsState=A0, scratch=D1
        
#endif // CONFIGURE_PTS_STATS

        bsr     _ptsWait
        
        
        // 10. If step 9 terminates without an interrupt, disable interrupts
        // and return to _ptsSchedule().
        
        _ptsDisableInterrupts ociBase=A1, scratch=D1
        _ptsIncrStateStat EXIT_WAIT, ptsState=A0, scratch=D1
        
        bra    _ptsSchedule                             


        .ptsEpilogue _ptsSchedule

        
        //////////////////////////////////////////////////////////////////////
        // _ptsWait
        //////////////////////////////////////////////////////////////////////
        //
        // At entry:    
        //
        // D0 :  The number of wait loops at 20 PORE cycles per loop
        //
        // At exit:     
        //
        // D0 :  0 
        // No other registers modified               
        //
        // Enter the aligned wait loop at the bottom to correctly handle 0
        // wait times.
        //
        // In Simics we force D0 to 0, then use the PORE wait method to
        // implement the wait. This is not only more efficient than spinning
        // here, but also gives an accurate timing model. This is bypassed if
        // the wait time is 0, since by specification invoking io_pore.wait(0)
        // will cause the PORE engine to halt. 

        .ptsGlobalFunction _ptsWait
_ptsWait:

#if !CONFIGURE_PTS_SLW
        ##@ uint64_t delay;
        ##@ delay = d0();
        ##@ if (delay != 0) {
        ##@     io_pore.d0.write(0);
        ##@     io_pore.wait(delay * 20);
        ##@ }
#endif

        bra     2f
        .balign 8
1:
                subs    D0, D0, 1
2:
                branz   D0, 1b

        ret                

        .ptsEpilogue _ptsWait
        

        //////////////////////////////////////////////////////////////////////
        // _ptsResumeThread
        //////////////////////////////////////////////////////////////////////
        //
        // At entry point _ptsResumeThread:
        //
        // Interrupts are disabled
        // A0 : &PtsState
        // D0 : &PtsThread
        // 
        // Store the new thread as the current thread in the PTS state, and in
        // SPRG0. If the thread is handling its own PIB errors then set the
        // special EMR value that allows this. If the thread is marked as
        // having been terminated we resume from a clean restart. Otherwise
        // restore the stack context and branch to the saved PC where inlined
        // code will perform any other register restore prior to continuing
        // the thread.
        //
        // If this is the first time the thread has been run, then assuming
        // that the stack pointers have been properly initialized to clear the
        // stack, this will also successfully kick off the thread.

        .ptsGlobalFunction _ptsResumeThread
_ptsResumeThread:

        LOG_DEBUG("_ptsResumeThread():Entry:Thread = %p\n",
                  (void*)(uint32_t)d0());
        _ptsIncrStateStat RESUME_THREAD, ptsState=A0, scratch=D1


        // A1 and SPRG0 get &PtsThread, and the current thread pointer is also
        // stored in the state. If the thread is handling its own PIB errors
        // then we need to go interruptible temporarily to update the error
        // mask (HW271773).

        mr      A1, D0
        mr      SPRG0, D0
        std     D0, PTS_STATE_CURRENT_THREAD, A0
        
        ldandi  D0, PTS_THREAD_FLAGS, A1, PTS_THREAD_HANDLES_PIB_ERRORS
        braz    D0, 1f

                LOG_DEBUG("_ptsResumeThread:Thread handles PIB errors\n");

                _ptsGetOciBase ptsState=A0, ociBase=A1, scratch=D0
        
                sti     PTS_STATE_SCHEDULER_STATE, A0, \
                        PTS_SCHEDULER_STATE_INTERRUPTIBLE
        
                _ptsEnableInterrupts ociBase=A1, scratch=D0

                li      D0, PTS_THREAD_HANDLES_PIB_ERRORS_MASK
                mr      EMR, D0
        
                _ptsDisableInterrupts ociBase=A1, scratch=D0

                mr      A1, SPRG0

1:      
        _ptsIncrStateStat RESUME_NOT_INTERRUPTED, ptsState=A0, scratch=D1

        // The "THREAD" state is required to correctly charge time spent by
        // the thread between system calls, when CONFIGURE_PTS_STATS is
        // defined. 

         sti     PTS_STATE_SCHEDULER_STATE, A0, PTS_SCHEDULER_STATE_THREAD

#if CONFIGURE_PTS_STATS

        lpcs    P0, PTS_TOD
        ld      D0, PTS_TOD, P0
        std     D0, PTS_THREAD_LAST_SCHEDULE, A1

#endif

        // If this is a new or previously terminated thread it gets a clean
        // restart. Otherwise restore the stack and branch to the saved entry
        // point. 
        //                
        // A0 : &PtsState --> OciBase
        // A1 : &PtsThread

        _ptsGetOciBase ptsState=A0, ociBase=A0, scratch=D0

        ldandi  D0, PTS_THREAD_FLAGS, A1, PTS_THREAD_HAS_CONTEXT
        branz   D0, 2f
        
                // Clean restart   
        
                LOG_DEBUG("_ptsResumeThread:Clean restart\n")         

                ls      D0, 0
        
                std     D0, PTS_THREAD_FLAGS, A1
                std     D0, PTS_THREAD_RC, A1
                std     D0, PTS_THREAD_PTS_RC, A1

                sti     PTS_PORE_PC_STACK0_OFFSET, A0, PTS_STACK0_EMPTY
                std     D0, PTS_PORE_PC_STACK1_OFFSET, A0
                std     D0, PTS_PORE_PC_STACK2_OFFSET, A0

                ld      D0, PTS_THREAD_ENTRY_POINT, A1
                _ptsBrad D0

2:      
        // Resume the saved state. The stack state must be carefully restored
        // due to the bizarre way the logic was designed. First clear the
        // stack (perhaps redundantly).  This is to avoid potential stack
        // overflows since writing the stack pointer seems to cause "pushes"
        // internally. Then set the new stack pointer _only_. Writing
        // PC_STACK0 with bit 59 set updates the stack pointer but not the
        // stack entry! Then write stack entry 0 with the stack pointer update
        // bits cleared, followed by the other stack entries.
        
        LOG_DEBUG("_ptsResumeThread:Resuming saved state\n")         
        
        _ptsClearStack ociBase=A0

        ld      D0, PTS_THREAD_PC_STACK0, A1
        andi    D1, D0, 0xffff
        std     D1, PTS_PORE_PC_STACK0_OFFSET, A0 # Set stack pointer

        andi    D0, D0, 0xffffffffffff0000
        std     D0, PTS_PORE_PC_STACK0_OFFSET, A0 # Set stack0 contents

        ld      D0, PTS_THREAD_PC_STACK1, A1
        std     D0, PTS_PORE_PC_STACK1_OFFSET, A0

        ld      D0, PTS_THREAD_PC_STACK2, A1
        std     D0, PTS_PORE_PC_STACK2_OFFSET, A0

        ld      D0, PTS_THREAD_PC, A1
        _ptsBrad D0

        .ptsEpilogue _ptsResumeThread
        

////////////////////////////////////////////////////////////////////////////
// System Calls
////////////////////////////////////////////////////////////////////////////                

        //////////////////////////////////////////////////////////////////////
        // _ptsYieldSleepSuspend
        //////////////////////////////////////////////////////////////////////
        //
        // At entry point _ptsYieldSleepSuspend:     
        //
        // A0 : &PtsThread
        // D0 : The next schedule time.
        // P0 : Boolean 1 if this is a suspend operation, otherwise 0
        //
        // First update the next schedule time of the thread from D0.
        //
        // If the thread is running atomic its state is now corrupted and it
        // is killed.  Otherwise set the flag indicating the saved state is to
        // be restored.
        //
        // Next we need to save the stack context.  scheduler. To save the
        // stack context we need to read the PORE status register, because
        // only the PORE status register contains the stack level as a
        // readable field. This must be copied over to an image of the
        // PC_STACK0 register along with setting the "Set New Stack Pointer"
        // bit, so that when the scheduler restores these registers in
        // _ptsResumeThread() it can simply write them to reinitialize the
        // stack context.
        //
        // If this was a suspend operation then _ptsTerminateSuspendDie() is
        // called, since a suspend is treated like a terminate with a saved
        // state. Otherwise simply reenter the scheduler.

        .ptsGlobalFunction _ptsYieldSleepSuspend
_ptsYieldSleepSuspend:
        
        ld      D1, PTS_THREAD_SCHEDULER_THREAD, A0
        mr      A1, D1
        std     D0, PTS_SCHEDULER_THREAD_NEXT_SCHEDULE, A1

        _ptsLoadPtsState ptsState=A1, scratch=D0

        ldandi  D0, PTS_STATE_FLAGS, A1, PTS_STATE_MAINSTORE_ATOMIC
        braz    D0, 1f

                braa    _ptsThreadAtomicViolation
1:              
        bsi     D0, PTS_THREAD_FLAGS, A0, PTS_THREAD_HAS_CONTEXT

        _ptsGetOciBase ptsState=A1, ociBase=A1, scratch=D0

        // A0 :  &PtsThread
        // A1 :  Engine-specific OCI base
        // P0 : Boolean 1 if this is a suspend operation, otherwise 0

        // Stack1 and 2 are easy
        
        ld      D0, PTS_PORE_PC_STACK1_OFFSET, A1
        std     D0, PTS_THREAD_PC_STACK1, A0
        ld      D0, PTS_PORE_PC_STACK2_OFFSET, A1
        std     D0, PTS_THREAD_PC_STACK2, A0

        // Stack0 must be modified to cause the correct update when written
        
        ld      D0, PTS_PORE_STATUS_OFFSET, A1
        extrdi  D0, D0, 4, 12   # D0 = stack pointer
        
        ld      D1, PTS_PORE_PC_STACK0_OFFSET, A1
        insrdi  D1, D0, 4, 60   # Insert stack pointer

        ori     D1, D1, BIT(59) # Set 'update stack pointer' bit
        std     D1, PTS_THREAD_PC_STACK0, A0

        // Handle the special case for suspend

        mr      D0, P0
        braz    D0, 2f

                ls      D0, PTS_SUSPENDED
                bra     _ptsTerminateSuspendDie
2:      
        bra     _ptsSchedule

        .ptsEpilogue _ptsYieldSleepSuspend


        //////////////////////////////////////////////////////////////////////
        // _ptsYield
        //////////////////////////////////////////////////////////////////////
        //
        // At entry point _ptsYield:     
        //
        // SPRG0 : &PtsThread
        // D0    : The continuation address.  
        //
        // First we save the continuation address into the thread structure
        // and continue to _ptsYieldSleepSuspend().

        .ptsGlobalFunction _ptsYield
_ptsYield:

        LOG_DEBUG("_ptsYield():Entry:Thread = %p\n",
                  (void*)(uint32_t)sprg0());

        mr      A0, SPRG0
        std     D0, PTS_THREAD_PC, A0

        li      D0, PTS_RUNNABLE
        ls      P0, 0
        
        bra     _ptsYieldSleepSuspend

        .ptsEpilogue _ptsYield
        

        //////////////////////////////////////////////////////////////////////
        // _ptsSleep
        //////////////////////////////////////////////////////////////////////
        //
        // At entry point _ptsSleep:
        //
        // SPRG0 : &PtsThread
        // D0    : The continuation address 
        // D1    : The sleep interval
        //        
        // The continuation address is saved and the interval is
        // added to the current TOD to create the new next schedule time of
        // the thread. Then continue to _ptsYieldSleepSuspend().

        .ptsGlobalFunction _ptsSleep
_ptsSleep:

#if !CONFIGURE_PTS_SLW
        ##` uint64_t S_continuation, S_interval;
        ##@ S_continuation = d0();
        ##@ S_interval = d1();
#endif
        
        mr      A0, SPRG0
        std     D0, PTS_THREAD_PC, A0

        lpcs    P0, PTS_TOD
        ld      D0, PTS_TOD, P0
        add     D0, D0, D1

        LOG_DEBUG("_ptsSleep():Entry:Thread = %p @ %p:"
                  "Interval = " FMT_DX " (" FMT_VTIME "):"
                  "Wakeup = " FMT_DX " (" FMT_VTIME ")\n",
                  (void*)(uint32_t)sprg0(), (void*)(uint32_t)S_continuation,
                  S_interval, tod2vtime(S_interval),
                  d0(), tod2vtime(d0()))

        ls      P0, 0
        bra     _ptsYieldSleepSuspend

        .ptsEpilogue _ptsSleep


        //////////////////////////////////////////////////////////////////////
        // _ptsSleepAbsolute
        //////////////////////////////////////////////////////////////////////
        //
        // At entry point _ptsSleepAbsolute:
        //
        // SPRG0 : &PtsThread
        // D0    : The continuation address 
        // D1    : The sleep-until TOD value
        //        
        // The continuation address is saved and the sleep-until value is used
        // directly as the new next schedule time of the thread. 

        .ptsGlobalFunction _ptsSleepAbsolute
_ptsSleepAbsolute:

        LOG_DEBUG("_ptsSleepAbsolute():Entry:Thread = %p @ %p:"
                  "Timeout = " FMT_DX " (" FMT_VTIME ")\n",
                  (void*)(uint32_t)sprg0(),
                  (void*)(uint32_t)d0(),
                  d1(), tod2vtime(d1()))

        mr      A0, SPRG0
        std     D0, PTS_THREAD_PC, A0

        mr      D0, D1
        ls      P0, 0

        bra     _ptsYieldSleepSuspend

        .ptsEpilogue _ptsSleepAbsolute


        //////////////////////////////////////////////////////////////////////
        // _ptsSuspend()
        //////////////////////////////////////////////////////////////////////
        //
        // At entry point _ptsSuspend:
        //
        // SPRG0 : &PtsThread
        // D0    : The restart address
        //
        // The continuation address is saved. _ptsYieldSleepSuspend is entered
        // in suspend mode.

        .ptsGlobalFunction _ptsSuspend
_ptsSuspend:

        LOG_DEBUG("_ptsSuspend():Entry:Thread = %p @ %p\n",
                  (void*)(uint32_t)sprg0(),
                  (void*)(uint32_t)d0());

        mr      A0, SPRG0
        std     D0, PTS_THREAD_PC, A0
        
        li      D0, PTS_SUSPENDED
        ls      P0, 1
        bra     _ptsYieldSleepSuspend

        .ptsEpilogue _ptsSuspend


        //////////////////////////////////////////////////////////////////////
        // _ptsTerminateSuspendDie()
        //////////////////////////////////////////////////////////////////////
        //
        // The common entry point _ptsTerminateSuspendDie is used by
        // _ptsTerminate, _ptsSuspend and _ptsKillThread. At entry here:
        //
        // A0 :  &PtsThread
        // D0 :  The special timeout code (PTS_SUSPENDED, PTS_TERMINATED, or
        //       PTS_KILLED used to effectively mark the thread as unrunnable
        //
        // Terminaing threads clear their flags so they will restart cleanly;
        // suspending threads maintain their context.  The stack is cleared
        // prior to invoking the termination handlers.  If the thread has a
        // unique termination handler it is invoked, and then the engine
        // specific handler is invoked if it exists. Finally we re-enter the
        // scheduler.

        .ptsGlobalFunction _ptsTerminateSuspendDie              
_ptsTerminateSuspendDie:

        // First the address of the PtsSchedulerThread is loaded into
        // A1 and the timeout is updated. Set thread flags for
        // suspend/terminated. 

        ld      D1, PTS_THREAD_SCHEDULER_THREAD, A0
        mr      A1, D1
        std     D0, PTS_SCHEDULER_THREAD_NEXT_SCHEDULE, A1

        cmpibrane D0, 1f, PTS_SUSPENDED

                bsi     D0, PTS_THREAD_FLAGS, A0, PTS_THREAD_HAS_CONTEXT
                bra     2f
1:      
                sti     PTS_THREAD_FLAGS, A0, 0
2:      

        // If the thread is running atomic it will eventually return here to
        // die as an atomic violation.

        _ptsLoadPtsState ptsState=A0, scratch=D0

        ldandi  D0, PTS_STATE_FLAGS, A0, PTS_STATE_MAINSTORE_ATOMIC
        braz    D0, 3f

                braa    _ptsThreadAtomicViolation
3:      
        // Clear the stack

        _ptsGetOciBase ptsState=A0, ociBase=A1, scratch=D0
        _ptsClearStack ociBase=A1


        // If the thread has a termination handler, call it
        //
        // A0 :  &PtsState

        mr      A1, SPRG0
        ld      D0, PTS_THREAD_TERMINATION_HANDLER, A1
        braz    D0, 4f

                // A0 :  &PtsState
                // A1 :  &PtsThread
                _ptsBsrd D0

                _ptsLoadPtsState ptsState=A0, scratch=D0
                mr      A1, SPRG0

4:      
        // If PTS defines a thread termination handler, call it after clearing
        // the current thread pointer.
        //
        // A0 :  &PtsState
        // A1 :  &PtsThread

        ld      D0, PTS_STATE_THREAD_TERMINATION_HANDLER, A0
        braz    D0, 5f

                // A0 :  &PtsState
                // A1 :  &PtsThread
                sti     PTS_STATE_CURRENT_THREAD, A0, 0
                _ptsBsrd D0

5:
        bra     _ptsSchedule

        .ptsEpilogue _ptsTerminateSuspendDie


        //////////////////////////////////////////////////////////////////////
        /// _ptsTerminate()
        //////////////////////////////////////////////////////////////////////
        //
        // At entry point _ptsTerminate:
        //
        // Interrupts are disabled
        // SPRG0 : &PtsThread
        // D0    : The termination return code.
        //
        // The PtsThread pointer is moved into A0 and the terminal RC is
        // stored. The common entry point _ptsTerminateSuspendDie() finishes
        // the thread.

        .ptsGlobalFunction _ptsTerminate
_ptsTerminate:

        LOG_DEBUG("_ptsTerminate():Entry:Thread = %p:rc = %d\n",
                  (void*)(uint32_t)sprg0(),
                  (int)d0());

        mr      A0, SPRG0
        std     D0, PTS_THREAD_RC, A0
        
        li      D0, PTS_TERMINATED
        bra     _ptsTerminateSuspendDie

        .ptsEpilogue _ptsTerminate

                        
        //////////////////////////////////////////////////////////////////////
        // _ptsThreadHandlePibErrors
        ////////////////////////////////////////////////////////////////////////////
        //
        // At entry point _ptsThreadHandlesPibErrors:
        //
        // SPRG0 : &PtsThread
        // D0    : The restart address

        .ptsGlobalFunction _ptsThreadHandlesPibErrors
_ptsThreadHandlesPibErrors:
        
        // Set the flag indicating that the thread wants to handle PIB errors,
        // then yield.

        LOG_DEBUG("_ptsThreadHandlesPibErrors:Entry:Thread %p @ %p\n",
                  (void*)(uint32_t)sprg0(), (void*)(uint32_t)d0())

        mr      A0, SPRG0
        ld      D1, PTS_THREAD_FLAGS, A0
        ori     D1, D1, PTS_THREAD_HANDLES_PIB_ERRORS
        std     D1, PTS_THREAD_FLAGS, A0
        bra     _ptsYield
               
         .ptsEpilogue _ptsThreadHandlesPibErrors


        //////////////////////////////////////////////////////////////////////
        // _ptsPtsHandlePibErrors
        ////////////////////////////////////////////////////////////////////////////
        //
        // At entry point _ptsPtsHandlesPibErrors:
        //
        // SPRG0 : The address of the PtsThread structure of the caller
        // D0    : The restart address

        .ptsGlobalFunction _ptsPtsHandlesPibErrors
_ptsPtsHandlesPibErrors:
        
        // Clear the flag indicating that the thread wants to handle PIB
        // errors, then yield.

        LOG_DEBUG("_ptsPtsHandlesPibErrors:Entry:Thread %p @ %p\n",
                  (void*)(uint32_t)sprg0(), (void*)(uint32_t)d0())

        mr      A0, SPRG0
        ld      D1, PTS_THREAD_FLAGS, A0
        andi    D1, D1, ~PTS_THREAD_HANDLES_PIB_ERRORS
        std     D1, PTS_THREAD_FLAGS, A0
        bra     _ptsYield
               
         .ptsEpilogue _ptsPtsHandlesPibErrors


        //////////////////////////////////////////////////////////////////////
        // _ptsStart()
        //////////////////////////////////////////////////////////////////////
        //
        // This is the initial entry point to PTS. Interrupts must be enabled
        // at entry here (HW271773) and the _ptsPublicBranchTable and
        // PTS_DEFAULT_ERROR_MASK are installed.
        //
        // Note that if an interrupt arrives before this code is finished, we
        // are screwed. Whatever process starts PTS needs to guarantee this
        // constraint. This condition can be checked by looking to make sure
        // that
        //
        //     PtsState.schedulerState != PTS_SCHEDULER_STATE_UNINITIALIZED
        
        .ptsGlobalFunction _ptsStart
_ptsStart:

        LOG_DEBUG("_ptsStart():Entry\n")

        // Enable interrupts

        _ptsLoadPtsState ptsState=A0, scratch=D0
        _ptsGetOciBase ptsState=A0, ociBase=A1, scratch=D0


        // Install the public branch table and error mask.
        
        la      D0, _ptsPublicBranchTable
        std     D0, PTS_PORE_TBAR_OFFSET, A1                                

        sti     PTS_PORE_EMR_OFFSET, A1, PTS_DEFAULT_ERROR_MASK  
        

        // Check to make sure this hardware can even run PTS.  This is true of
        // all Venice chips and Murano DD2.0 onward.

        lpcs    P0, PTS_TPC_DEVICE_ID
        ld      D1, PTS_TPC_DEVICE_ID, P0

        extrdi  D0, D1, 8, 12   # 8-bit chip type
        
        cmpibraeq D0, able, PTS_CFAM_CHIP_TYPE_VENICE
        cmpibrane D0, unable, PTS_CFAM_CHIP_TYPE_MURANO

                extrdi  D0, D1, 4, 0    # 4-bit major EC level
                cmpibraeq D0, able, 2
        
                        bra     unable

able:
        sti     PTS_STATE_SCHEDULER_STATE, A0, \
                PTS_SCHEDULER_STATE_STARTED
        bra     ableExit
        
unable: 
        sti     PTS_STATE_SCHEDULER_STATE, A0, \
                PTS_SCHEDULER_STATE_UNABLE
        sti     PTS_STATE_RC, A0, PTS_NOT_SUPPORTED
        bra     unableExit


        // This is called as a subroutine from the SLW application, however as
        // the infinite loop entry from the OCC application. The OCC case will
        // halt here if unable, causing an error to the PTS async
        // code. Otherwise the OCC case disables interrupts and starts
        // scheduling. 

#if CONFIGURE_PTS_SLW

ableExit:       
unableExit:   
        ret

#else

ableExit:
        _ptsDisableInterrupts ociBase=A1, scratch=D0
        bra     _ptsSchedule

unableExit:
        halt
        
#endif // CONFIGURE_PTS_SLW

        .ptsEpilogue _ptsStart
