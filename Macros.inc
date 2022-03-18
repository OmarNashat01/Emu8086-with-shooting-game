;-------------MACROS-----------------
PortConfiguration Macro

        mov dx,3fbh 			; Line Control Register
        mov al,10000000b		;Set Divisor Latch Access Bit
        out dx,al				;Out it
        ;   Set LSB byte of the Baud Rate Divisor Latch register.
        mov dx,3f8h			
        mov al,0ch			
        out dx,al
        ;	Set MSB byte of the Baud Rate Divisor Latch register.
        mov dx,3f9h
        mov al,00h
        out dx,al
        ;   	Set port configuration
        mov dx,3fbh
        mov al,00011011b
        
        out dx,al


EndM

WaitForSerialInput Macro
	Local CHK

	mov dx , 3FDH ; Line Status Register
        CHK:
            in al , dx
            AND al , 1
            JZ CHK
EndM

CheckForSerialInput Macro	;; Zero flag = 1 if not ready

	mov dx , 3FDH ; Line Status Register
	in al , dx
	AND al , 1

EndM
    

WaitForSerialOutput Macro
	Local AGAIN

            mov dx , 3FDH ; Line Status Register
            AGAIN:
                In al , dx ;Read Line Status
                AND al , 00100000b
                JZ AGAIN

EndM

CheckForSerialOutput Macro	;; Zero flag = 1 if not ready

	mov dx , 3FDH ; Line Status Register
	In al , dx ;Read Line Status
	AND al , 00100000b

EndM

PrintCharVidMode Macro color         ;Takes char in al

	mov  bl, color  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h

EndM

DrawPixel Macro color           ;Takes column in Cx and rows in Dx
        
        mov al,color ;Pixel color
        mov ah,0ch ;Draw Pixel Command
        int 10h

EndM

PrintMsg Macro str
        mov ah,2
        int 10h

        mov ah,9
        mov dx,offset str
        int 21h

EndM

Screen1 Macro str1,str2,str3,separator, ChatInv, GameInv
        mov dx,0818H
        PrintMsg str1

        mov dx,0A18H
        PrintMsg str2

        mov dx,0C18H
        PrintMsg str3

        mov dx,1600H
        PrintMsg separator

	mov dx, 1700H
	PrintMsg ChatInv

	mov dx, 1800H
	PrintMsg GameInv
        
EndM

ChatScreen Macro name1,name2,separator, endMsg

        mov ax,3
        int 10h

        mov dx,0102h
        PrintMsg Name1

        mov dx,0b00h
        PrintMsg separator

        mov dx,0C02h
        PrintMsg Name2

        mov dx,1700h
        PrintMsg separator

        mov dx,1800h
	PrintMsg endMsg

EndM

GetNm   MACRO namein
        Local NotVld,Vld
NotVld: mov ah,7H
        int 21H
        
        cmp al,'A'      ;smaller than 'A' means ascii number is smaller than all letter ascii code
        jb NotVld

        cmp al,'z'      ;Greater than 'z' means ascii number is greater than all ascii letters
        ja NotVld
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        cmp al,'Z'
        jbe Vld

        cmp al,'a'
        jae Vld
        ;;;;;;;;;;;;;;;;This part is to execlude the charachter between small and capital letters
        jmp NotVld

Vld:    mov ah,2
        mov dl,al
        int 21h         ;display first character

        mov cl,al       ;save first character in cl

        mov ah,0Ah
        mov dx,offset namein
        int 21h         ;take rest of the name input from keyboard

        mov dl,cl       ;save first character in dl

        mov ch,0
        mov cl,namein+1 ;mov the actual size of the rest of the name in cx

        mov si,offset namein
        mov di,offset namein

        add si,cx       ;let source point to last actual character input (not the first part of enter)
        inc si

        add di,cx       ;let distination point to last input +1 (the first part of enter)
        add di,2

        std             ;set direction flag to move backward in the movsb
        rep movsb       ;shift the input from keyboard by one position to have the fisrt letter input in the first position
        cld

        mov namein+2,dl ;move the first letter in the first position

        inc namein+1    ;since we took the first letter seperately we need to add it to the size

ENDM
        
GameScreenSplit Macro
  Local Vsep,Lsep
        mov ax,13h
        int 10h         ;switch to video mode

        mov color,6     ;Orange

        mov cx,0 ;Column
        mov dx,180 ;Row
Lsep:   DrawPixel color
        inc dx
        DrawPixel color
        dec dx

        inc cx
        cmp cx,320
        jnz Lsep

        mov cx,159 ;Column
        mov dx,0 ;Row
Vsep:  DrawPixel color
        inc cx
        DrawPixel color
        dec cx

        inc dx
        cmp dx,180
  jnz Vsep
   
ENDM

MoveCursor Macro location

	mov ah, 2
	mov dx, location
	int 10h


EndM

;--------------END MACROS----------------------------
