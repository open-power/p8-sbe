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
// Constant Definitions
//------------------------------------------------------------------------------
       // TOD Error Routing register init
	.set	TOD_ERROR_ROUTING_VAL, 0x9FC02000F0004000

       // TOD Error Mask init
	.set	TOD_ERROR_MASK_VAL, 0x0000000003F00000

       // TP XFIR inits
	.set	TP_XFIR_MASK_VAL, 0x2000F7E000000000
	.set	TP_XFIR_MASK_CACHE_CONTAINED_VAL, 0xFFFFFFE000000000

       // TP SPATTN inits
	.set	TP_SPATTN_MASK_CACHE_CONTAINED_VAL, 0xFF80000000000000

       // TP LFIR inits
	.set	TP_LFIR_ACTION0_VAL, 0x0000000000000000
	.set	TP_LFIR_ACTION1_VAL, 0x8002F09010000000
	.set	TP_LFIR_MASK_VAL, 0x7FFF0F6FE7800000

       // LPC FIR inits
	.set	LPC_FIR_ACTION0_VAL, 0x0000000000000000
	.set	LPC_FIR_ACTION1_VAL, 0x0000000000000000
	.set	LPC_FIR_MASK_VAL, 0xFFF0000000000000

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_tp_chiplet_init3, ipl, "$Revision: 1.35 $"
        POREVE_INF("<proc_sbe_tp_chiplet_init3> : *** Remaining Pervasive Chiplet Setup and Start Clocks for remaining Pervasive ***\n")


tci3_setup:

// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************

     // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P1, STBY_CHIPLET_0x00000000

     // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P0, TP_CHIPLET_0x01000000


tci3_start:
     // Switch PRV Cplt OOB mux
        POREVE_INF("Switching the Pervasive Chiplet OOB Mux ...\n")
        bci     D0, MBOX_FSIGP3_0x00050012, P1, BIT(21)

     // Reset PCB Master Interrupt Register
        POREVE_INF("Reset the PCB Master Interrupt Register ...\n")
        sti     MASTER_PCB_INT_0x000F001A, P1, 0x0000000000000000

     // Drop Pervasive Fence and OCC2PIB Fence in GPX (Bits 19 & 63)
        POREVE_INF("Drop Pervasive Fence ...\n")
        bci     D0, GENERIC_GP0_0x00000000, P0, (BIT(19) | BIT(63))

     // reset syncclk_muxsel_dc for LPC in GPX (bit 1)
	POREVE_INF("Drop synclk_muxsel ...\n")
	bci	D0, GENERIC_GP0_0x00000000, P0, BIT(1)

     // "Clock Start" Command (all other pervasive clocks)
        POREVE_INF("Starting remaining Pervasive Clocks ...\n")
        sti     GENERIC_CLK_REGION_0x00030006, P0, 0x4fe00e0000000000

     // Drop FSI Fence 5 (checkstop, Interrupt conditions)
        POREVE_INF("Drop FSI Fence 5 ...\n")
        bci     D0, MBOX_FSIGP3_0x00050012, P1, BIT(26)

     // Configure TP chiplet FIRs
	POREVE_DBG("Configuring LPC FIR ...\n")
	sti	LPC_FIR_ACTION0_0x01010C06, P0, LPC_FIR_ACTION0_VAL
	sti	LPC_FIR_ACTION1_0x01010C07, P0, LPC_FIR_ACTION1_VAL
	sti	LPC_FIR_MASK_0x01010C03, P0, LPC_FIR_MASK_VAL

     // set TOD Error Routing register
	POREVE_DBG("Configuring TOD Error Routing Register ...\n")
	sti	TOD_ERROR_ROUTING_REG_00040033, P1, TOD_ERROR_ROUTING_VAL

     // set TOD Error Mask register only for Murano DD2+ / Venice
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P1, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
        cmpibraeq   D0, clear_tod_error_reg,        (CFAM_CHIP_ID_MURANO    | CFAM_CHIP_ID_MAJOR_EC_1 )

	POREVE_DBG("Configuring TOD Error Mask Register ...\n")
	sti	TOD_ERROR_MASK_STATUS_REG_00040032, P1, TOD_ERROR_MASK_VAL

clear_tod_error_reg:
     // clear TOD Error register
	POREVE_DBG("Clearing TOD Error Register ...\n")
        sti     TOD_ERROR_REG_00040030, P1, BITS(0,63)

	POREVE_DBG("Configuring TP LFIR ...\n")
	sti	GENERIC_PERV_LFIR_0x0004000A, P0, 0x0000000000000000
	sti	GENERIC_PERV_LFIR_ACT0_0x00040010, P0, TP_LFIR_ACTION0_VAL
	sti	GENERIC_PERV_LFIR_ACT1_0x00040011, P0, TP_LFIR_ACTION1_VAL
	sti	GENERIC_PERV_LFIR_MASK_0x0004000D, P0, TP_LFIR_MASK_VAL

        POREVE_DBG("Configuring TP XFIR ...\n");
        // check cache contained mode
        lia     A0, PORE_SPACE_SEEPROM, proc_sbe_tp_chiplet_init3_control
	ldandi	D1, 0, A0, PROC_CONTROL_CACHE_CONTAINED
        branz   D1, tp_xfir_cache_contained

tp_xfir_non_cache_contained:
	sti	GENERIC_FIR_MASK_0x00040002, P0, TP_XFIR_MASK_VAL        
        bra     tp_xfir_done

tp_xfir_cache_contained:
        sti     GENERIC_FIR_MASK_0x00040002, P0, TP_XFIR_MASK_CACHE_CONTAINED_VAL
        sti     GENERIC_SPATTN_MASK_0x00040007, P0, TP_SPATTN_MASK_CACHE_CONTAINED_VAL

tp_xfir_done:
        // Get the ECID to apply trace setup to only Murano DD2+ / Venice
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P1, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
        cmpibraeq   D0, 1f,                         (CFAM_CHIP_ID_MURANO    | CFAM_CHIP_ID_MAJOR_EC_1 )

	POREVE_DBG("Configuring TP chiplet trace arrays to stop on checkstop")
	sti	GENERIC_DBG_MODE_REG_0x000107C0, P0, BIT(7)
	sti	GENERIC_DBG_TRACE_REG2_0x000107CB, P0, BIT(17)

1:
        POREVE_INF("*** End of Procedure ***\n")
        .end_procedure proc_sbe_tp_chiplet_init3
