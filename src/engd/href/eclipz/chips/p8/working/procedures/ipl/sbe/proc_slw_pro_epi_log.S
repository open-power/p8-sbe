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



        .nolist
#include "p8_sbe.H"
#include "p8_slw.H"
#include "proc_slw.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
	     .oci		// This code runs from OCI space to access SLW image
         .rt_text
		 			
//------------------------------------------------------------------------------
// Global Data 
//------------------------------------------------------------------------------

               
//------------------------------------------------------------------------------
// Local Macros 
//------------------------------------------------------------------------------

/// Generate the transision code conditioned by type
///
/// \param[in] type The transition type
///
/// Leaves P0 with the multicast base
///

	.macro slw_pro_epi_log, type:req

    .subroutine proc_slw_\type, rt, "$Revision: 1.10 $"
	
	// Set values based on which type is being dealt with   
    .ifc    \type, prolog
        
    // 0:15 - set multicast group 5
    // 19:21 - set previous group as 7
    .set MC_GROUP, 0xF4001C0000000000
    
    // MC Setup for Px
    //
    // 25   26  27  28  29  30  31
    //
    // PIB
    // 1    2   3   4   5   6   7
    //      <--------> <--------->
    // MC     MC Type     MC Grp
    //
    //         Write      Grp=5
    //  1 , 1   0   1 , 1   0   1
    //      6     ,       D 
	.set MC_ID, 0x6D			
    
    .set ATOMIC_LOCK_DATA, SET_ATOMIC_LOCK_DATA
   	
	
	 POREVE_INF("## ---- Start Prolog. \n ")
     
    // -------------------------------------------------------------------------
    // Error Injection support
    //      Done in the prolog for immediate injection

    // Define an undefined OCI Address for error injection
    CONST_UINT64_T( PROC_SLW_INVALID_OCI_ADDRESS          , ULL(0xDEADDEAD) );

    // Define an undefined PIB Address in a known slave
    // This address is the highest one in the SLW engine space
    CONST_UINT64_T( PROC_SLW_INVALID_PIB_ADDRESS          , ULL(0x00068FFF) );

    // Define an undefined PIB Address whereby a PIB timeout will occur.
    // This address targets EX chiplet 0 - not existent for Murano or Venice
    CONST_UINT64_T( PROC_SLW_TIMEOUT_ADDRESS              , ULL(0x10000000) );
    
    // Define high negative offset for PC underflow.
    CONST_UINT64_T( PROC_SLW_PC_UNDERFLOW_OFFSET          , ULL(0x80000000) );
    
    // Define high positive offset for PC overflow.
    CONST_UINT64_T( PROC_SLW_PC_OVERFLOW_OFFSET           , ULL(0x7FFFFFFF) );
     
    // Check if the master error injection bit is on
    lpcs    P1, PROC_SLW_ERRINJ_MASTER_ADDR
    ldandi  D0, PROC_SLW_ERRINJ_MASTER_ADDR, P1, PROC_SLW_ERRINJ_MASTER_BIT
    braz    D0, errinj_end_\type
   
    // Check if any injection is enabled.  If not, skip the tests
    la      A0, slw_control_vector
    ldandi  D0, 0, A0, PROC_SLW_ERRINJ_MASK
    braz    D0, errinj_end_\type
    
    // ------------------------------
    // Simple halt
    ifslwcntlbitclr PROC_SLW_ERRINJ_SIMPLE_HALT, 1f
    halt
    .long RC_SLW_ERRINJ_SIMPLE_HALT
1:

    // ------------------------------
    // Invalid instruction
    ifslwcntlbitclr PROC_SLW_ERRINJ_INVALID_INSTR, 1f
    .long   0x0B000000           // Invalid instruction ("other" class) 
    .long   RC_SLW_ERRINJ_INVALID_INSTR
1:
    // ------------------------------
    // Invalid OCI Address
    ifslwcntlbitclr PROC_SLW_ERRINJ_INVALID_OCI_ADDRESS, 1f
    POREVE_INF("----> Error Injection of invalid OCI address.")

    // perform a real invalid operation
    la      A0, PROC_SLW_INVALID_OCI_ADDRESS
    ld      D0, 0, A0
    .long RC_SLW_ERRINJ_INVALID_OCI_ADDRESS
1:

    // ------------------------------
    // Invalid PIB Address
    ifslwcntlbitclr PROC_SLW_ERRINJ_INVALID_PIB_ADDRESS, 1f        
    POREVE_INF("----> Error Injection of invalid PIB address.")

    lpcs    P1, PROC_SLW_INVALID_PIB_ADDRESS
    ld      D0, PROC_SLW_INVALID_PIB_ADDRESS, P1 
    .long RC_SLW_ERRINJ_INVALID_PIB_ADDRESS
1:

    // ------------------------------
    // PC Underflow
    ifslwcntlbitclr PROC_SLW_ERRINJ_PC_UNDERFLOW, 1f        
    POREVE_INF("----> Error Injection of PC underflow.")

    braa    PROC_SLW_PC_UNDERFLOW_OFFSET
    .long   RC_SLW_ERRINJ_PC_UNDERFLOW
         
1:

    // ------------------------------
    // PC Overflow
    ifslwcntlbitclr PROC_SLW_ERRINJ_PC_OVERFLOW, 1f        
    POREVE_INF("----> Error Injection of PC overflow.")
    
    braa    PROC_SLW_PC_OVERFLOW_OFFSET
    .long   RC_SLW_ERRINJ_PC_OVERRFLOW
         
1:

    // ------------------------------
    // Timeout
    ifslwcntlbitclr PROC_SLW_ERRINJ_TIMEOUT, 1f        
    POREVE_INF("----> Error Injection of a timeout.")

    lpcs    P1, PROC_SLW_TIMEOUT_ADDRESS
    ld      D0, PROC_SLW_TIMEOUT_ADDRESS, P1 
    .long   RC_SLW_ERRINJ_TIMEOUT_ERROR
         
1:

errinj_end_\type:
	 
   .else
   .ifc    \type, epilog
    
	// 0:15 - set multicast group 7
    // 19:21 - set previous group as 5
    .set MC_GROUP, 0xFC00140000000000
        
    // MC Setup for Px
    //
    // 25   26  27  28  29  30  31
    //
    // PIB
    // 1    2   3   4   5   6   7
    //      <--------> <--------->
    // MC     MC Type     MC Grp
    //
    //        Read-AND    Grp=7
    //  1 , 0   0   1 , 1   1   1
    //      4     ,       F 
	.set MC_ID, 0x4F				
   
    .set ATOMIC_LOCK_DATA, CLEAR_ATOMIC_LOCK_DATA
	
	 POREVE_INF("## ---- Start Epilog. \n ")
    
    .else		
    .error  "Error:  slw_pro_epi_log type must be 'prolog' or 'epilog'"
    .endif
	.endif

    
	// Load the EXE Trigger (ETR) into D0 to build the chiplet vector.
	//
	// ETR is in the form of:
	//    0:7      - reserved
	//    8:11     - start vector (encoded)
	//    12:31    - reserved
	//    32:47    - 16 bit chiplet vector
	//    48:63    - reserved
	
	mr D1, ETR
	
	// Initialize P0 and CTR and execute the PORE for-loop paradigm
	ls P0, CHIPLET0
	ls CTR, MAX_CORES
	bra end_loop_\type
	
chiplet_loop_\type:
	
	// Check to see if chiplet should be added to multicast group
   	andi D0, D1, BIT(32)            # Clear all but bit 0 (the current chiplet)
	braz D0, continue_\type         # If bit is 0, skip adding it to the MC grp
		
	// add chiplet to multicast group
    POREVE_DBG("     SLW write MC Reg 4 to chiplet          0x%02llX",
                        io_pore.p0.read())
    sti EX_MCGR4_0x100F0004, P0, MC_GROUP  # P7+ used to use MCGrpReg 4
	//sti EX_MCGR4_0x100F0002, P0, MC_GROUP

continue_\type:

	rols D1, D1, 1 # Rotate chiplet vector mask
	adds P0, P0, 1 # Index next chiplet

end_loop_\type:
	
	loop chiplet_loop_\type
	
   
        
	// Make P0 be the multicast id
	ls P0, MC_ID
    
     
    // Atomic lock setting is the first thing done after the MC group is changed for
    // prolog case.
   .ifc    \type, prolog
   
    sti PCBS_ATOMIC_LOCK_0x100F03FF, P0, ATOMIC_LOCK_DATA
    
    // Note:  not getting the lock will result in an scresp of 001 which will trigger
    // error event 0 (PIB error) which will cause the SLW to halt. 
    
    
    // Set PMC Halt Idle State Machine to keep it from writing to EXE Trigger until
    // really done.  This is reeanbled after the Status is written back to PMC.
    // 
    // \bug
    
    //    P1, PMC_MODE_REG_0x00062000
    //ld      D0, PMC_MODE_REG_0x00062000, P1
    //ori     D0, D0, BIT(14)
    //std     D0, PMC_MODE_REG_0x00062000, P1
    
    .endif
	
	.end_subroutine proc_slw_\type
	 
	.endm 

//------------------------------------------------------------------------------
// Procedure 
//------------------------------------------------------------------------------

	
//
// Create each of the types by macro invocation

// Prolog
	slw_pro_epi_log prolog

// Epilog
	slw_pro_epi_log epilog

