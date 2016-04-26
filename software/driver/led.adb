
-- todo: use HAL
--with STM32_SVD.GPIO;  use STM32_SVD.GPIO;
with HIL.GPIO;        use HIL.GPIO;

package body LED is

	procedure init is
	begin
		null;
	end init;

	procedure on is
	begin
		write(RED_LED, HIGH);   -- LED on
	end on;

	procedure off is
	begin
		write(RED_LED, LOW);   -- LED off
	end off;

end LED;
