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

        .xip_quad host_runtime_scom, 0

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

        .procedure proc_sbe_ex_host_runtime_scom, slw, "$Revision: 1.11 $"

        // Run the SCOM sequence if the SCOM procedure is defined.
        la      A0, host_runtime_scom
        ld      D1, 0, A0
        braz    D1, 1f

        // Prep P1
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


        // Branch to sub_slw_runtime_scom()
        POREVE_INF("Launching Host Runtime SCOM routine")
        bsrd    D1


        // Prep P1
        setp1_mcreadand D0

        // Clear regular wake-up and restore PSCOM fence in OHA
        // These were established in proc_sbe_ex_scominit.S
        ld      D0, EX_OHA_AISS_IO_REG_0x10020014, P1
        andi    D0, D0, ~(BIT(15))
        ori     D0, D0, BIT(21)
        std     D0, EX_OHA_AISS_IO_REG_0x10020014, P0

        // Enable the AISS to allow further operation
        ld      D0, EX_OHA_MODE_REG_RWx1002000D, P1
        ori     D0, D0, (BIT(1))
        std     D0, EX_OHA_MODE_REG_RWx1002000D, P0

        bra     2f

1:
        // To accomodate IPL flow, where sub_slw_runtime_scom() is skipped

        setp1_mcreadand D0

        // Clear regular wake-up and restore PSCOM fence in OHA
        // These were established in proc_sbe_ex_scominit.S
        ld      D0, EX_OHA_MODE_REG_RWx1002000D, P1
        andi    D0, D0, ~BIT(1)
        std     D0, EX_OHA_MODE_REG_RWx1002000D, P0

        ld      D0, EX_OHA_AISS_IO_REG_0x10020014, P1
        andi    D0, D0, ~(BIT(15))
        ori     D0, D0, BIT(21)
        std     D0, EX_OHA_AISS_IO_REG_0x10020014, P0

        // Enable the AISS to allow further operation
        ld      D0, EX_OHA_MODE_REG_RWx1002000D, P1
        ori     D0, D0, (BIT(1))
        std     D0, EX_OHA_MODE_REG_RWx1002000D, P0

2:

        // If using cv_multicast, we need to set the magic istep number here
        la      A0, proc_sbe_select_ex_control
	ldandi	D0, 0, A0, PROC_CONTROL_INIT_ALL_EX
        braz    D0, 3f
        POREVE_DBG("Setting istep num to magic number because cv_multicast is set")
        lpcs    P1, MBOX_SBEVITAL_0x0005001C
        sti     MBOX_SBEVITAL_0x0005001C, P1, (PROC_SBE_EX_HOST_RUNTIME_SCOM_MAGIC_ISTEP_NUM << (4+32))
        
3:      
        
        .end_procedure proc_sbe_ex_host_runtime_scom
