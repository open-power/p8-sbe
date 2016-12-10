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
#include "proc_sbe_l3_pgood.H"
#include "common_ecids.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom

        .set STEP_EX_START_CLOCKS_NSL,     0x1
        .set STEP_EX_START_CLOCKS_SL,      0x2
        .set STEP_EX_START_CLOCKS_RUNNING, 0x3
        .set STEP_EX_START_CLOCKS_SUCCESS, 0x4

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_ex_startclocks, slw, "$Revision: 1.31 $"

        POREVE_INF("<proc_sbe_ex_startclocks>: P8 Start EX-Clocks started\n"  );
        nop

        // Drop the Pervasive THOLD
        // PM Exit States: WINKLE_EXIT_DROP_PERV_THOLD
        sti      EX_PMGP0_AND_0x100F0101,P0, ~(BIT(4))

	    POREVE_DBG("Enabling L3 EDRAM/LCO setup");
	    l3_setup L3_SETUP_ACTION_ENABLE, L3_SETUP_UNIT_L3_EDRAM

        // Drop perv fence GP0.63 multicast scomreg write
        sti     GENERIC_GP0_AND_0x00000004, P0, ~BIT(63)

        // Reset abstclk_muxsel, synclk_muxsel (io_clk_sel)
        sti     GENERIC_GP0_AND_0x00000004, P0, ~BITS(0,2)

        // Set ABIST_MODE_DC for core chiplets (core recovery)
        sti     GENERIC_GP0_OR_0x00000005, P0, BIT(11)|BIT(13)

	    // set fabric node/chip ID values (read from nest chiplet)
	    // read from nest chiplet
	    lpcs	P1, NEST_CHIPLET_0x02000000
	    ldandi	D0, NEST_GP0_0x02000000, P1, BITS(40, 6)
	    std	D0, GENERIC_GP0_OR_0x00000005, P0

	    // Write ClockControl, Scan Region Register,
        // set all bits to zero prior clock start
        sti     GENERIC_CLK_SCANSEL_0x00030007, P0, 0x0000000000000000

        // Write ClockControl, Clock Region Register, Clock Start command
        // (arrays + nsl only, not refresh clock region) EX Chiplet
        sti     GENERIC_CLK_REGION_0x00030006, P0, 0x4FF0060000000000

        updatestep  STEP_EX_START_CLOCKS_NSL, D0, P1

        // Write ClockControl, Clock Region Register, Clock Start command
        // (sl + refresh clock region) EX Chiplet
        sti     GENERIC_CLK_REGION_0x00030006, P0, 0x4FF00E0000000000

        updatestep  STEP_EX_START_CLOCKS_SL, D0, P1

        // Read Clock Status Register (EX chiplet)
        // check for bits 27:29 eq. zero, no tholds on
        // 27     ROX  CLOCK_STATUS_DPLL_FUNC_SL: status of dpll_func_sl_thold
        // 28     ROX  CLOCK_STATUS_DPLL_FUNC_NSL: status of dpll_func_nsl_thold - output not used
        // 29     ROX  CLOCK_STATUS_DPLL_ARY_NSL: status of dpll_ary_nsl_thold - output not used

        // Needed to resolve SLW reading using a multicast group
        // Get P1 setup for the chiplets to be targeted.
        setp1_mcreadand D0

        ld      D0, GENERIC_CLK_STATUS_0x00030008, P1
        xori    D0, D0, 0x00000003FFFFFFFF
        branz   D0, error_clock_start

        POREVE_DBG("<proc_sbe_ex_startclocks>: EX clock running now...\n");
        updatestep  STEP_EX_START_CLOCKS_RUNNING, D0, P1

        // Read the Global Checkstop FIR of dedicated EX chiplet
	    setp1_mcreador D0
        ld      D0, GENERIC_XSTOP_0x00040000, P1
        branz   D0, error_checkstop_fir

        POREVE_DBG("<proc_sbe_ex_startclocks>: All checkstop FIRs on initialized EX are zero ...\n");

        // Clear force_align in all Chiplet GP0
        sti     GENERIC_GP0_AND_0x00000004, P0, ~BIT(3)

        // Clear flushmode_inhibit in Chiplet GP0
        // Can't do this on Murano & Venice DD1.x due to a logic bug in L3 - HW250462
        lpcs	P1, PCBMS_DEVICE_ID_0x000F000F
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P1, CFAM_CHIP_ID_MAJOR_EC_MASK
        cmpibraeq   D0, 1f,                         CFAM_CHIP_ID_MAJOR_EC_1
        sti     GENERIC_GP0_AND_0x00000004, P0, ~BIT(2)

1:      
        // Clear core2cache and cache2core fences.  Necessary for Sleep,
        // redundant (already clear) but not harmful for IPL/Winkle
        sti     EX_PMGP0_AND_0x100F0101,P0,~(BIT(20)|BIT(21))

        // Disable PM and DPLL override                                                //AK-WAFER
        POREVE_INF("<proc_sbe_ex_startclocks>: Disable PM and DPLL override ...\n");   //AK-WAFER
        sti     EX_PMGP0_AND_0x100F0101,P0,~(BIT(0)|BIT(3))                            //AK-WAFER

        // PM Exit States: WINKLE_EXIT_WAIT_ON_OHA
        // Drop fence GP3.18 to unfence the chiplet
    		// CMO-20130516: First clear the pbus purge request bit(14) from AISS
	setp1_mcreador D0
        ld      D0, EX_OHA_MODE_REG_RWx1002000D, P1
  	    andi    D0, D0, ~BIT(1)
	      std     D0, EX_OHA_MODE_REG_RWx1002000D, P0
        ld      D0, EX_OHA_AISS_IO_REG_0x10020014, P1
  	    andi    D0, D0, ~BIT(14)
	      std     D0, EX_OHA_AISS_IO_REG_0x10020014, P0
        ld      D0, EX_OHA_MODE_REG_RWx1002000D, P1
  	    ori     D0, D0, BIT(1)
	      std     D0, EX_OHA_MODE_REG_RWx1002000D, P0
        // Now drop pb fence bit(18)
//        sti     GENERIC_GP3_AND_0x000F0013,P0, ~BIT(18)

        // Drop fence GP3.26 to allow PCB operations to the chiplet
        sti     GENERIC_GP3_AND_0x000F0013,P0, ~BIT(26)

        updatestep  STEP_EX_START_CLOCKS_SUCCESS, D0, P1

        POREVE_INF("<proc_sbe_ex_startclocks>: Exiting procedure successfully \n"  );

	ifidle D0, 1f
	//Not idle Check secure mode
	ifbitclrscom D1, D1, OTPC_M_SECURITY_SWITCH_0x00010005, P1, 1, 1f
	//Trusted boot is set, set core trusted boot.
	sti     EX_TRUSTED_BOOT_EN_0x10013C03, P0, BIT(0)

1:
	
        .end_procedure proc_sbe_ex_startclocks

//------------------------------------------------------------------------------
// ERROR -- Clocks failed to start
//------------------------------------------------------------------------------
error_clock_start:
        POREVE_ERR("<proc_sbe_ex_startclocks>: Clock Start Error on EX detected ...\n");
        reqhalt RC_SBE_EX_STARTCLOCKS_CLOCKS_NOT_STARTED

//------------------------------------------------------------------------------
// ERROR -- Checkstop detected
//------------------------------------------------------------------------------
error_checkstop_fir:
        POREVE_ERR("<proc_sbe_ex_startclocks>: Checkstop FIR on initialized EX is not zero, VITAL register was updated ...\n");
        reqhalt RC_SBE_EX_STARTCLOCKS_CHIP_XSTOPPED

