-- Institution: Technische Universitaet Muenchen
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
--
-- Authors: Martin Becker (becker@rcs.ei.tum.de>
with STM32.Timers; use STM32.Timers;
with System.OS_Interface;

--  @summary
--  Target-specific implementation of HIL for Timers. Pixracer.
package body HIL.Timers with SPARK_Mode => Off is

   procedure Initialize (t : in out HIL_Timer) is
   begin
      STM32.Timers.Enable (t);
   end Initialize;

   procedure Enable (t : in out HIL_Timer; ch : HIL.Timers.HIL_Timer_Channel) is
   begin
      if not STM32.Timers.Enabled (t) then
         STM32.Timers.Enable (t);
      end if;
      STM32.Timers.Enable_Channel (t, ch);
   end Enable;

   procedure Disable (t : in out HIL_Timer; ch : HIL.Timers.HIL_Timer_Channel) is
   begin
      -- STM32.Timers.Disable (t); -- we cannot disable the timer when channel is active
      STM32.Timers.Disable_Channel (t, ch); -- so we just let the timer do it's thing and disable the channel
   end Disable;

   procedure Calculate_Prescaler_and_Period (f : in Frequency_Type; Prescaler : out Short; Period : out Word) is
      TIM_CLK : constant := System.OS_Interface.Ticks_Per_Second;
   begin
      -- Frequency = 0.5 * TIM_CLK / ((Prescaler+1)*(Period+1))
      --  TIM_CLK = timer clock input in Hz
      -- => period = TIM_CLK / (2*f (prescaler+1)) - 1
      Prescaler := 0;
      period := Word (Float (TIM_CLK) / (2.0 * Float (f) * Float (Prescaler+1)));
      -- smallest: 1Hz => 84000000 < Word'Last
      -- largest: 1MHz => 84
      -- largest: 1MHz => 84
   end Calculate_Prescaler_and_Period;

   procedure Configure_OC_Toggle
     (This      : in out HIL_Timer;
      Frequency : Frequency_Type;
      Channel   : HIL_Timer_Channel)
   is
      Counter_Mode  : constant Timer_Counter_Alignment_Mode := Up;
      Clk_Div       : constant Timer_Clock_Divisor := Div1;
      Reps          : constant Byte := 0;
      Prescaler     : Short;
      Period        : Word;
   begin
      --  2. write ARR and CCRx to set event period. Counter decrements
      --  until zero, then starts at value=Period again.
      Calculate_Prescaler_and_Period (Frequency, Prescaler, Period);
      if Period >= 2**16 then
         Period := 2**16-1;
      end if;

      STM32.Timers.Configure (This,
                              Prescaler => Prescaler,
                              Period => Period,
                              Clock_Divisor => Clk_Div,
                              Counter_Mode => Counter_Mode,
                              Repetitions => Reps);

      --  3. configure output mode: toggle channel output every time we reach zero
      STM32.Timers.Configure_Channel_Output (This => This,
                                                Channel => Channel,
                                                Mode => Toggle,
                                                State => Enable,
                                                Pulse => Period,
                                                Polarity => High);

      -- 4. disable preload
      STM32.Timers.Set_Autoreload_Preload (This, False);

      -- 5. finally enable channel
      STM32.Timers.Enable_Channel (This, Channel);

      STM32.Timers.Enable (This);
   end Configure_OC_Toggle;

   --  procedure Set_Counter (This : in out HIL_Timer;  Value : Word) renames STM32.Timers.Set_Counter;
   --  procedure Set_Autoreload (This : in out HIL_Timer;  Value : Word) renames STM32.Timers.Set_Autoreload;
end HIL.Timers;
