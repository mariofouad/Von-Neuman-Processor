#	All numbers are in hex format
#	We always start by reset signal
# 	This is a commented line
#	You should ignore empty lines and commented ones
# ---------- Don't forget to Reset before you start anything ---------- #

.org 0			# means the code start at address zero, this could be written in 
			# several places in the file and the assembler should handle it

LDM R0, 1
LDM R1, AAAA
LDM R2, FFFF
INC R0
MOV R1, R4
NOT R1
MOV R0, R3
IN R0	# R0 = FFFF_FFFF
OUT R0
AND R5, R1, R0
MOV R0, R6
NOT R6
INC R0