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



#ifndef __PROC_SBE_FIXED_H__
#define __PROC_SBE_FIXED_H__

// $Id: proc_sbe_fixed.H,v 1.36 2015/05/28 20:48:08 jmcgill Exp $

/// \file proc_sbe_fixed.H
/// \brief Define the layout of fixed-position data in the P8 SBE reference
/// and IPL images
///
/// This file defines the layout of the special .fixed data section of P8 SBE
/// reference and IPL images.  The .fixed section is guaranteed to appear at a
/// fixed offset from the beginning of the image, containing data required to
/// be manipulated when images are resident in non-volatile memories, thereby
/// avoiding having to search the TOC. Data manipulated during in-memory image
/// processing can always be easily located using the SBE-XIP TOC APIs.  All
/// of the data stored in .fixed can also still be referenced via the SBE-XIP
/// TOC.
///
/// This header file can be #include-ed into either C or SBE assembly language
/// source code.  In C, it creates a simple structure 'ProcSbeFixed' that is
/// nothing more than an ordered set of uint64_t variables.  PORE image data
/// is always stored big-endian, so applications on little-endian hosts will
/// need to perform the appropriate endian converison when reading or writing
/// images via this header.
///
/// In assembler code, this header creates a macro '.proc_sbe_fixed' that is
/// expanded exactly once in the file 'sbe_base_header.S', creating the actual
/// data allocation of the data equivalent to the C structure.  Assembler code
/// references the data symbols as normal.
///
/// To simplify programming a 'mini-TOC' is also provided for this data in
/// the .fixed_toc section.  This section is comprised of SbeXipHashedToc
/// structures. When a symbol is indedxed in .fixed, a blank SbeXipHashedToc
/// stucture is added to .fixed_toc.  During image normalization the array of
/// SbeXipHashedToc is filled in as each symbol in .fixed is re-indexed into
/// .fixed_toc.

#include "p8_sbe.H"

#ifdef __ASSEMBLER__
             .macro	.proc_sbe_fixed
	     .section   .fixed, "a", @progbits
	     .balign    8
#else
typedef struct {
#endif

    // Procedure control variables listed in istep order

    //*************************************************************//
    //*                         READ THIS!!!                      *//
    //*                                                           *//
    //*   The locations in this file are "fixed", meaning that    *//
    //*   nothing may be deleted, and new things may only be      *//
    //*   added to the very END of the file. This means that      *//
    //*   some entries are not going to be in the correct order   *//
    //*                                                           *//
    //*************************************************************//

    PROC_SBE_FIXED_UINT64(proc_sbe_security_setup_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_tp_chiplet_init1_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_nest_skewadjust_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_tp_ld_image_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_pibmem_loader_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_npll_initf_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_npll_setup_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_tp_switch_gears_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_tp_chiplet_init2_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_tp_arrayinit_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_tp_chiplet_init3_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_chiplet_init_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_arrayinit_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_setup_evid_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_initf_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_pb_startclocks_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_scominit_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_fabricinit_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_check_master_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_select_ex_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_run_exinit_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_chiplet_reset_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_gptr_time_initf_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_core_gptr_time_initf_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_dpll_initf_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_dpll_setup_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_chiplet_init_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_repair_initf_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_core_repair_initf_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_arrayinit_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_initf_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_core_initf_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_do_manual_inits_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_startclocks_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_scominit_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_core_scominit_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_init_escape_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_sp_runtime_scom_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_occ_runtime_scom_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_ex_host_runtime_scom_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_enable_pnor_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_lco_loader_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_instruct_start_control);
    PROC_SBE_FIXED_UINT64(proc_sbe_trigger_winkle_control);


    PROC_SBE_FIXED_UINT64(proc_sbe_pibmem_repair_vector);

    // The combined good vectors
    //
    //              res.| 16 Comb. Reg.| res.
    //                  |              |
    //                  0000000000111111
    //                  0123456789012345
    //
    // Chiplet ID
    //
    // 00 : PIB
    // 01 : Pervasive
    // 02 : PowerBus
    // 03 : n/a
    // 04 : X-Bus
    // 05 : n/a
    // 06 : n/a
    // 07 : n/a
    // 08 : A-Bus
    // 09 : PCI
    // 0A : n/a
    // 0B : n/a
    // 0C : n/a
    // 0D : n/a
    // 0E : n/a
    // 0F : n/a
    // 10 : EX 0
    // 11 : EX 1
    // 12 : EX 2
    // 13 : EX 3
    // 14 : EX 4
    // 15 : EX 5
    // 16 : EX 6
    // 17 : EX 7
    // 18 : EX 8
    // 19 : EX 9
    // 1A : EX 10
    // 1B : EX 11
    // 1C : EX 12
    // 1D : EX 13
    // 1E : EX 14
    // 1F : EX 15

    PROC_SBE_FIXED_UINT64_VECTOR(combined_good_vectors, 32);

    // The nest skewadjust vector
    //
    // Contains 3 sets (nominal, fast and slow) of skewadjust vectors and a valid bit per setting
    //
    // 0000 0000 0011 1111 1111 2222 2222 2233 3333 3333 4444 4444 4455 5555 5555 6666
    // 0123 4567 8901 2345 6789 0123 4567 8901 2345 6789 0123 4567 8901 2345 6789 0123
    //
    // ..vn nnnn ..vf ffff ..vs ssss .... .... .... .... .... .... .... .... .... ....

    PROC_SBE_FIXED_UINT64(proc_sbe_nest_skewadjust_vector);

    // Fabric configuration data:
    // DW0 -> ADU Untrusted BAR value (secure mode)
    // DW1 -> ADU Untrusted BAR Mask value (secure mode)
    // DW2 -> PSI Untrusted BAR0 value (secure mode)
    // DW3 -> PSI Untrusted BAR0 Mask value (secure mode)
    // DW4 -> PSI Untrusted BAR1 value (secure mode)
    // DW5 -> PSI Untrusted BAR1 Mask value (secure mode)
    PROC_SBE_FIXED_UINT64_VECTOR(fabric_config, 6);

    // per-chiplet L2 single member mode configuration data
    PROC_SBE_FIXED_UINT64(l2_single_member_enable_mask);

    PROC_SBE_FIXED_UINT64(proc_sbe_security_setup_vector);

    // The delta_scan procedure needs the entry point of
    // proc_sbe_decompress_scan_chiplet in PIBMEM indexed in the
    // TOC.

    PROC_SBE_FIXED_QUADIA(proc_sbe_decompress_scan_chiplet_address,
                          PORE_SPACE_PIBMEM,
                          proc_sbe_decompress_scan_chiplet);

    //Alternate PLL ring
    PROC_SBE_FIXED_UINT64(perv_bndy_pll_ring_alt);

    //Repair rings
    PROC_SBE_FIXED_UINT64(perv_repr_ring);
    PROC_SBE_FIXED_UINT64(perv_repr_net_ring); //Not scannable
    PROC_SBE_FIXED_UINT64(perv_repr_pib_ring); //Not scannable
    PROC_SBE_FIXED_UINT64(pb_repr_ring);
    PROC_SBE_FIXED_UINT64(pb_repr_mcl_ring);
    PROC_SBE_FIXED_UINT64(pb_repr_mcr_ring);
    PROC_SBE_FIXED_UINT64(pb_repr_nx_ring);
    PROC_SBE_FIXED_UINT64(xb_repr_ring);
    PROC_SBE_FIXED_UINT64(ab_repr_ring);
    PROC_SBE_FIXED_UINT64(pci_repr_ring);
    PROC_SBE_FIXED_UINT64_VECTOR(ex_repr_core_ring, 16);
    PROC_SBE_FIXED_UINT64_VECTOR(ex_repr_eco_ring, 16);

    //Gptr rings
    PROC_SBE_FIXED_UINT64(ab_gptr_perv_ring);
    PROC_SBE_FIXED_UINT64(ab_gptr_ab_ring);
    PROC_SBE_FIXED_UINT64(ab_gptr_ioa_ring);
    PROC_SBE_FIXED_UINT64(ab_gptr_pll_ring);
    PROC_SBE_FIXED_UINT64(ex_gptr_perv_ring);
    PROC_SBE_FIXED_UINT64(ex_gptr_core_ring);
    PROC_SBE_FIXED_UINT64(ex_gptr_l2_ring);
    PROC_SBE_FIXED_UINT64(ex_gptr_l3_ring);
    PROC_SBE_FIXED_UINT64(ex_gptr_l3refr_ring);
    PROC_SBE_FIXED_UINT64(ex_gptr_dpll_ring);
    PROC_SBE_FIXED_UINT64(pb_gptr_perv_ring);
    PROC_SBE_FIXED_UINT64(pb_gptr_nest_ring);
    PROC_SBE_FIXED_UINT64(pb_gptr_nx_ring);
    PROC_SBE_FIXED_UINT64(pb_gptr_pcis_ring);
    PROC_SBE_FIXED_UINT64(pb_gptr_mcl_ring);
    PROC_SBE_FIXED_UINT64(pb_gptr_mcr_ring);
    PROC_SBE_FIXED_UINT64(pb_gptr_dmipll_ring);
    PROC_SBE_FIXED_UINT64(pci_gptr_perv_ring);
    PROC_SBE_FIXED_UINT64(pci_gptr_pci0_ring);
    PROC_SBE_FIXED_UINT64(pci_gptr_pci1_ring);
    PROC_SBE_FIXED_UINT64(pci_gptr_pci2_ring);
    PROC_SBE_FIXED_UINT64(pci_gptr_iopci_ring);
    PROC_SBE_FIXED_UINT64(pci_gptr_pbf_ring);
    PROC_SBE_FIXED_UINT64(pci_gptr_pll_ring);
    PROC_SBE_FIXED_UINT64(perv_gptr_perv_ring);
    PROC_SBE_FIXED_UINT64(perv_gptr_net_ring); //Not scannable
    PROC_SBE_FIXED_UINT64(perv_gptr_pib_ring); //Not scannable
    PROC_SBE_FIXED_UINT64(perv_gptr_occ_ring);
    PROC_SBE_FIXED_UINT64(perv_gptr_pll_ring);
    PROC_SBE_FIXED_UINT64(xb_gptr_perv_ring);
    PROC_SBE_FIXED_UINT64(xb_gptr_iox_ring);
    PROC_SBE_FIXED_UINT64(xb_gptr_iopci_ring);
    PROC_SBE_FIXED_UINT64(xb_gptr_pben_ring);

    //Time rings
    PROC_SBE_FIXED_UINT64(ab_time_ring);
    PROC_SBE_FIXED_UINT64_VECTOR(ex_time_core_ring, 16);
    PROC_SBE_FIXED_UINT64_VECTOR(ex_time_eco_ring, 16);
    PROC_SBE_FIXED_UINT64(pb_time_ring);
    PROC_SBE_FIXED_UINT64(pb_time_mcl_ring);
    PROC_SBE_FIXED_UINT64(pb_time_mcr_ring);
    PROC_SBE_FIXED_UINT64(pb_time_nx_ring);
    PROC_SBE_FIXED_UINT64(pci_time_ring);
    PROC_SBE_FIXED_UINT64(perv_time_net_ring); //Not scannable
    PROC_SBE_FIXED_UINT64(perv_time_pib_ring); //Not scannable
    PROC_SBE_FIXED_UINT64(perv_time_ring);
    PROC_SBE_FIXED_UINT64(xb_time_ring);

    //Standalone setup
    PROC_SBE_FIXED_UINT64(proc_sbe_standalone_setup_control);
#ifdef __ASSEMBLER__
    .global standalone_mbox_values
standalone_mbox_values:  
#endif
    PROC_SBE_FIXED_UINT64(standalone_mbox0_value);
    PROC_SBE_FIXED_UINT64(standalone_mbox1_value);
    PROC_SBE_FIXED_UINT64(standalone_mbox2_value);
    PROC_SBE_FIXED_UINT64(standalone_mbox3_value);

  //Bitmask of the EX chiplets that have valid ring data in the seeprom
    PROC_SBE_FIXED_UINT64(valid_boot_cores_mask);

  //For Little-endian support: Set this to skip EX override ring scanning
    PROC_SBE_FIXED_UINT64(skip_ex_override_ring_scans);

  //Control word for an istep added late in the process
    PROC_SBE_FIXED_UINT64(proc_sbe_tp_initf_control);

  // Fabric configuration data:
  // DW0 -> PBA Untrusted BAR value (secure mode)
  // DW1 -> PBA Untrusted BAR Mask value (secure mode)
    PROC_SBE_FIXED_UINT64_VECTOR(fabric_config_pba, 2);

  // Sleep enable:
    PROC_SBE_FIXED_UINT64(pm_sleep_enable);

  // DMI/A/PCI pll rings
    PROC_SBE_FIXED_UINT64(pb_bndy_dmipll_ring_alt);
    PROC_SBE_FIXED_UINT64(ab_bndy_pll_ring_alt);
    PROC_SBE_FIXED_UINT64(pci_bndy_pll_ring_alt);

  // DMI/A PLL ring modifications
    PROC_SBE_FIXED_UINT64_VECTOR(pb_bndy_dmipll_refclk_sel_mod, 8);
    PROC_SBE_FIXED_UINT64_VECTOR(pb_bndy_dmipll_pfd360_mod, 8);
    PROC_SBE_FIXED_UINT64_VECTOR(ab_bndy_pll_refclk_sel_mod, 3);
    PROC_SBE_FIXED_UINT64_VECTOR(ab_bndy_pll_pfd360_mod, 3);

  // SBE interrupt service customization
    PROC_SBE_FIXED_UINT64(intr_decrementer_delay_cycles);
    PROC_SBE_FIXED_UINT64(intr_decrementer_delay_us);


#ifdef __ASSEMBLER__
	.endm
#else
} ProcSbeFixed;
#endif

#endif  // __PROC_SBE_FIXED_H__
