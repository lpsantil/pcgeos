COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Impex		
FILE:		impexImport.asm

AUTHOR:		Ted H. Kim, 3/6/91

ROUTINES:
	Name			Description
	----			-----------
	RolodexImportTransferItem
				Import a spreadsheet meta file	
	ImportMetaFile		Import the meta file
	ReadFieldData		Read in a field data from meta file
	TruncateFieldData	Truncate field data if it is too long
	InsertPhone		Insert new phone entries into the record
	InsertPhoneTypes	Insert the phone entry labels into record
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/6/91		Initial revision
	owa	7/27/93		added phoneitc/zip field

DESCRIPTION:
	This file contains all the routines that deal with importing a file. 	

	$Id: impexImport.asm,v 1.1 97/04/04 15:50:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Impex	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexImportTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import a meta file into GeoDex file format.

CALLED BY:	MSG_META_DOC_OUTPUT_IMPORT_FILE

PASS:		ss:bp - ptr to ImpexTranslationParams

RETURN:		ss:bp - ptr to ImpexTranslationParams

DESTROYED:	ax, bx, cx, dx, si, di, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexImportTransferItem	proc	far	uses	ds
	RITI_SSMeta	local	SSMetaStruc
	mov	bx, bp
	.enter

	class	RolodexClass

	; initialize the stack frame for importing a file

	push	bx
	mov	ax, ss:[bx].ITP_transferVMChain.high	; ax - VM block handle
	mov	bx, ss:[bx].ITP_transferVMFile		; bx - VM file handle
	mov	ds:[xferFileHandle], bx			; save the file handle
	mov	ds:[xferBlockHandle], ax		; save the block handle
	push	bp
	mov	dx, ss 					; dx:bp - SSMetaStruc 
	lea	bp, RITI_SSMeta
	call	SSMetaInitForRetrieval			; set up stack frame
	pop	bp

	; get the size of the scrap 

	mov	ax, RITI_SSMeta.SSMDAS_scrapRows
	mov	ds:[numRecords], ax		; number of rows
	mov	ax, RITI_SSMeta.SSMDAS_scrapCols
	mov	ds:[numFields], ax 		; number of columns
	cmp	ax, GEODEX_NUM_FIELDS		; more than 10 fields?
	jle	okay				; if not, skip
	mov	ds:[numFields], GEODEX_NUM_FIELDS ; read in only 10 fields
okay:
	; make it point to the 1st entry in DAS_CELL array

	mov	RITI_SSMeta.SSMDAS_dataArraySpecifier, DAS_CELL	
	push	bp
	mov	dx, ss				; dx:bp - SSMetaStruc
	lea	bp, RITI_SSMeta
	call	SSMetaDataArrayResetEntryPointer		
	pop	bp	

	call	ImportMetaFile			; JUST DO IT!!

	; unlock DAS_CELL data array

	pushf
	push	bp
	mov	dx, ss				; dx:bp - SSMetaStruc
	lea	bp, RITI_SSMeta
	call	SSMetaDataArrayUnlock		
	pop	bp
	popf
	jnc	noError				; skip if no error		

	call	MemAllocErrBox			; put up an error message
	jmp	exit	
noError:
	; check to see if there were any records w/ empty index fields
	; if there were, then display a DB with a warning message

	call	CheckEmptyIndex

	; display the 1st record and update index list if necessary

	push	bp
	mov	di, ds:[gmb.GMB_mainTable]		
	call	FindFirst			
	clr	ds:[curRecord]			; so new one will display
	call	DisplayCurRecord		; display the 1st record
	andnf	ds:[searchFlag], not mask SOF_NEW   ; clear search flag
	call	UpdateNameList			; update SearchList
	pop	bp
exit:
	pop	bx

	.leave
	mov	bp, bx
	ret
RolodexImportTransferItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckEmptyIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if there was any record with empty index field.

CALLED BY:	(GLOBAL)

PASS:		ds:[indexEmpty] - flag 

RETURN:		nothing

DESTROYED:	ax, bx, di, si 

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckEmptyIndex		proc	far	uses	bp
	.enter

	tst	ds:[indexEmpty]		; were there records w/o index fields?
	je	exit			; if none, exit
	mov	bp, ERROR_NO_INDEX_IMPORT   ; bp - error message constant
	call	DisplayErrorBox		; put up an error dialog box
exit:
	.leave
	ret
CheckEmptyIndex		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportMetaFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import the meta file.

CALLED BY:	(GLOBAL) RolodexImportTransferItem, RolodexPasteRecord

PASS:		ds - dgroup

RETURN:		carry set if there was an error

DESTROYED:	ax, bx, es, si, di

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportMetaFile	proc	far	uses	cx, dx, ds, bp
	IMF_SSMeta	local	SSMetaStruc
	.enter	inherit	far
	
	segmov	es, ds				; es - seg addr of dgroup
	clr	cx				; init. record counter	
	mov	es:[endOfFile], cl		; clear some flags
	mov	es:[endOfRecord], cl		
	mov	es:[indexEmpty], cl
recLoop:
	push	cx				
	call	InitBuffers			; clear handle and size buffers
	jc	error				; not enough memory

	; check to see if the 1st field data of this record has already
	; been locked by the previous 'SSMetaDataArrayGetNextEntry' call

	tst	es:[endOfRecord]
	jnz	locked				; if already locked, jump

mainLoop:
	push	bp
	mov	dx, ss 				; dx:bp - SSMetaStruc
	lea	bp, IMF_SSMeta
	call	SSMetaDataArrayGetNextEntry	; lock the field data 
	pop	bp
	jnc	notEnd				; skip not end of data chain

	; exit if end of data chain

	mov	es:[endOfFile], TRUE		; set the end of file flag
	jmp	insert				
notEnd:
	pop	bx				; bx - current row number
	push	bx

	; check to see if this field data belongs to the next record

	cmp	bx, ds:[si].SSME_coordRow
	je	skip				; if not, skip

	; we are at the end of the record, insert this record into database

	mov	es:[endOfRecord], TRUE
	jmp	insert
locked:
	mov	es:[endOfRecord], FALSE		; clear end of record flag
skip:
	mov	dx, ds:[si].SSME_coordCol	; dx - column number

	; check to see if this is an empty text field

	cmp	({CellCommon} ds:[SSME_dataPortion]).CC_type, CT_TEXT
	jne	readData			; if not, skip
SBCS<	cmp	ds:[si].SSME_entryDataSize, (size char)	; is null char only data?	>
DBCS<	cmp	ds:[si].SSME_entryDataSize, (size wchar) ; is null char only data?	>
	je	mainLoop			; skip if so	

readData:
	; there is data, we need to format this data.

	push	bp, dx
	mov	dx, ss 				; dx:bp - SSMetaStruc
	lea	bp, IMF_SSMeta
	call	SSMetaFormatCellText		; ds:si <- ptr to text
	pop	bp, dx				; ax <- size of text
						; bx <- block (if any)
	call	ReadFieldData			; read in field data
	jnc	noErr				; exit if error		
	pop	cx
	jmp	error
noErr:
	; free the data block created by SSMetaFormatCellText if exists

	tst	bx
	je	truncate
	call	MemFree
truncate:
	call	TruncateFieldData		; truncate if necessary
	jmp	mainLoop
insert:
	call	InsertRecordToDatabase	 	; insert them into quick table
	pop	cx
	inc	cx				; update the record counter

	; are we end of file?

	tst	es:[endOfFile] 
	jz	recLoop				; if not, continue
	clc					; exit with no error
error:
	.leave
	ret
ImportMetaFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize buffers that contain field data block handles 
		and field data sizes.

CALLED BY:	(INTERNAL) ImportMetaFile

PASS:		es - dgroup

RETURN:		buffers initialized
		carry set if not enough memory
		phoneTypeHandle - handle of phone type block

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Clear all fieldHandles (geodex public)
		Clear all fieldLengths (geodex public)
		Clear all phoneHandles (impex private)
		Clear all phoneLengths (impex private)

NOTES/WISDOM/INSIGHTS/LIMITS:
		For the geodex public, we can't automatically size the
		"clear" loops since this data is defined under another
		manager (ie, in GeoDex/Main, not GeoDex/Impex).  All we
		see is the "global fieldLengths:word" declaration.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	2/1/93		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitBuffers	proc	near	uses	ax, bx, cx, di, es
	IB_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	; clear all the buffers that contain field sizes and handles

	mov	cx, NUM_TEXT_EDIT_FIELDS+2
	clr	di
next1:
	clr	es:fieldHandles[di]		; geodex global
	add	di, 2
	loop	next1

	mov	cx, NUM_TEXT_EDIT_FIELDS+4
	clr	di
next2:
	clr	es:fieldLengths[di]		; geodex global
	add	di, 2
	loop	next2

	mov	cx, (length phoneHandle)
	clr	di
next3:
	clr	es:phoneHandles[di]		; Impex internal
	clr	es:phoneLengths[di]		; Impex internal
	add	di, 2
	loop	next3
	;
	; Phone type block will contain an array of PhoneTypeStruct
	; followed by the Phone Type text strings.
	;
	mov	ax, NUM_PHONE_TYPE_FIELDS * (size PhoneTypeStruct)
	mov	cx, (HAF_STANDARD_LOCK shl 8) or 0
	call	MemAlloc
	jc	exit
	mov	es:[phoneTypeHandle], bx
	mov	es, ax				; es - block segment
	clr	di				; di - offset to 1st entry
	mov	cx, NUM_PHONE_TYPE_FIELDS
next4:	
	clr	es:[di].PTS_handle
	clr	es:[di].PTS_size
	add	di, (size PhoneTypeStruct)
	loop	next4

	call	MemUnlock
	jmp	done
exit:
	stc
done:
	.leave
	ret
InitBuffers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertRecordToDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert the record that just got imported into GeoDex database
		file.

CALLED BY:	(INTERNAL) ImportMetaFile

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	2/1/93		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertRecordToDatabase	proc	near	uses	bp, es, ds, si
	IRTB_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	segmov	ds, es

	; check to see if the last name field is empty

	mov	di, TEFI_LASTNAME
	shl	di, 1
	tst	ds:fieldHandles[di]	
	jne	notEmpty			; skip if not empty
	mov	ds:[indexEmpty], TRUE		; set this flag
	jmp	done				; and exit
notEmpty:
	clr	ax				; update the entire record
	call	InitRecord			; create a new record 

if	_IMPEX_MERGE
	; see if we can just brazenly create a duplicate record

	cmp	ds:[mergeFlag], IMS_DUPLICATE
	jne	checkDuplicate			; => no, so must go look for
						;  record with same index

insertRecord:
endif	; _IMPEX_MERGE

	mov     ds:[gmb.GMB_curPhoneIndex], PTI_HOME-1	; phone type is 'HOME'
	call	InsertRecord			; insert it into database
	call	InsertPhone			; insert new phone entries 
	call	InsertPhoneTypes		; insert new phone types
if _QUICK_DIAL
        call    InsertAllQuickViewEntry 	; insert them into quick table
endif ;if _QUICK_DIAL
done:
	.leave
	ret

if 	_IMPEX_MERGE
checkDuplicate:
	;
	; The current merge setting for all records requires us to see if
	; there's already something in the database with the index field.
	;
	; First fetch the index field out of the created record.
	;
	mov	si, ds:[curRecord]
	call	GetLastName
	;
	; Now see if there's a record in the database with that index field.
	; 
	call	FindSortBufInMainTable
	jnc	insertRecord			; => doesn't exist yet
	;
	; There's already something in there. Figure out what we should do.
	; 
	call	GetMergeFlag			; bx <- ImpexMergeState
	cmp	bx, IMS_DUPLICATE
	je	insertRecord			; => should create a new
						;  record
	cmp	bx, IMS_REPLACE
	jne	updateOrAugment
	;
	; Delete the existing record before processing this new record
	; normally.
	; 
	call	MergeDeleteExisting
	jmp	insertRecord

updateOrAugment:
	;
	; Go mangle the fields properly.
	; 
	call	MergeUpdateOrAugment
	;
	; Now destroy the record we created, as we need it no longer.
	; 
	mov	di, ds:[curRecord]
	call	NewDBFree
	;
	; Set the curRecord to the existing record, so it points to something
	; that still exists when we return...
	; 
	mov	ds:[curRecord], cx
	jmp	done
endif	; _IMPEX_MERGE
InsertRecordToDatabase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeDeleteExisting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the record we found in our search.

CALLED BY:	(INTERNAL) InsertRecordToDatabase
PASS:		cx	= entry handle to biff
		dx	= offset within table
		sortBuffer = index field of record
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	quick-dial shme updated.
     		main table shrunk by one
		item is biffed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 	_IMPEX_MERGE
MergeDeleteExisting proc near
	.enter
	push	ds:[curOffset], ds:[curRecord]
	
	mov	ds:[curOffset], dx
	mov	ds:[curRecord], cx
	call	DeleteFromMainTable

if _QUICK_DIAL
	call	DeleteQuickDial
	; XXX: ERROR FLAG CHECK?
	call	UpdateMonikers
	; XXX: ERROR FLAG CHECK?
endif ; _QUICK_DIAL
	mov	di, ds:[curRecord]
	call	NewDBFree

	pop	ds:[curOffset], ds:[curRecord]
	.leave
	ret
MergeDeleteExisting endp
endif	; _IMPEX_MERGE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeUpdateOrAugment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the individual fields of the new record & duplicate
		record according to the merge/augment flag passed, adjusting
		the existing record accordingly.

CALLED BY:	(INTERNAL) InsertRecordToDatabase
PASS:		cx	= item handle of existing record
		bx	= ImpexMergeState (IMS_UPDATE/IMS_AUGMENT)
		ds	= dgroup
		ds:[curRecord] = new record with index, address, notes,
				(pizza only:) phonetic and zip-code fields
				filled in
		ds:[fieldHandles], ds:[fieldLengths] = data from which
				new record was created
		ds:[phoneHandles], ds:[phoneLengths], ds:[phoneTypeHandle] =
				phone numbers for the record.
RETURN:		nothing
DESTROYED:	?
SIDE EFFECTS:	new numbers may be added to existing record, etc.

PSEUDO CODE/STRATEGY:
		if new.address exists && (cur.address exists not || updating):
			; copy address from new to cur
			UpdateAddr(cur)
		if new.notes exists && (cur.notes exists not || updating):
			; swap notes handles, so cur gets the new notes and
			; old notes (if any) get nuked when new record gets it.
			xchg new.notes with cur.notes
		for i = 0 to max_phone_no_record:
		    if phoneHandles[i] != 0:
			type = GetPhoneTypeID(phoneTypeHandle[i])
			if type known:
				entry = FindPhoneByType(cur, type)
			if type unknown || entry exists not:
				; phone number is completely new, so add it
				InsertPhoneEntry(cur, 0, phoneHandles[i])
			else if entry->size == 0:
				; entry exists but is empty, so put in new data
				InsertPhoneEntry(cur, entry, phoneHandles[i])
			else if updating:
				; want to replace the existing entry with the
				; new data
				DeletePhoneEntry(cur, entry)
				InsertPhoneEntry(cur, entry, phoneHandles[i])

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_IMPEX_MERGE
MergeUpdateOrAugment proc near
		.enter
	;
	; If anything given for the address, update or augment the existing
	; record with the new data.
	; 
		mov	si, offset DBR_addrSize
		mov	dx, offset DBR_toAddr
		call	MergeUpdateOrAugmentField

	;
	; If anything given for notes, swap the notes item handles as
	; appropriate.
	; 
	    ;
	    ; See if the existing record has any notes.
	    ; 
		mov	di, cx
		call	DBLockNO
		mov	di, es:[di]
		mov	ax, es:[di].DBR_notes
		call	DBUnlock
		tst	ax
		jz	updateNotes		; => no notes, so give it the
						;  new ones
	    ;
	    ; If not updating, leave existing notes alone.
	    ; 
		cmp	bx, IMS_UPDATE
		jne	checkPhonetic
		
updateNotes:
	    ;
	    ; Swap the DBR_notes handles of the two records, so the old notes,
	    ; if any, will be freed when the new record gets destroyed.
	    ; 
		mov	di, ds:[curRecord]
		call	DBLockNO
		mov	di, es:[di]
		xchg	es:[di].DBR_notes, ax
		call	DBDirty
		call	DBUnlock
		
		mov	di, cx
		call	DBLockNO
		mov	di, es:[di]
		mov	es:[di].DBR_notes, ax
		call	DBDirty
		call	DBUnlock

checkPhonetic:
if 	PZ_PCGEOS
	;
	; If anything given for the phonetic spelling, update or augment
	; as appropriate.
	; 
		mov	si, offset DBR_phoneticSize
		mov	dx, offset DBR_toPhonetic
		call	MergeUpdateOrAugmentField

	;
	; If anything given for the zip-code, update or augment as appropriate
	; 
		mov	si, offset DBR_zipSize
		mov	dx, offset DBR_toZip
		call	MergeUpdateOrAugmentField

endif	; PZ_PCGEOS

	;
	;  Now loop through all the phone numbers.
	;
	;  First set curRecord to be the existing record for the duration of
	;  this loop, as it's used when inserting/deleting phone entries
	;  
		push	ds:[curRecord]
		mov	ds:[curRecord], cx
		clr	si		; si <- phoneHandles index
phoneLoop:
		tst	ds:[phoneHandles][si]
		jz	freePhoneType	; => no number in this field
		
	;
	; Point fieldHandles[TEFO_PHONE_NO] to the current phone number, for use
	; by Insert/DeletePhoneEntry
	; 
		mov	ax, ds:[phoneHandles][si]
		mov	ds:[fieldHandles][TEFO_PHONE_NO], ax
		mov	ax, ds:[phoneLengths][si]
		mov	ds:[fieldLengths][TEFO_PHONE_NO], ax
	;
	; See if the phone type is one already known in the current record.
	; Every record always has the predefined types, even if they're empty,
	; so we don't have to worry about getting a 0 index back for a
	; predefined phone type.
	;
	; MergeGetExistingPhoneEntry will free the phone type name block if
	; the type is already known.
	; 
		call	MergeGetExistingPhoneEntry
		mov	ds:[gmb].GMB_curPhoneIndex, ax
		jc	insertNew		; (ax == 0)
	;
	; It is. Make sure it's not just one of the predefined types that's
	; empty.
	; 
		tst	es:[di].PE_length
		call	DBUnlock
		jz	insertNew		; => empty, so always add new
	;
	; If updating, delete the current data.
	; 
		cmp	bx, IMS_UPDATE
		jne	nextPhone

		push	cx, si, bx, ax, dx
		call	DeletePhoneEntry
		pop	cx, si, bx, ax, dx

insertNew:
	;
	; Add the phone number at the selected index (or the end, if phone type
	; wasn't known before)
	; 
		tst	dx
		jnz	havePhoneType
	    ;
	    ; Type name wasn't in table before, so put it there now. Frees
	    ; phone type name block.
	    ;
		push	cx, si, bx
		call	AddPhoneTypeName
		pop	cx, si, bx

havePhoneType:
		push	cx, si, bx
		call	InsertPhoneEntry
		pop	cx, si, bx

nextPhone:
	;
	; Advance to the next phone entry.
	; 
			CheckHack <type phoneHandles eq 2>
		inc	si
		inc	si
		cmp	si, NUM_PHONE_TYPE_FIELDS * type phoneHandles
		jb	phoneLoop
	;
	; Free up the block that pointed to the phone type strings.
	;
		push	bx
		mov	bx, ds:[phoneTypeHandle]
		call	MemFree
		pop	bx

		pop	ds:[curRecord]
		.leave
		ret

freePhoneType:
	;
	; Nothing in the phone number, but might still have a phone type string
	; that needs to be freed.
	;
		call	MergeGetPhoneTypeHandle
		tst	ax
		jz	nextPhone
		xchg	bx, ax		; bx <- handle, ax <- saved bx
		call	MemFree
		mov_tr	bx, ax		; bx <- saved bx
		jmp	nextPhone
MergeUpdateOrAugment endp
endif	; _IMPEX_MERGE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeGetPhoneTypeHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the handle for the phone type name for the current
		phone index.

CALLED BY:	(INTERNAL) MergeUpdateOrAugment, MergeGetExistingPhoneEntry
PASS:		si	= phone number index
		ds	= dgroup
		phoneTypeHandle = set
RETURN:		ax	= handle of phone type string, or 0 if none
		dx	= length of phone type string
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/16/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_IMPEX_MERGE
MergeGetPhoneTypeHandle proc	near
		uses	si, bx, es
		.enter
	;
	; First find the handle & size of the desired type.
	; 
		mov	bx, ds:[phoneTypeHandle]
		call	MemLock
		mov	es, ax
			CheckHack <type PhoneTypeStruct eq type phoneHandles*2>
		shl	si
		mov	ax, es:[si].PTS_handle
		mov	dx, es:[si].PTS_size
		call	MemUnlock
EC <		tst	ax						>
EC <		jz	done						>
		Assert	handle, ax
EC <done:								>
		.leave
		ret
MergeGetPhoneTypeHandle endp
endif	; _IMPEX_MERGE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeGetExistingPhoneEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the existing record holds an entry for the phone type
		we're checking.

CALLED BY:	(INTERNAL) MergeUpdateOrAugment
PASS:		si	= index to phoneHandles of phone being checked
		cx	= item handle of existing record
		ds	= dgroup
RETURN:		carry set if record has no entry for this phone #
			es, di	= destroyed
			ax	= 0
		carry clear if found entry:
			es:di	= PhoneEntry
			ax	= index of entry
		dx	= phone type (0 if type is unknown)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_IMPEX_MERGE
MergeGetExistingPhoneEntry proc	near
		uses	bx, si, cx
		.enter
		call	MergeGetPhoneTypeHandle

	;
	; Stuff the handle & size into the field data for the phone type
	; field and try and map that to a phone type index.
	; 
		mov	ds:[fieldHandles][TEFO_PHONE_TYPE], ax
		mov	ds:[fieldLengths][TEFO_PHONE_TYPE], dx
		
		push	cx, di, bp
		call	GetPhoneTypeID
		pop	cx, di, bp
		tst	dx
		jz	noEntry		; => type unknown, so can't be a number
					;  for it in the existing record
	;
	; The phone type is known, which means there might be an entry for
	; it. Lock down the current record and prepare to loop over all its
	; phone entries.
	; 
		mov	di, cx
		call	DBLockNO
		mov	si, es:[di]
		mov	cx, es:[si].DBR_noPhoneNo	; cx <- # numbers
		add	si, es:[si].DBR_toPhone		; es:si <- first entry
		clr	ax				; ax <- index of first
phoneLoop:
	;
	; See if this entry is of the right type.
	; 
		cmp	es:[si].PE_type, dl
		je	foundIt
	;
	; Not. Advance the index counter and the entry pointer to the next
	; 
		inc	ax
		mov	bx, es:[si].PE_length
		lea	si, es:[si+bx+size PhoneEntry]
		loop	phoneLoop
	;
	; No entry of that type -- release the record and boogie with the
	; PTI in dx, still
	; 
		call	DBUnlock
noEntry:
		clr	ax
		stc			; CF <- entry not found
done:
		.leave
		ret

foundIt:
	;
	; Found the entry -- return the index in ax, the PE in es:di, and
	; the PTI in dx.
	; 
		mov	di, si
		clc
		jmp	done
MergeGetExistingPhoneEntry endp
endif	; _IMPEX_MERGE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeUpdateOrAugmentField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If appropriate, store the new data for a field into the
		existing record

CALLED BY:	(INTERNAL) MergeUpdateOrAugment
PASS:		ds:[curRecord]	= new record
		cx		= handle of existing record
		dx		= offset within DB_Record of offset to data
		si		= offset within DB_Record of field to check
				  for 0 => existing record has no data for
				  the record field
		bx		= ImpexMergeState
		ds:[fieldHandles][?] = set to new field data
RETURN:		nothing
DESTROYED:	ax, dx, si, es, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_IMPEX_MERGE
MergeUpdateOrAugmentField proc near
		uses	bx, cx
		.enter
	;
	; See if the field has any data in the new record.
	; 
		mov	di, ds:[curRecord]
		call	DBLockNO
		mov	di, es:[di]
		add	di, si
		mov	ax, es:[di]
		call	DBUnlock
		tst	ax
		jz	toDone		; => no new data, so no point in
					;  doing anything else

		cmp	bx, IMS_UPDATE
		je	update		; perform update regardless of current
					;  field contents
	;
	; Lock down the existing record to see if it has data for this field.
	; 
		mov	di, cx
		call	DBLockNO
		mov	bx, es:[di]
		tst	{word}es:[bx+si]
		call	DBUnlock
		jz	update		; => field not in existing, so update
toDone:
		jmp	done

update:
	;
	; Call the proper routine to perform the update from fieldHandles. Need
	; to set curRecord to the existing one, rather than the new one, before
	; making the call.
	;
	; Compute the difference in sizes between the fields.
	; 
	; ax	= number of bytes to copy in from the new record
	; 
		mov	di, cx
		call	DBLockNO
		mov	bx, es:[di]	; es:bx <- existing record
		sub	ax, es:[bx+si]
		je	copy		; => fields identical, so no adjustment
					;  needed
	;
	; Release the record (since DI gets effectively nuked during the call,
	; we not knowing where the item will end up) after figuring the
	; insertion/deletion point.
	; 
		push	si		; save size offset
		mov	si, dx		; si <- pointer offset
		mov	dx, es:[bx+si]	; dx <- offset for ins/del
		call	DBUnlock
	;
	; Perform the insertion/deletion.
	; 
		mov	di, cx		; di <- existing record
		mov	cx, ax		; cx <- # bytes to add/-# bytes to del
		tst	cx
		jl	deleteSpace	; => existing field too large

		call	DBInsertAtNO
		jmp	adjustPtrs
deleteSpace:
		neg	cx		; convert to # bytes to delete
		call	DBDeleteAtNO

adjustPtrs:
	;
	; Now adjust all the pointers in the record by the amount added/deleted,
	; if they point beyond the insert/delete point.
	; 
		call	DBLockNO
		mov	bx, es:[di]

	irp	field, <toPhone, toAddr, toPhonetic, toZip>
		local	adjustDone
	    ifdef DBR_&field
	    	cmp	si, offset DBR_&field	; see if this is the field
						;  we just messed with
		je	adjustDone		; => don't mess with pointer
		cmp	es:[bx].DBR_&field, dx
		jb	adjustDone		; => not affected (if ==, then
						;  adjusted field was empty
						;  before...)
		add	es:[bx].DBR_&field, ax
adjustDone:
	    endif	; field defined
	endm
		pop	dx		; dx <- size offset
		xchg	si, dx		; si <- size offset,
					;  dx <- pointer offset
	;
	; Adjust size of field to be correct.
	; 
		add	es:[bx+si], ax
copy:
	;
	; Copy data from the new record to the existing.
	;
	; *es:di = es:bx = existing record
	; ds = dgroup
	; dx = pointer offset
	; si = size offset
	;
	; First, point to the destination address.
	; 
		xchg	si, dx
		mov	ax, es:[bx+si]
		add	ax, bx
		push	ds		; preserve dgroup
		pushdw	esax		; save dest addr during next bit
	;
	; Lock down the source record.
	; 
		mov	di, ds:[curRecord]
		call	DBLockNO
		segmov	ds, es
		mov	bx, ds:[di]
	;
	; Fetch out the source pointer & size
	; 
		mov	ax, ds:[bx+si]	; ax <- pointer
		mov	si, dx		; si <- size offset
		mov	cx, ds:[bx+si]	; cx <- # bytes in field
		add	ax, bx
	;
	; Now move the data into the existing record from the new.
	; 
		mov_tr	si, ax		; ds:si <- source pointer
		popdw	esdi
		rep	movsb
	;
	; Dirty and unlock the existing record.
	; 
		call	DBDirty
		call	DBUnlock
	;
	; Unlock the new record.
	; 
		segmov	es, ds
		call	DBUnlock
		pop	ds
done:
		.leave
		ret
MergeUpdateOrAugmentField endp
endif	; _IMPEX_MERGE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMergeFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the mergeFlag, asking the user for his/her input if
		mergeFlag indicates we've not yet asked.

CALLED BY:	(INTERNAL) InsertRecordToDatabase
PASS:		ds	= dgroup
RETURN:		bx	= ImpexMergeState
DESTROYED:	ax, si
SIDE EFFECTS:	ds:[mergeFlag] will be changed if user indicated answer is
     			for all records

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_IMPEX_MERGE
GetMergeFlag	proc	near
	uses	cx, dx, bp
	.enter
	;
	; See if we already know what to do when we find a duplicate.
	; 
	mov	bx, ds:[mergeFlag]
	cmp	bx, IMS_HAVENT_ASKED
	jne	done			; => yes, we do
	;
	; We don't. Prep the dialog box with the index field.
	; 
	GetResourceHandleNS	ImpexMergeDialog, bx
	mov	si, offset ImpexMergeRecordName
	clr	cx				; cx <- null-terminated
	mov	dx, ds				; dx:bp <- string
	mov	bp, offset sortBuffer
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	;
	; Ask the user.
	; 
	mov	si, offset ImpexMergeDialog
	call	UserDoDialog
	;
	; Find out what the action is before we decide whether it applies to
	; subsequent records too.
	; 
	push	ax
	mov	si, offset ImpexMergeActionGroup
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	Assert	etype, ax, ImpexMergeState
	mov_tr	bx, ax			; bx <- ImpexMergeState
	pop	ax
	;
	; If command was "yes", it means answer should apply to all subsequent
	; records for which there are duplicates. Anything else (including
	; IC_NULL) means ask again later... (XXX: is this right for IC_NULL?)
	; 
	cmp	ax, IC_YES
	jne	done
	mov	ds:[mergeFlag], bx
done:
	.leave
	ret
GetMergeFlag	endp
endif	; _IMPEX_MERGE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadFieldData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a memory block and copy field data into it.

CALLED BY:	(INTERNAL) ReadInRecord

PASS:		ds:si - pointer to the text of field data
			*NOT* null terminated
		ax - size of the text
		dx - field counter (column number)
		es - dgroup

RETURN:		fieldHandles, fieldLengths updated
		carry set if there was an error

DESTROYED:	ax, cx, si, di

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision
	witt	1/94		DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadFieldData	proc	near		uses	bx, dx, bp	
	.enter

	cmp     dx, GEODEX_NUM_FIELDS+NUM_PHONE_TYPE_FIELDS; too many fields?
	jge     toQuit				; if so, just exit
	
	; allocate a data block to copy the text string into

	LocalNextChar	dsax			; add one for null character

	push	ax
	mov	cx, (HAF_STANDARD_LOCK shl 8) or 0 ; HeapAllocFlags
	call	MemAlloc			; allocate a block
	pop	cx
	LONG jc	exit				; exit if not enough memory

	; update 'fieldHandles' and 'fieldLengths'
 
	mov	di, dx				; di - index into fieldHandles 
	cmp	di, TEFI_LASTNAME		; index field?
	je	index				; do special parsing
	cmp	di, TEFI_PHONE_NAME1			; phone type entry?
	jge	phoneType			; if so, skip to handle it
	cmp	di, TEFI_PHONE1			; phone number entry?
	jge	phone
updateVar:
	shl	di, 1
	mov	es:fieldHandles[di], bx		; save the handle of block
SBCS<	mov	es:fieldLengths[di], cx		; save the length of block >
DBCS<	mov	dx, cx				; dx - text size	>
DBCS<	shr	dx, 1				; dx - text length	>
DBCS<	mov	es:fieldLengths[di], dx		; save the length of block	>
	jmp	copy

	; if index field, skip any space characters at the beginning
index:
	LocalGetChar	dx, dssi, noAdvance	; read in a character
	LocalIsNull	dx			; null char?

	je	done				; exit loop if null char
	LocalCmpChar	dx, ' '			; space char?
	jne	updateVar			; exit loop if not space char
	LocalNextChar	dssi
DBCS <	dec	cx							>
DBCS <	Assert	ne, cx, 0						>
	loop	index				; get the next character

done:
	; the entire string contains noting but space characters.
	; Mark it as a blank field.

	shl	di, 1
	clr	es:fieldHandles[di]		; save the handle of block
	clr	es:fieldLengths[di]		; save the size of block
	call	MemFree				; free the data block
toQuit:
	jmp	quit

phone:
	sub	di, TEFI_PHONE1			; phone entry
	shl	di, 1
	mov	es:phoneHandles[di], bx		; save the handle phone block  
SBCS<	mov	es:phoneLengths[di], cx		; save the size info  	>
DBCS<	mov	dx, cx				; dx - string size	>
DBCS<	shr	dx, 1				; dx - string length	>
DBCS<	mov	es:phoneLengths[di], dx		; save length info	>
	jmp	copy
phoneType:
	sub	di, TEFI_PHONE_NAME1
	push	ds, es, ax
	mov	bp, bx
	mov	bx, es:[phoneTypeHandle]	; lock the phone type
	call	MemLock				;  of handles and sizes
	jc	exit
	mov	ds, ax
CheckHack < (size PhoneTypeStruct) eq 4 >
	shl	di
	shl	di				; di = di*4
	mov	ds:[di].PTS_handle, bp		; save handle to type block
	mov	ds:[di].PTS_size, cx		; save size of type text
	call	MemUnlock
	pop	ds, es, ax
	mov	bx, bp				; handle of text block
copy:
	; now copy cell data into this newly allocated block

	LocalPrevChar	dscx			; cx - number of bytes to copy
	push	es				; save dgroup 
	mov	es, ax
	clr	di				; es:di - destination block
	rep	movsb				; copy the string
	LocalClrChar	ax			; null terminate the string
	LocalPutChar	esdi, ax
	call	MemUnlock			
	pop	es				; restore dgroup
quit:
	clc					; exit with carry clear
exit:
	.leave
	ret
ReadFieldData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TruncateFieldData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Truncate the field data if it contains more than GeoDex
		can handle.

CALLED BY:	(INTERNAL) ReadInRecord	

PASS:		dx - field counter (column number) 
		es - dgroup

RETURN:		nothing

DESTROYED:	ax, di, si, ds

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision
	witt	1/94		DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TruncateFieldData	proc	near	uses	bx
	.enter

	cmp	dx, GEODEX_NUM_FIELDS		; too many fields?
	jge	exit				; if so, just exit

	; if address or note field, GeoDex can handle large amount of data

	cmp	dx, TEFI_ADDRESS
	je	exit
	cmp	dx, TEFI_NOTES
	je	exit

if PZ_PCGEOS
	cmp	dx, TEFI_PHONETIC
	je	checkSize
	cmp	dx, TEFI_ZIP
	je	checkSize
endif
	; otherwise, check to see if there is too much data

	cmp	dx, TEFI_LASTNAME
	jne	phone

	; check index field for data overflow
PZ <checkSize:								>
	mov	di, dx
	shl	di, 1
	cmp	es:fieldLengths[di], SORT_BUFFER_LENGTH+1
	jle	exit				; if not too much data, exit

	; if there is too much data than GeoDex can handle, truncate it

SBCS<	mov	si, SORT_BUFFER_SIZE+(size char)  ; si - offset to end of data>
DBCS<	mov	si, SORT_BUFFER_SIZE+(size wchar) ; si - offset to end of data>
	mov	es:fieldLengths[di], si		; update the size info
	mov	bx, es:fieldHandles[di]		; bx - handle of data block
	tst	bx
	je	exit				; exit if no data block
	call	MemLock
	mov	ds, ax
SBCS <	mov	{char} ds:[si-1], C_NULL	; truncate the data	>
DBCS <	mov	{wchar} ds:[si-2], C_NULL	; truncate the data	>
	call	MemUnlock
	jmp	exit
phone:
	; check phone number field for data overflow

	mov	di, dx
	sub	di, TEFI_PHONE1			; phone entry
	shl	di, 1
	cmp	es:phoneLengths[di], PHONE_NO_LENGTH
	jle	exit				; if not too much data, exit

	; if there is too much data than GeoDex can handle, truncate it

	mov	si, PHONE_NO_LENGTH - 1	 	; si - max char length
	mov	es:phoneLengths[di], si		; update the size info
	mov	bx, es:phoneHandles[di]		; bx - handle of data block
	tst	bx
	je	exit				; exit if no data block
	call	MemLock
	mov	ds, ax
DBCS <	shl	si, 1				; si - offset to end of data >
	LocalClrChar	ds:[si]			; truncate the data
	call	MemUnlock
exit:
	.leave
	ret
TruncateFieldData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertPhone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert new phone entries into the record.  From phoneHandles[]
		and phoneLengths[] (impex local) to call InsertPhoneEntry.

CALLED BY:	(INTERNAL) ImportRecord

PASS:		ds - dgroup
		    phoneHandles, phoneLengths

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

PSEUDO CODE/STRATEGY:
		Foreach PhoneTypeIndex -> pti,
		    Suchthat phoneHandles[pti] != NULL_HANDLE,
			(* Copy phone to DB_Record *)
			Copy phone handle, phone length


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		For some reason, the old FAX number is preserved -- why?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertPhone	proc	near
	mov	cx, MAX_PHONE_NO_RECORD-1	; cx - maximum allowable phone entry
	clr	di
	mov	dx, PTI_HOME		; dx - phone number type name ID

mainLoop:
	mov	bx, ds:phoneHandles[di]	; bx - handle of data block
	tst	bx			; is there a phone entry?
	jnz	insert			; if so, insert phone entry
next:
	inc	dx			; next phone type field
	add	di, (size nptr)		; if not, 
	loop	mainLoop		; check the next entry
	jmp	exit

insert:
	mov	ds:fieldHandles[TEFO_PHONE_NO], bx  ; save data block handle
	mov	bx, ds:phoneLengths[di]		    ; bx - length of data block
	mov	ds:fieldLengths[TEFO_PHONE_NO], bx  ; save length of data block

	; insert the new phone entry into the record entry

	push	ds, dx, di, cx
	mov	ds:[gmb.GMB_curPhoneIndex], dx
	dec	ds:[gmb.GMB_curPhoneIndex]
if not _NDO2000
	cmp	ds:[gmb.GMB_curPhoneIndex], PTI_FAX
	jl	skip
	; add anything >= PTI_FAX (which is the first *index* of the first non-
	; standard phone number) as a "new number".
	; Setting GMB_curPhoneIndex to 0 causes DeletePhoneEntry
	; to do nothing, which is appropriate, since there is nothing there yet
	clr	ds:[gmb.GMB_curPhoneIndex]
	clr	dx
skip:
endif
	call	DeletePhoneEntry	; delete old phone entry from record
	call	InsertPhoneEntry	; add a new phone entry into record
	pop	ds, dx, di, cx
	clr	ds:phoneHandles[di]
	clr	ds:phoneLengths[di]	; clear the buffer
	jmp	next			; check the next entry
exit:
	mov	ds:[gmb.GMB_curPhoneIndex], PTI_HOME	; display HOME
	ret
InsertPhone	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertPhoneTypes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert new phone type entries into the record 

CALLED BY:	(INTERNAL) ImportRecord

PASS:		phoneTypeHandle

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	8/4/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertPhoneTypes	proc	near
	mov	cx, MAX_PHONE_NO_RECORD-1	; cx - max allowable phone
	clr	si
mainLoop:
	mov	bx, ds:[phoneTypeHandle]	; bx - phone type blk handle
	call	MemLock				; lock the block
	mov	es, ax				; es - seg of block
CheckHack < (size PhoneTypeStruct) eq 4 >
	mov	di, si
	shl	di
	shl	di				; di = si*4
	mov	ax, es:[di].PTS_handle		; get the handle
	mov	dx, es:[di].PTS_size		; size of text
	call	MemUnlock
	mov	bx, ax				; bx - block handle
	tst	bx				; is there a phone entry?
	jne	insert				; if so, skip
next:
	inc	si				; if not, 
	loop	mainLoop			; check the next entry
	jmp	exit
insert:
	mov	ds:fieldHandles[TEFO_PHONE_TYPE], bx	; save data block handle 
	mov	ds:fieldLengths[TEFO_PHONE_TYPE], dx	; save size of data block 

	; insert the new phone type entry

	push	cx, si				; save count, handle index
	call	GetPhoneTypeID			; dx - Phone type
	tst	dx				; is it new?
	jne	notNewType			; if not, jump
	call	AddPhoneTypeName		; add the new phone type
notNewType:
	pop	cx, si				; phone count, handle index
	;
	; if phone number exists, then just change type.  Otherwise
	; insert a blank entry.
	;
	mov	di, ds:[curRecord]
	call	DBLockNO			; lock current record
	mov	di, es:[di]			; es:di - DB_Record
	mov	ax, si				; loop count
	inc	ax				; phone # count
	cmp	ax, es:[di].DBR_noPhoneNo	; do we need to add an entry?
	jb	dontInsert			; in not, skip insert
	mov	ax, es:[di].DBR_noPhoneNo
	call	DBUnlock
	clr	ds:fieldHandles[TEFO_PHONE_NO]	; no phone number
	clr	ds:fieldLengths[TEFO_PHONE_NO]	; don't add space
	push	bx, cx, dx, si
	mov	ds:[gmb.GMB_curPhoneIndex], ax	; index to number to insert
	call	InsertPhoneEntry		; add the phone entry
	pop	bx, cx, dx, si
	jmp	next				; done with this entry
dontInsert:
	add	di, es:[di].DBR_toPhone
	clr	ax				; start with 1st entry	
	mov	bp, si
	inc	bp				; phone count
findPhoneLoop:
	cmp	ax, bp				; is this the entry?
	je	foundPhone
if DBCS_PCGEOS
	push	ax				; save count
	mov	ax, es:[di].PE_length		; length of name
	shl	ax, 1				; size of name
	add	di, ax
	pop	ax				; restore count
else
	add	di, es:[di].PE_length
endif
	add	di, size PhoneEntry		; next entry
	inc	ax
	jmp	findPhoneLoop
foundPhone:
	mov	es:[di].PE_type, dl		; store the type
	call	DBUnlock			; unlock the block
	jmp	next				; check the next entry
exit:
	mov	bx, ds:[phoneTypeHandle]
	call	MemFree				; free the block
	ret
InsertPhoneTypes	endp

Impex	ends
