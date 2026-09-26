;===================================================================
; Microprocesadores - Actividad I
; Sistema: Z80 + 2x 8255 (PPI) + 28C256 (EEPROM, codigo) + 6264 (SRAM, datos)
; Tarea (inciso 3):
;   a) Muestra un texto solicitando nombre y apellidos
;   b) Captura nombre y apellidos (letras y espacios)
;   c) Envia mensaje de error ante un caracter invalido (ni letra ni espacio)
;   d) Cuenta el numero de letras (sin contar espacios)
;   e) Muestra un texto y la cantidad de letras
; Autor: Ivan
;===================================================================

	.org 0000h
;----------------- inicializacion del sistema ---------------------
	ld a,89h        ;PPI1: Puerto A->salida (LCD), Puerto B->salida (sin uso),
	out (CW1),a     ;      Puerto C->entrada (KEYB)  [1000 1001b]
	ld a,89h        ;PPI2: queda inicializado y disponible para expansion
	out (CW2),a     ;      (no se usa en este programa; completa los 6 puertos)
	ld SP,ffffh     ;pila al tope de la SRAM (F800h-FFFFh)

;----------------- programa principal ------------------------------
	ld hl,msg_prompt
	call desp_text        ;solicita nombre y apellidos

	ld b,0                ;B = contador de letras (sin espacios)
	ld hl,buffer           ;HL = puntero al buffer en SRAM (datos)

captura:
	call lee_tecla         ;espera/lee una tecla -> A
	cp 0dh                 ;ENTER (0Dh) = fin de captura
	jp z,fin_captura

	cp ' '                 ;20h : espacio -> valido, no se cuenta
	jp z,es_valido

	cp 41h                 ;'A'
	jp c,invalido          ;A < 'A'          -> invalido
	cp 5bh                 ;'Z'+1
	jp c,es_letra          ;'A' <= A <= 'Z'  -> letra mayuscula
	cp 61h                 ;'a'
	jp c,invalido          ;'Z' < A < 'a'    -> invalido
	cp 7bh                 ;'z'+1
	jp c,es_letra          ;'a' <= A <= 'z'  -> letra minuscula
	jp invalido            ;A > 'z'          -> invalido

es_letra:
	inc b                  ;cuenta la letra
es_valido:
	ld (hl),a              ;guarda el caracter en el buffer (SRAM)
	inc hl
	out (LCD),a            ;eco en pantalla
	jp captura

invalido:
	push hl                ;conserva el puntero del buffer
	ld hl,msg_error
	call desp_text         ;muestra mensaje de error
	pop hl
	jp captura             ;el caracter invalido NO se guarda ni se cuenta

fin_captura:
	ld hl,msg_resultado
	call desp_text         ;muestra texto de resultado
	ld a,b                 ;A = total de letras (0-255)
	call muestra_num       ;convierte y muestra el numero en decimal
	halt

;----------------- subrutinas --------------------------------------
desp_text:                 ;muestra cadena apuntada por HL, termina en '&'
	ld a,(hl)
	cp '&'
	jp z,fin_desp
	out (LCD),a
	inc hl
	jp desp_text
fin_desp:
	ret

lee_tecla:                 ;lee una tecla del puerto KEYB -> A
	in a,(KEYB)
	;NOTA: el ejemplo visto en clase (lee_KEYB) lee el puerto en forma
	;directa, sin bandera de "dato listo". Aqui se sigue la misma
	;convencion; si el simulador Z80_workbench requiere esperar un
	;cambio de valor para detectar una tecla nueva, conviene revisar
	;su manual y agregar aqui la espera correspondiente.
	ret

muestra_num:                ;convierte A (0-255) a 3 digitos ASCII y los
	ld c,0                  ;muestra en LCD (centenas-decenas-unidades)
cien:
	cp 64h                  ;100 decimal
	jp c,decenas_ini
	sub 64h
	inc c
	jp cien
decenas_ini:
	ld b,0
decenas:
	cp 0ah                  ;10 decimal
	jp c,unidades
	sub 0ah
	inc b
	jp decenas
unidades:                   ;A = digito de unidades
	push af
	ld a,c
	add a,'0'
	out (LCD),a              ;centenas
	pop af
	push af
	ld a,b
	add a,'0'
	out (LCD),a              ;decenas
	pop af
	add a,'0'
	out (LCD),a              ;unidades
	ret

;----------------- mensajes constantes (EEPROM, 0000h-3FFFh) -------
msg_prompt:    .db "Nombre y apellidos (letras y espacios). ENTER para terminar: &"
msg_error:     .db " [caracter invalido, solo letras y espacios] &"
msg_resultado: .db " Total de letras (sin contar espacios): &"

;----------------- puertos (PPI 8255, I/O 40h en adelante) ---------
LCD:   .equ 40h   ;PPI1 - Puerto A (salida)  -> pantalla/LCD
KEYB:  .equ 42h   ;PPI1 - Puerto C (entrada) -> teclado
CW1:   .equ 43h   ;PPI1 - palabra de control
CW2:   .equ 47h   ;PPI2 - palabra de control (PA=44h PB=45h PC=46h, libres)

;----------------- datos variables (SRAM, F800h-FFFFh) -------------
	.org f800h
buffer:            ;aqui se guarda el nombre y apellidos capturados

;program ends
	.end
