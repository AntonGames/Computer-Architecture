;Žingsninio režimo pertraukimo (int 1) apdorojimo procedūra, atpažįstanti komandą DEC r/m. 
;Ši procedūra turi patikrinti, ar pertraukimas įvyko prieš vykdant komandos DEC pirmąjį variantą,
;jei taip, į ekraną išvesti perspėjimą, ir visą informaciją apie komandą: adresą, kodą, mnemoniką, operandus.
.model small
.stack 100h
.data

	;Registrus issisaugojimui 
	regAX dw ?
	regBX dw ?
	regCX dw ?
	regDX dw ?
	regSP dw ? 
	regBP dw ?
	regSI dw ?
	regDI dw ?
	
	;komandu galimi variantai
	reg_bxsi db "BX + SI$"
	reg_bxdi db "BX + DI$"
	reg_bpsi db "BP + SI$"
	reg_bpdi db "BP + DI$"
	reg_si db "SI$" 
	reg_di db "DI$"
	reg_bp db "BP$"	
	reg_ax db "AX$"
	reg_al db "AL$"
	reg_ah db "AH$"
	reg_bx db "BX$"
	reg_bl db "BL$"
	reg_bh db "BH$"
	reg_cx db "CX$"
	reg_cl db "CL$"
	reg_ch db "CH$"
	reg_dx db "DX$"
	reg_dl db "DL$"
	reg_dh db "DH$"
	reg_sp db "SP$"
	
	;Saugomos baitu reiksmes
	operacijos_kodas db ?
	adresavimo_baitas db ?
	poslinkis1 db ?
	poslinkis2 db ?
	
	;w mod ir r/m reiksmes
	cw db ?
	cmod db ?
	crm db ?
	kodo_pletinys db ? ;pakeitimas
	
	;komandu tekstas
	pranesimas db "Zingsnio rezimo pertraukimas! ", 13, 10, '$'
	dec_komanda db "DEC $"
	inc_komanda db "INC $"
	byte_ptr db "byte ptr $"
	word_ptr db "word ptr $"	
	
	plius db " + $" 
	lygu db " = $"
	brac_open db "[$"
	brac_close db "]$"	
	dvitaskis db ":$"
	kablelis db ",$"	
	enteris db 13,10,"$"
	tarpas db " $"
	
.code
;Isspausdina paduota string'a
PrintString MACRO tekstas 
	push ax
	push dx
	mov dx, offset tekstas
	mov ah, 9
	int 21h
	pop dx
	pop ax
ENDM

;Macros'ai tikrina r/m reiksmes skirtingais variantais
TikrinkRM MACRO _rm, tekstas  
	mov al, _rm
	mov dx, offset tekstas
	call printRM
ENDM
TikrinkRM_value MACRO _rm, tekstas, reiksme 
	mov al, _rm
	mov dx, offset tekstas
	mov bx, reiksme
	call printRM
ENDM
TikrinkRM_1 MACRO _rm, tekstas1, reiksme1
	mov al, _rm
	mov dx, offset tekstas1
	mov bx, reiksme1
	call papildoma
ENDM

TikrinkRM_2 MACRO _rm, tekstas1, reiksme1, tekstas2, reiksme2
	push bx
	mov al, _rm
	mov dx, offset tekstas1
	mov bx, reiksme1
	call papildoma
	mov dx, offset tekstas2
	mov bx, reiksme2
	call papildoma
	pop bx
ENDM
pradzia:
	mov ax, @data
	mov ds, ax
	
	;es reiksme pasidarome nuliu, isivalome pakeitimui
	mov ax, 0
	mov es, ax
	
	;Pasiemame reiksmes is vektoriaus lenteles pagal INT 1
	push es:[4] ;IP - instruction pointer
	push es:[6] ;CS - code segment
	
	;Pasiemame dabartines cs ir pertraukimo proceduros reiksmes, padedame i vektoriu lentele
	mov ax, cs; 
	mov bx, offset pertraukimas
	
	;reiksmiu i vektoriu lentele padejimas
	mov es:[4], bx
	mov es:[6], ax
	
	;TRAP FLAG nustatymas = INT 1 vykdymas
	zingsninio_rezimas_ijungimas:
	pushf
	pop ax
	or ax, 100h
	push ax
	popf
	
	testavimo_kodas:
	mov bx, 1h
	dec word ptr [bx]
	inc word ptr [bx]
	dec word ptr [bx+si+4]
	inc word ptr [bx+si+4]

	;INT 1 isjungimas
	zingsninio_rezimo_isjungimas:
	pushf
	pop ax
	and ax, 0FEFFh
	push ax
	popf

	grazinam_vektoriaus_lenteles_reiksmes:
	pop es:[6] ;CS - code segment 
	pop es:[4] ;IP - instruction pointer
	
	pabaiga:	
	mov ah, 4Ch
	mov al, 0
	int 21h
	
pertraukimas:
	;Issisaugome registrus
	mov regAX, ax				
	mov regBX, bx
	mov regCX, cx
	mov regDX, dx
	mov regSP, sp
	mov regBP, bp
	mov regSI, si
	mov regDI, di

	;Pasiimame komandos poslinki 
	pop si
	pop di
	push di ;cs
	push si ;ip

	mov ax, cs:[si]    ;operacijos kodas ir adresavimo kodas
	mov bx, cs:[si+2]  ;poslinkio 2 baitai
	
	;Issaugome 4 komandos baitus
	mov operacijos_kodas, al
	mov adresavimo_baitas, ah
	mov poslinkis1, bl
	mov poslinkis2, bh
		
	tikrinimas:
	mov al, operacijos_kodas
	mov ah, adresavimo_baitas
	
	;Tikriname, ar komanda yra dec
	;Pagal operacijos koda
	push ax
	and al, 0FEh ;1111 1110b
	cmp al, 0FEh 
	jne pertraukimo_pabaiga 
	
	;Pagal adresavimo baita (operacijos kodo pletinys)
	and ah, 38h ;0011 1000b
	
	;pakeitimas
	mov kodo_pletinys, ah
	cmp ah, 8h  ;0000 1000b
	je tinka
	cmp ah, 0
	jne pertraukimo_pabaiga
	pop ax
	tinka:
	;pakeitimas
	
	;Issisaugom w, mod, rm reiksmes
	;w 
	push ax
	and al, 01h ;0000 0001b
	mov cw, al 
	pop ax
	
	;mod
	push ax
	and ah, 0C0h ;1100 0000b
	mov cmod, ah
	pop ax
	
	;rm
	push ax
	and ah, 07h ;0000 0111b
	mov crm, ah
	pop ax
		
	jmp komandos_analize
	pertraukimo_pabaiga:
	jmp pert_pabaiga
	
	komandos_analize:
	PrintString pranesimas ;Spausdiname masinini koda
	
	mov ax, di  ;spausdiname komandos poslinki (cs)
	call printAX
	PrintString dvitaskis
	mov ax, si  ;spausdiname komandos poslinki (ip)
	call printAX
	PrintString tarpas
	
	mov al, operacijos_kodas
	call printAL
	mov al, adresavimo_baitas
	call printAL

	;Tikriname, ar reikia dar spausdinti poslinki po adresavimo_baitas
	cmp cmod, 0C0h ;1100 0000b
	je registro_printinimas ;kai mod = 11
	
	cmp cmod, 0 ;kai mod = 00
	jne kiek_baitu_poslinkis
	
	cmp crm, 06h ;0110b (ar rm = 110?)
	je print_2_baitu_poslinki ; atskiras atvejis kai mod = 00, rm = 110
	jmp nera_poslinkio
	
	kiek_baitu_poslinkis:
		cmp cmod, 040h ;0100 0000b, kai mod = 01
		je print_1_baito_poslinki
	print_2_baitu_poslinki:
		mov al, poslinkis2
		call printAL
		mov al, poslinkis1
		call printAL
		jmp nera_poslinkio
	print_1_baito_poslinki:
		mov al, poslinkis1
		call printAL

	nera_poslinkio:
		PrintString tarpas
		
	jmp komandos_isvedimas
	
	registro_printinimas: ;kai mod = 11
	PrintString tarpas
	
	;pakeitimas
	cmp kodo_pletinys, 8h
	jne spausdinti_inc1
	PrintString dec_komanda
	jmp skip1
	spausdinti_inc1:
	PrintString inc_komanda
	skip1:
	;pakeitimas
	
	cmp cw, 0
	jne tikrinamas_rm_w_1
	PrintString tarpas
	jmp tikrinamas_rm_w_0
	
	tikrinamas_rm_w_1:
	PrintString word_ptr
	
	TikrinkRM_value 00h, reg_ax,regAX
	TikrinkRM_value 01h, reg_cx,regCX
	TikrinkRM_value 02h, reg_dx,regDX
	TikrinkRM_value 03h, reg_bx,regBX
	TikrinkRM_value 04h, reg_sp,regSP
	TikrinkRM_value 05h, reg_bp,regBP
	TikrinkRM_value 06h, reg_si,regSI
	TikrinkRM_value 07h, reg_di,regDI
	PrintString enteris
	jmp pert_pabaiga
		
	tikrinamas_rm_w_0:
	
	TikrinkRM_value 00h, reg_al,regAX
	TikrinkRM_value 01h, reg_cl,regCX
	TikrinkRM_value 02h, reg_dl,regDX
	TikrinkRM_value 03h, reg_bl,regBX
	TikrinkRM_value 04h, reg_ah,regSP
	TikrinkRM_value 05h, reg_ch,regBP
	TikrinkRM_value 06h, reg_dh,regSI
	TikrinkRM_value 07h, reg_bh,regDI
	PrintString enteris
	jmp pert_pabaiga
	
	;DEC komandos isvedimas su argumentais
	komandos_isvedimas:
	
	;pakeitimas
	cmp kodo_pletinys, 8h
	jne spausdinti_inc2
	PrintString dec_komanda
	jmp skip2
	spausdinti_inc2:
	PrintString inc_komanda
	skip2:
	;pakeitimas
	
	cmp cw, 0
	je w0
	PrintString word_ptr
	jmp mod_rm_analize
	
	w0:
	PrintString byte_ptr

	mod_rm_analize:
	PrintString brac_open
		
	cmp cmod, 0
	jne rm_analize
	cmp crm, 06h ; 0000 0110b
	je su_2_baitu_poslinkiu ; atskiras atvejis, kai mod = 00, rm = 110
	
	;Kas dec'reasinama
	rm_analize:
	TikrinkRM 00h, reg_bxsi
	TikrinkRM 01h, reg_bxdi
	TikrinkRM 02h, reg_bpsi
	TikrinkRM 03h, reg_bpdi
	TikrinkRM 04h, reg_si
	TikrinkRM 05h, reg_di
	TikrinkRM 06h, reg_bp
	TikrinkRM 07h, reg_bx
					
	tikr_offset:
		cmp cmod, 0
		je be_poslinkio
	su_poslinkiu:
		PrintString plius
		cmp cmod, 80h ;1000 0000b
		je su_2_baitu_poslinkiu
	su_1_baitu_poslinkiu:
		mov al, poslinkis1
		call printAL
		jmp be_poslinkio
	su_2_baitu_poslinkiu:
		mov al, poslinkis2
		call printAL
		mov al, poslinkis1
		call printAL
	PrintString brac_close
	PrintString kablelis
			
	;atskiras atvejis baigimui  (kai mod = 00 , r/m = 110)
	cmp cmod, 0
	jne value
	cmp crm, 06h ;0000 0110b
	jne value
	jmp pert_pabaiga_enter

	be_poslinkio:
	PrintString brac_close
	PrintString kablelis
	value:
	
	;Ka dec'reasinom
	TikrinkRM_2 00h, reg_bx, regBX, reg_si, regSI
	TikrinkRM_2 01h, reg_bx, regBX, reg_di, regDI
	TikrinkRM_2 02h, reg_bp, regBP, reg_si, regSI
	TikrinkRM_2 03h, reg_bp, regBP, reg_di, regDI
	TikrinkRM_1 04h, reg_si, regSI
	TikrinkRM_1 05h, reg_di, regDI
	TikrinkRM_1 06h, reg_bp, regBP
	TikrinkRM_1 07h, reg_bx, regBX	
		
	pert_pabaiga_enter:
	PrintString enteris
	pert_pabaiga:
		
	mov ax, regAX
	mov bx, regBX
	mov cx, regCX
	mov dx, regDX
	mov sp, regSP
	mov bp, regBP
	mov si, regSI
	mov di, regDI
iret
printRM proc
	;al -> rm reiksme, dx - string'o adresas
	cmp al, crm 
	jne netinka 
	push ax
	mov ah, 9
	int 21h
	pop ax
	cmp cmod, 0C0h
	jne netinka
		;Jeigu mod = 11
		PrintString kablelis
		PrintString tarpas
		push ax
		push bx
		mov ah, 9
		int 21h
		PrintString lygu
		cmp cw, 1
		je w_didesnis
		mov ax, bx
		call printAL
		jmp pabaigti_spausdinima
		w_didesnis:
		mov ax, bx
		call printAL
		mov al, ah
		call printAL
		pabaigti_spausdinima:
		pop bx
		pop ax
	netinka:
		ret
endp

;Spausdina AX
printAX proc
	push ax
	mov al, ah
	call printAL
	pop ax
	call printAL
	RET
endp

;Spausdina AL
printAL proc
	push ax
	push cx
	
	push ax
	mov cl, 4
	shr al, cl
	call printHexSkaitmuo
	pop ax
	call printHexSkaitmuo
		
	pop cx
	pop ax
	RET
endp
;Spausdina hex skaitmeni pagal AL jaunesniji pusbaiti
printHexSkaitmuo proc
	push ax
	push dx
	;nunulinam vyresniji pusbaiti
	and al, 0Fh 
	cmp al, 9
	jbe PrintHexSkaitmuo_0_9
	jmp PrintHexSkaitmuo_A_F
	
	PrintHexSkaitmuo_A_F: 
	sub al, 10 
	add al, 41h
	mov dl, al
	mov ah, 2
	int 21h
	jmp PrintHexSkaitmuo_grizti
	
	PrintHexSkaitmuo_0_9: 
	mov dl, al
	add dl, '0'
	mov ah, 2 
	int 21h
	
	printHexSkaitmuo_grizti:
	pop dx
	pop ax
	RET
endp	

papildoma proc ;spausdina registrus ir ju poslinkius (pabaigoje)
	push ax
	cmp al, crm 
	jne netinka2
	PrintString tarpas
	push ax
	call printRM
	PrintString lygu
	mov ax, bx
	call printAX
		PrintString kablelis
		pop ax
		PrintString brac_open
		call printRM
		PrintString brac_close
		PrintString lygu
		mov ax, [bx]
		call printAX
	netinka2:
	pop ax
	ret
endp
END