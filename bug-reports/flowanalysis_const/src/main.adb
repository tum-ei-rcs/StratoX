with p2; use p2;
procedure main with SPARK_Mode is
begin
    -- trying to reprouce the problem StratoX has in hil.ads, but doesn't show up here
    p2.foo;
end main;
