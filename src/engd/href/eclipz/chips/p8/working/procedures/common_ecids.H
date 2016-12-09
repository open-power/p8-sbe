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




#ifndef _COMMON_ECIDS_H_
#define _COMMON_ECIDS_H_


// Mask to use for direct comparision tests
CONST_UINT64_T( CFAM_CHIP_ID_CHIP_MASK                  , ULL(0x000FF00000000000) );
CONST_UINT64_T( CFAM_CHIP_ID_MAJOR_EC_MASK              , ULL(0xF000000000000000) );
CONST_UINT64_T( CFAM_CHIP_ID_MINOR_EC_MASK              , ULL(0x00F0000000000000) );
CONST_UINT64_T( CFAM_CHIP_ID_CHIP_MAJOR_MASK            , ULL(0xF00FF00000000000) );

/******************************************************************************/
/**********************************    ALL    *********************************/
/******************************************************************************/
CONST_UINT64_T( CFAM_CHIP_ID_MAJOR_EC_1                 , ULL(0x1000000000000000) );
CONST_UINT64_T( CFAM_CHIP_ID_MAJOR_EC_2                 , ULL(0x2000000000000000) );

/******************************************************************************/
/**********************************  VENICE  **********************************/
/******************************************************************************/
// The following are to be used under the masks above
CONST_UINT64_T( CFAM_CHIP_ID_VENICE                     , ULL(0x000ea00000000000) );
CONST_UINT64_T( CFAM_CHIP_ID_VENICE_1                   , ULL(0x100ea00000000000) );
CONST_UINT64_T( CFAM_CHIP_ID_VENICE_2                   , ULL(0x200ea00000000000) );

// The following are the exact values from the hardware
CONST_UINT64_T( CFAM_CHIP_ID_VENICE_10                  , ULL(0x120ea00100000000) );
CONST_UINT64_T( CFAM_CHIP_ID_VENICE_20                  , ULL(0x220ea00100000000) );
CONST_UINT64_T( CFAM_CHIP_ID_VENICE_21                  , ULL(0x221ea00100000000) );

/******************************************************************************/
/**********************************  NAPLES  **********************************/
/******************************************************************************/
// The following are to be used under the masks above
CONST_UINT64_T( CFAM_CHIP_ID_NAPLES                     , ULL(0x000d300000000000) );
CONST_UINT64_T( CFAM_CHIP_ID_NAPLES_1                   , ULL(0x100d300000000000) );
CONST_UINT64_T( CFAM_CHIP_ID_NAPLES_2                   , ULL(0x200d300000000000) );

// The following are the exact values from the hardware
CONST_UINT64_T( CFAM_CHIP_ID_NAPLES_10                  , ULL(0x120d300100000000) );
CONST_UINT64_T( CFAM_CHIP_ID_NAPLES_20                  , ULL(0x220d300100000000) );
CONST_UINT64_T( CFAM_CHIP_ID_NAPLES_21                  , ULL(0x221d300100000000) );

/******************************************************************************/
/**********************************  MURANO   *********************************/
/******************************************************************************/
// The following are to be used under the masks above
CONST_UINT64_T( CFAM_CHIP_ID_MURANO                     , ULL(0x000ef00000000000) ); 
CONST_UINT64_T( CFAM_CHIP_ID_MURANO_1                   , ULL(0x100ef00000000000) ); 
CONST_UINT64_T( CFAM_CHIP_ID_MURANO_2                   , ULL(0x200ef00000000000) );

// The following are the exact values from the hardware
CONST_UINT64_T( CFAM_CHIP_ID_MURANO_10                  , ULL(0x120ef00100000000) );
CONST_UINT64_T( CFAM_CHIP_ID_MURANO_20                  , ULL(0x220ef00100000000) );
CONST_UINT64_T( CFAM_CHIP_ID_MURANO_21                  , ULL(0x221ef00100000000) );


/******************************************************************************/
/**********************************  CENTAUR  *********************************/
/******************************************************************************/
CONST_UINT64_T( CFAM_CHIP_ID_CENTAUR                    , ULL(0x000e900000000000) );
CONST_UINT64_T( CFAM_CHIP_ID_CENTAUR_10                 , ULL(0x160e904900000000) );
CONST_UINT64_T( CFAM_CHIP_ID_CENTAUR_20                 , ULL(0x260e904900000000) );
CONST_UINT64_T( CFAM_CHIP_ID_CENTAUR_21                 , ULL(0x261e904900000000) );

#endif  // _COMMON_ECIDS_H_


/*
*************** Do not edit this area ***************
This section is automatically updated by CVS when you check in this file.
Be sure to create CVS comments when you commit so that they can be included here.
$Log: common_ecids.H,v $
Revision 1.4  2014/07/29 18:27:55  szhong
added Naples support
Revision 1.3  2013/04/06 15:52:32  stillgs
Update for EC masking
Revision 1.2  2013/02/06 06:11:33  stillgs
Updated so that ECIDs are in upper word to match the hardware
Revision 1.1  2013/01/17 15:00:40  stillgs
Initial checkin
*/
