	page	0
	cpu	z80
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Minimal assembler for EMUZ-80
;
; Designed by Akihito Honda
; 1st release : 2022.11.10??
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MON_Rev03 = 0
RAM12K = 1
RAM_MODE = 1

CR	EQU	0DH
LF	EQU	0AH
BS	EQU	08H
DEL	EQU	7FH
CTLC	equ	03H
NO_UPPER	equ	00000100b
NO_LF		equ	00000010b
NO_CR		equ	00000001b

ROM_B		equ	0000H	;EMUZ80_Q84 ROM base address

B03_1		equ	0040h

	if	RAM12K
RAM_B	equ	0C000H	;EMUZ80_Q84 RAM base address
RAM_SIZ	equ	3000H	; 12K
IO_B	equ	0F000H	;EMUZ80_Q84 I/O base address
WORK_TOP	equ	RAM_B + 2E00H
	else
RAM_B	equ	08000H	; EMUZ80_Q84 RAM base address
RAM_SIZ	equ	2000H	; 8K
IO_B	equ	0E000H	;EMUZ80_Q84 I/O base address
WORK_TOP	equ	RAM_B + 1E00H
	endif

	if RAM_MODE
LASM_BASE	equ	RAM_B
adr_base	equ	lasm_end
	else
LASM_BASE	equ	4500h
adr_base	equ	RAM_B
	endif
	
work_area	equ	work_e - work_s
BUFLEN		equ	40H
NUMLEN		equ	7

	org	LASM_BASE

	jp	c_start

;
; EMUZ80 API
;

;
; console in,out
;
CONOUT:
	rst	08h
	ret

CONIN:
	rst	10h
	ret

CONST:
	rst	18h
	ret


;
; EMUZ80-MON API
;
WSTART:
	ld	c, 01
	rst	30h
	ret

STROUT:
	ld	c, 03
	rst	30h
	ret

HEXOUT4:
	ld	c,07
	rst	30h
	ret

HEXOUT2:
	ld	c,08
	rst	30h
	ret

CRLF:
	ld	c,13
	rst	30h
	ret

RDHEX:	ld	c, 15	; get hex number from chr buffer
	rst	30h	; input  HL : hex string buffer
	ret		; output DE : hex number
			; CF=1 : error, C, A = hex counts(1-4)
dasm_st:
	ld	c, 20		; 20: get dis assemble string
	rst	30h		;     input: HL : disassemble address
	ret			;            DE : user buffer (need 42bytes)
				;     output : DE : next MC address
				;              A  : disassembled MC size

	if	MON_Rev03
GET_dNUM:
	ld	c, 21		; 21: get number from decimal strings
	rst	30h		;     input HL : string buffer
	ret			;     Return
				;        CF =1 : Error
				;        BC: Calculation result
	else

GET_dNUM:
	XOR	A		; Initialize C
	LD	B, A
	LD	C, A		; clear BC
	
GET_NUM0:
	CALL	skp_sp		; A <- next char
	OR	A
	RET	Z		; ZF=1, ok! buffer end

	CALL	GET_BI
	RET	C

	push	af
	EX	AF, AF'		;'AF <> AF: save A
	pop	af
	CALL	MUL_10		; BC = BC * 10
	RET	C		; overflow error
	EX	AF, AF'		;'AF <> AF: restor A

	push	hl
	ld	d, 0
	ld	e, a

	ld	h, b
	ld	l, c
	add	hl, de
	ld	b, h
	ld	c, l		; result: BC = BC * 10 + A
	pop	hl
	RET	C		; overflow error

	INC	HL
	JR	GET_NUM0
;
; Make binary to A
; ERROR if CF=1
;
GET_BI:
	OR	A
	JR	Z, UP_BI
	CP	'0'
	RET	C
	
	CP	'9'+1	; ASCII':'
	JR	NC, UP_BI
	SUB	'0'	; Make binary to A
	RET

UP_BI:
	SCF		; Set CF
	RET

;
; multiply by 10
; BC = BC * 10
MUL_10:
	push	hl

	push	bc
	SLA	C
	RL	B		; 2BC
	SLA	C
	RL	B		; 4BC
	pop	hl		; hl = bc
	add	hl, bc
	push	hl
	pop	bc		; 5BC
	SLA	C
	RL	B		; 10BC

	pop	hl
	RET			; result : BC = BC * 10

	endif

GETLN:	; input hl

	PUSH	de
	push	hl
	ld	e, b	; E: buffer length
	dec	e	; buffer lenght -1
	LD	B,0

GL00:
	CALL	CONIN
	CP	CR
	JR	Z,GLE
	CP	LF
	JR	Z,GLE
	CP	BS
	JR	Z,GLB
	CP	DEL
	JR	Z,GLB
	cp	'"'
	jr	nz, GL001
	push	af
	ld	a, (ky_flg)
	xor	NO_UPPER	; toggle UPPER or NO UPPER
	ld	(ky_flg), a
	pop	af

GL001:	CP	' '
	JR	C,GL00
	CP	80H
	JR	NC,GL00
	LD	C,A
	LD	A,B
	CP	e	; buffer full check
	JR	NC,GL00	; Too long
	INC	B
	LD	A,C
	CALL	CONOUT
	cp	'a'
	jr	c, GL1
	cp	'z'+1
	jr	nc, GL1

	push	hl
	ld	hl, ky_flg
	bit	NO_UPPER>>1, (hl)
	jr	nz, skip_upper
	and	0DFH	; make upper code
skip_upper:
	pop	hl
GL1:
	LD	(HL),A
	INC	HL
	JR	GL00
GLB:
	LD	A,B
	AND	A
	JR	Z,GL00
	DEC	B
	DEC	HL
	LD	A,08H
	CALL	CONOUT
	LD	A,' '
	CALL	CONOUT
	LD	A,08H
	CALL	CONOUT
	JR	GL00
GLE:
	push	hl
	ld	hl, ky_flg
	bit	NO_CR>>1, (hl)
	jr	nz, skip_cr
	ld	a, CR
	call	CONOUT
skip_cr:
	bit	NO_LF>>1, (hl)
	jr	nz, skip_lf
	ld	a, LF
	call	CONOUT
skip_lf:
	res	NO_UPPER>>1,(HL)	; set upper flag
	pop	hl
	LD	(HL),00H

	pop	hl
	POP	de
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; EMUZ80 Mini Assembler Rev.01
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_msg:	db	"EMUZ80 Mini Assembler Rev.01",CR,LF,00
prompt:		db	"> ", 00
com_errm	db	"??? ", 00
lasm_adr	dw	adr_base
dsap		db	"  ", 00

c_start:
	ld	sp, asm_stack
	xor	a
	ld	c, work_area
	ld	hl, work_s
init_l:
	ld	(hl), a
	inc	hl
	dec	c
	jr	nz, init_l
	
	ld	bc, (1)
	ld	hl, B03_1
	sbc	hl, bc
	jr	nz, vchkend
	ld	a, 1
vchkend:
	ld	(mon_vchk), a

	ld	hl, (lasm_adr)
	ld	(asm_adr), hl
	ld	(tasm_adr), hl
	ld	(dsaddr), hl
	ld	(dasm_adr), hl

	ld	hl, init_msg
	call	strout
	
com_in:
	ld	hl, prompt
	call	strout
	
	ld	hl, line_buf
	ld	b, BUFLEN
	call	GETLN

;
; check command input
;
; command:
;	# ? ; command help
;	# A[<address>] ; Mini assemble mode
;			; [.]<cr> : exit assemble mode
;	# L[<address>][,<steps>] ; list disassemble
;	# S<address> ; set address for line assemble
;	# D[<start address>][,<end address>]
;	# BYE	; goto EMUZ80-MON
;
	ld	hl, line_buf
	call	skp_sp
	or	a
	jr	z, com_in
	cp	'?'
	jr	z, hlp_cmd
	cp	'A'
	jp	z, line_asm
	cp	'L'
	jp	z, list_asm
	cp	'S'
	jp	z, setm
	cp	'D'
	jp	z, DUMP
	cp	'B'
	jp	z, exit_asm

com_err:
	ld	hl, com_errm
	call	STROUT		; output error msg
	call	CRLF
	jr	com_in

hlp_cmd:
	inc	hl
	call	skp_sp
	or	a
	jr	nz, com_err
	
	ld	hl, hlp_str
	call	STROUT		; output error msg
	jr	com_in
	
hlp_str:
	db	"? : Command Help", CR, LF
	db	"A[<address>] : Mini Assemble mode", CR, LF
	db	"L[<address>][,<steps>] : List Disassemble", CR, LF
	db	"S[<adr>] :Set Memory", CR, LF
	db	"D[<start address>][,<end address>] : Dump Memory", CR, LF
	db	"BYE ; Go to EMUZ80-MON", CR, LF, 0

list_asm:
	ld	bc, (dasm_adr)
	ld	(tasm_adr), bc
	ld	a, 10
	ld	(steps), a
	xor	a
	ld	(steps+1), a

	inc	hl
	call	skp_sp
	or	a
	jr	z, skp_ladr
	cp	','
	jr	z, list_asm1

	call	RDHEX		; get DE: address
	jp	c, com_err
	ld	(tasm_adr), de	; set start address
	call	skp_sp
	or	a
	jr	z, skp_ladr
	cp	','
	jp	nz, com_err

list_asm1:
	inc	hl
	call	skp_sp
	call	GET_dNUM
	jp	c, com_err
	ld	(steps), bc

skp_ladr:
	ld	hl, (tasm_adr)
	ld	de, line_buf
	push	de
	call	dasm_st
	ld	(tasm_adr), de	; save next address
	pop	hl
	call	STROUT		; cousole out result inline assemble

	call	CONST
	jr	nz, b_List
	ld	bc, (steps)
	dec	bc
	ld	(steps), bc
	ld	a, b
	or	c
	jr	nz, skp_ladr
	jr	b_list1

b_list:
	call	CONIN		; discard key
b_list1:
	ld	hl, (tasm_adr)
	ld	(dasm_adr), hl
	jp	com_in
;;
;; BYE
;;
exit_asm:
	inc	hl
	ld	a, (hl)
	cp	'Y'
	jp	nz, com_err
	inc	hl
	ld	a, (hl)
	cp	'E'
	jp	nz, com_err
	jp	WSTART		; goto monitor

;;; 
;;; Dump memory
;;; 

dsep0:
	DB	" :",00H
dsep1:
	DB	" | ",00H

dump:
	inc	hl
	ld	a, (hl)
	call	skp_sp
	call	RDHEX		; 1st arg.
	jr	c, dp0
	;; 1st arg. found
	ld	(dsaddr), de
	jr	dp00

dp0:	;; no arg. chk

	push	hl
	ld	hl, (dsaddr)
	ld	bc, 128
	add	hl, bc
	ld	(deaddr), hl
	pop	hl
	ld	a,(hl)
	or	a
	jr	z, dpm_c	; no arg.

dp00:
	call	skp_sp
	ld	a, (hl)
	cp	','
	jr	z, dp1
	or	a
	jp	nz, com_err

	;; no 2nd arg.

	ld	hl, 128
	add	hl, de
	ld	(deaddr), hl
	jr	dpm_c

dp1:
	inc	hl
	call	skp_sp
	call	RDHEX
	jp	c, com_err
	call	skp_sp
	or	a
	jp	nz, com_err
	inc	de
	ld	(deaddr), de
dpm_c:
	call	dpm
	jp	com_in
	
	;; dump main
dpm:
	ld	hl, (dsaddr)
	ld	a, 0f0h
	and	l
	ld	l, a
	xor	a
	ld	(dstate), a
dpm0:
	push	hl
	call	dpl
	pop	hl
	ld	bc, 16
	add	hl, bc
	call	CONST
	jr	nz, dpm1
	ld	a, (dstate)
	cp	2
	jr	c, dpm0
	ld	hl, (deaddr)
	ld	(dsaddr), hl
	ret

dpm1:
	ld	(dsaddr), hl
	jp	CONIN

dpl:
	;; dump line
	call	HEXOUT4
	push	hl
	ld	hl, dsep0
	call	STROUT
	pop	hl
	ld	ix, line_buf
	ld	b, 16
dpl0:
	call	dpb
	djnz	dpl0

	ld	hl, dsep1
	call	STROUT

	ld	hl, line_buf
	ld	b, 16
dpl1:
	ld	a, (hl)
	inc	hl
	cp	' '
	jr	c, dpl2
	cp	7fh
	jr	nc, dpl2
	call	CONOUT
	jr	dpl3
dpl2:
	ld	a, '.'
	call	CONOUT
dpl3:
	djnz	dpl1
	jp	CRLF

dpb:	; dump byte

	ld	a, ' '
	call	CONOUT
	ld	a, (dstate)
	or	a
	jr	nz, dpb2
	; dump state 0
	ld	a, (dsaddr)	; low byte
	cp	l
	jr	nz, dpb0
	ld	a, (dsaddr+1)	; high byte
	cp	h
	jr	z, dpb1
dpb0:	; still 0 or 2
;	ld	a,' '
	ld	a,'-'
	call	CONOUT
	call	CONOUT
	ld	(ix), a
	inc	hl
	inc	ix
	ret
dpb1:	; found start address
	ld	a, 1
	ld	(dstate), a
dpb2:
	ld	a, (dstate)
	cp	1
	jr	nz, dpb0
	; dump state 1
	ld	a, (hl)
	ld	(ix), a
	call	HEXOUT2
	inc	hl
	inc	ix
	ld	a, (deaddr)	; low byte
	cp	l
	ret	nz
	ld	a, (deaddr+1)	; high byte
	cp	h
	ret	nz
	; found end address
	ld	a, 2
	ld	(dstate), a
	ret

;;;
;;; set memory
;;; 
setm:
	inc	hl
	call	skp_sp
	call	RDHEX

	jp	c, com_err

	call	skp_sp
	ld	a, (hl)
	or	a
	jp	nz,com_err
	ld	a, c
	or	a
	jr	nz, sm0
	ld	de, (saddr)


sm0:
	ex	de,hl
sm1:
	call	HEXOUT4
	push	hl
	ld	hl, dsap
	call	STROUT
	pop	hl
	ld	a, (hl)
	push	hl
	call	HEXOUT2
	ld	a, ' '
	call	CONOUT
	ld	hl, line_buf
	ld	b, BUFLEN
	call	GETLN
	call	skp_sp
	ld	a, (hl)
	or	a
	jr	nz, sm2
	;; empty  (increment address)
	pop	hl
	inc	hl
	ld	(saddr), hl
	jr	sm1
sm2:
	cp	'-'
	jr	nz,sm3
	;; '-'  (decrement address)
	pop	hl
	dec	hl
	ld	(saddr), hl
	jr	sm1
sm3:
	cp	'.'
	jr	nz, sm4
	pop	hl
	ld	(saddr), hl

	jp	com_in

sm4:
	call	rdhex
	or	a
	pop	hl
	jp	z, com_err
	ld	(hl), e
	inc	hl
	ld	(saddr) ,hl	; set value
	jr	sm1

;--------------------------------------------------
;
; Line assemble
;
;--------------------------------------------------

dm_bit	equ	80h

ope_cds:
; 4 bytes string
	db	"INIR",	dm_bit | 57
	db	"INDR",	dm_bit | 59
	db	"OUTI",	dm_bit | 61
	db	"OTIR",	dm_bit | 62
	db	"OUTD",	dm_bit | 63
	db	"OTDR",	dm_bit | 64
	db	"HALT",	dm_bit | 51
	db	"RETI",	dm_bit | 47
	db	"RETN",	dm_bit | 48
	db	"DJNZ",	dm_bit | 44
	db	"CALL",	dm_bit | 45
	db	"CPDR",	dm_bit | 40
	db	"LDIR",	dm_bit | 03
	db	"LDDR",	dm_bit | 05
	db	"PUSH",	dm_bit | 08
	db	"RLCA",	dm_bit | 10
	db	"RRCA",	dm_bit | 14
	db	"CPIR",	dm_bit | 38

; 3 bytes string
	db	"LDI",	dm_bit | 02
	db	"LDD",	dm_bit | 04
	db	"EXX",	dm_bit | 07
	db	"POP",	dm_bit | 09
	db	"RLA",	dm_bit | 11
	db	"RLC",	dm_bit | 12
	db	"RRA",	dm_bit | 15
	db	"RRC",	dm_bit | 16
	db	"SLA",	dm_bit | 18
	db	"SRA",	dm_bit | 19
	db	"SRL",	dm_bit | 20
	db	"ADD",	dm_bit | 21
	db	"ADC",	dm_bit | 22
	db	"INC",	dm_bit | 23
	db	"SUB",	dm_bit | 24
	db	"SBC",	dm_bit | 25
	db	"DEC",	dm_bit | 26
	db	"AND",	dm_bit | 27
	db	"XOR",	dm_bit | 29
	db	"CPL",	dm_bit | 30
	db	"NEG",	dm_bit | 31
	db	"CCF",	dm_bit | 32
	db	"SCF",	dm_bit | 33
	db	"BIT",	dm_bit | 34
	db	"SET",	dm_bit | 35
	db	"RES",	dm_bit | 36
	db	"CPI",	dm_bit | 37
	db	"CPD",	dm_bit | 39
	db	"RET",	dm_bit | 46
	db	"RST",	dm_bit | 49
	db	"NOP",	dm_bit | 50
	db	"INI",	dm_bit | 56
	db	"IND",	dm_bit | 58
	db	"OUT",	dm_bit | 60
	db	"DAA",	dm_bit | 65
	db	"RLD",	dm_bit | 66
	db	"RRD",	dm_bit | 67
	db	"ORG",	dm_bit | 68

; 2 bytes string
	db	"EX",	dm_bit | 06
	db	"RL",	dm_bit | 13
	db	"RR",	dm_bit | 17
	db	"OR",	dm_bit | 28
	db	"CP",	dm_bit | 41
	db	"JP",	dm_bit | 42
	db	"JR",	dm_bit | 43
	db	"IM",	dm_bit | 54
	db	"IN",	dm_bit | 55
	db	"DI",	dm_bit | 52
	db	"EI",	dm_bit | 53
	db	"LD",	dm_bit | 01
	db	"DB",	dm_bit | 69
	db	"DW",	dm_bit | 70
	db	0	; delimiter

operand_cds:
; 4 bytes string
	db	"(BC)",	dm_bit | 26
	db	"(DE)",	dm_bit | 27
	db	"(HL)",	dm_bit | 28
	db	"(IX)",	dm_bit | 29
	db	"(IY)",	dm_bit | 30
	db	"(SP)",	dm_bit | 32

; 3 bytes string
	db	"(C)",	dm_bit | 31
	db	"AF'",	dm_bit | 3

; 2 bytes string
	db	"AF",	dm_bit | 2
	db	"BC",	dm_bit | 5
	db	"DE",	dm_bit | 8
	db	"HL",	dm_bit | 11
	db	"IX",	dm_bit | 14
	db	"IY",	dm_bit | 15
	db	"SP",	dm_bit | 16
	db	"NZ",	dm_bit | 20
	db	"NC",	dm_bit | 21
	db	"PO",	dm_bit | 23
	db	"PE",	dm_bit | 24

; 1 bytes string
	db	"A",  	dm_bit | 1
	db	"B",	dm_bit | 4
	db	"C",	dm_bit | 6
	db	"D",	dm_bit | 7
	db	"E",	dm_bit | 9
	db	"H",	dm_bit | 10
	db	"L",	dm_bit | 12
	db	"I",	dm_bit | 13
	db	"R",	dm_bit | 17
	db	"Z",	dm_bit | 18
	db	"M",	dm_bit | 19
	db	"P",	dm_bit | 22
	db	0	; delimiter

opr_cd1:
	db	"(IX+",	dm_bit | 33
	db	"(IY+",	dm_bit | 34
	db	"(IX-",	dm_bit | 36
	db	"(IY-",	dm_bit | 37
	db	0	; delimiter

;A[<address>]	; input line assemble mode
;		; [.]<cr> : exit assemble mode
line_asm:
	inc	hl
	call	skp_sp
	or	a
	jr	z, skpa_adr
	call	RDHEX		; get DE: address
	jp	c, com_err
	ld	(asm_adr), de	; set start address

	call	skp_sp
	or	a
	jp	nz, com_err
	
	; init work area
skpa_adr:
	ld	hl, (asm_adr)
	ld	(tasm_adr), hl
	
	; print address

next_asm:
	xor	a
	ld	(element_cnt), a
	ld	(opc_cd), a
	ld	(opr1_cd), a
	ld	(opr2_cd), a

	ld	hl, (tasm_adr)
	call	HEXOUT4
	ld	hl, dsap
	call	STROUT

;-----------------------------
; get a line from console
;-----------------------------
	ld	hl, ky_flg
	set	NO_LF>>1, (hl)
	ld 	hl, line_buf
	ld	b, BUFLEN

	push	hl
	call	GETLN
	ld	hl, ky_flg
	res	NO_LF>>1, (hl)
	pop	hl

	call	recorrect
	ld	a, (hl)
	cp	CTLC
	jr	z, ext_asm
	cp	'.'
	jr	z, ext_asm
	or	a		; NULL?
	jp	nz, cont_asm
	call	lf_out
	jr	next_asm

ext_asm:
	call	lf_out
	ld	hl, (tasm_adr)
	ld	(asm_adr), hl	; save new address
	jp	com_in		; exit assemble mode

lf_out:
	ld	a, LF
	jp	CONOUT

asm_err:
	ld	hl, com_errm
asm_err1:
	call	lf_out
	call	STROUT
	ld	hl, ERRMSG
	call	STROUT
	jr	next_asm

ERRMSG:	db	"Error", CR, LF, 0

;-------------------------------------------------
; post operation
;-------------------------------------------------
cout_sp:
	ld	a, (mon_vchk)
	or	a
	jr	z, skp_outm
	ld	a, (opc_cd)
	cp	68
	jr	z, skp_outm
	cp	69
	jr	z, dmp_db
	cp	70
	jr	z, dmp_dw

	ld	a, ' '
	ld	c, BUFLEN-2	; clear
	ld	hl, line_buf	; disassemble string buffer
cout_sp1:
	ld	(hl), a
	inc	hl
	dec	c
	jr	nz, cout_sp1
	ld	a, CR
	ld	(hl), a
	inc	hl
	xor	a
	ld	(hl), a		; set delimitor
	call	STROUT

	ld	hl, (tasm_adr)	; disassemble address
	ld	de, line_buf	; disassemble string buffer
	push	de
	call	dasm_st
	pop	hl
	call	STROUT		; cousole out result inline assemble
cout_sp2:
	ld	hl, (tasm_adr)	; disassemble address
	call	setbytec
	ld	(tasm_adr), hl	; next address
	jp	next_asm

skp_outm:
	call	lf_out
	jr	cout_sp2

dmp_db:
	call	setdsadr
	call	setbytec
	ld	(deaddr), hl
	jr	prtdmp

dmp_dw:
	call	setdsadr
	inc	hl
	inc	hl
	ld	(deaddr), hl
prtdmp:	
	call	dpm
	jr	cout_sp2

setdsadr:
	call	lf_out
	ld	hl, (tasm_adr)
	ld	(dsaddr), hl
	ret

setbytec:
	ld	a, (byte_count)
	ld	c, a
	xor	a
	ld	b, a
	add	hl, bc
	ret

;----------------------------
; analize input data
;----------------------------
cont_asm:
	call	analize_input
	jp	c, asm_err		;error

	if	0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; test patch
	ld	a, LF
	call	CONOUT

	ld	hl, msg1
	call	STROUT
	ld	a, (element_cnt)
	call	HEXOUT2
	call	CRLF

	ld	hl, msg2
	call	STROUT
	ld	a, (byte_count)
	call	HEXOUT2
	call	CRLF

	ld	hl, msg3
	call	STROUT
	ld	a, (opc_cd)
	call	HEXOUT2
	call	CRLF

	ld	hl, msg4
	call	STROUT
	ld	a, (opr1_cd)
	call	HEXOUT2
	call	CRLF

	ld	hl, msg5
	call	STROUT
	ld	a, (opr2_cd)
	call	HEXOUT2
	call	CRLF

	ld	hl, msg6
	call	STROUT
	ld	hl, (opr_num25)
	call	HEXOUT4
	call	CRLF

	ld	hl, msg7
	call	STROUT
	ld	hl, (opr_num35)
	call	HEXOUT4
	call	CRLF

	ld	hl, msg8
	call	STROUT
	ld	a, (opr_num37)
	call	HEXOUT2
	call	CRLF

	ld	hl, msg9
	call	STROUT
	ld	a, (opr_num34)
	call	HEXOUT2
	call	CRLF

	ld	hl, msg10
	call	STROUT
	ld	a, (opr_num36)
	call	HEXOUT2
	call	CRLF

	ld	hl, msg11
	call	STROUT
	ld	a, (opr_num33)
	call	HEXOUT2
	call	CRLF

	jp	next_asm

msg1:	db	"element_cnt ",0	; ds 1
msg2:	db	"byte_count ",0		; ds 1
msg3:	db	"opc_cd ",0		; ds 1
msg4:	db	"opr1_cd ",0		; ds 1
msg5:	db	"opr2_cd ",0		; ds 1
msg6:	db	"opr_num25 ",0		; ds 2
msg7:	db	"opr_num35 ",0		; ds 2
msg8:	db	"opr_num37 ",0		; ds 1
msg9:	db	"opr_num34 ",0		; ds 1
msg10:	db	"opr_num36 ",0		; ds 1
msg11:	db	"opr_num33 ",0		; ds 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; test patch
	endif

; make machine code

	ld	a, (element_cnt)
	cp	1
	jp	z, mk_e1
	cp	2
	jp	z, mk_e2

;333333333333333333333333333333333333333
;
; make machine code,
; element_cnt = 3 (ex. LD SP, HL)
;
;333333333333333333333333333333333333333

el3_um	equ	el3_stbe - el3_stb

mk_e3:	ld	a, (opc_cd)
	ld	bc, el3_um
	ld	hl, el3_stb
	cpir
	jp	nz, asm_err
	
	ld	hl, el3_jtb

jp_each:
	add	hl, bc		; offset : BC = BC * 2
	add	hl, bc		; HL = ent_el2 + offset
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	push	bc
	ret

el3_stb:	db	1			; normal, DD, FD, ED
		db	6, 21 			; normal, DD, FD
		db	22, 25			; normal, DD, FD, ED
		db	43 			; normal
		db	55, 60			; normal, ED
		db	42, 45			; normal
		db	34, 36, 35 		; CB, DD, FD
el3_stbe:	

el3_jtb:	dw	el3_35
		dw	el3_36
		dw	el3_34
		dw	el3_45
		dw	el3_42
		dw	el3_60
		dw	el3_55
		dw	el3_43
		dw	el3_25
		dw	el3_22
		dw	el3_21
		dw	el3_6
		dw	el3_1


;
; SET section
;
; r_hl_nn:	db	1, 4, 6, 7, 9, 10, 12, 28

set_mcb:	db	0C0h, 0C8h, 0D0h, 0D8h, 0E0h, 0E8h, 0F0h, 0F8h
set_xyt:	db	0C6h, 0CEh, 0D6h, 0DEh, 0E6h, 0EEh, 0F6h, 0FEh

el3_35: ; SET  ( CB, DD, FD )

	ld	hl, set_mcb
	ld	(cb_mcw), hl
	ld	hl, set_xyt
	ld	(cb_xyw), hl
	jr	bit_res_set

;
; RES section
;
; r_hl_nn:	db	1, 4, 6, 7, 9, 10, 12, 28

res_mcb:	db	80h, 88h, 90h, 98h, 0A0h, 0A8h, 0B0h, 0B8h
res_xyt:	db	86h, 8Eh, 96h, 9Eh, 0A6h, 0AEh, 0B6h, 0BEh

el3_36: ; RES  ( CB, DD, FD )

	ld	hl, res_mcb
	ld	(cb_mcw), hl
	ld	hl, res_xyt
	ld	(cb_xyw), hl
	jr	bit_res_set

;
; BIT section
;
; r_hl_nn:	db	1, 4, 6, 7, 9, 10, 12, 28

bit_mcbn	equ	bit_mcbe - bit_mcb
bit_mcb:	db	40h, 48h, 50h, 58h, 60h, 68h, 70h, 78h
bit_mcbe:
bit_xyt:	db	46h, 4Eh, 56h, 5Eh, 66h, 6Eh, 76h, 7Eh


el3_34: ; BIT  ( CB, DD, FD )

	ld	hl, bit_mcb
	ld	(cb_mcw), hl
	ld	hl, bit_xyt
	ld	(cb_xyw), hl

bit_res_set:
	ld	a, (opr1_cd)
	cp	25
	jp	nz, asm_err

	ld	hl, (opr_num25)
	ld	a, h
	or	a
	jp	nz, asm_err
	ld	a, l
	cp	8
	jp	nc, asm_err

	; HL : 0 - 7

	ld	a, (opr2_cd)
	cp	33
	jr	z, bit_ixp
	cp	36
	jr	z, bit_ixm
	cp	34
	jr	z, bit_iyp
	cp	37
	jr	z, bit_iym
;
; CB : bit n, [r | (hl)]
;
	ld	bc, (cb_mcw)
	add	hl, bc
	ld	d, (hl)		; get MC base

	ld	a, (opr2_cd)
	ld	hl, r_hl_nn
	ld	bc, bit_mcbn
	cpir
	jp	nz, asm_err

	ld	a, c
	cp	7
	jr	z, el3_341

	ld	a, 6
	sub	c
el3_341:
	add	a, d		; make 2nd MC
	jp	el2_130

	; HL : 0 - 7

bit_ixp:
	ld	a, (opr_num33)
bit_ixp1:
	ld	e, a
	ld	d, 0DDh

; adjust I/F
; d: 1st MC, a: 2nd MC, c: 3rd MC, e: 4th MC

el3_342:
	ld	bc, (cb_xyw)
	add	hl, bc
	ld	c, e		; adjust I/F
	ld	e, (hl)		; 4th MC
	ld	a, 0CBh
	jp	mc_end41	; save 4byte MC

bit_ixm:
	ld	a, (opr_num36)
	jr	bit_ixp1


bit_iyp:
	ld	a, (opr_num34)
bit_iyp1:
	ld	e, a
	ld	d, 0FDh
	jr	el3_342

bit_iym:
	ld	a, (opr_num37)
	jr	bit_iyp1

;
; CALL section
; ret_no:	db	6, 18, 19, 20, 21, 22, 23, 24
;
call_mc1t:	db	0ECh, 0E4h, 0F4h, 0D4h, 0C4h, 0FCh, 0CCh, 0DCh

el3_45: ; CALL ( normal )

	ld	de, call_mc1t
	jr	el3_421
;
; JP section
; ret_no:	db	6, 18, 19, 20, 21, 22, 23, 24
;
jp_mc1tm	equ	jp_mc1te - jp_mc1t
jp_mc1t:	db	0EAh, 0E2h, 0F2h, 0D2h, 0C2h, 0FAh, 0CAh, 0DAh
jp_mc1te:

el3_42: ; JP   ( normal )

	ld	de, jp_mc1t

el3_421:
	ld	hl, ret_no
	ld	bc, jp_mc1tm
	ld	a, (opr1_cd)
	cpir
	jp	nz, asm_err

	ld	a, (opr2_cd)
	cp	25
	jp	nz, asm_err

	ld	h, d		; DE : MC target table
	ld	l, e		; DE : MC target table
	add	hl, bc
	ld	a, (hl)		; get 1st MC
	jp	el2_451

;
; OUT section
;
in_selm		equ	ld_e2_tbl1 - in_selt

el3_60: ; OUT  ( normal, ED )

	ld	de, 41D3H
	ld	bc, (opr1_cd)	; c = (opr1_cd), b = (opr2_cd)
	jr	el3_550

;
; IN section
;
el3_55: ; IN   ( normal, ED )

	ld	de, 40DBH
	ld	a, (opr1_cd)
	ld	b, a
	ld	a, (opr2_cd)
	ld	c, a

el3_550:
	ld	a, c
	cp	35
	jr	z, in_a_nn
	cp	31
	jp	nz, asm_err

	ld	a, b
	cp	1
	jr	z, el3_551	; passing search
	
	ld	hl, in_selt
	ld	bc, in_selm
	call	mkmc_sh
	jp	c, asm_err
	ld	a, d
	jr	el3_552
	
el3_551:
	ld	a, d
	add	a, 38h		; get 2nd MC
el3_552:
	jp	el2_5411

in_a_nn:
	ld	hl, (opr_num35)
	ld	a, h
	or	a
	jp	nz, illnum_err
	ld	a, l
	push	af		; adjust I/F
	ld	a, e		; 1st MC
	jr	el3_431		; save 2byte MC (el2_441)
	
;
; JR section
;
jr_cct:	db	20, 18, 21, 6

el3_43: ; JR   ( normal )

	ld	hl, jr_cct
	ld	bc, 4
	ld	d, 20h		; base MC
	ld	a, (opr1_cd)
	call	mkmc_sh
	jp	c, asm_err

	ld	a, (opr2_cd)
	cp	25		; number?
	jp	nz, illnum_err

	call	calc_reladr
	jp	c, illnum_err
	
	push	af		; adjust I/F
	ld	a, d		; adjust I/F
el3_431:
	jp	el2_441		; save 2byte MC
;
; hl : search table
; bc : loop counter
; d  : base MC 
;
; output:
;	  CF=1 : error
;	  CF=0 : D = MC
mkmc_sh:
	cpi
	jr	z, mkmc_shed
	
	ld	e, a	; save a
	ld	a, d
	add	a, 8
	ld	d, a

	ld	a, c
	or	b
	ld	a, e	; restore a
	jr	nz, mkmc_sh
	scf
	ret

mkmc_shed:
	ret

;
; ADC section
;

el3_25: ; SBC  ( normal, DD, FD, ED )

	ld	de, 429fh
	ld	a, 0DEh
	ex	af, af'
	jr	el3_221
;
; ADC section
;
; defined other section
; r_hl_nn:	db	1, 4, 6, 7, 9, 10, 12, 28
; ld_rr_:	db	25
; ex_sr_:	db	33, 36, 34, 37
; r_hl_nne:

adc_MC	equ	ex_sr_ - r_hl_nn
adc_3MC	equ	r_hl_nne - ex_sr_

el3_22: ; ADC  ( normal, DD, FD, ED )

	ld	de, 4a8fh
	ld	a, 0CEh
	ex	af, af'

el3_221:
	ld	a, (opr1_cd)
	cp	1		; A?
	jr	z, adc_a_
	cp	11		; HL?
	jp	nz, asm_err

; adc hl,[ BC | DE | HL | SP ]

	ld	a, (opr2_cd)
	cp	5
	jr	z, adc_hl_bc
	cp	8
	jr	z, adc_hl_de
	cp	11
	jr	z, adc_hl_hl
	cp	16
	jp	nz, asm_err

adc_hl_sp:
	ld	a, 30h
	jr	adc_hl_
adc_hl_hl:
	ld	a, 20h
	jr	adc_hl_
adc_hl_de:
	ld	a, 10h
	jr	adc_hl_
adc_hl_bc:
	xor	a
adc_hl_:
	add	a, d		; make 2nd MC

	jp	el2_5411

adc_a_:
	ld	a, (opr2_cd)
	ld	hl, r_hl_nn
	ld	bc, adc_MC
	cpir
	jr	nz, chk_adc3mc

	ld	a, c
	cp	8
	jr	z, adc_a_a
	or	a
	jr	z, adc_a_n
	ld	a, e
	sub	c		; make MC 1
adc_a_x:
	jp	st_mc11
	
adc_a_n:
	ld	hl, (opr_num25)
	ex	af, af'		; get 1st MC
	ld	d, a		; adjust I/F
	jp	ld_r251

adc_a_a:
;	inc	e
	ld	a, e
	jr	adc_a_x

chk_adc3mc:
	ld	hl, ex_sr_
	ld	bc, adc_3MC
	cpir
	jp	nz, asm_err

	ld	hl, opr_num37
	add	hl, bc
	ld	d, (hl)		; 3rd MC

	ld	a, c
	ld	c, 0FDH		; 1st MC
	cp	2
	jr	c, adc_fd

	ld	c, 0DDH		; 1st MC

adc_fd:
	dec	e		; get 2nd MC
	jp	ld_bc_n42	; save 3MC
;
; ADD section
;
el3_21: ; ADD  ( normal, DD, FD )

	ld	de, 0987h
	ld	a, 0C6h
	ex	af, af'

	ld	a, (opr2_cd)
	ld	b, a
	ld	a, (opr1_cd)
	cp	1
	jr	z, adc_a_
	cp	11
	jr	z, add_hl_
	cp	14
	jr	z, add_ix_
	cp	15
	jp	nz, asm_err
;;
;;
add_iy_:
	ld	c, 0FDh
	jr	el3_211
;;
;;
add_ix_:
	ld	c, 0DDh
el3_211:
	ld	a, b
	cp	5
	jr	z, add_xy_bc
	cp	8
	jr	z, add_xy_de
	cp	14
	jr	z, add_ix_ix
	cp	15
	jp	z, add_iy_iy
	cp	16
	jp	nz, asm_err
add_xy_sp:
	ld	a, 39h
el3_212:
	push	af		; adjust I/F
	ld	a, c
	jp	el2_441

add_xy_bc:
	ld	a, 9h
	jr	el3_212
add_xy_de:
	ld	a, 19h
	jr	el3_212
add_ix_ix:
	ld	a, c
	cp	0ddh
	jp	nz, asm_err
add_xy_xy:
	ld	a, 29h
	jr	el3_212
add_iy_iy:
	ld	a, c
	cp	0fdh
	jp	nz, asm_err
	jr	add_xy_xy

;;
;;
add_hl_:
	ld	a, b
	cp	5
	jr	z, add_hl_bc
	cp	8
	jr	z, add_hl_de
	cp	11
	jr	z, add_hl_hl
	cp	16
	jp	nz, asm_err
add_hl_sp:
	ld	a, 39h
	jp	adc_a_x
add_hl_bc:
	ld	a, 09h
	jp	adc_a_x
add_hl_de:
	ld	a, 19h
	jp	adc_a_x
add_hl_hl:
	ld	a, 29h
	jp	adc_a_x

;
; EX section
;

el3_6:  ; EX   ( normal, DD, FD )

	ld	a, (opr2_cd)
	ld	b, a
	ld	a, (opr1_cd)
	cp	2
	jr	z, ex_af_
	cp	8
	jr	z, ex_de_
	cp	32
	jp	nz, asm_err

; ex (sp),
	ld	a, b
	ld	e, 0E3h

	cp	11		; hl
	jr	z, ex_sp_hl
	cp	14
	ld	d, 0ddh
	jr	z, ex_sp_ix
	cp	15
	jp	nz, asm_err
	ld	d, 0fdh
ex_sp_ix:
	ld	a, e
	push	af		; adjust I/F
	ld	a, d
	jp	el2_441

ex_sp_hl:
	ld	a, e
	jr	el3_61

ex_af_:
	ld	a, b
	cp	3
	jp	nz, asm_err
	ld	a, 08h		; 1st MC
	jr	el3_61

ex_de_:
	ld	a, b
	cp	11		; hl
	jp	nz, asm_err
	ld	a, 0ebh		; 1st MC
el3_61:
	jp	st_mc11

;
; LD section
;

; ld_en1 = 7 (1, 4, 6, 7, 9, 10, 12)
; ld_en2 = 5 (5, 8, 11, 14, 15)
; ld_en3 = 4 (33, 36, 34, 37 )
; ld_en4 =  7 (13, 16, 17, 26, 27, 28, 35)
ld_en1		equ	ld_e2_tbl1 - ld_e2_tbl
ld_en2		equ	ld_e2_tbl2 - ld_e2_tbl1
ld_en3		equ	ld_e2_tbl3 - ld_e2_tbl2
ld_en4		equ	ld_e2_tble - ld_e2_tbl3

ld_e2_tbl:	db	1
in_selt:	db	4, 6, 7, 9, 10, 12
ld_e2_tbl1:	db	5, 8, 11, 14, 15
ld_e2_tbl2:	db	33, 36, 34, 37
ld_e2_tbl3:	db	13
		db	16
		db	17
		db	26
		db	27
		db	28
		db	35
ld_e2_tble:

rhlnnxy		equ	r_hl_nne - r_hl_nn
ld_rrn		equ	ld_rr_ -  r_hl_nn
ld_rxyn_sp	equ	lda_spe - ld_rr_

m_num		equ	r_hl_nne - ld_rr_	; except No.0 - 4  (IX+,IY+,IX-,IY-,nn)

r_hl_nn:	db	1, 4, 6, 7, 9, 10, 12, 28
ld_rr_:		db	25
ex_sr_:		db	33, 36, 34, 37
r_hl_nne:
lda_sp:		db	26 ; LD A (BC)
		db	27 ; LD A (DE)
		db	13 ; LD A I
		db	17 ; LD A R
		db	35 ; LD A (1234H)
lda_spe:

ld1_base:	db	68h	; L
		db	60h	; H
		db	58h	; E
		db	50h	; D
		db	48h	; C
		db	40h	; B
		db	78h	; A

ld_r_jt:	dw	ld_r35 ; LD A (1234H)
		dw	ld_r17 ; LD A R
		dw	ld_r13 ; LD A I
		dw	ld_r27 ; LD A (DE)
		dw	ld_r26 ; LD A (BC)
		dw	ld_r37
		dw	ld_r34
		dw	ld_r36
		dw	ld_r33
		dw	ld_r25

; LD XXXX, XXXX
el3_1:
	ld	a, (opr1_cd)
	ld	hl, ld_e2_tbl
	ld	bc, ld_en1
	cpir
	jp	nz, el3_11
	
	ld	hl, ld1_base
	add	hl, bc
	ld	d, (hl)		; met MC base code

	ld	a, (opr2_cd)
	ld	hl, r_hl_nn
	ld	bc, ld_rrn
	cpir
	jr	nz, el3_125
	
	ld	a, c
	cp	7		; A param?
	jr	z, el3_12
	ld	a, 6
	sub	c		; make B, C, D, E, H, L, (HL) param
el3_12:
	or	d		; make MC
	jp	st_mc11	


el3_125:
	ld	hl, ld_rr_
	ld	bc, ld_rxyn_sp
	cpir
	jp	nz, asm_err

	ld	a, c
	cp	5		; check LD A, special
	jr	nc, el3_126

	ld	a, d
	cp	78h		; LD A ?
	jp	nz, asm_err	; err, if B, C, D, E, H, L, (HL)

el3_126:
	ld	hl, ld_r_jt
	jp	jp_each

ld_r35: ; LD A,(1234H)
	ld	a, 3ah		; 1st MC

	ld	hl, (tasm_adr)
	ld	(hl), a
	inc	hl
	ld	de, (opr_num35)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	jp	mc_end3

ld_r17: ; LD A,R
	ld	a, 5fh
ld_r171:
	jp	el2_5411
	
ld_r13: ; LD A,I
	ld	a, 57h
	jr	ld_r171

ld_r27: ; LD A,(DE)
	ld	a, 1ah
	jp	st_mc11
	
ld_r26: ; LD A,(BC)
	ld	a, 0ah
	jp	st_mc11

ld_r37:	; LD r,(IY-nn)
	ld	a, (opr_num37)
ld_r371:
	ld	c, a
	ld	e, 0FDH
ld_r372:
	ld	a, 6
	or	d		; make 2nd MC
	ld	d, a		; adjust I/F
	ld	a, e		; adjust I/F
	jp	cp_xy1

ld_r34: ; LD r,(IY+nn)
	ld	a, (opr_num34)
	jr	ld_r371

ld_r36: ; LD r,(IX-nn)
	ld	a, (opr_num36)
ld_r361:
	ld	c, a
	ld	e, 0DDH
	jr	ld_r372

ld_r33: ; LD r,(IX+nn)
	ld	a, (opr_num33)
	jr	ld_r361

ld_r25: ; LD r, nn
	ld	a, d		; get 1st MC base
	sub	3ah		; get 1st MC
	ld	d, a

ld_r251:
	ld	hl, (opr_num25)
	ld	a, h
	or	a
	jp	nz, illnum_err
	ld	a, l
	push	af		; adjust I/F
	ld	a, d		; adjust I/F
	jp	el2_441

;
; LD rp16, nnnn
; LD rp16, (nnnn)
; rp16 : BC, DE, HL, IX, IY
; ld_e2_tbl1:	db	5, 8, 11, 14, 15

el3_11:
;	hl = ld_e2_tbl1
	ld	bc, ld_en2
	cpir
	jr	nz, el3_1_2
	ld	a, c
	or	a
	jr	z, ld_iy_n4
	cp	1
	jr	z, ld_ix_n4
	cp	2
	jr	z, ld_hl_n4
	cp	3
	jr	z, ld_de_n4


; LD BC, nnnn; LD BC, (nnnn)
ld_bc_n4:
	ld	d, 0EDH		; 1st MC
	ld	e, 4bh		; 2nd MC
	ld	c, 1		; 1st MC

ld_bc_n40:
	ld	a, (opr2_cd)
	cp	25
	jr	z, ld_bc_n41

	ld	a, e		; 2nd MC
	ld	hl, opr_num35
	ld	c, (hl)		; 3rd MC
	inc	hl
	ld	e, (hl)		; 4th MC
	jp	mc_end41

ld_bc_n41:
	ld	hl, opr_num25
	ld	e, (hl)		; 2rd MC
	inc	hl
	ld	d, (hl)		; 3rd MC
	ld	a, c		; 1st MC

ld_bc_n42:
	ld	hl, (tasm_adr)
	ld	(hl), c		; save 1st MC
	inc	hl
	ld	(hl), e
	inc	hl
	ld	(hl), d
	jp	mc_end3
	
; LD DE, nnnn; LD DE, (nnnn)
ld_de_n4:
	ld	d, 0EDH		; 1st MC
	ld	e, 5bh		; 2nd MC
	ld	c, 11h		; 1st MC
	jr	ld_bc_n40

; LD HL, nnnn; LD HL, (nnnn)
ld_hl_n4:
	ld	c, 21h
	ld	de, (opr_num25)
	ld	a, (opr2_cd)
	cp	25
	jr	z, ld_bc_n42
	ld	c, 2Ah
	ld	de, (opr_num35)
	jr	ld_bc_n42

; LD IX, nnnn; LD IX, (nnnn)
ld_ix_n4:
	ld	d, 0DDh		; 1st MC

ld_ix_n40:
	ld	c, 21h
	ld	hl, opr_num25

	ld	a, (opr2_cd)
	cp	25
	jr	z, ld_ix_n42

	ld	c, 2Ah
	ld	hl, opr_num35

ld_ix_n42:
	ld	a, c		; 2nd MC
	ld	c, (hl)		; 3rd MC
	inc	hl
	ld	e, (hl)		; 4th MC
	jp	mc_end41

; LD IY, nnnn; LD IY, (nnnn)
ld_iy_n4:
	ld	d, 0FDh		; 1st MC
	jr	ld_ix_n40

;
; LD ([IX|IY][+|-]nn), [r|nn]
;
;ld_e2_tbl2:	db	33, 36, 34, 37
; LD (IX | IY +|- nn), r | nn
el3_1_2:
;	hl = ld_e2_tbl2
	ld	bc, ld_en3
	cpir
	jr	nz, el3_13
	
	ld	hl, opr_num37
	add	hl, bc
	ld	d, (hl)		; get 3rd MC

	ld	a, c
	ld	e, 0FDh		; 1st MC
	cp	2
	jr	c, el3_121
	ld	e, 0DDh		; 1st MC

; reg_A = (opr2_cd)
; if (reg_A = 25) 2nd_MC = 36h
; else {
;     if (Reg_C = 6) 2nd_MC =77h
;     else 2nd_MC = 75h - reg_C
; }
el3_121: ; check element No.3
	ld	a, (opr2_cd)
	cp	25
	jr	z, ld_xynln

	ld	hl, ld_e2_tbl
	ld	bc, ld_en1
	cpir
	jp	nz, asm_err

	ld	a, c
	cp	6
	ld	a, 077h		; a : 2nd MC
	jr	z, mc2_77

	ld	a, 75h
	sub	c	; a : 2nd MC

 ; adjust 1: c, 2: e, 3: d
mc2_77:
	ld	c, e		; adjust I/F
	ld	e, a		; adjust I/F
	jp	ld_bc_n42

ld_xynln: ; 4byte MC 
	  ; LD ([IX|IY] [+|-]), nn
	  ; 2nd MC = 36h

	ld	hl, (opr_num25)
	ld	a, h
	or	a
	jp	nz, illnum_err

; adjust I/F
; d: 1st MC, a: 2nd MC, c: 3rd MC, e: 4th MC

	ld	a, 36h		; 2nd MC
	ld	c, d		; 3rd MC
	ld	d, e		; 1st MC
	ld	e, l		; 4th MC
	jp	mc_end41

;
; 35 : ld (nnnn), reg
; 28 : ld (hl), r | nn
; 16 : ld SP, hl | ix | iy | nnnn | (nnnn)
; 27 : LD (DE), A
; 26 : LD (BC), A
; 17 : LD R, A
; 13 : LD I, A
;
el3_13:
;	hl = ld_e2_tbl3
	ld	bc, ld_en4
	cpir
	jp	nz, asm_err
	ld	hl, el3_14
	jp	jp_each

; jump table
el3_14:		dw	el3_s35
		dw	el3_s28
		dw	el3_s27
		dw	el3_s26
		dw	el3_s17
		dw	el3_s16
		dw	el3_s13

ldnr_n	equ	ldnr_c - ldnr_t

ldnr_t:		db	1, 11, 5, 8, 16, 14, 15
ldnr_c:		db	22h, 22h, 73h, 53h, 43h, 22h, 32h

el3_s35: ; ld (nnnn), reg

	ld	a, (opr2_cd)

	ld	hl, ldnr_t
	ld	bc, ldnr_n
	cpir
	jp	nz, asm_err

	ld	hl, ldnr_c
	add	hl, bc
	ld	a, c
	ld	c, (hl)		; 1st MC

	ld	hl, (opr_num35)
	cp	5
	jr	c, el3_s351

 ; adjust 1: c, 2: e, 3: d

	ld	e, l			; 2nd MC
	ld	d, h			; 3rd MC
	jp	ld_bc_n42

el3_s351:
	cp	2
	jr	c, el3_s352
 ; ED
; d: 1st MC, a: 2nd MC, c: 3rd MC, e: 4th MC

	ld	d, 0EDH			; 1st MC
el3_s353:
	ld	a, c			; 2nd MC
	ld	c, l			; 3rd MC
	ld	e, h			; 4th mc
	jp	mc_end41

el3_s352: ; DD, FD
	ld	d, 0FDh			; 1st MC
	or	a
	jr	z, el3_s353
	ld	d, 0DDh			; 1st MC
	jr	el3_s353

; ld (hl), r | nn
el3_s28:
	ld	a, (opr2_cd)
	cp	25
	jr	z, el3_s281
	cp	1
	jr	z, el3_s282
	ld	hl, ld_e2_tbl + 1
	ld	bc, ld_en1 - 1
	cpir
	jp	nz, asm_err
	ld	a, 75h
	sub	c
el3_s283:
	jp	st_mc11

el3_s282: ; LD (HL), A
	ld	a, 77h
	jr	el3_s283

el3_s281: ; LD (HL), nn
	ld	hl, (opr_num25)
	ld	a, h
	or	a
	jp	nz, illnum_err

	ld	a, l
	push	af		; adjust I/F
	ld	a, 36h		; 1st MC
	jp	el2_441

el3_s16: ; ld SP, hl | ix | iy | nnnn | (nnnn)

	ld	a, (opr2_cd)
	cp	11
	jr	z, el3_s161
	cp	14
	jr	z, el3_s162
	cp	15
	jr	z, el3_s163
	cp	25
	jr	z, el3_s164
	cp	35
	jp	nz, asm_err

; LD SP, (nnnn)
; d: 1st MC, a: 2nd MC, c: 3rd MC, e: 4th MC

	ld	d, 0edh		; 1st MC
	ld	a, 7bh		; 2nd MC
	ld	hl, (opr_num35)
	ld	c, l		; 3rd MC
	ld	e, h		; 4th MC
	jp	mc_end41
	

el3_s161: ; LD SP, HL
	ld	a, 0f9h
	jr	el3_s261

el3_s162: ; LD SP, IX
	ld	d, 0DDh
	jr	el3_s1631
	
el3_s163: ; LD SP, IY
	ld	d, 0FDh
el3_s1631:
	ld	a, 0f9h
	push	af		; adjust I/F
	ld	a, d
	jp	el2_441

el3_s164: ; LD SP, nnnn
; adjust 1: c, 2: e, 3: d

	ld	c, 31h		; 1st MC
	ld	de, (opr_num25)	; e: 2nd MC, d: 3rd MC
	jp	ld_bc_n42

el3_s27: ; LD (DE), A
	ld	a, 12h		; set MC
	jr	el3_s261
	
el3_s26: ; LD (BC), A
	ld	a, 2h		; set MC
el3_s261:
	jp	st_mc11
	
el3_s17: ; LD R, A
	ld	a, 4fh		; set 2nd MC
	jp	el2_5411

el3_s13: ; LD I, A
	ld	a, 47h		; set 2nd MC
	jp	el2_5411

;1111111111111111111111111111111111
;
; element count = 1 
;
;1111111111111111111111111111111111

e1s	equ	e1_e - e1_s
e1s1	equ	e1_e1 - e1_s1

e1_s: ;------------------------------------------------
elem1_cd:	db	7, 10, 11, 14, 15, 30, 32
		db	33, 46, 50, 51, 52, 53, 65
e1_e: ;------------------------------------------------

elem1_opcd:	db	27H, 0FBH, 0F3H, 76H, 00H, 0C9H, 37H
		db	3FH, 2FH, 1FH, 0FH, 17H, 07H, 0D9H

e1_s1: ; ----------------------------------------------
elem1_cd1:	db	39, 40, 37, 38, 58, 59, 56
		db	57, 4,  5,  2,  3,  31, 64
		db	62, 63, 61, 47, 48, 66, 67
e1_e1: ; ----------------------------------------------

elem1_opcd1:	db	 67h,  6Fh,  45h,  4Dh, 0A3h, 0ABh, 0B3h
		db	0BBh,  44h, 0B0h, 0A0h, 0B8h, 0A8h, 0B2h
		db	0A2h, 0BAh, 0AAh, 0B1h, 0A1h, 0B9h, 0A9h

;
; make machine code,
; element_cnt = 1 (ex. NOP)
; output : 1 byte Machine code
;
mk_e1:	; 1byte MC
	ld	a, (opc_cd)
	ld	bc, e1s
	ld	hl, elem1_cd
	cpir
	jp	nz, mk_e11
	
	ld	hl, elem1_opcd

st_mc1:
	add	hl, bc
	; get MC
	ld	a, (hl)
st_mc11:
	ld	hl, (tasm_adr)
	ld	(hl), a
	ld	a, 1

mc_end:
	ld	(byte_count), a	; set MC bytes
	jp	cout_sp

mk_e11: ; 2byte MC (0EDh, XX)
	ld	bc, e1s1
	ld	hl, elem1_cd1
	cpir
	jp	nz, asm_err
	
	ld	hl, (tasm_adr)
	ld	a, 0EDH
	ld	(hl), a		; set MC No.1
	inc	hl
	ex	de, hl

	ld	hl, elem1_opcd1
	add	hl, bc
	; get MC
	ld	a, (hl)
	ld	(de), a		; set MC No.2

mc_end2:
	ld	a, 2
	jr	mc_end

;2222222222222222222222222222222222222222222222
;
; element count = 2 
;
;2222222222222222222222222222222222222222222222

e2s	equ	e2_e - e2_s

e2_s:
elem2_cd:
	db	8, 9			; DD, FD
	db	23, 26			; DD, FD
	db	24, 27, 28 ,29, 41	; DD, FD
	db	42			; DD, FD
	db	46
	db	49
	db	43
	db	44
	db	45
; CB
	db	12			; DD, FD
	db	16			; DD, FD
	db	13			; DD, FD
	db	17			; DD, FD
	db	18			; DD, FD
	db	19			; DD, FD
	db	20			; DD, FD
; ED
	db	54			; ED
	db	68			; ORG
	db	69			; DB
	db	70			; DW
e2_e:

ent_el2:
	dw	el2_70		; DW
	dw	el2_69		; DB
	dw	el2_68		; ORG
	dw	el2_54		; IM
	dw	el2_20		; SRL
	dw	el2_19		; SRA
	dw	el2_18		; SLA
	dw	el2_17		; RR
	dw	el2_13		; RL
	dw	el2_16		; RRC
	dw	el2_12		; RLC

	dw	el2_45		; CALL nnnn
	dw	el2_44		; DJNZ e
	dw	el2_43		; jR e
	dw	el2_49		; RST nn
	dw	el2_46		; RET CC
	dw	el2_42		; JP (HL), JP nnnn

; code base 0a0h, or 00h, 08h, 10h, 18h
	dw	el2_41		; CP
	dw	el2_29		; XOR
	dw	el2_28		; OR
	dw	el2_27		; AND

	dw	el2_24		; SUB

	dw	el2_26		; DEC
	dw	el2_23		; INC

	dw	el2_9		; POP
	dw	el2_8		; PUSH

;
; make machine code,
; element_cnt = 2 (ex. PUSH AF)
; output : 1 to 3 bytes Machine code
;

mk_e2:
	ld	a, (opc_cd)
	ld	bc, e2s
	ld	hl, elem2_cd
	cpir
	jp	nz, asm_err
	
	ld	hl, ent_el2
	jp	jp_each

el2_70: ; DW
	ld	a, (opr1_cd)
	cp	25
	jp	nz, asm_err

	ld	hl, (tasm_adr)
	ld	bc, (opr_num25)
	ld	(hl), c
	inc	hl
	ld	(hl), b
	jp	mc_end2

el2_69: ; DB
	ld	a, (opr1_cd)
	cp	25
	jr	z, el2_691
	cp	38
	jp	nz, asm_err
	
	ld	hl, (opr_num25)

	xor	a
	ld	c, a
	ld	de, (tasm_adr)

el2_692:
	ld	a, (hl)
	cp	'"'
	jr	z, cpstrend
	or	a
	jr	z, cpstrend

	ld	(de), a
	inc	hl
	inc	de
	inc	c
	jr	el2_692

cpstrend:
	ld	a, c
	jp	mc_end

el2_691:
	ld	bc, (opr_num25)
	ld	a, b
	or	a
	jp	nz, illnum_err

	ld	hl, (tasm_adr)
	ld	(hl), c
	ld	a, 1
	jp	mc_end

el2_68: ; ORG
	ld	a, (opr1_cd)
	cp	25
	jp	nz, asm_err

	xor	a
	ld	hl, (opr_num25)
	ld	bc, RAM_B
	sbc	hl, bc
	jr	c, ramerr

	ld	bc, RAM_B + RAM_SIZ
	ld	hl, (opr_num25)
	sbc	hl, bc
	jr	c, okram

ramerr:
	ld	hl, ramerr_msg
	jp	asm_err1

okram:
	ld	hl, (opr_num25)
	ld	(tasm_adr), hl
	xor	a
	jp	mc_end

ramerr_msg:
	db	"No RAM ", 0
	
; CALL nnnn
el2_45:
	ld	a, (opr1_cd)
	cp	25
	jr	nz, illnum_err

	ld	a, 0CDH

el2_451:
	ld	hl, (tasm_adr)
	ld	(hl), a		; save op_code
	inc	hl
	ld	de, (opr_num25)
	ld	(hl), e
	inc	hl
	ld	(hl), d

mc_end3:
	ld	a, 3
	jp	mc_end

; DJNZ relative number
el2_44:
	ld	a, (opr1_cd)
	cp	25
	jr	nz, illnum_err

	call	calc_reladr
	jr	c, ovr_err
	push	af
	ld	a, 10H
el2_441:
	ld	hl, (tasm_adr)
	ld	(hl), a		; save op_code
	inc	hl
	pop	af
	ld	(hl), a
	jp	mc_end2

ovr_err:
	ld	hl, ovr_msg
	jp	asm_err1

ovr_msg:
	db	"Over. ", 0

; JR e
el2_43:
	ld	a, (opr1_cd)
	cp	25
	jr	nz, illnum_err
	call	calc_reladr
	jr	c, ovr_err
	push	af
	ld	a, 18H
	jr	el2_441

; RST
el2_49:
	ld	hl, (opr_num25)
	ld	a, h
	or	a
	jr	nz, illnum_err
	ld	a, l
	ld	hl, rst_no
	ld	bc, 8
	cpir
	jr	nz, illnum_err

	ld	hl, rst_cd
	jp	st_mc1		; get and store MC code

illnum_err:
	ld	hl, ill_num
	jp	asm_err1

rst_no:	db	0, 8, 10H, 18H, 20H, 28H, 30H, 38H
rst_cd:	db	0FFH, 0F7H, 0EFH, 0E7H, 0DFH, 0D7H, 0CFH, 0C7H

ill_num:	db	"Ill-No. ", 0

; RET CC
el2_46:
	ld	a, (opr1_cd)	; get code number of operand No.1
	ld	hl, ret_no
	ld	bc, 8
	cpir
	jr	nz, opr_err

	ld	hl, ret_cd
	jp	st_mc1		; get and store MC code

opr_err:
	ld	hl, opr_errm
	jp	asm_err1

ret_no:	db	6, 18, 19, 20, 21, 22, 23, 24
ret_cd:	db	0E8H, 0E0H, 0F0H, 0D0H, 0C0H, 0F8H, 0C8H, 0D8H

opr_errm:	db	"Operand ", 0

; JP (HL), JP nnnn, JP (IX), JP (IY)
el2_42:
	ld	a, (opr1_cd)	; get code number of operand No.1
	cp	25
	jr	z, jpnnnn	; JP nnnn
	ld	l, 0E9H
	cp	28		; (HL)?
	jr	z, jphl
	cp	29		; (IX)?
	jr	z, jpix
	cp	30		; (IY)?
	jr	nz, opr_err

; JP (IY)
	ld	a, l
	push	af
	ld	a, 0FDH
	jp	el2_441

; JP (IX)
jpix:
	ld	a, l
	push	af
	ld	a, 0DDH
	jp	el2_441

; JP (HL)
jphl:
	ld	a, l
	jp	st_mc11		; set JP (HL) MC code

; JP nnnn
jpnnnn:
	ld	a, 0c3h
	jp	el2_451		; save OP and jmp address

;
; CP, XOR, OR, AND, SUB section
;
; (defined already)
;rhlnnxy	equ	r_hl_nne - r_hl_nn
;m_num		equ	5	; except No.0 - 4  (IX+,IY+,IX-,IY-,nnnn)
;r_hl_nn:	db	1, 4, 6, 7, 9, 10, 12, 28
;		db	25
;ex_sr_:	db	33, 36, 34, 37
;r_hl_nne:
;
base1:		db	06H, 06H, 06H, 06H, 46h
		db	06H, 05H, 04H, 03H, 02H, 01H, 00H, 07H

el2_41: ; CP
	ld	d, 0b8h
	jr	and_cp

el2_29: ; XOR
	ld	d, 0a8h
	jr	and_cp

el2_28: ; OR
	ld	d, 0b0h
	jr	and_cp

el2_27: ; AND
	ld	d, 0a0h
	jr	and_cp

el2_24: ; SUB
	ld	d, 090h

and_cp:
	ld	a, (opr1_cd)	; get code number of operand No.1
	ld	hl, r_hl_nn
	ld	bc, rhlnnxy
	cpir
	jr	nz, opr_err

	ld	hl, base1
	add	hl, bc
	ld	a, (hl)
	or	a, d		; make code operand1
	ld	d, a		; save operand1
	ld	a, c
	cp	m_num		; check IX+,IY+,IX-,IY-,nnnn
	jp	c, el2_410
	ld	a, d		; restore
	jp	st_mc11
	
; IX+,IY+,IX-,IY-,nnnn
el2_410:
	cp	4 		; cp nn ?
	jr	c, cp_ixiy	; no, IX+,IY+,IX-,IY-

; CP nn
	ld	hl, (opr_num25)
	ld	a, h
	or	a
	jp	nz, illnum_err

	ld	a, l
el2_411:
	push	af		; adjust save I/F
	ld	a, d		; restore cp opecode
	jp	el2_441
	
; CP (IX+nn), CP (IY+nn), CP (IX-nn), CP (IY-nn)

cp_ixiy:
	cp	2
	ld	a, 0FDH
	jr	c, cp_iy
	ld	a, 0DDH
cp_iy:
	ld	hl, opr_num37
	add	hl, bc
	ld	c, (hl)
cp_xy1:	
	ld	hl, (tasm_adr)
	ld	(hl), a		; save op_code
	ld	a, d		; restore 2nd operand
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), c
	jp	mc_end3

;
; DEC, INC section
;

di_nbs		equ	d_i_tbe - d_i_tb
di_ixynum	equ	d_i_tbe - dix_tbl
di_ixnnum	equ	d_i_tbe - dixn_tbl
di_iynnum	equ	d_i_tbe - diyn_tbl

d_i_tb:		db	1, 4, 5, 6, 7, 8
		db	9, 10, 11, 12, 16, 28
dix_tbl:	db	14, 15		; IX, IY
dixn_tbl:	db	33, 36		; IX+nn, IX-nn
diyn_tbl:	db	34, 37		; IY+nn, IY-nn
d_i_tbe:

DEC_opr:	db	35h, 35h	; IY-, IY+
		db	35h, 35h	; IX-, IX+
		db	2bh, 2bh 	; IY, IX
		db	35h, 3Bh, 2Dh, 2Bh, 25h, 1Dh
		db	1Bh, 15h, 0Dh, 0Bh, 05h, 3Dh

INC_opr:	db	34h, 34h	; IY-, IY+
		db	34h, 34h	; IX-, IX+
		db	23h, 23h	; IY,  IX
		db	34h, 33h, 2Ch, 23h, 24h, 1Ch
		db	13h, 14h, 0Ch, 03h, 04h, 3Ch

el2_26: ; DEC
	ld	de, DEC_opr
	jr	el2_di

el2_23: ; INC
	ld	de, INC_opr

el2_di:
	ld	a, (opr1_cd)	; get code number of operand No.1
	ld	hl, d_i_tb
	ld	bc, di_nbs
	cpir
	ld	h, d
	ld	l, e
	jp	nz, opr_err

	ld	a, c
	ld	d, 0FDH		; set IY extended OP
	cp	di_ixynum
	jp	nc, st_mc1	; 1 MC code

	add	hl, bc
	ld	a, (hl)		; get 2nd operand
	ld	e, a		; save
	ld	a, c
	cp	di_ixnnum
	jr	c, di_3mc
	
	; 2 MC. : INC IX, IY, DEC IX, IY
	
	jr	z, di_iy
	ld	d, 0DDH		; set IX extended OP
di_iy:
	ld	a, e		; restoe 2nd operand
	jp	el2_411		; 2 MC (IX, IY)

	; 3 MC. : INC (IX+nn) etc,.
di_3mc:
	cp	di_iynnum	; IY+-nn?
	jr	c, di_3mc1
	ld	d, 0DDH		; set IX extended OP
di_3mc1:
	ld	a, d		; adjust I/F
	ld	d, e		; adjust I/F
	jp	cp_iy		; make 3 MC
	
;
; PUSH, POP section
;

pp_no		equ	pp_tble - pp_tbl
pp_ixiy		equ	pp_tble - pp_ixy

pp_tbl:		db	2, 5, 8, 11
pp_ixy:		db	14, 15
pp_tble:	

pp_base:	db	0E0h, 0E0h ; IY, IX
		db	0E0h, 0D0h, 0C0h, 0f0h

el2_9:  ; POP
	ld	d, 01h		; base code for pop operand
	jr	el2_81

el2_8:  ; PUSH
	ld	d, 05h

el2_81:
	ld	hl, pp_tbl
	ld	bc, pp_no
	ld	a, (opr1_cd)	; get code number of operand No.1
	cpir
	jp	nz, opr_err
	
	ld	hl, pp_base
	add	hl, bc
	ld	a, (hl)
	or	d		; make opecode
	ld	d, a		; save

	ld	a, c
	cp	pp_ixiy
	ld	a, d		; restore
	jp	nc, st_mc11	; 1 MC code

	ld	e, 0FDH		; set IY extended OP
	ld	a, c
	or	a		; IY
	jr	z, el2_82
	ld	e, 0DDH		; set IX code
el2_82:
	ld	a, d
	push	af		; adjust I/F
	ld	a, e		; adjust I/F
	jp	el2_441		; make 2 MC

;
; SRL, SRA, SLA, RR, RL, RRC, RLC section
;


; already defined
; r_hl_nn:	db	1, 4, 6, 7, 9, 10, 12, 28
;		db	25
; ex_sr_:		db	33, 36, 34, 37

sr_num		equ	8
ex_sr_num	equ	ld_en3

;SRL_cd:	db	3Eh, 3Dh, 3Ch, 3Bh, 3Ah, 39h, 38h, 3Fh
;SRA_cd:	db	2Eh, 2Dh, 2Ch, 2Bh, 2Ah, 29h, 28h, 2Fh
;RR_cd:		db	1Eh, 1Dh, 1Ch, 1Bh, 1Ah, 19h, 18h, 1Fh
;RRC_cd:	db	0Eh, 0Dh, 0Ch, 0Bh, 0Ah, 09h, 08h, 0Fh
;SLA_cd:	db	26h, 25h, 24h, 23h, 22h, 21h, 20h, 27h
;RL_cd:		db	16h, 15h, 14h, 13h, 12h, 11h, 10h, 17h
;RLC_cd:	db	06h, 05h, 04h, 03h, 02h, 01h, 00h, 07h
;RLC_cd:	db	06h, 05h, 04h, 03h, 02h, 01h, 00h, 07h

RLC_or	equ	0
RL_or	equ	10h
SLA_or	equ	20h
RRC_or	equ	08h
RR_or	equ	18h
SRA_or	equ	28h
SRL_or	equ	38h

SR_base:	db	06h, 05h, 04h, 03h, 02h, 01h, 00h, 07h



el2_20:	; SRL
	ld	de, (SRL_or << 8) | 3Eh
	jr	sr_lookfor
el2_19:	; SRA
	ld	de, (SRA_or << 8) | 2Eh
	jr	sr_lookfor
el2_18:	; SLA
	ld	de, (SLA_or << 8) | 26h
	jr	sr_lookfor
el2_17:	; RR
	ld	de, (RR_or << 8) | 1Eh
	jr	sr_lookfor
el2_13:	; RL
	ld	de, (RL_or << 8) | 16h
	jr	sr_lookfor
el2_16:	; RRC
	ld	de, (RRC_or << 8) | 0Eh
	jr	sr_lookfor
el2_12:	; RLC
	ld	de, (RLC_or << 8) | 06h

sr_lookfor:
	ld	a, (opr1_cd)	; get code number of operand No.1
	ld	hl, r_hl_nn
	ld	bc, sr_num
	cpir
	jr	nz, nxt_sr

	ld	hl, SR_base
	add	hl, bc
	ld	a, (hl)
	or	d		; make 2nd opcode

el2_130:
	push	af		; adjust I/F
	ld	a, 0cbh		; set OP code
	jp	el2_441

nxt_sr:
	ld	hl, ex_sr_
	ld	bc, ex_sr_num
	cpir
	jp	nz, opr_err

	ld	d, 0FDh		; for IY
	ld	a, c
	cp	2
	jr	c, sr_iy1
	ld	d, 0DDh		; for IX

sr_iy1:	; D: opecode, E : code operand4

	ld	hl, opr_num37
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	ld	a, 0CBH

mc_end41:
	ld	hl, (tasm_adr)
	ld	(hl), d		; save 1st MC
	inc	hl
	ld	(hl), a		; save 2nd MC 
	inc	hl
	ld	(hl), c		; save 3rd MC (8bit litelal)
	inc	hl
	ld	(hl), e		; save 4th MC
mc_end4:
	ld	a, 4
	jp	mc_end

;
; IM section
;
el2_54:	; IM
	ld	a, (opr_num25+1)	; get high byte
	or	a
	jp	nz, illnum_err
	ld	a, (opr_num25)		; get low byte
	cp	3
	jp	nc, illnum_err

	ld	c, 046h		; IM 0
	or	a
	jr	z, el2_541

	ld	c, 056h		; IM 1
	dec	a
	jr	z, el2_541
	ld	c, 05Eh		; IM 2

el2_541:
	ld	a, c

el2_5411:
	push	af		; adjust I/F
	ld	a, 0EDh		; set MC 1
	jp	el2_441

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get opecode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
analize_input:
	call	sch_opecode
	ret	c		; error return
	ld	(opc_cd), a	; save code number of opecode
	call	inc_element

	ld	a, (hl)
	or	a
	ret	z		; no operand
	cp	a, ' '		; check opecode delimiter
	jp	nz, sx_err	; not space then syntax error

	; get code of operand 1

	call	analize_opr
	ret	c		; error
	ld	(opr1_cd), a	; save operand code to opr1
	ex	af, af'
	call	inc_element
	ex	af, af'
	cp	38		; check operand code 38:='"'
	ret	z
	ld	a, (hl)
	or	a
	ret	z		; no operand2
	cp	a, ','		; check opecode delimiter
	jr	nz, sx_err

	; get code of operand 2

	call	analize_opr
	ret	c		; error
	ld	(opr2_cd), a	; save operand code to opr1
	call	inc_element

	ld	a, (hl)
	or	a
	jr	nz, sx_err	; error end
	ret

an_err:
	pop	af
sx_err:
	scf
	ret

inc_element:
	ld	a, (element_cnt)
	inc	a
	ld	(element_cnt), a
	ret

;------------------------
; HL : input buffer
;------------------------
analize_opr:
	inc	hl		; HL : top of operand strings point
	call	sch_operand1
	ret	nc		; match, then retrun
	
	; search (IX+, (IY+, (IX-, (IY-

	call	sch_operand1_1
	jr	c, nxt_a1	; jump, in not match

	; analize "nn)"

	push	af		; save operand code
	call	get_number	; DE : binary
	jp	c, an_err
	
	ld	a, d
	or	a
	jr	nz, an_err	; over 255
	
	ld	a, (hl)
	cp	')'
	jr	nz, an_err

	inc	hl
	pop	af		; restore operand code

	push	af
	cp 	33		; IX+?
	jr	nz, nxt_a2
	ld	bc, opr_num33
	jr	nxt_a21

nxt_a2:
	cp 	34		; IY+?
	jr	nz, nxt_a3
	ld	bc, opr_num34

nxt_a21:
	ld	a, e
	cp	80H
	jr	nc, an_err

nxt_a22:
	ld	(bc),a		; save binary
	pop	af
	ret
	
nxt_a3:
	cp 	36		; IX-?
	jr	nz, nxt_a4
	ld	bc, opr_num36

nxt_a31:
	ld	a, e
	cp	81H
	jr	nc, an_err
	neg
	jr	nxt_a22
	
nxt_a4:	; IY-
	ld	bc, opr_num37
	jr	nxt_a31

; check '('
nxt_a1:
	ld	a, (hl)
	cp	'('
	jr	nz, chk_strings
	
	; get number
	
	inc	hl
	call	get_number
	ret	c		; error number

	ld	a, (hl)
	cp	')'
	jr	nz, sx_err

	inc	hl
	ld	(opr_num35),de	; save binary
	ld	a, 35		; set operand code
	ret			; normal end

chk_strings:
	cp	'"'
	jr	nz, only_num
	inc	hl
	ld	(opr_num25), hl
	ld	a, 38
	ret

only_num:
	call	get_number
	ret	c		; error number
	ld	(opr_num25),de	; save binary
	ld	a, 25		; set operand code
	ret			; normal end

;------------------
; HL : input buffer
;------------------
sch_operand1:
	ld	de, operand_cds
	jr	sh_0

;------------------
; HL : input buffer
; search (IX+, (IY+, (IX-, (IY-
;------------------
sch_operand1_1:
	ld	de, opr_cd1
	jr	sh_0

;----------------------------------------------------------
; Search code number of opecode from input strings
; 
; output:
; if mach opecode ; HL : next point of input strings
;		    A  : a code number of opecode
; not mach	  ; CF = 1
;----------------------------------------------------------
sch_opecode:
	ld	hl, line_buf
	ld	de, ope_cds

sh_0:
	push	hl
sh_1:
	ld	a, (de)
	cp	(hl)
	jr	nz, sch_next
	
	; match
	inc	hl
	inc	de
	jr	sh_1

sch_next:
	and	dm_bit		; delimiter?
	jr	nz, ok_match
	
skip_next:
	inc	de
	ld	a, (de)
	and	dm_bit
	jr	z, skip_next

	; detect delimiter string

	inc	de		; next search strings
	
	ld	a, (de)
	or	a		; tabel end?
	jr	z, n_end	; yes, no match return

	pop	hl
	jr	sh_0		; search again

	; match opecode strings
	; a : opecode number

ok_match:
	ld	a, (de)
	and	a, 7Fh		; mask dm_bit, get code of opecode
	pop	de		; discard top string address
	ret
	
; no opecode strings maching
n_end:
	pop	hl
	scf
	ret

;---------------------
; HL : string buffer
;
; output : de or CF
;----------------------
get_number:

	ld	de, num_string
	ld	c, 0
	
; check first character

	call	dec_chr		; check decimal chrarcter
	ret	c		; no number inputs detect

;  detect 1st number( only 0 to 9 )

	ld	(de), a		; save to buffer
	inc	de
	inc	hl
	inc	c

; check 2nd, 3rd, 4th, 5th number string

lop_gnum:
	call	hex_chr
	jr	c, ck_endmk	; no number inputs detect

; detect 2nd, 3rd, 4th, 5th number (include A to F)

	ld	(de), a		; save to buffer
	inc	de
	inc	hl
	inc	c
	ld	a, c
	cp	NUMLEN		; buffer check
	jr	z, no_num	; overfllow. error return
	jr	lop_gnum

ck_endmk:
	ex	af, af'
	xor	a
	ld	(de), a		; set delimiter
	ex	af, af'
	cp	'H'		; check hex?
	jr	z, bi_hex

;	get binary from decimal string
;bi_dec:
	push	hl
	ld	hl, num_string
	call	GET_dNUM	; return bc
	pop	hl
	ld	d, b		; set binary to DE
	ld	e, c		; set binary to DE
	ret

;	ret	nc		; if CF =1, try hex to bin
;	dec	hl		; adjust hl pointer

	;hex to binary
bi_hex:
	inc	hl
	push	hl
	ld	hl, num_string
	call	RDHEX		; get binary to DE
	pop	hl
	or	a		; clear CF
	ret

;--------------------------
; skip sp
;--------------------------
skp_sp:
	ld	a, (hl)
	cp	' '
	ret	nz
	inc	hl
	jr	skp_sp

;--------------------------
; check decimal char
;--------------------------
dec_chr:
	ld	a, (hl)
	cp	':'
	jr	nc, no_num
	cp	'0'
	ret	nc
	
no_num:	scf
	ret

;--------------------------
; check HEX char
;--------------------------
hex_chr:
	ld	a, (hl)
	cp	'0'
	ret	c	; error return
	cp	'9'+1
	jr	c, dec_num
	cp	'A'
	ret	c	; error return
	cp	'F'+1
	jr	nc, no_num
dec_num:
	or	a	; clear carry
	ret

;--------------------------------------
; 2 byte machine code branch
; - 2nd byte is Relative address
; - output a = (e-2) relative number
;          CF=1 : target address error
;--------------------------------------
calc_reladr:
	push	hl
	push	de

	ld	de, (tasm_adr)	; base address
	inc	de
	inc	de
	ld	hl, (opr_num25)	; target address
	xor	a
	sbc	hl, de
	ld	a, l
	jr	c, cal_1	; CF=1 :target address is lower

	cp	80H
	jr	nc, adr_ovr
	or	a

cal_01:
	pop	de
	pop	hl
	ret

cal_1:
	cp	80H
	jr	cal_01

adr_ovr:
	scf
	jr	cal_01

;-----------------------------
;
; Recorrect input strings
;
;-----------------------------
recorrect:
	push	hl
	push	de
	push	bc

	ld	hl, line_buf
	ld	d, h
	ld	e, l

	ld	c, ' '		; space delimitor. (opecode and operand)
	call	skp_sp
	call	recorr
	or	a
	jr	z, gle_end

	ld	c, 0		; end delimitor. (end strings)
	inc	hl
	call	skp_sp
	or	a
	jr	z, gle_end1
	call	recorr

gle_end1:
	dec	de
	ld	(de), a		; replace space to 0
gle_end:
	pop	bc
	pop	de
	pop	hl
	ret

; extract space from input buffer
recorr:
	ld	b, 0
recorr1:
	ld	(de), a
	inc	de
	or	a
	ret	z
	cp	c
	ret	z

next_char:
	cp	'"'
	jr	nz, nxchr

	ex	af, af'		;'
	ld	a, b
	xor	a, 1
	ld	b, a		; toggle '"' flag
	ex	af, af'		;'
;"	
nxchr:
	inc	hl
	ld	a, (hl)
	cp	c
	jr	z, recorr1
	bit	0, b
	jr	nz, recorr1

	cp	' '
	jr	z, next_char
	jr	recorr1
	

	db	($ & 0FF00H)+100H-$ dup(0FFH)

lasm_end	equ	$


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Work area
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org	WORK_TOP

line_buf:	ds	BUFLEN
dasm_adr:	ds	2
asm_adr:	ds	2
tasm_adr:	ds	2
steps:		ds	2
dsaddr		ds	2
deaddr		ds	2
dstate		ds	1
saddr:		DS	2

element_cnt:	ds	1	; Element count of input string
byte_count:	ds	1	; numbers of Machine code
opc_cd:		ds	1	; opecode number
opr1_cd:	ds	1	; 1st operand number
opr2_cd:	ds	1	; 2nd operand number
opr_num25:	ds	2	; save number nnnn
opr_num35:	ds	2	; save number (nnnn)
opr_num37:	ds	1	; save number (IY-nn)
opr_num34:	ds	1	; save number (IY+nn)
opr_num36:	ds	1	; save number (IX-nn)
opr_num33:	ds	1	; save number (IX+nn)
cb_mcw		ds	2	; use BIT, RES, SET
cb_xyw		ds	2	; use BIT, RES, SET

num_string:	ds	NUMLEN	; max 65536 or 0FFFFH + null
work_s:

mon_vchk:	ds	1
ky_flg		ds	1
work_e:

		ds	40h	; stack area for inline assemble
asm_stack:

	end
