;------------------------------------------------------------------------
; HEADER FOR GENERATING A ROM FILE
;------------------------------------------------------------------------
;     output "../output/msxpong.rom"

;     defpage 0,4000h,16384
;     ; defpage 1,8000h

;     page 0

;     code @ 4000h

; romheader
;     byte "AB"
;     word START
;     word 0,0,0,0,0,0

;     code
;------------------------------------------------------------------------
; END OF HEADER
;------------------------------------------------------------------------

;------------------------------------------------------------------------
; HEADER FOR GENERATING A BIN FILE - OPEN FROM BASIC
;------------------------------------------------------------------------
    output "../output/msxpong.bin"

    db #fe                  ;cabecera de ficheros que seran cargados con BLOAD desde basic
    dw START
    dw END
    dw START

    org     #8200           ;starting point of the program in RAM
;------------------------------------------------------------------------
; END OF HEADER
;------------------------------------------------------------------------

CHGET   equ     #009F
CHPUT   equ     #00A2
POSIT   equ     #00C6
INLIN   equ     #00B1
GTTRIG  equ     #00D8
GTSTCK  equ     #00D5

RDVDP   equ     #013E       ;lee registro status VDP
WRTVDP  equ     #0047       ;escribe registros del VDP
LDIRVM  equ     #005C       ;RAM/ROM -> VRAM
LDIRMV  equ     #0059       ;VRAM -> RAM
CHGMOD  equ     #005F       ;change screen mode

BEEP    equ     #00C0       ;generates beep
KEYMTX	equ     #FBE5       ;read the keys (Key Matrix, http://map.tni.nl/articles/keymatrix.php)


RG0SAV  equ     #F3DF       ;Mirror fo VDP register 0 (Basic: VDP(0))
RG1SAV  equ     #F3E0       ;Mirror fo VDP register 0 (Basic: VDP(0))
RG2SAV  equ     #F3E1       ;Mirror fo VDP register 0 (Basic: VDP(0))
RG3SAV  equ     #F3E2       ;Mirror fo VDP register 0 (Basic: VDP(0))
RG4SAV  equ     #F3E3       ;Mirror fo VDP register 0 (Basic: VDP(0))
RG5SAV  equ     #F3E4       ;Mirror fo VDP register 0 (Basic: VDP(0))
RG6SAV  equ     #F3E5       ;Mirror fo VDP register 0 (Basic: VDP(0))
RG7SAV  equ     #F3E6       ;Mirror fo VDP register 0 (Basic: VDP(0))
STATFL  equ     #F3E7       ;Mirror fo VDP(8) status register (S#0)



START:
    call    initialize_video
    call    initialize_tiles_and_sprites
    call    initialize_variables
    ; call    CHGET

loop:
    halt
    call    check_collisions
    call    update_ball_deltas
    call    update_ball_position
    call    update_computer_player
    call    update_player_1_controls
    call    update_sprite_attrs
    call    dump_sprite_attrs_to_ram

pausemode:
    ld	    a,(KEYMTX+7)                        ;escape key is in row 7...
	bit	    2,a                                 ;...bit 2. If it's pressed...
	jp	    z,exit                              ;...jump to exit

    ; jr      pausemode

    ld      a,(goal_status)
    cp      0
    jr      z,loop

exit:
    ret


initialize_video:
    ld      a,2                                 ;change to Screen 2
    call    CHGMOD

    ld      a,(RG1SAV)
    or      00000010b                           ;force 16x16 sprites (screen 2,2)
    and     11111110b                           ;sprites wont be extended

    ld      b,a
    ld      c,1
    call    WRTVDP                              ;writes all to the VDP register 1
    ret


initialize_tiles_and_sprites:
    ld      hl,tiles_data                       ;load tiles
    ld      de,#0000
    ld      bc,256*24
    call    LDIRVM
    

    ld      hl,tiles_color                      ;load tile colors
    ld      de,#2000
    ld      bc,256*24
    call    LDIRVM

    
    ld      hl,screen_data                      ;load screen tile pattern
    ld      de,#1800
    ld      bc,256*3
    call    LDIRVM

    ld      hl,spr_ball                       ;load ball sprite
    ld      de,#3800
    ld      bc,8*4
    call    LDIRVM

    ld      hl,spr_ply1_1                       ;load player 1 sprite 1
    ld      de,#3820
    ld      bc,8*4
    call    LDIRVM
    ld      hl,spr_ply1_2                       ;load player 1 sprite 2
    ld      de,#3840
    ld      bc,8*4
    call    LDIRVM

    ld      hl,spr_ply2_1                       ;load player 2 sprite 1
    ld      de,#3860
    ld      bc,8*4
    call    LDIRVM
    ld      hl,spr_ply2_2                       ;load player 2 sprite 2
    ld      de,#3880
    ld      bc,8*4
    call    LDIRVM

    ret
    

initialize_variables:
    ret

dump_sprite_attrs_to_ram:
    ld      hl,ball_spr_attr                    ;set ball sprite attributes
    ld      de,#1b00
    ld      bc,4

    call    LDIRVM
    ld      hl,spr_ply1_1_attr                  ;set attributes for player 1 sprite 1
    ld      de,#1b04
    ld      bc,4
    call    LDIRVM
    ld      hl,spr_ply1_2_attr                  ;set attributes for player 1 sprite 2
    ld      de,#1b08
    ld      bc,4
    call    LDIRVM

    ld      hl,spr_ply2_1_attr                  ;set attributes for player 2 sprite 1
    ld      de,#1b0c
    ld      bc,4
    call    LDIRVM
    ld      hl,spr_ply2_2_attr                  ;set attributes for player 2 sprite 2
    ld      de,#1b10
    ld      bc,4
    call    LDIRVM

    ret

;------------------------------------------------------------------------
; Update ball increments
;------------------------------------------------------------------------
update_ball_deltas:
    ld      a,(ball_y)                          ;load ball y position into a registry
    cp      178                                 ;compare with 178 (max y is 191)
    jr      nc,change_ball_delta_y              ;jump if y position greater
    cp      6                                   ;compare with 6
    jr      c,change_ball_delta_y               ;jump if lower

check_delta_x:
    ; ld      a,(ball_x)
    ; cp      247
    ; jp      END
    ; cp      4
    ; jp      END
delta_ret:
    ret

change_ball_delta_y:
    ; ld      a,(ball_bounces)
    ; inc     a
    ; ld      (ball_bounces),a
    ld      a,(ball_y_inc)                      
    cp      1
    jr      z,change_ball_delta_y_negative
    ld      a,(ball_y)                          ;substract a pixel from x
    add     a
    ld      (ball_y),a                          ;end of substract
    ld      a,1
    ld      (ball_y_inc),a
    jp      check_delta_x
change_ball_delta_y_negative:
    ld      a,(ball_y)                          ;add a pixel to y
    dec     a
    ld      (ball_y),a
    ld      a,0                                 ;now change delta
    ld      (ball_y_inc),a
    jp      check_delta_x

; change_ball_delta_x:
;     ld      a,(ball_bounces)
;     inc     a
;     ld      (ball_bounces),a
;     ld      a,(ball_x_inc)                      
;     cp      1
;     jr      z,change_ball_delta_x_negative
;     ld      a,(ball_x)                          ;substract a pixel from x
;     add     a
;     ld      (ball_x),a                          ;end of substract
;     ld      a,1
;     ld      (ball_x_inc),a
;     jp      delta_ret
; change_ball_delta_x_negative:
;     ld      a,(ball_x)                          ;add a pixel to x
;     dec     a
;     ld      (ball_x),a
;     ld      a,0                                 ;now change delta
;     ld      (ball_x_inc),a
;     jp      delta_ret

;------------------------------------------------------------------------
; Update ball position
;------------------------------------------------------------------------
update_ball_position:
    ld      a,(ball_y_inc)
    cp      1
    jp      z,ball_y_increase

    ld      a,(ball_speed)
    ld      b,a
    ld      a,(ball_y)
    call    loop_position_decrement
    ld      (ball_y),a

update_pos_x:    
    ld      a,(ball_x_inc)
    cp      1
    jr      z,ball_x_increase
    
    ld      a,(ball_speed)
    ld      b,a
    ld      a,(ball_x)
    call    loop_position_decrement
    cp      249 ;ojo
    call    nc,goal_player_2
    ld      (ball_x),a
update_ret:
    ret


ball_y_increase:
    ld      a,(ball_speed)
    ld      b,a
    ld      a,(ball_y)
    call    loop_position_increment
    ld      (ball_y),a
    jr      update_pos_x

ball_x_increase:
    ld      a,(ball_speed)
    ld      b,a
    ld      a,(ball_x)
    call    loop_position_increment
    cp      249
    call    nc,goal_player_1
    ld      (ball_x),a
    jr      update_ret


loop_position_increment
    inc     a
    djnz    loop_position_increment
    ret

loop_position_decrement
    dec     a
    djnz    loop_position_decrement
    ret


;------------------------------------------------------------------------
; Update computer player
;------------------------------------------------------------------------
update_computer_player:
    ld      a,(ply2_y)
    ld      b,a
    ld      a,(ball_y)
    cp      b
    jr      z,update_computer_player_finish
    jr      c,update_computer_player_decrease
    ld      a,(computer_speed)
    ld      b,a
    ld      a,(ply2_y)
    add     a,b
    ld      (ply2_y),a
    jr      update_computer_player_finish
update_computer_player_decrease:
    ld      a,(computer_speed)
    ld      b,a
    ld      a,(ply2_y)
    sub     a,b
    ld      (ply2_y),a
update_computer_player_finish
    ret

;------------------------------------------------------------------------
; Update Player from controls
;------------------------------------------------------------------------
update_player_1_controls
    xor     a
    call    GTSTCK
    cp      1
    jr      z,move_player_1_up
    cp      5
    jr      z,move_player_1_down
    jr      update_player_1_controls_finish
move_player_1_up
    ld      a,(ply1_y)
    sub     a,3
    ld      (ply1_y),a
    cp      16
    jr      nc,update_player_1_controls_finish
    ld      a,16
    ld      (ply1_y),a
    jr      update_player_1_controls_finish
move_player_1_down
    ld      a,(ply1_y)
    add     a,3
    ld      (ply1_y),a
    cp      175
    jr      c,update_player_1_controls_finish
    ld      a,175
    ld      (ply1_y),a
update_player_1_controls_finish:
    ret

;------------------------------------------------------------------------
; Check collisions
;------------------------------------------------------------------------
check_collisions:
    ld      a,(STATFL)
    bit     5,a
    jr      z,check_collisions_end

    ld      a,(ball_bounces)                    ;increase ball bounces
    inc     a
    ld      (ball_bounces),a
    ld      a,(ball_speed)                      ;if ball speed is equal a number, continue
    cp      4
    jr      z,continue_collision
    ld      a,(ball_bounces)                    ;if ball bounces dont reach a number, continue
    cp      4
    jr      nz,continue_collision
    ld      a,0                                 ;reset ball bounces to 0
    ld      (ball_bounces),a
    ld      a,(ball_speed)                      ;increase ball speed
    inc     a
    ld      (ball_speed),a
    cp      4                                   ;increase computer speed if it lower than 3
    jr      nc,continue_collision
    ld      (computer_speed),a

continue_collision:
    ld      a,(ball_x_inc)
    cp      1
    jr      z,ball_collision_set_decrease

    ; ld      a,(ball_x)
    ; cp      #F8
    ; jr      nc,check_collisions_end

    ld      a,1
    ld      (ball_x_inc),a
    ld      a,9
    ld      (ball_x),a
    jr      check_collisions_end
ball_collision_set_decrease:
    ld      a,0
    ld      (ball_x_inc),a
    ld      a,240
    ld      (ball_x),a
check_collisions_end:
    ret

;------------------------------------------------------------------------
; Update sprite attributes
;------------------------------------------------------------------------
update_sprite_attrs:
    ld      ix,ball_spr_attr    ; Update ball attrs
    ld      a,(ball_y)          ; ball Y coordinate
    ld      (ix+0),a
    ld      a,(ball_x)          ; ball X coordinate
    ld      (ix+1),a

    ld      ix,spr_ply1_2_attr  ; Update player 1 attrs
    ld      a,(ply1_y)          ; player 1 Y coordinate
    ld      (ix+0),a
    ld      ix,spr_ply1_1_attr  ; Update player 1 attrs
    sub     a,16
    ld      (ix+0),a

    ld      ix,spr_ply2_2_attr  ; Update player 2 attrs
    ld      a,(ply2_y)          ; player 2 Y coordinate
    ld      (ix+0),a
    ld      ix,spr_ply2_1_attr  ; Update player 2 attrs
    sub     a,16
    ld      (ix+0),a
    ret

;------------------------------------------------------------------------
; Player 1 Goal
;------------------------------------------------------------------------
goal_player_1:
    ld      a,1
    ld      (goal_status),a
    ld      a,249
    ; call    BEEP
    ret

;------------------------------------------------------------------------
; Player 2 Goal
;------------------------------------------------------------------------
goal_player_2:
    ld      a,2
    ld      (goal_status),a
    ld      a,0
    ; call    BEEP
    ret

;------------------------------------------------------------------------
; CONSTANTS
;------------------------------------------------------------------------

;Tiles
tiles_data:             incbin "bin/pong_tiles.til"
tiles_color:            incbin "bin/pong_tiles.col"
screen_data:            incbin "bin/pong_screen.dat"

;Sprites - Ball
;spr_ball_1:             db  #07,#1F,#33,#6F,#7F,#FF,#FF,#FF,#FF,#FF,#7F,#7F,#3F,#1F,#07,#00,#C0,#F0,#F8,#FC,#FC,#FE,#FE,#FE,#FE,#FE,#FC,#FC,#F8,#F0,#C0,#00

spr_ball:               db #38,#7C,#FE,#FE,#FE,#7C,#38,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00

; Sprites - Player 1
spr_ply1_1:              db #18,#38,#78,#78,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
spr_ply1_2:              db #F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#78,#78,#38,#18,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00

; Sprites - Player 2
spr_ply2_1:              db #C0,#E0,#F0,#F0,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
spr_ply2_2:              db #F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F0,#F0,#E0,#C0,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00





;------------------------------------------------------------------------
; VARIABLE DEFINITION
;------------------------------------------------------------------------
ball_x:                 db      30
ball_y:                 db      100
ball_x_inc:             db      1
ball_y_inc:             db      1
ball_speed:             db      1
ball_bounces:           db      0
ply1_y:                 db      50
ply2_y:                 db      80
computer_speed:         db      1
goal_status:            db      0                   ; 0:no goal, 1:goal player 1, 2:goal player 2
player_1_score:         db      0
player_2_score:         db      0

;ball_spr_attr:          ds      4,0                    ;Y, X, escena, color
ball_spr_attr:          db      80, 100, #0, #0F        ;Y, X, escena, color

spr_ply1_1_attr:        db      64, 4, 4, 6        ;Y, X, escena, color
spr_ply1_2_attr:        db      80, 4, 8, 6        ;Y, X, escena, color

spr_ply2_1_attr:        db      64, 247, 12, 7        ;Y, X, escena, color
spr_ply2_2_attr:        db      80, 247, 16, 7        ;Y, X, escena, color

END:
    ret