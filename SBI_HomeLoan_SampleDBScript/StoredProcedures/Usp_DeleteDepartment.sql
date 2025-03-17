Create procedure Usp_DeleteDepartment(@deptid int)  
as   
begin  
set nocount on--it prvents no of rows effected.   
Delete from Department where deptid=@deptid  
end