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
    call    update_sprite_attrs
    call    dump_sprite_attrs_to_ram
    call    delay_wait_long
    ld      a,0
    ld      (player_winner),a
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
    ld      a,(goal_status)
    cp      0
    call    nz,check_goal_status
    ld      a,(player_winner)
    cp      0
    jr      nz,endgame

pausemode:
    ld	    a,(KEYMTX+7)                        ;escape key is in row 7...
	bit	    2,a                                 ;...bit 2. If it's pressed...
	jp	    z,exit                              ;...jump to exit

    ; jr      pausemode

    ;salir al meter un gol
    ; ld      a,(goal_status)
    ; cp      0
    ; jr      z,loop

    ;test incremento marcadores
    ; ld	    a,(KEYMTX+5)
	; bit	    7,a
    ; call    z,goal_player_1
    ; jr      pausemode

    jr      loop

endgame:
    ld      a,215
    ld      (ball_y),a
    ld      (ply1_y),a
    ld      (ply2_y),a
    call    update_sprite_attrs
    call    dump_sprite_attrs_to_ram
    ld	    a,(KEYMTX+8)
	bit	    0,a
    jr      nz,endgame

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
    ; ball_x:                 db      30
    ; ball_y:                 db      100
    ; ball_speed:             db      1
    ; computer_speed:         db      1
    ; ball_bounces:           db      0
    ; ply1_y:                 db      50
    ; ply2_y:                 db      80
    ; goal_status:   
    ld      a,126
    ld      (ball_x),a
    ld      a,96
    ld      (ball_y),a
    ld      (ply1_y),a
    ld      (ply2_y),a
    ld      a,1
    ld      (ball_speed),a
    ld      a,1
    ld      (computer_speed),a
    ld      a,0
    ld      (ball_bounces),a
    ld      (goal_status),a
    call    update_sprite_attrs
    call    dump_sprite_attrs_to_ram
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
    ; call    nc,goal_player_2
    ld      b,2
    call    nc,change_goal_status
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
    ; call    nc,goal_player_1
    ld      b,1
    call    nc,change_goal_status
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

change_goal_status:
    push    af
    ld      a,b
    ld      (goal_status),a
    pop     af
    ret
reset_goal_status
    push    af
    ld      a,0
    ld      (goal_status),a
    pop     af
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
; Check Goals
;------------------------------------------------------------------------
check_goal_status:
    ld      a,(goal_status)
    cp      1
    call    z,goal_player_1
    ld      a,(goal_status)
    cp      2
    call    z,goal_player_2
    call    reset_goal_status
    call    hide_ball
    call    delay_wait_long
    call    initialize_variables
    ret

;------------------------------------------------------------------------
; Player 1 Goal
;------------------------------------------------------------------------
goal_player_1:
    ld      a,(player_1_score)
    cp      9
    jr      nz,goal_player_1_ini
    ld      a,2
    ld      (player_winner),a
    ret

goal_player_1_ini:
    call    get_score_marker

    ld      hl,#186C
    ld      d,h
    ld      e,l
    push    hl
    ld      hl,tile_marker_blur
    call    marker_change
    pop     hl
    call    delay_wait_short
    
    ld      a,(player_1_score)
    call    get_score_marker
    ld      d,h
    ld      e,l
    push    hl
    ld      hl,tile_marker_off
    call    marker_change
    pop     hl
    call    delay_wait_short

    ld      a,(player_1_score)
    inc     a
    ld      (player_1_score),a

    ld      a,(player_1_score)
    call    get_score_marker
    ld      d,h
    ld      e,l
    push    hl
    ld      hl,tile_marker_blur
    call    marker_change
    pop     hl
    call    delay_wait_short

    ld      a,(player_1_score)
    call    get_score_marker
    ld      d,h
    ld      e,l
    push    hl
    ld      hl,tile_marker_on
    call    marker_change
    pop     hl

    ret

;------------------------------------------------------------------------
; Player 2 Goal
;------------------------------------------------------------------------
goal_player_2:
    ld      a,(player_2_score)
    cp      9
    jr      nz,goal_player_2_ini
    ld      a,2
    ld      (player_winner),a
    ret

goal_player_2_ini:
    call    get_score_marker

    ld      hl,#1871
    ld      d,h
    ld      e,l
    push    hl
    ld      hl,tile_marker_blur
    call    marker_change
    pop     hl
    call    delay_wait_short
    
    ld      a,(player_2_score)
    call    get_score_marker
    ld      d,h
    ld      e,l
    push    hl
    ld      hl,tile_marker_off
    call    marker_change
    pop     hl
    call    delay_wait_short

    ld      a,(player_2_score)
    inc     a
    ld      (player_2_score),a

    ld      a,(player_2_score)
    call    get_score_marker
    ld      d,h
    ld      e,l
    push    hl
    ld      hl,tile_marker_blur
    call    marker_change
    pop     hl
    call    delay_wait_short

    ld      a,(player_2_score)
    call    get_score_marker
    ld      d,h
    ld      e,l
    push    hl
    ld      hl,tile_marker_on
    call    marker_change
    pop     hl

    ret

hide_ball:
    ld      a,192               ;put ball sprite Y under screen limit
    ld      (ball_y),a
    ld      ix,ball_spr_attr    ;Update ball sprite attrs
    ld      a,(ball_y)
    ld      (ix+0),a
    ld      hl,ball_spr_attr    ;dump ball sprite attributes to VRAM
    ld      de,#1b00
    ld      bc,2
    call    LDIRVM
    ret

;------------------------------------------------------------------------
; Routines for changing the Score markers
;------------------------------------------------------------------------
marker_change
    ld      a,5
    ld      b,3
marker_change_ini:
    push    af
marker_change_step:
    push    bc
    ld      b,h
    ld      c,l
    push    hl
    ld      h,b
    ld      l,c
    bit     0,(ix)
    call    nz,change_marker_tile
    pop     hl
    pop     bc
    inc     ix
    inc     de
    dec     b
    jr      nz,marker_change_step
    ld      b,3

    push    hl
    ld      hl,29
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    
    pop     af
    dec     a
    jr      nz,marker_change_ini
    ret


change_marker_tile:
    push    de
    push    bc
    ld      bc,1
    call    LDIRVM
    pop     bc
    pop     de
    ret

get_score_marker:
    cp      0
    jr      z,get_score_marker_0
    cp      1
    jr      z,get_score_marker_1
    cp      2
    jr      z,get_score_marker_2
    cp      3
    jr      z,get_score_marker_3
    cp      4
    jr      z,get_score_marker_4
    cp      5
    jr      z,get_score_marker_5
    cp      6
    jr      z,get_score_marker_6
    cp      7
    jr      z,get_score_marker_7
    cp      8
    jr      z,get_score_marker_8
    cp      9
    jr      z,get_score_marker_9
get_score_marker_0:
    ld      ix,marker_0
    ret
get_score_marker_1:
    ld      ix,marker_1
    ret
get_score_marker_2:
    ld      ix,marker_2
    ret
get_score_marker_3:
    ld      ix,marker_3
    ret
get_score_marker_4:
    ld      ix,marker_4
    ret
get_score_marker_5:
    ld      ix,marker_5
    ret
get_score_marker_6:
    ld      ix,marker_6
    ret
get_score_marker_7:
    ld      ix,marker_7
    ret
get_score_marker_8:
    ld      ix,marker_8
    ret
get_score_marker_9:
    ld      ix,marker_9
    ret


;------------------------------------------------------------------------
; Delay Wait
;------------------------------------------------------------------------
delay_wait_short:
    ld      b,5
    jr      delay_wait_sync
delay_wait_long:
    ld      b,60
delay_wait_sync:
    halt
    djnz    delay_wait_sync
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
spr_ply1_1:             db #18,#38,#78,#78,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
spr_ply1_2:             db #F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#78,#78,#38,#18,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00

; Sprites - Player 2
spr_ply2_1:             db #C0,#E0,#F0,#F0,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
spr_ply2_2:             db #F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F8,#F0,#F0,#E0,#C0,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00

; Marker tile position
tile_marker_on:         db #08
tile_marker_blur:       db #28
tile_marker_off:        db #30

; Markers
; marker_0:               db #7B,#6F
; marker_0_blur:          db #28,#28,#28,#28,#30,#28,#28,#30,#28,#28,#30,#28,#28,#28,#28
marker_0:          db 1,1,1,1,0,1,1,0,1,1,0,1,1,1,1
marker_1:          db 0,0,1,0,0,1,0,0,1,0,0,1,0,0,1
marker_2:          db 1,1,1,0,0,1,1,1,1,1,0,0,1,1,1
marker_3:          db 1,1,1,0,0,1,0,1,1,0,0,1,1,1,1
marker_4:          db 1,0,1,1,0,1,1,1,1,0,0,1,0,0,1
marker_5:          db 1,1,1,1,0,0,1,1,1,0,0,1,1,1,1
marker_6:          db 1,1,1,1,0,0,1,1,1,1,0,1,1,1,1
marker_7:          db 1,1,1,0,0,1,0,0,1,0,0,1,0,0,1
marker_8:          db 1,1,1,1,0,1,1,1,1,1,0,1,1,1,1
marker_9:          db 1,1,1,1,0,1,1,1,1,0,0,1,1,1,1

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
player_winner:          db      0

;ball_spr_attr:          ds      4,0                    ;Y, X, escena, color
ball_spr_attr:          db      95, 122, #0, #0F        ;Y, X, escena, color

spr_ply1_1_attr:        db      64, 4, 4, 6        ;Y, X, escena, color
spr_ply1_2_attr:        db      80, 4, 8, 6        ;Y, X, escena, color

spr_ply2_1_attr:        db      79, 247, 12, 7        ;Y, X, escena, color
spr_ply2_2_attr:        db      95, 247, 16, 7        ;Y, X, escena, color


END:
    ret