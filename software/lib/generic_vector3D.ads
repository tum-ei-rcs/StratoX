-- Institution: Technische Universität München
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Generic vector package
--
-- ToDo:
-- [ ] Implementation


with Ada.Numerics.Generic_Elementary_Functions;

generic
   type Data_Type is Float;
package Generic_Vector3D with SPARK_Mode is

   type Vector_Type is tagged private;

  type Karthesian_Vector_Type is record
     x : Data_Type;
     y : Data_Type;
     z : Data_Type;
  end record;

  function norm(vector : Karthesian_Vector_Type) return Data_Type;

end Generic_Vector3D;
