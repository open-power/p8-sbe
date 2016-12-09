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
#include "p8_slw.H"
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


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_run_exinit, ipl, "$Revision: 1.15 $"

        .callproc proc_sbe_ex_chiplet_reset

	    ifsleep D0, 1f
	    .callproc proc_sbe_ex_gptr_time_initf
1:
	    .callproc proc_sbe_ex_core_gptr_time_initf

         ifsleep D0, 1f
	    .callproc proc_sbe_ex_dpll_initf
1:
	    .callproc proc_sbe_ex_dpll_setup
        // The above proc contains SLW conditionals       

        .callproc proc_sbe_ex_chiplet_init
        // The above proc contains SLW conditionals      

	    ifsleep D0, 1f
	    .callproc proc_sbe_ex_repair_initf
1:
	    .callproc proc_sbe_ex_core_repair_initf

        .callproc proc_sbe_ex_arrayinit
        // The above proc contains SLW conditionals 
	
	    ifsleep D0, 1f
	    .callproc proc_sbe_ex_initf
1:
        .callproc proc_sbe_ex_core_initf

	    .callproc proc_sbe_ex_do_manual_inits
        // The above proc contains SLW conditionals 
        
        .callproc proc_sbe_ex_startclocks
	    
        ifsleep D0, 1f       
	    .callproc proc_sbe_ex_scominit          
1:              
	    .callproc proc_sbe_ex_core_scominit 
        //  The above proc sets SPWKUP override to allow core SCOMS    

        .callproc proc_sbe_ex_init_escape
        .callproc proc_sbe_ex_sp_runtime_scom
        .callproc proc_sbe_ex_occ_runtime_scom
                
        .callproc proc_sbe_ex_host_runtime_scom 
        // The above proc clears SPWKUP override to allow core to re-enter power save
       
	sti     GENERIC_GP3_AND_0x000F0013,P0, ~BIT(18)
 
        // As this overall procedure can be called from multiple places
        // (IPL and Sleep/Winkle Idle) and procedures invoked by ".callproc"
        // must have unique return points, the idle return points must be
        // invoked explicitly. The .end_idle macro does this check and early exit.
	    .end_idle proc_sbe_run_exinit

        .end_procedure proc_sbe_run_exinit
