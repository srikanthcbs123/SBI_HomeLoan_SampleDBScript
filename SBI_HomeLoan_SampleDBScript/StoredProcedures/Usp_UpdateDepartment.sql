Create procedure Usp_UpdateDepartment(@deptid int,@deptname varchar(max),@deptlocation varchar(max))  
as   
begin  
set nocount on   
Update Department set deptname=@deptname,deptlocation=@deptlocation where deptid=@deptid  
end