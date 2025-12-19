LDM R1, 10      ; R1 = 10
JMP 2           ; Jump to (PC+1) + 2 = (1+1)+2 = 4. Skips addr 2 and 3.
LDM R1, 0xDEAD  ; [TRAP] Should be skipped. If executed, R1 dies.
LDM R1, 0xDEAD  ; [TRAP] Should be skipped.
LDM R2, 20      ; R2 = 20. (Success Target of JMP)
SUB R3, R1, R1  ; R3 = R1 - R1 = 0. Sets ZERO Flag.
JZ  1           ; Jump to (PC+1) + 1 = (6+1)+1 = 8. Skips addr 7.
LDM R4, 0xBAD   ; [TRAP] Should be FLUSHED. If executed, R4 becomes BAD.
LDM R4, 0xGOOD  ; R4 = 0xGOOD (Target of JZ).
LDM R5, 50      ; R5 = 50. End of test.