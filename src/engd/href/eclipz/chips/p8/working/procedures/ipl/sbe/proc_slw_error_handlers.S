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



/*  
   
    A)  Upon being initiated for an idle transition, the SLW code will first
        establish the Error Mask register with the settings that produce the
        SLW engine hardware behavior described.
    
        For idle processing, the SLW PORE is set up to stop immediately so that 
        none of the SLW PORE state is lost (eg the PC and DBG0/1 registers) are 
        retained.  This means that no error handlers are needed.  The SLW is 
        also setup to assert the "fatal_error" signal to the PMC so that the PMC 
        will immediately cause the malfunction alert to occur (via PMC LFIR (11)).
        As the SLW PORE is stopped, no status is written back to the PMC so it 
        will not process any further idle transitions until recovery actions 
        take place.
        
        Firmware detected errors will utilize the "reqhalt" macro to also stop
        immediate but the error code will be inserted at the point of fail.
        
        Recovery code needs to check for all the error bits in the DBG0/1 regs.
        If any are on, it is to be assumed that this was the reason for the halt.
        If none are on, then it is to be assumed that a firmware error was 
        detected and the halt code is in the location following the halt 
        instruction.  Reseting the SLW PORE will remove all but come IBUF 
        Control register bits and the Error Mask state.
        
    B)  For 24x7 processing, error handlers are present to all a halt instruction
        to be executed so interruptibility can be restored (typically) such that
        any subsequent idle operation will be handled.  The scheduler will 
        establish the proper Error Mask value to allow this.
        
        \todo The EMR layout for this mode is TBD.
        
*/
// *!
// *! Procedure Prereq:
// *!
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Includes
//------------------------------------------------------------------------------
        .nolist
#include "p8_sbe.H"
        .list
		
#include "proc_slw.H"

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
        .macro .error_routine vector:req
        .global \vector\()_ptr
 \vector\()_ptr:
        // call the procedure to handle the transition
        .callproc \vector
        
        .endm



//------------------------------------------------------------------------------
// Procedures 
//------------------------------------------------------------------------------

        .error_routine slw_error_0
        .error_routine slw_error_1
        .error_routine slw_error_2
        .error_routine slw_error_3
        .error_routine slw_error_4
        .error_routine slw_undefined

// Note: SLW procedures don't use .end_procedure as they halt upon completion 
// vs branching back to the caller (which was the branch table)

//------------------------------------------------------------------------------	
// Error0
//  Non-zero return code on PIB Master or PIB Read Data parity

	.procedure slw_error_0, slw, "$Revision: 1.6 $"
	
	reqhalt RC_SLW_EH_PIB_ERROR
		
	.end_procedure slw_error_0

//------------------------------------------------------------------------------
// Error1
//  Non-zero return code on OCI or OCI Read Data parity

	.procedure slw_error_1, slw, "$Revision: 1.6 $"
	
	reqhalt RC_SLW_EH_OCI_ERROR

    .end_procedure slw_error_1

//------------------------------------------------------------------------------
// Error2
//  Error during instruction fetch or decode

	.procedure slw_error_2, slw, "$Revision: 1.6 $"
	
	reqhalt RC_SLW_EH_INSTRUCTION_ERROR
        
    .end_procedure slw_error_2
	

//------------------------------------------------------------------------------	
// Error3
//  Internal data error

	.procedure slw_error_3, slw, "$Revision: 1.6 $"
	
	reqhalt RC_SLW_EH_INTERNAL_DATA_ERROR
        
    .end_procedure slw_error_3
		
	
//------------------------------------------------------------------------------	
// Error4
//  Error on Error.  Any error occured while the Debug Registers 0-1 are locked.

	.procedure slw_error_4, slw, "$Revision: 1.6 $"
	
	reqhalt RC_SLW_EH_ERROR_ON_ERROR
        
    .end_procedure slw_error_4
	
//------------------------------------------------------------------------------	       
// ErrorUndefined
//  An undefinded program branch

	.procedure slw_undefined, slw, "$Revision: 1.6 $"
	
	reqhalt RC_SLW_UNDEFINED_SV
        
    .end_procedure slw_undefined
