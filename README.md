# SAP1

## Purpose:

This collection of RTL is meant to model an 8-bit SAP1 computer, specifically based on
Ben Eater's whcih he describes in great detail [here](https://eater.net/8bit).

This project was part of my own learning experience of Computer Architecture and Verilog,
and I hope that this finds someone else whose intrigued and finds it helpful.

The bench is written in C++ and is compiled using [Verilator](https://www.veripool.org/wiki/verilator).

## Verilog Background

Verilog is an HDL (Hardware Description language). This means that you write "code" to describe
combinatorial and sequential nets. You should think as a hardware designer when you write Verilog and
should have some sense as to how your design will look in gates & flops & rams.

Verilog is built around the idea of a "module", which you can think of as a black box circuit. You define
the in ports and the out ports to the circuit and then can make instances of it elsewhere in your design.
These are analogous to the pins of an IC. Inside, you define the relationships of the inports and out ports.

You can also parameterize your modules - which means you can make several versions of it with different widths, for example.
Those can be defined by whoever instantiates the module.

Verilog has the idea of "wires" - which are combinational logic, and registers which are (usually) sequential logic.

I like to use the "ternary operator" like a mux, ie

    wire mux = (sel == 1'b0) ? a0 : a1;

This kind of logic is nice because I can visualize it very well, as opposed to if statements (especially when you
dont have parity betweeen them), but it is a lot of personal preference.

You can use similar logic for a register to only update it at "load"

    register r;
    always @(posedge mclk) r <= load ? load_data : r;
    
Note that assigning r to itself really just means we wont load in a new value this clock.
You cannot do this on a wire, a wire must always have something assigned to it (there cant be circular
combinational logic).

Hopefully thats enough to atleast start reading the code, but verilog is so deep that its impossible to cover much here.

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
clock, or if you are comfortable with synchronizers and debouncing tomanually toggle the clock.
It is safer to send the clock everywhere with an enable then to gate the clock directly using gates.

### ADV Microinstruction
I added the "Advance" microinstruction which immediately resets the instruction counter to 0.
This means we dont have to fill each instruction with NOPs and waste cycles there.

## Installation and Usage
This is tested to work on major Linux distros. You will need to install Verilator, gcc, and
ncurses (some distros will seperate into devel and non devel, you need the devel version).

From there, simply running *make* should be enough to verilate, build, and run your bench.
You should place your RAM file in "ram.hex". I've left an example in the repo.

The main bench is in *Top.cpp*. In the file you have the option to run in GUI mode, which lets you
step the clock and view registers changing (its simplistic, but functional), and you have the option
to dump the outputs to a trace file. This will create a \*.vcd which you can open with GTKWAVE.
This will show you all waveforms. You can combine these options, or run without the GUI and just dump
for faster, more scripted testing.

You also could make some C model of what you expect the Computer to do and then just use if statements to compare.
Then, if your program doesn't exit out, you will know that it succeeded - and viewing the waveform would be unnecessary.

You can make more benches and update the makefile appropriately if you like.

## Further Work
### Extending to 16 bits and beyond
Most of the design is parameterized so it should be pretty easy to exend bitwidths, etc. I'd love to
see what you make but likely will leave this as the "base" computer.
### Compiler
I'd love to make some scripts that take plain text and can compile to both Instruction\_Decoder.v and also use that file
to convert instructions into the ram file.
### Improve the GUI
Right now the Ncurses interface is a bit of a hack, I'd love to clean it up or possibly do a full GUI with QT or SDL or something.
Ideas I also has would be to have a key to pull up the entire contents of ram, to inject contents into RAM,
and also to maybe have a key file to convert what's in the instruction register to text "LDA/STA/etc"
### Use Enviorment Variables in Make
I'd like to modify the C++ program so I can run

    USE_GUI=0 GEN_TRACES=1 make

Or something like that, rather than recompiling. I can't imagine that being too hard.

### FPGA Implementation
#### Output Module
I didnt want to go through the trouble of making a binary to bcd converter then bd to 7seg.
Also, each FPGA will have a different port config to drive the 7segs (shift registers, act high, act low).
So that is an open excercise.
Currently, I am able to synthesize this design on Vivado when I map out\_data to a handful of LEDs.
#### Clocking
Eventually everything will need to be registered (most likely). This will change timing but it should be simple enough.
I also want to remove the negedge triggered counter for instruction counter. That might require counting 
wheter we are on an even or odd clock and alternating appropriately between "real clock" and "negedge clock".

## Screenshots

![Emulator Example](/screenshots/emulator_example.png?raw=true)

## Further Reading
I learned a lot about verilator and verilog from [ZipCpu](https://zipcpu.com/tutorial/), so I recommend
everyone to check out their blog as a first step.
