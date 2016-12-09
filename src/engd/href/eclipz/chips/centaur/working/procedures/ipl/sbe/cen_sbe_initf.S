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




// Change Log
//   1.12  |26-Aug-2013|jmcgilll | skip tcn_refr_time processing for DD2+
//   1.11  |17-May-2013|yctschan | added tcn_refr_time_ring
//   1.5   |19-Feb-2013|bellows  | added tcn and tcm perv rings
//   1.1-4 |19-Feb-2013|thomsen+ | Updates from various authors
//------------------------------------------------------------------------------
// Includes
//------------------------------------------------------------------------------
        .nolist
#include "cen_sbe.H"
#include "cen_sbe_fixed.H"
#include "cen_sbe_initf_common_pnor.H"
#include "common_ecids.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .pnor

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure cen_sbe_initf, cen, "$Revision: 1.12 $"

load_nest_rings:
	lpcs	P0, NEST_CHIPLET_0x02000000

        POREVE_INF("SCANNING tcn_mbs_func")
	load_ring tcn_mbs_func
        POREVE_INF("SCANNING tcn_mbs_cmsk")
	load_ring tcn_mbs_cmsk

	POREVE_INF("SCANNING tcn_mbi_cmsk")
	load_ring tcn_mbi_cmsk
        POREVE_INF("SCANNING tcn_mbi_func")
	load_ring tcn_mbi_func
        POREVE_INF("SCANNING tcn_mbi_gptr")
	load_ring tcn_mbi_gptr

        POREVE_INF("SCANNING tcn_perv_func")
        load_ring tcn_perv_func

        POREVE_INF("SCANNING tcn_dmi_func")
	load_ring tcn_dmi_func

	POREVE_INF("SCANNING tcn_refr_func")
	load_ring tcn_refr_func
        POREVE_INF("SCANNING tcn_refr_abst")
	load_ring tcn_refr_abst

        // process tcn_refr_time ring in image only for DD1
        // repair loader loads ring from OTPROM content in DD2+
        lpcs    P1, STBY_CHIPLET_0x00000000
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P1, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
        cmpibrane D0, load_mem_rings,               (CFAM_CHIP_ID_CENTAUR   | CFAM_CHIP_ID_MAJOR_EC_1)

        POREVE_INF("SCANNING tcn_refr_time")
        load_ring tcn_refr_time

load_mem_rings:
        lpcs	P0, MEM_CHIPLET_0x03000000

        POREVE_INF("SCANNING tcm_memn_cmsk")
	load_ring tcm_memn_cmsk
        POREVE_INF("SCANNING tcm_mems_cmsk")
	load_ring tcm_mems_cmsk
        POREVE_INF("SCANNING tcm_memn_func")
        load_ring tcm_memn_func
        POREVE_INF("SCANNING tcm_mems_func")
        load_ring tcm_mems_func

        POREVE_INF("SCANNING tcm_perv_func")
        load_ring tcm_perv_func

        .end_procedure cen_sbe_initf
