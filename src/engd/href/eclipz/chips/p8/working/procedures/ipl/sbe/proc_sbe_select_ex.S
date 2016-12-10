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

        //The bit offset of the start of the EX partial good multicast results
        .set EX_PG_BIT, 16

        // Since we don't ever have core 15 we only need to check 0:14 = 15 positions 
        .set POSITIONS_TO_CHECK, 15
        .set EX_CHIPLET_OFFSET, 0x10

        //This is the bit number that indicates if we should skip the first core
        .set SKIP_FIRST_CORE_BIT,  9

        // Locations in the program
        .set STEP_FIND_FIRST_CORE,   0x1
        .set STEP_FIRST_CORE_FOUND,  0x2
        .set STEP_FIND_SECOND_CORE,  0x3
        .set STEP_NO_SECOND_CORE,    0x4
        .set STEP_CORE_SELECTED,     0x5

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------
        //Stolen from proc_sbe_common.S
        // Helper macro to check state of control bits
        .macro ifcntrbitset, bitmask:req, target:req
        ldandi  D1, 0, A0, \bitmask
        branz	D1, \target
        .endm

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_select_ex, ipl, "$Revision: 1.17 $"

        //Check if we want to use multicast
        //NOTE: This assumes that on procedure entry A0 contains the address
        //      of the control word
        ifcntrbitset PROC_CONTROL_INIT_ALL_EX, use_multicast

        //Get partial good bit (bit 0 of GP3) for all cores
        lpcs    P0, ALL_CORES_BITX_0x52000000
        ld      D1, GENERIC_GP3_0x000F0012, P0

        //Get the valid boot cores mask and apply it to the good cores value
        lia     A0, PORE_SPACE_SEEPROM, valid_boot_cores_mask
        ld      D0, 0x0, A0
        and     D1, D0, D1
        
        //Search for the first good boot core starting with EX0
        updatestep STEP_FIND_FIRST_CORE, D0, P1
        POREVE_INF( "Searching for a good core to boot with\n" )
        ls      CTR, POSITIONS_TO_CHECK
        
        //Check cores starting with EX00
        //Invariant: (POSITIONS_TO_CHECK - CTR) cores have been found to be bad
find_first_core:
        ifbitset D0, D1, EX_PG_BIT, first_core_found
        rols    D1, D1, 1
        loop    find_first_core

        POREVE_ERR( "Unable to find a good core to boot with\n" )
        reqhalt RC_SBE_SELECT_EX_NO_GOOD_BOOT_CORES_FOUND

first_core_found:
        updatestep STEP_FIRST_CORE_FOUND, D0, P1

        //Test sbe vital to see if we want to skip the first core
        lpcs    P0, MBOX_SBEVITAL_0x0005001C
        ifbitclrscom D0, D0, MBOX_SBEVITAL_0x0005001C, P0, SKIP_FIRST_CORE_BIT, success

        //Look for next good core if first core wasn't the last core
        updatestep STEP_FIND_SECOND_CORE, D0, P1
        POREVE_INF( "Skipping the first good core and looking for a second to boot with\n" )
        //Need to advance loop to the next core
        bra     find_second_core_start

find_second_core:
        ifbitset D0, D1, EX_PG_BIT, success
find_second_core_start: 
        rols    D1, D1, 1
        loop    find_second_core

        POREVE_ERR( "Unable to find a second core to boot with\n" )
        reqhalt RC_SBE_SELECT_EX_NO_SECOND_GOOD_BOOT_CORE_FOUND

success:
        updatestep STEP_CORE_SELECTED, D0, P1
        // CTR is counting down from POSITIONS_TO_CHECK, but we're checking PG bits
        // starting at core 0, so the core number is POSITIONS_TO_CHECK - CTR.
        ls      D0, POSITIONS_TO_CHECK
        mr      D1, CTR
        sub     D0, D0, D1

        POREVE_INF( "Booting with EX%02lli\n", io_pore.d0.read() )
        adds    D0, D0, EX_CHIPLET_OFFSET
        mr      P0, D0

        bra     exit

use_multicast:
        POREVE_INF( "Booting with all EX multicast group\n" )
        lpcs      P0, ALL_CORES_WRITE_0x6A000000
exit:
        .end_procedure proc_sbe_select_ex
