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
#include "p8_slw.H"
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

        // procedure progress codes
        .set    STEP_SCOMINIT_WRITE_CHIPLET_IDS, 0x0
        .set    STEP_SCOMINIT_WRITE_XSCOM_BAR, 0x1
        .set    STEP_SCOMINIT_WRITE_TBROM_BAR, 0x2
        .set    STEP_SCOMINIT_WRITE_ADU_PSI_PBA_BARS, 0x3
        .set    STEP_SCOMINIT_WRITE_FIR_REGS, 0x4
        .set    STEP_SCOMINIT_WRITE_HP_REGS, 0x5


        // ADU XSCOM/TBROM BAR values
        // ADU/PSI Unstrusted BAR/BAR mask values come from global config data
        .set    ADU_XSCOM_BAR, 0x0003FC0000000000
        .set    ADU_TBROM_BAR, 0x0003FFFFC0000000

	// Data pattern to clear FIRs
        .set	CLEAR_ALL_FIRS_VAL, 0x0000000000000000

	// PB PERV LFIR
	.set	PB_PERV_LFIR_ACTION0_VAL, 0x0000000000000000
	.set	PB_PERV_LFIR_ACTION1_VAL, 0x8000000000000000
	.set	PB_PERV_LFIR_MASK_VAL,    0x7FFFFFFFFF800000

        // PB CENTRAL
        .set	PB_CENTRAL_FIR_ACTION0_VAL, 0x0000000000000000
        .set	PB_CENTRAL_FIR_ACTION1_VAL, 0x0040000000000000
        .set	PB_CENTRAL_FIR_MASK_VAL,    0x110FC00000000000

        // PB WEST
        .set	PB_WEST_FIR_ACTION0_VAL, 0x0000000000000000
        .set	PB_WEST_FIR_ACTION1_VAL, 0x0000000000000000
        .set	PB_WEST_FIR_MASK_VAL,    0xFFFFFFFFC0000000

        // PB EAST
        .set	PB_EAST_FIR_ACTION0_VAL, 0x0000000000000000
        .set	PB_EAST_FIR_ACTION1_VAL, 0x0000000000000000
        .set	PB_EAST_FIR_MASK_VAL,    0xFFFFFFFFC0000000

        // PBA FIR
        .set	PBA_FIR_ACTION0_VAL, 0x0000000000000000
        .set	PBA_FIR_ACTION1_VAL, 0xFF7D000E00000000
        .set	PBA_FIR_MASK_VAL,    0x0082FFF1FFFC0000

        // PB XFIR
	.set	PB_XFIR_MASK_VAL, 0x002007E000000000
	.set	PB_XFIR_MASK_CACHE_CONTAINED_VAL, 0xFFFFFFE000000000

        // PB SPATTN inits
	.set	PB_SPATTN_MASK_CACHE_CONTAINED_VAL, 0x8000000000000000

    .set MPIPL_BITNUM, 0

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_scominit, ipl, "$Revision: 1.42 $"

        // If MPIPL, go set the untrusted bars
        lpcs    P0, MBOX_SCRATCH_REG1_0x00050039
        ifbitsetscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, write_untrusted_bars

set_fabric_ids:
        // node ID is bits 40:42 of GP0
        // chip ID is bits 43:45 of GP0
	// differentiate based on chip type
        lpcs    P0, STBY_CHIPLET_0x00000000
        ld      D1, PCBMS_DEVICE_ID_0x000F000F, P0
        andi    D0, D1, CFAM_CHIP_ID_CHIP_MASK
	cmpibraeq D0, venice_fabric_ids, CFAM_CHIP_ID_VENICE
	cmpibraeq D0, naples_fabric_ids, CFAM_CHIP_ID_NAPLES

murano_fabric_ids:
	ldandi	D0, MBOX_SCRATCH_REG1_0x00050039, P0, BIT(1)
	braz	D0, murano_fabric_ids_sp

murano_fabric_ids_spless:
	// static: 1 c/n, 4n
	// node ID: set as Device ID bits 37,39
	// chip ID: set to zero
	// unsecure BARs: do not use drawer offset
	    POREVE_DBG("Read Murano fabric node ID (=%llX), SP-less...\n", \
                       io_pore.d1.extractToRight(37,1)*2 + io_pore.d1.extractToRight(39,1))
	mr	D0, D1
	andi	D0, D0, BIT(37)
	andi	D1, D1, BIT(39)
	srdi	D0, D0, 1
	or	D1, D0, D1
	srdi	D1, D1, 3
	li	A1, 0
	POREVE_DBG("Assigning Murano fabric chip ID (=0), SP-less ...\n")
	bra	write_fabric_ids

murano_fabric_ids_sp:
	// max: 2 c/n, 4n
	// node ID: set from Device ID bits 37:38
	// chip ID: set from Device ID bit 39
	// unsecure BARs: do not use drawer offset
        POREVE_DBG("Read Murano fabric node ID (=%llX), chip ID (=%llX), SP ...\n", \
                   io_pore.d1.extractToRight(37, 2), \
                   io_pore.d1.extractToRight(39, 1))

        // compute chiplet GP0 OR mask
        // D0 will contain node ID (GP0 bits 41:42)
        andi    D0, D1, BITS(37,2)
        srdi    D0, D0, 4
        // D1 will contain chip ID (GP0 bit 45)
        andi    D1, D1, BITS(39,1)
        srdi    D1, D1, 6
        // merge final mask into D1
        or      D1, D0, D1
	li	A1, 0
        bra     write_fabric_ids

naples_fabric_ids:
	// isolate Device ID field
	andi	D1, D1, BITS(37,2)
	// node ID: 0
	// chip ID: set from Device ID bits 37:38
	// unsecure BARs: do not use drawer offset
	POREVE_DBG("Read Naples fabric chip ID (=%llX) ...\n", \
                   io_pore.d1.extractToRight(37, 2))
	srdi	D1, D1, 7
	// D1 now contains final mask
	li	A1, 0
	bra	write_fabric_ids

venice_fabric_ids:
	// isolate Device ID field
	andi	D1, D1, BITS(37,2)
        ldandi	D0, MBOX_SCRATCH_REG1_0x00050039, P0, BIT(1)
        braz	D0, venice_fabric_ids_sp

venice_fabric_ids_spless:
        // static: 1 c/n, 4n
	// node ID: set from Device ID bits 37:38
        // chip ID: set to zero
	// unsecure BARs: do not use drawer offset
        POREVE_DBG("Read Venice fabric node ID (=%llX), SP-less ...\n", \
                   io_pore.d1.extractToRight(37, 2))
	srdi	D1, D1, 4
	POREVE_DBG("Assigning Venice fabric chip ID (=0), SP-less ...\n")
	// D1 now contains final mask
	li	A1, 0
        bra     write_fabric_ids

venice_fabric_ids_sp:
	// max: 4 c/n, 4n
	// node ID: set from mailbox bits 29:31
	// chip ID: set from Device ID bits 37:38
	// unsecure BARs: use drawer offset
        POREVE_DBG("Read Venice fabric chip ID (=%llX), SP ...\n", \
                   io_pore.d1.extractToRight(37, 2))
        srdi    D1, D1, 7
        ldandi  D0, MBOX_SCRATCH_REG3_0x0005003B, P0, BITS(29, 3)
        POREVE_DBG("Read Venice fabric node ID (=%llX), SP ...\n", \
                   io_pore.d0.extractToRight(29, 3))
        srdi    D0, D0, 11
        // merge final mask into D1
        or      D1, D0, D1
	li	A1, 1
	// determine if chip ID adjustment is needed, based on wrap
        // test mode (mailbox bit 28)
	ldandi	D0, MBOX_SCRATCH_REG3_0x0005003B, P0, BIT(28)
	POREVE_DBG("Read Venice wrap test bit (=%lld), SP ...\n", \
                   io_pore.d0.extractToRight(28, 1));
	braz	D0, write_fabric_ids
	// wrap test enabled, adjust chip IDs
        // also, since single hostboot image will be used, don't
        // set unsecure BARs with node/drawer offset
        li      A1, 0
	mr	D0, D1
	andi	D0, D0, BIT(44)
	braz	D0, write_fabric_ids
	POREVE_DBG("Adjust Venice fabric chip id for wrap mode, SP ...\n");
	xori	D1, D1, BITS(44,2)

write_fabric_ids:
        // write ID values to all chiplets (GP0 OR mask, multicast group 0)
        updatestep STEP_SCOMINIT_WRITE_CHIPLET_IDS, D0, P0
        lpcs    P0, WRITE_ALL_GP0_OR_0x68000005
        std     D1, WRITE_ALL_GP0_OR_0x68000005, P0

write_xscom_bar:
        // write ADU XSCOM BAR to set desired value
        updatestep STEP_SCOMINIT_WRITE_XSCOM_BAR, D0, P0
        lpcs    P1, NEST_CHIPLET_0x02000000
        POREVE_DBG("Setting ADU XSCOM BAR ...\n");
        sti     ADU_XSCOM_BASE_0x02020005, P1, ADU_XSCOM_BAR

write_tbrom_bar:
        // write ADU TBROM BAR to set desired value
        updatestep STEP_SCOMINIT_WRITE_TBROM_BAR, D0, P0
        POREVE_DBG("Setting ADU TBROM BAR ...\n");
        sti     ADU_TBROM_BAR_0x02020017, P1, ADU_TBROM_BAR

        // Note: this is a branch target point for MPIPL
write_untrusted_bars:
        // write ADU/PSI/PBA Untrusted BAR/BAR mask registers
        updatestep STEP_SCOMINIT_WRITE_ADU_PSI_PBA_BARS, D0, P0
        lpcs    P1, NEST_CHIPLET_0x02000000
        // determine if running in secure mode
        lpcs    P0, STBY_CHIPLET_0x00000000
        ifbitsetscom D0, D0, OTPC_M_SECURITY_SWITCH_0x00010005, P0, 1, secure_mode

insecure_mode:
        // allow unrestricted access in insecure mode
        POREVE_DBG("Setting ADU/PSI BARs for insecure mode\n");
        li      D0, 0x0
        POREVE_DBG("Setting ADU Untrusted BAR (=%016llX)...\n", \
                   io_pore.d0.read());
        std     D0, ADU_UNTRUSTED_BAR_0x02020015, P1
        POREVE_DBG("Setting ADU Untrusted BAR Mask (=%016llX)...\n", \
                   io_pore.d0.read());
        std     D0, ADU_UNTRUSTED_BAR_MASK_0x02020016, P1
        bra     config_pba_bar_mask

secure_mode:
        // read global data to determine values in secure mode
	// if system dictates use of drawer offset, add (32TB * node ID)
	// to base address values
	mr	D0, A1
	braz	D0, secure_mode_no_offset
secure_mode_offset:
	// mask node ID (bits 40:42)
	andi	D1, D1, BITS(40, 3)
	// shift to node offset position (bit 18 = 32TB)
	sldi	D1, D1, 24
	bra	secure_mode_write_bars
secure_mode_no_offset:
	li	D1, 0

secure_mode_write_bars:
        POREVE_DBG("Setting ADU/PSI BARs for secure mode\n");
        lia     A0, PORE_SPACE_SEEPROM, fabric_config
        ld      D0, 0x00, A0
	add	D0, D0, D1
        POREVE_DBG("Setting ADU Untrusted BAR (=%016llX)...\n", \
                   io_pore.d0.read());
        std     D0, ADU_UNTRUSTED_BAR_0x02020015, P1

        ld      D0, 0x08, A0
	add	D0, D0, D1
        POREVE_DBG("Setting ADU Untrusted BAR Mask (=%016llX)...\n", \
                   io_pore.d0.read());
        std     D0, ADU_UNTRUSTED_BAR_MASK_0x02020016, P1

        ld      D0, 0x10, A0
	add	D0, D0, D1
	POREVE_DBG("Setting PSI Notrust BAR0 (=%016llX)...\n", \
                   io_pore.d0.read());
        std     D0, PSI_NOTRUST_BAR0_0x02013F40, P1

        ld      D0, 0x18, A0
	add	D0, D0, D1
        POREVE_DBG("Setting PSI Notrust BAR0 Mask (=%016llX)...\n", \
                   io_pore.d0.read());
        std     D0, PSI_NOTRUST_BAR0_MASK_0x02013F42, P1

        ld      D0, 0x20, A0
	add	D0, D0, D1
        POREVE_DBG("Setting PSI Notrust BAR1 (=%016llX)...\n", \
                   io_pore.d0.read());
        std     D0, PSI_NOTRUST_BAR1_0x02013F41, P1

        ld      D0, 0x28, A0
	add	D0, D0, D1
        POREVE_DBG("Setting PSI Notrust BAR1 Mask (=%016llX)...\n", \
                   io_pore.d0.read());
        std     D0, PSI_NOTRUST_BAR1_MASK_0x02013F43, P1

	POREVE_DBG("Setting PBA BARs\n");
	lia	A0, PORE_SPACE_SEEPROM, fabric_config_pba
	ld	D0, 0x00, A0
	add	D0, D0, D1
        POREVE_DBG("Setting PBA BAR3 (=%016llX)...\n", \
                   io_pore.d0.read());
        std     D0, PBA_BAR3_0x02013F03, P1
	
config_pba_bar_mask:
	lia	A0, PORE_SPACE_SEEPROM, fabric_config_pba
	ld	D0, 0x08, A0
        POREVE_DBG("Setting PBA BAR3 Mask (=%016llX)...\n", \
                   io_pore.d0.read());
        std     D0, PBA_BARMSK3_0x02013F07, P1

config_firs:

    // If MPIPL, leave the procedure
        lpcs    P0, MBOX_SCRATCH_REG1_0x00050039
        ifbitsetscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, procedure_end

	// Configure PB FIRs
        POREVE_DBG("Clearing PB FIRs\n")
        updatestep STEP_SCOMINIT_WRITE_FIR_REGS, D0, P0
        sti     PB_FIR_AND_CENT_0x02010C41, P1, CLEAR_ALL_FIRS_VAL
        sti     PB_FIR_AND_WEST_0x02010C01, P1, CLEAR_ALL_FIRS_VAL
        sti     PB_FIR_AND_EAST_0x02010C81, P1, CLEAR_ALL_FIRS_VAL

        POREVE_DBG("Configuring PB FIR (Central) ...\n")
        sti     PB_FIR_ACTION0_CENT_0x02010C46, P1, PB_CENTRAL_FIR_ACTION0_VAL
        sti     PB_FIR_ACTION1_CENT_0x02010C47, P1, PB_CENTRAL_FIR_ACTION1_VAL
        sti     PB_FIR_MASK_CENT_0x02010C43, P1, PB_CENTRAL_FIR_MASK_VAL

pb_west_fir:
        POREVE_DBG("Configuring PB FIR (West) ...\n")
        sti	PB_FIR_ACTION0_WEST_0x02010C06, P1,  PB_WEST_FIR_ACTION0_VAL
        sti     PB_FIR_ACTION1_WEST_0x02010C07, P1, PB_WEST_FIR_ACTION1_VAL
        sti     PB_FIR_MASK_WEST_0x02010C03, P1, PB_WEST_FIR_MASK_VAL
	// leave masked if Murano
	lpcs	P0, STBY_CHIPLET_0x00000000
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P0, CFAM_CHIP_ID_CHIP_MASK
        cmpibraeq   D0, pb_east_fir,                CFAM_CHIP_ID_MURANO
	// Venice, setup configuration based on state of EX1-3, 9-11
pb_west_fir_ex1:
	ls	P0, 0x11
	ifbitclrscom D0, D0, GENERIC_GP3_0x000F0012, P0, 0, pb_west_fir_ex2
	sti	PB_FIR_MASK_AND_WEST_0x02010C04, P1, ~(BITS(0,4) | BITS(24,5))
pb_west_fir_ex2:
	ls	P0, 0x12
        ifbitclrscom D0, D0, GENERIC_GP3_0x000F0012, P0, 0, pb_west_fir_ex3
        sti     PB_FIR_MASK_AND_WEST_0x02010C04, P1, ~(BITS(4,4) | BITS(24,5))
pb_west_fir_ex3:
        ls      P0, 0x13
        ifbitclrscom D0, D0, GENERIC_GP3_0x000F0012, P0, 0, pb_west_fir_ex9
        sti     PB_FIR_MASK_AND_WEST_0x02010C04, P1, ~(BITS(8,4) | BITS(24,5))
pb_west_fir_ex9:
        ls      P0, 0x19
        ifbitclrscom D0, D0, GENERIC_GP3_0x000F0012, P0, 0, pb_west_fir_ex10
        sti     PB_FIR_MASK_AND_WEST_0x02010C04, P1, ~(BITS(12,4) | BITS(24,5))
pb_west_fir_ex10:
        ls      P0, 0x1A
        ifbitclrscom D0, D0, GENERIC_GP3_0x000F0012, P0, 0, pb_west_fir_ex11
        sti     PB_FIR_MASK_AND_WEST_0x02010C04, P1, ~(BITS(16,4) | BITS(24,5))
pb_west_fir_ex11:
        ls      P0, 0x1B
        ifbitclrscom D0, D0, GENERIC_GP3_0x000F0012, P0, 0, pb_east_fir
        sti     PB_FIR_MASK_AND_WEST_0x02010C04, P1, ~(BITS(20,4) | BITS(24,5))

pb_east_fir:
	POREVE_DBG("Configuring PB FIR (East) ...\n")
        sti     PB_FIR_ACTION0_EAST_0x02010C86, P1, PB_EAST_FIR_ACTION0_VAL
        sti     PB_FIR_ACTION1_EAST_0x02010C87, P1, PB_EAST_FIR_ACTION1_VAL
        sti     PB_FIR_MASK_EAST_0x02010C83, P1, PB_EAST_FIR_MASK_VAL
	// Venice/Murano, setup configuration based on state of EX4-6,12-14
pb_east_fir_ex4:
        ls      P0, 0x14
        ifbitclrscom D0, D0, GENERIC_GP3_0x000F0012, P0, 0, pb_east_fir_ex5
        sti     PB_FIR_MASK_AND_EAST_0x02010C84, P1, ~(BITS(0,4) | BITS(24,5))
pb_east_fir_ex5:
        ls      P0, 0x15
        ifbitclrscom D0, D0, GENERIC_GP3_0x000F0012, P0, 0, pb_east_fir_ex6
        sti     PB_FIR_MASK_AND_EAST_0x02010C84, P1, ~(BITS(4,4) | BITS(24,5))
pb_east_fir_ex6:
        ls      P0, 0x16
        ifbitclrscom D0, D0, GENERIC_GP3_0x000F0012, P0, 0, pb_east_fir_ex12
        sti     PB_FIR_MASK_AND_EAST_0x02010C84, P1, ~(BITS(8,4) | BITS(24,5))
pb_east_fir_ex12:
        ls      P0, 0x1C
        ifbitclrscom D0, D0, GENERIC_GP3_0x000F0012, P0, 0, pb_east_fir_ex13
        sti     PB_FIR_MASK_AND_EAST_0x02010C84, P1, ~(BITS(12,4) | BITS(24,5))
pb_east_fir_ex13:
        ls      P0, 0x1D
        ifbitclrscom D0, D0, GENERIC_GP3_0x000F0012, P0, 0, pb_east_fir_ex14
        sti     PB_FIR_MASK_AND_EAST_0x02010C84, P1, ~(BITS(16,4) | BITS(24,5))
pb_east_fir_ex14:
        ls      P0, 0x1E
        ifbitclrscom D0, D0, GENERIC_GP3_0x000F0012, P0, 0, pba_fir
        sti     PB_FIR_MASK_AND_EAST_0x02010C84, P1, ~(BITS(20,4) | BITS(24,5))

pba_fir:
	// Configure PBA FIRs
        POREVE_DBG("Clearing PBA FIR ...\n")
	sti	PBA_FIR_AND_0x02010841, P1, CLEAR_ALL_FIRS_VAL

	POREVE_DBG("Configuring PBA FIR ...\n")
	sti	PBA_FIR_ACTION0_0x02010846, P1, PBA_FIR_ACTION0_VAL
	sti	PBA_FIR_ACTION1_0x02010847, P1, PBA_FIR_ACTION1_VAL
	sti	PBA_FIR_MASK_0x02010843, P1, PBA_FIR_MASK_VAL

	// Configure PB Pervasive LFIR
	POREVE_DBG("Clearing PB Pervasive FIR ...\n");
        sti     GENERIC_PERV_LFIR_0x0004000A, P1, CLEAR_ALL_FIRS_VAL

	POREVE_DBG("Configuring PB Pervasive FIR ...\n");
        sti     GENERIC_PERV_LFIR_ACT0_0x00040010, P1, PB_PERV_LFIR_ACTION0_VAL
        sti     GENERIC_PERV_LFIR_ACT1_0x00040011, P1, PB_PERV_LFIR_ACTION1_VAL
        sti     GENERIC_PERV_LFIR_MASK_0x0004000D, P1, PB_PERV_LFIR_MASK_VAL

        POREVE_DBG("Configuring PB XFIR ...\n");
        // check cache contained mode
        lia     A1, PORE_SPACE_SEEPROM, proc_sbe_scominit_control
	ldandi	D1, 0, A1, PROC_CONTROL_CACHE_CONTAINED
        branz   D1, pb_xfir_cache_contained

pb_xfir_non_cache_contained:
	sti	GENERIC_FIR_MASK_0x00040002, P1, PB_XFIR_MASK_VAL
        bra     pb_xfir_done

pb_xfir_cache_contained:
        sti     GENERIC_FIR_MASK_0x00040002, P1, PB_XFIR_MASK_CACHE_CONTAINED_VAL
        sti     GENERIC_SPATTN_MASK_0x00040007, P1, PB_SPATTN_MASK_CACHE_CONTAINED_VAL

pb_xfir_done:
        // write PBA hang pulse configuration register
        updatestep STEP_SCOMINIT_WRITE_HP_REGS, D0, P0
        POREVE_DBG("Writing PBA hang pulse divider registers ...\n")
        // preserve content outside of hang pulses
        ldandi  D1, PBA_CONFIG_0x0201084B, P1, BITS(0, 4) | BITS(14, 50)
        // set data hang divider = 0b00011, oper hang divider = 0b00001
        ori     D1, D1, BITS(7,2) | BIT(13)
        // write back
        std     D1, PBA_CONFIG_0x0201084B, P1

        // write ADU hang pulse configuration register
        POREVE_DBG("Writing ADU hang pulse divider registers ...\n")
        // set data hang divider = 0b00011, oper hang divider = 0b00001
        li      D1, BITS(3,2) | BIT(9)
        std     D1, ADU_HANG_DIV_0x02020018, P1

        POREVE_INF("Perform winkle setup")
        bsr proc_sbe_ex_winkle_setup

        // Get the ECID to apply this to only Murano DD1.x
        lpcs	P1, PCBMS_DEVICE_ID_0x000F000F
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P1, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
        cmpibrane   D0, 1f,                         (CFAM_CHIP_ID_MURANO    | CFAM_CHIP_ID_MAJOR_EC_1 )

        POREVE_INF("Set the OCC/PMC hang pulse to "
                    "64us for HW221998")
        lpcs    P1, TP_CHIPLET_0x01000000
        sti     HANG_PULSE_2_REG_0x010F0022, P1, 0x3C00000000000000
	bra	2f

1:
	POREVE_DBG("Configuring PB chiplet trace arrays to stop on checkstop")
	lpcs	P1, NEST_CHIPLET_0x02000000
	sti	GENERIC_DBG_MODE_REG_0x000107C0, P1, BIT(7)
	sti	GENERIC_DBG_TRACE_REG2_0x000107CB, P1, BIT(17)

2:
procedure_end:
        .end_procedure proc_sbe_scominit


// -----------------------------------------------------------------------------
// Configure all good EX chiplets for Fast with no power loss
//------------------------------------------------------------------------------
    // procedure progress codes
        .set    STEP_SCOMINIT_WINKLE_WA_START,     0x8
        .set    STEP_SCOMINIT_WINKLE_WA_EX_SCAN,   0x9
        .set    STEP_SCOMINIT_WINKLE_WA_FENCING,   0xA
        .set    STEP_SCOMINIT_WINKLE_WA_OFF,       0xB
        .set    STEP_SCOMINIT_WINKLE_WA_END,       0xC

    // 12 stages
    // set wait to about delay per stage (256) * #stages = 1536
    // plus 1 for conservatism.
        .set PFET_WAIT,         256*(12+1)

    // Mask to IFSM bits of monitor register
        .set FSM_MASK,          BITS(23,7)

    // Number of idle polls
        .set IDLE_POLL_MAX,     100
    // Number of PFET polls
        .set PFET_POLL_MAX,     8

        .subroutine proc_sbe_ex_winkle_setup, ipl, "$Revision: 1.42 $"

        // Clean up EX Multicast group 4 registers since it's owned by PM but was being used by istep 2
        lpcs    P0, ALL_EXS_BITX_0x51000000
        ld      D1, GENERIC_GP3_0x000F0012, P0
        lpcs    P0, EX00_CHIPLET_0x10000000

        // P0 contains the current EX chiplet to process
        // D1 contains the EX chiplets that are in MC group 3, with bit 16 representing
        // chiplet P0 and the following bits being the higher numbered chiplets
check_if_EX_chiplet_is_configured:
        ifbitclr D0, D1, 16, select_next_EX
        remove_from_mc_group D0, GENERIC_MCGR4_0x000F0004, P0
select_next_EX:
        rols    D1, D1, 1
        andi    D0, D1, BITS(16,16)
        braz    D0, done_processing_EX
        adds    P0, P0, 1
        bra     check_if_EX_chiplet_is_configured
done_processing_EX:


        updatestep STEP_SCOMINIT_WINKLE_WA_START, D0, P1

     // Skip EX section if no EX enabled
        lpcs    P0, ALL_EXS_BITX_0x51000000
        ld      D0, GENERIC_GP3_0x000F0012, P0
        braz    D0, winkle_wa_exit

        lpcs    P0, ALL_EXS_WRITE_0x69000000

        setp1_mcreadand D0

        // The following is not needed for Venice but done anyway as it doesn't
        // hurt anything
        POREVE_DBG("Clearing the OCC special wakeup bit that is present at the "
                    "beginning to keep from an automatic exit")
        sti     PM_SPECIAL_WKUP_OCC_0x100F010C, P0, 0x0

        // Needed for both Murano DD1 and Venice DD1
        POREVE_DBG("Configure PMPG1 for Fast with no power loss")
        POREVE_DBG("    Set bit 3 for hardware (non-assisted) mode")
        sti     EX_PMGP1_OR_0x100F0105, P0, BIT(3)

        // Done for both Murano DD1 and Venice DD1.   Still questionable value
        POREVE_DBG("    Clear bit 5 to select retention (this has questionable use actually)")
        sti     EX_PMGP1_AND_0x100F0104, P0, ~(BIT(5))

        // Needed for both Murano DD1 and Venice DD1
        POREVE_DBG("    Set the PFET Power Down Delays to minimums as the power isn't really going off")
        // Bits 0:3 is a power of 2 selector for a 0:15 timer.  Set these to 15 (eg F).
        sti     EX_CorePFPDDly_REG_0x100F012D, P0, BITS(0,4)
        sti     EX_ECOPFPDDly_REG_0x100F014D, P0, BITS(0,4)

        // Needed for both Murano DD1 and Venice DD1
        POREVE_DBG("Enable the PCBS-PM function by clearing PMGP0(0)")
        sti     EX_PMGP0_AND_0x100F0101, P0, ~(BIT(0))

        updatestep STEP_SCOMINIT_WINKLE_WA_FENCING, D0, P1

        // Not needed for Venice and beyond
        // Get the ECID to apply this to only Murano DD1
//      lpcs	P0, PCBMS_DEVICE_ID_0x000F000F
//      ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P0, BITS(0, 32)
//      cmpibrane   D0, 1f, CFAM_CHIP_ID_MURANO_10

//      lpcs    P0, ALL_EXS_WRITE_0x69000000
        POREVE_DBG("Clear GP0(63) to allow signal out of the EX to the PCBS")
        sti     EX_GP0_AND_0x10000004, P0, ~BIT(63)

        POREVE_DBG("Leaving GP0(63) set to keep the value hot to the PCBS until the "
                    "actual Winkle Exit.")
1:
        lpcs    P0, ALL_EXS_WRITE_0x69000000
        updatestep STEP_SCOMINIT_WINKLE_WA_OFF, D0, P1

        POREVE_DBG("Poll that the PFET controller is idle via bits 42 (core vdd) "
                    "and 50 (core vcs) being 1s")

        setp1_mcreadand D0
        ls      CTR, PFET_POLL_MAX
        bra     winkle_wa_pfet_loop_end

winkle_wa_pfet_loop_begin:
        ldandi  D0, EX_PFVddCntlStat_REG_0x100F0106, P1, (BIT(42)|BIT(50))

        POREVE_DBG("check VDD is complete, if so, proceed to VCS; if not, wait and loop")
        POREVE_DBG("    SLW PFET Stat 0x%16llX", io_pore.d0.read())
        cmpibrane   D0, winkle_wa_pfet_wait, (BIT(42)|BIT(50))

winkle_wa_pfet_vcs:
        ldandi  D0, EX_PFVcsCntlStat_REG_0x100F010E, P1, (BIT(42)|BIT(50))

        POREVE_DBG("check VCS is complete, if so, we're at the end; if not, wait and loop")
        POREVE_DBG("    SLW PFET Stat 0x%16llX", io_pore.d0.read())
        cmpibraeq D0, winkle_wa_waiting_for_idle, (BIT(42)|BIT(50))

        // otherwise wait
winkle_wa_pfet_wait:
        POREVE_DBG("PFET Poll wait")
        waits PFET_WAIT

        POREVE_DBG("PFET Poll CTR => %08lld", io_pore.ctr.read());

winkle_wa_pfet_loop_end:
        loop    winkle_wa_pfet_loop_begin
winkle_wa_error:
        reqhalt RC_SBE_WINKLE_PFET_TIMEOUT_ERROR

        // Poll for Idle FSM to be idle
winkle_wa_waiting_for_idle:
        POREVE_DBG("    PMGP0 check WA WAITING FOR IDLE")
        ld      D0, EX_PMGP0_0x100F0100, P1
        POREVE_DBG("    PMGP0 check 0x%16llX", io_pore.d0.read())

        ld      D0, EX_GP3_0x100F0012, P1
        POREVE_DBG("    GP3 check 0x%16llX", io_pore.d0.read())


        ls      CTR, IDLE_POLL_MAX
        bra     winkle_wa_wait_idle_end
winkle_wa_wait_idle_loop_begin:
	    POREVE_INF("Polling for exit of Winkle GOTO- CTR => %08lld", io_pore.ctr.read());
        //Check that PCBS-PM FSM is idle
        ldandi      D0, EX_PCBS_FSM_MONITOR2_REG_0x100F0171, P1, FSM_MASK
        POREVE_DBG("monitor2 D0 - %16llx", io_pore.d0.read());
        braz   D0, winkle_wa_end
winkle_wa_wait_idle_end:
        loop   winkle_wa_wait_idle_loop_begin

winkle_wa_idle_timeout:
        reqhalt RC_SBE_WINKLE_FSM_TIMEOUT_ERROR

winkle_wa_end:

        POREVE_DBG("PMGP0 -> Drop the DPLL_THOLD, PERV_THOLD, "
                    "PERVASIVE_ECO_FENCE and SLW_WINKLE_FENCE "
                    "that were raised by the Fast Winkle transition")
        // Difference before to after: 3, 4, 22, and 39
        sti     EX_PMGP0_AND_0x100F0101, P0, ~(BIT(3)|BIT(4)|BIT(22)|BIT(39))

        POREVE_DBG("EX_GP0 -> Drop the VITAL_THOLD and TP_LVLTRANS "
                    "electrical fence raised by the Fast Winkle transition")
        sti     EX_GP3_AND_0x100F0013, P0, ~(BIT(16)|BIT(27))

        //     odo remove : Dump the relevant regs to check status
        POREVE_DBG("    PMGP0 check WA END after clearing")
        ld      D0, EX_PMGP0_0x100F0100, P1
        POREVE_DBG("    PMGP0 check 0x%16llX", io_pore.d0.read())

        POREVE_DBG("    GP3 check WA END after clearing")
        ld      D0, EX_GP3_0x100F0012, P1
        POREVE_DBG("    GP3 check 0x%16llX", io_pore.d0.read())
        //     odo remove :


        POREVE_DBG("Check PMHISTRegOCC for winkle state")
        // Check bits 0:2 for 110 (Fast Winkle)
        // MC read-AND is not full sufficient to ensure that all chiplets are
        // at the correct state as all zeros (eg running) will not be noticed.
        // If both a read AND and and a Read OR succeed, then all chiples DID
        // give a valid response.

        // Do the present MC read AND
        ldandi   D0, EX_PMSTATEHISTOCC_REG_0x100F0112, P1, BITS(0,3)
        POREVE_DBG("    PMHISTRegOCC mc read AND 0x%16llX", io_pore.d0.read())
        cmpibraeq D0, 1f, (BIT(0)|BIT(1))
winkle_wa_check_error_and:
        reqhalt RC_SBE_WINKLE_STATE_AND_ERROR
1:
        // Do the MC read OR case
        setp1_mcreador D0
        ldandi   D0, EX_PMSTATEHISTOCC_REG_0x100F0112, P1, BITS(0,3)
        POREVE_DBG("    PMHISTRegOCC mc read OR  0x%16llX", io_pore.d0.read())
        cmpibraeq D0, 1f, (BIT(0)|BIT(1))
winkle_wa_check_error_or:
        reqhalt RC_SBE_WINKLE_STATE_OR_ERROR
1:

        POREVE_DBG("PCB heartbeat disable to avoid clock"
                    "controller collisions coming out of winkle\n")
        // Bit 4: heartbeat disable;  Bits 8:12: Error Mask that defaults to on
        // Bit 4 is cleared upon EP Reset.
        sti     EX_SLAVE_CONFIG_0x100F001E, P0, (BIT(4)|BITS(8,5))

        // Check PMErr_REG(12) snitch bit for invalid PMGP0 writes.
        ld      D0, EX_PMErr_REG_0x100F0109, P1
        andi    D1, D0, (BIT(12))
        braz    D1, skip_pmerrreg_clear
        // Only clean PMErr_REG for non-Mur1.x systems.
        lpcs    P1, STBY_CHIPLET_0x00000000
        ldandi  D1, PCBMS_DEVICE_ID_0x000F000F, P1, BITS(0, 32)
        andi    D1, D1, CFAM_CHIP_ID_CHIP_MAJOR_MASK
        xori    D1, D1, CFAM_CHIP_ID_MURANO_1
        braz    D1, skip_pmerrreg_clear
        nop
        POREVE_DBG("    PMERR_REG 0x%16llX", io_pore.d0.read())
        POREVE_DBG("Resetting entire PMErr_REG because the \"PMGP0 invalid write snitch\" bit PMErr_REG(12) is on");
        // Even though the following reg write attempts to only clear bit12, it will
        // in fact cause the entire PMErr_REG to be cleared. So we only do this
        // in case the snitch bit12 is set.. because this bit is so precious to us.
        andi    D1, D0, ~(BIT(12))
        std     D1, EX_PMErr_REG_0x100F0109, P0

skip_pmerrreg_clear:

        updatestep STEP_SCOMINIT_WINKLE_WA_END, D0, P1
        POREVE_DBG("Winkle work-around complete ...\n")

winkle_wa_exit:

        .end_subroutine proc_sbe_ex_winkle_setup
