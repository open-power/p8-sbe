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
        .oci
        .rt_text

//------------------------------------------------------------------------------
// Global Data 
//------------------------------------------------------------------------------
       
        .set THREADS,   8
        .set THREAD_PRESTART_SLEEP_BIT, 42
        .set THREAD_PRESTART_WINKLE_BIT, 43

//------------------------------------------------------------------------------
// Local Macros 
//------------------------------------------------------------------------------

 
/// -------------------------------  
/// dsx_thread_sleep_prestart - check if current thread to be processed for sleep
///
/// Check CTR for a match to THREADS-1-"passed thread number".  If match, set the 
///     Sleep thread prestart state.  Otherwise, skip.
///
/// \param[in] thread - Numeric thread number
///
  .macro dsx_thread_sleep_prestart, thread:req    
    mr      D0, CTR
    cmpibrane D0, dsx_sleep_\thread\()_skip, (THREADS-1-\thread\())
    sti     EX_PERV_TCTL\thread\()_DIRECT_0x100130\thread\()0, P1, (BIT(THREAD_PRESTART_SLEEP_BIT))

dsx_sleep_\thread\()_skip:
  .endm
 
/// -------------------------------  
/// dsx_thread_winkle_prestart - check if current thread to be processed for winkle
///
/// Check CTR for a match to THREADS-1-"passed thread number".  If match, set the 
///     winkle thread prestart state.  Otherwise, skip.
///
/// \param[in] thread - Numeric thread number
///
  .macro dsx_thread_winkle_prestart, thread:req    
      mr      D0, CTR
      cmpibrane D0, dsx_winkle_\thread\()_skip, (THREADS-1-\thread\())
      sti     EX_PERV_TCTL\thread\()_DIRECT_0x100130\thread\()0, P1, (BIT(THREAD_PRESTART_WINKLE_BIT))

dsx_winkle_\thread\()_skip:
    .endm

 

//------------------------------------------------------------------------------
// Procedure 
//------------------------------------------------------------------------------

/// \desc proc_slw_sleep_thread_restore
///
/// Loop through the chiplets to restore the thread state as the state is 
///                 different per core.  
///
/// Register usage:
///		D0: 	Destroyed
///		D1: 	Destroyed
///		A0: 	Destroyed
///		A1: 	Destroyed
///		P0: 	Not used
///		P1: 	Used as target chiplet index (looped)
///		CTR: 	Destroyed
///     SPRG0   Parms for subroutines internal to the base processing; hold SLW
///             return code

    .subroutine proc_slw_sleep_thread_restore, slw, "$Revision: 1.3 $"

	// Load the EXE Trigger (ETR) into D0 to build the chiplet vector.
	//
	// ETR is in the form of:
	//    0:7      - reserved
	//    8:11     - start vector (encoded)
	//    12:31    - reserved
	//    32:47    - 16 bit chiplet vector
	//    48:63    - reserved
	
	mr D1, ETR

	// Initialize P1 and CTR and execute the PORE for-loop paradigm
	ls      P1, CHIPLET0
	ls      CTR, MAX_CORES
	bra     end_loop_dsx_tr
	
chiplet_loop_dsx_tr_begin:
	
	// Check to see if chiplet should be added to multicast group
  andi    D0, D1, BIT(32)         # Clear all but bit 0 (the current chiplet)
	braz    D0, continue_dsx_tr     # If bit is 0, skip
	
	
  //----------------- former handler - begin ----------------

  // Save OHA status reg in sram. (For debugging purposes)
  la  A1, slw_oha_status_sleep
  ld  D0, EX_OHA_RO_STATUS_REG_0x1002000B, P1
  std D0, 0, A1

	// Save chiplet vector bits(32:47) and rem bits(48:63) in D1 to A1
	mr			A1, D1

  // Save chiplet CTR to A0
	mr			A0, CTR
	
  // Read the OHA_RO_STATUS_REG(24:31) that holds thread state from sleep entry
  ld      D1, EX_OHA_RO_STATUS_REG_0x1002000B, P1
  
  // D1 has the state mask.  Shift left 1 bit at a time. Test w/bit24.
  // State information (hw-actual):  0 - Sleep  1 - Winkle (figtree is opposite
  // but wrong up until Mur 2.1)

  // Initialize CTR and execute the PORE for-loop paradigm
  // Note:  CTR is counting down so it is a reverse index
  // for walking the thread state from 7 down to 0.
  ls      CTR, THREADS
  bra     dsx_thread_prestart_loop_end

dsx_thread_prestart_loop_begin:
        	
  // Extract the thread prestart state from bit 24 of D0
	andi  	D0, D1, BIT(24)

  // Based on the state of the test bit, branch to the correct prestart
  branz   D0, dsx_thread_prestart_winkle

  // Prestart in Sleep
dsx_thread_prestart_sleep:
  
  //  Process the tread via an unrolled loop 
  //                        Thread
  dsx_thread_sleep_prestart   0
  dsx_thread_sleep_prestart   1
  dsx_thread_sleep_prestart   2
  dsx_thread_sleep_prestart   3
  dsx_thread_sleep_prestart   4
  dsx_thread_sleep_prestart   5
  dsx_thread_sleep_prestart   6
  dsx_thread_sleep_prestart   7

  bra  dsx_thread_prestart_continue

  // Prestart in Winkle
dsx_thread_prestart_winkle:

  //  Process the tread via an unrolled loop 
  //                         Thread
  dsx_thread_winkle_prestart   0
  dsx_thread_winkle_prestart   1
  dsx_thread_winkle_prestart   2
  dsx_thread_winkle_prestart   3
  dsx_thread_winkle_prestart   4
  dsx_thread_winkle_prestart   5
  dsx_thread_winkle_prestart   6
  dsx_thread_winkle_prestart   7

dsx_thread_prestart_continue:

  // Shift D1 left by one bit
  rols    D1, D1, 1
        
dsx_thread_prestart_loop_end:      
	
	loop dsx_thread_prestart_loop_begin

end:
  
  // Restore chiplet CTR from A0
  mr			CTR, A0
	
	// Restore chiplet vector to D1 from A1.
	mr			D1, A1

	//------------------ former handler - end -----------------


  // Workaround hook
  hooki 0, 0xFF12

continue_dsx_tr:

	rols    D1, D1, 1 # Rotate chiplet vector mask
	adds    P1, P1, 1 # Index next chiplet

end_loop_dsx_tr:
	
	loop chiplet_loop_dsx_tr_begin
  
  .end_subroutine proc_slw_sleep_thread_restore

