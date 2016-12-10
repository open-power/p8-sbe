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
        .list

#include "proc_slw.H"

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .oci
        .rt_text

//------------------------------------------------------------------------------
// Global Data 
//------------------------------------------------------------------------------

        .xip_address slw_branch_table
     
        
//------------------------------------------------------------------------------
// Local Macros 
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure 
//------------------------------------------------------------------------------

        .global slw_branch_table
slw_branch_table:
        
        
error0: 
        braa    slw_error_0_ptr
error1: 
        braa    slw_error_1_ptr
error2: 
        braa    slw_error_2_ptr
error3: 
        braa    slw_error_3_ptr
error4: 
        braa    slw_error_4_ptr

fast_sleep_entry:
        braa    slw_fast_sleep_enter_ptr
		
deep_sleep_enter:
        braa    slw_deep_sleep_enter_ptr

fast_sleep_exit:
        braa    slw_fast_sleep_exit_ptr

deep_sleep_exit:
        braa    slw_deep_sleep_exit_ptr

fast_winkle_enter:
        braa    slw_fast_winkle_enter_ptr

deep_winkle_enter:
        braa    slw_deep_winkle_enter_ptr

fast_winkle_exit:
        braa    slw_fast_winkle_exit_ptr

deep_winkle_exit:
        braa    slw_deep_winkle_exit_ptr
		
program8:       
        braa    slw_undefined_ptr
program9:       
        braa    slw_undefined_ptr
program10:      
        braa    slw_undefined_ptr
program11:      
        braa    slw_undefined_ptr
program12:      
        braa    slw_undefined_ptr
program13:      
        braa    slw_undefined_ptr
program14:      
        braa    _ptsDisableFromSlw
program15:      
        braa    _ptsEnableFromSlw

        
