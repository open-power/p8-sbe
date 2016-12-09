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



#ifndef __PTS_COMMAND_H__
#define __PTS_COMMAND_H__


/// \file pts_command.h
/// \brief The PTS command and completion interface structures
///
/// PTS implements a simple command/response interface by means of a command
/// word and a response word.  Commands are provided to start and stop PTS
/// thread scheduling, and safely start, terminate and remove previously
/// configured threads.  The full semantics of each command are documented
/// with the constants that define the command type; See \ref pts_commands.
///
/// Commands are processed at the top of every scheduling loop.  Commands are
/// processed even if PTS thread scheduling is stopped. Since PTS is a
/// single-threaded executable no threads are executing when commands are
/// processed so the thread table can be freely modified by commands.
///
/// It is assumed that the build or external control environment will handle
/// the complexity of static or dynamic addition of threads to the scheduler
/// table. Also note that terminated or suspended threads can also be
/// restarted by the simple expedient of writing the threads'
/// next-schedule-time to 0.
///
/// A command is a 64-bit value, further divided into command and priority
/// fields as defined by the PtsCommand union.  Responses are small integers,
/// with a 0 response indicating success. The external control environment may
/// wish to write the response field to -1 prior to issuing the command in
/// order to unambiguosuly observe the response.  The possible response codes
/// are documented here: \ref pts_response_codes. The response code
/// PTS_INVALID_COMMAND indicates an invalid command.
///
/// The OCC application of PTS also issues command responses in the completion
/// queue. 

#include "pts_structures.h"

/// \defgroup pts_command PTS Command Codes
///
/// @{

/// Start PTS thread scheduling
///
/// This command starts the PTS thread scheduling function. This command can
/// be issued regardless of the current state of PTS. Note that the initial
/// stopped/run state of PTS is a static initialization, so this command may
/// or may not be required to initially start PTS.
///
/// This command can not fail.
#define PTS_START_PTS 1

/// Stop PTS thread scheduling
///
/// This command stops the PTS thread scheduling function. While in the
/// stopped state the PTS infrastructure continues to process PORE interrupts
/// and PTS commands, but no PTS threads are allowed to run. This command can
/// be issued regardless of the current state of PTS.
///
/// This command can not fail.
#define PTS_STOP_PTS 2

/// Mark a thread as immediately runnable
///
/// This command marks a thread as immediately runnable. The thread will run
/// as soon as its scheduling priority allows. It is not considered an error
/// to invoke this command on a thread that is already runnable, however this
/// might cause the thread to misbehave if the thread is currently pending on
/// a self-scheduled timeout. Caveat emptor.
///
/// Note that the OCC async implementation allows suspended and terminated
/// threads to resume without the necessity of a command by the simple
/// expedient of writing their next schedule times to PTS_RUNNABLE (0). 
///
/// This command may fail with the response codes PTS_INVALID_PRIORITY and
/// PTS_THREAD_NOT_FOUND.
#define PTS_SCHEDULE_THREAD 3

/// Suspend a thread immediately
///
/// This command marks a thread as force-suspended, regardless of the current
/// thread state.  Note however that none of the normal termination handlers
/// for the thread are executed, under the assumption that control application
/// will handle any termination for the thread.
///
/// This command may fail with the response codes PTS_INVALID_PRIORITY and
/// PTS_THREAD_NOT_FOUND.
#define PTS_SUSPEND_THREAD 4

/// Terminate a thread immediately
///
/// This command marks a thread as force-terminated, regardless of the current
/// thread state. This allows the thread to be cleanly restarted from its
/// entry point if required. Note however that none of the normal termination
/// handlers for the thread are executed, under the assumption that control
/// application will handle any termination for the thread.
///
/// This command may fail with the response codes PTS_INVALID_PRIORITY and
/// PTS_THREAD_NOT_FOUND.
#define PTS_TERMINATE_THREAD 5

/// Remove a thread from the scheduler table
///
/// This command simply removes the thread from the thread scheduler table.
///
/// This command may fail with the response codes PTS_INVALID_PRIORITY and
/// PTS_THREAD_NOT_FOUND.
#define PTS_REMOVE_THREAD 6

/// Inject a SCOM error into PTS
///
/// This will cause PTS to terminate with PtsState.RC = PTS_ERROR_0
#define PTS_INJECT_SCOM_ERROR 7

/// Inject an OCI error into PTS
///
/// This will cause PTS to terminate with PtsState.RC = PTS_ERROR_1
#define PTS_INJECT_OCI_ERROR 8

/// Inject an illegal instruction error into PTS
///
/// This will cause PTS to terminate with PtsState.RC = PTS_ERROR_2
#define PTS_INJECT_INSTRUCTION_ERROR 9

/// Inject a double fault into PTS
///
/// PTS cannot handle this error and will simply halt.
#define PTS_INJECT_DOUBLE_FAULT 10

/// @}


/// \defgroup pts_response_codes PTS Response Codes
///
/// A response code of 0 indicates success.
///
/// @{

/// The command field of a PtsCommand structure is invalid
#define PTS_INVALID_COMMAND 1

/// A command including a thread priority names a priority that is not
/// supported by the current scheduler table.
#define PTS_INVALID_PRIORITY 2

/// There is no thread with the given priority in the scheduler table.
#define PTS_THREAD_NOT_FOUND 3

/// @}


#ifndef __ASSEMBLER__

/// PTS Command structure

typedef union PtsCommand {

    uint64_t value;
    struct {
        
        /// The command, a required field. See \ref pts_commands
        uint8_t command;

        /// The thread priority parameter
        ///
        /// All commands other than PTS_START_PTS and PTS_STOP_PTS require a
        /// priority level to be specified in order to indentfy a thread to
        /// operate on.
        uint8_t priority;

        uint8_t pad[2];

        /// An uninterpreted argument
        uint32_t arg;
    };

} PtsCommand;

#else // __ASSEMBLER__

        // Extract fields of command records

        .macro  ptsCommandGetCommand, record:req, command:req
        ..data  (\record)
        ..data  (\command)
        extrdi  (\command), (\record), 8, 0
        .endm

        .macro  ptsCommandGetPriority, record:req, priority:req
        ..data  (\record)
        ..data  (\priority)
        extrdi  (\priority), (\record), 8, 8
        .endm

#endif // __ASSEMBLER__
    

/// \defgroup pts_completions PTS Completion Types
///
/// @{

/// The completion of a thread
#define PTS_THREAD_COMPLETION 1

/// The completion of a commmand
#define PTS_COMMAND_COMPLETION 2

/// @}


#ifndef __ASSEMBLER__

/// Command and thread completion records for PTS/OCC

typedef union PtsCompletion {

    uint64_t value;
    struct {
        
        /// The completion type. See \ref pts_completions.
        ///
        /// Thread completions will set the rc, priority and address fields of
        /// the union.  Command completions only set the rc field.
        ///
        /// 
        uint8_t completion;

        /// The command response code or thread return code
        uint8_t rc;

        /// The thread priority for completing threads
        uint8_t priority;

        uint8_t pad;

        union {
            /// The PtsThread structure for completing threads
            PtsThread* thread;

            /// The PtsCommand arg for completing commands
            uint32_t arg;
        };
    };

} PtsCompletion;

#else // __ASSEMBLER__

        .set    SIZE_OF_PTS_COMPLETION, 8

        // Set fields of completion records.  The completion type itself is
        // always a constant; other fields are always variables.

        .macro  ptsCompletionSetCompletion, record:req, completion:req
        ..data (\record)
        andi    (\record), (\record), 0x00ffffffffffffff
        ori     (\record), (\record), ((\completion) << 56)
        .endm

        .macro  ptsCompletionSetRc, record:req, rc:req
        ..dxdy  (\record), (\rc)
        insrdi  (\record), (\rc), 8, 8
        .endm

        .macro  ptsCompletionSetPriority, record:req, priority:req
        ..dxdy  (\record), (\priority)
        insrdi  (\record), (\priority), 8, 16
        .endm


        .macro  ptsCompletionSetThread, record:req, thread:req
        ..dxdy  (\record), (\thread)
        insrdi  (\record), (\thread), 32, 32
        .endm

#endif // __ASSEMBLER__


#ifndef __ASSEMBLER__

/// Completion queues for PTS/OCC
///
/// The queue is a fixed-length circular buffer managed with read/writer
/// indices.  The queue is managed using the discipline that if the readIndex
/// and writeIndex are equal, then the queue is empty. Therefore to guarantee
/// that the queue will never overflow the queue must have an entry for every
/// possible simultaneously active completion + 1.  The queue entries are each
/// 8 bytes as defined by the PtsCompletion structure.
///
/// These queue structures including the queue data are required to be
/// allocated in noncacheable memory by the OCC.

typedef struct PtsCompletionQueue {

    /// The 48-bit PORE address of the actual queue data.
    union {
        uint64_t pData;
        struct {
            uint32_t poreAddressSpace;
            PtsCompletion* data;
        };
    };

    /// The number of 8-byte entries in the queue
    const uint64_t entries;

    /// The read index; Not allowed to cache in a register
    volatile uint64_t readIndex;

    /// The write index; Not allowed to cache in a register
    volatile uint64_t writeIndex;

} PtsCompletionQueue;

#else // __ASSEMBLER__

        // The (partial) assembler layout of the PtsCompletionQueue

        .struct 0
        _ptsStructField PTS_COMPLETION_QUEUE_DATA
        _ptsStructField PTS_COMPLETION_QUEUE_ENTRIES
        _ptsStructField PTS_COMPLETION_QUEUE_READ_INDEX
        _ptsStructField PTS_COMPLETION_QUEUE_WRITE_INDEX
SIZE_OF_PTS_COMPLETION_QUEUE:
        .previous

        
         // Static allocation of a PtsCompletionQueue in assembler. The queue
         // must have at least 2 entries, and is initialized empty.

        .macro ptsDeclareCompletionQueue, data:req, entries:req

        .if     ((\entries) < 2)
                .error "There must be at least 2 entries in a PtsCompletionQueue"
        .endif
        
        .quada  (\data)
        .quad   (\entries)
        .quad   0
        .quad   0

        .endm
      

#endif // __ASSEMBLER__

#endif // __PTS_COMMAND_H__
