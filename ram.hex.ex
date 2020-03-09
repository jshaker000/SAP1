// Program to calculate fibonacci sequence and stop at first value over 255
// Unfortunately, this program cannot simply be reset, because I rely on the initialized values of
// X and Y. There is no store immediate command. (Maybe I can come up with something more clever)
1d    // addr:0x0 | LDA d  | Assing A_Reg = X
2e    // addr:0x1 | ADD e  | Assign A_Reg = X+Y
aa    // addr:0x2 | JIC a  | If carry, stop and DONT output
e0    // addr:0x3 | OUT    | Display output Z
7f    // addr:0x4 | STA f  | Store Z=X+Y
1d    // addr:0x5 | LDA d  | Store Y=X
7e    // addr:0x6 | STA e  | finish storing Y=X
1f    // addr:0x7 | LDA f  | Store X=Z
7d    // addr:0x8 | STA d  | finish storing X=Z
80    // addr:0x9 | JMP 0  | Loop to calculate next number
ff    // addr:0xa | HLT    | done
00    // addr:0xb | NOP    | unused
00    // addr:0xc | NOP    | unused
01    // addr:0xd | "X"    | initialize X to 1
00    // addr:0xe | "Y"    | initialize Y to 0
00    // addr:0xf | "Z"    | doesnt need to be anything, Z is written to before it is read
