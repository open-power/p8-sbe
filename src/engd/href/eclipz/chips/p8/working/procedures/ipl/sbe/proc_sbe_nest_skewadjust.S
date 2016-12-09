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
// Constant Definitions
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

        .procedure proc_sbe_nest_skewadjust, ipl, "$Revision: 1.9 $"
        POREVE_INF("<proc_sbe_nest_skewadjust> : *** Nest Skewadjust - adjust PRV and NEST ***\n")


nsa_setup:

// ********************************************************
// **          SBE Address Base Register Setups          **
// ********************************************************

     // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

     // Setup PRV_BASE_ADDR1; points to PRV Cplt
        lpcs    P1, XBUS_CHIPLET_0x04000000

     // Setup MEM_BASE_ADDR0; points to nest skewadjust vector
        lia     A0, PORE_SPACE_SEEPROM, proc_sbe_nest_skewadjust_vector

     // Setup MEM_BASE_ADDR1: points to the combined_good vector
        lia     A1, PORE_SPACE_SEEPROM, combined_good_vectors

nsa_start:

     // Check that XBUS chiplet is enabled
        POREVE_INF("<proc_sbe_nest_skewadjust> : Checking for partial-good XBUS chiplet ... \n");
        ld	D0, 4*0x8, A1
	braz	D0, nsa_done

     // Get the nest skewadjust vector (nominal only)
        POREVE_INF("<proc_sbe_nest_skewadjust> : Get the nominal nest skewadjust bits ...\n")
        ld      D0, 0x0, A0

     // Check for valid skewadjust value
        POREVE_INF("<proc_sbe_nest_skewadjust> : Checking for valid skewadjust settings ... \n")
        andi    D1, D0, BIT(2)
        braz    D1, nsa_done

     // CHANGED CODE START

     // Cut and move the skewadjust bits to match the compare reg layout
        POREVE_INF("<proc_sbe_nest_skewadjust> : Grepping the required skewadjust bits ... \n")
        andi    D0, D0, BITS(3,5)
        rols    D0, D0, 32
        rols    D0, D0, 8
	rols	D0, D0, 8
	rols	D0, D0, 8
	rols	D0, D0, 1
        rols    D0, D0, 1
	rols	D0, D0, 1
	POREVE_INF("<proc_sbe_nest_skewadjust>: VPD comparison value: %016llX\n", io_pore.d0.read());

                                                                                                   //     TP_CLK_ADJ_SET (0:31) register layout
                                                                                                   //
     // Initialize Coarse Step Counter                                                             //     o: override bit
        POREVE_INF("<proc_sbe_nest_skewadjust> : Initializing control counter to 32 steps ... \n") //     s: sync bit
        ls      CTR, 0x20                                                                          //     i: id
                                                                                                   //     s: select
     // CHANGED CODE END                                                                           //     c: cmd bit
                                                                                                   //     d: dcadj data bit
                                                                                                   //     s: skewadj data bit
                                                                                                   //
     // Set fast coarse max value                                                                  //     oosi iscc ccdd dddd dddd dsss ssss ssss
        POREVE_INF("<proc_sbe_nest_skewadjust> : Workaround a PCB_TIMEOUT ...\n")                  //     Request from Cedric - July 18, 2013
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x0000004200000000                                   //
        POREVE_INF("<proc_sbe_nest_skewadjust> : Set fast coarse max value ...\n")                 //
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x2500040800000000                                   //     0010 0101 0000 0000 0000 0100 0000 1000
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x0500040800000000                                   //     0000 0101 0000 0000 0000 0100 0000 1000
                                                                                                   //
     // Set fast fine max value                                                                    //
        POREVE_INF("<proc_sbe_nest_skewadjust> : Set fast fine max value ...\n")                   //
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x2500060800000000                                   //     0010 0101 0000 0000 0000 0110 0000 1000
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x0500060800000000                                   //     0000 0101 0000 0000 0000 0110 0000 1000
                                                                                                   //
                                                                                                   //
                                                                                                   //
     // NEW CODE START                                                                             //
                                                                                                   //
     // Set output mux to slow_coarse_progdelay                                                    //
        POREVE_INF("<proc_sbe_nest_skewadjust> : Set output mux to slow_coarse_progdelay ...\n")   //
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x2780004800000000                                   //     0010 0111 1000 0000 0000 0000 0100 1000
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x0780004800000000                                   //     0000 0111 1000 0000 0000 0000 0100 1000
                                                                                                   //
nsa_loop:                                                                                          //
                                                                                                   //
     // Decrease Coarse Step Counter                                                               //
        subs    CTR, 0x1                                                                           //
                                                                                                   //
     // Get current slow_coarse setting from logic                                                 //
        ld      D1, X_CLK_ADJ_DAT_REG_0x040F0015, P1                                               //
        andi    D1, D1, BITS(8,5)                                                                  //
                                                                                                   //
     // Compare current slow_coarse setting with VPD target value                                  //
        xor     D1, D0, D1                                                                         //
        braz    D1, nsa_match                                                                      //
                                                                                                   //
     // Increase slow_coarse_progdelay                                                             //
        POREVE_INF("<proc_sbe_nest_skewadjust> : Increase slow_coarse_progdelay ...\n")            //
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x2480000000000000                                   //     0010 0100 1000 0000 0000 0000 0000 0000
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x0480000000000000                                   //     0000 0100 1000 0000 0000 0000 0000 0000
                                                                                                   //
     // Check for max number of steps reached and start next loop iteration                        //
        mr      D1, CTR                                                                            //
        branz   D1, nsa_loop                                                                       //
                                                                                                   //
nsa_step_halt:                                                                                     //
                                                                                                   //
     // Number of max Coarse adjust steps reached                                                  //
        reqhalt RC_SBE_SKEWADJUST_MAX_STEPS_REACHED                                                //
                                                                                                   //
nsa_match:                                                                                         //
                                                                                                   //
     // NEW CODE END                                                                               //
                                                                                                   //
                                                                                                   //
                                                                                                   //
     // Set skewadj config                                                                         //
        POREVE_INF("<proc_sbe_nest_skewadjust> : Set skewadj config ...\n")                        //
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x2540038000000000                                   //     0010 0101 0100 0000 0000 0011 1000 0000
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x0540038000000000                                   //     0000 0101 0100 0000 0000 0011 1000 0000
                                                                                                   //
     // Set adjust delay low byte                                                                  //
        POREVE_INF("<proc_sbe_nest_skewadjust> : Set adjust delay low byte ...\n")                 //
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x2580007800000000                                   //     0010 0101 1000 0000 0000 0000 0111 1000
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x0580007800000000                                   //     0000 0101 1000 0000 0000 0000 0111 1000
                                                                                                   //
     // Set adj mode                                                                               //
        POREVE_INF("<proc_sbe_nest_skewadjust> : Set adj mode ...\n")                              //
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x2680020000000000                                   //     0010 0110 1000 0000 0000 0010 0000 0000
        sti     X_CLK_ADJ_SET_0x040F0016, P1, 0x0680020000000000                                   //     0000 0110 1000 0000 0000 0010 0000 0000

nsa_done:

        POREVE_INF("<proc_sbe_nest_skewadjust> : *** End of procedure ***\n")
        .end_procedure proc_sbe_nest_skewadjust
