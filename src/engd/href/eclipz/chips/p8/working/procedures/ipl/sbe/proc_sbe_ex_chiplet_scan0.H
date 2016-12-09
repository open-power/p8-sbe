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



#ifndef __PROC_SBE_EX_CHIPLET_SCAN0_H

#define __PROC_SBE_EX_CHIPLET_SCAN0_H


#ifdef __ASSEMBLER__

        // Maximum number of latches supported by a single SCAN0 operation
        .set    GENERIC_CC_SCAN0_MAXIMUM, 8191

        // Compile calculate of the number of scan0 repeats
        // Length of the longest ring / scan0 maximum is an integer division
        // Add 1 to cover any remainder
        // \todo  handle compile time reminder to conditionally add 1

        .set    PROC_SCAN0_FUNC_REPEAT,((PROC_EX_CHIPLET_SCAN0_FUNC_FLUSH_LENGTH / GENERIC_CC_SCAN0_MAXIMUM)+1)
        .set    PROC_SCAN0_GPTR_REPEAT,((PROC_EX_CHIPLET_SCAN0_GPTR_FLUSH_LENGTH / GENERIC_CC_SCAN0_MAXIMUM)+1)

        .macro ex_scan0, scanregion:req, clkregion:req

        li      D0, \scanregion         // Scan region/type control
        li      D1, \clkregion          // Clock region control
        bsr     ex_scan0_module

        .endm

#endif  // __ASSEMBLER__

#endif  // __PROC_SBE_EX_CHIPLET_SCAN0_H
