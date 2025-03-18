Create procedure Usp_UpdateOrder(@orderid int,@ordername varchar(max),@orderlocation varchar(max))  
as   
begin  
set nocount on--it prvents no of rows effected.   
Update Orders set ordername=@ordername,orderlocation=@orderlocation where orderid=@orderid  
end