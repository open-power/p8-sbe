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
// Procedure
//------------------------------------------------------------------------------

        .procedure proc_sbe_tp_ld_image, ipl, "$Revision: 1.12 $"
        POREVE_INF("<proc_sbe_tp_ld_image> : *** Starting PIBMEM loader ***\n")

// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************

     // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

// ********************************************************
// **          Initialize PIBMEM repair data             **
// ********************************************************

     // Get PIBMEM repair data and write to PIBMEM repair data register
        la      A0, proc_sbe_pibmem_repair_vector
        ld      D0, 0, A0
        ori     D0, D0, BIT(0)
        std     D0, PIBMEM_REPAIR_0x00088007 ,P0

// ********************************************************
// **          Start loading the PIBMEM image            **
// ********************************************************

     // Load the section table entry for .pibmem0, which is a 64-bit value
     // consisting of two 32-bit values - offset:size.

        la      A0, __pibmem0_section
        ld      D0, 0, A0

     // Extract the section size (bytes to copy) and store temporarily in
     // SPRGO

        extrdi  D1, D0, 32, 32
        mr      SPRG0, D1

     // Extract and add the section offset to the image link address.

        extrdi  D0, D0, 32, 0
        la      A0, __link_address
        ld      D1, 0, A0
        add     D0, D0, D1

     // The parameters for proc_sbe_pibmem_loader
     //
     // A0 :     The address of the image
     // D0 :     The number of bytes to copy
     // D1 :     The PIBMEM load address (0x0)

        mr      A0, D0
        mr      D0, SPRG0
        ls      D1, 0

        bsr     proc_sbe_pibmem_loader

// ********************************************************
// **          Switch Error Handlers to PIBMEM           **
// ********************************************************

     // Switch error handling (Table Base) to PIBMEM address 0

        lpcs    P0, PORE_SBE_TABLE_BASE_ADDR_0x000E0008
        stia    PORE_SBE_TABLE_BASE_ADDR_0x000E0008, P0, PORE_SPACE_PIBMEM, 0
	
	.end_procedure proc_sbe_tp_ld_image
