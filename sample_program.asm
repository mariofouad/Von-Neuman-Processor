# ==========================================
# Von Neumann Processor - Sample Program
# ==========================================
# This program demonstrates valid instructions
# for the custom Assembler.

# 1. Register Initialization (Moving Data)
LDM R1, 5       # R1 = 5
LDM R2, 10      # R2 = 10
LDM R3, 1       # R3 = 1

# 2. Arithmetic Operations
ADD R4, R1, R2  # R4 = R1 + R2 = 15
SUB R5, R2, R1  # R5 = R2 - R1 = 5
INC R3          # R3 = R3 + 1 = 2

# 3. Memory Operations
# Store R4 (15) to Memory Address at R1 (5)
# Address = R1 + Offset(0) = 5. Mem[5] = 15.
STD R4, R1, 0   

# Load from Memory Address 5 into R6
# R6 = Mem[R1 + 0] = 15
LDD R6, R1, 0

# 4. Logical Operations
NOT R1          # R1 = ~R1
AND R7, R2, R3  # R7 = R2 & R3 = 10 & 2 = 2

# 5. Program Loop (Infinite)
# Jump back to start of loop (e.g. instruction 0 or here)
# Since we don't have labels yet, we use absolute address.
# Let's say this code starts at M[16].
# We just Jump to 16.
JMP 16     
