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
        .list


//------------------------------------------------------------------------------
// preprocessor directives
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom


//------------------------------------------------------------------------------
// Constant Definitions
//------------------------------------------------------------------------------
        .set DPLL_LOCK_BIT,                 50
        .set DPLL_LOCK_MAX_POLL_LOOPS,      0x1600
        .set DPLL_LOCK_DELAY_CYCLES,        0x10
        .set STEP_SBE_DPLL_SETUP_LOCK,      1
        .set STEP_SBE_DPLL_GMUX_SET,        2
        .set STEP_SBE_DPLL_SETUP_COMPLETE,  3

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------
        // For a 2000GHz nest (500MHz Pervasive), 2ns clocks exists
        // For a DPLL lock time of >150us from power on, 150000/2 = 75000
        // d75000 => 0x124F8   ----> round up to 0x15000

        // For a 2400GHz nest (600MHz Pervasive), 1.667ns clocks exists
        // For a DPLL lock time of >150us from power on, 150000/1.667 = 89982
        // d90000 => 0x15f90   ----> round up to 0x16000

#define DPLL_LOCK_DELAY 0x10
#define DPLL_LOCK_LOOP_NUMBER 0x1600

        .xip_quad ex_dpll_lock_delay_mult,  0x1600
        .xip_quad ex_glsmux_post_delay_mult,  0x1

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_ex_dpll_setup, ipl, "$Revision: 1.19 $"


        POREVE_INF("EX Chiplet -> Start DPLL setup" )

        // The setup of P0 happens external to this procedure
        // P0 is set to point to either a single EX core, or to multiple EX 
        // cores using multicast
        POREVE_DBG("EX Chiplet dpll_setup P0 -> 0x%02llx" , io_pore.p0.read())

        // Skip DPLL and Glitchless mux setup for Sleep
        // Glitchless mux change for the core (Sleep) done in 
        // proc_sbe_ex_chiplet_reset.
        ifsleep D0, glm_end

dpll_start:

        setp1_mcreadand D0

        POREVE_INF("Set up CPM PARM register for DPLL")
        ld      D0, EX_DPLL_CPM_PARM_REG_0x100F0152, P1

        // ----- Make sure that ff_bypass is set to "1" -----
        // This is necessary to ensure that the DPLL is in Mode 1.  If not,
        // the lock times will go from ~30us to 3-5ms
        // Set bit 11 of DPLL Mode register  0x150F0152

        POREVE_DBG("Put DPLL into Mode 1 by asserting ff_bypass.")
        POREVE_DBG(">>> Work around  <<<<: Also disabling ping-pong synchronizer" )
        ori     D0, D0, (BIT(11)|BIT(32))

        POREVE_DBG("Clear bits 15,16,18-23 and set bit 17 of DPLL reg 0x10F0152")
        andi    D0, D0, 0xFFFE00FFFFFFFFFF
        ori     D0, D0, BIT(17)

        POREVE_DBG("Set slew rate to a modest value")
        ori     D0, D0, 0x8000000000000000
        std     D0, EX_DPLL_CPM_PARM_REG_0x100F0152, P0

	POREVE_DBG("Change static offset of duty cycle controller")
	sti	EX_CLK_ADJ_SET_0x100F0016, P0, 0x8005000000000000

        // ----- Clear dpllclk_muxsel (syncclk_muxsel) to "0" -----
        POREVE_INF("Reset syncclk_muxsel or dpllclk_muxsel")
        sti     GENERIC_GP0_AND_0x00000004, P0, ~BIT(1)
        sti     EX_PMGP0_AND_0x100F0101, P0, ~(BIT(11))

        // ----- Take DPLL out of bypass -----
        // Clear bit 5 of EX GP3 Register
        POREVE_INF("EX Chiplet -> Take DPLL out of bypass" )
        sti     EX_GP3_AND_0x100F0013, P0, ~(BIT(5))

        // ----- Drop DPLL tholds  -----
        // Clear bit 3 of EX PMGP0 Register
        POREVE_INF("EX Chiplet -> Drop internal DPLL THOLD" )
        sti     EX_PMGP0_AND_0x100F0101, P0, ~(BIT(3))

        // ----- Delay to wait for DPLL to lock  -----
        // TODO:  Determine whether or not we should POLL instead of put delay here.
        // Wait for >150us

        POREVE_INF("Wait for DPLL to lock" )
	    waits	DPLL_LOCK_LOOP_NUMBER*DPLL_LOCK_DELAY
        
        // Check for lock
        ldandi  D0, EX_PMGP0_0x100F0100, P1, BIT(DPLL_LOCK_BIT)
        braz    D0, dpll_nolock 
        
//        ld      D0, 0, A0
//        POREVE_DBG("DPLL Lock Delay Base:  0x%02X; Multiplier 0x%05llX",
//                        DPLL_LOCK_DELAY, io_pore.d0.read())
//        mr      CTR, D0

//        bra     dpll_delay_loop_end
//dpll_delay_loop_start:
//        waits   0x1600*DPLL_LOCK_DELAY
//dpll_delay_loop_end:
//        loop    dpll_delay_loop_start


        // Poll the DPLL lock bit until locked.      
//        pollbitset  D0, EX_PMGP0_0x100F0100, P1, \#
//                      DPLL_LOCK_BIT, \#
//                      DPLL_LOCK_MAX_POLL_LOOPS, \#
//                      DPLL_LOCK_DELAY_CYCLES, \#
//                      dpll_nolock

        // ----- Recycle DPLL in and out of bypass -----
        // Clear bit 5 of EX GP3 Register
        POREVE_INF("EX Chiplet -> Recycle DPLL in and out of bypass" )
        sti     EX_GP3_OR_0x100F0014, P0, BIT(5)
        sti     EX_GP3_AND_0x100F0013, P0, ~(BIT(5))
        
        POREVE_INF("EX Chiplet -> EX DPLL is locked" )
        updatestep STEP_SBE_DPLL_SETUP_LOCK, D0, P1

        //release stick to test_flush signal in dpll behavioral for Naples
        ##@char facname[1024];
        ##@ecmdDataBuffer data, partialgood;
        ##@ecmdChipTarget e_target;
        ##@std::string hierarchy;
        ##@fapi::ReturnCode rc;
        ##@fapi::ATTR_NAME_Type chip_type;
        ##@bool is_naples=false; 
        ##@rc= FAPI_ATTR_GET_PRIVILEGED(ATTR_NAME, &i_target, chip_type);
        ##@if(rc)
        ##@{
        ##@FAPI_ERR("Error getting attr_name to check for Naples");
        ##@return rc; 
        ##@}
        ##@if(chip_type == fapi::ENUM_ATTR_NAME_NAPLES)
        ##@{
        ##@FAPI_INF("NAPLES chip found.");
        ##@is_naples=true; 
        ##@}
        ##@else
        ##@{
        ##@FAPI_INF("MURANO or VENICE found.");
        ##@}
        ##@uint32_t rc_ecmd;
        ##@FAPI_DBG("Converting fapi-target to ecmd-target \n");
        ##@fapiTargetToEcmdTarget( i_target, e_target);
        ##@rc_ecmd = simGetHierarchy( e_target, hierarchy );
        ##@if(rc_ecmd){
        ##@FAPI_ERR("Error (0x%x) getting target hierarchy", rc_ecmd);
        ##@rc.setEcmdError(rc_ecmd);
        ##@return rc;
        ##@}
        ##@rc_ecmd = getScom( e_target, ALL_CORES_BITX_0x52000000|GENERIC_GP3_0x000F0012, partialgood);
        ##@if(rc_ecmd){
        ##@FAPI_ERR("Error (0x%x) getting partial good setup", rc_ecmd);
        ##@rc.setEcmdError(rc_ecmd);
        ##@return rc;
        ##@}
        ##@for(int i = 0x10; i < 0x20; i++ ) {
        ##@if( partialgood.isBitSet(i)) {
        ##@if(is_naples)
        ##@{
        ##@sprintf( facname, "%sEX%.2i.TP.ECO_DOM.TC_CCFLUSH_DC_INT", hierarchy.data(), i-0x10 );
        ##@rc_ecmd = simUNSTICK(facname, 1,  0, 0);
        ##@if(rc_ecmd){ 
        ##@FAPI_ERR("Error (0x%x) sticking %s", rc_ecmd, facname);
        ##@rc.setEcmdError(rc_ecmd);
        ##@return rc;
        ##@}
        ##@}
        ##@}
        ##@}
        ##@return rc; 
glm_start:

        // ----- Set Glitch-Less MUXes for IPL/Winkle case ----
        // For Sleep, the core glitchless mux is change earlier as the DPLL
        // was already up and locked.
        //
        // Set various gl muxes to pass the output of the DPLLs to the clock grid.

        // Read-modify-write (vs sti AND and sti OR) is done so that glitchless
        // mux change field change is atomic (eg 1 store)
        setp1_mcreadand D1

        ld      D1,EX_PMGP0_0x100F0100,P1   

        // IPL/Winkle - Switch glitchless mux primary source to 001 = DPLL for bits
        // 27:29

        // Note: GLM async reset occured in proc_sbe_ex_chiplet_reset.

        // Set tp_clkglm_sel_dc to "001"  (EX PM GP0 bits 27-29)
        POREVE_INF("EX Chiplet -> Set glitchless mux select for primary chiplet clock source to 001 ")
        // Set tp_clkglm_eco_sel_dc to "0"  (EX PM GP0 bit 30)
        // Set the core glitchless mux to use the primary input (b00).
        // EX PM GP0 bits 32-33)
        POREVE_INF("EX Chiplet -> Set glitchless mux select for core and eco domain to 0 ")
        andi    D1, D1, ~(BIT(27)|BIT(28)|BIT(30)|BIT(32)|BIT(33))
        ori     D1, D1, (BIT(29))

        // Store the final result to the hardware
        std     D1,EX_PMGP0_0x100F0100,P0

glm_end:

        updatestep STEP_SBE_DPLL_GMUX_SET, D0, P1

        // ----- Drop ff_bypass to enable slewing -----
        // ----- (Change from Mode 1 to mode 2)   -----
        // Clear bit 11 of DPLL Mode register  0x150F0152
        // CMO20131125-Further, drop the pp synchronizer bit32.
        // CMO20131219-Keep the pp sync bit32 asserted to avoid x-leakage (HW276931).
        POREVE_INF("EX Chiplet -> Clear ff_bypass to switch into slew-controlled mode" )
        setp1_mcreadand D1
        ld      D1, EX_DPLL_CPM_PARM_REG_0x100F0152, P1
        andi    D1, D1, ~(BIT(11))
        std     D1, EX_DPLL_CPM_PARM_REG_0x100F0152, P0

        // ----- Drop other tholds -----
        // Clear bit 3 of EX PM GP0 Register
//        POREVE_INF("EX Chiplet -> Drop DPLL thold" )
//        sti     EX_PMGP0_AND_0x100F0101,P0, ~(BIT(3))

        updatestep STEP_SBE_DPLL_SETUP_COMPLETE, D0, P1
        POREVE_INF("EX Chiplet -> DPLL setup completed" )
        
        // DEBUG only
        setp1_mcreadand D1
        ld      D0,EX_GP0_0x10000000,P1   


        .end_procedure proc_sbe_ex_dpll_setup

dpll_nolock:
        POREVE_ERR("EX_DPLL -> Failed to lock");
        reqhalt RC_SBE_DPLL_SETUP_NOLOCK
