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
        .pibmem

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

	.ipl_text

	.global	_lco_pibmem_start

_lco_pibmem_start:

        // set pervasive base register
	POREVE_INF("Arrived in PIBMEM ...\n")
        lpcs    P1, OCB3_DATA_0x0006B075
	// start main load/store loop
	bra	lco_loop_end

lco_loop_begin:

        // read image data from PNOR
        ld      D1, 0, A1
        // store to OCB data register
        std     D1, OCB3_DATA_0x0006B075, P1
        // bump image address pointer (HW will control real address increment/
        // cacheline gathering)
        adds    A1, A1, 8

lco_loop_end:

	loop	lco_loop_begin
	// done, branch back to SEEPROM
	POREVE_INF("Branching back to SEEPROM ...\n")
	ret
