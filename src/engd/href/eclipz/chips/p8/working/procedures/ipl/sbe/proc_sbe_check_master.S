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
#include "proc_sbe_check_master.H"
#include "proc_sbe_enable_pnor.H"
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

	.set CHECK_MASTER_OVERRIDE, 0x000000000000001

	.set SLAVE_CHIP, 0x000000000000000
	.set MASTER_CHIP_OVERRIDE, 0x000000000000001
	.set MASTER_CHIP, 0x000000000000002

        .set PRIMARY_NODE_MASTER_HBI_BOOT_PATTERN,    0x0000000000000000       // SBE_VITAL(10) = 0b0, chip ID = 0b00, chip pos = 0b0
        .set ALTERNATE_NODE_MASTER_HBI_BOOT_PATTERN,  0x0020000002000000       // SBE_VITAL(10) = 0b1, chip ID = 0b01, chip pos = 0b0

	.set MCS1_SCOM_OFFSET, 0x080
	.set MCS4_SCOM_OFFSET, 0x400
	.set MCS5_SCOM_OFFSET, 0x480
        .set MPIPL_BITNUM, 0

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

     // check_master subroutine
     //
     // At entry:
     //
     //    A0: Procedure control field address
     //    D0: Examine procedure control field for override?
     //          No: 0x0
     //          Yes: 0x1 (non-zero)
     //
     // At exit:
     //
     //    D0: Contains master indication
     //          Slave : SLAVE_CHIP constant (0x0)
     //          No EX : SLAVE_CHIP constant (0x0)
     //          Master (override) : MASTER_CHIP_OVERRIDE constant (0x1)
     //          Master (real):	 MASTER_CHIP constant (0x2)
     //
     //    P0, A0, A1 : maintained
     //    P1, D1, CTR : destroyed
     //

       .subroutine check_master_module, ipl, "$Revision"
        POREVE_INF("<subroutine: check_master> : *** Subroutine check_master was called ***\n")

     // Save state of override query input
	mr	CTR, D0

cmsr_check_hw:
     // Always check state of HW
     // Setup PRV_BASE_ADDR0; points to PIB
	lpcs    P1, STBY_CHIPLET_0x00000000

     // Read SBE_VITAL node master bit
        POREVE_INF("<subroutine: check_master> : Reading SBE_VITAL node master bit ...\n")
        ldandi  D0, MBOX_SBEVITAL_0x0005001C, P1, BIT(10)

     // Read PCB master chip id register to identify chip id and position
        POREVE_INF("<subroutine: check_master> : Reading chip id and position ...\n")
        ldandi  D1, PCBMS_DEVICE_ID_0x000F000F, P1, BITS(36, 4)

     // Combine node master bit, chip position and chip id to a combined pattern
        or      D0, D0, D1

     // Check for node master or alternate node master HBI boot pattern
        cmpibraeq   D0, cmsr_is_master, PRIMARY_NODE_MASTER_HBI_BOOT_PATTERN
        cmpibraeq   D0, cmsr_is_master, ALTERNATE_NODE_MASTER_HBI_BOOT_PATTERN

cmsr_is_slave:
     // Detected to be slave
        POREVE_INF("<subroutine: check_master> : Detected to be slave ... \n")
	li	D0, SLAVE_CHIP
     // if no cores present, treat as slave regardless of master override
	lpcs    P1, ALL_EXS_BITX_0x51000000
	ld      D1, GENERIC_GP3_0x000F0012, P1
	braz	D1, cmsr_exit
     // If not instructed to check procedure control field override, exit
	POREVE_INF("<subroutine: check_master>:	%s master override check ...\n", \
		   (io_pore.ctr.read() == 0)?("Skipping"):("Performing")) ;
	braz	CTR, cmsr_exit

cmsr_check_override:
     // Otherwise, check if we should always consider ourselves as master
     // via override
	ldandi	D1, 0, A0, PROC_CONTROL_INIT_ALL_EX
        POREVE_INF("<subroutine: check_master> : Master override IS %sset ...\n", \
	           (io_pore.d1.read() == 0)?("NOT "):(""));
	braz	D1, cmsr_exit
	li	D0, MASTER_CHIP_OVERRIDE
	bra	cmsr_exit

cmsr_is_master:
     // Detected to be master
        POREVE_INF("<subroutine: check_master> : Detected to be master ... \n")
	li	D0, MASTER_CHIP

     // if no cores present, fail unless running via virtual SBE
	lpcs    P1, ALL_EXS_BITX_0x51000000
	ld      D1, GENERIC_GP3_0x000F0012, P1
     // permit virtual boot with no cores, treat as slave chip
	##@fapi::ReturnCode rc;
	##@if (io_pore.d1.read() == 0) {
	##@  FAPI_INF("<subroutine: check_master> : Master with no cores, treating as slave chip\n");
	##@  io_pore.d0 = 0;
	##@  io_pore.forceBranch("seeprom::cmsr_exit");
	##@}
	##@return hookOk;
	branz	D1, cmsr_exit

	POREVE_ERR("<subroutine: check_master> Unable to find a good core to boot with\n" )
	reqhalt RC_SBE_SELECT_EX_NO_GOOD_BOOT_CORES_FOUND

	.global cmsr_exit
cmsr_exit:
       POREVE_INF("<subroutine: check_master> : *** Subroutine check_master ends ***\n")

        .end_subroutine check_master_module


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_check_master, ipl, "$Revision: 1.34 $"
        POREVE_INF("<proc_sbe_check_master> : Identify Node Master chip ...\n")

cm_start:

// ********************************************************
// **         Check Master status                        **
// ********************************************************

     // Call subroutine to determine master status
	li	D0, CHECK_MASTER_OVERRIDE
	bsr     check_master_module
	cmpibraeq D0, cm_boot_hbi, MASTER_CHIP
	cmpibraeq D0, cm_done, MASTER_CHIP_OVERRIDE

// ********************************************************
// **    Slave Chip ...                                  **
// ********************************************************

     // otherwise, if none of the HBI boot patterns matched, we must be a slave chip
     // if running on real SBE HW:
     //   enable LPC for chip if capable of PNOR access
     //   if security is enabled OR mailbox bit indicates to start slave scan service
     //     branch into slave scan service loop
     //   else
     //     halt
     // else halt
	##@ FAPI_INF("SKIPPING alt-master LPC enable and scan service loop\n");
	##@ io_pore.forceBranch("seeprom::cm_slave_stop");
	##@ return hookOk;
	lpcs	P0, PCBMS_DEVICE_ID_0x000F000F
	ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P0, BITS(36, 4)
	cmpibraeq D0, cm_slave_enable_lpc, 0x0000000000000000 // this chip is primary socket, alternate master in use
	cmpibraeq D0, cm_slave_enable_lpc, 0x0000000002000000 // this chip is alternate socket, primary master in use
	bra	cm_slave_check_scan_service
cm_slave_enable_lpc:
	bsr	enable_lpc_module

cm_slave_check_scan_service:
     // check state of security -- if in secure mode, jump to scan service routine
	ifbitsetscom D0, D0, OTPC_M_SECURITY_SWITCH_0x00010005, P0, 1, cm_slave_run_scan_service
     // check mailbox to determine if option is set to run scan service routine in insecure mode
        ifbitsetscom D0, D0, MBOX_SCRATCH_REG3_0x0005003B, P0, 24,  cm_slave_run_scan_service
     // otherwise, halt
	bra	cm_slave_stop

cm_slave_run_scan_service:
     // branch into routine which services scan requests, never return
	braia	PORE_SPACE_SEEPROM, proc_sbe_scan_service

	.global cm_slave_stop
cm_slave_stop:
     // set SBE Vital to the magic number HB looks for
	lpcs	P0, MBOX_SBEVITAL_0x0005001C
	sti     MBOX_SBEVITAL_0x0005001C, P0, ((PROC_SBE_CHECK_MASTER_MAGIC_ISTEP_NUM << 4) | SUBSTEP_CHECK_MASTER_SLAVE_CHIP) << 32

     // re-enable the CFAM I2C master 
	POREVE_INF("<proc_sbe_check_master> : This is a slave chip ... restoring CFAM I2CM and stopping SBE as we are done.\n")
        bci     D0, MBOX_FSIGP4_0x00050013, P0, BIT(20)
        
     // Cronus doesn't know that the slave chips are done, so just loop on the reqhalt
        .global cm_slave_loop
cm_slave_loop:
        reqhalt RC_SBE_SUCCESS_SLAVE_CHIP, D0, P0
        bra     cm_slave_loop


// ********************************************************
// **    Master Chip: Continue to boot HBI ...           **
// ********************************************************

cm_boot_hbi:

     // Continue to boot HBI
        POREVE_INF("<proc_sbe_check_master> : This is the master chip . continuing to boot HBI ...\n")
        updatestep SUBSTEP_CHECK_MASTER_MASTER_CHIP, D1, P0

     // if cache-contained, skip init of MCS BARs
	ldandi	D1, 0, A0, PROC_CONTROL_CACHE_CONTAINED
        POREVE_INF("<proc_sbe_check_master> : Cache contained mode IS %sset ...\n", \
	           (io_pore.d1.read() == 0)?("NOT "):(""));
	branz	D1, cm_done

     // if MPIPL, skip init of MCS BARs
        ifbitsetscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, cm_done

     // calculate MCFGP base address, shift node ID into proper portion of base
     // address field (offset drawer address space by 32 TB per drawer)
	lpcs    P1, NEST_CHIPLET_0x02000000
	ld	D0, NEST_GP0_0x02000000, P1
	mr	D1, D0
	andi	D1, D1, BITS(40, 3)
	POREVE_DBG("<proc_sbe_check_master> : Read drawer ID (=%llX) ...\n", \
	           io_pore.d1.extractToRight(40, 3))

     // MCFGP bits 26:43 = RA bits 14:31 (bit 30 of MCFGP is equivalent to 32 TB)
	sldi	D1, D1, 12

     // D1 now contains base address aligned to MCFGP register definition
     // OR in remaining configuration:
     // o  valid bit to enable BAR match logic
     // o  set two units per group
     // o  enable RCMD0/RCMD1
     // o  set 8GB group size (each MCS will cover 4GB)
     // o  enable fastpath function
	ori     D1, D1, BIT(0) | BIT(3) | BITS(9,2) | BITS(23,3)

     // use GP0 partial good fence bits to determine available MCS resource

     // check MCR fence bit (52, active-low), in the all good case this will
     // result in the same selection of MCS4/5 for both Venice/Murano
	andi	D0, D0, BIT(52)
	branz	D0, cm_write_regs_mcr

     // if MCR fenced, check MCL fence bit (51, active-low) to use MCSO/1
	ld	D0, NEST_GP0_0x02000000, P1
	andi	D0, D0, BIT(51)
	branz	D0, cm_write_regs_mcl

     // both MCR/MCL are fenced, halt
	POREVE_ERR("<proc_sbe_check_master> : Both MCL/MCR fences are asserted!\n")
	reqhalt	RC_SBE_CHECK_MASTER_NO_VALID_MCS

cm_write_regs_mcl:

     // disable speculative reads in MCSMODE1 register (set bits 31:48)
	POREVE_DBG("<proc_sbe_check_master> : Writing MCS0 MCSMODE1 register ...\n")
	bsi	D0, MCS_MCSMODE1_0x02011808, P1, BITS(31, 18)

	POREVE_DBG("<proc_sbe_check_master> : Writing MCS1 MCSMODE1 register ...\n")
	bsi	D0, MCS_MCSMODE1_0x02011808 + MCS1_SCOM_OFFSET, P1, BITS(31, 18)

     // write MCIFIRMASK AND Mask registers, enable error reporting for
     // command list timeout due to DMI channel
	POREVE_DBG("<proc_sbe_check_master> : Writing MCS0 MCIFIRMASK AND Mask register ...\n")
	li	D0, ~(BIT(27) | BIT(40))
	std	D0, MCS_MCIFIRMASK_AND_0x02011844, P1

	POREVE_DBG("<proc_sbe_check_master> : Writing MCS1 MCIFIRMASK AND Mask register ...\n")
	std	D0, MCS_MCIFIRMASK_AND_0x02011844 + MCS1_SCOM_OFFSET, P1

     // write MCFGP registers
	POREVE_DBG("<proc_sbe_check_master> : Writing MCS0 MCFGP register ...\n")
	std	D1, MCS_MCFGP_0x02011800, P1

     // set group member ID = 1
	POREVE_DBG("<proc_sbe_check_master> : Writing MCS1 MCFGP register ...\n")
	ori	D1, D1, BIT(8)
	std	D1, MCS_MCFGP_0x02011800 + MCS1_SCOM_OFFSET, P1
	bra	cm_done

cm_write_regs_mcr:

     // disable speculative reads in MCSMODE1 register (set bits 31:48)
	POREVE_DBG("<proc_sbe_check_master> : Writing MCS4 MCSMODE1 register ...\n")
	bsi	D0, MCS_MCSMODE1_0x02011808 + MCS4_SCOM_OFFSET, P1, BITS(31, 18)

	POREVE_DBG("<proc_sbe_check_master> : Writing MCS5 MCSMODE1 register ...\n")
	bsi	D0, MCS_MCSMODE1_0x02011808 + MCS5_SCOM_OFFSET, P1, BITS(31, 18)

     // write MCIFIRMASK AND Mask registers, enable error reporting for
     // command list timeout due to DMI channel
	POREVE_DBG("<proc_sbe_check_master> : Writing MCS4 MCIFIRMASK AND Mask register ...\n")
	li	D0, ~(BIT(27) | BIT(40))
	std	D0, MCS_MCIFIRMASK_AND_0x02011844 + MCS4_SCOM_OFFSET, P1

	POREVE_DBG("<proc_sbe_check_master> : Writing MCS5 MCIFIRMASK AND Mask register ...\n")
	std	D0, MCS_MCIFIRMASK_AND_0x02011844 + MCS5_SCOM_OFFSET, P1

     // write MCFGP registers
	POREVE_DBG("<proc_sbe_check_master> : Writing MCS4 MCFGP register ...\n")
	std	D1, MCS_MCFGP_0x02011800 + MCS4_SCOM_OFFSET, P1

     // set group member ID = 1
	POREVE_DBG("<proc_sbe_check_master> : Writing MCS5 MCFGP register ...\n")
	ori	D1, D1, BIT(8)
	std	D1, MCS_MCFGP_0x02011800 + MCS5_SCOM_OFFSET, P1

cm_done:
	lpcs    P0, STBY_CHIPLET_0x00000000
	
     // install custom interrupt service delay time into PIBMEM
	lia     A0, PORE_SPACE_SEEPROM, intr_decrementer_delay_us
	ld      D0, 0, A0
	std	D0, proc_sbe_intr_service_delay_us, P0

     // install custom interrupt service decrementer delay into PIBMEM
	lia	A0, PORE_SPACE_SEEPROM, intr_decrementer_delay_cycles
	ld	D0, 0, A0
	andi	D0, D0, BITS(40,24)
     // do NOT update the PIBMEM if the SEEPROM fixed section is uncustomized
     // this will result in a halt instruction instead of a wait ;)
	braz	D0, cm_skip_intr_update
	ld	D1, proc_sbe_intr_service_pibmem_loop, P0
	andi	D1, D1, BITS(0,40)
	or	D1, D0, D1
	std	D1, proc_sbe_intr_service_pibmem_loop, P0
cm_skip_intr_update:
        .end_procedure proc_sbe_check_master
