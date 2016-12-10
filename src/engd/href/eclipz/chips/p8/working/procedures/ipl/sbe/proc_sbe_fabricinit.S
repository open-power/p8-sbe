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

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Constant Defintions
//------------------------------------------------------------------------------

	// procedure progress codes
	.set	STEP_FABRICINIT_CHECK_FBC_STOP, 0x1
	.set	STEP_FABRICINIT_FBC_STOP_CLEAR, 0x2
	.set	STEP_FABRICINIT_ADU_LOCK_HELD, 0x3
	.set	STEP_FABRICINIT_FBC_INIT_OP_ISSUED, 0x4
	.set	STEP_FABRICINIT_FBC_INIT_OP_PASS, 0x5
	.set	STEP_FABRICINIT_ADU_LOCK_RELEASED, 0x6

        // procedure flow constants
        // number of SBE cycles to pause waiting for init op to complete
        .set    FABRICINIT_DELAY_CYCLES, 100

        // ADU Status Register error mask/expected values
        .set    ADU_STATUS_ERR_MASK, 0xFFFFFFFFFFFFFFFF
        //   2 = FBC_altd_Addr_Done => 0b1 (address phase done)
        //   18 = FBC_altd_pbinit_missing => 0b1 (cmd sent w/ init low)
  	//   59:63 = completion cresp => 0b00100 (ack_done)
        .set    ADU_STATUS_EXP, 0x2000200000000004

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_fabricinit, ipl, "$Revision: 1.11 $"

        // read ADU pMisc Mode register
	updatestep STEP_FABRICINIT_CHECK_FBC_STOP, D0, P0
        POREVE_DBG("Checking state of tc_pb_stop ...\n")
	lpcs    P1, NEST_CHIPLET_0x02000000
        ld      D0, ADU_PMISC_MODE_0x0202000B, P1

        // check state of FBC pervasive stop control signal which if set would
        // prohibit fabric commands from being broadcast
        // ADU pMisc Mode Register
        //   22 = pb_stop
        POREVE_DBG("tc_pb_stop = 0b%d\n", io_pore.d0.isBitSet(22))
        ifbitclr D0, D0, 22, set_lock

        // pervasive stop control bit is set, halt
        POREVE_ERR("tc_pb_stop is set, so proc_sbe_fabricinit will not run!\n")
        POREVE_ERR("Check fircheck output for system checkstop!\n")
        reqhalt RC_SBE_FABRICINIT_FBC_STOPPED_ERR

set_lock:

	updatestep STEP_FABRICINIT_FBC_STOP_CLEAR, D0, P0
        // write ADU Command Register to attempt lock acquisition
        // SCOM will fail if lock acquisition is unsuccessful
        //   11 = FBC_locked = 0b1  (acquire lock)
        POREVE_DBG("Acquiring ADU lock ...\n")
        sti     ADU_COMMAND_0x02020001, P1, BIT(11)

        // write ADU Command Register to clear ADU Status register
        // and reset ADU state machine
        //   3 = FBC_altd_Clear_Status => 0b1 (clear status reg)
        //   4 = FBC_altd_Reset_AD_PCB => 0b1 (reset state machine)
        //   11 = FBC_locked => 0b1  (hold lock)
	updatestep STEP_FABRICINIT_ADU_LOCK_HELD, D0, P0
        POREVE_DBG("Lock acquired!\n")
        POREVE_DBG("Performing ADU reset/clear ...\n")
        sti     ADU_COMMAND_0x02020001, P1, BITS(3, 2) | BIT(11)

        // program ADU Control/Command Registers to issue init command
        POREVE_DBG("Issuing fabric init command via ADU ...\n")
        // ADU Control Register
        //   0:5 = FBC_altd_ttype => 0x3F (pbop)
        //   7:13 = FBC_altd_tsize => 0x0B (en_all, MC FP enable)
        sti     ADU_CONTROL_0x02020000, P1, BITS(0, 6) | BIT(10) | BITS(12, 2)
        // ADU Command Register
        //   2 = FBC_altd_Start_Op => 0b1 (start cmd)
        //   6 = FBC_altd_axtype => 0b1 (address only)
        //   11 = FBC_locked => 0b1 (hold lock)
        //   16:18 = FBC_altd_scope => 0x2   (system)
        //   20:21 = FBC_altd_drop_priority => 0b10 (high priority)
        //   23 = FBC_altd_overwrite_pbinit => 0b1 (send cmd w/ init low)
        sti     ADU_COMMAND_0x02020001, P1, BIT(2)  | BIT(6)  | BIT(11) | \
                                            BIT(17) | BIT(20) | BIT(23)

        // pause for small delay to allow init operation to finish
	updatestep STEP_FABRICINIT_FBC_INIT_OP_ISSUED, D0, P0
        POREVE_DBG("Delaying to allow fabric init command to complete ...\n")
        waits   FABRICINIT_DELAY_CYCLES

        // read ADU Status Register
        POREVE_DBG("Reading ADU status register ...\n")
        ld      D0, ADU_STATUS_0x02020002, P1

        // compare with expected value
        POREVE_DBG("  FBC_ALTD_BUSY                  = 0b%d\n", io_pore.d0.isBitSet(0))
	POREVE_DBG("  FBC_ALTD_WAIT_CMD_ARBIT        = 0b%d\n", io_pore.d0.isBitSet(1))
  	POREVE_DBG("  FBC_ALTD_ADDR_DONE             = 0b%d\n", io_pore.d0.isBitSet(2))
  	POREVE_DBG("  FBC_ALTD_DATA_DONE             = 0b%d\n", io_pore.d0.isBitSet(3))
  	POREVE_DBG("  FBC_ALTD_WAIT_RESP             = 0b%d\n", io_pore.d0.isBitSet(4))
  	POREVE_DBG("  FBC_ALTD_OVERRUN_ERROR         = 0b%d\n", io_pore.d0.isBitSet(5))
  	POREVE_DBG("  FBC_ALTD_AUTOINC_ERROR         = 0b%d\n", io_pore.d0.isBitSet(6))
  	POREVE_DBG("  FBC_ALTD_COMMAND_ERROR         = 0b%d\n", io_pore.d0.isBitSet(7))
  	POREVE_DBG("  FBC_ALTD_ADDRESS_ERROR         = 0b%d\n", io_pore.d0.isBitSet(8))
	POREVE_DBG("  FBC_ALTD_PB_OP_HANG_ERR        = 0x%d\n", io_pore.d0.isBitSet(9))
        POREVE_DBG("  FBC_ALTD_PB_DATA_HANG_ERR      = 0x%d\n", io_pore.d0.isBitSet(10))
        POREVE_DBG("  FBC_ALTD_PB_UNEXPECT_CRESP_ERR = 0x%d\n", io_pore.d0.isBitSet(11))
        POREVE_DBG("  FBC_ALTD_PB_UNEXPECT_DATA_ERR  = 0x%d\n", io_pore.d0.isBitSet(12))
        POREVE_DBG("  RSVD_13_15                     = 0x%01llX\n", io_pore.d0.extractToRight(13, 3))
        POREVE_DBG("  FBC_ALTD_WAIT_PIB_DIRECT       = 0b%d\n", io_pore.d0.isBitSet(16))
        POREVE_DBG("  FBC_ALTD_PIB_DIRECT_DONE       = 0b%d\n", io_pore.d0.isBitSet(17))
        POREVE_DBG("  FBC_ALTD_PBINIT_MISSING        = 0b%d\n", io_pore.d0.isBitSet(18))
        POREVE_DBG("  FBC_ALTD_UNTRUSTED_DENIED      = 0b%d\n", io_pore.d0.isBitSet(19))
        POREVE_DBG("  RSVD_20_31                     = 0x%03llX\n", io_pore.d0.extractToRight(20, 12))
        POREVE_DBG("  FBC_ALTD_PCB_ERROR_FIR         = 0b%d\n", io_pore.d0.isBitSet(32))
        POREVE_DBG("  FBC_ALTD_PCB_ERROR             = 0x%02llX\n", io_pore.d0.extractToRight(33, 7))
        POREVE_DBG("  RSVD_40_47                     = 0x%02llX\n", io_pore.d0.extractToRight(40, 8))
        POREVE_DBG("  FBC_ALTD_ECC_CE                = 0b%d\n", io_pore.d0.isBitSet(48))
        POREVE_DBG("  FBC_ALTD_ECC_UE                = 0b%d\n", io_pore.d0.isBitSet(49))
        POREVE_DBG("  FBC_ALTD_ECC_SUE               = 0b%d\n", io_pore.d0.isBitSet(50))
        POREVE_DBG("  RSVD_51_58                     = 0x%02llX\n", io_pore.d0.extractToRight(51, 8))
        POREVE_DBG("  FBC_ALTD_CRESP_VALUE           = 0x%02llX\n", io_pore.d0.extractToRight(59, 5))
        andi    D0, D0, ADU_STATUS_ERR_MASK
        cmpibraeq D0, clr_lock, ADU_STATUS_EXP

        // unexpected value read back, halt
        POREVE_ERR("Fabric init failed, or mismatch in expected ADU status!\n")
        reqhalt RC_SBE_FABRICINIT_ERR

clr_lock:

	updatestep STEP_FABRICINIT_FBC_INIT_OP_PASS, D0, P0
        // clear ADU Command Register to release lock
        //   11 => FBC_locked => 0b0 (release lock)
        POREVE_DBG("Fabric init command succeeded!\n")
        POREVE_DBG("Releasing ADU lock ...\n")
        sti     ADU_COMMAND_0x02020001, P1, 0x0000000000000000
	updatestep STEP_FABRICINIT_ADU_LOCK_RELEASED, D0, P0
        .end_procedure proc_sbe_fabricinit
