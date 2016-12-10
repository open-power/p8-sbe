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
#include "proc_sbe_initf_common_seeprom.H"
        .list


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

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_tp_initf, ipl, "$Revision: 1.2 $"
        POREVE_INF("*** Pervasive Chiplet Scan Inits ***")


// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************


     // Switching on securety mask bit 9
        lpcs    P0, STBY_CHIPLET_0x00000000
        bsi     D0, OTPC_M_SECURITY_SWITCH_0x00010005, P0, BIT(9)


     // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P1, STBY_CHIPLET_0x00000000

     // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P0, TP_CHIPLET_0x01000000


        POREVE_INF("Scan perv_cmsk ...")
        load_ring perv_cmsk

        POREVE_INF("Scan perv_abst ...")
        load_ring perv_abst

        POREVE_INF("Scan perv_func_perv ...")
        load_ring perv_func_perv

        POREVE_INF("Scan perv_lbst ...")
        load_ring perv_lbst

        POREVE_INF("Scan perv_regf ...")
        load_ring perv_regf

        POREVE_INF("Scan perv_farr ...")
        load_ring perv_farr

        // Scan any inits into OCC before starting the clocks and dropping the fence
        POREVE_INF("Scan perv_func_occ ...")
        load_ring perv_func_occ

     // Switching off securety mask bit 9
        lpcs    P0, STBY_CHIPLET_0x00000000
        bci     D0, OTPC_M_SECURITY_SWITCH_0x00010005, P0, BIT(14)
        bci     D0, OTPC_M_SECURITY_SWITCH_0x00010005, P0, BIT(9)

        POREVE_INF("*** End of Procedure ***")
        .end_procedure proc_sbe_tp_initf
