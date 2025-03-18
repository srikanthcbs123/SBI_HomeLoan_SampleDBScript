Create procedure Usp_DeleteOrder(@orderid int)  
as   
begin  
set nocount on--it prvents no of rows effected.   
Delete from Orders where orderid=@orderid  
end