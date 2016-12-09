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



#ifndef __PROC_CONTROL_BITS_H
#define __PROC_CONTROL_BITS_H

// $Id: proc_control_bits.H,v 1.5 2013/01/28 22:43:02 jeshua Exp $

/// \file proc_control_bits.H
/// \brief A header to define the procedure control bits
///

#include "fapi_sbe_common.H"
#include "pore_bitmanip.H"

/// \defgroup Procedure control bits
///
/// Every named PNOR procedure allocates a control word for Cronus or other
/// control applications to control the execution of the procedure. The
/// default value of 0 means to execute the procedure normally. A few
/// high-order bits of the control word may be set to alter this behavior. 
/// The other bits of the control word are reserved for procedure-specific
/// overrides.
///
/// Both HALT and TRAP controls exist for entry and exit. It is possible to
/// continue execution after either condition.  The choice of whether to use
/// TRAP or HALT may depend on whether the user needs other traps to fire
/// prior to or after the TRAP or HALT at this procedure.  Note that is HALT is
/// selected then TRAP is ignored, i.e., execution will either HALT or TRAP but
/// not both.

/// @{

/// If set, skip this procedure entirely. If skip is selected the entire
/// procedure including error checking is completely skipped. Note halt and
/// trap checks still apply.
CONST_UINT64_T(PROC_CONTROL_SKIP, BIT(0));

/// If set, halt the PORE engine at entry.  This is an unequivocal hardware
/// stop. The halt control is checked before the trap control at entry.  It is
/// possible to continue the procedure from the halt in a debugging
/// environment. 
CONST_UINT64_T(PROC_CONTROL_ENTRY_HALT, BIT(1));

/// If set, trap the procedure at entry.  This will halt the PORE engine only
/// if traps are currently enabled in the engine. Resuming from the trap will
/// continue the procedure normally.
CONST_UINT64_T(PROC_CONTROL_ENTRY_TRAP, BIT(2));

/// If set, halt the PORE engine at exit.  This is an unequivocal hardware
/// stop. The halt control is checked before the trap control at exit.  It is
/// possible to continue the procedure from the halt in a debugging
/// environment. If HALT is selected than TRAP is ignored.
CONST_UINT64_T(PROC_CONTROL_EXIT_HALT, BIT(3));

/// If set, trap the procedure at exit.  This will halt the PORE engine only
/// if traps are enabled in the engine. Resuming from the trap will continue
/// the procedure normally.
CONST_UINT64_T(PROC_CONTROL_EXIT_TRAP, BIT(4));

/// If set, disable check to halt the PORE engine at exit if a checkstop is detected. 
CONST_UINT64_T(PROC_CONTROL_EXIT_XSTOP_HALT_DISABLE, BIT(5));

/// If set, halt the PORE engine at exit if a recoverable error is detected. 
CONST_UINT64_T(PROC_CONTROL_EXIT_RECOV_HALT_ENABLE, BIT(6));

/// If set, disable check to halt the PORE engine at exit if a special attention is detected. 
CONST_UINT64_T(PROC_CONTROL_EXIT_SPATTN_HALT_DISABLE, BIT(7));
/// @}

/// If set, apply EX chiplet specific operations to all cores (master or slave) on all
/// chips (where possible), regardless of chip master designation
/// Used to support IPL of all system cores without requiring winkle cycle
CONST_UINT64_T(PROC_CONTROL_INIT_ALL_EX, BIT(8));

/// Set if cache-contained IPL is being performed (l2_l3_mode), else clear
CONST_UINT64_T(PROC_CONTROL_CACHE_CONTAINED, BIT(9));

/// SCAN RATIO OVERRIDE (BITS 19:24)
/// Bits for adjusting scan ratio in the following procedures:
/// proc_sbe_tp_chiplet_init1: TP
/// proc_sbe_chiplet_init    : Non-TP, AB, PCIE, EX
/// proc_sbe_initf           : EX, AB, PCIE
/// The following will use the proc_sbe_initf copy that was put into pibmem
///    proc_sbe_ex_gptr_time_initf
///    proc_sbe_ex_core_gptr_time_initf
///    proc_sbe_ex_dpll_initf
///    
/// These bits are currently stored in control word bits 19:24 for quick shifting
/// Bit 19 is the override enable bit. If it's zero, there is no override
/// Bits 20:24 get shifted left by 16, to end up in bits 4:8 of the scom register
CONST_UINT64_T(SCAN_RATIO_START_BIT, 4);
CONST_UINT64_T(SCAN_RATIO_END_BIT, 8);
CONST_UINT64_T(SCAN_RATIO_ROTATE_COUNT, 16);
CONST_UINT64_T(SCAN_RATIO_ENABLE_BIT, SCAN_RATIO_START_BIT-1+SCAN_RATIO_ROTATE_COUNT);

#endif
