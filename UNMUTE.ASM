; Unmute - PCBEEP to headphone written by TomCat/Abaddon
; the PMODE init code comes from FASMD by Tomasz Grysztar

INCLUDE 'DOSDPMI\DPMIHEAD.INC'

 MOV    EDX,_welcome
 CALL   print_str

 MOV    DWORD [volume],1FH
 MOV    ESI,80H
 SUB    EAX,EAX
 SUB    ECX,ECX
 MOV    CL,[ES:SI]
 JECXZ  vol_ok
 INC    ESI
.1:
 MOV    AL,[ES:ESI]
 SUB    AL,'0'
 JC     .3
 CMP    AL,9
 JA     .3
 INC    ESI
 MOV    EDX,EAX
 MOV    AL,[ES:ESI]
 SUB    AL,'0'
 JC     .2
 CMP    AL,9
 JA     .2
 IMUL   EDX,EDX,10
 ADD    EDX,EAX
.2:
 MOV    EAX,1FH
 MUL    EDX
 MOV    EBX,96
 DIV    EBX
 MOV    [volume],EAX
 JMP    vol_ok
.3:
 INC    ESI
 LOOP   .1
vol_ok:

 MOV    EAX,[volume]
 MOV    CL,3
 CALL   print_num_eol

 MOV    WORD [azbar_selector],0 ; selector=0
 MOV    EDI,80000000H
main_pci:
 MOV    BL,0                    ; read Vendor/Device ID
 CALL   read_pci
 CMP    EAX,-1                  ; PCI device?
 JZ     next_pci                ; -1:no
 XCHG   ESI,EAX
 MOV    BL,8                    ; read Revision+Class
 CALL   read_pci
 BSWAP  EAX                     ; HD audio device?
 CMP    AX,0304H                ; Class:04H, Sub-Class:03H
 JNE    next_pci
 MOV    BL,10H                  ; AZBAR
 CALL   read_pci
 AND    AL,0F9H
 PUSHA
 CALL   hda_found
 POPA
next_pci:
 ADD    EDI,100H
 CMP    EDI,80FFF800H
 JNE    main_pci

 CMP    WORD [azbar_selector],0 ; HDA device found?
 JNE    @F

 MOV    EDX,_no_hda
 CALL   print_str

@@:
 MOV    AX,4C0FH
 INT    21H

read_pci:
 MOV    EAX,EDI                 ; in EDI:base address
 MOV    AL,BL                   ; in BL:register offset
 MOV    DX,0CF8H                ; PCI_INDEX_PORT
 OUT    DX,EAX
 MOV    DX,0CFCH                ; PCI_DATA_PORT
 IN     EAX,DX                  ; out EAX:register value
RETN

;-------------------------------------------------------
hda_found:
 XCHG   EDI,EAX

 MOV    EDX,_dev_ok
 CALL   print_str
 MOV    EAX,ESI
 SHR    EAX,16
 MOV    CL,4
 CALL   print_num
 MOV    EDX,_vendor
 CALL   print_str
 XCHG   EAX,ESI
 MOV    CL,4
 CALL   print_num_eol

 MOV    EDX,_io_ok
 CALL   print_str
 MOV    EAX,EDI
 MOV    CL,8
 CALL   print_num

 MOV    ECX,EDI
 MOV    EBX,EDI
 SHR    EBX,16
 MOV    EDI,16*1024             ; HDAIOLEN
 SUB    ESI,ESI
 MOV    AX,800H                 ; Physical Address Mapping
 INT    31H                     ; BX:CX - linear address
 JNC    lin_addr_ok

 MOV    EDX,_map_fail
 CALL   print_str
 RETN

lin_addr_ok:
 SHL    EBX,16
 MOV    BX,CX
 MOV    [linear_address],EBX

 MOV    EDX,_io_mapped
 CALL   print_str
 MOV    EAX,[linear_address]
 MOV    CL,8
 CALL   print_num

 MOV    ECX,[linear_address]
 MOV    EBX,ECX
 SHR    EBX,16
 MOV    EDI,16*1024             ; HDAIOLEN
 SUB    ESI,ESI
 MOV    AX,600H                 ; Lock Linear Region
 INT    31H
 JNC    lock_region_ok

 MOV    EDX,_lock_fail
 CALL   print_str
 MOV    ECX,[linear_address]
 MOV    EBX,ECX
 SHR    EBX,16
 MOV    AX,801H                 ; Free Physical Address Mapping
 INT    31H
 RETN

lock_region_ok:
 MOV    ECX,1
 SUB    EAX,EAX
 INT    31H                     ; Allocate LDT descriptors
 JC     allocation_fail
 MOV    [azbar_selector],AX
 MOV    FS,AX

 XCHG   EBX,EAX
 MOV    EDX,[linear_address]
 MOV    ECX,EDX
 SHR    ECX,16
 MOV    AX,7                    ; Set Segment Base Address
 INT    31H
 JC     allocation_fail

 MOV    BX,[azbar_selector]
 MOV    EDX,[linear_address]
 ADD    EDX,16*1024-1           ; HDAIOLEN-1
 MOV    ECX,EDX
 SHR    ECX,16
 MOV    AX,8                    ; Set Segment Limit
 INT    31H
 JNC    selector_ok

allocation_fail:
 MOV    EDX,_ldt_fail
 CALL   print_str
 JMP    hda_exit

selector_ok:
 MOV    EDX,_ldt_ok
 CALL   print_str
 MOV    AX,[azbar_selector]
 MOV    CL,3
 CALL   print_num_eol

 MOV    ESI,8                   ; HDAGCTL
 AND    DWORD [FS:ESI],-2
 MOV    ECX,1000                ; timeout
@@:
 CALL   delay_1ms
 TEST   DWORD [FS:ESI],1        ; CRST
 JZ     @F
 LOOP   @B
@@:
 OR     DWORD [FS:ESI],1        ; CRST
 MOV    ECX,1000                ; timeout
@@:
 CALL   delay_1ms
 TEST   DWORD [FS:ESI],1        ; CRST
 JNZ    @F
 LOOP   @B
@@:
 CMP    [FS:ESI],ECX
 JNZ    reset_ok
 MOV    EDX,_reset_fail
 CALL   print_str
 JMP    hda_exit

reset_ok:
 MOV    ESI,0EH                 ; HDASTATESTS
 MOV    AX,[FS:ESI]             ; codecmask
 TEST   AX,AX
 JNZ    codec_ok
 MOV    EDX,_codec_fail
 CALL   print_str
 JMP    hda_exit

codec_ok:
 MOV    ECX,4                   ; HDA_MAX_CODECS
 SUB    EBP,EBP                 ; codecaddr
.1:
 SHR    EAX,1
 JNC    .2
 PUSHA
 CALL   codec_found
 POPA
.2:
 ADD    EBP,10000000H
 LOOP   .1

hda_exit:
 MOV    ECX,[linear_address]
 MOV    EBX,ECX
 SHR    EBX,16
 MOV    EDI,16*1024             ; HDAIOLEN
 SUB    ESI,ESI
 MOV    AX,601H                 ; Unlock Linear Region
 INT    31H
 MOV    ECX,[linear_address]
 MOV    EBX,ECX
 SHR    EBX,16
 MOV    AX,801H                 ; Free Physical Address Mapping
 INT    31H
RETN

;-------------------------------------------------------
codec_found:
 MOV    EDX,_codec_ok
 CALL   print_str
 MOV    EAX,00F0000H            ; GET_PARAM,VENDOR_ID
 CALL   read_codec
 MOV    ESI,EAX
 MOV    CL,4
 CALL   print_num
 MOV    EDX,_vendor
 CALL   print_str
 XCHG   EAX,ESI
 SHR    EAX,16
 MOV    CL,4
 PUSH   EAX
 CALL   print_num_eol
 MOV    EDX,_addr_ok
 CALL   print_str

 MOV    EAX,EBP
 MOV    CL,8
 CALL   print_num

 MOV    EDX,_node_first
 CALL   print_str
 MOV    EAX,01F0004H            ; GET_PARAM,NODE_CNT
 CALL   read_codec
 SUB    EDX,EDX
 MOV    DL,AL                   ; number of nodes
 SHR    EAX,16                  ; first node
 MOV    AH,0
 ADD    EDX,EAX
 DEC    EDX
 MOV    [first_node_id],EAX
 MOV    [last_node_id],EDX
 MOV    CL,3
 CALL   print_num
 MOV    EDX,_node_last
 CALL   print_str
 MOV    EAX,[last_node_id]
 MOV    CL,3
 CALL   print_num_eol

 POP    EAX
 CMP    AX,10ECH                ; Realtek codec
 JNE    .1
;-------------------------------------------------------
; Set Realtek hidden PCBEEP register.
 MOV    EDX,_fix_realtek
 CALL   print_str

 MOV    EAX,2050036H            ; SET_COEF_INDEX
 CALL   write_codec
 MOV    EAX,20C0000H            ; GET_PROC_COEF
 CALL   read_codec
 MOV    CL,4
 CALL   print_num

 MOV    EAX,2050036H            ; SET_COEF_INDEX
 CALL   write_codec
 MOV    EAX,2040707H            ; SET_PROC_COEF
 CALL   write_codec

 MOV    EDX,_unmuted
 CALL   print_str
 JMP    find_generator
.1:

 CMP    AX,111DH                ; IDT codec
 JNE    .2
;-------------------------------------------------------
; IDT codec analog beep enable
 MOV    EDX,_fix_idt
 CALL   print_str

 MOV    EAX,017EE00H            ; SET_ANA_BEEP,Byte1
 MOV    AL,BYTE [volume]        ; gain
 AND    AL,18H
 SHL    AL,1
 OR     AL,1                    ; Always enabled
 CALL   write_codec
 MOV    EAX,017EF00H            ; SET_ANA_BEEP,Byte2
 MOV    AL,BYTE [volume]        ; gain
 AND    AL,07H
 SHL    AL,2
 OR     AL,3                    ; Quantization enable
 CALL   write_codec

 MOV    EDX,_unmuted
 CALL   print_str
;JMP    find_generator
.2:

;-------------------------------------------------------
find_generator:
 MOV    [generator_node_id],1   ; AudioFunctionGroup node id
 MOV    ECX,[first_node_id]
.1:
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F0009H            ; GET_PARAM,WIDGET_CAP
 CALL   read_codec
 SHR    EAX,20
 AND    AL,0FH                  ; type
 CMP    AL,7                    ; BEEP_GEN
 JNE    .2
 MOV    [generator_node_id],ECX
.2:
 INC    ECX
 CMP    ECX,[last_node_id]
 JBE    .1
 MOV    EDX,_node_generator
 CALL   print_str
 MOV    EAX,[generator_node_id]
 MOV    CL,3
 CALL   print_num

 MOV    EAX,[generator_node_id]
 SHL    EAX,20
 OR     EAX,0070A00H            ; SET_BEEP_GEN
 CALL   write_codec             ; disable

 MOV    EAX,[generator_node_id]
 SHL    EAX,20
 OR     EAX,0070500H            ; SET_POW_STATE,STATE_D0
 CALL   write_codec

 MOV    EDX,_disabled
 CALL   print_str

;-------------------------------------------------------
find_speaker:
 MOV    ECX,[first_node_id]
.1:
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F0009H            ; GET_PARAM,WIDGET_CAP
 CALL   read_codec
 TEST   AH,2                    ; IS_DIGITAL
 JNZ    .2
 SHR    EAX,20
 AND    AL,0FH                  ; type
 CMP    AL,4                    ; PIN_CMPLX
 JNE    .2
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F000CH            ; GET_PARAM,PIN_CAP
 CALL   read_codec
 TEST   AL,10H                  ; PIN_OUT_CAP
 JZ     .2
 TEST   AL,28H                  ; PIN_IN_CAP+PIN_HP_CAP
 JNZ    .2
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F1C00H            ; GET_PIN_CFG
 CALL   read_codec
 TEST   EAX,80000000H           ; conectivity
 JZ     .2                      ; not fixed

 PUSH   ECX
 MOV    EDX,_node_speaker
 CALL   print_str
 MOV    EAX,ECX
 MOV    CL,3
 CALL   print_num
 POP    ECX

 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,003B080H            ; SET_AMP_GAIN,SET_OUT_AMP
 CALL   write_codec             ; muted
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,0070700H            ; SET_PIN_CTRL
 CALL   write_codec             ; disabled

 MOV    EDX,_muted
 CALL   print_str

.2:
 INC    ECX
 CMP    ECX,[last_node_id]
 JBE    .1

;-------------------------------------------------------
find_headphone:
 MOV    ECX,[first_node_id]
.1:
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F0009H            ; GET_PARAM,WIDGET_CAP
 CALL   read_codec
 SHR    EAX,20
 AND    AL,0FH                  ; type
 CMP    AL,4                    ; PIN_CMPLX
 JNE    .2
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F000CH            ; GET_PARAM,PIN_CAP
 CALL   read_codec
 TEST   AL,10H                  ; PIN_OUT_CAP
 JZ     .2
 TEST   AL,08H                  ; PIN_HP_CAP
 JZ     .2
 TEST   AL,20H                  ; PIN_IN_CAP
 JNZ    .2
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F1C00H            ; GET_PIN_CFG
 CALL   read_codec
 SHR    EAX,20
 AND    AL,0FH                  ; pintype
 CMP    AL,2                    ; HP_OUT
 JNE   .2

 PUSH   ECX
 MOV    EDX,_node_hphone
 CALL   print_str
 MOV    EAX,ECX
 MOV    CL,3
 CALL   print_num
 POP    ECX

 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,003B000H            ; SET_AMP_GAIN,SET_OUT_AMP
 MOV    AL,BYTE [volume]        ; gain
 CALL   write_codec

 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00707C0H            ; SET_PIN_CTRL,PIN_OUT_ENAB+PIN_HP_ENAB
 CALL   write_codec

 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,0070500H            ; SET_POW_STATE,STATE_D0
 CALL   write_codec

 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F000CH            ; GET_PARAM,PIN_CAP
 CALL   read_codec
 TEST   EAX,10000H              ; PIN_EAPD_CAP
 JZ     .4
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F0C00H            ; GET_PIN_EAPDBTL
 CALL   read_codec
 XCHG   EDX,EAX
 MOV    EAX,ECX
 SHL    EAX,20
 MOV    AL,DL
 OR     EAX,0070C02H            ; SET_PIN_EAPDBTL,EAPD_ENABLE
 CALL   write_codec
.4:

 MOV    EDX,_unmuted
 CALL   print_str

.2:
 INC    ECX
 CMP    ECX,[last_node_id]
 JBE    .1

;-------------------------------------------------------
find_pcbeep:
 MOV    ECX,[first_node_id]
.1:
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F0009H            ; GET_PARAM,WIDGET_CAP
 CALL   read_codec
 CMP    EAX,400400H
 JE     pcbeep_found
 CMP    EAX,400000H
 JE     pcbeep_found
.2:
 INC    ECX
 CMP    ECX,[last_node_id]
 JBE    .1

 MOV    EDX,_no_pcbeep
 CALL   print_str

RETN

pcbeep_found:
 MOV    [pcbeep_node_id],ECX
 MOV    EDX,_node_pcbeep
 CALL   print_str
 MOV    EAX,[pcbeep_node_id]
 MOV    CL,3
 CALL   print_num
 MOV    EDX,_on
 CALL   print_str

 MOV    ECX,[first_node_id]
.1:
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F0009H            ; GET_PARAM,WIDGET_CAP
 CALL   read_codec
 SHR    EAX,20
 AND    AL,0FH                  ; type

 CMP    AL,2                    ; MIXER
 JNE    .5

 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F000EH            ; GET_PARAM,CON_LIST
 CALL   read_codec
 AND    EAX,7FH
 XCHG   EDX,EAX                 ; number of connections
.2:
 DEC    EDX
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F0200H            ; GET_CON_LST_ENT
 MOV    AL,DL                   ; index
 CALL   read_codec
 PUSH   ECX
 MOV    ECX,EDX
 AND    CL,3
 SHL    ECX,3
 SHR    EAX,CL
 POP    ECX
 AND    EAX,7FH
 CMP    EAX,[pcbeep_node_id]
 JE     .3
 SHL    EAX,20
 OR     EAX,00F0009H            ; GET_PARAM,WIDGET_CAP
 CALL   read_codec
 SHR    EAX,20
 AND    AL,0FH                  ; type
 CMP    AL,2                    ; MIXER
 JNE    .4
.3:
 MOV    EAX,ECX
 SHL    EAX,20
 MOV    AH,DL                   ; index
 OR     EAX,0037000H            ; SET_AMP_GAIN,SET_IN_AMP
 MOV    AL,BYTE [volume]        ; gain
 CALL   write_codec
 PUSHA
 PUSH   EDX
 MOV    EAX,ECX                 ; node
 MOV    CL,2
 CALL   print_num
 MOV    DL,'#'
 MOV    AH,2
 INT    21H
 POP    EAX
 MOV    CL,1
 CALL   print_num
 MOV    DL,' '
 MOV    AH,2
 INT    21H
 POPA
.4:
 TEST   EDX,EDX
 JNZ    .2
 JMP    .8

.5:
 CMP    AL,3                    ; SELECTOR
 JNE    .8
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F000EH            ; GET_PARAM,CON_LIST
 CALL   read_codec
 AND    EAX,7FH
 XCHG   EDX,EAX                 ; number of connections
.6:
 DEC    EDX
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,00F0200H            ; GET_CON_LST_ENT
 MOV    AL,DL                   ; index
 CALL   read_codec
 PUSH   ECX
 MOV    ECX,EDX
 AND    CL,3
 SHL    ECX,3
 SHR    EAX,CL
 POP    ECX
 AND    EAX,7FH
 CMP    EAX,[pcbeep_node_id]
 JNE    .7
 MOV    EAX,ECX
 SHL    EAX,20
 OR     EAX,0070100H            ; SET_CON_SEL
 MOV    AL,DL                   ; index
 CALL   write_codec
 PUSHA
 MOV    EAX,ECX                 ; node
 MOV    CL,2
 CALL   print_num
 MOV    DL,' '
 MOV    AH,2
 INT    21H
 POPA
.7:
 TEST   EDX,EDX
 JNZ    .6
.8:
 INC    ECX
 CMP    ECX,[last_node_id]
 JBE    .1

 MOV    EDX,_unmuted+1
 CALL   print_str

RETN

;-------------------------------------------------------
; subroutines

read_codec:
 CALL   write_codec
 PUSH   EBX ECX
 MOV    EBX,68H                 ; HDAICIS
 MOV    ECX,1000                ; timeout
@@:
 CALL   delay_1ms
 MOV    AX,[FS:EBX]
 AND    AL,3                    ; ICB | IRV
 CMP    AL,2                    ; IRV
 JE     @F
 LOOP   @B
@@:
 MOV    EBX,64H                 ; HDAICII
 MOV    EAX,[FS:EBX]
 POP    ECX EBX
RETN

write_codec:
 OR     EAX,EBP                 ; codecaddr
 PUSH   EBX ECX
 MOV    EBX,68H                 ; HDAICIS
 MOV    ECX,1000                ; timeout
@@:
 CALL   delay_1ms
 TEST   WORD [FS:EBX],1         ; ICB
 JZ     @F
 LOOP   @B
@@:
 MOV    WORD [FS:EBX],3         ; ICB | IRV
 MOV    EBX,60H                 ; HDAICOI
 MOV    [FS:EBX],EAX
 POP    ECX EBX
RETN

delay_1ms:
 PUSH   ECX EAX
 MOV    ECX,67                  ; 66.5 x 15.085 close enough.
 IN     AL,61H                  ; PORTB
 AND    AL,10H                  ; REFRESH_STATUS
 MOV    AH,AL                   ; Start toggle state
@@:
 IN     AL,61H                  ; Read system control port
 AND    AL,10H                  ; Refresh toggles 15.085 microseconds
 CMP    AH,AL
 JE     @B                      ; Wait for state change
 MOV    AH,AL                   ; Update with new state
 LOOP   @B
 POP    EAX ECX
RETN

print_num_eol:
 CALL   print_num
 MOV    EDX,_eol
 CALL   print_str
RETN

print_num:
 SUB    EBX,EBX
 MOV    BL,CL
 MOV    ECX,EBX
.1:
 SUB    EDX,EDX
 PUSH   EBX
 MOV    EBX,16
 DIV    EBX
 POP    EBX
 ADD    DL,'0'
 CMP    DL,'9'
 JNA    .2
 ADD    DL,'A'-'9'-1
.2:
 PUSH   EDX
 LOOP   .1
 MOV    ECX,EBX
.3:
 POP    EDX
 MOV    AH,2
 INT    21H
 LOOP   .3
RETN

print_str:
 PUSH   ESI
 MOV    ESI,EDX
.1:
 MOV    DL,[ESI]
 INC    ESI
 MOV    AH,2
 INT    21H
 CMP    BYTE [ESI],'$'
 JNE    .1
 POP    ESI
RETN

;-------------------------------------------------------
; text messages

_welcome DB 'Unmute - PCBEEP to headphone - '
         DB 'Written by TomCat/Abaddon - v1.3/2023',13,10
         DB '-------------------------------'
         DB '-------------------------------------',13,10
         DB 'HDA mixer volume: $'
_dev_ok DB 'HDA device id: $'
_vendor DB ', vendor id: $'
_eol DB '.',13,10,'$'
_io_ok DB '- i/o base found at $'
_map_fail DB 13,10,'Physical address mapping error.',13,10,'$'
_io_mapped DB ', mapped to $'
_lock_fail DB 13,10,'Lock linear region error.',13,10,'$'
_ldt_fail DB 13,10,'Selector allocation error.',13,10,'$'
_ldt_ok DB ', selector: $'
_reset_fail DB 'Controller not ready.',13,10,'$'
_codec_fail DB 'No codec found after reset.',13,10,'$'
_codec_ok DB 'HDA codec id: $'
_addr_ok DB '- codec address found at $'
_node_first DB ', first widget id: $'
_node_last DB ', last widget id: $'
_node_generator DB '- BEEP generator widget id: $'
_node_speaker DB '- PC speaker widget id: $'
_node_hphone DB '- headphone widget id: $'
_node_pcbeep DB '- PCBEEP widget id: $'
_on DB ' on $'
_no_pcbeep DB '- PCBEEP widget not found.',13,10,'$'
_fix_realtek DB '- Realtek PC Beep Hidden Register: $'
_fix_idt DB '- IDT analog beep: $'
_muted DB ' MUTED.',13,10,'$'
_unmuted DB ' UNMUTED.',13,10,'$'
_disabled DB ' DISABLED.',13,10,'$'
_no_hda DB 'No compatible device found.',13,10,'$'

;-------------------------------------------------------
; variables

volume DD ?
linear_address DD ?
first_node_id DD ?
last_node_id DD ?
pcbeep_node_id DD ?
generator_node_id DD ?
azbar_selector DW ?

INCLUDE 'DOSDPMI\DPMIFOOT.INC'
