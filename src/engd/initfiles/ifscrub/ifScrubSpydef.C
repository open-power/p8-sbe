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
//        F720242   wfenlon   08/26/09  Created
//  @02   D750007   wfenlon   04/20/10  Ignore case on espy enum compares &
//                                      error out if enum is never defined
//        D754106   dglbert   06/23/10  Fix warnings                               
//  @07   D866846   dpeterso  01/18/13  Add support for inversion mask                               
//  @08   D885046   dpeterso  05/29/13  Long hex strings causing segmentation fault                               
//  @09   D893871   dpeterso  07/31/13  Not handling spydef 'groups'                               
//  @0A   D908472   dpeterso  12/03/13  Store affected rings names for build verification
// End Change Log *****************************************************

#include <ifScrubDataSpec.H>
#include <iomanip>

bool EngdSpydefFile::locateFragment()
{
    size_t cpA = string::npos;  // Character position

    while (getTangibleLine(cpA))
    {
        if (cv_line.compare(cpA,  5, "idial") == 0 ||
            cv_line.compare(cpA,  5, "edial") == 0 ||
            cv_line.compare(cpA,  5, "alias") == 0 ||
            cv_line.compare(cpA,  9, "eplatches") == 0)
        {
            break;
        }
    }
                
    // Strip off leading whitespace
    if (cpA != string::npos)
        cv_line.erase(0, cpA);
    // Don't strip off trailing comments, cuz some spys have '#' in them!
    
    return (! cv_inStream.eof());
}

/**
 * Parses the config file (ifScrubber.config by default) to determine if any rings
 * are to be excluded for the specified chip and EC level.  If matching rings are
 * found, then a set of ring names is populated and returned to the caller.
 *
 * @param set<string> & o_ringSet - Set of ring names to excluded.
 *
 * @return int - Return 0 for success, non-0 for failure
 */


void EngdSpydefFile::digestData()
{
    int rc = 0;
    string lineA, lineB, spyName, ringName, tempStr, savedSpyName;		//@09c
    size_t cpA, cpB;
    string rPrefix;
    uint32_t bitSeq = 0, numTokens;
    bool bitValsKnown;
    engdSpyInfoMap_t::iterator spyMapIter;
    string spyEnumStr, sdEnumStr;
    bool isRingZone, isEnumZone, isEpcheckersZone, isExcluded, spyHasGroups = false;	// @09c
    streampos posOfRingBits;
    uint32_t bracketLevel, ringBracketLevel = 0;
    uint32_t thisBitCount, curBitAddr, bitValue;
    int bitAddr;
    engdBitStorePtr_t bitStorePtr;
    engdRingModMap_t::iterator modMapIter;
    pair<engdRingModMap_t::iterator, bool> modMapPair;
    set<string> eplatchSet;
    vector<streampos> vetoSpys;
    vector<streampos>::iterator vetoSpyIter;
    set<streampos> vetoDoneSet;
    uint32_t invMask =0; //@07a
    char invMaskChar;    //@07a
        
    cout << dec;
  
    do
    {
        // wf - what is this first group of statements for?!
        // cpA = cv_spydefFn.find_last_of('/');  // Seek to end of path
        // if (cpA != string::npos)
        //     cpA++;
        // else
        //     cpA = 0;

        while (locateFragment())
        {   // Foreach fragment ...
                        
            numTokens = parseLineTokens("{", 2);
            
            if (numTokens == 2 && getTokStr(0) == "eplatches")
            {
                uint32_t currAddr, currNumBits;
                uint32_t prevAddr = 0x3fffffff, prevNumBits = 0;
                uint32_t rangeStart = 0, rangeLength = 0;
                bool isInZone = false, isOutZone = false;
                ENGD_PARBIT_TRAIT parityType = ENGD_PARBIT_ODD;
                bool oneMoreTime = false;
                
                // Declared near entry, but needs to be init'd here
                isRingZone = false;
                
                // Check if this is an eplatch definition that matters
                if (eplatchSet.find(getTokStr(1)) == eplatchSet.end())
                {
                    // DLOG(P5MSG) << "failed eplatch search for: " << getTokStr(1) << endl;
                    continue;
                }
                else
                {
                    DLOG(P5MSG) << "MATCH eplatch search for: " << getTokStr(1) << endl;
                }
                    
                bracketLevel = 1;
                
                while (bracketLevel > 0 && getTangibleLine(cpA))
                {
                    cpB = cv_line.find_first_of("{}", cpA);
                    if (cpB != string::npos)
                    {
                        if (cv_line[cpB] == '{')
                            bracketLevel++;
                        else
                        {
                            bracketLevel--;
                            isOutZone = false;
                            if (! oneMoreTime)
                            {
                                isInZone  = false;
                                isRingZone = false;
                                continue;
                            }
                        }
                    }
                    
                    if (cv_line.substr(cpA, 8) == "function")
                    {
                        parityType = (cv_line.find("EVEN", cpA) == string::npos) ? ENGD_PARBIT_ODD : ENGD_PARBIT_EVEN;
                        continue;
                    }
                    
                    if (cv_line.substr(cpA, 2) == "in")
                    {
                        isInZone = true;
                        continue;
                    }
                    
                    if (cv_line.substr(cpA, 4) == "ring")
                    {
                        isRingZone = true;
                        if (isInZone)
                            oneMoreTime = true;
                        
                        if (getDelimitedString(cv_line, cpA+4, " \t", "", ringName, cpB))
                        {
                            // Make sure ring name is NOT in exclude list!
                            if (P_ExcludeRingSet.find(ringName) != P_ExcludeRingSet.end())
                            {
                                break;  // Skip rest of fragment
                            }
                            
                            // Get iterator to this ringName in map
                            modMapIter = P_RingModMap.find(ringName);
                            if (modMapIter == P_RingModMap.end())
                            {
                                // Not sure how this could happen -- here because
                                // we matched the eplatch name, but cannot find
                                // ringName in map?!
                                break;  // Skip rest of fragment
                            }
                        }
                        else
                        {
                            ILOG(ERMSG) << "E[1010] **Error** Failed to parse ring name here: " << cv_line << endl;
                            break;  // Skip rest of fragment
                        }

                        continue;
                    }
                    
                    if (cv_line.substr(cpA,3) == "out")
                    {
                        isOutZone = true;
                        continue;
                    }
                    
                    // Don't care about lines that are not in ring section
                    if (! isRingZone)
                        continue;
                    
                    // There are 2 ring sections in an eplatches definition --
                    // one for the "in" part and one for the "out" part.  At
                    // this point we are in one or the other.
                    // The next call, grabs a line of latch data for the ring:
                    // token 0 = number of bits
                    // token 1 = FSI-based bit address
                    // token 2 = JTAG-based bit address
                    numTokens = parseLineTokens("", 3);

                    // Each latch data line has 3+ tokens, and to insure full
                    // processing of ALL latch data lines, the code is designed
                    // to read one line past final latch line (thus the else).
                    if (numTokens == 3)
                    {   // A standard latch data line
                        currNumBits = decStrtoul(getTokStr(0));
                        if (P_FSItype)
                            currAddr = decStrtoul(getTokStr(1));
                        else
                            currAddr = decStrtoul(getTokStr(2));
                    }
                    else
                    {   // One beyond last latch data line
                        // Fudge vars to force any loose ends to be tied up
                        currAddr = prevAddr;
                        currNumBits = prevNumBits = 10;
                        oneMoreTime = false;
                    }
                    
                    if (isInZone)
                    { 
                        if (currAddr != (prevAddr + prevNumBits) &&
                            prevAddr != (currAddr + currNumBits))
                        {   // Found non-consecutive bits, or on final pass
                            // Check if range needs to be saved
                            if (rangeLength > 1)
                            {   // Saving a range of bits here
                                // First, write out the lowest addr in the range
                                if (prevAddr < rangeStart)
                                {
                                    // DLOG(P6MSG) << "1 InZone range detected, start/length = " << prevAddr << '/' << rangeLength << endl;
                                    modMapIter->second->parityData.push_back(engdBitSpec_t(prevAddr, ENGD_PARBIT_INPUT, ENGD_PARBIT_RANGE));
                                }
                                else
                                {
                                    // DLOG(P6MSG) << "2 InZone range detected, start/length = " << rangeStart << '/' << rangeLength << endl;
                                    modMapIter->second->parityData.push_back(engdBitSpec_t(rangeStart, ENGD_PARBIT_INPUT, ENGD_PARBIT_RANGE));
                                }
                                    
                                // Second, write out length of range
                                modMapIter->second->parityData.push_back(engdBitSpec_t(rangeLength, ENGD_PARBIT_INPUT, ENGD_PARBIT_RANGE));
                            }
                            else if (rangeLength) // Single bit
                            {
                                // Save it
                                // DLOG(P6MSG) << "Single bit detected, addr = " << prevAddr << endl;
                                modMapIter->second->parityData.push_back(engdBitSpec_t(prevAddr, ENGD_PARBIT_INPUT, ENGD_PARBIT_SINGLE));
                            }
                            
                            // In all cases, need to prepare for next loop
                            rangeLength = currNumBits;
                            rangeStart  = currAddr;
                        }
                        else  // Continuation of range processing
                            rangeLength += currNumBits;
                        
                        prevAddr    = currAddr;
                        prevNumBits = currNumBits;
                    }
                    else if (isOutZone)
                    {   // The bits from the "in" section will be used to form
                        // the parity bit that will be saved at the addr here
                        // DLOG(P6MSG) << "Parity out bit detected, addr = " << currAddr << ", eParity = " << parityType << endl;
                        modMapIter->second->parityData.push_back(engdBitSpec_t(currAddr, ENGD_PARBIT_OUTPUT, parityType));
                    }
                }
                
                continue;
            }  // end if eplatches
            
            // Grab the spy name
            if (numTokens == 2 && getTokDel(0) == ' ' && getTokDel(1) == '{')
            {
                spyName = getTokStr(1);
                // @02d - Replace use of uppercase transform func here with
                // case-insensitive compare as needed
                spyMapIter = P_SpyInfoMap.find(spyName);
                if (spyMapIter == P_SpyInfoMap.end())
                    continue;  // Spy is not in the map!
                DLOG(P5MSG) << "Matched spyname in MAP! " << spyName << endl;
                    
                DLOG(P5MSG) << ">>> " << cv_line << endl;
                if (spyMapIter->second->isEnum())
                {   // Working with an espy here
                    bitValsKnown = false;
                    spyEnumStr = spyMapIter->second->bitBasis.genAsciiStr();
                    DLOG(P5MSG) << "..> Looking for enum = " << spyEnumStr << endl;
                }
                else
                {   // Working with an ispy here
                    bitValsKnown = true;
                    if (spyMapIter->second->bitBasis.getBitLength() <= 32)
                    {
                        DLOG(P5MSG) << "..> Setting fixed value = " << hex <<
                            spyMapIter->second->bitBasis.getWord(0) << dec << endl;
                    }
                    else
                    {
                        DLOG(P5MSG) << "..> Setting fixed value = " << hex << spyMapIter->second->bitBasis.getWord(0) <<
                            ' ' << spyMapIter->second->bitBasis.getWord(1) << dec << endl;
                    }
                }
                
                bracketLevel = 1;
		if (spyHasGroups)		// Previous spy had groups	@09a
		{
		    DLOG(P5MSG) << "Deleting spy from map = " << spyName << endl; // @09a
		    P_SpyInfoMap.erase(savedSpyName);  // Safe to remove it now	@09a
		    spyHasGroups = false;	// New spy so reset groups flag	@09a
		}
                isRingZone = false;
                isEnumZone = false;
                isExcluded = false;
                isEpcheckersZone = false;
                curBitAddr = 0;
                posOfRingBits = streampos(0);
                // Walk thru lines for this spydef
                while (bracketLevel > 0 && getTangibleLine(cpA))
                {
                    cpB = cv_line.find_first_of("{}", cpA);
                    if (cpB != string::npos)
                    {
                        if (cv_line[cpB] == '{')
                            bracketLevel++;
                        else
                        {
                            bracketLevel--;
                            isRingZone = false;
                            isEnumZone = false;
                            isExcluded = false;
                            isEpcheckersZone = false;
                            continue;
                        }
                    }
                    
                    if (cv_line.substr(cpA, 5) == "group")	//	@09a
                    {
			DLOG(P5MSG) << "Found spy with groups = " << spyName << endl; // @09a
			spyHasGroups = true;	// Set groups flag	@09a
			savedSpyName = spyName;	// Remember spy name	@09a
		    }
                    if (cv_line.substr(cpA, 4) == "ring")
                    {
                        if (getDelimitedString(cv_line, cpA+4, " \t", "", ringName, cpB))
                        {
                            // Make sure ring name is NOT in exclude list!
                            if (P_ExcludeRingSet.find(ringName) != P_ExcludeRingSet.end())
                            {
                                DLOG(P5MSG) << "Excluded ring detected, " << ringName << ", do not store data!" << endl;
                                
                                // Save pos of spy that needs to be saved back to
                                // reduced IF. Will iterate thru vector later.
                                // BUT, if SavePos == 0, then this is part of a
                                // multi-spy & will be covered by other spy in set.
                                if (spyMapIter->second->spySavePos)
                                    vetoSpys.push_back(spyMapIter->second->spySavePos);
                                
                                // Remove this spy from map??
                                
                                // We still need to know how many bits are listed
                                // for this ring, cuz a spydef can contain
                                // multitple rings and we need to keep them in
                                // sync with the spy bit numbering.
                                isExcluded   = true;
                                bitValsKnown = true;
                                
                                continue;
                            }
                            
                            isRingZone = true;
                            if (posOfRingBits == streampos(0))
                            {
                                // This is first ring found for this spydef
                                // Save position in case we have to come back for enum
                                posOfRingBits    = tellG();
                                ringBracketLevel = bracketLevel;
                                bitSeq = 0;
                            }
                            rPrefix = ringName + "-#-" + spyName;
                            DLOG(P5MSG) << rPrefix << "_s" << dec << setw(6) << setfill('0') << bitSeq++ << "........Start......." << endl;

                            // Process ring name here
                        
                            // See if there is an existing key for ringName in modMap
                            modMapIter = P_RingModMap.find(ringName);
                            if (modMapIter == P_RingModMap.end())
                            {
                                // Ring name not in map -- Create new entry
                                bitStorePtr = new engdBitStore_t;
                                modMapPair = P_RingModMap.insert(make_pair(ringName, bitStorePtr));
                                if (modMapPair.second == false)
                                {
                                    ILOG(ERMSG) << "E[1011] **Error** Ring " << ringName << " duplicates an existing entry!" << endl;
                                    delete bitStorePtr;
                                    break;  // Skip rest of fragment
                                }
                                
                                modMapIter = modMapPair.first;
                            }
                        }
                        else
                        {
                            ILOG(ERMSG) << "E[1012] **Error** Unable to locate ring name here: " << cv_line << endl;
                            break;  // Skip rest of fragment
                        }
                        continue;
                    }
                    
                    if (cv_line.substr(cpA, 4) == "enum" && ! bitValsKnown)
                    {
                        isEnumZone = true;
                        sdEnumStr  = "";
                        continue;
                    }
                    
                    if (cv_line.substr(cpA, 10) == "epcheckers")
                    {
                        isEpcheckersZone = true;
                        continue;
                    }
                    
                    if (isEnumZone)
                    {
                        if (getDelimitedString(cv_line, cpA, " \t=", " \t=", sdEnumStr, cpB))
                        {
                            // @02c - switch to case-insensitive compare here
                            if (strEqCaseIn(sdEnumStr, spyEnumStr))
                            {
                                // Found matching spy enum & spydef enum here
                                // Grab numeric value of enum now
                                tempStr = cv_line.substr(cpB);
                                // And replace engdSpyData_t dataBuf enum string with acutal hex data
                                spyMapIter->second->bitBasis.setBitLength(0);
                                if (spyMapIter->second->setBuffer(0, ENGD_DC_VALUE, tempStr))
                                {
				    // The following message was causing a seg fault for very log (168 bytes) hex values
                                    //DLOG(P5MSG) << "Enum value string:buffer = " << tempStr << ':' << spyMapIter->second->bitBasis.genAsciiStr() << endl;  // @08D
                                    bitValsKnown = true;
                                    isEnumZone = false;
                                    isRingZone = true;
                                    isEpcheckersZone = false;
                                    bracketLevel = ringBracketLevel;
                                    seekG(posOfRingBits, ios_base::beg);
                                    continue;
                                }
                                else
                                {
                                    ILOG(P5MSG) << "Invalid numeric value for enum: " << tempStr << endl;
                                    break;
                                }
                            }
                            else
                            {
                                continue;
                            }
                        }
                        else
                        {
                            ILOG(ERMSG) << "E[1013] **Error** Parsing spydef enum line: " << cv_line << endl;
                            continue;
                        }
                    }
                    
                    // Ready to connect bit addresses with values now!
                    if (isRingZone && bitValsKnown)
                    {
                        numTokens = parseLineTokens("", 5);
                        
                        if (numTokens == 5)
                        {
                            // At this point:
                            // Token 0 = Number of bits
                            // Token 1 = FSI bit addr
                            // Token 2 = JTAG bit addr
                            // Token 3 = Inversion mask
                            // Token 4 = Latch name (or deadbits)
                        
                            thisBitCount = decStrtoul(getTokStr(0));
                        
                            // Skip any updates if deadbits or excluded ring
                            if (getTokStr(4).substr(0, 7) == "deadbit" || isExcluded)
                            {
                                // @01c - Used to have "-=" for JTAG
                                curBitAddr += thisBitCount;
                                continue;
                            }
                            
			    invMaskChar = getTokStr(3).at(0);	// Get inversion flag  @07a
			    if (invMaskChar == '0')		// Inv mask can be '0', '1' or '!' @07a
			    {
				invMask = 0;			// Get inversion flag  @07c
			    }
			    else				// @07a
			    {
				invMask = 1;			// @07a
			    }
                            int addrDelta = 1;
                            uint32_t stopBitAddr;
                            
                            if (curBitAddr+thisBitCount > spyMapIter->second->bitValid.getBitLength())
                                stopBitAddr = spyMapIter->second->bitValid.getBitLength();
                            else
                                stopBitAddr = curBitAddr+thisBitCount;
                                                  
                            // Get bit address now
                            if (P_FSItype)
                            {
                                // This is FSI, use first address
                                bitAddr = decStrtoul(getTokStr(1));
                            }
                            else
                            {   // This is JTAG, use second address
                                bitAddr = decStrtoul(getTokStr(2));
                                
                                // Now determine if forward or reverse bit-range
                                // Do quick check for range first
                                cpB = getTokStr(4).find_first_of(':');
                                if (cpB != string::npos)
                                {
                                    tempStr = getTokStr(4);
                                    cpA = tempStr.find_first_of('(');
                                    if (cpA == string::npos)
                                    {
                                        // Missing open-paren here?!
                                        ILOG(P5MSG) << "JTAG bit-range check: missing open paren!" << endl;
                                        curBitAddr += thisBitCount;
                                        continue;
                                    }
                                    
                                    // Found bit-range
                                    uint32_t sBit, eBit;
                                    sBit = decStrtoul(tempStr.substr(cpA+1, cpB-cpA-1));
                                    cpA = tempStr.find_first_of(')', cpB);
                                    if (cpA == string::npos)
                                    {
                                        // Missing close-paren here?!
                                        ILOG(P5MSG) << "JTAG bit-range check: missing close paren!" << endl;
                                        curBitAddr += thisBitCount;
                                        continue;
                                    }
                                    eBit = decStrtoul(tempStr.substr(cpB+1, cpA-cpB-1));
                                    if (sBit > eBit)
                                    {
                                        // Found reverse bit-range (eg. 5:0)
                                        DLOG(P5MSG) << "Found reverse bit-range here! " << tempStr << endl;
                                        addrDelta = -1;
                                    }
                                }
                            }  // End if JTAG address
                            
			    if (spyHasGroups && (curBitAddr == stopBitAddr))	// True if adding next group of bits @09a
			    {
				curBitAddr = 0;			// Reset current address for next group	@09a
				stopBitAddr = thisBitCount;	// Reset stop address for next group	@09a
			    }
			    for (uint32_t i = curBitAddr; i<stopBitAddr; ++i, bitAddr += addrDelta)
                            {
                                // Only keep the valid bits
                                if (spyMapIter->second->bitValid.getBit(i))
                                {
				    bitValue = spyMapIter->second->bitBasis.getBit(i);
				    if (invMask)		// Invert if mask indicates that @07a
				    {
					if (bitValue == 0)	// @07a
					{
					    bitValue = 1;	// @07a
					}
					else			// @07a
					{
					    bitValue = 0;	// @07a
					}
				    }
				    modMapIter->second->bitQData.push(engdBitSpec_t(bitAddr, bitValue));
				    DLOG(P5MSG) << "Push addr[value] pair = " << bitAddr << '[' << bitValue << "] onto BitQ" << endl;
                                    DLOG(P5MSG) << rPrefix << "_s" << dec << setw(6) << setfill('0') << bitSeq <<
                                                       '_' << dec << setw(6) << setfill('0') << bitAddr << endl;
                                }
                                bitSeq ++;
                            }
                           
                           curBitAddr += thisBitCount;
			}
                        else
                        {
                            ILOG(ERMSG) << "E[1014] **Error** Unexpected format within ring zone: " << cv_line << endl;
                            continue;
                        }
                    }  // isRingZone && bitValsKnown
                    
                    if (isEpcheckersZone)
                    {
                        cpB = cv_line.find_first_of(" \t", cpA);
                        if (cpB == string::npos)
                        {
                            eplatchSet.insert(cv_line.substr(cpA));
                        }
                        else
                        {
                            eplatchSet.insert(cv_line.substr(cpA, cpB-cpA));
                        }
                    }
                    
                }  // while getTangibleLine
                

                // @02a - For espy, verify that the enum is defined in the spydef
                if (!bitValsKnown && spyMapIter->second->isEnum())
                {
                    ILOG(ERMSG) << "E[1030] **Error** Undefined enum = " << spyEnumStr << " for spy " << spyName << endl;
                    rc = 1;
                }

		// If there may be additions groups defined for this spy wait until next spy is reached to
		//  erase it from the map otherwise delete it here.
		if (!spyHasGroups)			// @09a
		    P_SpyInfoMap.erase(spyName);	
                
            }  // Spy name check
            else
            {
                // Error - Missing spy name after keyword
            }
            
	}  // Foreach fragment
        
	// Check in case last spy had groups and is still in map	@09a
	if (spyHasGroups)		// Previous spy had groups	@09a
	{
	    DLOG(P5MSG) << "Deleting spy from map = " << spyName << endl; // @09a
	    P_SpyInfoMap.erase(savedSpyName);  // Remove it now		@09a
	    spyHasGroups = false;	// Reset groups flag		@09a
	}
       
        // Check for spys which were initially processed as statics, but were
        // found in an exclude ring -- so they need to be saved back to RIF.
        if (vetoSpys.size())
        {
            // ifstream fullInitFile;  // Full initfile
            // EngdInitFile fullInitFile(cv_initFn);
            ofstream reducedIF;     // Reduced initfile
            string   spyLine;
            
            // First open the full initfile for read... again
            // if (openFn(cv_initFn, fullInitFile))
            // if (fullInitFile.fileOpenSuccess())
            P_InitFile.streamRef().open(P_InitFile.getFn().c_str());
            if (P_InitFile.streamRef().is_open())
            {
                ILOG(P3MSG) << "Successfully opened file again for read:" << P_InitFile.getFn() << '!' << endl;
            }
            else
            {
                ILOG(ERMSG) << "E[1028] **Error** Unable to open file again for read: " << P_InitFile.getFn() << endl;
                rc = 2;
            }

            // And open the reduced initfile again, but this time for APPEND
            reducedIF.open(P_ReducedFn.c_str(), ios::app);
            if (reducedIF.good())
            { 
                ILOG(P3MSG) << "Successfully opened file for apend: " << P_ReducedFn << '!' << endl;
            }
            else
            {
                ILOG(ERMSG) << "E[1029] **Error** Unable to open file for append: " << P_ReducedFn << endl;
                rc = 3;
            }
            
            // Now, seek to the saved file positions in the full initfile and
            // write those spys to the reduced initfile.
            if (rc == 0)
            {
                streampos ifsPos;
                
                reducedIF << "# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" << endl;
                reducedIF << "# Start Static Ring Init exclusions section" << endl;
                reducedIF << "# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" << endl;
                reducedIF << endl;
                for (vetoSpyIter = vetoSpys.begin(); vetoSpyIter != vetoSpys.end(); vetoSpyIter++)
                {
                    ifsPos = *vetoSpyIter;
                    
                    // Check if spy has already been saved to the RIF.  Besides
                    // the multi-spy case, this can happen for a spy that
                    // contains multiple rings.
                    if (vetoDoneSet.find(ifsPos) != vetoDoneSet.end())
                    {
                        continue;
                    }
            
                    // Decrement count of static spys removed from full initfile
                    P_SpyNumStatic--;
                    
                    // Spy has not been previously processed.  Mark it done now.
                    vetoDoneSet.insert(ifsPos);
                    
                    // Seek to position of spy in initfile
                    P_InitFile.seekG(ifsPos, ios_base::beg);
                    
                    // And copy appropriate lines from initfile to reduced IF
                    reducedIF << "# Static Ring Init: Excluded ring exception" << endl;
                    P_InitFile.getLINE(spyLine);
                    while (!P_InitFile.isEOF())
                    {
                        reducedIF << spyLine << endl;
                        
                        cpA = spyLine.find_first_not_of(" \t", 0);
                        
                        if (cpA != string::npos && spyLine[cpA] == '}')
                            break;
                         
                        P_InitFile.getLINE(spyLine);
                    }
                    reducedIF << endl;  // Put a little space between spys
                }
            }
            
            if (rc != 2)
                P_InitFile.streamRef().close();
            if (rc != 3)
                reducedIF.close();
        }
        
    } while (0);
    
    if (P_SpyInfoMap.size())
    { 
        ILOG(ERMSG) << "E[1015] **Error** processSpydef, " << P_SpyInfoMap.size() << " spys REMAIN IN MAP!" << endl;
        
        for (spyMapIter = P_SpyInfoMap.begin(); spyMapIter != P_SpyInfoMap.end(); spyMapIter++)
        {
            ILOG(ERMSG) << "E[1016] " << spyMapIter->first << ", bitLen = " << dec << spyMapIter->second->bitBasis.getBitLength() <<
                    ", data = 0x" << spyMapIter->second->bitBasis.genHexLeftStr() << endl;
        }
    }
    else
    { 
        DLOG(P3MSG) << "Exiting processSpydef, MAP is clear!" << endl;
    }
   
#if 0   
    // DEBUG ##############
    set<string>::iterator setIter;
    DLOG(P5MSG) << "Dump of full eplSet here:" << endl;
    for (setIter  = eplatchSet.begin();
         setIter != eplatchSet.end();
         setIter++)
     {
        DLOG(P5MSG) << "* eplSet element = " << *setIter << endl;
     }
 
    // ******** TEST below **
    modMapIter = P_RingModMap.find("ex_mode");
    engdBitSpec_t myBitSpec;
    if (modMapIter == P_RingModMap.end())
    {
        DLOG(P6MSG) << " +DBG: Cannot find ex_mode ring!" << endl;
    }
    else
    {
        priorityBitQPtr = modMapIter->second;
        while (! priorityBitQPtr->empty())
        {
            // myBitSpec = priorityBitQPtr->pop();
            DLOG(P6MSG) << "@R@::>> " << priorityBitQPtr->top().getAddress() << '[' << priorityBitQPtr->top().getValue() << ']' << endl;
            priorityBitQPtr->pop();
        }
    }
    // ******** TEST above **
#endif
        
    ILOG(INMSG) << "Count of static spys removed from initfile = " << setw(5) << dec << P_SpyNumStatic << endl;
    ILOG(INMSG) << "- Count of original spys which remain      = " << setw(5) << dec << P_SpyNumTotal - P_SpyNumStatic << endl;
    ILOG(INMSG) << "- Count of rings to modify for this chip   = " << setw(5) << dec << P_RingModMap.size() << endl;

    if (P_RingListFn != "") {			// Store affected ring list requested	   @0Aa
	ofstream ringList;		// Ring list file			   @0Aa
        // Open the file to contain the ring list
	ringList.open(P_RingListFn.c_str(), ios::app);				// @0Aa	
	if (ringList.good())							// @0Aa
	{ 
	    ILOG(P3MSG) << "Successfully opened ring list file: " << P_RingListFn << '!' << endl; // @0Aa
	}
	else									// @0Aa
	{
	    ILOG(ERMSG) << "E[1029] **Error** Unable to open ring list file: " << P_RingListFn << endl; // @0Aa
	    rc = 3;								// @0Aa
	}

        // Write all affected ring names to the ring list file.  Duplicates will be handled in the
	// makefile or elsewhere.
	if (rc == 0)								// @0Aa
	{
	    for (modMapIter = P_RingModMap.begin(); modMapIter !=   P_RingModMap.end(); modMapIter++) { // @0Aa
		ringList << P_ChipStr << "." << P_ArgvEcStr << "." << P_IplModeStr << "." << modMapIter -> first << ".bin.srd" << endl;					   // @0Aa
	    }
	    if (rc != 3)							// @0Aa
		ringList.close();						// @0Aa
	}
    }
    
    return;
}
