Create procedure Usp_GetDepartmentById(@deptid int)  
as   
begin  
set nocount on--it prvents no of rows effected.   
Select * from Department where deptid=@deptid  
end