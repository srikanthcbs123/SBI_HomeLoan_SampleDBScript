Create procedure Usp_AddDepartment(@deptname varchar(max),@deptlocation varchar(max),@insertedvalue int output)  
as   
begin  
set nocount on--it prvents no of rows effected.   
insert into Department(deptname,deptlocation) values(@deptname,@deptlocation)  
set @insertedvalue=SCOPE_IDENTITY()  
end