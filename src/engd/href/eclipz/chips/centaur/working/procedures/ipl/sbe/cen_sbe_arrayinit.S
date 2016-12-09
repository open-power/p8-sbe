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
#include "cen_sbe.H"
        .list

//------------------------------------------------------------------------------
// preprocessor directives
//------------------------------------------------------------------------------

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
        .procedure cen_sbe_arrayinit, cen, "$Revision: 1.13 $"
	POREVE_INF("*** Array Init and Scan0 Cleanup for good Chiplets *** ")

	//--------------------------------------------------------
        //          SBE Address Base Register Setups
        //--------------------------------------------------------
        // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

        // Setup PRV_BASE_ADDR1; points to MC group3
        ls      P1, SCAN_CHIPLET_GROUP3

        POREVE_INF("MC Group 3: Calling Array Init Subroutine ..." )
        li      D1, SCAN_ALLREGIONEXVITAL	// 0x0FF00E0000000000
        bsr     cen_arrayinit_module

        // Step 2: Scan0 for other Cplts
        // =============================
        POREVE_INF("Call SCAN0 Subroutine for MC Group 3 ..." )
        li      D0, SCAN_ALLREGIONEXVITAL       // 0x0FF00E0000000000
        li      D1, SCAN_ALLSCANEXPRV           // 0x0FF00DCE00000000
        bsr     cen_scan0_module


        POREVE_INF( "*** End of procedure ***" )
        .end_procedure cen_sbe_arrayinit
