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



#ifndef __CEN_SBE_FIXED_H__
#define __CEN_SBE_FIXED_H__

// $Id: cen_sbe_fixed.H,v 1.5 2014/05/13 13:28:38 jmcgill Exp $

/// \file cen_sbe_fixed.H
/// \brief Define the layout of fixed-position data in the Centaur SBE PNOR
/// image
///
/// This file defines the layout of the special .fixed data section of Centaur
/// SBE PNOR images.  The .fixed section is guaranteed to appear at a fixed
/// offset from the beginning of the image, containing data required to be
/// manipulated when images are resident in non-volatile memories, thereby
/// avoiding having to search the TOC. Data manipulated during in-memory image
/// processing can always be easily located using the SBE-XIP TOC APIs.  All
/// of the data stored in .fixed can also still be referenced via the SBE-XIP
/// TOC.
///
/// This header file can be #include-ed into either C or SBE assembly language
/// source code.  In C, it creates a simple structure 'CenSbeFixed' that is
/// nothing more than an ordered set of uint64_t variables.  PORE image data
/// is always stored big-endian, so applications on little-endian hosts will
/// need to perform the appropriate endian converison when reading or writing
/// images via this header.
///
/// In assembler code, this header creates a macro '.cen_sbe_fixed' that is
/// expanded exactly once in the file 'cen_pnor_header.S', creating the actual
/// data allocation of the data equivalent to the C structure.  Assembler code
/// references the data symbols as normal.

#include "cen_sbe.H"

#ifdef __ASSEMBLER__
             .macro	.cen_sbe_fixed
	     .section   .fixed, "a", @PROGBITS
	     .balign    8
#else
typedef struct {
#endif

    // Procedure control variables listed in istep order

    PROC_SBE_FIXED_UINT64(cen_sbe_tp_chiplet_init1_control);
    PROC_SBE_FIXED_UINT64(cen_sbe_pll_initf_control);
    PROC_SBE_FIXED_UINT64(cen_sbe_pll_setup_control);
    PROC_SBE_FIXED_UINT64(cen_sbe_tp_chiplet_init2_control);
    PROC_SBE_FIXED_UINT64(cen_sbe_tp_arrayinit_control);
    PROC_SBE_FIXED_UINT64(cen_sbe_tp_chiplet_init3_control);
    PROC_SBE_FIXED_UINT64(cen_sbe_chiplet_init_control);
    PROC_SBE_FIXED_UINT64(cen_sbe_arrayinit_control);
    PROC_SBE_FIXED_UINT64(cen_sbe_dts_init_control);
    PROC_SBE_FIXED_UINT64(cen_sbe_initf_control);
    PROC_SBE_FIXED_UINT64(cen_sbe_do_manual_inits_control);
    PROC_SBE_FIXED_UINT64(cen_sbe_nest_startclocks_control);
    PROC_SBE_FIXED_UINT64(cen_sbe_scominits_control);

    //Alternate PLL ring
    PROC_SBE_FIXED_UINT64(tp_pll_bndy_ring_alt);

    // Reference clock termination customization
    PROC_SBE_FIXED_UINT64(refclock_term);
     
#ifdef __ASSEMBLER__
	.endm
#else
} ProcSbeFixed;
#endif

#endif  // __CEN_SBE_FIXED_H__


