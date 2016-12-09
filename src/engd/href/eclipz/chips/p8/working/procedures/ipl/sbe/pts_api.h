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



#ifndef __PTS_API_H__
#define __PTS_API_H__


/// \file pts_api.h
/// \brief PTS system calls and APIs
///
/// PTS system calls explicitly or implicitly yield control back to the PTS
/// scheduler to allow interrupts to be taken, allow the current thread to
/// sleep, or to allow other, higher-priority runnable threads to
/// execute. Each operating enviornment defines the maximum amount of time a
/// thread is allowed to execute before issuing a system call.
///
/// The majority of PTS system calls allow the caller to optionally specify a
/// register context to be saved across the context switch.  The register-save
/// list may contain the registers D0, D1, A0, A1, P0, P1 and CTR. SPRG0 is
/// reserved to PTS and is implicitly saved and restored. Duplicate register
/// specifications are flagged as errors.  Both D0 and D1 may not be
/// specified, as the PORE architecture requires that at least 1 register be
/// destroyed in order to save the PORE engine state.  Some system calls
/// require a parameter in D0, and therfore can not allow D1 to be saved. Any
/// register state not explictly saved and restored by the system call should
/// be assumed to have been destroyed
///
/// The PORE stack context is always saved and restored across the system
/// call. Since all PTS system calls are implemented as macros they can be
/// invoked from any legal subroutine depth.
///
/// The exception to the above is ptsTerminate.  This is a system call that
/// terminates the thread, hence no context is saved. If a terminated thread
/// is recheduled it will begin execution at its original entry point with an
/// empty stack.
///
/// PTS APIs are also presented as assembler macros, but are implemented as
/// one or more single-level subroutine calls.  Due to the limited stack depth
/// of the PORE engine, these APIs can only be invoked from top-level code or
/// first-level subroutines. Furthermore, the caller should assume that all
/// PORE register state is destroyed by these calls.  The PTS APIs include
/// ptsMainstoreCoherent(), ptsMainstoreAtomicAdd() and ptsMainstoreDefault().

#ifdef __ASSEMBLER__

////////////////////////////////////////////////////////////////////////////
// Context save/restore system calls
////////////////////////////////////////////////////////////////////////////


        //////////////////////////////////////////////////////////////////////
        // ptsYield
        //////////////////////////////////////////////////////////////////////

        // Yield control to PTS temporarily but continue to run if possible.

        // The specified register values are saved and restored across the
        // context switch. The register-save list may contain the registers
        // D0, D1, A0, A1, P0, P1 and CTR. Both D0 and D1 may not be
        // specified. Duplicates are flagged as errors. SPRG0 is reserved to
        // PTS.

        .macro  ptsYield, \
                r0=-1, r1=-1, r2=-1, r3=-1, r4=-1, r5=-1

        _ptsSaveContext \
                (\r0), (\r1), (\r2), (\r3), (\r4), (\r5)

        la      D0, 2668398f
        braa    _ptsYield
2668398:
        _ptsRestoreContext
        .endm


        //////////////////////////////////////////////////////////////////////
        // ptsSleepConstant
        //////////////////////////////////////////////////////////////////////

        // Yield control to PTS for a constant interval of time measured by
        // the TOD 

        // The specified register values are saved and restored across the
        // context switch. The register-save list may contain the registers
        // D0, D1, A0, A1, P0, P1 and CTR. Both D0 and D1 may not be
        // specified. Duplicates are flagged as errors. SPRG0 is reserved to
        // PTS.

        .macro  ptsSleepConstant, interval:req, \
                r0=-1, r1=-1, r2=-1, r3=-1, r4=-1, r5=-1

        _ptsSaveContext \
                (\r0), (\r1), (\r2), (\r3), (\r4), (\r5)
        la      D0, 2668398f
        li      D1, (\interval)
        braa    _ptsSleep
2668398:
        _ptsRestoreContext

        .endm


        //////////////////////////////////////////////////////////////////////
        // ptsSleep
        //////////////////////////////////////////////////////////////////////

        // Yield control to PTS for a variable interval of time measured by
        // the TOD 

        // The specified register values are saved and restored across the
        // context switch. The register-save list may contain the registers
        // D0, D1, A0, A1, P0, P1 and CTR. Both D0 and D1 may not be
        // specified. Duplicates are flagged as errors. SPRG0 is reserved to
        // PTS.

        // The first argument of the macro must be one of D0 or D1. This
        // register contains the variable sleep interval in TOD ticks. This
        // register is also saved in the context, which means that the other
        // data register may not appear in the register save list and can not
        // be saved.

        .macro  ptsSleep, \
                r0=-1, r1=-1, r2=-1, r3=-1, r4=-1, r5=-1
        ..data  (\r0)

        _ptsSaveContext \
                (\r0), (\r1), (\r2), (\r3), (\r4), (\r5)
        la      D0, 2668398f
        mr      A0, SPRG0
        .if     ((\r0) == D0)
                ld      D1, PTS_THREAD_D0, A0
        .else
                ld      D1, PTS_THREAD_D1, A0
        .endif
        braa    _ptsSleep
2668398:
        _ptsRestoreContext

        .endm


        //////////////////////////////////////////////////////////////////////
        // ptsSleepAbsolute
        //////////////////////////////////////////////////////////////////////

        // Yield control to PTS until an absolute value of the TOD. If the
        // absolute time is "in the past" then this call is effectively
        // equivalent to ptsYield().

        // The specified register values are saved and restored across the
        // context switch. The register-save list may contain the registers
        // D0, D1, A0, A1, P0, P1 and CTR. Both D0 and D1 may not be
        // specified. Duplicates are flagged as errors. SPRG0 is reserved to
        // PTS.

        // The first argument of the macro must be one of D0 or D1. This
        // register contains the absolute timeout as a 64-bit TOD value. This
        // register is also saved in the context, which means that the other
        // data register may not appear in the register save list and can not
        // be saved.

        .macro  ptsSleepAbsolute, \
                r0=-1, r1=-1, r2=-1, r3=-1, r4=-1, r5=-1
        ..data  (\r0)

        _ptsSaveContext \
                (\r0), (\r1), (\r2), (\r3), (\r4), (\r5)

        la      D0, 2668398f
        mr      A0, SPRG0
        .if     ((\r0) == D0)
                ld      D1, PTS_THREAD_D0, A0
        .else
                ld      D1, PTS_THREAD_D1, A0
        .endif
        braa    _ptsSleepAbsolute
2668398:
        _ptsRestoreContext

        .endm


////////////////////////////////////////////////////////////////////////////
// Thread control system calls
////////////////////////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////////////////
        // ptsSuspend
        //////////////////////////////////////////////////////////////////////

        // Suspend the thread. The thread will be suspended and the thread- or
        // engine-specific termination handler will be invoked. The thread
        // return code is forced to 0 here. If restarted, the thread will
        // restart at the suspension point.

        // The specified register values are saved and restored across the
        // suspension context switch. The register-save list may contain the
        // registers D0, D1, A0, A1, P0, P1 and CTR. Both D0 and D1 may not be
        // specified. Duplicates are flagged as errors. SPRG0 is reserved to
        // PTS.

        .macro  ptsSuspend, r0=-1, r1=-1, r2=-1, r3=-1, r4=-1, r5=-1

        _ptsSaveContext (\r0), (\r1), (\r2), (\r3), (\r4), (\r5)
        la      D0, 2668398f
        braa    _ptsSuspend
2668398:
        _ptsRestoreContext

        .endm


        //////////////////////////////////////////////////////////////////////
        // ptsTerminate
        //////////////////////////////////////////////////////////////////////

        // Terminate the thread with a 64-bit return code.  The thread will be
        // terminated and the thread- or engine-specific termination handler
        // will be invoked. The thread state will be reset such that if the
        // thread is later reactivated it will restart cleanly at the original
        // entry point.

        .macro  ptsTerminate, rc=0

        li      D0, (\rc)
        braa    _ptsTerminate

        .endm


////////////////////////////////////////////////////////////////////////////
// Error handling system calls
////////////////////////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////////////////
        // ptsThreadHandlesPibErrors
        //////////////////////////////////////////////////////////////////////

        // Invoked by a thread that wants to handle execute-phase PIB errors
        // itself. A special error mask is set and the thread is flagged as
        // being in this mode. 

        // Due to HW271773, changes to the PORE Error Mask register can only
        // be made while the PORE engine is interruptible. This requires this
        // (otherwise simple) API to be executed as a context switch.

        .macro  ptsThreadHandlesPibErrors, \
                r0=-1, r1=-1, r2=-1, r3=-1, r4=-1, r5=-1

        _ptsSaveContext (\r0), (\r1), (\r2), (\r3), (\r4), (\r5)
        la      D0, 7878473f
        braa    _ptsThreadHandlesPibErrors
7878473:       
        _ptsRestoreContext
        
        .endm               
        
        //////////////////////////////////////////////////////////////////////
        // ptsPtsHandlesPibErrors
        //////////////////////////////////////////////////////////////////////

        // Invoked by a thread that no longer wants to handle PIB errors
        // itself. The default error mask is restored and the thread is
        // flagged as being in the default mode.

        // Due to HW271773, changes to the PORE Error Mask register can only
        // be made while the PORE engine is interruptible. This requires this
        // (otherwise simple) API to be executed as a context switch.

        .macro  ptsPtsHandlesPibErrors, \
                r0=-1, r1=-1, r2=-1, r3=-1, r4=-1, r5=-1
        
        _ptsSaveContext (\r0), (\r1), (\r2), (\r3), (\r4), (\r5)
        la      D0, 7877473f
        braa    _ptsPtsHandlesPibErrors
7877473:       
        _ptsRestoreContext
        
        .endm               


////////////////////////////////////////////////////////////////////////////
// Mainstore Configuration APIs
////////////////////////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////////////////
        // ptsMainstoreCoherent
        //////////////////////////////////////////////////////////////////////

        // Reset the PBA slave to reestablish coherence
        
        // The caller should assume that all PORE programmer state is
        // destroyed by this API.

        .macro  ptsMainstoreCoherent
        
        la      A0, ptsPbaDefaultParms
        bsr     ptsPbaReset

        .endm


        //////////////////////////////////////////////////////////////////////
        // ptsMainstoreDefault
        //////////////////////////////////////////////////////////////////////

        // Reprogram the PBA to do normal writes to mainstore.  At exit the
        // thread is marked as not (no longer) being in an atomic RMW mode.

        // The caller should assume that all PTS programmer state is
        // destroyed by this API.

        .macro  ptsMainstoreDefault

        la      A0, ptsPbaDefaultParms
        bsr     ptsPbaReset

        la      A0, ptsPbaDefaultParms
        bsr     ptsPbaSetup   
        
        _ptsLoadPtsState ptsState=A0, scratch=D0
        bci     D0, PTS_STATE_FLAGS, A0, PTS_STATE_MAINSTORE_ATOMIC

        .endm


        //////////////////////////////////////////////////////////////////////
        // ptsMainstoreAtomicAdd
        //////////////////////////////////////////////////////////////////////

        // Reprogram the PBA such that all writes to mainstore are implemented
        // as atomic add operations.  At entry the thread is marked as being
        // in an atomic RMW mode. If the thread is already in atomic add mode
        // this is a NOP.

        // The caller should assume that all PTS programmer state is destroyed
        // by this API.
        
        // Any thread that sets this mode must remove this mode (by invoking
        // ptsMainstoreDefault) prior to returning control to PTS via a system
        // call or other API. 

        .macro  ptsMainstoreAtomicAdd
        
        _ptsLoadPtsState ptsState=A0, scratch=D0

        ldandi  D0, PTS_STATE_FLAGS, A0, PTS_STATE_MAINSTORE_ATOMIC
        branz   D0, 7622f
        
                ori     D0, D0, PTS_STATE_MAINSTORE_ATOMIC
                std     D0, PTS_STATE_FLAGS, A0

                la      A0, ptsPbaAtomicAddParms
                bsr     ptsPbaReset

                la      A0, ptsPbaAtomicAddParms
                bsr     ptsPbaSetup
7622:   
                
        .endm



#endif // __ASSEMBLER__

#endif // __PTS_API_H__

        
        

