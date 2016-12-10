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



#include <ifScrubBase.H>

// Globals
uint32_t g_VBMask = VBM_LE2;

EngdBaseFile::~EngdBaseFile()
{
    if (cv_inStream.is_open())
        cv_inStream.close();
}

void EngdBaseFile::processFile(LogItStream & i_log)
{
    cv_inStream.open(cv_fn.c_str());
    if (cv_inStream.is_open())
    {
        i_log << INMSG << "-> Enter processing of " << cv_fn << endl;
    }
    else
    {
        i_log << ERMSG << "**Error** Unable to open file for read: " << cv_fn << endl;
    }

    digestData();
    
    if (cv_inStream.is_open())
    {
        i_log << INMSG << "<- Exit processing of  " << cv_fn << ", isErr = " << i_log.isCriticalError() << endl;
        cv_inStream.close();
    }
    else
    {
        i_log << INMSG << "<* Unexpected exit of " << cv_fn << " with file closed?" << endl;
    }
}


/**
 * Read i_file til a tangible line is found.  This will skip lines til:
 * - Not a comment (first non-blank char is '#' or '*'), and
 * - Not a blank line
 *
 * @param ifstream & i_file - Input file stream
 * @param size_t & o_firstNonWS - Position of first non whitespace char in
 *     tangible line.
 * @param uint32_t * o_numLines - If not NULL, returns how many lines were read
 *    from i_file.
 * @param streampos * o_linePos - If not NULL, returns the start position of the
 *    found tangible line.
 *
 * @return bool - Returns true if not end-of-file
 */
bool EngdBaseFile::getTangibleLine(size_t & o_firstNonWS, uint32_t * o_numLines, streampos * o_linePos)
{
    if (o_numLines)
        *o_numLines = 0;
    
    while (! cv_inStream.eof())
    {
        if (o_linePos != NULL)
            *o_linePos = cv_inStream.tellg();
            
        getline(cv_inStream, cv_line);
        
        if (o_numLines)
            *o_numLines += 1;
        
        o_firstNonWS = cv_line.find_first_not_of(" \t");
        if (o_firstNonWS == string::npos || cv_line.at(o_firstNonWS) == '#' ||
            cv_line.at(o_firstNonWS) == '*')
        {
            continue;
        }
            
        break;
    }
    
    return (! cv_inStream.eof());
}


/**
 * Parses the global line buffer based on the specified delimeters.  Space and tab
 * are delimiters by default.  Up to MAX_LINE_TOKENS can be located and are saved
 * to a global array of type tokenInfo_t.  Each tokenInfo_t entry consists of the
 * token string, position, and the actual char that delimited the token.  The nth
 * token info can be retrieved with getTokStr(n), getTokPos(n), getTokDel(n).
 *
 * @param const string & i_delimChars - The set of chars used to delimit tokens.
 *    An empty string here results in space/tab only.
 * @param const uint32_t i_max - Max number of tokens to find.  Limited by MAX_LINE_TOKENS
 *
 * @return uint32_t - The number of tokens found based on input parms.
 */
uint32_t EngdBaseFile::parseLineTokens(const string & i_delimChars, const uint32_t i_max)
{
    uint32_t tokenIndex = 0;
    string dChars = " \t" + i_delimChars;
    size_t cpA, cpB, cpC;
    uint32_t loopCount = (i_max > MAX_LINE_TOKENS) ? MAX_LINE_TOKENS : i_max;
    tokenInfo_t * tokPtr = cv_tokenInfo;
    
    do
    {
        cpA = cv_line.find_first_not_of(" \t", 0);
        while (cpA != string::npos && tokenIndex < loopCount)
        {
            tokPtr->position = cpA;
            cpB = cv_line.find_first_of(dChars, cpA);
            if (cpB != string::npos)
                tokPtr->length = cpB-cpA;
            else
            {
                tokPtr->length    = cv_line.length()-cpA;
                tokPtr->delimeter = '?';
                tokenIndex++;
                break;
            }
            
            cpA = cv_line.find_first_not_of(dChars, cpB);
            cpC = cv_line.find_first_not_of(" \t", cpB);
            if (cpA == cpC)
                tokPtr->delimeter = ' ';
            else if (cpC != string::npos)
                tokPtr->delimeter = cv_line.at(cpC);
            else
                break;
                
            tokenIndex++;
            tokPtr++;
        }
    } while (0);
    
    return tokenIndex;
}

/**
 * Based on user supplied parameters, searches a string for a desired token.
 * Leading whitespace is skipped, and the string will be processed as follows:
 *  - Find position in i_string of first non-whitespace character (pos/1)
 *  - Starting at pos/1, find position of first char in i_delimSet (pos/2)
 *  - Starting at pos/2, find position of first char NOT in i_skipCharSet (pos/3)
 *  - Return delimited string, from i_startOffset to pos/2-1
 *  - Return pos/3 (position of next token)
 *
 * @param const string & i_string - String to search.
 * @param size_t i_startOffset - Starting char offset.
 * @param string i_delimCharSet - Set of chars defined as delimeters.
 * @param string i_skipCharSet - Set of chars to be skipped at end of token.
 * @param string & o_dString - Resulting delimited string.
 * @param size_t & o_nextAfterSkip - Char following last from skip set.  Meant
 *     for use in locating the next token on a subsequent call.
 *
 * @return bool - Returns true if token found
 */
bool EngdBaseFile::getDelimitedString(const string & i_string, size_t i_startOffset,
                        string i_delimCharSet, string i_skipCharSet,
                        string & o_dString, size_t & o_nextAfterSkip)
{
    bool valid;

    size_t cpA, cpB;
    
    // Skip leading whitespace
    cpA = i_string.find_first_not_of(" \t", i_startOffset);
    
    cpB = i_string.find_first_of(i_delimCharSet, cpA);
    if (cpB != string::npos)
    {    
        o_dString = i_string.substr(cpA, cpB-cpA);
        o_nextAfterSkip = i_string.find_first_not_of(i_skipCharSet, cpB);
        valid = true;
    }
    else
    {
        o_dString.clear();
        o_nextAfterSkip = string::npos;
        valid = false;
    }
    
    return valid;
}


LogItStream& operator<< (LogItStream& ls, Verbosity v)
{
    ls.set_verbosity(v);
    return ls;
}

