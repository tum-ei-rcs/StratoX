-- Institution: Technische Universitaet Muenchen
-- Department:  Realtime Computer Systems (RCS)
-- Project:     StratoX
-- Module:      Console
-- Authors: Emanuel Regnath (emanuel.regnath@tum.de)
-- 
-- ToDo:
-- [ ] Implementation

--  @summary Command Line Interface for user interactions
package Console with 
   SPARK_Mode
is
   
   type User_Command_Type is ( NONE, RESTART, STATUS, TEST, PROFILE, ARM, DISARM, INC_ELE, DEC_ELE );

   procedure read_Command( cmd : out User_Command_Type );
   
   procedure write_Line( message : String );

end Console;
