; "Sparks", Atari XL/XE Intro 256B
; code by tr1x
; requirements: original Atari XL/XE 64KB PAL
; version: 1.0
; release date: 2019-12-07

	org $0600

;debug	equ 1		; for graphics preview of sine wave
offset	equ 0		; display list offset, used for preview only

gtia10	equ $80		; graphics 10 (GTIA mode)
memdl1	equ $00cb
memdl2	equ $00cd
memvp1	equ $00cf
delta	equ $00d1
value	equ $00d3
memdbg1	equ $00d5
memdbg2	equ $00d7
gprior	equ $026f
pcolr1	equ $02c1
sinwav	equ $0800
vidptr	equ $4000	; video memory
dlist	equ $9c20	; display list
colpm1	equ $d013
random	equ $d20a
vcount	equ $d40b

	; generate fake sine wave array using parabolas
	ldy #$3f
	ldx #$00	
loopa1	lda value
	adc delta
	sta value
	lda value+1
	adc #$00	; accumulate carry flag
	sta value+1
	sta sinwav+$40,y
	sta sinwav+$80,x
	eor #$3f
	sta sinwav+$00,x
	sta sinwav+$c0,y
	lda delta
	adc #$04
	sta delta
	inx
	dey
	bpl loopa1

	; prepare display list
	ldx #<dlist+3
	stx memdl1
	lda #>dlist
	sta memdl1+1
	ldx #$c0
	iny		; ldy #$00
loopb1	lda #$4f	; ANTIC command: gr.mode | address
	sta (memdl1),y
	inc memdl1
	;bne skipb1	; not needed,
	;inc memdl1+1	; ..since does not occur in practice
skipb1	lda random
	and #%11000000	; $..00, $..40, $..80, $..c0
	sta (memdl1),y
	inc memdl1
	bne skipb2
	inc memdl1+1
skipb2	lda random
	and #%00111111
	;clc		; not needed in practice
	adc #$09
	sta (memdl1),y
	inc memdl1
	bne skipb3
	inc memdl1+1
skipb3	dex
	bne loopb1

	;lda #$41	; jump to the beginning of display list
	;sta dlist+$243	; ..is not necessary
	;lda #<dlist
	;sta dlist+$244
	;lda #>dlist
	;sta dlist+$245

	; set GTIA graphics mode
	lda #gtia10
	sta gprior

	; draw sine wave
	;lda <vidptr	; not needed
	;sta memvp1
	lda >vidptr
	sta memvp1+1
loopc1
opcodc1	lda sinwav
	clc
	adc #$07
	lsr
	tay
opcodc2	ldx #$00
	bcs skipc2
	inx
	inx
skipc2	lda colors,x
	sta (memvp1),y
	inc memvp1
	inx
	lda colors,x
	sta (memvp1),y
	clc
	lda memvp1
	adc #$40-1
	sta memvp1
	bne skipc3
	inc memvp1+1
skipc3	inc opcodc1+1
	bpl skipc4
	lda #$04
	sta opcodc2+1
skipc4	bne loopc1

	; for sine wave preview; not needed for normal operation
.if .def debug
	lda #<dlist+4
	sta memdbg1
	lda #>dlist
	sta memdbg1+1
	lda #<vidptr
	sta memdbg2
	lda #>vidptr+offset
	sta memdbg2+1
	ldx #$c0
	ldy #$00
loopd1	lda memdbg2
	sta (memdbg1),y
	inc memdbg1
	bne skipd1
	inc memdbg1+1
skipd1	lda memdbg2+1
	sta (memdbg1),y
	lda memdbg2
	clc
	adc #$40
	sta memdbg2
	bne skipd2
	inc memdbg2+1
skipd2	inc memdbg1
	bne skipd3
	inc memdbg1+1
skipd3	inc memdbg1
	bne skipd4
	inc memdbg1+1
skipd4	dex
	bne loopd1
	lda #$92
	sta pcolr1
	lda #$94
	sta pcolr1+1
	lda #$98
	sta pcolr1+2
	lda #$9e
	sta pcolr1+3
	jmp *
.endif

	; display list animation
anim	lda #<dlist+4
	sta memdl2
	lda #>dlist
	sta memdl2+1
	ldx #$c0
loope1	lda vcount
	asl
	asl
	asl
	asl
	adc #$02
	sta colpm1
	adc #$02
	sta colpm1+1
	adc #$04
	sta colpm1+2
	adc #$06
	sta colpm1+3
	ldy #$00
	lda (memdl2),y
	clc
	adc #64
	sta (memdl2),y
	bne skipe1
	iny
	lda (memdl2),y
	clc
	adc #1
	bpl skipe2
	lda #>vidptr
skipe2	sta (memdl2),y
skipe1	inc memdl2
	bne skipe3
	inc memdl2+1
skipe3	inc memdl2
	bne skipe4
	inc memdl2+1
skipe4	inc memdl2
	;bne skipe5	; not needed,
	;inc memdl2+1	; ..since does not occur in practice
skipe5	dex
	bne loope1
	bpl anim	; 1 byte less than "jmp anim"

colors	.byte $02, $11, $21, $10	; dark
	.byte $02, $34, $23, $40	; bright
