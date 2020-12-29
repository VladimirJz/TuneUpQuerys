SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_InicializaHcontinuidad]
@quincena varchar(6), @id_emp varchar(MAX), @id_cia int
WITH EXEC AS CALLER
AS
begin 

  DECLARE @Xml AS XML  
  DECLARE @desde as datetime
  DECLARE @hasta as datetime
  SET @Xml = '<empleado>' + REPLACE(@id_emp, ',', '</empleado><empleado>') + '</empleado>';
  SET @desde = (select dbo.anioquincenatofecha(@quincena,0))
  SET @hasta = DATEADD (mi,-1,(select dbo.anioquincenatofecha(@quincena,1)))

               

  if  @id_emp = '0'
    begin
    
     Delete from h from Hcontinuidad h with(nolock)
     inner join empleados ee with(nolock) on ee.id_emp = h.id_emp
     where h.añoqna = @quincena  and h.Id_emp = Case When @id_emp = '0' Then h.Id_emp else @id_emp End and ee.id_cia =  @id_cia  
      
     insert into Hcontinuidad (id_emp,id_plaza,id_plazaanterior,statusplaza,tipoplaza,TipoPlazaPermisoAnterior,categoria,MotivoMov,horas,añoqna,añoQnaContinuidad )
     select id_emp,id_plaza,id_plazaanterior,statusplaza,tipoplaza,TipoPlazaPermisoAnterior,categoria,MotivoMov,horas,añoqna, AñoQnacontinuidad                   
     from spc_BasePeriodo(@desde,@hasta,@id_emp, @id_cia ) 
     Where  Id_emp = Case When @id_emp = 0 Then Id_emp else @id_emp End      
    end
  else
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
