Create procedure Usp_AddOrder(@ordername varchar(max),@orderlocation varchar(max),@insertedvalue int output)  
as   
begin  
set nocount on--it prvents no of rows effected.   
insert into Orders(ordername,orderlocation) values(@ordername,@orderlocation)  
set @insertedvalue=SCOPE_IDENTITY()  
end