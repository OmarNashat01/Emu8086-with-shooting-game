	include code\GMacros.inc
	include code\Macros.inc

	PUBLIC Game, Is_Obj_Shot, P1Registers, P1MemoryAcc, currentFlagRegAdd
	PUBLIC CurrentPlayerRegsAddress, P2Registers, P2MemoryAcc, F_CHAR_CURR

	Extrn StartingPlayer	    :Byte
	Extrn F_CHAR2		    :Byte
	Extrn F_CHAR1		    :Byte
	Extrn itPntsp1		    :Byte
	Extrn itPntsp2		    :Byte
	Extrn Player1_wrong_flag    :Byte
	Extrn Name1		    :Byte
	Extrn Name2 		    :Byte
	Extrn Draw_Shot		    :Far
	Extrn Draw_Shooter	    :Far
	Extrn Draw_Flying 	    :Far
	Extrn Operation_Executer    :Far
	Extrn Complete_BackGnd	    :Far
	Extrn PrintMsgSprite	    :Far

        .model small
        .stack 64
        .data

;; Constants
Screen_Width		    equ 320
Screen_Heigth	 	    equ 200

Sprite_Width	 	    equ 8
Sprite_Height	 	    equ 5

Num_of_Supported_Chars	    equ 19

Rounds_Bef_Shoot	    equ 5


;; Vairables

P1Xoffset		    db 0
P2Xoffset		    db 20
Mem1XPos		    dw 127
Mem2XPos		    dw 287
PointsAscii		    db '$$$$'

carryFlagP1		    db 0
P1Registers		    db 1 dup('0250$')   ;all register 
			    db 7 dup('0000$')   ;all register 

P1MemoryAcc	    	    db 16 dup('00')       ;16 bytes of memory		26 06 70 00 00
P1Memory	    	    db 16 dup('00$')       ;16 bytes of memory		26$06$70$00$00

carryFlagP2		    db 0
P2Registers	    	    db 8 dup('0000$')
P2MemoryAcc            	    db 16 dup('00')
P2Memory            	    db 16 dup('00$')
RegNames	    	    db 'AX$','BX$','CX$','DX$','SI$','DI$','SP$','BP$'
RegStartIndex       	    db 0,5,10,15,20,25,30,35,40     ;dictionary for using xlat (0 start index of AX, 5 Start index of BX...)
MemStartIndex       	    db 0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45
CurrentPlayerRegsAddress    dw ?
currentFlagRegAdd	    dw	?
F_CHAR_CURR		    db ?
counter			    db 0
color		    	    db 0	;1 --> Blue, 2 --> Green,3 --> Baby Blue

Fly_X		    	    db 0
Flyer_Cycles	    	    db 18
Flying_Obj_Stat	    	    db 0
Flying_Obj_Stat2    	    db 0


shooter_X	    	    db 0
shooter_Y	    	    db 0

Shot_Active	    	    db 0
Shot_X		    	    db 0
Shot_Y		    	    db 0

Fly_X2		    	    db 0

shooter_X2	    	    db 0
shooter_Y2	    	    db 0

Shot_Active2	    	    db 0
Shot_X2		    	    db 0
Shot_Y2		    	    db 0


Shot_Cycles	    	    db 0

Is_Obj_Shot	    	    db 0


;; Increase to decrease speed of flying object and shot and vise versa
Flyer_Cycle_num	    	    db 14	;; Minimum number is 8 
Shot_Cycle_num	    	    db 2

Flying_Obj_Color    	    db 19


CongratsMess		    db 'Has Won Congrats$'

RoundsBefShoot		    db 5
sendstatus		    db 0
datasent		    db 1

receivestatus		    db 0
datareceived		    db 1

gameover		    db 0
finishfirst		    db 0

	.code

;-----------PROCEDURES--------------------------  
DecimalToAscii	proc far		;; takes byte in al and returns 4 byte string last byte is $

	mov PointsAscii[0], '$'
	mov PointsAscii[1], '$'
	mov PointsAscii[2], '$'
	
    
	mov ah,0

	mov bl, 100
	div bl
	add al, 30h

	mov PointsAscii[0], al

	xchg al, ah		;; take remainder and put it in al
	mov ah, 0
	mov bl, 10
	div bl
	add al, 30h

	mov PointsAscii[1], al
	
	add ah, 30h
	
	mov PointsAscii[2], ah

	ret
DecimalToAscii	endp

prntreg proc;takes offset of the registers and the si determined which register is printed and Di for register name

        xchg si,di
        call PrintMsgVidMode
        
        mov al,':'      ;char to be print
        PrintCharVidMode color
        
        mov dx,cx
        add dl,3
        mov bh,0

        mov si,di
        call PrintMsgVidMode

                
        add ch,2        ;move cursor to the location of next register to print
        mov dx,cx
        mov bh,0
        mov ah,2
        int 10h

        ret
prntreg endp

PrintMsgVidMode proc       ;takes column in dl and rows in dh and string offset in si
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	loop1:  mov  al,[si]
		cmp al,'$'
		jz stopprnt
		mov  bl,color
		mov  bh, 0    ;Display page
		mov  ah, 0Eh  ;Teletype
		int  10h
		inc si
	jmp loop1

stopprnt:
	ret
PrintMsgVidMode Endp


	
PrintMem1   proc
	
	mov di, offset P1Memory
	mov si, offset P1MemoryAcc
	
	mov cx, 16
					;; Looping through the actual memory and copying it to the 
					;; Printing memory to update it before printing
	Transfer_Mem:
	    mov bl, [si]
	    mov [di], bl
	    inc si
	    inc di

	    mov bl, [si]
	    mov [di], bl
	    inc si
	    inc di
	    inc di
	loop Transfer_Mem
	    

	mov cx, Mem1XPos	;; X position in cx, Ypos in dx
	mov dx, 2

	mov bl, 16

	mov si, offset P1Memory


	MemLoop:
	    
	    call PrintMsgSprite
	    add dx, 11

	    inc si
	dec bl
	jnz MemLoop

	ret
PrintMem1   endp

PrintMem2   proc

	mov di, offset P2Memory
	mov si, offset P2MemoryAcc
	
	mov cx, 16

					;; Looping through the actual memory and copying it to the 
					;; Printing memory to update it before printing
	Transfer_Mem2:
	    mov bl, [si]
	    mov [di], bl
	    inc si
	    inc di

	    mov bl, [si]
	    mov [di], bl
	    inc si
	    inc di
	    inc di
	loop Transfer_Mem2


	mov cx, Mem2XPos	;; X position in cx, Ypos in dx
	mov dx, 2

	mov bl, 16

	mov si, offset P2Memory


	MemLoop2:
	    
	    call PrintMsgSprite
	    add dx, 11

	    inc si
	    dec bl
	jnz MemLoop2

	ret
PrintMem2   endp

UpdtRegs1 proc
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Moving cursor to top left corner of each section
        mov dl, P1Xoffset
        add dl,2
        mov cl,dl ;keeping track of dl (x offset) in cl
        mov ch,2  ;keeping track of dh (y offset) in ch
        mov dh,2

        mov bh,0    ;page number
        mov ah,2
        int 10h

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Printing registers
        mov counter,0
	prntregs1:
		mov ah,00

		mov al,counter
		mov bx,offset RegStartIndex
		xlat
		mov si,ax
		add si,offset P1Registers

		mov al,counter
		mov bx,offset MemStartIndex
		xlat
		mov di,ax
		add di,offset RegNames

		call prntreg

		inc counter
		cmp counter,8
        jnz prntregs1

	call PrintMem1
	mov si, offset Name1
	mov cx, Mem1XPos
	sub cx, 125
	mov dx, 2
	call PrintMsgSprite

	mov al, itPntsp1
	call DecimalToAscii
	mov si, offset PointsAscii
	
	mov cx, Mem1XPos
	sub cx, 55
	mov dx, 2
	call PrintMsgSprite

        ret
UpdtRegs1 endp

UpdtRegs2 proc

        mov bh,0
        mov dl, P2Xoffset
        add dl,2
        mov cl,dl ;keeping track of dl (x offset) in cl
        mov ch,2  ;keeping track of dh (y offset) in ch
        mov ah,2
        mov dh,2
        int 10h
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Printing registers
        mov counter,0
	prntregs2:
		mov ah,00
		mov al,counter
		mov bx,offset RegStartIndex
		xlat
		mov si,ax
		add si,offset P2Registers

		mov al,counter
		mov bx,offset MemStartIndex
		xlat
		mov di,ax
		add di,offset RegNames

		call prntreg

		inc counter
		cmp counter,8
        jnz prntregs2
	
	call PrintMem2

	mov si, offset Name2
	mov cx, Mem2XPos
	sub cx, 125
	mov dx, 2
	call PrintMsgSprite

	mov al, itPntsp2
	call DecimalToAscii
	mov si, offset PointsAscii
	
	mov cx, Mem2XPos
	sub cx, 55
	mov dx, 2
	call PrintMsgSprite

        ret
UpdtRegs2 endp

PaintBackGnd proc
	mov ax,13h	; change to video mode
	int 10h

	mov ax,0A000h	; initialize es = Video mode Memory segment, DI = 0
	mov es,ax
	mov di,0
	
	mov dl,180	;we game page is 180 rows
	mov ch,0

	BackGndLoop:
		;; Player one section
		mov al, 3	;color of player1 background 3 --> babyblue
		mov cl, 120
		rep stosb
		
		mov al, 8
		mov cl, 2
		rep stosb

		mov al,3	;color of player1 background 3 --> babyblue
		mov cl,35
		rep stosb

		mov al, 8
		mov cl,2
		rep stosb

		;; seperator
		mov al,8	; color 0 --> black
		mov cl,2
		rep stosb
		
		;; Player two section
		mov al,13	;color of player2 background
		mov cl,120
		rep stosb

		mov al, 8
		mov cl,2
		rep stosb

		mov al,13
		mov cl,35
		rep stosb

		mov al, 8
		mov cl,2
		rep stosb

		dec dl
	jnz BackGndLoop

	mov cx,640
	mov al,15
	rep stosb
	
	
	call Complete_BackGnd
	

	ret
PaintBackGnd endp


Get_ScreenPos	proc		;takes X in dl, Y in dh, returns DI pointing to memory pos of X,Y
	push ax
	push bx
	push dx

	xor ax,ax		;setting to zero
	xor bx,bx

	mov bl,dl		;keep X in bl

	xchg dl,dh		;Put Y in dl and clear dh to multiply by dx
	xor dh,dh
	
	mov ax,Screen_Width	;Y*ScreenWidth + X
	mul dx
	add ax,bx

	mov di,ax
    
	pop dx
	pop bx
	pop ax

	ret
Get_ScreenPos	endp

SendShootingData    proc


	mov dx, 3f8H
	mov al, datasent
	out dx, al
	
	WaitForSerialInput
	mov dx, 03f8h
	in al, dx
	cmp al, 0FAh
	jne senddata
    
	WaitForSerialOutput
	mov dx, 38fh
	mov al, 0FAh
	out dx, al

	ret
	
	    
	
	senddata:
		WaitForSerialOutput
		
		mov dx, 3f8H
		mov al, shooter_X
		out dx, al

	    Is2:
		WaitForSerialOutput
		
		mov dx, 3f8H
		mov al, shooter_Y
		out dx, al

	    Is3:
		WaitForSerialOutput
		
		mov dx, 3f8H
		mov al, Fly_X
		out dx, al

	    
	    Is4:
		WaitForSerialOutput
		
		mov dx, 3f8H
		mov al, Shot_Active
		out dx, al

	    
	    Is5:
		WaitForSerialOutput
		
		mov dx, 3f8H
		mov al, Shot_X
		out dx, al

	    Is6:
		WaitForSerialOutput
		
		mov dx, 3f8H
		mov al, Shot_Y
		out dx, al


	EndSending:
	ret
SendShootingData    endp

ReceiveShootingData proc


	    mov dx , 03F8H
	    in al , dx
	    cmp al, 0FAh
	    jne Cont
    
	    WaitForSerialOutput
	    mov dx, 3f8h
	    mov al, 0FAh
	    out dx, al

	    mov gameover, 1
	    ret

	    Cont:
	
	    WaitForSerialOutput
	    mov dx, 3f8h
	    out dx, al


	ReceiveData:
	    WaitForSerialInput
	    
	    mov dx, 03f8H
	    in al, dx
	    mov shooter_X2, al


	    IsR2:
	    WaitForSerialInput
	    
	    mov dx, 03f8H
	    in al, dx
	    mov shooter_Y2, al


	    IsR3:
	    WaitForSerialInput
	    
	    mov dx, 03f8H
	    in al, dx
	    mov Fly_X2, al


	    IsR4:
	    WaitForSerialInput
	    
	    mov dx, 03f8H
	    in al, dx
	    mov Shot_Active2, al

	    IsR5:
	    WaitForSerialInput
	    
	    mov dx, 03f8H
	    in al, dx
	    mov Shot_X2, al

	    IsR6:
	    WaitForSerialInput
	    
	    mov dx, 03f8H
	    in al, dx
	    mov Shot_Y2, al






	EndReceiveShoot:
	ret
ReceiveShootingData endp

Shooting_Game	proc

	mov gameover, 0

	call PaintBackGnd
	call UpdtRegs1
	call UpdtRegs2

	mov shooter_X, 0
	mov shooter_Y, 160

	mov Shot_Active, 0
	mov Fly_X, 0
	mov al,Flyer_Cycle_num
	mov Flyer_Cycles,al 

	Shooting_Loop:
	    CheckForSerialInput
	    jnz draw2
	    jmp CheckSend
	    draw2:
		    mov dx, 4
		    mov cl, Fly_X2
		    xor ch,ch
		    add cx, 160
		    mov al, 13			;; player 2 color
		    mov ah, Flying_Obj_Stat2
		    call Draw_Flying


		mov dl, shooter_Y2
		xor dh,dh
		mov cl, shooter_X2
		xor ch,ch
		add cx, 160

		mov al, 13		    ;;Shooter color
		call Draw_Shooter
		    mov cl, Shot_X2
		    xor ch,ch
		    add cx, 160

		    mov dl, Shot_Y2
		    xor dh,dh


		    mov al, 13
		    mov ah, 255			;;Big number that isn't available on screen so never hits it
		    call Draw_Shot


	    call ReceiveShootingData

		mov dl, shooter_Y2
		xor dh,dh
		mov cl, shooter_X2
		xor ch,ch
		add cx, 160

		mov al, 6		    ;;Shooter color
		call Draw_Shooter

		    mov dx, 4
		    mov cl, Fly_X2
		    xor ch,ch
		    add cx, 160

		    xor Flying_Obj_Stat2, 1
		    mov ah, Flying_Obj_Stat2
		    mov al, Flying_Obj_Color
		    call Draw_Flying

		cmp Shot_Active2, 1
		jne Shot2Inactive


		    mov cl, Shot_X2
		    xor ch, ch
		    add cx, 160
		    mov dl, Shot_Y2
		    xor dh, dh
		    mov al, 1
		    mov ah, 255			    ;;Big number that isn't available on screen so never hits it
		    
		    call Draw_Shot
    

		Shot2Inactive:

	    CheckSend:
	    CheckForSerialOutput
	    jz NoDataSent
	    call SendShootingData

	    
	
	    NoDataSent:
	    mov ah, 1
	    int 16h
	    jnz ConsumeChar 
	    jmp StartDrawing

	    ConsumeChar:
		mov dl, shooter_Y
		xor dh,dh

		mov cl, shooter_X
		xor ch,ch

		mov al, 3
		call Draw_Shooter

		mov ah, 0
		int 16h
		
		IsRight:
		    cmp ah, 77
		    jnz IsLeft


		    add shooter_X, 2
		    
		    cmp shooter_X, 150
		    jnb HitBarrier
		    jmp StartDrawing
		    HitBarrier:
		    mov shooter_X, 150

		    jmp StartDrawing
		
		IsLeft:
		    cmp ah, 75
		    jnz IsUp


		    sub shooter_X, 2
		    
		    cmp shooter_X, 4
		    ja StartDrawing
		    mov shooter_X, 0

		    jmp StartDrawing
		
		IsUp:
		    cmp ah, 72
		    jnz IsDown
	    
		    sub shooter_Y, 2

		    cmp shooter_Y, 40
		    ja StartDrawing
		    mov shooter_Y, 40

		    jmp StartDrawing

		IsDown:
		    cmp ah, 80
		    jnz IsSpace
	
		    add shooter_Y, 3

		    cmp shooter_Y, 170
		    jb StartDrawing
		    mov shooter_Y, 170

		    jmp StartDrawing

		IsSpace:	
		    cmp ah, 57
		    jnz StartDrawing
		    
		    cmp Shot_Active, 1
		    jne CreateShot
		    
			mov cl, Shot_X
			xor ch,ch

			mov dl, Shot_Y
			xor dh,dh

			mov al, 3
			mov ah, Flying_Obj_Color
			call Draw_Shot

		    CreateShot:
			mov Shot_Active, 1	    ;; Shot is being shot

			mov al, shooter_X   ;; Start the shot from the middle of the shooter
			add al,4
			mov Shot_X, al
			mov al, shooter_Y
			mov Shot_Y, al
		    
			mov al, Shot_Cycle_num
			mov Shot_Cycles, al
		

	    StartDrawing:
		    mov dx, 4
		    mov cl, Fly_X
		    xor ch,ch
		    mov al, 3
		    mov ah, Flying_Obj_Stat
		    call Draw_Flying


		    mov cl, Shot_X
		    xor ch,ch

		    mov dl, Shot_Y
		    xor dh,dh

		    mov al, 3
		    mov ah, Flying_Obj_Color
		    call Draw_Shot

    
		    call UpdtRegs1
		    call UpdtRegs2
		    call Complete_BackGnd
		
		dec Flyer_Cycles
		jnz DrawFlying

		add Fly_X, 5
		mov al, Flyer_Cycle_num
		mov Flyer_Cycles, al
		
		    xor Flying_Obj_Stat,1

		cmp Fly_X, 145
		jb DrawFlying
    
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		jmp Shooting_Game_End
		
		DrawFlying:
		    mov dx, 4
		    mov cl, Fly_X
		    xor ch,ch

		    ;xor Flying_Obj_Stat,1
		    mov ah, Flying_Obj_Stat
		    mov al, Flying_Obj_Color
		    call Draw_Flying


		mov dl, shooter_Y
		xor dh,dh
		mov cl, shooter_X
		xor ch,ch
		mov al, 6		    ;;Shooter color
		call Draw_Shooter
	    

		;; Start checking for shot movements
		cmp Shot_Active, 1
		jne ShotInactive
		
		dec Shot_Cycles
		jnz DrawShot
	    
		mov al, Shot_Cycle_num
		mov Shot_Cycles, al
		sub Shot_Y, 3

		cmp Shot_Y, 3
		ja DrawShot

		mov Shot_Active, 0
		jmp ShotInactive
		
		DrawShot:
		    mov cl, Shot_X
		    xor ch,ch
		    mov dl, Shot_Y
		    xor dh,dh
		    mov al, 1
		    mov ah, Flying_Obj_Color
		    
		    call Draw_Shot
		
		ShotInactive:
		
		;hlt


	    
	    cmp Is_Obj_Shot, 1
	    je Shooting_Game_End

	jmp Shooting_Loop
	    

	Shooting_Game_End:
	
	CheckForSerialInput
	jz sendwiningsignal
	
	call ReceiveShootingData
	cmp gameover, 1
	jne sendwiningsignal

	WaitForSerialOutput
	mov dx, 3f8h
	mov al, 0FFh
	out dx, al
	
	
	ret
	
	sendwiningsignal:
	WaitForSerialOutput
	mov dx, 3f8h
	mov al, 0FAh
	out dx, al
	
	WaitForSerialInput
	mov dx, 3f8h
	in al, dx
	cmp al, 0FFh
	jne sendwiningsignal 
	


	ret
Shooting_Game	endp

Sending_AllRegs	proc

	    WaitForSerialOutput
	    
	    mov dx , 3F8H ; Transmit data register
	    mov al, 0FBh
	    out dx, al

	waitagain:
	    WaitForSerialInput
	    
	    mov dx , 03F8H
	    in al , dx
	    cmp al, 0FBh
	    jne waitagain
	    

	mov cx, 72
	lea si, P1Registers
	SendRegs:
	    
	    WaitForSerialOutput    
	    mov dx , 3F8H ; Transmit data register
	    mov al, [si]
	    out dx, al
	    inc si
	
	loop SendRegs

	WaitForSerialOutput    
	mov dx , 3F8H ; Transmit data register
	mov al, itPntsp1
	out dx, al

	WaitForSerialOutput
	
	mov dx , 3F8H ; Transmit data register
	mov al, 0FFh
	out dx, al

	ret
Sending_AllRegs	endp

Receiving_AllRegs   proc

	takeinputagain:
	    WaitForSerialInput
	
	    mov dx , 03F8H
	    in al , dx
	    cmp al, 0FBh
	    jne takeinputagain

	    WaitForSerialOutput

	    mov dx , 3F8H ; Transmit data register
	    mov al, 0FBh
	    out dx, al


	lea si, P2Registers
	mov cx, 72
	ReceiveRegs:

	    WaitForSerialInput
	
	    mov dx , 03F8H
	    in al , dx

	    ;cmp al, 0FFh
	    ;jz EndReceive

	    mov [si], al
	    inc si
	loop ReceiveRegs
	    

	WaitForSerialInput
    
	mov dx , 03F8H
	in al , dx
	mov itPntsp2, al
	    
	WaitForSerialInput
    
	mov dx , 03F8H
	in al , dx

	EndReceive:
	    
	
	    


	ret
Receiving_AllRegs   endp


Game    proc far
	
	mov al, F_CHAR2
	mov F_CHAR_CURR, al
	
	mov CurrentPlayerRegsAddress, offset P1Registers	;; To execute command on Player 1 Regs
	mov currentFlagRegAdd, offset carryFlagP1

	mov counter,0
	Game_Loop:

	    	

	    mov color, 15
	    
		cmp StartingPlayer, 1
		jz StrtPlayer

		jmp SecPlayer
		StrtPlayer:

		    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;PLAYER ONE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		    call PaintBackGnd	;Draw the window for game mode
		    call UpdtRegs1
		    call UpdtRegs2


		    call Operation_Executer


		    mov al, Player1_wrong_flag
		    sub itPntsp1, al 
		    jnz P1DidntLost
		    jmp P1Lost
		    P1DidntLost:
		    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;PLAYER ONE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		    call Sending_AllRegs
	

		    call PaintBackGnd	;Draw the window for game mode
		    call UpdtRegs1
		    call UpdtRegs2

		    call Receiving_AllRegs

		    call PaintBackGnd	;Draw the window for game mode
		    call UpdtRegs1
		    call UpdtRegs2
		    
		    sub itPntsp2, 0
		    jnz P2DidntLost
		    jmp P2Lost
		    P2DidntLost:
		    
		    

		    jmp ShootingGame
		    

		SecPlayer:

		    call PaintBackGnd	;Draw the window for game mode
		    call UpdtRegs1
		    call UpdtRegs2

		    call Receiving_AllRegs

		    sub itPntsp2, 0
		    jnz P2DidntLost2
		    jmp P2Lost
		    P2DidntLost2:

		    call PaintBackGnd	;Draw the window for game mode
		    call UpdtRegs1
		    call UpdtRegs2


		    call Operation_Executer


		    mov al, Player1_wrong_flag
		    sub itPntsp1, al 
		    jnz P1DidntLost2
		    jmp P1Lost
		    P1DidntLost2:

		    call Sending_AllRegs
		
		    call PaintBackGnd	;Draw the window for game mode
		    call UpdtRegs1
		    call UpdtRegs2



		ShootingGame:
    
		    dec RoundsBefShoot
		    jnz Continue_Game
		    
			mov RoundsBefShoot, Rounds_Bef_Shoot
			call Shooting_Game
		    
			cmp Is_Obj_Shot, 1
			jne EndShooting
			
			mov al, Flying_Obj_Color
			sub al, 10
			add itPntsp1, al
	    

			mov Is_Obj_Shot, 0
			
			    
			EndShooting:

			add Flying_Obj_Color, 2
			dec Flyer_Cycle_num		    ;; increase speed for next round and change color and points

			CheckForSerialInput
			jz noinp
			mov dx, 03f8h
			in al, dx

			noinp:
			CheckForSerialOutput
			jz Continue_Game
	
			mov dx, 03f8h
			out dx, al
			

	    Continue_Game:
	    jmp Game_loop

	P1Lost:
	    call Sending_AllRegs

	    xor di,di
	    mov cx, 64000
	    mov al, 3
	    rep stosb

	    mov si, offset Name2
	    mov al, 5
	    mov cx, 120
	    mov dx, 40
	    call PrintMsgSprite
	    
	    mov si, offset CongratsMess
	    mov al, 5
	    mov cx, 90
	    mov dx, 70
	    call PrintMsgSprite



	    ret


	P2Lost:

	    xor di,di
	    mov cx, 64000
	    mov al, 3
	    rep stosb

	    mov si, offset Name1
	    mov al, 5
	    mov cx, 120
	    mov dx, 40
	    call PrintMsgSprite
	    
	    mov si, offset CongratsMess
	    mov al, 5
	    mov cx, 90
	    mov dx, 70
	    call PrintMsgSprite
	
        ret
Game    endp

;------------------------------END Procedures---------------

end
