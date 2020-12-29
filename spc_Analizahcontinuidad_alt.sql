SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- CREATE PROCEDURE [dbo].[spc_Analizahcontinuidad]
--@Qna varchar(6), @idEmp varchar(MAX), @id_cia int
-- WITH EXEC AS CALLER
-- AS
-- begin                  
 
 
 
DECLARE @Xml AS XML  
SET @Xml = '<empleado>' + REPLACE(@idEmp, ',', '</empleado><empleado>') + '</empleado>';                 

-- usaremos variables de otro tipo de datos enbase a los cambios ya realizados.                   
DECLARE @desde as date
DECLARE @hasta as date
DECLARE @AnioQuincenaID int 
DECLARE @AnioQuincenaAntID int
DECLARE @Entero_uno int=1
DECLARE @Entero_cero int=0

-- parametros 
 DECLARE  @Qna varchar(6)='202001'
 DECLARE  @id_emp varchar(MAX)= '0'
 DECLARE  @id_cia int=2

SET @AnioQuincenaAntID=((select AnioQuincenaID from CATANIOQUINCENA where AnioQuincena=@Qna)-@Entero_uno) -- 157


-- Nos enfocaremos en la sección de código para todos los empleados
if @idEmp = '0'
begin
/** estos son los parametros que recibimos*/
DECLARE  @Qna VARCHAR(6) = '202001'
DECLARE @idEmp varchar(MAX)='0'
DECLARE @id_cia int=2
/* - -- - - - - - - - - - - - */

-- para todos los empleados
-- Esta consulta lo que hace es borrar el valor previo de añoqnacontinuidad en Hcontinuidad ?
-- un update en una tabla tan grande siempre es muy costoso, mas si no se usan los indices adecuados
-- se pudo inserta el valor en 'cadena vacio' desde el insert de InicializaContinuidad
-- o mejor aun, no se debio hacer el insert directo a Hcontinuidad hasta que todos los valores estuvieran calculados.
-- #Nota 2: se hace al cambio de la tabla Hcontinuidad a una de paso
-- no requerimos esta parte del código
/*
update Hcontinuidad set añoqnacontinuidad = '      '
from Hcontinuidad with(nolock) inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where añoqna = @Qna 
--and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End                    
and e.id_cia = @id_cia */


-- Las Reglas de negocio estan 'quemadas' en el código fuente, eso hace el código poco dinamico y dificil de mantener !


--primero actualizo la continuidad de las plazas que no tienen plazaanterior ,que ya se pagaron la quincena pasada y siguen igual          
-- en tipo, status y categoria        

-- creo una tabla para extraer los datos que voy a ocupar, la tabla la reutilizare en todo el procedimiento
-- y se eliminara al final del mismo, no uso tablas temporales por que no son muy eficientes para grandes volumenes 
-- de datos




DECLARE @desde as date
DECLARE @hasta as date
DECLARE @AnioQuincenaID int 
DECLARE @AnioQuincenaAntID int
DECLARE @Entero_uno int=1
-- parametros 
 DECLARE  @Qna varchar(6)='202001'
 DECLARE  @id_emp varchar(MAX)= '0'
 DECLARE  @id_cia int=2

SET @AnioQuincenaAntID=((select AnioQuincenaID from CATANIOQUINCENA where AnioQuincena=@Qna)-@Entero_uno) -- 157


INSERT INTO TMPCONTINUIDADANT ([id_emp] ,                   [id_plaza],             [id_plazaanterior],   [statusplaza],      [tipoplaza], 

                              [categoria],                  [MotivoMov],            [horas],              [añoqna],           [añoQnaContinuidad],
                              [TipoPlazaPermisoAnterior],   [ContinuidadAguinaldo], [AnioQnaID],          [AnioQnaContID],    [AnioQnaContAgID])
        
          select  id_emp ,                   id_plaza,             id_plazaanterior,     statusplaza,      tipoplaza, 
                  categoria,                  MotivoMov,            horas,                añoqna,           añoQnaContinuidad,
                  TipoPlazaPermisoAnterior,   ContinuidadAguinaldo, AnioQnaID,            AnioQnaContID,    AnioQnaContAgID
          from Hcontinuidad_test where AnioQnaID=@AnioQuincenaAntID -- 112,610  3s




/* CONSULTA ORIGINAL */ /*
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad  with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and Hcontinuidad.id_plaza = b.id_plaza 
inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and Hcontinuidad.id_plazaanterior = '' and          
Hcontinuidad.statusplaza = b.statusplaza and Hcontinuidad.tipoplaza = b.tipoplaza and           
Hcontinuidad.categoria = b.categoria 
--      --and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End             
and e.id_cia = @id_cia -- 111,591 registros*/
/* TERMINA CONSULTA ORIGINAL */


UPDATE act SET  act.añoQnaContinuidad = ant.añoQnaContinuidad , act.AnioQnaContID=ant.AnioQnaContID
FROM 
  TMPCONTINUIDADANT ant inner join (
  TMPANALIZAHCONTINUIDAD act  inner join  Empleados emp on act.id_emp=emp.Id_Emp)
  on act.id_emp=ant.id_emp and act.id_plaza=ant.id_plaza and act.statusplaza=ant.statusplaza 
  and act.tipoplaza=ant.tipoplaza and act.categoria=ant.categoria
WHERE act.id_plazaanterior='' and emp.id_cia=@id_cia -- 111,591   -  <1 s


/* CONSULTA ORIGINAL */ /*
-- #actualizo la continuidad de las plazas que no tienen plazaanterior (o es la misma ),que ya se pagaron la quincena pasada y cambiaron          
-- #cierto tipo o status ( proporcionados por ellos ) que no deberia de cambiar continuidad          
/*update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and Hcontinuidad.id_plaza = b.id_plaza   
inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and  Hcontinuidad.añoQnaContinuidad = '' and       
(Hcontinuidad.id_plazaanterior = cast(b.id_plaza as varchar) or Hcontinuidad.id_plazaanterior = '' ) and          
((Hcontinuidad.statusplaza = 10 and Hcontinuidad.tipoplaza  in (44,48) ) or      
(Hcontinuidad.statusplaza = 14 and Hcontinuidad.tipoplaza  = 44 ) or       
(Hcontinuidad.statusplaza = 15 and Hcontinuidad.tipoplaza  = 48 ) or      
(Hcontinuidad.statusplaza = 11 and Hcontinuidad.tipoplaza  = 44 ) ) 
--and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End            
and e.id_cia = @id_cia*/   -- 0 rows 
/* TERMINA CONSULTA ORIGINAL */


-- TMPANALIZAHCONTINUIDAD solo tiene registros de la AnioQuincena seleccionada
-- TMPCONTINUIDADANT tiene registros de la AnioQuincena anterior
-- Evaluo AnioQnaContID en lugar del varchar !!
-- Los valores de Status Plaza u Tipo Plaza del Where aun se pueden controlar de otra forma
-- para el ejemplo los dejaremos asi.


UPDATE act SET  act.añoQnaContinuidad = ant.añoQnaContinuidad , act.AnioQnaContID=ant.AnioQnaContID
FROM 
  TMPCONTINUIDADANT ant inner join (
  TMPANALIZAHCONTINUIDAD act  inner join  Empleados emp on act.id_emp=emp.Id_Emp)
  on act.id_emp=ant.id_emp and act.id_plaza=ant.id_plaza 
WHERE act.AnioQnaContID=@Entero_cero
AND (act.id_plazaanterior=ant.id_plaza or act.id_plazaanterior='') 
AND
  ((act.statusplaza = 10 and act.tipoplaza  in (44,48) ) or      
  (act.statusplaza = 14 and act.tipoplaza  = 44 ) or       
  (act.statusplaza = 15 and act.tipoplaza  = 48 ) or      
  (act.statusplaza = 11 and act.tipoplaza  = 44 ) ) 
AND emp.id_cia=@id_cia -- 0 rows 








--Si la plaza aun tiene añoqnacontinuidad vacio Y NO TIENE ID_PLAZAANTERIOR                  
--significa que la plaza es nueva, asi que la continuidad empieza a partir de este momento                  
Update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = Hcontinuidad.añoqna  
from Hcontinuidad with(nolock) inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and Hcontinuidad.añoQnaContinuidad = ''                   
and Hcontinuidad.id_plazaanterior = '' 
--and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End                           
and e.id_cia = @id_cia

--Si la plaza tiene en plaza anterior LA MISMA PLAZA                   
--y el status01/tipoplaza95  en la plazaanterior de la qna pasada                  
--y un status01/tipoplaza10 en la plazaactual                  
--eso significa que le dieron definitivamente la plaza y debe mantener continuidad                  
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and b.id_plaza=Hcontinuidad.id_plaza   
inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and (Hcontinuidad.id_plazaanterior = cast(Hcontinuidad.id_plaza as varchar) or Hcontinuidad.id_plazaanterior = ''  )                
and Hcontinuidad.statusplaza = 01 and  Hcontinuidad.tipoplaza = 10                  
and b.statusplaza = 01 and  b.tipoplaza = 95  
--and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End                          
and e.id_cia = @id_cia
                  
--Si la plaza tiene en plaza anterior LA MISMA PLAZA                   
--y no cambia ni el tipo,ni el status,ni lacategoria                  
--eso significa que debe mantener continuidad                  
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + Hcontinuidad.id_plazaanterior + ',') <> 0   
inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and charindex(','+ ltrim(rtrim(cast(hcontinuidad.id_plaza  as varchar))) + ',',',' + Hcontinuidad.id_plazaanterior + ',') <> 0            
and Hcontinuidad.statusplaza = b.statusplaza and  Hcontinuidad.tipoplaza = b.tipoplaza                  
and Hcontinuidad.categoria = b.categoria  
-- and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End                           
and e.id_cia = @id_cia

--Si la plaza NO tiene en plaza anterior                   
--y un status14/tipoplaza41-42-43-49 ó status06/tipoplaza51-52-53 en la plazaactual                 
--eso significa que debe perder continuidad                  
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = añoQna  
from Hcontinuidad with(nolock) inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where ((Hcontinuidad.statusplaza = 14 and Hcontinuidad.tipoplaza in (41,42,43,49)) or                 
(Hcontinuidad.statusplaza = 06 and Hcontinuidad.tipoplaza in (51,52,53)))                
 and Hcontinuidad.añoqna = @Qna  
-- and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End                        
and e.id_cia = @id_cia

--Si en la qna anterior                 
--el status14/tipoplaza41-42-43-49 ó status06/tipoplaza51-52-53  en la plazaanterior de la qna pasada                  
--y un status01/tipoplaza95 en la plazaactual                 
--eso significa viene regresando de una licencia   y debe iniciar la continuidad                  
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = Hcontinuidad.añoQna                 
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and Hcontinuidad.id_plaza = b.id_plaza
inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and                
((b.statusplaza = 14 and b.tipoplaza in (41,42,43,49)) or                 
(b.statusplaza = 06 and b.tipoplaza in (51,52,53)))                  
and Hcontinuidad.statusplaza = 01 and  Hcontinuidad.tipoplaza = 95  
-- and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End                          
and e.id_cia = @id_cia

--Si tiene PLAZAANTERIOR pero el status y el motivo es el mismo que el actual            
--debe de tomar la continuidad de la plaza anterior            
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + Hcontinuidad.id_plazaanterior + ',') <> 0 
inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and Hcontinuidad.id_plazaanterior <> ''            
and Hcontinuidad.tipoplaza = b.tipoplaza and Hcontinuidad.statusplaza = b.statusplaza  
-- and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End             
and e.id_cia = @id_cia

--Si tiene PLAZAANTERIOR pero el status y el motivo de la nueva es 01-10            
-- y el status y motivo de la anterior es 01-95            
--debe de tomar la continuidad de la plaza anterior            
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B               
on Hcontinuidad.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + Hcontinuidad.id_plazaanterior + ',') <> 0            
inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and Hcontinuidad.id_plazaanterior <> ''            
and ((Hcontinuidad.tipoplaza = 10 and Hcontinuidad.statusplaza = 01 and b.tipoplaza = 95 and b.statusplaza = 01) or      
(Hcontinuidad.tipoplaza = 95 and Hcontinuidad.statusplaza = 01 and b.tipoplaza = 10 and b.statusplaza = 01) )   
-- and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End       
and e.id_cia = @id_cia      
-------------------------------------------         
--Si la plaza tiene en plaza anterior LA MISMA PLAZA                   
--y el status10,11,14,15/tipoplaza44,48  en la plazaanterior de la qna pasada                  
--y un status01/tipoplaza10,95 en la plazaactual                  
--eso significa que le dieron definitivamente la plaza y debe mantener continuidad                  
--update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
--from Hcontinuidad inner join ( Select * from Hcontinuidad where añoqna = @Qnaanterior) B                  
--on Hcontinuidad.id_emp = b.id_emp       
--where Hcontinuidad.añoqna = @Qna and       
--(Hcontinuidad.id_plazaanterior = cast(b.id_plaza as varchar) or Hcontinuidad.id_plazaanterior = '' )                 
--and Hcontinuidad.statusplaza = 01 and  Hcontinuidad.tipoplaza in (10,95)                  
--and b.statusplaza in (10,11,14,15) and  b.tipoplaza in (44,48)   and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End              
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and  Hcontinuidad.id_plaza = b.id_plaza 
inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and       
(Hcontinuidad.id_plazaanterior = cast(b.id_plaza as varchar) or Hcontinuidad.id_plazaanterior = '' )                 
and Hcontinuidad.statusplaza = 01 and  Hcontinuidad.tipoplaza in (10,95)                  
and b.statusplaza in (10,11,14,15) and  b.tipoplaza in (44,48)   
-- and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End           
and e.id_cia = @id_cia 

update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp  
inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and       
(Hcontinuidad.id_plazaanterior = cast(b.id_plaza as varchar) or Hcontinuidad.id_plazaanterior = '' )                 
and Hcontinuidad.statusplaza = 01 and  Hcontinuidad.tipoplaza in (10,95)                  
and b.statusplaza in (10,11,14,15) and  b.tipoplaza in (44,48)   
-- and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End           
and Hcontinuidad.id_emp in (select id_emp from Hcontinuidad where [añoqna] = @Qna and ([añoQnaContinuidad] = '' or [añoQnaContinuidad] = '      '  ) )
and e.id_cia = @id_cia 

--Si la plaza tiene en plaza anterior LA MISMA PLAZA                   
--y el status03,06/tipoplaza20  en la plazaanterior de la qna pasada                  
--y un status01/tipoplaza10,95 en la plazaactual                  
--eso significa que le dieron definitivamente la plaza y debe mantener continuidad                  
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + Hcontinuidad.id_plazaanterior + ',') <> 0  
inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and Hcontinuidad.id_plazaanterior = cast(Hcontinuidad.id_plaza as varchar)                  
and Hcontinuidad.statusplaza = 01 and  Hcontinuidad.tipoplaza in ( 10 , 95)                 
and b.statusplaza in (03,06) and  b.tipoplaza in (20) 
--and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End                           
and e.id_cia = @id_cia    

----Si la el tipo de plaza es de tipo prorroga
----Select * from ttipoplaza where destipoplaza like 'pró%'
----y el tipoplazapermisoanterior es distino de 48 o 44 entonces debe cortar continuidad
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = Hcontinuidad.añoQna                  
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp 
inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna                   
and Hcontinuidad.tipoplaza in (Select id_tipoplaza from ttipoplaza where destipoplaza like 'pró%')
and Hcontinuidad.tipoplazapermisoanterior not in (48,44)
--and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End                           
and e.id_cia = @id_cia 






-- Se agregan casos a cantinuidad 25/10/2016


-- los movimientos 1-96 deben de tomar la cntinuidad de la plaza anterior
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from hcontinuidad a  with(nolock)    
inner join ( Select * from Hcontinuidad with(nolock) where añoqna =  @Qnaanterior) b on b.id_emp = a.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.[añoqna]= @Qna
and a.statusplaza = 01 and a.tipoplaza = 96 and a.id_plazaanterior <> ''
--and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia    


-- la licencia 88 debe tomar la continuidad anterior 
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) 
inner join ( Select * from Hcontinuidad with(nolock) where añoqna =  @Qnaanterior) b on b.id_emp = a.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.[añoqna]= @Qna
and a.statusplaza = 14 and a.tipoplaza = 88 
--and a.Id_emp  in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia 

-- cuando regresa de licencia 88 debe permanecer su continuidad 
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a  with(nolock)
inner join ( Select * from Hcontinuidad with(nolock) where añoqna =  @Qnaanterior) b on b.id_emp = a.id_emp and a.id_plaza = b.id_plaza 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.[añoqna]= @Qna
and a.statusplaza = 01 and a.tipoplaza in (10,95,96) and b.statusplaza = 14 and b.tipoplaza = 88 
--and a.Id_emp  in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
 and e.id_cia = @id_cia 
 
-- cuando entra en licencia o reanudacion y continuia con la lic que cortan
update a set a.añoQnaContinuidad = a.añoqna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((a.statusplaza in ( 14,10) and a.tipoplaza in (41,43,49,40)) or                 
(a.statusplaza in ( 14,10) and a.tipoplaza in (51,53)))                  
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia   

 -- licencias y reanudas que cortan
update a set a.añoQnaContinuidad = a.añoqna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10) and b.tipoplaza in (41,43,49,40)) or                 
(b.statusplaza  in ( 14,10) and b.tipoplaza in (51,53)))                  
and a.statusplaza = 01 and  a.tipoplaza in( 95,10)  
--and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia   


update a set a.añoQnaContinuidad = a.añoqna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10) and b.tipoplaza in (41,43,49,40)) or                 
(b.statusplaza in ( 06,10,14) and b.tipoplaza in (51,53)))                  
and ((a.statusplaza in ( 14,10,15) and a.tipoplaza in (44,42,48)) or                 
(a.statusplaza in ( 14,10) and a.tipoplaza in (52)))
--and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia   

update a set a.añoQnaContinuidad = a.añoqna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10,15) and b.tipoplaza in (44,42,48)) or                 
(b.statusplaza in (14,10) and b.tipoplaza in (52)))                  
and ((a.statusplaza in ( 14,10) and a.tipoplaza in (41,43,49,40)) or                 
(a.statusplaza in ( 06,10,14) and a.tipoplaza in (51,53  )))
--and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia   




-- licencias que no pierden la continuidad -- 05052020 la lic 42 corta
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((a.statusplaza in ( 14,10,15) and a.tipoplaza in (44,48)) or                 
(a.statusplaza in ( 14,10,15) and a.tipoplaza in (52))) and 
((b.statusplaza in ( 14,10,15) and b.tipoplaza in (4,48)) or                 
(b.statusplaza in ( 14,10,15) and b.tipoplaza in (52)))
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia   

-- cuando regresa de una licencia que no debe cortar continuidad -- 05052020 la lic 42 corta
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza  in ( 14,10,15) and b.tipoplaza in (44,48)) or                 
(b.statusplaza in ( 14,10,15) and b.tipoplaza in (52)))                  
and ( (a.statusplaza = 01 and  a.tipoplaza in( 95,10,96)) or (a.statusplaza = 06 and  a.tipoplaza in(20)) )
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia   





-- plaza 6-20 que tuvieron otra plaza y esa plaza esta en 14-42 -- 05052020 la lic 42 corta
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
a.statusplaza = 06 and a.tipoplaza = 20
and b.statusplaza in( 14,10) and b.tipoplaza = 0
and a.id_plazaanterior <> ''
--and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia 

-- plaza 6-20 que tienen en la misma quincena la licencia 42

update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join (
  select h.* from Hcontinuidad h with(nolock) inner join (
  select a.id_emp, a.[añoqna], min(a.id_plaza) id_plaza
  from Hcontinuidad a with(nolock)
  inner join (
  Select id_emp, añoqna, min(añoqnacontinuidad) añoqnacontinuidad  from Hcontinuidad with(nolock) where añoqna = @Qnaanterior group by id_emp,añoqna
  ) b on a.id_emp = b.id_emp and a.[añoQnaContinuidad] = b.[añoQnaContinuidad] and a.[añoqna] = b.[añoqna]
  where a.[añoqna] = @Qnaanterior
  group by a.id_emp, a.[añoqna]
  ) m on m.id_emp = h.id_emp and m.id_plaza = h.id_plaza and m.añoqna = h.añoqna
) B                  
on a.id_emp = b.id_emp 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                   
a.statusplaza = 06 and a.tipoplaza in (20)                
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia  
and exists (
select 1 from Hcontinuidad h where h.id_emp = a.id_emp and h.[añoqna] = @Qna and h.statusplaza = 10 and h.tipoplaza = 42
)






-- movimientos 96 que tuvieron una baja 32 o 35 no cortan
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
inner join hplazas h with(nolock) on h.id_plaza = b.id_plaza and h.Id_TipoMovPlazas = 1 and h.Fecha = dbo.anioQuincenaToFecha(b.añoqna, 1) and h.Valor_IdCampo in (32,35)
where a.añoqna = @Qna  and a.id_plazaanterior <> ''                
and a.statusplaza = 01 and  a.tipoplaza = 96 
--and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia 


-- tenian una hija 6-20 y le dan una padre debe de tener continuidad 
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and a.id_plazaanterior <> '' 
and b.statusplaza = 06 and  b.tipoplaza = 20 
and a.statusplaza = 01 and a.tipoplaza in (95,10,96)
and a.categoria = b.categoria
and b.id_plaza in (select id_plaza from hplazas where Id_TipoMovPlazas = 4)
and a.id_plaza not in (select id_plaza from hplazas where Id_TipoMovPlazas = 4)
--and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia 



--de baja de 1-95-10 a 06-20

update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and  b.statusplaza in ( 01) and b.tipoplaza in (95,10,96)                
and a.statusplaza = 6 and  a.tipoplaza in( 20)  
--and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia



-- continuidad de regularizados se trunca si la plaza anterior no esta conciliada

update a set a.añoQnaContinuidad = a.añoQna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
inner join hplazas h with(nolock) on h.id_plaza = b.id_plaza and h.Id_TipoMovPlazas = 1 and h.Fecha = dbo.anioQuincenaToFecha(b.añoqna, 1) and h.Valor_IdCampo in (32)
where a.añoqna = @Qna  and a.id_plazaanterior <> ''                
and ((a.statusplaza = 01 and  a.tipoplaza = 95) or (a.statusplaza = 06 and  a.tipoplaza = 20)   )
--and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza in (select id_plaza from Thst_Plaza where Regularizada = 1)

update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
inner join hplazas h with(nolock) on h.id_plaza = b.id_plaza and h.Id_TipoMovPlazas = 1 and h.Fecha = dbo.anioQuincenaToFecha(b.añoqna, 1) and h.Valor_IdCampo in (32)
where a.añoqna = @Qna  and a.id_plazaanterior <> ''                
and ((a.statusplaza = 01 and  a.tipoplaza = 95) or (a.statusplaza = 06 and  a.tipoplaza = 20)   )
--and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)



-------------- queries nuevos movimientos


-- Si esta en 01 95-96-10 o 06 20 24 25 y pasa a motivo nuevo misma plaza mantiene continuidad
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 01) and b.tipoplaza in (95,96,10)) or                 
(b.statusplaza = 06 and b.tipoplaza in (20,24,25)))                  
and ( (a.statusplaza = 01 and  a.tipoplaza in( 111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 )) or -- '10','FV','FT','FZ','FW','FJ','FK','FS','FY','FJ','FI' 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) ) 
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)


-- Si esta en 01 95-96-10 o 06 20 24 25 y pasa a motivo nuevo OTRA PLAZA mantiene continuidad
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and a.id_plazaanterior <> '' and                
((b.statusplaza in ( 01) and b.tipoplaza in (95,96,10)) or                 
(b.statusplaza = 06 and b.tipoplaza in (20,24,25)))                  
and ( (a.statusplaza = 01 and  a.tipoplaza in( 111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151)) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) ) 
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1) 


-- si de nuevo movimiento regresa a 01 95-96-10 o 06 20 24 25 en la misma plaza continuia
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 01) and b.tipoplaza in (111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 )) or                 
(b.statusplaza = 06 and b.tipoplaza in (88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)))                  
and ( (a.statusplaza = 01 and  a.tipoplaza in(95,96,10 )) or 
(a.statusplaza = 06 and  a.tipoplaza in(20,24,25)) ) 
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)  


-- si de nuevo movimiento regresa a 01 95-96-10 o 06 20 24 25 en OTRA PLAZA continuia
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and a.id_plazaanterior <> '' and                
((b.statusplaza in ( 01) and b.tipoplaza in (111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151)) or                 
(b.statusplaza = 06 and b.tipoplaza in (88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)))                  
and (( a.statusplaza = 01 and  a.tipoplaza in( 95,96,10 )) or 
(a.statusplaza = 06 and  a.tipoplaza in(20,24,25)) ) 
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)  


-- de un nuevo movimiento a otro nuevo movimiento con las misma plaza
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 01) and b.tipoplaza in (111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151)) or                 
(b.statusplaza = 06 and b.tipoplaza in (88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)))                  
and (( a.statusplaza = 01 and  a.tipoplaza in(111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151  )) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) ) 
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1) 


-- de un nuevo movimiento a otro nuevo movimiento con OTRA plaza
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and a.id_plazaanterior <> '' and                
((b.statusplaza in ( 01) and b.tipoplaza in (111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 )) or                 
(b.statusplaza = 06 and b.tipoplaza in (88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)))                  
and (( a.statusplaza = 01 and  a.tipoplaza in( 111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151  ) ) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) ) 
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1) 





-- Si tiene nuevo movimiento y entra a lic 14-10 41-43-49-40 0 06 51-53 corta continuidad
 update a set a.añoQnaContinuidad = a.añoqna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 01) and b.tipoplaza in (111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 )) or                 
(b.statusplaza = 06 and b.tipoplaza in (88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)))                  
and (( a.statusplaza in (14,10) and  a.tipoplaza in(41,43,49,40)) or 
(a.statusplaza in (14,10) and  a.tipoplaza in(51,53)) )
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)   


-- si esta en lic 14-10 41-43-49-40 0 06 51-53 y le dan mov nuevo inicia su continuidad
 update a set a.añoQnaContinuidad = a.añoqna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10) and b.tipoplaza in (41,43,49,40 )) or                 
(b.statusplaza in (14,10) and b.tipoplaza in (51,53)))                  
and (( a.statusplaza in (01) and  a.tipoplaza in(111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 ) ) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) )
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)   


-- si tine plaza en licencia y le dan una con movimiento sdp
update a set a.añoQnaContinuidad =  b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join 
( Select * from Hcontinuidad with(nolock) where añoqna = @Qna
) B                  
on a.id_emp = b.id_emp 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10,15) and b.tipoplaza in (44,42,48,88 )) or                 
(b.statusplaza in ( 14,10,15) and b.tipoplaza in (52)))                  
and (( a.statusplaza in (01) and  a.tipoplaza in(113,115,116,123,124,125,126,131,132,147,148,150,151) ) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) )
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia =  @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)



-- si tiene un nuevo movimiento y entra el lic 14-10 44-42-48-88 o 06 52 continuia -- 05052020 quito la lic 42 ya que no continua
 update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 01) and b.tipoplaza in (111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151)) or                 
(b.statusplaza = 06 and b.tipoplaza in (88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)))                  
and (( a.statusplaza in ( 14,10,15) and  a.tipoplaza in(44,48,88)) or 
(a.statusplaza in ( 14,10,15) and  a.tipoplaza in(52)) )
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1) 



-- si regresa de lic 14-10 44-42-48-88 o 06 52 a un nuevo movimiento continua-- 05052020 quito la lic 42 ya que no continua
 update a set a.añoQnaContinuidad =  b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10,15) and b.tipoplaza in (44,48,88 )) or                 
(b.statusplaza in ( 14,10,15) and b.tipoplaza in (52)))                  
and (( a.statusplaza in (01) and  a.tipoplaza in(111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 ) ) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) )
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia =  @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)

-- 05052020 quito la lic 42 ya que no continua
 update a set a.añoQnaContinuidad =  b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10,15) and b.tipoplaza in (44,48,88 )) or                 
(b.statusplaza in ( 14,10,15) and b.tipoplaza in (52)))                  
and (( a.statusplaza in (01) and  a.tipoplaza in(111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 ) ) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) )
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia =  @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)



-- 23/11/2018 si esta en 6 15 y pasas a 6 -90-11 con otra plaza corta continuidad
update a set a.añoQnaContinuidad = a.añoQna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and (b.statusplaza = 06 and  b.tipoplaza in(15,103,137)) and
(a.statusplaza = 06 and  a.tipoplaza in(11,99,133,108,143,15,103,137))
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)




---- de 96 a 96-10 y al reves con diferente plaza continuan continuan
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and a.id_plazaanterior <> '' and                
((b.statusplaza in ( 01) and b.tipoplaza in (95,96,10)) )                  
and ( (a.statusplaza = 01 and  a.tipoplaza in( 95,96,10))) 
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1) 

update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 01) and b.tipoplaza in (95,96,10)) )                  
and ( (a.statusplaza = 01 and  a.tipoplaza in( 95,96,10))) 
-- and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1) 


--------------      
update Hcontinuidad set añoqnacontinuidad = añoqna 
from Hcontinuidad with(nolock) inner join Empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where añoqna = @Qna and añoqnacontinuidad = '      '   
--and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End                  
and e.id_cia = @id_cia 



-- para cambios de estado

-- lo comento para aguinaldo

--update h set h.añoqnacontinuidad = es.sep
--from hcontinuidad h
--inner join (
--select fd.Id_Emp, fdd.Id_Plaza, dbo.fechaToAnioQuincena(fdd.fechaini) qna, s.sep from FUP_Documentos fd
--inner join FUP_Documento_Detalle fdd on fd.Id_Documento = fdd.Id_Documento
--inner join FUP_Informacion_Documentos fid on fid.Id_Documento = fd.Id_Documento
--inner join FUP_MotivoMovimiento fmm on fmm.Id_MotivoMovimiento = fdd.Id_MotivoMovimiento
--inner join (
--  select a.id_emp, dbo.fechaToAnioQuincena(a.fecha_alta_sep) sep from HFecha_Alta_SEP a inner join (
--  select id_emp, max(fecha) fecha from HFecha_Alta_SEP where fecha <= getdate() group by id_emp
--  ) b on a.fecha = b.fecha and a.id_emp = b.id_emp
--) s on s.id_emp = fd.id_emp
--where fdd.Id_MotivoMovimiento = 1 and fmm.Id_TipoMovimiento = 2
--) es on es.id_emp = h.id_emp and es.id_plaza = h.id_plaza and es.qna = h.añoqna
--inner join empleados e on e.id_emp = h.id_emp
--where h.[añoqna] = @Qna and e.id_cia = @id_cia




end

else

begin

-- para empleados especificos

update Hcontinuidad set añoqnacontinuidad = '      ' 
from Hcontinuidad with(nolock) inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where añoqna = @Qna and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))     
and e.id_cia = @id_cia

--primero actualizo la continuidad de las plazas que no tienen plazaanterior ,que ya se pagaron la quincena pasada y siguen igual          
-- en tipo, status y categoria          
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B on Hcontinuidad.id_emp = b.id_emp and Hcontinuidad.id_plaza = b.id_plaza 
inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and Hcontinuidad.id_plazaanterior = '' and          
Hcontinuidad.statusplaza = b.statusplaza and Hcontinuidad.tipoplaza = b.tipoplaza and           
Hcontinuidad.categoria = b.categoria 
and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))             
and e.id_cia = @id_cia

--actualizo la continuidad de las plazas que no tienen plazaanterior (o es la misma ),que ya se pagaron la quincena pasada y cambiaron          
-- cierto tipo o status ( proporcionados por ellos ) que no deberia de cambiar continuidad          
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and Hcontinuidad.id_plaza = b.id_plaza  
inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and  Hcontinuidad.añoQnaContinuidad = '' and       
(Hcontinuidad.id_plazaanterior = cast(b.id_plaza as varchar) or Hcontinuidad.id_plazaanterior = '' ) and          
((Hcontinuidad.statusplaza = 10 and Hcontinuidad.tipoplaza  in (44,48) ) or      
(Hcontinuidad.statusplaza = 14 and Hcontinuidad.tipoplaza  = 44 ) or       
(Hcontinuidad.statusplaza = 15 and Hcontinuidad.tipoplaza  = 48 ) or      
(Hcontinuidad.statusplaza = 11 and Hcontinuidad.tipoplaza  = 44 ) ) 
and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia
                  
--Si la plaza aun tiene añoqnacontinuidad vacio Y NO TIENE ID_PLAZAANTERIOR                  
--significa que la plaza es nueva, asi que la continuidad empieza a partir de este momento                  
Update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = Hcontinuidad.añoqna 
from Hcontinuidad with(nolock) inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and Hcontinuidad.añoQnaContinuidad = ''                   
and Hcontinuidad.id_plazaanterior = '' 
and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia                          
                  
--Si la plaza tiene en plaza anterior LA MISMA PLAZA                   
--y el status01/tipoplaza95  en la plazaanterior de la qna pasada                  
--y un status01/tipoplaza10 en la plazaactual                  
--eso significa que le dieron definitivamente la plaza y debe mantener continuidad                  
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and b.id_plaza=Hcontinuidad.id_plaza   
inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and (Hcontinuidad.id_plazaanterior = cast(Hcontinuidad.id_plaza as varchar) or Hcontinuidad.id_plazaanterior = ''  )                
and Hcontinuidad.statusplaza = 01 and  Hcontinuidad.tipoplaza = 10                  
and b.statusplaza = 01 and  b.tipoplaza = 95  
and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia                            
                  
                  
--Si la plaza tiene en plaza anterior LA MISMA PLAZA                   
--y no cambia ni el tipo,ni el status,ni lacategoria                  
--eso significa que debe mantener continuidad                  
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + Hcontinuidad.id_plazaanterior + ',') <> 0   
inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and charindex(','+ ltrim(rtrim(cast(hcontinuidad.id_plaza  as varchar))) + ',',',' + Hcontinuidad.id_plazaanterior + ',') <> 0            
and Hcontinuidad.statusplaza = b.statusplaza and  Hcontinuidad.tipoplaza = b.tipoplaza                  
and Hcontinuidad.categoria = b.categoria  
and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia                             
                
--Si la plaza NO tiene en plaza anterior                   
--y un status14/tipoplaza41-42-43-49 ó status06/tipoplaza51-52-53 en la plazaactual                 
--eso significa que debe perder continuidad                  
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = añoQna    
from Hcontinuidad with(nolock) inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where ((Hcontinuidad.statusplaza = 14 and Hcontinuidad.tipoplaza in (41,42,43,49)) or                 
(Hcontinuidad.statusplaza = 06 and Hcontinuidad.tipoplaza in (51,52,53)))                
 and Hcontinuidad.añoqna = @Qna  
 and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia                         
                  
--Si en la qna anterior                 
--el status14/tipoplaza41-42-43-49 ó status06/tipoplaza51-52-53  en la plazaanterior de la qna pasada                  
--y un status01/tipoplaza95 en la plazaactual                 
--eso significa viene regresando de una licencia   y debe iniciar la continuidad                  
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = Hcontinuidad.añoQna                 
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and Hcontinuidad.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and                
((b.statusplaza = 14 and b.tipoplaza in (41,42,43,49)) or                 
(b.statusplaza = 06 and b.tipoplaza in (51,52,53)))                  
and Hcontinuidad.statusplaza = 01 and  Hcontinuidad.tipoplaza = 95  
and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia                              
                
--Si tiene PLAZAANTERIOR pero el status y el motivo es el mismo que el actual            
--debe de tomar la continuidad de la plaza anterior            
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + Hcontinuidad.id_plazaanterior + ',') <> 0 
inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and Hcontinuidad.id_plazaanterior <> ''            
and Hcontinuidad.tipoplaza = b.tipoplaza and Hcontinuidad.statusplaza = b.statusplaza  
and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia                
            
--Si tiene PLAZAANTERIOR pero el status y el motivo de la nueva es 01-10            
-- y el status y motivo de la anterior es 01-95            
--debe de tomar la continuidad de la plaza anterior            
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B               
on Hcontinuidad.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + Hcontinuidad.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and Hcontinuidad.id_plazaanterior <> ''            
and ((Hcontinuidad.tipoplaza = 10 and Hcontinuidad.statusplaza = 01 and b.tipoplaza = 95 and b.statusplaza = 01) or      
(Hcontinuidad.tipoplaza = 95 and Hcontinuidad.statusplaza = 01 and b.tipoplaza = 10 and b.statusplaza = 01) )  
and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia         
          
-------------------------------------------         
--Si la plaza tiene en plaza anterior LA MISMA PLAZA                   
--y el status10,11,14,15/tipoplaza44,48  en la plazaanterior de la qna pasada                  
--y un status01/tipoplaza10,95 en la plazaactual                  
--eso significa que le dieron definitivamente la plaza y debe mantener continuidad                  
--update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
--from Hcontinuidad inner join ( Select * from Hcontinuidad where añoqna = @Qnaanterior) B                  
--on Hcontinuidad.id_emp = b.id_emp       
--where Hcontinuidad.añoqna = @Qna and       
--(Hcontinuidad.id_plazaanterior = cast(b.id_plaza as varchar) or Hcontinuidad.id_plazaanterior = '' )                 
--and Hcontinuidad.statusplaza = 01 and  Hcontinuidad.tipoplaza in (10,95)                  
--and b.statusplaza in (10,11,14,15) and  b.tipoplaza in (44,48)   and Hcontinuidad.Id_emp = Case When @idEmp = 0 Then Hcontinuidad.Id_emp else @idEmp End              
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and  Hcontinuidad.id_plaza = b.id_plaza 
inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and       
(Hcontinuidad.id_plazaanterior = cast(b.id_plaza as varchar) or Hcontinuidad.id_plazaanterior = '' )                 
and Hcontinuidad.statusplaza = 01 and  Hcontinuidad.tipoplaza in (10,95)                  
and b.statusplaza in (10,11,14,15) and  b.tipoplaza in (44,48)   
and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia              

update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp   
inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and       
(Hcontinuidad.id_plazaanterior = cast(b.id_plaza as varchar) or Hcontinuidad.id_plazaanterior = '' )                 
and Hcontinuidad.statusplaza = 01 and  Hcontinuidad.tipoplaza in (10,95)                  
and b.statusplaza in (10,11,14,15) and  b.tipoplaza in (44,48)   
and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia     
and Hcontinuidad.id_emp in (select id_emp from Hcontinuidad where [añoqna] = @Qna and ([añoQnaContinuidad] = '' or [añoQnaContinuidad] = '      '  ) )

--Si la plaza tiene en plaza anterior LA MISMA PLAZA                   
--y el status03,06/tipoplaza20  en la plazaanterior de la qna pasada                  
--y un status01/tipoplaza10,95 en la plazaactual                  
--eso significa que le dieron definitivamente la plaza y debe mantener continuidad                  
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = b.añoQnaContinuidad                   
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + Hcontinuidad.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna and Hcontinuidad.id_plazaanterior = cast(Hcontinuidad.id_plaza as varchar)                  
and Hcontinuidad.statusplaza = 01 and  Hcontinuidad.tipoplaza in ( 10 , 95)                 
and b.statusplaza in (03,06) and  b.tipoplaza in (20) 
and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia                           
             
----Si la el tipo de plaza es de tipo prorroga
----Select * from ttipoplaza where destipoplaza like 'pró%'
----y el tipoplazapermisoanterior es distino de 48 o 44 entonces debe cortar continuidad
update Hcontinuidad set Hcontinuidad.añoQnaContinuidad = Hcontinuidad.añoQna                  
from Hcontinuidad with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on Hcontinuidad.id_emp = b.id_emp 
inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where Hcontinuidad.añoqna = @Qna                   
and Hcontinuidad.tipoplaza in (Select id_tipoplaza from ttipoplaza where destipoplaza like 'pró%')
and Hcontinuidad.tipoplazapermisoanterior not in (48,44)
and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia                             




-- Se agregan casos a cantinuidad 25/10/2016


-- los movimientos 1-96 deben de tomar la cntinuidad de la plaza anterior
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from hcontinuidad a   with(nolock)   
inner join ( Select * from Hcontinuidad with(nolock) where añoqna =  @Qnaanterior) b on b.id_emp = a.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.[añoqna]= @Qna
and a.statusplaza = 01 and a.tipoplaza = 96 and a.id_plazaanterior <> ''
and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia    


-- la licencia 88 debe tomar la continuidad anterior 
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a  with(nolock)
inner join ( Select * from Hcontinuidad with(nolock) where añoqna =  @Qnaanterior) b on b.id_emp = a.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.[añoqna]= @Qna
and a.statusplaza = 14 and a.tipoplaza = 88 and a.Id_emp  in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia 

-- cuando regresa de licencia 88 debe permanecer su continuidad 
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a  with(nolock)
inner join ( Select * from Hcontinuidad with(nolock) where añoqna =  @Qnaanterior) b on b.id_emp = a.id_emp and a.id_plaza = b.id_plaza 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.[añoqna]= @Qna
and a.statusplaza = 01 and a.tipoplaza in (10,95,96) and b.statusplaza = 14 and b.tipoplaza = 88 
 and a.Id_emp  in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
 and e.id_cia = @id_cia 
 
-- cuando entra en licencia o reanudacion y continuia con la lic que cortan
update a set a.añoQnaContinuidad = a.añoqna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((a.statusplaza in ( 14,10) and a.tipoplaza in (41,43,49,40)) or                 
(a.statusplaza in ( 14,10) and a.tipoplaza in (51,53)))                  
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia   

 -- licencias y reanudas que cortan
update a set a.añoQnaContinuidad = a.añoqna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10) and b.tipoplaza in (41,43,49,40)) or                 
(b.statusplaza in ( 14,10) and b.tipoplaza in (51,53)))                  
and a.statusplaza = 01 and  a.tipoplaza in( 95,10)  
and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia   

update a set a.añoQnaContinuidad = a.añoqna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10) and b.tipoplaza in (41,43,49,40)) or                 
(b.statusplaza in ( 06,10,14) and b.tipoplaza in (51,53)))                  
and ((a.statusplaza in ( 14,10,15) and a.tipoplaza in (44,42,48)) or                 
(a.statusplaza in ( 14,10) and a.tipoplaza in (52)))
and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia   

update a set a.añoQnaContinuidad = a.añoqna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10,15) and b.tipoplaza in (44,42,48)) or                 
(b.statusplaza in (14,10) and b.tipoplaza in (52)))                  
and ((a.statusplaza in ( 14,10) and a.tipoplaza in (41,43,49,40)) or                 
(a.statusplaza in ( 06,10,14) and a.tipoplaza in (51,53  )))
and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia   




-- licencias que no pierden la continuidad -- 05052020 la lic 42 corta
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((a.statusplaza in ( 14,10,15) and a.tipoplaza in (44,48)) or                 
(a.statusplaza in ( 14,10,15) and a.tipoplaza in (52)))  and
((b.statusplaza in ( 14,10,15) and b.tipoplaza in (44,48)) or                 
(b.statusplaza in ( 14,10,15) and b.tipoplaza in (52)))
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia   

-- cuando regresa de una licencia que no debe cortar continuidad-- 05052020 la lic 42 corta
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10,15) and b.tipoplaza in (44,48)) or                 
(b.statusplaza in ( 14,10,15) and b.tipoplaza in (52)))                  
and ( (a.statusplaza = 01 and  a.tipoplaza in( 95,10,96)) or (a.statusplaza = 06 and  a.tipoplaza in(20)) ) 
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia   



-- plaza 6-20 que tuvieron otra plaza y esa plaza esta en 14-42 -- 05052020 la lic 42 corta
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
a.statusplaza = 06 and a.tipoplaza = 20
and b.statusplaza in( 14,10) and b.tipoplaza = 0
and a.id_plazaanterior <> ''
and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia 

-- plaza 6-20 que tienen en la misma quincena la licencia 42

update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join (
  select h.* from Hcontinuidad h with(nolock) inner join (
  select a.id_emp, a.[añoqna], min(a.id_plaza) id_plaza
  from Hcontinuidad a with(nolock)
  inner join (
  Select id_emp, añoqna, min(añoqnacontinuidad) añoqnacontinuidad  from Hcontinuidad with(nolock) where añoqna = @Qnaanterior group by id_emp,añoqna
  ) b on a.id_emp = b.id_emp and a.[añoQnaContinuidad] = b.[añoQnaContinuidad] and a.[añoqna] = b.[añoqna]
  where a.[añoqna] = @Qnaanterior
  group by a.id_emp, a.[añoqna]
  ) m on m.id_emp = h.id_emp and m.id_plaza = h.id_plaza and m.añoqna = h.añoqna
) B                  
on a.id_emp = b.id_emp 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                   
a.statusplaza = 06 and a.tipoplaza in (20)                
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia  
and exists (
select 1 from Hcontinuidad h where h.id_emp = a.id_emp and h.[añoqna] = @Qna and h.statusplaza = 10 and h.tipoplaza = 42
)






-- movimientos 96 que tuvieron una baja 32 o 35 no cortan
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
inner join hplazas h with(nolock) on h.id_plaza = b.id_plaza and h.Id_TipoMovPlazas = 1 and h.Fecha = dbo.anioQuincenaToFecha(b.añoqna, 1) and h.Valor_IdCampo in (32,35)
where a.añoqna = @Qna  and a.id_plazaanterior <> ''                
and a.statusplaza = 01 and  a.tipoplaza = 96 
and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia 


-- tenian una hija 6-20 y le dan una padre debe de tener continuidad 
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and a.id_plazaanterior <> '' 
and b.statusplaza = 06 and  b.tipoplaza = 20 
and a.statusplaza = 01 and a.tipoplaza in (95,10,96)
and a.categoria = b.categoria
and b.id_plaza in (select id_plaza from hplazas where Id_TipoMovPlazas = 4)
and a.id_plaza not in (select id_plaza from hplazas where Id_TipoMovPlazas = 4)
and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia 


--de baja de 1-95-10 a 06-20

update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and  b.statusplaza in ( 01) and b.tipoplaza in (95,10,96)                
and a.statusplaza = 6 and  a.tipoplaza in( 20)  
and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia



-- continuidad de regularizados se trunca si la plaza anterior no esta conciliada

update a set a.añoQnaContinuidad = a.añoQna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
inner join hplazas h with(nolock) on h.id_plaza = b.id_plaza and h.Id_TipoMovPlazas = 1 and h.Fecha = dbo.anioQuincenaToFecha(b.añoqna, 1) and h.Valor_IdCampo in (32)
where a.añoqna = @Qna  and a.id_plazaanterior <> ''                
and ((a.statusplaza = 01 and  a.tipoplaza = 95) or (a.statusplaza = 06 and  a.tipoplaza = 20)   )
and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza in (select id_plaza from Thst_Plaza where Regularizada = 1)

update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
inner join hplazas h with(nolock) on h.id_plaza = b.id_plaza and h.Id_TipoMovPlazas = 1 and h.Fecha = dbo.anioQuincenaToFecha(b.añoqna, 1) and h.Valor_IdCampo in (32)
where a.añoqna = @Qna  and a.id_plazaanterior <> ''                
and ((a.statusplaza = 01 and  a.tipoplaza = 95) or (a.statusplaza = 06 and  a.tipoplaza = 20)   )
and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)



-------------- queries nuevos movimientos


-- Si esta en 01 95-96-10 o 06 20 24 25 y pasa a motivo nuevo misma plaza mantiene continuidad
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 01) and b.tipoplaza in (95,96,10)) or                 
(b.statusplaza = 06 and b.tipoplaza in (20,24,25)))                  
and ( (a.statusplaza = 01 and  a.tipoplaza in( 111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 )) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) ) 
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)


-- Si esta en 01 95-96-10 o 06 20 24 25 y pasa a motivo nuevo OTRA PLAZA mantiene continuidad
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and a.id_plazaanterior <> '' and                
((b.statusplaza in ( 01) and b.tipoplaza in (95,96,10)) or                 
(b.statusplaza = 06 and b.tipoplaza in (20,24,25)))                  
and ( (a.statusplaza = 01 and  a.tipoplaza in( 111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 )) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) ) 
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1) 


-- si de nuevo movimiento regresa a 01 95-96-10 o 06 20 24 25 en la misma plaza continuia
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 01) and b.tipoplaza in (111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 )) or                 
(b.statusplaza = 06 and b.tipoplaza in (88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)))                  
and ( (a.statusplaza = 01 and  a.tipoplaza in(95,96,10 )) or 
(a.statusplaza = 06 and  a.tipoplaza in(20,24,25)) ) 
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)  


-- si de nuevo movimiento regresa a 01 95-96-10 o 06 20 24 25 en OTRA PLAZA continuia
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and a.id_plazaanterior <> '' and                
((b.statusplaza in ( 01) and b.tipoplaza in (111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 )) or                 
(b.statusplaza = 06 and b.tipoplaza in (88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)))                  
and (( a.statusplaza = 01 and  a.tipoplaza in( 95,96,10 )) or 
(a.statusplaza = 06 and  a.tipoplaza in(20,24,25)) ) 
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)  


-- de un nuevo movimiento a otro nuevo movimiento con las misma plaza
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 01) and b.tipoplaza in (111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 )) or                 
(b.statusplaza = 06 and b.tipoplaza in (88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)))                  
and (( a.statusplaza = 01 and  a.tipoplaza in(111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151  )) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) ) 
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1) 


-- de un nuevo movimiento a otro nuevo movimiento con OTRA plaza
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and a.id_plazaanterior <> '' and                
((b.statusplaza in ( 01) and b.tipoplaza in (111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 )) or                 
(b.statusplaza = 06 and b.tipoplaza in (88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)))                  
and (( a.statusplaza = 01 and  a.tipoplaza in( 111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 ) ) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) ) 
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1) 




-- Si tiene nuevo movimiento y entra a lic 14-10 41-43-49-40 0 06 51-53 corta continuidad
 update a set a.añoQnaContinuidad = a.añoqna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 01) and b.tipoplaza in (111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 )) or                 
(b.statusplaza = 06 and b.tipoplaza in (88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)))                  
and (( a.statusplaza in (14,10) and  a.tipoplaza in(41,43,49,40)) or 
(a.statusplaza in (14,10) and  a.tipoplaza in(51,53)) )
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)   


-- si esta en lic 14-10 41-43-49-40 0 06 51-53 y le dan mov nuevo inicia su continuidad
 update a set a.añoQnaContinuidad = a.añoqna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10) and b.tipoplaza in (41,43,49,40 )) or                 
(b.statusplaza in (14,10) and b.tipoplaza in (51,53)))                  
and (( a.statusplaza in (01) and  a.tipoplaza in(111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 ) ) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) )
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)   

-- si tine plaza en licencia y le dan una con movimiento sdp
update a set a.añoQnaContinuidad =  b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join 
( Select * from Hcontinuidad with(nolock) where añoqna = @Qna
) B                  
on a.id_emp = b.id_emp 
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10,15) and b.tipoplaza in (44,42,48,88 )) or                 
(b.statusplaza in ( 14,10,15) and b.tipoplaza in (52)))                  
and (( a.statusplaza in (01) and  a.tipoplaza in(113,115,116,123,124,125,126,131,132,147,148,150,151) ) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) )
and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia =  @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)


-- si tiene un nuevo movimiento y entra el lic 14-10 44-42-48-88 o 06 52 continuia -- 05052020 quito la lic 42 ya que no continua
 update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 01) and b.tipoplaza in (111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 )) or                 
(b.statusplaza = 06 and b.tipoplaza in (88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)))                  
and (( a.statusplaza in ( 14,10,15) and  a.tipoplaza in(44,48,88)) or 
(a.statusplaza in ( 14,10,15) and  a.tipoplaza in(52)) )
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1) 



-- si regresa de lic 14-10 44-42-48-88 o 06 52 a un nuevo movimiento continua-- 05052020 quito la lic 42 ya que no continua
 update a set a.añoQnaContinuidad =  b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10,15) and b.tipoplaza in (44,48,88 )) or                 
(b.statusplaza in ( 14,10,15) and b.tipoplaza in (52)))                  
and (( a.statusplaza in (01) and  a.tipoplaza in(111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151) ) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) )
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia =  @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)

-- 05052020 quito la lic 42 ya que no continua
 update a set a.añoQnaContinuidad =  b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 14,10,15) and b.tipoplaza in (44,48,88 )) or                 
(b.statusplaza in ( 14,10,15) and b.tipoplaza in (52)))                  
and (( a.statusplaza in (01) and  a.tipoplaza in(111,113,115,116,117,147,148,150,121,122,123,124,125,126,131,132,151 ) ) or 
(a.statusplaza = 06 and  a.tipoplaza in(88,99,100,101,102,103,104,105,106,107,108,109,110,112,114,118,133,134,135,136,137,138,139,141,142,143,144,145,146,119,120,127,128,129,130,154,155,156,157,152,153,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173)) )
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia =  @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)

--------------------

-- 23/11/2018 si esta en 6 15 y pasas a 6 -90-11 con otra plaza corta continuidad
update a set a.añoQnaContinuidad = a.añoQna
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and (b.statusplaza = 06 and  b.tipoplaza in(15,103,137)) and
(a.statusplaza = 06 and  a.tipoplaza in(11,99,133,108,143,15,103,137))
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1)

---- de 96 a 96-10 y al reves con diferente plaza continuan continuan
update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and charindex(','+ ltrim(rtrim(cast(b.id_plaza  as varchar))) + ',',',' + a.id_plazaanterior + ',') <> 0
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and a.id_plazaanterior <> '' and                
((b.statusplaza in ( 01) and b.tipoplaza in (95,96,10)) )                  
and ( (a.statusplaza = 01 and  a.tipoplaza in( 95,96,10))) 
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1) 

update a set a.añoQnaContinuidad = b.añoQnaContinuidad
from Hcontinuidad a with(nolock) inner join ( Select * from Hcontinuidad with(nolock) where añoqna = @Qnaanterior) B                  
on a.id_emp = b.id_emp and a.id_plaza = b.id_plaza
inner join empleados e with(nolock) on e.id_emp = a.id_emp
where a.añoqna = @Qna and                
((b.statusplaza in ( 01) and b.tipoplaza in (95,96,10)) )                  
and ( (a.statusplaza = 01 and  a.tipoplaza in( 95,96,10))) 
 and a.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia and b.id_plaza not in (select id_plaza from Thst_Plaza where Regularizada = 1) 

--------------      
update Hcontinuidad set añoqnacontinuidad = añoqna 
from Hcontinuidad with(nolock) inner join empleados e with(nolock) on e.id_emp = Hcontinuidad.id_emp
where añoqna = @Qna and añoqnacontinuidad = '      '   
and Hcontinuidad.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))
and e.id_cia = @id_cia   




-- Para cambios de estado

-- lo comento para aguinaldo

--update h set h.añoqnacontinuidad = es.sep
--from hcontinuidad h
--inner join (
--select fd.Id_Emp, fdd.Id_Plaza, dbo.fechaToAnioQuincena(fdd.fechaini) qna, s.sep from FUP_Documentos fd
--inner join FUP_Documento_Detalle fdd on fd.Id_Documento = fdd.Id_Documento
--inner join FUP_Informacion_Documentos fid on fid.Id_Documento = fd.Id_Documento
--inner join FUP_MotivoMovimiento fmm on fmm.Id_MotivoMovimiento = fdd.Id_MotivoMovimiento
--inner join (
--  select a.id_emp, dbo.fechaToAnioQuincena(a.fecha_alta_sep) sep from HFecha_Alta_SEP a inner join (
--  select id_emp, max(fecha) fecha from HFecha_Alta_SEP where fecha <= getdate() group by id_emp
--  ) b on a.fecha = b.fecha and a.id_emp = b.id_emp
--) s on s.id_emp = fd.id_emp
--where fdd.Id_MotivoMovimiento = 1 and fmm.Id_TipoMovimiento = 2
--) es on es.id_emp = h.id_emp and es.id_plaza = h.id_plaza and es.qna = h.añoqna
--inner join empleados e on e.id_emp = h.id_emp
--where h.[añoqna] = @Qna and e.id_cia = @id_cia
--and h.Id_emp in (SELECT empleados.n.value('.', 'INT') AS n FROM    @Xml.nodes('/empleado') AS empleados(n))



end


--- para empleados que cambian de baseica a MM y viceversa


update a set a.añoqnacontinuidad = b.añoqnacontinuidad
 from hcontinuidad a
 inner join empleados e on e.id_emp = a.id_emp
 inner join (
  select a.*, e.curp from hcontinuidad a
   inner join empleados e on e.id_emp = a.id_emp
   where a.añoqna = @Qnaanterior and e.id_cia = 3 and a.statusplaza in (01)
 ) b on e.curp = b.curp
 where a.añoqna = @Qna and e.id_cia = 2 and a.statusplaza in (01,06)
 

update a set a.añoqnacontinuidad = b.añoqnacontinuidad
 from hcontinuidad a
 inner join empleados e on e.id_emp = a.id_emp
 inner join (
  select a.*, e.curp from hcontinuidad a
   inner join empleados e on e.id_emp = a.id_emp
   where a.añoqna = @Qnaanterior and e.id_cia = 2 and a.statusplaza in (01,06)
 ) b on e.curp = b.curp
 where a.añoqna = @Qna and e.id_cia = 3 and a.statusplaza in (01)




end
GO
