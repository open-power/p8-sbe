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
#include "proc_sbe_l3_pgood.H"
        .list


//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom

//------------------------------------------------------------------------------
// Global Data 
//------------------------------------------------------------------------------

	.xip_quad ex_init_escape, 0

//------------------------------------------------------------------------------
// Local Macros 
//------------------------------------------------------------------------------

 
//------------------------------------------------------------------------------
// Procedure 
//------------------------------------------------------------------------------

        .procedure proc_sbe_ex_init_escape, slw, "$Revision: 1.7 $"

        POREVE_DBG("Configuring L3 LCO setup");
        l3_setup L3_SETUP_ACTION_ENABLE, L3_SETUP_UNIT_L3_LCO

        // Run the init file procedure if the procedure is defined
	la	A0, ex_init_escape
	ld	D0, 0, A0
	braz	D0, 1f
	bsrd	D0
1:
        .end_procedure proc_sbe_ex_init_escape
