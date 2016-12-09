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
// Comments
//------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////
//
//  setup Multicast groups
//
////////////////////////////////////////////////////////////////////////////////
// There will be 4 Multicast Groups:
// Multicast Group 0:   All functional chiplets (PRV PB XBUS ABUS PCIE TPCEX) (Use PCB Slave Multicast Group Register #1)
// Multicast Group 1:   All functional ex (no cores)        (Use PCB Slave Multicast Group Register #2)
// Multicast Group 2:   All functional ex (cores)           (Use PCB Slave Multicast Group Register #3)
// Multicast Group 3:   All functional chiplets, but not PRV (Use PCB Slave Multicast Group Register #4)
//
//
// Chiplet     group 0     group 1     group 2          group 3
//
// Perv        y            n           n                 n
// Nest        y            n           n                 y
// XBUS        y            n           n                 y
// ABUS        y            n           n                 y
// PCIE        y            n           n                 y
// EX1         y            y           y  core only      y
// EX2         y            y           y  core only      y
// EX3         y            y           y  core only      y
// EX4         y            y           y  core only      y
// EX5         y            y           y  core only      y
// EX6         y            y           y  core only      y
// EX9         y            y           y  core only      y
// EX10        y            y           y  core only      y
// EX11        y            y           y  core only      y
// EX12        y            y           y  core only      y
// EX13        y            y           y  core only      y
// EX14        y            y           y  core only      y
//
// chiplet pervasive for chiplets: TPCPRV TPCPB  TPCXBUS TPCABUS TPCPCIE TPCEX(1,  2, 3, 4, 5, 6, 9,10,11,12,13,14)
// address (PCB)                 : 01     02     03      08      09            11,12,13,14,15,16,19,1A,1B,1C,1D,1E
//
//
// PCB endpoints are included within the pervasive top wrapper:
// vhdl_prv_top  wrapper    address (PCB)
// tpc_prv_top   EH_TOP     01
// tpc_pb_top    EH_TOP     02
// tpc_fbc_top   EN_TOP     03
// tpc_ab_bus    ES_TOP     08
// tpc_pci_top   ES_TOP     09
// tpc_ex_top    EX_TOP     11,12,13,14,15,16,19,1A,1B,1C,1D,1E
//
// specify group register content:
//------------------------------------------------------------------------------
// Set PCB Slave Endpoint Multicast Group Registers #1 to #4
// Value is the multicast group number the slave should respond to
// documentation Table 5-30 PRV workwork:
// bit        0 1 2 3 4 5
// bin value  1 1 1 0 0 0 multicast group 0 -> pcb slave endpoint multicast group register 1 is used
//            1 1 1 0 0 1 multicast group 1 -> pcb slave endpoint multicast group register 2 is used
//            1 1 1 0 1 0 multicast group 2 -> pcb slave endpoint multicast group register 3 is used
//            1 1 1 0 1 1 multicast group 3 -> pcb slave endpoint multicast group register 4 is used
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Includes
//------------------------------------------------------------------------------
        .nolist
#include "p8_sbe.H"
#include "p8_slw.H"
#include "proc_sbe_initf_common_seeprom.H"
#include "proc_sbe_ex_chiplet_scan0.H"
#include "p8_ex_scan0_length.H"
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

        .set MCG_REGISTER_SETUP_MCG0, 0xe0001c0000000000
        .set MCG_REGISTER_SETUP_MCG1, 0xe4001c0000000000
        .set MCG_REGISTER_SETUP_MCG2, 0xe8001c0000000000
        .set MCG_REGISTER_SETUP_MCG3, 0xec001c0000000000
        .set MCG_REGISTER_SETUP_MCG7, 0xfc001c0000000000

        .set EX_GP3_RESET_VALUE, 0x7C1623E000000000
        // 1     -  PCB_EP_RESET
        // 2     -  GLMMUX Reset
        // 3     -  PLL_TEST Enable
        // 4     -  PLLRST - PLL Reset
        // 5     -  PLL Bypass
        // 11    -  D_MODE for Vital
        // 13    -  MPW2 for Vital
        // 14    -  PMW1 for Vital
        // 18    -  FENCE_EN for chiplet
        // 22    -  Resonant Clock disable
        // 23:24 -  Glitchless Mux Sel
        // 25:   -  ?? (set because System Pervasive flow does this)
        // 26:   -  FENCE PCB

        .set MPIPL_BITNUM, 0

     // Procedure Progress Step Definition
        .set STEP_MCGR_PRV_DONE,      0x1
        .set STEP_LOOP1_DONE,         0x2
        .set STEP_SETUP_VIA_MC_DONE,  0x3
        .set STEP_MCGR3_SCAN0_1_DONE, 0x4
        .set STEP_MCGR3_SCAN0_2_DONE, 0x5
        .set STEP_LOOP2_DONE,         0x6
        .set STEP_EX_MC_SCAN_DONE,    0x7

     // Security Unlock Polling parameters
        .set MAX_SECURITY_POLLS,      256   // 426ns x 256 = 109us total
        .set SECURITY_DELAY,          256   // SBE cyc @ 600MHz(1.667ns) = 426ns

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

    .macro ci_scan_ex_gen id:req, next_id:req
ci_scan_ex\id:
        .pibmem_port (PORE_SPACE_PIBMEM & 0xf)
    // check if chiplet being processed (in CTR) matches this ID
    // skip to the next ID if not
        mr      D1, CTR
        xori    D1, D1, (0x10+\id)
        branz   D1, ci_scan_ex\next_id

        // double-check that the chiplet is actually enabled
        ls      P0, (0x10+\id)
        ifbitclrscom D1, D1, GENERIC_GP3_0x000F0012, P0, 0, ci_scan_ex\next_id

    // save CTR (chiplet ID), A0/D0 state (combined_good vector)
        bsr     store_ctr_a0_d0_module

    // extract state of refr domain from combined_good data
    andi    D0, D0, BIT(10)
    // if bit is ON: need to include this chiplet in lco_victim_vector
    branz    D0, ci_update_lco_victim_ex\id

ci_update_edram_mask_ex\id:
    // if bit is OFF: need to set edram_disable bit for this chiplet
    lpcs    P0, STBY_CHIPLET_0x00000000
    POREVE_INF("Marking L3 disabled for EX%llu ...\n", (io_pore.ctr.read() & 0x0F))
    bsi    D0, edram_disable_mask, P0, BIT(0x10+\id)
    // skip to ring scanning
    bra    ci_scan_rings_ex\id

ci_update_lco_victim_ex\id:
        ld    D0, lco_config, P0
        .if(\id < 8)
        ori      D0, D0, BIT(\id -1)
        .else
        ori      D0, D0, BIT(\id -3)
        .endif

    adds    D0, D0, 1
    POREVE_INF("Updating LCO victim vector = %016llX to include EX%llu ...\n", io_pore.d0.read(), (io_pore.ctr.read() & 0x0F))
    std    D0, lco_config, P0

    // scan rings
ci_scan_rings_ex\id:
    // restore P0 for scan
    ls    P0, (0x10+\id)
    POREVE_INF("Scanning EX%llu GPTR/Repair/Time rings ...\n", (io_pore.p0.read() & 0x0F) )

        load_ring ex_time_eco  index=\id skipoverride=1
        load_ring ex_repr_eco  index=\id skipoverride=1

    // Check for good core and eco domain and skip this EX if not both are good
        // We will assume we always have good core and L2 in a good EX chiplet
//        bsr       restore_ctr_a0_d0_module
//        andi      D0, D0, BITS(5,2)
//        cmpibrane D0, ci_loop2_cplt_done, BITS(5,2)

        load_ring ex_time_core index=\id skipoverride=1
        load_ring ex_repr_core index=\id skipoverride=1

        load_ring ex_gptr_core skipoverride=1
        load_ring ex_gptr_l2   skipoverride=1

        bsr       restore_ctr_a0_d0_module

        .endm


//------------------------------------------------------------------------------
// Subroutines
//------------------------------------------------------------------------------

        .subroutine cleanup_pcb_slave_EX, ipl, "$Revision"

        // This routine makes no assumptions as to the clock state upon entry and
        // will react appropriately whether the clocks engaged upon entry are
        // refclk or DPLL.  In either case, this routine will exit running on
        // refclks as the remainder of the IPL assumes this to be the case.

        //  1. Clear special wakeup & shut down all EX hang pulses
        //  2. Remove all EX chiplets from multicast groups
	//     Disable chiplet if instructed, else continue
        //  3. Disable all PCB interrupt sources for a clean reset
        //  4. Switch the Glitchless Mux to refclks (IPL assumes this)
        //  5. Disable the DPLL
        //  6. Start the clocks to allow access to the AISS
        //          This operation in a secure system requires a double
        //          flush operation to be performed.  This is done regardless
        //          to keep the flows between secure and unsecure systems common.
        //  7. Perform PCB subsystem reset to ensure async interfaces are ready
        //  8. Disable the AISS
        //  9. Set AISS request terminate the PCB to quiesce all PCB endpoints
        // 10. Set block wake-up sources in PMGP0 to keep PM logic from reacting
        // 11. Enable PM to allow hardware to react to AISS PCB terminate request
        // 12. Check that PCB is fenced via GP3(26)
        // 13. Disable Power Management functions
        // 14. Set EX GP3 to reset value (which continues to block PCB interrupts)
        // 15. Set block wake-up sources in PMGP0
        // 16. Set PM SLave Winkle Fence
        // 17. Clear PCB Fence set for the EP reset above
        // 18. Clear the PCB Slave Error Reg of residual errors
        //
        // P0 - destroyed
        // P1 - contains chiplet to clean up
        // D0 - destroyed
        // D1 - preserved
        // CTR - destroyed, at entry contains desired chiplet state (zero=disabled, non-zero=enabled)
	//      

        // #1
	POREVE_INF("Clear special wakeup sources")
	sti	PM_SPECIAL_WKUP_FSP_0x100F010B, P1, 0x0
	sti	PM_SPECIAL_WKUP_PHYP_0x100F010D, P1, 0x0
	sti	PM_SPECIAL_WKUP_OCC_0x100F010C, P1, 0x0
		
        POREVE_INF("Shut down all EX hang pulses")
        sti     EX_HANG_P0_0x100F0020, P1, 0x0
        sti     EX_HANG_P1_0x100F0021, P1, 0x0
        sti     EX_HANG_P2_0x100F0022, P1, 0x0
        sti     EX_HANG_P3_0x100F0023, P1, 0x0
        sti     EX_HANG_P4_0x100F0024, P1, 0x0
        sti     EX_HANG_P5_0x100F0025, P1, 0x0
        sti     EX_HANG_P6_0x100F0026, P1, 0x0

        // #2
        POREVE_INF("Remove chiplet from multicast groups")
        remove_from_mc_group D0, GENERIC_MCGR1_0x000F0001, P1
        remove_from_mc_group D0, GENERIC_MCGR2_0x000F0002, P1
        remove_from_mc_group D0, GENERIC_MCGR3_0x000F0003, P1
        remove_from_mc_group D0, GENERIC_MCGR4_0x000F0004, P1

        // disable chiplet & exit if instructed
	mr	D0, CTR
	// chiplet will remain enabled, continue
	branz	D0, disable_clock_controller_interrupts
	// clear chiplet enable & exit
	sti  	GENERIC_GP3_AND_0x000F0013, P1, ~BIT(0)
	bra	cleanup_pcb_slave_ex_return

disable_clock_controller_interrupts:		
        ld      D0, EX_SYNC_CONFIG_0x10030000, P1
        POREVE_DBG("\tCC SYNC before = %016llX ...", io_pore.d0.read());

        // #3
        POREVE_INF("Disable Clock Controller interrupts");
        bsi     D0, EX_SYNC_CONFIG_0x10030000, P1, BIT(6)

        POREVE_INF("Mask all Interrupts via GP2");
        sti     EX_GP2_0x10000002, P1, ~(BITS(0,64))

        // Debug read for Cronus
        ld      D0, EX_PMGP0_0x100F0100, P1
        POREVE_DBG("\tPMGP0 value = %016llX ...", io_pore.d0.read());

        // Debug read for Cronus
        ld      D0, GENERIC_GP3_0x000F0012, P1
        POREVE_DBG("\tGP3 value = %016llX ...", io_pore.d0.read());

        POREVE_INF("Disable PM to release hardware control")
        sti     EX_PMGP0_OR_0x100F0102, P1, BIT(0)

        // #4
        // Switch Glitchmux to refclk as the normal IPL path code assumes this
        POREVE_INF("Switch Primary GLSMUX to refclks")
        sti     EX_PMGP0_OR_0x100F0102, P1,  BIT(28)
        
        // Ensure the core GLSMUX is set to the primary GLSMUX as the chiplet
        // may have been in sleep.  Also, clear the Pervasive ECO fence (SW255300)       
        POREVE_INF("Switch Core GLSMUX to primary")
        sti     EX_PMGP0_AND_0x100F0101, P1,  ~(BIT(22)) || ~(BITS(32,2))
               
        // Allow time for switchover to settle
        ls      CTR, 16
        bra     clock_delay_loop_end
clock_delay_loop_start:
        waits   0xFFFFFF
clock_delay_loop_end:
        loop    clock_delay_loop_start

        // #5
        // Disable the DPLL to prepare for reIPL
        POREVE_INF("Mask the PLL lock errors to keep false logs from occuring")
        ld      D0, EX_SLAVE_CONFIG_0x100F001E, P1
        ori     D0, D0, BIT(12)
        std     D0, EX_SLAVE_CONFIG_0x100F001E, P1

        POREVE_INF("Disable DPLL in PMGP0")
        sti     EX_PMGP0_OR_0x100F0102, P1, BIT(10)

        POREVE_INF("Stop all clocks to prepare for security unlock")
        POREVE_DBG("\tWrite ClockControl, Scan Region Register, set all bits to zero prior clock start")
        sti     GENERIC_CLK_SCANSEL_0x00030007, P1, 0x0000000000000000
        POREVE_DBG("\tWrite ClockControl, Clock Region Register, Clock Stop command (all)");
        sti     GENERIC_CLK_REGION_0x00030006, P1, 0x0
        sti     GENERIC_CLK_REGION_0x00030006, P1, 0x8FFFFFFFFFFFFFFF

        // In a secure system, the stopping of the clocks makes the clock
        // controller inaccessable.  Thus, the normal operation of setting
        // the Clock Region Register back to 0 is skipped.  In non-secure
        // system, this is not harmful as this register is re-established
        // before use anyway
        //
        // Return to NOP condition
        // sti     GENERIC_CLK_REGION_0x00030006, P1, 0x0

        // #6
        POREVE_INF("Start the clocks to allow access to the AISS")

        // Due to secure boot, the clocks cannot be restarted unless the rings
        // are flushed.

        // The EX scan0 routines use both D0 and D1 but D1 must be preseverd for
        // the caller.  Thus, save D1 away.
        mr      D0, D1

        // save CTR/A0/D0 to pibmem  (note:  P0 is destroyed)
        bsr     store_ctr_a0_d0_module

        // Scan Flush routines assume that P0 points to the target chiplet(s)
        mr      P0, P1

        // Programming note:  the ex_scan0 routines will use P1 for chiplet
        // access and therefore states that P1 is destroyed..  Thus is true
        // if P0 were a multicast address. However, this subroutine is being
        // called in chiplet walking loop so P1 will be loaded with the value
        // of P0 which, in effect, retains the value of P1.
        POREVE_DBG("Scan the GPTR/TIME/REP rings as step 1 to unlock security");
        .rept PROC_SCAN0_FUNC_REPEAT
        ex_scan0 SCAN_GPTR_TIME_REP, SCAN_CLK_ALL
        .endr

        POREVE_DBG("Scan the all but GPTR/TIME/REP rings as step 2 to unlock security");
        .rept PROC_SCAN0_FUNC_REPEAT
        ex_scan0 SCAN_ALL_BUT_GPTRTIMEREP, SCAN_CLK_ALL
        .endr

        // Restore D1
        // restore CTR/A0/D0 to pibmem  (note:  P0 is destroyed)
        bsr     restore_ctr_a0_d0_module
        mr      D1, D0

        POREVE_INF("Check CC SYNC(14) that security is unlocked");
        pollbitclr D0, EX_SYNC_CONFIG_0x10030000, P1, 14 \
                MAX_SECURITY_POLLS, SECURITY_DELAY, security_unlock_error

        POREVE_DBG("\tDrop the Pervasive THOLD")
        sti      EX_PMGP0_AND_0x100F0101,P1, ~(BIT(4))

        POREVE_DBG("\tDrop perv fence GP0.63")
        sti     GENERIC_GP0_AND_0x00000004, P1, ~BIT(63)

        POREVE_DBG("\tReset abstclk_muxsel, synclk_muxsel (io_clk_sel)")
        sti     GENERIC_GP0_AND_0x00000004, P1, ~BITS(0,2)

        POREVE_DBG("\tSet ABIST_MODE_DC for core chiplets")
        sti     GENERIC_GP0_OR_0x00000005, P1, BIT(11)|BIT(13)

        POREVE_DBG("\tWrite ClockControl, Scan Region Register, set all bits to zero prior clock start")
        sti     GENERIC_CLK_SCANSEL_0x00030007, P1, 0x0000000000000000

        POREVE_DBG("\tWrite ClockControl, Clock Region Register, Clock Start command (arrays + nsl only, not refresh clock region)")
        sti     GENERIC_CLK_REGION_0x00030006, P1, 0x4FF0060000000000

        POREVE_DBG("\tWrite ClockControl, Clock Region Register, Clock Start command (sl + refresh clock region)")
        sti     GENERIC_CLK_REGION_0x00030006, P1, 0x4FF00E0000000000

        POREVE_DBG("\tCheck that clocks have started")
        ls      CTR, 16
        bra     clock_check_loop
clock_check_start:
        ld      D0, GENERIC_CLK_STATUS_0x00030008, P1
        xori    D0, D0, 0x00000003FFFFFFFF
        braz    D0, clock_check_end
clock_check_loop:
        loop    clock_check_start
        bra     clock_start_error
clock_check_end:

        // #7
        // As the clocks to the EX have been stopped, perform a PCB subsystem
        // reset to ensure that async interfaces are in proper alignment.
        lpcs    P0, PCBMS_RESET_REG_0x000F001D
        ld      D0, PCBMS_RESET_REG_0x000F001D, P0
        ori     D0, D0, BIT(0)
        std     D0, PCBMS_RESET_REG_0x000F001D, P0
        andi    D0, D0, ~(BIT(0))
        std     D0, PCBMS_RESET_REG_0x000F001D, P0

        // #8
        POREVE_INF("Disable the AISS to release hardware control... ")
        clrbitscom  D0, EX_OHA_MODE_REG_RWx1002000D, P1, 1

        // #9
        POREVE_INF("Set AISS request terminate the PCB to quiesce all PCB endpoints...")
        setbitscom  D0, EX_OHA_AISS_IO_REG_0x10020014, P1, 19

        // #10
        POREVE_INF("Set block wake-up sources in PMGP0 to keep PM logic from reacting..")
        sti     EX_PMGP0_OR_0x100F0102, P1,  (BIT(53))

        // #11
        POREVE_INF("Enable PM to allow hardware to react to AISS PCB terminate request...")
        sti     EX_PMGP0_AND_0x100F0101, P1, ~(BIT(0))

        // #12
        POREVE_INF("Check that PCB is fenced via GP3(26)")
        // Note: CTR register is used in the following macro.  This is not
        // used by the caller and thus can be used here.
        pollbitset D0, GENERIC_GP3_0x000F0012, P1, 26, 50, 16, pcb_fence_timeout_error

         // #13
        POREVE_INF("Disable PM to release hardware control")
        sti     EX_PMGP0_OR_0x100F0102, P1, BIT(0)

        // #14
        // This reset has the local endpoint reset enabled but this does NOT
        // influence the PM functions.  It only influences the interal to EX PCB
        // endpoints (eg clock control, OHA, PSCOM, etc).

        // Debug read for Cronus
        ld      D0, GENERIC_GP3_0x000F0012, P1
        POREVE_DBG("\tGP3 value = %016llX ...", io_pore.d0.read());

        POREVE_INF("Apply GP reset vector which includes endpoint reset, TP_FENCE_PCB")
        sti     GENERIC_GP3_0x000F0012, P1, EX_GP3_RESET_VALUE

        // #15
        // Set block wake-up sources in PMGP0
        POREVE_INF("Set block wake-up sources in PMGP0")
        sti     EX_PMGP0_OR_0x100F0102, P1,  BIT(53)

        // #16
        // Set PM SLave Winkle Fence
        POREVE_INF("Set PM SLave Winkle Fence")
        sti     EX_PMGP0_OR_0x100F0102, P1,  BIT(39)

cleanup_pcb_slave_EX_end:

        // #17
        POREVE_INF("Clear PCB Fence set for the EP reset above")
        sti     GENERIC_GP3_AND_0x000F0013, P1, ~BIT(26)

        // #18
        // Clear PCB Slave Error Capture
        POREVE_INF("Reset PCB Slave error capture register to clear PLL lock error that is injected by DPLL disablement")
        sti     EX_PCBS_ERROR_REG_0x100F001F, P1, BITS(25,3)

cleanup_pcb_slave_ex_return:
        .end_subroutine cleanup_pcb_slave_EX

clock_start_error:
        POREVE_ERR("Clock Start Error")
        reqhalt RC_SBE_MPIPL_CLOCK_START_ERROR

pcb_fence_timeout_error:
        POREVE_ERR("PCB Fence Timeout Error")
        reqhalt RC_SBE_MPIPL_PBC_FENCE_TIMEOUT_ERROR

security_unlock_error:
        POREVE_ERR("Security Unlock Error")
        reqhalt RC_SBE_MPIPL_SECURITY_UNLOCK_ERROR

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

        .procedure proc_sbe_chiplet_init, ipl, "$Revision: 1.81 $"
        POREVE_INF("*** Initialize good chiplets with some first settings ***")

start_ci_setup:

// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************

     // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

     // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P1, TP_CHIPLET_0x01000000

     // Setup MEM_BASE_ADDR0; points to partial good vector
        lia     A0, PORE_SPACE_SEEPROM, combined_good_vectors

     // Check for MPIPL
        ifbitclrscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, cplt_init

     // on MPIPL, need to process PCB slave for currently enabled EX chiplets
     // - if chiplet is partial good (SEEPROM)
     //   - if chiplet is enabled (PCB slave)
     //     - if chiplet is NOT garded (mbox)
     //         leave PCB slave enabled / cleanup PCB slave for MPIPL
     //     - else
     //         remove chiplet from multicast groups & disable PCB slave (newly GARDed)
     //   - else
     //       skip/don't touch (chiplet was previously GARDed)
     // - else
     //     skip/don't touch (chiplet is bad/not present)

     // reset LCO configuration status held in pibmem
	li	D0, 0x0
	std	D0, lco_config, P0

     // P1 contains the current EX chiplet to process
        lpcs    P1, EX00_CHIPLET_0x10000000
     // address first EX partial good record in SEEPROM
	adds	A0, A0, 8*0x10

check_if_EX_chiplet_is_configured:
     // read partial good record
	ld      D0, 0x0, A0
        andi    D0, D0, BITS(4,16)
     // no regions enabled so chiplet is not present/good, skip to next chiplet ID
	braz	D0, select_next_EX
	
     // chiplet is partial good, read PCB slave state via unicast
	POREVE_DBG("EX%02lld is partial good, checking PCB slave state", io_pore.p1.read()-16);
	ldandi	D0, GENERIC_GP3_0x000F0012, P1, BIT(0)
     // disabled, skip to next chiplet ID
	braz	D0, select_next_EX

     // chiplet is currently enabled, PCB slave must be processed
     // determine if chiplet should remain enabled on this IPL based on GARD record
	POREVE_DBG("EX%02lld PCB slave is enabled, checking GARD record", io_pore.p1.read()-16);
	lpcs	P0, STBY_CHIPLET_0x00000000
     // read/preserve EX chiplet GARD records from mailbox
        ldandi  D0, MBOX_SCRATCH_REG0_0x00050038, P0, BITS(16, 16)
     // invert EX data (in mbox, functional chiplets are marked with 0b0)
	xori	D0, D0, BITS(16, 16)
     // load chiplet ID to process in CTR
	mr	CTR, P1
     // via loop, shift GARD record for this chiplet into bit 0
	bra	check_EX_gard_loop_end
check_EX_gard_loop_begin:
        sldi    D0, D0, 1
check_EX_gard_loop_end:
        loop    check_EX_gard_loop_begin
     // GARD record is now aligned to bit 0, mask 
	andi	D0, D0, BIT(0)
	braz	D0, disable_EX_pcb_slave
     // chiplet will remain enabled
enable_EX_pcb_slave:
	li	CTR, 1
	bra	process_EX_pcb_slave
disable_EX_pcb_slave:
	li	CTR, 0
process_EX_pcb_slave:
	POREVE_DBG("Processing EX%02lld (PCB slave state = %s)", io_pore.p1.read()-16, ((io_pore.ctr.read())?("enabled"):("disabled")))
	bsr	cleanup_pcb_slave_EX

select_next_EX:
     // increment chiplet ID & SEEPROM address pointer
	POREVE_DBG("EX%02lld done", io_pore.p1.read()-16)
        adds    P1, P1, 1
	adds	A0, A0, 0x8
     // fall through once we have processed last chiplet
	mr	D0, P1
	cmpibrane D0, check_if_EX_chiplet_is_configured, 0x20       

done_processing_EX:

        // Check on xstops introduced by EX cleanup
        lpcs     P0, MASTER_PCB_INT_0x000F001A
        ifbitclrscom D0, D0, MASTER_PCB_INT_0x000F001A, P0, 2, 1f
        POREVE_DBG("\tP0 = %02llX ...", io_pore.p0.read());
        POREVE_DBG("\tD0 = %016llX ...", io_pore.d0.read());
        POREVE_ERR("Checkstop detected via bit 2 in register F001A.\n");
        reqhalt    RC_SBE_PROC_CHECKSTOP
1:

     // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P1, TP_CHIPLET_0x01000000

     // Need to skip into the middle of the chiplet setup loop
     // Use CTR as index variable to iterate thru chiplets (init to cplt 0x11 = EX01)
        ls      CTR, 0x11
     // set pointer to point to partial good vector Chiplet 0x11 (EX01)
	lia	A0, PORE_SPACE_SEEPROM, combined_good_vectors
        adds    A0, A0, 0x8*0x11
        bra     ci_loop1_start

cplt_init:

     // Setup PRV Chiplet
     // =======================================
     //   - setup Multicast Group
     // =======================================
        POREVE_INF("Setup MC Group for Pervasive Chiplet ...")

        sti     GENERIC_MCGR1_0x000F0001, P1, MCG_REGISTER_SETUP_MCG0
        sti     GENERIC_MCGR2_0x000F0002, P1, MCG_REGISTER_SETUP_MCG7
        sti     GENERIC_MCGR3_0x000F0003, P1, MCG_REGISTER_SETUP_MCG7
        sti     GENERIC_MCGR4_0x000F0004, P1, MCG_REGISTER_SETUP_MCG7

     // Progress Indicator update
        updatestep STEP_MCGR_PRV_DONE, D0, P0

     // =================
     // Start of Looper 1
     // =================
     //
     // Loop thru all remaining good chiplets
     // ========================================
     //   - setup Multicast Groups
     //   - Release endpoint reset
     //   - Partial Good settings
     //   - PCB Slave error register reset
     //   - Release winkle fences
     // ========================================
        POREVE_INF("Start Loopers for remaining Chiplets ...")

     // Use CTR as index variable to iterrate thru chiplets (init to cplt #2 = NEST)
        ls      CTR, 0x2
     // Skip over chiplets 0 & 1 (ie. pervasive) of partial good vector
        adds    A0, A0, 2*0x8

ci_loop1_start:

     // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P1, TP_CHIPLET_0x01000000

     // New iteration start of looper 1
        POREVE_INF("Looper 1 Iteration start ...")

     // Check whether we have a EX chiplet and need to look at the guard vector
        mr      D0, CTR
        andi    D0, D0, 0x10
        braz    D0, ci_loop1_not_guarded

     // Since we have a EX chiplet, let's get the guard vector bit from mailbox scratch reg 0x38
        POREVE_INF("EX chiplet, so getting guard vector information ...")
        ld      D0, MBOX_SCRATCH_REG0_0x00050038, P0

     // Shift the guard vector to bring current chiplet bit to bit position 0
        mr      D1, CTR

ci_loop1_guard_vector_shift:

        rols    D0, D0, 1
        subs    D1, D1, 1
        branz   D1, ci_loop1_guard_vector_shift

     // Check whether this EX chiplet is guarded and skip the chiplet if it is
        andi    D0, D0, BIT(0)
        branz   D0, ci_loop1_cplt_done

ci_loop1_not_guarded:

     // Get the combined good vector for the current chiplet ID
        POREVE_INF("Get the combined good vector for the current chiplet ID ...")
        ld      D0, 0x0, A0
        andi    D0, D0, BITS(4,16)

     // If current chiplet has no good regions, end this loop iterration and start next, otherwise
     //   set PRV_BASE_ADDR1 to point to this chiplet
        braz    D0, ci_loop1_cplt_done
        mr      P1, CTR

ci_loop1_cplt_base_setup:


     // Setup Multicast Groups for good chiplets (cplt id > 1)
     // ======================================================
        POREVE_INF("Setup MC Groups for current Chiplet ...")

     // Check whether we are an EX chiplet, if not then jump to "none EX"
        mr      D1, CTR
        andi    D1, D1, 0x10
        braz    D1, ci_loop1_mcg_none_ex

        POREVE_INF("*INFO* This is an EX chiplet *INFO*")

     // Ensure that core region is good, we don't support ECO
        andi    D0, D0, BIT(5)
        braz    D0, ci_loop1_cplt_done

        sti     GENERIC_MCGR1_0x000F0001, P1, MCG_REGISTER_SETUP_MCG0
        sti     GENERIC_MCGR2_0x000F0002, P1, MCG_REGISTER_SETUP_MCG1
        sti     GENERIC_MCGR3_0x000F0003, P1, MCG_REGISTER_SETUP_MCG2
        sti     GENERIC_MCGR4_0x000F0004, P1, MCG_REGISTER_SETUP_MCG3
        bra     ci_loop1_cplt_done

ci_loop1_mcg_none_ex:

        sti     GENERIC_MCGR1_0x000F0001, P1, MCG_REGISTER_SETUP_MCG0
        sti     GENERIC_MCGR2_0x000F0002, P1, MCG_REGISTER_SETUP_MCG3

ci_loop1_cplt_done:

     // We are now done with the loop for this chiplet; let's prepare for the next
     //   chiplet or end the looper
        POREVE_INF("Looper 1 completed on this chiplet")

     // Increment the chiplet index
        adds    CTR, 0x1
        adds    A0, 0x8

     // Check whether we reached chiplet id 32, otherwise start next iterration
        mr      D1, CTR
        andi    D1, D1, 0x20
        braz    D1, ci_loop1_start

     // ===============
     // End of Looper 1
     // ===============
        POREVE_INF("Looper 1 is complete")

     // Progress Indicator update
        updatestep STEP_LOOP1_DONE, D0, P0

ci_all_cplts_setup:

     // Hangcounter Setup
     // =================

     // Skip to the EX chiplet if MPIPL
        ifbitsetscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, ci_hc_setup_EX

     // Chiplet #01: Pervasive
     // ----------------------

        POREVE_INF("HC Setup : PRV 00 | Usage: PBA hang  | Dec. Value: 18 | Suppress: No")
        lpcs    P1, TP_HANG_P0_0x010F0020
        sti     TP_HANG_P0_0x010F0020, P1, 0x4800000000000000

        POREVE_INF("HC Setup : PRV 01 | Usage: ADU hang  | Dec. Value: 28 | Suppress: Yes")
        lpcs    P1, TP_HANG_P1_0x010F0021
        sti     TP_HANG_P1_0x010F0021, P1, 0x7200000000000000

        POREVE_INF("HC Setup : PRV 02 | Usage: OCC hang  | Dec. Value:  9 | Suppress: No")
        lpcs    P1, TP_HANG_P2_0x010F0022
        sti     TP_HANG_P2_0x010F0022, P1, 0x2400000000000000

        POREVE_INF("HC Setup : PRV 03 | Usage: NX hang   | Dec. Value: 24 | Suppress: Yes")
        lpcs    P1, TP_HANG_P3_0x010F0023
        sti     TP_HANG_P3_0x010F0023, P1, 0x6200000000000000

        POREVE_INF("HC Setup : PRV 04 | Usage: PB freq.  | Dec. Value:  1 | Suppress: No")
        lpcs    P1, TP_HANG_P4_0x010F0024
        sti     TP_HANG_P4_0x010F0024, P1, 0x0400000000000000

        POREVE_INF("HC Setup : PRV 05 | Usage: Malef. Al.| Dec. Value:  6 | Suppress: No")
        lpcs    P1, TP_HANG_P5_0x010F0025
        sti     TP_HANG_P5_0x010F0025, P1, 0x1800000000000000



     // Chiplet #02: Nest / PowerBus
     // ----------------------------

        POREVE_INF("HC Setup : NPB 00 | Usage: Therm.    | Dec. Value: 16 | Suppress: No")
        lpcs    P1, NEST_HANG_P0_0x020F0020
        sti     NEST_HANG_P0_0x020F0020, P1, 0x4000000000000000

        POREVE_INF("HC Setup : NPB 01 | Usage: PB hang   | Dec. Value: 23 | Suppress: Yes")
        lpcs    P1, NEST_HANG_P1_0x020F0021
        sti     NEST_HANG_P1_0x020F0021, P1, 0x5E00000000000000

        POREVE_INF("HC Setup : NPB 02 | Usage: PB exit   | Dec. Value: 15 | Suppress: Yes")
        lpcs    P1, NEST_HANG_P2_0x020F0022
        sti     NEST_HANG_P2_0x020F0022, P1, 0x3E00000000000000

        POREVE_INF("HC Setup : NPB 03 | Usage: NXAS hang | Dec. Value: 20 | Suppress: Yes")
        lpcs    P1, NEST_HANG_P3_0x020F0023
        sti     NEST_HANG_P3_0x020F0023, P1, 0x5200000000000000

        POREVE_INF("HC Setup : NPB 04 | Usage: PB early  | Dec. Value: 19 | Suppress: Yes")
        lpcs    P1, NEST_HANG_P4_0x020F0024
        sti     NEST_HANG_P4_0x020F0024, P1, 0x4E00000000000000

        POREVE_INF("HC Setup : PRV 05 | Usage: Malef. Al.| Dec. Value:  6 | Suppress: No")
        lpcs    P1, NEST_HANG_P5_0x020F0025
        sti     NEST_HANG_P5_0x020F0025, P1, 0x1800000000000000



     // Chiplet #04: X-Bus
     // ------------------

        POREVE_INF("HC Setup : XBS 00 | Usage: Therm.    | Dec. Value: 16 | Suppress: No")
        lpcs    P1, X_HANG_P0_XBUS_0x040F0020
        sti     X_HANG_P0_XBUS_0x040F0020, P1, 0x4000000000000000


     // Chiplet #08: A-Bus
     // ------------------

        POREVE_INF("HC Setup : ABS 00 | Usage: Therm.    | Dec. Value: 16 | Suppress: No")
        lpcs    P1, A_HANG_P0_0x080F0020
        sti     A_HANG_P0_0x080F0020, P1, 0x4000000000000000


     // Chiplet #09: PCIe
     // -----------------

        // nothing to do for PCIe

     // Chiplet #1x: EX
     // ---------------
ci_hc_setup_EX:
        POREVE_INF("HC Setup : EX  00 | Usage: Therm.         | Dec. Value: 16 | Suppress: No")
        lpcs    P1, WRITE_ALL_HPRE0_0x690F0020
        sti     WRITE_ALL_HPRE0_0x690F0020, P1, 0x4000000000000000

        POREVE_INF("HC Setup : EX  01 | Usage: REFR           | Dec. Value:  1 | Suppress: No")
        sti     WRITE_ALL_HPRE1_0x690F0021, P1, 0x0400000000000000

        // select init value bassed on chip type/EC
        lpcs    P0, STBY_CHIPLET_0x00000000
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P0, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
        cmpibrane   D0, ci_hc_setup_EX_not_murdd1x, (CFAM_CHIP_ID_MURANO    | CFAM_CHIP_ID_MAJOR_EC_1 )

        POREVE_INF("HC Setup : EX  02 | Usage: PM early & PC  | Dec. Value: 23 | Suppress: Yes")
        sti     WRITE_ALL_HPRE2_0x690F0022, P1, 0x5E00000000000000
        POREVE_INF("HC Setup : EX  03 | Usage: -              | Dec. Value:  0 | Suppress: Yes")
        sti     WRITE_ALL_HPRE3_0x690F0023, P1, 0x0200000000000000

        bra    ci_hc_setup_EX_hc4

ci_hc_setup_EX_not_murdd1x:
        POREVE_INF("HC Setup : EX  02 | Usage: PM early       | Dec. Value:  6 | Suppress: No")
        sti     WRITE_ALL_HPRE2_0x690F0022, P1, 0x1800000000000000
        POREVE_INF("HC Setup : EX  03 | Usage: PC             | Dec. Value: 23 | Suppress: Yes")
        sti     WRITE_ALL_HPRE3_0x690F0023, P1, 0x5E00000000000000

ci_hc_setup_EX_hc4:

        POREVE_INF("HC Setup : EX  04 | Usage: PM hang        | Value: 0x09 -  | Suppress: No")
        sti     WRITE_ALL_HPRE4_0x690F0024, P1, 0x2400000000000000

        POREVE_INF("HC Setup : EX  05 | Usage: Malef. Al.     | Value: 0x06 -  | Suppress: No")
        sti     WRITE_ALL_HPRE5_0x690F0025, P1, 0x1800000000000000

     // Some setups via Multicasts
     // ==========================

     // Drop clk_async_reset for EX cplts (MC group 1: all EX chiplets)
        POREVE_INF("MC Group 1: Drop Clock async reset in EX Cplt GP3 ...")
        lpcs    P1, WRITE_ALL_EXS_GP3_AND_0x690F0013
        sti     WRITE_ALL_EXS_GP3_AND_0x690F0013, P1, ~BIT(2)

     // Set EX PM PI test decodes (MC group 1: all EX chiplets)
        POREVE_INF("MC Group 1: Set PM PI test decodes in EX Cplt GP3 ...")
        sti     WRITE_ALL_EXS_GP3_OR_0x690F0014, P1, BIT(20)

     // Release endpoint reset (MC group 3: all chiplets except PRV)
        POREVE_INF("MC Group 3: Release Endpoint Reset ...")
        lpcs    P1, WRITE_ALL_FUNC_GP3_AND_0x6B0F0013
        sti     WRITE_ALL_FUNC_GP3_AND_0x6B0F0013, P1, ~BIT(1)

     // Partial Good Setting (MC group 3: all chiplets except PRV)
        POREVE_INF("MC Group 3: Partial Good Setting ...")
        sti     WRITE_ALL_FUNC_GP3_OR_0x6B0F0014 , P1, BIT(0)

     // Align f and f/2 tholds (MC group 1: all EX chiplets)
        POREVE_INF("MC Group 1: Align f and f/2 ...")
        lpcs    P1, WRITE_ALL_EXS_GP3_AND_0x690F0013
        sti     WRITE_ALL_EXS_GP0_AND_0x69000004, P1, ~BIT(62)

     // Skip ahead if not MPIPL
        ifbitclrscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, ci_enable_nest_subdomains

     // MPIPL, so make sure we actually have EXs to initialize
        lpcs    P0, ALL_EXS_BITX_0x51000000
        ld      D1, GENERIC_GP3_0x000F0012, P0
        braz    D1, mpipl_end

     // MPIPL with EXs, so clear errors, set P0 to ALL EX group, and branch ahead
        sti     GENERIC_PCB_ERR_0x000F001F, P1, BITS(0,64)
        bra     ci_ex_chiplet_scan_ratio

ci_enable_nest_subdomains:
     // Enable Nest Chiplet sub-domains
     // ===============================

     // Check for NX, MCL and MCR good bits

     // Setup MEM_BASE_ADDR0; points to partial good vector Chiplet 02 (Nest)
        lia     A0, PORE_SPACE_SEEPROM, combined_good_vectors
        adds    A0, A0, 0x10

     // Setup PRV_BASE_ADDR1; points to Nest Chiplet
        lpcs    P1, NEST_CHIPLET_0x02000000

ci_check_NX_good:

     // Load Nest Partial Good Vector and unfence NX if good
        ldandi  D0, 0x0, A0, BIT(6)
        braz    D0, ci_check_MCL_good
        sti     NEST_GP0_OR_0x02000005, P1, BIT(53)

ci_check_MCL_good:

     // Load Nest Partial Good Vector and unfence MCL if good
        ldandi  D0, 0x0, A0, BIT(8)
        braz    D0, ci_check_MCR_good
        sti     NEST_GP0_OR_0x02000005, P1, BIT(51)

ci_check_MCR_good:

     // Load Nest Partial Good Vector and unfence MCR if good
        ldandi  D0, 0x0, A0, BIT(9)
        braz    D0, ci_continue_multicast_setup
        sti     NEST_GP0_OR_0x02000005, P1, BIT(52)


ci_continue_multicast_setup:

     // Some more setups via Multicasts
     // ===============================

     // PCB Slave Error Register Reset (MC group 3: all chiplets except PRV)
        POREVE_INF("MC Group 3: Reset PCB Slave Error Register ...")
        lpcs    P1, WRITE_ALL_FUNC_GP3_AND_0x6B0F0013
        sti     SLAVE_PCB_ERR_0x6B0F001F, P1, BITS(0,64)


     // Setup scan ration to 8:1 for all chiplets except PRV
        POREVE_INF("Set scan ration to 8:1 for all chiplets except PRV ...")
        //Inputs: A1 and P0, destroys D0 & D1
        lpcs    P0, WRITE_ALL_OPCG_CNTL0_0x6B030002
ci_ex_chiplet_scan_ratio:
        lia     A1, PORE_SPACE_SEEPROM, proc_sbe_chiplet_init_control
        bsr     set_scan_ratio


     // Drop winkle fences for EX cplts (MC group 1: all EX chiplets)
     // POREVE_INF("MC Group 1: Drop Winkle Fences in PMGP0 ...")
        lpcs    P1, WRITE_EX_PMGP0_AND_0x690F0101
        sti     WRITE_EX_PMGP0_AND_0x690F0101, P1, ~(BIT(23) | BIT(39))

     // Skip to EX scan0 if MPIPL
        lpcs    P0, MBOX_SCRATCH_REG1_0x00050039
        ifbitsetscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, ci_scan0_EX

     // Some more setups via Unicast for enabled chiplets
     // =================================================

     // Nest Chiplet: Check for chiplet enabled and if so, set enable listen to sync pulse
        POREVE_INF("Check Nest Chiplet enable bit ...")
        lpcs    P1, NEST_CHIPLET_0x02000000
        ldandi  D0, GENERIC_GP3_0x000F0012, P1, BIT(0)
        braz    D0, ci_xbus_listen_to_sync

     // Nest Chiplet: Set enable listen to sync pulse
        POREVE_INF("Set listen to sync pulse ...")
        bsi     D0, GENERIC_CLK_SYNC_CONFIG_0x00030000, P1, BIT(11)

     // Nest Chiplet: Set default trace array mux control (=0010)
    POREVE_INF("Set nest trace array mux control ...")
    sti     GENERIC_GP0_OR_0x00000005, P1, BIT(30)

ci_xbus_listen_to_sync:

     // XBus Chiplet: Check for chiplet enabled and if so, set enable listen to sync pulse
        POREVE_INF("Check XBus Chiplet enable bit ...")
        lpcs    P1, XBUS_CHIPLET_0x04000000
        ldandi  D0, GENERIC_GP3_0x000F0012, P1, BIT(0)
        braz    D0, ci_scan0_mcgr3

     // XBus Chiplet: Set enable listen to sync pulse
        POREVE_INF("Set listen to sync pulse ...")
        bsi     D0, GENERIC_CLK_SYNC_CONFIG_0x00030000, P1, BIT(11)


ci_scan0_mcgr3:
     // Progress Indicator update
        updatestep STEP_SETUP_VIA_MC_DONE, D0, P0

     // Check for induced xstop
        lpcs    P1, MASTER_PCB_INT_0x000F001A
        ifbitclrscom D0, D0, MASTER_PCB_INT_0x000F001A, P1, 2, 1f
        POREVE_ERR("Checkstop detected via bit 2 in register F001A.  Halting\n");
        reqhalt    RC_SBE_PROC_CHECKSTOP
1:

     // Call SCAN0 for GPTR, TIME and REPAIR (MC group 3: all chiplets except PRV)
     // ==========================================================================
        POREVE_INF("MC Group 3: Call SCAN0 subroutine (GPTR/TIME/REPAIR)...")
     //
     // SCAN0 module -> see: proc_sbe_tp_chiplet_init2.S
     //
     // At entry:
     //
     //    P1 : The chiplet ID
     //    D0 : The clock regions (to be written to Clock Controller, Clock Region Register)
     //    D1 : The scan selects  (to be written to Clock Controller, Scan Select Register)
     //
     // At exit:
     //
     //    P0, D0, D1, CTR  : destroyed
     //    P1, A0, A1       : maintained
     //

        ls      P1, SCAN_CHIPLET_GROUP3
ci_scan0_EX:
        li      D0, SCAN_ALLREGIONEXVITAL
        li      D1, SCAN_GPTR_TIME_REP
        bsr     seeprom_scan0_module


     // Murano DD10 circumvention - Part 1 of 2                                      // DD10 Murano only CIRCUMVENTION - to get arrays X-state free
        sti     GENERIC_GP0_OR_0x00000005, P1, (BIT(8) | BIT(14))                    // DD10 Murano only CIRCUMVENTION - to get arrays X-state free
        ld      D0, GENERIC_OPCG_CNTL2_0x00030004, P0                                // DD10 Murano only CIRCUMVENTION - to get arrays X-state free
        ori     D0, D0, BIT(53)                                                      // DD10 Murano only CIRCUMVENTION - to get arrays X-state free
        std     D0, GENERIC_OPCG_CNTL2_0x00030004, P1                                // DD10 Murano only CIRCUMVENTION - to get arrays X-state free

     // Progress Indicator update
        updatestep STEP_MCGR3_SCAN0_1_DONE, D0, P0



     // Call SCAN0 for all rings except GPTR, TIME and REPAIR (MC group 3: all chiplets except PRV)
     // ===========================================================================================
        POREVE_INF("MC Group 3: Call SCAN0 subroutine (except GPTR/TIME/REPAIR) ...")
     //
     // SCAN0 module -> see: proc_sbe_tp_chiplet_init2.S
     //
     // At entry:
     //
     //    P1 : The chiplet ID
     //    D0 : The clock regions (to be written to Clock Controller, Clock Region Register)
     //    D1 : The scan selects  (to be written to Clock Controller, Scan Select Register)
     //
     // At exit:
     //
     //    P0, D0, D1, CTR  : destroyed
     //    P1, A0, A1       : maintained
     //

        //Keep P1 at current value rather than setting it again, to support MPIPL
        li      D0, SCAN_ALLREGIONEXVITAL
        li      D1, SCAN_ALLSCANEXPRV
        bsr     seeprom_scan0_module

     // Murano DD10 circumvention - Part 2 of 2                                      // DD10 Murano only CIRCUMVENTION - to get arrays X-state free
        sti     GENERIC_GP0_AND_0x00000004, P1, ~(BIT(8) | BIT(14))                  // DD10 Murano only CIRCUMVENTION - to get arrays X-state free
        ld      D0, GENERIC_OPCG_CNTL2_0x00030004, P0                                // DD10 Murano only CIRCUMVENTION - to get arrays X-state free
        andi    D0, D0, ~BIT(53)                                                     // DD10 Murano only CIRCUMVENTION - to get arrays X-state free
        std     D0, GENERIC_OPCG_CNTL2_0x00030004, P1                                // DD10 Murano only CIRCUMVENTION - to get arrays X-state free


     // Progress Indicator update
        updatestep STEP_MCGR3_SCAN0_2_DONE, D0, P0

     // Check for induced xstop
        lpcs    P1, MASTER_PCB_INT_0x000F001A
        ifbitclrscom D0, D0, MASTER_PCB_INT_0x000F001A, P1, 2, 1f
        POREVE_ERR("Checkstop detected via bit 2 in register F001A.  Halting\n");
        reqhalt    RC_SBE_PROC_CHECKSTOP
1:

     // =================
     // Start of Looper 2
     // =================
        POREVE_INF("Start Looper 2 ...")
     //
     // Loop thru all remaining good chiplets
     // =====================================
     //   - Scan Repair/Time Containers
     // =====================================

     // Setup MEM_BASE_ADDR0; points to partial good vector
        lia     A0, PORE_SPACE_SEEPROM, combined_good_vectors

     // Check for MPIPL
        ifbitclrscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, ci_loop2_init
     // Need to skip into the middle of the loop
     // Use CTR as index variable to iterate thru chiplets (init to cplt 0x11 = EX01)
        ls      CTR, 0x11
     // increment pointer to point to partial good vector Chiplet 0x11 (EX01)
        adds    A0, A0, 0x8*0x11
        bra     ci_loop2_start

ci_loop2_init:
     // Use CTR as index variable to iterrate thru chiplets (init to cplt #2 = NEST)
        ls      CTR, 0x2
     // Skip over chiplets 0 & 1 (ie. pervasive) of partial good vector
        adds    A0, A0, 2*0x8

ci_loop2_start:

     // Get the combined good vector for the current chiplet ID
        POREVE_INF("Looper 2 Iteration start ...")
        POREVE_INF("Get the combined good vector for the current chiplet ID ...")
        ld      D0, 0x0, A0
        andi    D0, D0, BITS(4,16)

     // If current chiplet has no good regions, end this loop iterration and go to next chiplet
        braz    D0, ci_loop2_cplt_done

ci_loop2_scan_repair_time:

     // Do a Repair/Time scan for the current chiplet (by calling the scan subroutine)
     // ==============================================================================
        POREVE_INF("This is a (at least partial) good Chiplet, so starting scan of Repair/Time ...")

     // Per Chiplet scan sections
     // =========================

ci_scan_nest:

        mr      D1, CTR
        xori    D1, D1, 0x02
        branz   D1, ci_scan_xbus

     // Nest Chiplet scan section
     // -------------------------

        POREVE_INF("Scanning Nest GPTR/Repair/Time rings ...")
        bsr     store_ctr_a0_d0_module
        lpcs    P0, NEST_CHIPLET_0x02000000

        load_ring pb_gptr_dmipll skipoverride=1
        load_ring pb_gptr_nest   skipoverride=1
        load_ring pb_gptr_perv   skipoverride=1
        load_ring pb_gptr_pcis   skipoverride=1     // turn on clock off if not used
        load_ring pb_time        skipoverride=1
        load_ring pb_repr        skipoverride=1

ci_scan_nest_mcl:

        lpcs    P0, NEST_CHIPLET_0x02000000
        ldandi  D1, NEST_GP0_0x02000000, P0, BIT(51)
        braz    D1, ci_scan_nest_mcr

        load_ring pb_gptr_mcl  skipoverride=1
        load_ring pb_time_mcl  skipoverride=1
        load_ring pb_repr_mcl  skipoverride=1

ci_scan_nest_mcr:

        lpcs    P0, NEST_CHIPLET_0x02000000
        ldandi  D1, NEST_GP0_0x02000000, P0, BIT(52)
        braz    D1, ci_scan_nest_nx

        load_ring pb_gptr_mcr  skipoverride=1
        load_ring pb_time_mcr  skipoverride=1
        load_ring pb_repr_mcr  skipoverride=1

ci_scan_nest_nx:

        lpcs    P0, NEST_CHIPLET_0x02000000
        ldandi  D1, NEST_GP0_0x02000000, P0, BIT(53)
        braz    D1, ci_scan_nest_restore

        load_ring pb_gptr_nx   skipoverride=1
        load_ring pb_time_nx   skipoverride=1
        load_ring pb_repr_nx   skipoverride=1

ci_scan_nest_restore:
        bsr     restore_ctr_a0_d0_module

ci_scan_xbus:

        mr      D1, CTR
        xori    D1, D1, 0x04
        branz   D1, ci_scan_abus

     // XBus Chiplet scan section
     // -------------------------

        POREVE_INF("Scanning XBus GPTR/Repair/Time rings ...")
        bsr     store_ctr_a0_d0_module
        lpcs    P0, X_BUS_CHIPLET_0x04000000

        load_ring xb_gptr_iopci skipoverride=1   //psi
        load_ring xb_gptr_iox   skipoverride=1
        load_ring xb_gptr_pben  skipoverride=1
        load_ring xb_gptr_perv  skipoverride=1
        load_ring xb_time       skipoverride=1
        load_ring xb_repr       skipoverride=1

        bsr     restore_ctr_a0_d0_module

ci_scan_abus:

        mr      D1, CTR
        xori    D1, D1, 0x08
        branz   D1, ci_scan_pcie

     // ABus Chiplet scan section
     // -------------------------

        POREVE_INF("Scanning ABus GPTR/Repair/Time rings ...")
        bsr     store_ctr_a0_d0_module

     // determine chip type
        lpcs    P0, STBY_CHIPLET_0x00000000
	ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P0, CFAM_CHIP_ID_CHIP_MASK

     // retarget ABus chiplet
	lpcs    P0, A_BUS_CHIPLET_0x08000000

     // leave scan ratio at 8:1 for Naples (tied to nest grid)
	cmpibraeq D0, ci_scan_abus2, CFAM_CHIP_ID_NAPLES

     // for Murano/Venice, set scan ratio to 1:1 (refclock)
        POREVE_INF("Set ABus scan ratio to 1:1 ...")
        sti     A_OPCG_CNTL0_0x08030002, P0, 0x0

ci_scan_abus2:
        load_ring ab_gptr_ab    skipoverride=1
        load_ring ab_gptr_ioa   skipoverride=1
        load_ring ab_gptr_perv  skipoverride=1
        load_ring ab_gptr_pll   skipoverride=1
        load_ring ab_time       skipoverride=1
        load_ring ab_repr       skipoverride=1

     // Set ABus scan ratio back to 8:1 as ABus
        POREVE_INF("Set ABus scan ratio to 8:1 ...")
        //Inputs: A1 and P0, destroys D0 & D1
        lia     A1, PORE_SPACE_SEEPROM, proc_sbe_chiplet_init_control
        bsr     set_scan_ratio

        bsr     restore_ctr_a0_d0_module

ci_scan_pcie:

        mr      D1, CTR
        xori    D1, D1, 0x09
        branz   D1, ci_scan_ex

     // PCIe Chiplet scan section
     // -------------------------

        POREVE_INF("Scanning PCIe GPTR/Repair/Time rings ...")
        bsr     store_ctr_a0_d0_module
        lpcs    P0, PCIE_CHIPLET_0x09000000

     // Set PCIe scan ratio to 1:1 as PCIe is still at refclock
        POREVE_INF("Set PCIe scan ratio to 1:1 ...")
        sti     PCIE_OPCG_CNTL0_0x09030002, P0, 0x0

        load_ring pci_gptr_iopci skipoverride=1
        load_ring pci_gptr_pbf   skipoverride=1
        load_ring pci_gptr_pci0  skipoverride=1
        load_ring pci_gptr_pci1  skipoverride=1
        load_ring pci_gptr_pci2  skipoverride=1
        load_ring pci_gptr_perv  skipoverride=1
        load_ring pci_gptr_pll   skipoverride=1
        load_ring pci_time       skipoverride=1
        load_ring pci_repr       skipoverride=1

     // Set PCIe scan ratio back to 8:1 as PCIe
        POREVE_INF("Set PCIe scan ratio to 8:1 ...")
        //Inputs: A1 and P0, destroys D0 & D1
        lia     A1, PORE_SPACE_SEEPROM, proc_sbe_chiplet_init_control
        bsr     set_scan_ratio

        bsr     restore_ctr_a0_d0_module

ci_scan_ex:

     // Skip EX section if no EX enabled
        lpcs    P0, ALL_EXS_BITX_0x51000000
        ld      D1, GENERIC_GP3_0x000F0012, P0
        braz    D1, ci_scan_ex_done


     // Set EX scan ratio to 1:1 as EX is still at refclock (via multicast)
	POREVE_INF("Set EX scan ratio to 1:1 ...")
        ls      P0, SCAN_CHIPLET_GROUP1
        sti     EX_OPCG_CNTL0_0x10030002, P0, 0x0


     // EX Chiplet scan section
     // -------------------------

        // Scan EX    (id, next)
        ci_scan_ex_gen  1,  2
        ci_scan_ex_gen  2,  3
        ci_scan_ex_gen  3,  4
        ci_scan_ex_gen  4,  5
        ci_scan_ex_gen  5,  6
        ci_scan_ex_gen  6,  9
        ci_scan_ex_gen  9, 10
        ci_scan_ex_gen 10, 11
        ci_scan_ex_gen 11, 12
        ci_scan_ex_gen 12, 13
        ci_scan_ex_gen 13, 14
        ci_scan_ex_gen 14, _done

ci_scan_ex_done:

ci_loop2_cplt_done:

     // We are now done with the loop for this chiplet; let's prepare for the next
     //   chiplet or end the looper
        POREVE_INF("Chiplet complete")

     // Increment the chiplet index
        adds    CTR, 0x1
        adds    A0, 0x8

     // Check whether we reached chiplet id 32, otherwise start next iterration
        mr      D1, CTR
        andi    D1, D1, 0x20
        braz    D1, ci_loop2_start

     // ===============
     // End of Looper 2
     // ===============


     // Check for induced xstop
        lpcs    P1, MASTER_PCB_INT_0x000F001A
        ifbitclrscom D0, D0, MASTER_PCB_INT_0x000F001A, P1, 2, 1f
        POREVE_ERR("Checkstop detected via bit 2 in register F001A.  Halting\n");
        reqhalt    RC_SBE_PROC_CHECKSTOP
1:
        POREVE_INF("Looper 2 is complete")

     // rewrite pibmem field which documents need for LCO hash disable
     // ci_scan_ex_gen macro stores total victim count into low-order bits
     // of lco_config
     // retrieve this count and store back LCO hash disable
     //   1 if victim count is 0/1/2
     //   0 otherwise
        lpcs    P0, STBY_CHIPLET_0x00000000

     // retrieve LCO victim count
        ld      D0, lco_config, P0
        mr      D1, D0
        andi    D0, D0, BITS(59, 5)
        andi    D1, D1, ~BITS(59, 5)
        subs    D0, D0, 3
        tfbuge  D0, ci_ex_lco_write_enable
        ori     D1, D1, BIT(63)
ci_ex_lco_write_enable:
        POREVE_INF("Writing LCO config to set hash disable (%016llX) ...", io_pore.d1.read())
        std    D1, lco_config, P0

     // Progress Indicator update
        updatestep STEP_LOOP2_DONE, D0, P0

ci_ex_gptr_scan:

     // Scan all good EX GPTR rings
     // ===========================

     // Skip EX section if no EX enabled
        lpcs    P0, ALL_EXS_BITX_0x51000000
        ld      D1, GENERIC_GP3_0x000F0012, P0
        braz    D1, ci_scan_ex_gptr_done

        ls      P0, SCAN_CHIPLET_GROUP1

        load_ring ex_gptr_perv   skipoverride=1
        load_ring ex_gptr_dpll   skipoverride=1
        load_ring ex_gptr_l3     skipoverride=1
        load_ring ex_gptr_l3refr skipoverride=1

     // Set EX scan ratio back to 8:1
        POREVE_INF("Set EX scan ratio to 8:1 ...")
        //Inputs: A1 and P0, destroys D0 & D1
        lia     A1, PORE_SPACE_SEEPROM, proc_sbe_chiplet_init_control
        bsr     set_scan_ratio

ci_scan_ex_gptr_done:
     // Progress Indicator update
        lpcs    P0, STBY_CHIPLET_0x00000000
        updatestep STEP_EX_MC_SCAN_DONE, D0, P0

ci_complete:

        POREVE_INF("*** End of Procedure ***")
        .end_procedure proc_sbe_chiplet_init

