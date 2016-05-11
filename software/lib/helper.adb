
package body helper is


  function addWrap(
    x   : Numeric_Type;
    inc : Numeric_Type)
  return Numeric_Type
  is
  begin
      if x + inc > Numeric_Type'Last then
         return x + inc - Numeric_Type'Last;
      else
         return x + inc;
      end if;
  end addWrap;


end helper;
