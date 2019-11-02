// Program to calculate fibonacci sequence and stop at first value over 255
1d    // 0x0 LDA d  grab X from RAM
2e    // 0x1 ADD e  A_Reg = X+Y
aa    // 0x2 JIC a  If carry, stop and DONT output
e0    // 0x3 OUT    ..
7f    // 0x4 STA f  Store Z=X+7
1d    // 0x5 LDA d  Y=X
7e    // 0x6 STA e  ..
1f    // 0x7 LDA f  X=Z
7d    // 0x8 STA d  ..
80    // 0x9 JMP 0  Loop
ff    // 0xa HLT    done
00    // 0xb NOP
00    // 0xc NOP
01    // 0xd "X"
00    // 0xe "Y"
00    // 0xf "Z"
