.ORIG x3000

;get block underfoot
TRAP 0x31
ADD R1, R1, #-1

LOOP
    ; check block is not air
    TRAP 0x33
    ADD R3, R3, #0
    ; if air halt
    BRz STOP
    ; else add to count in R6 and move to next block
    ADD R6, R6, #1
    ADD R0, R0, #1
    BR LOOP

STOP
HALT
.END