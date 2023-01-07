# PetVideoSim
Verilog simulations of Commodore PET video circuitry.

These are crude Verilog simulations of the Commodore PET 2001 and PET 2001N video circuits.
To creating these, I cobbled together some quick and dirty models for various 74xx TTL chips (in ttllib.v).
These models are incomplete and are not very well tested.  They really shouldn't be relied upon
as accurate.  Also, putting all those modules in one file is really bad form.

This is a small Vivado (Xilinx) project.  To create the project, clone the repository onto a Linux
machine, cd to the top directory and type "make project".  Then in Vivado, open the project at:
(top)/PetVideoSim/PetVideoSim.xpr.  There are two top simulations:  pet2001vid and dynamicpet.
You choose which one to run in the Simulation Settings menu.

Because Vivado is a large, unwieldy piece of software most people don't want to install or use, I will make an
attempt to create VCD files of both simulations and make them available somewhere (and I will update
this README with their location).
VCD files can be viewed using GtkWave which is an open source waveform viewer (See https://gtkwave.sourceforge.net/).
It's available on Linux by installing package "gtkwave".

For now, I have a VCD file on Google Drive:

https://drive.google.com/file/d/12FR8pZxCnjmvW9VoOwyYSXcHFgqAeEUd/view?usp=sharing

Download this and uncompress it with "gunzip".  View with gtkwave.  THIS FILE LOCATION WILL PROBABLY CHANGE!

-Thomas Skibo

Jan 2023
