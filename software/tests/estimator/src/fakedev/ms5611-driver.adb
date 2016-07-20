with CSV;
with Config.software;
with Simulation;
with Ada.Text_IO; use Ada.Text_IO;


package body ms5611.driver  with
   SPARK_Mode => Off,
   Refined_State => (State => (have_data, csv_file, cur_temp, cur_press), Coefficients => null) is

   package CSV_here is new CSV (filename => "ms5611.csv");
   have_data : Boolean := False;
   csv_file : File_Type;

   cur_temp : Temperature_Type;
   cur_press : Pressure_Type;

   procedure reset is null;

   procedure init is
   begin

      if not CSV_here.Open then
         Put_Line ("MS5611: Error opening file");
         Simulation.Finished := True;
         return;
      else
         Put_Line ("MS5611: Replay from file");
         have_data := True;
         CSV_here.Parse_Header;
      end if;

   end init;

   procedure update_val is
   begin
      if not have_data and then CSV_here.End_Of_File then
         Simulation.Finished := True;
         Put_Line ("MS5611: EOF");
         return;
      end if;

      if not csv_here.Parse_Row then
         Simulation.Finished := True;
         Put_Line ("MS5611: Row error");
      end if;

      cur_press := Pressure_Type (CSV_here.Get_Column ("press"));
      cur_temp := Temperature_Type (CSV_here.Get_Column ("temp"));
   end update_val;

   function get_temperature return Temperature_Type is (cur_temp);

   function get_pressure return Pressure_Type is (cur_press);

   procedure self_check (Status : out Error_Type) is null;
end ms5611.driver;
