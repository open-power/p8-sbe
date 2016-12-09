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
// Procedure - SEEPROM
//------------------------------------------------------------------------------
        .procedure proc_sbe_trigger_winkle, ipl, "$Revision: 1.6 $"
        //Copy the control word into PIBMEM
        lia     A0, PORE_SPACE_SEEPROM, proc_sbe_trigger_winkle_control
        ld      D0, 0x0, A0
        lpcs    P1, PIBMEM0_0x00080000
        .pibmem_port (PORE_SPACE_PIBMEM & 0xf) 
        std     D0, proc_sbe_trigger_winkle_pibmem_control, P1

        //Branch into the pibmem, and never return
        POREVE_INF( "Branching into PIBMEM for proc_sbe_trigger_winkle\n" )
        braia   PORE_SPACE_PIBMEM, proc_sbe_trigger_winkle_pibmem

        .end_procedure proc_sbe_trigger_winkle
