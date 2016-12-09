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

	// Control bit vector for all SLW procedures
        .xip_quad slw_control_vector, 0

// Ring Lookup Table -------------------------------------------------------

        .ipl_data

	// Functional rings (+ overrides)
        .xip_quad ex_func_core_ring, 0, 2
        .xip_quad ex_func_l3_ring, 0, 2
        .xip_quad ex_func_l3refr_ring, 0, 2
        .xip_quad ex_fary_l2_ring, 0, 2
        .xip_quad ex_func_dpll_ring, 0, 2

        .xip_quad ex_func_perv_ring, 0, 2
        .xip_quad ex_abfa_eco_ring, 0, 2
        .xip_quad ex_cmsk_eco_ring, 0, 2
        .xip_quad ex_regf_l3_ring, 0, 2
        .xip_quad ex_regf_l3refr_ring, 0, 2
        .xip_quad ex_lbst_eco_ring, 0, 2
        .xip_quad ex_abfa_core_ring, 0, 2
        .xip_quad ex_cmsk_core_ring, 0, 2
        .xip_quad ex_lbst_core_ring, 0, 2
        .xip_quad ex_regf_core_ring, 0, 2

        .xip_quad perv_func_pll_ring, 0, 2
        .xip_quad perv_abst_ring, 0, 2
        .xip_quad perv_func_occ_ring, 0, 2
        .xip_quad perv_func_perv_ring, 0, 2
        .xip_quad perv_farr_ring, 0, 2
        .xip_quad perv_lbst_ring, 0, 2
        .xip_quad perv_regf_ring, 0, 2
        .xip_quad perv_cmsk_ring, 0, 2

        .xip_quad pb_abst_ring, 0, 2
        .xip_quad pb_abst_mcr_ring, 0, 2
        .xip_quad pb_abst_mcl_ring, 0, 2
        .xip_quad pb_abst_nx_ring, 0, 2
        .xip_quad pb_bndy_mcr_ring, 0, 2
        .xip_quad pb_bndy_mcl_ring, 0, 2
        .xip_quad pb_cmsk_ring, 0, 2
        .xip_quad pb_cmsk_nx_ring, 0, 2
        .xip_quad pb_farr_ring, 0, 2
        .xip_quad pb_farr_mcr_ring, 0, 2
        .xip_quad pb_farr_mcl_ring, 0, 2
        .xip_quad pb_farr_nx_ring, 0, 2
        .xip_quad pb_func_dmipll_ring, 0, 2
        .xip_quad pb_func_mcr_ring, 0, 2
        .xip_quad pb_func_mcl_ring, 0, 2
        .xip_quad pb_func_nest_ring, 0, 2
        .xip_quad pb_func_nx_ring, 0, 2
        .xip_quad pb_func_pcis_ring, 0, 2
        .xip_quad pb_func_perv_ring, 0, 2
        .xip_quad pb_lbst_ring, 0, 2
        .xip_quad pb_lbst_nx_ring, 0, 2
        .xip_quad pb_lbst_perv_ring, 0, 2
        .xip_quad pb_regf_mcr_ring, 0, 2
        .xip_quad pb_regf_mcl_ring, 0, 2
        .xip_quad pb_regf_nest_ring, 0, 2
        .xip_quad pb_regf_nx_ring, 0, 2
        .xip_quad pb_regf_pcis_ring, 0, 2
        .xip_quad xb_abst_ring, 0, 2
        .xip_quad xb_bndy_io_ring, 0, 2
        .xip_quad xb_cmsk_ring, 0, 2
        .xip_quad xb_farr_ring, 0, 2
        .xip_quad xb_func_iopci_ring, 0, 2
        .xip_quad xb_func_iox_ring, 0, 2
        .xip_quad xb_func_pben_ring, 0, 2
        .xip_quad xb_func_perv_ring, 0, 2
        .xip_quad xb_lbst_perv_ring, 0, 2
        .xip_quad xb_regf_xb_ring, 0, 2
        .xip_quad ab_abst_ring, 0, 2
        .xip_quad ab_bndy_ioa_ring, 0, 2
        .xip_quad ab_cmsk_ring, 0, 2
        .xip_quad ab_farr_ring, 0, 2
        .xip_quad ab_func_ab_ring, 0, 2
        .xip_quad ab_func_ioa_ring, 0, 2
        .xip_quad ab_func_perv_ring, 0, 2
        .xip_quad ab_func_pll_ring, 0, 2
        .xip_quad ab_lbst_ring, 0, 2
        .xip_quad ab_regf_ring, 0, 2
        .xip_quad pci_abst_ring, 0, 2
        .xip_quad pci_bndy_iopci_ring, 0, 2
        .xip_quad pci_cmsk_ring, 0, 2
        .xip_quad pci_farr_ring, 0, 2
        .xip_quad pci_func_iopci_ring, 0, 2
        .xip_quad pci_func_pbf_ring, 0, 2
        .xip_quad pci_func_pci0_ring, 0, 2
        .xip_quad pci_func_pci1_ring, 0, 2
        .xip_quad pci_func_pci2_ring, 0, 2
        .xip_quad pci_func_perv_ring, 0, 2
        .xip_quad pci_func_pll_ring, 0, 2
        .xip_quad pci_lbst_ring, 0, 2
        .xip_quad pci_regf_ring, 0, 2

        //The default PLL rings (no override)
        .xip_quad perv_bndy_pll_ring, 0
	.xip_quad pb_bndy_dmipll_ring, 0
	.xip_quad ab_bndy_pll_ring, 0
	.xip_quad pci_bndy_pll_ring, 0

	// Repair rings (no overrides, no defaults)
        // These need to be in the proc_sbe_fixed.H file!


//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------
        .set MPIPL_BITNUM, 0

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .ipl_text

        .xip_address entry_point, _sbe_seeprom_start

        .global _sbe_seeprom_start
_sbe_seeprom_start:
	// Establish the MRR for SBE execution from SEEPROM, then switch to
	// relocatable code addressing and istep.
        lpcs    P0, PORE_SBE_MEMORY_RELOC_0x000E0016
        sti     PORE_SBE_MEMORY_RELOC_0x000E0016, P0, SBE_SEEPROM_MRR
	braa	1f
1:
        //------------------------------------------------//
        //------------------- ISTEP 2 --------------------//
        //------------------------------------------------//
        .callproc proc_sbe_security_setup skiperrorchecks=1
        .callproc proc_sbe_standalone_setup skiperrorchecks=1
        //Skip tp_chiplet_init1 on MPIPL
        lpcs    P0, MBOX_SCRATCH_REG1_0x00050039
        ifbitsetscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, mpipl_part_1
        .callproc proc_sbe_tp_chiplet_init1 skiperrorchecks=1
mpipl_part_1:
        .callproc proc_sbe_tp_ld_image skiperrorchecks=1
	// MPIPL only: Halt the OCC and hold it in reset: SW232655 + SW259140
	lpcs	P0, MBOX_SCRATCH_REG1_0x00050039
	ifbitclrscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, non_mpipl_part_1
        // This procedure is equivalent to the procedure coded in
        // p8_occ_control.C as the PPC405_RESET_SEQUENCE option. See that
        // procedure for further background and details. Briefly:
        //
        // 1. Save the original OCC FIR mask
        // 2. Mask the "OCC halted" FIR bit to avoid confusion
        // 3. Halt the 405 (to avoid bus protocol violations)
        // 4. Give the 405 100us to halt (100us @ 600MHz == 0xea60 cycles)
        // 5. Put (and hold) the 405 in(to) reset
        // 6. Un-halt the 405
        // 7. Clear the "OCC halted" FIR bit
        // 8. Restore the original FIR mask
        //
        // Once P0 and P1 are initialized, each line above translates into a
        // line of assembly.
        ls      P0, 0x00
        ls      P1, 0x01
        ld      D0, OCC_LFIR_MASK_0x01010803, P1
        sti     OCC_LFIR_MASK_OR_0x01010805, P1, BIT(25)
        sti     OCC_JTG_PIB_OJCFG_OR_0x0006B006, P0, BIT(6)
        waits   0xea60
        sti     OCC_CONTROL_OR_0x0006B002, P0, BIT(0) # SW232655 incomplete fix
        sti     OCC_JTG_PIB_OJCFG_AND_0x0006B005, P0, ~BIT(6)
        sti     OCC_LFIR_AND_0x01010801, P1, ~BIT(25)
        std     D0, OCC_LFIR_MASK_0x01010803, P1
	//Skip TP & PLL setup on MPIPL
	bra	mpipl_part_2
non_mpipl_part_1:
        .callproc proc_sbe_npll_initf skiperrorchecks=1
        .callproc proc_sbe_npll_setup skiperrorchecks=1
        .callproc proc_sbe_tp_switch_gears skiperrorchecks=1
        .callproc proc_sbe_tp_chiplet_init2 skiperrorchecks=1
        .callproc proc_sbe_tp_arrayinit skiperrorchecks=1
        .callproc proc_sbe_tp_initf skiperrorchecks=1
        .callproc proc_sbe_tp_chiplet_init3
mpipl_part_2:
        .callproc proc_sbe_chiplet_init
        //Skip skew adjust/arrayinit on MPIPL
        lpcs    P0, MBOX_SCRATCH_REG1_0x00050039
        ifbitsetscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, mpipl_part_3
	.callproc proc_sbe_nest_skewadjust
        .callproc proc_sbe_arrayinit
mpipl_part_3:
        .callproc proc_sbe_setup_evid
        .callproc proc_sbe_initf
        //Skip PB Clocks on MPIPL
        lpcs    P0, MBOX_SCRATCH_REG1_0x00050039
        ifbitsetscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, mpipl_part_4
        .callproc proc_sbe_pb_startclocks
mpipl_part_4:             
        // Reestablish Untrusted BARs as they could have changed
	.callproc proc_sbe_scominit       
        //Skip Fabric Init on MPIPL
        lpcs    P0, MBOX_SCRATCH_REG1_0x00050039
        ifbitsetscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, mpipl_part_5
        .callproc proc_sbe_fabricinit       
        lpcs    P0, MBOX_SCRATCH_REG1_0x00050039
        ifbitclrscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P0, MPIPL_BITNUM, mpipl_end
mpipl_part_5:
        //Run a portion of the EX scominit that we skipped over
        bsr     proc_sbe_ex_winkle_setup
        .global mpipl_end
mpipl_end:     
        .callproc proc_sbe_check_master
        .callproc proc_sbe_select_ex

        //------------------------------------------------//
        //------------------- ISTEP 4 --------------------//
        //------------------------------------------------//
        .callproc proc_sbe_run_exinit

        //------------------------------------------------//
        //------------------- ISTEP 5 --------------------//
        //------------------------------------------------//
	.callproc proc_sbe_enable_pnor
        .callproc proc_sbe_lco_loader
        .callproc proc_sbe_instruct_start
        .callproc proc_sbe_trigger_winkle

        .global _sbe_seeprom_halt
_sbe_seeprom_halt:
        // Unlock seeprom access before halting
        POREVE_DBG("Unlocking SEEPROM access before halting\n") ;
        lpcs    P1, MBOX_FSIGP4_0x00050013
        bci     D0, MBOX_FSIGP4_0x00050013, P1, BIT(20)

        //Halt with success
        reqhalt RC_SBE_SUCCESS, D0, P1

