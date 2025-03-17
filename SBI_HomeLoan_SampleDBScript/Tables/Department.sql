CREATE TABLE [dbo].[Department](
	[deptid] [int] IDENTITY(1,1) NOT NULL,
	[deptname] [varchar](max) NULL,
	[deptlocation] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]