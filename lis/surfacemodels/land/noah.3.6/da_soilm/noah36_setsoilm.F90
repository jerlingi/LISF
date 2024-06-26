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
! !ROUTINE: noah36_setsoilm
!  \label{noah36_setsoilm}
!
! !REVISION HISTORY:
! 27Feb2005: Sujay Kumar; Initial Specification
! 25Jun2006: Sujay Kumar: Updated for the ESMF design
! 28Aug2017: Mahdi Navari; Updated to take into account the latest developments in the SM DA 
!
! !INTERFACE:
subroutine noah36_setsoilm(n, LSM_State)
! !USES:
  use ESMF
  use LIS_coreMod 
  use LIS_logMod
  use noah36_lsmMod

  implicit none
! !ARGUMENTS: 
  integer, intent(in)    :: n
  type(ESMF_State)       :: LSM_State
!
! !DESCRIPTION:
!  
!  This routine assigns the soil moisture prognostic variables to noah's
!  model space. 
! 
!EOP

  real, parameter        :: MIN_THRESHOLD = 0.02 
  real                   :: MAX_threshold
  real                   :: sm_threshold
  type(ESMF_Field)       :: sm1Field
  type(ESMF_Field)       :: sm2Field
  type(ESMF_Field)       :: sm3Field
  type(ESMF_Field)       :: sm4Field
  real, pointer          :: soilm1(:)
  real, pointer          :: soilm2(:)
  real, pointer          :: soilm3(:)
  real, pointer          :: soilm4(:)
  integer                :: t, j,i, gid, m, t_unpert, LIS_localP, row , col
  integer                :: status
  real                   :: delta(4)
  real                   :: delta1,delta2,delta3,delta4
  real                   :: tmpval
  logical                :: bounds_violation
  integer                :: nIter
  logical                :: update_flag(LIS_rc%ngrid(n))
  logical                :: ens_flag(LIS_rc%nensem(n))
! mn
  real                   :: tmp(LIS_rc%nensem(n)), tmp0(LIS_rc%nensem(n))
  real                   :: tmp1(LIS_rc%nensem(n)),tmp2(LIS_rc%nensem(n)),tmp3(LIS_rc%nensem(n)),tmp4(LIS_rc%nensem(n)) 
  logical                :: update_flag_tile(LIS_rc%npatch(n,LIS_rc%lsm_index))
  logical                :: flag_ens(LIS_rc%ngrid(n))
  logical                :: flag_tmp(LIS_rc%nensem(n))
  logical                :: update_flag_ens(LIS_rc%ngrid(n))
  logical                :: update_flag_new(LIS_rc%ngrid(n))
  integer                :: pcount, icount
  real                   :: MaxEnsSM1 ,MaxEnsSM2 ,MaxEnsSM3 ,MaxEnsSM4
  real                   :: MinEnsSM1 ,MinEnsSM2 ,MinEnsSM3 ,MinEnsSM4 
  real                   :: MaxEns_sh2o1, MaxEns_sh2o2, MaxEns_sh2o3, MaxEns_sh2o4
  real                   :: smc_rnd, smc_tmp 
  real                   :: sh2o_tmp, sh2o_rnd 
  INTEGER, DIMENSION (1) :: seed 
  real                   :: lat , lon 

!  integer :: svk_col,svk_row,ii,jj
!  real    :: svk_statebf(LIS_rc%lnc(n),LIS_rc%lnr(n))

  call ESMF_StateGet(LSM_State,"Soil Moisture Layer 1",sm1Field,rc=status)
  call LIS_verify(status,&
       "ESMF_StateSet: Soil Moisture Layer 1 failed in noahmp36_setsoilm")
  call ESMF_StateGet(LSM_State,"Soil Moisture Layer 2",sm2Field,rc=status)
  call LIS_verify(status,&
       "ESMF_StateSet: Soil Moisture Layer 2 failed in noahmp36_setsoilm")
  call ESMF_StateGet(LSM_State,"Soil Moisture Layer 3",sm3Field,rc=status)
  call LIS_verify(status,&
       "ESMF_StateSet: Soil Moisture Layer 3 failed in noahmp36_setsoilm")
  call ESMF_StateGet(LSM_State,"Soil Moisture Layer 4",sm4Field,rc=status)
  call LIS_verify(status,&
       "ESMF_StateSet: Soil Moisture Layer 4 failed in noahmp36_setsoilm")

  call ESMF_FieldGet(sm1Field,localDE=0,farrayPtr=soilm1,rc=status)
  call LIS_verify(status,&
       "ESMF_FieldGet: Soil Moisture Layer 1 failed in noahmp36_setsoilm")
  call ESMF_FieldGet(sm2Field,localDE=0,farrayPtr=soilm2,rc=status)
  call LIS_verify(status,&
       "ESMF_FieldGet: Soil Moisture Layer 2 failed in noahmp36_setsoilm")
  call ESMF_FieldGet(sm3Field,localDE=0,farrayPtr=soilm3,rc=status)
  call LIS_verify(status,&
       "ESMF_FieldGet: Soil Moisture Layer 3 failed in noahmp36_setsoilm")
  call ESMF_FieldGet(sm4Field,localDE=0,farrayPtr=soilm4,rc=status)
  call LIS_verify(status,&
       "ESMF_FieldGet: Soil Moisture Layer 4 failed in noahmp36_setsoilm")

  update_flag = .true. 
  update_flag_tile = .true. 

  do t=1,LIS_rc%npatch(n,LIS_rc%lsm_index)
  
!    sm_threshold_lo = noah36_struc(n)%noah(t)%smcdry
     MAX_THRESHOLD = noah36_struc(n)%noah(t)%smcmax
     sm_threshold  = MAX_THRESHOLD-MIN_THRESHOLD       
     
     gid = LIS_domain(n)%gindex(&
          LIS_surface(n,LIS_rc%lsm_index)%tile(t)%col,&
          LIS_surface(n,LIS_rc%lsm_index)%tile(t)%row) 




!	if ( LIS_localPet == 0 ) then
!	if (gid ==139027) then

!	row =  LIS_surface(n, LIS_rc%lsm_index)%tile(t)%row
!	col =  LIS_surface(n, LIS_rc%lsm_index)%tile(t)%col
!	      print*, 'LIS_localPet == 0' ,t, gid, row, col, &
!	          LIS_domain(n)%grid(LIS_domain(n)%gindex(col, row))%lat ,&
!	          LIS_domain(n)%grid(LIS_domain(n)%gindex(col, row))%lon
!	endif
!	endif

  !if (gid == 11380) then
      !print*,'here'
      !print*, t, gid,  LIS_surface(n,LIS_rc%lsm_index)%tile(t)%col,&
      !    LIS_surface(n,LIS_rc%lsm_index)%tile(t)%row 
  !endif     
     !MN: delta = X(+) - X(-)
     !NOTE: "noah_updatesoilm.F90" updates the soilm_(t)     
     delta1 = soilm1(t)-noah36_struc(n)%noah(t)%smc(1)
     delta2 = soilm2(t)-noah36_struc(n)%noah(t)%smc(2)
     delta3 = soilm3(t)-noah36_struc(n)%noah(t)%smc(3)
     delta4 = soilm4(t)-noah36_struc(n)%noah(t)%smc(4)
     
     ! MN: check    MIN_THRESHOLD < volumetric liquid soil moisture < threshold 
     if(noah36_struc(n)%noah(t)%sh2o(1)+delta1.gt.MIN_THRESHOLD .and.&
          noah36_struc(n)%noah(t)%sh2o(1)+delta1.lt.&
          sm_threshold) then 
        update_flag(gid) = update_flag(gid).and.(.true.)
        ! MN save the flag for each tile (col*row*ens)   (64*44)*20
        update_flag_tile(t) = update_flag_tile(t).and.(.true.)
     else
        update_flag(gid) = update_flag(gid).and.(.false.)
        update_flag_tile(t) = update_flag_tile(t).and.(.false.)
     endif
     if(noah36_struc(n)%noah(t)%sh2o(2)+delta2.gt.MIN_THRESHOLD .and.&
          noah36_struc(n)%noah(t)%sh2o(2)+delta2.lt.sm_threshold) then 
        update_flag(gid) = update_flag(gid).and.(.true.)
        update_flag_tile(t) = update_flag_tile(t).and.(.true.)
     else
        update_flag(gid) = update_flag(gid).and.(.false.)
        update_flag_tile(t) = update_flag_tile(t).and.(.false.)
     endif
     if(noah36_struc(n)%noah(t)%sh2o(3)+delta3.gt.MIN_THRESHOLD .and.&
          noah36_struc(n)%noah(t)%sh2o(3)+delta3.lt.sm_threshold) then 
        update_flag(gid) = update_flag(gid).and.(.true.)
        update_flag_tile(t) = update_flag_tile(t).and.(.true.)
     else
        update_flag(gid) = update_flag(gid).and.(.false.)
        update_flag_tile(t) = update_flag_tile(t).and.(.false.)
     endif
     if(noah36_struc(n)%noah(t)%sh2o(4)+delta4.gt.MIN_THRESHOLD .and.&
          noah36_struc(n)%noah(t)%sh2o(4)+delta4.lt.sm_threshold) then 
        update_flag(gid) = update_flag(gid).and.(.true.)
        update_flag_tile(t) = update_flag_tile(t).and.(.true.)
     else
        update_flag(gid) = update_flag(gid).and.(.false.)
        update_flag_tile(t) = update_flag_tile(t).and.(.false.)
     endif

   enddo

!-----------------------------------------------------------------------------------------
! MN create new flag: if update flag for 50% of the ensemble members is true 
! then update the stats 
!-----------------------------------------------------------------------------------------
   update_flag_ens = .true.  
   do i=1,LIS_rc%npatch(n,LIS_rc%lsm_index),LIS_rc%nensem(n)
     gid = LIS_domain(n)%gindex(&
          LIS_surface(n,LIS_rc%lsm_index)%tile(i)%col,&
          LIS_surface(n,LIS_rc%lsm_index)%tile(i)%row) 
      flag_tmp=update_flag_tile(i:i+LIS_rc%nensem(n)-1)
      !flag_tmp=update_flag_tile((i-1)*LIS_rc%nensem(n)+1:(i)*LIS_rc%nensem(n))
      pcount = COUNT(flag_tmp) ! Counts the number of .TRUE. elements
      if (pcount.lt.LIS_rc%nensem(n)*0.5) then   ! 50%
         update_flag_ens(gid)= .False.
      endif
      update_flag_new(gid)= update_flag(gid).or.update_flag_ens(gid)  ! new flag
   enddo
   
  ! update step
  ! loop over grid points 
  do i=1,LIS_rc%npatch(n,LIS_rc%lsm_index),LIS_rc%nensem(n)

     gid = LIS_domain(n)%gindex(&
          LIS_surface(n,LIS_rc%lsm_index)%tile(i)%col,&
          LIS_surface(n,LIS_rc%lsm_index)%tile(i)%row) 

     if(update_flag_new(gid)) then 
!-----------------------------------------------------------------------------------------
! 1- update the states
! 1-1- if update flag for tile is TRUE --> apply the DA update    
! 1-2- if update flag for tile is FALSE --> resample the states  
! 2- adjust the sataes
!-----------------------------------------------------------------------------------------
! store update value for  cases that flag_tile & update_flag_new are TRUE
! flag_tile = TRUE --> means met the both min and max threshold 

        tmp1 = LIS_rc%udef
        tmp2 = LIS_rc%udef
        tmp3 = LIS_rc%udef
        tmp4 = LIS_rc%udef

        do m=1,LIS_rc%nensem(n)
           t = i+m-1
           !t = (i-1)*LIS_rc%nensem(n)+m
           
           if(update_flag_tile(t)) then
              
              tmp1(m) = soilm1(t) !noah36_struc(n)%noah(t)%smc(1)
              tmp2(m) = soilm2(t) !noah36_struc(n)%noah(t)%smc(2)
              tmp3(m) = soilm3(t) !noah36_struc(n)%noah(t)%smc(3)
              tmp4(m) = soilm4(t) !noah36_struc(n)%noah(t)%smc(4)

           endif
        enddo
        
        MaxEnsSM1 = -10000
        MaxEnsSM2 = -10000
        MaxEnsSM3 = -10000
        MaxEnsSM4 = -10000

        MinEnsSM1 = 10000
        MinEnsSM2 = 10000
        MinEnsSM3 = 10000
        MinEnsSM4 = 10000

        do m=1,LIS_rc%nensem(n)
           if(tmp1(m).ne.LIS_rc%udef) then 
              MaxEnsSM1 = max(MaxEnsSM1, tmp1(m))
              MaxEnsSM2 = max(MaxEnsSM2, tmp2(m))
              MaxEnsSM3 = max(MaxEnsSM3, tmp3(m))
              MaxEnsSM4 = max(MaxEnsSM4, tmp4(m))

              MinEnsSM1 = min(MinEnsSM1, tmp1(m))
              MinEnsSM2 = min(MinEnsSM2, tmp2(m))
              MinEnsSM3 = min(MinEnsSM3, tmp3(m))
              MinEnsSM4 = min(MinEnsSM4, tmp4(m))
              
           endif
        enddo


       tmp0 = LIS_rc%udef


        ! loop over ensemble       
        do m=1,LIS_rc%nensem(n)
           t = i+m-1
           !t = (i-1)*LIS_rc%nensem(n)+m

           MAX_THRESHOLD = noah36_struc(n)%noah(t)%smcmax
           sm_threshold  = MAX_THRESHOLD-MIN_THRESHOLD       
                      
           ! MN check update status for each tile  
           if(update_flag_tile(t)) then
              
              delta1 = soilm1(t)-noah36_struc(n)%noah(t)%smc(1)
              delta2 = soilm2(t)-noah36_struc(n)%noah(t)%smc(2)
              delta3 = soilm3(t)-noah36_struc(n)%noah(t)%smc(3)
              delta4 = soilm4(t)-noah36_struc(n)%noah(t)%smc(4)
              
              noah36_struc(n)%noah(t)%sh2o(1) = noah36_struc(n)%noah(t)%sh2o(1)+&
                   delta1
              noah36_struc(n)%noah(t)%smc(1) = soilm1(t)
              if(soilm1(t).lt.0) then 
                 print*, 'setsoilm1 ',t,soilm1(t)
                 stop
              endif
              if(noah36_struc(n)%noah(t)%sh2o(2)+delta2.gt.MIN_THRESHOLD .and.&
                   noah36_struc(n)%noah(t)%sh2o(2)+delta2.lt.sm_threshold) then 
                 noah36_struc(n)%noah(t)%sh2o(2) = noah36_struc(n)%noah(t)%sh2o(2)+&
                      soilm2(t)-noah36_struc(n)%noah(t)%smc(2)
                 noah36_struc(n)%noah(t)%smc(2) = soilm2(t)
                 if(soilm2(t).lt.0) then 
                    print*, 'setsoilm2 ',t,soilm2(t)
                    stop
                 endif
              endif
              if(noah36_struc(n)%noah(t)%sh2o(3)+delta3.gt.MIN_THRESHOLD .and.&
                   noah36_struc(n)%noah(t)%sh2o(3)+delta3.lt.sm_threshold) then 
                 noah36_struc(n)%noah(t)%sh2o(3) = noah36_struc(n)%noah(t)%sh2o(3)+&
                      soilm3(t)-noah36_struc(n)%noah(t)%smc(3)
                 noah36_struc(n)%noah(t)%smc(3) = soilm3(t)
                 if(soilm3(t).lt.0) then 
                    print*, 'setsoilm3 ',t,soilm3(t)
                    stop
                 endif
              endif
              ! surface layer
              if(noah36_struc(n)%noah(t)%sh2o(4)+delta4.gt.MIN_THRESHOLD .and.&
                   noah36_struc(n)%noah(t)%sh2o(4)+delta4.lt.sm_threshold) then 
                 noah36_struc(n)%noah(t)%sh2o(4) = noah36_struc(n)%noah(t)%sh2o(4)+&
                      soilm4(t)-noah36_struc(n)%noah(t)%smc(4)
                 noah36_struc(n)%noah(t)%smc(4) = soilm4(t)
                 if(soilm4(t).lt.0) then 
                    print*, 'setsoilm4 ',t,soilm4(t)
                    stop
                 endif
              endif
              
              
!-----------------------------------------------------------------------------------------
! randomly resample the smc from [MIN_THRESHOLD,  Max value from DA @ that tiem step]
!-----------------------------------------------------------------------------------------
           else 
              
!-----------------------------------------------------------------------------------------  
! set the soil moisture to the ensemble mean  
!-----------------------------------------------------------------------------------------
              
              ! use mean value
              ! Assume sh2o = smc (i.e. ice content=0) 
              smc_tmp = (MaxEnsSM1 - MinEnsSM1)/2 + MinEnsSM1
              noah36_struc(n)%noah(t)%sh2o(1) = smc_tmp 
              noah36_struc(n)%noah(t)%smc(1) = smc_tmp
              
              smc_tmp = (MaxEnsSM2 - MinEnsSM2)/2 + MinEnsSM2            
              noah36_struc(n)%noah(t)%sh2o(2) = smc_tmp
              noah36_struc(n)%noah(t)%smc(2) = smc_tmp
              
              smc_tmp = (MaxEnsSM3 - MinEnsSM3)/2 + MinEnsSM3
              noah36_struc(n)%noah(t)%sh2o(3) = smc_tmp
              noah36_struc(n)%noah(t)%smc(3) = smc_tmp
              
              smc_tmp = (MaxEnsSM4 - MinEnsSM4)/2 + MinEnsSM4
              noah36_struc(n)%noah(t)%sh2o(4) = smc_tmp
              noah36_struc(n)%noah(t)%smc(4) = smc_tmp
 
              
	      !MN  4 print 	
	      tmp0(m) = noah36_struc(n)%noah(t)%smc(1)
                          
           endif ! flag for each tile
        enddo ! loop over tile
 
     else ! if update_flag_new(gid) is FALSE   
        if(LIS_rc%pert_bias_corr.eq.1) then           
!--------------------------------------------------------------------------
! if no update is made, then we need to readjust the ensemble if pert bias
! correction is turned on because the forcing perturbations may cause 
! biases to persist. 
!--------------------------------------------------------------------------
           bounds_violation = .true. 
           nIter = 0
           ens_flag = .true. 
           
           do while(bounds_violation) 
              niter = niter + 1
              !t_unpert = i*LIS_rc%nensem(n)
	      t_unpert = i+LIS_rc%nensem(n)-1
              do j=1,4
                 delta(j) = 0.0
                 do m=1,LIS_rc%nensem(n)-1
                    t = i+m-1
                    !t = (i-1)*LIS_rc%nensem(n)+m
                    
                    if(m.ne.LIS_rc%nensem(n)) then 
                       delta(j) = delta(j) + &
                            (noah36_struc(n)%noah(t)%sh2o(j) - &
                            noah36_struc(n)%noah(t_unpert)%sh2o(j))
                    endif
                    
                 enddo
              enddo
              
              do j=1,4
                 delta(j) =delta(j)/(LIS_rc%nensem(n)-1)
                 do m=1,LIS_rc%nensem(n)-1
                    t = i+m-1
                    !t = (i-1)*LIS_rc%nensem(n)+m
                    MAX_THRESHOLD = noah36_struc(n)%noah(t)%smcmax
                    sm_threshold  = MAX_THRESHOLD-MIN_THRESHOLD
                    
                    tmpval = noah36_struc(n)%noah(t)%sh2o(j) - &
                         delta(j)
                    if(tmpval.le.MIN_THRESHOLD) then 
                       noah36_struc(n)%noah(t)%sh2o(j) = &
                            max(noah36_struc(n)%noah(t_unpert)%sh2o(j),&
                            MIN_THRESHOLD)
                       noah36_struc(n)%noah(t)%smc(j) = &
                            max(noah36_struc(n)%noah(t_unpert)%smc(j),&
                            MIN_THRESHOLD)
                       ens_flag(m) = .false. 
                    elseif(tmpval.ge.sm_threshold) then
                       noah36_struc(n)%noah(t)%sh2o(j) = &
                            min(noah36_struc(n)%noah(t_unpert)%sh2o(j),&
                            sm_threshold)
                       noah36_struc(n)%noah(t)%smc(j) = &
                            min(noah36_struc(n)%noah(t_unpert)%smc(j),&
                            sm_threshold)
                       ens_flag(m) = .false. 
                    endif
                 enddo
              enddo
              
!--------------------------------------------------------------------------
! Recalculate the deltas and adjust the ensemble
!--------------------------------------------------------------------------
              do j=1,4
                 delta(j) = 0.0
                 do m=1,LIS_rc%nensem(n)-1
                    t = i+m-1
                    !t = (i-1)*LIS_rc%nensem(n)+m
                    if(m.ne.LIS_rc%nensem(n)) then 
                       delta(j) = delta(j) + &
                            (noah36_struc(n)%noah(t)%sh2o(j) - &
                            noah36_struc(n)%noah(t_unpert)%sh2o(j))
                    endif
                 enddo
              enddo
              
              do j=1,4
                 delta(j) =delta(j)/(LIS_rc%nensem(n)-1)
                 do m=1,LIS_rc%nensem(n)-1
                    t = i+m-1
                    !t = (i-1)*LIS_rc%nensem(n)+m
                    
                    if(ens_flag(m)) then 
                       tmpval = noah36_struc(n)%noah(t)%sh2o(j) - &
                            delta(j)
                       MAX_THRESHOLD = noah36_struc(n)%noah(t)%smcmax
                       if(.not.(tmpval.le.0.0 .or.&
                            tmpval.gt.(MAX_THRESHOLD))) then 
                          
                          noah36_struc(n)%noah(t)%smc(j) = &
                               noah36_struc(n)%noah(t)%smc(j) - delta(j)
                          noah36_struc(n)%noah(t)%sh2o(j) = &
                               noah36_struc(n)%noah(t)%sh2o(j) - delta(j)
                          bounds_violation = .false.
                       endif
                    endif
                    
                    tmpval = noah36_struc(n)%noah(t)%sh2o(j)
                    MAX_THRESHOLD = noah36_struc(n)%noah(t)%smcmax
                    
                    if(tmpval.le.0.0 .or.&
                         tmpval.gt.(MAX_THRESHOLD)) then 
                       bounds_violation = .true. 
                    else
                       bounds_violation = .false.
                    endif
                 enddo
              enddo
              
              if(nIter.gt.10.and.bounds_violation) then 
!--------------------------------------------------------------------------
! All else fails, set to the bounds
!--------------------------------------------------------------------------
                 
!                 write(LIS_logunit,*) '[ERR] Ensemble structure violates physical bounds '
!                 write(LIS_logunit,*) '[ERR] Please adjust the perturbation settings ..'
                 do j=1,4
                    do m=1,LIS_rc%nensem(n)
                       t = i+m-1
                       !t = (i-1)*LIS_rc%nensem(n)+m
                       
                       MAX_THRESHOLD = noah36_struc(n)%noah(t)%smcmax
                       
                       if(noah36_struc(n)%noah(t)%sh2o(j).gt.MAX_THRESHOLD.or.&
                            noah36_struc(n)%noah(t)%smc(j).gt.MAX_THRESHOLD) then                        
                          noah36_struc(n)%noah(t)%sh2o(j) = MAX_THRESHOLD
                          noah36_struc(n)%noah(t)%smc(j) = MAX_THRESHOLD
                       endif
                       
                       if(noah36_struc(n)%noah(t)%sh2o(j).lt.MIN_THRESHOLD.or.&
                            noah36_struc(n)%noah(t)%smc(j).lt.MIN_THRESHOLD) then                        
                          noah36_struc(n)%noah(t)%sh2o(j) = MIN_THRESHOLD
                          noah36_struc(n)%noah(t)%smc(j) = MIN_THRESHOLD
                       endif
!                    print*, i, m
!                    print*, 'smc',t, noah36_struc(n)%noah(t)%smc(:)
!                    print*, 'sh2o ',t,noah36_struc(n)%noah(t)%sh2o(:)
!                    print*, 'max ',t,MAX_THRESHOLD !noah36_struc(n)%noah(t)%smcmax
                    enddo
!                 call LIS_endrun()
                 enddo
              endif
              
           end do
        endif
     endif
  enddo

#if 0 
  svk_statebf = 0.0
  
  do t = 1,LIS_rc%npatch(n,LIS_rc%lsm_index)

     svk_col = LIS_surface(n,LIS_rc%lsm_index)%tile(t)%col
     svk_row = LIS_surface(n,LIS_rc%lsm_index)%tile(t)%row
     
     svk_statebf(svk_col,svk_row) =  svk_statebf(svk_col,svk_row) + &
          noah36_struc(n)%noah(t)%smc(1)
  enddo

  do jj=1,LIS_rc%lnr(n)
     do ii=1,LIS_rc%lnc(n)
        if(svk_statebf(ii,jj).gt.0) then 
           svk_statebf(ii,jj) = svk_statebf(ii,jj)/LIS_rc%nensem(n)
        endif
     enddo
  enddo

  open(100,file='stateupd.bin',form='unformatted')
  write(100) svk_statebf
  close(100)
!  stop
#endif

!stop 666
 
end subroutine noah36_setsoilm

