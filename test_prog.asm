# Sample Program for Von Neumann Processor
# ----------------------------------------
# This program initializes registers, performs math,
# and stores the result to memory.

# 1. Initialize R1 = 10, R2 = 20
LDM R1, 10
LDM R2, 20

# 2. Arithmetic: R3 = R1 + R2 (should be 30)
ADD R3, R1, R2

# 3. Store Result: Mem[R2 + 0] = R3
# (Stores value 30 to Address 20)
STD R3, R2, 0

# 4. Modify R1: R1 = R1 + 1 (INC)
# Note: INC uses Format "INC Rdst" -> logic says opcode+rdst.
# Wait, assembler logic for INC: "Op Rdst".
INC R1

# 5. Logical: R4 = NOT R1
NOT R4

# 6. Infinite Loop (Jump to self)
# JMP Address (Relative or Absolute? Assembler logic: J-Type takes Imm)
# Assuming Absolute Jump.
# If code starts at 16 (0x10), 
# Instructions:
# 16: LDM R1, 10
# 17: LDM R2, 20
# 18: ADD R3...
# 19: STD...
# 20: INC...
# 21: NOT...
# 22: JMP 22
JMP 22
