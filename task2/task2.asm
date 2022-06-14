.model small		    
skBufDydis     EQU 255	
raBufDydis    EQU 255
.stack 100h		
.data            
	kiekKartuNuskaityta DB 0
	masyvoDydis   DW 0
    
    duom        DB 50 dup (?)
   	skBuf   	    DB skBufDydis dup (0)
   	dFail      DW ?   ;handle
   	
    
    rez        DB 50 dup (?)
	raBuf   	     DB raBufDydis dup (0)
    rFail      DW ?   ;handle
	
	skaicius         DB 0
    
    pagalba             DB 'Tai programa, kuri padaugina beveik bet kokio ilgio sesioliktaini teigiama skaiciu, esanti faile, is skaiciaus nuo 0 iki F ir isveda rezultata i kita faila. Parametru pavyzdys.: antra masyvoDydis.txt 6 rez.txt $'   
    sekmingaiIvykdyta   DB 'Programa buvo sekmingai ivykdyta be klaidu, rezultatas yra faile $'
	neraSkaiciaus       DB 'Duomenu faile skaiciaus nera $'
.code

pradzia:                  
    MOV AX, @data
    MOV DS, AX  
    	
	MOV SI, 0
	MOV BH, 0   
		
	LEA DI, duom
	CALL skaitytiParametrus
	CMP BH, 0FFh
	JE klaida
	LEA DI, skaicius
	CALL skaitytiParametrus 
	CMP skaicius, 39h
    JBE skaitmuo4 
    SUB skaicius, 37h 
    JMP pabaiga4  
    skaitmuo4: 
    SUB skaicius, 30h
    pabaiga4:   
	CMP BH, 0FFh
	JE klaida
	
	LEA DI, rez
	CALL skaitytiParametrus
	CMP BH, 0FFh
	JE klaida  
	
	
	MOV AX, 3D00h                  
	LEA DX, duom
	INT 21h
	JC klaida                   
	MOV dFail, AX                  
	 
	MOV AH, 3Ch                   
	MOV CX, 0                      
	LEA DX, rez
	INT 21h
	JC klaida                    
	MOV rFail, AX            
	
	JMP skaitytiFaila 
    
	klaida:   
    	MOV AH, 09h  
        LEA DX, pagalba
        INT 21h
        MOV AX, 4C00h
        INT 21h
		
    ;pakeitimas
	klaida3:
		MOV AH, 09h
	    LEA DX, neraSkaiciaus
	    INT 21h
		MOV AX, 4C00h
        INT 21h
	;pakeitimas
	
	
	skaitytiFaila:
	    CALL pravalytiBufferi
	    MOV BH, 0
	    CALL rasytiIBufferi    
	    CMP BH, 0FFh
	    JE klaida3      ;pakeitimas
	    CMP AX, 0       
	    JE baigti2
		JMP skaiciavimai
	baigti2:	
		MOV AH, 3Eh
	    MOV BX, rFail   
	    INT 21h
	    JC klaida
	
	    MOV AH, 3Eh
	    MOV BX, dFail  
	   INT 21h
	   JC klaida
	
	    MOV AH, 09h
	    LEA DX, sekmingaiIvykdyta
	    INT 21h
	
	    MOV AH, 09h
	    LEA DX, rez
	    INT 21h
	
	skaiciavimai:
	    MOV	CX, AX
		MOV AX, 0
	    MOV BX, 0
	    MOV DX, 0
	    MOV SI, offset skBuf
	    MOV	DI, offset raBuf
	    ADD SI, CX 
	    DEC SI
        dirbk:
           CMP CX, 0
	       JE rasymasIFaila
        ciklas:         
		MOV  AL, [SI]   
        CMP AL, 39h
        JBE skaitmuo 
        SUB AL, 37h 
        JMP pabaiga2  
        skaitmuo: 
            CMP AL, 0
            JE pabaiga2 
            SUB AL, 30h
        pabaiga2: 
            MUL skaicius  
            ADD AX, BX
			MOV BX, 16
			DIV BX
			MOV BX, AX 
			
			MOV AX, DX
			MOV DX, 0
            CMP DX, 0
            
            PUSH AX
	        DEC	SI
	        INC masyvoDydis
	        LOOP ciklas
	        
	        CMP BX, 0
	        JE skip
	        MOV AX, BX
	        PUSH AX
	        INC masyvoDydis
	        
	    skip:
	        MOV	DI, offset raBuf
	        MOV CX, masyvoDydis
	        MOV AX, 0
	
	    rasytiIsStako:             ;rasyti skaicius is stako i bufferi
	        POP AX
	        CMP AL, 9h
            JBE skaitmuo3 
            ADD AL, 37h 
            JMP pabaiga3  
            skaitmuo3:  
               ADD AL, 30h
            pabaiga3:  
	           MOV [DI], AL
			   INC DI
	        LOOP rasytiIsStako			
	        
	rasymasIFaila:
	    MOV	CX, masyvoDydis        
	    MOV BX, rFail  
	    CALL rasytIsBufferio
	    CMP DH, 0FFh
	    JE klaida2  
	    CMP AX, skBufDydis   
	    JE skaitytiFaila2
		
	skaitytiFaila2:
	    CALL pravalytiBufferi
	    MOV BH, 0
	    CALL rasytiIBufferi    
	    CMP BH, 0FFh
	    JE klaida2
	    CMP AX, 0       
	    JE baigti
		JMP skaiciavimai
		
	baigti:           
	
	MOV AH, 3Eh
	MOV BX, rFail   
	INT 21h
	JC klaida2
	
	MOV AH, 3Eh
	MOV BX, dFail  
	INT 21h
	JC klaida2
	
	MOV AH, 09h
	LEA DX, sekmingaiIvykdyta
	INT 21h
	
	MOV AH, 09h
	LEA DX, rez
	INT 21h

    klaida2:
	    MOV AH, 09h  
        LEA DX, pagalba
        INT 21h
        MOV AX, 4C00h
        INT 21h
   

    
    
PROC skaitytiParametrus
    
    MOV BL, 0             
    MOV AL, ES:[81h+SI]
    CMP AL, ' '
    JE praleistiTusciasVietas
    JMP toliau
    
	praleistiTusciasVietas:   
    	INC SI
    	MOV AL, ES:[81h+SI]
    	CMP AL, ' '
        JE praleistiTusciasVietas
	
    toliau: 
        MOV AL, ES:[81h+SI]
        CMP AL, ' '              
        JE procedurosUzbaigimas
        CMP ES:[81h+SI], '?/'  
        JE pagalbosIskvietimas   
        CMP AL, 0Dh               
        JE procedurosUzbaigimas
        MOV DS:[DI], AL            
        INC BL               
        INC DI
        INC SI
        JMP toliau
        
    pagalbosIskvietimas:
        MOV BH, 0FFh              
        INC BL
        JMP procedurosUzbaigimas
        
    procedurosUzbaigimas:
        MOV AL, 0
        MOV DS:[DI], AL            
        CMP BL, 0
        JE pagalbosIskvietimas               
        INC DI       
        MOV AL, '$'
        MOV DS:[DI], AL
        DEC DI 
        RET
        
skaitytiParametrus ENDP

PROC rasytiIBufferi           
    MOV CX, skBufDydis
    
    MOV AH, 3Fh
    LEA DX, skBuf      
    MOV BX, dFail
    INT 21h
    JC rasymoKlaida
	PUSH AX
	
	POP DX
	
	CMP AX, 0
	JE tikrintiKlaida
	CMP DX, 0
	JE tikrintiKlaida
	
	tikrintiKlaidaReturn:
	INC kiekKartuNuskaityta
	CMP AX, DX
	JB keitimas
	JMP rasytiIBufferiEnd
	
	keitimas:
	    MOV AX, DX
    
    rasytiIBufferiEnd:
        RET  
        
    rasymoKlaida:
        MOV BH, 0FFh
        MOV AX, 0       
        JMP rasytiIBufferiEnd
		
	tikrintiKlaida:
	CMP kiekKartuNuskaityta, 0
	JE rasymoKlaida
	JMP tikrintiKlaidaReturn
        
rasytiIBufferi ENDP

PROC rasytIsBufferio
    MOV AH, 40h
    LEA DX, raBuf          
    INT 21h
    JC skaitymoKlaida    
    CMP CX, AX
    JNE skaitymoKlaida
    
    rasytIsBufferioEnd:          
        RET
    
    skaitymoKlaida:
        MOV DH, 0FFh       
        JMP rasytIsBufferioEnd
rasytIsBufferio ENDP


PROC pravalytiBufferi
	MOV CX, skBufDydis
	LEA BX, skBuf
	MOV AL, 0
	istrinti:
	MOV DS:[BX], AL
	MOV DS:[BP], AL
	INC BX
	INC BP
	LOOP istrinti
	RET
pravalytiBufferi ENDP
	
        
end pradzia