;  Program to calculate fibonacci sequence and stop at first value over 255
RESERVE x y z
INIT:
  LDI 0
  STA y
  LDI 1
LOOP:
  STA x
  ADD y
  JIC HLT
  OUT
  STA z
  LDA x
  STA y
  LDA z
  JMP LOOP
HLT:
  HLT
