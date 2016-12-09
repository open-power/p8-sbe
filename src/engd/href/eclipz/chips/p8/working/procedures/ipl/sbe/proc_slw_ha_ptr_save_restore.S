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
       
//------------------------------------------------------------------------------
// Local Macros 
//------------------------------------------------------------------------------
 
//------------------------------------------------------------------------------
// Subroutines
//------------------------------------------------------------------------------

///-----------------------------------------------------------------------------
/// \desc proc_slw_ha_write_ptr_save
///
/// \param[in]  P1  contains the target chiplet as this routine does not support
///                 multicast.  This is because the write pointers are unique
///                 per core. 
///
/// Register usage:
///		D0: 	Temporary scratch register (destroyed)
///		D1: 	Temporary scratch register (destroyed)
///		A0: 	SRAM Save Area Pointer
///		A1: 	Save/Restore index
///		P0: 	Multicast group for the target chiplets (used and not modified)
///		P1: 	Destroyed (chiplet index)
///		CTR: 	Destroyed (chiplet loop counter)
///          
///     SPRG0   16:31 - holds the initial chiplet vector for chiplet
///             This is used as work area for walking the chiplets;  this 
///             field is restored to the ETR value upon exit for use by other
///             routines.
///
/// The HA Write Address Pointer is a 17 bit value per chiplet so a 
/// .long (4B) is reserved for each.  Indexing uses the EX chiplet 
/// number after masking out the "0x10" from it (eg indexes are 0 - F.
/// However, access to the SRAM are in quads (eg 8B each).  Thus, the
/// structure allocates 8 quads (64B) for up to 16 chiplets. 
///
///  Structure
///                            Even            Odd
///      .quad  (8B) ->    4B (chiplet 0), 4B (chiplet 1)
///      .quad  (8B) ->    4B (chiplet 2), 4B (chiplet 3)
///      ....
///      .quad  (8B) ->    4B (chiplet E), 4B (chiplet F)

    .subroutine proc_slw_ha_write_ptr_save, slw, "$Revision: 1.1 $"
    
    POREVE_DBG("SLW HA Save entry...")


    // Drop the PCB Fence to allow SCOMs as the hardware has raised this
    // fence in the winkle entry process.  Done with multicast.
    sti     GENERIC_GP3_AND_0x000F0013,P0, ~BIT(26)  
    
    // Init pointer to save/restore structure
    la      A0, slw_ha_write_addr_ptr_sr_sram   
    
    mr      D1, SPRG0
    andi    D1, D1, SLW_SPRG0_CHIPLET_MASK  
    
    // Initialize P1 and CTR and execute the PORE for-loop paradigm to walk
    // the chiplet that are part of the transition.
	ls      P1, CHIPLET0
	ls      CTR, MAX_CORES
    bra     ha_save_loop_end  

ha_save_loop_begin:
        
    // Save the working chiplet vector from D1 to SPRG0 to free up D1
    mr      D0, SPRG0                       # Working copy
    andi    D0, D0, SLW_SPRG0_CHIPLET_CLEAR # Clear field
    or      D0, D0, D1                      # Store to field
    mr      SPRG0, D0
    POREVE_DBG("SLW HA Save SPRG0 chplt save             0x%08llX", 
                    io_pore.sprg0.read())

    andi    D0, D1, SLW_SPRG0_CHIPLET_TEST  # Clear all but the current
    POREVE_DBG("SLW HA Save D0 chplt masked              0x%016llX", 
                    io_pore.d0.read())
    braz    D0, ha_save_loop_continue   # If bit is 0, skip it
    
    // Get the base save/restore address for computation
    mr      D1, A0
    POREVE_DBG("SLW HA Save A0 pointer                   0x%08llX", 
                    io_pore.a0.read())
        
    // Compute the 8B entry to read
    mr      D0, P1
    andi    D0, D0, BITS(60,3)          # Mask to the even chiplet number
    sldi    D0, D0, 2                   # Mult by 4 (4B per chiplet) to create offset   
    add     D0, D0, D1                  # Compute the index address
    mr      A1, D0
    POREVE_DBG("SLW HA Save A1 index                     0x%08llX", 
                    io_pore.a1.read())
    
    // Read the L3 HA Dirty Address save entry for read-modify-write operation
    ld      D1, 0, A1                   # Load the index entry for RMW
    
    mr      D0, P1
    andi    D0, D0, BIT(63)             # Determine even/odd
    braz    D0, ha_save_even
    
ha_save_odd:
    /*
    ##@ fapi::ReturnCode rc;
    ##@ uint8_t platform = 0;
    ##@ rc = FAPI_ATTR_GET( ATTR_EXECUTION_PLATFORM, &i_target, platform );
    ##@ if( !rc.ok() )
    ##@ {
    ##@ return rc;
    ##@ }
    ##@ if( platform == ENUM_ATTR_EXECUTION_PLATFORM_FSP )
    ##@ {
    ##@ // Put info into D0 as though the hardware was read based on P1
    ##@ io_pore.d0.write(0x0123800000000000ull);
    ##@ printf ("--> Hook emulation of hardware via D0: 0x%16llx\n", io_pore.d0.read());
    ##@ io_pore.forceBranch("oci::ha_save_read_hw_odd");
    ##@ }
    ##@ return hookOk;
    */
        
    // Read the hardware.  Relevant information is in the high word (0:31)
    // As this is an odd chiplet, clear to the lower word (32:63) and insert
    // the new value.
    ld      D0, EX_L3_HA_DIRTY_ADDR_WR_PTR_0x10010832, P1
    
    .global ha_save_read_hw_odd
ha_save_read_hw_odd:    
    POREVE_DBG("SLW HA Save Odd chiplet detected")      
    POREVE_DBG("SLW HA Save D0 odd pre aligned         0x%016llX", 
                    io_pore.d0.read())
    srdi    D0, D0, 32                  # Align for merge
    POREVE_DBG("SLW HA Save D0 odd aligned             0x%016llX", 
                    io_pore.d0.read())
    andi    D1, D1, BITS(32,32)         # Clear S/R entry
    bra     ha_save_merge 

ha_save_even:
/*
    ##@ fapi::ReturnCode rc;
    ##@ uint8_t platform = 0;
    ##@ rc = FAPI_ATTR_GET( ATTR_EXECUTION_PLATFORM, &i_target, platform );
    ##@ if( !rc.ok() )
    ##@ {
    ##@ return rc;
    ##@ }
    ##@ if( platform == ENUM_ATTR_EXECUTION_PLATFORM_FSP )
    ##@ {
    ##@ // Put info into D0 as though the hardware was read based on P1
    ##@ io_pore.d0.write(0xABCD800000000000ull);
    ##@ printf ("--> Hook emulation of hardware via D0: 0x%16llx\n", io_pore.d0.read());
    ##@ io_pore.forceBranch("oci::ha_save_read_hw_even");
    ##@ }
    ##@ return hookOk;
*/

    // Read the hardware.  Relevant information is in the high word (0:31)
    // As this is an EVEN chiplet, clear to the high word (0:31) and insert
    // the new value.
    ld      D0, EX_L3_HA_DIRTY_ADDR_WR_PTR_0x10010832, P1

    .global ha_save_read_hw_even
ha_save_read_hw_even: 
    POREVE_DBG("SLW HA Save Even chiplet detected")      
      
    andi    D1, D1, BITS(0,32)          # Clear S/R entry

ha_save_merge:  
    or      D1, D0, D1                  # Merge new value
    std     D1, 0, A1                   # Store it away
    POREVE_DBG("SLW HA merged value stored               0x%016llX", 
                    io_pore.d1.read())

ha_save_loop_continue:

    // Restore the working chiplet vector to D1 from SPRG0
    mr      D1, SPRG0
    sldi    D1, D1, 1                   # Shift chiplet vector mask
    andi    D1, D1, SLW_SPRG0_CHIPLET_MASK  
    POREVE_DBG("SLW HA Save D1 rotated 1                 0x%016llX", 
                    io_pore.d1.read())

    mr      D0, P1
    adds    D0, D0, 1                   # Index next chiplet
    mr      P1, D0
    POREVE_DBG("SLW HA Save P1 incr chiplet              0x%02llX", 
                    io_pore.p1.read())
       
ha_save_loop_end:      
	
	loop    ha_save_loop_begin

ha_save_exit:        

    // Restore chiplet vector in the SPRG0 via Read-Modify-Write with the
    // value from the EXE Trigger (ETR)
	
    // Get the SPRG0 and clear the chiplet vector
	mr      D0, SPRG0
    andi    D0, D0, SLW_SPRG0_CHIPLET_CLEAR
    POREVE_DBG("     SLW Load SPRG0 Cleared                 0x%016llX", 
                    io_pore.d1.read())
    
	// Get the chiplet vector from the ETR
	mr      D1, ETR 
    POREVE_DBG("SLW HA Save SPRG0 D1 ETR                 0x%016llX", 
                    io_pore.d1.read())
    andi    D1, D1, SLW_ETR_CHIPLET_MASK        # Mask for the chiplet vector
    POREVE_DBG("SLW HA Save SPRG0 D1 andi chplt          0x%016llX", 
                    io_pore.d1.read())
    srdi    D1, D1, SLW_ETR_CM_RALIGN64         # Shift right to right justify
    POREVE_DBG("SLW HA Save SPRG0 D1 srdi chplt          0x%016llX", 
                    io_pore.d1.read())
                    
    // Merge with SPRG0 value and write back to SPRG0
    or      D0, D0, D1                          # Combine
    POREVE_DBG("SLW HA Save SPRG0 D0 or D1               0x%016llX", 
                    io_pore.d0.read())
    mr      SPRG0, D0                           # Save to SPRG0
    POREVE_DBG("SLW HA Save SPRG0 Register Value         0x%08llX", 
                    io_pore.sprg0.read())   
                    
    POREVE_DBG("SLW HA Save complete...")                 

    .end_subroutine proc_slw_ha_write_ptr_save

///-----------------------------------------------------------------------------
/// \desc proc_slw_ha_write_ptr_restore
///
/// \param[in]  P1  contains the target chiplet as this routine does not support
///                 multicast.  This is because the write pointers are unique
///                 per core. 
///
/// Register usage:
///		D0: 	Temporary scratch register (destroyed)
///		D1: 	Temporary scratch register (destroyed)
///		A0: 	SRAM Save Area Index
///		A1: 	0:23 - CTR Save/Restore; 24:31 - expected thread vector
///		P0: 	Multicast group for the target chiplets (used and not modified)
///		P1: 	Destroyed
///		CTR: 	Destroyed 
///          
///     SPRG0   16:31 - holds the initial chiplet vector for chiplet
///             This is used as work area for walking the chiplets;  this 
///             field is restored to the ETR value upon exit for use by other
///             routines.
///
/// The HA Write Address Pointer is a 17 bit value per chiplet so a 
/// .long (4B) is reserved for each.  Indexing uses the EX chiplet 
/// number after masking out the "0x10" from it (eg indexes are 0 - F.
/// However, access to the SRAM are in quads (eg 8B each).  Thus, the
/// structure allocates 8 quads (64B) for up to 16 chiplets. 
///
///  Structure
///                            Even            Odd
///      .quad  (8B) ->    4B (chiplet 0), 4B (chiplet 1)
///      .quad  (8B) ->    4B (chiplet 2), 4B (chiplet 3)
///      ....
///      .quad  (8B) ->    4B (chiplet E), 4B (chiplet F)

    .subroutine proc_slw_ha_write_ptr_restore, slw, "$Revision: 1.1 $"
    
    POREVE_DBG("SLW HA Restore entry...")
    
    // Init pointer to save/restore structure   
    la      A0, slw_ha_write_addr_ptr_sr_sram
    
    mr      D1, SPRG0
    andi    D1, D1, SLW_SPRG0_CHIPLET_MASK  

    // Initialize P1 and CTR and reexecute the PORE for-loop paradigm to walk
    // the chiplet that are part of the transition.
	ls      P1, CHIPLET0
	ls      CTR, MAX_CORES
    bra     ha_restore_loop_end         

ha_restore_loop_begin:
        
    // Save the working chiplet vector from D1 to SPRG0 to free up D1
    mr      D0, SPRG0                       # Working copy
    andi    D0, D0, SLW_SPRG0_CHIPLET_CLEAR # Clear field
    or      D0, D0, D1                      # Store to field
    mr      SPRG0, D0
    POREVE_DBG("SLW HA Restore SPRG0 chplt save             0x%08llX", 
                    io_pore.sprg0.read())

    andi    D0, D1, SLW_SPRG0_CHIPLET_TEST  # Clear all but the current
    POREVE_DBG("SLW HA Restore D0 chplt masked              0x%016llX", 
                    io_pore.d0.read())
    braz    D0, ha_restore_loop_continue       # If bit is 0, skip it
    

    // Get the base save/restore address for computation   
    mr      D1, A0
    POREVE_DBG("SLW HA Restore A0 pointer                   0x%08llX", 
                    io_pore.a0.read())
    
    // Compute the 8B entry to read
    POREVE_DBG("SLW HA Restore P1 index                     0x%02llX", 
                    io_pore.p1.read())
    mr      D0, P1
    andi    D0, D0, BITS(60,3)          # Mask to the even chiplet number
    sldi    D0, D0, 2                   # Mult by 4 (4B per chiplet) to create offset   
    add     D0, D0, D1                  # Compute the index address
    mr      A1, D0
    POREVE_DBG("SLW HA Restore A1 index                     0x%08llX", 
                    io_pore.a1.read())
    
    // Read the L3 HA Dirty Address save entry for read-modify-write operation
    ld      D1, 0, A1                   # Load the index entry for RMW
    POREVE_DBG("SLW HA Restore D1 entry read                0x%016llX", 
                    io_pore.d1.read())
    
    mr      D0, P1
    andi    D0, D0, BIT(63)             # Determine even/odd
    braz    D0, ha_restore_even
    
ha_restore_odd:
    POREVE_DBG("SLW HA Restore Odd chiplet detected")
    // Relevant information is in the  low word (32:63)
    // As this is an ODD chiplet, align to high word to write to hardware 
    sldi    D1, D1, 32                  # Align for write
    bra     ha_restore_write 

ha_restore_even:
    POREVE_DBG("SLW HA Restore Even chiplet detected")
    // Relevant information is in the high word (0:31)
    // As this is an EVEN chiplet, the save information is correctly aligned

ha_restore_write: 
    POREVE_DBG("SLW HA Restore pointer to chiplet 0x%02llX",  io_pore.p1.read())
    std     D1, EX_L3_HA_DIRTY_ADDR_WR_PTR_0x10010832, P1

ha_restore_loop_continue:

    // Restore the working chiplet vector to D1 from SPRG0.  done as RMW to 
    // retain the other fields.
    mr      D1, SPRG0
    sldi    D1, D1, 1                   # Shift chiplet vector mask
    andi    D1, D1, SLW_SPRG0_CHIPLET_MASK  
    POREVE_DBG("SLW HA Restore D1 rotated 1              0x%016llX", 
                    io_pore.d1.read())

    mr      D0, P1
    adds    D0, D0, 1                   # Index next chiplet
    mr      P1, D0
    POREVE_DBG("SLW HA Restore P1 incr chiplet           0x%02llX", 
                    io_pore.p1.read())
       
ha_restore_loop_end:      
	
	loop    ha_restore_loop_begin

ha_restore_exit:        

    // Restore chiplet vector in the SPRG0 via Read-Modify-Write with the
    // value from the EXE Trigger (ETR)
	
    // Get the SPRG0 and clear the chiplet vector
	mr      D0, SPRG0
    andi    D0, D0, SLW_SPRG0_CHIPLET_CLEAR
    POREVE_DBG("SLW Load SPRG0 Cleared                 0x%016llX", 
                    io_pore.d1.read())
    
	// Get the chiplet vector from the ETR
	mr      D1, ETR 
    POREVE_DBG("SLW HA Restore SPRG0 D1 ETR              0x%016llX", 
                    io_pore.d1.read())
    andi    D1, D1, SLW_ETR_CHIPLET_MASK        # Mask for the chiplet vector
    POREVE_DBG("SLW HA Restore SPRG0 D1 andi chplt          0x%016llX", 
                    io_pore.d1.read())
    srdi    D1, D1, SLW_ETR_CM_RALIGN64         # Shift right to right justify
    POREVE_DBG("SLW HA Restore SPRG0 D1 srdi chplt       0x%016llX", 
                    io_pore.d1.read())
                    
    // Merge with SPRG0 value and write back to SPRG0
    or      D0, D0, D1                          # Combine
    POREVE_DBG("SLW HA Restore SPRG0 D0 or D1            0x%016llX", 
                    io_pore.d0.read())
    mr      SPRG0, D0                           # Save to SPRG0
    POREVE_DBG("SLW HA Restore SPRG0 Register Value      0x%08llX", 
                    io_pore.sprg0.read())   
        
    POREVE_DBG("SLW HA Restore complete...")
                    

    .end_subroutine proc_slw_ha_write_ptr_restore

