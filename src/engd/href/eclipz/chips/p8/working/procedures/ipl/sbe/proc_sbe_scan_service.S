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
#include "p8_scom_addresses.H"
#include "proc_sbe_scan_service.H"
#include "proc_sbe_initf_common_seeprom.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------

     //
     // mailbox scan request constants
     //

     // poll delay
     //   this value is set to target a 500us delay between mailbox polls
     //   - for a nest frequency of 2.4GHz, the TP clock time is 1.667ns
     //     [1/ (2.4GHz/4)] -> 1/600MHz -> .001667us -> 1.667ns.
     //   - the maximum count that a PORE waits instruction can have is 2^24.
     //   - this represents 268435455 * 1.667ns or 447ms.  A count of 300000
     //     yields ~500us.  0d300000 -> 0x493E0
        .set    REQ_POLL_DELAY, 0x493E0
     // request valid
        .set    REQ_VALID_MASK, BIT(0)
     // ring ID
        .set    RING_ID_MASK, BITS(6,2)
        .set    RING_ID_ABUS, BIT(7)
        .set    RING_ID_PCI, BIT(6)
        .set    RING_ID_DMI, BIT(6) | BIT(7)
     // ring operation
        .set    RING_OP_MASK, BITS(9,3)
        .set    RING_OP_SHIFT, 52
        .set    RING_OP_USE_CURR_RING_MASK, BIT(9)
        .set    RING_OP_USE_IMG_RING_MASK, BITS(10,2)
        .set    RING_OP_BASE, 0
        .set    RING_OP_BASE_VCO_S1, 1
        .set    RING_OP_BASE_VCO_S2, 2
        .set    RING_OP_MOD_REFCLK_SEL, 3
        .set    RING_OP_MOD_PFD360, 4
        .set    RING_MOD_IS_BIT_SET, 1
        .set    RING_MOD_IS_BIT_CLEAR, 0
     // ring bus ID
        .set    RING_BUS_ID_MASK, BITS(13,3)
        .set    RING_BUS_ID_SHIFT, 48
        .set    MAX_RING_BUS_ID_ABUS, 3-1
        .set    MAX_RING_BUS_ID_DMI, 8-1
     // halt request pattern
        .set    REQ_HALT_MASK, BITS(16,16)
        .set    REQ_HALT_PATTERN, 0x0000D05E00000000

     //
     // mailbox scan response constants
     //

     // response valid
        .set    RESP_VALID_BIT, BIT(0)

     //
     // SEEPROM ring container image consants
     //
        .set    RING_IMG_LENGTH_OFFSET, 64
        .set    RING_IMG_LENGTH_MASK, BITS(32,32)

     //
     // ring rotation/setpulse generation constants
     //

     // scan select register value to select PLL bndy ring for rotation
        .set    CLK_SCANSEL_PLL_RING, BIT(11) | BIT(28)
     // OPCG register programming to apply setpulse
	.set	OPCG_CNTL0_SCAN_RATIO_MASK, BITS(4,5)
	.set	OPCG_CNTL0_RUNN_MODE, BIT(0)
	.set	OPCG_CNTL0_SCAN_RATIO, BITS(7,2)
	.set	OPCG_CNTL0_INOP_ALIGN, BITS(12,2)
	.set	OPCG_CNTL2_OPCG_PAD_VALUE, BIT(50)
	.set	OPCG_CNTL3_RUN_ON_UPDATE_DR, BIT(1)
	.set	OPCG_CNTL3_RUN_ON_CAPTURE_DR, BIT(2)
     // clock region register value to select PLL bndy ring for setpulse
	.set	CLK_REGION_PLL_SETPULSE, BIT(11) | BIT(21)
     // header check pattern/mask
        .set    HEADER_CHECK_PATTERN, 0xA5A55A5A00000000
        .set    HEADER_CHECK_MASK, BITS(0,32)
     // maximum number of bits to rotate in single operation
        .set    MAX_ROTATE_BITS, 0x3F
        .if     ((((MAX_ROTATE_BITS + 1) & MAX_ROTATE_BITS) != 0) || \
                 (MAX_ROTATE_BITS <= 0) || (MAX_ROTATE_BITS > 0xfff))
                .error  "MAX_ROTATE_BITS must be of the form 2**n - 1, for 1 <= n <= 12"
        .endif

//------------------------------------------------------------------------------
// Subroutines
//------------------------------------------------------------------------------

     // PLL bndy ring pre-scan setup
     //   Condition OPCG/clock controller to issue setpulse (update shadow ring from bndy)
     //   prior to bndy ring scan
     // At entry:
     //   P0: Chiplet ID
     // Destroys:
     //   D0
	.subroutine pre_scan_cc_setup, ipl, "$Revision: 1.1 $"
	ldandi  D0, GENERIC_OPCG_CNTL0_0x00030002, P0, OPCG_CNTL0_SCAN_RATIO_MASK
	andi    D0, D0, ~OPCG_CNTL0_SCAN_RATIO_MASK
	ori     D0, D0, OPCG_CNTL0_RUNN_MODE | OPCG_CNTL0_SCAN_RATIO | OPCG_CNTL0_INOP_ALIGN
	std     D0, GENERIC_OPCG_CNTL0_0x00030002, P0
	sti     GENERIC_OPCG_CNTL2_0x00030004, P0, OPCG_CNTL2_OPCG_PAD_VALUE
	sti     GENERIC_OPCG_CNTL3_0x00030005, P0, OPCG_CNTL3_RUN_ON_UPDATE_DR | OPCG_CNTL3_RUN_ON_CAPTURE_DR
	sti     GENERIC_CLK_REGION_0x00030006, P0, CLK_REGION_PLL_SETPULSE
	.end_subroutine pre_scan_cc_setup

     // PLL bndy ring post-scan cleanup
     //   Cleanup OPCG/clock controller after bndy ring scan
     // At entry:
     //   P0: Chiplet ID
     // Destroys:
     //   none
	.subroutine post_scan_cc_setup, ipl, "$Revision: 1.1 $"
	sti     GENERIC_OPCG_CNTL3_0x00030005, P0, 0
	sti     GENERIC_CLK_REGION_0x00030006, P0, 0
	sti     GENERIC_CLK_SCANSEL_0x00030007, P0, 0
	.end_subroutine post_scan_cc_setup

     // PLL bndy ring rotate function
     //   This leverages existing routines in pibmem (proc_sbe_decompress_scan)
     //   to accomplish ring rotation of an arbitrary bit length.  The pibmem
     //   solution is necessary because portions of the code sequence must be
     //   self modifying.
     // At entry:
     //   D1: Rotate count
     //   P0: Chiplet ID to scan
     // Destroys:
     //   D0, D1, P1, SPRG0, A1
     // Preserves:
     //   P0, A0, CTR
	.subroutine pll_ring_rotate, ipl, "$Revision: 1.1 $"
     // prep for call to pibmem scan rotate function
        lpcs    P1, STBY_CHIPLET_0x00000000
        mr      D0, P0
        std     D0, read_chiplet, P1
rotate_ring_loop:
     // if remaining rotate count is greater than MAX_ROTATE_BITS
     //    - rotate by MAX_ROTATE_BITS
     //    - decrement rotate count
     //    - loop again
     // else
     //    - rotate by remaining count
        POREVE_DBG("pll_ring_rotate: Bits remaining = %lld", io_pore.d1.read())
        andi    D0, D1, ~MAX_ROTATE_BITS
        braz    D0, rotate_ring_final
        subs    D1, D1, MAX_ROTATE_BITS
        mr      SPRG0, D1
        ls      D0, MAX_ROTATE_BITS
        bsria   PORE_SPACE_PIBMEM, scan_rotate
        mr      D1, SPRG0
        bra     rotate_ring_loop
rotate_ring_final:
        braz    D1, rotate_ring_done
        mr      D0, D1
        bsria   PORE_SPACE_PIBMEM, scan_rotate
rotate_ring_done:
	.end_subroutine pll_ring_rotate

     // register save function
     //   Saves CTR/A0/D0 values to pibmem
     // At entry:
     //   CTR, A0, D0: values to save
     // Destroys:
     //   P1
     // Preserves:
     //   P0, A0, A1, SPRG0
	.subroutine scan_service_save_regs, ipl, "$Revision: 1.1 $"
        mr      P1, P0
        bsr     store_ctr_a0_d0_module
        mr      P0, P1
	.end_subroutine scan_service_save_regs

     // register restore function
     //   Restores CTR/A0/D0 values from pibmem
     // At exit:
     //   CTR, A0, D0: restored from pibmem scratch area
     // Destroys:
     //   P1
     // Preserves:
     //   P0, A0, A1, SPRG0
	.subroutine scan_service_restore_regs, ipl, "$Revision: 1.1 $"
	mr	P1, P0
	bsr	restore_ctr_a0_d0_module
	mr	P0, P1
	.end_subroutine scan_service_restore_regs


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

	.global	proc_sbe_scan_service

	.subroutine proc_sbe_scan_service, ipl, "$Revision: 1.1 $"
	POREVE_DBG("proc_sbe_scan_service: Setting up");

     // write initial progress code
	lpcs	P1, STBY_CHIPLET_0x00000000
	sti     MBOX_SBEVITAL_0x0005001C, P1, ((PROC_SBE_SCAN_SERVICE_ISTEP_NUM << 4) | SUBSTEP_PROC_ENTRY) << 32

     // clear response mailbox (SBE->HB)
	sti	MBOX_SCRATCH_REG1_0x00050039, P1, 0
       
prep_for_hb_request:
     // clear request mailbox (HB->SBE)
 	sti	MBOX_SCRATCH_REG0_0x00050038, P1, 0

     // indicate SBE is ready to service scan requests
        POREVE_INF("proc_sbe_scan_service: Marking SBE ready for next scan request");
        updatestep_inline SUBSTEP_SBE_READY, D0, P0
 
        .global wait_for_hb_request
wait_for_hb_request:
     // having the SBE generically consuming the PIB can collide with other
     // activities possible on the PIB, so delay between polls
        waits   REQ_POLL_DELAY

     // read request mailbox from hostboot 
	POREVE_DBG("proc_sbe_scan_service: Polling for scan request from HB");
	ld	D1, MBOX_SCRATCH_REG0_0x00050038, P1
	POREVE_DBG("proc_sbe_scan_service: Read MBOX: %16llx", io_pore.d1.read());
	andi	D0, D1, REQ_VALID_MASK
        braz	D0, wait_for_hb_request

process_request:
     // save original request (minus valid bit) in MBOX1
     // this will later serve as scan reply response
	POREVE_DBG("proc_sbe_scan_service: Processing HB scan request")
	andi	D0, D1, ~REQ_VALID_MASK
	std	D0, MBOX_SCRATCH_REG1_0x00050039, P1

     // check for pattern indicating we are done
	andi	D0, D1, REQ_HALT_MASK
	cmpibraeq D0, scan_service_halt, REQ_HALT_PATTERN

     // indicate progress update to HB
	POREVE_DBG("proc_sbe_scan_service: Decoding request")
	updatestep_inline SUBSTEP_DECODE_REQ, D0, P0

decode_request:
     // isolate ring operation (CTR)
	andi	D0, D1, RING_OP_MASK
	srdi	D0, D0, RING_OP_SHIFT
	mr	CTR, D0
     // default maximum bus ID (P1) permitted to zero
	ls	P1, 0
     // determine ring ID
     // branch to ring specific code which will:
     // - load pointer to base ring application routine (A1)
     // - load pointer to base ring modification offset (A0)
     // - set maximum permitted bus ID (P1)
	andi	D0, D1, RING_ID_MASK
        cmpibraeq D0, ring_id_abus, RING_ID_ABUS
        cmpibraeq D0, ring_id_pci, RING_ID_PCI
        cmpibraeq D0, ring_id_dmi, RING_ID_DMI
     // halt, invalid operation requested (bad ring ID)
	bra	invalid_operation_error

ring_id_abus:
	POREVE_DBG("proc_sbe_scan_service: Ring ID = ABUS")
	lpcs	P0, A_BUS_CHIPLET_0x08000000
	la	A1, scan_instr_ptr_abus
	mr	D0, CTR
	cmpibraeq D0, set_offset_abus_refclk_sel, RING_OP_MOD_REFCLK_SEL
	cmpibraeq D0, set_offset_abus_pfd360, RING_OP_MOD_PFD360
	cmpibraeq D0, check_bus_id, RING_OP_BASE
     // halt, invalid operation requested (bad ring op for ABUS)
	bra	invalid_operation_error
set_offset_abus_refclk_sel:
	POREVE_DBG("proc_sbe_scan_service: Op = REFCLK SEL")
	la	A0, ab_bndy_pll_refclk_sel_mod
	ls	P1, MAX_RING_BUS_ID_ABUS
	bra	check_bus_id
set_offset_abus_pfd360:
	POREVE_DBG("proc_sbe_scan_service: Op = PFD360")
	la	A0, ab_bndy_pll_pfd360_mod
	ls	P1, MAX_RING_BUS_ID_ABUS
	bra	check_bus_id

ring_id_pci:
	POREVE_DBG("proc_sbe_scan_service: Ring ID = PCI")
	lpcs	P0, PCIE_CHIPLET_0x09000000
	la	A1, scan_instr_ptr_pci
	mr	D0, CTR
	cmpibraeq D0, check_bus_id, RING_OP_BASE
     // halt, invalid operation requested (bad ring op for PCI)
	bra	invalid_operation_error

ring_id_dmi:
	POREVE_DBG("proc_sbe_scan_service: Ring ID = DMI")
	lpcs	P0, NEST_CHIPLET_0x02000000
	la	A1, scan_instr_ptr_dmi
	mr	D0, CTR
        cmpibraeq D0, set_offset_dmi_refclk_sel, RING_OP_MOD_REFCLK_SEL
        cmpibraeq D0, set_offset_dmi_pfd360, RING_OP_MOD_PFD360
        cmpibraeq D0, check_bus_id, RING_OP_BASE
     // halt, invalid operation requested (bad ring op for DMI)
        bra     invalid_operation_error
set_offset_dmi_refclk_sel:
        POREVE_DBG("proc_sbe_scan_service: Op = REFCLK SEL")
        la	A0, pb_bndy_dmipll_refclk_sel_mod
        ls      P1, MAX_RING_BUS_ID_DMI
        bra     check_bus_id
set_offset_dmi_pfd360:
        POREVE_DBG("proc_sbe_scan_service: Op = PFD360")
        la	A0, pb_bndy_dmipll_pfd360_mod
	ls	P1, MAX_RING_BUS_ID_DMI

check_bus_id:
     // check that bus ID value in request is permissable
     // P1 contains maximum value allowed based on ring type/modification requested
	POREVE_DBG("proc_sbe_scan_service: Validating BUS ID")
	andi	D1, D1, RING_BUS_ID_MASK
	srdi	D1, D1, RING_BUS_ID_SHIFT
	mr	D0, P1
	sub	D0, D0, D1
	tfbuge	D0, prep_for_initial_scan
     // halt, invalid operation requested (bad bus ID)
	bra	invalid_operation_error

prep_for_initial_scan:
     // save register state (CTR/A0/D0) ahead of potential call to load_ring
        lpcs    P1, STBY_CHIPLET_0x00000000
        ld      D0, MBOX_SCRATCH_REG1_0x00050039, P1
	bsr	scan_service_save_regs

set_initial_ring_state:
     // based on ring operation, setup clock controller for scan with setpulse
	updatestep_inline SUBSTEP_SCAN_IP, D0, P1
	mr	D0, CTR
	cmpibrane D0, scan_seeprom_ring, RING_OP_BASE
scan_seeprom_ring_pre:
     // setup clock controller for scan with setpulse
	bsr	pre_scan_cc_setup
	updatestep_inline SUBSTEP_SCAN_PRE_BRANCH, D0, P1
scan_seeprom_ring:
     // branch to apprpriate ring specific base scan routine (via A1), optionally
     // do scan (via load_ring) and branch back (after branch back, A1 will
     // hold pointer to fixed section entry associated with ring)
	POREVE_DBG("proc_sbe_scan_service: Branching to scan routine")
	mr	D0, CTR
	ld	D1, 0, A1
	brad	D1
scan_seeprom_ring_post:
	updatestep_inline SUBSTEP_SCAN_POST_BRANCH, D0, P1
     // restore register state (CTR/A0/D0)
	bsr	scan_service_restore_regs
	mr	D1, D0
     // based on ring operation, cleanup clock controller after scan
	mr	D0, CTR
	cmpibrane D0, scan_seeprom_ring_done, RING_OP_BASE
	bsr	post_scan_cc_setup
scan_seeprom_ring_done:
     // base ring from SEEPROM has now been handled
     // if no further modifications are specified, scan request is satisfied
	cmpibraeq D0, scan_request_done, RING_OP_BASE

calc_ring_mod_offset:
     // ring will be re-scanned to apply modification
     // determine bit offset in ring to be modified
     // add 8*bus_ID to previously saved modification address pointer (A0)
	updatestep_inline SUBSTEP_RESCAN_IP, D0, P1
	andi	D0, D1, RING_BUS_ID_MASK
	srdi	D0, D0, RING_BUS_ID_SHIFT-3
	mr	D1, A0
	add	D0, D0, D1
	mr	A0, D0
     // final address computed, retrieve data
     // save into pibmem scratch (D0) along with base ring fixed section pointer (A0)
	ld	D0, 0, A0
	POREVE_DBG("proc_sbe_scan_service: Bit offset to modify = %lld", io_pore.d0.read())
	mr	A0, A1
	bsr	scan_service_save_regs
     // shift modification offset into D1 (used by rotate subroutine, D0 will be destroyed
     // before then)
	mr	D1, D0

rescan_ring_pre:
     // setup clock controller for scan with setpulse
	bsr	pre_scan_cc_setup
     // prime ring with header check pattern
        sti     GENERIC_CLK_SCANSEL_0x00030007, P0, CLK_SCANSEL_PLL_RING
        sti     GENERIC_CLK_SCANDATA0_0x00038000, P0, HEADER_CHECK_PATTERN

rotate_ring_to_mod:
     // rotate ring until bit to modify
	bsr	pll_ring_rotate

mod_ring:
     // flip targeted bit in ring
     // - by previous rotate the bit to modify will be in MSB of scan data register
     // - read-modify-write scan data register to flip this value, preserving
     //   all other bit positions in register
	ld	D0, GENERIC_CLK_SCANDATA0_0x00038000, P0
	mr	D1, D0
	andi	D0, D0, ~BIT(0)
	andi	D1, D1, BIT(0)
	branz	D1, mod_ring_store_bit
	ori	D0, D0, BIT(0)
mod_ring_store_bit:
	std	D0, GENERIC_CLK_SCANDATA0_0x00038000, P0

calc_remaining_rotate_count:
     // restore registers from pibmem scratch
     // modification offset will restore to D0, base ring fixed section pointer to A0
	bsr	scan_service_restore_regs
	mr	D1, D0
     // determine length of target ring from base ring image in SEEPROM
     // - A0 holds address of fixed section entry associated with ring
     // - read this & use as pointer value to find ring image
     // - ring length is present at fixed offset in image container
        ld      D0, 0, A0
        mr      A0, D0
        ld      D0, RING_IMG_LENGTH_OFFSET, A0
        andi    D0, D0, RING_IMG_LENGTH_MASK
        POREVE_DBG("proc_sbe_scan_service: Ring length = %lld bits", io_pore.d0.read())
	sub	D0, D0, D1
	POREVE_DBG("proc_sbe_scan_service: Remaining bits = %lld bits", io_pore.d0.read())
     // shift modification offset into D1 (used by rotate subroutine)
	mr	D1, D0

rotate_ring_to_end:
     // rotate ring to end
	bsr	pll_ring_rotate

rescan_ring_finish:
     // check that header rotated through ring correctly
	POREVE_DBG("proc_sbe_scan_service: Checking ring header")
	ldandi	D0, GENERIC_CLK_SCANDATA0_0x00038000, P0, HEADER_CHECK_MASK
	cmpibrane D0, scan_checkword_error, HEADER_CHECK_PATTERN
     // trigger setpulse
	POREVE_DBG("proc_sbe_scan_service: Issuing setpulse to complete the scan")
	sti	GENERIC_CLK_SCAN_UPDATEDR_0x0003A000, P0, 0

rescan_ring_post:
     // clean up clock controller
	bsr	post_scan_cc_setup

scan_request_done:
     // update SBE->HB response mailbox
	POREVE_DBG("proc_sbe_scan_service: Scan request done")
	lpcs	P1, STBY_CHIPLET_0x00000000
	ld	D0, MBOX_SCRATCH_REG1_0x00050039, P1
	ori	D0, D0, RESP_VALID_BIT
	std	D0, MBOX_SCRATCH_REG1_0x00050039, P1
     // loop back to service the next scan request
	bra	prep_for_hb_request


     //
     // procedure halt locations
     //

        .global scan_service_halt
scan_service_halt:
     // halt point -- exit with success
        POREVE_INF("proc_sbe_scan_service: Success!");
     // re-enable the CFAM I2C master 
	POREVE_INF("proc_sbe_scan_service: Restoring CFAM I2CM and stopping SBE as we are done")
	lpcs	P0, STBY_CHIPLET_0x00000000
        bci     D0, MBOX_FSIGP4_0x00050013, P0, BIT(20)
	updatestep_inline SUBSTEP_HALT_SUCCESS, D0, P1
        reqhalt RC_SBE_SUCCESS_SLAVE_CHIP, D0, P1
        bra     scan_service_halt

scan_checkword_error:
     // error halt point -- checkword error observed when rotating ring to perform bit manipulation
	POREVE_ERR("proc_sbe_scan_service: Scan ring header check failed, halting!")
	updatestep_inline SUBSTEP_RESCAN_CHECKWORD_ERR, D0, P1
	reqhalt RC_SBE_SCAN_CHECKWORD_ERROR

invalid_operation_error:
     // error halt point -- invalid operation requested by HB via mailbox
	POREVE_ERR("proc_sbe_scan_service: Invalid operation requested, halting!")
	updatestep_inline SUBSTEP_ARG_ERR, D0, P1
	reqhalt RC_PROC_SBE_SCAN_SERVICE_INVALID_OPERATION


     // ring specific data areas
     // includes code block to scan SEEPROM-resident ring image and
     // storage for pointer to this code block

	.balign	PORE_INSTRUCTION_BUFFER_SIZE
scan_instr_ptr_abus:
        .quadia PORE_SPACE_SEEPROM, scan_seeprom_abus

scan_seeprom_abus:
        updatestep_inline SUBSTEP_SCAN_IN_BRANCH, D1, P1
        cmpibrane D0, scan_seeprom_abus_done, RING_OP_BASE
	POREVE_DBG("proc_sbe_scan_service: Scanning ABUS ring from SEEPROM")
	load_ring ab_bndy_pll skipoverride=1 hasalternate=1
scan_seeprom_abus_done:
	updatestep_inline SUBSTEP_SCAN_DONE, D1, P1
	la	A1, ab_bndy_pll_ring_alt
	bra	scan_seeprom_ring_post

	.balign PORE_INSTRUCTION_BUFFER_SIZE
scan_instr_ptr_pci:
	.quadia PORE_SPACE_SEEPROM, scan_seeprom_pci

scan_seeprom_pci:
	updatestep_inline SUBSTEP_SCAN_IN_BRANCH, D1, P1
	cmpibrane D0, scan_seeprom_pci_done, RING_OP_BASE
	POREVE_DBG("proc_sbe_scan_service: Scanning PCI ring from SEEPROM")
	load_ring pci_bndy_pll skipoverride=1 hasalternate=1
scan_seeprom_pci_done:
	updatestep_inline SUBSTEP_SCAN_DONE, D1, P1
	la	A1, pci_bndy_pll_ring_alt
	bra	scan_seeprom_ring_post

	.balign PORE_INSTRUCTION_BUFFER_SIZE
scan_instr_ptr_dmi:
	.quadia PORE_SPACE_SEEPROM, scan_seeprom_dmi

scan_seeprom_dmi:
        updatestep_inline SUBSTEP_SCAN_IN_BRANCH, D1, P1
	cmpibrane D0, scan_seeprom_dmi_done, RING_OP_BASE
	POREVE_DBG("proc_sbe_scan_service: Scanning DMI ring from SEEPROM")
	load_ring pb_bndy_dmipll skipoverride=1 hasalternate=1
scan_seeprom_dmi_done:
	updatestep_inline SUBSTEP_SCAN_DONE, D1, P1
	la	A1, pb_bndy_dmipll_ring_alt
	bra	scan_seeprom_ring_post

	.end_subroutine proc_sbe_scan_service
