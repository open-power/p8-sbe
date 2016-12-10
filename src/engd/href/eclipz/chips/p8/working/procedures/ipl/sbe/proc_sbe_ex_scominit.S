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
#include "proc_sbe_l3_pgood.H"
#include "common_ecids.H"
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

	.procedure proc_sbe_ex_scominit, slw, "$Revision: 1.9 $"

        //
	// NCU
        //

        //
	// L3
        //

	POREVE_DBG("Configuring L3 disable");
	l3_setup L3_SETUP_ACTION_DISABLE, L3_SETUP_UNIT_L3

        //
	// OHA
        //

	POREVE_DBG("Enable OHA to accept idle operations by removing idle state override");
	setp1_mcreadand D1
	ld      D0, EX_OHA_MODE_REG_RWx1002000D, P1
	POREVE_DBG("Read OHA_MODE value:    0x%16llx", io_pore.d0.read());
	andi    D0, D0, ~BIT(6)

	// if directed, disable sleep
	lia     A0, PORE_SPACE_SEEPROM, pm_sleep_enable
        ld      D1, 0x00, A0
	POREVE_DBG("Read SLEEP_ENABLE: %llX ...\n", io_pore.d1.read()) ;
	branz	D1, update_oha_mode_reg
	ori	D0, D0, BIT(2)

update_oha_mode_reg:	
	POREVE_DBG("Updated OHA_MODE value: 0x%16llx", io_pore.d0.read());
	std     D0, EX_OHA_MODE_REG_RWx1002000D, P0


        // set trace stop on checkstop
        // Get the ECID to apply trace setup to only Murano DD2+ / Venice
	lpcs	P1, STBY_CHIPLET_0x00000000
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P1, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
        cmpibraeq   D0, 1f,                         (CFAM_CHIP_ID_MURANO    | CFAM_CHIP_ID_MAJOR_EC_1 )

        POREVE_DBG("Configuring EX chiplet trace arrays to stop on checkstop/recoverable errors")
        sti     GENERIC_DBG_MODE_REG_0x000107C0, P0, BIT(7) | BIT(8)
        sti     GENERIC_DBG_TRACE_REG2_0x000107CB, P0, BIT(17)

1:
        .end_procedure proc_sbe_ex_scominit
