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
        .pnor

        //This is the bit number that indicates if we should skip the first core
        //JDS TODO - put in the real bit number when available
        .set SKIP_FIRST_CORE_BIT,  32
        //This is the bit number that indicates if we should skip the first side
        //JDS TODO - put in the real bit number when available
        .set SKIP_FIRST_SIDE_BIT,  33

        //This is the bit number to set to restart the IPL
        //JDS TODO - put the real bit number when available
        .set RESTART_IPL_BIT, 0
//------------------------------------------------------------------------------
// Global Data 
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros 
//------------------------------------------------------------------------------

 
//------------------------------------------------------------------------------
// Procedure 
//------------------------------------------------------------------------------
        .procedure proc_sbe_switch_core, ipl, "$Revision: 1.3 $"

        //Read EXETRIGGER to see what we've skipped
        mr      D0, ETR
        ifbitset D1, D0, SKIP_FIRST_SIDE_BIT, side_1

side_0:
        ifbitset D1, D0, SKIP_FIRST_CORE_BIT, side_0_core_1

side_0_core_0:  
        POREVE_ERR( "There's a bug in proc_sbe_switch_side\n" )
        POREVE_ERR( "It should have switched to side 1 before getting here\n" )
        halt
        
side_0_core_1:
        POREVE_ERR( "There's a bug in proc_sbe_switch_side\n" )
        POREVE_ERR( "It should have given up the IPL before getting here\n" )
        halt
        
size_1: 
        ifbitset D1, D0, SKIP_FIRST_CORE_BIT, side_1_core_1

side_1_core_0:  
        POREVE_IMP( "Switching IPL to backup core and retrying IPL\n" )
        setbit  D0, SKIP_FIRST_CORE_BIT
        mr      ETR, D0
        //JDS TODO - get the real scom address
        setbitscom D0, TP_FSI_???, P0, RESTART_IPL_BIT
        nop
        POREVE_ERR( "The IPL didn't restart correctly\n" )
        halt
        
side_1_core_1:
        POREVE_ERR( "There's a bug in proc_sbe_switch_side\n" )
        POREVE_ERR( "It should have switched to side 0 before getting here\n" )
        halt


        .end_procedure proc_sbe_switch_core
