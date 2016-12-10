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



#ifndef IFSCRUBDATASPEC_H
#define IFSCRUBDATASPEC_H

// Change Log *********************************************************
//
//  Flag  def/feat  Userid    Date      Description
//  ----  --------  --------  --------  --------------------------------
//        F720242   wfenlon   08/26/09  Created
//        D724558   wfenlon   09/18/09  Update output/logging functions
//   @02  D750007   wfenlon   04/20/10  Fix EngdPublicScrubData assignment
//                                      operator compiler warning and switch to
//                                      case-insensitive sort for engdSpyInfoMap_t
//   @03  F750357   wfenlon   05/18/10  VPO & Model EC updates
//   @04  F858677   dpeterso  10/17/12  P8 updates - adding IPLMODE
//   @06  F866181   dpeterso  01/03/13  Support for 'env' as static init
//   @08  F868940   dpeterso  01/31/13  Combine flush ring parm in with dump ring option
//   @0A  D908472   dpeterso  12/03/13  Store affected rings names for build verification
// End Change Log *****************************************************

#include <ifScrubFileSpec.H>
#include <map>    // STL map container
#include <queue>  // STL queue & vector containers
#include <set>    // STL set container
#include <algorithm>         // For transform, uppercase functions
#include <ecmdDataBuffer.H>

using namespace std;


// Don't Care value
#define ENGD_DC_VALUE 0x5DAD


struct engdSpyData_t
{
    friend ostream& operator<<(ostream& ostr, const engdSpyData_t & rhs);

    ecmdDataBuffer bitBasis; // Contains enum string if espy, bit values if ispy
    // Note: espy is denoted by bitValid.getBitLength() == 0
    ecmdDataBuffer bitValid; // Marks which ispy bits are valid (may have gaps)
    streampos spySavePos;   // If spy in exclude ring, will have restore it later
    
    engdSpyData_t() : bitBasis(), bitValid() {}
    
    bool isEnum();

    bool setBuffer(uint32_t i_start, uint32_t i_length, string i_data);
};

// @02a - below
// case-independent (ci) string less_than
// returns true if s1 < s2
struct ci_less : binary_function<string, string, bool>
{
    // case-independent (ci) compare_less binary function
    struct nocase_compare : public binary_function<unsigned char,unsigned char,bool> 
    {
        bool operator() (const unsigned char& c1, const unsigned char& c2) const 
       {
           return tolower(c1) < tolower(c2);
       }
    };
    
    bool operator() (const string & s1, const string & s2) const
    {
    
    return lexicographical_compare 
          (s1.begin (), s1.end (),   // source range
           s2.begin (), s2.end (),   // dest range
                nocase_compare ());  // compare function
    }
}; // end of ci_less
// @02a - above

// @02c - replace less<string> with ci_less
typedef map<string, engdSpyData_t *, ci_less > engdSpyInfoMap_t;

enum ENGD_PARBIT_TRAIT
{
    ENGD_PARBIT_OUTPUT = 0,
    ENGD_PARBIT_INPUT  = 1,
    ENGD_PARBIT_ODD    = 0,
    ENGD_PARBIT_EVEN   = 1,
    ENGD_PARBIT_SINGLE = 0,
    ENGD_PARBIT_RANGE  = 1
};


// engdBitSpec_t objects are used to hold both plain bit data and parity information.
// Because init processing requires a lot of bits to be stored, this class combines
// address/length data with data/flag information in a single uint32_t "bitspec".
// The layout of information in the uint32_t is all encapsulated within the various
// class methods.  For the plain bit data, the object contains the bit value and
// address.  For parity, the object covers 3 different cases:
//   1. A single parity input bit,
//   2. A range of consecutive parity input bits, and
//   3. A single parity output bit.
// Cases 1 & 3 are covered by a single object containing an address and some
// flags to differentiate the cases.  In case 2 there is too much information
// for a single object, so 2 are used, where the first contains the starting
// address and the second contains the bit-length of the range.
class engdBitSpec_t
{
    friend ostream& operator<<(ostream& ostr, const engdBitSpec_t& rhs);
    
    private:
        uint32_t cv_bitspec;
    public:
        // Default ctor
        engdBitSpec_t()
            : cv_bitspec(0)
            {}
    
        // Plain bit data ctor with address/value inputs
        engdBitSpec_t(uint32_t addr, uint32_t valu)
        {
            cv_bitspec = addr & 0x0fffffff;
            if (valu)
                cv_bitspec |= 0x10000000;
        }
    
        // Parity data ctor with address, input parity bit flag, and range flag
        // or even parity flag inputs.
        // Usage of bools, in order: isBitParInput, isRangeOrEven, meaning
        // 00 This is an output parity bit calculated with odd parity
        // 01 This is an output parity bit calculated with even parity
        // 10 This is a single input parity bit
        // 11 This is the starting address of an input parity bit range
        engdBitSpec_t(uint32_t addr, ENGD_PARBIT_TRAIT isBitParInput, ENGD_PARBIT_TRAIT isRangeOrEven)
        {
            cv_bitspec = (cv_bitspec & 0x10000000) | (addr & 0x0fffffff);
            if (isBitParInput)
                cv_bitspec |= 0x40000000;
            if (isRangeOrEven)
                cv_bitspec |= 0x20000000;
        }
        
        // Copy ctor
        engdBitSpec_t(const engdBitSpec_t & rhs)
        {
            cv_bitspec = rhs.cv_bitspec;
        }

        // Assignment operator
        engdBitSpec_t & operator= (const engdBitSpec_t & rhs)
        {
            if (this != &rhs)
            {
                cv_bitspec = rhs.cv_bitspec;
            }
            
            return *this;
        }
                
        // less operator based on address
        bool operator<(const engdBitSpec_t& rhs) const
        {
            return (cv_bitspec & 0x0fffffff) < (rhs.cv_bitspec & 0x0fffffff);
        }

        // greater operator based on address
        bool operator>(const engdBitSpec_t& rhs) const
        {
            return (cv_bitspec & 0x0fffffff) > (rhs.cv_bitspec & 0x0fffffff);
        }
        
        // When storing address in class data, use this for clarity's sake
        uint32_t getAddress() const
        {
            return cv_bitspec & 0x0fffffff;
        }
        
        // When storing length in class data, use this for clarity's sake
        uint32_t getLength() const
        {
            return cv_bitspec & 0x0fffffff;
        }
        
        // Expected use with plain bit data only
        uint32_t getValue() const
        {
            if (cv_bitspec & 0x10000000)
            {
                return 1;
            }
            else
            {
                return 0;
            }
        }
        
        // Expected use with plain bit data only
        void setValue(const uint32_t rhs)
        {
            if (rhs)
            {
                cv_bitspec |= 0x10000000;
            }
            else
            {
                cv_bitspec &= 0x0fffffff;
            }
        }
        
        void setAddress(const uint32_t addr)
        {
            cv_bitspec = (cv_bitspec & 0x70000000) | (addr & 0x0fffffff);
        }
        
        // Expected use with parity based data only
        bool isBitParInput()
        {
            return (cv_bitspec & 0x40000000) != 0;
        }
        
        // Expected use with parity based data only
        // Only meaningful when parity bit (1) is 0
        bool isParBitRange()
        {
            return (cv_bitspec & 0x20000000) != 0;
        }
        
        // Expected use with parity based data only
        // Only meaningful when parity bit (1) is 1
        bool isEvenParity()
        {
            return (cv_bitspec & 0x20000000) != 0;
        }
};

// Custom output operator to display engdBitSpec_t as <addr>:<value>
ostream& operator<<(ostream& ostr, const engdBitSpec_t& rhs);

// These next 2 functions are defined for use with the engdPriorityBitQ_t to keep
// the bits ordered by address.  The sort needs to be ascending for FSI based
// chips, and descending for JTAG based chips (only P5IOC2 as far as I know)
bool fsiCmpAscending(const engdBitSpec_t& lhs, const engdBitSpec_t& rhs);
bool jtagCmpDescending(const engdBitSpec_t& lhs, const engdBitSpec_t& rhs);

// Define function pointer which will be assigned to point at one of the
// ascending or descending functions above once we know if chip is FSI or JTAG.
extern bool (*g_cmpFuncPtr)(const engdBitSpec_t&, const engdBitSpec_t&);

// Call this function on insert to engdPriorityBitQ_t to keep data sorted
struct BitSpecCompare
{
    bool operator()(const engdBitSpec_t& lhs, const engdBitSpec_t& rhs) const
    {
        return (*g_cmpFuncPtr)(lhs, rhs);
    }
};

// Define a custom type of priority_queue to keep a list of bits in sorted order.
// This makes use of the STL deque container, stores elements of type engdBitSpec_t,
// and uses the BitSpecCompare function to keep the elements sorted properly.
typedef priority_queue<engdBitSpec_t, deque<engdBitSpec_t>, BitSpecCompare> engdPriorityBitQ_t;

// This struct defines the set of all bits to be modified in a ring.  This
// inludes the plain bit data and the parity data.
struct engdBitStore_t
{
    engdPriorityBitQ_t     bitQData;
    vector<engdBitSpec_t>  parityData;
};

// Rather than store the whole engdBitStore_t struct in the following Ring
// Modifications Map, which would involve a copy of the entire struct, we will
// just store a pointer.
typedef engdBitStore_t * engdBitStorePtr_t;

// Define a custom version of the STL map container with a key = ring name, and
// each element being a pointer to an engdBitStore_t
typedef map<string, engdBitStorePtr_t, less<string> > engdRingModMap_t;


// Define a singleton to contain public (global) data
class EngdPublicScrubData
{
    public:
        static EngdPublicScrubData * Instance();
   
        EngdConfigFile  cv_cnfgFile;
        EngdInitFile    cv_initFile;
        EngdSpydefFile  cv_spydFile;
        EngdScandefFile cv_scndFile;
        
        string cv_reducedFn;
        ofstream cv_rifFile;
        string cv_ringImgFn;
        
        bool    cv_FSItype;
        string  cv_logFn;
        
        string   cv_chipStr;
        string   cv_argvEcStr;   // @03c - was cv_ecStr
        string   cv_evalEcStr;   // @03a
        string   cv_padEC;
        uint32_t cv_ecValue;
        
        set<string> cv_excludeRingSet;
        
        engdSpyInfoMap_t cv_spyInfoMap;
        engdRingModMap_t cv_ringModMap;

        bool     cv_dbgPlus;
        uint32_t cv_spyNumTotal;
        uint32_t cv_spyNumStatic;
        bool     cv_mimicEcmdRingDump;
        string   cv_ringToDump;
        bool     cv_dumpAsciiRingData;
        string   cv_asciiRingFn;
        bool     cv_iplModeFilter; // @04a
        string   cv_iplModeStr;    // @04a
        string   cv_envFilter;               // @06a
        map<string, string> cv_initDefines;  // @06a
        string   cv_ringListFn;              // @0Aa

        LogItStream cv_logData;
    private:
        EngdPublicScrubData()    // Private so that it can  not be called
            : cv_FSItype(true), cv_dbgPlus(false), cv_spyNumTotal(0),
            cv_spyNumStatic(0), cv_mimicEcmdRingDump(false),
            cv_dumpAsciiRingData(false), cv_iplModeFilter(false)
            {};                                                        // @04c
        EngdPublicScrubData(EngdPublicScrubData const&){};          // copy constructor is private
        EngdPublicScrubData& operator=(EngdPublicScrubData const&)  // assignment operator is private
        {
            // @02a - This is never used, but makes the compiler happy
            EngdPublicScrubData *p = new EngdPublicScrubData;
            return *p;
        };
        static EngdPublicScrubData* cv_Instance;
};

// Define shorthand expressions for accessing singleton data
#define P_CnfgFile EngdPublicScrubData::Instance()->cv_cnfgFile
#define P_InitFile EngdPublicScrubData::Instance()->cv_initFile
#define P_SpydFile EngdPublicScrubData::Instance()->cv_spydFile
#define P_ScndFile EngdPublicScrubData::Instance()->cv_scndFile
#define P_ReducedFn EngdPublicScrubData::Instance()->cv_reducedFn
#define P_RifFile EngdPublicScrubData::Instance()->cv_rifFile
#define P_RingImgFn EngdPublicScrubData::Instance()->cv_ringImgFn
#define P_FSItype EngdPublicScrubData::Instance()->cv_FSItype
#define P_LogFn EngdPublicScrubData::Instance()->cv_logFn
#define P_ChipStr EngdPublicScrubData::Instance()->cv_chipStr
#define P_IplModeFilter EngdPublicScrubData::Instance()->cv_iplModeFilter // @04a 
#define P_IplModeStr EngdPublicScrubData::Instance()->cv_iplModeStr       // @04a 
#define P_ArgvEcStr EngdPublicScrubData::Instance()->cv_argvEcStr   // @03c - was P_EcStr
#define P_EvalEcStr EngdPublicScrubData::Instance()->cv_evalEcStr   // @03a
#define P_PadEC EngdPublicScrubData::Instance()->cv_padEC
#define P_EcValue EngdPublicScrubData::Instance()->cv_ecValue
#define P_ExcludeRingSet EngdPublicScrubData::Instance()->cv_excludeRingSet
#define P_SpyInfoMap EngdPublicScrubData::Instance()->cv_spyInfoMap
#define P_RingModMap EngdPublicScrubData::Instance()->cv_ringModMap
#define P_DbgPlus EngdPublicScrubData::Instance()->cv_dbgPlus
#define P_SpyNumTotal EngdPublicScrubData::Instance()->cv_spyNumTotal
#define P_SpyNumStatic EngdPublicScrubData::Instance()->cv_spyNumStatic
#define P_MimicEcmdRingDump EngdPublicScrubData::Instance()->cv_mimicEcmdRingDump
#define P_EnvFilter EngdPublicScrubData::Instance()->cv_envFilter          // @06a 
#define P_DefinesMap EngdPublicScrubData::Instance()->cv_initDefines	   // @06a
#define P_RingListFn EngdPublicScrubData::Instance()->cv_ringListFn        // @0Aa 
#define P_RingToDump EngdPublicScrubData::Instance()->cv_ringToDump
#define P_DumpAsciiRingData EngdPublicScrubData::Instance()->cv_dumpAsciiRingData
#define P_AsciiRingFn EngdPublicScrubData::Instance()->cv_asciiRingFn
#define P_LogData EngdPublicScrubData::Instance()->cv_logData


#define ILOG(v) P_LogData << v

#ifdef BASICDBG
#define DLOG(v) if (0) ; else P_LogData << v
#else
#define DLOG(v) if (1) ; else P_LogData << v
#endif



// Inline function definitions
inline bool engdSpyData_t::isEnum()
{
    return bitValid.getBitLength() == 0;
}


#endif  // IFSCRUBDATASPEC_H
