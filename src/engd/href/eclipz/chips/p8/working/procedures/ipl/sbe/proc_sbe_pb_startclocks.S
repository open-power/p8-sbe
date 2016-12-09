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
        .set    STEP_PB_START_CLOCKS_NSL, 0x1
        .set    STEP_PB_CLOCKS_RUNNING,   0x2
        .set    STEP_PB_CLOCKS_SUCCESS,   0x3

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_pb_startclocks, ipl, "$Revision: 1.12 $"

        POREVE_INF( "P8 Start PB-Clocks starting..." )

        // Setup PRV_BASE_ADDR0; points to NEST Cplt
        lpcs    P0, NEST_CHIPLET_0x02000000

        POREVE_DBG( "Read ChipletEnable GP3(0)=0b1" )
        ld      D0, NEST_GP3_0x020F0012, P0
        ifbitset D0, D0, 0, chplt_enabled

        POREVE_INF("PB chiplet is disabled; GP3(0)='0'"  );
        bra pb_end_proc

chplt_enabled:
        POREVE_DBG( "Drop fence GP3(18)=0b0" )
        // 0x020F0013 WAND codepoint 0xFFFFDFFFFFFFFFFF    bit(18) = 0b0
        sti     NEST_GP3_AND_0x020F0013, P0, ~BIT(18)

        POREVE_DBG( "Drop perv fence GP0 GP3(63)=0b0" )
        // 0x02000004 WAND codepoint 0xFFFFFFFFFFFFFFFE    bit(63) = 0b0
        sti     NEST_GP0_AND_0x02000004, P0, ~BIT(63)

        POREVE_DBG( "Reset abstclk_muxsel, synclk_muxsel, GP0(0,1)=0b00" )
        // 0x02000004 WAND codepoint    0x3FFFFFFFFFFFFFFF    bit(0:1) = 0b00
        sti     NEST_GP0_AND_0x02000004, P0, ~BITS(0,2)

        POREVE_DBG( "Write Clock Control, Scan Region, reset prior clock start" )
        // Write ClockControl, Scan Region Register, set all bits to zero prior clock start
        // 0x02030007    0x0000000000000000
        sti     NEST_CLK_SCANSEL_0x02030007, P0, 0x0000000000000000

        updatestep  STEP_PB_START_CLOCKS_NSL, D0, P0

        // PgP only clock start settings
	// Read partial good information out of SEEPROM table
        POREVE_INF("Get partial good vector for PB-chiplet out of SEEPROM table" )
        lia     A0, PORE_SPACE_SEEPROM, combined_good_vectors
        adds    A0, A0, 0x10
        ld      D0, 0x0, A0
        andi    D0, D0, BITS(4,16)                               	
        POREVE_INF("Got the combined good vector for PB chiplet: 0x%16llX",
			io_pore.d0.read() )
        rotrdi  D1, D0, 14			// align PG value for A1 0x00003D0000000000
        mr	A1, D1				// save  PG work value in A1
        ori     D1, D0, 0x4000060000000000	// set CC regions for start

        // Reload P0 to point to NEST Cplt
        lpcs    P0, NEST_CHIPLET_0x02000000

        // Write Region Register (all clock regions)
        POREVE_DBG( "Write Clock Control, set Clock Regions in NEST chiplet" )
	std     D1, NEST_CLK_REGION_0x02030006, P0	// 0x4F40060000000000 				

        POREVE_DBG( "Write Clock Control, add SEL_THOLD_SL Bit(20)" )
        ori	D1, D1, BIT(20)			
	std     D1, NEST_CLK_REGION_0x02030006, P0	// 0x4F400E0000000000 				

	// Create expected_status out of PGood values
	ls	CTR, 9			// loop counter for 9 clock regions
        li	d1, 0x0000000000000000	// expected status value
        				//	skip    0=running; 1=stopped
        bra	exp_begin		

exp_start:
	mr	D0, a1			// retrieve A1
        andi    d0, d0, BIT(18)
	branz	d0, exp_skip
        ori	d1, d1, BITS(61, 3)	// apply expected scan types for chiplt

exp_skip:
	mr	D0, a1			// retrieve A1
	rols	d0, d0, 1
	mr	a1, D0			// save A1
        braz	CTR, exp_end		// end loop

	rols	d1, d1, 1		// shift expected status left by 3 bit
	rols	d1, d1, 1
	rols	d1, d1, 1

exp_begin:
        loop exp_start
exp_end:
	// shift D1 and add trailing constant 27:63; 37 bit = '1'
	rols	d1, d1, 32		
	rols	d1, d1, 4
	rols	d1, d1, 1
        ori	d1, d1, BITS(27, 37)	

        // Reload P0 to point to NEST Cplt
        lpcs    P0, NEST_CHIPLET_0x02000000

        POREVE_INF( "Checking THOLDS in clock status. Expecting: 0x%016llX",
                    io_pore.d1.read() )

        // Read Clock Status Register (NEST chiplet) expected value in D1
        ld      D0, NEST_CLK_STATUS_0x02030008, P0
        xor	D1, D0, D1
        braz	D1, continue

        POREVE_ERR( "ERROR: PB Clock Status Register (0x02030008) got "
                    "unexpected value: 0x%016llX", io_pore.d0.read() )
        reqhalt PROC_SBE_PB_START_CLOCK_ERROR


continue:
        POREVE_INF( "PB clocks should be running now" )
        updatestep  STEP_PB_CLOCKS_RUNNING, D0, P0

        // Reload P0 to point to NEST Cplt
        lpcs    P0, NEST_CHIPLET_0x02000000


        POREVE_DBG( "Clear GP0 force_align and flushmode_inhibit" )
        // Clear force_align in all Chiplets GP0 0xEFFFFFFFFFFFFFFF    bit(3) = 0b0
        sti     NEST_GP0_AND_0x02000004, P0, ~BIT(3)

        // Clear flushmode_inhibit in all Chiplets GP0 0xDFFFFFFFFFFFFFFF    bit(2) = 0b0
        sti     NEST_GP0_AND_0x02000004, P0, ~BIT(2)

        POREVE_DBG("Write GP0, clear force_align" )
        //  Write GP0, clear force_align address 01000000     bit(03)=0b0
        lpcs    P0, TP_GP0_0x01000000
        bci     D0, TP_GP0_0x01000000, P0, BIT(3)

        POREVE_DBG("Write GP0, clear flushmode_inhibit" )
        //  Write GP0, clear flushmode_inhibit address 01000000     bit(02)=0b0
        bci     D0, TP_GP0_0x01000000, P0, BIT(2)


        updatestep  STEP_PB_CLOCKS_SUCCESS, D0, P0
        POREVE_INF("Exiting procedure successfully"  );

pb_end_proc:
        .end_procedure proc_sbe_pb_startclocks

