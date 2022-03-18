	Extrn Is_Obj_Shot :Byte
	PUBLIC Draw_Shooter, PrintMsgSprite, Complete_BackGnd, Draw_Flying, Draw_Shot
	.model small
	.stack 64
	.data
;; Constants
Screen_Width		equ 320
Screen_Heigth	 	equ 200

Sprite_Width	 	equ 8
Sprite_Height	 	equ 5

Num_of_Supported_Chars	equ 36

;;  Sprite Bitmaps
Flying_Obj1	dw 1110001110000111b
                dw 1111011111001111b
                dw 0111011111011110b
                dw 0011101110111100b
                dw 0001111111111000b
		dw 0001111111111000b
                dw 0000001001000000b
                dw 0000011001100000b
                dw 0000000000000000b
                dw 0000000000000000b

Flying_Obj2	dw 0000001110000000b
                dw 0000011111000000b
                dw 0000011111000000b
                dw 0000001110000000b
                dw 0001111111111000b
		dw 0001111111111000b
                dw 0011101001011100b
                dw 0111011001101110b
                dw 1111000000001111b
                dw 1110000000000111b

shooter		db 00000000b
                db 00011000b
                db 00111100b
                db 01111110b
                db 11111111b

Space		db 00000000b
                db 00000000b
                db 00000000b
                db 00000000b
                db 00000000b

Letter_A        db  00111100b
                db  01100110b
                db  01111110b
                db  01100110b
                db  01100110b

Letter_B        db  01111110b
                db  01100111b
                db  01111110b
                db  01100111b
                db  01111110b

Letter_C        db  00111100b
                db  01100110b
                db  01100000b
                db  01100110b
                db  00111100b

Letter_D        db  01111100b
                db  01100110b
                db  01100110b
                db  01100110b
                db  01111100b

Letter_E        db  11111110b
                db  11000000b
                db  11111100b
                db  11000000b
                db  11111110b

Letter_F        db  01111110b
                db  01100000b
                db  01111100b
                db  01100000b
                db  01100000b

Letter_G        db  00111111b
                db  01100000b
                db  01100111b
                db  01100011b
                db  00111111b

Letter_H        db  01100110b
                db  01100110b
                db  01111110b
                db  01100110b
                db  01100110b

Letter_I        db  01111110b
                db  00011000b
                db  00011000b
                db  00011000b
                db  01111110b

Letter_J        db  11111110b
                db  00011000b
                db  00011000b
                db  11011000b
                db  11111000b

Letter_K        db  01100111b
                db  01101110b
                db  01111100b
                db  01101110b
                db  01100111b

Letter_L        db  01100000b
                db  01100000b
                db  01100000b
                db  01100000b
                db  01111110b

Letter_M        db  01000010b
                db  01100110b
                db  01111110b
                db  01100110b
                db  01100110b

Letter_N        db  10000110b
                db  11000110b
                db  11100110b
                db  11011110b
                db  11001110b

Letter_O        db  00111100b
                db  01100110b
                db  01100110b
                db  01100110b
                db  00111100b

Letter_P        db  11111100b
                db  11001110b
                db  11111100b
                db  11000000b
                db  11000000b

Letter_Q        db  01111110b
                db  11000011b
                db  11011011b
                db  11001111b
                db  01110110b

Letter_R        db  01111100b
                db  01100110b
                db  01111100b
                db  01100110b
                db  01100011b

Letter_S        db  00111110b
                db  01100000b
                db  00111100b
                db  00000110b
                db  01111100b

Letter_T        db  01111110b
                db  00011000b
                db  00011000b
                db  00011000b
                db  00011000b

Letter_U        db  01100110b
                db  01100110b
                db  01100110b
                db  01100110b
                db  00111100b

Letter_V        db  11000011b
                db  01100110b
                db  01100110b
                db  00111100b
                db  00011000b

Letter_W        db  11000011b
                db  11000011b
                db  11011011b
                db  11011011b
                db  01111110b

Letter_X        db  11101110b
                db  01101100b
                db  00111000b
                db  01101100b
                db  11101110b

Letter_Y        db  11000011b
                db  01100110b
                db  00111100b
                db  00011000b
                db  00011000b

Letter_Z        db  01111110b
                db  00001100b
                db  00011000b
                db  00110000b
                db  01111110b

Number_0        db  01111110b
                db  11001111b
                db  11011011b
                db  11110011b
                db  01111110b

Number_1        db  00011000b
                db  00111000b
                db  00011000b
                db  00011000b
                db  00111100b

Number_2        db  01111110b
                db  00000110b
                db  01111110b
                db  01100000b
                db  01111110b

Number_3        db  01111110b
                db  00000110b
                db  00111110b
                db  00000110b
                db  01111110b

Number_4        db  01101100b
                db  01101100b
                db  01111110b
                db  00001100b
                db  00001100b

Number_5        db  01111110b
                db  01100000b
                db  01111110b
                db  00000110b
                db  01111110b

Number_6        db  01111110b
                db  01100000b
                db  01111110b
                db  01100110b
                db  01111110b

Number_7        db  01111110b
                db  00000110b
                db  00111100b
                db  00011000b
                db  00110000b

Number_8        db  00111100b
                db  01100110b
                db  00111100b
                db  01100110b
                db  00111100b

Number_9        db  01111110b
                db  01100110b
                db  01111110b
                db  00000110b
                db  01111110b

Not_Found       db  11111111b
                db  11111111b
                db  11111111b
                db  11111111b
                db  11111111b


Supported_Chars db  ' ','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R'
		db  'S','T','U','V','W','X','Y','Z','0','1','2','3','4','5','6','7','8','9'


String		db 'AB3 das $'

	.code
;;;;;;;;;;;;;;;;;;;;;;;;;;Procedures;;;;;;;;;;;;;;;;;;;;;;;;
Draw_Flying proc far	    ;; Takes x in dl and Y in dh, Al color, AH 1 ==> flying obj 2 

	call Get_ScreenPos
	
	mov si, offset Flying_Obj1

	cmp ah,1
	jne DrawObj1
	    
	mov si, offset Flying_Obj2
	
	DrawObj1:	

    
	call Draw_fly_Sprite

	ret
Draw_Flying endp


Draw_fly_Sprite proc    ;takes X in cx, Y in dx, Si pointing to bitmap of variable, Al = sprite color , Ah = back ground color

	push ax
	push bx
	push cx
	push dx
	push di

	call Get_ScreenPos

	mov dl,al
	mov cx, 10
	
	Drawing_Row1:
	    lodsw			    ;take first row of bitmap of letter in al

	    xchg ax,dx		    	    ;put color in al, and first row of bitmap in dl

	    mov bx,1000000000000000b	    ;for checking if the first bit is one
	    Drawing_Pixels1:
		test dx,bx
		jz BackGND1

		stosb		    	    ;put color in di from al
		jmp Next_Pixel1

		BackGND1:
		;xchg al,ah	    	    ;; To set back ground color too
		;stosb
		;xchg al,ah

		inc di

		Next_Pixel1:
		shr bx,1
	    jnz Drawing_Pixels1

	    add di, 320 - 16
	    xchg ax,dx		    	    ;put color in dl to get it back next loop
	loop Drawing_Row1

	pop di
	pop dx
	pop cx
	pop bx
	pop ax

	ret
Draw_fly_Sprite	endp


Draw_Shooter	proc Far


	mov si, offset shooter
	call Draw_Sprite

	ret
Draw_Shooter	endp

Draw_Shot	proc Far        ;; al has shot color, (cx,dx) has position, ah has flying obj color

	call Get_ScreenPos
	
	mov cx,3
	Drawing:
	    cmp es:[di], ah
	    je Collision
	    stosb

	    cmp es:[di], ah
	    je Collision
	    stosb

	    cmp es:[di], ah
	    je Collision
	    stosb

	    add di, 317		;; 320 - 3 pixels width of shot

	loop Drawing

	jmp NoCollision

	Collision:
	    mov Is_Obj_Shot, 1

	
	NoCollision:

	ret
Draw_Shot	endp


Write_Char  proc		;takes char in bl and position in (dl,dh), al = character color
	push si
	push di
	push ax
	push cx
	push dx
	
	mov si,offset Space
	
	mov di,offset Supported_Chars	;check every supported char to get the offset of the sprite

	mov bh, Num_of_Supported_Chars
	Find_Char:
	    mov ah, [di]

	    cmp bl, ah
	    jz Found

	    add ah, 20H
	    cmp bl,ah
	    jz Found

	    add si, 5
	    inc di
	dec bh
	jnz Find_Char

	Found:
	    call Draw_Sprite		;In case character not supported print filled square

	pop dx
	pop cx
	pop ax
	pop di
	pop si
	    
	ret
Write_Char  endp

PrintMsgSprite proc far       ;takes column in cx and rows in dx and string offset in si
	push bx
	push cx
	push dx
	
loop1:  mov  bl,[si]
        cmp bl,'$'
        jz stopprnt
        mov  al,1
	call Write_Char
	
	add cx,10
        inc si
        jmp loop1

stopprnt:

	pop dx
	pop cx
	pop bx

        ret
PrintMsgSprite Endp

Get_ScreenPos	proc		;takes X in cx, Y in dx, returns DI pointing to memory pos of X,Y
	push ax
	push bx
	push cx
	push dx

	xor ax,ax		;setting to zero


	
	mov ax,Screen_Width	;Y*ScreenWidth + X
	mul dx
	add ax,cx

	mov di,ax
    
	pop dx
	pop cx
	pop bx
	pop ax

	ret
Get_ScreenPos	endp
Draw_Sprite proc    ;takes X in cx, Y in dx, Si pointing to bitmap of variable, Al = sprite color , Ah = back ground color

	push ax
	push bx
	push cx
	push dx
	push di

	call Get_ScreenPos

	mov dl,al
	mov cx, Sprite_Height
	
	Drawing_Row:
	    lodsb		    ;take first row of bitmap of letter in al

	    xchg al,dl		    ;put color in al, and first row of bitmap in dl

	    mov dh,dl		    ;Saving Sprite row in dh for backup
	    mov bh,10000000b	    ;for checking if the first bit is one
	    Drawing_Pixels:
		and dl,bh
		jz BackGND

		stosb		    ;put color in di from al
		jmp Next_Pixel

		BackGND:
		;xchg al,ah	    ;; To set back ground color too
		;stosb
		;xchg al,ah

		inc di

		Next_Pixel:
		mov dl,dh	    ;Put Sprite byte in dl  again and check for next bit
		shr bh,1
	    jnz Drawing_Pixels

	    add di, 320 - Sprite_Width
	    xchg al,dl		    ;put color in dl to get it back next loop
	loop Drawing_Row

	pop di
	pop dx
	pop cx
	pop bx
	pop ax

	ret
Draw_Sprite endp

Complete_BackGnd    proc far

	mov cx, 122
	mov dx, 10
	call Get_ScreenPos

	mov dl,16 
	mov al, 8
	MemPartitions:
	    
	    mov cx, 35
	    rep stosb
	    
	    add di, 320 - 35
	    mov cx,35
	    rep stosb
	    
	    add di, 320 -35
	    mov cx, 9
	    movenextpartition:
		add di, 320
	    loop movenextpartition
	    
	    dec dl
	jnz MemPartitions

	mov cx, 123
	mov dx, 10
	call Get_ScreenPos

	add di, 160

	mov dl,16 
	mov al, 8
	MemPartitions2:
	    
	    mov cx, 35
	    rep stosb
	    
	    add di, 320 - 35
	    mov cx,35
	    rep stosb
	    
	    add di, 320 -35
	    mov cx, 9
	    movenextpartition2:
		add di, 320 
	    loop movenextpartition2
	    
	    dec dl
	jnz MemPartitions2


	ret
Complete_BackGnd    endp


main	proc far

        mov ax,@data
        mov ds,ax

	mov ax,0A000h		    ;initialize es to video memory segment
	mov es,ax

	mov ax,13h		    ;turn to video mode
	int 10h
	mov cx,64000
	mov al,5
	rep stosb
	
	
	mov si, offset shooter
	mov dx, 1080h
	mov al, 19
	call Draw_Sprite

	call Draw_Flying

	mov cx, 20
	mov dx, 180
	mov si, offset String
	call PrintMsgSprite
    
	mov ah,0
	int 16h
	
	mov ah,4ch
	int 21h
main	endp
	end main
