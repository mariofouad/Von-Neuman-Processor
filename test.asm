# --- INITIALIZATION ---
LDM R1, 20      # R1 = 20 (0x14)
LDM R2, 10      # R2 = 10 (0x0A)
LDM R3, 5       # R3 = 5  (0x05)

# --- BUBBLE (Wait for registers to fill) ---
NOP
NOP
NOP

# --- TEST 1: SUBTRACTION (R4 = R1 - R2) ---
# Expected: 20 - 10 = 10 (0x0A)
SUB R4, R1, R2

# --- BUBBLE (Wait for result) ---
NOP
NOP
NOP

# --- TEST 2: LOGICAL AND (R5 = R2 AND R3) ---
# R2 = 10 (1010)
# R3 = 5  (0101)
# Expected: 1010 AND 0101 = 0 (0x00)
AND R5, R2, R3

# --- BUBBLE ---
NOP
NOP
NOP

# --- TEST 3: IMMEDIATE ADD (R6 = R1 + 5) ---
# Expected: 20 + 5 = 25 (0x19)
IADD R6, R1, 5

# --- BUBBLE ---
NOP
NOP
NOP

# --- TEST 4: ACCUMULATION (R7 = R1 + R2) ---
# Expected: 20 + 10 = 30 (0x1E)
ADD R7, R1, R2

HLT