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




/// \file pts_slw_config.S
/// \brief PORE Thread Scheduler (PTS) configuration for the SLW application

//------------------------------------------------------------------------------
// Includes
//------------------------------------------------------------------------------

        .nolist
#include "p8_sbe.H"
#include "proc_slw.H"
#include "pts.h"
#include "p8_homer_map.h"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------

        .oci

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

        // The number of threads supported by the SLW instance of PTS.

        .if     !CONFIGURE_PTS_TEST
                .set    PTS_SLW_THREADS, 1 # 24x7 only
        .else
                .set    PTS_SLW_THREADS, 2 # 2 test threads
        .endif
        

        // The PTS scheduler state

        ptsDeclareState, \
                engine=PORE_ID_SLW, \
                stopped=0, \
                ptsErrorHandler=_ptsSlwErrorHandler, \
                interruptTable=slw_branch_table, \
                interruptErrorMask=SLW_ERROR_MASK, \
                threadTerminationHandler=_ptsSlwThreadTerminationHandler, \
                threadTable=G_pts_slwTable, \
                threadTableEntries=PTS_SLW_THREADS, \
                validThreads=PTS_SLW_THREADS \
                maxWait=PTS_MILLISECONDS(5)


#if !CONFIGURE_PTS_TEST

        // Product-mode configuration.  A single thread runs the 24x7
        // application.

        .global G_pts_slwTable
        ptsDeclareSchedulerThreads \
                symbol=G_pts_slwTable, \
                slots=1, \
                t0=G_ima_24x7_reset_thread

        .global G_ima_24x7_reset_thread
        ptsDeclareThread \
                symbol=G_ima_24x7_reset_thread, \
                table=G_pts_slwTable, \
                slot=0, \
                entryPoint=ima_24x7_reset, \
                error0Handler=ima_24x7_pibErrorHandle


#else

        // The test mode configuration supports 2 threads

        ptsDeclareSchedulerThreads \
                symbol=G_pts_slwTable, \
                slots=2, \
                t0=quickieThread, \
                t1=ballastThread

        ptsDeclareThread \
                symbol=quickieThread, \
                table=G_pts_slwTable, \
                slot=0, \
                entryPoint=quickie

        ptsDeclareThread \
                symbol=ballastThread, \
                table=G_pts_slwTable, \
                slot=1, \
                entryPoint=ballast

#endif // !CONFIGURE_PTS_TEST

//------------------------------------------------------------------------------
// Text
//------------------------------------------------------------------------------

        //////////////////////////////////////////////////////////////////////
        // _ptsEnableFromSlw
        //////////////////////////////////////////////////////////////////////
        //
        // Enable PTS for the PORE-SLW application. This enable is implemented
        // as a full reset of the PTS-SLW state. 
        //
        // During the reset, the HOMER_PTS_DATA structure is initialized. As
        // the thread table is walked to create the pointer table, every
        // mapped thread is "reset" by clearing its flags, which will make the
        // thread restart from its entry point.
        //
        // Finally, we write the address _ptsEntryFromSlw into the global
        // variable slw_terminator, then make a non-returning branch to
        // _ptsEntryFromSlw.
        //
        // At Entry:
        //
        // This entry point is invoked by issuing PORE command 15 through the
        // EXE-Trigger register.  Prior to issuing the command all cores must
        // be under special wakeup and the PORE-SLW must be 
        // halted. This invariant is not checked by this routine.

        .ptsGlobalFunction _ptsEnableFromSlw
_ptsEnableFromSlw:

        // Set the scheduler state to uninitialized, no RC, no command.
        
        _ptsLoadPtsState ptsState=A0, scratch=D0

        sti     PTS_STATE_SCHEDULER_STATE, A0, \
                PTS_SCHEDULER_STATE_UNINITIALIZED
        ls      D0, 0
        std     D0, PTS_STATE_RC, A0
        std     D0, PTS_STATE_COMMAND, A0


        // Initialize the static portion of the PtsHomerData. PHYP prefers
        // that the PtsHomerData addresses be physical addresses, and also
        // requires fields containing structure sizes.

        // We get the physical base address of SLW image data areas from PBA
        // BAR 2, and hold it in D1. The PBA BAR has scope information in bits
        // 0:2 that needs to be masked out. Also note that these images are
        // linked at 0x80000000 and relocated to 0x0, so addresses need to be
        // masked before adding to the physical base address.

        // *NB*: PBA addressing is confusing here. It was decided to relocate
        // the SLW image using PBA BAR 2, which is a fixed 2MB (0x200000) from
        // the start of the Homer image, whereas the HOMER offsets are all
        // relative to effective address 0x0 (PBA BAR 0).
            
        PHYSICAL_ADDRESS_MASK = 0x000000000fffffff
        
        la      A1, HOMER_PTS_DATA
        
        lpcs    P0, PBA_BAR2_0x02013F02
        ldandi  D1, PBA_BAR2_0x02013F02, P0, 0x1fffffffffffffff

        // Store PtsHomerData.sizeofPtsState

        ls      D0, SIZE_OF_PTS_STATE
        std     D0, PTS_HOMER_DATA_SIZE_OF_PTS_STATE, A1

        // Store PtsHomeData.state

        la      D0, G_pts_slwState
        andi    D0, D0, PHYSICAL_ADDRESS_MASK
        add     D0, D0, D1
        std     D0, PTS_HOMER_DATA_STATE, A1

        // Store PtsHomerData.sizeofThreadTable

        ls      D0, PTS_SLW_THREADS * SIZE_OF_PTS_SCHEDULER_THREAD
        std     D0, PTS_HOMER_DATA_SIZE_OF_THREAD_TABLE, A1

        // Store PtsHomerData.threadTable

        ld      D0, PTS_STATE_THREAD_TABLE, A0
        andi    D0, D0, PHYSICAL_ADDRESS_MASK
        add     D0, D0, D1
        std     D0, PTS_HOMER_DATA_THREAD_TABLE, A1

        // Store PtsHomerData.nThreads
        
        ls      D0, PTS_SLW_THREADS
        std     D0, PTS_HOMER_DATA_N_THREADS, A1

        // Store PtsHomerData.sizeofPtsThread

        ls      D0, SIZE_OF_PTS_THREAD
        std     D0, PTS_HOMER_DATA_SIZE_OF_PTS_THREAD, A1         


        // Now to run down the thread table, storing thread body addresses to
        // the HOMER area, and resetting the threads. PORE is so limited that
        // we need to use (rename temporarily) a few fields of the state
        // to store the current HOMER address and the current scheduler table
        // and thread addresses.

        HOMER_POINTER = PTS_STATE_DBG0
        TABLE_POINTER = PTS_STATE_DBG1
        THREAD_POINTER = PTS_STATE_PC_STACK0

        mr      D0, A1
        adds    D0, D0, PTS_HOMER_DATA_THREAD
        std     D0, HOMER_POINTER, A0
        
        ld      D0, PTS_STATE_THREAD_TABLE, A0
        std     D0, TABLE_POINTER, A0

        ls      D0, PTS_SLW_THREADS
        mr      CTR, D0
        
        bra     enableContinue

enableLoop:
                // For each thread, first reset the thread, mung the
                // address and store it in the PtsHomerData. Clearing the
                // thread flags marks the thread as having no context. For
                // good measure we also clear the RC and PTS RC. 

                // A1 <- TABLE_POINTER++

                ld      D0, TABLE_POINTER, A0
                mr      A1, D0
                adds    D0, D0, SIZE_OF_PTS_SCHEDULER_THREAD
                std     D0, TABLE_POINTER, A0
                        
                // D0 <- &PtsThread; Short circuit if null

                ld      D0, PTS_SCHEDULER_THREAD_THREAD, A1
                std     D0, THREAD_POINTER, A0
                braz    D0, 1f

                        // Reset the thread to an initial, runnable state.
        
                        sti     PTS_SCHEDULER_THREAD_NEXT_SCHEDULE, A1, 0
        
                        mr      A1, D0
                        ls      D0, 0
                        std     D0, PTS_THREAD_FLAGS, A1
                        std     D0, PTS_THREAD_RC, A1
                        std     D0, PTS_THREAD_PTS_RC, A1

#if CONFIGURE_PTS_STATS
                        std     D0, PTS_THREAD_MAX_LATENCY, A1
#endif

1:      
                // Store physical address or null
        
                ld      D0, HOMER_POINTER, A0
                mr      A1, D0
                ld      D0, THREAD_POINTER, A0
                braz    D0, 1f
        
                        andi    D0, D0, PHYSICAL_ADDRESS_MASK
                        add     D0, D0, D1
1:      
                std     D0, 0, A1

                // HOMER_POINTER++

                mr      D0, A1
                adds    D0, D0, 8
                std     D0, HOMER_POINTER, A0
        
enableContinue: 
        loop    enableLoop


        // Reset is done, now start.        

        la      D0, _ptsEntryFromSlw
        la      A0, slw_terminator
        std     D0, 0, A0
        bra     _ptsEntryFromSlw

        .ptsEpilogue _ptsEnableFromSlw

        
        //////////////////////////////////////////////////////////////////////
        // _ptsDisableFromSlw
        //////////////////////////////////////////////////////////////////////
        //
        // Disable PTS for the PORE-SLW application by writing 0
        // into the global variable slw_terminator. The PTS state object is
        // also marked as "uninitialized" and the RC is cleared. 
        // The interrupt table and error mask are restored so that PTS code is
        // fully out of the picture. The PORE-SLW is then halted.
        //
        // At Entry:
        //
        // This entry point is invoked by issuing PORE command 14 through the
        // EXE-Trigger register.  Prior to issuing the command all cores must
        // be under special wakeup and the PORE-SLW must be 
        // halted. This invariant is not checked by this routine.

        .ptsGlobalFunction _ptsDisableFromSlw
_ptsDisableFromSlw:

        la      A0, slw_terminator
        sti     0, A0, 0

        _ptsLoadPtsState ptsState=A0, scratch=D0
        _ptsGetOciBase ptsState=A0, ociBase=A1, scratch=D0
        
        sti     PTS_STATE_SCHEDULER_STATE, A0, \
                PTS_SCHEDULER_STATE_UNINITIALIZED
        sti     PTS_STATE_RC, A0, 0

        ld      D0, PTS_STATE_INTERRUPT_TABLE, A0
        std     D0, PTS_PORE_TBAR_OFFSET, A1
        ld      D0, PTS_STATE_INTERRUPT_ERROR_MASK, A0
        mr      EMR, D0


        halt

        .ptsEpilogue _ptsDisableFromSlw

        //////////////////////////////////////////////////////////////////////
        // _ptsEntryFromSlw
        //////////////////////////////////////////////////////////////////////
        //
        // Re-enter PTS from handling a SLW deep-idle command. This entry
        // point is also used when PTS is (re-)enabled.
        //
        // By definition interrupts are enabled at entry - otherwise we
        // wouldn't be here. Another interrupt from the PMC can't fire until
        // we set the DONE overide.
        //
        // If PTS has not been initialized, clear the stack and call
        // _ptsStart(), which for the SLW application is a subroutine
        // call. _ptsStart() may decide that PTS is unable to run due to the
        // chip DD-level, and in that case we simply halt as the normal SLW
        // code would do.
        //
        // Due to HW271773, PTS' error mask must be re-established here while
        // interrupts are enabled.
        //
        // Next we disable interrupts and manually set the DONE
        // override to signal PMC that this interrupt is finished. Since we
        // are setting this bit we can do this with interrupts disabled in
        // spite of HW271773. The protocol in use by PTS is to override DONE
        // until the next interrupt fires. The DONE override is cleared in the
        // _ptsPublicVector() routine in pts_error.S. 
        //
        // This protocol allows us to always re-enter the scheduler and
        // process any outstanding command before reenabling interrupts.
        //
        // Prior to branching to _ptsSchedule, bits 32:63 of the ETR are
        // written with 0xFFFFFFFF, to signal PHYP (in the case of the
        // PORE-SLW application) that initialization is complete, PTS is
        // running, and it is safe to resume operations.
        
        .ptsGlobalFunction _ptsEntryFromSlw
_ptsEntryFromSlw:       

        _ptsLoadPtsState ptsState=A0, scratch=D0
        _ptsGetOciBase ptsState=A0, ociBase=A1, scratch=D0

        ld      D0, PTS_STATE_SCHEDULER_STATE, A0
        cmpibrane D0, 1f, PTS_SCHEDULER_STATE_UNINITIALIZED

                _ptsClearStack ociBase=A1
                bsr     _ptsStart
                bra     _ptsEntryFromSlw # Recur to re-establish A0/A1/D0
1:      
        cmpibrane D0, 2f, PTS_SCHEDULER_STATE_UNABLE 
        
                halt
2:
        li      D0, PTS_DEFAULT_ERROR_MASK
        mr      EMR, D0

        _ptsDisableInterrupts ociBase=A1, scratch=D0

        ld      D0, PTS_PORE_CONTROL_OFFSET, A1
        ori     D0, D0, PTS_PORE_CONTROL_DONE_OVERRIDE
        std     D0, PTS_PORE_CONTROL_OFFSET, A1

        li      D0, 0x00000000ffffffff
        mr      ETR, D0

        braa    _ptsSchedule
        
        .ptsEpilogue _ptsEntryFromSlw


        //////////////////////////////////////////////////////////////////////
        // _ptsSlwErrorHandler
        //////////////////////////////////////////////////////////////////////

        // In the event that PTS catches its own error, or in the event that a
        // thread terminates with a non-0 return code, PTS-SLW:  
        //
        // 0. Unlocks the debug registers.
        // 1. Writes a 0 into 'slw_terminator', effectively disabling PTS.
        // 2. Sets PMC FIR bit 38.  This generates a malfunction alert.
        // 3. Enables interrupts
        // 4. Halts
        //
        // Note that if PMC had an interrupt pending that it will be handled
        // normally, and when the deep-idle operation completes it will also
        // simply halt since we have cleared the slw_terminator. SLW
        // recovery code seeing FIR bit 38 must be aware that the SLW may
        // still be executing deep idle operations.
        //
        // Note that we try to restore the normal error mask and branch table
        // but we can't do it reliably due to HW271773. So we mark the state
        // as INTERRUPTIBLE so that if an interrupt is pending here it will be
        // handled properly. The HMI recovery handler should disable PTS to
        // make sure that the base error mask and branch table have been
        // re-established.
        //
        // At entry, all FFDC has been saved, and:
        //
        // - A0 : &PtsState
        // - A1 : OCI Base Address of the engine

        .ptsGlobalFunction _ptsSlwErrorHandler
_ptsSlwErrorHandler:

        ls      D0, 0
        std     D0, PTS_PORE_DBG0_OFFSET, A1
        std     D0, PTS_PORE_DBG1_OFFSET, A1
        
        mr      D0, A1
        la      A1, slw_terminator
        sti     0, A1, 0
        mr      A1, D0

        lpcs    P0, PMC_LFIR_OR_0x01010842
        sti     PMC_LFIR_OR_0x01010842, P0, BIT(38)

        sti     PTS_STATE_SCHEDULER_STATE, A0, \
                PTS_SCHEDULER_STATE_INTERRUPTIBLE 
        _ptsEnableInterrupts ociBase=A1, scratch=D0

        ld      D0, PTS_STATE_INTERRUPT_TABLE, A0
        std     D0, PTS_PORE_TBAR_OFFSET, A1
        ld      D0, PTS_STATE_INTERRUPT_ERROR_MASK, A0
        mr      EMR, D0

        halt

        .ptsEpilogue _ptsSlwErrorHandler
        

        /////////////////////////////////////////////////////////////////////
        // _ptsSlwThreadTerminationHandler
        //////////////////////////////////////////////////////////////////////
        //
        // At entry, all FFDC has been saved, and:
        //
        // - A0 : &PtsState
        // - A1 : &PtsThread
        //
        // If the thread RC is 0, we don't do anything and simply reenter the
        // scheduler. Otherwise we change A1 to be the OCI base address, add
        // the PTS failure return code and then go to the PTS error handler.

        .ptsGlobalFunction _ptsSlwThreadTerminationHandler
_ptsSlwThreadTerminationHandler:

        ld      D0, PTS_THREAD_RC, A1
        braz    D0, _ptsSchedule

        ls      D0, PTS_SLW_THREAD_FAILURE
        std     D0, PTS_STATE_RC, A0

        _ptsGetOciBase ptsState=A0, ociBase=A1, scratch=D0
        bra       _ptsSlwErrorHandler
        
        .ptsEpilogue _ptsSlwThreadTerminationHandler


////////////////////////////////////////////////////////////////////////////
// Development/Bringup configuration
////////////////////////////////////////////////////////////////////////////

#if !CONFIGURE_PTS_TEST

        // A placeholder stub that can be used in lieu of the real 24x7 thread.
        
        .ptsGlobalFunction ima_24x7_stub
ima_24x7_stub:
        lpcs    P0, TOD_VALUE_REG_00040020
        la      A0, ima_24x7_tod
1:      
                ld      D0, TOD_VALUE_REG_00040020, P0
                std     D0, 0, A0
                ptsSleepConstant PTS_MILLISECONDS(10), A0, P0
                bra     1b

        .ptsEpilogue ima_24x7_stub

        .ptsGlobalData ima_24x7_tod
ima_24x7_tod:
        .quad 0

#else

        // For bringup shifts two trivial threads are defined. The
        // "quickie" thread runs every 1ms and simply increments a counter in
        // main memory. The "ballast" thread runs every 10ms, stalling for
        // 50us before incrementing its counter using atomic add. The
        // "ballast" thread also sleeps inside 2-levels of subroutine call.

        // Note that PTS system calls and APIs are much more thoroughly tested
        // using the OCC version of PTS. This configuration provides a
        // simple test for bringup.

        // The counters are explicitly located at the end of the 1MB SLW space
        // on PBA BAR 2
        
        .set    SLW_SPACE_BASE, 0x20000000
        .set    SLW_SPACE_SIZE, 0x00100000
        .set    quickieCounter, SLW_SPACE_BASE + SLW_SPACE_SIZE - (1 * 8)
        .set    ballastCounter, SLW_SPACE_BASE + SLW_SPACE_SIZE - (2 * 8)

                .ptsLocalFunction quickie
quickie:

        la      A0, quickieCounter
0:
                ld      D0, 0, A0
                adds    D0, D0, 1
                std     D0, 0, A0
        
                ptsSleepConstant PTS_MILLISECONDS(1), A0
        
                bra     0b

        .ptsEpilogue quickie


        .ptsLocalFunction ballast
ballast:
0:
                waits   25000 # 50us @ 500 MHx

                ptsMainstoreAtomicAdd

                la      A0, ballastCounter # NB: A0 destroyed by APIs
                sti     0, A0, 1

                ptsMainstoreDefault
        
                bsr     1f
                bra     0b
1:
                bsr     2f
                ret
2:      
                ptsSleepConstant PTS_MILLISECONDS(10)
                ret

        .ptsEpilogue ballast

        
#endif // !CONFIGURE_PTS_TEST
