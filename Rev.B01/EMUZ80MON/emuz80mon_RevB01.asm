	page	0
	cpu	z80
;;; 
;;; Universal Monitor for Zilog Z80
;;;   Copyright (C) 2019,2020,2021 Haruo Asano
;;;

;;; 2022.10.1 It was added functions by A.honda
;;; Rev.B01

;;; Constants
CR	EQU	0DH
LF	EQU	0AH
BS	EQU	08H
DEL	EQU	7FH
BUFLEN	equ	32	
F_bitSize	equ	8
;;;
;;; Memory switch
;;;

RAM12K = 1
RAM8K = 0
RAM4K = 0

	IF	RAM12K
;; ROM48K RAM12K for PIC18F47Q84
UARTDR	EQU	0FF00H	; UART DATA REGISTOR
UARTCR	EQU	0FF01H	; UART CONTROL REGISTOR
WORK_B	equ	0EF00H	; work area EF00-EFFF
STACKM	equ	0EF00H	; monitor stack
STACK	equ	0EEC0H	; user stack
ROM_B	equ	0000H	;EMUZ80_Q84 ROM base address
RAM_B	equ	0C000H	;EMUZ80_Q84 RAM base address
RAM_E	equ	0EFFFH	;EMUZ80_Q84 RAM END address
IO_B	equ	0F000H	;EMUZ80_Q84 I/O base address
	ENDIF

	IF	RAM8K
; ORIGINAL MEMORY MAP for PIC18F47Q84
UARTDR	EQU	0E000H	; UART DATA REGISTOR
UARTCR	EQU	0E001H	; UART CONTROL REGISTOR
WORK_B	equ	9F00H	; work area 9F00-9FFF
STACKM	equ	9F00H	; monitor stack
STACK	equ	8EC0H	; user stack
ROM_B	equ	0000H	;EMUZ80_Q84 ROM base address
RAM_B	equ	8000H	;EMUZ80_Q84 RAM base address
RAM_E	equ	9FFFH	;EMUZ80_Q84 RAM END address
IO_B	equ	0E000H	;EMUZ80_Q84 I/O base address
	ENDIF

	IF	RAM4K
; ORIGINAL MEMORY MAP for PIC18F47Q43

UARTDR	EQU	0E000H	; UART DATA REGISTOR
UARTCR	EQU	0E001H	; UART CONTROL REGISTOR
WORK_B	equ	8F00H	; work area 8F00-8FFF
STACKM	equ	8F00H	; monitor stack
STACK	equ	8EC0H	; user stack
ROM_B	equ	0000H	;EMUZ80_Q43 ROM base address
RAM_B	equ	8000H	;EMUZ80_Q43 RAM base address
RAM_E	equ	9FFFH	;EMUZ80_Q43 RAM END address
IO_B	equ	0E000H	;EMUZ80_Q43 I/O base address
	ENDIF

BASIC_TOP	equ	2000H
BASIC_CST	equ	2000H	; basic cold start
BASIC_WST	equ	2003H	; basic warm start

	IF	RAM12K
TIM0_CTL0	equ	0F800H	; timer0 control0 register
TIM0_CTL1	equ	0F801H	; timer0 control1 register
TIMER0_CNTL	equ	0F810H	; timer0 16bit counter LSB
TIMER0_CNTH	equ	0F811H	; timer0 16bit counter MSB
TIMER0_SCTL	equ	0F820H	; timer0 seconds counter LSB
TIMER0_SCTH	equ	0F821H	; timer0 seconds counter MSB
TIMER0_INITC	equ	87e1h	; timer adjust count number
	ENDIF

ENTRY	EQU	0040H		; Entry point

;;; 
;;; ROM area
;;;
start:

	ORG	ROM_B	; (RST 00H)

E_CSTART:
	JP	CSTART

E_WSTART:
	JP	API01

	db	0008H - $ dup(00H)
;	ORG	0008H	; (RST 08H)
	JP	RST08H

	db	0010H - $ dup(00H)
;	ORG	0010H	; (RST 10H)
	JP	RST10H

	db	0018H - $ dup(00H)	; nop
;	ORG	0018H	; (RST 18H)
	JP	RST18H

	db	0020H - $ dup(00H)	; nop
;	ORG	0020H	; (RST 20H)
	JP	RST20H

	db	0028H - $ dup(00H)	; nop
;	ORG	0028H	; (RST 28H)
	JP	RST28H

	db	0030H - $ dup(00H)	; nop
;	ORG	0030H
	JP	RST30H

	db	0038H - $ dup(00H)	; nop
;	ORG	0038H
	JP	RST38H

	;;
	;; Entry point
	;;

	db	ENTRY - $ dup(00H)
	;	ORG	ENTRY
;;;
;;; RST 08H Handler
;;;
RST08H:

	ld	(save_hl), hl	; save hl
	ld	hl, (stealRST08)
	jr	jmp_rst

;;;
;;; RST 10H Handler
;;;
RST10H:

	ld	(save_hl), hl	; save hl
	ld	hl, (stealRST10)
	jr	jmp_rst

;;;
;;; RST 18H Handler
;;;
RST18H:

	ld	(save_hl), hl	; save hl
	ld	hl, (stealRST18)
	jr	jmp_rst

;;;
;;; RST 20H Handler
;;;
RST20H:

	ld	(save_hl), hl	; save hl
	ld	hl, (stealRST20)
	jr	jmp_rst

;;;
;;; RST 28H Handler
;;;
RST28H:

	ld	(save_hl), hl	; save hl
	ld	hl, (stealRST28)
	jr	jmp_rst

;;;
;;; RST 30H Handler
;;;
RST30H:

	ld	(save_hl), hl	; save hl
	ld	hl, (stealRST30)
	jr	jmp_rst

;;;
;;; RST 38H Handler
;;;
RST38H:

	ld	(save_hl), hl	; save hl
	ld	hl, (stealRST38)
jmp_rst:
	push	hl		; set jump address
	ld	hl, (save_hl)	; restore hl
RST20H_IN:
RST28H_IN:
	ret			; jump (stealRST38)

;;;
;;; Universal Monitor Z80 Cold start
;;;

CSTART:
	DI
	LD	SP,STACKM	; monitor stask defines STACKM

	LD	HL,RAM_B
	LD	(DSADDR),HL
	LD	(SADDR),HL
	LD	(GADDR),HL
	LD	A,'I'
	LD	(HEXMOD),A
	
	; init back door RST XXH entory point
	ld	hl, CONOUT		; RST 08H : CONOUT
	ld	(stealRST08), hl
	ld	hl, CONIN
	ld	(stealRST10), hl	; RST 10H : CONIN
	ld	hl, CONST
	ld	(stealRST18), hl	; RST 18H : CONST
	ld	hl, RST20H_IN
	ld	(stealRST20), hl
	ld	hl, RST28H_IN
	ld	(stealRST28), hl
	ld	hl, RST30H_IN
	ld	(stealRST30), hl
	ld	hl, RST38H_IN
	ld	(stealRST38), hl

	;; Initialize register value
	XOR	A
	LD	HL,REG_B
	LD	B,REG_E-REG_B
IR0:
	LD	(HL),A
	INC	HL
	DJNZ	IR0

	LD	HL,STACK		; user stack define STACK
	LD	(REGSP),HL
	ld	hl, RAM_B
	ld	(REGPC), HL		; set program counter

	ld	b, F_bitSize
	ld	a, '.'
	ld	hl, F_bit
ir00:
	ld	(hl), a
	inc	hl
	djnz	ir00		; init F_bit string
	xor	a
	ld	(hl), a		; delimiter
;
;	LD	B,100
;TL:	
;	XOR	A
;	CALL	CONOUT
;	DJNZ	TL
;
	
; init dbg work area

	LD	B, dbg_wend - dbg_wtop
	ld	hl,dbg_wtop	
	XOR	A

dbg_wini:
	ld	(hl), a
	inc	hl
	DJNZ	dbg_wini

	ld	a, 'I'
	ld	(TM_mode), a	; default call_in mode
	ld	a, 'N'
	ld	(TP_mode), a	; default display reg mode
	ld	l, 0
	ld	h, 0
	ld	(TC_cnt), hl	; clear trace step counter to 0
	xor	a
	ld	(fever_t), a	; clear flag trace forever
	; init bp, tp, gstop address & opcode
	ld	hl, RAM_B
	ld	(tpt1_adr), hl
	ld	(tpt2_adr), hl
	ld	(bpt1_adr), hl
	ld	(bpt2_adr), hl
	ld	(tmpb_adr), hl
	ld	a, (hl)
	ld	(tpt1_op), a
	ld	(tpt2_op), a
	ld	(bpt1_op), a
	ld	(bpt2_op), a
	ld	(tmpb_op), a
	
;; Opening message

	LD	HL,OPNMSG
	CALL	STROUT
;	EI

WSTART:
	LD	HL,PROMPT
	CALL	STROUT
	CALL	GETLIN
	CALL	SKIPSP
	CALL	UPPER
	OR	A
	JR	Z, WSTART

	CP	'D'
	JP	Z, DUMP
	CP	'G'
	JP	Z, GO
	CP	'S'
	JP	Z, SETM

	CP	'L'
	JP	Z, LOADH
	CP	'P'
	JP	Z, SAVEH

	CP	'R'
	JP	Z, REG

	cp	'#'
	jp	Z, Launcher

	cp	'B'
	jp	z, brk_cmd	; break point command
	
	cp	'T'
	jp	z, trace_cmd	; trace point command

	cp	'?'
	jr	z, command_hlp	; command help message

ERR:
	LD	HL,ERRMSG
	CALL	STROUT
	JR	WSTART

;;
;; command help
;;
command_hlp:

	LD	HL, cmd_hlp
	CALL	STROUT
	JR	WSTART

;;
;; Launch appended program
;;
Launcher:
	INC	HL
	CALL	SKIPSP		; A <- next char
	CALL	UPPER
	OR	A
	JR	Z,ERR

	; check L or number
	
	cp	'L'
	JR	Z,LST_PRG	; list append program

	; check number

	call	GET_NUM		; return BC : number
	JR	C, ERR

	; check number
	LD	A, C
	CP	(lanch1 - ApendTBL)/2 +1	; a < 17 ?
	JP	NC, ERR
	OR	A				; check '0'
	JP	Z, ERR

	; A <- append program No.

	DEC	A	; 0 <= A <= 0FH
	RLA		; A = A * 2
	LD	D, 0
	LD	E, A
	LD	HL, ApendTBL
	ADD	HL, DE	; get lanch address point
	LD	E, (HL)
	INC	HL
	LD	D, (HL)	; DE : JUMP POINT

	; Jump to append program
	
	EX	DE, HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)	; DE : jump address
	LD	A, D
	OR	E	; address check
	JR	Z,ERR	; jump address NULL
	EX	DE, HL
	JP	(HL)	; lanch append program
	
	; List out append program
LST_PRG:
	; get address to DE
	LD	HL, ApendTBL

LST_PRG1:
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	INC	HL

	PUSH	DE
	POP	IX	; IX <-DE
	LD	A, (IX+0)
	OR	(IX+1)
	JR	Z, LST_END
	INC	DE
	INC	DE	; get string address
	
	EX	DE, HL
	CALL	STROUT
	EX	DE, HL
	JR	LST_PRG1

LST_END:
	JP	WSTART
	
; Append program launch table
;
ApendTBL:
	dw	lanch1
	dw	lanch2
	dw	lanch3
	dw	lanch4
	dw	lanch5
	dw	lanch6
	dw	lanch7
	dw	lanch8
	dw	lanch9
	dw	lanch10
	dw	lanch11
	dw	lanch12
	dw	lanch13
	dw	lanch14
	dw	lanch15
	dw	lanch16
	
lanch1:
	dw	BASIC_CST
	DB	"1. BASIC4.7b Cold Start",CR,LF,00H
lanch2:
	dw	BASIC_WST
	DB	"2. BASIC4.7b Warm Start",CR,LF,00H

lanch3:
lanch4:
lanch5:
lanch6:
lanch7:
lanch8:
lanch9:
lanch10:
lanch11:
lanch12:
lanch13:
lanch14:
lanch15:
lanch16:
	dw	0

	; get number
	; input HL : string buffer
	;
	; Return
	; CF =1 : Error
	; BC: Calculation result

GET_NUM:
	XOR	A		; Initialize C
	LD	B, A
	LD	C, A		; clear BC
	
GET_NUM0:
	CALL	SKIPSP		; A <- next char
	CALL	UPPER
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

	ld	d, 0
	ld	e, a
	CALL	BC_PLUS_DE	; BC = BC + A
	RET	C		; overflow error
				; result: BC = BC * 10 + A
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
	push	bc
	SLA	C
	RL	B		; 2BC
	SLA	C
	RL	B		; 4BC
	SLA	C
	RL	B		; 8BC
	pop	de		; de = bc
	ret	c
	CALL	BC_PLUS_DE	; 9BC
	ret	c
	CALL	BC_PLUS_DE	; 10BC
	RET			; result : BC = BC * 10
;
; BC = BC + DE
BC_PLUS_DE:
	push	hl

	push	de
	pop	hl

	add	hl, bc

	push	hl
	pop	bc

	pop	hl
	RET

;
; list break point
;
b_list:
	ld	a, (bpt1_f)
	or	a
	jr	z, b_list1

	ld	hl, (bpt1_adr)
	ld	a, '1'
	call	b_msg_out

b_list1:
	ld	a, (bpt2_f)
	or	a
	jp	z, WSTART

	ld	hl, (bpt2_adr)
	ld	a, '2'
	call	b_msg_out
	JP	WSTART


;;; 
;;; break point command
;;; 
brk_cmd:
	INC	HL
	CALL	SKIPSP		; A <- next char
	CALL	UPPER
	OR	A
	JR	Z,b_list	; only type "B"

	ld	bc, bpt1_f
	cp	'1'
	jr	z, set_bp1

	ld	bc, bpt2_f
	cp	'2'
	jr	z, set_bp1

	cp	'C'	;clear?
	jr	z, bp_clr
	jp	ERR

set_bp1:
	EX	AF, AF'

	INC	HL
	CALL	SKIPSP		; A <- next char
	CALL	UPPER
	OR	A
	JR	Z, bp_LOT 	;; No address input -> list out
	cp	','
	jp	nz, ERR

	INC	HL
	CALL	SKIPSP
	push	bc
	CALL	RDHEX		; 1st arg.
	pop	hl		; hl <- bc
	jp	c, ERR

	call	setbpadr
	jp	c, ERR
	JP	WSTART


; hl : point of bp flag( bpt1_f or bpt2_f)
; de : break point address

; check ram area, and set berak point
; 
setbpadr:
	ld	a, d
	cp	RAM_B >> 8	; a - 0C0H
	jp	c, chkERR	; ROM area
	cp	IO_B >> 8	; a - 0F0H
	jp	nc, chkERR	; I/O area
	ld	a,1
	ld	(hl), a	; set flag
	inc	hl
	ld	a, (de)		; get opcode
	ld	(hl), a		; save opcode
	inc	hl
	ld	(hl), e ; set break point low address
	inc	hl
	ld	(hl), d ; set break point high address
	or	a	; reset carry
	ret

chkERR:
	scf	;set carry
	ret

; clear break point

bp_clr:
	INC	HL
	CALL	SKIPSP		; A <- next char
	CALL	UPPER
	OR	A
	JR	Z,b_aclr	; all clear

	ld	bc, bpt1_f
	cp	'1'
	jr	z, bp_clr1

	ld	bc, bpt2_f
	cp	'2'
	jp	nz, ERR

bp_clr1:
	xor	a
	ld	(bc), a
	JP	WSTART

b_aclr:
	xor	a
	ld	bc, bpt1_f
	ld	(bc), a
	ld	bc, bpt2_f
	ld	(bc), a
	JP	WSTART

; when no address input. list out BP
;
; bc : break pointer buffer offset
bp_LOT:
	ld	a, (bc)		; set break point?
	or	a
	jp	z, WSTART	; no break point setting

	EX	AF, AF'
	ld	hl, (bpt1_adr)
	cp	'1'
	jr	z, l_b2
	ld	hl, (bpt2_adr)
l_b2:
	call	b_msg_out
	JP	WSTART

bp_msg1:	db	"BP(",00H
bp_msg2:	db	"):",00H

b_msg_out:
	push	hl
	push	af
	ld	hl, bp_msg1
	call	STROUT
	pop	af
	call	CONOUT
	ld	hl, bp_msg2
	call	STROUT
	pop	hl
	call	HEXOUT4
	call	CRLF	
	ret

;;; 
;;; trace command
;;; 
trace_cmd:

; T[address][,step数]
; TP[ON | OFF]
; TM[I | S]

; init steps
	push	hl
	ld	l, 0
	ld	h, 0
	ld	(TC_cnt), hl	; clear trace step counter to 0
	ld	hl,(REGPC)
	ld	(tmpT), hl	; init temp address
	xor	a
	ld	(fever_t), a	; clear flag trace forever

	pop	hl
	inc	hl
	CALL	SKIPSP
	CALL	RDHEX		; 1st arg.
	jp	nc, tadr_chk
	CALL	SKIPSP
	ld	a, (hl)
	or	a
	Jp	z, t_op1	; only 1 step trace, check opcode
	cp	','
	jp	z, stp_chk	; steps check

	CALL	UPPER
	cp	'P'
	jr	z, tp_cmd
	cp	'M'
	jp	nz, ERR
	
	; tm_cmd
	
	inc	hl
	CALL	SKIPSP		; A <- next char
	CALL	UPPER
dip_TM:
	ld	hl, tm_msg_i
	cp	'I'
	jr	z, set_TM
	ld	hl, tm_msg_s
	cp	'S'
	jr	z, set_TM
	or	a
	jp	nz, ERR

;display T mode
	ld	a, (TM_mode)
	jr	dip_TM

;set TM mode and display
set_TM:
	ld	(TM_mode),a
	push	hl
	ld	hl, tm_msg_0
	call	STROUT
	pop	hl
	call	STROUT
	jp	WSTART

tm_msg_0:
	db	"TM mode:<CALL ", 00h
tm_msg_i:
	db	"IN>", CR, LF, 00h
tm_msg_s:
	db	"SKIP>", CR, LF, 00h
	
	
	; tp_cmd
tp_cmd:	
	inc	hl
	CALL	SKIPSP		; A <- next char
	CALL	UPPER
	or	a
	jr	nz, tp_n1
	ld	a, (TP_mode)
	jr	tp_n2
	
tp_n1:
	cp	'O'
	jp	nz, ERR
	inc	hl
	CALL	SKIPSP		; A <- next char
	CALL	UPPER

tp_n2:
	ld	hl, tp_msg_on
	cp	'N'
	jr	z, tp_md_on

	ld	hl, tp_msg_off
	cp	'F'
	jp	nz, ERR

tp_md_on:
	; set trace mode and display mode
	ld	(TP_mode), a
	push	hl
	ld	hl, tp_msg_0
	call	STROUT
	pop	hl
	call	STROUT
	jp	WSTART
	
tp_msg_0:
	db	"TP mode: ", 00h
tp_msg_on:
	db	"ON", CR, LF, 00h
tp_msg_off:
	db	"OFF", CR, LF, 00h

tadr_chk:
	ld	(tmpT), de	; set start address
	CALL	SKIPSP		; A <- next char
	or	a
	jr	z, t_op1	; 1step trace
	cp	','
	jr	z, stp_chk
	jp	ERR

stp_chk:
	inc	hl
	CALL	SKIPSP		; A <- next char
	or	a
	jp	z, ERR
	cp	'-'
	jr	z, chk_fevre

; check steps

	call	GET_NUM		; get steps to BC
	JP	C, ERR		; number error

t_op11:
	ld	(TC_cnt), bc	; set trace step counter
	jr	t_op_chk

t_op1:
	ld	bc, 1
	jr	t_op11

chk_fevre:
	inc	hl
	CALL	SKIPSP		; A <- next char
	cp	'1'
	jp	nz, ERR
	inc	hl
	CALL	SKIPSP		; A <- next char
	or	a
	jp	nz, ERR		; not "-1" then error
	ld	a, 1
	ld	(fever_t), a	; set flag trace forever

t_op_chk:
	ld	hl, (tmpT)	; get PC address
	ld	a, (hl)		; get opcode
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; branch opecode check
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 2 insertion Trace code(TC) 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INSTC2:
	; check 1 byte machine code: branch (RET CC)

	ld	bc, RETCC_TBLE - RETCC_TBLS
	ld	hl, RETCC_TBLS
	cpir
	jr	nz, next_bc1	; not RET CC

	; RET CC
	; trace operation:
	;   1. ea = *REGSP; *ea = TC;
	;   2. ea = *REGPC; *(ea+1) = TC;

	; 1
	ld	c, 1		; first TC point
	call	insBRK_sp
	jp	c, err_trace_seq
	
	; 2
	ld	c, 2		; second TC point
	call	insBRK_1op
	jp	c, err_trace_seq

	jp	END_INS_TC

	; check 2 byte machine code: branch (JR CC, Relative Value)
next_bc1:

	ld	bc, JRCC_TBLE - JRCC_TBLS
	ld	hl, JRCC_TBLS
	cpir
	jr	nz, next_bc2	; not JR CC

	; JR CC, nn
	; trace operation:
	;   1. ea = *REGPC; *(ea + 2 + *(ea+1)) = TC;
	;   2. ea = *REGPC; *(ea+2) = TC;

	; 1
	ld	c, 1		; first TC point
	ld	hl, (tmpT)
	call	Rel_adr_c
	call	inadr_chk_and_wrt
	jp	c, err_trace_seq

	; 2
	ld	c, 2		; second TC point
	call	insBRK_2op
	jp	c, err_trace_seq

	jp	END_INS_TC

	; check 3 byte machine code: branch JP CC, nnnn 16bit literal)

next_bc2:
	ld	bc, JPCC_TBLE - JPCC_TBLS
	ld	hl, JPCC_TBLS
	cpir
	jr	nz, next_bc21		; not JP CCC

	; JP CC, nnnn
	; trace operation:
	;   1. ea = *REGPC; *((short *)(ea+1)) = TC;
	;   2. ea = *REGPC; *(ea+3) = TC;

	ld	c, 1		; first TC point
	jr	next_bc222

	; check 3 byte machine code: branch (CALL CC, nnnn 16bit literal)

next_bc21:
	ld	bc, CLCC_TBLE - CLCC_TBLS
	ld	hl, CLCC_TBLS
	cpir
	jr	nz, INSTC1		; not CALL CCC

	; CALL CC, nnnn
	; trace operation:
	; TM_mode = 'I'
	;   1. ea = *REGPC; *((short *)(ea+1)) = TC;
	;   2. ea = *REGPC; *(ea+3) = TC;
	;
	; TM_mode = 'S'
	;   2. ea = *REGPC; *(ea+3) = TC;

	ld	c, 1		; first TC point
	ld	a, (TM_mode)
	cp	'S'
	jr	z, next_bc22	; skip insertion 1.

next_bc222:
	; 1. ea = *REGPC; *((char *)(ea+1)) = TC;
	call	insBRK_brp
	jp	c, err_trace_seq
	
next_bc221:
	; 2. ea = *REGPC; *(ea+3) = TC;
	ld	c, 2		; second TC point
next_bc22:
	call	insBRK_3op
	jp	c, err_trace_seq

	jp	END_INS_TC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 1 insertion Trace code(TC) 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INSTC1:
	; check 1 byte machine code: branch (return)
	cp	0C9H		; RET ?
	jr	nz, next_bc3	; not RET

	; RET
	; trace operation:
	;   ea = *REGSP; *ea = TC;
	ld	c, 1		; first TC point
	call	insBRK_sp
	jp	c, err_trace_seq
	jp	END_INS_TC

	; check RST p
next_bc3:
	ld	bc, RST_TBLE - RST_TBLS
	ld	hl, RST_TBLS
	cpir
	jr	nz, next_bc4		; not RST p

	; RST p
	; can't trace: skip trace
	; trace operation:
	;   ea = *REGPC; *(ea+1) = TC;
;	ld	hl, RST_DMSG
;	call	STROUT		; message out "DETECT RST OPCODE"
	ld	c, 1		; first TC point
	call	insBRK_1op
	jp	c, err_trace_seq
	
	jp	END_INS_TC

;RST_DMSG:
;	db	"(RST nn) WILL BE SKIPPED. AND TRACE NEXT OPCODE", CR, LF,00

	; check code 0EDH
next_bc4:
	cp	0EDH		; CODE 0EDH ?
	jr	nz, next_bc5	; not 0EDH

	inc	hl
	ld	a, (hl)
	cp	45H		; RETN?
	jr	z, next_bc6	; yes, RETN
	cp	4DH		; RETI?
	jr	nz, next_bc5	; not RETN

	; trace operation:
	;   ea = *REGSP; *ea = TC;
next_bc6:
	ld	c, 1		; first TC point
	call	insBRK_sp
	jr	c, err_trace_seq
	jr	END_INS_TC

	; check JP (HL)
next_bc5:
	ld	hl, (tmpT)
	ld	a, (hl)

	cp	0E9H		; JP (HL) ?
	jr	nz, next_bc7	; not JP (HL)

	; JP (HL)
	; trace operation:
	;   ea = *REGHL; *ea = TC;
	ld	hl, (REGHL)
jphl:
	ld	c, 1		; first TC point
	call	inadr_chk_and_wrt
	jr	c, err_trace_seq
	jr	END_INS_TC

	; check JP (IX)
next_bc7:
	cp	0DDH		; 1st OPOCDE 0DDH ?
	jr	nz, next_bc8	; no 0DDH
	inc	hl
	ld	a, (hl)
	cp	0E9H		; JP (IX) ?
	jr	nz, next_bc8	; not JP (IX)

	; JP (IX)
	; trace operation:
	;   ea = *REGIX; *ea = TC;
	ld	hl, (REGIX)
	jr	jphl

	; check JP (IY)
next_bc8:
	ld	hl, (tmpT)
	ld	a, (hl)

	cp	0FDH		; 1st OPOCDE 0FDH ?
	jr	nz, next_bc9	; no 0FDH
	inc	hl
	ld	a, (hl)
	cp	0E9H		; JP (IX) ?
	jr	nz, next_bc9	; not JP (IX)

	; JP (IY)
	; trace operation:
	;   ea = *REGIY; *ea = TC;
	ld	hl, (REGIY)
	jr	jphl

	; check JR relative
next_bc9:
	ld	hl, (tmpT)
	ld	a, (hl)
	cp	18H		; JR relative ?
	jr	nz, next_bc10	; not JR relative

	; JR Relative
	; trace operation:
	;   ea = *REGPC; *(ea + 2 + *(ea+1)) = TC;
	ld	c, 1		; first TC point
	call	Rel_adr_c
	call	inadr_chk_and_wrt
	jr	c, err_trace_seq
	jr	END_INS_TC

	; check JP literal
next_bc10:
	cp	0C3H		; JP literal ?
	jr	nz, next_bc11	; not JP literal

	; JP literal
	; trace operation:
	; ea = *REGPC; *((char *)(ea+1)) = TC;
	ld	c, 1		; first TC point
	call	insBRK_brp
	jr	c, err_trace_seq
	jr	END_INS_TC

	; check call literal
next_bc11:
	cp	0CDH		; CALL literal ?
	jp	nz, INS2	; no, check not branch opcode 

	; CALL literal
	; trace operation:
	; TM_mode = 'I'
	;   ea = *REGPC; *((short *)(ea+1)) = TC;
	; TM_mode = 'S'
	;   2. ea = *REGPC; *(ea+3) = TC;

	ld	c, 1		; first TC point
	ld	a, (TM_mode)
	cp	'S'
	jr	z, next_bc111	; yes, TM_mode='S'

	; TM_mode = 'I'
	; ea = *REGPC; *((char *)(ea+1)) = TC;
	call	insBRK_brp
	jr	c, err_trace_seq
	jr	END_INS_TC

	; TM_mode = 'S'
	; ea = *REGPC; *(ea+3) = TC;
next_bc111:
	call	insBRK_3op
	jr	c, err_trace_seq

END_INS_TC:
	jp	G0	; go, trace operation

err_trace_seq:
	ld	hl, terr_msg
	call	STROUT
	JP	WSTART
	rst	38h
;	
terr_msg:	db	"Adr ERR", CR, LF, 00H

;--------------------------------------
; 2 byte machine code branch
; - 2nd byte is Relative address
; - input hl : opecode address
; - output hl : target address
;--------------------------------------
Rel_adr_c:
	inc	hl
	ld	e, (hl)		; e = 2nd operand
	inc	hl		; hl = PC + 2
	ld	d, 0ffh
	bit	7, e		; test msb bit
	jr	nz, exp_msb	; 
	ld	d, 0
exp_msb:
	add	hl, de
	ret

;--------------------------------------
; 1 byte op code, insert TC
; ea = *REGPC; *(ea+1) = TC
;--------------------------------------
insBRK_1op:
;	ld	hl, (REGPC)
	ld	hl, (tmpT)
	jr	ib1
	
;--------------------------------------
; 2 byte op code, insert TC
; ea = *REGPC; *(ea+2) = TC
;--------------------------------------
insBRK_2op:
;	ld	hl, (REGPC)
	ld	hl, (tmpT)
	jr	ib2
	
;--------------------------------------
; 3 byte op code, insert TC
; ea = *REGPC; *(ea+3) = TC;
;--------------------------------------
insBRK_3op:
;	ld	hl, (REGPC)
	ld	hl, (tmpT)
ib3:
	inc	hl
ib2:
	inc	hl
ib1:
	inc	hl
	call	inadr_chk_and_wrt
	ret

;--------------------------------------
; 3 byte op code, insert TC in branch point
; ea = *REGPC; *((char *)(ea+1)) = TC;
;--------------------------------------
insBRK_brp:
;	ld	hl, (REGPC)
	ld	hl, (tmpT)
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ex	de,  hl
	call	inadr_chk_and_wrt
	ret

;--------------------------------------
; insert TC at SP
; ea = *REGSP; *ea = TC;
;--------------------------------------
insBRK_sp:
	ld	de, (REGSP)
	ld	a, (de)
	ld	l, a
	inc	de
	ld	a, (de)
	ld	h, a		; hl = *sp
	call	inadr_chk_and_wrt
	ret

;--------------------------------------
; check (HL) is RAM AREA
; insert Trace code at (HL)
;--------------------------------------
inadr_chk_and_wrt:
	ld	a, h

	IF	RAM12K
	cp	RAM_B >> 8	; a & 0c0h
	jr	c, NO_RAM_AREA
	cp	IO_B >> 8
	jr	nc, NO_RAM_AREA
	ENDIF

	IF	RAM8K
	cp	RAM_B >> 8		; 80H
	jr	c, NO_RAM_AREA
	cp	RAM_E >> 8		; 9FH
	jr	nc, NO_RAM_AREA
	ENDIF

	IF	RAM4K
	cp	RAM_B >> 8		; 80H
	jr	c, NO_RAM_AREA
	cp	RAM_E >> 8		; 8FH
	jr	nc, NO_RAM_AREA
	ENDIF

	ld	a, c
	cp	1		;first save?
	jr	nz, icka1
	ld	de, tpt1_f
	ld	(de), a		; set trace ON
	ld	(tpt1_adr), hl
;	ld	a, (hl)		; get opcode
;	ld	(tpt1_op), a	; save opcode
	jr	icka_end
icka1:
	ld	de, tpt2_f
	ld	(de), a		; set trace ON
	ld	(tpt2_adr), hl
;	ld	a, (hl)		; get opcode
;	ld	(tpt2_op), a	; save opcode
icka_end:
	xor	a
	ret

NO_RAM_AREA:
	SCF
	ret
	

;;;;;;;;;;;;;;;;;;;;;;;;;;
; 2 insertion TC TABLE
;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 1 byte machine code: branch (RET CC)
RETCC_TBLS:
	DB	0C0H	; RET	NZ
	DB	0C8H	; RET	Z
	DB	0D0H	; RET	NC
	DB	0D8H	; RET	C
	DB	0E0H	; RET	PO
	DB	0E8H	; RET	PE
	DB	0F0H	; RET	P
	DB	0F8H	; RET	M
RETCC_TBLE:

; 2 byte machine code: branch (JR CC, Relative)
JRCC_TBLS:
	DB	10H	; DJNZ	$
	DB	20H	; JR	NZ,$
	DB	28H	; JR	Z,$
	DB	30H	; JR	NC,$
	DB	38H	; JR	C,$
JRCC_TBLE:

; 3 byte machine code: branch (JP CC, 16bit literal)
JPCC_TBLS:
	DB	0C2H	; JP	NZ,1234H
	DB	0CAH	; JP	Z,1234H
	DB	0D2H	; JP	NC,1234H
	DB	0DAH	; JP	C,1234H
	DB	0E2H	; JP	PO,1234H
	DB	0EAH	; JP	PE,1234H
	DB	0F2H	; JP	P,1234H
	DB	0FAH	; JP	M,1234H
JPCC_TBLE:

; (call 16bit literal)
CLCC_TBLS:
	DB	0C4H	; CALL	NZ,1234H
	DB	0CCH	; CALL	Z,1234H
	DB	0D4H	; CALL	NC,1234H
	DB	0DCH	; CALL	C,1234H
	DB	0E4H	; CALL	PO,1234H
	DB	0ECH	; CALL	PE,1234H
	DB	0F4H	; CALL	P,1234H
	DB	0FCH	; CALL	M,1234H
CLCC_TBLE:

;;;;;;;;;;;;;;;;;;;;;;;;;;
; 1 insertion TC TABLE
;;;;;;;;;;;;;;;;;;;;;;;;;;

; restart
RST_TBLS:
	DB	0C7H	; RST	00H
	DB	0CFH	; RST	08H
	DB	0D7H	; RST	10H
	DB	0DFH	; RST	18H
	DB	0EFH	; RST	28H
	DB	0E7H	; RST	20H
	DB	0F7H	; RST	30H
	DB	0FFH	; RST	38H
RST_TBLE:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; machine code check(except branch)
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INS2:

	; 2byte machine code search
	ld	bc, TWO_OPTBL_E - TWO_OPTBL
	ld	hl, TWO_OPTBL
	cpir
	jp	z, meet_op2

	; 3byte machine code search
	ld	bc, THREE_OPTBL_E - THREE_OPTBL
	ld	hl, THREE_OPTBL
	cpir
	jp	z, meet_op3

	; check 0CBH
	
	; readjust hl
	ld	hl, (tmpT)

	cp	0CBH		; opecode 0CBH?
	jr	z, meet_op2
	
	; check 0DDH
	cp	0ddh		; opecode 0DDH?
	jr	z, meet_dd
	
	; check 0EDH
	cp	0edh		; opecode 0EDH?
	jr	z, meet_ed

	; check 0FDH
	cp	0fdh		; opecode 0FDH?
	jr	z, meet_dd

	; 1byte machine code
	jr	meet_op1

	; opecode 0DDh
meet_dd:
	inc	hl
	ld	a, (hl)	
	cp	0cbh		; 2nd 0CBH?
	jr	z, meet_op4
	cp	21h		; 2nd 21H?
	jr	z, meet_op4
	cp	22h		; 2nd 22H?
	jr	z, meet_op4
	cp	2ah		; 2nd 2AH?
	jr	z, meet_op4
	cp	36h		; 2nd 36H?
	jr	z, meet_op4

	; 2nd code search
	ld	bc, DD_2NDTBL_E - DD_2NDTBL
	ld	hl, DD_2NDTBL
	cpir
	jr	z, meet_op2
	jr	meet_op3

meet_ed:
	inc	hl
	ld	a, (hl)	
	cp	43h		; 2nd 43H?
	jr	z, meet_op4
	cp	4bh		; 2nd 4BH?
	jr	z, meet_op4
	cp	53h		; 2nd 53H?
	jr	z, meet_op4
	cp	5bh		; 2nd 5BH?
	jr	z, meet_op4
	cp	73h		; 2nd 73H?
	jr	z, meet_op4
	cp	7bh		; 2nd 7BH?
	jr	z, meet_op4
	jr	meet_op2

; 1 machine code
meet_op1:
	ld	c, 1
	call	insBRK_1op
	jp	c, err_trace_seq
	jp	END_INS_TC

; 2 machine code
meet_op2:
	ld	c, 1
	call	insBRK_2op
	jp	c, err_trace_seq
	jp	END_INS_TC
; 3 machine code
meet_op3:
	ld	c, 1
	call	insBRK_3op
	jp	c, err_trace_seq
	jp	END_INS_TC

; 4 machine codee
meet_op4:
	ld	c, 1
;	ld	hl, (REGPC)
	ld	hl, (tmpT)
	inc	hl
	call	ib3
	jp	c, err_trace_seq
	jp	END_INS_TC

TWO_OPTBL:	; second byte is literal[nn]
	DB	06h	; LD	B,nn
	DB	0Eh	; LD	C,nn
;	DB	10h	; DJNZ	nn
	DB	16h	; LD	D,nn
;	DB	18h	; JR	nn
	DB	1Eh	; LD	E,nn
;	DB	20h	; JR	NZ,nn
	DB	26h	; LD	H,12H
;	DB	28h	; JR	Z,nn
	DB	2Eh	; LD	L,nn
;	DB	30h	; JR	NC,nn
	DB	36h	; LD	(HL),nn
;	DB	38h	; JR	C,nn
	DB	3Eh	; LD	A,nn
	DB	0C6h	; ADD	A,nn
	DB	0CEh	; ADC	A,nn
	DB	0D3h	; OUT	(nn),A
	DB	0D6h	; SUB	nn
	DB	0DBh	; IN	A,(nn)
	DB	0DEh	; SBC	A,nn
	DB	0E6h	; AND	nn
	DB	0EEh	; XOR	nn
	DB	0F6h	; OR	nn
	DB	0FEh	; CP	nn
TWO_OPTBL_E:

THREE_OPTBL:	; 2nd, 3rd byte is 16bitliteral[nnnn]
	DB	01h	; LD	BC,nnnn
	DB	11h	; LD	DE,nnnn
	DB	21h	; LD	HL,nnnn
	DB	22h	; LD	(nnnn),HL
	DB	2Ah	; LD	HL,(nnnn)
	DB	31h	; LD	SP,nnnn
	DB	32h	; LD	(nnnn),A
	DB	3Ah	; LD	A,(nnnn)
;	DB	0C2h	; JP	NZ,nnnn
;	DB	0C3h	; JP	nnnn
;	DB	0C4h	; CALL	NZ,nnnn
;	DB	0CAh	; JP	Z,nnnn
;	DB	0CCh	; CALL	Z,nnnn
;	DB	0CDh	; CALL	nnnn
;	DB	0D2h	; JP	NC,nnnn
;	DB	0D4h	; CALL	NC,nnnn
;	DB	0DAh	; JP	C,nnnn
;	DB	0DCh	; CALL	C,nnnn
;	DB	0E2h	; JP	PO,nnnn
;	DB	0E4h	; CALL	PO,nnnn
;	DB	0EAh	; JP	PE,nnnn
;	DB	0ECh	; CALL	PE,nnnn
;	DB	0F2h	; JP	P,nnnn
;	DB	0F4h	; CALL	P,nnnn
;	DB	0FAh	; JP	M,nnnn
;	DB	0FCh	; CALL	M,nnnn
THREE_OPTBL_E:

DD_2NDTBL:
	DB	09h	; ADD	IX,BC
	DB	19h	; ADD	IX,DE
	DB	23h	; INC	IX
	DB	29h	; ADD	IX,IX
	DB	2Bh	; DEC	IX
	DB	39h	; ADD	IX,SP
	DB	0E1h	; POP	IX
	DB	0E3h	; EX	(SP),IX
	DB	0E5h	; PUSH	IX
;	DB	0E9h	; JP	(IX)
	DB	0F9h	; LD	SP,IX
DD_2NDTBL_E:

;;; 
;;; Dump memory
;;; 

DUMP:
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX		; 1st arg.
	jr	nc, DP0
	;; No arg. chk
	CALL	SKIPSP
	LD	A,(HL)
	OR	A
	JP	NZ,ERR
	LD	HL,(DSADDR)
	LD	BC,128
	ADD	HL,BC
	LD	(DEADDR),HL
	JR	DPM

	;; 1st arg. found
DP0:
	LD	(DSADDR),DE
	CALL	SKIPSP
	LD	A,(HL)
	CP	','
	JR	Z,DP1
	OR	A
	JP	NZ,ERR
	;; No 2nd arg.
	LD	HL,128
	ADD	HL,DE
	LD	(DEADDR),HL
	JR	DPM
DP1:
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX
	jp	c, ERR
	CALL	SKIPSP
	OR	A
	jp	nz, ERR
	INC	DE
	LD	(DEADDR),DE
DPM:
	;; DUMP main
	LD	HL,(DSADDR)
	LD	A,0F0H
	AND	L
	LD	L,A
	XOR	A
	LD	(DSTATE),A
DPM0:
	PUSH	HL
	CALL	DPL
	POP	HL
	LD	BC,16
	ADD	HL,BC
	CALL	CONST
	JR	NZ,DPM1
	LD	A,(DSTATE)
	CP	2
	JR	C,DPM0
	LD	HL,(DEADDR)
	LD	(DSADDR),HL
	JP	WSTART
DPM1:
	LD	(DSADDR),HL
	CALL	CONIN
	JP	WSTART

DPL:
	;; DUMP line
	CALL	HEXOUT4
	PUSH	HL
	LD	HL,DSEP0
	CALL	STROUT
	POP	HL
	LD	IX,INBUF
	LD	B,16
DPL0:
	CALL	DPB
	DJNZ	DPL0

	LD	HL,DSEP1
	CALL	STROUT

	LD	HL,INBUF
	LD	B,16
DPL1:
	LD	A,(HL)
	INC	HL
	CP	' '
	JR	C,DPL2
	CP	7FH
	JR	NC,DPL2
	CALL	CONOUT
	JR	DPL3
DPL2:
	LD	A,'.'
	CALL	CONOUT
DPL3:
	DJNZ	DPL1
	JP	CRLF

DPB:	; Dump byte
	LD	A,' '
	CALL	CONOUT
	LD	A,(DSTATE)
	OR	A
	JR	NZ,DPB2
	; Dump state 0
	LD	A,(DSADDR)	; Low byte
	CP	L
	JR	NZ,DPB0
	LD	A,(DSADDR+1)	; High byte
	CP	H
	JR	Z,DPB1
DPB0:	; Still 0 or 2
	LD	A,' '
	CALL	CONOUT
	CALL	CONOUT
	LD	(IX),A
	INC	HL
	INC	IX
	RET
DPB1:	; Found start address
	LD	A,1
	LD	(DSTATE),A
DPB2:
	LD	A,(DSTATE)
	CP	1
	JR	NZ,DPB0
	; Dump state 1
	LD	A,(HL)
	LD	(IX),A
	CALL	HEXOUT2
	INC	HL
	INC	IX
	LD	A,(DEADDR)	; Low byte
	CP	L
	RET	NZ
	LD	A,(DEADDR+1)	; High byte
	CP	H
	RET	NZ
	; Found end address
	LD	A,2
	LD	(DSTATE),A
	RET

;;;
;;; GO address
;;; 

GO:
	ld	de, (REGPC)
	ld	(goTmp), de	; save go tmp go address
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX
	jr	nc, gostmp
	OR	A
	JR	Z, g_stpadr
gostmp:
	ld	a, d
	cp	IO_B >> 8	; a - 0F0H
	jp	nc, ERR		; detect I/O area
	LD	(goTmp),DE	; save going address
g_stpadr:
	CALL	SKIPSP
	LD	A,(HL)
	or	a
	jr	z, GO1
	cp	','
	jp	nz, ERR

; set break point with go command

	INC	HL
	CALL	SKIPSP
	CALL	RDHEX		; 1st arg.
	jp	c, ERR

	ld	hl, tmpb_f	; hl: temp break point buffer
	call	setbpadr
	jp	c, ERR		; address is incorrect

GO1:
	LD	hl, (goTmp)
	ld	(REGPC), hl	; set go address

G0:
	; set break point
	ld	hl, bpt1_f
	ld	de, bpt1_adr
	call	set_bp
	ld	hl, bpt2_f
	ld	de, bpt2_adr
	call	set_bp

; check Trace mode

	ld	a, (tpt1_f)
	or	a
	jr	z, donot_trace
	
	ld	hl,(tmpT)
	ld	(REGPC), hl	; set trace address

	ld	hl, tpt1_f
	ld	de, tpt1_adr
	call	set_bp
	ld	hl, tpt2_f
	ld	de, tpt2_adr
	call	set_bp
	jr	skp_tbp		; skip set tmp bp, if tracing

; check break pointer

donot_trace:
	ld	hl, tmpb_f
	ld	de, tmpb_adr
	call	set_bp

	;; R register adjustment

skp_tbp:
	LD	HL,(REGSP)
	LD	SP,HL
	LD	HL,(REGPC)
	PUSH	HL
	LD	IX,(REGIX)
	LD	IY,(REGIY)
	LD	HL,(REGAFX)
	PUSH	HL
	LD	BC,(REGBCX)
	LD	DE,(REGDEX)
	LD	HL,(REGHLX)
	EXX
	POP	AF
	EX	AF,AF'
	LD	HL,(REGAF)
	PUSH	HL
	LD	BC,(REGBC)
	LD	DE,(REGDE)
	LD	HL,(REGHL)
	LD	A,(REGI)
	LD	I,A
	LD	A,(REGR)
	LD	R,A
	POP	AF
	RET			; POP PC

set_bp:
	ld	a, (hl)
	or	a
	ret	z
	inc	hl	; hl = save opcode buffer

	ld	a, (de)
	ld	c, a
	inc	de
	ld	a, (de)
	ld	b, a	; bc = break point address

	ld	a, (bc)	; get save opcode
	ld	(hl),a	; save opcode
	ld	a, 0FFH
	ld	(bc), a	; insert RST 38H code
	ret
	
;;;
;;; SET memory
;;; 

SETM:
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX

	jp	c, ERR

	CALL	SKIPSP
	LD	A,(HL)
	OR	A
	JP	NZ,ERR
	LD	A,C
	OR	A
	JR	NZ,SM0
	LD	DE,(SADDR)


SM0:
	EX	DE,HL
SM1:
	CALL	HEXOUT4
	PUSH	HL
	LD	HL,DSEP1
	CALL	STROUT
	POP	HL
	LD	A,(HL)
	PUSH	HL
	CALL	HEXOUT2
	LD	A,' '
	CALL	CONOUT
	CALL	GETLIN
	CALL	SKIPSP
	LD	A,(HL)
	OR	A
	JR	NZ,SM2
	;; Empty  (Increment address)
	POP	HL
	INC	HL
	LD	(SADDR),HL
	JR	SM1
SM2:
	CP	'-'
	JR	NZ,SM3
	;; '-'  (Decrement address)
	POP	HL
	DEC	HL
	LD	(SADDR),HL
	JR	SM1
SM3:
	CP	'.'
	JR	NZ,SM4
	POP	HL
	LD	(SADDR),HL
	JP	WSTART
SM4:
	CALL	RDHEX
	OR	A
	POP	HL
	JP	Z,ERR
	LD	(HL),E
	INC	HL
	LD	(SADDR),HL	; set value

	; resave opcode for BP command
	ld	de, (bpt1_adr)
	ld	a, (de)
	ld	(bpt1_op), a
	ld	de, (bpt2_adr)
	ld	a, (de)
	ld	(bpt2_op), a

	JR	SM1

;;;
;;; LOAD HEX file
;;;

LOADH:
	; clear brk point
	xor	a
	ld	(bpt1_f), a
	ld	(bpt2_f), a
	
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	LD	A,(HL)
	OR	A
	JP	NZ,ERR

	LD	A,C
	OR	A
	JR	NZ,LH0

	LD	DE,0		;Offset
LH0:
	CALL	CONIN
	CALL	UPPER
	CP	'S'
	JR	Z,LHS0
LH1:
	CP	':'
	JR	Z,LHI0
LH2:
	;; Skip to EOL
	CP	CR
	JR	Z,LH0
	CP	LF
	JR	Z,LH0
LH3:
	CALL	CONIN
	JR	LH2

LHI0:
	ld	a, '.'
	call	CONOUT

	CALL	HEXIN
	LD	C,A		; Checksum
	LD	B,A		; Length

	CALL	HEXIN
	LD	H,A		; Address H
	ADD	A,C
	LD	C,A

	CALL	HEXIN
	LD	L,A		; Address L
	ADD	A,C
	LD	C,A

	;; Add offset
	ADD	HL,DE

	CALL	HEXIN
	LD	(RECTYP),A
	ADD	A,C
	LD	C,A		; Checksum

	LD	A,B
	OR	A
	JR	Z,LHI3
LHI1:
	CALL	HEXIN
	PUSH	AF
	ADD	A,C
	LD	C,A		; Checksum

	LD	A,(RECTYP)
	OR	A
	JR	NZ,LHI20

	POP	AF
	LD	(HL),A
	INC	HL
	JR	LHI2
LHI20:
	POP	AF
LHI2:
	DJNZ	LHI1
LHI3:
	CALL	HEXIN
	ADD	A,C
	JR	NZ,LHIE		; Checksum error
	LD	A,(RECTYP)
	OR	A
	JP	Z,LH3
	JP	WSTART
LHIE:
	LD	HL,IHEMSG
	CALL	STROUT
	JP	WSTART
	
LHS0:
	CALL	CONIN
	LD	(RECTYP),A

	CALL	HEXIN
	LD	B,A		; Length+3
	LD	C,A		; Checksum

	CALL	HEXIN
	LD	H,A
	ADD	A,C
	LD	C,A
	
	CALL	HEXIN
	LD	L,A
	ADD	A,C
	LD	C,A

	ADD	HL,DE

	DEC	B
	DEC	B
	DEC	B
	JR	Z,LHS3
LHS1:
	CALL	HEXIN
	PUSH	AF
	ADD	A,C
	LD	C,A		; Checksum

	LD	A,(RECTYP)
	CP	'1'
	JR	NZ,LHS2

	POP	AF
	LD	(HL),A
	INC	HL
	JR	LHS20
LHS2:
	POP	AF
LHS20:
	DJNZ	LHS1
LHS3:
	CALL	HEXIN
	ADD	A,C
	CP	0FFH
	JR	NZ,LHSE

	LD	A,(RECTYP)
	CP	'7'
	JR	Z,LHSR
	CP	'8'
	JR	Z,LHSR
	CP	'9'
	JR	Z,LHSR
	JP	LH3
LHSE:
	LD	HL,SHEMSG
	CALL	STROUT
LHSR:
	JP	WSTART
	
;;;
;;; SAVE HEX file
;;;

SAVEH:
	INC	HL
	LD	A,(HL)
	CALL	UPPER
	CP	'I'
	JR	Z,SH0
	CP	'S'
	JR	NZ,SH1
SH0:
	INC	HL
	LD	(HEXMOD),A
SH1:
	CALL	SKIPSP
	CALL	RDHEX
	OR	A
	JR	Z,SHE
	PUSH	DE
	POP	IX		; IX = Start address
	CALL	SKIPSP
	LD	A,(HL)
	CP	','
	JR	NZ,SHE
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX		; DE = End address
	OR	A
	JR	Z,SHE
	CALL	SKIPSP
	LD	A,(HL)
	OR	A
	JR	Z,SH2
SHE:
	JP	ERR

SH2:
	PUSH	IX
	POP	HL
	EX	DE,HL
	INC	HL
	OR	A
	SBC	HL,DE		; HL = Length
SH3:
	CALL	SHL00
	LD	A,H
	OR	L
	JR	NZ,SH3

	LD	A,(HEXMOD)
	CP	'I'
	JR	NZ,SH4
	;; End record for Intel HEX
	LD	HL,IHEXER
	CALL	STROUT
	JP	WSTART
SH4:
	;; End record for Motorola S record
	LD	HL,SRECER
	CALL	STROUT
	JP	WSTART

SHL00:
	LD	C,16
	LD	A,H
	OR	A
	JR	NZ,SHL0
	LD	A,L
	CP	C
	JR	NC,SHL0
	LD	C,A
SHL0:
	LD	B,0
	OR	A
	SBC	HL,BC
	LD	B,C

	LD	A,(HEXMOD)
	CP	'I'
	JR	NZ,SHLS

	;; Intel HEX
	LD	A,':'
	CALL	CONOUT

	LD	A,B
	CALL	HEXOUT2		; Length
	LD	C,B		; Checksum

	LD	A,D
	CALL	HEXOUT2
	LD	A,D
	ADD	A,C
	LD	C,A
	
	LD	A,E
	CALL	HEXOUT2
	LD	A,E
	ADD	A,C
	LD	C,A
	
	XOR	A
	CALL	HEXOUT2
SHLI0:
	LD	A,(DE)
	PUSH	AF
	CALL	HEXOUT2
	POP	AF
	ADD	A,C
	LD	C,A

	INC	DE
	DJNZ	SHLI0

	LD	A,C
	NEG
	CALL	HEXOUT2
	JP	CRLF

SHLS:
	;; Motorola S record
	LD	A,'S'
	CALL	CONOUT
	LD	A,'1'
	CALL	CONOUT

	LD	A,B
	ADD	A,2+1		; DataLength + 2(Addr) + 1(Sum)
	LD	C,A
	CALL	HEXOUT2

	LD	A,D
	CALL	HEXOUT2
	LD	A,D
	ADD	A,C
	LD	C,A
	
	LD	A,E
	CALL	HEXOUT2
	LD	A,E
	ADD	A,C
	LD	C,A
SHLS0:
	LD	A,(DE)
	PUSH	AF
	CALL	HEXOUT2		; Data
	POP	AF
	ADD	A,C
	LD	C,A

	INC	DE
	DJNZ	SHLS0

	LD	A,C
	CPL
	CALL	HEXOUT2
	JP	CRLF

;;;
;;; Register
;;;

REG:
	INC	HL
	CALL	SKIPSP
	CALL	UPPER
	OR	A
	JR	NZ,RG0
	CALL	RDUMP
	JP	WSTART
RG0:
	EX	DE,HL
	LD	HL,RNTAB
RG1:
	CP	(HL)
	JR	Z,RG2		; Character match
	LD	C,A
	INC	HL
	LD	A,(HL)
	OR	A
	JR	Z,RGE		; Found end mark
	LD	A,C
	LD	BC,5
	ADD	HL,BC		; Next entry
	JR	RG1
RG2:
	INC	HL
	LD	A,(HL)
	CP	0FH		; Link code
	JR	NZ,RG3
	;; Next table
	INC	HL
	LD	C,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,C
	INC	DE
	LD	A,(DE)
	CALL	UPPER
	JR	RG1
RG3:
	OR	A
	JR	Z,RGE		; Found end mark

	LD	C,(HL)		; LD C,A???
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	PUSH	DE		; Reg storage address
	INC	HL
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A		; HL: Reg name
	CALL	STROUT
	LD	A,'='
	CALL	CONOUT

	LD	A,C
	AND	07H
	CP	1
	JR	NZ,RG4
	;; 8 bit register
	POP	HL
	LD	A,(HL)
	PUSH	HL
	CALL	HEXOUT2
	JR	RG5
RG4:
	;; 16 bit register
	POP	HL
	PUSH	HL
	INC	HL
	LD	A,(HL)
	CALL	HEXOUT2
	DEC	HL
	LD	A,(HL)
	CALL	HEXOUT2
RG5:
	LD	A,' '
	CALL	CONOUT
	PUSH	BC		; C: reg size
	CALL	GETLIN
	CALL	SKIPSP
	CALL	RDHEX
	OR	A
	JR	Z,RGR
	POP	BC
	POP	HL
	LD	A,C
	CP	1
	JR	NZ,RG6
	;; 8 bit register
	LD	(HL),E
	JR	RG7
RG6:
	;; 16 bit register
	LD	(HL),E
	INC	HL
	LD	(HL),D
RG7:
RGR:
	JP	WSTART
RGE:
	JP	ERR

RDUMP:
	LD	HL,RDTAB
RD0:
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,D
	OR	E
	JP	Z,CRLF		; End
	push	de
	EX	DE,HL
	CALL	STROUT	; print name of register
	EX	DE,HL
	pop	de

; flag check
	ld	a, RDSF_H
	cp	d
	jr	nz, rd101
	ld	a, RDSF_L
	cp	e
	jr	nz, rd101
	jr	rd20

rd101:
	ld	a, RDSFX_H
	cp	d
	jr	nz, rd10
	ld	a, RDSFX_L
	cp	e
	jr	z, rd20

rd10:
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,(HL)
	INC	HL
	EX	DE,HL
	CP	1
	JR	NZ,RD1
	;; 1 byte
	LD	A,(HL)
	CALL	HEXOUT2
	EX	DE,HL
	JR	RD0
RD1:
	;; 2 byte
	INC	HL
	LD	A,(HL)
	CALL	HEXOUT2		; High byte
	DEC	HL
	LD	A,(HL)
	CALL	HEXOUT2		; Low byte
	EX	DE,HL
	JR	RD0

; make flag image string
rd20:
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	ld	a, (de)		; get flag values

	push	de
	push	hl

; make flag image

	ld	hl, F_bit
	ld	bc, F_bit_on
	ld	de, F_bit_off
	push	af		; adjustment SP. DO NOT DELETE THIS LINE!

flg_loop:
	pop	af		; "push af" before loop back
	sla	a
	jr	nc, flg_off
	push	af
	ld	a, (bc)
	ld	(hl), a
	pop	af
	jr	flg_nxt
flg_off:
	push	af
	ld	a, (de)
	ld	(hl), a
	pop	af

flg_nxt:
	inc	bc
	inc	de
	inc	hl

	push	af
	ld	a, (hl)
	or	a		;check delimiter
	jr	nz, flg_loop

	pop	af		; restore stack position
	ld	hl, F_bit
	call	STROUT		; print flag register for bit imaze

	pop	hl
	pop	de

	inc	hl
	JR	RD0

F_bit_on:	db	"SZ.H.PNC"
F_bit_off:	db	"........"


;;;
;;; Other support routines
;;;

STROUT:
	LD	A,(HL)
	AND	A
	RET	Z
	CALL	CONOUT
	INC	HL
	JR	STROUT

; input:  HL
; output: 4 hex_char output console

HEXOUT4:
	LD	A,H
	CALL	HEXOUT2
	LD	A,L

; input:  A
; output: 2 hex_char output console
HEXOUT2:
	PUSH	AF
	RRA
	RRA
	RRA
	RRA
	CALL	HEXOUT1
	POP	AF

; input:  A
; output: 1 hex_char output console
HEXOUT1:
	AND	0FH
	ADD	A,'0'
	CP	'9'+1
	JP	C,CONOUT
	ADD	A,'A'-'9'-1
	JP	CONOUT

HEXIN:
	XOR	A
	CALL	HI0
	RLCA
	RLCA
	RLCA
	RLCA
HI0:
	PUSH	BC
	LD	C,A
	CALL	CONIN
	CALL	UPPER
	CP	'0'
	JR	C,HIR
	CP	'9'+1
	JR	C,HI1
	CP	'A'
	JR	C,HIR
	CP	'F'+1
	JR	NC,HIR
	SUB	'A'-'9'-1
HI1:
	SUB	'0'
	OR	C
HIR:
	POP	BC
	RET
	
CRLF:
	LD	A,CR
	CALL	CONOUT
	LD	A,LF
	JP	CONOUT

CLR_CRT:
	PUSH	HL
	LD	HL, ESC_CRT_CLR
	CALL	STROUT
	POP	HL
	RET
	
ESC_CRT_CLR:
	db	01BH
	db	"[2"
	db	0


GETLIN0:	; input hl

	PUSH	BC
	LD	B,0
	jr	GL0

GETLIN:
	PUSH	BC
	LD	HL,INBUF
	LD	B,0
GL0:
	CALL	CONIN
	CP	CR
	JR	Z,GLE
	CP	LF
	JR	Z,GLE
	CP	BS
	JR	Z,GLB
	CP	DEL
	JR	Z,GLB
	CP	' '
	JR	C,GL0
	CP	80H
	JR	NC,GL0
	LD	C,A
	LD	A,B
	CP	BUFLEN-1
	JR	NC,GL0	; Too long
	INC	B
	LD	A,C
	CALL	CONOUT
	LD	(HL),A
	INC	HL
	JR	GL0
GLB:
	LD	A,B
	AND	A
	JR	Z,GL0
	DEC	B
	DEC	HL
	LD	A,08H
	CALL	CONOUT
	LD	A,' '
	CALL	CONOUT
	LD	A,08H
	CALL	CONOUT
	JR	GL0
GLE:
	CALL	CRLF
	LD	(HL),00H
	LD	HL,INBUF
	POP	BC
	RET

SKIPSP:
	LD	A,(HL)
	CP	' '
	RET	NZ
	INC	HL
	JR	SKIPSP

UPPER:
	CP	'a'
	RET	C
	CP	'z'+1
	RET	NC
	ADD	A,'A'-'a'
	RET

RDHEX:
	LD	C,0
	LD	DE,0
RH0:
	LD	A,(HL)
	CALL	UPPER
	CP	'0'
	JR	C,RHE
	CP	'9'+1
	JR	C,RH1
	CP	'A'
	JR	C,RHE
	CP	'F'+1
	JR	NC,RHE
	SUB	'A'-'9'-1
RH1:
	SUB	'0'
	RLA
	RLA
	RLA
	RLA
	RLA
	RL	E
	RL	D
	RLA
	RL	E
	RL	D
	RLA
	RL	E
	RL	D
	RLA
	RL	E
	RL	D
	INC	HL
	INC	C
	JR	RH0
RHE:
	ld	a, c
	or	a
	jr	z, rhe1
	cp	5
	jr	nc, rhe1
	or	a	; clear carry
	ret
	
rhe1:
	scf	; set carry
	RET

;;;
;;; API Handler
;;:   C : API entory NO.
;;;

RST30H_IN:

	PUSH	HL
	PUSH	BC
	LD	HL,APITBL
	LD	B,0
	ADD	HL,BC
	ADD	HL,BC
	LD	B,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,B
	POP	BC
	EX	(SP),HL		; Restore HL, jump address on stack top
	RET

APITBL:
	DW	API00		; 00: CSTART
	DW	API01		; 01: WSTART
	DW	CONOUT		; 02: CONOUT
	DW	STROUT		; 03: STROUT
	DW	CONIN		; 04: CONIN
	DW	CONST		; 05: CONST
	DW	API06		; 06: PSPEC
	DW	HEXOUT4		; 07: CONOUT HEX4bytes: input HL
	DW	HEXOUT2		; 08: CONOUT HEX2bytes: input A
	DW	HEXOUT1		; 09: CONOUT HEX1byte : input A
	DW	CLR_CRT		; 10: Clear screen (ESC+[2)
	DW	GETLIN0		; 11: GET a line (input HL : input buffer address)
	DW	SKIPSP		; 12: SKIP Spase
	DW	CRLF		; 13: CONOUT CRLF
	DW	UPPER		; 14: Lower to UPPER
	DW	RDHEX		; 15: get hex number from chr buffer
				;     input  HL : hex string buffer
				;     output DE : hex number
				;            CF=1 : error, C, A = hex counts(1-4)
	DW	DEC_STR		; 16: get decimal srtings
				; input hl : return storings buffer addr.
				;       de : 16bit binary
	DW	DIV16_8		; 17; division 16bit / 8bit
	DW	MUL_8		; 18: multiply 8bit * 8bit
	IF RAM12K
	DW	STOPW		; 19: stopwatch
	ENDIF

	;; CSTART
API00:
	JP	CSTART

	;; WSTART from API
API01:
	LD	SP,STACKM	; reset SP for monitor

; check stop by bp and trace operation

	ld	a, (tmpb_f)
	or	a
	jr	z, ws_chk1
	ld	hl, tmpb_op
	call	rstr_tpt
ws_chk1:
	ld	a, (tpt1_f)
	or	a
	jr	z, ws_chk2
	ld	hl, tpt1_op
	call	rstr_tpt

ws_chk2:
	ld	a, (tpt2_f)
	or	a
	jr	z, ws_chk3
	ld	hl, tpt2_op
	call	rstr_tpt
ws_chk3:
	ld	a, (bpt2_f)
	or	a
	jr	z, ws_chk4
	ld	hl, bpt2_op
	call	rstr_bpt
ws_chk4:
	ld	a, (bpt1_f)
	or	a
	jr	z, ws_chk5
	ld	hl, bpt1_op
	call	rstr_bpt
ws_chk5:
	JP	backTomon

	;; PSPEC
API06:
	XOR	A
	RET

;;;
;;; Break Point
;;; trace Point
;;; go, stop point
;;; operation handler
;;
RST38H_IN:
	PUSH	AF
	LD	A,R
	LD	(REGR),A
	LD	A,I
	LD	(REGI),A
	LD	(REGHL),HL
	LD	(REGDE),DE
	LD	(REGBC),BC
	POP	HL
	LD	(REGAF),HL
	EX	AF,AF'
	PUSH	AF
	EXX
	LD	(REGHLX),HL
	LD	(REGDEX),DE
	LD	(REGBCX),BC
	POP	HL
	LD	(REGAFX),HL
	LD	(REGIX),IX
	LD	(REGIY),IY
	POP	HL
	DEC	HL
	LD	(REGPC),HL
	LD	(REGSP),SP

; check bp and trace operation

	LD	SP,STACKM	; reset SP for monitor
	xor	a
	ld	d, a
	ld	e, a		;clear msg pointer


; check go, end operation
	ld	a, (tmpb_f)
	or	a
	jr	z, tp_chk1
	ld	de, stpBrk_msg
	ld	hl, tmpb_op
	call	rstr_tpt

; check trace operation
tp_chk1:
	ld	a, (tpt1_f)
	or	a
	jr	z, tp_chk2
	ld	de, trace_msg
	ld	hl, tpt1_op
	call	rstr_tpt

tp_chk2:
	ld	a, (tpt2_f)
	or	a
	jr	z, chk_bp

	ld	de, trace_msg
	ld	hl, tpt2_op
	call	rstr_tpt

; check set break point

chk_bp:
	ld	a, (bpt2_f)
	or	a
	jr	z, bp_chk1
	ld	de, stpBrk_msg
	ld	hl, bpt2_op
	call	rstr_bpt

bp_chk1:
	ld	a, (bpt1_f)
	or	a
	jr	z, bp_chk_end
	ld	de, stpBrk_msg
	ld	hl, bpt1_op
	call	rstr_bpt

bp_chk_end:
	ld	a, d
	or	e
	jr	nz, no_rst38_msg

	; set RST 38H message
	LD	de,RST38MSG

no_rst38_msg:
	ld	a, (de)		; get first char of message
	cp	'T'		; trace ?
	jr	z, chk_ntrace
	
	ex	de, hl
	CALL	STROUT

	;; R register adjustment

	CALL	RDUMP
	jr	backTomon	; goto WBOOT

;
; check continue trace operation
;
chk_ntrace:
	ld	a, (TP_mode)
	cp	'F'		; chk
	jr	z, skp_rmsg

;no_trace:
	ex	de, hl
	CALL	STROUT

	;; R register adjustment

	CALL	RDUMP

skp_rmsg:
	call	CONST
	jr	z, t_no_ky		; no key in
	call	CONIN
	cp	03h	; chk CTL+C
	jr	nz, t_no_ky

	; stop_trace
backTomon:
	xor	a
	ld	(fever_t), a	; clear forever flag
	ld	h, a
	ld	l, a
	ld	(TC_cnt), hl
	JP	WSTART
	
	; check trace forever
t_no_ky:
	ld	a, (fever_t)
	or	a
	jp	nz, repeat_trace

	ld	hl, (TC_cnt)
	dec	hl
	ld	(TC_cnt), hl
	ld	a, l
	or	h
	jr	nz, repeat_trace
	JP	WSTART

repeat_trace:
	ld	hl, (REGPC)
	ld	(tmpT), hl
	jp	t_op_chk

rstr_tpt:	; HL=buffer point
	push	hl
	ld	a, (hl)
	inc	hl
	ld	c, (hl)
	inc	hl
	ld	b, (hl)

	ld	(bc), a		; restor OP CODE
	pop	hl
	xor	a
	dec	hl
	ld	(hl), a		; clear trace flag
	ret

rstr_bpt:	; HL=buffer point
	ld	a, (hl)
	inc	hl
	ld	c, (hl)
	inc	hl
	ld	b, (hl)

	ld	(bc), a		; restor OP CODE
	ret

RST38MSG:
	DB	"RST 38H",CR,LF,00H
stpBrk_msg:	
	db	"Break!",CR,LF,00H
trace_msg:	
	db	"Trace!",CR,LF,00H

	IF RAM12K
STOPW:
	; (input) A = 0 : start timer, (output) none
	; (input) A = 1 : stop timer,  (output) BC : msec time, DE : Sec time
	; (input) A = 2 : lap timer,   (output) BC : msec time, DE : Sec time
	; (input) A = 3 : clear timer counter,  (output) none

	push	af
	push	hl
	cp	0
	jr	z, start_tim
	cp	1
	jr	z, stop_tim
	cp	2
	jr	z, lap_tim
	cp	3
	jr	z, clr_tim
	pop	hl
	pop	af
	ret

start_tim:
	ld	hl, TIM0_CTL0
	ld	a, 90h
	ld	(hl),a		; enable timer 0
	pop	hl
	pop	af
	ret
	
stop_tim:
	ld	hl, TIM0_CTL0
	ld	a, 10h
	ld	(hl), a		; disable timer 0

	; save timer counter

lap_tim:
	ld	a, (TIMER0_CNTL)
	ld	(c16b), a
	ld	a, (TIMER0_CNTH)
	ld	(c16b+1), a

; adjust 16bit counter

	ld	bc, TIMER0_INITC
	ld	hl, (c16b)
	ld	a, h
	or	l	; HL = 0?
	jr	nz, adj_tim1
	ld	(c16b), bc
	jr	rd_sec

adj_tim1:
	sbc	hl, bc
	ld	(c16b), hl

; read seconds counter

rd_sec:
	ld	a, (TIMER0_SCTL)
	ld	(secb), a
	ld	a, (TIMER0_SCTH)
	ld	(secb+1), a

	; convert msec from 16bit counter

	ld	hl,(c16b)
	call	chg_msec	; result BC
	ld	(msecb),bc	; save result
	ld	de,(secb)	; get sec counter
	pop	hl
	pop	af
	ret

clr_tim:
	xor	a
	ld	h, a
	ld	l, a
	ld	(msecb), hl
	ld	(secb), hl
	ld	(c16b), hl
	
	ld	(TIMER0_SCTL), a
	ld	(TIMER0_SCTH), a
	ld	a, 0e8h
	ld	(TIMER0_CNTL), a
	ld	a, 86H
	ld	(TIMER0_CNTH), a
	pop	hl
	pop	af
	ret

chg_msec:
	xor	a
	ld	b, a
	ld	c ,a		;cear BC
	ld	hl, (c16b)	; get 16bit counter
	ld	a, l
u_00:
	cp	31
	jr	c, u_1
	sub	31
u_0:
	ld	l, a
	inc	bc
	jr	u_00

u_1:
	ld	a, h
	or	a
	ret	z	; can't sub

	ld	a, l
	sub	31
	neg
	dec	h
	jr	u_0

	ENDIF

;
; make decimal string
;
; input HL : output string buffer
;       DE : 16bit binary
;
; output (HL) : decimal strings

DEC_STR:
	PUSH	AF
	PUSH	BC
	PUSH	DE
	push	hl
	push	ix

	push	hl
	pop	ix		; ix: save buffer top address

	ex	de, hl		; hl: 16bit binary, de: buffer
	push	hl		; save 16bit binary
	ld	hl, 5
	add	hl, de		; hl = buffer + 5
	xor	a
	ld	(hl), A
	ex	de, hl		; de: buffer + 5, hl : buffer
	pop	hl		; hl : 16bit binary
	LD	BC, 1

LOOP_DEC:
	LD	A, 10
	CALL	DIV16_8
	OR	30H
	DEC	DE
	LD	(DE), A
	INC	C
	LD	A, H
	OR	L
	JR	NZ, LOOP_DEC

	LD	A, C
	CP	6
	JR	Z, END_DEC

	push	ix
	pop	hl		; hl : buffer top address
	EX	DE, HL
	LDIR

END_DEC:
	pop	ix
	pop	hl
	POP	DE
	POP	BC
	POP	AF
	RET


; DIV 16bit / 8 bit
; input
;	HL, A
; output
;	result = HL, mod = A

DIV16_8:
	PUSH	BC
	PUSH	DE

	LD	C, A
	LD	B, 15
	XOR	A
	ADD	HL, HL
	RLA
	SUB	C
	JR	C, D16_MINUS_BEFORE
	ADD	HL, HL
	INC	L

D16_PLUS:
	RLA
	SUB	C
	JR	C, D16_MINUS_AFTER

D16_PLUS_AFTER:
	ADD	HL, HL
	INC	L
	DJNZ	D16_PLUS
	JP	D16_END

D16_MINUS_BEFORE:
	ADD	HL, HL

D16_MINUS:
	RLA
	ADD	A, C
	JR	C, D16_PLUS_AFTER

D16_MINUS_AFTER:
	ADD	HL, HL
	DJNZ	D16_MINUS
	ADD	A,C
D16_END:
	POP	DE
	POP	BC
	RET

;
; input : HL / DE
; output : quotient HL
;	   remainder DE

DIV16:
	LD	(DIV16_NA), HL
	LD	(DIV16_NB), DE

	XOR	A
	LD	(DIV16_NC), A
	LD	(DIV16_NC+1), A
	LD	(DIV16_ND), A
	LD	(DIV16_ND+1), A
	LD	B, 16

DIV16_X2:
	LD	HL, DIV16_NC
	SLA	(HL)
	INC	HL
	RL	(HL)

	LD	HL, DIV16_NA
	SLA	(HL)
	INC	HL
	RL	(HL)
	LD	HL, DIV16_ND
	RL	(HL)
	INC	HL
	RL	(HL)

	LD	HL, (DIV16_NB)
	LD	E, L
	LD	D, H
	LD	HL, (DIV16_ND)
	XOR	A
	SBC	HL, DE
	JR	NC, DIV16_X0
	JR	DIV16_X1

DIV16_X0:
	LD	(DIV16_ND), HL

	LD	A, (DIV16_NC)
	OR	1
	LD	(DIV16_NC), A

DIV16_X1:
	DJNZ	DIV16_X2

	LD	HL,(DIV16_NC)
	LD	DE,(DIV16_ND)
	RET

; 8bit * 8bit : ans = 16bit
; input A , BC
; output HL

MUL_8:
	PUSH	AF
	PUSH	BC
	OR	A	; clear carry
	JR	ST_MUL8

LOOP_M8:
	SLA	C
	RL	B

ST_MUL8:
	RRA
	JR	NC, LOOP_M8
	ADD	HL, BC
	JR	NZ, LOOP_M8
	POP	BC
	POP	AF
	RET
;;;
;;; Messages
;;;

cmd_hlp:	db	"? : Command Help", CR, LF
		db	"D[addr] : Dump Memory [addr]", CR, LF
		db	"S[addr] : Set Memory [addr]", CR, LF
		db	"R[reg] : Set or Dump [reg]", CR, LF
		db	"G[addr][,stop addr] : Go and Stop specified address", CR, LF
		db	"L : Load Hex File", CR, LF
		db	"P[I|S] : Save Hex File (I:Intel, S:Motorola", CR, LF
		db	"#L|Number : Launch program", CR, LF
		db	"B[1|2[,BP addr]] : Set Break Point", CR, LF
		db	"BC[1|2] : Clear Break Point", CR, LF
		db	"T[addr][,steps|-1] : Trace command", CR, LF
		db	"TP[ON|OFF] : Trace Print Mode", CR, LF
		db	"TM[I|S] : Trace Option for CALL", CR, LF, 00h

OPNMSG:
	DB	CR,LF
	db	"EMUZ80 MONITOR Rev.B01",CR,LF
	db	"This monitor is based on unimon.",CR,LF,00H

PROMPT:
	DB	"] ",00H

IHEMSG:
	DB	"Error ihex",CR,LF,00H
SHEMSG:
	DB	"Error srec",CR,LF,00H
ERRMSG:
	DB	"Error",CR,LF,00H

DSEP0:
	DB	" :",00H
DSEP1:
	DB	" : ",00H
IHEXER:
        DB	":00000001FF",CR,LF,00H
SRECER:
        DB	"S9030000FC",CR,LF,00H

	;; Register dump table
RDTAB:	DW	RDSA,   REGAF+1
	DB	1
	DW	RDSBC,  REGBC
	DB	2
	DW	RDSDE,  REGDE
	DB	2
	DW	RDSHL,  REGHL
	DB	2
	DW	RDSF,   REGAF
	DB	1

	DW	RDSIX,  REGIX
	DB	2
	DW	RDSIY,  REGIY
	DB	2

	DW	RDSAX,  REGAFX+1
	DB	1
	DW	RDSBCX, REGBCX
	DB	2
	DW	RDSDEX, REGDEX
	DB	2
	DW	RDSHLX, REGHLX
	DB	2
	DW	RDSFX,  REGAFX
	DB	1

	DW	RDSSP,  REGSP
	DB	2
	DW	RDSPC,  REGPC
	DB	2
	DW	RDSI,   REGI
	DB	1
	DW	RDSR,   REGR
	DB	1

	DW	0000H,  0000H
	DB	0

RDSA:	DB	"A =",00H
RDSBC:	DB	" BC =",00H
RDSDE:	DB	" DE =",00H
RDSHL:	DB	" HL =",00H

RDSF:	DB	" F =",00H

RDSF_H	equ	RDSF >> 8
RDSF_L	equ	RDSF & 0FFh


RDSIX:	DB	" IX=",00H
RDSIY:	DB	" IY=",00H
RDSAX:	DB	CR,LF,"A'=",00H
RDSBCX:	DB	" BC'=",00H
RDSDEX:	DB	" DE'=",00H
RDSHLX:	DB	" HL'=",00H

RDSFX:	DB	" F'=",00H

RDSFX_H	equ	RDSFX >> 8
RDSFX_L	equ	RDSFX & 0FFh

RDSSP:	DB	" SP=",00H
RDSPC:	DB	" PC=",00H
RDSI:	DB	" I=",00H
RDSR:	DB	" R=",00H

RNTAB:
	DB	'A',0FH		; "A?"
	DW	RNTABA,0
	DB	'B',0FH		; "B?"
	DW	RNTABB,0
	DB	'C',0FH		; "C?"
	DW	RNTABC,0
	DB	'D',0FH		; "D?"
	DW	RNTABD,0
	DB	'E',0FH		; "E?"
	DW	RNTABE,0
	DB	'F',0FH		; "F?"
	DW	RNTABF,0
	DB	'H',0FH		; "H?"
	DW	RNTABH,0
	DB	'I',0FH		; "I?"
	DW	RNTABI,0
	DB	'L',0FH		; "L?"
	DW	RNTABL,0
	DB	'P',0FH		; "P?"
	DW	RNTABP,0
	DB	'R',1		; "R"
	DW	REGR,RNR
	DB	'S',0FH		; "S?"
	DW	RNTABS,0

	DB	00H,0		; End mark

RNTABA:
	DB	00H,1		; "A"
	DW	REGAF+1,RNA
	DB	27H,1		; "A'"
;;	DB	'\'',1		; "A'"
	DW	REGAFX+1,RNAX

	DB	00H,0
	
RNTABB:
	DB	00H,1		; "B"
	DW	REGBC+1,RNB
	DB	27H,1		; "B'"
;;	DB	'\'',1		; "B'"
	DW	REGBCX+1,RNBX
	DB	'C',0FH		; "BC?"
	DW	RNTABBC,0

	DB	00H,0		; End mark

RNTABBC:
	DB	00H,2		; "BC"
	DW	REGBC,RNBC
	DB	27H,2		; "BC'"
;;	DB	'\'',2		; "BC'"
	DW	REGBCX,RNBCX

	DB	00H,0
	
RNTABC:
	DB	00H,1		; "C"
	DW	REGBC,RNC
	DB	27H,1		; "C'"
;;	DB	'\'',1		; "C'"
	DW	REGBCX,RNCX

	DB	00H,0
	
RNTABD:
	DB	00H,1		; "D"
	DW	REGDE+1,RND
	DB	27H,1		; "D'"
;;	DB	'\'',1		; "D'"
	DW	REGDEX+1,RNDX
	DB	'E',0FH		; "DE?"
	DW	RNTABDE,0

	DB	00H,0

RNTABDE:
	DB	00H,2		; "DE"
	DW	REGDE,RNDE
	DB	27H,2		; "DE'"
;;	DB	'\'',2		; "DE'"
	DW	REGDEX,RNDEX

	DB	00H,0
	
RNTABE:
	DB	00H,1		; "E"
	DW	REGDE,RNE
	DB	27H,1		; "E'"
;;	DB	'\'',1		; "E'"
	DW	REGDEX,RNEX

	DB	00H,0
	
RNTABF:
	DB	00H,1		; "F"
	DW	REGAF,RNF
	DB	27H,1		; "F'"
;;	DB	'\'',1		; "F'"
	DW	REGAFX,RNFX

	DB	00H,0
	
RNTABH:
	DB	00H,1		; "H"
	DW	REGHL+1,RNH
	DB	27H,1		; "H'"
;;	DB	'\'',1		; "H'"
	DW	REGHLX+1,RNHX
	DB	'L',0FH		; "HL?"
	DW	RNTABHL,0

	DB	00H,0

RNTABHL:
	DB	00H,2		; "HL"
	DW	REGHL,RNHL
	DB	27H,2		; "HL'"
;;	DB	'\'',2		; "HL'"
	DW	REGHLX,RNHLX

	DB	00H,0
	
RNTABL:
	DB	00H,1		; "L"
	DW	REGHL,RNL
	DB	27H,1		; "L'"
;;	DB	'\'',1		; "L'"
	DW	REGHLX,RNLX

	DB	00H,0
	
RNTABI:
	DB	00H,1		; "I"
	DW	REGI,RNI
	DB	'X',2		; "IX"
	DW	REGIX,RNIX
	DB	'Y',2		; "IY"
	DW	REGIY,RNIY
	
	DB	00H,0

RNTABP:
	DB	'C',2		; "PC"
	DW	REGPC,RNPC

	DB	00H,0

RNTABS:
	DB	'P',2		; "SP"
	DW	REGSP,RNSP

	DB	00H,0

RNA:	DB	"A",00H
RNBC:	DB	"BC",00H
RNB:	DB	"B",00H
RNC:	DB	"C",00H
RNDE:	DB	"DE",00H
RND:	DB	"D",00H
RNE:	DB	"E",00H
RNHL:	DB	"HL",00H
RNH:	DB	"H",00H
RNL:	DB	"L",00H
RNF:	DB	"F",00H
RNAX:	DB	"A'",00H
RNBCX:	DB	"BC'",00H
RNBX:	DB	"B'",00H
RNCX:	DB	"C'",00H
RNDEX:	DB	"DE'",00H
RNDX:	DB	"D'",00H
RNEX:	DB	"E'",00H
RNHLX:	DB	"HL'",00H
RNHX:	DB	"H'",00H
RNLX:	DB	"L'",00H
RNFX:	DB	"F'",00H
RNIX:	DB	"IX",00H
RNIY:	DB	"IY",00H
RNSP:	DB	"SP",00H
RNPC:	DB	"PC",00H
RNI:	DB	"I",00H
RNR:	DB	"R",00H

;;;
;;; Cold start for device dependent
;;;
INIT:
	RET

;;;
;;; Console drivers
;;;

CONIN:
	LD	A,(UARTCR)
	BIT	0,A
	JR	Z,CONIN
	LD	A,(UARTDR)
	RET

CONST:
	LD	A,(UARTCR)
	BIT	0,A
	RET

CONOUT:
	PUSH	AF
PCST1:	LD	A,(UARTCR)
	BIT	1,A
	JR	Z,PCST1
	POP	AF
	LD	(UARTDR),A
	RET

	db	BASIC_TOP - $ dup(0ffH)
;	ORG	BASIC_TOP

;;;
;;; RAM area
;;;

	;;
	;; Work Area
	;;
	
	ORG	WORK_B

stealRST08:	ds	2	; hacking RST 08H, set jump address
stealRST10:	ds	2	; hacking RST 10H, set jump address
stealRST18:	ds	2	; hacking RST 18H, set jump address
stealRST20:	ds	2	; hacking RST 20H, set jump address
stealRST28:	ds	2	; hacking RST 28H, set jump address
stealRST30:	ds	2	; hacking RST 30H, set jump address
stealRST38:	ds	2	; hacking RST 38H, set jump address
save_hl:	ds	2

INBUF:	DS	BUFLEN	; Line input buffer
DSADDR:	DS	2	; Dump start address
DEADDR:	DS	2	; Dump end address
DSTATE:	DS	1	; Dump state
GADDR:	DS	2	; Go address
SADDR:	DS	2	; Set address
HEXMOD:	DS	1	; HEX file mode
RECTYP:	DS	1	; Record type
SIZE:	DS	1	; I/O Size 00H,'W','S'

REG_B:	
REGAF:	DS	2
REGBC:	DS	2
REGDE:	DS	2
REGHL:	DS	2
REGAFX:	DS	2		; Register AF'
REGBCX:	DS	2
REGDEX:	DS	2
REGHLX:	DS	2		; Register HL'
REGIX:	DS	2
REGIY:	DS	2
REGSP:	DS	2
REGPC:	DS	2
REGI:	DS	1
REGR:	DS	1
REG_E:

	IF RAM12K
; stop watch timer

c16b:	ds	2	; copy of TIMER0_CNT
secb:	ds	2	; copy of TIMER0_SCTT
msecb:	ds	2
	ENDIF

; DIV 16 /16 buffer
DIV16_NA:	ds	2
DIV16_NB:	ds	2
DIV16_NC:	DS	2
DIV16_ND:	DS	2

; go command temp start address
goTmp:		ds	2

; trace mode switch
TP_mode:	ds	1	; N: display on, F: display off
TM_mode:	ds	1	; 'S':skip call, 'I':trace CALL IN
TC_cnt:		ds	2	; numbers of step
tmpT:		ds	2	; save temp buffer
fever_t:	ds	1	; flag trace forever

; break, trace point work area
dbg_wtop	equ	$
tpt1_f:		ds	1
tpt1_op:	ds	1	; save trace point1 opcode
tpt1_adr:	ds	2
tpt2_f:		ds	1
tpt2_op:	ds	1	; save trace point2 opcode (for branch)
tpt2_adr:	ds	2

; break point work area
bpt1_f:		ds	1
bpt1_op:	ds	1
bpt1_adr:	ds	2
bpt2_f:		ds	1
bpt2_op:	ds	1
bpt2_adr:	ds	2

tmpb_f:		ds	1
tmpb_op:	ds	1
tmpb_adr:	ds	2
dbg_wend	equ	$

F_bit:		ds	F_bitSize+1
	END
