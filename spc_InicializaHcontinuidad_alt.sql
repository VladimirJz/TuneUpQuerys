SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_InicializaHcontinuidad]
             @quincena varchar(6), 
             @id_emp varchar(MAX), 
             @id_cia int

WITH EXEC AS CALLER
AS
begin 



  DECLARE @Xml AS XML  
  -- DECLARE @desde as datetime
  -- DECLARE @hasta as datetime
  SET @Xml = '<empleado>' + REPLACE(@id_emp, ',', '</empleado><empleado>') + '</empleado>';
  -- SET @desde = (select dbo.anioquincenatofecha(@quincena,0))
 --  SET @hasta = DATEADD (mi,-1,(select dbo.anioquincenatofecha(@quincena,1)))


-- lamada Stored exec spc_InicializaHcontinuidad '202001', 0, 2
/*
 DECLARE  @quincena varchar(6)='202001'
 DECLARE  @id_emp varchar(MAX)= '0'
 DECLARE  @id_cia int=2*/

DECLARE @desde as date
DECLARE @hasta as date
DECLARE @AnioQuincenaID int -- ahora utilizaremos un ID entero mucho mas eficiente que un string
-- omitimos el uso de funciones inecesarias, ahora consutamos directamente el catalogo
-- SET @desde = (select dbo.anioquincenatofecha(@quincena,0))
-- SET @hasta = DATEADD (mi,-1,(select dbo.anioquincenatofecha(@quincena,1)))
DECLARE @Cadena_Vacia varchar(1)
SET @Cadena_Vacia=''

select  @AnioQuincenaID=AnioQuincenaID,@desde=Desde,@hasta= Hasta   from CATANIOQUINCENA where AnioQuincena=@quincena
select  @desde,@hasta,@AnioQuincenaID    

 if  @id_emp = '0'
    begin
    
     /*Delete from h from Hcontinuidad_test h with(nolock)
     inner join empleados ee with(nolock) on ee.id_emp = h.id_emp
     where h.añoqna = @quincena  and h.Id_emp = Case When @id_emp = '0' Then h.Id_emp else @id_emp End and ee.id_cia =  @id_cia  */
     -- verificamos cuantos registros afecta
     --*    select * from  Hcontinuidad_test h with(nolock)
     --*    inner join empleados ee with(nolock) on ee.id_emp = h.id_emp
     --*   where h.añoqna = @quincena  and h.Id_emp = Case When @id_emp = '0' Then h.Id_emp else @id_emp End and ee.id_cia =  @id_cia  
     -- 111,847 rows 36 s (El Select)
     -- ahora con la tabla reconstruida


    --      select * from  Hcontinuidad_test h 
    --      inner join empleados e on e.id_emp = h.id_emp
    --      where h.AnioQnaID=@AnioQuincenaID  and e.id_cia =  @id_cia
    
     
    -- reemplazamos el delete..
    /*Delete from h from Hcontinuidad_test h with(nolock)
     inner join empleados ee with(nolock) on ee.id_emp = h.id_emp
     where h.añoqna = @quincena  and h.Id_emp = Case When @id_emp = '0' Then h.Id_emp else @id_emp End and ee.id_cia =  @id_cia  */

    -- BEGIN TRANSACTION
    -- # se borra la información original (previa)
    delete h from  Hcontinuidad_test h 
    inner join empleados e on e.id_emp = h.id_emp
     where h.AnioQnaID=@AnioQuincenaID  and e.id_cia =  @id_cia  --6s []
    -- ROLLBACK
     
     -- truncamos la tabla de paso
   truncate table TMPANALIZAHCONTINUIDAD

     -- el case when @id_emp=0 no tiene sentido puesto que se esta  controladndo desde  en el IF de arriba
    -- y h.Id_emp  siempre sera igual que h.Id_emp
    -- por que el uso de spc_BasePeriodo ? 
    --          select  * from spc_BasePeriodo(@desde,@hasta,@id_emp, @id_cia )  -- 111,847 registros, 40 s
    -- de manera personal sugiero optar por alternativas de SQL ANSI
    -- vamos a usar la tabla generada, pero ese código siento que tambien se puede mejorar
      
     insert into TMPANALIZAHCONTINUIDAD (id_emp,                     id_plaza,   id_plazaanterior,   statusplaza,    tipoplaza,
                                    TipoPlazaPermisoAnterior,   categoria,  MotivoMov,          horas,          añoqna,
                                    añoQnaContinuidad )
                            select id_emp,                     id_plaza,       id_plazaanterior,   statusplaza,    tipoplaza,
                                    TipoPlazaPermisoAnterior,   categoria,      MotivoMov,          horas,          añoqna, 
                                    @Cadena_Vacia                   
                            from spc_BasePeriodo(@desde, @hasta, @id_emp, @id_cia ) 


     -- mismo caso que arriba con el case when 
     -- Where  Id_emp = Case When @id_emp = 0 Then Id_emp else @id_emp End    

     --#Nota2 : En lugar de trabajar con la tabla Hcontinuidad, usaremos una tabla difernte para hacer todos los calculos al finalizar
     --  solamente se hara un insert, nos ahorramos el insert +  N cantidad de update's sobre la tabla transaccional.
     -- como se esta seteando  en AnalizaContinuidad 'añoqnacontinuidad' a Vacio entonces simplemente lo inserto vacio, uso uno
     -- constante @Cadena_Vacia p


     -- 
    end
  else -- EL CASO DE UN EMPLEADO ESPECIFICO  NO SE REVISó
    begin
    
     Delete from h from Hcontinuidad h with(nolock)
     inner join empleados ee with(nolock) on ee.id_emp = h.id_emp
     where h.añoqna = @quincena  
     and h.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n)) 
     and ee.id_cia = @id_cia
      
     insert into Hcontinuidad (id_emp,id_plaza,id_plazaanterior,statusplaza,tipoplaza,TipoPlazaPermisoAnterior,categoria,MotivoMov,horas,añoqna,añoQnaContinuidad )
     select id_emp,id_plaza,id_plazaanterior,statusplaza,tipoplaza,TipoPlazaPermisoAnterior,categoria,MotivoMov,horas,añoqna, AñoQnacontinuidad                   
     from spc_BasePeriodo(@desde,@hasta,@id_emp, @id_cia ) 
     Where  Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
    end
          
end
GO
