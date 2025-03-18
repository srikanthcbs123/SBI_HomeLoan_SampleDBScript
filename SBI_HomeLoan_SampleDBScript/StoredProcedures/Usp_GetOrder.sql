Create procedure Usp_GetOrder  
as   
begin  
set nocount on--it prvents no of rows effected.   
Select * from Orders  
end