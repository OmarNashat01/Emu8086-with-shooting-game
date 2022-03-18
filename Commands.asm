    Public Operation_Executer, Player1_wrong_flag

    Extrn P1Registers			:Byte
    Extrn P1MemoryAcc	 		:Byte
    Extrn P2Registers	 		:Byte
    Extrn P2MemoryAcc	 		:Byte
    Extrn CurrentPlayerRegsAddress	:Word
    Extrn currentFlagRegAdd		:Word
    Extrn F_CHAR_CURR	 		:Byte

    .model small
    .stack 64h
    .data

;variables here here

Operations_list		    db 'ADD $','ADC $','SUB $','SBB $','MOV $'
			    db 'XOR $','AND $','OR  $','SHR $'
			    db 'SHL $','SAR $','ROR $','RCL $','RCR $'
			    db 'ROL $','NOP $','CLC $','PUSH$','POP $','INC $','DEC $' ;the orders of the processor 0->20



Operand_list		    db 'AX  $','BX  $','CX  $','DX  $','SI  $','DI  $','SP  $','BP  $','AH  $'
	     		    db 'AL  $','BH  $','BL  $','CH  $','CL  $','DH  $','DL  $','----$',"VALU$";list of operands 0->17




COMMA			    db ',$'
SPACE 			    db '    $'
SINGLE_SPACE		    db ' $'
END_MESS		    db 'END$'
RIGHT_MESS		    db 'RIGHT$'
WRONG_MESS 		    db 'WRONG$'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Bracket_opening		    db '[$'
Bracket_closing  	    db ']$'
X_offset_opening_brkt_op1   db ?
Y_offset_opening_brkt_op1   db ?
X_offset_closing_brkt_op1   db ?
Y_offset_closing_brkt_op1   db ?

X_offset_opening_brkt_op2   db ?
Y_offset_opening_brkt_op2   db ?
X_offset_closing_brkt_op2   db ?
Y_offset_closing_brkt_op2   db ?

Addressing_boolean_operand1 db 0
Addressing_boolean_operand2 db 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Value_operand1_boolean	    db 0
Value_operand2_boolean 	    db 0
Value1			    db 5,?
Actual_Value1		    db 5 dup('$')
VALUE1_HEX          	    dw ?


Value2			    db 5,?
Actual_Value2		    db 5 dup('$')
VALUE2_HEX		    dw ?
NumberHex		    dw ?

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

X_offset		    db 10 ;x offset of the operation box
Y_offset 		    db 121 ;y offset of the operation box

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Operation_offset	    db 0
Operand1_offset 	    db 0
Operand1_Size		    db 0

Operand2_offset 	    db 0
Operand2_Size		    db 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Player1_points		    db 100
Player1_wrong_flag	    db 0
OUT_OF_MEMORY		    db 0


AsciiToHexTemp		    db ?,?,?,?
AsciiToHexRes		    dw ?
AsciiToHexRes2		    db ?
AsciiToHexRes4		    dw ?

Operand1_variableW	    dw ?
Operand1_variableB	    db ?
Operand2_variableW	    dw ?
Operand2_variableB	    db ?

FORBIDDEN_CHAR_FLAG	    db 0 
    .code




PrintMsgVidMode proc       ;takes column in dl and rows in dh and string offset in si
        mov  bh, 0    ;Display page
        mov  ah, 02h  ;SetCursorPosition
        int  10h

loop1:  mov  al,[si]
        cmp al,'$'
        jz stopprnt
        mov  bl,15
        mov  bh, 0    ;Display page
        mov  ah, 0Eh  ;Teletype
        int  10h
        inc si
        jmp loop1

stopprnt:
        ret
PrintMsgVidMode Endp
;#################################################################

Operations_picker proc ;proc of the operations box
;code to move cursor

;I used --------------->>> SI,DI
mov X_offset,0
mov Y_offset,21


operation_picker: ;prints the current picked command 
    mov ah,02
    mov dl, X_offset
    mov dh,Y_offset
    int 10h
    

    mov dl,X_offset
    mov dh,Y_offset
    
    mov si, offset Operations_list
    mov ah,0h
    mov al,Operation_offset  
    mov di,ax
    add si,di
    call PrintMsgVidMode
    


get_key_pressed_command:    ;sees if the user wants the previous or next command
    mov ah,0
    int 16h

    cmp ah,50h ;checks if down is pressed
    jz show_next_command
    cmp ah,48h ;checks if up is pressed 
    jz show_previous_command

    cmp ah,1Ch
    jz operand1_Picker_pre

    jmp get_key_pressed_command


show_next_command: ;shows next command if the DOWN key is pressed
    cmp Operation_offset,100;offset of the last command

    jnz reset_picker_next_command

    mov Operation_offset,-5    

reset_picker_next_command:

    add Operation_offset,5
    jmp Operation_picker


show_previous_command: ;shows previous command if UP button is pressed
    cmp Operation_offset,0;offset of the first command
    
    jnz reset_picker_previous_command

    mov Operation_offset,105

    reset_picker_previous_command:

    add Operation_offset,-5
    jmp Operation_picker

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


operand1_Picker_pre: ;prints the currently picked operand1
    add X_offset,5
operand1_Picker:

    mov ah,02
    mov dl, X_offset
    mov dh,Y_offset
    int 10h
    

    mov dl,X_offset
    mov dh,Y_offset
    
    mov si, offset Operand_list
    mov ah,0h
    mov al,Operand1_offset 
    mov di,ax
    add si,di
    call PrintMsgVidMode





get_key_pressed_operand1:    ;sees if the user wants the previous or next operand1
    mov ah,0
    int 16h

    cmp ah,50h ;checks if down is pressed
    jnz next
    jmp show_next_operand1
    next:

    cmp ah,48h ;checks if up is pressed 
    jnz next2 
    jmp show_previous_operand1
    next2:

    cmp ah,1Ch;checks if ENTER is pressed
    jnz next3
    jmp operand2_Picker_pre
    next3:
    cmp ah,0Fh;checks if TAB is pressed
    jz  toggle_addressing_mode_operand1

    jmp get_key_pressed_operand1



toggle_addressing_mode_operand1:;toggles if the user wants to use the operand in adressing mode or not
    
    cmp Addressing_boolean_operand1,1
    jnz set_addressing1
  
    
reset_addresing1:;removes the addressing bracket
    push ax
    mov ah, X_offset
    add ah,-1
    mov X_offset_opening_brkt_op1,ah
    mov ah,Y_offset
    mov Y_offset_opening_brkt_op1,ah
    
    mov dl,X_offset_opening_brkt_op1
    mov dh,Y_offset_opening_brkt_op1
    mov si,offset SINGLE_SPACE
    call PrintMsgVidMode
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    mov ah,X_offset_opening_brkt_op1
    add ah,5
    mov X_offset_closing_brkt_op1,ah
    mov ah,Y_offset
    mov Y_offset_closing_brkt_op1,ah

    mov dl,X_offset_closing_brkt_op1
    mov dh,Y_offset_closing_brkt_op1
    mov si, offset SINGLE_SPACE
    call PrintMsgVidMode
    
    mov ah,Addressing_boolean_operand1
    mov ah,0
    mov Addressing_boolean_operand1,ah






    pop ax
    jmp operand1_Picker
        
    
    
    
Set_addressing1:;puts on tthe addressing bracket
    push ax
    mov ah, X_offset
    add ah,-1
    mov X_offset_opening_brkt_op1,ah
    mov ah,Y_offset
    mov Y_offset_opening_brkt_op1,ah
    
    mov dl,X_offset_opening_brkt_op1
    mov dh,Y_offset_opening_brkt_op1
    mov si,offset Bracket_opening
    call PrintMsgVidMode
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    mov ah,X_offset_opening_brkt_op1
    add ah,5
    mov X_offset_closing_brkt_op1,ah
    mov ah,Y_offset
    mov Y_offset_closing_brkt_op1,ah

    mov dl,X_offset_closing_brkt_op1
    mov dh,Y_offset_closing_brkt_op1
    mov si, offset Bracket_closing
    call PrintMsgVidMode
    
    mov ah,Addressing_boolean_operand1
    mov ah,1
    mov Addressing_boolean_operand1,ah






    pop ax
    jmp operand1_Picker

show_next_operand1: ;shows next operand1 if the DOWN key is pressed
    cmp operand1_offset,85;offset of the last operand 1

    jnz reset_picker_next_operand1

    mov operand1_offset,-5   

reset_picker_next_operand1:

    add operand1_offset,5
    jmp operand1_picker


show_previous_operand1: ;shows previous operand1 if UP button is pressed
    cmp operand1_offset,0;offset of the first operand 1
    
    jnz reset_picker_previous_operand1

    mov operand1_offset,90

    reset_picker_previous_operand1:

    add operand1_offset,-5
    jmp operand1_picker  










;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  


operand2_Picker_pre: ;prints the currently picked operand2
   
    mov ah,operand1_offset

    cmp ah,85;checks if the user wanted to enter a value and takes value of the input

    jz ENTER_VALUE1_SKIP
    jmp Enter_Value1
ENTER_VALUE1_SKIP:
    mov ah,02
    mov dl,X_offset
    mov dh,Y_offset
    int 10h


    mov si,offset SPACE
    call PrintMsgVidMode
  

    mov ah,02
    mov dl,X_offset
    mov dh,Y_offset
    int 10h

    mov dx,offset Value1
    mov ah,0ah
    int 21h



    

    ;CHECKING THAT THE ENTERED VALUE IS VALID

    mov ch,4
    mov si, 0

    CHECK_LOOP1:

    mov bh,0
    mov ah,Actual_Value1[si]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp ah,30h ;sees if the value is in the range 0-->9
    jb WRONG_VAL_1_1

    cmp ah,39h
    ja WRONG_VAL_1_1
    
    mov bh,1


    
 WRONG_VAL_1_1:
    cmp bh,1
    jz END_CHK_LOOP_1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp ah,41h ;sees if the value is in the range A-->F
    jb WRONG_VAL_1_2

    cmp ah,46h
    ja WRONG_VAL_1_2
    
    mov bh,1


    
 WRONG_VAL_1_2:
    cmp bh,1
    jz END_CHK_LOOP_1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp ah,61h ;sees if the value is in the range a-->f
    jb WRONG_VAL_1_3

    cmp ah,66h
    ja WRONG_VAL_1_3
    
    mov bh,1


    
 WRONG_VAL_1_3:
    cmp bh,1
    jz END_CHK_LOOP_1

   


    jmp wrong_input_value1



END_CHK_LOOP_1:





    inc si
    dec ch
    cmp ch,0
    jnz CHECK_LOOP1

    jmp VAL1_CONTINUE


wrong_input_value1:
    mov ah,1
    ret










VAL1_CONTINUE:
    ;the number of shifts
    
    mov al,Value1[1]
    mov bh,4
    sub bh,al ;bh contains the number of shifts
    cmp bh,0
    jz SKIP_SHIFTER1
    
    
    
SHIFT_LOOP1:
    mov ah,Value1[4]
    mov Value1[5],ah
    
    mov ah,Value1[3]
    mov Value1[4],ah
    
    mov ah,Value1[2]
    mov Value1[3],ah
    
    mov Value1[2],30h
    
    dec bh
    cmp bh,0
    jnz SHIFT_LOOP1 
   
SKIP_SHIFTER1:
     
    mov si, offset Actual_Value1
    call AsciiToHex1
    mov ax,NumberHex
    mov VALUE1_HEX,ax


Enter_Value1:

    
    
   
    





    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    add X_offset,5
    mov dl,X_offset
    mov dh,Y_offset
    
 
    mov si,offset COMMA
    call PrintMsgVidMode
    
    add X_offset,2
operand2_Picker:

    mov ah,02
    mov dl, X_offset
    mov dh,Y_offset
    int 10h
    

    mov dl,X_offset
    mov dh,Y_offset
    
    mov si, offset Operand_list
    mov ah,0h
    mov al,Operand2_offset 
    mov di,ax
    add si,di
    call PrintMsgVidMode





get_key_pressed_operand2:    ;sees if the user wants the previous or next operand2
    mov ah,0
    int 16h

    cmp ah,50h ;checks if down is pressed
    jnz  next4
    jmp show_next_operand2
    next4:
    cmp ah,48h ;checks if up is pressed 
    jnz  next5
    jmp	show_previous_operand2
    next5:

    cmp ah,0Fh;checks if TAB is pressed
    jnz TOGGLE_ADD1
    jmp toggle_addressing_mode_operand2
TOGGLE_ADD1:
    cmp ah,1Ch
    jnz get_key_pressed_operand2
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    mov ah,operand2_offset

    cmp ah,85;checks if the user wanted to enter a value and takes value of the input
    jz ENTER_VALUE2_SKIP
    jmp Enter_Value2
ENTER_VALUE2_SKIP:
    mov bh,0
    mov ah,02
    mov dl,X_offset
    mov dh,Y_offset
    int 10h


    mov si,offset SPACE
    call PrintMsgVidMode
  
    mov bh,0
    mov ah,02
    mov dl,X_offset
    mov dh,Y_offset
    int 10h

    mov dx,offset Value2
    mov ah,0ah
    int 21h
    







    mov si,0
    mov ch,Value2[1]
 CHECK_LOOP2:
   
    mov bh,0
    mov ah,Actual_Value2[si]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp ah,30h ;sees if the value is in the range 0-->9
    jb WRONG_VAL_2_1

    cmp ah,39h
    ja WRONG_VAL_2_1
    
    mov bh,1


    
 WRONG_VAL_2_1:
    cmp bh,1
    jz END_CHK_LOOP_2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp ah,41h ;sees if the value is in the range A-->F
    jb WRONG_VAL_2_2

    cmp ah,46h
    ja WRONG_VAL_2_2
    
    mov bh,1


    
 WRONG_VAL_2_2:
    cmp bh,1
    jz END_CHK_LOOP_2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp ah,61h ;sees if the value is in the range a-->f
    jb WRONG_VAL_2_3

    cmp ah,66h
    ja WRONG_VAL_2_3
    
    mov bh,1


    
 WRONG_VAL_2_3:
    cmp bh,1
    jz END_CHK_LOOP_2

   


    jmp wrong_input_value2

END_CHK_LOOP_2:




    inc si
    dec ch
    cmp ch,0
    jnz CHECK_LOOP2

    jmp VAL2_CONTINUE


wrong_input_value2:
    mov ah,1
    ret

VAL2_CONTINUE:

















        ;the number of shifts
    
    mov al,Value2[1]
    mov bh,4
    sub bh,al ;bh contains the number of shifts
    cmp bh,0
    jz SKIP_SHIFTER2
    
    
    
SHIFT_LOOP2:
    mov ah,Value2[4]
    mov Value2[5],ah
    
    mov ah,Value2[3]
    mov Value2[4],ah
    
    mov ah,Value2[2]
    mov Value2[3],ah
    
    mov Value2[2],30h
    
    dec bh
    cmp bh,0
    jnz SHIFT_LOOP2 
   
SKIP_SHIFTER2:
     

    mov si, offset Actual_Value2
    call AsciiToHex1
    mov ax,NumberHex
    mov VALUE2_HEX,ax
    




    Enter_Value2:


    



    ;jz operand2_Picker_pre ;;;;;PUT NEXT STEP HERE
    jmp End_of_proc




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
toggle_addressing_mode_operand2:;toggles if the user wants to use the operand in adressing mode or not
    
    cmp Addressing_boolean_operand2,1
    jnz set_addressing2
    
reset_addresing2:;removes the addressing brackets
    push ax
    mov ah, X_offset
    add ah,-1
    mov X_offset_opening_brkt_op2,ah
    mov ah,Y_offset
    mov Y_offset_opening_brkt_op2,ah
    
    mov dl,X_offset_opening_brkt_op2
    mov dh,Y_offset_opening_brkt_op2
    mov si,offset SINGLE_SPACE
    call PrintMsgVidMode
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    mov ah,X_offset_opening_brkt_op2
    add ah,5
    mov X_offset_closing_brkt_op2,ah
    mov ah,Y_offset
    mov Y_offset_closing_brkt_op2,ah

    mov dl,X_offset_closing_brkt_op2
    mov dh,Y_offset_closing_brkt_op2
    mov si, offset SINGLE_SPACE
    call PrintMsgVidMode
    
    mov ah,Addressing_boolean_operand2
    mov ah,0
    mov Addressing_boolean_operand2,ah

    





    pop ax
    jmp operand2_Picker
        
    
    
    
Set_addressing2:;adds the addressing brackets
    push ax
    mov ah, X_offset
    add ah,-1
    mov X_offset_opening_brkt_op2,ah
    mov ah,Y_offset
    mov Y_offset_opening_brkt_op2,ah
    
    mov dl,X_offset_opening_brkt_op2
    mov dh,Y_offset_opening_brkt_op2
    mov si,offset Bracket_opening
    call PrintMsgVidMode
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    mov ah,X_offset_opening_brkt_op2
    add ah,5
    mov X_offset_closing_brkt_op2,ah
    mov ah,Y_offset
    mov Y_offset_closing_brkt_op2,ah

    mov dl,X_offset_closing_brkt_op2
    mov dh,Y_offset_closing_brkt_op2
    mov si, offset Bracket_closing
    call PrintMsgVidMode
    
    mov ah,Addressing_boolean_operand2
    mov ah,1
    mov Addressing_boolean_operand2,ah






    pop ax
    jmp operand2_Picker





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;








show_next_operand2: ;shows next operand2 if the DOWN key is pressed
    cmp operand2_offset,85;offset of the last operand 2

    jnz reset_picker_next_operand2

    mov operand2_offset,-5   

reset_picker_next_operand2:

    add operand2_offset,5
    jmp operand2_picker


show_previous_operand2: ;shows previous operand2 if UP button is pressed
    cmp operand2_offset,0;offset of the first operand 2
    
    jnz reset_picker_previous_operand2

    mov operand2_offset,90

    reset_picker_previous_operand2:

    add operand2_offset,-5
    jmp operand2_picker  












End_of_proc:





  mov ah,F_CHAR_CURR;capetalizing the forbidden char
    cmp ah,5Ah
    jbe CAPITALIZE_FORBIDDEN_CHAR
     
     
     sub ah,20h
     
     
     
 CAPITALIZE_FORBIDDEN_CHAR:
    mov F_CHAR_CURR,ah  ;checking for forbidden char in operation
     
      
        
    mov ax,0       
    mov al,operation_offset
    mov si,ax
     
    mov ah,F_CHAR_CURR
     
     mov cl,4
FORBIDDEN_LOOP_OPERATION:
 
    cmp ah,operations_list[si]
    jnz CHAR_OPERATION_CHECK
    
    mov FORBIDDEN_CHAR_FLAG,1
        
CHAR_OPERATION_CHECK:
   
              
            
    inc si
    dec cl
    jnz FORBIDDEN_LOOP_OPERATION 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


     
    mov ax,0       
    mov al,operand1_offset
    mov si,ax
     
     ;checking if operand 1 is a value
     
    
    cmp operand1_offset,85
     
    jz OPERAND1_VALUE_FORBIDDEN
     
     
     
     
     
     
     
    mov ah,F_CHAR_CURR ;checking for forbidden char in operand1
     
     mov cl,4
FORBIDDEN_LOOP_OPERAND1:
 
    cmp ah,operand_list[si]
    jnz CHAR_OPERAND1_CHECK
    
    mov FORBIDDEN_CHAR_FLAG,1
        
CHAR_OPERAND1_CHECK:
   
              
            
    inc si
    dec cl
    jnz FORBIDDEN_LOOP_OPERAND1         
  
  
OPERAND1_VALUE_FORBIDDEN:  





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


     
    mov ax,0       
    mov al,operand2_offset
    mov si,ax
     
    ;checking if operand 2 is a value
     
     
    cmp operand2_offset,85
     
    jz OPERAND2_VALUE_FORBIDDEN
     
     
     
     
     
     
     
    mov ah,F_CHAR_CURR ;checking for forbidden char in operand2
     
    mov cl,4
FORBIDDEN_LOOP_OPERAND2:
 
    cmp ah,operand_list[si]
    jnz CHAR_OPERAND2_CHECK
    
    mov FORBIDDEN_CHAR_FLAG,1
        
CHAR_OPERAND2_CHECK:
   
              
            
    inc si
    dec cl
    jnz FORBIDDEN_LOOP_OPERAND2         
  
  
OPERAND2_VALUE_FORBIDDEN:






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;CHECKING IF OPERAND1 IS A VALUE AND IF IT IS CHECK FOR THE FORBIDDEN CHAR


    cmp operand1_offset,85
    jnz OPERAND1_VALUE_SKP
    
    
    
    
   
    mov si,0
     
    ;checking if operand 2 is a value
     
   
     
     
     
     
     
     mov ah,F_CHAR_CURR ;checking for forbidden char in operand1
     
     mov cl,4
FORBIDDEN_LOOP_OPERAND1_VAL:
    
    
    mov bl,Actual_value1[si]
    cmp bl,5Ah
    jbe CAPITALIZE_FORBIDDEN_CHAR_OP1
     
     
    sub bl,20h
     
     
     
 CAPITALIZE_FORBIDDEN_CHAR_OP1:
    
    
    
    
    
     
    cmp ah,bl
    jnz CHAR_OPERAND1_CHECK_VAL
    
    mov FORBIDDEN_CHAR_FLAG,1
        
CHAR_OPERAND1_CHECK_VAL:
   
              
            
    inc si
    dec cl
    jnz FORBIDDEN_LOOP_OPERAND1_VAL         
  
    
    
    
    
    

OPERAND1_VALUE_SKP:


   
  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;CHECKING IF OPERAND2 IS A VALUE AND IF IT IS CHECK FOR THE FORBIDDEN CHAR


    cmp operand2_offset,85
    jnz OPERAND2_VALUE_SKP
    
    
    
    
    
    
    mov si,0
     
    ;checking if operand 2 is a value
     
   
     
     
     
     
     
    mov ah,F_CHAR_CURR ;checking for forbidden char in operand2
     
    mov cl,4
FORBIDDEN_LOOP_OPERAND2_VAL:
     
     
     
     mov bl,Actual_value2[si]
     cmp bl,5Ah
     jbe CAPITALIZE_FORBIDDEN_CHAR_OP2
     
     
     sub bl,20h
     
     
     
 CAPITALIZE_FORBIDDEN_CHAR_OP2:
    
     
     
     
     
    cmp ah,bl
    jnz CHAR_OPERAND2_CHECK_VAL
    
    mov FORBIDDEN_CHAR_FLAG,1
        
CHAR_OPERAND2_CHECK_VAL:
   
              
            
    inc si
    dec cl
    jnz FORBIDDEN_LOOP_OPERAND2_VAL         
  
    
   
    

OPERAND2_VALUE_SKP:










    
    ret
Operations_picker endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;----------------------------------------------------------------------------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;----------------------------------------------------------------------------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;----------------------------------------------------------------------------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;----------------------------------------------------------------------------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;----------------------------------------------------------------------------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;----------------------------------------------------------------------------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;----------------------------------------------------------------------------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



AsciiToHex1 PROC           ;; takes only 4 chars in ascii
    mov cl,[si]
    mov AsciiToHexTemp[0],cl
    inc si
    mov cl,[si]
    mov AsciiToHexTemp[1],cl
    inc si
    mov cl,[si]
    mov AsciiToHexTemp[2],cl
    inc si
    mov cl,[si]
    mov AsciiToHexTemp[3],cl
    
    mov si, offset AsciiToHexTemp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov cl,4
    mov NumberHex, 0

    Main_Loop1:


    mov al, [si]

    cmp al, 39h
    ja Letter1

    sub byte ptr [si], 30h
    jmp NextChar1
    
    Letter1:

        cmp al, 47h
        ja Small_Letter1

        sub byte ptr [si], 37h    ;; 'A' - 10 which is the value of A
        jmp NextChar1

        Small_Letter1:
        sub byte ptr [si], 57h

    NextChar1:
        inc si
        dec cl 

    jnz Main_Loop1

    mov cl, 4
    mov ch, 4
    mov bx, 1000h
    mov si, offset AsciiToHexTemp

    MultiplyLoop1:

    mov ax,bx                     ;; 161616

    mov dh, 0
    mov dl, [si]

    mul dx

    add NumberHex, ax

    shr bx, cl            ;; shift by 4 = divide by 16 for next digit
    inc si
    dec ch
    jnz MultiplyLoop1

    ret
AsciiToHex1 ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



Operation_checker proc far


    call Operations_Picker
    cmp ah,1
    jnz WRONG_INPUT_SKIP
    jmp wrong_input1
WRONG_INPUT_SKIP:

	mov Player1_wrong_flag, 0

; CHECK FOR NO FIRST OPERAND ERROR
    
    ;checking which command the user picked
    mov ah,Operation_offset

    ;OFFSET OF ALL 2 OPERAND NON-SHIFT OPERATIONS
    cmp ah,40;ADD
    jae ADD_COMMAND_next
    jmp ADD_COMMAND
ADD_COMMAND_next:

   cmp ah,75
   jae SHIFT_COMMAND_NEXT
    jmp SHIFT_COMMAND
SHIFT_COMMAND_NEXT:


    cmp ah,75;NOP
    jnz NOP_COMMAND_next
    jmp NOP_COMMAND
NOP_COMMAND_next:

    cmp ah,80;CLC
    jnz CLC_COMMAND_next
    jmp CLC_COMMAND
CLC_COMMAND_next:
    
    
    cmp ah,85;PUSH
    jnz PUSH_COMMAND_next
    jmp PUSH_COMMAND
PUSH_COMMAND_next:
    
    cmp ah,90;POP
    jnz POP_COMMAND_next
    jmp PUSH_COMMAND
POP_COMMAND_next:
   
    cmp ah,95;INC
    jnz INC_COMMAND_NEXT
    jmp INC_COMMAND
INC_COMMAND_NEXT:
    cmp ah,100;DEC
     jnz DEC_COMMAND_NEXT
    jmp INC_COMMAND
DEC_COMMAND_NEXT:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





;2 OPERAND COMMANDS (ADD,ADC,SUB,SBB,DIV,MUL,MOV,IDIV,IMUL,XOR,AND,OR,SHR,SHL,SAR,ROR,ROL,RCR,RCL)



ADD_COMMAND: 
;check if no first operand
    mov ah,Operand1_offset
    cmp ah,80 

    jnz ADD_NO_FIRST_OPERAND_NXT
    jmp wrong_input1
ADD_NO_FIRST_OPERAND_NXT:


    
;CHECKING NO SECOND OPERAND ERROR
    mov ah,operand2_offset
    cmp ah,80 
    jnz ADD_NO_SECOND_OPERAND_NXT
    jmp wrong_input1
ADD_NO_SECOND_OPERAND_NXT:


;CHECKING FOR ADRESS TO ADRESS ERROR

    mov ah,Addressing_boolean_operand1
    mov al,Addressing_boolean_operand2

    add ah,al
    cmp ah,2
    jnz ADD_ADDRESS_to_ADDRESS
    jmp wrong_input1
ADD_ADDRESS_to_ADDRESS:




;CHECKING FOR USING REGISTERS EXCEPT BX,SI,DI,VALUE FOR ADRESSING



    mov ah,Addressing_boolean_operand1;checks if operand1 is used for adderessing
    cmp ah,1
    jnz ADD_Continue_check_op1

    mov ah,Operand1_offset ;checking for operand1
    cmp ah,5
    jz ADD_Continue_check_op1
    cmp ah,20
    jz ADD_Continue_check_op1
    cmp ah,25
    jz ADD_Continue_check_op1
    cmp ah,85
    jz ADD_Continue_check_op1


    jmp wrong_input1
    
ADD_Continue_check_op1:

    mov ah,Addressing_boolean_operand2;checks if operand2 is used for adderessing
    cmp ah,1
    jnz ADD_Continue_check_op2

    mov ah,Operand2_offset ;checking for operand2
    cmp ah,5
    jz ADD_Continue_check_op2
    cmp ah,20
    jz ADD_Continue_check_op2
    cmp ah,25
    jz ADD_Continue_check_op2
    cmp ah,85
    jz ADD_Continue_check_op2

    jmp wrong_input1

ADD_Continue_check_op2:


;CHECKING IF THE FIRST OPERAND IS A VALUE ANDD NOT REFERENCED

    mov ah,operand1_offset
    cmp ah,85
    jnz ADD_op1_value_addressing

    mov ah,Addressing_boolean_operand1
    cmp ah,1
    jz ADD_op1_value_addressing
    jmp wrong_input1

ADD_op1_value_addressing:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CHECKING FOR VALUE SIZE MISMATCH




    mov ah,operand1_offset
    cmp ah,40
    jae ADD_Continue1
    mov ah,0
    jmp ADD_Continue2
ADD_Continue1:
    mov ah,1
ADD_Continue2:

   cmp ah,1
   jnz ADD_op1_8bit



;FIXME: can input 00FF and be considered wrong
; to detect mov al,1234h
    mov ah,Addressing_boolean_operand2
    cmp ah,1
    jz ADD_VALUE_SIZE_MISMATCH



    mov ax,VALUE2_HEX
    cmp ax,0ffh
    jbe ADD_VALUE_SIZE_MISMATCH
    jmp wrong_input1


    
ADD_VALUE_SIZE_MISMATCH:




    
ADD_op1_8bit:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CHECKING SIZE MISMACH ERROR

    mov ah,operand1_offset
    mov al,operand2_offset
    ;check if one of the operands is a value
    ;Because the value is already checked above that it is legal
    cmp ah,85
    jz ADD_Memory_to_Val
    cmp al,85
    jz ADD_Memory_to_Val





    cmp ah,40;sees if operand1 is a 8-bit or 16-bit register
    jb ADD_eight_bit_operand1
    mov ah,0
    jmp ADD_Checked_bits1
ADD_eight_bit_operand1:
    mov ah,1    
ADD_Checked_bits1:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    cmp al,40;sees if operand2 is a 8-bit or 16-bit register
    jb  ADD_eight_bit_operand2
    mov al,0
    jmp ADD_Checked_bits2
ADD_eight_bit_operand2:
    mov al,1    
ADD_Checked_bits2:

    add ah,al
    cmp ah,1


    jnz ADD_Memory_to_Val

    ;checks if operand 1 is used for addressing
    mov ah,Addressing_boolean_operand1
    cmp ah,1
    jz ADD_Memory_to_Val

    ;checks if operand 2 is used for addressing
    mov ah,Addressing_boolean_operand2
    cmp ah,1
    jz ADD_Memory_to_Val

    jmp wrong_input1

ADD_Memory_to_Val:

;END OF ALL CHECKS ALL IS OK
jmp End_of_proc_chk
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;COMMANDS WITH ONE OPERAND (PUSH,POP)

PUSH_COMMAND:;BEGIN CHECKS FOR ONE OPERAND OPERATIONS HERE
;check if there is a second operand 
    mov ah,operand2_offset
    cmp ah,80
    jz PUSH_SECOND_OP_ERR
    jmp wrong_input1
PUSH_SECOND_OP_ERR:


;check if the operand is referenced
    mov ah,Addressing_boolean_operand1
    cmp ah,1
    jnz PUSH_notref
; 
    mov ah,Operand1_offset ;checking if the value between the [] is si,di,bx,value.if right,the check is done
    cmp ah,5
    jz PUSH_END_CHK
    cmp ah,20
    jz PUSH_END_CHK
    cmp ah,25
    jz PUSH_END_CHK
    cmp ah,85
    jz PUSH_END_CHK
    
    jmp wrong_input1
    
PUSH_CHK_ADDRESSING:
    
;check if operand one is value,the value size doesn't matter.The check is done
PUSH_notref:
    mov ah,Operand1_offset
    cmp ah,85
    jz PUSH_END_CHK
    
    cmp ah,80
    jnz PUSH_NOTREF_CHK
    jmp wrong_input1


PUSH_NOTREF_CHK:
;
;check for pushing an 8 bit register
    mov ah,Operand1_offset
    cmp ah,40

    jb PUSH_8_bit_chk
    jmp wrong_input1
PUSH_8_bit_chk:
;
PUSH_END_CHK:
;END OF CHECKS ALL IS OK
    jmp End_of_proc_chk



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;COMMANDS WITH NO OPERANDS (CLC,NOP)

CLC_COMMAND:
;check if there is a first operand 
    mov ah,operand1_offset
    cmp ah,80
    jz CLC_NULL_CHK_op1
    jmp wrong_input1
CLC_NULL_CHK_OP1:
;
;check if there is a second operand 
    mov ah,operand2_offset
    cmp ah,80
  jz CLC_NULL_CHK_op2
    jmp wrong_input1
CLC_NULL_CHK_OP2:
    
    ;END OF CHECKS ALL IS OK
    jmp End_of_proc_chk
;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NOP_COMMAND:
;check if there is a first operand 
    mov ah,operand1_offset
    cmp ah,80
    jz NOP_NULL_CHK_op1
    jmp wrong_input1
NOP_NULL_CHK_OP1:
;
;check if there is a second operand 
    mov ah,operand2_offset
    cmp ah,80
       jz NOP_NULL_CHK_op2
    jmp wrong_input1
NOP_NULL_CHK_OP2:
    
    ;END OF CHECKS ALL IS OK
    jmp End_of_proc_chk
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INC_COMMAND:
;check if second operand is not empty
    mov ah,operand2_offset
    cmp ah,80
    jnz INC_SECOND_OP_ERR
    jmp wrong_input1
INC_SECOND_OP_ERR:
;check if operand 1 is referenced
    mov ah,Addressing_boolean_operand1
    cmp ah,1
    jnz INC_notref
; 
    mov ah,Operand1_offset ;checking if the value between the [] is si,di,bx,value.if right,the check is done
    cmp ah,5
    jz INC_END_CHK
    cmp ah,20
    jz INC_END_CHK
    cmp ah,25
    jz INC_END_CHK
    cmp ah,85
    jz INC_END_CHK
    jmp wrong_input1
    
INC_notref:;check if it is a value
    mov ah,Operand1_offset
    cmp ah,85
    jnz INC_END_CHK ;if operand 1 is not a value ,then it will be either a 4 bit register or a 16 bit register,Check is done
    jmp wrong_input1


INC_END_CHK:
    jmp End_of_proc_chk










jmp End_of_proc_chk
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;NOTE: ADDED THAT  OPERAND 2 MUST BE CL
SHIFT_COMMAND:

;check if no first operand
    mov ah,Operand1_offset
    cmp ah,80 

    jnz SHIFT_NO_FIRST_OPERAND_NXT
    jmp wrong_input1
SHIFT_NO_FIRST_OPERAND_NXT:


    
;CHECKING NO SECOND OPERAND ERROR
    mov ah,operand2_offset
    cmp ah,80 
    jnz SHIFT_NO_SECOND_OPERAND_NXT
    jmp wrong_input1
SHIFT_NO_SECOND_OPERAND_NXT:

    mov ah,Operand2_offset
    cmp ah,65
    jz SHIFT_CL_USED
    jmp wrong_input1
SHIFT_CL_USED:
;CHECKING FOR ADRESS TO ADRESS ERROR

    mov ah,Addressing_boolean_operand1
    mov al,Addressing_boolean_operand2

    add ah,al
    cmp ah,2
    jnz SHIFT_ADDRESS_to_ADDRESS
    jmp wrong_input1
SHIFT_ADDRESS_to_ADDRESS:




;CHECKING FOR USING REGISTERS EXCEPT BX,SI,DI,VALUE FOR ADRESSING



    mov ah,Addressing_boolean_operand1;checks if operand1 is used for adderessing
    cmp ah,1
    jnz SHIFT_Continue_check_op1

    mov ah,Operand1_offset ;checking for operand1
    cmp ah,5
    jz SHIFT_Continue_check_op1
    cmp ah,20
    jz SHIFT_Continue_check_op1
    cmp ah,25
    jz SHIFT_Continue_check_op1
    cmp ah,85
    jz SHIFT_Continue_check_op1


    jmp wrong_input1
    
SHIFT_Continue_check_op1:





;CHECKING IF THE FIRST OPERAND IS A VALUE ANDD NOT REFERENCED

    mov ah,operand1_offset
    cmp ah,85
    jnz SHIFT_op1_value_addressing

    mov ah,Addressing_boolean_operand1
    cmp ah,1
    jz SHIFT_op1_value_addressing
    jmp wrong_input1

SHIFT_op1_value_addressing:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CHECK IF THE SECOND OPERAND IS A VALUE AND IS LESS THAN 16 BITS
;FIXME:INPUT 00FF IS COUNTED AS AN ERROR

  



;END OF ALL CHECKS ALL IS OK
jmp End_of_proc_chk






;NOTE: RESET THIS WHEN DONE (THE OUTPUT MESSAGE)
wrong_input1:;deducts points when written command is wrong
    

    ;mov ah,2
    ;mov dx,0102h
    ;int 10h

    ;mov si,offset WRONG_MESS

    ;call PrintMsgVidMode 



    mov ah,Player1_wrong_flag
    mov ah,1
    mov Player1_wrong_flag,ah

    ret

End_of_proc_chk:; jump to here when all the checks are OK
    


    
    ;mov ah,2
    ;mov dx,0102h
    ;int 10h

    ;mov si,offset RIGHT_MESS

    ;call PrintMsgVidMode 



    ret





Operation_checker endp




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AsciiToHex4 PROC           ;; takes only 4 chars in ascii


    mov cl,4
    Main_Loop4:

	mov al, [si]

	cmp al, 39h
	ja Letter4

	sub byte ptr [si], 30h
	jmp NextChar4

	Letter4:

	    cmp al, 47h
	    jae Small_Letter4

	    sub byte ptr[si], 37h    ;; 'A' - 10 which is the value of A
	    jmp NextChar4

	    Small_Letter4:
	    sub byte ptr[si], 57h

	NextChar4:
	    inc si

    dec cl
    jnz Main_Loop4

    mov cl, 4
    mov ch, 4
    mov bx, 1000h
    mov si, offset AsciiToHexTemp
    mov AsciiToHexRes4, 0
    MultiplyLoop4:

	mov ax,bx                     ;; 161616

	mov dh, 0
	mov dl, [si]

	mul dx

	add AsciiToHexRes4, ax

	shr bx, cl            ;; shift by 4 = divide by 16 for next digit
	inc si
    dec ch
    jnz MultiplyLoop4

    ret
AsciiToHex4 ENDP

AsciiToHex2 PROC          


    
    mov cl, 2
    Main_Loop2:

	mov al, [si]

	cmp al, 39h
	ja Letter2

	sub byte ptr[si], 30h
	jmp NextChar2

	Letter2:

	    cmp al, 47h
	    ja Small_Letter2

	    sub byte ptr[si], 37h    ;; 'A' - 10 which is the value of A
	    jmp NextChar2

	    Small_Letter2:
	    sub byte ptr[si], 57h

	NextChar2:
	    inc si

    dec cl
    jnz Main_Loop2

    mov cl, 4
    mov ch, 2
    mov bx, 10h
    mov si, offset AsciiToHexTemp
    mov AsciiToHexRes2, 0
    MultiplyLoop2:

	mov ax,bx                     ;; 161616

	mov dl, [si]

	mul dl

	add AsciiToHexRes2, al

	shr bx, cl            ;; shift by 4 = divide by 16 for next digit
	inc si
    dec ch
    jnz MultiplyLoop2

    ret
AsciiToHex2 ENDP

HexToAscii proc		    ;; takes  word in ax returns 4 chars in AsciiToHexTemp

    lea di, AsciiToHexTemp
    mov dx, 0
    mov cx, 1000H
    div cx 
    mov bp,dx ;keep remainder in bp 
    call checkdig
    mov [di],al
    inc di
    mov ax,bp
    mov cx,256d 
    mov dx,00
    div cx 
    mov si,dx ;keep remainder2 in ch  
    call checkdig
    mov [di],al
    inc di 
    mov ax,si
    mov cx,16d 
    mov dx,00
    div cx    ; remainder 3 in dx
    call checkdig
    mov [di],al
    inc di 
    mov ax,dx 
    call checkdig
    mov [di],al 
     
    
HexToAscii endp

checkDig proc
    cmp ax,10d
    jae isLetter
    add ax,30h
    ret
    isLetter:
    add ax,37h
    ret
checkDig endp



Get_Operand1	proc	

	cmp Addressing_boolean_operand1, 1
	je  AddressingOp1

	    cmp Operand1_Size, 1	    ;; One byte Operand
	    ja  TwoByteOperand1
		
		mov si, CurrentPlayerRegsAddress
		xor ah, ah
		mov al, Operand1_offset
		add si, ax

		mov di, offset AsciiToHexTemp

		mov cx,2
		rep movsb
		
		mov si, offset AsciiToHexTemp
		call AsciiToHex2
		mov al, AsciiToHexRes2
		mov Operand1_variableB, al

		ret

	    TwoByteOperand1:		    ;; TWO byte operand
	    cmp Operand1_Size, 2
	    ja Val1
		
		mov si, CurrentPlayerRegsAddress
		xor ah, ah
		mov al, Operand1_offset
		add si, ax

		mov di, offset AsciiToHexTemp

		mov cx,4
		rep movsb
		
		mov si, offset AsciiToHexTemp
		call AsciiToHex4
		mov ax, AsciiToHexRes4
		mov Operand1_variableW, ax

		ret

	    Val1:
		
		mov ax, VALUE1_HEX
		
		cmp ah, 0 
		jne TwoByteValue1
    
		    mov Operand1_variableB, al	    ;; One Byte Value

		TwoByteValue1:
		    mov Operand1_variableW, ax	    ;; Two Byte Value
						    
						    ;; Value might be needed as a word even if byte is enough
						    ;; mov ax, 0023h, we need to provide 23h in byte in case it will be used as one byte operation
						    ;; yet we need to provide 0023h as word if needed to be used in word operation

		ret
	    

	AddressingOp1:
	    
	    cmp Operand1_Size, 1	    ;; One byte Operand
	    ja  TwoByteAddress1
		
		mov si, CurrentPlayerRegsAddress
		xor ah, ah
		mov al, Operand1_offset
		add si, ax

		mov di, offset AsciiToHexTemp

		mov cx,2
		rep movsb
		
		mov si, offset AsciiToHexTemp
		call AsciiToHex2
		mov al, AsciiToHexRes2
		mov Operand1_variableB, al

		ret

	    TwoByteAddress1:
	    cmp Operand1_Size, 2
	    ja ValAddress1
		
		mov si, CurrentPlayerRegsAddress
		xor ah, ah
		mov al, Operand1_offset
		add si, ax

		mov di, offset AsciiToHexTemp

		mov cx,4
		rep movsb
		
		mov si, offset AsciiToHexTemp
		call AsciiToHex4
		mov ax, AsciiToHexRes4
		mov Operand1_variableW, ax

		ret

	    ValAddress1:
		mov si, CurrentPlayerRegsAddress
		add si, 40			    ;; Start of memory segment
		
		cmp ax, 15
		jbe IN_MEM_RANGE

		    mov OUT_OF_MEMORY, 1

		IN_MEM_RANGE:

		    mov ax, VALUE1_HEX
		    mov Operand1_variableW, ax
    

	ret
Get_Operand1	endp

Get_Operand2	proc	
	cmp Addressing_boolean_operand2, 1
	je  AddressingOp2

	    cmp Operand1_Size, 1	    ;; One byte Operand
	    ja  TwoByteOperand2
		
		mov si, CurrentPlayerRegsAddress
		xor ah, ah
		mov al, Operand2_offset
		add si, ax

		mov di, offset AsciiToHexTemp

		mov cx,2
		rep movsb
		
		mov si, offset AsciiToHexTemp
		call AsciiToHex2
		mov al, AsciiToHexRes2
		mov Operand1_variableB, al

		ret

	    TwoByteOperand2:		    ;; TWO byte operand
	    cmp Operand1_Size, 2
	    ja Val2op
		
		mov si, CurrentPlayerRegsAddress
		xor ah, ah
		mov al, Operand2_offset
		add si, ax

		mov di, offset AsciiToHexTemp

		mov cx,4
		rep movsb
		
		mov si, offset AsciiToHexTemp
		call AsciiToHex4
		mov ax, AsciiToHexRes4
		mov Operand1_variableW, ax

		ret

	    Val2op:
		
		mov ax, VALUE2_HEX
		
		cmp ah, 0 
		jne TwoByteValue2
    
		    mov Operand1_variableB, al	    ;; One Byte Value

		TwoByteValue2:
		    mov Operand1_variableW, ax	    ;; Two Byte Value
						    
						    ;; Value might be needed as a word even if byte is enough
						    ;; mov ax, 0023h, we need to provide 23h in byte in case it will be used as one byte operation
						    ;; yet we need to provide 0023h as word if needed to be used in word operation

		ret
	    

	AddressingOp2:
	    
	    cmp Operand2_Size, 1	    ;; One byte Operand
	    ja  TwoByteAddress2
		
		mov si, CurrentPlayerRegsAddress
		xor ah, ah
		mov al, Operand2_offset
		add si, ax

		mov di, offset AsciiToHexTemp

		mov cx,2
		rep movsb
		
		mov si, offset AsciiToHexTemp
		call AsciiToHex2
		mov al, AsciiToHexRes2
		mov Operand2_variableB, al

		ret

	    TwoByteAddress2:
	    cmp Operand2_Size, 2
	    ja ValAddress2
		
		mov si, CurrentPlayerRegsAddress
		xor ah, ah
		mov al, Operand1_offset
		add si, ax

		mov di, offset AsciiToHexTemp

		mov cx,4
		rep movsb
		
		mov si, offset AsciiToHexTemp
		call AsciiToHex4
		mov ax, AsciiToHexRes4
		mov Operand1_variableW, ax

		ret

	    ValAddress2:
		mov si, CurrentPlayerRegsAddress
		add si, 40			    ;; Start of memory segment
		
		cmp ax, 15
		jbe IN_MEM_RANGE2

		    mov OUT_OF_MEMORY, 1

		IN_MEM_RANGE2:

		    mov ax, VALUE2_HEX
		    mov Operand2_variableW, ax
    


	ret
Get_Operand2	endp

Operation_Executer  proc far
	push es
	push di
	push si
    
	add si, ax			;; es = ds for string operations
	mov ax, ds
	mov es, ax
	
	mov FORBIDDEN_CHAR_FLAG, 0

	call Operation_checker
	cmp Player1_wrong_flag, 1
	jne Correct_Command

	jmp End_Execute

	Correct_Command:

	cmp FORBIDDEN_CHAR_FLAG, 1
	jne notForbidden

	jmp End_Execute

	notForbidden:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Btshta8al lel register to register operations bas till now;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	    cmp Operand1_offset, 40		    ;; offset of AH which is last 2 byte register
	    jae OneByte_Or_Val

	    mov Operand1_Size, 2
	    
	    jmp CMPVAL2				;;;;;;jump l 2a5er el block


	    OneByte_Or_Val:
		mov Operand1_Size, 1
		cmp Operand1_offset, 75
		ja Val
		
		sub Operand1_offset, 40		    ;; to start from the beginning of the registers
						    ;; AH starts from 0 same as AX
		xor ah,ah
		mov al, Operand1_offset
		
		mov bl, 2

		div bl				    ;; BH = 50, -40 = 10 /2 = 5 which is offset to BH (BX)
						    ;; BL = 55, -40 = 15 /2 = 7 which is the offset of BL (BX+2)
		mov Operand1_offset, al

		jmp CMPVAL2				;;;;;;jump l 2a5er el block


	    Val:
		mov Operand1_Size, 3
	    
	    CMPVAL2:

	    cmp Operand2_offset, 40		    ;; offset of AH which is last 2 byte register
	    jae OneByte_Or_Val2

	    mov Operand2_Size, 2
	    jmp DONECHECK


	    OneByte_Or_Val2:
		mov Operand2_Size, 1
		cmp Operand2_offset, 75
		ja Val2
		
		sub Operand2_offset, 40		    ;; to start from the beginning of the registers
						    ;; AH starts from 0 same as AX
		xor ah,ah
		mov al, Operand2_offset
		
		mov bl, 2

		div bl				    ;; BH = 50, -40 = 10 /2 = 5 which is offset to BH (BX)
						    ;; BL = 55, -40 = 15 /2 = 7 which is the offset of BL (BX+2)
		mov Operand2_offset, al
		jmp DONECHECK


	    Val2:
		mov Operand2_Size, 3

	    DONECHECK:



    mov ah, Operation_offset		;; Checking for offset and jumping to chosen operation 

    cmp ah, 0		    ;; ADD Operation
    jnz ADD_OPSKIP

    jmp ADD_OP

    ADD_OPSKIP:

    cmp ah, 5		    ;; ADC Operation
    jnz ADC_OPSKIP
    jmp ADC_OP
    ADC_OPSKIP:


    cmp ah, 10		    ;; SUB Operation
    jnz SUB_OPSKIP
    jmp SUB_OP
    SUB_OPSKIP:

    cmp ah, 15		    ;; SBB Operation
    jnz SBB_OPSKIP
    jmp SBB_OP
    SBB_OPSKIP:

    cmp ah, 20		    ;; MOV Operation
    jnz MOV_OPSKIP
    jmp MOV_OP
    MOV_OPSKIP:

    cmp ah, 25		    ;; XOR Operation
    jnz XOR_OPSKIP
    jmp XOR_OP
    XOR_OPSKIP:

    cmp ah, 30		    ;; AND Operation
    jnz AND_OPSKIP
    jmp AND_OP
    AND_OPSKIP:

    cmp ah, 35		    ;; OR Operation
    jnz OR_OPSKIP
    jmp OR_OP
    OR_OPSKIP:

    cmp ah, 40		    ;; SHR Operation
    jnz SHR_OPSKIP
    jmp SHR_OP
    SHR_OPSKIP:

    cmp ah, 45		    ;; SHL Operation
    jnz SHL_OPSKIP
    jmp SHL_OP
    SHL_OPSKIP:

    cmp ah, 50		    ;; SAR Operation
    jnz SAR_OPSKIP
    jmp SAR_OP
    SAR_OPSKIP:

    cmp ah, 55		    ;; ROR Operation
    jnz ROR_OPSKIP
    jmp ROR_OP
    ROR_OPSKIP:

    cmp ah, 60		    ;; RCL Operation
    jnz RCL_OPSKIP
    jmp RCL_OP
    RCL_OPSKIP:

    cmp ah, 65		    ;; RCR Operation
    jnz RCR_OPSKIP
    jmp RCR_OP
    RCR_OPSKIP:

    cmp ah, 70		    ;; ROL Operation
    jnz ROL_OPSKIP
    jmp ROL_OP
    ROL_OPSKIP:

    cmp ah, 75		    ;; NOP Operation
    jnz NOP_OPSKIP
    jmp NOP_OP
    NOP_OPSKIP:

    cmp ah, 80		    ;; CLC Operation
    jnz CLC_OPSKIP
    jmp CLC_OP
    CLC_OPSKIP:

    cmp ah, 85		    ;; PUSH Operation
    jnz PUSH_OPSKIP
    jmp PUSH_OP
    PUSH_OPSKIP:

    cmp ah, 90		    ;; POP Operation
    jnz POP_OPSKIP
    jmp POP_OP
    POP_OPSKIP:

    cmp ah, 95		    ;; INC Operation
    jnz INC_OPSKIP
    jmp INC_OP
    INC_OPSKIP:

    cmp ah, 100		    ;; DEC Operation
    jnz DEC_OPSKIP
    jmp DEC_OP
    DEC_OPSKIP:


    ADD_OP:
	
	call Get_Operand1
	call Get_Operand2

	cmp OUT_OF_MEMORY, 1
	jne CONT_ADD_OP

	    jmp End_Execute

	CONT_ADD_OP:

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteADD
	
	    
	    mov al, Operand1_variableB
	    mov dl, Operand2_variableB
	    
	    add al, dl

	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take al and put it in the Player registers
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	    
	
	jmp End_Execute
	
	TwoByteADD:
	cmp Operand1_Size, 2	    ;; One byte Operand
	ja  ValueADD

	    mov ax, Operand1_variableW
	    mov dx, Operand2_variableW
	    
	    add ax, dx
	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	
	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb

	ValueADD:

	    ;; TODO take ax and put it in the Player registers

	jmp End_Execute

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ADC_OP:

	;; TODO: Take the carry flag into consideration
	call Get_Operand1
	call Get_Operand2

	cmp OUT_OF_MEMORY, 1
	jne CONT_ADC_OP

	    jmp End_Execute

	CONT_ADC_OP:

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteADC
	
	    
	    mov al, Operand1_variableB
	    mov dl, Operand2_variableB

	    
	    
	    add al, dl
	    add al, byte ptr[currentFlagRegAdd]

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    
	    ;; TODO take al and put it in the Player registers
	
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	
	jmp End_Execute
	TwoByteADC:

	    mov ax, Operand1_variableW
	    mov dx, Operand2_variableW
	    
	    add ax, dx
	    add al, byte ptr[currentFlagRegAdd]

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0

	    ;; TODO take ax and put it in the Player registers

	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb

	jmp End_Execute
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    SUB_OP:

	call Get_Operand1
	call Get_Operand2

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteSUB
	
	cmp OUT_OF_MEMORY, 1
	jne CONT_SUB_OP

	    jmp End_Execute

	CONT_SUB_OP:
	    mov al, Operand1_variableB
	    mov dl, Operand2_variableB
	    
	    sub al, dl
	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take al and put it in the Player registers
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	
	jmp End_Execute
	
	TwoByteSUB:

	    mov ax, Operand1_variableW
	    mov dx, Operand2_variableW
	    
	    sub ax, dx

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take ax and put it in the Player registers

	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb


	jmp End_Execute
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    SBB_OP:

	;;TODO: Take borrow into consideration
	call Get_Operand1
	call Get_Operand2

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteSBB

	cmp OUT_OF_MEMORY, 1
	jne CONT_SBB_OP

	    jmp End_Execute

	CONT_SBB_OP:
	
	    
	    mov al, Operand1_variableB
	    mov dl, Operand2_variableB

	    
	    sub al, dl
	    sub ax, [currentFlagRegAdd]
	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take al and put it in the Player registers
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	
	jmp End_Execute
	
	TwoByteSBB:

	    mov ax, Operand1_variableW
	    mov dx, Operand2_variableW
	    

	    sub ax, dx
	    sub ax, [currentFlagRegAdd]
	    

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take ax and put it in the Player registers

	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb


	jmp End_Execute
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    MOV_OP:

	    mov si, CurrentPlayerRegsAddress
	    mov ah,0
	    mov al, Operand2_offset
	    add si, ax
    
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah,0
	    mov al, Operand1_offset
	    add di, ax

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteMOV
	
	    
	    mov cx, 2
	    rep movsb

	    
	    ;; TODO take al and put it in the Player registers
	
	jmp End_Execute
	
	TwoByteMOV:

	    
	    mov cx, 4
	    rep movsb
	    ;; TODO take ax and put it in the Player registers


	jmp End_Execute
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    XOR_OP:

	call Get_Operand1
	call Get_Operand2

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteXOR
	
	    
	    mov al, Operand1_variableB
	    mov dl, Operand2_variableB
	    
	    xor al, dl
	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take al and put it in the Player registers
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	
	jmp End_Execute
	
	TwoByteXOR:

	    mov ax, Operand1_variableW
	    mov dx, Operand2_variableW
	    
	    xor ax, dx

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take ax and put it in the Player registers

	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb




	jmp End_Execute
    AND_OP:

	call Get_Operand1
	call Get_Operand2

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteAND
	
	    
	    mov al, Operand1_variableB
	    mov dl, Operand2_variableB
	    
	    and al, dl
	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take al and put it in the Player registers
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	
	jmp End_Execute
	
	TwoByteAND:

	    mov ax, Operand1_variableW
	    mov dx, Operand2_variableW
	    
	    and ax, dx

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take ax and put it in the Player registers


	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb





	jmp End_Execute
    OR_OP:

	call Get_Operand1
	call Get_Operand2

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteOR
	
	    
	    mov al, Operand1_variableB
	    mov dl, Operand2_variableB
	    
	    or al, dl
	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take al and put it in the Player registers
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	
	jmp End_Execute
	
	TwoByteOR:

	    mov ax, Operand1_variableW
	    mov dx, Operand2_variableW
	    
	    or ax, dx

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take ax and put it in the Player registers


	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb



	jmp End_Execute
    SHR_OP:

	call Get_Operand1
	call Get_Operand2

	mov cl, Operand2_variableB

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteSHR
	
	    
	    mov al, Operand1_variableB
	    
	    shr al, cl
	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take al and put it in the Player registers
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	
	jmp End_Execute
	
	TwoByteSHR:

	    mov ax, Operand1_variableW
	    
	    shr ax, cl

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take ax and put it in the Player registers


	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb





	jmp End_Execute
    SHL_OP:

	call Get_Operand1
	call Get_Operand2

	mov cl, Operand2_variableB

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteSHL
	
	    
	    mov al, Operand1_variableB
	    
	    shL al, cl
	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take al and put it in the Player registers
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	
	jmp End_Execute
	
	TwoByteSHL:

	    mov ax, Operand1_variableW
	    
	    shl ax, cl

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take ax and put it in the Player registers



	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb




	jmp End_Execute
    SAR_OP:

	call Get_Operand1
	call Get_Operand2

	mov cl, Operand2_variableB

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteSAR
	
	    
	    mov al, Operand1_variableB
	    
	    sar al, cl
	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take al and put it in the Player registers
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	
	jmp End_Execute
	
	TwoByteSAR:

	    mov ax, Operand1_variableW
	    
	    sar ax, cl

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take ax and put it in the Player registers

	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb
    
	jmp End_Execute

    ROR_OP:

	call Get_Operand1
	call Get_Operand2

	mov cl, Operand2_variableB

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteROR
	
	    
	    mov al, Operand1_variableB
	    
	    ROR al, cl
	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take al and put it in the Player registers
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	
	jmp End_Execute
	
	TwoByteROR:

	    mov ax, Operand1_variableW
	    
	    ror ax, cl

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take ax and put it in the Player registers

	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb


	jmp End_Execute
    RCL_OP:

	call Get_Operand1
	call Get_Operand2

	mov cl, Operand2_variableB

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteRCL
	
	    
	    mov al, Operand1_variableB
	    
	    RCL al, cl
	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take al and put it in the Player registers
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	
	jmp End_Execute
	
	TwoByteRCL:

	    mov ax, Operand1_variableW
	    
	    RCL ax, cl

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take ax and put it in the Player registers

	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb


    
	jmp End_Execute

    RCR_OP:

	call Get_Operand1
	call Get_Operand2

	mov cl, Operand2_variableB

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteRCR
	
	    
	    mov al, Operand1_variableB
	    
	    RCR al, cl
	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take al and put it in the Player registers
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	
	jmp End_Execute
	
	TwoByteRCR:

	    mov ax, Operand1_variableW
	    
	    RCR ax, cl

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take ax and put it in the Player registers

	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb

	jmp End_Execute

    ROL_OP:

	call Get_Operand1
	call Get_Operand2

	mov cl, Operand2_variableB

	cmp Operand1_Size, 1	    ;; One byte Operand
	ja  TwoByteROL
	
	    
	    mov al, Operand1_variableB
	    
	    ROL al, cl
	    
	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take al and put it in the Player registers
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb
	
	jmp End_Execute
	
	TwoByteROL:

	    mov ax, Operand1_variableW
	    
	    ROL ax, cl

	    mov [currentFlagRegAdd], 0
	    adc [currentFlagRegAdd], 0
	    ;; TODO take ax and put it in the Player registers

	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb

	jmp End_Execute

    
    NOP_OP:			;; Finished

	jmp End_Execute

    CLC_OP:			;; finished
	
	    mov [currentFlagRegAdd], 0

    
	jmp End_Execute

    PUSH_OP:

	


	jmp End_Execute

    POP_OP:
    

	jmp End_Execute

    INC_OP:
	call Get_Operand1
	
	cmp Operand1_Size, 1
	ja TwoByteINC
	    
	    mov al, Operand1_variableB
	    inc al

	;; TODO: put al in reg again
	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb



	TwoByteINC:
	    mov ax, Operand1_variableW
	    inc ax

	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb
	    
	;; TODO: put ax in reg again

	jmp End_Execute
    
    DEC_OP:
	call Get_Operand1
	
	cmp Operand1_Size, 1
	ja TwoByteDEC
	    
	    mov al, Operand1_variableB
	    dec al

	;; TODO: put al in reg again

	    mov ah, 0
	    call HexToAscii
	
	    mov si, offset AsciiToHexTemp
	    add si, 2
	    
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    mov cx, 2
	    rep movsb


	TwoByteDEC:
	    mov ax, Operand1_variableW
	    dec ax

	    
	;; TODO: put ax in reg again
	    call HexToAscii
	    
	    mov si, offset AsciiToHexTemp
	    mov di, CurrentPlayerRegsAddress
	    mov ah, 0
	    mov al, Operand1_offset
	    add di, ax
	    
	    mov cx, 4

	    rep movsb
    
	jmp End_Execute
    


	End_Execute:
	
	mov Operand1_offset, 0
	mov Operand2_offset, 0


	pop si
	pop di
	pop es

	ret
Operation_Executer  endp





main proc far 
    mov ax,@data
    mov ds,ax

    mov ax,13h
    int 10h


    mov ax,0A000h
    mov es,ax
    mov al,19h
    mov di,0
    mov cx,64000
    rep stosb


  
    call Operation_checker



    mov ah,07
    int 21h

    mov ah,4ch
    int 21h


main    endp
        end main





