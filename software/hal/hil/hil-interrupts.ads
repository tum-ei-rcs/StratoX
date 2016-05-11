
package HIL.Interrupts is

	type Interrupt_Handler is access protected procedure;
	type Interrupt_ID_Type is new Integer range 1 .. 81;

	procedure registerInterrupt(Handler : Interrupt_Handler );



end HIL.Interrupts;

