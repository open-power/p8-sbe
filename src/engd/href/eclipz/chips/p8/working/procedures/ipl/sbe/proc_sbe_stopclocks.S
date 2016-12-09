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
// constant declaration for FAPI HOOKs
//------------------------------------------------------------------------------

        ##` fapi::ReturnCode rc_iniStop;
        ##` const uint32_t BAD_ERROR_CODE   = 0x3E7;


//------------------------------------------------------------------------------
// constant declaration for GAS
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// preprocessor directives
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .otprom

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------
.set    CHIPLET_ALL_WRITE, 0x68
.set    CORE_ONLY_WRITE,   0x6A

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

        .procedure proc_sbe_stopclocks, otprom, "$Revision: 1.1 $"

        FAPI_INF( "Stop functional P8 clocks.\n" );

        // Set flushmode_inhibit in Chiplet GP0
        // write 0x[68]000005 WOR codepoint 0x2000000000000000 bit(2) = 0b1
        ls      P0, CHIPLET_ALL_WRITE
        sti     GENERIC_GP0_OR_0x00000005, P0, 0x2000000000000000

        // Set force_align in Chiplet GP0
        // write 0x[68]000005 WOR codepoint 0x1000000000000000 bit(3) = 0b1
        sti     GENERIC_GP0_OR_0x00000005, P0, 0x1000000000000000

        // Write ClockControl, Scan Region Register, set all bits to zero prior clock stop
        // write 0x[68]030007    0x0000000000000000
        sti     GENERIC_CLK_SCANSEL_0x00030007, P0, 0x0000000000000000

        FAPI_INF( "Need to: EP only: reset all IOVALIDs.\n" );
        // EP only: reset all IOVALIDs
        // write 0x02000004 WAND codepoint 0xFFFFFFFFFFFF03FF bit(48:53) = 0b000000
//        ls      P0, CHIPLET_NEST
//        sti     WRITE_IOVALID_WAND_0x02000004, P0, 0xFFFFFFFFFFFF03FF

        FAPI_INF( "Need to: EP only: reset IOVALID MCA.\n" );
        // EP only: reset IOVALID MCA
        // write 0x06000004 WAND codepoint 0xFFFFFFFFFFFF7FFF bit(48) = 0b0
//        ls      P0, CHIPLET_DONTKNOW
//        sti     WRITE_IOVALID_MCA_WAND_0x06000004, P0, 0xFFFFFFFFFFFF7FFF

        FAPI_INF( "Need to: ES only: reset all IOVALIDs.\n" );
        // ES only: reset all IOVALIDs
        // write 0x02000004 WAND codepoint 0xFFFFFFFFFFFF007F bit(48:56) = 0b000000000
//        ls      P0, CHIPLET_NEST
//        sti     WRITE_IOVALID_WAND_0x02000004, P0, 0xFFFFFFFFFFFF007F

        // Reset abist_mode_dc for core chiplets (core recovery)
        // write 0x[68]000004 WAND codepoint 0xFFEFFFFFFFFFFFFF    bit(11) = 0b0
        ls      P0, CHIPLET_ALL_WRITE
        sti     GENERIC_GP0_AND_0x00000004, P0, 0xFFEFFFFFFFFFFFFF

        // Set synclk_muxsel (io_clk_sel)
        // write 0x[68]000005 WOR codepoint 0x4000000000000000 bit(1) = 0b1
        sti     GENERIC_GP0_OR_0x00000005, P0, 0x4000000000000000

        // Assert perv fence GP0.63
        // write 0x[68]000005 WOR codepoint 0x4000000000000001 bit(63) = 0b1
        sti     GENERIC_GP0_OR_0x00000005, P0, 0x4000000000000001

        // GP3(28) disable EDRAM (just chiplets with EDRAM logic group2: allCoreOnly)
        // (skip this step if refresh clock domain stays running)
        // write 0x[6A]0F0013 WAND codepoint 0xFFFFFFF7FFFFFFFF bit(28) = 0b0
        ls      P0, CORE_ONLY_WRITE
        sti     GENERIC_GP3_AND_0x000F0013, P0, 0xFFFFFFF7FFFFFFFF

        // Assert fence GP3.18
        // write 0x[68]0F0014 WOR codepoint 0x0000200000000000 bit(18) = 0b1
        ls      P0, CHIPLET_ALL_WRITE
        sti     GENERIC_GP3_OR_0x000F0014, P0, 0x0000200000000000

        FAPI_INF( "Done executing proc_stopclocks. \n" );
        nop

        .end_procedure proc_sbe_stopclocks
