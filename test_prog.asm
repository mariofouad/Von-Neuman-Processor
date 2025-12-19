-- Assume SP starts at 0x03FF
LDM R1, 0x0005  -- Load 5 into R1
NOP             -- Fillers to avoid RAW hazards for now
NOP
NOP
PUSH R1         -- Memory[0x03FF] should become 5, SP should become 0x03FE
POP R2          -- SP should become 0x03FF, R2 should become 5