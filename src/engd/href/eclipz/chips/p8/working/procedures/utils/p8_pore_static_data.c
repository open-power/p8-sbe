/* IBM_PROLOG_BEGIN_TAG                                                   */
/* This is an automatically generated prolog.                             */
/*                                                                        */
/* OpenPOWER Project                                                      */
/*                                                                        */
/* Contributors Listed Below - COPYRIGHT 2012,2016                        */
/* [+] International Business Machines Corp.                              */
/*                                                                        */
/*                                                                        */
/* Licensed under the Apache License, Version 2.0 (the "License");        */
/* you may not use this file except in compliance with the License.       */
/* You may obtain a copy of the License at                                */
/*                                                                        */
/*     http://www.apache.org/licenses/LICENSE-2.0                         */
/*                                                                        */
/* Unless required by applicable law or agreed to in writing, software    */
/* distributed under the License is distributed on an "AS IS" BASIS,      */
/* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or        */
/* implied. See the License for the specific language governing           */
/* permissions and limitations under the License.                         */
/*                                                                        */
/* IBM_PROLOG_END_TAG                                                     */




/*------------------------------------------------------------------------------*/
/* Don't forget to create CVS comments when you check in your changes!          */
/*------------------------------------------------------------------------------*/
#include "p8_pore_api_custom.h"
#include "p8_pore_api.h"
#include "p8_pore_static_data.h"

/* Note: this info is a place holder until we get all other rings */
const p8_pore_ringInfoStruct P8_PORE_RINGINFO[] = {
  /*ring name            ring local address    scan region/type*/
  { "REPR_RING_C0",      0x00034A08,           0x48000080 },
  { "REPR_RING_C1",      0x00034A02,           0x48002000 },
  { "REPR_RING_C2",      0x00034A01,           0x48004000 },
  { "REPR_RING_C3",      0x00034A04,           0x48000800 },
  { "REPR_RING_C4",      0x00034A07,           0x48000100 },
  { "REPR_RING_C5",      0x00034A05,           0x48000400 },
  { "REPR_RING_C6",      0x00034A07,           0x48000100 },
  { "REPR_RING_C7",      0x00034A05,           0x48000400 },
  /* P7P data
  { "EX_ECO_BNDY",       0x00034A08,           0x48000080 },
  { "EX_ECO_GPTR",       0x00034A02,           0x48002000 },
  { "EX_ECO_MODE",       0x00034A01,           0x48004000 },
  { "EX_ECO_LBST",       0x00034A04,           0x48000800 },
  { "EX_ECO_TIME",       0x00034A07,           0x4800010000000000 },
  { "EX_ECO_ABST",       0x00034A05,           0x4800040000000000 },
  { "EX_ECO_REGF",       0x00034A03,           0x4800100000000000 },
  { "EX_ECO_REPR",       0x00034A06,           0x4800020000000000 },
  { "EX_ECO_FUNC",       0x00034800,           0x4800800000000000 },
  { "EX_ECO_L3REFR",     0x00030200,           0x0200800000000000 },
  { "EX_ECO_DPLL_FUNC",  0x00030400,           0x0400800000000000 },
  { "EX_ECO_DPLL_GPTR",  0x00030402,           0x0400200000000000 },
  { "EX_ECO_DPLL_MODE",  0x00030401,           0x0400400000000000 },
  { "EX_CORE_BNDY",      0x00033008,           0x3000008000000000 },
  { "EX_CORE_GPTR",      0x00033002,           0x3000200000000000 },
  { "EX_CORE_MODE",      0x00033001,           0x3000400000000000 },
  { "EX_CORE_LBST",      0x00033004,           0x3000080000000000 },
  { "EX_CORE_TIME",      0x00033007,           0x3000010000000000 },
  { "EX_CORE_ABST",      0x00033005,           0x3000040000000000 },
  { "EX_CORE_REGF",      0x00032003,           0x2000100000000000 },
  { "EX_CORE_REPR",      0x00033006,           0x3000020000000000 },
  { "EX_CORE_FUNC",      0x00032000,           0x2000800000000000 },
  { "EX_CORE_L2FARY",    0x00031009,           0x1000900000000000 },
  */
};

const int P8_PORE_RINGINDEX=sizeof P8_PORE_RINGINFO/sizeof P8_PORE_RINGINFO[0];

/*
*************** Do not edit this area ***************
This section is automatically updated by CVS when you check in this file.
Be sure to create CVS comments when you commit so that they can be included here.
$Log: p8_pore_static_data.c,v $
Revision 1.2  2013/07/25 15:50:49  dcrowell
Remove HvPlic include, not needed for PHYP build
Revision 1.1  2011-08-25 12:32:01  yjkim
initial checkin
Revision 1.5  2010/10/19 22:34:41  schwartz
added #include <p7p_pore_static_data.h>
Revision 1.4  2010/08/26 15:13:33  schwartz
Fixed more C++ style comments to C style comments
Revision 1.3  2010/08/26 03:57:02  schwartz
Changed comments to C-style
Changed "" to <> for #includes
Moved RINGINFO struct and RINGINDEX constant into separate object file, includes created static_data.h file
Put p7p_pore in front of #defines
Removed ring length from ringInfoStruct
Renamed scom operators to have SCOM in the name
Fixed gen_scan to use SCANRD and SCANWR pore instructions
Fixed compiler warnings
Revision 1.2  2010/07/09 15:38:35  schwartz
Changed ring names to uppercase and updated length of rings.  Neither of these pieces of data are used in the gen_scan API, but is used when generating rings for verification
Revision 1.1  2010/06/23 23:10:06  schwartz
Moved constants ringInfoStruct and RINGINDEX into this file
*/
