with System.Dim.Float_IO;

with Units;       use Units;
with Config;

package body Mission with SPARK_Mode is

   package SystemDimUnits is new System.Dim.Float_IO (Unit_Type);
   use SystemDimUnits;

   mstate : Mission_State_Type := ASCENDING;

   procedure monitor_Ascend;
     -- with Pre => True; -- adding this is a workaround

   procedure monitor_Ascend is
      height : Altitude_Type := 0.0 * Meter;
   begin
      if height >= Config.CFG_TARGET_ALTITUDE_THRESHOLD then -- error: both operands for operation ">=" must have same dimensions
        null;
      end if;

      if height > 100.0 * Meter then -- this works
         null;
      end if;
      Put(height, 1, 2, 0);
   end monitor_Ascend;

   procedure run_Mission is
   begin
      case (mstate) is
         when UNKNOWN => null;
         when ASCENDING =>
            monitor_Ascend;
         when others => null;
      end case;
   end run_Mission;


end Mission;
