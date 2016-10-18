
with Units; use Units;

generic
	type Unit is new Unit_Type'Base;
package Generic_Unit_Vectors with SPARK_Mode is

  type Unit_Comp_Type is new Unit'Base;

  --subtype Unit_X is Unit_Comp_Type with Dimension => (Symbol => 'm', Meter => 1, others => 0);


  subtype Unit_X_Type is Unit;
  subtype Unit_Y_Type is Unit;
  subtype Unit_Z_Type is Unit;


  ------------------------------
  type X_Dim_Type is record
  	value : Unit_X_Type;
  end record;

  type Y_Dim_Type is record
  	value : Unit_Y_Type;
  end record;

  type Z_Dim_Type is record
  	value : Unit_Z_Type;
  end record;

  type Unit_Vector2 is record
    x : X_Dim_Type;
    y : Y_Dim_Type;
    z : Z_Dim_Type;
  end record;   -- Dimension System only applies to Numeric Types
  ----------------------------------


  type Unit_Vector is record
    x : Unit_X_Type;
    y : Unit_Y_Type;
    z : Unit_Z_Type;
  end record;   -- Dimension System only applies to Numeric Types

  generic
  function addition(Left, Right : Unit_Vector) return Unit_Vector;

  -- Global Pragma Unreferenced/Obs
  -- function "+"(Left : Unit_X_Type; Right : Unit_Y_Type) return Unit_X_Type is
  -- (Unit_X_Type(Left));
  --pragma Obsolescent ("+");

end Generic_Unit_Vectors;
