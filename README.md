
# UNMUTE

DOS utility which is redirecting the PCBEEP to headphone.

It's useful for capturing the PC speaker sound from DOS
games and demoscene stuff.

### Requirements

- FreeDOS or MS-Dos
- DPMI DOS extender (like HDPMI32)
- hardware with High Definition Audio codec

### Usage

You can adjust the volume by a command line parameter.
Possible values are from 0 to 99 percent.
The default is full volume.

### Author

It was written in FASMD by Tamás Kaproncai aka TomCat/Abaddon.
PMODE init code is borrowed from FASMD source by Tomasz Grysztar.

### Contact

E-mail: kapor@dit.hu
GitHub: Kaproncai

### Used references

- Intel High Definition Audio specification 1.0
- Realtek ALC221 codec datasheet
- PCI scan and delay routines from AC97 CDPlayer coded by Dex
- HDA part of WSS audio library adopted from JUDAS by Khusraw
- Integrated Device Technology 92HD91 codec datasheet
- Codec informations from HD-audio emulator by tiwai@github
- Realtek PC Beep Hidden Register from kernel.org/doc

### Files

- UNMUTE.ASM - the main source code
- UNMUTE.EXE - compiled version
- DOSDPMI - director of DPMI include files
- CHANGES - detailed features
- TESTED - tested CODEC list
- LICENSE - copyright information
- TODO - future plans and dreams
- README.MD - this file

### Example

Here is the result of UNMUTE on my PC:

    Unmute - PCBEEP to headphone - Written by TomCat/Abaddon - v1.3/2023
    --------------------------------------------------------------------
    HDA mixer volume: 01F.
    HDA device id: 9D71, vendor id: 8086.
    - i/o base found at D1328000, mapped to 00111000, selector: 0C7.
    HDA codec id: 0256, vendor id: 10EC.
    - codec address found at 00000000, first widget id: 002, last widget id: 024.
    - Realtek PC Beep Hidden Register: 7717 UNMUTED.
    - BEEP generator widget id: 001 DISABLED.
    - PC speaker widget id: 014 MUTED.
    - headphone widget id: 021 UNMUTED.
    - PCBEEP widget id: 01D on 22#4 23#4 UNMUTED.
    HDA codec id: 280B, vendor id: 8086.
    - codec address found at 20000000, first widget id: 002, last widget id: 003.
    - BEEP generator widget id: 001 DISABLED.
    - PCBEEP widget not found.
