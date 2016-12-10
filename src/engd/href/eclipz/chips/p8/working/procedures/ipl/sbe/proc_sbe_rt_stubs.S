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
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .oci

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

	// We need a header for the test image; pretend the entry
	// point is proc_sbe_run_exinit.

	SbeXipHeader SBE_BASE_MAGIC, SBE_BASE_ORIGIN, proc_sbe_run_exinit, _sbe_base_size

        .text

	// Called by SLW code to run EX-init procedures
	.global	proc_sbe_run_exinit
proc_sbe_run_exinit:

	// .callproc helpers
	.global callproc_prologue
callproc_prologue:
	.global callproc_epilogue
callproc_epilogue:

    .global updatestep_D0_P1_step_D1
updatestep_D0_P1_step_D1:

	.rt_data

	// Control word required by all SLW code, including some code
	// in .ipl_text 
	.global slw_control_vector
slw_control_vector:
