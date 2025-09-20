; Dodge Game: "SPACE DODGE" (multiple meteors)
; 8086-compatible (emu8086) + DOSBox
; Full program: start screen, gameplay, score, restart/quit, ASCII art banners.
; Multiple meteors support (MAX_METEORS)

org 100h

; ------------------------------------------------------------------
; Configuration
; ------------------------------------------------------------------
MAX_METEORS  equ 4       ; change to 2 or 3 to reduce difficulty

.data

creator_msg db 13,10,'                           Game created by: syfr',13,10,'$'
; --- Title ASCII art (pre-centered by spaces) ---
title_art1 db '    _____   ____    ___    _____  ______  ____    ____    ____    _____  ______  ',13,10,'$'
title_art2 db '   / ___/  / __ \  /   |  / ___/ / ____/ / __ \  / __ \  / __ \  / ___/ / ____/  ',13,10,'$'
title_art3 db '   \__ \  / /_/ / / /| | / /    / __/   / / / / / / / / / / / / / / _  / __/     ',13,10,'$'
title_art4 db '  ___/ / / /___/ / /-| |/ /__  / /___  / /_/ / / /_/ / / /_/ / / /_// / /___     ',13,10,'$'
title_art5 db ' /____/ /_/     /_/  |_|\____//_____/ /_____/  \____/ /_____/  \___/ /_____/     ',13,10,'$'
title_hint db 13,10,'                   Press any key to start  (Use < > to move)    $'

; --- Game over ASCII art (pre-centered) ---
gameover_art1 db '         ¦¦¦¦¦¦  ¦¦¦¦¦  ¦¦¦    ¦¦¦ ¦¦¦¦¦¦  ¦¦¦¦¦¦ ¦¦      ¦¦ ¦¦¦¦¦¦ ¦¦¦¦¦¦   ',13,10,'$'
gameover_art2 db '        ¦¦      ¦¦   ¦¦ ¦¦¦¦  ¦¦¦¦ ¦¦      ¦¦  ¦¦  ¦¦    ¦¦  ¦¦     ¦¦  ¦¦   ',13,10,'$'
gameover_art3 db '        ¦¦  ¦¦¦ ¦¦¦¦¦¦¦ ¦¦ ¦¦¦¦ ¦¦ ¦¦¦¦¦   ¦¦  ¦¦   ¦¦  ¦¦   ¦¦¦¦¦  ¦¦¦¦¦¦   ',13,10,'$'
gameover_art4 db '        ¦¦   ¦¦ ¦¦   ¦¦ ¦¦  ¦¦  ¦¦ ¦¦      ¦¦  ¦¦    ¦¦¦¦    ¦¦     ¦¦  ¦¦   ',13,10,'$'
gameover_art5 db '         ¦¦¦¦¦¦ ¦¦   ¦¦ ¦¦      ¦¦ ¦¦¦¦¦¦  ¦¦¦¦¦¦     ¦¦     ¦¦¦¦¦¦ ¦¦   ¦¦  ',13,10,'$'

gameover_label db 13,10,'                               *** GAME OVER ***',13,10,'$'
your_score_msg db 13,10,'                                 Your score: $'
againmsg db 13,10,'                       Press R to restart or Q to quit...$',13,10,'$'

; --- Gameplay data ---
playerCol db 40                    ; spaceship center column (1..78)

; arrays for multiple meteors
fallRows  db MAX_METEORS dup(0)    ; each meteor's row (0..24)
; initial columns are spread out; RNG will randomize when they reset
fallCols  db 10,30,50,70           ; adjust values if MAX_METEORS < 4

score     dw 0        ; number of dodged meteors

seed      dw 0A5Aah    ; RNG seed (changeable)

; Delay tuning (adjust to taste; lower = faster)
DELAY_OUTER dw 1
DELAY_INNER dw 32000

.code
; ------------------------------------------------------------------
; MAIN
; ------------------------------------------------------------------
main proc
    ; set ES to video memory (B800h)
    mov ax,0B800h
    mov es,ax

start_screen:
    ; clear screen via BIOS
    call bios_clear

    ; print big title lines (they are pre-centered)
    mov dx, offset title_art1
    call print_string
    mov dx, offset title_art2
    call print_string
    mov dx, offset title_art3
    call print_string
    mov dx, offset title_art4
    call print_string
    mov dx, offset title_art5
    call print_string

    mov dx, offset title_hint
    call print_string
    
    mov dx, offset creator_msg
    call print_string

    ; wait for any key
    mov ah,0
    int 16h

    ; clear before starting
    call bios_clear

    ; reset game variables
    mov byte ptr [playerCol], 40
    mov word ptr [score], 0

    ; initialize meteors: rows = 0, keep initial columns (or randomize)
    mov cx, MAX_METEORS
    xor si, si
init_meteors:
    mov byte ptr [fallRows + si], 0
    ; fallCols already have starting values in data
    inc si
    loop init_meteors

game_loop:
    call erase_falling
    call erase_player

    call read_input
    call update_falling

    call draw_player
    call draw_falling

    call check_collision

    call delay_per_row
    jmp game_loop

    ; normal exit
    mov ah,4Ch
    int 21h
main endp

; ------------------------------------------------------------------
; BIOS clear screen (INT 10h AH=06h)
; ------------------------------------------------------------------
bios_clear proc
    push ax
    push bx
    push cx
    push dx

    mov ah,06h     ; scroll up (clear)
    mov al,0       ; lines to scroll (0 = clear entire window)
    mov bh,07h     ; attribute for blank lines
    mov cx,0       ; upper left (row/col)
    mov dx,184Fh   ; lower right (row/col)
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
bios_clear endp

; ------------------------------------------------------------------
; DRAW PLAYER "<^>" (bottom row = 24)
; ------------------------------------------------------------------
draw_player proc
    push ax
    push bx

    mov ax,24
    mov bx,160
    mul bx           ; AX = 24*160
    mov di,ax

    mov al,[playerCol]
    xor ah,ah
    add ax,ax        ; AX = col*2
    add di,ax

    mov byte ptr es:[di-2], '<'
    mov byte ptr es:[di-1], 0Bh

    mov byte ptr es:[di], '^'
    mov byte ptr es:[di+1], 0Bh

    mov byte ptr es:[di+2], '>'
    mov byte ptr es:[di+3], 0Bh

    pop bx
    pop ax
    ret
draw_player endp

erase_player proc
    push ax
    push bx

    mov ax,24
    mov bx,160
    mul bx
    mov di,ax

    mov al,[playerCol]
    xor ah,ah
    add ax,ax
    add di,ax

    mov byte ptr es:[di-2], ' '
    mov byte ptr es:[di-1], 07h

    mov byte ptr es:[di], ' '
    mov byte ptr es:[di+1], 07h

    mov byte ptr es:[di+2], ' '
    mov byte ptr es:[di+3], 07h

    pop bx
    pop ax
    ret
erase_player endp

; ------------------------------------------------------------------
; DRAW / ERASE FALLING METEORS (all)
; ------------------------------------------------------------------
draw_falling proc
    push ax
    push bx
    push cx
    push si
    push di

    mov cx, MAX_METEORS
    xor si, si            ; index 0

df_loop:
    ; compute DI = row * 160
    mov al, [fallRows + si]
    xor ah, ah
    mov bx, 160
    mul bx                ; DX:AX = row * 160
    mov di, ax

    ; add col*2
    mov al, [fallCols + si]
    xor ah, ah
    add ax, ax            ; AX = col*2
    add di, ax

    mov byte ptr es:[di], '@'
    mov byte ptr es:[di+1], 0Ch

    inc si
    loop df_loop

    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
draw_falling endp

erase_falling proc
    push ax
    push bx
    push cx
    push si
    push di

    mov cx, MAX_METEORS
    xor si, si

ef_loop:
    mov al, [fallRows + si]
    xor ah, ah
    mov bx, 160
    mul bx
    mov di, ax

    mov al, [fallCols + si]
    xor ah, ah
    add ax, ax
    add di, ax

    mov byte ptr es:[di], ' '
    mov byte ptr es:[di+1], 07h

    inc si
    loop ef_loop

    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
erase_falling endp

; ------------------------------------------------------------------
; UPDATE FALLING: advance each meteor; when passes bottom -> score & RNG
; ------------------------------------------------------------------
update_falling proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov cx, MAX_METEORS
    xor si, si

uf_loop:
    mov al, [fallRows + si]
    inc al
    mov [fallRows + si], al

    cmp al, 24
    jle uf_skip

    ; meteor passed bottom -> increment score
    inc word ptr [score]

    ; reset to top
    mov byte ptr [fallRows + si], 0

    ; RNG: seed = seed * 25173 + 13849
    mov ax, [seed]
    mov bx, 25173
    mul bx
    add ax, 13849
    adc dx, 0
    mov [seed], ax

    ; use low byte as random column, limit 0..77
    mov al, al
    and al, 7Fh
    cmp al, 77
    jbe uf_colok
    mov al, 77
uf_colok:
    mov [fallCols + si], al

uf_skip:
    inc si
    loop uf_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
update_falling endp

; ------------------------------------------------------------------
; READ INPUT: arrow keys + ESC
; ------------------------------------------------------------------
read_input proc
    push ax
    push bx

    mov ah,1
    int 16h
    jz ri_done
    mov ah,0
    int 16h      ; AL = ascii, AH = scan code

    cmp ah,4Bh   ; left arrow
    jne ri_check_right
    mov al,[playerCol]
    cmp al,1
    jb ri_done
    dec byte ptr [playerCol]
    jmp ri_done

ri_check_right:
    cmp ah,4Dh   ; right arrow
    jne ri_esc
    mov al,[playerCol]
    cmp al,78
    jae ri_done
    inc byte ptr [playerCol]
    jmp ri_done

ri_esc:
    cmp al,27
    jne ri_done
    mov ah,4Ch
    int 21h

ri_done:
    pop bx
    pop ax
    ret
read_input endp

; ------------------------------------------------------------------
; CHECK COLLISION: test all meteors; on hit show GAME OVER screen
; ------------------------------------------------------------------
check_collision proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov cx, MAX_METEORS
    xor si, si

cc_loop:
    mov al, [fallRows + si]
    cmp al, 24
    jne cc_next

    mov al, [fallCols + si]
    mov bl, [playerCol]

    cmp al, bl
    je cc_hit
    mov dl, bl
    dec dl
    cmp al, dl
    je cc_hit
    mov dl, bl
    inc dl
    cmp al, dl
    je cc_hit

cc_next:
    inc si
    loop cc_loop
    jmp cc_done

cc_hit:
    ; clear screen
    call bios_clear

    ; print big GAME OVER art lines (pre-centered)
    mov dx, offset gameover_art1
    call print_string
    mov dx, offset gameover_art2
    call print_string
    mov dx, offset gameover_art3
    call print_string
    mov dx, offset gameover_art4
    call print_string
    mov dx, offset gameover_art5
    call print_string

    ; print label
    mov dx, offset gameover_label
    call print_string

    ; print "Your score:" then number
    mov dx, offset your_score_msg
    call print_string

    mov ax, [score]
    call print_number     ; prints decimal via int 21h AH=02

    ; show restart/quit hint
    mov dx, offset againmsg
    call print_string

    mov dx, offset creator_msg
    call print_string

wait_key:
    mov ah,0
    int 16h
    cmp al,'R'
    je restart_game
    cmp al,'r'
    je restart_game
    cmp al,'Q'
    je quit_game
    cmp al,'q'
    je quit_game
    jmp wait_key

restart_game:
    ; reset state and go to start screen
    mov byte ptr [playerCol],40
    mov word ptr [score],0

    ; reset meteors (rows->0, columns keep initial or you can randomize)
    mov cx, MAX_METEORS
    xor si, si
reset_loop:
    mov byte ptr [fallRows + si], 0
    ; optional: spread columns again (commented out)
    ; mov byte ptr [fallCols + si], 10
    inc si
    loop reset_loop

    jmp start_screen

quit_game:
    mov ah,4Ch
    int 21h

cc_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
check_collision endp

; ------------------------------------------------------------------
; DELAY: nested busy loop (tune DELAY_OUTER / DELAY_INNER)
; ------------------------------------------------------------------
delay_per_row proc
    push cx
    push dx

    mov cx, [DELAY_OUTER]
outer_loop:
    mov dx, [DELAY_INNER]
inner_loop:
    nop
    dec dx
    jnz inner_loop
    loop outer_loop

    pop dx
    pop cx
    ret
delay_per_row endp

; ------------------------------------------------------------------
; PRINT STRING (DOS) - DS:DX -> '$' terminated string
; ------------------------------------------------------------------
print_string proc
    mov ah,09h
    int 21h
    ret
print_string endp

; ------------------------------------------------------------------
; PRINT NUMBER (AX -> decimal) using INT 21h AH=02 to print each digit
; Preserves registers (push/pop individually)
; ------------------------------------------------------------------
print_number proc
    push ax
    push bx
    push cx
    push dx

    mov cx,0
    mov bx,10

conv_loop:
    xor dx,dx
    div bx       ; AX = AX / 10 ; DX = remainder
    push dx
    inc cx
    cmp ax,0
    jne conv_loop

print_digits:
    pop dx
    add dl,'0'
    mov ah,02h
    mov dl, dl
    int 21h
    loop print_digits

    ; restore registers
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number endp

end main
