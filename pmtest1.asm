;; pmtest1.asm
%include    "pm.inc"    ;define a lot of macro 
org     0100h
        jmp LABEL_BEGIN

        [SECTION .gdt]
        ;; GDT
        ;;                        段基址   段界限               属性
LABEL_GDT:        Descriptor      0,       0,                   0   ; 空描述符
LABEL_DESC_CODE32:Descriptor      0,       SegCode32Len-1,      DA_C + DA_32 ; 非一致性代码
LABEL_DESC_VIDEO: Descriptor      0B8000h, 0ffffh,              DA_DRW  ;显存首地址
        ;; GDT 结束
        
GdtLen      equ     $ - LABEL_GDT ; GDT length
GdtPtr      dw      GdtLen - 1    ; GDT boundaries
            dd      0             ; GDT base address
        ;; GDT selector

SelectorCode32      equ     LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo       equ     LABEL_DESC_VIDEO - LABEL_GDT
        ;;  end of [ SECTION .gdt]

[SECTION .S16]                  ;
[BITS   16]
LABEL_BEGIN:
        mov     ax, cs
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, 0100h

        ;; initial the 32-bites code segment descriptor
        xor     eax,    eax
        mov     ax,     cs
        shl     eax,    4       ;move to left by 4 bites
        add     eax,    LABEL_SEG_CODE32
        mov     word    [LABEL_DESC_CODE32 + 2],    ax
        shr     eax,    16
        mov     byte    [LABEL_DESC_CODE32 + 4],    al
        mov     byte    [LABEL_DESC_CODE32 + 7],    ah

        ;; ready to load the gdtr
        xor eax,    eax
        mov ax,     ds
        shl eax,    4
        add eax,    LABEL_GDT
        mov dword   [GdtPtr + 2],   eax ; [GdtPtr + 2] <- gdt 基地址
        ;; laod the GDTR
        lgdt    [GdtPtr]

        ;; close the interrupt
        cli
        ;; open the address A20
        in  al,     92h
        or  al,     00000010b
        out 92h,    al

        ;; ready to switch the protected mode
        mov eax,    cr0
        or  eax,    1
        mov cr0,    eax

        ;; come in  protect mode
        jmp dword   SelectorCode32:0 ;loading the SelectorCode32 in the cs

        ;; End of [sectopm .s16]

        [SECTION .s32]          ; 32-bites code segement
        [BITS 32]

LABEL_SEG_CODE32:
        mov ax, SelectorVideo        ;
        mov gs, ax

        mov edi,(80*11+79)*2         ;row 11 and column 79 in the scrren
        mov ah, 0ch                  ; 0000 : black backgroud, 1100 : red 
        mov al, 'p'
        mov [gs:edi],   ax

        ;; deadloop
        jmp $

        SegCode32Len   equ  $ - LABEL_SEG_CODE32
        ;; end the section 32