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
        .seeprom

//------------------------------------------------------------------------------
// Global Data 
//------------------------------------------------------------------------------

	.xip_quad occ_runtime_scom, 0

//------------------------------------------------------------------------------
// Local Macros 
//------------------------------------------------------------------------------

 
//------------------------------------------------------------------------------
// Procedure 
//------------------------------------------------------------------------------

        .procedure proc_sbe_ex_occ_runtime_scom, slw, "$Revision: 1.8 $"

	// Run the SCOM sequence if the SCOM procedure is defined

	la	A0, occ_runtime_scom
	ld	D0, 0, A0
	braz	D0, 1f
    POREVE_INF("Launching OCC Runtime SCOM routine")
	bsrd	D0
1:	
        .end_procedure proc_sbe_ex_occ_runtime_scom
