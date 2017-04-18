with unav;
with Units; use Units;
with Text_IO; use Text_IO;

procedure main with SPARK_Mode is

   distance : Length_Type;
begin
   distance := unav.Get_Distance;
   Put_Line ("distance=" & Float'Image(Float(distance)) & " m");
end main;
