.model small
 .stack 100h
 .data

 tekstas db 'Iveskite: $'
 maximumas db 100
 simboliai db 0
 eilute db 100 DUP (0)
 naujalinija db 13,10,13,10,'$'
 hex1 db ?    
 hex2 db '  $' 

.code
start:
  mov  AX, @data
  mov  DS, AX

  mov  AH, 9
  lea  DX, tekstas
  int  21h

  mov  AH, 0Ah
  lea  DX, maximumas
  int  21h

  mov  AH, 9
  lea  DX, naujalinija
  int  21h

  mov  CL, simboliai
  mov  ch, 0 
  mov  SI, offset eilute

ciklas:         

  mov  DL, [SI] 

  cmp DL, '9'   ;pakeitimas
  jbe toliau    ;pakeitimas
  jmp netinka   ;pakeitimas
  
toliau:         ;pakeitimas
  cmp DL, '0'   ;pakeitimas
  jae  galas    ;pakeitimas
 
netinka:        ;pakeitimas
  and  DL, 00001111b
  call convertuot 
  mov  hex2, dl 

  mov  DL, [SI] 

  shr  DL, 4 
  call convertuot 
  mov  hex1, dl 

  mov  ah, 9
  mov  dx, offset hex1
  int  21h  

galas:        ;pakeitimas
  inc  si 
  loop ciklas
  mov AL, 0
  mov AH,4Ch
  int 21h


proc convertuot       
  cmp DL, 9
  jbe skaitmuo 

  add dl, 55 
  jmp pabaiga  
skaitmuo:  
  add dl, 48 
pabaiga:
  ret
endp 

end start