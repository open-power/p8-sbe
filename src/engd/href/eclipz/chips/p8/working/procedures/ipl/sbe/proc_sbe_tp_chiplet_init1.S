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
#include "common_ecids.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Constant Definitions
//------------------------------------------------------------------------------

        .set MBOX_FSIGP3_INIT_VALUE, 0x0080003F00000000              //LAST UPDATED ON: 2012-11-20
        .set MBOX_FSIGP4_INIT_VALUE, 0x00000a8000000000              //LAST UPDATED ON: 2013-02-20         //AK-WAFER : Keep the secure override bit untouched, was: 0x00004c8000000000
        .set MBOX_FSIGP5_INIT_VALUE, 0x0000c10000000000              //LAST UPDATED ON: 2012-11-20
        .set MBOX_FSIGP6_INIT_VALUE, 0x0000000000000000              //LAST UPDATED ON: 2012-11-20
	.set MBOX_FSIGP7_INIT_VALUE_MUR_DD1X, 0x3000000000000000     //LAST UPDATED ON: 2013-09-26
	.set MBOX_FSIGP7_INIT_VALUE_MUR_NOT_DD1X, 0xC000000000000000 //LAST UPDATED ON: 2013-09-26
	.set MBOX_FSIGP7_INIT_VALUE_VEN, 0x9000000000000000          //LAST UPDATED ON: 2013-09-26
        .set MBOX_FSIGP8_INIT_VALUE, 0x1060003000000000              //LAST UPDATED ON: 2013-02-09
        .set MBOX_GP3MIR_INIT_VALUE, 0x1c16204000000000              //LAST UPDATED ON: 2012-11-20
        .set TP_GP0_FLUSH_VALUE, 0x7001900000000003

     // Procedure Progress Step Definition
        .set STEP_FSIGP_REINIT_COMPLETE,  0x1

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_tp_chiplet_init1, ipl, "$Revision: 1.45 $"
        POREVE_INF("<proc_sbe_tp_chiplet_init1> : *** First Init Steps for Pervasive Chiplet ***\n")


tci1_setup:

// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************

     // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

     // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P1, TP_CHIPLET_0x01000000


tci1_gp_register_setup:

// ********************************************************
// **   Starting FSI Mailbox register initialization     **
// ********************************************************

     // PRV Cplt: initialize Mailbox GP registers
        POREVE_INF("<proc_sbe_tp_chiplet_init1> : Re-Initializing GP Registers ...\n")

	// Only Set FSI GP3 bits if in FSP Less systems
	// in other systems this is handled through FAPI procedures
	// value of 1 for FSP less systems
	// value of 0 for FSP bases systems
	ld      D0, MBOX_SCRATCH_REG1_0x00050039, P0
	andi    D0, D0, BIT(1)
	braz    D0, tci1_init_gp4
        sti     MBOX_FSIGP3_0x00050012, P0, MBOX_FSIGP3_INIT_VALUE

tci1_init_gp4:
     // FSI GP4: preserve state of nest mesh select bit (set in proc_select_clock_mux), the security override bit,             //AK-WAFER
     //          and refclock receiver termination
	ldandi	D0, MBOX_FSIGP4_0x00050013, P0, (BITS(8,4) | BIT (16) | BIT(18) | BIT(23))                                     //AK-WAFER
	ori	D0, D0, MBOX_FSIGP4_INIT_VALUE
	std	D0, MBOX_FSIGP4_0x00050013, P0
        sti     MBOX_FSIGP5_0x00050014, P0, MBOX_FSIGP5_INIT_VALUE


	// Only Set FSI GP6 bits if in FSP Less systems
	// in other systems this is handled through FAPI procedures
	// value of 1 for FSP less systems
	// value of 0 for FSP bases systems
	ld      D0, MBOX_SCRATCH_REG1_0x00050039, P0
	andi    D0, D0, BIT(1)
	braz    D0, tci1_init_gp7
        sti     MBOX_FSIGP6_0x00050015, P0, MBOX_FSIGP6_INIT_VALUE

tci1_init_gp7:
	// Only Set FSI GP7 bits if in FSP Less systems
	// in other systems this is handled through FAPI procedures
	// value of 1 for FSP less systems
	// value of 0 for FSP bases systems
	ld      D0, MBOX_SCRATCH_REG1_0x00050039, P0
	andi    D0, D0, BIT(1)
	braz    D0, tci1_init_gp8

     // FSI GP7: select init value based on chip type/EC
	ld	D1, PCBMS_DEVICE_ID_0x000F000F, P0
	andi	D0, D1, CFAM_CHIP_ID_CHIP_MASK
	cmpibraeq D0, tci1_init_gp7_murano, CFAM_CHIP_ID_MURANO
tci1_init_gp7_venice:
        sti     MBOX_FSIGP7_0x00050016, P0, MBOX_FSIGP7_INIT_VALUE_VEN
	bra	tci1_init_gp8
tci1_init_gp7_murano:
        andi    D0, D1, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
	cmpibraeq D0, tci1_init_gp7_murano_dd1x, (CFAM_CHIP_ID_MURANO | CFAM_CHIP_ID_MAJOR_EC_1)
tci1_init_gp7_murano_not_dd1x:
	sti	MBOX_FSIGP7_0x00050016, P0, MBOX_FSIGP7_INIT_VALUE_MUR_NOT_DD1X
	bra	tci1_init_gp8
tci1_init_gp7_murano_dd1x:
        sti     MBOX_FSIGP7_0x00050016, P0, MBOX_FSIGP7_INIT_VALUE_MUR_DD1X

tci1_init_gp8:
     // FSI GP8: preserve state of centaur refclock enable bits (set in proc_select_clock_mux)
        ldandi  D0, MBOX_FSIGP8_0x00050017, P0, BITS(16,8)
        ori     D0, D0, MBOX_FSIGP8_INIT_VALUE
        std     D0, MBOX_FSIGP8_0x00050017, P0
        sti     MBOX_GP3MIR_0x0005001B, P0, MBOX_GP3MIR_INIT_VALUE

     // Progress Indicator update
        updatestep_inline STEP_FSIGP_REINIT_COMPLETE, D0, P0

tci1_start:

     // PRV Cplt: Drop VDD2VIO fence
        POREVE_INF("<proc_sbe_tp_chiplet_init1> : Drop VDD2VIO fence ...\n")
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(27)

     // PRV Cplt: Release reset of OSC Switch (Power Good Bar)
        POREVE_INF("<proc_sbe_tp_chiplet_init1> : Release reset of OSC Switch (Power Good Bar) ...\n")
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(30)

     // PRV Cplt: Enable auto-reset on PCB timeout errors
        POREVE_INF("<proc_sbe_tp_chiplet_init1> : Set TIMEOUT_RESET_EN ...\n")
        bsi     D0, PCBMS_RESET_REG_0x000F001D, P0, BIT(2)

     // PRV Cplt: release PCB reset
        POREVE_INF("<proc_sbe_tp_chiplet_init1> : Release PCB Reset ...\n")
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(22)

     // PRV Cplt: set chiplet enable
        POREVE_INF("<proc_sbe_tp_chiplet_init1> : Set Chiplet Enable ...\n")
        bsi     D0, MBOX_GP3MIR_0x0005001B, P0, BIT(0)

     // PRV Cplt: drop fence enable
        POREVE_INF("<proc_sbe_tp_chiplet_init1> : Drop TP Chiplet Fence Enable ...\n")
        bci     D0, MBOX_GP3MIR_0x0005001B, P0, BIT(18)

     // Drop Global Endpoint reset
        POREVE_INF("<proc_sbe_tp_chiplet_init1> : Drop Global Endpoint reset ...\n")
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(31)

     // Switch PIB trace to SBE trace bus
        POREVE_INF("<proc_sbe_tp_chiplet_init1> : Switching PIB trace bus to SBE tracing ...\n")
     // Work around SW310405 by forcing GP0 to flush value in case it was clobbered
     // sti     GENERIC_GP0_OR_0x00000005, P1, BIT(31)
        sti     TP_GP0_0x01000000, P1, TP_GP0_FLUSH_VALUE | BIT(31) 

     // Setup scan ration to 8:1 for PRV chiplet                                                        //AK-WAFER
        POREVE_INF("<proc_sbe_tp_chiplet_init1> : PRV Chiplet: Setup scan ration to 8:1 ...\n")         //AK-WAFER
        //Inputs: A1 and P0, destroys D0 & D1
        lpcs    P0, TP_CHIPLET_0x01000000
        lia     A1, PORE_SPACE_SEEPROM, proc_sbe_tp_chiplet_init1_control
        bsr     set_scan_ratio

        POREVE_INF("<sbe_proc_tp_chiplet_init1> : *** End of procedure ***\n")
        .end_procedure proc_sbe_tp_chiplet_init1
