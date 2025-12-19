#	All numbers are in hex format
#	We always start by reset signal
# 	This is a commented line
#	You should ignore empty lines and commented ones
# ---------- Don't forget to Reset before you start anything ---------- #

.org 0			# means the code start at address zero, this could be written in 
			# several places in the file and the assembler should handle it

LDM R1, 5
NOP
INT 0
LDM R1, 10
NOP
NOP
NOP
LDM R2, 10
MOV R1, R4


