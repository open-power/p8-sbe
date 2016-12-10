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
//        .set    SBE_PNOR_MAGIC, 0x53424520504e4f52 // "SBE PNOR"
        .set    TRY0_ADDRESS, 0x0ffffff8
        .set    TRY1_ADDRESS, (TRY0_ADDRESS - (1 << 15)) // 32K?
        .set    BAD_ADDRESS, 0xffffffffffffffff

 
//------------------------------------------------------------------------------
// Procedure 
//------------------------------------------------------------------------------
        .procedure proc_sbe_locate_image, ipl, "$Revision: 1.5 $"

        // Try 0

        // Check try0 pointer (SBE-IPL physical base address) for validity

try0:   
        lia     A0, PORE_SPACE_PNOR, TRY0_ADDRESS
        ld      D0, 0, A0
        cmpibraeq D0, try1, BAD_ADDRESS

        // Move physical base address of SBE-IPL image to A0 and D1.
        // SBE-IPL image startup requires the physical base address to be held
        // in A0 at entry, the physical base address is also saved in D1 to add
        // to the offset to perform the handoff.   Check the magic number.
        
        mr      A0, D0
        mr      D1, D0
        ld      D0, 0, A0
        cmpibrane D0, try1, SBE_PNOR_MAGIC
        bra     handoff

        // Try 1 is analgous to Try 0
try1:
        //?? Must set bit to tell error handlers we're in TRY1 ??
        lia     A0, PORE_SPACE_PNOR, TRY1_ADDRESS
        ld      D0, 0, A0
        cmpibraeq D0, fail, BAD_ADDRESS

        mr      A0, D0
        mr      D1, D0
        ld      D0, 0, A0
        cmpibrane D0, fail, SBE_PNOR_MAGIC

        // Load and add the SBE-IPL entry point offset to the physical base
        // address and branch indirect into the PNOR.
handoff:        
        ld      D0, 8, A0
        add     D0, D0, D1
        brad    D0
        
        // OTPROM -> PNOR handoff failure
fail:   
        halt    


        .end_procedure proc_sbe_locate_image
