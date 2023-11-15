;******************************************************************************
;*                      RS232C接收程式 ( PC --> 8051 )                        *
;*                                                                            *
;*    1. crystal : 12MHZ                                                      *
;*    2. Under Test !!!                                                       *
;*    3. DATE: 2004.  2. 16                                                   *
;*    4. Baud rate : 4800 bps                                                 *
;*    5. 將接收程式寫入外部 RAM 中.                                           *
;*    6. 手動版 !!!                                                           *
;*                                                                            *
;******************************************************************************
;┌─────────────┐
;│  以下設定各變數位置.     │
;└─────────────┘
lengthh         equ     21h             ; ┐ 工作變數,常數群.
lengthl         equ     22h             ; ┘

;┌─────────────┐
;│    設定各中斷向量位址    │
;└─────────────┘
        org     00h
        jmp     start

;┌─────────────┐
;│       初始化設定         │
;│1.Set stack pointer.      │
;│2.Set timer's mode.       │
;│3.Set interrupt disable.  │
;│4.Set register bank.      │
;└─────────────┘
start:
        mov     sp,#30h
        mov     psw,#00000000b
        mov     ie,#00000000b                   ; Disable all interrupt.
        mov     scon,#01010000b                 ; 規劃串列埠為模式1.
        mov     tmod,#00100000b                 ; 鮑率由Timer1設定(auto reload)
        orl     pcon,#10000000b                 ; pcon.7(smod) = 1.
        mov     th1,#0f3h                       ; Baud rate = 4800.
        setb    tr1

;┌─────────────┐
;│       主程式部份         │
;└─────────────┘
wait:   jnb     ri,$                            ; ┐
        clr     ri                              ; ├ 等待傳送開始.
        mov     a,sbuf                          ; ├ 等待字元 P.
        cjne    a,#'P',wait                     ; ┘

        jnb     ri,$                            ; ┐
        clr     ri                              ; ├ 接收資料長度之High byte.
        mov     a,sbuf                          ; │
        mov     lengthh,a                       ; ┘

        jnb     ri,$                            ; ┐
        clr     ri                              ; ├ 接收資料長度之Low byte.
        mov     a,sbuf                          ; │
        mov     lengthl,a                       ; ┘
        jnz     go
        dec     lengthh

go:     mov     dptr,#0000h
loop:   jnb     ri,$
        clr     ri
        mov     a,sbuf
        movx    @dptr,a
        inc     dptr

handshk:
        mov     a,#'Z'
        mov     sbuf,a
        jnb     ti,$
        clr     ti

        djnz    lengthl,loop
        mov     a,lengthh
        jz      ok
        dec     lengthh
        jmp     loop
ok:     jmp     ok
        end
