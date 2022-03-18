;Micro-processor 1 project

	include code\macros.inc

	PUBLIC itPntsp1, itPntsp2, Name1, Name2, F_CHAR2, F_CHAR1, sprtr, StartingPlayer

	Extrn Game  :Far
	Extrn Chat  :Far


        .model small
        .stack 64
        .data

name1in 	db 15,?
Name1   	db 16 dup('$')
name2in 	db 15,?
Name2   	db 16 dup('$')
itPntsp1	db ?
itPntsp2	db ?
itPnts		db ?
counter		db 0
color		db 0	;1 --> Blue, 2 --> Green,3 --> Baby Blue
F_CHAR1     	db ?
F_CHAR2     	db ?

Name2Received	db 0

GameInvSent 	db 0
ChatInvSent 	db 0
GameInvReceived	db 0
ChatInvReceived	db 0

StartingPlayer	db 0



    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DISPLAY MESSAGES;;;;;;;;;;;;;;;;;;;;;;;;;;;
Nmprmpt		db 'Please enter your name:$'
intpnts 	db 'Initial Points:$'
entrkey 	db 'Press enter key to continue$'
msg1    	db 'To start chatting press F1$' 
msg2    	db 'To start the game press F2$' 
msg3    	db 'To end the program press ESC$' 
gamemsg 	db 'Hello you are in game mode$'
Endmsg  	db 'Thanks for playing our game...Goodbye$'
sprtr   	db '--------------------------------------------------------------------------------$'
F_CHAR_MSG	db 'ENTER FORBIDDEN CHARACTER:  $'
ChatInvMsg	db '$You Have Been Invited To a Chat Room.$'
GameInvMsg	db '$You Have Been Invited To a Game.$'


        .code

;-----------PROCEDURES--------------------------  

GetUserInfo proc
        push ax
        push dx
        push cx
        push si
        push di

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Player 1;;;;;;;;;;;;;;;;;;;;;;;;;  
        mov ax,0003h
        int 10h

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;Printing message for display
        mov dx,0618H
        PrintMsg Nmprmpt

        mov dx,0918H
        PrintMsg intpnts

        mov dx,0C18H
        PrintMsg entrkey

        mov ah,2	    ;; Moving Cursor for reading name position
        mov dx,0718H
        int 10h
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;Printing message for display

        GetNm name1in     ;; Getting the user name

        mov ah,2	    ;; Moving cursor for reading points position
        mov dx,0A18H
        int 10h

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Getting Initial Points


	mov itPntsp1, 0
	mov cl, 10
	NotNumber:
		mov ah,7H
		int 21H
		
		cmp al,'0'
		jb NotNumber

		cmp al,'9'
		ja NotNumber


		mov ah,2
		mov bh,0
		mov dl,al	    ;;  Display First Number
		int 21h
		
		mov al,dl
		sub al, 30h
		mul cl
		
		add itPntsp1, al
		sub cl,9	    ;; next number from input will be multiplied by 1
	ja NotNumber
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Getting Initial Points
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Player 1;;;;;;;;;;;;;;;;;;;;;;;;;  

	
        call ClrScrn
        Screen1 msg1,msg2,msg3,sprtr, ChatInvMsg, GameInvMsg


	CheckForSerialInput
	jz StartSending
	mov Name2Received, 1
	
	
	    WaitForSerialInput
		mov dx , 03F8H
		in al , dx

	    WaitForSerialOutput
	    mov dx , 3F8H ; Transmit data register
	    mov al, 100
	    out dx , al
	    

	    xor di, di
	    ReadName:
		WaitForSerialInput


		mov dx , 03F8H
		in al , dx
		cmp al, 7		    ;; terminating character
		jz StartSending
		mov Name2[di], al	    
		inc di

	    jmp ReadName

	    


    
	StartSending:

	mov cl, name1in +1
	mov ch, 0

	    WaitForSerialOutput
	    mov dx , 3F8H ; Transmit data register
	    mov al, 100
	    out dx , al

	    WaitForSerialInput
		mov dx , 03F8H
		in al , dx
	    

	

	xor si, si
	SendName:

	    WaitForSerialOutput

		mov dx , 3F8H ; Transmit data register
		mov al, Name1[si]
		out dx , al
	
		inc si
	    loop SendName

	    WaitForSerialOutput
		
	    mov dx , 3F8H ; Transmit data register
	    mov al, 7
	    out dx , al

	cmp Name2Received, 1
	jz endExchange
	xor di, di
    
	    WaitForSerialInput
		mov dx , 03F8H
		in al , dx

	    WaitForSerialOutput
	    mov dx , 3F8H ; Transmit data register
	    mov al, 100
	    out dx , al
	
	    ReadName2:
		WaitForSerialInput


		mov dx , 03F8H
		in al , dx
		cmp al, 7		    ;; terminating character
		jz endExchange
		mov Name2[di], al	    
		inc di
	    jmp ReadName2

	endExchange:

	

	    WaitForSerialOutput
	    mov dx , 3F8H ; Transmit data register
	    mov al, itPntsp1
	    out dx , al

	    WaitForSerialInput
	    mov dx , 03F8H
	    in al , dx
	    mov itPntsp2, al

		mov al, itPntsp1

		cmp al, itPntsp2	    ;; Compare the 2 initial  points and set both to lower points
		jbe ItPnts1Smaller
		
		mov al, itPntsp2
		mov itPntsp1, al

		ItPnts1Smaller:
		mov itPntsp2, al
		mov itPnts, al

        pop di
        pop si
        pop cx
        pop dx
        pop ax

        ret
GetUserInfo Endp


ClrScrn proc
        push ax
        push cx

        mov ax,0003h    ;Clear screen
        int 10h

        mov ah, 1       ;Hide cursor
	mov ch, 2bh
	mov cl, 0bh
	int 10h

        pop cx
        pop ax
        ret
ClrScrn endp       

;----------END PROCEDURES--------------------------------

Main    proc far
        mov ax,@data
        mov ds,ax
        mov es,ax

	PortConfiguration

        call GetUserInfo

        call ClrScrn
        Screen1 msg1,msg2,msg3,sprtr, ChatInvMsg, GameInvMsg

	mov ah, 0CH	    ;; Clear keyboard buffer
	int 21h


Start:

	CheckForSerialInput
	jz NoInput

	mov dx , 03F8H
	in al , dx
	
	cmp al, 1
	jne IsGameInv
	
	    mov ChatInvReceived, 1
	    mov ChatInvMsg, ' '    
	    jmp enditeration

	IsGameInv:
	    cmp al, 2
	    jne NoInput

	    mov GameInvReceived, 1
	    mov GameInvMsg, ' '    
	    jmp enditeration


    NoInput:

	mov ah,1
        int 16h
        jz CheckForInvitations
        mov ah,0
        int 16h

	jmp IsF1

CheckForInvitations:

	mov StartingPlayer, 1
	
	cmp ChatInvSent, 1
	jz ChatInv

	cmp GameInvSent, 1
	jz GameInv

	jmp Start
	

IsF1:   cmp ah,3bh   
        jnz IsF2     
	
	
	mov StartingPlayer, 0

	mov ChatInvSent, 1

	WaitForSerialOutput
	    
	mov dx , 3F8H ; Transmit data register
	mov al, 1	    ;; 1 for chat mode
	out dx , al


	ChatInv:
        
	cmp ChatInvReceived, 1
	jz StartChat
	cmp GameInvSent, 1
	jz GameInv

	jmp Start

    StartChat:

        call Chat

	mov ChatInvSent, 0
	mov ChatInvReceived, 0
	mov ChatInvMsg[0], '$'

        jmp enditeration

IsF2:   cmp ah,3ch
        jz F2
	jmp IsESC
	F2:

	mov StartingPlayer, 0

	mov GameInvSent, 1

	CheckForSerialOutput
	jz GameInv
	    
	mov dx , 3F8H ; Transmit data register
	mov al, 2	    ;; 2 for game mode
	out dx , al


	GameInv:
	cmp GameInvReceived, 1
	jz StartGame

	jmp Start

    StartGame:

        call ClrScrn

        mov dx,0a18h
        printmsg F_CHAR_MSG
        mov ah,0
        int 16h

        mov F_CHAR1,al ;takes forbidden character from player1

        mov ah,2
        mov dl,F_CHAR1
        int 21h



	;; Send the forbidden character to second player

		
	WaitForSerialOutput
	
	mov dx , 3F8H ; Transmit data register
	mov al, F_CHAR1
	out dx , al

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; Receiving initial points to initialize points
    
	WaitForSerialInput

        mov dx , 03F8H
        in al , dx
        mov F_CHAR2 , al
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	call ClrScrn
	mov dl, F_CHAR2
	mov ah, 2
	int 21h
    
	mov ah, 0CH	    ;; Clear keyboard buffer
	int 21h

	
	mov ah, 7
	int 21h


	mov al, itPnts
	mov itPntsp1, al
	mov itPntsp2, al
	

        call game
  
	mov ah,7        ;halt the simulation
	int 21h
	
	mov GameInvSent, 0
	mov GameInvReceived, 0
	mov GameInvMsg[0], '$'

        jmp enditeration

IsESC:  cmp ah,01h
        jz ProgramEnd

	jmp Start
enditeration:
        call ClrScrn
        Screen1 msg1,msg2,msg3,sprtr, ChatInvMsg, GameInvMsg
        jmp Start

ProgramEnd:
        call ClrScrn
        mov dx,0A18H
        PrintMsg Endmsg

        mov ah,4ch      ;return to OS
  	int 21h
Main    endp
        end Main
