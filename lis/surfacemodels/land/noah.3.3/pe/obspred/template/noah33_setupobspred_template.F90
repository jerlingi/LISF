!-----------------------BEGIN NOTICE -- DO NOT EDIT-----------------------
! NASA Goddard Space Flight Center
! Land Information System Framework (LISF)
! Version 7.5
!
! Copyright (c) 2024 United States Government as represented by the
! Administrator of the National Aeronautics and Space Administration.
! All Rights Reserved.
!-------------------------END NOTICE -- DO NOT EDIT-----------------------
!BOP
! !ROUTINE: noah33_setupobspred_template
!  \label{noah33_setupobspred_template}
!
! !REVISION HISTORY:
! 16 Jul 2009: Sujay Kumar; Initial Specification
!
! !INTERFACE:
subroutine noah33_setupobspred_template(OBSPred)
! !USES:
  use ESMF

  implicit none
! !ARGUMENTS: 
  type(ESMF_State)       :: OBSPred
!
! !DESCRIPTION:
!  
!  This routine creates an entry in the Obs pred object used for 
!  parameter estimation
! 
!EOP

end subroutine noah33_setupobspred_template

