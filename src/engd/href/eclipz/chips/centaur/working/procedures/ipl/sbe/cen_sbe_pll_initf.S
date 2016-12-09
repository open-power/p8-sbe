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
#include "cen_sbe_initf_common_pnor.H"
        .list

//------------------------------------------------------------------------------
// preprocessor directives
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .pnor

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure cen_sbe_pll_initf, cen, "$Revision: 1.19 $"

        POREVE_INF( "Load tp_pll_bndy ring." )
	lpcs    P1, TP_CHIPLET_0x01000000

	POREVE_INF( "Scan0 PLL GPTR ring" )
        li      D0, CEN_SCAN_CLK_PLL	// 0x08100E00 bit 4,11,20,21,22    => 0x01030006
        li      D1, CEN_SCAN_PLL_GPTR	// 0x08100200 bit 4,11,22          => 0x01030007
        bsr     cen_scan0_module

	POREVE_INF( "Scan0 PLL BNDY and FUNC ring" )
        li      D0, CEN_SCAN_CLK_PLL		// 0x08100E00 bit 4,11,20,21,22    => 0x01030006
        li      D1, CEN_SCAN_PLL_BNDY_FUNC	// 0x08100808 bit 4,11,20,28       => 0x01030007
        bsr     cen_scan0_module

	lpcs    P0, TP_CHIPLET_0x01000000
	POREVE_INF( "Set OPCG RunN, Scan Ratio 16:1, Phase Align 4:1" )
	sti	TP_OPCG_CNTL0_0x01030002, P0, BIT(0)|BIT(5)|BIT(6)|BIT(7)|BIT(8)|BIT(12)|BIT(13)
						// 0x818C000000000000
	POREVE_INF( "Set OPCG Pad value 2x16 cycles" )
	sti	TP_OPCG_CNTL2_0x01030004, P0, BIT(50)
						// 0x0000000000002000
	POREVE_INF( "Set OPCG Set Pulse Controls" )
	sti	TP_OPCG_CNTL3_0x01030005, P0, BIT(1)
						// changed from 6 to 4
						// 0x6000000000000000
	POREVE_INF( "Select OPGC PLL Region (nsl only)" )
	sti	TP_CLK_REGION_0x01030006, P0, BIT(11)|BIT(21)
						// 0x0010040000000000

        POREVE_INF( "Load pervasive PLL GPTR, FUNC and BNDY rings for Nest and MEM PLL" )
	load_ring tp_pll_gptr skipoverride=1
	load_ring tp_pll_func
        load_ring tp_pll_bndy skipoverride=1 hasalternate=1

	lpcs    P0, TP_CHIPLET_0x01000000
	POREVE_INF( "Clear OPCG Set Pulse Setup" )
	sti	TP_OPCG_CNTL3_0x01030005, P0, 0x0000000000000000
	POREVE_INF( "Clear OPCG Clock Region Selects" )
	sti	TP_CLK_REGION_0x01030006, P0, 0x0000000000000000

        POREVE_INF( "*** End of procedure ***" )
        .end_procedure cen_sbe_pll_initf

