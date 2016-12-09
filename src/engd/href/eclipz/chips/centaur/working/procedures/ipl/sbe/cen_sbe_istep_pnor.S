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
// 1.31  |16-May-2013|yctschan | added tcn_refr_time_ring
// 1.27  |19-Feb-2013|bellows  | added tcm/tcn_perv_func_ring
// 1.1-26|19-Feb-2013|thomsen+ | Various Authors

//------------------------------------------------------------------------------
// Includes
//------------------------------------------------------------------------------
        .nolist
#include "cen_sbe.H"
        .list


//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .pnor
        .ipl_text

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

        // Functional rings (+ overrides)
	.xip_quad tp_pll_gptr_ring, 0, 2
	.xip_quad tp_pll_func_ring, 0, 2
	.xip_quad tp_pll_bndy_ring, 0, 2

	.xip_quad tcn_dmi_func_ring, 0, 2

	.xip_quad tcn_mbs_func_ring, 0, 2
	.xip_quad tcn_mbs_cmsk_ring, 0, 2

	.xip_quad tcn_mbi_func_ring, 0, 2
	.xip_quad tcn_mbi_cmsk_ring, 0, 2
	.xip_quad tcn_mbi_gptr_ring, 0, 2

	.xip_quad tcm_memn_cmsk_ring, 0, 2
	.xip_quad tcm_mems_cmsk_ring, 0, 2
	.xip_quad tcm_memn_func_ring, 0, 2
	.xip_quad tcm_mems_func_ring, 0, 2

	.xip_quad tcm_perv_func_ring, 0, 2
	.xip_quad tcn_perv_func_ring, 0, 2

	.xip_quad tcn_refr_func_ring, 0, 2
	.xip_quad tcn_refr_abst_ring, 0, 2

	.xip_quad tcn_refr_time_ring, 0, 2
//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
	.ipl_text

        .xip_address entry_point, _sbe_pnor_start

        .global _sbe_pnor_start
_sbe_pnor_start:
        .global cen_sbe_istep_pnor
cen_sbe_istep_pnor:
        .callproc cen_sbe_tp_chiplet_init1 skiperrorchecks=1
        .callproc cen_sbe_pll_initf skiperrorchecks=1
        .callproc cen_sbe_pll_setup skiperrorchecks=1
        .callproc cen_sbe_tp_chiplet_init2 skiperrorchecks=1
        .callproc cen_sbe_tp_arrayinit skiperrorchecks=1
        .callproc cen_sbe_tp_chiplet_init3
        .callproc cen_sbe_chiplet_init
        .callproc cen_sbe_arrayinit

        .callproc cen_sbe_dts_init
        .callproc cen_sbe_initf
        .callproc cen_sbe_do_manual_inits

        .callproc cen_sbe_nest_startclocks
        .callproc cen_sbe_scominits

        .global _cen_sbe_seeprom_halt
_cen_sbe_seeprom_halt:
        //Halt with success
        reqhalt RC_SBE_SUCCESS, D0, P1

