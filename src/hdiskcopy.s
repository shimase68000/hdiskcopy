*********************************************************
*
*		hdiskcopy
*
*********************************************************

		.include	iocscall.mac
		.include	doscall.mac

**********************************************************

MinimamFreeArea	.equ	512	* followed to 'getfreearea'

**********************************************************

		.offset	0	* offset of DPB ptr ( 94byte )

dpb_drive	.ds.b	1	* ƒhƒ‰ƒCƒu”Ô†@‚O‚`C‚P‚a
dpb_unit	.ds.b	1	* ƒfƒoƒCƒXƒhƒ‰ƒCƒo‚Åg‚¤ƒ†ƒjƒbƒg”Ô†
dpb_byte	.ds.w	1	* ‚PƒZƒNƒ^‚ ‚½‚è‚ÌƒoƒCƒg”
dpb_sec		.ds.b	1	* ‚PƒNƒ‰ƒXƒ^‚ ‚½‚è‚ÌƒZƒNƒ^”|‚P
dpb_shift	.ds.b	1	* æ“ªƒNƒ‰ƒXƒ^‚ÌƒZƒNƒ^”Ô†
dpb_fatsec	.ds.w	1	* ‚e‚`‚s‚Ìæ“ªƒZƒNƒ^”Ô†
dpb_fatcount	.ds.b	1	* ‚e‚`‚s—Ìˆæ‚ÌŒÂ”
dpb_fatlen	.ds.b	1	* ‚e‚`‚s‚Ìè‚ß‚éƒZƒNƒ^”i•¡Ê•ª‚ğœ‚­j
dpb_dircount	.ds.w	1	* ƒ‹[ƒgƒfƒBƒŒƒNƒgƒŠ‚ÌŒÂ”
dpb_datasec	.ds.w	1	* ƒf[ƒ^•”‚Ìæ“ªƒZƒNƒ^”Ô†
dpb_maxfat	.ds.w	1	* ‘ƒNƒ‰ƒXƒ^”{‚P
dpb_dirsec	.ds.w	1	* ƒ‹[ƒgƒfƒBƒŒƒNƒgƒŠ‚Ìæ“ªƒZƒNƒ^”Ô†
dpb_driver	.ds.l	1	* ƒfƒoƒCƒXƒhƒ‰ƒCƒo‚Ö‚Ìƒ|ƒCƒ“ƒ^
dpb_id		.ds.b	1	* ƒƒfƒBƒAƒoƒCƒg
dpb_flg		.ds.b	1	* ‚c‚o‚ag—pƒtƒ‰ƒO
dpb_next	.ds.l	1	* Ÿ‚Ì‚c‚o‚a‚Ìƒ|ƒCƒ“ƒ^
dpb_dirfat	.ds.w	1	* ƒJƒŒƒ“ƒgƒfƒBƒŒƒNƒgƒŠ‚ÌƒNƒ‰ƒXƒ^”Ô†i‚O‚Íƒ‹[ƒgj
dpb_dirbuf	.ds.b	64	* ƒJƒŒƒ“ƒgƒfƒBƒŒƒNƒgƒŠ‚Ì•¶šƒoƒbƒtƒ@

*********************************************************

		.text

start:
	lea	stackarea(pc),sp

	bsr	print_title
	bsr	getpara
	bsr	getfreearea

	DOS	_FFLUSH

	lea	dpbptr(pc),a6
	lea	databuf(pc),a5

	bsr	pre_readwrite
	bsr	make_fatusedata

	lea	(a5),a4			* a4; data buffer
	lea	databuf(pc),a5		* a5; FAT pointer
	bsr	cp_main

	bsr	disk_reset

	pea	mes_completed(pc)
	DOS	_PRINT
	DOS	_EXIT

*************************************************
*	cp main
*************************************************
cp_main
	moveq	#0,d5
	moveq	#0,d6
	moveq	#0,d7
	move.b	dpb_sec(a6),d7
	addq.l	#1,d7			* d7; ƒZƒNƒ^^ƒNƒ‰ƒXƒ^
	move.w	dpb_maxfat(a6),d6	* d6; number of FAT
	subq.w	#2,d6			* !!!
	move.w	dpb_datasec(a6),d5	* d5; top sector of data
	sub.l	d7,d5
	sub.l	d7,d5			* d5 - ƒNƒ‰ƒXƒ^x2

*----------------------------
	pea	mes_sec1(pc)
	DOS	_PRINT
	addq.l	#4,sp

	move.w	d6,d0
	mulu	d7,d0
	add.l	d5,d0
	add.l	d7,d0
	bsr	hex2dec
*----------------------------
	pea	mes_printcr(pc)
	DOS	_PRINT
	pea	mes_sec2(pc)
	DOS	_PRINT
	addq.l	#8,sp
*----------------------------

	moveq	#0,d4			* d4; number of data sector
cp_main1_1
	moveq	#7,d0			* d0; bit counter
	move.b	(a5)+,d1
cp_main1_2
	btst.l	d0,d1
	beq	cp_main2
cp_main1_3
	addq.l	#1,d4
	subq.w	#1,d6
	dbcs	d0,cp_main1_2
	bcc	cp_main1_1

	bsr	cp_readwrite
	bra	cp_main_exit

*--------------
cp_main2
	bsr	cp_readwrite
	bra	cp_main2_3

cp_main2_1
	moveq	#7,d0			* d0; bit counter
	move.b	(a5)+,d1
cp_main2_2
	btst.l	d0,d1
	bne	cp_main1_3
cp_main2_3
	add.l	d7,d5			* skip sector
	subq.w	#1,d6
	dbcs	d0,cp_main2_2
	bcc	cp_main2_1

cp_main_exit
*-------------------------------------
	pea	mes_printdec(pc)	* print copy sector
	DOS	_PRINT
	addq.l	#4,sp

	move.l	d5,d0
	bsr	hex2dec

	pea	mes_printcr(pc)
	DOS	_PRINT
	addq.l	#4,sp
*------------------------------
	rts

*************************************************
*	cp read/write
*************************************************
cp_readwrite
	movem.l	d0-d3/a0-a6,-(sp)

	lea	(a4),a3
	add.l	#$8000_0000,a3		* expand mode

	mulu	d7,d4			* d4 <- n sector
	move.l	freearea(pc),d3

cp_readwrite1
*---------------------------
	pea	mes_printdec(pc)	* print copy sector
	DOS	_PRINT
	addq.l	#4,sp

	move.l	d5,d0
	bsr	hex2dec
*----------------------------
	cmp.l	d3,d4
	bhi	cp_readwrite2

	move.l	d4,d3

cp_readwrite2
	move.l	d3,-(sp)
	move.l	d5,-(sp)
	move.w	sourcedrive(pc),-(sp)
	pea	(a3)
	DOS	_DISKRED
	lea	14(sp),sp

	move.l	d3,-(sp)
	move.l	d5,-(sp)
	move.w	destdrive(pc),-(sp)
	pea	(a3)
	DOS	_DISKWRT
	lea	14(sp),sp

	add.l	d3,d5
	sub.l	d3,d4
	bne	cp_readwrite1

*---------------------------
	pea	mes_printdec(pc)	* print copy sector
	DOS	_PRINT
	addq.l	#4,sp

	move.l	d5,d0
	bsr	hex2dec
*----------------------------
	movem.l	(sp)+,d0-d3/a0-a6
	rts

*************************************************
*	pre read/write
*************************************************
pre_readwrite
	moveq	#0,d1
	move.w	dpb_byte(a6),d1
	moveq	#1,d2

	move.b	dpb_id(a6),d3
	cmp.b	#$f6,d3		* MOD(scsi)
	beq	pre_readwrite1
	cmp.b	#$f7,d3		* HDD(scsi)
	beq	pre_readwrite1
	cmp.b	#$f8,d3		* HDD(sasi)
	beq	pre_readwrite1

	moveq	#0,d1
	moveq	#0,d2

pre_readwrite1
	moveq	#0,d0
	move.w	dpb_datasec(a6),d0

	lea	databuf(pc),a0
	add.l	a0,d1
	or.l	#$8000_0000,d1

	movem.l	d0-d2,-(sp)

	move.l	d0,-(sp)		* pre read
	move.l	d2,-(sp)
	move.w	sourcedrive(pc),-(sp)
	move.l	d1,-(sp)
	DOS	_DISKRED
	lea	14(sp),sp

	movem.l	(sp)+,d0-d2

	move.l	d0,-(sp)		* pre write
	move.l	d2,-(sp)
	move.w	destdrive(pc),-(sp)
	move.l	d1,-(sp)
	DOS	_DISKWRT
	lea	14(sp),sp

	rts

*************************************************
*	make FAT use data
*************************************************
make_fatusedata
	move.w	dpb_byte(a6),d0		* FAT check & FAT convert
	mulu	dpb_fatsec(a6),d0
	lea	(a5,d0.l),a4		* a4; FAT pointer
	moveq	#0,d0
	move.b	dpb_fatlen(a6),d0
	mulu	dpb_byte(a6),d0
	lea	(a4,d0.l),a3		* a3; converted FAT pointer

	move.l	a4,-(sp)

	move.w	dpb_maxfat(a6),d0
	cmp.w	#$FF8+1,d0		* 2byte sector ??
	bcc 	fat_convert_exit

	move.l	a3,(sp)
fat_convert_1
	moveq	#0,d1
	move.b	2(a4),d1
	lsl.l	#8,d1
	move.b	1(a4),d1
	lsl.l	#8,d1
	move.b	(a4),d1
	addq.l	#3,a4

	move.l	d1,d2
	and.w	#$FFF,d2
	cmp.w	#$FF7,d2
	bcs	fat_convert_2
	or.w	#$F000,d2
fat_convert_2
	move.w	d2,(a3)+
	dbra	d0,fat_convert_3
	bra	fat_convert_exit

fat_convert_3
	lsr.l	#8,d1
	lsr.l	#4,d1
	and.w	#$FFF,d1
	cmp.w	#$FF7,d1
	bcs	fat_convert_4
	or.w	#$F000,d1
fat_convert_4
	move.w	d1,(a3)+
	dbra	d0,fat_convert_1

fat_convert_exit
	movem.l	(sp)+,a4
	lea	cp_mode(pc),a3

	moveq	#0,d7
	move.w	dpb_maxfat(a6),d7
	subq.w	#2,d7			* !!!
*	lsr.w	#3,d7			* byte
make_fatusedata1
	moveq	#8-1,d0
	moveq	#0,d1
make_fatusedata2
	btst.b	#7,(a3)
	bne	make_fatusedata2_1	* copy all sector
	tst.w	(a4)+
	beq	make_fatusedata3
make_fatusedata2_1
	bset.l	d0,d1
make_fatusedata3
	subq.w	#1,d0
	bcc	make_fatusedata4

	move.b	d1,(a5)+
	moveq	#8-1,d0
	moveq	#0,d1
make_fatusedata4
	dbra	d7,make_fatusedata2

	move.b	d1,(a5)+		* +1

	rts

**********************************************************
*	disk reset
**********************************************************
disk_reset
	move.w	destdrive(pc),d0
	add.b	#'A'-1,d0
	lea	dpath(pc),a0
	move.b	d0,(a0)

	pea	(a0)
	DOS	_CHDIR
	addq.l	#4,sp

	DOS	_FFLUSH

	rts

**********************************************************
*	get para
**********************************************************
getpara
	tst.b	(a2)+
	beq	print_usage

	lea	sourcedrive(pc),a6

getpara_loop
	moveq	#0,d0
	move.b	(a2)+,d0
	beq	getpara_next
	cmp.b	#' ',d0
	beq	getpara_loop

	cmp.b	#'/',d0
	beq	getpara2
	cmp.b	#'-',d0
	beq	getpara2

	cmp.b	#$60,d0
	bls	getpara1
	sub.b	#$20,d0
getpara1
	cmp.b	#'A',d0
	bcs	print_usage
	cmp.b	#'Z',d0
	bhi	print_usage

	move.b	(a2)+,d1
	cmp.b	#':',d1
	bne	err_badpara

	tst.b	(a6)
	bne	err_badpara

	sub.b	#'A'-1,d0		* A=1, B=2, ...
	move.w	d0,(a6)
	lea	destdrive(pc),a6

	bra	getpara_loop

*----------------------------
getpara2
	move.b	(a2)+,d0

	cmp.b	#'A',d0
	beq	sw_allsector
	cmp.b	#'a',d0
	beq	sw_allsector

	cmp.b	#'H',d0
	beq	sw_help
	cmp.b	#'h',d0
	beq	sw_help
	cmp.b	#'?',d0
	beq	sw_help

	bra	err_badpara

*----------------------------
getpara_next
	lea	sourcedrive(pc),a6
	move.w	(a6),d0
	beq	err_badpara
	tst.w	2(a6)
	beq	err_badpara
	cmp.w	2(a6),d0
	beq	err_badpara

	lea	dpbptr(pc),a6

	pea	(a6)			* ƒfƒBƒXƒeƒBƒl[ƒVƒ‡ƒ“‘¤‚c‚o‚a
	move.w	destdrive(pc),-(sp)
	DOS	_GETDPB
	addq.l	#6,sp
	tst.l	d0
	bmi	err_baddrive

*	cmp.w	#1024,dpb_byte(a6)	* 1sector = 1024 ??
*	bne	err_baddrive
*	cmp.b	#1,dpb_sec(a6)		* sector/cluster = 2 ??
*	bne	err_baddrive
	move.w	dpb_maxfat(a6),-(sp)

	pea	(a6)			* ƒ\[ƒX‘¤‚c‚o‚a
	move.w	sourcedrive(pc),-(sp)
	DOS	_GETDPB
	addq.l	#6,sp
	tst.l	d0
	bmi	err_baddrive

*	cmp.w	#1024,dpb_byte(a6)	* 1sector = 1024 ??
*	bne	err_baddrive
*	cmp.b	#1,dpb_sec(a6)		* sector/cluster = 2 ??
*	bne	err_baddrive
	move.w	(sp)+,d0
	cmp.w	dpb_maxfat(a6),d0	* same maxfat ??
	bne	err_baddrive

	rts

*--------------------------------------
sw_allsector
	lea	cp_mode(pc),a3
	bset.b	#7,(a3)
	bra	getpara_loop

*--------------------------------------
sw_help
	bra	print_usage

**********************************************************
*	get free area
**********************************************************
getfreearea
	move.l	8(a0),d0		* d0; end of memory
	sub.l	a1,d0			* a1; end of program

	lsr.l	#8,d0
	lsr.l	#2,d0			* d0 / 1024
	and.l	#$FFFF_FFFE,d0		* even KB

	sub.l	#64,d0			* Ï°¼Şİ 64KB
	cmp.l	#MinimamFreeArea,d0	* MinimamFreeArea < FreeArea ?
	bcs	err_nomemory

	lea	dpbptr(pc),a6
	move.l	#1024,d1		* 1KB / byte(per sector)
	divu	dpb_byte(a6),d1
	bvs	err_badbyte		* divu overflow

	mulu	d1,d0

	lea	freearea(pc),a6
	move.l	d0,(a6)

	rts

*********************************************************
*	hex2dec
*********************************************************
hex2dec
	movem.l	d0-d5/a0-a3,-(sp)

*	move.l	#1000000000,d1
	move.l	#10000000,d1
	clr.b	d5
hex2dec0
	moveq	#$30-1,d2
hex2dec1
	addq.b	#1,d2
	sub.l	d1,d0
	bcc	hex2dec1
	add.l	d1,d0

	tst.b	d5
	bne	hex2dec3
	cmp.b	#$30,d2
	sne	d5
	bne	hex2dec3
hex2dec2
	move.b	#' ',d2
hex2dec3
	movem.l	d0-d1,-(sp)
	move.w	d2,d1
	IOCS	_B_PUTC
	movem.l	(sp)+,d0-d1

	moveq	#0,d3
	move.w	d1,d3
	clr.w	d1
	swap	d1
	divu	#10,d1
	move.w	d1,d4
	swap	d4
	clr.w	d1
	add.l	d1,d3
	divu	#10,d3
	move.w	d3,d4
	move.l	d4,d1
	bne	hex2dec0

	movem.l	(sp)+,d0-d5/a0-a3
	rts



*********************************************************
*	print message
*********************************************************
print_title
	pea	mes_title(pc)
	DOS	_PRINT
	addq.l	#4,sp
	rts
*--------------------------------------------------------
print_usage
	pea	mes_usage(pc)
	DOS	_PRINT
	DOS	_EXIT
*--------------------------------------------------------
err_nomemory
	pea	mes_nomemory(pc)
	moveq	#8,d1
	bra	exit_2
*--------------------------------------------------------
err_badpara
	pea	mes_badpara(pc)
	moveq	#14,d1
	bra	exit_2
*--------------------------------------------------------
err_baddrive
	pea	mes_baddrive(pc)
	moveq	#15,d1
	bra	exit_2
*--------------------------------------------------------
err_badbyte
	pea	mes_badbyte(pc)
	moveq	#127,d1
exit_2
	DOS	_PRINT
	move.w	d1,-(sp)
	DOS	_EXIT2

*********************************************************

		.data

dpath		.dc.b	"B:\",0

		.even

cp_mode		.dc.w	0
sourcedrive	.dc.w	0
destdrive	.dc.w	0

mes_title	.dc.b	'High Speed Diskcopy version 1.03 Copyright 1993,94 UG.',13,10,0
mes_usage	.dc.b	'usage: HDISKCOPYmƒXƒCƒbƒ`nƒRƒs[Œ³ƒhƒ‰ƒCƒu–¼ ƒRƒs[æƒhƒ‰ƒCƒu–¼',13,10
		.dc.b	'switch:  /a   ‘SƒZƒNƒ^ƒRƒs[',13,10,0
mes_completed	.dc.b	'I—¹‚µ‚Ü‚µ‚½',13,10,0
mes_nomemory	.dc.b	'ƒƒ‚ƒŠ‚ª‘«‚è‚Ü‚¹‚ñiÅ’á512KByte•K—v‚Å‚·j',13,10,0
mes_badpara	.dc.b	'ƒpƒ‰ƒ[ƒ^‚Ìw’è‚ªŠÔˆá‚Á‚Ä‚¢‚Ü‚·',13,10,0
mes_baddrive	.dc.b	'ƒhƒ‰ƒCƒu—e—Ê‚ªˆá‚¤‚©A‘ÎÛŠO‚Ìƒhƒ‰ƒCƒu‚Å‚·',13,10,0
mes_badbyte	.dc.b	'ƒoƒCƒg^ƒZƒNƒ^‚Ì’l‚ªˆÙí‚Å‚·',13,10,0
mes_sec1	.dc.b	'    ‘SƒZƒNƒ^”F',0
mes_sec2	.dc.b	'ƒRƒs[ƒZƒNƒ^”F        ',0
mes_printdec	.dc.b	'[8D',0
mes_printcr	.dc.b	13,10,0
		.even

		.bss

freearea	.ds.l	1
heaparea	.ds.l	128
stackarea
dpbptr		.ds.b	94
databuf

