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




/// \file pts_command.S
/// \brief The internal _ptsCommand() API
///
/// _ptsCommand() is always called at the top of the main scheduler loop if a
/// command is waiting to be processed. The commmand is immediately processed
/// and the response is generated. 
///
/// The SLW application uses a polling protocol to perodicially check for
/// commands in the absence of idle events or thread scheduling. In the SLW
/// application the response is simply placed into the PtsState.response field
/// once the command is complete.
///
/// The OCC application is purely interrupt-driven; Every interrupt causes the
/// command to be checked. In the OCC application command responses are placed
/// into PtsState.response, as well as into the completion queue for
/// processing by the OCC infrastructure.

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

        //////////////////////////////////////////////////////////////////////
        // _ptsCommand()
        //////////////////////////////////////////////////////////////////////
        //
        // At entry:
        //
        // Called from the top level
        // Interrupts are disabled
        // A0 : &PtsState
        // D0 : The command
        //
        // At exit:
        //
        // A0 : &PtsState

        .ptsGlobalFunction _ptsCommand
_ptsCommand:

        // Clear the command field and case split on the command.

        mr      D1, D0
        ls      D0, 0
        std     D0, PTS_STATE_COMMAND, A0            

        ptsCommandGetCommand record=D1, command=D0

        cmpibraeq D0, startPts, PTS_START_PTS
        cmpibraeq D0, stopPts, PTS_STOP_PTS        
        cmpibraeq D0, scheduleThread, PTS_SCHEDULE_THREAD
        cmpibraeq D0, suspendThread, PTS_SUSPEND_THREAD
        cmpibraeq D0, terminateThread, PTS_TERMINATE_THREAD
        cmpibraeq D0, removeThread, PTS_REMOVE_THREAD
        cmpibraeq D0, scomError, PTS_INJECT_SCOM_ERROR
        cmpibraeq D0, ociError, PTS_INJECT_OCI_ERROR
        cmpibraeq D0, instructionError, PTS_INJECT_INSTRUCTION_ERROR
        cmpibraeq D0, doubleFault, PTS_INJECT_DOUBLE_FAULT

        ls      D0, PTS_INVALID_COMMAND
        bra     finish             
        

        //////////////////////////////////////////////////////////////////////
        // Invariant for all command processors:
        //
        // A0 :  The scheduler state
        // D1 :  The command record
        //////////////////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////////////////
        // PTS_START_PTS
        //////////////////////////////////////////////////////////////////////

        // Set the scheduler state and clear the RC.

startPts:
        ls      D0, PTS_SCHEDULER_STATE_SCHEDULING
        std     D0, PTS_STATE_SCHEDULER_STATE, A0
        ls      D0, 0
        std     D0, PTS_STATE_RC, A0
        bra     finish


        //////////////////////////////////////////////////////////////////////
        // PTS_STOP_PTS
        //////////////////////////////////////////////////////////////////////

        // Set the scheduler state and clear the RC.

stopPts:
        ls      D0, PTS_SCHEDULER_STATE_STOPPED
        std     D0, PTS_STATE_SCHEDULER_STATE, A0
        ls      D0, 0
        std     D0, PTS_STATE_RC, A0
        bra     finish

        
        //////////////////////////////////////////////////////////////////////
        // PTS_SCHEDULE_THREAD
        //////////////////////////////////////////////////////////////////////

        // If the thread exists, mark it as runnable

scheduleThread:

        bsr     _ptsThreadExists
        branz   D0, finish

        ls      D0, PTS_RUNNABLE
        std     D0, PTS_SCHEDULER_THREAD_NEXT_SCHEDULE, A1

        ls      D0, 0
        bra     finish

        
        //////////////////////////////////////////////////////////////////////
        // PTS_SUSPEND_THREAD
        //////////////////////////////////////////////////////////////////////

        // If the thread exists, mark it force-suspended

suspendThread:

        bsr     _ptsThreadExists
        branz   D0, finish

        sti     PTS_SCHEDULER_THREAD_NEXT_SCHEDULE, A1, PTS_FORCE_SUSPENDED

        ls      D0, 0
        bra     finish


        //////////////////////////////////////////////////////////////////////
        // PTS_TERMINATE_THREAD
        //////////////////////////////////////////////////////////////////////

        // If the thread exists, mark it force-terminated

terminateThread:

        bsr     _ptsThreadExists
        branz   D0, finish

        sti     PTS_SCHEDULER_THREAD_NEXT_SCHEDULE, A1, PTS_FORCE_TERMINATED
        ld      D0, PTS_SCHEDULER_THREAD_THREAD, A1
        
        sti     PTS_THREAD_FLAGS, A1, 0

        ls      D0, 0
        bra     finish
        
        
        //////////////////////////////////////////////////////////////////////
        // PTS_REMOVE_THREAD
        //////////////////////////////////////////////////////////////////////

        // If the thread exists, remove it from the thread scheduler table.

removeThread:

        bsr     _ptsThreadExists
        branz   D0, finish

        li      D0, PTS_TERMINATED
        std     D0, PTS_SCHEDULER_THREAD_NEXT_SCHEDULE, A1
                
        ls      D0, 0
        std     D0, PTS_SCHEDULER_THREAD_THREAD, A1

        bra     finish


        //////////////////////////////////////////////////////////////////////
        // Error Injection
        //////////////////////////////////////////////////////////////////////

        // Error injection commands. Each command includes a final
        // branch-to-self to catch cases where the errors are not detected
        // (which should not happen). Note that double-fault is emulated in
        // _ptsKillPts (pts_error.S) for reasons explained there, and requires
        // the double-fault command to be re-inserted.

scomError:
        ls      P0, 0
        ld      D0, 0, P0       # getscom 0x0, illegal
        bra     .

ociError:
        la      A0, 0xfff00000  # Illegal OCI address in SRAM space
        ld      D0, 0, A0
        bra     .

instructionError:
        .long   0               # 0 is an illegal instruction
        bra     .

doubleFault:    
        sti     PTS_STATE_COMMAND, A0, (PTS_INJECT_DOUBLE_FAULT << 56)
        .long   0               # 0 is an illegal instruction
        bra     .

        
        //////////////////////////////////////////////////////////////////////
        // Finish
        //////////////////////////////////////////////////////////////////////

        // A0 :  &PtsState
        // D0 :  The response code
        //
        // The response code is stored into the PTS state. In the case of the
        // OCC application, a response is also generated into the completion
        // queue. 
finish: 
        std     D0, PTS_STATE_RESPONSE, A0

#if !CONFIGURE_PTS_SLW

        ls      D1, 0
        ptsCompletionSetRc record=D1, rc=D0
        ls      D0, PTS_COMMAND_COMPLETION
        ptsCompletionSetCompletion record=D1, completion=D0

        mr      D0, D1
        bsr     _ptsWriteCompletionRecord

#endif

        ret                

        .ptsEpilogue _ptsCommand
        
        
        //////////////////////////////////////////////////////////////////////
        // _ptsThreadExists
        ////////////////////////////////////////////////////////////////////////////
        //
        // Determine if a priority named in a command is legal, and if so,
        // whether there is a thread mapped at that priority.
        //
        // At entry:
        //
        // A0 :  &PtsState
        // D1 :  The command record
        //
        // At exit:
        // 
        // A0 :  &PtsState
        // D0 :  Either 0 to indicate success or a failure code.
        // D1 :  If successful, the address of the PtsSchedulerThread.
        // A1 :  If successful, the address of the PtsSchedulerThread.

        .ptsLocalFunction _ptsThreadExists
_ptsThreadExists:

        // Get the thread priority from the command record and check that it
        // is even in bounds.

        ptsCommandGetPriority record=D1, priority=D0
        ld      D1, PTS_STATE_THREAD_TABLE_ENTRIES, A0
        sub     D1, D0, D1
        tfbult  D1, 1f

        ls      D0, PTS_INVALID_PRIORITY
        ret

1:
        // Compute the address of the PtsSchedulerThread into D1 and see if
        // there is a thread mapped there

        .if     (SIZE_OF_PTS_SCHEDULER_THREAD != 16)
        .err    "SIZE_OF_PTS_SCHEDULER_THREAD expected to be 16"
        .endif

        sldi    D0, D0, 4
        ld      D1, PTS_STATE_THREAD_TABLE, A0
        add     D1, D0, D1
        mr      A1, D1
        ld      D0, PTS_SCHEDULER_THREAD_THREAD, A1
        branz   D0, 2f

        ls      D0, PTS_THREAD_NOT_FOUND
        ret

2:
        // The normal exit.  The address of the scheduler thread is already in
        // A1/D1, a 0 in D0 indicates a good return.

        ls      D0, 0
        ret

        .ptsEpilogue _ptsThreadExists


#if !CONFIGURE_PTS_SLW

        //////////////////////////////////////////////////////////////////////
        // _ptsWriteCompletionRecord
        ////////////////////////////////////////////////////////////////////////////
        //
        // Write a completion record into the OCC completion queue.  If the
        // completion queue is full it is considered an unrecoverable fatal
        // error.
        //
        // At entry:
        //
        // A0 :  &PtsState
        // D0 :  The completion record
        //
        // At exit:
        // 
        // A0 :  &PtsState

        .ptsGlobalFunction _ptsWriteCompletionRecord
_ptsWriteCompletionRecord:

        // We just don't have enough register state to keep the completion
        // record in the PORE while we do the pointer math, so we have to
        // commit the record to memory temporarily.

        std     D0, PTS_STATE_TEMP0, A0


        // Compute the next write index into D0, modulo the number of entries

        ld      D0, PTS_STATE_COMPLETION_QUEUE, A0
        mr      A1, D0
        ld      D0, PTS_COMPLETION_QUEUE_WRITE_INDEX, A1
        ld      D1, PTS_COMPLETION_QUEUE_ENTRIES, A1
        adds    D0, D0, 1
        sub     D1, D0, D1
        branz   D1, 1f

                ls      D0, 0
1:      

        // Check for a full queue - new Write Index == current Read Index.

        ld      D1, PTS_COMPLETION_QUEUE_READ_INDEX, A1
        sub     D1, D0, D1
        branz   D1, 1f


            // Queue is full.  There is no return from _ptsKillPts.

            LOG_ERROR("The PTS completion queue is full. "
                      "New Write Index == Old Read Index == %d\n",
                      (int)io_pore.d0.read())

            ls      D0, PTS_COMPLETION_QUEUE_FULL
            braa    _ptsKillPts

1:
        // A0 : &PtsState
        // A1 : &PtsCompletionQueue
        // D0 : Write index
        //
        // Compute the record address into A1.  Then reload the completion
        // record and store it. This requires temporarily converting the write
        // index into a byte offset.

        ld      D1, PTS_COMPLETION_QUEUE_DATA, A1
        sldi    D0, D0, 3
        add     D1, D0, D1
        mr      A1, D1
        srdi    D0, D0, 3
        ld      D1, PTS_STATE_TEMP0, A0
        std     D1, 0, A1

        LOG_DEBUG("Storing completion record 0x%016llx "
                  "at index %d (address 0x%08x)\n",
                  (unsigned long long)io_pore.d1.read(),
                  ((int)(io_pore.d0.read())) / 8,
                  ((uint32_t)(io_pore.a1.read())))

        // A0 : &PtsState
        // D0 : Write index
        //
        // The completion record is now commited to memory. Reload the address
        // of the completion queue back into A1 and store the new write index.

        ld      D1, PTS_STATE_COMPLETION_QUEUE, A0
        mr      A1, D1
        std     D0, PTS_COMPLETION_QUEUE_WRITE_INDEX, A1

        ret

        .ptsEpilogue _ptsWriteCompletionRecord

#endif // !CONFIGURE_PTS_SLW
        
