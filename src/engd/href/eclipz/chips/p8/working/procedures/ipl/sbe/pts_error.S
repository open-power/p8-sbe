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




/// \file pts_error.S
/// \brief PORE Thread Scheduler (PTS) interrupt and error handling

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
// Local Macros
//------------------------------------------------------------------------------

        // Macros to create the public branch table
        //                
        // D0 : Offset of statistics counter (only if CONFIGURE_PTS_STATS)
        // D1 : The table base offset of the event in bytes.

        .macro  _ptsErrorEntry, error:req
        
#if CONFIGURE_PTS_STATS
        ls      D0, PTS_STATE_STAT_ERROR_COUNT + (8 * (\error))
#else
        nop
#endif
        ls      D1, (12 * (\error))
        bra     _ptsPublicError

        .endm


        .macro  _ptsFunctionEntry, function:req
 
#if CONFIGURE_PTS_STATS
        ls      D0, PTS_STATE_STAT_FUNCTION_COUNT + (8 * (\function))
#else
        nop
#endif
        ls      D1, ((5 * 12) + (12 * (\function)))
        bra     _ptsPublicFunction

        .endm

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Text
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////
// Base Address Tables
////////////////////////////////////////////////////////////////////////////
        
        // PTS normally runs with interrupts disabled. PTS enables interrupts
        // at two places:       
        //
        // o At the top of the scheduler loop, after processing any
        //   outstanding command. 
        //
        // o Having found no threads to schedule, at the bottom of the
        //   scheduling loop PTS enters a timed WAIT loop with interrupts
        //   enabled.
        //
        // Due to HW271773, PTS always takes every takeable event through a
        // single branch table, _ptsPublicBranchTable, which is installed in
        // the PORE by _ptsStart(). The action that follows then depends on
        // the PTS scheduler state:
        //
        // - PTS_SCHEDULER_STATE_INTERRUPTIBLE: The event is vectored
        // through the interrupt handler's branch table,
        // PtsState.interruptTable. PTS always installs the interrupt
        // handler's error mask prior to vectoring to the interrupt function.
        //
        // - Other: This event is vectored through PTS' private branch table,
        // _ptsPrivateBranchTable. This private branch table will never take
        // functional interrupts.  Error events are further handled depending
        // on the scheduler state.


        ////////////////////////////////////////////////////////////
        // _ptsPublicBranchTable
        ////////////////////////////////////////////////////////////
        //
        // The PTS public branch table.  All entries vector to either the
        // interrupt handler's table or PTS' private table.

        .ptsGlobalFunction _ptsPublicBranchTable
_ptsPublicBranchTable:

        // 5 error handlers
        
        _ptsErrorEntry 0
        _ptsErrorEntry 1
        _ptsErrorEntry 2
        _ptsErrorEntry 3
        _ptsErrorEntry 4

        // 16 functional handlers

        _ptsFunctionEntry 0
        _ptsFunctionEntry 1
        _ptsFunctionEntry 2
        _ptsFunctionEntry 3
        _ptsFunctionEntry 4
        _ptsFunctionEntry 5
        _ptsFunctionEntry 6
        _ptsFunctionEntry 7
        _ptsFunctionEntry 8
        _ptsFunctionEntry 9
        _ptsFunctionEntry 10
        _ptsFunctionEntry 11
        _ptsFunctionEntry 12
        _ptsFunctionEntry 13
        _ptsFunctionEntry 14
        _ptsFunctionEntry 15

        .ptsEpilogue _ptsPublicBranchTable             


        ////////////////////////////////////////////////////////////
        // _ptsPublicError
        ////////////////////////////////////////////////////////////
        //
        // Vector error events from the public table. If the error is for the
        // interrupt task the interrupt task is completely responsible for
        // handling it. 
        //
        // If the error is for PTS we need to first check to see if we're in
        // mainstore atomic mode. If so this mode has to be disabled
        // before continuing.
        //
        // At entry:
        //
        // D0 : Offset of statistics counter (only if CONFIGURE_PTS_STATS)
        // D1 : The table base offset of the event in bytes.

        .ptsGlobalFunction _ptsPublicError
_ptsPublicError:

        LOG_DEBUG("_ptsPublicError:%d\n", (int)d1() / 12)
        // SIM_BREAK_SIMULATION("Error") # Handy sometimes to stop here
                
#if CONFIGURE_PTS_STATS

        // Increment the statistics counter from the offset in D0. This is a
        // little verbose since PORE does not support indexed addressing.

        mr      A1, D1
        _ptsLoadPtsState ptsState=A0, scratch=D1
        _ptsIncrStateStat ERRORS, ptsState=A0, scratch=D1

        mr      D1, A0
        add     D0, D0, D1
        mr      A0, D0
        ld      D0, 0, A0
        adds    D0, D0, 1
        std     D0, 0, A0
        mr      D1, A1

#endif // CONFIGURE_PTS_STATS

        _ptsLoadPtsState ptsState=A0, scratch=D0
        
        ld      D0, PTS_STATE_SCHEDULER_STATE, A0
        cmpibrane D0, 1f, PTS_SCHEDULER_STATE_INTERRUPTIBLE
                      
                // This error is for the interrupt task.  We assume the
                // interrupt task's error mask is already in effect. If it
                // isn't we can't update it anyway because this error is
                // really for PTS and PTS is uninterruptible.  Thank HW271773
                // for this confusion.

                ld      D0, PTS_STATE_INTERRUPT_TABLE, A0
                add     D0, D0, D1
                _ptsBrad D0

1:      
        // PTS is running. Compute the final branch address. If we're not in
        // atomic mode go ahead and take the error branch.

        la      D0, _ptsPrivateBranchTable
        add     D0, D0, D1
        
        ldandi  D1, PTS_STATE_FLAGS, A0, PTS_STATE_MAINSTORE_ATOMIC
        branz   D1, 1f

                _ptsBrad D0

1:
        // We're atomic. Save D0 in SPRG0 and restore main memory to the
        // default mode. We have to clear the stack first to make this
        // subroutine call. Reconsititute the error branch address and go
        // there.

        mr      SPRG0, D0

        _ptsGetOciBase ptsState=A0, ociBase=A1, scratch=D0
        _ptsClearStack ociBase=A1

        ptsMainstoreDefault

        la      D0, 0
        mr      D1, SPRG0
        ori     D0, D0, D1
        _ptsBrad D0

        .ptsEpilogue _ptsPublicError                

        
        ////////////////////////////////////////////////////////////
        // _ptsPublicFunction
        ////////////////////////////////////////////////////////////
        //
        // Vector function (interrupt) events from the public table. Note that
        // we can't be in a PTS-initiated atomic mainstore mode here.
        //
        // At entry:
        //
        // D0 : Offset of statistics counter (only if CONFIGURE_PTS_STATS)
        // D1 : The table base offset of the event in bytes.
        //
        // Note: All of the optional and conditional code below must maintain
        //       D1 throughout.

        .ptsGlobalFunction _ptsPublicFunction
_ptsPublicFunction:

        LOG_DEBUG("_ptsPublicFunction:%d\n", ((int)d1() / 12) - 5);
        
#if CONFIGURE_PTS_STATS

        // Increment the statistics counter from the offset in D0. This is a
        // little verbose since PORE does not support indexed addressing.
        // After this we're done with D0.

        mr      A1, D1
        _ptsLoadPtsState ptsState=A0, scratch=D1
        _ptsIncrStateStat INTERRUPTS, ptsState=A0, scratch=D1
        
        mr      D1, A0
        add     D0, D0, D1
        mr      A0, D0
        ld      D0, 0, A0
        adds    D0, D0, 1
        std     D0, 0, A0
        mr      D1, A1

#endif // CONFIGURE_PTS_STATS

#if CONFIGURE_PTS_SLW

        // Due to HW273478 and HW273482, EXE-Trigger 32:63 is meaningless when
        // PTS is operating. In order for sleep/winkle to work with PTS, we
        // have to go fetch the core bit mask from PMC_PORE_REQ_REG1 (bits
        // 0:15) and re-insert these bits into EXE-Trigger 32:63.
        //
        // Note: Currently the OCC PTS application does not require these
        // bits, and if it were necessary to pass information to the PORE
        // interrupt handler it could easily be done via SRAM.

        la      A0, PTS_PMC_PORE_REQ_REG1
        ldandi  D0, 0, A0, BITS(0, 16)
        rotldi  D0, D0, 32
        mr      ETR, D0

#endif // CONFIGURE_PTS_SLW

#if CONFIGURE_PTS_TRACE

        // This code creates a TOD-timestamped trace of the contents of the
        // EXE-Trigger register just after each functional interrupt is
        // taken. The trace is stored in the circular TRACE buffer that is
        // part of the PTS state.

        mr      A1, D1
        _ptsLoadPtsState ptsState=A0, scratch=D0
        
        ld      D0, PTS_STATE_TRACE_INDEX, A0
        adds    D0, D0, 1                
        cmpibrane D0, 1f, PTS_STATE_TRACES / 2
                ls      D0, 0
1:      
        std     D0, PTS_STATE_TRACE_INDEX, A0

        sldi    D0, D0, 4
        adds    D0, D0, PTS_STATE_TRACE
        mr      D1, A0
        add     D1, D0, D1

        mr      A0, D1
        mr      D1, ETR
        std     D1, 0, A0
        lpcs    P0, PTS_TOD
        ld      D0, PTS_TOD, P0
        std     D0, 8, A0
        
        mr      D1, A1
                        
#endif // CONFIGURE_PTS_TRACE
        
        _ptsLoadPtsState ptsState=A0, scratch=D0

#if CONFIGURE_PTS_SLW

        // For the PORE-SLW application the PORE DONE override is cleared. The
        // fact that we took an interrupt means that interrupts are enabled so
        // we can clear this bit in spite of HW271773.

        _ptsGetOciBase ptsState=A0, ociBase=A1, scratch=D0
         
        bci     D0, PTS_PORE_CONTROL_OFFSET, A1, PTS_PORE_CONTROL_DONE_OVERRIDE

#endif // CONFIGURE_PTS_SLW
        
        ld      D0, PTS_STATE_SCHEDULER_STATE, A0
        cmpibraeq D0, 1f, PTS_SCHEDULER_STATE_INTERRUPTIBLE
                      
                // PTS is running, use PTS' branch table.  Note that PTS'
                // error mask is already in force.

                la      D0, _ptsPrivateBranchTable
                bra     2f

                // This error or interrupt is for the interrupt task. Install
                // the interrupt handler's error mask before the branch.
1:      
_ptsVectorThroughInterruptTable:  
                ld      D0, PTS_STATE_INTERRUPT_ERROR_MASK, A0
                mr      EMR, D0
                ld      D0, PTS_STATE_INTERRUPT_TABLE, A0
                
2:      
        add     D0, D0, D1
        _ptsBrad D0
        
        .ptsEpilogue _ptsPublicFunction


        ////////////////////////////////////////////////////////////
        // _ptsPrivateBranchTable
        ////////////////////////////////////////////////////////////
        //
        // The PTS private branch table. Error 4 is "unexpected" since PTS
        // sets up the error mask to immediately halt on error 4
        // (Error-on-error).
        //
        // In the original implementation of PTS, all functional vectors
        // caused errors here. This is because we should only be here when we
        // are not interruptible, so the reasoning was if we are getting these
        // interrupts here then something must be amiss. However, 
        // it turns out that if PTS died while non-interruptible, then the
        // origional behavior led to infinite error loops, since any command
        // (enable/disable/idle) coming in in this state was being handled by
        // PTS and being treated as an error.
        //
        // So now, all of the functional vectors that wind up here crowbar the
        // scheduler state into INTERRUPTIBLE and handle the functional
        // interrupt through the interrupt handler's branch table. This
        // is assumed (but not checked or proven by the code) to be an error
        // recovery path. Therefore the DBG registers are cleared and the
        // stack is cleared as well before branching back into the interrupt
        // handler's table.

        .ptsGlobalFunction _ptsPrivateBranchTable
_ptsPrivateBranchTable:

        // 5 error handlers
        
        _ptsBatEntry _ptsError0
        _ptsBatEntry _ptsError1
        _ptsBatEntry _ptsError2
        _ptsBatEntry _ptsError3
        _ptsUnexpectedBatEntry _ptsUnexpected, PTS_UNEXPECTED_THREAD_ERROR4

        // 16 functional handlers

        .macro  _ptsUnexpectedFunction
        bra     _ptsUnexpectedFunctionHandler
        nop
        nop
        .endm

        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction
        _ptsUnexpectedFunction

        .ptsEpilogue _ptsPrivateBranchTable             


        // Note that A0 holds the PTS state here, and D1 must be preserved by
        // this routine, as it contains the branch table entry offset.

        .ptsLocalFunction _ptsUnexpectedFunctionhandler
_ptsUnexpectedFunctionHandler:

        _ptsGetOciBase ptsState=A0, ociBase=A1, scratch=D0

        sti     PTS_STATE_SCHEDULER_STATE, A0, PTS_SCHEDULER_STATE_INTERRUPTIBLE
        ls      D0, 0
        std     D0, PTS_PORE_DBG0_OFFSET, A1
        std     D0, PTS_PORE_DBG1_OFFSET, A1
        _ptsClearStack  ociBase=A1
        bra     _ptsVectorThroughInterruptTable

        .ptsEpilogue _ptsUnexpectedFunctionHandler
        

////////////////////////////////////////////////////////////////////////////
// Subroutines
////////////////////////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////////////////
        // _ptsKillThread
        //////////////////////////////////////////////////////////////////////
        //
        // At entry:     
        //
        // A0 :  &PtsState
        // A1 :  &PtsThread
        // D0 :  Thread PTS return code
        // 
        // Although Ax and Dx state is lost in the event of a thread
        // error, we go ahead and store the stack, Px, CTR and EMR along with
        // DBG0 and DBG1. All non-FFDC register context is set to the pattern
        // 0xa5a5a5a5a5a5a5a5 to avoid confusion over what is real FFDC and
        // what is not. 
        
        .ptsLocalFunction _ptsKillThread
_ptsKillThread:    
         
        LOG_DEBUG("_ptsKillThread:Entry:Thread " FMT_AX " returns %d\n",
                  a0(), (int)d0());
        
        // Clear the current thread pointer from the state to avoid infinite
        // error-loops. Collect thread FFDC. After saving DBG0/1 we unlock the
        // debug registers. 

        sti     PTS_STATE_CURRENT_THREAD, A0, 0
        sti     PTS_STATE_SCHEDULER_STATE, A0, PTS_SCHEDULER_STATE_THREAD_ERROR
        
        
        _ptsGetOciBase ptsState=A0, ociBase=A0, scratch=D1

        li      D1, 0xa5a5a5a5a5a5a5a5
        std     D1, PTS_THREAD_PC, A1
        std     D1, PTS_THREAD_D0, A1
        std     D1, PTS_THREAD_D1, A1
        std     D1, PTS_THREAD_A0, A1
        std     D1, PTS_THREAD_A1, A1

        ld      D1, PTS_PORE_DBG0_OFFSET, A0
        std     D1, PTS_THREAD_DBG0, A1
        
        ld      D1, PTS_PORE_DBG1_OFFSET, A0
        std     D1, PTS_THREAD_DBG1, A1

        sti     PTS_PORE_DBG0_OFFSET, A0, 0
        sti     PTS_PORE_DBG1_OFFSET, A0, 0

        ld      D1, PTS_PORE_PC_STACK0_OFFSET, A0
        std     D1, PTS_THREAD_PC_STACK0, A1

        ld      D1, PTS_PORE_PC_STACK1_OFFSET, A0
        std     D1, PTS_THREAD_PC_STACK1, A1

        ld      D1, PTS_PORE_PC_STACK2_OFFSET, A0
        std     D1, PTS_THREAD_PC_STACK2, A1

        mr      D1, P0
        std     D1, PTS_THREAD_P0, A1
        
        mr      D1, P1
        std     D1, PTS_THREAD_P1, A1

        mr      D1, CTR
        std     D1, PTS_THREAD_CTR, A1

        mr      D1, EMR
        std     D1, PTS_THREAD_EMR, A1


        // If this is error 0, the thread is not already handling error 0,
        // and the thread has a handler for error 0, then restore the
        // thread address in the state, clear the stack, set the PTS state as
        // handling error 0 and invoke the handler.
        //
        // A0 :  OCI Base
        // A1 :  &PtsThread
        // D0 :  Error code    

        cmpibrane D0, 1f, PTS_THREAD_ERROR_0

        ld      D1, PTS_THREAD_ERROR0_HANDLER, A1
        braz    D1, 1f

        _ptsLoadPtsState ptsState=A0, scratch=D1

        ldandi  D1, PTS_STATE_FLAGS, A0, PTS_STATE_HANDLING_ERROR0
        branz   D1, 1f

                mr      D0, A1
                std     D0, PTS_STATE_CURRENT_THREAD, A0

                bsi     D0, PTS_STATE_FLAGS, A0, PTS_STATE_HANDLING_ERROR0

                _ptsGetOciBase ptsState=A0, ociBase=A0, scratch=D0
                _ptsClearStack ociBase=A0

                ld      D0, PTS_THREAD_ERROR0_HANDLER, A1
                _ptsBrad D0

1:
        // Else, Store the PTS RC in the thread and set the RC field to
        // -1. Finally call _ptsTerminateSuspendDie to kill the thread.

        std     D0, PTS_THREAD_PTS_RC, A1
        sti     PTS_THREAD_RC, A1, -1

        mr      A0, A1
        li      D0, PTS_KILLED

        // A0 :  &PtsThread
        // D0 :  Timeout code (PTS_KILLED)
        braa    _ptsTerminateSuspendDie
        
        .ptsEpilogue _ptsKillThread

                        
        //////////////////////////////////////////////////////////////////////
        // _ptsKillPts
        //////////////////////////////////////////////////////////////////////
        //
        // At entry:     
        //
        // A0 :  &PtsState
        // D0 :  The error code
        //
        // Store the error code and DBG and other registers into the state as
        // FFDC. Then clear the stack and branch to the error handler which
        // must be defined. We do not unlock the DBG registers prior to the
        // branch.
        //
        // As a special case for error injection of a double fault, we check
        // to see if a double-fault command is pending, and if so, generate an
        // illegal instruction to double-fault. If we do not handle this
        // specially, then the only way to double fault is to corrupt the PTS
        // code or PTS/system state, which makes the error truly unrecoverable
        // and makes testing much more difficult. Note that you can't 
        // simply set the "debug regs are locked" bit in DBG1 :-(.
        
        .ptsGlobalFunction _ptsKillPts
_ptsKillPts:
        LOG_DEBUG("_ptsKillPts:Entry:RC = %d\n", (int)d0());

        std     D0, PTS_STATE_RC, A0
        sti     PTS_STATE_SCHEDULER_STATE, A0, PTS_SCHEDULER_STATE_PTS_ERROR

        _ptsGetOciBase ptsState=A0, ociBase=A1, scratch=D0
        
        ld      D0, PTS_PORE_DBG0_OFFSET, A1
        std     D0, PTS_STATE_DBG0, A0
        
        ld      D0, PTS_PORE_DBG1_OFFSET, A1
        std     D0, PTS_STATE_DBG1, A0

        ld      D0, PTS_PORE_PC_STACK0_OFFSET, A1
        std     D0, PTS_STATE_PC_STACK0, A0

        ld      D0, PTS_PORE_PC_STACK1_OFFSET, A1
        std     D0, PTS_STATE_PC_STACK1, A0

        ld      D0, PTS_PORE_PC_STACK2_OFFSET, A1
        std     D0, PTS_STATE_PC_STACK2, A0

        ld      D0, PTS_PORE_CONTROL_OFFSET, A1
        std     D0, PTS_STATE_CONTROL, A0

        ld      D0, PTS_PORE_STATUS_OFFSET, A1
        std     D0, PTS_STATE_STATUS, A0

        mr      D0, P0
        std     D0, PTS_STATE_P0, A0
        
        mr      D0, P1
        std     D0, PTS_STATE_P1, A0

        mr      D0, CTR
        std     D0, PTS_STATE_CTR, A0

        mr      D0, EMR
        std     D0, PTS_STATE_EMR, A0

        _ptsClearStack ociBase=A1


        // Double-fault injection special case

        ld      D0, PTS_STATE_COMMAND, A0
        ptsCommandGetCommand record=D0, command=D0
        cmpibrane D0, 1f, PTS_INJECT_DOUBLE_FAULT
        .long   0               # Double fault

        
        // Call the error handler
1:      
        ld      D0, PTS_STATE_PTS_ERROR_HANDLER, A0
        _ptsBrad D0

        .ptsEpilogue _ptsKillPts
        

////////////////////////////////////////////////////////////////////////////
// Error Handlers
////////////////////////////////////////////////////////////////////////////
        
        //////////////////////////////////////////////////////////////////////
        // _ptsError0
        // _ptsError1
        // _ptsError2
        // _ptsError3
        // errorN
        //////////////////////////////////////////////////////////////////////

        // Error 0 is allowed to be handled by the thread, but is fatal to
        // PTS. Errors 1, 2 and 3 are fatal to both threads and PTS itself. If
        // the PTS_STATE_CURRENT_THREAD is non-0 we charge the error to that
        // thread. 

        .ptsLocalFunction errorN
        
_ptsError0:
        LOG_DEBUG("_ptsError0:Entry\n");
        ls      D1, PTS_ERROR_0
        bra     errorN

_ptsError1:
        LOG_DEBUG("_ptsError1:Entry\n");
        ls      D1, PTS_ERROR_1
        bra     errorN

_ptsError2:
        LOG_DEBUG("_ptsError2:Entry\n");
        ls      D1, PTS_ERROR_2
        bra     errorN

_ptsError3:
        LOG_DEBUG("_ptsError3:Entry\n");
        ls      D1, PTS_ERROR_3
        bra     errorN

errorN:
        // If the current thread is non-0 the thread gets blamed, otherwise
        // PTS.
        //
        // D1 :  PTS state error code, add 0x10 to convert to a thread code
        
        _ptsLoadPtsState ptsState=A0, scratch=D0
        ld      D0, PTS_STATE_CURRENT_THREAD, A0
        branz   D0, 1f

                // PTS' fault

                mr      D0, D1
                bra     _ptsKillPts

1:
        // The thread gets blamed

        mr      A1, D0
        mr      D0, D1
        adds    D0, D0, 0x10

        // A0 :  &PtsState
        // A1 :  &PtsThread
        // D0 :  Error code
        bra     _ptsKillThread

        .ptsEpilogue errorN


        //////////////////////////////////////////////////////////////////////
        // _ptsUnexpected
        //////////////////////////////////////////////////////////////////////
        //
        // Set the scheduler state then branch to killPts.
        //
        // D0 : The final return code

        .ptsGlobalFunction _ptsUnexpected
_ptsUnexpected:

        LOG_DEBUG("_ptsUnexpected:RC = %d\n", (int)d0());

        _ptsLoadPtsState ptsState=A0, scratch=D1
        
        sti     PTS_STATE_SCHEDULER_STATE, A0, \
                PTS_SCHEDULER_STATE_UNEXPECTED_ERROR

        // A0 :  &PtsState
        // D0 :  Error code
        bra     _ptsKillPts
        
        .ptsEpilogue _ptsUnexpected


        //////////////////////////////////////////////////////////////////////
        // _ptsThreadAtomicViolation
        //////////////////////////////////////////////////////////////////////
        //
        // A thread made a system call while in an atomic mainstore mode. It
        // will die with this error regardless of whatever else it was doing.
        //
        // SPRG0 :  &PtsThread

        .ptsGlobalFunction _ptsThreadAtomicViolation
_ptsThreadAtomicViolation:

        LOG_DEBUG("_ptsThreadAtomicViolation:Thread = " FMT_SPRG0 "\n", 
                sprg0())

        ptsMainstoreDefault

        _ptsLoadPtsState ptsState=A0, scratch=D0
        mr      A1, SPRG0
        ls      D0, PTS_THREAD_ATOMIC_VIOLATION

        // A0 :  &PtsState
        // A1 :  &PtsThread
        // D0 :  Thread PTS return code
        bra     _ptsKillThread        
        
        .ptsEpilogue _ptsThreadAtomicViolation
