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



#ifndef __PTS_INTERNAL_H__
#define __PTS_INTERNAL_H__


/// \file pts_internal.h
/// \brief Internal 'non-published' macros for PORE Thread Scheduler (PTS)
///
/// These macros will never be used directly by PTS thread applications, but
/// may be required by thread and environment error handlers and the unique
/// PORE/PTS interrupt handler.

#ifdef __ASSEMBLER__

#include "pgas.h"
#include "pts_config.h"


////////////////////////////////////////////////////////////////////////////
// PtsState
////////////////////////////////////////////////////////////////////////////

        // Load the engine-specific PTS_STATE. A Dx register is scratched, and 
        // an Ax register contains the address of the PtsState object at the
        // end.  

        .macro  _ptsLoadPtsState, ptsState:req, scratch:req
        ..address (\ptsState)
        ..data  (\scratch)

#if CONFIGURE_PTS_SLW

        la      (\ptsState), G_pts_slwState

#else
        
        tebgpe1 (\scratch), 78756230f
                la      (\ptsState), G_pts_gpe0State
                bra     78756231f
78756230:
                la      (\ptsState), G_pts_gpe1State
78756231:       

#endif
        .endm


        // Load the engine-specific OCI base address        

        .macro  _ptsGetOciBase, ptsState:req, ociBase:req, scratch:req
        ..address (\ptsState)
        ..address (\ociBase)
        ..data  (\scratch)

#if CONFIGURE_PTS_SLW

        la      (\ociBase), PTS_SLW_OCI_BASE

#else
        ld      (\scratch), PTS_STATE_OCI_BASE, (\ptsState)
        mr      (\ociBase), (\scratch)

#endif
        .endm                


        // Get the current thread address into an Ax register                

        .macro  _ptsGetCurrentThread, ptsState:req, thread:req, scratch:req
        ..address (\ptsState)
        ..address (\thread)
        ..data  (\scratch)
        ld      (\scratch), PTS_STATE_CURRENT_THREAD, (\ptsState)
        mr      (\thread), (\scratch)
        .endm                


////////////////////////////////////////////////////////////////////////////
// Miscellaneous
////////////////////////////////////////////////////////////////////////////

        // Clear the stack by writing the "empty stack" state into PC_STACK0,
        // then clearing the register to remove the sticky stack-update
        // bit. The caller must have established the OCI base address in an
        // address register.

        .macro  _ptsClearStack, ociBase:req

        ..address (\ociBase)
        sti     PTS_PORE_PC_STACK0_OFFSET, (\ociBase), PTS_STACK0_EMPTY
        sti     PTS_PORE_PC_STACK0_OFFSET, (\ociBase), 0

        .endm


        // Generate an entry for an expected entry or error branch in a PORE
        // branch table.  

        .macro  _ptsBatEntry, symbol:req
        braa    \symbol
        .endm


        // Generate an entry for an unexpected entry or error in PORE branch
        // table.

        .macro  _ptsUnexpectedBatEntry, symbol:req, code:req
        ls      D0, (\code)
        bra     \symbol
        nop
        .endm

       
        // Increment a statistic in the PtsState

        .macro _ptsIncrStateStat, stat:req, ptsState:req, scratch:req
        ..address (\ptsState)
        ..data  (\scratch)

#if CONFIGURE_PTS_STATS

        ld      (\scratch), PTS_STATE_STAT_\stat, (\ptsState)
        adds    (\scratch), (\scratch), 1
        std     (\scratch), PTS_STATE_STAT_\stat, (\ptsState)

#endif // CONFIGURE_PTS_STATS

        .endm



////////////////////////////////////////////////////////////////////////////
// Interrupts
////////////////////////////////////////////////////////////////////////////

        // PTS interrupt enable/disable macros are for internal use only.
        // Application threads always run with interrupts disabled and must
        // yield or sleep periodically to allow interrupts to be taken. The
        // caller 'ociBase' Ax register must hold the OCI base address of the
        // engine at entry. Caller 'scratch' register DX is scratched.
        //
        // The lock_exe_trigger bit is purely software-controlled now, and we
        // ensure that it doesn't get in the way of PTS operations.

        .macro  _ptsEnableInterrupts, ociBase:req, scratch:req
        
        ..address (\ociBase)
        ..data (\scratch)
        
        ldandi  (\scratch), PTS_PORE_CONTROL_OFFSET, (\ociBase), \
                ~PTS_PORE_CONTROL_LOCK_EXE_TRIG
        ori     (\scratch), (\scratch), \
                (PTS_PORE_CONTROL_INTERRUPTIBLE | \
                (PTS_PORE_CONTROL_INTERRUPTIBLE_EN))
        std     (\scratch), PTS_PORE_CONTROL_OFFSET, (\ociBase)
        
        .endm


        .macro  _ptsDisableInterrupts, ociBase:req, scratch:req
        
        ..address (\ociBase)
        ..data (\scratch)
        
        ldandi  (\scratch), PTS_PORE_CONTROL_OFFSET, (\ociBase), \
                ~(PTS_PORE_CONTROL_INTERRUPTIBLE | \
                PTS_PORE_CONTROL_LOCK_EXE_TRIG)
        ori     (\scratch), (\scratch), PTS_PORE_CONTROL_INTERRUPTIBLE_EN
        std     (\scratch), PTS_PORE_CONTROL_OFFSET, (\ociBase)
        
        .endm


////////////////////////////////////////////////////////////////////////////
// Context Switch
////////////////////////////////////////////////////////////////////////////
//
// The context switch macros allow PTS threads to name the set of registers to
// save/restore or remain unmodified across the context switch.  PTS allows
// threads free use of 7 programmer-visible registers: A0, A1, D0, D1, P0, P1
// and CTR.  SPRG0 is reserved to PTS and is used as the pointer to the
// current thread.  The context save/restore macros require a free Dx register
// to operate, i.e., the register-save list can not contain both D0 and D1.
// Currently there is no support for restoring a context in any place other
// than the place it was saved.
//
// Notes :
//
// These macros only apply to PTS threads.  The special PTS interrupt
// handler(s) is (are) completely responsible for saving and restoring any of
// its context, and is (are) allowed to use SPRG0 at will. Due to the way the
// PORE is designed the interrupt handler(s) is (are) always re-entered at its
// (their) entry points(s) as recorded in the PORE branch table.
//
// These macro definitions take advantage of the fact that PGAS/PORE uses
// small integers to represent registers (the same encoding used by the
// hardware), and that assembler macros can perform computation by
// reassigning symbol values.  The context switch uses the symbol
// _PTS_CONTEXT_MASK to record the register save list between the
// _ptsSaveContext and _ptsRestoreContex macros. 

#define _PTS_CONTEXT_INCLUDES(bit) (_PTS_CONTEXT_MASK & BIT(bit))


        //////////////////////////////////////////////////////////////////////
        // _ptsSaveContext
        //////////////////////////////////////////////////////////////////////

        // Save the register context to the current thread structure. PTS
        // reserves SPRG0 as the pointer to the current thread while executing
        // threads. 

        .macro  _ptsSaveContext, r0=-1, r1=-1, r2=-1, r3=-1, r4=-1, r5=-1

        // Create the register mask.  If it's 0 we're done.

        _ptsCreateRegisterMask _PTS_CONTEXT_MASK, \
         (\r0), (\r1), (\r2), (\r3), (\r4), (\r5)
        
        .if     (_PTS_CONTEXT_MASK != 0)                

                // Only one of D0/D1 can be saved.  If D0 is saved it will be
                // first moved to D1. Then move the pointer to the current
                // thread into A0 from SPRG0, moving A0 to D0 if necessary
                // first.
                
                .if     ((_PTS_CONTEXT_INCLUDES(D0)) && \
                         (_PTS_CONTEXT_INCLUDES(D1)))
                        .error  "Can't save both D0 and D1 across a context switch"
                .endif
                .if     (_PTS_CONTEXT_INCLUDES(D0))
                        mr      D1, D0
                .endif  
                .if     (_PTS_CONTEXT_INCLUDES(A0))
                        mr      D0, A0
                .endif  
                mr      A0, SPRG0
                
                
                // Unload register state into the thread structure. Recall
                // that D0 has been moved to D1 and A0 has been moved to D0 if
                // being saved respectively.
                
                .if     (_PTS_CONTEXT_INCLUDES(D0))
                        std     D1, PTS_THREAD_D0, A0
                .endif
                .if     (_PTS_CONTEXT_INCLUDES(D1))
                        std     D1, PTS_THREAD_D1, A0
                .endif
                .if     (_PTS_CONTEXT_INCLUDES(A0))
                        std     D0, PTS_THREAD_A0, A0
                .endif
                .if     (_PTS_CONTEXT_INCLUDES(A1))
                        mr      D0, A1
                        std     D0, PTS_THREAD_A1, A0
                .endif
                .if     (_PTS_CONTEXT_INCLUDES(P0))
                        mr      D0, P0
                        std     D0, PTS_THREAD_P0, A0
                .endif
                .if     (_PTS_CONTEXT_INCLUDES(P1))
                        mr      D0, P1
                        std     D0, PTS_THREAD_P1, A0
                .endif
                .if     (_PTS_CONTEXT_INCLUDES(CTR))
                        mr      D0, CTR
                        std     D0, PTS_THREAD_CTR, A0
                .endif
        
        .endif
        .endm


        //////////////////////////////////////////////////////////////////////
        /// _ptsRestoreContext
        //////////////////////////////////////////////////////////////////////

        // Restore the register context from the current thread structure. PTS
        // reserves SPRG0 as the pointer to the current thread while executing
        // threads, and the value of SPRG0 is the only assumption at entry.

        .macro  _ptsRestoreContext

        .if     (_PTS_CONTEXT_MASK != 0)                             
                            
                mr      A0, SPRG0

                // First load P0, P1, CTR and A1 via A0/D0

                .if     (_PTS_CONTEXT_INCLUDES(P0))
                        ld      D0, PTS_THREAD_P0, A0
                        mr      P0, D0
                .endif
                .if     (_PTS_CONTEXT_INCLUDES(P1))
                        ld      D0, PTS_THREAD_P1, A0
                        mr      P1, D0
                .endif
                .if     (_PTS_CONTEXT_INCLUDES(CTR))
                        ld      D0, PTS_THREAD_CTR, A0
                        mr      CTR, D0
                .endif
                .if     (_PTS_CONTEXT_INCLUDES(A1))
                        ld      D0, PTS_THREAD_A1, A0
                        mr      A1, D0
                .endif
        

                //  Either saved data register (there can only be one) is
                //  reloaded into D1. If A0 was saved it is restored via
                //  D0. Then D0 is moved to its correct location if necessary.

                .if     (_PTS_CONTEXT_INCLUDES(D0))
                        ld      D1, PTS_THREAD_D0, A0
                .endif
                .if     (_PTS_CONTEXT_INCLUDES(D1))
                        ld      D1, PTS_THREAD_D1, A0
                .endif
                .if     (_PTS_CONTEXT_INCLUDES(A0))
                        ld      D0, PTS_THREAD_A0, A0
                        mr      A0, D0
                .endif
                .if     (_PTS_CONTEXT_INCLUDES(D0))
                        mr      D0, D1
                .endif
        .endif

        .endm


        //////////////////////////////////////////////////////////////////////
        /// _ptsAddRegToMask
        //////////////////////////////////////////////////////////////////////

        // Initialize a symbol from a list of registers, checking for illegal
        // and duplicate values. The mask argument must be a symbol.

        .macro  _ptsAddRegToMask mask:req, reg:req
        .if     ((\reg) >= 0)
                .if     (((\reg) != D0) && \
                         ((\reg) != D1) && \
                         ((\reg) != A0) && \
                         ((\reg) != A1) && \
                         ((\reg) != P0) && \
                         ((\reg) != P1) && \
                         ((\reg) != CTR))
                        .error  "Symbol or expression is not a legal register for register-save list"
                .else                   
                        .if     (\mask & BIT(\reg))
                                .error  "Duplicate register specified in register-save list"
                        .else
                                .set  \mask, (\mask | BIT(\reg))
                        .endif
                .endif
        .endif
        .endm
        

        //////////////////////////////////////////////////////////////////////
        /// _ptsCreateRegisterMask
        //////////////////////////////////////////////////////////////////////

        .macro  _ptsCreateRegisterMask mask:req, \
                r0=-1, r1=-1, r2=-1, r3=-1, r4=-1, r5=-1
        .set    \mask, 0
        _ptsAddRegToMask \mask, (\r0)
        _ptsAddRegToMask \mask, (\r1)
        _ptsAddRegToMask \mask, (\r2)
        _ptsAddRegToMask \mask, (\r3)
        _ptsAddRegToMask \mask, (\r4)
        _ptsAddRegToMask \mask, (\r5)
        .endm


////////////////////////////////////////////////////////////////////////////
// Debug
////////////////////////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////////////////
        // _ptsBrad
        // _ptsBsrd
        //////////////////////////////////////////////////////////////////////

        // brad/bsrd that trap on null pointers in debug mode
        
        .macro  _ptsBrad, dx:req

        ..data  (\dx)

#if CONFIGURE_PTS_DEBUG

        andi    (\dx), (\dx), 0xffffffff
        branz   (\dx), 7872723f

                halt
7872723:
        ori     (\dx), (\dx), (PORE_SPACE_OCI << 32)

#endif // CONFIGURE_PTS_DEBUG
        
        brad    (\dx)

        .endm

        
        .macro  _ptsBsrd, dx:req

        ..data  (\dx)

#if CONFIGURE_PTS_DEBUG

        andi    (\dx), (\dx), 0xffffffff
        branz   (\dx), 7872773f

                halt
7872773:
        ori     (\dx), (\dx), (PORE_SPACE_OCI << 32)

#endif // CONFIGUIRE_PTS_DEBUG
        
        brad    (\dx)

        .endm


        // Store an immediate bread crumb in the state object, from a pointer
        // held in an AX register

        .macro  _ptsStateCrumbI, index:req, ptsState:req, crumb:req
        ..address (\ptsState)

        .if     (((\index) < 0) || ((\index) > PTS_STATE_CRUMBS))
        .error  "Index out of range"
        .endif

#if CONFIGURE_PTS_DEBUG
        sti     (PTS_STATE_CRUMB + (8 * (\index))), (\ptsState), (\crumb)
#endif
        .endm


        // Store a bread crumb in the state object, from a data register and 
        // a pointer held in an AX register

        .macro  _ptsStateCrumbD, index:req, ptsState:req, crumb:req
        ..address (\ptsState)
        ..data    (\crumb)

        .if     ((\index) < 0) || ((\index) > PTS_STATE_CRUMBS)
        .error  "Index out of range"
        .endif

#if CONFIGURE_PTS_DEBUG
        std     (\crumb), (PTS_STATE_CRUMB + (8 * (\index))), (\ptsState)
#endif
        .endm

        
        // Get a bread crumb from the state object.

        .macro  _ptsStateGetCrumb, index:req, ptsState:req, crumb:req
        ..address (\ptsState)
        ..data    (\crumb)

        .if     ((\index) < 0) || ((\index) > PTS_STATE_CRUMBS)
        .error  "Index out of range"
        .endif

#if CONFIGURE_PTS_DEBUG
        ld      (\crumb), (PTS_STATE_CRUMB + (8 * (\index))), (\ptsState)
#else
        .error  "_ptsStateGetCrumb requires CONFIGURE_PTS_DEBUG"
#endif
        .endm

        
        // Increment a bread crumb in the state object

        .macro  _ptsStateIncrCrumb, index:req, ptsState:req, scratch:req
        ..address (\ptsState)
        ..data    (\scratch)

        .if     ((\index) < 0) || ((\index) > PTS_STATE_CRUMBS)
        .error  "Index out of range"
        .endif

#if CONFIGURE_PTS_DEBUG
        ld      (\scratch), (PTS_STATE_CRUMB + (8 * (\index))), (\ptsState)
        adds    (\scratch), (\scratch), 1
        std     (\scratch), (PTS_STATE_CRUMB + (8 * (\index))), (\ptsState)
#endif
        .endm

        
        // Set a crumb to a TOD timestamp

        .macro  _ptsStateTODCrumb index:req, ptsState:req, scratch:req, px:req

#if CONFIGURE_PTS_DEBUG
        lpcs    (\px), PTS_TOD
        ld      (\scratch), PTS_TOD, (\px)
        _ptsStateCrumbD (\index), ptsState=(\ptsState), crumb=(\scratch)
#endif

        .endm


        // Increment a bread crumb in the thread object

        .macro  _ptsThreadIncrCrumb, index:req, ptsThread:req, scratch:req
        ..address (\ptsThread)
        ..data    (\scratch)

        .if     ((\index) < 0) || ((\index) > PTS_THREAD_CRUMBS)
        .error  "Index out of range"
        .endif

#if CONFIGURE_PTS_DEBUG
        ld      (\scratch), (PTS_THREAD_CRUMB + (8 * (\index))), (\ptsThread)
        adds    (\scratch), (\scratch), 1
        std     (\scratch), (PTS_THREAD_CRUMB + (8 * (\index))), (\ptsThread)
#endif
        .endm

        
        // Enable the TRAP instruction
        
        .macro  _ptsEnableTrap, ociBase:req, scratch:req
        ..address (\ociBase)
        ..data  (\scratch)
        
        ld      (\scratch), PTS_PORE_CONTROL_OFFSET, (\ociBase)
        ori     (\scratch), (\scratch), PTS_PORE_CONTROL_TRAP_ENABLE
        std     (\scratch), PTS_PORE_CONTROL_OFFSET, (\ociBase)

        .endm
        

        // Disable the TRAP instruction
        
        .macro  _ptsDisableTrap, ociBase:req, scratch:req
        ..address (\ociBase)
        ..data  (\scratch)
        
        ld      (\scratch), PTS_PORE_CONTROL_OFFSET, (\ociBase)
        andi    (\scratch), (\scratch), ~PTS_PORE_CONTROL_TRAP_ENABLE
        std     (\scratch), PTS_PORE_CONTROL_OFFSET, (\ociBase)

        .endm
        

        // Set the breakpoint address from a symbol.  This requires both D0
        // and D1.
        
        .macro  _ptsSetBreakpoint, ociBase:req, break:req
        ..address (\ociBase)
        
        ld      D0, PTS_PORE_CONTROL_OFFSET, (\ociBase)
        la      D1, (\break)
        insrdi  D0, D1, 48, 16
        std     D0, PTS_PORE_CONTROL_OFFSET, (\ociBase)
        
        .endm
        

        // TRAP if an interrupt is pending
        
        .macro  _ptsTrapIfInterruptPending, ociBase:req, scratch:req
        ..address (\ociBase)
        ..data  (\scratch)
        
        ldandi  (\scratch), PTS_PORE_STATUS_OFFSET, (\ociBase), \
                PORE_STATUS_INTERRUPT_PENDING
        braz    (\scratch), 8447f
                trap
8447:

        .endm
        

        // HALT if an interrupt is pending
        
        .macro  _ptsHaltIfInterruptPending, ociBase:req, scratch:req
        ..address (\ociBase)
        ..data  (\scratch)
        
        ldandi  (\scratch), PTS_PORE_STATUS_OFFSET, (\ociBase), \
                PORE_STATUS_INTERRUPT_PENDING
        braz    (\scratch), 4447f
                halt
4447:

        .endm
        


#endif // __ASSEMBLER__

#endif // __PTS_INTERNAL_H__
