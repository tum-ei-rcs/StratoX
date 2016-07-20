with CSV;
with Ada.Text_IO; use Ada.Text_IO;

package Simulation is

   package CSV_here is new CSV (filename => "rawdata.csv");
   have_data : Boolean := False;
   csv_file : File_Type;
   Finished : Boolean := False;

   procedure init;

   procedure update;

   procedure close;

end Simulation;
