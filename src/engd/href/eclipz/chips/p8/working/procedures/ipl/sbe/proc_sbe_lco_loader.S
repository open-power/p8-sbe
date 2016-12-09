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

	// procedure prgress codes
	.set	STEP_LCO_LOADER_CHECK_FBC, 0x1
	.set	STEP_LCO_LOADER_RAM_HRMOR, 0x2
	.set	STEP_LCO_LOADER_SET_SCRATCH, 0x3
	.set	STEP_LCO_LOADER_CHECK_IMAGE, 0x4
	.set	STEP_LCO_LOADER_PREP_STREAM, 0x5
	.set	STEP_LCO_LOADER_MAIN_LOOP, 0x6
	.set	STEP_LCO_LOADER_CHECK_STATUS, 0x7

	// RAM Instruction Mode Register constants
	// enable ram mode, set HV for all threads
	.set	RAM_MODE_REG_EN_ALL_HV, 0xAAAA800000000000
	// disable ram mode
	.set	RAM_MODE_REG_DIS_ALL, 0x0000000000000000

	// RAM Instruction Control Register constants
	// mfsprd (scratch0 -> GPR0)
	.set	RAM_CTRL_REG_SCR0_GPR0, 0x0F82A854C0000000
	// mthrmor (GPR0 -> HRMOR)
	.set	RAM_CTL_REG_GPR0_HRMOR, 0x0F832974C0000000

	// size of master cache (8MB L3 cache for Murano/Venice)
        .set    MASTER_CACHE_SIZE, 0x0000000000800000

        // OCB Status/Control Register error mask/expected values
        .set    OCB3_STATUS_CONTROL_ERR_MASK, 0xC0FA000000000000
        .set    OCB3_STATUS_CONTROL_EXP, 0x0000000000000000

        // PBA FIR Register error mask/expected values
        .set    PBA_FIR_ERR_MASK, 0xFFFEFFFC00000000
        .set    PBA_FIR_EXP, 0x000000000000

        // PBA Write Buffer Valid Status Register error mask/expected values
        .set    PBA_WBUFVAL_ERR_MASK, 0x000000001F7F0000
        //   35:39 = write buffer status => 0x01 (empty)
        .set    PBA_WBUFVAL_EXP, 0x0000000001000000

        // This bit number indicates if we're doing a MPIPL
        .set MPIPL_BITNUM, 0
        
//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

        .procedure proc_sbe_lco_loader, ipl, "$Revision: 1.29 $"

	// halt here if we are mistakenly executing this procedure
	// with multicast, as it is not supported
	mr	D0, P0
	sldi	D0, D0, 24
	cmpibrane D0, get_host_image_offset, ALL_CORES_WRITE_0x6A000000

	POREVE_ERR("proc_sbe_lco_loader does not support execution with cv_multicast!")
	reqhalt RC_SBE_LCO_LOADER_MULTICAST_ERR

get_host_image_offset:
        // set pointer to start of image space
        POREVE_DBG("Loading host image offset from mailbox...")
	lpcs	P1, MBOX_SCRATCH_REG2_0x0005003A
	ld	D0, MBOX_SCRATCH_REG2_0x0005003A, P1
	srdi	D0, D0, 32
	mr	D1, D0
	ori	D0, D0, (PORE_SPACE_PNOR << 32)
	mr	A0, D0
	POREVE_DBG("Host image address (PNOR) = 0x%016llX", io_pore.a0.read())


	// configure ECC
	POREVE_DBG("Configuring ECC range...")
	ori	D1, D1, 0xFFFFFFFF00000000
	lpcs	P1, LPC_ECC_ADDRESS_0x000B0004
	std	D1, LPC_ECC_ADDRESS_0x000B0004, P1

check_xstop:

        // read ADU pMisc Mode register
	updatestep STEP_LCO_LOADER_CHECK_FBC, D1, P1
        POREVE_DBG("Checking state of tc_pb_stop ...")
        lpcs    P1, NEST_CHIPLET_0x02000000
        ld      D0, ADU_PMISC_MODE_0x0202000B, P1

        // check state of FBC pervasive stop control signal which if set would
        // prohibit fabric commands from being broadcast
        //   22 = pb_stop
        POREVE_DBG("tc_pb_stop = 0b%d", io_pore.d0.isBitSet(22))
        ifbitclr D0, D0, 22, ram_hrmor

        // pervasive stop control bit is set, halt
        POREVE_ERR("tc_pb_stop is set, so proc_sbe_lco_loader will not run!")
        POREVE_ERR("Check fircheck output for system checkstop!")
        reqhalt RC_SBE_LCO_LOADER_FBC_STOPPED_ERR

ram_hrmor:
 
	// do not RAM hrmor in secure mode.
	lpcs	P1, STBY_CHIPLET_0x00000000
	ifbitsetscom D1, D1, OTPC_M_SECURITY_SWITCH_0x00010005, P1, 1, set_scratch

 	// set HRMOR to secure load address
	updatestep STEP_LCO_LOADER_RAM_HRMOR, D1, P1
	ld	D1, 0x8, A0

        // Force the hardware to think we're in special wakeup so the SCOMs will
        // succeed to the core due to the init state of Nap.  This does NOT 
        // influence the PM state machines; only the wire to turn clocks on 
        // to the core.
        // Bit 6 enables/disables override; bit 8 controls the Special Wake-up
        sti EX_PMGP1_OR_0x100F0105, P0, BIT(6) | BIT(8)

        // execute RAM sequence
	POREVE_DBG("Activating T0 for RAM ...")
	bsi	D0, EX_PERV_THREAD_ACTIVE_0x1001310E, P0, BIT(8)
	POREVE_DBG("Enabling RAM_MODE, set HV mode for all threads ...")
	sti	EX_PERV_RAM_MODE_0x10013C00, P0, RAM_MODE_REG_EN_ALL_HV
	POREVE_DBG("Loading EX SCRATCH0 register for RAM write (0x%016llX)...", io_pore.d1.read())
	std	D1, EX_PERV_SCRATCH0_10013283, P0
	POREVE_DBG("Configuring SPR_MODE register ...")
	sti	EX_PERV_SPR_MODE_10013281, P0, BIT(3) | BIT(20)
	POREVE_DBG("Configuring SPRC register ...")
	sti	EX_PERV_L0_SCOM_SPRC_10013280, P0, BIT(57)
	POREVE_DBG("Writing RAM_CTRL to execute mfsprd ...")
	sti	EX_PERV_RAM_CTRL_0x10013C01, P0, RAM_CTRL_REG_SCR0_GPR0
	POREVE_DBG("Writing RAM_CTRL to execute mthrmor ...")
	sti	EX_PERV_RAM_CTRL_0x10013C01, P0, RAM_CTL_REG_GPR0_HRMOR
	POREVE_DBG("Disabling RAM_MODE register ...")
	sti	EX_PERV_RAM_MODE_0x10013C00, P0, RAM_MODE_REG_DIS_ALL

set_scratch:

	// set EX scratch0 to XSCOM base address
	POREVE_DBG("Retrieving XSCOM base address ...")
	updatestep STEP_LCO_LOADER_SET_SCRATCH, D0, P1
	lpcs	P1, NEST_CHIPLET_0x02000000
	ld	D0, ADU_XSCOM_BASE_0x02020005, P1

	// keep base address bits 14:22, mask off the rest of the register
	andi	D0, D0, BITS(14,9)

	// write to scratch0 register
	POREVE_DBG("Writing EX SCRATCH0 register with XSCOM BAR (0x%016llX)  ...", io_pore.d0.read())
	std	D0, EX_PERV_SCRATCH0_10013283, P0     

	// set EX scratch1 to unsecure load address + 4KB
	ld	D1, 0x0, A0
	adds	D1, D1, 0x1000
	POREVE_DBG("Writing EX SCRATCH1 register with unsecure address (0x%016llX) ...", io_pore.d1.read())
	std	D1, EX_PERV_SCRATCH1_10013284, P0
        
        // Remove the special wakeup override to allow the core to re-enter
        // power save "nap".  This does NOT influence the PM state machines.
        // Bit 6 enables/disables override; bit 8 controls the Special Wake-up
        sti EX_PMGP1_AND_0x100F0104, P0, ~(BIT(6) | BIT(8))

check_image_size1:

	// load size of image payload in bytes
	updatestep STEP_LCO_LOADER_CHECK_IMAGE, D1, P1
        ld      D0, 0x10, A0

	// determine if running in secure or insecure mode
	// set A0 to point at base address
	// set A1 to point at start of payload
	lpcs	P1, STBY_CHIPLET_0x00000000
	ifbitsetscom D1, D1, OTPC_M_SECURITY_SWITCH_0x00010005, P1, 1, secure_mode

insecure_mode:
	// if insecure, subtract 4KB from size as we will skip container
	POREVE_DBG("Performing load in insecure mode ...")
	subs	D0, D0, 0x1000
	// set A0 to secure load address
	// set A1 to payload
	mr	A1, A0
	adds	A0, A0, 0x8
	adds	A1, A1, (0x1000+0x18)
	bra	check_image_size2

secure_mode:
	// if secure, size is correct as it includes container
	POREVE_DBG("Performing load in secure mode ...")
	// set A0 to insecure load address
	// set A1 to point to container
	mr	A1, A0
	adds	A1, A1, 0x18

check_image_size2:

        // check that the image size in D0 is evenly divisible by cacheline size
        POREVE_DBG("Image size (B) = 0x%016llX", io_pore.d0.read())
        POREVE_DBG("Checking image size is divisible by cacheline size ...")
        andi    D1, D0, BITS(57, 7)
        braz    D1, check_image_size3

        // image is not padded to cacheline alignment, halt
        POREVE_ERR("Image is not evenly divisible by cacheline size ...")
        reqhalt RC_SBE_LCO_LOADER_IMAGE_SIZE_PAD_ERR

check_image_size3:

        // check that the image size will fit into master cache
        POREVE_DBG("Checking image will fit into master cache size ...")
        li      D1, MASTER_CACHE_SIZE
        sub     D1, D0, D1
        tfbule  D1, check_ocb_wrap

        // image is too large to fit in the cache, halt
        POREVE_ERR("Image is larger than master chiplet cache size!")
        reqhalt RC_SBE_LCO_LOADER_IMAGE_SIZE_OVERFLOW_ERR

check_ocb_wrap:

        // initialize loop counter before moving on (shift three as each
        // transfer will move 8B at a time)
	mr	D1, D0
        srdi    D0, D0, 3
        mr      CTR, D0

        // load target base real address
        ld      D0, 0, A0
        POREVE_DBG("Target base real address = 0x%016llX", io_pore.d0.read())

        // check if OCB HW counter wrap will occur based on base real address
        // and image size, D1 will eventually hold last address to be written
        // compute real address of final storage element
        add     D1, D0, D1
        subs    D1, D1, 8
        // OCB HW counter would have wrapped if RA bit 36 changes
        xor     D1, D0, D1
        // mask off all but bit of interest
        andi    D1, D1, BIT(36)
        // halt if bit of interest has changed values
        braz    D1, check_ra_align

        // OCB HW counter will overflow if image load is attempted, halt
        POREVE_ERR("Target base real address/image size will wrap OCB address!")
        reqhalt RC_SBE_LCO_LOADER_IMAGE_WRAP_ERR

check_ra_align:

        // ensure that the base real address is cacheline aligned
        andi    D1, D0, BITS(57, 7)
        braz    D1, reset_pba

        // target base real address is not properly aligned, halt
        POREVE_ERR("Target base address is not cacheline aligned!")
        reqhalt RC_SBE_LCO_LOADER_IMAGE_ALIGN_ERR

reset_pba:

        // reset PBA slave control logic
	updatestep STEP_LCO_LOADER_PREP_STREAM, D1, P1
        POREVE_DBG("Resetting PBA Slave control logic ...");
        // write register to initiate reset
        lpcs    P1, PBA_SLVRST_0x00064001
        // SLVCTL0
        sti     PBA_SLVRST_0x00064001, P1, BIT(0)
        // SLVCTL1
        sti     PBA_SLVRST_0x00064001, P1, BIT(0)|BIT(2)
        // SLVCTL2
        sti     PBA_SLVRST_0x00064001, P1, BIT(0)|BIT(1)
        // SLVCTL3
        sti     PBA_SLVRST_0x00064001, P1, BITS(0,3)

        // SW238936 fix start       
        // save D0, as the cmpibraeq below only can use D0       
        mr      D1, D0  

        // Perform EC check if MPIPL (eg skip if normal IPL)
        // Due to HW228485, skip the check of the in-progress bits for MPIPL 
        // (after the PBA channels have been used at runtime) as they
        // are unreliable in Murano 1.x.
        ifbitclrscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P1, MPIPL_BITNUM, ec_check_complete
               
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P1, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
        cmpibraeq   D0, prep_stream,                (CFAM_CHIP_ID_MURANO    | CFAM_CHIP_ID_MAJOR_EC_1 )

ec_check_complete:  

        // read back register to ensure clean reset
        ld      D0, PBA_SLVRST_0x00064001, P1
        // check that no reset is in progress, and all slave control
	// registers are not busy
        //   4:7  = PBA SLVCTL[0:3] reset in progress (=0b0000)
        //   8:11 = buffers allocated to PBA SLVCTL[0:3] are busy (=0b0000)
        braz    D0, prep_stream

        // PBA slave control did not reset cleanly, halt
        POREVE_ERR("PBA Slave reset still in progress or buffer busy!")
        reqhalt RC_SBE_LCO_LOADER_PBA_RESET_ERR

prep_stream:
        // Restore D0 for original code flow
        mr      D0, D1  
        // SW238936 fix end

        // configure OCB3 Address Register
        //   2:3  = destination PBA SLVCTL => 0b11 (PBA SLVCTL3)
        //   5:28 = real address (37:60) => target base address (37:60)
        POREVE_DBG("Configuring OCB3 Address Register ...")
        // mask appropriate portions of base address (leave bits 37:60)
        mr      D1, D0
        andi    D1, D1, BITS(37, 24)
        // rotate left into final position in register (bits 5:28)
        rols    D1, D1, 32
        // set slave control bits (select SLVCTL3)
        ori     D1, D1, BITS(2, 2)
        // write register
        lpcs    P1, OCB3_ADDRESS_0x0006B070
        std     D1, OCB3_ADDRESS_0x0006B070, P1

        // configure PBA Slave Control Register
        //   28:29 = PB tsize(0:1) => 0b00
        //   30:34 = PB tsize(2:6) => master chiplet LCO ID
        //   35:48 = real address (23:36) extmask => zero (unused)
        POREVE_DBG("Configuring PBA Slave Control Register ...")
        // read L3 Mode Register 1
        //   1:5 = LCO ID of master chiplet
        ld      D1, EX_L3_MODE_REG1_0x1001080A, P0
        // shift right to align with associated tsize bits (30:34)
        srdi    D1, D1, 29
        // mask, leave LCO ID bits only
        andi    D1, D1, BITS(30,5)
        // form final SCOM content (MPIPL)
        // 0     = enable
        // 1:3   = OCI master ID (using master 5)
        // 5:7   = OCI master ID care mask (using all bits)
        // 8:10  = write TTYPE (000 for DMA)
        // 16:17 = read prefetch control (using 01 = none)
        // 19    = write buffer pair allocation
        // 21    = read buffer pair B allocation
        ori     D1, D1, BIT(0)|BIT(1)|BIT(3)|BITS(5,3)|BIT(17)|BIT(19)|BIT(21)
        //Skip tp_chiplet_init1 on MPIPL
        ifbitsetscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P1, MPIPL_BITNUM, mpipl_ttype
        // form final SCOM content (mainline IPL)
        // 8:10  = write TTYPE (001 for LCO)
        ori     D1, D1, BIT(10)
mpipl_ttype:  
        // write register
        std     D1, PBA_SLVCTL3_0x00064007, P1

        // configure PBA Base Address Register
        //   14:36 = real address bits (14:36) => target base address (14:36)
        POREVE_DBG("Configuring PBA Base Address Register ...")
        // load base real address again, keep bits 14:36, mask off the rest
        ldandi  D0, 0, A0, BITS(14, 23)
        // write register
        lpcs    P1, PBA_BAR3_0x02013F03
        std     D0, PBA_BAR3_0x02013F03, P1

        // configure PBA Base Address Mask Register
        //   23:36 = real address bits (23:36) extmask enable => zero (use BAR)
        //   37:43 = real address bits (37:43) extmask enable => 0x7F (use OCB)
        POREVE_DBG("Configuring PBA Base Address Mask Register ...")
        li      D0, BITS(37, 7)
        std     D0, PBA_BARMSK3_0x02013F07, P1

        // branch to main load/store loop (in pibmem)
	updatestep STEP_LCO_LOADER_MAIN_LOOP, D1, P1
	bsria	PORE_SPACE_PIBMEM, _lco_pibmem_start

check_ocb:

	// read/mask/check OCB Status/Control Register
	updatestep STEP_LCO_LOADER_CHECK_STATUS, D1, P1
	lpcs	P1, OCB3_STATUS_CONTROL_0x0006B071
        ldandi  D0, OCB3_STATUS_CONTROL_0x0006B071, P1, OCB3_STATUS_CONTROL_ERR_MASK
        cmpibraeq D0, check_pba_fir, OCB3_STATUS_CONTROL_EXP
        reqhalt RC_SBE_LCO_LOADER_OCB_STATUS_ERR

check_pba_fir:

        // read/mask/check PBA FIR register
        lpcs    P1, PBA_FIR_0x02010840
        ldandi  D0, PBA_FIR_0x02010840, P1, PBA_FIR_ERR_MASK
        cmpibraeq D0, check_pba_wbuf0, PBA_FIR_EXP
        reqhalt RC_SBE_LCO_LOADER_PBA_FIR_ERR

check_pba_wbuf0:

        // read/mask/check PBA write buffer0 status
        ldandi  D0, PBA_WBUFVAL0_0x02010858, P1, PBA_WBUFVAL_ERR_MASK
        cmpibraeq D0, check_pba_wbuf1, PBA_WBUFVAL_EXP
        reqhalt RC_SBE_LCO_LOADER_PBA_WBUF0_ERR

check_pba_wbuf1:

        // read/mask/check PBA write buffer1 status
	ldandi  D0, PBA_WBUFVAL1_0x02010859, P1, PBA_WBUFVAL_ERR_MASK
	cmpibraeq D0, set_secure_bar, PBA_WBUFVAL_EXP
	reqhalt RC_SBE_LCO_LOADER_PBA_WBUF1_ERR

set_secure_bar:

	lpcs	P1, STBY_CHIPLET_0x00000000
	ifbitclrscom D0, D0, OTPC_M_SECURITY_SWITCH_0x00010005, P1, 1, load_done

	// set runtime secure PBA config for master chip
	lpcs    P1, NEST_CHIPLET_0x02000000
	ld	D1, NEST_GP0_0x02000000, P1
	andi	D1, D1, BITS(40, 3)
	// shift to node offset position (bit 18 = 32TB)
	sldi	D1, D1, 24

	POREVE_DBG("Setting PBA BAR for secure mode\n");
	lia	A0, PORE_SPACE_SEEPROM, fabric_config_pba
	ld	D0, 0x00, A0
	add	D0, D0, D1
	POREVE_DBG("Setting PBA BAR3 (=%016llX)...\n", \
                   io_pore.d0.read());
	std     D0, PBA_BAR3_0x02013F03, P1

load_done:
	
	lpcs	P1, NEST_CHIPLET_0x02000000
	lia	A0, PORE_SPACE_SEEPROM, fabric_config_pba
	ld	D0, 0x08, A0
	POREVE_DBG("Setting PBA BAR3 Mask (=%016llX)...\n", \
                   io_pore.d0.read());
	std     D0, PBA_BARMSK3_0x02013F07, P1
        .end_procedure proc_sbe_lco_loader
