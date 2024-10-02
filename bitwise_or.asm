.ORIG x3000
; reset regs
AND R0, R0, #0
AND R1, R1, #0
AND R2, R2, #0
AND R3, R3, #0
AND R4, R4, #0
AND R5, R5, #0
AND R6, R6, #0
AND R7, R7, #0

TRAP 0x31


; get the first block ID
ADD R0, R0, #1
ADD R1, R1, #-1
TRAP 0x33
ADD R4, R3, #0


; second block ID
ADD R0, R0, #1
TRAP 0x33


; R3 OR R4 -> R3
NOT R3, R3
NOT R4, R4
AND R5, R3, R4
NOT R3, R5

ADD R0, R0, #1
TRAP 0x34

HALT
.END