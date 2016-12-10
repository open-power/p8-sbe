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




#include <stdio.h>
#include <string.h>
#include <stdint.h>


//----------------------------------------------------------------------
uint32_t modifier2scanselect( uint32_t i_modifier, uint32_t* o_scanselect, uint8_t* o_chiplet )
{
uint32_t scanselect = 0;
uint8_t  chiplet    = (i_modifier & 0xFF000000) >>24;   // chiplet is bits 0:7 of modifier
uint32_t region     = (i_modifier & 0x0000FFF0) >>4;    // region is bits 16:27 of modifier
uint32_t type       = (i_modifier & 0x0000000F);        // type is bits 28:31 of modifier

scanselect = region << 17; // put bits 20:31 of the region value into bits 3:14 of the scanselect value

// scanselect 20:30 are the type value

switch( type ){
  case  0: scanselect |= 0x00000800; break;
  case  1: scanselect |= 0x00000400; break;
  case  2: scanselect |= 0x00000200; break;
  case  3: scanselect |= 0x00000100; break;
  case  4: scanselect |= 0x00000080; break;
  case  5: scanselect |= 0x00000040; break;
  case  6: scanselect |= 0x00000020; break;
  case  7: scanselect |= 0x00000010; break;
  case  8: scanselect |= 0x00000008; break;
  case  9: scanselect |= 0x00000004; break;
  case 10: scanselect |= 0x00000002; break;
	case 11: scanselect |= 0x00000dce; // 1101 1100 1110 scantype_allf
		break;
	case 12: scanselect |= 0x00000280; // 0010 1000 0000 scantype_ccvf
		break;
	case 13: scanselect |= 0x00000082; // 0000 1000 0010 scantype_lbcm
		break;
	case 14: scanselect |= 0x00000044; // 0000 0100 0100 scantype_abfa
		break;
	case 15: scanselect |= 0x00000900; // 1001 0000 0000 scantype_fure
		break;
	}

*o_scanselect = scanselect;
*o_chiplet    = chiplet;

return 0;
}



//----------------------------------------------------------------------
// Test by passing in 32 bit ascii-hex modifier value like "08036006" or "10032000"
//
int main( int argc, char *argv[] )
{
uint32_t modifier   = 0;
uint32_t scanselect = 0;
uint8_t  chiplet    = 0;

if( argc == 1 ){
  printf( "ERROR! Expected modifier value\n" );
  return( 1 );
	}

if( strcmp( argv[1], "-h" ) == 0 ){
  printf( "\nUsage: modifier2scanselect <ascii-hex modifier>\n" );
	printf( "Example: modifier2scanselect 11033006\n\n" );
  return( 1 );
	}

sscanf( argv[1], "%x", &modifier );

modifier2scanselect( modifier, &scanselect, &chiplet );

printf( "modifier=%08x chiplet=%02x scanselect=%08x\n", modifier, chiplet, scanselect );

return( 0 );
}

