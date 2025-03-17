CREATE FUNCTION [dbo].[GetSampleone] (@ApptId int, @ProviderId int) RETURNS @UsageFee TABLE (
  RegularFee decimal(18, 2) NULL, 
  AfterHrFee decimal(18, 2) NULL, 
  WeekendFee decimal(18, 2) NULL --TotalAmount DECIMAL NULL
  ) AS BEGIN DECLARE @CountValue int, 
@resourceId int, 
@labId int, 
@userId int, 
@userType varchar(50), 
@sessionType char(1), 
@RateType int, 
@SqlQuery Varchar(max), 
@ExtUserRoleId int, 
@UserRoleId int, 
@GroupType nvarchar(1) 
set 
  @ExtUserRoleId = 0 
set 
  @UserRoleId = 0 
set 
  @RateType = 0 
set 
  @SqlQuery = '' 
SELECT 
  @resourceId = appt.ResourceId, 
  @labId = appt.LabId, 
  @userId = appt.UserId --,@userType=[user].user_type
  , 
  @sessionType = appt.SpecialFlag, 
  @GroupType =(
    select 
      isnull(GroupType, 'A') 
    from 
      Core.GroupDetail 
    where 
      GroupId = appt.LabId
  ) 
FROM 
  Core.Appointment appt, 
  Core.UserDetail UD 
WHERE 
  appt.UserId = UD.UserId 
  and appt.ApptId = @ApptId 
  and appt.ProviderId = @ProviderId --  And appt.lab_id in (select distinct lab_id from lab_facility_map where facility_id=@facility_id)
  --    AND appt.facility_id = [user].facility_id
set 
  @RateType = (
    select 
      top 1 isnull(UsageFeeTypeId, 0) 
    from 
      Core.UsageFees 
    where 
      ProviderId = @ProviderId 
    order by 
      UsageFeeTypeId desc
  ) --select @ExtUserRoleId = GroupRoleId from Core.GroupRole where GroupId=@ProviderId and Description like 'External User'
  declare @IsSuperAdmin bit 
set 
  @IsSuperAdmin = 0 if exists(
    select 
      * 
    From 
     UserAccess 
    where 
      UserId = @UserId 
      and GroupRoleId in (
        Select 
          GroupRoleId 
        from 
          Core.GroupRole 
        where 
          Description = 'Super Admin'
      )
  ) 
set 
  @IsSuperAdmin = 1 if(@IsSuperAdmin = 1) 
set 
  @UserRoleId = 6 else begin if(
    (
      select 
        description 
      from 
        Core.GroupRole 
      where 
        GroupRoleId in (
          select 
            GroupRoleId 
          from 
            Map.UserAccess 
          where 
            FacilityId = @ProviderId 
            and UserId = @userId 
            and GroupId = @labId
        )
    ) like 'Group Admin'
  ) 
select 
  @UserRoleId = GroupRoleId 
from 
  UserAccess 
where 
  FacilityId = @ProviderId 
  and UserId = @userId 
  and GroupId = @ProviderId else 
select 
  @UserRoleId = GroupRoleId 
from 
  Map.UserAccess 
where 
  FacilityId = @ProviderId 
  and UserId = @userId 
  and GroupId = @labId end 
  /***** Normal Fee Structure      ****/
  if(@RateType = 1) begin if(@ExtUserRoleId != @UserRoleId) Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and isnull(UserType, 'I') like 'I';
else Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and isnull(UserType, 'E') like 'E';
RETURN;
End 
/**************************************************/

/******** Resource based Fee structure ***********/
else if(@RateType = 2) begin if exists (
  select 
    * 
  from 
    Core.UsageFees 
  where 
    ProviderId = @ProviderId 
    and ResourceId = @resourceId
) begin if(@ExtUserRoleId != @UserRoleId) Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and ResourceId = @resourceId 
  and isnull(UserType, 'I') like 'I';
else Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and ResourceId = @resourceId 
  and isnull(UserType, 'E') like 'E';
end else begin if exists (
  select 
    * 
  from 
   UsageFees 
  where 
    ProviderId = @ProviderId 
    and ResourceId =-1
) begin if(@ExtUserRoleId != @UserRoleId) Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and ResourceId =-1 
  and isnull(UserType, 'I') like 'I';
else Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and ResourceId =-1 
  and isnull(UserType, 'E') like 'E';
end else insert into @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.ResourceDetail 
WHERE 
  GroupId = @ProviderId 
  and ResourceId = @resourceId end RETURN;
End 
/********************************************************/

/*************** Group Based Fee Structure***************/
else if(@RateType = 3) begin if exists (
  select 
    * 
  from 
    Core.UsageFees 
  where 
    ProviderId = @ProviderId 
    and GroupId = @labId
) begin if(@ExtUserRoleId != @UserRoleId) begin Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and GroupId = @labId 
  and isnull(UserType, 'I') like 'I';
end else begin Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and GroupId = @labId 
  and isnull(UserType, 'E') like 'E';
end end else begin if exists (
  select 
    * 
  from 
    Core.UsageFees 
  where 
    ProviderId = @ProviderId 
    and GroupId =-1
) begin if(@ExtUserRoleId != @UserRoleId) begin Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and GroupId =-1 
  and isnull(UserType, 'I') like 'I';
end else begin Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and GroupId =-1 
  and isnull(UserType, 'E') like 'E';
end end else insert into @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.ResourceDetail 
WHERE 
  GroupId = @ProviderId 
  and ResourceId = @resourceId end RETURN;
End 
/********************************************************/

/*************** Session Based Fee Structure***************/
else if(@RateType = 4) begin if exists (
  select 
    * 
  from 
    Core.UsageFees 
  where 
    ProviderId = @ProviderId 
    and SessionTypeId in (
      select 
        ProviderSessionMapId 
      from 
        Map.ProviderSessionTypes 
      where 
        SessionCode like @sessionType 
        and GroupId = @ProviderId
    )
) begin if(@ExtUserRoleId != @UserRoleId) Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and SessionTypeId in (
    select 
      ProviderSessionMapId 
    from 
      Map.ProviderSessionTypes 
    where 
      SessionCode like @sessionType 
      and GroupId = @ProviderId
  ) 
  and isnull(UserType, 'I') like 'I';
else Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and isnull(UserType, 'E') like 'E' 
  and SessionTypeId in (
    select 
      ProviderSessionMapId 
    from 
      Map.ProviderSessionTypes 
    where 
      SessionCode like @sessionType 
      and GroupId = @ProviderId
  );
end else begin if exists (
  select 
    * 
  from 
    Core.UsageFees 
  where 
    ProviderId = @ProviderId 
    and SessionTypeId =-1
) begin if(@ExtUserRoleId != @UserRoleId) Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and SessionTypeId =-1 
  and isnull(UserType, 'I') like 'I';
else Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and SessionTypeId =-1 
  and isnull(UserType, 'E') like 'E';
end else insert into @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.ResourceDetail 
WHERE 
  GroupId = @ProviderId 
  and ResourceId = @resourceId end RETURN;
End 
/********************************************************/

/*************** Custom Fee Structure***************/
else if(@RateType = 5) begin Insert INTO @UsageFee 
select 
  * 
from 
  [dbo].[GetUsageFeeForCustomFeeType] (@ApptId, @ProviderId) RETURN;
End 
/********************************************************/

/*************** Lab Type Based Fee Structure***************/
else if(@RateType = 6) begin if exists (
  select 
    * 
  from 
    Core.UsageFees 
  where 
    ProviderId = @ProviderId 
    and BillingTypes = @GroupType
) begin if(@ExtUserRoleId != @UserRoleId) Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and BillingTypes = @GroupType 
  and isnull(UserType, 'I') like 'I';
else Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and isnull(UserType, 'E') like 'E' 
  and BillingTypes = @GroupType;
end else begin if exists (
  select 
    * 
  from 
    Core.UsageFees 
  where 
    ProviderId = @ProviderId 
    and BillingTypes like '-1'
) begin if(@ExtUserRoleId != @UserRoleId) Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and BillingTypes like '-1' 
  and isnull(UserType, 'I') like 'I';
else Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and BillingTypes like '-1' 
  and isnull(UserType, 'E') like 'E';
end else insert into @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.ResourceDetail 
WHERE 
  GroupId = @ProviderId 
  and ResourceId = @resourceId end RETURN;
End 
/*************************************************************************/

/*************** User Role Based Fee Structure***************/
else if(@RateType = 7) begin if exists (
  select 
    * 
  from 
    Core.UsageFees 
  where 
    ProviderId = @ProviderId 
    and Roles = @UserRoleId
) begin if(@ExtUserRoleId != @UserRoleId) Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and Roles = @UserRoleId 
  and isnull(UserType, 'I') like 'I';
else Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and isnull(UserType, 'E') like 'E' 
  and Roles = @UserRoleId;
end else begin if exists (
  select 
    * 
  from 
    Core.UsageFees 
  where 
    ProviderId = @ProviderId 
    and Roles =-1
) begin if(@ExtUserRoleId != @UserRoleId) Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and Roles =-1 
  and isnull(UserType, 'I') like 'I';
else Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.UsageFees 
WHERE 
  ProviderId = @ProviderId 
  and Roles =-1 
  and isnull(UserType, 'E') like 'E';
end else insert into @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.ResourceDetail 
WHERE 
  GroupId = @ProviderId 
  and ResourceId = @resourceId end RETURN;
End 
/************************************************************************************/

/*************** Fee not Set***************/
else begin Insert INTO @UsageFee 
SELECT 
  isnull(RegularFee, 0), 
  isnull(AfterHourFee, 0), 
  isnull(WeekendFee, 0) 
FROM 
  Core.ResourceDetail 
WHERE 
  GroupId = @ProviderId 
  and ResourceId = @resourceId;
RETURN;
end 
/*********************************************************/
insert into @UsageFee 
values 
  (NULL, NULL, NULL);
return;
END
