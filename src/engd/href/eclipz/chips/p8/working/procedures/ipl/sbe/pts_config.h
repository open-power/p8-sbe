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



#ifndef __PTS_CONFIG_H__
#define __PTS_CONFIG_H__


/// \file pts_config.h
/// \brief PORE Thread Scheduler (PTS) configuration and constants
///
/// PTS supports 2 major configurations.  
///
/// 1. If the C-preprocesor symbol CONFIGURE_PTS_SLW is non-0 (the default),
/// PTS is configured for the SBE/SLW code development environment in which
/// PTS runs on the SLW engine to allow 24x7 support and other threads to
/// coexist with the deep-idle exit function. In this configuration the file
/// pts_slw_config.S is assembled and linked with the image to provide the
/// scheduler state structure G_pts_slwState.
///
/// 2. Otherwise, PTS is built in a way that allows it to run on PORE-GPE0/1
/// to support OCC use. In this configuration the file pts_occ_config.pS is
/// assembled and linked with the application to provide the scheduler state
/// structures G_pts_gpe0State and G_pts_gpe1State
///
/// Note that PTS does not start automatically, so it is safe for
/// pts_occ_config.S to declare all of the state structures, even though only
/// a subset of the engines will actually run PTS.

#include "pgas.h"

/// The default configuration is for the product SLW application
///
/// The non-default configuration allows PTS to run on PORE-GPE0 and/or
/// PORE-GPE1
#ifndef CONFIGURE_PTS_SLW
#define CONFIGURE_PTS_SLW 1
#endif

/// Default to no statistics
#ifndef CONFIGURE_PTS_STATS
#define CONFIGURE_PTS_STATS 0
#endif

/// Default to no debugging information
#ifndef CONFIGURE_PTS_DEBUG
#define CONFIGURE_PTS_DEBUG 0
#endif

/// Default to no trace collection
#ifndef CONFIGURE_PTS_TRACE
#define CONFIGURE_PTS_TRACE 0
#endif

/// Default to non-test mode
#ifndef CONFIGURE_PTS_TEST
#define CONFIGURE_PTS_TEST 0
#endif


/// The nominal frequency of the TOD clock
#define PTS_TOD_FREQUENCY_MHZ 512

/// Convert milliseconds into TOD ticks
#define PTS_MILLISECONDS(x) ((x) * PTS_TOD_FREQUENCY_MHZ * 1000)

/// Convert microseconds into TOD ticks
#define PTS_MICROSECONDS(x) ((x) * PTS_TOD_FREQUENCY_MHZ)


/// Language-specific decoration for 64-bit constants

#ifdef __ASSEMBLER__

#ifndef ULL
#define ULL(x) x
#endif

#else

#ifndef ULL
#define ULL(x) x##ull
#endif

#endif // __ASSEMBLER


/// Create a multi-bit mask of \a n bits starting at bit \a b
#ifndef BITS
#define BITS(b, n) ((ULL(0xffffffffffffffff) << (64 - (n))) >> (b))
#endif


/// Create a single bit mask at bit \a b
#ifndef BIT
#define BIT(b) BITS((b), 1)
#endif


/// Special value conventionally used to mark a thread as immediately runnable
#define PTS_RUNNABLE 0

/// \defgroup pts_unrunnable_states PTS Unrunnable States
///
/// @{

/// Special value indicating a terminated thread that may be restarted cleanly
/// at its original entry point.
#define PTS_TERMINATED ULL(0xffffffffffffffff)

/// Special value indicating a suspended thread that may be restarted with a
/// saved context
#define PTS_SUSPENDED ULL(0xfffffffffffffffe)

/// Special value indicating a thread that was killed due to an unhandled
/// error. The thread may be restarted cleanly from its original entry point. 
#define PTS_KILLED ULL(0xfffffffffffffffd)

/// Special value indicating a thread terminated by comand; The thread may be
/// restarted cleanly at its original entry point.
#define PTS_FORCE_TERMINATED ULL(0xfffffffffffffffc)

/// Special value indicating a thread suspended by command; The thread will 
/// restart in its current context.
#define PTS_FORCE_SUSPENDED ULL(0xfffffffffffffffb)

/// @}


/// Special value loaded into PC_STACK0 to reset to an empty stack
///
/// Bit 59 enables a write to the register to set bit 63, which indicates that
/// the stack is empty. Other stack pointers (1, 2) are simply cleared (to
/// avoid confusion).
#define PTS_STACK0_EMPTY (BIT(59) | BIT(63))

/// \defgroup pts_states PTS Scheduler States
///
/// PTS error handling code uses the scheduler state to determine how to
/// handle errors.  The scheduler state can also be used for debugging and
/// FFDC. 
/// @{

/// The PTS scheduler is uninitialized
#define PTS_SCHEDULER_STATE_UNINITIALIZED 0

/// The PTS scheduler is executing
///
/// Note that if a thread is executing then PtsState.currentThread will be
/// non-0. 
#define PTS_SCHEDULER_STATE_SCHEDULING 1

/// PORE interrupts are enabled
///
/// *NB* - DO NOT REASSIGN THIS CONSTANT, PHYP USES THIS VALUE - *NB*
#define PTS_SCHEDULER_STATE_INTERRUPTIBLE 2

/// The PTS scheduler has taken an error
///
/// This state is set prior to PTS calling its error handler.
#define PTS_SCHEDULER_STATE_PTS_ERROR 3

/// The PTS scheduler is handling a thread error.
///
/// This state is set as soon as an error has been assigned to a thread. It
/// will be seen even if a thread is handling Error 0, until the thread makes
/// a system call from the error handler.
#define PTS_SCHEDULER_STATE_THREAD_ERROR 4

/// The PTS scheduler has taken an "unexpected" error
///
/// An "unexpected" error signifies a bug in PTS or the PORE hardware. See
/// pts_error.S.  This state is set prior to PTS calling its error handler.
#define PTS_SCHEDULER_STATE_UNEXPECTED_ERROR 5

/// The PTS scheduler has been commanded to stop thread scheduling
///
/// Note that PTS command processing and interrupt processing continues even
/// when PTS is stopped.
#define PTS_SCHEDULER_STATE_STOPPED 6

/// The PTS scheduler can not execute on this hardware
#define PTS_SCHEDULER_STATE_UNABLE 7

/// PTS has been started but has not yet entered the scheduling loop.
#define PTS_SCHEDULER_STATE_STARTED 8

/// PTS is executing a thread
#define PTS_SCHEDULER_STATE_THREAD 9

/// @}


/// \defgroup pts_error_codes PTS scheduler error return codes.
///
/// These are codes found in the rc field of the PtsState data structure
/// in the event that PTS terminates itself.
///
/// Note PTS_THREAD_ERROR_<n> codes must be defined as PTS_ERROR_<n> + 0x10.
///
/// @{

/// PTS took Error 0, an execute phase PIB error.  This can only mean that a
/// read of the TOD failed.
#define PTS_ERROR_0 0x10

/// PTS took Error 1, an execute phase OCI error.
#define PTS_ERROR_1 0x11

/// PTS took Error 2, one of many possible fetch/decode errors
#define PTS_ERROR_2 0x12

/// PTS took Error 3, which includes both HW and FW errors.
#define PTS_ERROR_3 0x13

/// The PTS completion queue is full
#define PTS_COMPLETION_QUEUE_FULL 0x14

/// The scheduler state was wierd when an error was detected
#define PTS_UNEXPECTED_SCHEDULER_STATE 0x15

/// PTS was expecting an interrupt to fire and it did not
#define PTS_INTERRUPT_EXPECTED 0x16

/// PTS is not supported on this chip
#define PTS_NOT_SUPPORTED 0x17

/// PTS-SLW terminated itself because a thread failed or terminated
///
/// Prior to this self-termination, PTS will set PMC LFIR bit 38 which should
/// be programmed to create a malfunction alert to the hypervisor.
#define PTS_SLW_THREAD_FAILURE 0x18

/// @}


/// \defgroup pts_thread_errors PTS Thread error return codes.
///
/// These are codes found in the PtsThread.ptsRc field of the thread in the
/// event the thread is killed by PTS.
///
/// Note PTS_THREAD_ERROR_<n> codes must be defined as PTS_ERROR_<n> + 0x10.
///
/// @{

/// The thread took Error 0, an execute-phase PIB error.
#define PTS_THREAD_ERROR_0 0x20

/// The thread took Error 1, an execute-phase OCI error.
#define PTS_THREAD_ERROR_1 0x21

/// The thread took Error 2, one of many possible fetch/decode errors.
#define PTS_THREAD_ERROR_2 0x22

/// The thread took Error 3, which includes both HW and FW errors.
#define PTS_THREAD_ERROR_3 0x23

/// The thread made a system call while in an atomic mainstore mode
#define PTS_THREAD_ATOMIC_VIOLATION 0x24

/// @}


/// \defgroup pts_unexpected_codes PTS Codes for "Unexpected" Transitions
///
/// These are FFDC codes for PORE branch tables transitions and a couple of
/// other events that are "unexpected", i.e., should never happen. If one of
/// the branch table transitions does happen it may indicate a HW error. In
/// any event PTS will halt with the major error code in PtsState[RC].
///
/// @{

#define PTS_UNEXPECTED_THREAD_ERROR0 0x10
#define PTS_UNEXPECTED_THREAD_ERROR1 0x11
#define PTS_UNEXPECTED_THREAD_ERROR2 0x12
#define PTS_UNEXPECTED_THREAD_ERROR3 0x13
#define PTS_UNEXPECTED_THREAD_ERROR4 0x14

#define PTS_UNEXPECTED_INTERRUPT_ERROR0 0x30
#define PTS_UNEXPECTED_INTERRUPT_ERROR1 0x31
#define PTS_UNEXPECTED_INTERRUPT_ERROR2 0x32
#define PTS_UNEXPECTED_INTERRUPT_ERROR3 0x33
#define PTS_UNEXPECTED_INTERRUPT_ERROR4 0x34

#define PTS_UNEXPECTED_INTERRUPT_ENTRY0 0x40
#define PTS_UNEXPECTED_INTERRUPT_ENTRY1 0x41
#define PTS_UNEXPECTED_INTERRUPT_ENTRY2 0x42
#define PTS_UNEXPECTED_INTERRUPT_ENTRY3 0x43
#define PTS_UNEXPECTED_INTERRUPT_ENTRY4 0x44
#define PTS_UNEXPECTED_INTERRUPT_ENTRY5 0x45
#define PTS_UNEXPECTED_INTERRUPT_ENTRY6 0x46
#define PTS_UNEXPECTED_INTERRUPT_ENTRY7 0x47
#define PTS_UNEXPECTED_INTERRUPT_ENTRY8 0x48
#define PTS_UNEXPECTED_INTERRUPT_ENTRY9 0x49
#define PTS_UNEXPECTED_INTERRUPT_ENTRYA 0x4A
#define PTS_UNEXPECTED_INTERRUPT_ENTRYB 0x4B
#define PTS_UNEXPECTED_INTERRUPT_ENTRYC 0x4C
#define PTS_UNEXPECTED_INTERRUPT_ENTRYD 0x4D
#define PTS_UNEXPECTED_INTERRUPT_ENTRYE 0x4E
#define PTS_UNEXPECTED_INTERRUPT_ENTRYF 0x4F

/// @}


/// \defgroup pts_state_flags PTS State Flags
///
/// @{

/// A flag indicating that a thread has set up an atomic RMW mode for
/// mainstore.
///
/// This is required in the event that a thread takes an error while running
/// in an atomic RMW mode, as it is necessary to restore mainstore access to
/// the default mode. The PTS scheduler itself never uses atomic RMW mode.
///
/// This flag is set when the thread invokes the ptsMainstoreAtomicAdd
/// API, and reset when the thread invokes the ptsMainstoreDefault API
/// or the thread fails.
///
/// \note There is currently no support for the PTS interrupt handlers to
/// use atomic RMW to mainstore, or more precisely, they are expected to
/// handle atomic RMW modes properly themselves if required.
#define PTS_STATE_MAINSTORE_ATOMIC 0x1

/// A flag indicating that the thread is currently handling error 0.
///
/// This flag prevents infinite loops and hangs caused by a thread with a
/// faulty error 0 handler that generates another error0 before making a
/// system call. 
#define PTS_STATE_HANDLING_ERROR0 0x2

/// @}


/// \defgroup pts_thread_flags PTS Thread Flags
///
/// @{

/// A flag indicating that the thread is handling PIB errors.
///
/// This flag is set when a thread call ptsThreadHandlesPibErrors.  It
/// indicates that the thread requires a special value of EMR that allows
/// the thread to handle PIB errors.  The flag is reset when the thread
/// calls ptsPtsHandlesPibErrors.
#define PTS_THREAD_HANDLES_PIB_ERRORS 0x1

/// A flag indicating that the thread has context that needs to be restored
///
/// This flag distinguishes threads that are to be restarted from their entry
/// point (i.e., terminated [killed] threads), vs. threads that saved a state
/// across a context switch.
#define PTS_THREAD_HAS_CONTEXT 0x2

/// @}


// Constants controlling the sizes of PtsState and PtsThread debugging
// structures
        
#ifndef PTS_STATE_CRUMBS
#define PTS_STATE_CRUMBS 8
#endif
 
#ifndef PTS_STATE_TRACES
#define PTS_STATE_TRACES 64
#endif

#ifndef PTS_THREAD_CRUMBS
#define PTS_THREAD_CRUMBS 2
#endif
 

#ifdef __ASSEMBLER__

        // To make PTS as independent as possible of OCC FW or SBE FW headers,
        // PTS privately defines a few address constants, PORE register
        // offsets, PORE register bits etc. These constants should not be
        // needed by C support code.

        .set    PTS_TOD, 0x00040020

        .set    PTS_PBA_SLVRST, 0x40020008

        .set    PTS_PMC_PORE_REQ_REG1, 0x40010478

        .set    PTS_TPC_DEVICE_ID, 0x000f000f  
        .set    PTS_CFAM_CHIP_TYPE_VENICE, 0xea
        .set    PTS_CFAM_CHIP_TYPE_MURANO, 0xef

        .set    PTS_GPE0_OCI_BASE, 0x40000000
        .set    PTS_GPE1_OCI_BASE, 0x40000100
        .set    PTS_SLW_OCI_BASE, 0x40040000

        .set    PTS_PORE_STATUS_OFFSET,    0x00
        .set    PTS_PORE_CONTROL_OFFSET,   0x08
        .set    PTS_PORE_EMR_OFFSET,       0x18
        .set    PTS_PORE_TBAR_OFFSET,      0x40
        .set    PTS_PORE_DBG0_OFFSET,      0x78
        .set    PTS_PORE_DBG1_OFFSET,      0x80
        .set    PTS_PORE_PC_STACK0_OFFSET, 0x88
        .set    PTS_PORE_PC_STACK1_OFFSET, 0x90
        .set    PTS_PORE_PC_STACK2_OFFSET, 0x98

        .set    PTS_PORE_STATUS_INTERRUPT_PENDING, BIT(9)

        .set    PTS_PORE_CONTROL_LOCK_EXE_TRIG, BIT(7)
        .set    PTS_PORE_CONTROL_TRAP_ENABLE, BIT(11)
        .set    PTS_PORE_CONTROL_INTERRUPTIBLE, BIT(13)
        .set    PTS_PORE_CONTROL_DONE_OVERRIDE, BIT(14)
        .set    PTS_PORE_CONTROL_INTERRUPTIBLE_EN, BIT(15)

        .set    PTS_PORE_ERROR_MASK_ENABLE_ERR_HANDLER0, BIT(0)
        .set    PTS_PORE_ERROR_MASK_ENABLE_ERR_HANDLER1, BIT(1)
        .set    PTS_PORE_ERROR_MASK_ENABLE_ERR_HANDLER2, BIT(2)
        .set    PTS_PORE_ERROR_MASK_ENABLE_ERR_HANDLER3, BIT(3)
        .set    PTS_PORE_ERROR_MASK_ENABLE_ERR_HANDLER4, BIT(4)

        .set    PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT0, BIT(5)
        .set    PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT1, BIT(6)
        .set    PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT2, BIT(7)
        .set    PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT3, BIT(8)
        .set    PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT4, BIT(9)

        .set    PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT0, BIT(10)
        .set    PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT1, BIT(11)
        .set    PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT2, BIT(12)
        .set    PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT3, BIT(13)
        .set    PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT4, BIT(14)

        .set    PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR0, BIT(15)
        .set    PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR1, BIT(16)
        .set    PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR2, BIT(17)
        .set    PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR3, BIT(18)
        .set    PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR4, BIT(19)

        // The default error mask for PTS
        //
        // Whenever threads are running, PTS attempts to handle all errors
        // except for error-on-error (error 4). The thread can override the
        // Error 0 behavior (execute-phase PIB errors) either by defining a
        // handler for Error 0 or by the ptsThreadHandlesPibErrors API which
        // allows the thread to handle PIB errors inline.
        //
        // To support debugging, define PTS_HALT_ON_ERRORS. Otherwise much
        // of the processor state is lost during error handling.
#ifndef PTS_HALT_ON_ERRORS
        .set PTS_DEFAULT_ERROR_MASK, \
            (PTS_PORE_ERROR_MASK_ENABLE_ERR_HANDLER0      | \
             PTS_PORE_ERROR_MASK_ENABLE_ERR_HANDLER1      | \
             PTS_PORE_ERROR_MASK_ENABLE_ERR_HANDLER2      | \
             PTS_PORE_ERROR_MASK_ENABLE_ERR_HANDLER3      | \
             PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT4       | \
             PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT4 | \
             PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR4)
#else
        .set PTS_DEFAULT_ERROR_MASK, \
            (PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT0       | \
             PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT0 | \
             PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT1       | \
             PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT1 | \
             PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT2       | \
             PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT2 | \
             PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT3       | \
             PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT3 | \
             PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT4       | \
             PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT4 | \
             PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR0       | \
             PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR1       | \
             PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR2       | \
             PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR3       | \
             PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR4)
#endif


        // Error mask for PTS threads handling their own PIB errors
        //
        // This error mask is used by threads that have executed the
        // ptsThreadHandlesPibErrors API which allows the thread to handle
        // PIB errors inline.
        //
        // To support debugging, define PTS_HALT_ON_ERRORS. Otherwise much
        // of the processor state is lost during error handling. Note we still
        // let the thread handle error 0 in this case.
#ifndef PTS_HALT_ON_ERRORS
        .set PTS_THREAD_HANDLES_PIB_ERRORS_MASK, \
             (PTS_PORE_ERROR_MASK_ENABLE_ERR_HANDLER1      | \
              PTS_PORE_ERROR_MASK_ENABLE_ERR_HANDLER2      | \
              PTS_PORE_ERROR_MASK_ENABLE_ERR_HANDLER3      | \
              PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT4       | \
              PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT4 | \
              PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR4)
#else
        .set PTS_THREAD_HANDLES_PIB_ERRORS_MASK, \
            (PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT1       | \
             PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT1 | \
             PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT2       | \
             PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT2 | \
             PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT3       | \
             PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT3 | \
             PTS_PORE_ERROR_MASK_ENABLE_ERR_OUTPUT4       | \
             PTS_PORE_ERROR_MASK_ENABLE_FATAL_ERR_OUTPUT4 | \
             PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR1       | \
             PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR2       | \
             PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR3       | \
             PTS_PORE_ERROR_MASK_STOP_EXE_ON_ERROR4)
#endif


#if CONFIGURE_PTS_SLW

        // PTS text goes into the SBE-XIP .text section, 4-byte aligned
        .macro  .ptsText
        .section .text, "ax", @progbits
        .balign 4
        .endm

        // PTS data goes into the SBE-XIP .data section, 8-byte aligned
        .macro  .ptsData
        .section .data
        .balign 8
        .endm

#else

        // PTS text goes into the .text.pore section, 4-byte aligned
        .macro  .ptsText
        .section .text.pore, "ax", @progbits
        .balign 4
        .endm

        // PTS data goes into the .data.pore section, 8-byte aligned
        .macro  .ptsData
        .section .data.pore, "a", @progbits
        .balign 8
        .endm

#endif // CONFIGURE_PTS_SLW

        // Declare a local PTS function
        .macro  .ptsLocalFunction, symbol:req
        .ptsText
        .endm

        // Declare a global PTS function
        .macro  .ptsGlobalFunction, symbol:req
        .ptsText
        .global \symbol
        .endm

        // Declare global PTS data
        .macro  .ptsGlobalData, symbol:req
        .ptsData
        .global \symbol
        .endm

       // The .ptsEpilogue pseudo-op defines a type and size of a symbol,
       // which could be a subroutine, procedure, or even a data array.
        .macro  .ptsEpilogue, symbol:req, type=@function
        .type   \symbol, \type
        .size   \symbol, (. - \symbol)
        .endm

        
// For portability, PTS code only uses (may only use) special hook forms for
// logging.

#if CONFIGURE_PTS_SLW

// Hooks are not supported for the SLW application. Simics implements a
// slightly different way of doing hooks that is not compatible with
// POREVE. Note that PTS will never run under the PoreVe anyway.

#define LOG_OUTPUT(...)
#define LOG_INFO(...)
#define LOG_DEBUG(...)
#define LOG_ERROR(...)
#define TRACE_OUTPUT(...)
#define TRACE_INFO(...)
#define TRACE_DEBUG(...)
#define TRACE_ERROR(...)

#define PORE_ASSERT(...)

#else

// All traces and logs produced by PTS for OCC/GPE include the current virtual
// time.

#include "pore_hooks.h"

#define LOG_OUTPUT(fmt, ...) \
        PORE_LOG_OUTPUT(FMT_VTIME ":" fmt, vtime(), ##__VA_ARGS__)

#define LOG_INFO(fmt, ...) \
        PORE_LOG_INFO(FMT_VTIME ":" fmt, vtime(), ##__VA_ARGS__)

#define LOG_DEBUG(fmt, ...) \
        PORE_LOG_DEBUG(FMT_VTIME ":" fmt, vtime(), ##__VA_ARGS__)

#define LOG_ERROR(fmt, ...) \
        PORE_LOG_ERROR(FMT_VTIME ":" fmt, vtime(), ##__VA_ARGS__)

#define TRACE_OUTPUT(fmt, ...) \
        PORE_TRACE_OUTPUT(FMT_VTIME ":" fmt, vtime(), ##__VA_ARGS__)

#define TRACE_INFO(fmt, ...) \
        PORE_TRACE_INFO(FMT_VTIME ":" fmt, vtime(), ##__VA_ARGS__)

#define TRACE_DEBUG(fmt, ...) \
        PORE_TRACE_DEBUG(FMT_VTIME ":" fmt, vtime(), ##__VA_ARGS__)

#define TRACE_ERROR(fmt, ...) \
        PORE_TRACE_ERROR(FMT_VTIME ":" fmt, vtime(), ##__VA_ARGS__)

/// Convert a TOD value into a virtual time
#define tod2vtime(tod) \
    ((double)(tod) / (PTS_TOD_FREQUENCY_MHZ * 1e6))

#endif // CONFIGURE_PTS_SLW

#endif // __ASSEMBLER__

#endif // __PTS_CONFIG_H__
