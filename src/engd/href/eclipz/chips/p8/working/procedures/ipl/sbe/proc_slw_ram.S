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
#include "proc_slw.H"
#define FOR_PORE_RAMMING
#include "p8_pore_table_gen_api.H"
#undef  FOR_PORE_RAMMING
        .list
#define SLW_ENABLE_SAFE_MSR
// Hook includes
##`#include<stdio.h>

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------

    .oci			// This code runs from OCI space to access SLW image
    .rt_text

//------------------------------------------------------------------------------
// Global Data 
//------------------------------------------------------------------------------

    .xip_quad slw_host_scom_nc_vector, 0, MAX_CORES
    .xip_quad slw_host_scom_l2_vector, 0, MAX_CORES
    .xip_quad slw_host_scom_l3_vector, 0, MAX_CORES
    .xip_quad slw_host_reg_vector,  0, MAX_CORES
    .xip_quad slw_fsp_scom_vector,  0, MAX_CORES
    .xip_quad scan_max_rotate_38xxx, 110
    .xip_quad waits_delay_for_scan, 0x0000

//PibMem setup
//    .pibmem_port  (PORE_SPACE_PIBMEM & 0xf)

//------------------------------------------------------------------------------
// Local Macros 
//------------------------------------------------------------------------------


 
/// -------------------------------  
/// Check D1 for a match to the passed thread number and load the RAM data if
/// a hit.  Otherwise, skip.
///
/// \param[in] thread Numeric thread number
///
/// \param[in] hit_target Label where to branch if a hit occurs
///
/// Preququisite:  D1 contains the currently targetted thread number (right 
/// justified)
/// Preserves:  D1, A0 and CTR
///
/// Notes:  We use SCRATCH0 for all threads. This is faster than using different
/// SCRATCH<n> for each thread<n>.
/// 
/// Todo: 1) do all PCRs. 4) Start using my image. 5) email greg.
///
    .macro thread_check_load_data_reg, thread:req, hit_target:req     
    
    POREVE_DBG("HOST Runtime check thread D1              0x%16llX", 
                     io_pore.d1.read())
    //xori    D0, D1, \thread
    ls      D0, \thread\()
    POREVE_DBG("HOST Runtime xori D0, D1, thrd            0x%16llX", 
                    io_pore.d0.read())
    sub    D0, D0, D1
    tfbne D0, check_\thread\()_skip
    
    POREVE_DBG("HOST Runtime data setup begin A0          0x%08llX", 
                     io_pore.a0.read())
 		
	  // Setup SPRC to point SPRD to threadn's SCRATCHn register
	  li      D0, (BIT(20+\thread\()))     // Set bit(20+thread<n>)
	  std     D0, EX_PERV_SPR_MODE_10013281, P1
//	  li      D0, (BIT(57)|(\thread\()<<3)) // Point SPRC to SCRATCH<n>
    li      D0, BIT(57)                  // Point SPRC to SCRATCH0
	  std     D0, EX_PERV_L0_SCOM_SPRC_10013280, P1

	// Load table data into D0
    ld      D0, RAM_DATA, A0  // A0 points to table entry, RAM_DATA is 8-byte offset

    POREVE_DBG("HOST Runtime RAM Data to Scratch          0x%16llX", 
                    io_pore.d0.read())

	  // Move table data in D0 into scratch<n> (register in SPRD)
//	  std    D0, EX_PERV_SCRATCH\thread\(), P1 // Put D0 into scratch<n>
	  std    D0, EX_PERV_SCRATCH0, P1          // Put D0 into SCRATCH0
	  // Move table data in scratch<n> to gpr0 by ramming as follow:
	  // - Put opcode(mfspr gpr0, scratch0) into D0
	  // - Left shift 29 bits
//    li    D0, MFSPR_GPR0_SCRATCH\thread\()_RAM_READY
	  li    D0, MFSPR_GPR0_SCRATCH0_RAM_READY
    POREVE_DBG("HOST RAM Inst: shifted opcode(mfspr gpr0, scratch0) in D0  0x%16llX",
	              io_pore.d0.read());
	  ori		D0, D0, (\thread\()<<61)
    POREVE_DBG("HOST RAM Inst: shifted opcode + thread              in D0  0x%16llX",
	              io_pore.d0.read());

    // Ram the MFSPR instruction
    //
	  std     D0, EX_PERV_RAM_CTRL_0x10013C01, P1
    
    // Poll Ram status register to make sure the Ram completed - Begin
    //
    ld      D0, EX_PERV_RAM_STAT_0x10013C02, P1  // First poll to Ram complete
    POREVE_DBG("HOST RAM Inst: RAM STAT   0x%16llX", io_pore.d0.read());

    // Save away D1 and CTR, and restore later, to preserve them
    la      A1, slw_d1_sr
    std     D1, 0, A1
    la      A1, slw_ctr_sr
    mr      D1, CTR
    std     D1, 0, A1

    ls      CTR, RAM_COMPLETE_POLLS   // Load max polls in CTR
    ls      D1, 1                     // Initial poll count

ram_complete_loop_\thread\():

	  andi    D0, D0, BITS(0,4)
	  xori    D0, D0, RAM_STATUS_REG_AFTER_RAM
	  braz    D0, ram_complete_save_max_\thread\()
    
	  ld      D0, EX_PERV_RAM_STAT_0x10013C02, P1  // Another poll
    adds    D1, D1, 1                 // Increment poll count
    loop ram_complete_loop_\thread\() // Loop again

	  POREVE_ERR("Ram complete bits for mfspr ram not set (in thread_check_load_data_reg).")
	  reqhalt RC_SLW_RAM_STATUS_TIMEOUT_ERROR

ram_complete_save_max_\thread\():

    // Load prev count from Sram. If current count greater save the greater count.
    la      A1, ram_complete_max_polls
    ld      D0, 0, A1
    sub     D0, D0, D1
    tfbuge  D0, ram_mfspr_restore_\thread\() // Jump to exit if prev count D0 >= this count D1
    std     D1, 0, A1                 // ..otherwise, update sram with greater count D1

ram_mfspr_restore_\thread\():

    // Restore CTR and D1
    la      A1, slw_ctr_sr
    ld      D1, 0, A1
    mr      CTR, D1
    la      A1, slw_d1_sr
    ld      D1, 0, A1

    bra \hit_target\()

    //
    // Poll Ram status register                                 - End

check_\thread\()_skip:
    POREVE_DBG("HOST Runtime RAM: >>> skipping thread")
    
    .endm
   
// -------------------------------  
/// Check D1 for a match to the passed thread number and check the thread active
//  bit.  If not set, branch to error target. 
///
/// \param[in] thread Numeric thread number
///
/// \param[in] error_target Label where to branch if a non-active case is found
///

    .macro thread_quiesce_check, thread:req, error_target:req     
   
    ld      D0, EX_PERV_TCTL\thread\()_R_STAT, P1
//    POREVE_DBG("HOST Runtime Active Thread check : thread %x", \thread\())
    POREVE_DBG("HOST Runtime Active Thread check D0       0x%16llX", 
                    io_pore.d0.read())
   
    // Check for thread enabled 
//    mr      D1, D0  
//    andi    D1, D1,BIT(48)
//    POREVE_DBG("HOST Runtime Active Thread check (48) D1  0x%16llX", 
//                    io_pore.d1.read())   
//    branz   D1, enable_error_\thread\()
    
    mr      D1, D0  
    andi    D1, D1,BIT(49)
    POREVE_DBG("HOST Runtime Active Thread check quiesce (49) D1  0x%16llX", 
                    io_pore.d1.read())  
    branz   D1, active_check_end_\thread\()  
    
    POREVE_DBG("HOST Runtime Active Thread check (49) Quiesce Error")
    bra     \error_target\()   

active_check_end_\thread\():
    
    .endm


//------------------------------------------------------------------------------
// Subroutines
//------------------------------------------------------------------------------

/// sub_slw_runtime_scom 
///
/// Perform both the SCOM and RAM of registers that are dynamically defined at
/// runtime via the p8_slw_api.
///
/// CTR can be used as this will be called in the top level flow where
/// P0 contains the multicast write group.  ETR has the valid chiplet vector.
///    
///  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	Temporary scratch register
/// 		A0: 	Points to the RAM routine to run
/// 		A1: 	Points to the host_reg_table
/// 		P0: 	Chiplet/Multicast ID pointer (unmodified)
/// 		P1: 	Chiplet ID pointer
/// 		CTR: 	Chiplet counter
///         SPRG0:  Running chiplet mask save area (subset of bits)
///         ETR     Applicable chiplets to be restored
    
    .subroutine sub_slw_runtime_scom, slw, "$Revision: 1.31 $"

    // If not idle (eg IPL), exit out
    ifnidle D0, end_proc

test_for_deep_sleep_exit:
		mr		D0, SPRG0
		andi	D0, D0, SLW_SPRG0_TV_DSX_MASK
		braz  D0, test_for_deep_winkle_exit
    //POREVE_INF("Prestart PC threads in sleep")
    //bsr 	slw_pc_prestart_sleep
    POREVE_INF("Restoring PC threads to their pre-sleep states")
    bsr   proc_slw_sleep_thread_restore
    nop
    bra 	prestart_done

test_for_deep_winkle_exit:
		mr		D0, SPRG0
		andi	D0, D0, SLW_SPRG0_TV_DWX_MASK
		braz  D0, no_prestart_todo
	  POREVE_INF("Prestart PC threads in winkle")
	  bsr 	slw_pc_prestart_winkle
    nop
		bra 	prestart_done

no_prestart_todo:

    nop

prestart_done:

    // As SCOMs and ramming are core specific, P1 is used to perform the RAM
    // operations so as to not destroy P0
  
    POREVE_DBG("HOST Runtime: called with ETR           0x%08llX",
                        io_pore.etr.read());
           
    // Get chiplet vector from ETR and right align
    mr D1, ETR
    srdi D1, D1, SLW_ETR_CM_RALIGN64    

    // Save away in SPRG0 for rotation
    mr D0, SPRG0
    andi D0, D0, SLW_SPRG0_CHIPLET_CLEAR
    or D0, D0, D1
    mr SPRG0, D0

	  // Initialize P1 and CTR and execute the PORE for-loop paradigm
    // P1 is used so as to not mess with the MC group in P0
	  ls P1, CHIPLET0
	  ls CTR, MAX_CORES
    bra end_loop
	
chiplet_loop:
    // Check to see if chiplet is exiting as part of this transition
    
    POREVE_DBG("HOST Runtime: chiplet 0x%03llX  SPRG0      0x%08llX",
                          io_pore.p1.read(), io_pore.sprg0.read());

    // Load running vector from SPRG0
    mr D0, SPRG0
    andi D0, D0, SLW_SPRG0_CHIPLET_MASK

    // Check if this chiplet is to be processed.  Skip if 0
   	andi D0, D0, SLW_SPRG0_CHIPLET_TEST // Clear all but test bit (being rotated)
    braz D0, next_loop                  
    
    // Perform dynamic SCOM restoration of API generated PGAS instructions
    POREVE_INF("HOST Runtime begin SCOM processing");
    la      A1, slw_host_scom_nc_vector
    mr      D0, A1
    POREVE_DBG("HOST Runtime RAM: slw_host_scom_nc_vector     0x%016llX",
                        io_pore.d0.read());
    mr      D1, P1
    subs    D1, D1, CHIPLET0        # Compute zero based offset
    POREVE_DBG("HOST Runtime SCOM: chiplet zero based  0x%016llX",
                        io_pore.d1.read());
    sldi    D1, D1, 3               # Multiply by 8 for doubleword addressing
    POREVE_DBG("HOST Runtime SCOM: mult 8              0x%016llX",
                        io_pore.d1.read());
    add     D0, D0, D1              # Compute address of SCOM table pointer
    POREVE_DBG("HOST Runtime SCOM: computed host_scom  0x%016llX",
                        io_pore.d0.read());
    mr      A1, D0                  # Put pointer addreess into address reg
    ld      D1, 0, A1               # Get the pointer to the SCOM routine
    braz    D1, end_scom            # If 0, then there are no operations   
    POREVE_DBG("HOST Runtime calling SCOM subroutine");
    bsrd    D1                      # Call the generated subroutine
    POREVE_DBG("HOST Runtime returning from SCOM subroutine");
   
	  ld      D1, 0x15020015, P1
    POREVE_DBG("HOST Runtime SCOM: Check Scom 20015    0x%016llX", io_pore.d1.read());
		ld      D1, 0x1505000f, P1
    POREVE_DBG("HOST Runtime SCOM: Check Scom 5000F    0x%016llX", io_pore.d1.read());

end_scom:
    
    // Perform dynamic CPU Register restoration of API generated list
    
    // Check for presence of CPU RAM list  for this core
    POREVE_INF("HOST Runtime begin RAM processing");
    la      A1, slw_host_reg_vector
    mr      D0, A1
    POREVE_DBG("HOST Runtime RAM: host_reg_vector       0x%016llX",
                        io_pore.d0.read());
    mr      D1, P1
    subs    D1, D1, CHIPLET0        # Compute zero based offset
    POREVE_DBG("HOST Runtime RAM: chiplet offset        0x%016llX",
                        io_pore.d1.read());
    sldi    D1, D1, 3               # Multiply by 8 for doubleword addressing
    POREVE_DBG("HOST Runtime RAM: mult 8                0x%016llX",
                        io_pore.d1.read());                                        
    add     D0, D0, D1              # Compute address of core reg table pointer
    POREVE_DBG("HOST Runtime RAM: core reg table ptr    0x%016llX",
                        io_pore.d0.read());
    mr      A1, D0                  # Put pointer address into address reg
    POREVE_DBG("HOST Runtime RAM: computed host_reg addr 0x%016llX  A1  0x%08llX ",
                        io_pore.d0.read(), io_pore.a1.read());
    ld      D1, 0, A1               # Get the pointer to the core reg table
    POREVE_DBG("HOST Runtime RAM: core_reg_table        0x%016llX",
                        io_pore.d1.read());
    braz    D1, end_ram             # if 0 (NULL ptr), then there are no operations   

    // Get the pointer to the core reg table
    mr      A0, D1
    POREVE_DBG("HOST Runtime RAM: core_reg_table A0     0x%08llX",
                        io_pore.a0.read());

		// Fixed image support: Check for empty table content, even if not NULL ptr.
    ld      D1, 0,A0                # Load table content - Need to check for zeros.
		braz    D1, end_ram             # if 0 (zero content), then there are no ops.

    // A0 is pointing to the RAM table for core
    // A1 is pointing to the core entry in host_reg_table
    
    // Put the core into core reg mode
    bsr     sub_slw_ramstart        # needs P1

#ifdef SLW_ENABLE_SAFE_MSR
    // Save MSR and setup MSR (e.g., disable machine interrupts ME-bit51)
		// CMO-20130508: This is not done in a thread specific way. It should really
		//               but it's not important since PHYP always programs the MSRs.
		bsr     sub_slw_msr_setup
#endif

ram_loop:
   
    ld      D0, 0, A0               # Load entry into D0
    
    POREVE_DBG("HOST Runtime RAM: header/instruct       0x%016llX",
                        io_pore.d0.read());

#ifdef SLW_ENABLE_SAFE_MSR
    // Extract the header type to determine if mtmsrd instruction. 
		// If type==0, then mtspr instr  => do nothing.
		// If type==1, then mtmsrd instr => set flag in slw_msr_rammed.  
		extrdi  D1, D0, 2, 2
		andi    D1, D1, 0x0000000000000003
		POREVE_DBG("HOST Runtime RAM: header type           0x%016llX", io_pore.d1.read());
		xori    D1, D1, 0x0000000000000001
		branz   D1, check_thread
    
    // save away A0 
    mr      D1, A0
    la      A0, slw_a0_sr
    std     D1, 0, A0
    
    la      A0, slw_saved_msr+8
    sti     0, A0, 0x0000000000000001
    
    // restore A0
    la      A0, slw_a0_sr
    ld      D1, 0, A0
    mr      A0, D1
    
check_thread:
#endif

    // Extract the thread ID to determine the addresses for both scratch data
    // and thread control
    extrdi  D1, D0, 16, 3
		andi    D1, D1, 0x0000000000000007
    POREVE_DBG("HOST Runtime RAM: extract thread        0x%016llX",
                        io_pore.d1.read());
    
    // Write thread scratch data register with the extracted data from the entry
    // based on the thread ID
    // A0 is pointing at the header of the entry; the data is at A0+8
    // The following macro 
    // - destroys D0 and A1
    // - preserves D1, A0 and CTR
    thread_check_load_data_reg  0, continue_list
    thread_check_load_data_reg  1, continue_list
    thread_check_load_data_reg  2, continue_list
    thread_check_load_data_reg  3, continue_list
    thread_check_load_data_reg  4, continue_list
    thread_check_load_data_reg  5, continue_list
    thread_check_load_data_reg  6, continue_list
    thread_check_load_data_reg  7, continue_list
   
    // Error case: thread specific test failed for some reason
    POREVE_DBG("HOST Runtime RAM: halt due to error     0x%016llX",
                        io_pore.d0.read());
    reqhalt RC_SLW_RAM_THREAD_CHECK_ERROR
    
continue_list:

    // Call sub_slw_raminst to physically perform the RAM and poll for completion
    ///  Register usage:
    /// 		D0: 	Can be destroyed
    /// 		D1:   Thread ID (right justified), but can be destroyed
    /// 		A0: 	Points to the RAM instruction to run, must be preserved
    /// 		A1: 	Can be destroyed
    /// 		P0: 	Chiplet/Multicast ID pointer (unmodified)
    /// 		P1: 	Chiplet ID pointer
    /// 		CTR: 	Chiplet counter, must be preserved
    ///         SPRG0: 
    ///         ETR     Applicable chiplets to be RAM restored
    bsr     sub_slw_raminstr
    
    // Extract the end flag
    ld      D0, 0, A0
    andi    D1, D0, RAM_HEADER_END_MASK
         
    POREVE_DBG("HOST RAM: Header end check  D1, D0      0x%16llX  0x%16llX",
                        io_pore.d1.read(),   io_pore.d0.read());

    branz    D1, end_list         // Check for end entry (a 1). if found, exit.
    
    // Increment to the next RAM entry
    adds    A0, A0, RAM_ENTRY_LENGTH
    POREVE_DBG("HOST RAM: Increment entry               0x%16llX",
                        io_pore.a0.read());

    bra     ram_loop
    
end_list: 
    POREVE_DBG("HOST RAM: End of list");

#ifdef SLW_ENABLE_SAFE_MSR
		// Restore MSR to original setting, unless it has been programmed by API.
    POREVE_DBG("HOST RAM: Restore MSR content");
		bsr     sub_slw_msr_restore
#endif

    bsr     sub_slw_ramstop

end_ram:
       
    POREVE_DBG("HOST RAM: Header end hit                0x%16llX",
                        io_pore.d1.read());
next_loop:

    // Reload running vector from SPRG0
    // Note:  D0 is destroyed when the above bsr is executed
    mr      D0, SPRG0
    andi D0, D0, SLW_SPRG0_CHIPLET_MASK                                            

    rols    D0, D0, 1                      // Rotate chiplet vector mask
    andi    D0, D0, SLW_SPRG0_CHIPLET_MASK // Clear any shifted out bits

    // Merge and save away in SPRG0
    mr      D1, SPRG0
    andi    D1, D1, SLW_SPRG0_CHIPLET_CLEAR
    or      D0, D0, D1
    mr      SPRG0, D0
    POREVE_DBG("HOST RAM: Restored SPRG0 to             0x%16llX", io_pore.d0.read());

    adds    P1, P1, 1                      // Index next chiplet using P1
    
end_loop:
    loop    chiplet_loop

end_proc:	

    POREVE_DBG("HOST RAM: End of sub_slw_runtime_scom");
    
		.global return_from_sub_slw_runtime_scom
return_from_sub_slw_runtime_scom:
    .end_subroutine sub_slw_runtime_scom


/// ----------------------------------------------------------------------------
/// sub_slw_ramstart
///
/// --------------------------------------------------- //
/// Setup for Ram                                       //
///  check for all threads quiesced                     //
///  For SLW exit, the core is, by definition, quiesced // 
///  Check anyway                                       //
///  put PC in ram mode                                 //
/// --------------------------------------------------- //
/// \todo confirm if this quiesce check can be removed
///  
///  Register usage:
/// 		D0: 	Temporary scratch
/// 		D1: 	Temporary scratch
/// 		A0: 	Points to instruction/data structure
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast ID pointer (unmodified)
/// 		P1: 	Chiplet ID pointer
/// 		CTR: 	Unused
///         SPRG0:  Unmodified
///         ETR     Unused
///
/// Instruction/Data Structure
/// .quad   instruction (4B instruction in 8B left justified
/// .quad   data        (8B of data to be written)
/// struct {
///     unit32_t    instruction
///     uint32_t    pad
///     uint64_t    data
///  };
///
    .subroutine sub_slw_ramstart, slw, "$Revision: 1.31 $"       
    
   
    POREVE_INF("********* SLW RAM activate       *********")

    // Check that the threads are all quiesced.  As this is run right after
    // a idle exit operation, this should be the case (eg no overt stopping
    // is needed
    thread_quiesce_check  0, ram_quiesce_error
    thread_quiesce_check  1, ram_quiesce_error
    thread_quiesce_check  2, ram_quiesce_error
    thread_quiesce_check  3, ram_quiesce_error
    thread_quiesce_check  4, ram_quiesce_error
    thread_quiesce_check  5, ram_quiesce_error
    thread_quiesce_check  6, ram_quiesce_error
    thread_quiesce_check  7, ram_quiesce_error

    ld         D0, EX_PERV_THREAD_ACTIVE_0x1001310E, P1
    POREVE_DBG("HOST RAM Inst: THREAD_ACTIVE Read      0x%16llX",
                       io_pore.d0.read());

    mr         D1, D0
    andi       D1, D1, (BITS(8,8))
    POREVE_DBG("HOST RAM Inst: THREAD_ACTIVE check D1   0x%16llX",
                       io_pore.d1.read());
    branz      D1, ram_quiesce_error

    // Activate all threads to accept RAM

    ori        D0, D0, (BITS(8,8))
    std        D0, EX_PERV_THREAD_ACTIVE_0x1001310E, P1
    POREVE_DBG("HOST RAM Inst: THREAD_ACTIVE Write     0x%16llX",
                       io_pore.d0.read());


    POREVE_DBG("Checking for Activate on core 0x%02llX", io_pore.p1.read())

    ld         D0, EX_PERV_THREAD_ACTIVE_0x1001310E, P1
    POREVE_DBG("HOST RAM Inst: THREAD_ACTIVE Check     0x%16llX",
                       io_pore.d0.read());

    // Check that all the threads activated
    andi       D0, D0, (BITS(8,8))
    cmpibrane  D0, ram_quiesce_error, (BITS(8,8))

    POREVE_INF("********* SLW RAM start          *********")
    
    sti         EX_PERV_RAM_MODE_0x10013C00, P1, 0xAAAA800000000000 

    POREVE_INF("********* SLW RAM start complete *********\n")

   bra ram_start_finish

ram_quiesce_error:
    POREVE_ERR("SLW RAM Quiesce Error...")
    reqhalt    RC_SLW_RAM_THREAD_QUIESCE_ERROR 
       
ram_start_finish:   
    
     
    .end_subroutine sub_slw_ramstart
     
     

/// ----------------------------------------------------------------------------
/// sub_slw_raminstr
///
/// ------------------------------------------------- //
/// Ram instruction                                   //
///  Poll Ram Stat register until idle.               //
///      Set Ram Data to the scom instruction         //
///      Poll Ram Stat register until idle.           //
/// ------------------------------------------------- //
///
/// \param[in] targeted_chiplet (P1)
/// \param[in] thread id (A1)
/// \param[in] address of instructions (A0) - each instruction is 4B in length
/// 
///
///  Register usage:
/// 		D0:   Destroyed
/// 		D1: 	Thread ID on input, then destroyed
/// 		A0: 	Points to the RAM instruction on input
/// 		A1: 	Destroyed
/// 		P0: 	Chiplet/Multicast ID pointer (unmodified)
/// 		P1: 	Chiplet ID pointer
/// 		CTR: 	Preserved, but temporarily used as polling counter
///         SPRG0:  
///         ETR     Applicable chiplets to be RAM restored
     
    .subroutine sub_slw_raminstr, slw, "$Revision: 1.31 $"
    
    ld		D0, 0, A0   // Load the instruction (32 bit) into D0 (left justified)
    POREVE_DBG("HOST RAM Inst: Instruction D0 D1        0x%16llX  0x%16llX",
                        io_pore.d0.read(),   io_pore.d1.read());
    sldi 	D0, D0, 29  // Shift instruction the upper half leaving 3 thrd bits
    POREVE_DBG("HOST RAM Inst: Shift instr D0           0x%16llX  0x%16llX",
                        io_pore.d0.read(),   io_pore.d1.read());
    sldi 	D1, D1, 61  // Shift 3 bit thread ID (bit 61:63) to bit 0 (61-0-1)
    POREVE_DBG("HOST RAM Inst: Shift thread D1          0x%16llX  0x%16llX",
                        io_pore.d0.read(),   io_pore.d1.read());
    or 		D1, D0, D1  // Combine the thread id with the instruction (in D1)
    
    POREVE_INF("********* SLW RAM Instruction    *********")
    POREVE_INF("********* Instruction = 0x%016llX", io_pore.d1.read())
 
    // -----------------------------------------------------------------
    // Do the Ramming: Store the instruction into RAM Control Register
		// -----------------------------------------------------------------
    std     D1, EX_PERV_RAM_CTRL_0x10013C01, P1

    // -----------------------------------------------------------------
    // Poll Ram status register to make sure the Ram completed - Begin
    // -----------------------------------------------------------------

    // Note, we do not impose any additional waits delay here since
    //   we want to poll as fast as possible and get out asap.

		ld      D0, EX_PERV_RAM_STAT_0x10013C02, P1 // First poll to Ram complete

    POREVE_DBG("HOST RAM Inst: RAM STAT poll            0x%16llX",
                        io_pore.d0.read());
 
 /*   
    ##@ // Force D0 to act like hdw
    ##@ io_pore.d0.write(0xF000000000000000ull);
    ##@ printf ("--> Hook force of RAM Status\n");
    ##@ return hookOk;
 */
    
    // Save away CTR, and restore later, to preserve it
    la      A1, slw_ctr_sr
    mr      D1, CTR
    std     D1, 0, A1

    ls      CTR, RAM_COMPLETE_POLLS   // Load max polls in CTR
    ls      D1, 1                     // Initial poll count

ram_complete_loop:

    andi    D0, D0, BITS(0,4)
    xori    D0, D0, RAM_STATUS_REG_AFTER_RAM
    braz    D0, ram_complete_save_max

    ld      D0, EX_PERV_RAM_STAT_0x10013C02, P1   // Another poll
    adds    D1, D1, 1               // Increment poll count
    loop ram_complete_loop          // Loop again

    POREVE_ERR("Ram complete bits for Ram not set.")
    reqhalt RC_SLW_RAM_STATUS_TIMEOUT_ERROR
    
ram_complete_save_max:

    // Load prev count from Sram. If current count greater save the greater count.
    la      A1, ram_complete_max_polls
    ld      D0, 0, A1
    sub     D0, D0, D1
    tfbuge  D0, slw_raminstr_restore // Jump to exit if prev count D0 >= this count D1
    std     D1, 0, A1                // ..otherwise, update sram with greater count D1

slw_raminstr_restore: 

    // Restore CTR
    la      A1, slw_ctr_sr
    ld      D1, 0, A1
    mr      CTR, D1

    //
    // Poll Ram status register                                 - End
    //
    
    POREVE_INF("********* SLW RAM Instruction Complete **\n")
    
    .end_subroutine sub_slw_raminstr
        
/// ----------------------------------------------------------------
/// sub_slw_ramstop
///
/// ------------------------------------------------- //
/// Exit Ram Mode                                     //
///  all ram operations are complete, return pc to    //
///  non-ram state                                    //
/// ------------------------------------------------- //
///  
///  Register usage:
/// 		D0: 	Unused
/// 		D1: 	Unused
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast ID pointer (unmodified)
/// 		P1: 	Chiplet ID pointer
/// 		CTR: 	Unused
///         SPRG0:  Unused
///         ETR     AUnused

    .subroutine sub_slw_ramstop, slw, "$Revision: 1.31 $"

    POREVE_INF("********* SLW RAM stop           *********")   
    sti EX_PERV_RAM_MODE_0x10013C00, P1, 0x0
    
    // The following is necessary as having this bits active
    // reduces core performance considerably.
    POREVE_INF("***  SLW RAM clear thread active bits  ***")     
    sti EX_PERV_THREAD_ACTIVE_0x1001310E, P1, 0x0

    POREVE_INF("********* SLW RAM stop complete *********\n")

    .end_subroutine sub_slw_ramstop
        

#ifdef SLW_ENABLE_SAFE_MSR
/// ----------------------------------------------------------------------------
/// sub_slw_msr_setup
///
/// ---------------------------------------------------- //
/// Prepare the MSR for ramming                          //
/// - Save original MSR in PIBMEM                        //
/// - Disable Machine Interrupt Enable ME-bit51 in MSR   // 
/// ---------------------------------------------------- //
///  
///  Register usage (CMO: confirm that these are as stated):
/// 		D0: 	Temporary scratch
/// 		D1: 	Temporary scratch
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast ID pointer (unmodified)
/// 		P1: 	Chiplet ID pointer
/// 		CTR: 	Unused
///         SPRG0:  Unmodified
///         ETR     Unused
///
    
		.subroutine sub_slw_msr_setup, slw, "$Revision: 1.31 $"       
    
    // "reset" SCRATCH0 to some recognizable value to ensure we can reliably check its 
		// content when putting GPR0 into it. We should actually logically check this...
		li      D0, SCRATCH0_RESET_VALUE
		std     D0, EX_PERV_SCRATCH0, P1

    POREVE_INF("********* SLW MSR Setup - Save MSR in PIBMEM temp storage     *********")
     
		// Setup SPRC to point SPRD to SCRATCH0 register
		li      D0, BIT(20)  // Use thread0_sprc
		std     D0, EX_PERV_SPR_MODE_10013281, P1
		li      D0, BIT(57)  // Point SPRC to SPRD's SCRATCH0 register for data
		std     D0, EX_PERV_L0_SCOM_SPRC_10013280, P1

    // Ram-copy MSR register to GPR0
		li      D0, MFMSR_GPR0_RAM_READY
		std     D0, EX_PERV_RAM_CTRL_0x10013C01, P1
		// We'll skip polling the ram control reg for now.

		// Ram-copy MSR in GPR0 to SCRATCH0
		li				D0, MTSPR_SCRATCH0_GPR0_RAM_READY
		std       D0, EX_PERV_RAM_CTRL_0x10013C01, P1

		// Scom-copy MSR in SCRATCH0 to D0
		ld				D0, EX_PERV_SCRATCH0, P1
    POREVE_DBG("MSR: Initial content =  0x%16llX", io_pore.d0.read());

    // Scom-copy MSR in D0 to SRAM
    // save away A0 
    mr      D1, A0
    la      A0, slw_a0_sr
    std     D1,0, A0

    la      A0, slw_saved_msr
    std     D0, 0, A0

    // restore A0
    la      A0, slw_a0_sr
    ld      D1, 0, A0
    mr      A0, D1

    POREVE_INF("********* SLW MSR Setup - Ram to MSR   *********")
    
		// Put predefined MSR value into SCRATCH0
		li				D0, P8_PORE_MSR_DURING_RAM
		std				D0, EX_PERV_SCRATCH0, P1
    POREVE_DBG("MSR: New intended content =  0x%16llX", io_pore.d0.read());

		// Ram-copy MSR in SCRATCH0 to GPR0
		li				D0, MFSPR_GPR0_SCRATCH0_RAM_READY
		std				D0, EX_PERV_RAM_CTRL_0x10013C01, P1

		// Ram-copy MSR in GPR0 to MSR
		li				D0, MTMSRD_GPR0_RAM_READY
		std				D0, EX_PERV_RAM_CTRL_0x10013C01, P1

    POREVE_INF("********* SLW MSR Setup - Done   *********\n")

// Check that mtmsrd alters the MSR reg.
// Debug - begin
    // "reset" SCRATCH0 to some recognizable value to ensure we can reliably check its 
		// content when putting GPR0 into it. We should actually logically check this...
		li      D0, SCRATCH0_RESET_VALUE
		std     D0, EX_PERV_SCRATCH0, P1

    // Copy MSR content to GPR0
		li        D0, MFMSR_GPR0_RAM_READY
		std       D0, EX_PERV_RAM_CTRL_0x10013C01, P1

		// Copy GPR0 to SCRATCH0
		li				D0, MTSPR_SCRATCH0_GPR0_RAM_READY
		std       D0, EX_PERV_RAM_CTRL_0x10013C01, P1

		// Copy SCRATCH0 to D0
		ld				D0, EX_PERV_SCRATCH0, P1
    POREVE_DBG("MSR: Actual new predetermined content (before ramming API) =  0x%16llX", io_pore.d0.read());
// Debug - end

    .end_subroutine sub_slw_msr_setup
     
     
/// ----------------------------------------------------------------------------
/// sub_slw_msr_restore
///
/// ---------------------------------------------------- //
/// Restore the MSR after ramming                        //
/// - Only restore original saved content if API has     //
///   not updated MSR.                                   // 
/// ---------------------------------------------------- //
///  
///  Register usage (CMO: confirm that these are as stated):
/// 		D0: 	Temporary scratch
/// 		D1: 	Temporary scratch
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast ID pointer (unmodified)
/// 		P1: 	Chiplet ID pointer
/// 		CTR: 	Unused
///         SPRG0:  Unmodified
///         ETR     Unused
///
    .subroutine sub_slw_msr_restore, slw, "$Revision: 1.31 $"       
    
    // "reset" SCRATCH0 to some recognizable value to ensure we can reliably check its 
		// content when putting GPR0 into it.
		li      D0, SCRATCH0_RESET_VALUE
		std     D0, EX_PERV_SCRATCH0, P1

		// Setup SPRC to point SPRD to SCRATCH0 register
		li      D0, BIT(20)  // Use thread0_sprc
		std     D0, EX_PERV_SPR_MODE_10013281, P1
		li      D0, BIT(57)  // Point SPRC to SPRD's SCRATCH0 register for data
		std     D0, EX_PERV_L0_SCOM_SPRC_10013280, P1

// Check content of MSR reg before restore (debugging only).
// Debug - begin
    // Copy MSR content to GPR0
		li        D0, MFMSR_GPR0_RAM_READY
		std       D0, EX_PERV_RAM_CTRL_0x10013C01, P1

		// Copy GPR0 to SCRATCH0
		li				D0, MTSPR_SCRATCH0_GPR0_RAM_READY
		std       D0, EX_PERV_RAM_CTRL_0x10013C01, P1

		// Copy SCRATCH0 to D0
		ld				D0, EX_PERV_SCRATCH0, P1
    POREVE_DBG("MSR: Actual MSR content (just after ramming API) =  0x%16llX", io_pore.d0.read());
// Debug - end

    POREVE_INF("********* SLW MSR Restore - Restore saved copy to MSR   *********")
		
		// First check if MSR has been rammed by instr from the .slw table. If flag
		// has been set, skip restoring the MSR.
    
    // Scom-copy MSR in D0 to SRAM
    // save away A0 
    mr      D1, A0
    la      A0, slw_a0_sr
    std     D1,0, A0

    la      A0, slw_saved_msr+8
    ld      D0, 0, A0

    // restore A0
    la      A0, slw_a0_sr
    ld      D1, 0, A0
    mr      A0, D1  
    
    POREVE_DBG("MSR: Was MSR rammed? [No:0 Yes:1]  Flag:0x%016llX", io_pore.d0.read());

    branz     D0, skip_msr_restore

    // Scom-copy saved MSR in SRAM to D0
    // save away A0 
    mr      D1, A0
    la      A0, slw_a0_sr
    std     D1,0, A0

    la      A0, slw_saved_msr
    ld      D0, 0, A0

    // restore A0
    la      A0, slw_a0_sr
    ld      D1, 0, A0
    mr      A0, D1  
    
		// Scom-copy saved MSR to SCRATCH0
		std       D0, EX_PERV_SCRATCH0, P1
    POREVE_DBG("MSR: Saved MSR content =  0x%16llX", io_pore.d0.read());

		// Ram-copy saved MSR in SCRATCH0 to GPR0
		li        D0, MFSPR_GPR0_SCRATCH0_RAM_READY
		std       D0, EX_PERV_RAM_CTRL_0x10013C01, P1

		// Ram-copy saved MSR to MSR
		li        D0, MTMSRD_GPR0_RAM_READY
		std       D0, EX_PERV_RAM_CTRL_0x10013C01, P1

    POREVE_INF("********* SLW MSR Restore - Done   *********")

skip_msr_restore:

// Always clear slw_saved_msr and its associated flag. And to avoid
//   confusion, also clear the PERV_SCRATCH0 register.
    li        D0, 0x0000000000000000

    // save away A0 
    mr      D1, A0
    la      A0, slw_a0_sr
    std     D1,0, A0

    la      A0, slw_saved_msr
    std     D0, 0, A0
		std     D0, 8, A0
        
    // restore A0
    la      A0, slw_a0_sr
    ld      D1, 0, A0
    mr      A0, D1  

// Check that mtmsrd alters the MSR reg.
// Debug - begin
    // "reset" SCRATCH0 to some recognizable value to ensure we can reliably check its 
		// content when putting GPR0 into it. We should actually logically check this...
		li      D0, SCRATCH0_RESET_VALUE
		std     D0, EX_PERV_SCRATCH0, P1

    // Copy MSR content to GPR0
		li        D0, MFMSR_GPR0_RAM_READY
		std       D0, EX_PERV_RAM_CTRL_0x10013C01, P1

		// Copy GPR0 to SCRATCH0
		li				D0, MTSPR_SCRATCH0_GPR0_RAM_READY
		std       D0, EX_PERV_RAM_CTRL_0x10013C01, P1

		// Copy SCRATCH0 to D0
		ld				D0, EX_PERV_SCRATCH0, P1
    POREVE_DBG("MSR: Actual restored content (after ramming API) =  0x%16llX", io_pore.d0.read());
// Debug - end
    
    sti       EX_PERV_SCRATCH0, P1, 0x0000000000000000

    .end_subroutine sub_slw_msr_restore

#endif


///------------------------------------------------------------------------------
/// PC Threads Prestart Sleep
///
/// Prime PC with the thread state for deep sleep exit.
///
/// For now (as was done in P7+), all the threads are put into Sleep state.
///
/// There is a pending change to read the thread state captured on Deep Sleep Entry
/// (location is TBD - either image memory or OHA register per core) and then
/// this routine will walk the chiplet vector (in ETR), read that chiplet's saved
/// state (8 bit vector indicating Sleep or Winkle per thread), and then hit either
/// bit 42 (Winkle, no its sleep) or bit 43 (Sleep, no its winkle).
///
///
///  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	Temporary scratch register
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast target
/// 		P1: 	Used to walk the chiplets in the ETR (when per thread support comes)
/// 		CTR: 	Unused
///         SPRG0:  Sets 0:7 with the Transition Vector bits

      .subroutine slw_pc_prestart_sleep, slw, "$Revision: 1.31 $"

        // Workaround hook
        hooki 0, 0xFF10
        
    //cmodebug
    setp1_mcreador D0
    la  A1, slw_oha_status_sleep
    ld  D0, EX_OHA_RO_STATUS_REG_0x1002000B, P1
    std D0, 0, A1
    //cmodebug-end
        //  Preload the last idle state - currently all to Sleep
        sti     EX_PERV_TCTL0_DIRECT_0x10013000, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL1_DIRECT_0x10013010, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL2_DIRECT_0x10013020, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL3_DIRECT_0x10013030, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL4_DIRECT_0x10013040, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL5_DIRECT_0x10013050, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL6_DIRECT_0x10013060, P0, BIT(42) // set SP_PRESTART_SLEEP
        sti     EX_PERV_TCTL7_DIRECT_0x10013070, P0, BIT(42) // set SP_PRESTART_SLEEP
               
	    .end_subroutine slw_pc_prestart_sleep

//------------------------------------------------------------------------------
/// PC Threads Prestart Winkle
///
/// Prime PC with the thread state for deep winkle exit.  As all threads had
/// to be in winkle to have entered winkle, all threads are primed with winkle
///
/// NB! The AISS must be disabled and PSCOM fence dropped ahead of this routine.
///
///  Register usage:
/// 		D0: 	Temporary scratch register
/// 		D1: 	Temporary scratch register
/// 		A0: 	Unused
/// 		A1: 	Unused
/// 		P0: 	Chiplet/Multicast target
/// 		P1: 	Unused
/// 		CTR: 	Unused
///         SPRG0:  Sets 0:7 with the Transition Vector bits

      .subroutine slw_pc_prestart_winkle, slw, "$Revision: 1.31 $"

        hooki 0, 0xFF10
        
    //cmodebug
    setp1_mcreador D0
    la  A1, slw_oha_status_winkle
    ld  D0, EX_OHA_RO_STATUS_REG_0x1002000B, P1
    std D0, 0, A1
    //cmodebug-end
        //  Preload the last idle state
        sti     EX_PERV_TCTL0_DIRECT_0x10013000, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL1_DIRECT_0x10013010, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL2_DIRECT_0x10013020, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL3_DIRECT_0x10013030, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL4_DIRECT_0x10013040, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL5_DIRECT_0x10013050, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL6_DIRECT_0x10013060, P0, BIT(43) // set SP_PRESTART_WINKLE
        sti     EX_PERV_TCTL7_DIRECT_0x10013070, P0, BIT(43) // set SP_PRESTART_WINKLE
       
	    .end_subroutine slw_pc_prestart_winkle

