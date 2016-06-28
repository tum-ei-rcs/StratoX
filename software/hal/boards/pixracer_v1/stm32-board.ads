------------------------------------------------------------------------------
--                                                                          --
--                  Copyright (C) 2015-2016, AdaCore                        --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions are  --
--  met:                                                                    --
--     1. Redistributions of source code must retain the above copyright    --
--        notice, this list of conditions and the following disclaimer.     --
--     2. Redistributions in binary form must reproduce the above copyright --
--        notice, this list of conditions and the following disclaimer in   --
--        the documentation and/or other materials provided with the        --
--        distribution.                                                     --
--     3. Neither the name of STMicroelectronics nor the names of its       --
--        contributors may be used to endorse or promote products derived   --
--        from this software without specific prior written permission.     --
--                                                                          --
--   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    --
--   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      --
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  --
--   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   --
--   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, --
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       --
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  --
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  --
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    --
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  --
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   --
--                                                                          --
--                                                                          --
--  This file is based on:                                                  --
--                                                                          --
--   @file    stm32-board.ads                                               --
--   @author  AdaCore                                                       --
--   @brief   This file contains definitions for Pixracer V1 board          --
--            LEDs, push-buttons hardware resources.                        --
--                                                                          --
------------------------------------------------------------------------------
with STM32.Device;  use STM32.Device;

with STM32.GPIO;    use STM32.GPIO;
with STM32.SPI;     use STM32.SPI;

with Ada.Interrupts.Names;  use Ada.Interrupts;

package STM32.Board is

   pragma Elaborate_Body;

   ----------
   -- LEDs --
   ----------

   subtype User_LED is GPIO_Point;

   Green : User_LED renames PB1;
   Red   : User_LED renames PB11;
   Blue  : User_LED renames PB3;

   LCH_LED : User_LED renames Red;

   All_LEDs  : GPIO_Points := Green & Red & Blue;

   procedure Initialize_LEDs;
   --  MUST be called prior to any use of the LEDs unless initialization is
   --  done by the app elsewhere.

   procedure Turn_On  (This : in User_LED) renames STM32.GPIO.Set;
   procedure Turn_Off (This : in out User_LED) renames STM32.GPIO.Clear;

   procedure All_LEDs_Off with Inline;
   procedure All_LEDs_On  with Inline;

   procedure Toggle_LEDs (These : in out GPIO_Points) renames STM32.GPIO.Toggle;

   
   ----------
   -- Button
   ----------
   --  TODO

   
--     ---------------
--     -- SPI5 Pins --
--     ---------------
--
--     --  Required for the gyro and LCD so defined here
--
--     SPI5_SCK     : GPIO_Point renames PF7;
--     SPI5_MISO    : GPIO_Point renames PF8;
--     SPI5_MOSI    : GPIO_Point renames PF9;
--     NCS_MEMS_SPI : GPIO_Point renames PC1;
--     MEMS_INT1    : GPIO_Point renames PA1;
--     MEMS_INT2    : GPIO_Point renames PA2;
--
   
end STM32.Board;
