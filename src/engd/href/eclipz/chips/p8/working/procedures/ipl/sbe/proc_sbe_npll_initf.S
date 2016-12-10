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
#include "proc_sbe_initf_common_seeprom.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_npll_initf, ipl, "$Revision: 1.25 $"

        lpcs    P1, TP_CHIPLET_0x01000000

	POREVE_INF("Scan0 PLL GPTR ring")
        li      D0, SCAN_CLK_PLL
        li      D1, SCAN_PLL_GPTR
        bsr     seeprom_scan0_module

	POREVE_INF("Scan0 PLL BNDY and FUNC ring")
        li      D0, SCAN_CLK_PLL
        li      D1, SCAN_PLL_BNDY_FUNC
        bsr     seeprom_scan0_module

	lpcs    P0, TP_CHIPLET_0x01000000

	POREVE_INF("Set OPCG RunN, Phase Align")
        //Leave Scan ratio alone
        ldandi  D0, TP_OPCG_CNTL0_0x01030002, P0, BITS(4,5)
        ori     D0, D0, 0x800C000000000000                                            //AK-WAFER
        std     D0, TP_OPCG_CNTL0_0x01030002, P0
	POREVE_INF("Set OPCG Pad value")
	sti	TP_OPCG_CNTL2_0x01030004, P0, 0x0000000000002000
	POREVE_INF("Set OPCG Set Pulse Controls")
	sti	TP_OPCG_CNTL3_0x01030005, P0, 0x6000000000000000
	POREVE_INF("Select OPGC PLL Region")
	sti	TP_CLK_REGION_0x01030006, P0, 0x0010040000000000

        POREVE_INF("Loading pervasive PLL ring for NEST, XBus and filter PLLs")
	load_ring perv_gptr_pll skipoverride=1
	load_ring perv_func_pll
        load_ring perv_bndy_pll skipoverride=1 hasalternate=1

	lpcs    P0, TP_CHIPLET_0x01000000
	POREVE_INF("Clear OPCG Set Pulse Setup")
	sti	TP_OPCG_CNTL3_0x01030005, P0, 0x0000000000000000
	POREVE_INF("Clear OPCG Clock Region Selects")
	sti	TP_CLK_REGION_0x01030006, P0, 0x0000000000000000

        POREVE_INF("*** End of procedure ***\n")
        .end_procedure proc_sbe_npll_initf

