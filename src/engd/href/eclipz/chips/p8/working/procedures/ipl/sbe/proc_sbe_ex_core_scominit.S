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
#include "proc_sbe_l2_pgood.H"
#include "proc_sbe_l3_pgood.H"
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
// Constants
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

        .procedure proc_sbe_ex_core_scominit, slw, "$Revision: 1.7 $"

    // Core

        // Force the hardware to think we're in special wakeup so the SCOMs will
        // succeed to the core due to the init state of Nap.  This does NOT
        // influence the PM state machines; only the wire indicating special
        // wake-up using the override in PMGP1
        // Bit 6 enables/disables override; bit 8 controls the Special Wake-up
        sti EX_PMGP1_OR_0x100F0105, P0, BIT(6) | BIT(8)

        setp1_mcreadand D0

        // Disable the AISS to allow the override 
        ld      D0, EX_OHA_MODE_REG_RWx1002000D, P1
        andi    D0, D0, ~(BIT(1))
        std     D0, EX_OHA_MODE_REG_RWx1002000D, P0   

        // Drop PSCOM fence to allow SCOM and set pm_wake-up to PC to accepts 
        // RAMs (SCOMs actually) in the IPL "Nap" state
        ld      D0, EX_OHA_AISS_IO_REG_0x10020014, P1
        ori     D0, D0, (BIT(15))
        andi    D0, D0, ~(BIT(21))
        std     D0, EX_OHA_AISS_IO_REG_0x10020014, P0
				
				//CMO-> Should prob reenable AISS here. But carefully...
        
        // These are dropped in proc_sbe_ex_host_runtime_scom.S

    // Clock Controller

        // Set the OPCG_PAD_VALUE to be fast enough to not allow overrun by the
        // OHA in for Deep Sleep Exit.  Set for 32 cycles (2 x 16) -> 0b010
        POREVE_INF("Setup OPCG_PAD_VALUE for Deep Sleep scanning ...")
        ld      D1, EX_OPCG_CNTL2_0x10030004, P1
        andi    D1, D1, ~(BITS(49,3))
        ori     D1, D1,  BIT(50)
        std     D1, EX_OPCG_CNTL2_0x10030004, P0

    // L2

        // set L2 inits to force single member mode if required
        POREVE_DBG("Configuring L2 single member mode ...");
        l2_single_member

        // set L2 inits to disable L3 if required
        POREVE_DBG("Configuring L3 disable ...");
        l3_setup L3_SETUP_ACTION_DISABLE, L3_SETUP_UNIT_L2
        
    // DTS
        // As this routine get runs for IPL, Winkle and Sleep, all Digital
        // Thermal Sensor setup is done here.  
        //
        // For the case of Sleep where the L3 DTS is still active, the 
        // initialization is redone anyway as, while this operation is going on, 
        // the atomic lock prevents other entities (eg OCC) from accessing it.  
        // This keep the flows the same.
        
        setp1_mcreadand D0
        POREVE_INF("Initialize DTS function ...")
        ld      D1, EX_THERM_MODE_REG_0x1005000F, P1
            
        // Enable DTS sampling - bit 5
        // Sample Pulse Count - bits(6:9)  set to a small number for sim
        // Enable loop 1 DTSs  (20:22); loop 2 DTSs (24)
        ori     D1, D1, (BIT(5)|BITS(6, 4)|BITS(20,3)|BIT(24))             
        std     D1, EX_THERM_MODE_REG_0x1005000F, P0

        .end_procedure proc_sbe_ex_core_scominit
