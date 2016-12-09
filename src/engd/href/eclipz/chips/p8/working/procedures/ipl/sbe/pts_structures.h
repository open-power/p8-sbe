/* IBM_PROLOG_BEGIN_TAG                                                   */
/* This is an automatically generated prolog.                             */
/*                                                                        */
/* OpenPOWER Project                                                      */
/*                                                                        */
/* Contributors Listed Below - COPYRIGHT 2012,2016                        */
/* [+] International Business Machines Corp.                              */
/*                                                                        */
/*                                                                        */
/* Licensed under the Apache License, Version 2.0 (the "License");        */
/* you may not use this file except in compliance with the License.       */
/* You may obtain a copy of the License at                                */
/*                                                                        */
/*     http://www.apache.org/licenses/LICENSE-2.0                         */
/*                                                                        */
/* Unless required by applicable law or agreed to in writing, software    */
/* distributed under the License is distributed on an "AS IS" BASIS,      */
/* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or        */
/* implied. See the License for the specific language governing           */
/* permissions and limitations under the License.                         */
/*                                                                        */
/* IBM_PROLOG_END_TAG                                                     */



#ifndef __PTS_STRUCTURES_H__
#define __PTS_STRUCTURES_H__


/// \file pts_structures.h
/// \brief PORE Thread Scheduler (PTS) data structures
///
/// This header contains both C and PORE assembler definitions of PTS
/// structures and structure access.

#include "pts_config.h"

#ifndef __ASSEMBLER__

#include <stdint.h>

#endif // __ASSEMBLER__


////////////////////////////////////////////////////////////////////////////
// Assembler Macros
////////////////////////////////////////////////////////////////////////////

#ifdef __ASSEMBLER__


        // This macro defines structure offsets for PORE assembler-versions of
        // structures.

        .macro  _ptsStructField, field:req, size=8
\field\():
        .struct \field + (\size)
        .endm

        
         // This macro converts optional pointers defaulting to 'null' to a
         // 0x0 quadword, otherwise generates a .quada address for the
         // pointer.

        .macro  _ptsOptionalPointer, ptr:req
        .ifc    \ptr, null
                .quad   0
        .else
                .quada  (\ptr)
        .endif
        .endm

#endif // __ASSEMBLER__


////////////////////////////////////////////////////////////////////////////
// Scheduler-Private Structures
////////////////////////////////////////////////////////////////////////////

/// The PTS scheduler state
///
/// A unique instance of the scheduler state must be allocated for each engine
/// running PTS.
        
#ifndef __ASSEMBLER__

typedef struct {

    // *** Fields required to be initialized (6 quadwords) *** //

    /// The current state of the PTS scheduler
    ///
    /// This field is volatile to allow it to be polled from C code.
    ///
    /// *NB* - DO NOT MOVE THIS FIELD, REQUIRED BY PHYP TO BE FIRST FIELD - *NB*
    volatile uint64_t schedulerState;

    /// Is PTS thread scheduling stopped?
    /// 
    /// If this flag is set then it simply means that PTS thread scheduling is
    /// suspended.  Command processing and interrupt handling continue, and
    /// the scheduler state continues to evolve.
    uint64_t stopped;
        
    /// The OCI base address of the PORE engine
    uint64_t ociBase;

    /// The 48-bit address of a handler for PTS fatal errors
    ///
    /// This handler is required, and is invoked whenever any error occurs in
    /// the PTS scheduler code itself. Any errors that occur during execution
    /// of thread code will be handled either by calling the thread's handler
    /// (if it exists) or terminating the thread. Any error-on-error always
    /// halts PTS.
    ///
    /// This handler is an entry point only, not a subroutine. The handler
    /// must decide which action to take and how or if to continue PTS. At
    /// entry the error code and FFDC has been saved in the state, the stack
    /// has been cleared but the debug registers have \e not been unlocked.
    ///
    /// At entry to the handler:
    ///
    /// - A0 : &PtsState
    /// - A1 : The OCI base address of the engine
    ///
    uint64_t ptsErrorHandler;

    /// The 48-bit PORE Table Base Address of the interrupt handler
    ///
    /// When an interrupt occurs, PTS "takes" the interrupt with its own PORE
    /// base address table, installs the interrupt handler's error mask, then
    /// vectors through this table to run the requested function.
    uint64_t interruptTable;

    /// The Error Mask Register setting used the interrupt handler
    ///
    /// When an interrupt occurs, PTS "takes" the interrupt with its own PORE
    /// base address table, installs the interrupt handler's error mask, then
    /// vectors through this table to run the requested function.
    uint64_t interruptErrorMask;


    // *** Fields optionally initialized (8 quadwords) *** //

    /// The optional termination handler for all threads
    ///
    /// This field can be initialized to a non-0 value to specify a generic
    /// handler that is invoked whenever any thread is terminated, suspended
    /// or killed. This handler is called after any thread-specific
    /// termination handler is invoked. This handler is a subroutine called
    /// with an empty stack.  The thread return code has already been stored
    /// in the PtsThread->rc field. If PTS killed the thread then the non-0
    /// PTS return code will be found in PtsThread->ptsRc field and
    /// PtsThread->rc will be set to -1. The following parameters are provided
    /// to the handler:
    ///
    /// - A0 : &PtsState
    /// - A1 : &PtsThread
    ///
    /// This handler will be used by the OCC application to invoke 'async'
    /// signalling for terminating threads.
    uint64_t threadTerminationHandler;

    /// A pointer to the table of PtsSchedulerThread for the threads scheduled
    /// by this instance of PTS
    uint64_t threadTable;

    /// The number of entries allocated in the thread table
    uint64_t threadTableEntries;

    /// The index of the last (lowest priority) valid thread + 1
    ///
    /// This field is an optimization that allows the scheduler to terminate
    /// looking for schedulable threads without scanning the entire
    /// thread table. This value is read-only to PTS.
    uint64_t validThreads;

    /// A command to PTS. For legal values see \ref pts_command
    ///
    /// The external control environment can issue commands to PTS by writing
    /// instances of the PtsCommand structures into this field. PTS looks for
    /// a non-0 value in this field at the top of every scheduling loop, and
    /// clears this field prior to processing the command.
    ///
    /// The response to the command appears in the response field. The
    /// external control environment should write the response field to -1
    /// prior to issuing the command. PTS will overwrite the response field
    /// with the response code once the command is complete.
    ///
    /// The external control environment is responsible for serializing access
    /// to the single command/response interface provided by PTS.
    uint64_t command;

    /// The command response.  See the documentation for the command field.
    uint64_t response;

    /// The OCC async completion queue
    ///
    /// This is a pointer to a PtsCompletionQueue structure used to report
    /// back the status of threads that terminate, suspend or fail to the OCC
    /// async interrupt handler. Command completions are also communicated
    /// here.
    uint64_t completionQueue;

    /// Maximum wait time between scheduling loops
    ///
    /// This value is specified in 512MHz TOD timebase ticks.  It specifies
    /// the maximum amount of time the PTS scheduler is allowed to busy-wait
    /// between scheduler loops when it finds no threads to schedule. If a
    /// thread \e is found to schedule sooner than this it will be scheduled
    /// at the proper time. The busy waiting is done with interrupts
    /// disabled. 
    ///
    /// This field is supplied to allow PTS to poll for commands on a regular
    /// basis, as PTS checks for new commands at the top of each scheduling
    /// loop. Another option is to set this field to "infinity" and use
    /// PORE interrupts to prod PTS to reenter the scheduling loop - which is
    /// what the OCC application does.
    uint64_t maxWait;

    // *** Renaining fields initialized to 0 *** //

    /// Flags; See \ref pts_state_flags
    uint64_t flags;

    /// Temporary storage; PORE is just too register-poor 
    uint64_t temp[2];

    /// A pointer to the PtsThread structure of the current thread
    ///
    /// In thread mode (as opposed to the mode where an interrupt is being
    /// handled) this value will also be maintained in SPRG0.
    uint64_t currentThread;

    /// Return code in the event of PTS failure; See \ref pts_error_codes
    uint64_t rc;

    /// Synchronization for the OCC instance
    ///
    /// Since the PORE engine does not disable interrupts when an interrupt is
    /// taken, it opens windows where back-to-back interrupts from OCC can be
    /// delivered and potentialy cause confusion. This flag is set by the OCC
    /// async code to indicate that an interrupt has been presented, but not
    /// yet handled by the handler. The OCC interrupt handler will clear this
    /// flag once it has passed any critical section.
    volatile uint64_t occInterruptPending;

    // FFDC

    uint64_t dbg0;
    uint64_t dbg1;
    uint64_t pc_stack0;
    uint64_t pc_stack1;
    uint64_t pc_stack2;
    uint64_t p0;
    uint64_t p1;
    uint64_t ctr;
    uint64_t emr;
    uint64_t control;
    uint64_t status;

#if CONFIGURE_PTS_STATS

    /// The number of times each public error event was vectored
    uint64_t errorCount[5];

    /// The number of times each public function (interrupt) event was vectored
    uint64_t functionCount[16];

    /// The total number of errors handled
    uint64_t errors;

    /// The total number of interrupts handled
    uint64_t interrupts;

    /// The number of times _ptsSchedule was entered
    uint64_t ptsScheduleEntered;

    /// The number of times no interrupt was pending at _ptsSchedule()
    uint64_t noInterruptPending;

    /// The number of times _ptsResumeThread was entered
    uint64_t ptsResumeThreadEntered;

    /// The number of times _ptsResumeThread was not interrupted
    uint64_t resumeNotInterrupted;

    /// The number of times PTS entered its wait loop
    uint64_t enterWait;

    /// The number of times PTS exited its wait loop w/o being interrupted
    uint64_t exitWait;

    /// TOD timestamp at entry to _ptsSchedule()
    uint64_t entryTime;

    /// TOD delta for the last completed pass through _ptsSchedule()
    uint64_t scheduleTime;

#endif // CONFIGURE_PTS_STATS


#if CONFIGURE_PTS_DEBUG

    /// For PORE hardware validation, the OCC-based test targets all valid
    /// functions (interrupts).  In production mode any function other than 0
    /// is "unexpected" and is considered a fatal error.
    uint64_t allowUnexpectedFunction;

    /// Bread crumbs for debugging PTS; See the _ptsStateCrumbI,
    /// _ptsStateCrumbD and _ptsStateIncrCrumb macros
    uint64_t crumb[PTS_STATE_CRUMBS];

#endif // CONFIGURE_PTS_DEBUG


#if CONFIGURE_PTS_TRACE

    /// The index into the trace buffer
    uint64_t traceIndex;

    /// The trace buffer.
    uint64_t trace[PTS_STATE_TRACES];

#endif // CONFIGURE_PTS_TRACE

} PtsState;

#else

        // The assembler layout of the PtsState

        .struct 0

        _ptsStructField PTS_STATE_SCHEDULER_STATE
        _ptsStructField PTS_STATE_STOPPED
        _ptsStructField PTS_STATE_OCI_BASE
        _ptsStructField PTS_STATE_PTS_ERROR_HANDLER
        _ptsStructField PTS_STATE_INTERRUPT_TABLE
        _ptsStructField PTS_STATE_INTERRUPT_ERROR_MASK
        
        _ptsStructField PTS_STATE_THREAD_TERMINATION_HANDLER
        _ptsStructField PTS_STATE_THREAD_TABLE
        _ptsStructField PTS_STATE_THREAD_TABLE_ENTRIES
        _ptsStructField PTS_STATE_VALID_THREADS
        _ptsStructField PTS_STATE_COMMAND
        _ptsStructField PTS_STATE_RESPONSE
        _ptsStructField PTS_STATE_COMPLETION_QUEUE
        _ptsStructField PTS_STATE_MAX_WAIT

        _ptsStructField PTS_STATE_FLAGS
        _ptsStructField PTS_STATE_TEMP0
        _ptsStructField PTS_STATE_TEMP1
        _ptsStructField PTS_STATE_CURRENT_THREAD
        _ptsStructField PTS_STATE_RC
        _ptsStructField PTS_STATE_OCC_INTERRUPT_PENDING

        _ptsStructField PTS_STATE_DBG0
        _ptsStructField PTS_STATE_DBG1
        _ptsStructField PTS_STATE_PC_STACK0
        _ptsStructField PTS_STATE_PC_STACK1
        _ptsStructField PTS_STATE_PC_STACK2
        _ptsStructField PTS_STATE_P0
        _ptsStructField PTS_STATE_P1
        _ptsStructField PTS_STATE_CTR
        _ptsStructField PTS_STATE_EMR
        _ptsStructField PTS_STATE_CONTROL
        _ptsStructField PTS_STATE_STATUS

#if CONFIGURE_PTS_STATS

        _ptsStructField PTS_STATE_STAT_ERROR_COUNT, (5 * 8)
        _ptsStructField PTS_STATE_STAT_FUNCTION_COUNT, (16 * 8)
        _ptsStructField PTS_STATE_STAT_ERRORS
        _ptsStructField PTS_STATE_STAT_INTERRUPTS
        _ptsStructField PTS_STATE_STAT_SCHEDULE
        _ptsStructField PTS_STATE_STAT_NO_INTERRUPT_PENDING
        _ptsStructField PTS_STATE_STAT_RESUME_THREAD
        _ptsStructField PTS_STATE_STAT_RESUME_NOT_INTERRUPTED
        _ptsStructField PTS_STATE_STAT_ENTER_WAIT
        _ptsStructField PTS_STATE_STAT_EXIT_WAIT
        _ptsStructField PTS_STATE_STAT_ENTRY_TIME
        _ptsStructField PTS_STATE_STAT_SCHEDULE_TIME

#endif // CONFIGURE_PTS_STATS


#if CONFIGURE_PTS_DEBUG

        _ptsStructField PTS_STATE_ALLOW_UNEXPECTED_FUNCTION
        _ptsStructField PTS_STATE_CRUMB, (PTS_STATE_CRUMBS * 8)

#endif  // CONFIGURE_PTS_DEBUG


#if CONFIGURE_PTS_TRACE

        _ptsStructField PTS_STATE_TRACE_INDEX            
        _ptsStructField PTS_STATE_TRACE, (PTS_STATE_TRACES * 8)

#endif // CONFIGURE_PTS_TRACE

SIZE_OF_PTS_STATE:      
        .previous


        // This macro allocates an instance of the PtsState structure. Much of
        // the state must be configured at assembly time. The user has the
        // option of configuring part of the scheduler state either at
        // assembly time or run time.

        .macro  ptsDeclareState, \
                engine:req, \
                stopped=0, \
                ptsErrorHandler:req, \
                interruptTable:req, \
                interruptErrorMask:req, \
                threadTerminationHandler=null, \
                threadTable=null, \
                threadTableEntries=0, \
                validThreads=0, \
                command=0, \
                response=(-1), \
                completionQueue=null, \
                maxWait=0xffffffffffffffff

        .if     ((\engine) == PORE_ID_GPE0)
                .ptsGlobalData G_pts_gpe0State
G_pts_gpe0State:
        .else
        .if     ((\engine) == PORE_ID_GPE1)
                .ptsGlobalData G_pts_gpe1State
G_pts_gpe1State:
        .else
        .if     ((\engine) == PORE_ID_SLW)
                .ptsGlobalData G_pts_slwState
G_pts_slwState:
        .else
                .error "Unknown engine"
        .endif
        .endif
        .endif
        
1:
        // *** Fields required to be initialized (6 quadwords) *** //

        .quad   PTS_SCHEDULER_STATE_UNINITIALIZED
        .quad   (\stopped)

        .if     ((\engine) == PORE_ID_GPE0)
                .quad   PTS_GPE0_OCI_BASE
        .else
        .if     ((\engine) == PORE_ID_GPE1)
                .quad   PTS_GPE1_OCI_BASE
        .else
                .quad   PTS_SLW_OCI_BASE
        .endif
        .endif

        .quada  \ptsErrorHandler
        .quada  \interruptTable
        .quad   \interruptErrorMask
        
        // *** Fields optionally initialized (8 quadwords) *** //

        _ptsOptionalPointer \threadTerminationHandler
        _ptsOptionalPointer \threadTable
        .quad   (\threadTableEntries)
        .quad   (\validThreads)
        .quad   (\command)
        .quad   (\response)
        _ptsOptionalPointer \completionQueue
        .quad   (\maxWait)             
        
        // *** Remaining fields initialized to 0 *** //

        .space  SIZE_OF_PTS_STATE - (. - 1b)

        .endm
        
#endif // __ASSEMBLER__


/// The PTS scheduler thread structure
///
/// This structure contains the next thread schedule time and a pointer to the
/// application thread.  The nextScheduleTime is kept here rather then in the
/// PtsThread structure to reduce mainstore access overhead through the PBA
/// when PTS is used for the product SLW application.
        
#ifndef __ASSEMBLER__   

typedef struct {

    /// The next schedule time for this thread
    ///
    /// This is an absolute time as measured by the chip-level TOD clock.  By
    /// convention this value is set to 0 to indicate an immediately runnable
    /// thread, and to PTS_SUSPENDED (0xffffffffffffffff) to indicate a
    /// suspended thread.
    uint64_t nextSchedule;

    /// A pointer to the application thread
    ///
    /// The scheduler always checks this pointer for 0 during scheduling, and
    /// will actually or effectively remove the scheduler thread slot from the
    /// scheduling algorithm if found to be 0.
    uint64_t thread;

} PtsSchedulerThread;

#else

        // The assembler layout of the PtsSchedulerThread

        .struct 0

        _ptsStructField PTS_SCHEDULER_THREAD_NEXT_SCHEDULE
        _ptsStructField PTS_SCHEDULER_THREAD_THREAD

SIZE_OF_PTS_SCHEDULER_THREAD:
        .previous


        // This macro allocates the PTS scheduler thread table.  It allows
        // fixed configurations of up to 4 threads (sufficient for the
        // product SLW application).  All threads are marked immediately
        // runnable. 

        .macro ptsDeclareSchedulerThreads, symbol:req, slots:req, \
               t0=0, t1=0, t2=0, t3=0

      .balign 128
\symbol\():
        _ptsDeclareSchedulerThread 0, (\slots), (\t0)
        _ptsDeclareSchedulerThread 1, (\slots), (\t1)
        _ptsDeclareSchedulerThread 2, (\slots), (\t2)
        _ptsDeclareSchedulerThread 3, (\slots), (\t3)
        .if     ((\slots) > 4)
                .rept   ((\slots) - 4)
                        _ptsDeclareSchedulerThread -1, 0, 0
                .endr
        .endif
        .endm


        // Private helper macro for the above

        .macro  _ptsDeclareSchedulerThread n:req, slots:req, thread:req
        .if     ((\n) == -1)
                .quad 0
                .quad 0
        .else
                .if     ((\n) < (\slots))
                        .quad   0
                        .quada  (\thread)
                .endif
        .endif
        .endm     
        
        
#endif  // __ASSEMBLER__
        
            
/// The PTS (application) thread structure
///
/// This structure stores the thread context during context switches, and
/// contains a back-pointer to the PtsSchedulerThread.  Each application
/// thread structure also maintains an optional pointer to an error handler
/// for PORE error 0 specific to that thread.  For full information on error
/// handling and error handling options please see the written specification of
/// PTS.
///
/// The following fields of the PtsThread state are updated as FFDC in the
/// event of any error on a thread. It is not possible to save D0/D1, A0/A1 or
/// the PC, however the error return address will be in the stack.
///
/// - pc_stack0
/// - pc_stack1
/// - pc_stack2
/// - p0
/// - p1
/// - ctr
/// - dbg0
/// - dbg1
/// - emr
///
/// \note The PtsThread structure is carefully laid out in a way that arranges
/// the most commonly-referenced and updated fields into a single 128-byte
/// PowerBus cache line. This helps with memory access efficiency for the SLW
/// application. For the SLW application all PtsThread structures should be
/// allocated 128-byte aligned. For the OCC application 8-byte alignment is
/// sufficient and automatic for PtsThread structures allocated from C code.

#ifndef __ASSEMBLER__

typedef struct {

    /// The back-pointer to the PtsSchedulerThread referencing this PtsThread
    ///
    /// If the PtsThread is not mapped, this pointer will be 0.
    uint64_t schedulerThread;

    /// Thread flags; See \ref pts_thread_flags
    uint64_t flags;

    // The following fields are context saved during context switches. The PC
    // and stack pointers are always saved, however not all of the other state
    // is saved every time - the context switch macros are parameterized by
    // the register state required to be saved and restored across the context
    // switch. As a corollary, a PTS context can only be restored at the point
    // (PC) from which it was saved.  
    //
    // Portions of this state are also saved as FFDC

    uint64_t pc;
    uint64_t pc_stack0;
    uint64_t pc_stack1;
    uint64_t pc_stack2;

    uint64_t d0;
    uint64_t d1;
    uint64_t a0;
    uint64_t a1;
    uint64_t p0;
    uint64_t p1;
    uint64_t ctr;

    // FFDC-only registers

    uint64_t dbg0;
    uint64_t dbg1;
    uint64_t emr;

    /// The original entry point for the thread (48-bit PORE address)
    ///
    /// This field is included to support restarting threads that use the
    /// _ptsTerminate() protocol.
    uint64_t entryPoint;

    /// The optional termination handler for this thread
    ///
    /// This field can be initialized to a non-0 value to specify a
    /// thread-specific handler that is invoked whenever the thread is
    /// terminated, suspended or killed. This handler is a subroutine called
    /// with an empty stack.  The thread return code has already been stored
    /// in the PtsThread->rc field. If PTS killed the thread then PtsThread.rc
    /// = -1 and the non-0 PTS return code will be found in PtsThread->ptsRc
    /// field. The following parameters are provided to the handler:
    ///
    /// - A0 : &PtsState
    /// - A1 : &PtsThread
    uint64_t terminationHandler;

    /// The optional PORE error 0 handler for this thread (48-bit PORE address)
    ///
    /// Threads are only allowed to handle PORE error 0 - execute-phase PIB
    /// errors - themselves by default.  Prior to invoking the handler FFDC
    /// state is stored in the PtsThread, the stack is flushed and mainstore
    /// access is returned to the default mode if necessary.  PTS then
    /// branches to the error handler.  No context other than that visible in
    /// the saved FFDC state is available to the error handler.  
    ///
    /// The thread can observe the failing SCOM address and PIB error code as
    /// follows:
    ///
    ///     mr      A0, SPRG0                # Move thread pointer to A0
    ///     ld      D1, PTS_THREAD_DBG0, A0  # Load DBG0 register image
    ///     extrdi  D0, D1, 32, 0            # D0 <- Failing PIB address
    ///     extrdi  D1, D1, 4, 32            # D1 <- PIB error code
    ///
    /// The error handler is considered a continuation of the thread, and must
    /// eventually execute a PTS system call to return control to the
    /// scheduler. The thread should execute a PTS system call (e.g.,
    /// ptsYield) as soon as possible because if the thread takes another
    /// error 0 event before executing a PTS system call the thread will be
    /// killed with an assumed double-fault.
    ///
    /// A value of 0 specifies no thread-specific handler, and the thread is
    /// simply killed in the event of an error 0 event.
    uint64_t error0Handler;

    /// The thread priority
    ///
    /// If the PtsThread is not mapped, this priority is informative only.
    uint64_t priority;

    /// The return code from the thread's call of ptsTerminate or ptsSuspend.
    ///
    /// Note that if the thread is killed by PTS - signified by a non-0 value
    /// in the ptsRc field - then this field will be set to -1.
    uint64_t rc;

    /// The PTS return code from terminating or suspending the thread
    ///
    /// The PTS return code will be 0 if the thread successfully executes
    /// ptsTerminate or ptsSuspend, in which case the rc field will contain
    /// the thread's return code.  Otherwise if PTS has to kill the thread
    /// then this field will contain one of the codes documented as \ref
    /// pts_thread_errors, and the rc field is set to -1.
    uint64_t ptsRc;

    /// An uninterpreted argument for the thread
    ///
    /// This field is provided to allow the external environment to pass data
    /// to the thread using whatever protocol is desired.  For example, the
    /// OCC application uses this field to pass a parameter to the
    /// thread. This field is neither read nor written by PTS.
    uint64_t arg;

    /// An uninterpreted argument for the thread completion handler
    ///
    /// This field is provided to store a 32-bit value for the completion
    /// record of the thread. For the OCC instance of PTS this will store the
    /// AsyncRequest* of the request that scheduled the thread. 
    uint64_t completionArg;

#if CONFIGURE_PTS_STATS

    /// The TOD timestamp of the last time the thread was scheduled
    uint64_t lastSchedule;

    /// The maximum latency of the thread, measured from thread scheduling to
    /// the re-entry of the scheduling loop after a system call.
    uint64_t maxLatency;

#endif

#if CONFIGURE_PTS_DEBUG

    /// Bread crumbs for debugging PTS threads
    uint64_t crumb[PTS_THREAD_CRUMBS];

#endif // CONFIGURE_PTS_DEBUG

} PtsThread;

#else

        // The assembler layout of the PtsThread

        .struct 0
        _ptsStructField PTS_THREAD_SCHEDULER_THREAD
        _ptsStructField PTS_THREAD_FLAGS
        _ptsStructField PTS_THREAD_PC
        _ptsStructField PTS_THREAD_PC_STACK0
        _ptsStructField PTS_THREAD_PC_STACK1
        _ptsStructField PTS_THREAD_PC_STACK2
        _ptsStructField PTS_THREAD_D0
        _ptsStructField PTS_THREAD_D1
        _ptsStructField PTS_THREAD_A0
        _ptsStructField PTS_THREAD_A1
        _ptsStructField PTS_THREAD_P0
        _ptsStructField PTS_THREAD_P1
        _ptsStructField PTS_THREAD_CTR
        _ptsStructField PTS_THREAD_DBG0
        _ptsStructField PTS_THREAD_DBG1
        _ptsStructField PTS_THREAD_EMR
        _ptsStructField PTS_THREAD_ENTRY_POINT
        _ptsStructField PTS_THREAD_TERMINATION_HANDLER
        _ptsStructField PTS_THREAD_ERROR0_HANDLER
        _ptsStructField PTS_THREAD_PRIORITY
        _ptsStructField PTS_THREAD_RC
        _ptsStructField PTS_THREAD_PTS_RC
        _ptsStructField PTS_THREAD_ARG
        _ptsStructField PTS_THREAD_COMPLETION_ARG

#if CONFIGURE_PTS_STATS

        _ptsStructField PTS_THREAD_LAST_SCHEDULE
        _ptsStructField PTS_THREAD_MAX_LATENCY

#endif

#if CONFIGURE_PTS_DEBUG

        _ptsStructField PTS_THREAD_CRUMB, (PTS_THREAD_CRUMBS * 8)

#endif // CONFIGURE_PTS_DEBUG

SIZE_OF_PTS_THREAD:
        .previous


        // Static allocation of a PtsThread structure at a fixed slot in a
        // table of PtsSchedulerThread.  The entry point is required; error 0
        // and termination handlers are optional. 
        //
        // This macro will only be used to configure the PORE-SLW applications
        // as the OCC instance of PTS is dynamically configured. Assuming the
        // data structures are all initialized correctly then this thread is
        // initialized ready-to-run at its entry point with an empty stack.
        //
        // NB: The scheduler thread table must also be initialized using
        // _ptsDeclareSchedulerThreads to point back to the threads declared
        // here. 

        .macro  ptsDeclareThread, \
                symbol:req, table=G_pts_slwTable, slot:req, \
                entryPoint:req, terminationHandler=0, error0Handler=0, \
                arg=0

        .balign 128
\symbol\():

        // PTS_THREAD_SCHEDULER_THREAD
        // PTS_THREAD_FLAGS

        .quada  (\table) + ((\slot) * SIZE_OF_PTS_SCHEDULER_THREAD)
        .quad   0

        // PTS_THREAD[PC, PC_STACK0, PC_STACK1, PC_STACK2,
        //            D0, D1, A0, A1, P0, P1, CTR,
        //            DBG0, DBG1, EMR]

        .quada  (\entryPoint)
        .quad   PTS_STACK0_EMPTY
        .space  (8 * 12)

        // PTS_THREAD_ENTRY_POINT
        // PTS_THREAD_TERMINATION_HANDLER
        // PTS_THREAD_ERRO0_HANDLER
        
        .quada  (\entryPoint)
        .if     ((\terminationHandler) == 0)
                .quad   0
        .else
                .quada  (\terminationHandler)
        .endif
        .if     ((\error0Handler) == 0)
                .quad   0
        .else
                .quada  (\error0Handler)
        .endif

        // PTS_THREAD_PRIORITY
        // PTS_THREAD_RC
        // PTS_THREAD_PTS_RC
        // PTS_THREAD_ARG
        // PTS_THREAD_COMPLETION_ARG                     

        .quad   (\slot)
        .quad   0
        .quad   0                
        .quad   (\arg)
        .quad   0   

        // *** Remaining fields initialized to 0 *** //

        .if     (SIZE_OF_PTS_THREAD - (. - \symbol))                     
                .space  SIZE_OF_PTS_THREAD - (. - \symbol)
        .endif

        .endm


#endif // __ASSEMBLER__


// A table of pointers to PTS data structures for the SLW application
//
// To simplify debug and FFDC collection in the PHYP environment, PTS
// initialization creates a table of pointers to PTS data structures at a
// well-known place in the HOMER image (HOMER_PTS_DATA). This is much
// simpler than trying to allocate PTS data structures at well-known
// locations. The table also includes the sizes of teh structures so that
// error logging code has no dependence on the PTS header files.
//
// NB: The pointers stored here are all PowerBus physical addresses

#ifndef __ASSEMBLER__

typedef struct PtsHomerData {

    /// Holds sizeof(PtsState)
    uint64_t sizeofPtsState;

    /// A pointer to the PtsState object
    uint64_t state;

    /// Holds the entire size of the PTS thread table
    uint64_t sizeofThreadTable;

    /// A pointer to the PTS thread table
    uint64_t threadTable;

    /// Holds the number of threads in the thread table
    uint64_t nThreads;

    /// Holds sizeof(PtsThread)
    uint64_t sizeofPtsThread;

    /// A table of pointers to the mapped PtsThread blocks. There will be as
    /// many entries in this table as the size of the scheduler thread table,
    /// defined by the assembler constant PTS_SLW_THREADS in
    /// pts_slw_config.S. Thread slots that are not mapped will contain zeros.
    uint64_t thread[];

} PtsHomerData;

#else

        // The assembler layout of the PtsHomerData

        .struct 0

        _ptsStructField PTS_HOMER_DATA_SIZE_OF_PTS_STATE
        _ptsStructField PTS_HOMER_DATA_STATE

        _ptsStructField PTS_HOMER_DATA_SIZE_OF_THREAD_TABLE
        _ptsStructField PTS_HOMER_DATA_THREAD_TABLE

        _ptsStructField PTS_HOMER_DATA_N_THREADS
        _ptsStructField PTS_HOMER_DATA_SIZE_OF_PTS_THREAD

SIZE_OF_PTS_HOMER_DATA:
        _ptsStructField PTS_HOMER_DATA_THREAD

        .previous

#endif // __ASSEMBLER__

        
#endif  // __PTS_STRUCTURES_H
