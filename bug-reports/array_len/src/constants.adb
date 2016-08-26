package body constants with SPARK_Mode is

   type Buffer_Wrap_Idx is mod BUFLEN;
   head : Arr_T (0 .. 3);   -- THIS must come before procedure, otherwise checks fail

   procedure readFromDev (data : out UBX_Data) is
      data_rx : Arr_T (0 .. BUFLEN - 1):= (others => 0);
      msg_start_idx : Buffer_Wrap_Idx;
   begin
      data := (others => 0);

      for i in 0 .. data_rx'Length - 2 loop

         if data_rx (i) = UBX_SYNC1 and data_rx (i + 1) = UBX_SYNC2 then
            msg_start_idx := Buffer_Wrap_Idx (i);

            declare
               idx_start : constant Buffer_Wrap_Idx := msg_start_idx + 2;
               idx_end   : constant Buffer_Wrap_Idx := msg_start_idx + 5;
               pragma Assert (idx_start + 3 = idx_end); -- modulo works as ecpected
            begin
               if idx_start > idx_end then
                  -- wrap
                  head := data_rx (Integer (idx_start) .. data_rx'Last) & data_rx (data_rx'First .. Integer (idx_end));
               else
                  -- no wrap
                  head := data_rx (Integer (idx_start) .. Integer (idx_end));
               end if;
            end;
            exit;
         end if;
      end loop;
   end readFromDev;

   procedure Do_Something is
      test : UBX_Data;
   begin
      readFromDev (test);
      pragma Unreferenced (test);
   end Do_Something;

end constants;
