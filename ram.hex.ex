// Program to calculate fibonacci sequence and stop at first value over 255

// INIT
40    // addr:0x0 | LDI 0  | initialize Y to 0
7e    // addr:0x1 | STA e  | continue initializing Y to 0
41    // addr:0x2 | LDI 1  | initialize X to 1
// LOOP
7d    // addr:0x3 | STA d  | Initialize X(first time) / Store X
2e    // addr:0x4 | ADD e  | Assign A_Reg = X+Y
ac    // addr:0x5 | JIC c  | If carry, stop and DONT output
e0    // addr:0x6 | OUT    | Display output Z
7f    // addr:0x7 | STA f  | Store Z=X+Y
1d    // addr:0x8 | LDA d  | Store Y=X
7e    // addr:0x9 | STA e  | finish storing Y=X
1f    // addr:0xa | LDA f  | Load X=Z
83    // addr:0xb | JMP 3  | Loop to calculate next number
ff    // addr:0xc | HLT    | done
// VARIABLES
aa    // addr:0xd | "X"    | These can default to anything as they are initialized before being read from
bb    // addr:0xe | "Y"    | You can therefore simple reset the program counter and instruction counter
cc    // addr:0xf | "Z"    | Without reporgramming these to reset the program
