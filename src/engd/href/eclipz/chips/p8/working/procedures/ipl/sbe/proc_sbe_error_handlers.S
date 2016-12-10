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
        .pibmem

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

	.ipl_text

	.global	proc_sbe_error_handler0
        .global	proc_sbe_error_handler1
        .global	proc_sbe_error_handler2
        .global	proc_sbe_error_handler3
        .global	proc_sbe_error_handler4

proc_sbe_error_handlers:	

proc_sbe_error_handler0:	

     // Error Handler for SBE Error Event 0 (PIB error during Execution Phase)
     // ======================================================================
     //
     // State:   disabled
     //
     // Action:  Stops the SBE with appropriate halt indication

        POREVE_ERR("Error halt from Error Handler0: <Execution Phase PIB Error>")
	reqhalt	RC_SBE_PORE_ERROR0


proc_sbe_error_handler1:	

     // Error Handler for SBE Error Event 1 (OCI error during Execution Phase)
     // ======================================================================
     //                                                                                       	
     // State:   disabled (invalid for SBE)
     //
     // Action:  Stops the SBE with appropriate halt indication

        POREVE_ERR("Error halt from Error Handler1: <Execution Phase OCI Error>")
	reqhalt RC_SBE_PORE_ERROR1


proc_sbe_error_handler2:	

     // Error Handler for SBE Error Event 2 (Instruction fetch/decode error)
     // ======================================================================
     //
     // State:   disabled
     //
     // Action:  Stops the SBE with appropriate halt indication

        POREVE_ERR("Error halt from Error Handler2: <Instruction fetch/decode Error>")
	reqhalt RC_SBE_PORE_ERROR2


proc_sbe_error_handler3:	

     // Error Handler for SBE Error Event 3 (Internal data error)
     // ======================================================================
     //
     // State:   disabled
     //	
     // Action:  Stops the SBE with appropriate halt indication

        POREVE_ERR("Error halt from Error Handler3: <Internal Data Error>")
	reqhalt RC_SBE_PORE_ERROR3


proc_sbe_error_handler4:	

     // Error Handler for SBE Error Event 4 (Error-on-Error)
     // ======================================================================
     //
     // State:   disabled
     //
     // Action:  Stops the SBE with appropriate halt indication

        POREVE_ERR("Error halt from Error Handler4: <Error-on-Error>")
	reqhalt RC_SBE_PORE_ERROR4
			
	.epilogue proc_sbe_error_handlers
	

