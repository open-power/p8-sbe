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
#include "common_ecids.H"
        .list

//------------------------------------------------------------------------------
// preprocessor directives
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .pnor

//------------------------------------------------------------------------------
// Constant Definitions
//------------------------------------------------------------------------------
        // Constants used for poll timeouts
        .set MAX_FLUSH_LOOPS, 100
        .set FLUSH_DELAY, 20000

        .set STEP_NEST_PLL_LOCKED,	0x1
        .set STEP_MEM_PLL_LOCKED,	0x2
        .set STEP_NEST_PLL_ALIGNED,	0x3

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure cen_sbe_pll_setup, cen, "$Revision: 1.12 $"

        POREVE_INF( "*** After loading the PLL ring, start the LOCK checking ***" )

///////////////////////////////////////////////////////
//           SBE Address Base Register Setups
///////////////////////////////////////////////////////
        // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

        // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P1, TP_CHIPLET_0x01000000

        POREVE_INF( "Reset PLL test enable" )
        bci     D0, MBOX_FSIGP4_0x00050013, P0, BIT(24)

        POREVE_INF( "PLL Leave Reset State" )
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(28)

        POREVE_INF( "Centuar only: Nest PLL Leave Reset State" )
        bci     D0, MBOX_FSIGP4_0x00050013, P0, BIT(16)

        POREVE_INF( "Drop Nest PLL bypass GP3MIR(5)=0  tp_pllbyp_dc" )
        bci     D0, MBOX_GP3MIR_0x0005001B, P0, BIT(5)

        POREVE_INF( "Poll FSI2PIB-Status(24) for (nest) pll lock bits." )
        pollbitset D1, MBOX_FSISTATUS_0x00050007, P0, 24, \
                   MAX_FLUSH_LOOPS, FLUSH_DELAY, cen_nest_lock_failed
        bra     cen_nest_lock_done

cen_nest_lock_failed:
	POREVE_ERR( "ERROR: Gave up waiting for PLL lock bit(24)='1'.");
        reqhalt RC_MSS_NEST_PLL_LOCK_TIMEOUT

cen_nest_lock_done:
        // Progress Indicator update
        updatestep STEP_NEST_PLL_LOCKED, D0, P1

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Chiplet Init bring-up MEM PLL
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        POREVE_INF( "bring-up the MEM PLL for ARRAYINIT closure" )

        POREVE_INF( "Change to side-band path." )
        lpcs    P0, STBY_CHIPLET_0x00000000

        POREVE_INF( "Drop bypass mode before LOCK (tp_pllmem_bypass_en_dc)." )
        bci     D0, MBOX_GP3MIR_0x0005001B, P0, BIT(17)

        POREVE_INF( "Poll FSI2PIB-Status(25) for (mem) pll lock bits." )
        pollbitset D1, MBOX_FSISTATUS_0x00050007, P0, 25, \
                   MAX_FLUSH_LOOPS, FLUSH_DELAY, cen_mem_lock_failed
        bra     cen_mem_lock_done

cen_mem_lock_failed:
	POREVE_ERR( "ERROR: Gave up waiting for PLL lock bit(25)='1'." )
        reqhalt RC_MSS_MEM_PLL_LOCK_TIMEOUT

cen_mem_lock_done:
        // Progress Indicator update
        updatestep STEP_MEM_PLL_LOCKED, D0, P1

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Nest PLL Re-alignment workaround
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// workaround for HW247901, apply only for DD1
        ldandi  D0, MBOX_CFAMID_0x0005000A, P0, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
        cmpibrane D0, cen_nest_align_done,      (CFAM_CHIP_ID_CENTAUR   | CFAM_CHIP_ID_MAJOR_EC_1)

        POREVE_INF( "Raise VITL_THOLD PERV_GP3(16)." )
	bsi	D0, MBOX_GP3MIR_0x0005001B, P0, BIT(16)

	POREVE_INF( "Drop PLL_DRV ENABLE FSIGP5(23)." )
	bci     D0, MBOX_FSIGP5_0x00050014, P0, BIT(23)

	POREVE_INF( "Raise PLL DRV ENABLE FSIGP5(23)." )
	bsi	D0, MBOX_FSIGP5_0x00050014, P0, BIT(23)

        POREVE_INF( "Drop VITL_THOLD PERV_GP3(16)." )
	bci	D0, MBOX_GP3MIR_0x0005001B, P0, BIT(16)

        POREVE_INF( "Poll FSI2PIB-Status(24) for (nest) pll lock bits." )
        pollbitset D1, MBOX_FSISTATUS_0x00050007, P0, 24, \
                   MAX_FLUSH_LOOPS, FLUSH_DELAY, cen_nest_align_failed
        bra     cen_nest_align_done

cen_nest_align_failed:
	POREVE_ERR( "ERROR: Gave up waiting for PLL lock bit(24)='1' after re-align");
        reqhalt RC_MSS_NEST_PLL_LOCK_TIMEOUT

cen_nest_align_done:
        // Progress Indicator update
        updatestep STEP_NEST_PLL_ALIGNED, D0, P1


        POREVE_INF( "*** End of procedure ***" )
        .end_procedure cen_sbe_pll_setup
