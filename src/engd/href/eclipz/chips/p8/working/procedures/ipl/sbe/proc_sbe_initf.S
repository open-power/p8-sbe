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
#include "proc_sbe_initf_common_seeprom.H"
#include "common_ecids.H"
        .list

// Hook includes
##`#include<stdio.h>

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
        .set MPIPL_BITNUM, 0

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

	// check chiplet partial good state, jump to target if not configured
	.macro ifcpltbad, id:req, target:req
	    lia     A0, PORE_SPACE_SEEPROM, combined_good_vectors
	    ld	D0, (\id*8), A0
	    andi	D0, D0, BITS(4,16)
        braz    D0, \target
    .endm

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
    .procedure proc_sbe_initf, ipl, "$Revision: 1.16 $"

        // Perform work-arounds
     // Skip EX section if no EX enabled
        lpcs    P0, ALL_EXS_BITX_0x51000000
        ld      D0, GENERIC_GP3_0x000F0012, P0
        braz    D0, scan_nest

        POREVE_DBG("EX Winkle work-around scan ...\n")

     // Setup P0 for MC group 2 (all functional EX chiplets)
        lpcs    P0, ALL_CORES_WRITE_0x6A000000

     // Set EX scan ratio to 1:1 as EX is still at refclock                                    //AK-LAB
        POREVE_INF("Set EX scan ratio to 1:1 ...\n")                 //AK-LAB
        sti     EX_OPCG_CNTL0_0x10030002, P0, 0x0                                              //AK-LAB

        load_ring ex_func_perv conditional_override=1

     // Set EX scan ratio back to 8:1                                                          //AK-LAB
        POREVE_INF("Set EX scan ratio to 8:1 ...\n")                 //AK-LAB
        ls      P0, SCAN_CHIPLET_GROUP1                                                        //AK-LAB
        //Inputs: A1 and P0, destroys D0 & D1
        lia     A1, PORE_SPACE_SEEPROM, proc_sbe_initf_control
        bsr     set_scan_ratio
        //Also save this value in pibmem
        ld      D0, 0x0, A1
        lpcs    P1, PIBMEM0_0x00080000
        .pibmem_port (PORE_SPACE_PIBMEM & 0xf) 
        std     D0, ex_scan_ratio_override, P1

        //Skip Nest on MPIPL
        ifbitsetscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P1, MPIPL_BITNUM, scan_done

scan_nest:
        ifcpltbad SCAN_CHIPLET_NEST, scan_xbus

        POREVE_DBG("Scanning Nest rings ...\n")
        lpcs    P0, NEST_CHIPLET_0x02000000

        load_ring pb_func_nest
        load_ring pb_func_perv
        load_ring pb_func_dmipll
        load_ring pb_regf_nest
        load_ring pb_farr
        load_ring pb_lbst
        load_ring pb_lbst_perv
        load_ring pb_abst
        load_ring pb_cmsk

	load_ring pb_func_pcis
	load_ring pb_regf_pcis

scan_nest_mcl:

        ldandi  D0, NEST_GP0_0x02000000, P0, BIT(51)
        braz    D0, scan_nest_mcr

        POREVE_DBG("Scanning Nest rings (MCL) ...\n")

        load_ring pb_func_mcl
        load_ring pb_regf_mcl
        load_ring pb_farr_mcl
        load_ring pb_abst_mcl
        load_ring pb_bndy_mcl

scan_nest_mcr:

        ldandi  D0, NEST_GP0_0x02000000, P0, BIT(52)
        braz    D0, scan_nest_nx

        POREVE_DBG("Scanning Nest rings (MCR) ...\n")

        load_ring pb_func_mcr
        load_ring pb_regf_mcr
        load_ring pb_farr_mcr
        load_ring pb_abst_mcr
        load_ring pb_bndy_mcr

scan_nest_nx:

         ldandi  D0, NEST_GP0_0x02000000, P0, BIT(53)
         braz    D0, scan_xbus

         POREVE_DBG("Scanning Nest rings (NX) ...\n")

         load_ring pb_func_nx
         load_ring pb_regf_nx
         load_ring pb_farr_nx
         load_ring pb_lbst_nx
         load_ring pb_abst_nx
         load_ring pb_cmsk_nx

scan_xbus:

         ifcpltbad SCAN_CHIPLET_XBUS, scan_abus

         POREVE_DBG("Scanning XBus rings ...\n")
         lpcs    P0, X_BUS_CHIPLET_0x04000000

         load_ring xb_func_iopci
         load_ring xb_func_iox
         load_ring xb_func_pben
         load_ring xb_func_perv
         load_ring xb_regf_xb
         load_ring xb_farr
         load_ring xb_lbst_perv
         load_ring xb_abst
         load_ring xb_cmsk
         load_ring xb_bndy_io

scan_abus:

        ifcpltbad SCAN_CHIPLET_ABUS, scan_pcie

        POREVE_DBG("Scanning ABus rings ...\n")

     // determine chip type
        lpcs    P0, STBY_CHIPLET_0x00000000
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P0, CFAM_CHIP_ID_CHIP_MASK

     // target ABus chiplet
        lpcs    P0, A_BUS_CHIPLET_0x08000000

     // leave scan ratio at 8:1 for Naples (tied to nest grid)
        cmpibraeq D0, scan_abus2, CFAM_CHIP_ID_NAPLES

     // Set ABus scan ratio to 1:1 as ABus is still at refclock                                //AK-LAB
        POREVE_INF("Set ABus scan ratio to 1:1 ...\n")               //AK-LAB
        sti     A_OPCG_CNTL0_0x08030002, P0, 0x0                                               //AK-LAB

scan_abus2:
        load_ring ab_func_ab
        load_ring ab_func_ioa
        load_ring ab_func_perv
        load_ring ab_func_pll
        load_ring ab_regf
        load_ring ab_farr
        load_ring ab_lbst
        load_ring ab_abst
        load_ring ab_cmsk
        load_ring ab_bndy_ioa

     // Set ABus scan ratio back to 8:1 as ABus                                                //AK-LAB
        POREVE_INF("Set ABus scan ratio to 8:1 ...\n")               //AK-LAB
        //Inputs: A1 and P0, destroys D0 & D1
        lia     A1, PORE_SPACE_SEEPROM, proc_sbe_initf_control
        bsr     set_scan_ratio

scan_pcie:

        ifcpltbad SCAN_CHIPLET_PCIE, scan_done

        POREVE_DBG("Scanning PCIe rings ...\n")
        lpcs    P0, PCIE_CHIPLET_0x09000000

     // Set PCIe scan ratio to 1:1 as PCIe is still at refclock                                //AK-LAB
        POREVE_INF("Set PCIe scan ratio to 1:1 ...\n")               //AK-LAB
        sti     PCIE_OPCG_CNTL0_0x09030002, P0, 0x0                                            //AK-LAB

//        load_ring pci_func_iopci //Moved to proc_sbe_setup_evid
        load_ring pci_func_pbf
        load_ring pci_func_pci0
        load_ring pci_func_pci1
        load_ring pci_func_pci2
        load_ring pci_func_perv
        load_ring pci_func_pll
        load_ring pci_regf
        load_ring pci_farr
        load_ring pci_lbst
        load_ring pci_abst
        load_ring pci_cmsk
        load_ring pci_bndy_iopci

	sti     GENERIC_CLK_SCANSEL_0x00030007, P0, 0x0

     // Set PCIe scan ratio back to 8:1 as PCIe                                                //AK-LAB
        POREVE_INF("Set PCIe scan ratio to 8:1 ...\n")               //AK-LAB
        //Inputs: A1 and P0, destroys D0 & D1
        lia     A1, PORE_SPACE_SEEPROM, proc_sbe_initf_control
        bsr     set_scan_ratio

scan_done:


    .end_procedure proc_sbe_initf
