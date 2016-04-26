-- Institution: Technische Universität München
-- Department: Realtime Computer Systems (RCS)
-- Project: StratoX
-- Module: Types
--
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
--
-- Description: Common used type definitions
-- 
-- ToDo:
-- [ ] Implementation


-- Data Hierarchy:
-- Data_Type: has one or more values
-- Sample_Type: is a Data_Type with timestamp
-- Signal_Type: array of Sample_Type


with units;

package Types is

  type Data_Type is interface;
     procedure getData(This : in out Data_Type) is abstract;
     function  isValid(This : in     Data_Type) is abstract return Boolean;

  generic 
    type Data_Type
  type Sample_Type is record
     data      : Data_Type;
     timestamp : Time_Type;
  end record;

  generic
    SAMPLE_COUNT : Natural;
  type Signal_Type is array (SAMPLE_COUNT) of Sample_Type;




  type Karthesian_Coordinate_Dimension_Type is (X, Y, Z);
  type Polar_Coordinate_Dimesion_Type is (Phi, Rho, Psi);
  type Earth_Coordinate_Dimension_Type is (LONGITUDE, LATITUDE, ALTITUDE);

  type Karthesian_Vector_Type is array (Karthesian_Coordinate_Dimension_Type) of Length_Type;



end Types;