procedure main with SPARK_Mode is
   vstring : constant String := Integer'Image (10); -- unconstrained type ... lower bound not fixed.

   pragma Assert (Integer'Size <= 32);
   pragma Assume (vstring'Length <= 11 and vstring'Length > 0);

   cs : constant String (1..2) := (others => ' ');

   --  NOT A BUG AFTER ALL, see comments and read RM RM 4.5.3-6 and 7: the lower bound of the concat
   --  result is defined by the lower bound of the LHS value's ultimative ancestor type. If that is
   --  constrained, then the lower bound is also known by GNATprove

   --  concat with unconstrained:
   catstring1  : constant String := (vstring & vstring) & vstring; -- fails => OK
   catstring2  : constant String := vstring & (vstring & vstring); -- surprising success, because if catstring1 fails, then the bad execution cannot reach this.
   catstring  : constant String := vstring & vstring & vstring; -- surprising success, for the same reason as catstring2

   --  concat with constrained:
   catstring11 : constant String := cs & cs; -- success, as expected
   catstring8  : constant String := vstring & cs & vstring; -- unconstrained, verification fail -> ok
   catstring9  : constant String := (vstring & cs) & vstring; -- unconstrained, verification success -> proof builds on catstring8 failing
   catstring10 : constant String := vstring & (cs & vstring); -- unconstrained, verification success -> proof builds on catstring8 failing

   --  concat with string literals:
   catstring3 : constant String := vstring & " hello" & vstring; -- unconstrained, verification fail -> ok
   catstring4 : constant String := (vstring & " hello") & vstring; -- unconstrained, but verification success -> proof builds on catstring3 failing
   catstring5 : constant String := vstring & (" hello" & vstring); -- unconstrained, but verification success -> proof builds on catstring3 failing

   --  indeed success, because "hello" has a known lower bound (compiler knows it)
   catstring6 : constant String := "hello" & vstring & "hello"; -- internally constrained by constant string -> OK

   pragma Assert (vstring'First <= 1);
begin
   null;
end main;
