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
! !ROUTINE: jules52_getsoilm
! \label{jules52_getsoilm}
!
! !REVISION HISTORY:
! 27Feb2005: Sujay Kumar; Initial Specification
! 25Jun2006: Sujay Kumar: Updated for the ESMF design
! 20 Dec 2018: Mahdi Navari; Modified for JULES 5.2
!
! !INTERFACE:
subroutine jules52_getsoilm(n, LSM_State)

! !USES:
  use ESMF
  use LIS_coreMod, only : LIS_rc
  use LIS_logMod,  only  : LIS_verify
  use jules52_lsmMod

  implicit none
! !ARGUMENTS: 
  integer, intent(in)    :: n
  real                   ::timenow
  type(ESMF_State)       :: LSM_State
!
! !DESCRIPTION:
!
!  Returns the soilmoisture related state prognostic variables for
!  data assimilation
! 
!  The arguments are: 
!  \begin{description}
!  \item[n] index of the nest \newline
!  \item[LSM\_State] ESMF State container for LSM state variables \newline
!  \end{description}
!EOP
  type(ESMF_Field)       :: sm1Field
  type(ESMF_Field)       :: sm2Field
  type(ESMF_Field)       :: sm3Field
  type(ESMF_Field)       :: sm4Field
  integer                :: t
  integer                :: status
  real, pointer          :: soilm1(:)
  real, pointer          :: soilm2(:)
  real, pointer          :: soilm3(:)
  real, pointer          :: soilm4(:)
  character*100          :: lsm_state_objs(4)

  call ESMF_StateGet(LSM_State,"Soil Moisture Layer 1",sm1Field,rc=status)
  call LIS_verify(status,'ESMF_StateGet failed for sm1 in jules52_getsoilm')
  call ESMF_StateGet(LSM_State,"Soil Moisture Layer 2",sm2Field,rc=status)
  call LIS_verify(status,'ESMF_StateGet failed for sm2 in jules52_getsoilm')
  call ESMF_StateGet(LSM_State,"Soil Moisture Layer 3",sm3Field,rc=status)
  call LIS_verify(status,'ESMF_StateGet failed for sm3 in jules52_getsoilm')
  call ESMF_StateGet(LSM_State,"Soil Moisture Layer 4",sm4Field,rc=status)
  call LIS_verify(status,'ESMF_StateGet failed for sm4 in jules52_getsoilm')

  call ESMF_FieldGet(sm1Field,localDE=0,farrayPtr=soilm1,rc=status)
  call LIS_verify(status,'ESMF_FieldGet failed for sm1 in jules52_getsoilm')
  call ESMF_FieldGet(sm2Field,localDE=0,farrayPtr=soilm2,rc=status)
  call LIS_verify(status,'ESMF_FieldGet failed for sm2 in jules52_getsoilm')
  call ESMF_FieldGet(sm3Field,localDE=0,farrayPtr=soilm3,rc=status)
  call LIS_verify(status,'ESMF_FieldGet failed for sm3 in jules52_getsoilm')
  call ESMF_FieldGet(sm4Field,localDE=0,farrayPtr=soilm4,rc=status)
  call LIS_verify(status,'ESMF_FieldGet failed for sm4 in jules52_getsoilm')


  do t=1,LIS_rc%npatch(n,LIS_rc%lsm_index)
     soilm1(t) = jules52_struc(n)%jules52(t)%smcl_soilt(1) ! [kg/m2]
     soilm2(t) = jules52_struc(n)%jules52(t)%smcl_soilt(2)
     soilm3(t) = jules52_struc(n)%jules52(t)%smcl_soilt(3)
     soilm4(t) = jules52_struc(n)%jules52(t)%smcl_soilt(4)
  enddo



	     
!!           if (LIS_rc%mo.eq. 6 .and. LIS_rc%da.eq.3) then
!           timenow = float(LIS_rc%hr)*3600 + 60*LIS_rc%mn + LIS_rc%ss
!           if (timenow.eq.43200) then
!             print*,' get soilm1  ',soilm1((1376-1)*20+1 : 1376*20)
!           endif




end subroutine jules52_getsoilm

