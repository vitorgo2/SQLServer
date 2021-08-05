USE [master]
GO

/****** Object:  UserDefinedFunction [ags].[udf_AGHadrGroupIsPrimary]    Script Date: 8/5/2021 1:11:58 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   FUNCTION [ags].[udf_AGHadrGroupIsPrimary]
(
    @AGName sysname
)
RETURNS CHAR(1)
AS
BEGIN
    DECLARE @PrimaryReplica sysname,
            @IsPrimary CHAR(1);

    SELECT @PrimaryReplica = hags.primary_replica
    FROM sys.dm_hadr_availability_group_states hags
        INNER JOIN sys.availability_groups ag
            ON ag.group_id = hags.group_id
    WHERE ag.name = @AGName;

    IF UPPER(@PrimaryReplica) = UPPER(@@SERVERNAME)
    BEGIN
        SET @IsPrimary = 'Y'; -- primary
    END;
    ELSE
    BEGIN
        SET @IsPrimary = 'N'; -- not primary
    END;

    IF ISNULL(@AGName, '') = ''
    BEGIN
        SET @IsPrimary = 'F'; -- failed 
    END;

    RETURN @IsPrimary;
END;
GO


