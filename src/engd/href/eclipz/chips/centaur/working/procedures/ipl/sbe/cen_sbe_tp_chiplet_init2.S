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
// constant declaration for FAPI HOOKs
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// preprocessor directives
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .pnor

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Constant Definitions
//------------------------------------------------------------------------------
        // Constants used for poll timeouts
        .set MAX_FLUSH_LOOPS, 400
        .set FLUSH_DELAY, 20000
        .set CLOCK_START_REGIONS_pibnet,	0x46000E0000000000
        .set EXPECTED_CC_STATUS_START_pibnet,	0xE07FFFFFFFFFFFFF

        // Constants to recognize and convert MC-write to MC-read
        .set MULTI_CAST_PATTERN,     0x0000000000000078
        .set MULTI_CAST_COMPARE,     0x0000000000000068
        .set MULTI_CAST_WAIT_WR,     0x000000000000005F

        // constants for Repair Loader Status Register polling
        // stop polling and check status if (status AND MASK) XOR EXP != 0
        // need to monitor these fields after each poll as they clear on each read:
        //   2: repair done
        //   5: PIB parity check
        //   22:24: PIB master response information
        // also check for state of:
        //   0: busy
        .set    REPAIR_STATUS_POLL_MASK, 0xA400038000000000
        .set    REPAIR_STATUS_POLL_BUSY1, 0xA000000000000000
        .set    REPAIR_STATUS_POLL_BUSY2, 0x8000000000000000
        // 1ms @ 600 MHz
        .set    REPAIR_DELAY_HW, 0x927C0
        .set    REPAIR_MAX_POLL_LOOPS, 100 

        // constants for Repair Loader Status Register checking
        .set    REPAIR_STATUS_CHECK_MASK, 0xA6FFFF8000000000
        .set    REPAIR_STATUS_CHECK_EXP, 0x2080000000000000

        // constants for Repair Loader ECC Trap Register checking
        .set    REPAIR_ECC_TRAP_MASK, 0x0F00300000000000
        .set    REPAIR_ECC_TRAP_EXP, 0x0000300000000000

	// Repair Loader invocation constants
	.set REPAIR_COMMAND_VALIDATION_ENTRIES, 0x010  // control word 7
	.set REPAIR_COMMAND_START_ADDRESS, 0x27F     

	// Procedure Progress Step Definitions
        .set STEP_INIT2_SCAN0_DONE,	0x1
        .set STEP_PIBNET_RUNING,	0x2
        .set STEP_START_REPAIR,	        0x3


//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------
        // SCAN0 module
        //
        // At entry:
        //
        //    P1 : The chiplet ID
        //    D0 : The clock regions (Clock Controller, Clock Region Register)
        //    D1 : The scan selects  (Clock Controller, Scan Select Register)
        //
        // At exit:
        //
        //    P0, D0, D1, CTR  : destroyed
        //    P1, A0, A1       : maintained

        .subroutine cen_scan0_module, cen, "$Revision"
        POREVE_INF( "<scan0> : *** Subroutine SCAN0 was called ***")

        POREVE_INF( "<scan0> : Setting up Clock Regions according to "
                   "D0: 0x%016llX", io_pore.d0.read() )
        std     D0, GENERIC_CLK_REGION_0x00030006, P1

        POREVE_INF( "<scan0> : Setting up Scan Selects according to "
                   "D1: 0x%016llX", io_pore.d1.read() )
        std     D1, GENERIC_CLK_SCANSEL_0x00030007, P1

        POREVE_INF( "<scan0> : Clear OPCG_CNTL0 REG BIT(0)" )
        bci     D0, GENERIC_OPCG_CNTL0_0x00030002, P1, BIT(0)

        // If P1 is a multicast write group, set P0 to the matching AND-combine
        // read group, otherwise simply set P0 = P1. Polling uses P1 as chiplet ID
        mr      D0, P1
        mr      P0, P1
        andi    D0, D0, MULTI_CAST_PATTERN
        cmpibrane D0, cen_osm_start, MULTI_CAST_COMPARE

        POREVE_INF( "<scan0> : *INFO* This is a multicast SCAN0 *INFO* ")
        POREVE_INF( "<scan0> : Setting OPCG_CNTL0 run BIT(2) for scan0 to start; also set scan ratio 16:1" )
        bsi     D0, GENERIC_OPCG_CNTL0_0x00030002, P1, BIT(2)|BITS(5, 4)|BITS(12, 2)	// 218C0000
        mr      D0, P1
        andi    D0, D0, MULTI_CAST_WAIT_WR
        mr      P0, D0
        bra 	cen_osm_poll

cen_osm_start:
        POREVE_INF( "<scan0> : Setting OPCG_CNTL0 run BIT(2) for scan0 to start" )
        bsi     D0, GENERIC_OPCG_CNTL0_0x00030002, P1, BIT(2)


cen_osm_poll:

        POREVE_INF( "<scan0> : Start polling for SCAN0 complete ...")
        pollbitset D1, GENERIC_GP1_0x00000001, P0, 15, \
                   MAX_FLUSH_LOOPS, FLUSH_DELAY, cen_osm_poll_failed

        bra     cen_osm_poll_done
        
cen_osm_poll_failed:
        POREVE_ERR( "<scan0> : ERROR: Gave up waiting for OPCG done bit(15)='1'.");
        reqhalt RC_MSS_INIT1_OPCG_DONE_ERROR

cen_osm_poll_done:

        POREVE_INF( "<scan0> : SCAN0 completed, clear Clock Regions and Scan Selects")
        sti     GENERIC_CLK_REGION_0x00030006, P1, 0x0
        sti     GENERIC_CLK_SCANSEL_0x00030007, P1, 0x0

        POREVE_INF( "<scan0> : *** Subroutine SCAN0 ends *** ")

        .end_subroutine cen_scan0_module


	//----------------------------------------------------------------------
	// cen_repair_loader
	//----------------------------------------------------------------------
	// Invoke Centaur repair loader
	// Assumes: A0 contains Command Validation Register bits 0:15 (repair
	//            command entries to process, right aligned in register)
	//          A1 contains Command Register bits 4:15 (start address
	//            of first repair control word entry in OTPROM, right
	//            aligned in register)
	// CTR, P0, P1, D0, D1 are destroyed, all other registers are preserved
	//----------------------------------------------------------------------

	.subroutine cen_repair_loader, cen , "$Revision"

	POREVE_INF("<repair_loader>: Start")

	// initialize pervasive base registers
	lpcs	P0, STBY_CHIPLET_0x00000000
	lpcs	P1, TP_CHIPLET_0x01000000

	// read OTPROM to see if repair loader should be called
	POREVE_DBG("<repair_loader>: Reading OTPROM to determine if repair loader should be run")
	ifbitclrscom D0, D0, ECID_PART_1_0x00010001, P0, 0, repair_loader_done

	// check that repair loader is idle before starting operation
	POREVE_DBG("<repair_loader>: Reading Status Register to verify engine is idle...")
	ifbitsetscom D0, D0, CEN_READ_ARRAY_REPAIR_STATUS_0x00050003, P0, 0, repair_loader_not_idle_err
	bra	repair_loader_start

repair_loader_not_idle_err:
        POREVE_ERR("<repair_loader>: Repair loader reports busy, but engine should be idle!");
        reqhalt RC_CEN_SBE_REPAIR_LOADER_BUSY_ERR

repair_loader_start:
        // write command validation register with repair loader control entries to process
	POREVE_DBG("<repair_loader>: Writing Command Validation Register");
	mr	D0, A0
	sldi	D0, D0, 52
	std	D0, CEN_WRITE_ARRAY_REPAIR_CMD_0x00050002, P0

	// write commmand register to kick off repair engine
	POREVE_DBG("<repair_loader>: Writing Command Register to start engine");
        // load argument
        mr	D0, A1
	andi	D0, D0, BITS(52,12)
	sldi	D0, D0, 48

	ori	D0, D0, BIT(2)
	std	D0, CEN_WRITE_ARRAY_REPAIR_REG_0x00050000, P0

	// poll for repair loader to finish
	li	CTR, REPAIR_MAX_POLL_LOOPS
	bra	repair_loader_loop_end

repair_loader_loop_begin:
	// pause between polls (smaller delay in sim only)
	POREVE_DBG("<repair_loader>: Pausing before status poll...")
        ##@ fapi::ReturnCode rc;
        ##@ uint8_t is_simulation = 0;
        ##@ rc = FAPI_ATTR_GET(ATTR_IS_SIMULATION, NULL, is_simulation);
        ##@ if (!rc.ok())
        ##@ {
        ##@     return rc;
        ##@ }
        ##@ if (is_simulation)
        ##@ {
        ##@     rc = fapiDelay(0, 0x30D40);
        ##@     if (!rc.ok())
        ##@     {
        ##@         return rc;
        ##@     }
        ##@     io_pore.forceBranch("pnor::repair_loader_loop_sim");
        ##@ }
        ##@ return hookOk;
	waits   REPAIR_DELAY_HW

        .global repair_loader_loop_sim
repair_loader_loop_sim:
	// retreive current status
	POREVE_DBG("<repair_loader>: Polling repair loader Status Register...")
	ld	D0, CEN_READ_ARRAY_REPAIR_STATUS_0x00050003, P0

	// stop/check if status is not clean or engine finishes
        // check for first acceptable busy pattern (done+busy)
	mr	D1, D0
	andi	D1, D1, REPAIR_STATUS_POLL_MASK
	xori	D1, D1, REPAIR_STATUS_POLL_BUSY1
	braz	D1, repair_loader_loop_end

        // check for second acceptable busy pattern (done)
	mr	D1, D0
	andi	D1, D1, REPAIR_STATUS_POLL_MASK
	xori	D1, D1, REPAIR_STATUS_POLL_BUSY2
	braz	D1, repair_loader_loop_end

        // status does not match any expected busy patern
	bra	repair_loader_check_status

repair_loader_loop_end:
	// decrement counter & repeat if counter is non-zero
	// otherwise fall through and halt
	loop	repair_loader_loop_begin

repair_loader_poll_timeout:
	// loop counter has expired with no change in relevant status fields, give up
	POREVE_ERR("<repair_loader>: Timed out waiting for repair loader to finish!");
	reqhalt	RC_CEN_SBE_REPAIR_LOADER_NOT_DONE_ERR

repair_loader_check_status:
	// status field(s) being monitored has changed, check that repair
	// loader has reached expected state
	POREVE_DBG("<repair_loader>: Checking repair loader status...");
        POREVE_DBG("<repair_loader>:   BUSY             = 0b%d", io_pore.d0.isBitSet(0))
	POREVE_DBG("<repair_loader>:   REPAIR DONE      = 0b%d", io_pore.d0.isBitSet(2))
  	POREVE_DBG("<repair_loader>:   PIB PARITY CHECK = 0b%d", io_pore.d0.isBitSet(5))
  	POREVE_DBG("<repair_loader>:   FSM ERROR        = 0b%d", io_pore.d0.isBitSet(6))
  	POREVE_DBG("<repair_loader>:   ECC ERROR        = 0b%d", io_pore.d0.isBitSet(7))
  	POREVE_DBG("<repair_loader>:   FSM STATE        = 0x%04llX", io_pore.d0.extractToRight(8, 14))
  	POREVE_DBG("<repair_loader>:   PIB MASTER RESP  = 0x%01llX", io_pore.d0.extractToRight(22, 3))
	mr	D1, D0
	andi	D0, D0, REPAIR_STATUS_CHECK_MASK
        cmpibraeq D0, repair_loader_check_ecc, REPAIR_STATUS_CHECK_EXP

repair_loader_status_error:
	POREVE_ERR("<repair_loader>: Mismatch in expected repair loader status!");
	reqhalt RC_CEN_SBE_REPAIR_LOADER_STATUS_ERR

repair_loader_check_ecc:
	// check that ECC trap register has reached expected state
        ld	D0, CEN_READ_ECC_TRAP_REGISTER_0x00050004, P0
	POREVE_DBG("<repair_loader>: Checking ECC Trap Register status...");
        POREVE_DBG("<repair_loader>:   CE NUMBER              = 0x%01llX", io_pore.d0.extractToRight(0, 4))
        POREVE_DBG("<repair_loader>:   UE NUMBER              = 0x%01llX", io_pore.d0.extractToRight(4, 4))
        POREVE_DBG("<repair_loader>:   FIRST ERR SYNDROME     = 0x%02llX", io_pore.d0.extractToRight(9, 7))
        POREVE_DBG("<repair_loader>:   ECC DATA CORRECTION EN = 0b%d", io_pore.d0.isBitSet(18))
        POREVE_DBG("<repair_loader>:   ADDRESS CHECKING EN    = 0b%d", io_pore.d0.isBitSet(19))
        POREVE_DBG("<repair_loader>:   FIRST ERR ADDRESS      = 0x%03llX", io_pore.d0.extractToRight(22, 10))
	mr	D1, D0
	andi	D0, D0, REPAIR_ECC_TRAP_MASK
	cmpibraeq D0, repair_loader_done, REPAIR_ECC_TRAP_EXP

repair_loader_ecc_error:
        POREVE_ERR("<repair_loader>: ECC trap register reported error!");
        reqhalt RC_CEN_SBE_REPAIR_LOADER_ECC_TRAP_ERR

repair_loader_done:
	POREVE_INF("<repair_loader>: Done");
	.end_subroutine cen_repair_loader


	
//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure cen_sbe_tp_chiplet_init2, cen, "$Revision: 1.34 $"


        POREVE_INF( "*** Scan Initialization of Pervasive Chiplet (SCAN0 and Scan Repair) ***")

        // call cen_scan0_module( CHIPLET_TP, ALLREGIONEXVITAL, GPTR_TIME_REP )
        ls      P1, SCAN_CHIPLET_TP
        li      D0, SCAN_CLK_ALL_BUT_PLL	  // 0x0FE00E00 bit 4-10,20-22     => 0x01030006
        li      D1, SCAN_GPTR_TIME_REP_NO_PLL     // 0x0FE00230 bit 4-10,22,26-27  => 0x01030007
        bsr     cen_scan0_module

        // call cen_scan0_module( CHIPLET_TP, ALLSCANEXPRV )
        ls      P1, SCAN_CHIPLET_TP
        li      D0, SCAN_CLK_ALL_BUT_PLL          // 0x0FE00E00 bit 4-10,20-22     => 0x01030006
        li      D1, SCAN_ALL_BUT_VITALPLLGPTRTIME // 0x0FE00DCE bit 4-10,20-21,23-25,28-30  => 0x01030007
        bsr     cen_scan0_module

        // Update SBE VITAL register
        updatestep STEP_INIT2_SCAN0_DONE, D0, P1

///////////////////////////////////////////////////////
//           SBE Address Base Register Setups
///////////////////////////////////////////////////////
        // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

        // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P1, TP_CHIPLET_0x01000000

///////////////////////////////////////////////////////
//           Clock Start (PIB, NET)
///////////////////////////////////////////////////////

        POREVE_INF( "Clock Start command (PIB, NET only)." )    // 0x46000E0000000000
        sti     TP_CLK_REGION_0x01030006, P1, CLOCK_START_REGIONS_pibnet

        // Read Clock Status Register, check tholds
        ld      D0, TP_CLK_STATUS_0x01030008, P1
        xori    D1, D0, EXPECTED_CC_STATUS_START_pibnet		// 0xE07FFFFFFFFFFFFF
        branz   D1, error_clock_start

        POREVE_INF( "PIB, NET running now." )

        // Update SBE VITAL register
        updatestep STEP_PIBNET_RUNING, D0, P1
        bra     next_init1

error_clock_start:
        POREVE_ERR( "ERROR: Clock Control Register: 0x%016llX does "
                    "not match the expected value: 0xE07FFFFFFFFFFFFF",
                    io_pore.d1.read() )
        reqhalt RC_MSS_THOLD_ERROR

next_init1:
        POREVE_INF( "Assert PCB reset" )
        bsi     D0, MBOX_FSIGP3_0x00050012, P0, BIT(22)

        POREVE_INF( "PIB2PCB switch mux, set to operational" )
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(20)

        POREVE_INF( "Deassert PCB reset" )
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(22)

        POREVE_INF( "Drop global_ep_reset signal" )
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(31)

        POREVE_INF( "Switch Pervasive Chiplet OOB Mux" )
        bci     D0, MBOX_FSIGP3_0x00050012, P0, BIT(21)

///////////////////////////////////////////////////////
//           Repair Loader (TP)
///////////////////////////////////////////////////////

	POREVE_INF("Invoking repair loader...")
        updatestep STEP_START_REPAIR, D0, P1
	li	A0, REPAIR_COMMAND_VALIDATION_ENTRIES
	li	A1, REPAIR_COMMAND_START_ADDRESS
	bsr	cen_repair_loader

        POREVE_INF( "*** End of procedure ***" )
        .end_procedure cen_sbe_tp_chiplet_init2
