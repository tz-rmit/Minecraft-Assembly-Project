.ORIG x3000
; get pos
TRAP 0x31

ADD R0, R0, #2
ADD R2, R2, #2
JSR CREATE_LAMP

ADD R2, R2, #-4
JSR CREATE_LAMP

ADD R0, R0, #-4
JSR CREATE_LAMP

ADD R2, R2, #4
JSR CREATE_LAMP
HALT

CREATE_LAMP
    ; place stone
    LD R3, STONE
    TRAP 0x34

    ; place next stone
    ADD R1, R1, #1
    TRAP 0x34

    ; place glowstone
    ADD R1, R1, #1
    LD R3, GLOW
    TRAP 0x34

    ;reset height
    ADD R1, R1, #-2
    RET


HALT
STONE .FILL #1
GLOW .FILL #89
.END