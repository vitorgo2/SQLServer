USE [master]
GO


CREATE SCHEMA [ags]
GO

CREATE TABLE [ags].[TB_JobsAlwaysOnPrimaryReplica](
	[IdJobsAlwaysOnPrimaryReplica] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[Nome] [varchar](255) NOT NULL,
	[Ativo] [bit] NOT NULL,
	[StReplicaPrimaria] [bit] NOT NULL,
	[DataModificacao] [datetime] NULL,
	[DataInsercao] [datetime] NULL)
GO

ALTER TABLE [ags].[TB_JobsAlwaysOnPrimaryReplica] ADD CONSTRAINT DF_DataInsercao DEFAULT  (GETDATE()) FOR [DataInsercao]
GO


