-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Generic signal package
-- 
-- ToDo:
-- [ ] Implementation


with Units; use Units;

generic
   type Data_Type is private;
   -- with function "/" (X : Data_Type; Y : Integer) return Data_Type is <>;
   -- with function "+" (X,Y : Data_Type) return Data_Type is <>;
package Generic_Signal with SPARK_Mode is


   type Sample_Type is record
      data      : Data_Type;
      timestamp : Time_Type;
   end record;

   type Signal_Type is array (Natural range <>) of Sample_Type;
   
   -- function Average( signal : Signal_Type ) return Data_Type;
--     function Average( signal : Signal_Type ) return Data_Type is
--        avg : Data_Type;
--     begin
--        avg := signal( signal'First ).data / signal'Length;
--        if signal'Length > 1 then
--           for index in Integer range signal'First+1 .. signal'Last loop
--              avg := avg + signal( index ).data / signal'Length;
--           end loop;
--        end if;
--        return avg;
--     end Average;   

end Generic_Signal;
