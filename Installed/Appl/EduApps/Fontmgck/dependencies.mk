ASMTOOLS.obj \
ASMTOOLS.eobj: ASMTOOLS/ASMTOOLSMANAGER.ASM \
                GEOS.DEF RESOURCE.DEF GSTRING.DEF GRAPHICS.DEF FONTID.DEF \
                FONT.DEF COLOR.DEF TEXT.DEF CHAR.DEF
FONTDRVR.obj \
FONTDRVR.eobj: FONTDRVR/FONTDRVRMANAGER.ASM \
                GEOS.DEF
CHARSET.obj \
CHARSET.eobj: STDAPP.GOH OBJECT.GOH UI.GOH OBJECTS/METAC.GOH \
                OBJECTS/INPUTC.GOH OBJECTS/CLIPBRD.GOH \
                OBJECTS/UIINPUTC.GOH IACP.GOH OBJECTS/WINC.GOH \
                OBJECTS/GPROCC.GOH ALB.GOH OBJECTS/PROCESSC.GOH \
                OBJECTS/VISC.GOH OBJECTS/VCOMPC.GOH OBJECTS/VCNTC.GOH \
                OBJECTS/GAPPC.GOH OBJECTS/GENC.GOH OBJECTS/GINTERC.GOH \
                OBJECTS/GPRIMC.GOH OBJECTS/GDISPC.GOH OBJECTS/GTRIGC.GOH \
                OBJECTS/GVIEWC.GOH OBJECTS/GTEXTC.GOH OBJECTS/VTEXTC.GOH \
                OBJECTS/GCTRLC.GOH GCNLIST.GOH SPOOL.GOH \
                OBJECTS/GFSELC.GOH OBJECTS/GGLYPHC.GOH \
                OBJECTS/GDOCCTRL.GOH OBJECTS/GDOCGRPC.GOH \
                OBJECTS/GDOCC.GOH OBJECTS/GCONTC.GOH OBJECTS/GDCTRLC.GOH \
                OBJECTS/GEDITCC.GOH OBJECTS/GBOOLGC.GOH \
                OBJECTS/GITEMGC.GOH OBJECTS/GDLISTC.GOH \
                OBJECTS/GITEMC.GOH OBJECTS/GBOOLC.GOH \
                OBJECTS/GGADGETC.GOH OBJECTS/GTOOLCC.GOH \
                OBJECTS/GVALUEC.GOH OBJECTS/GTOOLGC.GOH \
                OBJECTS/HELPCC.GOH CHARSET.GOH
CHARSET.obj \
CHARSET.eobj: CHARSET/CHARSET.GOC GEOS.H HEAP.H GEODE.H RESOURCE.H EC.H \
                OBJECT.H LMEM.H GRAPHICS.H FONTID.H FONT.H COLOR.H \
                GSTRING.H TIMER.H VM.H DBASE.H LOCALIZE.H ANSI/CTYPE.H \
                TIMEDATE.H FILE.H SLLANG.H SYSTEM.H GEOWORKS.H CHUNKARR.H \
                OBJECTS/HELPCC.H DISK.H DRIVE.H INPUT.H CHAR.H HWR.H \
                WIN.H UDIALOG.H OBJECTS/GINTERC.H OBJECTS/TEXT/TCOMMON.H \
                STYLESH.H DRIVER.H THREAD.H PRINT.H INTERNAL/SPOOLINT.H \
                SERIALDR.H PARALLDR.H HUGEARR.H FILEENUM.H
DRAWFONT.obj \
DRAWFONT.eobj: STDAPP.GOH OBJECT.GOH UI.GOH OBJECTS/METAC.GOH \
                OBJECTS/INPUTC.GOH OBJECTS/CLIPBRD.GOH \
                OBJECTS/UIINPUTC.GOH IACP.GOH OBJECTS/WINC.GOH \
                OBJECTS/GPROCC.GOH ALB.GOH OBJECTS/PROCESSC.GOH \
                OBJECTS/VISC.GOH OBJECTS/VCOMPC.GOH OBJECTS/VCNTC.GOH \
                OBJECTS/GAPPC.GOH OBJECTS/GENC.GOH OBJECTS/GINTERC.GOH \
                OBJECTS/GPRIMC.GOH OBJECTS/GDISPC.GOH OBJECTS/GTRIGC.GOH \
                OBJECTS/GVIEWC.GOH OBJECTS/GTEXTC.GOH OBJECTS/VTEXTC.GOH \
                OBJECTS/GCTRLC.GOH GCNLIST.GOH SPOOL.GOH \
                OBJECTS/GFSELC.GOH OBJECTS/GGLYPHC.GOH \
                OBJECTS/GDOCCTRL.GOH OBJECTS/GDOCGRPC.GOH \
                OBJECTS/GDOCC.GOH OBJECTS/GCONTC.GOH OBJECTS/GDCTRLC.GOH \
                OBJECTS/GEDITCC.GOH OBJECTS/GBOOLGC.GOH \
                OBJECTS/GITEMGC.GOH OBJECTS/GDLISTC.GOH \
                OBJECTS/GITEMC.GOH OBJECTS/GBOOLC.GOH \
                OBJECTS/GGADGETC.GOH OBJECTS/GTOOLCC.GOH \
                OBJECTS/GVALUEC.GOH OBJECTS/GTOOLGC.GOH \
                OBJECTS/HELPCC.GOH
DRAWFONT.obj \
DRAWFONT.eobj: DRAWFONT/DRAWFONT.GOC GEOS.H HEAP.H GEODE.H RESOURCE.H \
                EC.H OBJECT.H LMEM.H GRAPHICS.H FONTID.H FONT.H COLOR.H \
                GSTRING.H TIMER.H VM.H DBASE.H LOCALIZE.H ANSI/CTYPE.H \
                TIMEDATE.H FILE.H SLLANG.H SYSTEM.H GEOWORKS.H CHUNKARR.H \
                OBJECTS/HELPCC.H DISK.H DRIVE.H INPUT.H CHAR.H HWR.H \
                WIN.H UDIALOG.H OBJECTS/GINTERC.H OBJECTS/TEXT/TCOMMON.H \
                STYLESH.H DRIVER.H THREAD.H PRINT.H INTERNAL/SPOOLINT.H \
                SERIALDR.H PARALLDR.H HUGEARR.H FILEENUM.H ANSI/STRING.H \
                ANSI/STDIO.H MATH.H FONTMAGI.H
FONTM.obj \
FONTM.eobj: STDAPP.GOH OBJECT.GOH UI.GOH OBJECTS/METAC.GOH \
                OBJECTS/INPUTC.GOH OBJECTS/CLIPBRD.GOH \
                OBJECTS/UIINPUTC.GOH IACP.GOH OBJECTS/WINC.GOH \
                OBJECTS/GPROCC.GOH ALB.GOH OBJECTS/PROCESSC.GOH \
                OBJECTS/VISC.GOH OBJECTS/VCOMPC.GOH OBJECTS/VCNTC.GOH \
                OBJECTS/GAPPC.GOH OBJECTS/GENC.GOH OBJECTS/GINTERC.GOH \
                OBJECTS/GPRIMC.GOH OBJECTS/GDISPC.GOH OBJECTS/GTRIGC.GOH \
                OBJECTS/GVIEWC.GOH OBJECTS/GTEXTC.GOH OBJECTS/VTEXTC.GOH \
                OBJECTS/GCTRLC.GOH GCNLIST.GOH SPOOL.GOH \
                OBJECTS/GFSELC.GOH OBJECTS/GGLYPHC.GOH \
                OBJECTS/GDOCCTRL.GOH OBJECTS/GDOCGRPC.GOH \
                OBJECTS/GDOCC.GOH OBJECTS/GCONTC.GOH OBJECTS/GDCTRLC.GOH \
                OBJECTS/GEDITCC.GOH OBJECTS/GBOOLGC.GOH \
                OBJECTS/GITEMGC.GOH OBJECTS/GDLISTC.GOH \
                OBJECTS/GITEMC.GOH OBJECTS/GBOOLC.GOH \
                OBJECTS/GGADGETC.GOH OBJECTS/GTOOLCC.GOH \
                OBJECTS/GVALUEC.GOH OBJECTS/GTOOLGC.GOH \
                OBJECTS/HELPCC.GOH OBJECTS/GVIEWCC.GOH \
                OBJECTS/TEXT/TCTRLC.GOH RULER.GOH OBJECTS/COLORC.GOH \
                OBJECTS/STYLES.GOH CHARSET.GOH FONTM/FONT_UI.GOH \
                BREADBOX.GOH ART/APPICON.GOH ART/MONIKERS.GOH
FONTM.obj \
FONTM.eobj: FONTM/FONTM.GOC GEOS.H HEAP.H GEODE.H RESOURCE.H EC.H \
                OBJECT.H LMEM.H GRAPHICS.H FONTID.H FONT.H COLOR.H \
                GSTRING.H TIMER.H VM.H DBASE.H LOCALIZE.H ANSI/CTYPE.H \
                TIMEDATE.H FILE.H SLLANG.H SYSTEM.H GEOWORKS.H CHUNKARR.H \
                OBJECTS/HELPCC.H DISK.H DRIVE.H INPUT.H CHAR.H HWR.H \
                WIN.H UDIALOG.H OBJECTS/GINTERC.H OBJECTS/TEXT/TCOMMON.H \
                STYLESH.H DRIVER.H THREAD.H PRINT.H INTERNAL/SPOOLINT.H \
                SERIALDR.H PARALLDR.H HUGEARR.H FILEENUM.H ANSI/STRING.H \
                ANSI/STDIO.H FONTMAGI.H GSOL.H
NONLIN.obj \
NONLIN.eobj: STDAPP.GOH OBJECT.GOH UI.GOH OBJECTS/METAC.GOH \
                OBJECTS/INPUTC.GOH OBJECTS/CLIPBRD.GOH \
                OBJECTS/UIINPUTC.GOH IACP.GOH OBJECTS/WINC.GOH \
                OBJECTS/GPROCC.GOH ALB.GOH OBJECTS/PROCESSC.GOH \
                OBJECTS/VISC.GOH OBJECTS/VCOMPC.GOH OBJECTS/VCNTC.GOH \
                OBJECTS/GAPPC.GOH OBJECTS/GENC.GOH OBJECTS/GINTERC.GOH \
                OBJECTS/GPRIMC.GOH OBJECTS/GDISPC.GOH OBJECTS/GTRIGC.GOH \
                OBJECTS/GVIEWC.GOH OBJECTS/GTEXTC.GOH OBJECTS/VTEXTC.GOH \
                OBJECTS/GCTRLC.GOH GCNLIST.GOH SPOOL.GOH \
                OBJECTS/GFSELC.GOH OBJECTS/GGLYPHC.GOH \
                OBJECTS/GDOCCTRL.GOH OBJECTS/GDOCGRPC.GOH \
                OBJECTS/GDOCC.GOH OBJECTS/GCONTC.GOH OBJECTS/GDCTRLC.GOH \
                OBJECTS/GEDITCC.GOH OBJECTS/GBOOLGC.GOH \
                OBJECTS/GITEMGC.GOH OBJECTS/GDLISTC.GOH \
                OBJECTS/GITEMC.GOH OBJECTS/GBOOLC.GOH \
                OBJECTS/GGADGETC.GOH OBJECTS/GTOOLCC.GOH \
                OBJECTS/GVALUEC.GOH OBJECTS/GTOOLGC.GOH \
                OBJECTS/HELPCC.GOH
NONLIN.obj \
NONLIN.eobj: NONLIN/NONLIN.GOC GEOS.H HEAP.H GEODE.H RESOURCE.H EC.H \
                OBJECT.H LMEM.H GRAPHICS.H FONTID.H FONT.H COLOR.H \
                GSTRING.H TIMER.H VM.H DBASE.H LOCALIZE.H ANSI/CTYPE.H \
                TIMEDATE.H FILE.H SLLANG.H SYSTEM.H GEOWORKS.H CHUNKARR.H \
                OBJECTS/HELPCC.H DISK.H DRIVE.H INPUT.H CHAR.H HWR.H \
                WIN.H UDIALOG.H OBJECTS/GINTERC.H OBJECTS/TEXT/TCOMMON.H \
                STYLESH.H DRIVER.H THREAD.H PRINT.H INTERNAL/SPOOLINT.H \
                SERIALDR.H PARALLDR.H HUGEARR.H FILEENUM.H MATH.H \
                FONTMAGI.H

FONTMGCKEC.geo FONTMGCK.geo : GEOS.LDF UI.LDF TEXT.LDF ANSIC.LDF COLOR.LDF GSOL.LDF 