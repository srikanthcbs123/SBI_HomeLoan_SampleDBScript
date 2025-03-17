Create procedure Usp_GetDepartment  
as   
begin  
set nocount on--it prvents no of rows effected.   
Select * from Department  
end