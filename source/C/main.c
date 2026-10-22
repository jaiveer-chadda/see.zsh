/// @file main.c

#include <stdio.h>
#include <errno.h>
#include <wchar.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <locale.h>
#include <inttypes.h>

#include "graphics/graphics.h"

/* —— Definitions —————————————————————————————————————————————————————————————————————————————————————————————————— */

/** @brief `BUFSIZE` == `(1 << 12)` == `4,096 B` == `4 kB` */
#define BUFSIZE (1 << 12)

#define IN_RANGE(val, min, max) ((min) <= (val) && (val) <= (max))

typedef int errno_t;
typedef uint32_t chr32_t;
typedef unsigned char uchar;

/* —— getFilePointer() ————————————————————————————————————————————————————————————————————————————————————————————— */

static inline FILE *getFilePointer(const int argc, const char *const *const argv) {

	if (argc < 2) return stdin;

	/* —————————————————————————————————————————————————————— */

	const char *const input_file = argv[1];
	FILE *const pfile = fopen(input_file, "r");

	if (pfile != NULL) return pfile;

	/* —————————————————————————————————————————————————————— */

	const errno_t fopen_errno = errno;

	fprintf(stderr, "%s: unable to open `%s`: %d - %s\n",
		argv[0], input_file, fopen_errno, strerror(fopen_errno)
	);

	return NULL;
}

/* —— processChar() ———————————————————————————————————————————————————————————————————————————————————————————————— */

#define DO_OCT_ESC(c)  IN_RANGE(c, '\1', '\7' )
#define DO_HEX_ESC(c) (IN_RANGE(c,'\x8','\x1F') || (c) == '\x7F')

static inline CharType getASCII(const uchar chr) {
	switch (chr) {
		case ' ' : putwc( L'·', stdout); return CHAR_SPACE	;
		case '\0': fputs("\\0", stdout); return CHAR_NULL	;
		case '\a': fputs("\\a", stdout); return CHAR_GEN_ESC;
		case '\b': fputs("\\b", stdout); return CHAR_GEN_ESC;
		case '\t': fputs("\\t", stdout); return CHAR_TAB	;
		case '\v': fputs("\\v", stdout); return CHAR_TAB	;
		case '\f': fputs("\\f", stdout); return CHAR_GEN_ESC;
		case '\r': fputs("\\r", stdout); return CHAR_LINE	;
		case'\33': fputs("\\e", stdout); return CHAR_ESC	;
		case '\n':	puts("\\n"		  ); return CHAR_LINE	;

		default: {
			if		(DO_OCT_ESC(chr)) printf("\\%hhu", (uint8_t)chr);
			else if	(DO_HEX_ESC(chr)) printf("\\%02X", (uint8_t)chr);
			else putchar(chr);

			return CHAR_ASCII;
		}
	}
}

/* ————————————————————————————————————————————————————————————————————————————————————————————————————————————————— */

#define NEW_SEQ(by)	(by_left = ((by) - 1), seq_len = (by))
#define END_SEQ		(by_left = 0, seq_len = 0, payload = 0)
#define SEQ_ACTIVE	(by_left != 0)

static inline void processChar(const uchar chr) {
	static const chr32_t SURROGATE_MIN = 0xD800, SURROGATE_MAX = 0xDFFF;
	static const chr32_t MAX_CPOINT = 0x10FFFF;
	static const chr32_t MIN_CPOINTS[] = {
		0, 0,
		(1 <<  7), // below this, a single ASCII byte should be used
		(1 << 11), // below this, 2 bytes suffice
		(1 << 16), // below this, 3 bytes suffice
	};

	/* —————————————————————————————————————————————————————— */

	static chr32_t payload = 0; /** Unicode/UTF-8 character value. */
	static uint8_t seq_len = 0; /** Length of current sequence. */
	static uint8_t by_left = 0; /** Bytes left/remaining. */

	CharType c_type = 0; /** The type of the byte just parsed. */

	/* —————————————————————————————————————————————————————— */

	// a non-cont byte being encountered while a seq is unfinished means that the seq was truncated
	if		((chr >> 6) != 0b10 && SEQ_ACTIVE) { /* processMultibyteChar(( payload = 0 ), CHAR_INVALID); */ }

	if		((chr >> 7) == 0b0		) c_type = getASCII(chr),END_SEQ; // ASCII character
	else if	((chr >> 1) == 0b1100000) c_type = CHAR_INVALID, END_SEQ; // overlong encoding
	else if ((chr >> 6) == 0b10		) {	// check whether we were expecting a continuation byte or not
		if (!SEQ_ACTIVE)			  c_type = CHAR_INVALID, END_SEQ;
		else						  c_type = CHAR_CONTINU, by_left-- , payload |= (chr & 0b111111) << (6 * by_left);
	}									// header bytes for multibyte chars
	else if ((chr >> 5) == 0b110	) c_type = CHAR_2B_HEAD, NEW_SEQ(2), payload  = (chr &	0b11111) << (6 * by_left);
	else if ((chr >> 4) == 0b1110	) c_type = CHAR_3B_HEAD, NEW_SEQ(3), payload  = (chr &	 0b1111) << (6 * by_left);
	else if ((chr >> 3) == 0b11110	) c_type = CHAR_4B_HEAD, NEW_SEQ(4), payload  = (chr &	  0b111) << (6 * by_left);

	else							  c_type = CHAR_INVALID, END_SEQ; // invalid byte (too large)

	assert(seq_len <= 4);
	assert(by_left <= 3);

	/* —————————————————————————————————————————————————————— */

	// continue to the next char if:
	//	a sequence is still in progress (i.e. after a header byte, or after a cont byte which hasn't finished its seq)
	//	or the parsed char was an ASCII char (in which case we would have already processed it)
	if (SEQ_ACTIVE || CHAR_IS_ASCII(c_type)) return;

	// by this point, the byte has been classified and `by_left` is 0, so either we just parsed:
	//	- a single-byte sequence (ASCII, `0xC0`/`0xC1`, `0xF8 → 0xFF`, a stray continuation byte)
	//	- the last continuation byte of a multi-byte char

	if (c_type == CHAR_CONTINU) { // if we just finished a multibyte char (i.e. just parsed a continuation byte)
		if (!IN_RANGE(payload, MIN_CPOINTS[seq_len], MAX_CPOINT) ||	// if the resultant codepoint is out of bounds
			(IN_RANGE(payload, SURROGATE_MIN, SURROGATE_MAX))		//	or is a UTF-16 surrogate codepoint
		) c_type = CHAR_INVALID; // then it's an invalid sequence, and should be marked as such

		seq_len = 0; // since we've finished a multibyte char, reset the sequence length back to 0
	}

	/* processMultibyteChar(payload, c_type); */
}

/* —— readFile() ——————————————————————————————————————————————————————————————————————————————————————————————————— */

static inline int readFile(FILE *const pfile) {
	char buffer[BUFSIZE];
	size_t read_len;

	/* —————————————————————————————————————————————————————— */

	// read `BUFSIZE` objects, each `1` byte long
	while (( read_len = fread(buffer, sizeof(buffer[0]), sizeof(buffer), pfile) )) {
		for (size_t i = 0; i < read_len; i++) {
			processChar(buffer[i]);
		}
	}

	/* —————————————————————————————————————————————————————— */

	return 0;
}

/* —— main() ——————————————————————————————————————————————————————————————————————————————————————————————————————— */

int main(const int argc, const char *const *const argv) {

	const char *const locale = setlocale(LC_ALL, "");
	if(!strstr(locale, "UTF-8")) fprintf(stderr, "Warning: Non-UTF-8 locale `%s`\n", locale);

	/* —————————————————————————————————————————————————————— */

	FILE *const pfile = getFilePointer(argc, argv);
	if (pfile == NULL) return 1;

	/* —————————————————————————————————————————————————————— */

	const int retcode = readFile(pfile);

	/* —————————————————————————————————————————————————————— */

	if (pfile != stdin) fclose(pfile);
	return retcode;
}

/* ————————————————————————————————————————————————————————————————————————————————————————————————————————————————— */

// spell:ignoreRegexp /\b0b[01]*[a-z]*\b/g
