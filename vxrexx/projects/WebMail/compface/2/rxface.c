
/*  @(#)uncmain.c 1.4 91/10/24
 *
 *  Uncompface - 48x48x1 image decompression.
 *
 *  Copyright (c) James Ashton - Sydney University - June 1990.
 *
 *  Written 11th November 1889.
 *
 *  Permission is given to distribute these sources, as long as the
 *  copyright messages are not removed, and no monies are exchanged.
 *
 *  No responsibility is taken for any errors on inaccuracies inherent
 *  either to the comments or the code of this program, but if reported
 *  to me, then an attempt will be made to fix them.
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif

#ifdef	STDC_HEADERS
#include <stdlib.h>
#else	/* Not STDC_HEADERS */
extern void exit ();
extern char *malloc ();
#endif	/* STDC_HEADERS */

#ifdef HAVE_STRINGS_H
#include <strings.h>
#else
#include <string.h>
#endif

#include "compface.h"

/* the buffer is longer than needed to handle sparse input formats */
#define FACEBUFLEN 2048
char fbuf[FACEBUFLEN];

/* IO file descriptors and their names */
int infile    = 0;
char *inname  = "<stdin>";
int outfile   = 1;
char *outname = "<stdout>";

/* basename of executable */
char *cmdname;

/* error handling definitions follow */

#ifndef HAVE_STRERROR
extern int errno, sys_nerr;
extern char *sys_errlist[];
#else
extern int errno;
char *strerror();
char *strerrorwrap();
#endif

extern void exit P((int)) ;

/* This really shouldn't be done with cpp */
/*#ifndef HAVE_STRERROR
#define ERR ((errno < sys_nerr) ? sys_errlist[errno] : "")
#else
#define ERR (strerrorwrap(errno))
#endif */

#define INITERR(s) {(void)strcat(fbuf, ": ");\
					(void)strcat(fbuf, (s));}
#define ADDERR(s) (void)strcat(fbuf, (s));
#define ERROR {(void)strcat(fbuf, "\n");\
				(void)write(2, fbuf, strlen(fbuf)); exit(1);}
#define INITWARN(s) {(void)strcat(fbuf, ": (warning) ");\
					(void)strcat(fbuf, (s));}
#define ADDWARN(s) (void)strcat(fbuf, (s));
#define WARN {(void)strcat(fbuf, "\n"); (void)write(2, fbuf, strlen(fbuf));}

#define     INCL_REXXSAA
//#include    <rexxsaa.h> used with OS/2 ToolKit only
#include <os2emx.h>     //used with emx pgcc/gcc only
#define  RETSTR_INVALID  40
#define  RETSTR_OK        0
//RexxFunctionHandler dll_uncompface; // Not needed for gcc, only for C/Set

ULONG CompFace(CHAR *name,         /* Routine name */
               ULONG numargs,      /* Number of arguments */
               RXSTRING args[],    /* Null-terminated RXSTRINGs array*/
               CHAR *queuename,    /* Current external data queue name */
               RXSTRING *retstr)   /* returning RXSTRING  */
{
 int i;

 if (numargs!=1)
  return RETSTR_INVALID;

 strcpy(fbuf,args[0].strptr);

 i = compface(fbuf);

 retstr->strlength = strlen(fbuf);
 retstr->strptr=fbuf;

 return RETSTR_OK;
}


ULONG UncFace(CHAR *name,         /* Routine name */
               ULONG numargs,      /* Number of arguments */
               RXSTRING args[],    /* Null-terminated RXSTRINGs array*/
               CHAR *queuename,    /* Current external data queue name */
               RXSTRING *retstr)   /* returning RXSTRING  */
{
 int i;

 if (numargs!=2)
  return RETSTR_INVALID;

 if(atoi(args[0].strptr)<0|atoi(args[0].strptr)>1)
  return RETSTR_INVALID;

 compface_xbitmap=atoi(args[0].strptr);

 strcpy(fbuf,args[1].strptr);

 i = uncompface(fbuf);

 retstr->strlength = strlen(fbuf);
 retstr->strptr=fbuf;

 return RETSTR_OK;
}

#ifdef HAVE_STRERROR
char *strerrorwrap(err)
int err;
{
   char *c = strerror(err);
   return ((c) ? (c) : "" );
}
#endif

