---
title: 'Micro-Processors 1 Project'
author:
- Omar Nashat
- Shahd Abdelrhman
- Mark Milad 
- Mariam Ahmad
- Ziad Hazem
Date: December 15, 2021
keywords: [micro-processors,microprocessors,8086,emu8086,8086game]
toc: true
toccolor: NavyBlue
highlight: true
highlight-style: zenburn
---

\pagebreak
## Macros: {#Macros}

### PrintMsg(str): {#PrintMsg}

> Moves cursor to the position in Dx.
```asm
        mov ah,2
        int 10h
```
> Prints the value of the input variable using (int 21h/9).
```asm
        mov ah,9
        mov dx,offset str
        int 21h
```

### Screen1(str1, str2, str3, separator): {#Screen1}

> Displays the first menu (the input variables are the messages that are shown) using [PrintMsg](#PrintMsg).
```asm
        mov dx,0818H
        PrintMsg str1
```

### ChatScreen(name1, name2, separator): {#ChatScreen}

> Clears the screen.
```asm
        mov ax,3
        int 10h
```
> Then displays the name of the players and format the screen for chatting using [PrintMsg](#PrintMsg).
```asm
        mov dx,0102h
        PrintMsg Name1
```

### GetNm(namein): {#GetNm}

> Checks for the first letter of the name to validate that it is a letter by reading the character with out echo (int 21h/7).
```asm
	mov ah,7
	int 21h
```
> Then it performs necessary checks to validate it is a letter before displaying the letter on the screen or waiting for another input.
```asm
	mov ah,2
	mov dl,al
	int 21h
```
> Then the rest of the name is read by (int 21/0A).
```asm
        mov ah,0Ah
        mov dx,offset namein
        int 21h 
```
> Then shifts the whole name array by one place using movsb.
```asm
        std        
        rep movsb   
        cld
```
> Finally it adds the first character and increments the name size.
```asm

        mov namein+2,dl

        inc namein+1  
```

### GameScreenSplit(separator): {#GameScreenSplit} 

> Splits the lower part of the screen to be used as chat using [PrintMsg](#PrintMsg).
```asm
        mov dx,1600H
        PrintMsg separator
```
> Splits the screen vertically by printing '|' using (int 21h/2) in a loop.
```asm
	mov cx,16h
	mov ah,2
Vsep:	mov dh,cl
        dec dh
	mov dl,27h
	int 10h
	mov dl,'|'
	int 21h
	loop Vsep
```

### Prntreg(reg,regname): {#prntreg}

> Prints the register name by using the regname variable with the offset in DI the prints it by using (int 21h/9).
```asm
        mov ah,9 
        mov dx,offset regname
        add dx,di
        int 21h
```

> Then prints the register value using the reg variable with the offset in SI using same method as regname.

> Finally it sets the cursor position to the next line using (int 10h/2).
```asm
        add ch,2 
        mov dx,cx
        mov bh,0
        mov ah,2
        int 10h
```


## Procedures: {#Procs}

### GetUserIndo: {#GetUserInfo}

> Clears the screen then prints 3 messages using [PrintMsg](#PrintMsg).
```asm
        mov ax,0003h
        int 10h

        mov dx,0618H
        PrintMsg Nmprmpt
```
> Then it moves the cursor and take the name using [GetNm](#GetNm).
```asm
        mov ah,2
        mov dx,0718H
        int 10h

        GetNm name1in     
```
> Finally it takes the initial points by using (int 21h/0Ah).
```asm
        mov ah,0Ah
        mov dx,offset itPnts
        int 21h
```

### Chat: {#Chat}


### UpdtRegs1: {#UpdtRegs1}
> Sets initial cursor position then loops to print all registers using [prntreg](#prntreg).
```
    Xlat is used to determine the offset of the register.
    RegStartIndex: 0,	5,  10,   15,   20,    25,    30,    35,    40
		   AX  BX   CX    DX    SI     DI     SP     BP     FlagReg
```
```asm
prntregs1:
        mov ah,00

        mov al,counter
        mov bx,offset RegStartIndex
        xlat
        mov si,ax

        mov al,counter
        mov bx,offset MemStartIndex
        xlat
        mov di,ax

        prntreg P1Registers,RegNames

        inc counter
        cmp counter,8
        jnz prntregs1
```

### PaintBackGnd: {#PaintBackGnd}

> Change graphics mode to video mode 
>
