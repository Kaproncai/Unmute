
# UNMUTE

DOS utility which is redirecting the PCBEEP to headphone.

It's usefull for capturing the PC speaker sound from DOS
games and demoscene stuff.

### Requirements

FreeDOS or MS-Dos
and DPMI DOS extender required (like HDPMI32).

### Usage

You can adjust the volume by a command line parameter.
Possible values are from 0 to 99 percent.
The default is full volume.

### Author

It was written in FASMD by Tam s Kaproncai aka TomCat/Abaddon.
PMODE init code is borrowed from FASMD source by Tomasz Grysztar.

### Contact

E-mail: kapor@dit.hu
GitHub: Kaproncai

### Used references

- Intel High Definition Audio specification 1.0
- Realtek ALC221 codec datasheet
- PCI scan and delay routines from AC97 CDPlayer coded by Dex
- HDA part of WSS audio library adopted from JUDAS by Khusraw

### Files

UNMUTE.ASM - the main source code
DOSDPMI - director of DPMI include files
CHANGES - detailed features
TESTED - tested CODEC list
LICENSE - copyright information
TODO - future plans and dreams
README.MD - this file

### Example

Here is the result of UNMUTE on my PC:

> Unmute - PCBEEP to headphone - Written by TomCat/Abaddon - v1.0/2017

> --------------------------------------------------------------------

> HDA mixer volume: 01F.
> HDA device id: A170, vendor id: 8086.
> - i/o base found at F3144000, mapped to 00110000, selector: 0C7.
> HDA codec id: 0221, vendor id: 10EC.
> - codec address found at 00000000, first widget id: 002, last widget id: 023.
> - BEEP generator widget id: 001 DISABLED.
> - PC speaker widget id: 017 MUTED.
> - headphone widget id: 021 UNMUTED.
> - PCBEEP widget id: 01D on 0B#4 0C#1 0D#1 0F#1 22 23 UNMUTED.
> HDA device id: 0FB9, vendor id: 10DE.
> - i/o base found at F3000000, mapped to 00110000, selector: 0CF.
> HDA codec id: 0080, vendor id: 10DE.
> - codec address found at 00000000, first widget id: 004, last widget id: 00D.
> - BEEP generator widget id: 001 DISABLED.
> - PCBEEP widget not found.

