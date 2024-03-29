# SAP1

## Purpose:

This collection of RTL is meant to model an 8-bit SAP1 computer as explained by Albert Paul Malvino,
but specifically based on Ben Eater's design he describes in great detail [here](https://eater.net/8bit).

This project was part of my own learning experience of Computer Architecture and Verilog,
and I hope that this finds someone else who finds it useful as an introduction to either topic.

The bench is written in C++ and is compiled using [Verilator](https://www.veripool.org/wiki/verilator).
I used the bench to generate dumps and a front ponel with ncurses.

For a more sophisticated design, see my [SAP2](https://github.com/jshaker000/SAP2).

## Theory of Operation

Malvino's SAP 1 has several components

    1. Two 8-bit general purpose registers (A and B)
    2. 16x1 byte RAM, which is addressed by:
    3. 4-bit Memory Address Register
    3. An 8-bit ALU which supports addition and subtraction between the A & B Registers.
    4. A Program counter and an Instruction Counter for microinstructions
    5. An 8-bit Instruction Register, which stores the current instruction.
    6. An 8-bit Bus which connects the above elements together
    7. Control Logic, which combines the Instruction Counter and the Instruction OpCode to
       decide what gets put on and what gets read from the bus, among other things.
    8. An Output Register

At the beginning, the program counter and Instruction Counter are both initialized to 0.
The Instruction Counter will increment on every Clock.

At the 1st and 2nd step (the value 0 and value 1 of the Instruction Counter) for every instruction

    0. The Program Counter gets put onto the Bus, and Read in by the Memory Address Register
    1. The Value from RAM is output to the Bus, and Read in by the Instruction Register. The Program Counter is incremented by 1 to prepare for the next instruction.

Each Instruction is made of 2 4-bit bit fields: the 4-bit OP Code and the 4-bit Argument.

The OpCode is combined with the Instruction Counter in the InstructionDecode module to produce appropriate control words for the remaining steps.

IE: LDA 15 (0x1F)

   2. Put 15 (F) [the argument] onto the bus, and load it into the Memory Address Register
   3. Put the output of RAM onto the bus, and load it into the A Register, also the Instruction Counter to 0 to start execution of the next instruction

This effectively copies the value RAM[Argument] into the A Register. Other instructions work similarly.
Its always an interesting decision to figure out how much you want to implement in hardware vs software, to try to help keep the other simple.

The ALU will latch flags such as carry, zero, or overflow at the end of each of its operations. These are used for conditional instructions,
such as JIZ (jump if zero). At least one conditional instruction is requried to make the machine turing complete.

An example program is attached in `example.asm`, and is automatically assembled by running `make` via `assembler.rb` to generate `ram.hex` unless that file already exists.
Running make runs the program in `ram.hex` so you can write and assemble your own code there if desired. Note that the assembler currently does not automatically stay in sync
with the `Instruction_Decoder.v` and will likely need edits if you need to update that file. These two files `assembler.rb` and `Instruction_Decoder.v` kind of show the brains of the
computer, how it does it and what it does.

The assembler file has a lot of comments explaining the valid syntax for it.

The control words are defined in `control_words.vi` to be shared between other files as needed.

## Tweaks from Ben's Machine
There are some modifications I made to make it more simulatable and easier for me to work with.
(I also think I changed some op codes but these are easy enough to figure out)

### Bus
Verilator does not like working with tri-state logic, so instead I am input everything that goes to the Bus
to the bus module as well as a *valid* signal (which is analogous to the data out control bit).
I and each valid with each signal and then OR-reduce each of those signals to make the bus. Only one valid should
ever be high so it's really identical functionally to the tri-state implementation.

### Clock Enable
I added a Clock Enable line. The idea is that if someone wants to synthesize and put this on a
real FPGA the clock would be far too fast. So you can use the Clock Enable Module to divide the
clock, or if you are comfortable with synchronizers and debouncing to manually toggle the clock.
It is safer to send the clock everywhere with an enable then to gate the clock directly using gates.

See the Clock Enable Module for an example.

### Instruction Counter
Changed from negedge to posedge so logic can run faster. Works just aswell, and no other design changes were needed.
This should allow the design to run faster.

### ADV Microinstruction
I added the "Advance" microinstruction which immediately resets the Instruction Counter to 0.
This means we dont have to fill each instruction with NOPs and waste cycles there.

## Installation and Usage
This is tested to work on major Linux distros. You will need to install Verilator, gcc, and
ncurses (some distros will seperate into devel and non devel, you need the devel version).

You will also need `ruby` installed to run the assembler, though I suppose it isnt technically needed if you dont
mind hand writing machine code.

From there, simply running *make* should be enough to verilate, build, and run your bench.

The main bench is in *Top.cpp*. In the file you have the option to run in GUI mode, which lets you
step the clock and view registers changing (its simplistic, but functional), and you have the option
to dump the outputs to a trace file. This will create a \*.vcd which you can open with GTKWAVE.
This will show you all waveforms. You can combine these options using enviornment variables.
Setting a variable to "1" will set it. Setting it to anything else, or leaving unset will keep it disabled.

The bench tries to prevent infinite loops by killing the simulation is more than `MAX_STEPS` clock cycles have passed.
You can freely set this to any integer you like.

IE

    USE_GUI=0 DUMP_TRACES=1 MAX_STEPS=10000 make

You can set the DUMP_F variable to name the vcd file (otherwise there is a default name).

You also could make some C model of what you expect the Computer to do and then just use if statements to compare.
Then, if your program doesn't exit out, you will know that it succeeded - and viewing the waveform would be unnecessary.
You can make more benches and update the makefile appropriately if you like.

## Further Work

### Extending to 16 bits and beyond
Most of the design is parameterized so it should be pretty easy to exend bitwidths, etc. I'd love to
see what you make but likely will leave this repo as the "base" computer.


### Improve the GUI
Right now the Ncurses interface is a bit of a hack, I'd love to clean it up or possibly do a full GUI with QT or SDL or something.
Ideas I also has would be to have a key to pull up the entire contents of ram, to inject contents into RAM,
and also to maybe have a key file to convert what's in the instruction register to text "LDA/STA/etc"

### FPGA Implementation
#### Output Module
You could implement a pipelined Double-Dabble Module and tie that output then the 7seg decoder. Many FPGAs then will have a scheme
that you enable only one Seven Seg Digit at a time, so you'll need a fast clock to shift through each BCD digit and drive it quick enough that it looks
like they are all being held at once.

I didnt want to go through the trouble of making a binary to bcd converter then bd to 7seg.
Also, each FPGA will have a different port config to drive the 7segs (shift registers, active high, active low).
So that is an open excercise.
Currently, I am able to synthesize this design on Vivado when I map out\_data to a handful of LEDs. (The whole design will be optimized out if there is no
output port)

#### Reset Line
Some ability to reset everyhting -> perhaps also have  "backup ram (functionally rom)" and some bootstrapping module to copy the backup ram
back into the main ram to easily restart

#### UART RAM Programming
Some way to reprogram the RAM from a computer / live so that we dont have to reelaborate and synthesisize and all each time would be nice.
Perhaps having a UART controller listen to a control word that turns the computer into RESET mode, allows you to program the RAM, and then lifts reset mode.
I don't think this would be too hard, honestly. This could be a plausible alternative to a reset line and having a backup Ram.


#### Add a Stack / other functionatilty
Self explanatory.

## Screenshots

![Emulator Example](/screenshots/emulator_example.png?raw=true)
