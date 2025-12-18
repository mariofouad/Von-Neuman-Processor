# --- TEST 1: Unconditional Jump ---
JMP 20              # Jump to address 20
LDM R1, 2989        # (0xBAD) TRAP! Should be skipped
NOP                 
NOP
LDM R1, 51966       # (0xCAFE) Success! 

# --- TEST 2: Conditional Jump Taken ---
LDM R2, 0           # Set R2 = 0
JZ R2, 25           # Jump to address 25
LDM R2, 2989        # (0xBAD) TRAP! Should be skipped
NOP
LDM R3, 64206       # (0xFACE) Success!

# --- TEST 3: Conditional Jump NOT Taken ---
LDM R4, 1           # Set R4 = 1
JZ R4, 30           # Jump to 30 (Should NOT jump)
LDM R5, 48879       # (0xBEEF) Success! Should execute
NOP
HLT