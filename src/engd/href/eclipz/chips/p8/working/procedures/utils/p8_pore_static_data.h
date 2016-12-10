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




#ifndef _P8_PORE_STATIC_DATA_H
#define _P8_PORE_STATIC_DATA_H

extern const p8_pore_ringInfoStruct P8_PORE_RINGINFO[];
extern const int P8_PORE_RINGINDEX;

#endif /* _P8_PORE_STATIC_DATA_H */

/*
*************** Do not edit this area ***************
This section is automatically updated by CVS when you check in this file.
Be sure to create CVS comments when you commit so that they can be included here.
$Log: p8_pore_static_data.h,v $
Revision 1.1  2011/08/25 12:31:51  yjkim
initial check-in
Revision 1.2  2010/08/26 15:13:34  schwartz
Fixed more C++ style comments to C style comments
Revision 1.1  2010/08/26 03:57:02  schwartz
Changed comments to C-style
Changed "" to <> for #includes
Moved RINGINFO struct and RINGINDEX constant into separate object file, includes created static_data.h file
Put p7p_pore in front of #defines
Removed ring length from ringInfoStruct
Renamed scom operators to have SCOM in the name
Fixed gen_scan to use SCANRD and SCANWR pore instructions
Fixed compiler warnings
*/
