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





//------------------------------------------------------------------------------
// Includes
//------------------------------------------------------------------------------
        .nolist
#include "p8_sbe.H"
#include "p8_slw.H"
#include "proc_sbe_initf_common_seeprom.H"
        .list


//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_ex_core_gptr_time_initf, slw, "$Revision: 1.8 $"

    // For sleep, bypass the pull back of the scan ratio
        ifsleep D0, 1f
    // Set EX scan ratio to 1:1 as EX is still at refclock
        POREVE_INF("<proc_sbe_ex_gptr_time_initf> : Set EX scan ratio to 1:1 ...\n")
        sti     EX_OPCG_CNTL0_0x10030002, P0, 0x0
1:

    // scan ring content shared among all chiplets
	    POREVE_DBG("Scanning EX core GPTR rings...\n")
	    load_ring ex_gptr_core skipoverride=1
	    load_ring ex_gptr_l2 skipoverride=1

	// scan chiplet specific ring content
	    POREVE_DBG("Scanning EX core TIME rings...\n")
        load_ring_vec_ex ex_time_core

    // Set EX scan ratio back to 8:1
        POREVE_INF("<proc_sbe_ex_core_gptr_time_initf> : Set EX scan ratio to 8:1 ...\n")
        //Inputs: A1 and P0 and D0, destroys D0 & D1
        .pibmem_port (PORE_SPACE_PIBMEM & 0xf)
        lpcs    P1, PIBMEM0_0x00080000
        ld      D0, ex_scan_ratio_override, P1
        bsr     set_scan_ratio_d0

        .end_procedure proc_sbe_ex_core_gptr_time_initf
