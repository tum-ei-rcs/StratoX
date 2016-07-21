package body simulation is

   procedure init is
   begin

      if not CSV_here.Open then
         Put_Line ("Simulation: Error opening file");
         Simulation.Finished := True;
         return;
      else
         Put_Line ("Simulation: Replay from file");
         have_data := True;
         CSV_here.Parse_Header;
      end if;

   end init;

   procedure update is
   begin
      if CSV_here.End_Of_File then
         Finished := True;
         Put_Line ("Simulation: EOF");
         return;
      end if;

      if not CSV_here.Parse_Row then
         Simulation.Finished := True;
         Put_Line ("Simulation: Row error");
      else
         CSV_here.Dump_Columns;
         declare
            t : float := CSV_here.Get_Column("time");
         begin
            Put_Line ("t=" & t'Img);
         end;
      end if;

   end;

   procedure close is
   begin
      CSV_here.Close;
   end close;

end simulation;
