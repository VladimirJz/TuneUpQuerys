-- 
-- Creamos Objetos Adicionales Necesarios para optimizar el acceso a los DATA_COMPRESSION
-- 


-- Para no trabajar evaluando Varchars que en realidad representan fechas o un periodo de fecha determinado, creamos un
-- catalogo de Año quincena con la información que vamos a requerir.
drop table if exists TMPQUINCENAS
create Table TMPQUINCENAS
(
    AnioQuincena varchar(6),
    Anio int,
    Quincena int
)

-- Nota la letra Ñ no es un caracter ASCII standar su uso se restringe en casi todos los lenguajes de programación para codificación 
-- y declaración de objetos
insert into TMPQUINCENAS(AnioQuincena)
        select distinct AñoQna from Hcontinuidad
        OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE')) --  5s

-- ### IMPORTANTE #####
-- select * from Hcontinuidad where añoQnaContinuidad='2501' -- Existen registros con AñoQnaContinuidad = 2501 ?? que significa
-- para la prueba cambia  la columna usada a a AñoQna
-- se podria crear dinamicamente las N quincenas a futuro necesarias, para el ejemplo usaremos solo las ya existentes.

-- obtenemos el mes y año referenciado con el string
update TMPQUINCENAS set Anio=SUBSTRING(AnioQuincena,1,4),Quincena=SUBSTRING(AnioQuincena,5,2)  -- 181 rows

select * from TMPQUINCENAS -- anio/quincena
--
-- y ahora creamos la tabla  catálogo que seria permanente.

drop table if exists CATANIOQUINCENA
CREATE TABLE CATANIOQUINCENA
(
  AnioQuincenaID int IDENTITY(1,1) PRIMARY KEY, -- usaremos un auto incremental, de maner particular me parece mas mejor controlat todos los 
  AnioQuincena  varchar(6),                     -- ID's del sistema con rutinas  de alta y baja, pero para el ejemplo esta bien.
  Anio          int,
  Mes           int,
  Quincena      int,
  Desde         date,
  Hasta         date
)


insert into CATANIOQUINCENA (AnioQuincena,Anio,Quincena,Mes)
  select AnioQuincena,Anio,Quincena,(Quincena-(Quincena /2))Mes  from TMPQUINCENAS order by Anio asc, Quincena asc

-- Calculamos las fechas desde / hasta
update  CATANIOQUINCENA set Desde = DATEFROMPARTS(Anio,Mes,((case when Quincena % 2 = 1 then 1 else 16 end )))
update  CATANIOQUINCENA set Hasta = (case when Quincena % 2 = 1 then DATEFROMPARTS(Anio,Mes,15) else  EOMONTH(Desde) end)

select * from CATANIOQUINCENA -- Catalogo de quincenas hasta el 2020

-- ahora hacemos una copia de la tabla Hcontinuidad  y sobre ella hacemos  ajustes en su estructura.
-- como no sabemos si un cambio en los tipos de datos /longitudes puede afectar la operación del sistema u otras 
-- aplicaciones, solo agregamos columnas nuevas ya que es menos intrusivo

-- creamos una copia de la tabla para pruebas "Hcontinuidad_test"

drop table if exists  Hcontinuidad_test
select  * into Hcontinuidad_test   
     from Hcontinuidad
    OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE')) --   12ss



select count(*) from HContinuidad
select count(*) from Hcontinuidad_test
-- agregamos campos

ALTER TABLE [dbo].[Hcontinuidad_test]
    ADD 
        AnioQnaID          int not null default 0 , 
        AnioQnaContID      int not null default 0,
        AnioQnaContAgID    int not null default 0;

select top 100 * from Hcontinuidad_test

-- y ahora actualizamos los valores correspondientes
select * from  CATANIOQUINCENA

update hcon
set  hcon.AnioQnaID=cat.AnioQuincenaID
from 
Hcontinuidad_test hcon inner join  CATANIOQUINCENA cat
on  hcon.AñoQna=cat.AnioQuincena
OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE')) --  3m 12ss


DECLARE @count INT;
DECLARE @AnioQuincena varchar(6)

SET @count=(select count(*)from CATANIOQUINCENA)

WHILE @count > 0
BEGIN
    set @AnioQuincena=(select AnioQuincena from CATANIOQUINCENA where AnioQuincenaID=@count)
    print + @AnioQuincena
    -- Anio quincena
    update hcon
    set  hcon.AnioQnaID=@count
    from 
    Hcontinuidad_test hcon
    where  hcon.AñoQna=@AnioQuincena
    OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE')) 
                                                        
    -- Anio quincena continuidad
    update hcon
    set  hcon.AnioQnaContID=@count
    from 
    Hcontinuidad_test hcon
    where  hcon.añoQnaContinuidad=@AnioQuincena
    OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE')) 
    
    -- Anio quincena continuidad Aguinaldo
    update hcon
    set  hcon.AnioQnaContAgID=@count
    from 
    Hcontinuidad_test hcon
    where  hcon.ContinuidadAguinaldo=@AnioQuincena
    OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE')) 
              
    --  de 110,000 a 113,000 aprox x registro por AnioQuincena por Update

    SELECT @count = @count-1

END -- 29 m para actualizar todos los datos 20,668,363
    -- en un proceso que solo se ejecutara una vez

select count(*)  from Hcontinuidad_test 


--le creamos indices a las columnas que utilizaremos 
CREATE CLUSTERED INDEX [idx_AnioQnaId] ON [dbo].[Hcontinuidad_test]
(
	[AnioQnaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


CREATE INDEX idxAnioQnaID on Hcontinuidad_test(AnioQnaID)
CREATE INDEX idxAnioQnaContID on Hcontinuidad_test(AnioQnaContID) 


select * from CATANIOQUINCENA;
select top 1000 * from  Hcontinuidad_test 


    exec sp_help Hcontinuidad_test

    USE [IEEPO29JUL]
GO

/****** Object:  Index [idx_continuidad_añoqna]    Script Date: 20/11/2020 16:40:59 ******/
DROP INDEX [idx_continuidad_añoqna] ON [dbo].[Hcontinuidad_test] WITH ( ONLINE = OFF )
GO


USE [IEEPO29JUL]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [idx_continuidad_añoqna]    Script Date: 20/11/2020 16:42:23 ******/

-- Creamos una copia de la estructura de Hcontinuidad para nuestro ejemplo Hcontinuidad_test
USE [IEEPO29JUL]
GO

/****** Object:  Table [dbo].[Hcontinuidad_test]    Script Date: 23/11/2020 7:00:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- #Nota 2: creamos una tbla de trabajo para no trabajar sobre Hcontinuidad

CREATE TABLE [dbo].[TMPANALIZAHCONTINUIDAD](
	[id_emp] [int] NULL,
	[id_plaza] [int] NULL,
	[id_plazaanterior] [varchar](200) NULL,
	[statusplaza] [char](2) NULL,
	[tipoplaza] [char](3) NULL,
	[categoria] [char](10) NULL,
	[MotivoMov] [char](4) NULL,
	[horas] [int] NULL,
	[añoqna] [char](6) NULL,
	[añoQnaContinuidad] [char](6) NULL,
	[TipoPlazaPermisoAnterior] [char](2) NULL,
	[ContinuidadAguinaldo] [varchar](6) NULL,
	[AnioQnaID] [int] NULL DEFAULT 0,
	[AnioQnaContID] [int] NULL DEFAULT 0,
	[AnioQnaContAgID] [int] NULL DEFAULT 0
) ON [PRIMARY]
GO



DROP INDEX idxAnioQnaContID   
    ON TMPANALIZAHCONTINUIDAD;  
GO  


CREATE INDEX idxAnioQnaID_emp_plaza_inc on TMPANALIZAHCONTINUIDAD(AnioQnaID,id_emp,id_plaza) include (tipoplaza,statusplaza,categoria)
CREATE INDEX idxemp on TMPANALIZAHCONTINUIDAD(id_emp)
CREATE  INDEX idxAnioQnaContID_incl ON TMPANALIZAHCONTINUIDAD ([AnioQnaContID]) INCLUDE ([id_emp],[id_plaza],[id_plazaanterior],[statusplaza],[tipoplaza])
GO


-- omitimos la creación del cluster index

CREATE INDEX idxAnioQnaID on TMPANALIZAHCONTINUIDAD(AnioQnaID)
CREATE INDEX idxAnioQnaContID on TMPANALIZAHCONTINUIDAD(AnioQnaContID) 

-- datos de la continuidad Anterior

CREATE TABLE [TMPCONTINUIDADANT](
	[id_emp] [int] NULL,
	[id_plaza] [int] NULL,
	[id_plazaanterior] [varchar](200) NULL,
	[statusplaza] [char](2) NULL,
	[tipoplaza] [char](3) NULL,
	[categoria] [char](10) NULL,
	[MotivoMov] [char](4) NULL,
	[horas] [int] NULL,
	[añoqna] [char](6) NULL,
	[añoQnaContinuidad] [char](6) NULL,
	[TipoPlazaPermisoAnterior] [char](2) NULL,
	[ContinuidadAguinaldo] [varchar](6) NULL,
	[AnioQnaID] [int] NULL DEFAULT 0,
	[AnioQnaContID] [int] NULL DEFAULT 0,
	[AnioQnaContAgID] [int] NULL DEFAULT 0
) ON [PRIMARY]
GO

-- omitimos la creación del cluster index

DROP INDEX idxAnioQnaID_emp_plaza_inc   
    ON TMPCONTINUIDADANT;  
GO  


CREATE INDEX idxAnioQnaID_emp_plaza_inc on TMPCONTINUIDADANT(AnioQnaID,id_emp,id_plaza) include (tipoplaza,statusplaza,categoria)
-- CREATE INDEX idxEmpl_Plaza on TMPCONTINUIDADANT(id_emp,id_plaza) include (statusplaza,tipoplaza,categoria)
-- CREATE INDEX idxAnioQnaID_emp_plaza_inc on TMPCONTINUIDADANT(AnioQnaID,id_emp,id_plaza) include (statusplaza,tipoplaza,categoria)

CREATE INDEX idxAnioQnaContID on TMPCONTINUIDADANT(AnioQnaContID) 

