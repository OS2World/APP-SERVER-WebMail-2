#
#  Compface - 48x48x1 image compression and decompression
#

NAME		= compface
UNNAME		= rxface.dll
LIBNAME		= lib$(NAME).a
OBJECTS		= arith.obj file.obj gen.obj uncompface.obj compress.obj rxface.obj

CC		= gcc
CFLAGS		= -g -DHAVE_FCNTL_H -DHAVE_STRERROR -Zsys -Zmt

%.obj: %.c
	$(CC) $(CFLAGS) -Zomf -c $< -o $@

all:		$(UNNAME)

rxface.dll: $(OBJECTS) rxface.def
	$(CC) $(CFLAGS) -Zomf -Zdll -Zmap -Zlinker /MAP $^ -o $@

clean:
	rm *.dll *.obj *.map
