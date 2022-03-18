
	include code\MACROS.inc

	PUBLIC Chat

	Extrn Name1	    :Byte
	Extrn Name2 	    :Byte
	Extrn sprtr 	    :Byte
	


	.model small
	.stack 64
	.data

;;Constants
End_Of_My_Chat	    equ 0bh
End_Of_His_Chat	    equ 16h



MyChar		    db ?
HisChar		    db ?

MyCursorLoc	    dw 0200h
HisCursorLoc	    dw 0d00h
    

;; Display Messages
QuitMsg		    db 'To end chatting press F3$'
ChatEndMsg	    db 'has exited the chat room$'

	.code

ScrollMyChat	proc far
	push es
	push ds
	push di
	push si	

	
	mov ax, 0B800h
	mov es, ax
	mov ds, ax
    

	    mov si, 480	    ;; 3rd row or second chatting row
	    mov di, 320	    ;; first chatting row

	    mov cx, 1280
	    rep movsb
	    
	    

	mov cx, 80
	Loop1:
	    mov ah,2
	    mov dh,0ah
	    mov dl, cl
	    int 10h

	    mov dl, ' '
	    mov ah, 2
	    int 21h
	loop loop1
    

	mov dx, 0a00h
	
	pop si	
	pop di
	pop ds
	pop es

	ret
ScrollMyChat	endp

ScrollHisChat	proc

	push es
	push ds
	push di
	push si	

	
	mov ax, 0B800h
	mov es, ax
	mov ds, ax
    

	    mov si, 2240	    ;; 3rd row or second chatting row
	    mov di, 2080	    ;; first chatting row

	    mov cx, 1280
	    rep movsb
	    
	    

	mov cx, 80
	Loop2:
	    mov ah,2
	    mov dh,16h
	    mov dl, cl
	    int 10h

	    mov dl, ' '
	    mov ah, 2
	    int 21h

	loop loop2
    

	mov dx, 1600h

	pop si	
	pop di
	pop ds
	pop es

	ret
ScrollHisChat	endp

Chat	proc far

	mov ax, 3h
	int 10h

        ChatScreen Name1,Name2,sprtr, QuitMsg

	ChatLoop:

	    Sending:
		mov ah, 1
		int 16h
		jz Receiving

		mov ah, 0
		int 16h
		
		mov MyChar, al
		
		cmp ah, 3dh		;; Check if F3 is pressed
		jnz ContinueChat

		jmp EndChat
		ContinueChat:

		MoveCursor MyCursorLoc
		mov dl, MyChar
		mov ah, 2
		int 21h
		
		mov dx, MyCursorLoc
		cmp dl, 78
		jb NotEndOfline
		
		mov dl, 0
		inc dh
		
		cmp dh, End_Of_My_Chat
		jb sendchar
		

		call ScrollMyChat
		jmp sendchar	    

		NotEndOfline:
		
		    inc dl
		
		sendchar:
		    mov MyCursorLoc, dx
	    
		WaitForSerialOutput
		
		mov dx , 3F8H ; Transmit data register
		mov al, MyChar
		out dx, al
		
	    

	    Receiving:
		CheckForSerialInput
		jz Sending

		mov dx , 03F8H
		in al , dx
		cmp al, 7
		jz ChatEnded

		mov HisChar, al

		MoveCursor HisCursorLoc
		mov dl, HisChar
		mov ah, 2
		int 21h
		
		mov dx, HisCursorLoc
		cmp dl, 78
		jb NotEndOfline2
		
		mov dl, 0
		inc dh
		
		cmp dh, End_Of_His_Chat
		jb endreceive
		

		call ScrollHisChat
		jmp endreceive

		NotEndOfline2:
		
		    inc dl
		
		endreceive:
		    mov HisCursorLoc, dx

		jmp Sending

		



	EndChat:
	    WaitForSerialOutput
	    
	    mov dx , 3F8H ; Transmit data register
	    mov al, 7	    ;; 1 for chat mode
	    out dx , al
	    ret

	ChatEnded:
	    mov ah, 2
	    mov dx, 0C15h
	    int 10h
	    
	    mov ah, 9
	    mov dx, offset ChatEndMsg
	    int 21h
	    
	    mov ah, 0
	    int 16h



	ret
Chat	endp




Main	proc far
	mov ax, @data
	mov ds, ax

	call Chat
	
	mov ah,4ch
	int 21h

Main	endp
	end main
