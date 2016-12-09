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




// Change Log *********************************************************
//
//  Flag  def/feat  Userid    Date      Description
//  ----  --------  --------  --------  --------------------------------
//   @03  F750357   wfenlon   05/18/10  VPO & Model EC updates
// End Change Log *****************************************************

#include <ifScrubDataSpec.H>

/**
 * Looks for a useable text fragment based type of engd file.
 *
 * @param ENGD_FRAGMENT_TYPE i_type - Type of engd file.
 * @param ifstream & i_readFile - File to read from.
 *
 * @return bool - Returns true if not end-of-file
 */
bool EngdConfigFile::locateFragment()
{
    size_t cpA = string::npos;  // Character position

    while (getTangibleLine(cpA))
    {
        if (cv_line.substr(cpA,9) == "ringXList")
        break;
    }
                
    // Strip off leading whitespace
    if (cpA != string::npos)
        cv_line.erase(0, cpA);
    // Don't strip off trailing comments, cuz some spys have '#' in them!
    
    return (! cv_inStream.eof());
}


void EngdConfigFile::digestData()
{
    int rc = 0;
    string tempStr;
    size_t cpA;
    uint32_t numTokens;
    string chipTypeStr;
    string gblECstr;
    bool isAnyEC, cfgMatchUsrEC;
    
    do
    {
        while (locateFragment())
        {
            numTokens = parseLineTokens("{", 3);
            if (numTokens != 3 || getTokDel(2) != '{')
            { 
                ILOG(ERMSG) << "E[1002] **Error** Invalid exclude line format: " << cv_line << endl;
                rc = 2;
                break;
            }
            
            if (getTokStr(1) != P_ChipStr)
                continue;  // Found a chip, but not the one asked for
            
            if (getTokStr(2) == "ANY")
            {
                isAnyEC = true;
                cfgMatchUsrEC = true;
            }
            else
            {
                isAnyEC = false;
                cfgMatchUsrEC = (P_EvalEcStr == getTokStr(2));  // @03c - was P_EcStr
            }
            
            while (getTangibleLine(cpA) && (cv_line[cpA] != '}'))
            {
                numTokens = parseLineTokens("=!", 2);

                if (numTokens == 1 && (isAnyEC || cfgMatchUsrEC))
                {
                    P_ExcludeRingSet.insert(getTokStr(0));
                    continue;
                }
                else if (numTokens == 0)
                    continue;
                
                // Only legit way to get here is with a local ECFilter
                if ((getTokDel(0) == '=' && getTokStr(1) == P_EvalEcStr) ||  // @03c - was P_EcStr
                    (getTokDel(0) == '!' && getTokStr(1) != P_EvalEcStr) ||  // @03c - was P_EcStr
                    (getTokStr(1) == "ANY"))
                        P_ExcludeRingSet.insert(getTokStr(0));
            }
        }
        
    } while (0);
    
    DLOG(P3MSG) << "Exiting populateExcludeRings with number of excluded rings = " << P_ExcludeRingSet.size() << endl;
    
    return;
}
