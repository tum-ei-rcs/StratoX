with CSV;
with Config.software;
with Simulation;
with Ada.Text_IO; use Ada.Text_IO;
with Units; use Units;


package body ms5611.driver  with
   SPARK_Mode => Off,
   Refined_State => (State => ( cur_temp, cur_press), Coefficients => null) is

   G_CELSIUS_0 : constant := 273.15;
   cur_temp : Temperature_Type := 300.0 * Kelvin;
   cur_press : Pressure_Type := 1.0 * Bar;

   procedure reset is null;

   procedure init is null;

   subtype TEMP_Type is Float range -4000.9 .. 8500.9;
   function convertToKelvin (thisTemp : in TEMP_Type) return Temperature_Type is
   begin
      return Temperature_Type (G_CELSIUS_0 + thisTemp / 100.0);  -- SPARK Range Check might fail
   end convertToKelvin;

   procedure Update_Val (have_update : out Boolean) is
   begin
--        cur_press := Pressure_Type (Simulation.CSV_here.Get_Column ("Press"));
--        declare
--           f : float := Simulation.CSV_here.Get_Column ("Temp");
--        begin
--           cur_temp := convertToKelvin (f);
--        end;
      null;
   end update_val;

   function get_temperature return Temperature_Type is (cur_temp);

   function get_pressure return Pressure_Type is (cur_press);

   procedure self_check (Status : out Error_Type) is null;
end ms5611.driver;
