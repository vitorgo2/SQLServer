USE [msdb]
GO

/****** Object:  Alert [AlwaysOn - Role Change]    Script Date: 8/5/2021 1:21:40 PM ******/

DECLARE @Id UNIQUEIDENTIFIER
SELECT @Id = s.job_id FROM dbo.sysjobs AS s WHERE name = '_AlwaysOn Job Management - Control'

EXEC msdb.dbo.sp_add_alert @name=N'AlwaysOn - Role Change', 
		@message_id=1480, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=10, 
		@include_event_description_in=0, 
		@category_name=N'[Uncategorized]', 
		@job_id=@Id
GO

--Esse alerta em ambos os nós tem a finalidade de em um evento de Failover, executar o Job de controle para que seja feita a ativação dos jobs no novo primário e a desativação no secundário

