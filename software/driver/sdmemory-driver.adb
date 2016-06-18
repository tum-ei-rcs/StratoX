--with Ada.Unchecked_Conversion;
with Interfaces;                 use Interfaces;

with STM32.SDMMC;                use STM32.SDMMC;
--with STM32.Board;                use STM32.Board;

with FAT_Filesystem;             use FAT_Filesystem;
with FAT_Filesystem.Directories; use FAT_Filesystem.Directories;
with Media_Reader.SDCard;        use Media_Reader.SDCard;

package body SDMemory.Driver is

   procedure Init_Filesys is begin
      null; -- TODO
   end Init_Filesys;

   procedure SDCard_Demo
   is
      SD_Controller : aliased SDCard_Controller;
      SD_Card_Info  : Card_Information;

      Units         : constant array (Natural range <>) of Character :=
        (' ', 'k', 'M', 'G', 'T');
      Capacity      : Unsigned_64;
      Error_State   : Boolean := False;

      FS             : FAT_Filesystem_Access;

      Status         : FAT_Filesystem.Status_Code;

      Dir            : Directory_Handle;
      Ent            : Directory_Entry;

   begin
      SD_Controller.Initialize;
      --Display.Initialize (Landscape, Interrupt);
      --Display.Initialize_Layer (1, RGB_565);

      loop
         if not SD_Controller.Card_Present then
            -- Display.Get_Hidden_Buffer (1).Fill (Black);
            -- Draw_String
--                (Display.Get_Hidden_Buffer (1),
--                 (0, 0),
--                 "No SD-Card detected",
--                 BMP_Fonts.Font12x12,
--                 HAL.Bitmap.Red,
--                 Transparent);
--              Display.Update_Layer (1);

            loop
               if Card_Present (SD_Controller) then
                  exit;
               end if;
            end loop;

         else
            Error_State := False;

            SD_Card_Info := SD_Controller.Get_Card_Information;

            --  Dump general info about the SD-card
            Capacity := SD_Card_Info.Card_Capacity;

            for Unit of Units loop
               if Capacity < 1000 or else Unit = 'T' then
--                    Draw_String
--                      (Display.Get_Hidden_Buffer (1),
--                       (0, Y),
--                       "SDcard size:" & Capacity'Img & " " & Unit & "B",
--                       BMP_Fonts.Font12x12,
--                       White,
--                       Transparent);
--                    Display.Update_Layer (1, True);
                  exit;
               end if;

               if Capacity mod 1000 >= 500 then
                  Capacity := Capacity / 1000 + 1;
               else
                  Capacity := Capacity / 1000;
               end if;
            end loop;

            FS := Open (SD_Controller'Unchecked_Access, Status);

            if Status /= OK then
               Error_State := True;

               if Status = No_MBR_Found then
                  null;
               elsif Status = No_Partition_Found then
                  null;
               else
                  --  Error reading the card: & Status'Img
                  null;
               end if;
            end if;

            if not Error_State then
               -- Volume_Label (FS.all) & " (" & File_System_Type (FS.all) & "):",

               if Open_Root_Directory (FS, Dir) /= OK then
                  --  !!! Error reading the root directory
                  Close (FS);
                  Error_State := True;
               end if;
            end if;

            if not Error_State then
               while Read (Dir, Ent) = OK loop
                  --  Name (Ent) & (if Is_Subdirectory (Ent) then "/" else ""),
                  null;
               end loop;

               Close (Dir);
               Close (FS);
            end if;

            loop
               if not Card_Present (SD_Controller) then
                  exit;
               end if;
            end loop;
         end if;
      end loop;

--     exception
--        when E : others =>
--           Display.Get_Hidden_Buffer (1).Fill (White);
--           Draw_String
--             (Display.Get_Hidden_Buffer (1),
--              (0, 0),
--              Ada.Exceptions.Exception_Information (E),
--              BMP_Fonts.Font12x12,
--              Black,
--              White);
--           Draw_String
--             (Display.Get_Hidden_Buffer (1),
--              (0, 14),
--              Ada.Exceptions.Exception_Message (E),
--              BMP_Fonts.Font12x12,
--              Black,
--              White);
--           Display.Update_Layer (1);
--
--           loop
--              null;
--           end loop;

   end SDCard_Demo;
end SDMemory.Driver;
