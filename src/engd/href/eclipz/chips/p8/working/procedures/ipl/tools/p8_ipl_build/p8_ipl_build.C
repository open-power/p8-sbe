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



// $Id: p8_ipl_build.C,v 1.6 2014/08/19 15:48:32 cmolsen Exp $
/*------------------------------------------------------------------------------*/
/* *! TITLE : p8_ipl_build.C                                                    */
/* *! DESCRIPTION : Copies RS4 delta ring states from EPROM image to DD-        */
//                  specific PNOR IPL image.
//
/* *! EXTENDED DESCRIPTION :                                                    */
//
/* *! USAGE : To build -                                                        */
//              buildecmdprcd -C "p8_image_help_base.C" -c "sbe_xip_image.c" p8_ipl_build.C
//
/* *! ASSUMPTIONS :                                                             */
//    - For p8_ipl_build, sysPhase=0 is assumed.                       
//
/* *! COMMENTS :                                                                */
//    - .strings and .toc are removed as "a unit" before validating.
//
/*------------------------------------------------------------------------------*/

#define SLW_COMMAND_LINE
#include <p8_delta_scan_rw.h>

#define THIS_HELP  ("\nUSAGE:\n\tp8_ipl_build  -help [anything]\n\t  or\n"\
															"\tp8_ipl_build \n"\
															"\t\t<Input Reference image file>\n"\
															"\t\t<DD level [hex value]>\n"\
															"\t\t<Output IPL image file>\n")

//  main() input parms:
//  arg1:   Input Reference image file name
//  arg2:   DD level [hex value]
//  arg3:   Output IPL image file name
int main( int argc, char *argv[])
{
	int				rc=0;
  uint32_t	i;
  char			*i_fnImageIn, *i_fnImageOut;
  uint32_t	i_ddLevel=0;
  uint32_t	fdImageIn=0;
	FILE			*fpImageOut;
	struct stat stbuf;
	uint32_t 	sizeImageIn=0, sizeImageOut=0, sizeImageOutMax=0;
	void *imageIn, *imageOut=NULL;

	SBE_XIP_ERROR_STRINGS(g_errorStrings);

	// ==========================================================================
	// Convert input parms from char to <type>
	// ==========================================================================
	fprintf(stdout,"\n--> Processing Input Parameters...\n");

	if (argc<4 || strcmp(argv[1], "-h")==0 || strcmp(argv[1], "--h")==0)  {
		fprintf(stdout,"%s",THIS_HELP);
		return 1;
	}
	
 	// Convert input parms from char to <type>
 	//
	i_fnImageIn		=				 argv[1];
	i_ddLevel			=	strtol(argv[2], NULL, 16);
	i_fnImageOut	= 			 argv[3];

	fprintf(stdout,"\tInput Ref image fn  = %s\n",i_fnImageIn);
	fprintf(stdout,"\tDD level            = 0x%02x\n",i_ddLevel);
	fprintf(stdout,"\tOutput IPL image fn = %s\n",i_fnImageOut);

	// ==========================================================================
	// Memory map input image.
	// ==========================================================================
	fprintf(stdout,"--> Memory map Reference input image... \n");
	fdImageIn=open( i_fnImageIn, O_RDONLY);
	if (fstat(fdImageIn, &stbuf)!=0)  {
		fprintf(stderr,"Could not fstat the input image file.\n");
		return 1;
	}
	sizeImageIn = stbuf.st_size;
	imageIn = mmap(0, sizeImageIn, PROT_READ, MAP_SHARED, fdImageIn, 0);
	if (imageIn==MAP_FAILED)  {
		fprintf(stderr,"m\tmmap() of input image failed...\n");
		return 1;
	}
	// ...validate image.
  rc = sbe_xip_validate(imageIn, sizeImageIn);
  if (rc)   {
      fprintf(stderr,"\tsbe_xip_validate() of input image failed: %s\n", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
      return 1;
  }

	// Allocate sufficient memory for output image and make initial copy of Ref image.
	//
	// ...since we know it will be smaller than the input image, use sizeImageIn
	sizeImageOutMax = sizeImageIn;
	imageOut = (uint8_t*)malloc(sizeImageOutMax);
	if (!imageOut)  {
		fprintf(stderr,"\tmalloc() for IPL output image memory failed.\n");
		return 1;
	}
	memcpy( imageOut, imageIn, sizeImageIn);

	// Create the IPL image.
	//
	fprintf(stdout,"--> Create the IPL image... \n");
	rc = p8_ipl_build(	imageIn,
											i_ddLevel,
											imageOut,
											sizeImageOutMax);
	if (rc==DSLWB_SLWB_SUCCESS)
		fprintf(stdout,"IPL image build was SUCCESSFUL.\n");
	else
	if (rc==DSLWB_SLWB_NO_RING_MATCH)
		printf("IPL image build was SUCCESSFUL but no RS4 rings appended (rc=%i).\n",rc);
	else  {			
		printf("IPL image build was UNSUCCESSFUL (rc=%i).\n",rc);
		printf("No image file will be created.\n");
		if (imageOut)  free(imageOut);
		return 1;
	}
	close(fdImageIn);

	// Save the IPL image in the output file.
	//
	sbe_xip_image_size(imageOut, &sizeImageOut);
	fprintf(stdout,"\tOutput IPL image size = %i\n",sizeImageOut);
	fpImageOut = fopen(i_fnImageOut, "w");
	for (i=0; i<sizeImageOut; i++)
		fprintf(fpImageOut,"%c",((char*)imageOut)[i]);
	fclose(fpImageOut);
	
	if (imageOut)
		free(imageOut);
	return rc;
}



//  Parameter list:
//  void 			*i_imageIn:   	Pointer to memory mapped input Reference image
//  uint32_t	i_ddLevel:			DD level
//  void			*i_imageOut:  	Pointer to where the initial IPL output image is
//  uint32_t  i_sizeImageOutMax: Max size of output image.
//
int p8_ipl_build(	void 			*i_imageIn,
									uint32_t	i_ddLevel,
									void 			*i_imageOut,
									uint32_t	i_sizeImageOutMax)
{
	int 			rc=0, rcLoc=0, rcLoc1=0, rcLoc2=0, rcSearch=0, countRings=0;
	uint8_t  sysPhase=0;
  uint32_t  sizeImage=0, sizeImageOut=0;
	DeltaRingLayout *rs4RingLayout;
	void *nextRing=NULL;
	SbeXipSection xipSection;

	SBE_XIP_ERROR_STRINGS(g_errorStrings);

	// ==========================================================================
	// First, remove all unnecessary sections in the output image.
	// ==========================================================================
	//
	rcLoc1 = sbe_xip_delete_section( i_imageOut, SBE_XIP_SECTION_DCRINGS);
  rcLoc2 = sbe_xip_image_size(i_imageOut, &sizeImage);
  rcLoc =  sbe_xip_validate(i_imageOut, sizeImage);
	if (rcLoc1 || rcLoc2 || rcLoc)  {
		fprintf(stderr,"_delete_section(.dcrings) (rcLoc1=%i), _image_size() (rcLoc2=%i) and/or _validate() (rcLoc=%i) failed.\n",rcLoc1,rcLoc2,rcLoc);
		return IMGBUILD_ERR_SECTION_DELETE;
	}
	fprintf(stdout,"Image size (after .dcrings delete): %i\n",sizeImage);

	rcLoc1 = sbe_xip_delete_section( i_imageOut, SBE_XIP_SECTION_RINGS);
  rcLoc2 = sbe_xip_image_size(i_imageOut, &sizeImage);
  rcLoc =  sbe_xip_validate(i_imageOut, sizeImage);
	if (rcLoc1 || rcLoc2 || rcLoc)  {
		fprintf(stderr,"_delete_section(.rings) (rcLoc1=%i), _image_size() (rcLoc2=%i) and/or _validate() (rcLoc=%i) failed.\n",rcLoc1,rcLoc2,rcLoc);
		return IMGBUILD_ERR_SECTION_DELETE;
	}
	fprintf(stdout,"Image size (after .rings delete): %i\n",sizeImage);

	rcLoc1 = sbe_xip_delete_section( i_imageOut, SBE_XIP_SECTION_PIBMEM0);
  rcLoc2 = sbe_xip_image_size(i_imageOut, &sizeImage);
  rcLoc =  sbe_xip_validate(i_imageOut, sizeImage);
	if (rcLoc1 || rcLoc2 || rcLoc)  {
		fprintf(stderr,"_delete_section(.pibmem0) (rcLoc1=%i), _image_size() (rcLoc2=%i) and/or _validate() (rcLoc=%i) failed.\n",rcLoc1,rcLoc2,rcLoc);
		return IMGBUILD_ERR_SECTION_DELETE;
	}
	fprintf(stdout,"Image size (after .pibmem0 delete): %i\n",sizeImage);

	rcLoc1 = sbe_xip_delete_section( i_imageOut, SBE_XIP_SECTION_HALT);
  rcLoc2 = sbe_xip_image_size(i_imageOut, &sizeImage);
  rcLoc =  sbe_xip_validate(i_imageOut, sizeImage);
	if (rcLoc1 || rcLoc2 || rcLoc)  {
		fprintf(stderr,"_delete_section(.halt) (rcLoc1=%i), _image_size() (rcLoc2=%i) and/or _validate() (rcLoc=%i) failed.\n",rcLoc1,rcLoc2,rcLoc);
		return IMGBUILD_ERR_SECTION_DELETE;
	}
	fprintf(stdout,"Image size (after .halt delete): %i\n",sizeImage);

	rcLoc1 = sbe_xip_delete_section( i_imageOut, SBE_XIP_SECTION_STRINGS);
	rcLoc2 = sbe_xip_delete_section( i_imageOut, SBE_XIP_SECTION_TOC);
  sbe_xip_image_size(i_imageOut, &sizeImage);
  rcLoc =  sbe_xip_validate(i_imageOut, sizeImage);
	if (rcLoc1 || rcLoc2 || rcLoc)  {
		fprintf(stderr,"_delete_section(.strings) (rcLoc1=%i), _delete_section(.toc) (rcLoc2=%i) and/or _validate() (rcLoc=%i) failed.\n",rcLoc1,rcLoc2,rcLoc);
		return IMGBUILD_ERR_SECTION_DELETE;
	}
	fprintf(stdout,"Image size (after .strings and .toc delete): %i\n",sizeImage);
	
	rcLoc1 = sbe_xip_delete_section( i_imageOut, SBE_XIP_SECTION_DATA);
  rcLoc2 = sbe_xip_image_size(i_imageOut, &sizeImage);
  rcLoc =  sbe_xip_validate(i_imageOut, sizeImage);
	if (rcLoc1 || rcLoc2 || rcLoc)  {
		fprintf(stderr,"_delete_section(.data) (rcLoc1=%i), _image_size() (rcLoc2=%i) and/or _validate() (rcLoc=%i) failed.\n",rcLoc1,rcLoc2,rcLoc);
		return IMGBUILD_ERR_SECTION_DELETE;
	}
	fprintf(stdout,"Image size (after .data delete): %i\n",sizeImage);
	
	rcLoc1 = sbe_xip_delete_section( i_imageOut, SBE_XIP_SECTION_TEXT);
  rcLoc2 = sbe_xip_image_size(i_imageOut, &sizeImage);
  rcLoc =  sbe_xip_validate(i_imageOut, sizeImage);
	if (rcLoc1 || rcLoc2 || rcLoc)  {
		fprintf(stderr,"_delete_section(.text) (rcLoc1=%i), _image_size() (rcLoc2=%i) and/or _validate() (rcLoc=%i) failed.\n",rcLoc1,rcLoc2,rcLoc);
		return IMGBUILD_ERR_SECTION_DELETE;
	}
	fprintf(stdout,"Image size (after .text delete): %i\n",sizeImage);


	// ==========================================================================
	// Re-append .pibmem0
	// ==========================================================================
  rc = sbe_xip_get_section( i_imageIn, SBE_XIP_SECTION_PIBMEM0, &xipSection);
  if (rc)   {
      MY_INF("ERROR : sbe_xip_get_section() failed: %s", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
			MY_INF("Probable cause:");
			MY_INF("\tThe section (=SBE_XIP_SECTION_PIBMEM0=%i) was not found.",SBE_XIP_SECTION_RINGS);
			return IMGBUILD_ERR_KEYWORD_NOT_FOUND;
  }
	rc = sbe_xip_append( 	i_imageOut, 
												SBE_XIP_SECTION_PIBMEM0, 
												(void*)((uintptr_t)i_imageIn + xipSection.iv_offset),
												xipSection.iv_size,
												i_sizeImageOutMax,
												0);
  if (rc)   {
    MY_INF("sbe_xip_append() failed: %s", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
    return IMGBUILD_ERR_APPEND;
  }

	uint8_t   iRingType=0;
	uint8_t   xipSectionId=0;
	uint8_t   bDone=0;
		
	for (iRingType=0; iRingType<RING_SECTION_ID_SIZE; iRingType++)  {

		xipSectionId=RING_SECTION_ID[iRingType];
		nextRing = NULL;
		bDone = 0;

		/***************************************************************************
		 *														SEARCH LOOP - Begin												 	 *
		 ***************************************************************************/
 		do  {
 	
		fprintf(stdout,"nextRing (at top)=0x%016llx",(uint64_t)nextRing);
		
		// ==========================================================================
		// Get ring layout from image
		// ==========================================================================
		fprintf(stdout,"--> Retrieving RS4 ring from Reference image.");
		rcLoc = get_ring_layout_from_image2(	i_imageIn,
																					i_ddLevel,
																					sysPhase,
																					&rs4RingLayout,
																					&nextRing,
																					xipSectionId);
		rcSearch = rcLoc;
		if (rcSearch!=DSLWB_RING_SEARCH_MATCH && 
				rcSearch!=DSLWB_RING_SEARCH_EXHAUST_MATCH && 
				rcSearch!=DSLWB_RING_SEARCH_NO_MATCH)  {
			fprintf(stderr,"\tERROR : Error during retrieval of delta rings from the image (rcSearch=%i).",rcSearch);
			fprintf(stderr,"\tNo further RS4 rings will be appended to the IPL image.");
			fprintf(stderr,"\tThe IPL image is incomplete.");
			return IMGBUILD_ERR_INCOMPLETE_IMG_BUILD;
		}
		if (rcSearch==DSLWB_RING_SEARCH_MATCH || 
				rcSearch==DSLWB_RING_SEARCH_EXHAUST_MATCH)
			fprintf(stdout,"\tRetrieving RS4 ring was successful.");
	
		// Check if we're done at this point.
		//
		if (rcSearch==DSLWB_RING_SEARCH_NO_MATCH)  {
			fprintf(stdout,"IPL image build done.");
			fprintf(stdout,"Number of RS4 rings appended to ring section (ID=%i): %i",xipSectionId,countRings);
			if (countRings==0)
				fprintf(stdout,"ZERO RS4 rings appended to ring section.");
			sbe_xip_image_size( i_imageOut, &sizeImageOut);
			fprintf(stdout,"Final IPL image size: %i", sizeImageOut);
			rc = IMGBUILD_SUCCESS;
			bDone = 1;
		}
	

		if (!bDone)  {

			// ==========================================================================
			// Append RS4 ring to .rings section.
			// ==========================================================================
			fprintf(stdout,"--> Appending RS4 ring to .rings or .dcrings section.");
      void *bufTmp;
      bufTmp = malloc(FIXED_RING_BUF_SIZE);
	    if (!bufTmp)  {
	  	  fprintf(stderr,"\tmalloc() for temporary work buffer failed.\n");
	  	  return IMGBUILD_ERR_MEMORY;
	    }
			rc = write_ring_block_to_image(	i_imageOut,
			                                NULL, // If ringName not known, must be NULL.
																			rs4RingLayout,
																			0,    // Ignored for ringName=NULL.
																			0,    // Ignored for ringName=NULL.
																			0,    // Ignored for ringName=NULL.
																			i_sizeImageOutMax,
	  	                                xipSectionId,
                                      bufTmp,
                                      FIXED_RING_BUF_SIZE);
      free(bufTmp);
	  	if (rc)  {
				fprintf(stderr,"write_ring_block_to_image() failed w/rc=%i\n",rc);
				return IMGBUILD_ERR_RING_WRITE_TO_IMAGE;
			}

			countRings++;
	
			// ==========================================================================
			// Are we done?
			// ==========================================================================
			if (rcSearch==DSLWB_RING_SEARCH_EXHAUST_MATCH)  {
				fprintf(stdout,"IPL image build done.");
				fprintf(stdout,"Number of RS4 rings appended to ring section (ID=%i): %i",xipSectionId,countRings);
				if (countRings==0)
					fprintf(stdout,"ZERO RS4 rings appended to ring section.");
				sbe_xip_image_size( i_imageOut, &sizeImageOut);
				bDone = 1;
				rc = IMGBUILD_SUCCESS;
			}
	
			fprintf(stdout,"nextRing (at bottom)=0x%016llx",(uint64_t)nextRing);

		} // End of if(!bDone)	
	
		} 	while (nextRing!=NULL && !bDone);
		/***************************************************************************
		 *														SEARCH LOOP - End													 	 *
		 ***************************************************************************/
		
		fprintf(stdout,"Done adding rings to ring section ID = %i\n",xipSectionId);
		
	} // End of for(iRingType=...) loop
	
	return rc;

}
