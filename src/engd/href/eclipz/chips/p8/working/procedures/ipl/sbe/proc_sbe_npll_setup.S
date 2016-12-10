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
#include "common_ecids.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom

//------------------------------------------------------------------------------
// Constant Definitions
//------------------------------------------------------------------------------
       .set STEP_SBE_NPLL_SETUP_CPLOCK, 1
       .set STEP_SBE_NPLL_SETUP_EMLOCK, 2
       .set STEP_SBE_NPLL_SETUP_XBUSLOCK, 3
        
//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_npll_setup, ipl, "$Revision: 1.9 $"

        ##@  //Switch to 9600MHz-based clocking before starting PLLs
        ##@  fapi::ReturnCode l_rc = fapi::FAPI_RC_SUCCESS;
        ##@  uint8_t is_sim;
        ##@  do
        ##@  {
        ##@      l_rc = FAPI_ATTR_GET( ATTR_IS_SIMULATION, &i_target, is_sim);
        ##@      if (l_rc)
        ##@      {
        ##@          FAPI_ERR("fapi_attr_get( ATTR_IS_SIMULATION ) failed. "
        ##@                   "With rc = 0x%x", (uint32_t) l_rc );
        ##@          break;
        ##@      }
        ##@      if( is_sim )
        ##@      {
        ##@          FAPI_INF("Switching to 9600MHz-based clocking in sim!");
        ##@          char command[60];
        ##@          ecmdChipTarget e_target;
        ##@          fapiTargetToEcmdTarget( i_target, e_target);
        ##@          sprintf(command, "BATCH n%ip%i_9600MHz_clocking", e_target.node, e_target.pos);
        ##@          uint32_t rc_ecmd = simSUBCMD( command );
        ##@          if( rc_ecmd )
        ##@          {
        ##@              FAPI_ERR("Error (0x%x) running BATCH 9600MHz_clocking", 
        ##@                       rc_ecmd);
        ##@              l_rc.setEcmdError(rc_ecmd);
        ##@              break;
        ##@          }
        ##@      }
        ##@  } while (0);
        ##@  return l_rc;

        //Note: This code uses P1 for chiplet 0, and P0 for variable chiplet targeting
        lpcs    P1, STBY_CHIPLET_0x00000000
        lpcs    P0, TP_CHIPLET_0x01000000 

        //Filter PLLs
        POREVE_INF("CP/EM-Filter -> Release test enable" )
        bci     D0, MBOX_FSIGP4_0x00050013, P1, BIT(24)

        POREVE_INF("CP/EM-Filter -> Release PLL reset")
        bci     D0, MBOX_FSIGP3_0x00050012, P1, BIT(28)

        POREVE_INF("CP-Filter -> Poll PLLLOCKREG" )
        pollbitset D0, TP_PLL_LOCK_0x010F0019, P0, 0, 30, 50, cpfilt_nolock

        POREVE_INF("CP Filter -> PLL locked" )
        updatestep STEP_SBE_NPLL_SETUP_CPLOCK, D0, P1

        POREVE_INF("EM-Filter -> Poll PLLLOCKREG" )
        pollbitset D0, TP_PLL_LOCK_0x010F0019, P0, 1, 30, 50, emfilt_nolock

	// SW299659 -> leave filter PLLs in bypass for Brazos
	lpcs	P1, STBY_CHIPLET_0x00000000
	ld	D0, PCBMS_DEVICE_ID_0x000F000F, P1
	andi	D0, D0, CFAM_CHIP_ID_CHIP_MASK
	cmpibraeq D0, stay_in_bypass, CFAM_CHIP_ID_NAPLES
	cmpibrane D0, drop_bypass, CFAM_CHIP_ID_VENICE
	// venice-based, check presence of SP
	ldandi	D0, MBOX_SCRATCH_REG1_0x00050039, P1, BIT(1) 
	braz	D0, stay_in_bypass
	// SPless will fall through and drop bypass control
drop_bypass:
        POREVE_INF("CP/EM-Filters -> Drop PLL bypass")
        bci     D0, MBOX_FSIGP3_0x00050012, P1, BIT(29)

stay_in_bypass:
        POREVE_INF("CP/EM-Filters -> PLL setup completed" )
        updatestep STEP_SBE_NPLL_SETUP_EMLOCK, D0, P1

        //XBUS PLL
        POREVE_INF("X-Bus -> Start Setup" )

        POREVE_INF("X-Bus -> Release test_bypass1" )
        bci     D0, MBOX_FSIGP4_0x00050013, P1, BIT(22)

        POREVE_INF("X-Bus -> Release PLL reset" )
        bci     D0, MBOX_GP3MIR_0x0005001B, P1, BIT(4) 

        //Murano DD1.x has a PLL lock workaround in the gear switcher, so can't check it here
        ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P1, (CFAM_CHIP_ID_CHIP_MASK | CFAM_CHIP_ID_MAJOR_EC_MASK)
        cmpibraeq D0, skip_poll_for_xbus_pll_lock,  (CFAM_CHIP_ID_MURANO    | CFAM_CHIP_ID_MAJOR_EC_1 )
        
poll_for_xbus_pll_lock: 
        POREVE_INF("X-Bus -> Poll PLLLOCKREG" )
        lpcs    P0, XBUS_CHIPLET_0x04000000
        pollbitset D0, X_PLLLOCKREG_0x040F0019, P0, 0, 30, 50, xbus_nolock

        POREVE_INF("X-Bus -> PLL setup completed (bypass will be dropped in the gear switcher)" )
        updatestep STEP_SBE_NPLL_SETUP_XBUSLOCK, D0, P1
skip_poll_for_xbus_pll_lock:    
        .end_procedure proc_sbe_npll_setup

cpfilt_nolock:
        POREVE_ERR("CP Filter -> Failed to lock");
        reqhalt RC_SBE_NPLL_SETUP_CPFILT_NOLOCK

emfilt_nolock:
        POREVE_ERR("EM Filter -> Failed to lock");
        reqhalt RC_SBE_NPLL_SETUP_EMFILT_NOLOCK

xbus_nolock:
        POREVE_ERR("X-Bus -> Failed to lock");
        reqhalt RC_SBE_NPLL_SETUP_XBUS_NOLOCK

