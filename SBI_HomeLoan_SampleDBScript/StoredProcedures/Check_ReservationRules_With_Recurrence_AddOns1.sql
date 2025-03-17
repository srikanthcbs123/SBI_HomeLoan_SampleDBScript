CREATE PROCEDURE [Check_ReservationRules_With_Recurrence_AddOns1] (
  @ProviderId int, 
  @ResourceId int, 
  @ApptId int, 
  @StartTime datetime, 
  @EndTime datetime, 
  @UserId int, 
  @GroupId int, 
  @NoOfRec int = 0, 
  @FreqType nvarchar(1), 
  @AddOns nvarchar(max), 
  @Role varchar(100), 
  @AllowRecurrence bit = null
) as begin declare @UserRole nvarchar(max) declare @tmp table(
  Role nvarchar(max)
) insert into @tmp exec [Core].[Get_UserRole_By_ProviderId] @UserId, 
@ProviderId 
set 
  @UserRole = (
    select 
      top 1 Role 
    From 
      @tmp
  ) if(
    @UserRole like '%Super Admin%' 
    or @UserRole like '%Institution Admin%' 
    or @UserRole like '%Provider Admin%'
  ) begin 
select 
  '' return end print 'Her1' 
set 
  @AllowRecurrence = isnull(@AllowRecurrence, 0) print 'mi' if(
    @ApptId > 0 
    and @AllowRecurrence = 1
  ) begin print 'her2' 
SET 
  @NoOfRec = (
    select 
      count(*)-1 
    From 
      core.appointment 
    where 
      RecurrenceId = (
        Select 
          isnull(recurrenceId, 0) 
        from 
          core.appointment 
        where 
          apptId = @ApptId
      )
  ) 
SET 
  @FreqType = (
    Select 
      top 1 FreqType 
    from 
      Map.ApptRecurrence 
    where 
      RecurrenceId = (
        Select 
          isnull(recurrenceId, 0) 
        from 
          core.appointment 
        where 
          apptId = @ApptId
      )
  ) end print 'hr3' declare @RESULT nvarchar(max)= '' declare @TotalTmpHours decimal(18, 2)= 0 
set 
  @TotalTmpHours = cast(
    datediff(MI, @StartTime, @EndTime) as decimal(18, 2)
  ) --isnull(cast(datediff(mi,@StartTime ,@EndTime)/60 as varchar(5)) + '.' + RIGHT('0' + cast(datediff(mi,@StartTime ,@EndTime)%60 as varchar(5)), 2),'0.00')                                   
  --print 'Total Hours ' + cast(@TotalTmpHours   as nvarchar)        
set 
  @RESULT = (
    select 
      Core.UDF_Reservation(
        @ProviderId, @ResourceId, @ApptId, 
        @StartTime, @EndTime, @UserId, @GroupId, 
        0, @Role, @AllowRecurrence
      )
  ) --print 'Done Executeion' + @RESULT        
  --set @RESULT = (select [dbo].[udf_GET_Appt_TotalHours]( 3,41,932,3885,'11-11-2013','11-18-2013',1,1))                          
  --select 'result = ' + @RESULT          
  if(@RESULT <> '') begin 
select 
  @RESULT return --@RESULT                        
  end else if(
    @RESULT = '' 
    and @NoOfRec > 0
  ) begin 
set 
  @ApptId = (
    select 
      ApptId 
    from 
      (
        select 
          apptId, 
          Rank() over (
            order By 
              ApptId asc
          ) as Rnk 
        from 
          core.appointment 
        where 
          Recurrenceid = (
            Select 
              recurrenceId 
            from 
              core.appointment 
            where 
              apptId = @ApptId
          )
      ) as a 
    where 
      a.Rnk = 2
  ) 
set 
  @RESULT =(
    select 
      Core.Check_ReservationRules_Recurrence(
        @ProviderId, @ResourceId, @ApptId, 
        @StartTime, @EndTime, @UserId, @GroupId, 
        @NoOfRec, @FreqType, @TotalTmpHours, 
        @AllowRecurrence, ''
      )
  ) end if(@RESULT <> '') begin 
select 
  @RESULT return --@RESULT                           
  end else if(
    @RESULT = '' 
    and @AddOns <> ''
  ) begin --getting the freq type & no of recc with recurrenceId            
  declare @ResIds Table(ResId int) declare @ResCount int, 
  @ResId int insert into @ResIds 
select 
  * 
From 
  dbo.stringsplit(@AddOns, ',') 
select 
  @ResCount = count(*) 
from 
  @ResIds 
set 
  @TotalTmpHours = 0 while(@ResCount > 0) begin 
set 
  @ResId = (
    select 
      top 1 ResId 
    from 
      @ResIds
  ) if(@ApptId = 0) begin 
set 
  @ApptId = (
    Select 
      top 1 ApptId 
    from 
      core.Appointment 
    where 
      ProviderId = @providerId 
      and resourceId = @ResId 
      and starttime = @StartTime 
      and endtime = @EndTime 
      and userId = @UserId
  ) end if(
    @ApptId > 0 
    AND @AllowRecurrence = 1
  ) begin 
select 
  @NoOfRec = NumRecurrence, 
  @FreqType = FreqType 
from 
  Map.ApptRecurrence 
where 
  RecurrenceId = (
    select 
      RecurrenceId 
    from 
      Core.Appointment 
    where 
      ApptId = @ApptId
  ) end if(@NoOfRec > 0) --if it contains recurrences and contains addon resources                            
  begin 
set 
  @RESULT = (
    select 
      Core.Check_ReservationRules_Recurrence(
        @ProviderId, @ResId, @ApptId, @StartTime, 
        @EndTime, @UserId, @GroupId, @NoOfRec, 
        @FreqType, @TotalTmpHours, @AllowRecurrence, 
        ''
      )
  ) --set @TotalTmpHours =  isnull(cast(datediff(mi,@StartTime ,@EndTime)/60 as varchar(5)) + '.' + RIGHT('0' + cast(datediff(mi,@StartTime ,@EndTime)%60 as varchar(5)), 2),'0.00')                                   
  end --instrumentId is going to be change, so dont pass  @TotalTmpHours, cause thats the used hours of actual instrument                            
  else -- not contains recurrences, only contains addon resources                            
set 
  @RESULT = (
    select 
      Core.UDF_Reservation(
        @ProviderId, @ResId, @ApptId, @StartTime, 
        @EndTime, @UserId, @GroupId, 0, 0, 
        @Role
      )
  ) if(@RESULT <> '') begin 
select 
  @RESULT return --@RESULT                           
  end delete top(1) 
from 
  @ResIds 
select 
  @ResCount = count(*) 
from 
  @ResIds end end 
select 
  @RESULT --end                             
  end
