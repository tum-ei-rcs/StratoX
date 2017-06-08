# StratoX Weather Glider
This is a research firmware/software to control an unmanned fixed-wing glider model. Specifically,
a light-weight (below 1kg), unpowered delta-wing configuration with two elevon control surfaces.
This sofware is intended to run on autopilot hardware of the "Pixhawk" family (ARM Cortex-M4).

:warning: This software is a non-mature research project. Use it at your own risk. We recommend it as a 
benchmark for verification tools connected to SPARK 2014, or as source of inspiration for other projects.

TOC:
 1. [Overview](#overview) 
 1. [Installation](#install) 
 1. [Usage](#usage) 
 1. [Parts](#parts) 

<a name="overview"/>

## Overview
The purpose of the glider is to collect weather data (pressure, temperature, humidity) at very high
altitudes up to the stratosphere, and then "return back home" with the recorded data (neatly
residing on a microSD card and waiting to be analyzed). Since this glider has no propulsion, it 
requires a "carrier platform" to bring it up the the desired starting altitude. The proven and 
intended carrier platform is a helium-filled balloon (>2m³) that can climb at least to the chosen 
target altitude. There, the glider will disconnect itself from the carrier platform and start its
navigating flight back home.

![Alt text](/doc/fig/mission.png?raw=true "Mission Profile")

Therefore, the firmware supports a "mission profile" as follows:
 1. pre-flight check phase (sensor tests, GPS fix, etc.)
 2. climb monitoring phase (track altitude, proceed with detach sequence when target altitude is reached)
 3. detach sequence (mechanically unhitch from the carrier platform -- see section "Hitch")
 4. gliding + navigation phase (navigating, stabilizing attitude, homing)
 5. standby phase (after detection of landing, power down most systems and activate buzzer to ease recovery)

Logging of flight and weather data takes place the entire time.

<a name="install"/>

## Installation
This section describes how to setup our software for users and developers. Both users and developers
will need all the tools, because we do not provide pre-compiled releases.

### Which Branch?
We have two official branches:
 1. ***master***: this is where we develop. Includes the "newest stuff" that is considered usable, but
 not necessarily proven to be working in reality.
 2. ***stable***: Only firmware that successfully passed a test flight is located in this branch.

We usually rebase master into stable, when a flight test with master was considered successful. Potential
imperfect behavior is documented for these newly conceived stable versions.

Therefore, users should checkout the branch "stable", and developers must use "master".

### Required Tools
This software is written in SPARK 2014 and Ada 2012, using a slightly customized run-time system (RTS) to support
the platform and this project in the most appropriate way.

Required tools:
 * GNAT ARM toolchain, GPL2016
 * SPARK 2014 tools, version GPL2016
For both visit libre.adacore.com. Later versions might not work due to changes in GNAT (we are currently fixing this)

### Building Custom Run-Time System
Change into the subfolder `runtime/ravenscar-sfp-stm32f427` and run the script `rebuild.sh`. This uses the GNAT ARM tools
to build the packages of the Ravenscar RTS.

### Registering Custom Run-Time System
This step is necessary to "introduce" our custom Ada RTS to both GNAT and GNATprove.

#### Linux
First, we need to set a few temporary environment variables:
 * **GNATDIR** location of GNAT GPL 2016 ARM installation, e.g., `/opt/gnat-arm`
   * contains AdaCore's original bareboard run-time: `/opt/gnat-arm/arm-eabi/lib/gnat/ravenscar-sfp-stm32f4`
 * **SPARKDIR** location of SPARK (GPL or pro) installation, e.g., `/opt/spark`
 * **CPEERDIR**: optional, location of Codepeer installation, e.g., `/opt/codepeer`
 * **MYRTSDIR**: location of this repository's subfolder `runtime`: `/home/johndoe/async/StratoX.git/runtime/ravenscar-sfp-stm32f427` (referred to as MYRTSDIR)
   * contents: `adalib ada_object_path ada_source_path arch common gnarl-arch gnarl-common math obj ravenscar_build.gpr runtime_build.gpr runtime.xml`

To have gnatbuild and gnatprove recognize our custom RTS, we need to create softlinks for both installations to the location of our RTS folder. If GNAT and SPARK were installed into the same path, then the following two directories may coincide
```sh
# 1. show GNAT ARM the location of our custom RTS:
ln -s $MYRTSDIR $GNATDIR/arm-eabi/lib/gnat/
# 2. show SPARK the location of our custom RTS:
mkdir -p $SPARKDIR/share/spark/runtimes && ln -s $MYRTSDIR $SPARKDIR/share/spark/runtimes/
# 3. (optional, if codepeer is available)
ln -s $MYRTSDIR $CPEERDIR/libexec/codepeer/lib/gnat/.
```
   
#### Windows
TODO (let us know how)

### Debugger
To download this software onto the embedded target, a programmer/debugger is required. We recommend the ST-LINK V2 debugger because it is low cost and works out of the box.

#### Typical Debugging Session
Assuming Pixhawk his connected to 3DR radio transmitter (or TRX), and the receiver (or TRX) is at /dev/ttyUSB0:

```
st-util &
picocom -b 57600 /dev/ttyUSB0
```
Where picocom is an application reading the UART messages (thus showing "printfs") and must be installed prior to usage.
With st-util running, the "Debug" menu in GNAT programming studio is enabled.

<a name="usage"/>

## Usage
:warning: operating this glider system may be suject to regulations in your country, and require permissions from the authorities.
Please obtain clearances (and possibly insurance) before launching this system in public airspace.

This section describes how this software is used with a model airplane, which is an delta-wing glider,
how the glider can be monitored from a ground control station, and, finally, how the flight logs can
be downloaded and analyzed after the glider returned.

A rough part list (BOM) to build the glider is given in the last section of this README.

### Building the Flight Stack
The main project file is `software/stratox.gpr`. You can build as follows:
```sh
cd software
gprbuild -p -P stratox.gpr
```
The end of the output should look something like this:
```
arm-eabi-gnatbind boot.ali

The following additional restrictions may be applied to this partition:
pragma Restrictions (No_Access_Parameter_Allocators);
pragma Restrictions (No_Coextensions);
...
arm-eabi-gcc -c b__boot.adb
arm-eabi-gcc boot.o -Wl,--defsym=__stack_size=16384 -Wl,--gc-sections -Wl,--print-memory-usage -o boot
Memory region         Used Size  Region Size  %age Used
           flash:      490260 B         2 MB     23.38%
         sram123:       53272 B       192 KB     27.10%
             ccm:          0 GB        64 KB      0.00%
```
The binary to download on the target is `obj/boot`. We recommend to use the STLink V2 debugger to upload the binary.

### The Glider
This software was developed to stabilize and control a very specific airframe, which costs about $50 (HobbyKing "Ridge Rider"). 
It's a fixed-wing, unpowered glider named "RidgeRider", with a wingspan of around 900mm and a payload capacity of (according to our experience) up to 350g.

![Alt text](/doc/fig/glider.jpg?raw=true "Glider")

#### Hitch Connector
In this project, we use a mechanical hitch to detach from the carrier platform. The elevons double as actuators for that hitch.
In particular, when the elevons are fully deflected (pull up), then a rod that is connected to the lever of the actuator will
close this hitch, holding the tow rope in place. As soon as the elevators are fully deflected into reverse direction, the
hitch irreversively opens, the tow falls out, and the glider is free. By this mechanism, no additional hardware is required to
unhitch (e.g., separate actuators).

TODO: illustration goes here

Another option would be to use a Tungsten wire, and switch on a sufficiently high current that then cuts the tow rope. However,
we consider this as not as reliable due to very cold external temperatures, and also additional components are required (MOSFET, 
Tungsten wire, etc.) which then are only ballast after unhitching.

#### Actuators
These are included in the frame of the glider.

#### Embedded Target
As flight control computer, we use the hardware of the Pixhawk family. That is, this software works
for Pixhawk 2.4, and Pixhawk Lite V2.4. With some modifications (in particular, different PWM 
generation path, since they have no co-processor), PixRacer and AdaRacer can also be used. 
In the following, we explain the setup of the **Pixhawk Lite hardware** for using our software:

 * **Elevon Servos**: 
   * left at 7th pin, seen from the side of the USB/microSD slot.
   * right at 8th pin, seen from the side of the USB/microSD slot.
 * **Connecting the Buzzer**: Use AUX5, which is the 5th pin, seen from the side of the USB/microSD slot. Polarity is irrelevant.
 * **GPS**: Use the accordingly labeled port

#### Sensors
Required sensors are:
 * uBlox NEO-M8N GPS (UART) with HMC5883L magnetometer (I2C)
 * all other sensors are included on the embedded target

#### Power Supply
A battery is needed. Because of their high energy density, we recommend a LiPo battery. 
For the typical duration of weather flights, LiPo batteries for model airplanes can tolerate the 
preveiling temperaturs. The capacity should be around 600-800 mAh, 1 cell. To provide a 5V supply 
voltage for the Pixhawk, we recommend a low-power BEC (Pixhawk requires at most 2W), connected to
the 3rd pin, seen from the side of the USB/microSD slot.

#### Trim
Components must be placed in the "avionics bay", such that the center of gravity (CoG) is within 
the limits of the airframe.

#### Boot Sequence
After powering the PixLITE flight controller, the following happens:

1. Execution of Self Checks: blue LED '''FMU B/E''' is solid
   * LED off -> checking (up to 1 min...)
   * LED solid -> stuck
   * LED flashing -> checks passed
2. Double beep signal 
   * starting new mission
   * elevons are moving into HOLD position (please hitch to carrier platform now)
3. Waiting for GPS fix with HDOP <=20m, then memorize as home coordinate
4. Long beep signal:
   * GPX fix done and home coordinate saved
   * Ascend Timeout starts now

***Triple beep signal***: in-air reset (while recovering latest values from NVRAM)


### Post-Flight Analysis
 1. Eject the microSD card and download all files with extension *.log from the folder with the latest date (representing build date). There may be multiple files, each representing one boot of the software. Multiple boots can be present due to multiple power-up sequences, or due to in-air resets.
 2. Rename extension to *.px4log
 3. The format of the logs is similar to the logs of the (Pixhawk) PX4 flight stack. We have developed our own flight analysis software, which is available here: https://github.com/mbeckersys/MavLogAnalyzer Otherwise, you may also use the PX4 ecosystem of tools to read the logs

#### Log Contents
 * Glider attitude + position:
   * Position, velocity vector, acceleration, rates
   * GPS raw data
 * Weather data
   * temperature, pressure, ...
 * Debug info
   * exception info
   * message queue levels
 * ...

<a name="contrib"/>

## Issue Reporting, Contributing
If you want to contribute, report issues or propose enhancements, please let us know either via the issue tracker, or by contacting us directly.

### In-Air Reset
The firmware supports in-air reset in case an exception occurs. If the exception is in the logging task, no reset will happen.
Instead, the logging task is only frozen until the next reboot. Each reset is (if the logging task is still alive) indicated
in the logging data, including the line number and address of the exception that caused it.

Immediately after any reset, the firmware checks whether the mission was incomplete. If so, then the last known values for
various parameters (e.g., home coordinate) are restored from the NVRAM and the mission continues at its last known state.
For examplem if an exception occurs in the flight-critical task during the climb phase, then after reset, the values of the
climb monitoring algorithm (i.a.: reached altitude, position) are restored from NVRAM, and the climb monitoring continues
immediately, skipping the pre-flight checks.

<a name="parts"/>

## Part List (BOM)
Finally, we list all the parts to build the glider. The carrier platform (e.g., a helium balloon) is not included here.

**Position**  | **Price EUR** | **Comment**
------------- | ------------- | ------------
 ballon 800 | 99 | weight: 800g, volume: 2m³, diameter: 1.5m, e.g. [this one](https://www.stratoflights.com/en/shop/wetterballon-800/)
 special cord (tear strength 135N) | included with balloon 
 balloon gas 1.8m³  | 75 | e.g., 10 liter bottle w/ 200bar
 frame+servos  | 170  | [RidgeRider Slope Wing](http://www.hobbyking.com/hobbyking/store/__73986__HobbyKing_8482_Ridge_Ryder_Slope_Wing_EPO_913mm_PNF_UK_Warehouse_.html)
 BEC | 10 | provides 5V for Pixhawk
 battery | 10 | LiPo 2s, recommended 5Wh of energy
 avionics  | 200 | FCC: Pixhawk LITE 65$. GPS/Mag: ublox Mini NEO-M8N+HMC5983 Compass 40$
 insurance | 80 | e.g., Allianz AMU-300 in Germany
 clearance for take-off | varies | contact federal office of aviation
 GSM/GPS Tracker | 80 | optional, as back-up localization
 prepaid SIM card for GPS Tracker | 10 | optional, of back-up localization is used
 **Total**  | 650 - 740 EUR |
 
 You might want to add a camera and a telemetry downlink. 

