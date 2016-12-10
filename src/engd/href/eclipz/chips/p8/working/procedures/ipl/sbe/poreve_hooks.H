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



#ifndef __POREVE_HOOKS_H
#define __POREVE_HOOKS_H


/// \file poreve_hooks.H
/// \brief Support for inline hook programming for PoreVe

#ifdef __ASSEMBLER__

/// A CPP macro to generate the marker for an address-based execution hook
///
/// The HOOK_MARKER macro inserts the ##1@ token into the output of CPP,
/// allowing the definition of CPP 'one-liner' macros that generate hooks.
/// See for example the definition of FAPI_INF.
///
/// Note that only one HOOK_MARKER is required per macro - multiline CPP
/// macros (which require a trailing '\' on each line) do not include
/// newlines, and effectively generate a single line of code.
#define HOOK_MARKER INSERT_HOOK_MARKER(#,#)

/// A helper macro for HOOK_MARKER
#define INSERT_HOOK_MARKER(x,y) x##y##1@


/// \defgroup fapi_trace_hooks FAPI Trace Macros as PoreVe Hooks
///
/// These macros provide FAPI trace facilities in PoreVe environments
/// using the similar macro names and syntax as the native FAPI trace macros.
///
/// @{

/// Generate a FAPI informational trace
#define POREVE_INF(...) HOOK_MARKER FAPI_INF(__VA_ARGS__); return hookOk;

/// Generate a FAPI 'important' trace
#define POREVE_IMP(...) HOOK_MARKER FAPI_IMP(__VA_ARGS__); return hookOk;

/// Generate a FAPI error trace
#define POREVE_ERR(...) HOOK_MARKER FAPI_ERR(__VA_ARGS__); return hookOk;

/// Generate a FAPI debug trace
#define POREVE_DBG(...) HOOK_MARKER FAPI_DBG(__VA_ARGS__); return hookOk;

/// @}


/// \defgroup scom_hooks SCOM Macros as PoreVe Hooks
///
/// @{

/// Put a 64-bit immediate value to a 32-bit SCOM address
#define PUTSCOM(address, data)                  \
    HOOK_MARKER                                 \
    ecmdDataBufferBase d;                       \
    d.setDoubleWordLength(1);                   \
    d.setDoubleWord(0, data);                   \
    return fapiPutScom(i_target, address, d);

/// @}


/// Generate a dump of the PORE register state using FAPI_DBG
#define POREVE_DUMP() HOOK_MARKER io_pore.dump(); return hookOk;

#endif  // __ASSEMBLER__

#endif  // __POREVE_HOOKS_H
