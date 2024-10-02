.ORIG x3000

TRAP 0x31
ADD R0, R0, #1

ADD R4, R4, #1
JSR READ
ST R5, WORD_ONE

; reset position
TRAP 0x31
ADD R0, R0, #1
ADD R2, R2, #1
; reset R4
AND R4, R4, #0
ADD R4, R4, #1
; reset count and R5
LD R5, COUNT
AND R5, R5, #0
ST R5, COUNT
JSR READ
ST R5, WORD_TWO

; reset regs
AND R0, R0, #0
AND R1, R1, #0
AND R2, R2, #0
AND R3, R3, #0
AND R4, R4, #0
AND R5, R5, #0
AND R6, R6, #0
AND R7, R7, #0


LD R4, WORD_ONE
LD R5, WORD_TWO
; add them together
ADD R4, R4, R5
ST R4, NUMBER_TO_CONVERT
AND R4, R4, #0

; write the result
TRAP 0x31
ADD R0, R0, #1
ADD R2, R2, #2

; load num
LD R5, NUMBER_TO_CONVERT

; bound for pos.x
LD R6, MAX_BITS

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
; reads the word with lsb at (R0, R1, R2)
; outputs word to R5
; R4 must be #1 prior to calling
; R5 must be #0
; overrides R6
READ
    ; get block id
    TRAP 0x33

    ; if 1 add mask(R4) to sum(R5)
    ADD R3, R3, #0
    BRz SKIP
    ADD R5, R5, R4

    ; else do nothing
    SKIP
    ; shift mask
    ADD R4, R4, R4

    ; move to next block
    ADD R0, R0, #1

    ; increment counter
    LD R6, COUNT
    ADD R6, R6, #1
    ST R6, COUNT

    ; repeat if count is less than 16
    LD R3, MAX_BITS
    ADD R3, R3, R6
    BRn READ
    RET

HALT
COUNT .FILL #0
MAX_BITS .FILL #-16
WORD_ONE .BLKW	1
WORD_TWO .BLKW	1
NUMBER_TO_CONVERT .BLKW	1
MASK .FILL #1
.END