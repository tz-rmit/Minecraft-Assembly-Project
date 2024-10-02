.ORIG x3000
; R0, R1, R2 = x, y, z
; R3 = block id
; R4 = bit mask/count
; R5 = num
; R6 = max bits
; R7 = temp use

TRAP 0x31
ADD R0, R0, #1

; load num
LD R5, NUMBER_TO_CONVERT

; bound for pos.x
LD R6, MAX_BITS
NOT R6, R6
ADD R6, R6, #1

LOOP
    ; ++ and store count and load the mask
    ADD R4, R4, #1
    ST R4, COUNT
    LD R4, MASK
    ; check the bit (mask AND num)
    AND R7, R5, R4

    

    ; if zero
    BRz ZERO
    ; else
    ; place blockID=1
    AND R3, R3, #0
    ADD R3, R3, #1
    TRAP 0x34
    CONT
    
    ; increment pos.x
    ADD R0, R0, #1
    
    ; shift mask and store
    ADD R4, R4, R4
    ST R4, MASK
    

    ; check count is <= 16
    LD R4, COUNT
    ADD R7, R4, R6
    
    BRn LOOP

HALT

ZERO
    ; place blockID=0
    AND R3, R3, #0
    TRAP 0x34
    BR CONT

HALT
;NUMBER_TO_CONVERT .FILL #21746 ; Note: Please do not change the name of this constant
NUMBER_TO_CONVERT .FILL #60553
MAX_BITS .FILL #16
COUNT .FILL #0
MASK .FILL #1
.END