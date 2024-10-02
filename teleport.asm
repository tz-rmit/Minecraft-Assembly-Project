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

; R0 = x, R1 = y, R2 = z 
TRAP 0x31

; negate z (R2), store in R3
NOT R3, R2
ADD R3, R3, #1

; times y (R1) by 3, store in R1
ADD R6, R6, #2
ADD R5, R1, #0

X_LOOP
    ADD R1, R1, R5
    ADD R6, R6, #-1
    BRp X_LOOP

; get abs(x) (R0), store in R2
ADD R2, R0, #0
BRn NEGATE_X

CONT
; clear R0 and replace with R3
AND R0, R0, #0
ADD R0, R0, R3

TRAP 0x32

HALT

NEGATE_X
    NOT R2, R2
    ADD R2, R2, #1
    BR CONT

HALT
.END