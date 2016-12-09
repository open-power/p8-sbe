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
// Constant Definitions
//------------------------------------------------------------------------------
        .set    STRT_CLK_REGION_NSL_0x4FE0060000000000, 0x4FE0060000000000
        .set    STRT_CLK_REGION_SL_0x4FE00E0000000000,  0x4FE00E0000000000
        .set    EXPECTED_CLK_STATUS_0x0000001FFFFFFFFF, 0x0000001FFFFFFFFF

	// Procedure Progress Step Definitions
	.set    STEP_START_NEST_CLOCK,          0x1
		
//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .pnor

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure cen_sbe_nest_startclocks, cen, "$Revision: 1.4 $"
        POREVE_INF("Start clocks on Nest chiplet... ")

        // ********************************************************
	// **          SBE Address Base Register Setups          **
	// ********************************************************
        // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

        // Setup NEST_BASE_ADDR1; points to Nest Cplt
        lpcs    P1, NEST_CHIPLET_0x02000000


        // ------- Drop fences in all functional chiplets -------
        POREVE_INF("GP3 Reg: clear bit(18) to drop chiplet fences." )
        sti     NEST_GP3_AND_0x020F0013, P1, ~BIT(18)              // Clear bit 18       0xFFFFDFFFFFFFFFFF

        // ------- Enable EDRAM -------
        POREVE_INF("GP3 Reg: set bit(28) to enable EDRAM." )
        sti     NEST_GP3_OR_0x020F0014, P1, BIT(28)                // Set bit 28         0x0000000800000000

        // ------- Drop perv fences and reset abstclk_muxsel, synclk_muxsel (io_clk_sel) -------
        POREVE_INF("GP0 Reg: clear bit(63) to drop perv fences." )
        POREVE_INF("GP0 Reg: clear bits(0:1) to reset abstclk_muxsel, synclk_muxsel." )
        sti     NEST_GP0_AND_0x02000004, P1, ~(BITS(0,2)|BIT(63))  // Clear bits 0,1,63  0x3FFFFFFFFFFFFFFE

        // ------- Write ClockControl Scan Region Register, set all bits to zero prior clock start -------
        POREVE_INF("Clear Scan Region Reg prior to clock start." )
        sti	NEST_CLK_SCANSEL_0x02030007, P1, 0x0000000000000000
        std     D0, NEST_CLK_SCANSEL_0x02030007, P1

        updatestep STEP_START_NEST_CLOCK, D0, P1

        // Reload NEST_BASE_ADDR1; points to Nest Cplt
        lpcs    P1, NEST_CHIPLET_0x02000000

        // Clock settings unique for Centaur chip
        POREVE_INF("Clock start cmd for array and nsl tholds." )
        sti     NEST_CLK_REGION_0x02030006, P1, STRT_CLK_REGION_NSL_0x4FE0060000000000

        POREVE_INF("Clock start cmd for sl tholds." )
        sti     NEST_CLK_REGION_0x02030006, P1, STRT_CLK_REGION_SL_0x4FE00E0000000000

        POREVE_INF("Check status of THOLDs, 0x0000001FFFFFFFFF expected." )
        ld      D0, NEST_CLK_STATUS_0x02030008, P1
        xori    D0, D0, EXPECTED_CLK_STATUS_0x0000001FFFFFFFFF
        branz   D0, error_on_nest_clk_stat   // branch to error

        POREVE_INF("MBOX GP4 Reg: Set bit(2) to set MemReset Stability Control." )
        bsi     D0, MBOX_FSIGP4_0x00050013, P0, BIT(2)                                   // 0x20A04000

        POREVE_INF("MBOX GP4 Reg: Set bit(4) to release D3PHY PLL Reset Control." )
        bsi     D0, MBOX_FSIGP4_0x00050013, P0, BIT(4)                                   // 0x28A04000


        // -------- Clear EDRAM fence ----------------
        POREVE_INF("GP0 Reg: clear bit(19) to clear edram_fence." )	
        sti     NEST_GP0_AND_0x02000004, P1, ~BIT(19)
	
        // ------- Clear force_align in all functional chiplets -------
        POREVE_INF("GP0 Reg: clear bit(3) to clear force_align." )
        sti     NEST_GP0_AND_0x02000004, P1, ~BIT(3)              // clear bit 3         // 0xEFFFFFFFFFFFFFFF

        // ------- Clear flushmode_inhibit in all functional chiplets -------
        POREVE_INF("GP0 Reg: clear bit(2) to clear flushmode_inhibit." )
        sti     NEST_GP0_AND_0x02000004, P1, ~BIT(2)              // clear bit 2         // 0xDFFFFFFFFFFFFFFF

        // ------- Enable Drivers and Receivers -------
        POREVE_INF("MBOX GP4 Reg: Set bits(22-23,28-30) to enable drivers and receivers." )
        bsi     D0, MBOX_FSIGP4_0x00050013, P0, BITS(22,2)|BITS(28,3)                    // 0x28A0430E

        bra     end_of_routine

error_on_nest_clk_stat:
        POREVE_ERR("Nest clocks tholds aren't low after clock start")
        reqhalt RC_MSS_UNEXPECTED_NEST_CLK_STATUS

end_of_routine:
        POREVE_INF( "*** End of procedure ***" )
        .end_procedure cen_sbe_nest_startclocks
