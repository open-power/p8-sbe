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
// Constant Definitions
//------------------------------------------------------------------------------

        // Reset values (flush) for FSI GP-regs
        .set MBOX_FSIGP3_INIT_VALUE, 0x00000FFB00000000
        .set MBOX_FSIGP4_INIT_VALUE, 0x0000C28000000000
        .set MBOX_FSIGP5_INIT_VALUE, 0x0000010000000000
        .set MBOX_FSIGP6_INIT_VALUE, 0x0000000000000000
        .set MBOX_FSIGP7_INIT_VALUE, 0x0000000000000000
        .set MBOX_GP3MIR_INIT_VALUE, 0x4416600000000000
        .set PIB_RESET_INIT_VALUE,   0xFFFFFFFFFFFFFFFF

        // Procedure Progress Step Definitions
        .set STEP_FSIGP_REINIT_COMPLETE,  0x1

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure cen_sbe_tp_chiplet_init1, cen, "$Revision: 1.33 $"
        POREVE_INF( "*** First Init Steps for Pervasive Chiplet ***" )

// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************
        // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

        POREVE_INF( "Fix PIBABORT during warmstart via MAILBOX " )
        sti     MBOX_FSISTATUS_0x00050007, P0, PIB_RESET_INIT_VALUE
        sti     MBOX_FSIRESET_0x00050006,  P0, PIB_RESET_INIT_VALUE

// ********************************************************
// **   Starting FSI Mailbox register initialization     **
// ********************************************************
        POREVE_INF( "Re-Initializing GP Registers" )
        sti     MBOX_FSIGP3_0x00050012, P0, MBOX_FSIGP3_INIT_VALUE
	// apply customized refclock termination value
	li	D0, MBOX_FSIGP4_INIT_VALUE
	andi	D0, D0, ~BITS(8,4)
	lia	A0, PORE_SPACE_PNOR, refclock_term
	ld	D1, 0x0, A0
	or	D0, D0, D1
        std     D0, MBOX_FSIGP4_0x00050013, P0
        sti     MBOX_FSIGP5_0x00050014, P0, MBOX_FSIGP5_INIT_VALUE
        sti     MBOX_FSIGP6_0x00050015, P0, MBOX_FSIGP6_INIT_VALUE
        sti     MBOX_FSIGP7_0x00050016, P0, MBOX_FSIGP7_INIT_VALUE
        sti     MBOX_GP3MIR_0x0005001B, P0, MBOX_GP3MIR_INIT_VALUE

        // Progress Indicator update
        updatestep STEP_FSIGP_REINIT_COMPLETE, D0, P0

        POREVE_INF( "Drop VDD2VIO fence" )
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(27)
        // No combining of commands allowed here !
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(23)

        POREVE_INF( "Check FSI2PIB-Status(16) to see if VDD is on." )
        ldandi  D0, MBOX_FSISTATUS_0x00050007, P0, BIT(16)
        branz   D0, VDD_power_ok

no_VDD_power:
        POREVE_ERR( "FSI Status register bit(16) indicates, VDD power is off" )
        reqhalt RC_MSS_INIT1_FSISTATUS_FAIL

VDD_power_ok:
        POREVE_INF( "Set output enable of PLLs" )
        bsi     D0, MBOX_FSIGP3_0x00050012, P0, BIT(29)

//        POREVE_INF( "Stop the vital clocks" )
//        bsi     D0, MBOX_GP3MIR_0x0005001B, P0, BIT(16)

        ldandi  D0, MBOX_CFAMID_0x0005000A, P0, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
        cmpibraeq D0, div24_switch_done,        (CFAM_CHIP_ID_CENTAUR   | CFAM_CHIP_ID_MAJOR_EC_1)

        POREVE_INF( "Centaur DD2 only: switch DIV24 into run mode" )
        bci     D0, MBOX_FSIGP4_0x00050013, P0, BIT(16)

div24_switch_done:
        POREVE_INF( "Pervasive Chiplet release endpoint reset" )
        bci     D0, MBOX_GP3MIR_0x0005001B, P0, BIT(1)

        POREVE_INF( "Set PLL test enable" )
        bsi     D0, MBOX_FSIGP4_0x00050013, P0, BIT(24)

        POREVE_INF( "Pervasive Chiplet assert endpoint reset" )
        bsi     D0, MBOX_GP3MIR_0x0005001B, P0, BIT(1)

        POREVE_INF( "Pervasive Chiplet start vital clocks" )
        bci     D0, MBOX_GP3MIR_0x0005001B, P0, BIT(16)

        POREVE_INF( "Pervasive Chiplet release endpoint reset" )
        bci     D0, MBOX_GP3MIR_0x0005001B, P0, BIT(1)

        POREVE_INF( "Release PCB Reset" )
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(22)

        POREVE_INF( "Set Chiplet Enable" )
        bsi     D0, MBOX_GP3MIR_0x0005001B, P0, BIT(0)

        POREVE_INF( "Drop FSI fence 4 FSIGP3(25)=0  fence_4_dc" )
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(25)

        POREVE_INF( "Drop TP Chiplet Fence Enable" )
        bci     D0, MBOX_GP3MIR_0x0005001B, P0, BIT(18)

        POREVE_INF( "Drop FSI fence 3 (PIB Master Interface)" )
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(24)            // 00000CA7 => 00000C27

        POREVE_INF( "*** End of procedure ***" )
        .end_procedure cen_sbe_tp_chiplet_init1
