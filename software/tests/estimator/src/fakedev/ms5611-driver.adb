with CSV;
with Config.software;
with Simulation;
with Ada.Text_IO; use Ada.Text_IO;

package body ms5611.driver  with
   SPARK_Mode,
   Refined_State => (State => (have_data, csv_file), Coefficients => null) is

   have_data : Boolean := False;
   csv_file : Ada.Text_IO.File_Type;

   procedure reset is null;

   procedure init is
   begin
      Ada.Text_IO.Open (File => csv_file,
                        Mode => Ada.Text_IO.In_File,
                        Name => "ms5611.csv");

      if not Ada.Text_IO.Is_Open (csv_file) then
         Put_Line ("MS5611: Error opening file");
         Simulation.Finished := True;
      else
         Put_Line ("MS5611: Replay from file");
         have_data := True;
      end if;
   end init;

   procedure update_val is
   begin
      if not have_data and then Ada.Text_IO.End_Of_File (csv_file) then
         Simulation.Finished := True;
         Put_Line ("MS5611: EOF");
         return;
      end if;
      declare
         R : csv.Row := CSV.Get_Row (csv_file, Config.software.CSV_SEP);
      begin
         while R.Next loop
            Put(R.Item & ",");
         end loop;
         New_Line;
      end;
   end update_val;

   function get_temperature return Temperature_Type is
      a : Temperature_Type;
   begin
      return a;
   end;
   -- get temperature from buffer
   -- @return the last known temperature measurement

   function get_pressure return Pressure_Type is
      a :  Pressure_Type;
   begin
      return a;
   end;
   -- get barometric pressure from buffer
   -- @return the last known pressure measurement

   procedure self_check (Status : out Error_Type) is null;
end ms5611.driver;
