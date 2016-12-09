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
//  @02   D750007   wfenlon   04/20/10  remove uppercase conversion on spynames
//  @03   F750357   wfenlon   05/18/10  Fix error msg for duplicate spys
//  dg00 SW045016   dgilbert  11/19/10  Remove EC dependent spies from static rings
//  @04   F858677   dpeterso  10/18/12  Include IPLMODE dependent spies from static rings
//  @06   F866181   dpeterso  01/03/13  Support for 'env' as static init
//  @07   F866846   dpeterso  01/16/13  Support for PU_CHIP_TYPE as static init
//  @08   F868940   dpeterso  01/29/13  Support to deal with avpTestCase & fix multi-condition static bugs
//  @09   F870527   dpeterso  02/19/13  Handle multiple value lines for espys because of env support
//  @0A   F871961   dpeterso  02/25/13  Handle espy with expr & add initial risklevel support
//  @0B   F874515   dpeterso  03/14/13  Getting out_of_range error accessing define map
//  @0C   F875066   dpeterso  03/15/13  Updates for Venice
//  @0D   F875892   dpeterso  03/27/13  Handle ec expressions on value lines
//  @0E   F880884   dpeterso  05/01/13  Only allow 1 value line for ispys and skip lines conditioned on avpTestCase
//  @0F   D893871   dpeterso  07/25/13  Add support for logical or on when clause like
//                 [when=L && ((PU_CHIP_TYPE == VENICE) || ((PU_CHIP_TYPE == MURANO) && (ec >= 0x20)))]
//  @10   D901675   dpeterso  10/09/13  Increase max # of tokens from 8 -> 20
//  @11   D901679   dpeterso  10/10/13  Add space following 'or' if not present to keep processing straight
//  @12   D905257   dpeterso  11/01/13  Using '=' instead of '==' in ec clause parsing and fix or processing
//                 where adding extra space was causing failure to include spys.
//  @13   D925989   maploetz  05/15/14  Added resetTok flag for when tokens on the right side of OR are deleted
//                 and the tokens on the left side of the OR need to be checked.
//  @14   D931849   jprispol  07/11/14  Added support for Naples
//  @15   D935538   jknight   08/15/14  fix ifScrubber handling of runtime IPL
//                                      ipl mode
//  @16   D956492   maploetz  04/20/15  Fixed logic for additon of Naples.                                
// End Change Log *****************************************************

#include <ifScrubDataSpec.H>
#include <time.h>


bool EngdInitFile::locateFragment()
{
    size_t cpA = string::npos;  // Character position
    uint32_t numLines;
    streampos startOfThisLine;
        
    while (getTangibleLine(cpA, &numLines, &startOfThisLine))
    {
        if (numLines > 1)
            cv_outputPending = true;
        // "ispy/espy" are the strings that really matter here.  "array"
        // is also matched, but will be discarded later.
        if (cv_line.substr(cpA, 4) == "ispy" || cv_line.substr(cpA, 4) == "espy" ||
            cv_line.substr(cpA, 5) == "array" || cv_line.substr(cpA, 6) == "define" || cv_line.substr(cpA, 12) == "END_INITFILE")
        {
            // DLOG(P3MSG) << "wfdbg: Successful fragment match! cpA = " << cpA << endl;
            cv_filePosB = startOfThisLine;
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
 * Evaluates the condition string of a spy based on the specified EC value.
 * The condition string consists of either either one, two or three terms where the
 * first term is a "when=" phrase and the second and third are an EC conditional and/or an IPLMODE conditional.
 *
 * @param const string & i_conditionStr - Condition string
 *
 * @return bool - Return evaluation of condition string, true or false
 * @04 added iplmode
 * @07 added chiptype
 * @0A added risklevel
 * @0C upate chiptype
*/
bool EngdInitFile::matchConditionAndEc(const string & i_conditionStr, const uint32_t i_ecValue, const string & i_iplmodeStr, bool* isFatalErr)
{
    *isFatalErr = false;
    string i_chiptypeStr = ""; // @07a @0Cc
    if (P_ChipStr == "s1")	 // @0Ca
    {
        i_chiptypeStr = "MURANO"; // @0Ca
    }
    else if (P_ChipStr == "p8")	  // @0Ca
    {
        i_chiptypeStr = "VENICE"; // @0Ca
    }
    else if (P_ChipStr == "n1")
    {
        i_chiptypeStr = "NAPLES";
    }
    // Temp until we add full support for risklevel
    const uint32_t & i_risklevel = 0;	// @0Aa
    bool isStatic = true;
    bool onlyOneCondition;
    uint32_t numTokens =0;  // @0Fc
    size_t cpA, cpB; //@07c
    string tempStr;
    // uint32_t leftValue, rightValue;  //dg00d
    uint32_t leftValue, rightValue;  //dg00d  @04a
    string leftValueStr, rightValueStr;  //dg00d  @04a
    char c;
    uint8_t numExtraConditions = 0;  //@a04
   
    do
    {
        // Put condition string in cv_line for use by parseLineTokens
        cv_line = i_conditionStr;
        
        // First, check for logical &&
        cpA = cv_line.find_first_of('&');
        if (cpA == string::npos)
        {   // This must be simple "when=" condition
            onlyOneCondition = true;
            numTokens = parseLineTokens("=", 2);
        }
        else
	{   // Deleted the following check as we now can have more than one extra clause on statics @07d
	    // This is more complex condition, joined with &&
	    // cpB = cv_line.find_last_of('&') - 1;
	    // if (cpA != cpB)
	    // {
		// isStatic = false;
		// DLOG(P5MSG) << "ToRIF: Too many &&" << endl;
		// break;
	    // }

	    // Deleted the following section for p8 where more than 2 clauses can be used to define statics @07d
	    // Allow ONE set of parens if it surrounds entire right-hand cond.
	    // Start by locating first non whitespace character after &&
	    // cpA = cv_line.find_first_not_of(" \t", cpB+2);
	    // if (cpA != string::npos && cv_line[cpA] == '(')
	    // {   // Found open paren ok, now check position of close paren

	       // cpB = cv_line.find_last_of(')');
	       // cpC = cv_line.find_last_not_of(" \t");
	       // if (cpB == cpC)
	       // {
		    // With position verified now, remove parens from string
	       //     cv_line.erase(cpB, 1);
	       //     cv_line.erase(cpA, 1);
	       // }
	       // else
	       // {
	       //     isStatic = false;
	       //     DLOG(P5MSG) << "ToRIF: Unsupported use of parens" << endl;
	       //     break;
	       // }
	    // }

	    // Added section for handling logical OR							@0Fa
	    // Since remaining code really doesn't support OR logic the approach used is to delete	@0Fa
	    // clauses that don't apply (i.e. are always false based on current parameters) and         @0Fa
            // delete the '||' so that a simple test or 'anded' test remains.	                        @0Fa
	    // If this can't be done then we fail rather than silently continue and possibly generate	@0Fa
	    // bad rings.										@0Fa

            size_t nextOr = cv_line.find_first_of("|");	//						@0Fa
	    if (nextOr != string::npos)			// line contains logical OR			@0Fa
            {
                bool orProcessFailed = false;		//						@0Fa
                bool clauseIsFalse, resetTok = false;		//						@0Fa
                bool checkingLeftOfOr = true;		//						@0Fa
                uint8_t startTokToConsider = 2;		// skip when clause				@0Fa
                uint8_t endTokToConsider = 2;		//						@0Fa
                if (numTokens >= 4 && getTokDel(1) == '|') // Only 1 other clause beside when and use of 'or'
		{
                    isStatic = false;			// When clause required. OR makes it conditional. @0Fa
                    DLOG(P5MSG) << "ToRIF: Or paired with \"when\" is non-static" << endl;	//	@0Fa
                    break;									//	@0Fa
                }
                while (nextOr != string::npos && !orProcessFailed) // while contains OR and we can handle it @0Fa
                {
                    DLOG(P5MSG) << "Processing line = " << cv_line << endl; //				@0Fa
                    //numTokens = parseLineTokens("=&<>!|", 8);	// Get tokens				@0Fa
                    numTokens = parseLineTokens("=&<>!|", 20);	// Get tokens (incr to support complex cond@10a
                    DLOG(P5MSG) << "numTokens = " << numTokens << dec << endl; //				@0Fa
                    uint8_t i = 0;						//	@0Fa
                    uint8_t openParens, closeParens, startNestingLevel = 0;
                    size_t firstOpenParenOffset, lastCloseParenOffset, nextParenOffset, tempOffset = 0; // @0Fa
                    if (checkingLeftOfOr)			// Checking left side of OR		@0Fa
                    {
                        lastCloseParenOffset = cv_line.find_last_of(")",nextOr); // Find scope of OR	@0Fa
                        for (i = 0; cv_line.at(lastCloseParenOffset-i) ==  ')'; ++i)	//	@0Fa
                            { }
                        closeParens = i;							//	@0Fa
                        tempOffset = lastCloseParenOffset-closeParens;				//	@0Fa
                        for (i = 0; i < closeParens; )						//	@0Fa
                        {
                            nextParenOffset = cv_line.find_last_of("()",tempOffset);		//	@0Fa
                            if (cv_line.at(nextParenOffset) == ')')				//	@0Fa
                            {
                                --i;								//	@0Fa
                            } else if (cv_line.at(nextParenOffset) == '(')
                            {
                                ++i;								//	@0Fa
                            }
                            else
			    {
                            	DLOG(P5MSG) << "Error, we should see a ( or ) "<< endl;
		            }
                            tempOffset = nextParenOffset-1;					//	@0Fa
                        }
                        firstOpenParenOffset = nextParenOffset;					//	@0Fa
                        DLOG(P5MSG) << "lastCloseParenOffset = " << lastCloseParenOffset << dec << endl; // @0Fa
                        DLOG(P5MSG) << "firstOpenParenOffset = " << firstOpenParenOffset << dec << endl; // @0Fa
                        // Determine additional parens to insert later when token is deleted
                        startNestingLevel = 0;							//	@0Fa
                        for (i = 1; cv_line.at(firstOpenParenOffset-i) == '('; ++i)		//	@0Fa
                        { }
                        startNestingLevel +=(i-1);						//	@0Fa
                        DLOG(P5MSG) << "nesting level = " << (int)startNestingLevel << dec << endl; // @0Fa
		    } else									//	@0Fa
                    {
                        firstOpenParenOffset = cv_line.find_first_of("(",nextOr);		//	@0Fa
                        for (i = 0; cv_line.at(firstOpenParenOffset+i) ==  '('; ++i)	//	@0Fa
                            { }
                        openParens = i;							//	@0Fa
                        DLOG(P5MSG) << "openParens on right side = " << (int)openParens << dec << endl; //	@0Fa
                        DLOG(P5MSG) << "firstOpenParenOffset = " << firstOpenParenOffset << dec << endl; //	@0Fa
                        tempOffset = firstOpenParenOffset+openParens;				//	@0Fa
                        for (i = 0; i < openParens; )						//	@0Fa
                        {
                            nextParenOffset = cv_line.find_first_of("()",tempOffset);		//	@0Fa
                            if (cv_line.at(nextParenOffset) == '(')				//	@0Fa
                            {
                                --i;								//	@0Fa
                            } else								//	@0Fa
                            {
                                ++i;								//	@0Fa
                            }
                            tempOffset = nextParenOffset+1;					//	@0Fa
                        }
                        lastCloseParenOffset = nextParenOffset;					//	@0Fa
                        // Determine additional parens to insert later when token is deleted
                        startNestingLevel =0;							//	@0Fa
                        i=1;									//	@0Fa
                        while ((lastCloseParenOffset+i < cv_line.length()) && (cv_line.at(lastCloseParenOffset+i) == ')')) //	@0Fa
                        {
                            ++i;								//	@0Fa
                        }
                        startNestingLevel +=i-1;						//	@0Fa
                        DLOG(P5MSG) << "nesting level = " << (int)startNestingLevel << dec << endl; // @0Fa
                    }
                    i = startTokToConsider;
                    while (getTokPos(i)+getTokStr(i).length() < firstOpenParenOffset)		//	@0Fa
                    {
                        ++i;									//	@0Fa
                    }
                    startTokToConsider = i;							//	@0Fa
                    i = startTokToConsider+1;
                    while (getTokPos(i)+getTokStr(i).length() < lastCloseParenOffset)		//	@0Fa
                    {
                        ++i;									//	@0Fa
                    }
                    endTokToConsider = i;							//	@0Fa
                    for ( i = startTokToConsider; i < endTokToConsider; i+=2)			//	@0Fa
                    {
                        DLOG(P5MSG) << "Tokens remaining = " << (int)numTokens << ".  Checking to see if token " << getTokStr(i) << getTokDel(i) << getTokStr(i+1) << " can be removed." << endl; // @0Fa
                        if (clauseIsFalse)
                        {
                           DLOG(P5MSG) << "Clauses is false flag set!!" << endl; // @0Fa
                        }

                        tempStr = getTokStr(i+1);						//	@0Fa
                        while (tempStr.substr(tempStr.length()-1,1) == ")")			//	@0Fa
                        {
                            tempStr.erase(tempStr.length()-1,1);				//	@0Fa
                        }
			
                        if (((getTokStr(i).find("PU_CHIP_TYPE") != string::npos) && (getTokDel(i) == '=') && !(tempStr == i_chiptypeStr)) ||
                            ((getTokStr(i).find("PU_CHIP_TYPE") != string::npos) && (getTokDel(i) == '!') && !(tempStr != i_chiptypeStr)) ||
                            ((getTokStr(i).find("IPLMODE") != string::npos)      && (getTokDel(i) == '=') && !(tempStr == i_iplmodeStr)) ||
                            ((getTokStr(i).find("IPLMODE") != string::npos)      && (getTokDel(i) == '!') && !(tempStr != i_iplmodeStr)) ||
                            ((getTokStr(i).find("RISK_LEVEL") != string::npos)   && (getTokDel(i) == '=') && !(tempStr == "0x0")) ||
                            ((getTokStr(i).find("RISK_LEVEL") != string::npos)   && (getTokDel(i) == '!') && !(tempStr != "0x0")) ||
                            ((getTokStr(i).find("avpTestCase") != string::npos)  && (getTokDel(i) == '=') && !(tempStr == "NONE")) ||  
                            ((getTokStr(i).find("avpTestCase") != string::npos)  && (getTokDel(i) == '!') && !(tempStr != "NONE")) //	@0Fa
                             )  // If tokens match 
                        {
                            clauseIsFalse = true;						//	@0Fa
                        } else if (getTokStr(i).find("ec"))					//	@0Fa
                        {
                            tempStr = getTokStr(i+1);						//	@0Fa
                            c = toupper(tempStr[1]);						//	@0Fa
                            if (tempStr[0] == '0' && c == 'X')					//	@0Fa
                            {
				string tempStr2 = cv_line.substr(getTokPos(i), (getTokPos(endTokToConsider)-getTokPos(i))); // @12a
                                rightValue = hexStrtoul(tempStr.substr(2));			//	@0Fa
                                if ((tempStr2.find("(ec > ") != string::npos && !(i_ecValue >  rightValue ))  || 
                                    (tempStr2.find("(ec >=") != string::npos && !(i_ecValue >= rightValue ))  || 
                                    (tempStr2.find("(ec < ") != string::npos && !(i_ecValue <  rightValue ))  ||
                                    (tempStr2.find("(ec <=") != string::npos && !(i_ecValue <= rightValue ))  ||
                                    (tempStr2.find("(ec !=") != string::npos && !(i_ecValue != rightValue ))  ||
                                    (tempStr2.find("(ec ==") != string::npos && !(i_ecValue == rightValue ))  ) // @0Fa @12c
                                {
                                    clauseIsFalse = true;					//	@0Fa
                                }
                            }
                        } else									//	@0Fa
                        {
                            clauseIsFalse = false;						//	@0Fa
                        }
                    }
                    if (clauseIsFalse)			// We can eliminate these tokens		@0Fa
                    {
                        DLOG(P5MSG) << "Line before changes = " << cv_line << endl; //			@0Fa
                        // Carry forward any opening or closing parens that aren't closed/opened in what we're deleting
                        if (checkingLeftOfOr)							//	@0Fa
                        {
                            for ( i = 0; i < startNestingLevel; ++i)				//	@0Fa
                            {
                                cv_line.insert(getTokPos(endTokToConsider+1),"(");		//	@0Fa
                            }
                        } else									//	@0Fa
                        {
			    for ( i = 0; i < startNestingLevel; ++i)				//	@0Fa
                            {
                                cv_line.insert((getTokPos(startTokToConsider-1) + getTokStr(startTokToConsider-1).length()),")");         //	@0Fa
                            }
                                checkingLeftOfOr = true;
				resetTok = true;
		        }
			numTokens = parseLineTokens("=&<>!|", 20);	// Reparse line after inserting chars@12a
                        // Delete tokens that we've just considered
                        uint8_t tokLen = getTokPos(endTokToConsider) + getTokStr(endTokToConsider).length() - getTokPos(startTokToConsider); //	@0Fa
                        DLOG(P5MSG) << "About to delete " << (int)tokLen << " characters starting at position " << getTokPos(startTokToConsider) << endl;		//			 @12a
			cv_line.erase(getTokPos(startTokToConsider), tokLen); //			@0Fa
                        DLOG(P5MSG) << "After deleting string = " << cv_line << endl; //		@12a
                        cv_line.erase(cv_line.find("||"),2);
                        DLOG(P5MSG) << "Line after changes = " << cv_line << endl; //			@0Fa
			clauseIsFalse = false;						//	@dap
                        // if we can check that after the first &&, there is another && before the ||, reset tokens?
                        size_t nextOr = cv_line.find_first_of("|");
                        size_t firstAnd = cv_line.find_first_of("&");
                        size_t nextAnd = cv_line.find("&",firstAnd+2);
                        bool foundAnd = false;
                        if (nextAnd == string::npos)
			{
			    DLOG(P5MSG) << "No more AND's found after the first one" << endl;
			}
                        if ((nextAnd != string::npos) && (nextOr != string::npos) && (nextAnd < nextOr))
                        { //We found AND logic before the next OR logic, set foundAnd to true
                            DLOG(P5MSG) << "Found AND logic before OR at = " << nextAnd << dec << endl;
                            foundAnd = true;
                        }
                        if (foundAnd)
                        { // We have found an AND logic before the next OR logic, need to reset tokens
                            DLOG(P5MSG) << "foundAnd is true, resetting tokens" << endl;
                            resetTok = true;
                        }
                        if (resetTok)
			{
		            DLOG(P5MSG) << "Resetting tokens to start considering logic from beginning of string" << endl;
			    startTokToConsider = 2;
			    resetTok = false;
			}
                   } else if (checkingLeftOfOr)	// Check right of 'or' next			@0Fa
                    {
                        checkingLeftOfOr = false;						//	@0Fa
                        startTokToConsider = endTokToConsider+1; // Move to nextSet of tokens		@0Fa
                        DLOG(P5MSG) << "Switching to right side" << endl; //				@0Fa
                    } else
                    {
                        orProcessFailed = true;		// Can't remove logical 'or' fail compile	@0Fa
                        ILOG(ERMSG) << "E[1005] **Error** '||' processing failed for line = " << cv_line << endl; // @0Fa
                        break;									//	@0Fa
                    }

                    nextOr = cv_line.find_first_of("|");	// Get next OR				@0Fa
                    DLOG(P5MSG) << "Getting next or location.  Offset = " << (int)nextOr << dec <<endl; // @0Fa
		    // Check for space following 'or' processing gets messed up if one isn't there      @11a
                    if (nextOr == string::npos)							//	@0Fa @12c
		    {
                        DLOG(P5MSG) << "No '|' chars left " <<endl; // @0Fa
                    } else if (cv_line.at(nextOr+2) != ' ')	// Check for space following '||'       @11a @12c
		    {
                       cv_line.insert((nextOr+2)," ");		// Insert space	if not found		@11a
                       DLOG(P5MSG) << "Inserting space at offset = " << (int)nextOr+2 <<endl;	     // @11a
		    }

		}

            }

	    // End of OR processing
	    // Rewritten section to check for correct parens and remove them 
	    // Start by locating first paren after &&
	    cpA = cv_line.find_first_of("(");		// @07a
	    cpB = 0;					// @0Fa
	    size_t nextParen = 0;				// @0Fa

	    while (cpA != string::npos)			// @07a
	    {   // Found open paren ok, now check position of close paren
		nextParen = cv_line.find_first_of("()", cpA+1); // @0Fa
		while ((nextParen != string::npos) && (cpB < cpA)) // @0Fa
		{					//
		    if (cv_line.at(nextParen) == '(')	// @0Fa
			cpA = nextParen;		// @0Fa
		    else				// @0Fa
		    {					//
			cpB = nextParen;		// @0Fa
			break;				// @0Fa
		    }					//
		    nextParen = cv_line.find_first_of("()", cpA+1); // @0Fa
		    DLOG(P5MSG) << "cpA = " << (int)cpA << dec << "  cpB = " << (int)cpB << dec <<endl; // @0Fa
		}					//
		if (nextParen != string::npos)		// @0Fc
		{
		    // With position verified now, remove parens from string
		    cv_line.erase(cpB, 1);		// @07a
		    cv_line.erase(cpA, 1);		// @07a
		    cpB = 0;				// @0Fa
		}
		else					// @07a
		{
		    isStatic = false;			// @07a
                    *isFatalErr = true;
		    DLOG(P5MSG) << "ToRIF: Unsupported use of parens" << endl; // @07a
		    break;
		}
		// Check for more parens
		cpA = cv_line.find_first_of("(");	// @07a
	    }

	    onlyOneCondition = false;
	    numTokens = parseLineTokens("=&<>!", 8);	// @07a
	}
        
        // At this point with, for example, condition = "when=L && ec >= 0x10"
        // Tok#   Token   Delimeter
        // -----+-------+----------
        // 0      when    =
        // 1      L       &
        // 2      ec      >
        // 3      0x10    &
        // 4      IPLMODE =
        // 5      HBI     &
        // 6      PU_CHIP_TYPE =
        // 7      MURANO  NA
        // 8      avpTestCase =
        // 9      none  NA
        
        if (numTokens > 1 && getTokStr(0) == "when" && getTokDel(0) == '=')
        {
            c = getTokStr(1).at(0);
            if (c != 'L' && c != 'C')
            {
                isStatic = false; *isFatalErr = true;
                ILOG(ERMSG) << "ToRIF: Unsupported \"when\" type: " << c << endl;

                break;
            }
        }
        else
        {
                isStatic = false; *isFatalErr = true;
                ILOG(ERMSG) << "ToRIF: Problems with \"when\" condition" << endl;
                break;
        }
        
        // Know that "when=" part is ok here, so figure out any other conditions
        if (onlyOneCondition)
            break;  // This conditional contains only "when=" part
        
        // @04 Adding back conditional logic that had been removed below and conditioned on #if defined
        //dg00c  - Keep all EC conditional spies in the filtered initfile.
        //isStatic = false;
        //DLOG(P5MSG) << "ToRIF: Multiple \"when\" conditions unsupported" << endl;
        //break;

// @04 Adding back
//#if defined(__REMOVED__)     //dg00d

	// Could be 1 to 4 extra conditions (i.e. ec, PU_CHIP_TYPE and/or iplmode and/or avpTestCase and/or RISK_LEVEL)
        if (numTokens == 4 && getTokDel(1) == '&')
        {
                numExtraConditions = 1;
	}
	else if (numTokens == 6 && getTokDel(1) == '&' && getTokDel(3) == '&')  // @07c
        {
	       DLOG(P5MSG) << "Found 2 extra init condidtions." << endl;	// @07a
	       numExtraConditions = 2;
	}
	else if (numTokens == 8 && getTokDel(1) == '&' && getTokDel(3) == '&' && getTokDel(5) == '&') //@07a
        {
	       DLOG(P5MSG) << "Found 3 extra init condidtions." << endl;	// @07a
               numExtraConditions = 3;						// @07a
	}
	else if (numTokens == 10 && getTokDel(1) == '&' && getTokDel(3) == '&' && getTokDel(5) == '&' && getTokDel(7) == '&') //@08a @0Ac
        {
	       DLOG(P5MSG) << "Found 4 extra init condidtions." << endl;	// @08a
               numExtraConditions = 4;						// @08a
	}
	else if (numTokens == 12 && getTokDel(1) == '&' && getTokDel(3) == '&' && getTokDel(5) == '&' && getTokDel(7) == '&' && getTokDel(9) == '&') //@0Aa
        {
	       DLOG(P5MSG) << "Found 5 extra init condidtions." << endl;	// @0Aa
               numExtraConditions = 5;						// @0Aa
	}
        else
	{
                isStatic = false; *isFatalErr = true;
                ILOG(ERMSG) << "ToRIF: Invalid condition, related to &&" << endl;
                break;
        }
        
	// Handle 1 to n extra conditions (i.e. ec, PU_CHIP_TYPE, iplmode, avpTestCase, RISK_LEVEL, etc)
	for (uint8_t i = 1; i <= numExtraConditions && isStatic == true; ++i)			// @07c @08c
 	{
	    DLOG(P5MSG) << "Left token: " << getTokStr(2*i) <<  "  Right token: " << getTokStr(2*i+1) << endl; // @07a
	    // If next condition is 'ec'
	    if ((getTokStr(2*i) == "ec") || (getTokStr(2*i+1) == "ec"))		// @07c
	    {
	    // Process left operand
		tempStr = getTokStr(2*i);			// @07c
		c = toupper(tempStr[1]);
		if (tempStr == "ec")
		    leftValue = i_ecValue;
		else if (tempStr[0] == '0' && c == 'X')
		    leftValue = hexStrtoul(tempStr.substr(2));
		else if (tempStr[0] == '0' && c == 'B')
		    leftValue = binStrtoul(tempStr.substr(2));
		else
		{
		    isStatic = false; *isFatalErr = true;
		    ILOG(ERMSG) << "ToRIF: Unsupported L-operand: " << tempStr << endl;
		    break;
		}

	    // Process right operand
		tempStr = getTokStr(2*i+1);			// @07c
		c = toupper(tempStr[1]);
		if (tempStr == "ec")
		    rightValue = i_ecValue;
		else if (tempStr[0] == '0' && c == 'X')
		    rightValue = hexStrtoul(tempStr.substr(2));
		else if (tempStr[0] == '0' && c == 'B')
		    rightValue = binStrtoul(tempStr.substr(2));
		else
		{
		    isStatic = false; *isFatalErr = true;
		    ILOG(ERMSG) << "ToRIF: Unsupported R-operand: " << tempStr << endl;
		    break;
		}

	    // Process the operator
	    // Starting at left operand, find position of first operand char
		cpA = cv_line.find_first_of("<=>!", getTokPos(2*i)); // @07c
		c = cv_line[cpA+1];

	    // Now have everything needed to evaluate the condition stmt
	    // cpA points to first char of operator and c is second char
		switch (cv_line[cpA])
		{
		    case '<':
			if (c == '=')
			    isStatic = (leftValue <= rightValue);
			else
			    isStatic = (leftValue < rightValue);
			break;
		    case '>':
			if (c == '=')
			    isStatic = (leftValue >= rightValue);
			else
			    isStatic = (leftValue > rightValue);
			break;
		    case '=':
			if (c == '=')
			    isStatic = (leftValue == rightValue);
			else
			    isStatic = false;  // Illegal operator
			break;
		    case '!':
			if (c == '=')
			    isStatic = (leftValue != rightValue);
			else
			    isStatic = false;  // Illegal operator
			break;
		}
	    }
	    else if ((getTokStr(2*i) == "IPLMODE") || (getTokStr(2*i+1) == "IPLMODE")) // @07c
	    {
		// Process left operand
		tempStr = getTokStr(2*i);			// @07c
		if (tempStr == "IPLMODE")
		{
		    leftValueStr = i_iplmodeStr;
		}
		else if (tempStr == "HBI" || tempStr == "RUNTIME")
		{
		    leftValueStr = tempStr;
		}
		else
		{
		    isStatic = false; *isFatalErr = true;
		    ILOG(ERMSG) << "ToRIF: Unsupported L-operand: " << tempStr << endl;
		    break;
		}
		// Process right operand
		tempStr = getTokStr(2*i+1);			// @07c
		if (tempStr == "IPLMODE")
		{
		    rightValueStr = i_iplmodeStr;
		}
		else if (tempStr == "HBI" || tempStr == "RUNTIME")
		{
		    rightValueStr = tempStr;
		}
		else
		{
		    isStatic = false; *isFatalErr = true;
		    ILOG(ERMSG) << "ToRIF: Unsupported R-operand: " << tempStr << endl;
		    break;
		}
	    // Process the operator
	    // Starting at left operand, find position of first operand char
		cpA = cv_line.find_first_of("=!", getTokPos(2*i)); // @07c
		c = cv_line[cpA+1];

	    // Now have everything needed to evaluate the condition stmt
	    // cpA points to first char of operator and c is second char
		switch (cv_line[cpA])
		{
		    case '=':
			if (c == '=')
			    isStatic = (leftValueStr == rightValueStr);
			else
			    isStatic = false;  // Illegal operator
			break;
		    case '!':
			if (c == '=')
			    isStatic = (leftValueStr != rightValueStr);
			else
			    isStatic = false;  // Illegal operator
			break;
		}
	    }
	    else if ((getTokStr(2*i) == "PU_CHIP_TYPE") || (getTokStr(2*i+1) == "PU_CHIP_TYPE")) // @07a
	    {
		// Process left operand
		tempStr = getTokStr(2*i);				// @07a
		if (tempStr == "PU_CHIP_TYPE")			// @07a
		{
		    leftValueStr = i_chiptypeStr;		// @07a
		}
		else if (tempStr == "MURANO" || tempStr == "VENICE" || tempStr == "NAPLES") // @07a
		{
		    leftValueStr = tempStr;			// @07a
		}
		else						// @07a
		{
		    isStatic = false;				// @07a
		    *isFatalErr = true;
            ILOG(ERMSG) << "ToRIF: Unsupported L-operand: " << tempStr << endl;	// @07a
		    break;					// @07a
		}
		// Process right operand
		tempStr = getTokStr(2*i+1);			// @07a
		if (tempStr == "PU_CHIP_TYPE")			// @07a
		{
		    rightValueStr = i_chiptypeStr;		// @07a
		}
		else if (tempStr == "MURANO" || tempStr == "VENICE" || tempStr == "NAPLES") // @07a
		{
		    rightValueStr = tempStr;			// @07a
		}
		else						// @07a
		{
		    isStatic = false;				// @07a
		    *isFatalErr = true;
            ILOG(ERMSG) << "ToRIF: Unsupported R-operand: " << tempStr << endl; // @07a
		    break;					// @07a
		}
	    // Process the operator
	    // Starting at left operand, find position of first operand char
		cpA = cv_line.find_first_of("=!", getTokPos(2*i)); // @07a
		c = cv_line[cpA+1];				// @07a

	    // Now have everything needed to evaluate the condition stmt
	    // cpA points to first char of operator and c is second char
		switch (cv_line[cpA])				// @07a
		{
		    case '=':					// @07a
			if (c == '=')				// @07a
			    isStatic = (leftValueStr == rightValueStr);	// @07a
			else					// @07a
			    isStatic = false;  // Illegal operator @07a
			break;					// @07a
		    case '!':					// @07a
			if (c == '=')					// @07a
			    isStatic = (leftValueStr != rightValueStr);	// @07a
			else					// @07a
			    isStatic = false;  // Illegal operator @07a
			break;					// @07a
		}
	    }
	    else if ((getTokStr(2*i) == "avpTestCase") || (getTokStr(2*i+1) == "avpTestCase")) // @08a
	    {
		// Process left operand
		tempStr = getTokStr(2*i);			// @08a
		if (tempStr == "avpTestCase")			// @08a
		{
		    leftValueStr = "NONE";			// @08a
		}
		else						// @08a
		{
		    leftValueStr = tempStr;			// @08a
		}
		// Process right operand
		tempStr = getTokStr(2*i+1);			// @08a
		if (tempStr == "avpTestCase")			// @08a
		{
		    rightValueStr = "NONE";			// @08a
		}
		else						// @08a
		{
		    rightValueStr = tempStr;			// @08a
		}
	    // Process the operator
	    // Starting at left operand, find position of first operand char
		cpA = cv_line.find_first_of("=!", getTokPos(2*i)); // @08a
		c = cv_line[cpA+1];				// @08a

	    // Now have everything needed to evaluate the condition stmt
	    // cpA points to first char of operator and c is second char
		switch (cv_line[cpA])				// @08a
		{
		    case '=':					// @08a
			if (c == '=')				// @08a
			    isStatic = (leftValueStr == rightValueStr);	// @08a
			else					// @08a
			    isStatic = false;  // Illegal operator @08a
			break;					// @08a
		    case '!':					// @08a
			if (c == '=')					// @08a
			    isStatic = (leftValueStr != rightValueStr);	// @08a
			else					// @08a
			    isStatic = false;  // Illegal operator @08a
			break;					// @08a
		}
	    }
	    else if ((getTokStr(2*i) == "RISK_LEVEL") || (getTokStr(2*i+1) == "RISK_LEVEL")) // @0Aa
	    {
		// Process left operand
		tempStr = getTokStr(2*i);			// @0Aa
		c = toupper(tempStr[1]);			// @0Aa
		if (tempStr == "RISK_LEVEL")			// @0Aa
		    leftValue = i_risklevel;			// @0Aa
		else if (tempStr[0] == '0' && c == 'X')		// @0Aa
		    leftValue = hexStrtoul(tempStr.substr(2));	// @0Aa
		else if (tempStr[0] == '0' && c == 'B')		// @0Aa
		    leftValue = binStrtoul(tempStr.substr(2));	// @0Aa
		else						// @0Aa
		{
		    isStatic = false;				// @0Aa
		    *isFatalErr = true;
            ILOG(ERMSG) << "ToRIF: Unsupported L-operand: " << tempStr << endl; // @0Aa
		    break;					// @0Aa
		}
		// Process right operand
		tempStr = getTokStr(2*i+1);			// @0Aa
		c = toupper(tempStr[1]);			// @0Aa
		if (tempStr == "RISK_LEVEL")			// @0Aa
		    rightValue = i_risklevel;			// @0Aa
		else if (tempStr[0] == '0' && c == 'X')		// @0Aa
		    rightValue = hexStrtoul(tempStr.substr(2));	// @0Aa
		else if (tempStr[0] == '0' && c == 'B')		// @0Aa
		    rightValue = binStrtoul(tempStr.substr(2));	// @0Aa
		else						// @0Aa
		{
		    isStatic = false;				// @0Aa
		    *isFatalErr = true;
            ILOG(ERMSG) << "ToRIF: Unsupported R-operand: " << tempStr << endl; // @0Aa
		    break;					// @0Aa
		}
	    // Process the operator
	    // Starting at left operand, find position of first operand char
		cpA = cv_line.find_first_of("=!", getTokPos(2*i)); // @0Aa
		c = cv_line[cpA+1];				// @0Aa

	    // Now have everything needed to evaluate the condition stmt
	    // cpA points to first char of operator and c is second char
		switch (cv_line[cpA])				// @0Aa
		{
		    case '=':					// @0Aa
			if (c == '=')				// @0Aa
			    isStatic = (leftValue == rightValue);	// @0Aa
			else					// @0Aa
			    isStatic = false;  // Illegal operator @0Aa
			break;					// @0Aa
		    case '!':					// @0Aa
			if (c == '=')					// @0Aa
			    isStatic = (leftValue != rightValue);	// @0Aa
			else					// @0Aa
			    isStatic = false;  // Illegal operator @0Aa
			break;					// @0Aa
		}
	    }
	    else
	    {
		isStatic = false; *isFatalErr = true;
		ILOG(ERMSG) << "ToRIF: Not a static conditional. " << endl;
		break;
	    }
	}
// @04 Adding back logic that had been deleted by #if defined 
//#endif
    } while (0);
    
    return isStatic;
}

/**
 * Based on global file position markers in the full initfile, copy text from
 * that file to the reduced initfile.
 *
 * @param ifstream & i_readFile - Input file stream for full initfile
 * @param ofstream & i_writeFile - Output file stream for reduced initfile
 * @param char i_stopChar - If specified, continues text copy til this char is
 *    found, exiting with global file position set to start of the next line.
 *    If defaulted, then the global file position is saved/restored on entry/exit.
 * @return void
 */
void EngdInitFile::writeReducedIF(char i_stopChar)
{
    string aLine;
    size_t cpA;
    streampos saveMe = cv_inStream.tellg();

    cv_inStream.seekg(cv_filePosA, ios::beg);
    while (cv_inStream.tellg() < cv_filePosB && (! cv_inStream.eof()))
    {
        getline(cv_inStream, aLine);
        
        // Write line to reduced initfile
        P_RifFile << aLine << endl;
    }
    
    if (i_stopChar == '?')
    {
        cv_filePosB = saveMe;
        cv_inStream.seekg(cv_filePosB, ios::beg);
    }
    else
    {
        while (! cv_inStream.eof())
        {
            cpA = aLine.find_first_not_of(" \t");
            if (cpA != string::npos && aLine[cpA] == i_stopChar)
                break;
            getline(cv_inStream, aLine);
            P_RifFile << aLine << endl;
        }
        cv_filePosB = cv_inStream.tellg();
    }
    
    cv_filePosA = cv_filePosB;
    setOutPending(false);
}


void EngdInitFile::digestData()
{
    int rc = 0;
    time_t rawtime;
    struct tm * timeinfo;

    
    bool isEspy;
    bool checkEnv;	    //@06a
    bool checkExpr;	    //@06a
    bool linesIncluded;     //@06a
    string tempStr;
    uint32_t rightValue = 0;  //@0Da Added initialization to get rid of warning @0Fc
    string defValue;	    //@0Aa
    size_t cpA, cpB, cpNext;
    uint32_t numTokens;
    string rawSpyName, conditionStr;
    string spyPartL, spyVarList, spyPartR;
    string spyVariation;
    char c;
    static bool isFatalErr = false;
    pair<engdSpyInfoMap_t::iterator, bool> spyMapPair;
    
    do
    {
        P_RifFile.open(P_ReducedFn.c_str());
        if (P_RifFile.good())
        { 
            ILOG(P3MSG) << "Successfully opened file for write: " << P_ReducedFn << '!' << endl;
        }
        else
        {
            ILOG(ERMSG) << "E[1004] **Error** Unable to open file for write: " << P_ReducedFn << endl;
            rc = 2;
            break;
        }

        // Write timestamp as first line of reduced initfile
        time (&rawtime);
        timeinfo = localtime(&rawtime);
        P_RifFile << "# Reduced initfile generated by ifScrubber, " << asctime(timeinfo);

        P_SpyNumTotal = 0;
        while (locateFragment())
        {   // Foreach fragment ...
	    numTokens = parseLineTokens("[];", 4);  // @06a
	    if (getTokStr(0) != "define" && getTokStr(0) != "END_INITFILE")           // @06a
	    {
		//  New spy.  Reset spy env filtering flag
		checkEnv = false;                   // @06a
		checkExpr = false;                  // @06a
		linesIncluded = false;              // @06a

	        // Save pointer to start of fragment, may be needed for excluded rings
		saveFragStart();

		P_SpyNumTotal++;
		DLOG(P5MSG) << "\n >>> " << cv_line << endl;

	        // Check for valid format on first line of fragment
		numTokens = parseLineTokens("[]", 3);
		if (numTokens == 3 && (getTokStr(0) == "ispy" || getTokStr(0) == "espy") &&
		    getTokDel(0) == ' ' && getTokDel(1) == '[')
		{
		    // This line looks good so far
		    isEspy = (getTokStr(0).at(0) == 'e');
		    rawSpyName = getTokStr(1);
		    cpA = getTokPos(2);
		    cpB = cv_line.find_first_of("]", cpA);
		    conditionStr = cv_line.substr(cpA, cpB-cpA);
		    DLOG(P5MSG) << "condition string: [" << conditionStr << ']' << endl;
		}
		else
		{
		    ILOG(ERMSG) << "Unsupported format for 1st spydef line: " << cv_line << endl;
		    writeReducedIF('}');
		    continue;
		}

	        // Get the next meaningful line after the espy/ispy line
		if (! getTangibleLine(cpA))
		{
		    cout << "wfdbg: getTangibleLine returns EOF in processInitfile!" << endl;
		    break;  // Hit EOF!
		}

		DLOG(P5MSG) << ">>> " << cv_line << endl;

	        // Check for valid format on second line of fragment
		numTokens = parseLineTokens(",;", 3); 
		if (numTokens == 1 && getTokStr(0) == "spyv" && getTokDel(0) == ';')
		{
		// All is good -- simple enum/value type
		// DLOG(P5MSG) << "   ... Found simple enum/value type enum" << endl;
		}
		else if (numTokens == 2 && getTokStr(0) == "bits" && getTokDel(0) == ',' &&
			 getTokStr(1) == "spyv" && getTokDel(1) == ';')
		{
		    // All is good -- bits/spyv type
		    // DLOG(P5MSG) << "   ... Found bits/spyv type enum" << endl;
		}
		else if (numTokens == 2 && getTokStr(0) == "spyv" && getTokDel(0) == ',' &&
			 getTokStr(1) == "expr" && getTokDel(1) == ';')             //@06a
		{
		    // All is good -- bits/expr type
		    DLOG(P5MSG) << "   ... Found spyv/expr type spy" << endl;        //@06a
		    checkExpr = true;                                                //@06a
		}
		else if (numTokens == 3 && getTokStr(0) == "spyv" && getTokDel(0) == ',' &&
			 getTokStr(1) == "env" && getTokDel(1) == ',' &&
			 getTokStr(2) == "expr" && getTokDel(2) == ';') 	    //@06a
		{
		    // All is good -- spyv/env/expr type
		    DLOG(P5MSG) << "   ... Found spyv/env/expr type spy" << endl;   //@06a
		    checkEnv = true;                                                //@06a
		}
		else
		{
		    ILOG(ERMSG) << "Unsupported spyv line format" << endl;
		    writeReducedIF('}');
		    continue;
		}

	        // So far so good -- COULD be a static spy...
	        // Next examine the condition string, parsed out above
	        // @04 Added iplmode to check
		if (! matchConditionAndEc(conditionStr, P_EcValue, P_IplModeStr, &isFatalErr))  //@04c
		{
           if(isFatalErr == true) {
            ILOG(ERMSG) << "ToRIF: Failed EC/iplmode/Condition check with EC value of "
		     << hex << P_EcValue << ", iplmode: " << P_IplModeStr << dec << ", and condition: " << conditionStr << dec << endl;    //@04c
		    writeReducedIF('}');
            break;
           }
           else {
                DLOG(P5MSG) << "ToRIF: Failed EC/iplmode/Condition check with EC value of "
		        << hex << P_EcValue << ", iplmode: " << P_IplModeStr << dec << ", and condition: " << conditionStr << dec << endl;    //@04c
		        writeReducedIF('}');
		        continue;
           }

		     
		}

        DLOG(P5MSG) << "Map candidate! Type[" << isEspy << "]" << endl;
        DLOG(P5MSG) << "Raw spy name: \'" << rawSpyName << "\'" << endl;
        DLOG(P5MSG) << "Condition is \'" << conditionStr << "\'" << endl;
	        // Get spy values next
		engdSpyData_t * spyDataPtr = NULL;
		engdSpyData_t * spyCopyPtr = NULL;

		if (isEspy)
		{
		    while (getTangibleLine(cpA) && (cv_line[cpA] != '}')) // @09a
		    // if (getTangibleLine(cpA) && (cv_line[cpA] != '}')) // @09d
		    {
			// Only one value allowed for an espy
			if (linesIncluded == true)			// @0Aa
			{
			    DLOG(P5MSG) << "Already found value line ignoring subsequent line: " << cv_line << endl; //@0Aa
			    continue; //@0Aa
			}
			DLOG(P5MSG) << "Found espy value line: " << cv_line << endl;

			tempStr = "";					//@06a
			defValue = "";					//@0Aa
			numTokens = parseLineTokens(":;,", 8);          //@06c

			if (numTokens >= 2 && (checkExpr == true || checkEnv == true))	//@06a @09c @0Ac 
			{
			    // Line contains a define
			    if (cv_line.find("def_",0) != string::npos) //@06a
			    {
			        // Strip paren if present
				if (getTokStr(1).substr(0, 1) == "(" )	//@0Aa
				    tempStr = getTokStr(1).substr(1, getTokStr(1).length()); // @0Aa
				else					//@0Aa
				    tempStr = getTokStr(1);                     //@06a
				if (tempStr.substr(0,4) == "def_" )         //@06a
				{
				    defValue = P_DefinesMap[tempStr];   //@06a @0Aa
				    DLOG(P5MSG) << "Retrieving from map " << tempStr << " = " << defValue << endl; // @0Aa
				}
			    }
			    if (cv_line.find("(IPLMODE == RUNTIME)",0) != string::npos) //@06a
			    {
				tempStr = "RUNTIME";			//@06a
			    }
			    if (cv_line.find("(IPLMODE == HBI)",0) != string::npos) //@06a
			    {
				tempStr = "HBI";			//@06a
			    }
			    // If filter parms don't match filter parm or def_ not match or token 2 not 'any' then skip line
			    if (defValue != P_EnvFilter && tempStr != P_IplModeStr && (numTokens > 3 && defValue != getTokStr(3).substr(0, getTokStr(3).length()-1)) && tempStr != "any" )	//@06a @0Ac @0Bc
			    {
				continue;                               //@06a
			    }
			    linesIncluded = true;	                //@06a
			}

			if ((numTokens == 1 && getTokDel(0) == ';') || (linesIncluded == true)) //@06c
			{
			    spyDataPtr = new engdSpyData_t;

			    DLOG(P3MSG) << "Including line: " << cv_line << endl; //@0Aa
			    if (spyDataPtr)
			    {
				// Insert ascii enum string into bitBasis
				tempStr = getTokStr(0);
				spyDataPtr->bitBasis.growBitLength(8*tempStr.length());
				spyDataPtr->bitBasis.insertFromAscii(tempStr.c_str());
				spyDataPtr->bitValid.setBitLength(0);

				// Must read to end of fragment to keep in sync   
				//while (! isEOF())					@09d
				//{							@09d
				//    getLINE(tempStr);					@09d
				//    cpA = tempStr.find_first_not_of(" \t#");		@09d
				//    DLOG(P5MSG) << "Getting lines: " << tempStr << endl; @09d
				//    if (cpA != string::npos && tempStr[cpA] == '}')	@09d
				//	break;						@09d
				//}							@09d
			    }
			    else
			    {
				ILOG(ERMSG) << "E[1005] **Error** engdSpyData_t Allocation error!" << endl;
				delete spyDataPtr;
				spyDataPtr = NULL;
				break;
			    }
			}
			else
			{
			    ILOG(ERMSG) << "ToRIF: Invalid enum string" << endl;
			}
		    }   // while getTangibleLine
		    //else								@09d
		    //{									@09d
			//DLOG(P5MSG) << "ToRIF: Unable to find espy value!" << endl;	@09d
		    //}									@09d
		}
		else  // Ispy here
		{
		    uint32_t sBitNumVal, eBitNumVal, bitLength = 1;

		    spyDataPtr = new engdSpyData_t;

		    while (getTangibleLine(cpA) && (cv_line[cpA] != '}'))
		    {
			// Only one value allowed for an espy unless defining bit ranges (e.g. '0:63')
			if (linesIncluded == true && !(cv_line.find(":",0) != string::npos))	// @0Ea
			{
			    DLOG(P5MSG) << "Already found value line ignoring subsequent line: " << cv_line << endl; //@0Ea
			    continue; //@0Ea
			}
			DLOG(P5MSG) << "Found ispy value line: " << cv_line << endl;

			tempStr = "";					//@08a
			numTokens = parseLineTokens(":;,", 4);
			if (numTokens >= 3)				//@06a @0Ac @0Dc
			{
			    // Line contains a define
			    if (cv_line.find("def_",0) != string::npos) //@06a
			    {
				if (getTokStr(1).substr(0, 1) == "(" )	//@0Aa
				    tempStr = getTokStr(1).substr(1, getTokStr(1).length()); // @0Aa
				else					//@0Aa
				    tempStr = getTokStr(1);                     //@06a
				if (tempStr.substr(0,4) == "def_" )         //@06a
				{
				    defValue = P_DefinesMap[tempStr];   //@06a @0Ac
				    DLOG(P5MSG) << "value (retrieved from map): " << defValue << endl; //@06a
				}
			        // If filter parms don't match filter parm or token 2 not 'any' then skip line
				if (defValue != P_EnvFilter && tempStr != "any" )	//@06a @0Ac
				{
				    continue;                               //@06a
				}
				DLOG(P3MSG) << "Including ispy def_ line: " << cv_line << endl; //@0Ec
				linesIncluded = true;                    //@06a
			    }
			    if (getTokStr(1) == "(ec")				// @0Da
			    {
				tempStr = getTokStr(3).substr(0, getTokStr(3).length()-1); // @0Da
				c = (tempStr.length() > 1) ? toupper(tempStr[1]) : 'N';    // @0Da
				if (tempStr[0] == '0' && c == 'X')		// @0Da
				    rightValue = hexStrtoul(tempStr.substr(2));	// @0Da
				else if (tempStr[0] == '0' && c == 'B')		// @0Da
				    rightValue = binStrtoul(tempStr.substr(2));	// @0Da
				DLOG(P5MSG) << "Checking ec level parm: " << P_EcValue << " against specified value: " << rightValue << endl;			// @0Da
				if (((getTokStr(2) == ">")  && !(P_EcValue > rightValue ))   || 
				    ((getTokStr(2) == ">=") && !(P_EcValue >= rightValue ))  || 
				    ((getTokStr(2) == "<")  && !(P_EcValue < rightValue ))   ||
				    ((getTokStr(2) == "<=") && !(P_EcValue <= rightValue ))  ||
				    ((getTokStr(2) == "!=") && !(P_EcValue != rightValue ))  ||
				    ((getTokStr(2) == "=")  && !(P_EcValue = rightValue ))   ) // @0Da 
				{
				    continue;					// @0Da
				}
				DLOG(P3MSG) << "Including ispy ec line " << cv_line <<  endl;   // @0Ec
				linesIncluded = true;				// @0Da
			    }
			    if (getTokStr(1) == "(avpTestCase" && ((getTokStr(2) != "==") | (getTokStr(3) != "NONE"))) // @0Ea
			    {
				continue;					// @0Ea
			    }
			    if (getTokStr(1) == "(IPLMODE")
			    {
				   if (cv_line.find("(IPLMODE == RUNTIME)",0) != string::npos) //@06a
			    	   {
					DLOG(P5MSG) << "Found IPL mode - RUNTIME" << endl;
					tempStr = "RUNTIME";			//@06a
			           }
			    	   if (cv_line.find("(IPLMODE == HBI)",0) != string::npos) //@06a
			           {
					DLOG(P5MSG) << "Found IPL mode - HBI" << endl;
					tempStr = "HBI";			//@06a
			           }
			    	   // If filter parms don't match filter parm or def_ not match or token 2 not 'any' then skip line
			    	   if (defValue != P_EnvFilter && tempStr != P_IplModeStr && (numTokens > 3 && defValue != getTokStr(3).substr(0, getTokStr(3).length()-1)) && tempStr != "any" )	//@06a @0Ac @0Bc
			    	   {
					DLOG(P5MSG) << "Current IPL mode is " << P_IplModeStr << " but requested IPL mode is " << tempStr << endl;
					DLOG(P3MSG) << "Excluding " << cv_line << " due to IPL mode" << endl; 
                    continue; // @15c
			    	   }
			    	   linesIncluded = true;	                //@06a
			    }
			}
			if (getTokStr(0).find_first_of("+-/*()") != string::npos)
			{
			    ILOG(ERMSG) << "ToRIF: line contains an expression!" << endl;
			    delete spyDataPtr;
			    spyDataPtr = NULL;
			    break;
			}
			tempStr = getTokStr(0);
			c = (tempStr.length() > 1) ? toupper(tempStr[1]) : 'N';
			if (tempStr[0] == '0' && (c == 'B' || c == 'X'))
			{   // Found bare bin/hex data: cp value to buffer
			    if (! spyDataPtr->setBuffer(0, ENGD_DC_VALUE, tempStr))
			    {
				ILOG(ERMSG) << "ToRIF: 2-Invalid spy value char" << endl;
				delete spyDataPtr;
				spyDataPtr = NULL;
				break;
			    }
			}
			else if (tempStr.find_first_not_of("0123456789") == string::npos)
			{  // Found decimal bit position
			    sBitNumVal = decStrtoul(tempStr);
			    if (getTokDel(0) == ':')
			    {   // Bit range detected, find ending bit num
				if (numTokens >= 3 && 
				    getTokStr(1).find_first_not_of("0123456789") == string::npos)  // @0Dc
				{
				    eBitNumVal = decStrtoul(getTokStr(1));
				    bitLength  = eBitNumVal - sBitNumVal + 1;
				}
				else
				{
				    ILOG(ERMSG) << "ToRIF: non-dec in bit range!" << endl;
				    delete spyDataPtr;
				    spyDataPtr = NULL;
				    break;
				}
			    }
			    else if (getTokDel(0) == ',')
			    {   // Single bit/value detected
				bitLength = 1;
			    }
			    else
			    {
				ILOG(ERMSG) << "ToRIF: Decimal not followed by colon/comma" << endl;
				delete spyDataPtr;
				spyDataPtr = NULL;
				break;
			    }
			    // Ready to find the spy value
			    if (bitLength > 1)
			    {
				tempStr = getTokStr(2);
				c = getTokDel(2);
			    }
			    else
			    {
				tempStr = getTokStr(1);
				c = getTokDel(1);
			    }
			    if (c == ';')
			    {
				if (! spyDataPtr->setBuffer(sBitNumVal, bitLength, tempStr))
				{
				    ILOG(ERMSG) << "ToRIF: 3-Invalid spy value char" << endl;
				    delete spyDataPtr;
				    spyDataPtr = NULL;
				    break;
				}
			    }
			    else
			    {
				ILOG(ERMSG) << "ToRIF: Semicolon not where expected!" << endl;
				delete spyDataPtr;
				spyDataPtr = NULL;
				break;
			    }
			}
			else
			{
			    ILOG(ERMSG) << "ToRIF: Non bin/hex/decimal value!" << endl;
			    delete spyDataPtr;
			    spyDataPtr = NULL;
			    break;
			}
			DLOG(P3MSG) << "Including ispy line " << cv_line <<  endl;	//@0Ea
			linesIncluded = true;						//@08a
		    }  // while getTangibleLine
		    // Don't include spy if env lines were present but none for requested env.
		    if ((checkEnv == true || checkExpr == true) && linesIncluded == false)                      //@06a
		    {
			DLOG(P5MSG) << "No lines included for requested env/expr!" << endl;   //@06a
			delete spyDataPtr;                                               //@06a
			spyDataPtr = NULL;                                               //@06a
		    }
		}  // Found espy/ispy
		if (spyDataPtr == NULL)
		{
		    writeReducedIF('}');
		    continue;
		}
	        // At this point, we have successfully parsed a static spy definition
	        // and the last line read should have been the closing brace.
	        // Save starting position of spy in case it is in an exclude ring.
	        // This cannot be determined til parsing the spydef.  If a spy is
	        // initially determined to be static, but found to be part of an
	        // exclude ring when parsing the spydef, it must be writtn to the RIF.
		spyDataPtr->spySavePos = getFragStart();
	        // Write any pending output to the RIF
		if (getOutPending())
		    writeReducedIF();
		P_RifFile << "# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" << endl;
		P_RifFile << "# Probable static ring init: " << rawSpyName << endl;
		P_RifFile << "#  (Unless part of an excluded ring... Search below)" << endl;
		P_RifFile << "# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" << endl;
		P_RifFile << endl;
	        // Statics not output to RIF, so advance the file pointers
		P_InitFile.advanceFilePos();
	        // Expand multiple spy names if present
		if (getDelimitedString(rawSpyName, 0, "(", "(", spyPartL, cpNext))
		{
		    if (cpNext != string::npos &&
			getDelimitedString(rawSpyName, cpNext, ")", ")", spyVarList, cpNext))
		    {
		        // Add some trailing chars to simplify later parsing
			spyVarList += ",$";
			if (cpNext != string::npos)
			    spyPartR = rawSpyName.substr(cpNext);
			else
			    spyPartR = "";
			cpNext = 0;
			while (getDelimitedString(spyVarList, cpNext, ", \t", ",", spyVariation, cpNext))
			{
			    tempStr = spyPartL + spyVariation + spyPartR;
			    // @02c - previously converted spynames to upper case
			    // here.  No longer needed cuz map-ordering & compare are
			    // case-insensitive now.
			    DLOG(P5MSG) << "1 INSERT: key = " << tempStr << ", value = ["
			      << spyDataPtr->isEnum() << "]+" << spyDataPtr->bitBasis.genHexLeftStr() << endl;
			    spyMapPair = P_SpyInfoMap.insert(make_pair(tempStr, spyDataPtr));
			    if (spyMapPair.second == false)
			    {
				ILOG(ERMSG) << "E[1006] **Error** Duplicate spy map entry! " << tempStr << endl;
			        // TBD: Could maybe handle this by prefixing/appending special chars to string??
				continue;
			    }
			    // Allocate new mem for next entry
			    if (spyVarList[cpNext] != '$')  // Test for eol
			    {
				spyCopyPtr = new engdSpyData_t;
				spyCopyPtr->bitBasis   = spyDataPtr->bitBasis;
				spyCopyPtr->bitValid   = spyDataPtr->bitValid;
			        // On multi-spys that must be saved to the RIF due to
			        // being part of an excluded ring, only 1-of-N needs
			        // to be saved.  Assign to 0 here will skip others.
				spyCopyPtr->spySavePos = 0;
				spyDataPtr = spyCopyPtr;
			    }
			}
		    }
		}
		else
		{
		    // @02c - previously converted spynames to upper case
		    // here.  No longer needed cuz map-ordering & compare are
		    // case-insensitive now.
		    if (spyDataPtr->bitBasis.getBitLength() == 0)
		    {
		        // Shouldn't happen, but if it does I wanna know about it!!
			ILOG(ERMSG) << "E[1007] **Error** Trying to put a zero-length spy in map?! " << rawSpyName << endl;
		    }
		    else
		    {
			DLOG(P5MSG) << "2 INSERT: key = " << rawSpyName << ", value = ["
			  << spyDataPtr->isEnum() << "]+" << spyDataPtr->bitBasis.genHexLeftStr() << endl;
			spyMapPair = P_SpyInfoMap.insert(make_pair(rawSpyName, spyDataPtr));
			if (spyMapPair.second == false)
			{
			    // @03c next: Use diff. msg than multiple case above!
			    ILOG(ERMSG) << "E[1008] **Error** Duplicate spy map entry! " << rawSpyName << endl;
			    // TBD: There are 2 possibilities here: 1. spys are really duplicates, or 2. 2
			    // different spies hash to same entry.  Must report (1) as error, but may be able
			    // to handle (2) by modifying the string somehow and recognizing that later. 
			    continue;
			}
		    }
		}
	    }
	    else // Not a spy  @06a
	    {
		if (getTokStr(0) == "END_INITFILE") // Reset map of defines if new initfile @06a
		{
		    // Clear map
		    P_DefinesMap.clear();                                          // @06a
		    DLOG(P5MSG) << "New initfile section clearing map of defines " << endl; //@06a
		    continue;                                                      //@06a
		}
		else // It's a define.  Need to add map entry @06a
		{
		    tempStr = "";						//@0Aa
		    // Check for valid format -- example  define  def_xxxxx  = (value);
		    numTokens = parseLineTokens(";", 6);                           // @06a @0Ac
		    if (numTokens >= 4 &&
			getTokStr(1).substr(0, 4) == "def_" &&
			getTokStr(2) == "=")					//@0Ac
		    {
			if (getTokStr(3).substr(0, 1) == "(" &&
			    getTokStr(3).substr((getTokStr(3).length())-1, 1) == ")") // @06a
			{
			    // Strip () from define value
			    tempStr = getTokStr(3).substr(1, getTokStr(3).length()-2); // @06a
			}
			else if (getTokStr(3) == "(IPLMODE" && getTokStr(4) == "==") // @0Aa
			{
			    // Resolve IPLMODE if define contains that
			    tempStr = getTokStr(5).substr(0, getTokStr(5).length()-1);	// @0Aa
			    DLOG(P5MSG) << "tempStr = " << tempStr  << endl;	// @0Aa
			    if (tempStr == P_IplModeStr)
				tempStr = "1";					//@0Aa
			    else						//@0Aa
				tempStr = "0";					//@0Aa
			}
			else							//@0Aa
			    ILOG(INMSG) << "**Info** This define not supported for static inits " << getTokStr(1) << endl; //@0Aa
			// Insert define into map
			P_DefinesMap.insert(make_pair(getTokStr(1), tempStr));     // @06a
			DLOG(P5MSG) << "Inserting define into map " << getTokStr(1) << " = " << tempStr << endl; // @06a
		    }
		}
	    }
	}   // Foreach fragment ...
        
        if (rc)
            break;
	} while (0);
    if (rc != 2)
        P_RifFile.close();
        
    // This number may be decreased for excluded rings in processSpydef
    P_SpyNumStatic = P_SpyInfoMap.size();
    
    return;
}
