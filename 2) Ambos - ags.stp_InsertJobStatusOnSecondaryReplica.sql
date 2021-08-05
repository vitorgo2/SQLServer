USE [master]
GO

/****** Object:  StoredProcedure [ags].[stp_InsertJobStatusOnSecondaryReplica]    Script Date: 8/5/2021 1:11:36 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [ags].[stp_InsertJobStatusOnSecondaryReplica]
AS
BEGIN

    DECLARE @ServerPrimary VARCHAR(25) = 'NODE01'
	DECLARE @ServerSecondary VARCHAR(25) = 'NODE02'

    --QUANDO O NODE02 É SECUNDÁRIO E O NODE01 PRIMÁRIO, ATUALIZA A TABELA DE CONTROLE DE JOBS DO NODE01 A PARTIR DO MSDB DO NODE01
    IF @@SERVERNAME = @ServerPrimary AND ags.udf_AGHadrGroupIsPrimary('AGNAME') = 'Y'
    BEGIN

        MERGE ags.TB_JobsAlwaysOnPrimaryReplica AS Destino
        USING msdb.dbo.sysjobs AS Origem
        ON (Origem.name = Destino.Nome)

        -- Registro existe nas 2 tabelas
        WHEN MATCHED AND (Destino.Ativo <> Origem.enabled) THEN
            UPDATE SET Destino.Ativo = Origem.enabled,
                       Destino.DataModificacao = Origem.date_modified

        -- Registro não existe no destino. Inserir.
        WHEN NOT MATCHED THEN
            INSERT VALUES
                   (Origem.name, Origem.enabled, 1, GETDATE(), GETDATE());
    END;

	--QUANDO O NODE02 É SECUNDÁRIO E O NODE01 PRIMÁRIO, ATUALIZA A TABELA DE CONTROLE DE JOBS DO NODE02 A PARTIR DO MSDB DO NODE01
    IF @@SERVERNAME = @ServerSecondary AND ags.udf_AGHadrGroupIsPrimary('AGNAME') = 'N'
    BEGIN

        MERGE ags.TB_JobsAlwaysOnPrimaryReplica AS Destino
        USING [NODE01].msdb.dbo.sysjobs  AS Origem
        ON (Origem.name = Destino.Nome)

        -- Registro existe nas 2 tabelas
        WHEN MATCHED AND (Destino.Ativo <> Origem.enabled) THEN
            UPDATE SET Destino.Ativo = Origem.enabled,
                       Destino.DataModificacao = Origem.date_modified

        -- Registro não existe no destino. Inserir.
        WHEN NOT MATCHED THEN
            INSERT VALUES
                   (Origem.name, Origem.enabled, 1, GETDATE(), GETDATE());
    END;

END
GO


