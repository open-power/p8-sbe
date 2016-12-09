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





//-----------------------------------------------------------------------------
// Includes
//-----------------------------------------------------------------------------
        .nolist
#include "p8_sbe.H"
        .list


//-----------------------------------------------------------------------------
// Directives
//-----------------------------------------------------------------------------

        .otprom

//-----------------------------------------------------------------------------
// Global Data
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
// Local Macros
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
// Procedure
//-----------------------------------------------------------------------------

        .ipl_text

ecid:

        .quad 0x0                                // Placeholder for ECID
        .quad 0x0                                // Placeholder for ECID
        .quad 0x0                                // Placeholder for ECID

spare_entry:

        .quad 0x0                                // Placeholder

chip_settings:

        .quad 0x0                                // Placeholder for Chip Settings

sbe_base_table:

        braia   0x0008, 0x000000000000           // Branch to Error Handler 0 (located in PIB MEM)
        braia   0x0008, 0x00000000000C           // Branch to Error Handler 1 (located in PIB MEM)
        braia   0x0008, 0x000000000018           // Branch to Error Handler 2 (located in PIB MEM)
        braia   0x0008, 0x000000000024           // Branch to Error Handler 3 (located in PIB MEM)
        braia   0x0008, 0x000000000030           // Branch to Error Handler 4 (located in PIB MEM)

        braia   0x0001, _sbe_otprom_start        // Branch to OTPROM code start
        braia   0x0001, _sbe_otprom_start        // Branch to OTPROM code start
        braia   0x0001, _sbe_otprom_start        // Branch to OTPROM code start
