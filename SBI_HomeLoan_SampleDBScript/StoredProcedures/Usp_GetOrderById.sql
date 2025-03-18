Create procedure Usp_GetOrderById(@orderid int)  
as   
begin  
set nocount on--it prvents no of rows effected.   
Select * from Orders where orderid=@orderid  
end