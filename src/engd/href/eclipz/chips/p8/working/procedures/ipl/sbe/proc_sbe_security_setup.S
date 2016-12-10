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
// Constant Definitions
//------------------------------------------------------------------------------

        .set PRIMARY_NODE_MASTER_HBI_BOOT_PATTERN,    0x0000000000000000       // SBE_VITAL(10) = 0b0, chip ID = 0b00, chip pos = 0b0
        .set ALTERNATE_NODE_MASTER_HBI_BOOT_PATTERN,  0x0020000002000000       // SBE_VITAL(10) = 0b1, chip ID = 0b01, chip pos = 0b0

     // Procedure Progress Step Definition
        .set STEP_MASTER_SECURITY_SETUP_CHECK,        0x1
        .set STEP_MASTER_SECURITY_SETUP_OVERWRITE,    0x2
        .set STEP_SLAVE_SECURITY_SETUP_CHECK,         0x3
        .set STEP_SLAVE_SECURITY_SETUP_OVERWRITE,     0x4


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_security_setup, ipl, "$Revision: 1.2 $"
        POREVE_INF("<proc_sbe_security_setup> : *** Updating Security Switches according to SEEPROM Image ***\n")


sss_setup:

// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************

     // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

     // Setup MEM_BASE_ADDR0; points to security setup vector
        lia     A0, PORE_SPACE_SEEPROM, proc_sbe_security_setup_vector

sss_check_master_slave:

     // Read SBE_VITAL node master bit
        POREVE_INF("<proc_sbe_security_setup> : Reading SBE_VITAL node master bit ...\n")
        ldandi  D0, MBOX_SBEVITAL_0x0005001C, P0, BIT(10)

     // Read PCB master chip id register to identify chip id and position
        POREVE_INF("<proc_sbe_security_setup> : Reading chip id and position ...\n")
        ldandi  D1, PCBMS_DEVICE_ID_0x000F000F, P0, BITS(36, 4)

     // Combine node master bit, chip position and chip id to a combined pattern
        or      D0, D0, D1

     // Get the security setup vector
        POREVE_INF("<proc_sbe_security_setup> : Get the security setup vectors ...\n")
        ld      D1, 0x0, A0

     // Check for node master or alternate node master HBI boot pattern
        cmpibraeq   D0, sss_master_security_overwrite, PRIMARY_NODE_MASTER_HBI_BOOT_PATTERN
        cmpibraeq   D0, sss_master_security_overwrite, ALTERNATE_NODE_MASTER_HBI_BOOT_PATTERN

sss_slave_security_overwrite:

     // Progress Indicator update
        updatestep STEP_SLAVE_SECURITY_SETUP_CHECK, D0, P0
        POREVE_INF("<proc_sbe_security_setup> : Slave Chip Security Setup Check ...\n")

        andi        D1, D1, 0x00000000FFFF0000
        rols        D1, D1, 32

     // Checking for Security Setup Overwrite Bit
        andi        D0, D1, BIT(0)
        braz        D0, sss_complete

     // Progress Indicator update
        updatestep STEP_SLAVE_SECURITY_SETUP_OVERWRITE, D0, P0
        POREVE_INF("<proc_sbe_security_setup> : Slave Chip Security Setup Overwrite ...\n")
        std         D1, OTPC_M_SECURITY_SWITCH_0x00010005, P0

        bra         sss_complete

sss_master_security_overwrite:

     // Progress Indicator update
        updatestep STEP_MASTER_SECURITY_SETUP_CHECK, D0, P0
        POREVE_INF("<proc_sbe_security_setup> : Master Chip Security Setup Check ...\n")

        andi        D1, D1, 0xFFFF000000000000

     // Checking for Security Setup Overwrite Bit
        andi        D0, D1, BIT(0)
        braz        D0, sss_complete

     // Progress Indicator update
        updatestep STEP_MASTER_SECURITY_SETUP_OVERWRITE, D0, P0
        POREVE_INF("<proc_sbe_security_setup> : Master Chip Security Setup Overwrite ...\n")
        std         D1, OTPC_M_SECURITY_SWITCH_0x00010005, P0

sss_complete:

        POREVE_INF("<proc_sbe_security_setup> : *** End of procedure ***\n")
        .end_procedure proc_sbe_security_setup
