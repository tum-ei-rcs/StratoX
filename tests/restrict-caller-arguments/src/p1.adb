package body p1 with SPARK_Mode,
  Refined_State => (Only_Writing_Parameters => BUS_SEL, Internals => foo)
  -- this produces warnings: "no procedure exists, which can initialize abstract state"
is

   type Select_Type is (CHIP_SELECT, CHIP_DESELECT);
   BUS_DESEL : constant Select_Type := CHIP_DESELECT;
   BUS_SEL : constant Select_Type := CHIP_SELECT;

   foo : Integer; -- classic warning: 'body of package "p1" has unused hidden states'

   -- some empty function
   procedure low_level_chip_select(Device : Integer; hilo : Select_Type; succ : out Integer ) is
   begin
      succ := Device + 1;
   end low_level_chip_select;


   -- in this function we want to avoid that CHIP_SELECT is used
   -- can we add SPARK aspects at the body only?
   procedure write_on_bus(Device : Integer; Data: Integer) with
     Refined_Global => (Input => BUS_SEL) -- that is ineffective, see SPARK RM 6.1.4
   is
      ret : Integer;
   begin
      low_level_chip_select(Device => Device, hilo => CHIP_DESELECT, succ => ret);

      null;
   end write_on_bus;

end p1;
