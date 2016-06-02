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
package Generic_Signal with SPARK_Mode is


  type Sample_Type is record
     data      : Data_Type;
     timestamp : Time_Type;
  end record;

  type Signal_Type is array (Natural range <>) of Sample_Type;

end Generic_Signal;
