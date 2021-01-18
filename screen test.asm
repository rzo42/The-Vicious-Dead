; ========================================
; Project   : The Vicious Dead Screen Test
; Target    : Commodore VIC 20 (32k Exp.)
; Comments  : cursor up, down, left and right to adjust screeen
; Author    : Ryan Liston
; Date      : Jan. 17, 2020
; ========================================


@=$a000

;initial display settings

row       = 32            ;row-count=32
col       = 26            ;col-count=26
h1        = 5             ;value subtracted from current horizontal
v1        = 12            ;value subtracted from current verticle
sc1       = 0             ;screen value @ 36866 bit 7
sc2       = 224           ;screen value @ 36869 bit 4-7
ch1       = 12            ;character map value bit 0-3 @ 36869
scn       = 0             ;background-colour=0
bdr       = 6             ;border-colour=6
aux       = 8*16          ;aux-colour=8
inv       = 1             ;color invert
bcr       = bdr+(inv*8)+(scn*16)          ;generates col_set value

;screen and charachter registers
hor_set   = 36864          ;bit 0-6 = horizontal screen origin : bit 7 = interlace bit
ver_set   = 36865          ;verticle screen origin
col_set   = 36866          ;bit 7 = part of screen location : bit 0-6 = number of columns
row_set   = 36867          ;bit 7 = part of raster : bit 1-6 = number of rows : bit 0 = character size
scrn_set  = 36869          ;bit 4-7 = part of screen location : bit 0-3 character map location
aux_set   = 36878          ;bit 4-7 = auxillary color : bit 0-3 = sound volume
clr_set   = 36879          ;bit 4-7 = background color : bit 3 = color invert : bit 0-2 = border color

;graphics locations
chmap     = $1000          ;charachter map
scren     = $1800          ;screen
colr      = $9400          ;screen color

;kernal calls
setnam    = $ffbd
setlfs    = $ffba
load      = $ffd5
settim    = $ffdb
rdtim     = $ffde
getin     = $ffe4
scnkey    = $ff9f


;-------------------------------------------------------------------------------

;initial screen setup
setup     lda   hor_set   ; loads current horizontal screen value
          sec
          sbc   #h1       ; subtract h1
          sta   hor_set   ; sets new horizontal value

          lda   ver_set   ; loads current vertical screen value
          sec
          sbc   #v1       ; subtract v1
          sta   ver_set   ; sets new vertical screen value

          lda   #row*2    ;loads nuber of rows*2
          sta   row_set   ;sets numer of rows

          lda   #col      ;loads number of columns
          clc
          adc   #sc1      ;adds bit 7 value (part of screen address)
          sta   col_set   ;sets number of columns

          lda   #bcr      ;loads backround and border colors
          sta   clr_set   ;sts background and border color

          lda   #aux      ;loads auxillary color
          sta   aux_set   ;sets auxillary color

          lda   #sc2+#ch1 ;loads screen and charachter locations
          sta   scrn_set  ;sets screen and charachter locationa

;load grapghic files


set_n     lda   #<cont1   ;set return point  low byte
          sta   $01       
          lda   #>cont1   ;set return point high byte
          sta   $02       
          ldx   #<txt_fl  ;set file name pointer low byte
          ldy   #>txt_fl  ;set file name pointer high byte
          jmp   set_f     

cont1     lda   #<cont2   ;set return point  low byte
          sta   $01       
          lda   #>cont2   ;set return point high byte
          sta   $02       
          ldx   #<scr_fl  ;set file name pointer low byte
          ldy   #>scr_fl  ;set file name pointer high byte
          jmp   set_f     

cont2     lda   #<cont3   ;set return point  low byte
          sta   $01       
          lda   #>cont3   ;set return point high byte
          sta   $02       
          ldx   #<clr_fl  ;set file name pointer low byte
          ldy   #>clr_fl  ;set file name pointer high byte
          jmp   set_f     
;--------------------------------------------------------------------
;manual screen adjust

;key input delay
cont3     lda   #$00      ;sets jiffy clock to 0
          tax
          tay
          jsr   settim    

pause     jsr   rdtim     ;gets current jiffy count
          cmp   #$07      ;compares to 7
          bcc   pause     ;loop if < 7

;retrieves key input and tests for cursor keys
adjust    jsr   scnkey    ;scan keyboard
          jsr   getin     ;get keyboard input
          cmp   #$1d      ;if right
          beq   h_plus    ;branch to horizonal shift right
          cmp   #$9d      ;if left
          beq   h_min     ;branch to horizontal shift left
          cmp   #$91      ;if down
          beq   v_min     ;branch to vertical shift down
          cmp   #$11      ;if up
          beq   v_plus    ;branch to vertical shift up
          jmp   adjust    ;loop in no cursor key is detected

;horozontal shift right
h_plus    lda   hor_set   ;load current horizontal value
          cmp   #$3f      ;compare to 63
          bcs   adjust    ;branc if =>63
          inc   hor_set   ;add 1 to current horozontal screen position
          jmp   cont3     ;jump to key input delay

;horozontal shift left
h_min     lda   hor_set   ;load current horizontal value
          cmp   #$00      ;compare to 0
          beq   adjust    ;branch if =0
          dec   hor_set   ;subtracts 1 from current horizontal value
          jmp   cont3     ;jump to key input delay

;vertical shift down
v_plus    lda   ver_set   ;loads current vertical value
          cmp   #$ff      ;compares to 255
          beq   adjust    ;branch if =255
          inc   ver_set   ;adds 1 to current vertical value
          jmp   cont3     ;jump to key input delay

;vertical shift up
v_min     lda   ver_set   ;loads current vertical value
          cmp   #$00      ;compares to 0
          beq   adjust    ;branch of =0
          dec   ver_set   ;subtracts 1 from current vertical value
          jmp   cont3     ;jump to key input delay

;load routine
set_f     lda   #$02      ;set file name length
          jsr   setnam    ;sets file name
          lda   #$01      ; sets file #
          ldx   #$08      ;sets device
          ldy   #$01      ;set read
          jsr   setlfs    ;set logical file for load
load_f    lda   #$00      ;sets for load
          jsr   load      ; load file
          jmp   ($0001)   




;file names
txt_fl    byte  "t","0" ;text set
scr_fl    byte  "s","0" ;screen dispaly
clr_fl    byte  "c","0" ;screen color