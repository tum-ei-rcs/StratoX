
with System.Dim.Mks; use System.Dim.Mks;

package Sensors is

	subtype Data_Type is Float;
	type Timestamp_Type is Mks_Type with Dimension => (Symbol => 's', Second  => 1, others => 0);
	subtype Valid_Flag is Boolean;


	type Sensor_Data_Type is record
		Data : Data_Type := 0.0;
		isValid : Valid_Flag := FALSE;
	end record;

	function isDataValid();


end Sensors;
