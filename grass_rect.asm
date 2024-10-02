.ORIG x3000
; get position
TRAP 0x31
ADD R1, R1, #-1

LD R3, X_DIST

; add x dist to x pos
ADD R4, R3, R0
ADD R4, R4, #1
; negate result and store
NOT R4, R4
ADD R4, R4, #1
ST R4, X_END

; subtract x dist from x pos and store
; R0 is now at x start
NOT R3, R3
ADD R3, R3, #1
ADD R0, R3, R0
ST R0, X_START

LD R3, Z_DIST

; add z dist to z pos
ADD R4, R3, R2
ADD R4, R4, #1
; negate result and store
NOT R4, R4
ADD R4, R4, #1
ST R4, Z_END

; set R2 to z start
NOT R3, R3
ADD R3, R3, #1
ADD R2, R2, R3

; now R0, R1, R2 points to the bottom corner of the rect
LD R3, BLOCK
LD R4, X_END
LD R5, Z_END
LOOP
    LD R0, X_START
    JSR PLACE_ROW
    ; advance to next row
    ADD R2, R2, #1
    ; check that it is in range
    ADD R6, R5, R2
    ; if it is in range LOOP
    BRn LOOP
    ; else halt
    HALT

HALT

; inputs: R0, R1, R2 = x, y, z 
;         R3 = block ID
;         R4 = x to stop at
PLACE_ROW
    TRAP 0x34
    ADD R0, R0, #1
    ADD R6, R4, R0
    BRn PLACE_ROW
    RET

HALT
; Note: Please do not change the names of the constants below
X_DIST .FILL #2
Z_DIST .FILL #3
BLOCK .FILL #2

X_START .BLKW #1
X_END .BLKW #1
Z_END .BLKW #1
.END