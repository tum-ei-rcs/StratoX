-- Description:
-- Main System File
-- todo: better unit name

with CPU;
with Ada.Real_Time; use Ada.Real_Time;
with led_manager;

package body Main is

	-- the mission can only go forward
	type Mission_State_Type is (
		UNKNOWN,
		INITIALIZING,
		SELF_TESTING,
		READY_TO_START,
		ASCENDING,
		HOLDING,
		DESCENDING,
		LANDED,
		FOUND,
		EVALUATING
	);


	type Mission_Event_Type is (
		UNKNOWN,
		INITIALIZATION_START,
		INITIALIZATION_END,
		SELF_TEST_START,
		SELF_TEST_END,
		ARMED,
		RELEASED,
		BALLOON_CUT,
		DESCENDING,
		LANDED,
		FOUND,
		EVALUATED
	);


	type Health_Status_Type is (
		UNKNOWN,
		OK,
		EMERGENCY
	);

	type Altitude_State_Type is (
		GROUND,
		ASCENDING,
		STABLE,
		DESCENDING,
		FREEFALL
	);


	type System_State_Type is record
		Mission_State : Mission_State_Type := UNKNOWN;
		Health_Status : Health_Status_Type := UNKNOWN;	
	end record;

	procedure initialize is
	begin
		CPU.initialize;
	end initialize;


   procedure run_Loop is
   begin
      led_manager.LED_blink(led_manager.SLOW);
      loop
	 delay until Clock + Milliseconds (200);
	 led_manager.LED_tick(200);
	 led_manager.LED_sync;
      end loop;
   end run_Loop;	

end Main;
