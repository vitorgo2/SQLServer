USE [master]
GO

/****** Object:  StoredProcedure [ags].[stp_ManageJobStatusOnPrimaryReplica]    Script Date: 8/5/2021 1:11:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [ags].[stp_ManageJobStatusOnPrimaryReplica]
AS
BEGIN

	DECLARE @Server VARCHAR(25) = 'NODE01',
            @JobName VARCHAR(255) = NULL,
            @SQLString NVARCHAR(4000) = NULL;

    --QUANDO O NODE01 É SECUNDÁRIO, DESABILITA TODOS OS SEUS JOBS A PARTIR DA TABELA DE CONTROLE
    IF @@SERVERNAME = @Server AND ags.udf_AGHadrGroupIsPrimary('AGNAME') = 'N'
    BEGIN
        DECLARE agjobs CURSOR FOR
        SELECT j.name
        FROM msdb.dbo.sysjobs j
            INNER JOIN ags.TB_JobsAlwaysOnPrimaryReplica t
                ON j.name = t.Nome
                   AND j.enabled = 1 -- Atualmente habilitados no NODE01
                   AND t.Ativo = 1 -- Estavam ativos no primário antes do failover
				   AND j.name NOT LIKE '%AlwaysOn Job Management%'
        ORDER BY j.name;

        -- Abrir o cursor
        OPEN agjobs;
        FETCH NEXT FROM agjobs
        INTO @JobName;

        -- Habilitar Jobs no novo servidor primário
        WHILE @@FETCH_STATUS = 0
        BEGIN

            SET @SQLString = N'EXEC msdb.dbo.sp_update_job @job_name = '''+ @JobName +''', @enabled = 0';

            EXEC sp_executesql @SQLString;

            --PRINT @SQLString

            FETCH NEXT FROM agjobs
            INTO @JobName;
        END;

        -- Fechar o cursor
        CLOSE agjobs;
        DEALLOCATE agjobs;
    END;

	--QUANDO O NODE01 É PRIMÁRIO APÓS UM FAILOVER, HABILITA TODOS OS SEUS JOBS A PARTIR DA TABELA DE CONTROLE
    IF @@SERVERNAME = @Server AND ags.udf_AGHadrGroupIsPrimary('AGNAME') = 'Y'
    BEGIN
        DECLARE agjobs CURSOR FOR
        SELECT j.name
        FROM msdb.dbo.sysjobs j
            INNER JOIN ags.TB_JobsAlwaysOnPrimaryReplica t
                ON j.name = t.Nome
                   AND j.enabled = 0 -- Atualmente desabilitados no NODE01
                   AND t.Ativo = 1 -- Estavam ativos no primário antes do failover
				   AND j.name NOT LIKE '%AlwaysOn Job Management%'
        ORDER BY j.name;

        -- Abrir o cursor
        OPEN agjobs;
        FETCH NEXT FROM agjobs
        INTO @JobName;

        -- Habilitar Jobs no novo servidor primário
        WHILE @@FETCH_STATUS = 0
        BEGIN

            SET @SQLString = N'EXEC msdb.dbo.sp_update_job @job_name = '''+ @JobName +''', @enabled = 1';

            EXEC sp_executesql @SQLString;

            --PRINT @SQLString

            FETCH NEXT FROM agjobs
            INTO @JobName;
        END;

        -- Fechar o cursor
        CLOSE agjobs;
        DEALLOCATE agjobs;
    END;
END;
GO


