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



#ifndef __PTS_H__
#define __PTS_H__


/// \file pts.h
/// \brief PORE Thread Scheduler (PTS). 
///
/// This header file is required by the PTS scheduler code and all PTS
/// applications.  It includes both assembler and C structure definitions for
/// PTS structures - which must be kept consistent - as well as PTS
/// preprocessor and assembler macros. 

#include "pgas.h"
#include "pts_config.h"
#include "pts_command.h"
#include "pts_api.h"
#include "pts_internal.h"
#include "pts_structures.h"

#endif  // __PTS_H
