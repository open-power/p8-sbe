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
        .set SUBSTEP_CHECKING_IF_MBOX_IS_ZERO,         0x0
        .set SUBSTEP_COPYING_MBOX_VALUES_FROM_SEEPROM, 0x1

        .set STANDALONE_BIT, 1
        
//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_standalone_setup, ipl, "$Revision: 1.2 $"
        POREVE_INF("Setting MBOX registers to values from SEEPROM")
        
        //P1 is always pointed at the 0x00 chiplet at procedure entry
        ##@ fapiAssert(io_pore.p1.read() == 0x0ull) ; return hookOk;
        ld      D0, MBOX_SCRATCH_REG0_0x00050038, P1
        branz   D0, standalone_setup_done

        //Copy the MBOX values from SEEPROM to MBOX regs
        updatestep_inline SUBSTEP_COPYING_MBOX_VALUES_FROM_SEEPROM, D0, P1
        POREVE_DBG("Copying SEEPROM mailbox values to MBOX registers") ;
        ##@ fapiAssert(io_pore.p1.read() == 0x0ull) ; return hookOk;
        lia     A0, PORE_SPACE_SEEPROM, standalone_mbox_values
        ld      D0, 0x0, A0
        std     D0, MBOX_SCRATCH_REG0_0x00050038, P1
        ld      D0, 0x8, A0
        //Set Standalone bit in the mailbox
        ori     D0, D0, BIT(STANDALONE_BIT)
        std     D0, MBOX_SCRATCH_REG1_0x00050039, P1
        ld      D0, 0x10, A0
        std     D0, MBOX_SCRATCH_REG2_0x0005003A, P1
        ld      D0, 0x18, A0
        std     D0, MBOX_SCRATCH_REG3_0x0005003B, P1

standalone_setup_done:     
        .end_procedure proc_sbe_standalone_setup
