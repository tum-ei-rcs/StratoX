with p1; use p1;
package body p2 with SPARK_Mode is

    procedure write_to_uart (msg : Byte_Array) with
      Global => (Output => some_register)
    is
    begin
        some_register := msg(1);
    end;

    procedure foo is
    begin
        write_to_uart(p1.toBytes (some_constant));
    end foo;
end p2;
