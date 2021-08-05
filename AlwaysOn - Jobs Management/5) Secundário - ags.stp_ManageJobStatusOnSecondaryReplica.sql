USE [master]
GO

/****** Object:  StoredProcedure [ags].[stp_ManageJobStatusOnSecondaryReplica]    Script Date: 8/5/2021 1:13:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE     PROC [ags].[stp_ManageJobStatusOnSecondaryReplica]
AS
BEGIN

	DECLARE @Server VARCHAR(25) = 'NODE02',
            @JobName VARCHAR(255) = NULL,
            @SQLString NVARCHAR(4000) = NULL;

    --QUANDO O NODE02 É PRIMÁRIO, HABILITA OS JOBS DE ACORDO COM O ÚLTIMO STATUS NA TABELA DE CONTROLE
    IF @@SERVERNAME = @Server AND ags.udf_AGHadrGroupIsPrimary('AGNAME') = 'Y'
    BEGIN
        DECLARE agjobs CURSOR FOR
        SELECT j.name
        FROM msdb.dbo.sysjobs j
            INNER JOIN ags.TB_JobsAlwaysOnPrimaryReplica t
                ON j.name = t.Nome
                   AND j.enabled = 0 -- Atualmente desabilitados no secundário
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

            SET @SQLString = N'EXEC msdb.dbo.sp_update_job @job_name = '''+ @JobName +''' , @enabled = 1';

            EXEC sp_executesql @SQLString;

            --PRINT @SQLString

            FETCH NEXT FROM agjobs
            INTO @JobName;
        END;

        -- Fechar o cursor
        CLOSE agjobs;
        DEALLOCATE agjobs;
    END;

	--QUANDO O NODE02 É SECUNDÁRIO APÓS UM FAILOVER, DESABILITA OS JOBS DE ACORDO COM O ÚLTIMO STATUS NA TABELA DE CONTROLE
    IF @@SERVERNAME = @Server AND ags.udf_AGHadrGroupIsPrimary('AGNAME') = 'N'
    BEGIN
        DECLARE agjobs CURSOR FOR
        SELECT j.name
        FROM msdb.dbo.sysjobs j
            INNER JOIN ags.TB_JobsAlwaysOnPrimaryReplica t
                ON j.name = t.Nome
                   AND j.enabled = 1 -- Atualmente habilitados no NODE02
				   AND j.name NOT LIKE '%AlwaysOn Job Management%'
        ORDER BY j.name;

        -- Abrir o cursor
        OPEN agjobs;
        FETCH NEXT FROM agjobs
        INTO @JobName;

        -- Desabilitar Jobs no NODE02 quando ele se tornou secundário após um failback
        WHILE @@FETCH_STATUS = 0
        BEGIN

            SET @SQLString = N'EXEC msdb.dbo.sp_update_job @job_name = '''+ @JobName +''' , @enabled = 0';

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


