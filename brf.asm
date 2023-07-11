; Brf! An Atari 2600 barking dog simulator
; by Tim Heiderich tim@timtoon.com
; 2016/10/22
; How many times can you bark before your annoyed owners have you put to sleep? 🐶💀

; TODO --------------------------
; * Add a score counter
; * Figure out how the annoyance meter works (X barks per Y time, filling in a byte...?)
; * Make a Chinese crested mod

	processor 6502
	include "vcs.h"
	include "macro.h"

;------------------------------------------------------------------------------

	SEG.U vars	; the label "vars" will appear in our symbol table's segment list

	ORG $80		; start of RAM

Variable ds 1  ; a 1-byte variable (ds = define size in bytes)

; RAM locations ($80-$FF)

timer ds 1
current_note ds 1
bark ds 1
sky_color ds 1

cooldown ds 1
tension ds 1

score0	ds 1
score1	ds 1
score2	ds 1
score3	ds 1
score4	ds 1
score5	ds 1

volume ds 1

; Colors --

ear		= $20
face	= $2D
muzzle	= $0E
tongue	= $42
nose	= $00
sky		= $AB
grass	= $C4

cooldown_timer = #127	; 127 is the highest number, boss.

;------------------------------------------------------------------------------

    SEG			; end of uninitialised segment - start of ROM binary
	ORG $F000

Reset

   ; Clear RAM and all TIA registers

	ldx #0
	lda #0

Clear
	sta 0,x
	inx
	bne Clear

	;------------------------------------------------
	; Once-only initialisation...

	lda %00000001
	sta CTRLPF

	lda #0				; init to 0
	sta timer
	sta current_note
	sta bark

	lda cooldown_timer		; 120 frames, about 4 seconds
	sta cooldown

	lda #60
	sta volume			; set volume countdown timer

	lda #sky			; set sky_color to #sky
	sta sky_color

	lda sky
	sta COLUBK			; set the playfield BG colour to lt.blue

StartOfFrame

; Check whether the button had been pressed
	lda INPT4				; 3
	bmi ButtonNotPressed	; 3

	; do something here because the button *is* pressed
	; set `bark` to a non-zero value flag (ie #%10000000)
	lda #1				; 2
	sta bark			; 3
	inc score0			; not using this now. Scoring is a whole other "feature"
						; if AND score0 #10, bne add_score
						; inc score1
						; score0 = 0

ButtonNotPressed

; Steal some cycles from VBlank to do the audio processing
	lda bark			; 3
	cmp #1				; 2
	bne skip_bark		; 3

	inc timer			; 5
	lda timer			; 3

	cmp #2				; 2 this is the number of frames a note plays
	bne timer_add		; 3 skip resetting the timer if A != 15 [the double negatives!!]

	; otherwise, reset the timer and increment `current_note`
	lda #0				; 2
	sta timer			; 3 reset `timer`
	inc current_note	; 5 once `timer` flips past # of frames, increment current_note
	lda current_note	; 3 set A to current_note
	and #15				; 2 A is not to exceed 15. AND works like modulo ex: "AND #4"= A%4
	sta current_note	; 3 nor is current_note.

timer_add
	ldy current_note	; 3 a value from 0-15 (ideally)

; do your dog bark here

	lda bark_vol,y		; 4
	sta AUDV0			; 3

	lda bark_type		; 3
	sta AUDC0			; 3

	lda bark_pitch,y	; 4
	sta AUDF0			; 3

skip_bark

	lda current_note	; 4
	cmp #15
	bne keep_barking	; 3 exit if this is the 16th/0th note in current_note
	
; Reset `bark` to 0 if `current_note` > 15 (`AND #15` should reset current_note to 0)
	lda #0				; 2
	sta bark			; 3
	sta current_note	; 3

keep_barking

	lda #sky			; 3
	sta sky_color
	sta COLUBK			; 3 set the playfield BG colour to lt blue

	sta WSYNC

;------------------------------------------------
; Actual picture stuff!
;------------------------------------------------

   ; Start of vertical blank processing
   ; You actually have about 38 cycles to do stuff here...

	lda #2
	sta VSYNC

	sta WSYNC
	sta WSYNC
	sta WSYNC	; 3 scanlines of VSYNC signal

	;------------------------------------------------
	; 37 scanlines of vertical blank...
    ; LOTS of space up here for processing, too.

	ldx #0
	stx VSYNC

	ldx	#37				; Count down VBlank scanlines (normally 37)

; You really should put your bark logic here since you have 228x37 cycles doing nothing
VerticalBlank
	sta WSYNC
	dex					; Count down from 37 to 0
	bne VerticalBlank

	stx VBLANK	; x=0, turning VBLANK off -- this is only useful for VBLANK section at top


Line0
	ldx #12

Line0Loop
	sta WSYNC
	dex
	bne Line0Loop


Line1
	ldx #12
	ldy #ear
	sty COLUPF

	lda #%00000000
	sta PF1
	lda #%00011100
	sta PF2

Line1Loop
	sta WSYNC
	dex
	bne Line1Loop


Line2
	ldx #12

Line2Loop
	sta WSYNC

	ldy #ear
	sty COLUPF

	lda #%11111110
	sta PF2

	sleep 28

	ldy #face
	sty COLUPF

	sleep 8

	ldy #ear
	sty COLUPF

	dex
	bne Line2Loop


Line3
	ldx #12
	ldy #ear
	sty COLUPF

	lda #%11111111
	sta PF2

Line3Loop
	sta WSYNC

	sleep 32

	ldy #ear
	sty COLUPF

	ldy #face
	sty COLUPF

	sleep 10

	ldy #ear
	sty COLUPF

	dex
	bne Line3Loop


Line4
	ldx #12
	lda #%11111111
	sta PF2

Line4Loop
	sta WSYNC

	sleep 32

	ldy #ear
	sty COLUPF

	ldy #face
	sty COLUPF

	sleep 10

	ldy #ear
	sty COLUPF

	dex
	bne Line4Loop


Line5
	ldx #12
	lda #%00000001
	sta PF1
	lda #%11111111
	sta PF2

Line5Loop
	sta WSYNC

	sleep 32

	ldy #ear
	sty COLUPF

	ldy #nose	; eye
	sty COLUPF

	ldy #face
	sty COLUPF

	ldy #nose	; eye
	sty COLUPF

	ldy #ear
	sty COLUPF

	dex
	bne Line5Loop


Line6

	lda #%00000011
	sta PF1
	lda #%11111111
	sta PF2

	ldx #12				; 3

	; branch if bark is 0, otherwise continue
	; This part creates a 1-scanline high line I can't fix now
;	ldy bark			; 3 
;	bne Line6BarkLoop	; 3	if bark is 0, branch to LineLoop
;	jmp Line6Loop		; 3 otherwise jump to the BarkLoop
						; = 21 cycles

Line6Loop
	sta WSYNC

	sleep 28

	ldy #ear
	sty COLUPF

	sleep 4

	ldy #nose	; Eye
	sty COLUPF

	ldy #face
	sty COLUPF

	ldy #nose	; Eye
	sty COLUPF

	ldy #ear
	sty COLUPF

	dex
	bne Line6Loop
	jmp Line7		; jump to the next LineX+1 label and skip LineXBarkLoop

Line6BarkLoop
	sta WSYNC

	sleep 28

	ldy #ear
	sty COLUPF

	sleep 4

	ldy #face
	sty COLUPF

	sleep 10

	ldy #ear
	sty COLUPF

	dex
	bne Line6BarkLoop


Line7
	ldx #12
	lda #%00000010
	sta PF1
	lda #%11111100
	sta PF2

Line7Loop
	sta WSYNC

	sleep 28

	ldy #ear
	sty COLUPF

	ldy #face
	sty COLUPF

	sleep 16

	ldy #ear
	sty COLUPF

	dex
	bne Line7Loop


Line8
	ldx #14
	ldy #face
	sty COLUPF
	lda #%00000000
	sta PF1
	lda #%11111100
	sta PF2

Line8Loop
	dex
	bne Line8Loop


Line9
	ldx #12

	ldy bark
	bne Line9BarkLoop
	jmp Line9Loop

Line9Loop
	sta WSYNC

	ldy #muzzle
	sty COLUPF

	dex
	bne Line9Loop
	jmp LineA

Line9BarkLoop
	sta WSYNC

	ldy #muzzle
	sty COLUPF

	sleep 37

	ldy #nose
	sty COLUPF

	ldy #muzzle
	sty COLUPF

	dex
	bne Line9BarkLoop


LineA
	ldx #12

LineALoop
	sta WSYNC

	lda #grass
	sta sky_color	; tried a better way to save COLUBK to sky_color, but it didn't work
	sta COLUBK		; set the playfield BG colour to grass

	ldy #muzzle
	sty COLUPF

	lda #%11111100
	sta PF2

	sleep 24

	ldy #nose
	sty COLUPF

	ldy #muzzle
	sty COLUPF

	dex
	bne LineALoop


LineB
	ldx #12

	ldy bark
	bne LineBBarkLoop
	jmp LineBLoop

LineBLoop
	sta WSYNC

	ldy #muzzle
	sty COLUPF

	lda #%11111110
	sta PF2

	sleep 32

	ldy #nose
	sty COLUPF

	ldy #muzzle
	sty COLUPF

	dex
	bne LineBLoop
	jmp LineC

LineBBarkLoop
	sta WSYNC

	ldy #muzzle
	sty COLUPF

	lda #%11111110
	sta PF2

	dex
	bne LineBBarkLoop


LineC
	ldx #12

	ldy bark
	bne LineCBarkLoop
	jmp LineCLoop

LineCLoop
	sta WSYNC

	lda #%11111100
	sta PF2

	dex
	bne LineCLoop
	jmp LineD

LineCBarkLoop
	sta WSYNC

	ldy #muzzle
	sty COLUPF

	lda #%11111100
	sta PF2

	sleep 30

	ldy #tongue
	sty COLUPF

	sleep 4

	ldy #muzzle
	sty COLUPF

	dex
	bne LineCBarkLoop


LineD
	ldx #12

	ldy bark
	bne LineDBarkLoop
	jmp LineDLoop

LineDLoop
	sta WSYNC

	ldy #muzzle
	sty COLUPF

	lda #%11111000
	sta PF2

	sleep 32

	ldy #tongue
	sty COLUPF

	ldy #muzzle
	sty COLUPF

	dex
	bne LineDLoop
	jmp LineE

LineDBarkLoop
	sta WSYNC

	ldy #muzzle
	sty COLUPF

	lda #%11111000
	sta PF2

	sleep 30

	ldy #tongue
	sty COLUPF

	sleep 4

	ldy #muzzle
	sty COLUPF

	dex
	bne LineDBarkLoop


LineE
	ldx #12

LineELoop
	sta WSYNC
	lda #%11110000
	sta PF2

	sleep 40

	dex
	bne LineELoop


LineF
	ldx #12
	lda #%00000000		; clear playfield
	sta PF2

LineFLoop
	sta WSYNC
	dex
	bne LineFLoop


;------------------------------------------------

  
	lda #%01000010
	sta VBLANK   	; end of screen - enter blanking. Turn on registers 6,1 in TIA

	; 30 scanlines of overscan...
	; do extra non-graphic processing here

	ldx #0

Overscan
	sta WSYNC
	inx
	cpx #30
	bne Overscan

; this would ideally go in the Overscan, but we're not worrying about cycles now
	lda bark				; set A=bark
	beq no_bark				; if A!=0, jump to no_bark, otherwise continue

	lda current_note		; what's the current note?
	cmp #1					; is it 1?
	bne you_barked			; it's not? then just skip to the end

							; this is where the actual stuff happens

	lda cooldown			; what is the current cooldown value?
	cmp #0					; is it greater than zero?
	beq you_barked			; branch if it's zero and skip the rewards that follow
	rol tension				; if not zero, it gets worse - you just increased tension 2x!

	inc tension				; increase tension by +1
	lda tension
	clc						; clear the carry flag, we don't want a false positive
	adc #02					; 1 is too low and 2 is too high, because 01 is 1 and 10 is 2.
	bcc jmpGameOver			; If Carry is clear, branch - otherwise jmp GameOver.
	jmp GameOver			; jmp to GameOver if Carry is set
jmpGameOver					; Otherwise jump to after the jmp to GameOver (...huh?)

	lda #cooldown_timer		; reset the cooldown period to 120 frames
	sta cooldown

no_bark						; dog is not in the process of barking 
	lda cooldown
	bne cool_down			; branch if A=0
	ror tension				; Congrats, your cooldown has reached 0! Reduce tension.

cool_down
	lda cooldown			; what is the current cooldown value?
	bpl dec_cool_down		; if it's non-zero then decrement, otherwise
	lda cooldown_timer		; reset A with max counter_timer
	sta cooldown			; and store A in cooldown

dec_cool_down
	dec cooldown			; if cooldown is a non-sero number, decrement it

you_barked	; nothing happens here. This is just to skip the no_bark reward step

	jmp StartOfFrame


;------------------------------------------------
; GAME OVER
;------------------------------------------------
; create a whole new screen here. I don't know whether this is necessary, but I assume so.
; This is a reuse of the screen writing code -- rather than create a loop within the main StartOfFrame loop.
; Show the dog skull and set the BG to grey and red

GameOver

   ; Start of new frame
   ; Start of vertical blank processing
   ; You actually have about 38 cycles to do stuff here...

	; decrease volume to 0
	lda volume
	bmi skip_volume
	dec volume
	cmp #5
	bpl skip_volume		; start decreasing volume when it gets down to 15
	sta AUDV0

skip_volume

	lda #2
	sta VSYNC

	sta WSYNC
	sta WSYNC
	sta WSYNC	; 3 scanlines of VSYNC signal


	;------------------------------------------------
	; 37 scanlines of vertical blank...
    ; LOTS of space up here for processing, too.
    ;
    ; A good place to perform the bit operations checking whether you've barked too much

	ldx #0
	stx VSYNC

	ldx	#36				; last scanline

GOVerticalBlank
	sta WSYNC
	dex					; Count down from 37 to 0
	bne GOVerticalBlank

	stx VBLANK	; x=0, turning VBLANK off -- this is only useful for VBLANK section at top

	ldx #15
	lda #2

	lda #$00	; formerly #$40 (mauve)
	sta COLUBK

	; set the default dog color. This is temporary
	ldy #muzzle
	sty COLUPF

GOPicture

	ldy #12		; reset Y to 12 for every new pixel row

	; set playfield with X value
	; since we're counting X DOWN from 16, DOG needs to be UPSIDE-DOWN!
	lda dogPF1,x
	sta PF1
	
	lda dogPF2,x
	sta PF2

loop
	; draw the line again and again, until
	dey
	sta WSYNC	; start a new line here

	bne loop

next_row

	dex
	bne GOPicture
  
	lda #%01000010
	sta VBLANK   	; end of screen - enter blanking. Turn on registers 6,1 in TIA

	; 30 scanlines of overscan...
	; do extra non-graphic processing here

	ldx #0

GOOverscan
	sta WSYNC
	inx
	cpx #30
	bne GOOverscan

	jmp GameOver

;------------------------------------------------------------------------------
; I should figure out some logic, considering how many barks can happen at a time.
; Like a counter, counting down from one second, or something.
; Or several counters, like a 1-second, 5-second, and 1-minute one, and if you fill all them up, then jmp GameOver where the dog's eyes are X's -- which I don't think I can do.
; Maybe I can make the tongue loll off-center and turn the sky red and the ground grey.
; That's a bit dark, eh?
; OK, so there needs to be a timer where rol reduces the timer to zero, while IF you bark, your score is incremented by the current bit. So if you bark 8 times in a row, you die(!). If you bark once every eight seconds, you're... OK? 
; Once the C (carry) flag is set, game over.

;------------------------------------------------------------------------------

bark_type
	.byte $07
bark_pitch
	.byte 11,11,12,13,14,15,16,17,18,19,19,20,20,21,21
bark_vol
	.byte 15,15,15,15,15,15,15,15,15,15,10,9,5,3,1,0

dogPF1
		.byte #%00000000	;F|        |
		.byte #%00000000	;E|        |
		.byte #%00000000	;D|        |
		.byte #%00000000	;C|        |
		.byte #%00000000	;B|        |
		.byte #%00000000	;A|        |
		.byte #%00000000	;8|        |
		.byte #%00000000	;7|        |
		.byte #%00000010	;6|      X |
		.byte #%00000011	;5|      XX|
		.byte #%00000001	;4|       X|
		.byte #%00000000	;3|        |
		.byte #%00000000	;3|        |
		.byte #%00000000	;2|        |
		.byte #%00000000	;1|        |
		.byte #%00000000	;0|        |

dogPF2
		.byte #%00000000	;0|        |
		.byte #%00000000	;F|        |
		.byte #%11110000	;E|XXXX    |
		.byte #%01011000	;D| X XX   |
		.byte #%10101100	;C|X X XX  |
		.byte #%11111110	;B|XXXXXXX |
		.byte #%01111100	;A| XXXXX  |
		.byte #%01111000	;A| XXXXX  |
		.byte #%11010100	;7|XX X X  |
		.byte #%11101110	;6|XXX XXX |
		.byte #%11010111	;5|XX X XXX|
		.byte #%11111111	;4|XXXXXXXX|
		.byte #%11111111	;3|XXXXXXXX|
		.byte #%11111110	;2|XXXXXXX |
		.byte #%00011100	;1|   XXX  |
		.byte #%00000000	;0|        |

;------------------------------------------------------------------------------

    ORG $FFFA

InterruptVectors

            .word Reset   	; NMI
            .word Reset   	; RESET
            .word Reset   	; IRQ

	END