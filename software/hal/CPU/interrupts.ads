




package Interrupts is
 
	type IRQ_Type is tagged abstract;

	procedure enable_Interrupt(irq : IRQ_Type) is abstract;

	procedure enable_Interrupts();
	procedure disable_Interrupts();



end Interrupts;