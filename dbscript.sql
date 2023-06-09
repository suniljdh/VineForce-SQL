USE [icai_shifted]
GO
/****** Object:  User [icai_shifted]    Script Date: 07-06-2023 12:59:24 PM ******/
CREATE USER [icai_shifted] FOR LOGIN [icai_shifted] WITH DEFAULT_SCHEMA=[icai_shifted]
GO
ALTER ROLE [db_ddladmin] ADD MEMBER [icai_shifted]
GO
ALTER ROLE [db_backupoperator] ADD MEMBER [icai_shifted]
GO
ALTER ROLE [db_datareader] ADD MEMBER [icai_shifted]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [icai_shifted]
GO
/****** Object:  Schema [newschema]    Script Date: 07-06-2023 12:59:24 PM ******/
CREATE SCHEMA [newschema]
GO
/****** Object:  Table [newschema].[country]    Script Date: 07-06-2023 12:59:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [newschema].[country](
	[countryid] [int] IDENTITY(1,1) NOT NULL,
	[countryname] [varchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[countryid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [newschema].[states]    Script Date: 07-06-2023 12:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [newschema].[states](
	[stateid] [int] IDENTITY(1,1) NOT NULL,
	[statename] [varchar](500) NULL,
	[countryid] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[stateid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [newschema].[fetchcountry]    Script Date: 07-06-2023 12:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [newschema].[fetchcountry]
AS
BEGIN
    SELECT ROW_NUMBER() OVER (ORDER BY countryname ASC) rno,
           SPACE(0) [aed],
           countryid,
           countryname
    FROM newschema.country;
END;

--update newschema.country
--set countryname = 'Japan'
--where countryid = 2
GO
/****** Object:  StoredProcedure [newschema].[fetchstates]    Script Date: 07-06-2023 12:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [newschema].[fetchstates]
AS
BEGIN
    SELECT ROW_NUMBER() OVER (ORDER BY s.statename ASC) rno,
           SPACE(0) [aed],
           s.stateid,
           s.statename,
           s.countryid,
           c.countryname
    FROM newschema.states s
        INNER JOIN newschema.country c
            ON s.countryid = c.countryid;
END;
GO
/****** Object:  StoredProcedure [newschema].[modifycountry]    Script Date: 07-06-2023 12:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [newschema].[modifycountry]
(
    @countryid INT = -1,
    @countryname NVARCHAR(500) NULL,
    @aed CHAR(1) = 'E'
)
AS
BEGIN
    DECLARE @errorcode VARCHAR(5) = NULL,
            @msg VARCHAR(100) = NULL;
    BEGIN TRANSACTION;
    IF @aed = 'A'
    BEGIN
        INSERT INTO newschema.country
        (
            countryname
        )
        VALUES
        (ISNULL(@countryname, ''));
        IF @@ERROR = 0
           AND @@ROWCOUNT = 1
        BEGIN
            SET @errorcode = 'D101';
            SET @msg = 'Country Added Successfully';
        END;
    END;
    ELSE IF @aed = 'E'
    BEGIN
        IF EXISTS
        (
            SELECT 1
            FROM newschema.country c
            WHERE c.countryid <> @countryid
                  AND c.countryname = @countryname
        )
        BEGIN
            SET @errorcode = 'D104';
            SET @msg = 'Country Already Exists';
        END;
        ELSE
        BEGIN
            UPDATE c
            SET c.countryname = ISNULL(@countryname, '')
            FROM newschema.country c
            WHERE c.countryid = @countryid;
            IF @@ERROR = 0
               AND @@ROWCOUNT = 1
            BEGIN
                SET @errorcode = 'D102';
                SET @msg = 'Country Update Successfully';
            END;
        END;
    END;
    ELSE IF @aed = 'D'
    BEGIN
        IF NOT EXISTS
        (
            SELECT *
            FROM newschema.country c
                INNER JOIN newschema.states s
                    ON s.countryid = c.countryid
            WHERE c.countryid = @countryid
        )
        BEGIN
            DELETE c
            FROM newschema.country c
            WHERE c.countryid = @countryid;
            IF @@ERROR = 0
               AND @@ROWCOUNT = 1
            BEGIN
                SET @errorcode = 'D103';
                SET @msg = 'Country Deleted Successfully';
            END;
        END;
		ELSE
        BEGIN
             SET @errorcode = 'D103';
                SET @msg = 'State Exists for the Country';
        END
    END;
    IF @errorcode IN ( 'D101', 'D102', 'D103' )
        COMMIT;
    ELSE
        ROLLBACK;

    SELECT @errorcode [code],
           @msg [msg];
--SELECT ROW_NUMBER() OVER (ORDER BY countryname ASC) rno,
--       @aed [aed],
--       countryid,
--       countryname
--FROM newschema.country;
END;
GO
/****** Object:  StoredProcedure [newschema].[modifystates]    Script Date: 07-06-2023 12:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [newschema].[modifystates]
(
    @stateid INT = -1,
    @countryid INT,
    @statename NVARCHAR(500) NULL,
    @aed CHAR(1) = 'E'
)
AS
BEGIN
    DECLARE @errorcode VARCHAR(5) = SPACE(0),
            @msg VARCHAR(100) = SPACE(0);
    BEGIN TRANSACTION;
    IF @aed = 'A'
    BEGIN
        INSERT INTO newschema.states
        (
            statename,
            countryid
        )
        VALUES
        (ISNULL(@statename, ''), @countryid);
        IF @@ERROR = 0
           AND @@ROWCOUNT = 1
        BEGIN
            SET @errorcode = 'D101';
            SET @msg = 'State Added Successfully';
        END;
    END;
    ELSE IF @aed = 'E'
    BEGIN
        IF EXISTS
        (
            SELECT 1
            FROM newschema.states c
            WHERE c.stateid <> @stateid AND c.countryid = @countryid
                  AND c.statename = @statename
        )
        BEGIN
            SET @errorcode = 'D104';
            SET @msg = 'State Already Exists';
        END;
        ELSE
        BEGIN
            UPDATE c
            SET c.statename = ISNULL(@statename, ''),
                c.countryid = @countryid
            FROM newschema.states c
            WHERE c.stateid = @stateid;
            IF @@ERROR = 0
               AND @@ROWCOUNT = 1
            BEGIN
                SET @errorcode = 'D102';
                SET @msg = 'State Updated Successfully';
            END;
        END;
    END;
    ELSE IF @aed = 'D'
    BEGIN
        DELETE c
        FROM newschema.states c
        WHERE c.stateid = @stateid;
        IF @@ERROR = 0
           AND @@ROWCOUNT = 1
        BEGIN
            SET @errorcode = 'D103';
            SET @msg = 'State Deleted Successfully';
        END;
    END;
    IF @errorcode IN ( 'D101', 'D102', 'D103' )
        COMMIT;
    ELSE
        ROLLBACK;

    SELECT @errorcode [code],
           @msg [msg];

--SELECT ROW_NUMBER() OVER (ORDER BY s.statename ASC) rno,
--       @aed [aed],
--       s.stateid,
--       s.statename,
--       s.countryid,
--       c.countryname
--FROM newschema.states s
--    INNER JOIN newschema.country c
--        ON c.countryid = s.countryid;
END;
GO
