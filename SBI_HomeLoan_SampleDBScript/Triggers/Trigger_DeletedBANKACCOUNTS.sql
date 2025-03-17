Create TRIGGER [dbo].[Trigger_DeletedBANKACCOUNTS] 
ON [dbo].[BankAccounts] 
FOR DELETE 
AS 
Begin 
SELECT * FROM Deleted  
End