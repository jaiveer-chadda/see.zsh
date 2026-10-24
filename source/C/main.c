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

/**
 * @brief The size of the buffer read into by `fread`.
 *
 * ```C
 * BUFSIZE == (1 << 12) == 4,096 B == 4 kB
 * ```
 */
#define BUFSIZE (1 << 12)

/** @brief The maximum number of bytes it takes to encode a Unicode character. */
#define MAX_SEQ_LEN 4

/**
 * @brief Test if a value is within a range (inclusive).
 *
 * @return `true` if `val` is in the range `[min,max]`,
 * @return `false` otherwise
 */
#define IN_RANGE(val, min, max) ((min) <= (val) && (val) <= (max))

/* —————————————————————————————————————————————————————— */

typedef int errno_t;
typedef uint8_t char8_t;
typedef uint32_t chr32_t;

/* —— getFilePointer() ————————————————————————————————————————————————————————————————————————————————————————————— */

/**
 * @brief Get a pointer to the file referenced by the filepath in `argv[1]`.
 *
 * If no arguments were passed to the program (`argc == 1`), return a pointer to `stdin`.
 *
 * @param argc[in] The number of arguments passed to the program.
 * @param argv[in] The array of string arguments passed to the program.
 *
 * @return `FILE*` – a pointer to the file referenced by the filepath in `argv[1]`.
 */
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

/* —— processMultibyteChar() ——————————————————————————————————————————————————————————————————————————————————————— */

/**
 * @brief Process & print a multibyte UTF-8 character.
 *
 * @param type[in]		The type of the last byte parsed (usually only relevant to check it equals `CHAR_INVALID`).
 * @param seq_buf[in]	An array containing the individual bytes that make up a UTF-8 character.
 * @param seq_len[in]	The number of significant elements in `seq_buf`.
 * @param codepoint[in]	The UTF-8 codepoint created from parsing the first `seq_len` characters of `seq_buf`.
 */
static inline void processMultibyteChar(
	const char8_t seq_buf[MAX_SEQ_LEN], const uint8_t seq_len, const chr32_t codepoint, const CharType type
) {
	(void)codepoint, (void)type;

	fputs("\33[31m", stdout);

	for (uint8_t i = 0; i < seq_len; i++) {
		assert(seq_buf[i] != '\0');
		putchar(seq_buf[i]);
	}

	fputs("\33[m", stdout);
}

/* —— processASCIIChar() ——————————————————————————————————————————————————————————————————————————————————————————— */

#define DO_OCT_ESC(c)  IN_RANGE(c, '\1', '\7' )
#define DO_HEX_ESC(c) (IN_RANGE(c,'\x8','\x1F') || (c) == '\x7F')

/**
 * @brief Process & print an ASCII character.
 *
 * Process any character in the range `0x00` —→ `0x7F`.
 *
 * @pre `0x00 <= chr <= 0x7F`
 *
 * @param chr[in] The character to be processed.
 * @return `CharType` – The type of character that was processed.
 */
static inline CharType processASCIIChar(const char8_t chr) {
	assert(IN_RANGE(chr, 0x00, 0x7F));

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

/* —— processChar() ———————————————————————————————————————————————————————————————————————————————————————————————— */

/** @brief Reset `seq_buf` to its default state (all nullbytes). */
#define RESET_BUF	(memset(seq_buf, 0, sizeof(seq_buf)))
/** @brief Set the buffer at the current position to `c`.
 *
 * Assign `c` to `seq_buf`, indexed at the current character position (`seq_len - by_left - 1`).
 */
#define SET_BUF(c)	(seq_buf[seq_len - by_left - 1] = (c))

/** @brief Set up a new sequence of length `by`. */
#define NEW_SEQ(by)	(by_left = ((by) - 1), seq_len = (by), SET_BUF(chr))
/** @brief Reset the active sequence (called on failure). */
#define END_SEQ		(by_left = 0, seq_len = 0, payload = 0, RESET_BUF)
/** @brief Successfully complete the parsing of this character, adding its value to the buffer. */
#define CON_SEQ		(by_left--, SET_BUF(chr))

/** @brief True if the function is expecting at least one more continuation byte. */
#define SEQ_ACTIVE	(by_left != 0)

/* —————————————————————————————————————————————————————— */

/** @brief Lower bound of the UTF-16 surrogate codepoints, the values of which are disallowed in UTF-8. */
#define SURROGATE_MIN	((chr32_t)0xD800)
/** @brief Upper bound of the UTF-16 surrogate codepoints, the values of which are disallowed in UTF-8. */
#define SURROGATE_MAX	((chr32_t)0xDFFF)

/** @brief The largest UTF-8 codepoint specified by the [Unicode Standard](https://www.unicode.org/standard). */
#define MAX_CPOINT		((chr32_t)0x10FFFF)
/** @brief An array of the minimum accepted codepoints for each possible length of sequence.
 *
 * ---
 *
 * Below any of these minima, a multibyte character can (and must) be represented by a shorter sequence.
 *
 * To eliminate ambiguity (and a few other issues), the [Unicode Standard](https://www.unicode.org/standard) declares
 *	that these "overlong" sequences are invalid, and should not be parsed as UTF-8, no matter their codepoint.
 *
 * ---
 *
 * @note Sequences can be 1, 2, 3, or 4 bytes long.
 *
 *	- There are no sequences of length 0. This array _should_ never (and hopefully by design, _will_ never)
 *		be indexed at position `0`. As an acknowledgement, of this, `MIN_CPOINTS[0]` is set to `false`.
 *
 *	- Sequences which are a single byte long are ASCII characters. They do not have a minimum codepoint, therefore
 *		can be said to have a minimum code point of `0`.
 *
 */
#define MIN_CPOINTS		((chr32_t[MAX_SEQ_LEN + 1]){										\
	false,	/* there are no 0-length sequences - this array will never be indexed at 0 */	\
	0,		/* length 1 sequences (i.e. ASCII chars) don't have a minimum value */			\
	(1 <<  7), /* below this, a single ASCII byte should be used */							\
	(1 << 11), /* below this, 2 bytes suffice */											\
	(1 << 16), /* below this, 3 bytes suffice */											\
})

/** @brief Test if the given codepoint `cp`, with seq length `len`, is within the valid ranges for a UTF-8 character. */
#define IS_CODEPOINT_VALID(cp, len) ((bool)( \
	(IN_RANGE((cp), MIN_CPOINTS[(len)], MAX_CPOINT)) ||	/* if the resultant codepoint is in bounds */ \
	!IN_RANGE((cp), SURROGATE_MIN, SURROGATE_MAX)		/*	and isn't a UTF-16 surrogate codepoint */ \
))

/* —————————————————————————————————————————————————————— */

/**
 * @brief Process a single character from input.
 *
 * ---
 *
 * Determine whether the inputted character is an ASCII char or not, and dispatch the character/character buffer
 *	to the associated processing function (either `processASCIIChar` or `processMultibyteChar`).
 *
 * The determination/validation is done using function-static variables (described below) which track the past few
 *	characters to see if they, at any point, form a valid unicode sequence.
 *
 * ---
 *
 * If a valid unicode sequence _is_ found, then information about the sequence is passed to `processMultibyteChar`
 *	to be processed.
 *
 * If at any point, however, we reach a point where it would be impossible to form a valid sequence, we run the
 *	`processMultibyteChar` function, with `type` being set to `CHAR_INVALID`.
 *
 * Finally, if a character is an ASCII byte, it is sent to `processASCIIChar`, and the UTF-8 parsing context is reset.
 *
 * ---
 *
 * @param  chr[in]	The character most recently passed as input.
 *
 * @static seq_buf	A byte buffer storing the unprocessed bytes that make up the current UTF-8 sequence.
 * @static payload	The working/running version of the UTF-8 character being built's codepoint.
 * @static seq_len	How long this current sequence will/should be once it's complete.
 * @static by_left	Number of bytes left to parse in this sequence.
 *
 * ---
 *
 * @cond `seq_len <= MAX_SEQ_LEN`
 * @cond `by_left <= MAX_SEQ_LEN - 1`
 *
 */
static inline void processChar(const char8_t chr) {
	static char8_t seq_buf[MAX_SEQ_LEN] = {0}; /** The raw bytes that make up the current UTF-8 sequence. */

	static chr32_t payload = 0; /** Unicode/UTF-8 character codepoint. */
	static uint8_t seq_len = 0; /** Length of current sequence. */
	static uint8_t by_left = 0; /** Bytes left/remaining. */

	CharType type = CHAR_INVALID; /** The type of the byte just parsed. */

	/* —————————————————————————————————————————————————————— */

	// a non-cont byte being encountered while a seq is unfinished, means that the seq was truncated
	if		((chr >> 6) != 0b10 && SEQ_ACTIVE) processMultibyteChar(seq_buf, seq_len, payload, type), END_SEQ;

	if		((chr >> 7) == 0b0		) type = processASCIIChar(chr), END_SEQ; // ASCII character
	else if	((chr >> 1) == 0b1100000) type = CHAR_INVALID, END_SEQ; // overlong encoding

	else if ((chr >> 6) == 0b10		) {	// check whether we were expecting a continuation byte or not
		if (SEQ_ACTIVE)				  type = CHAR_CONTINU, CON_SEQ	 , payload |= (chr & 0b111111) << (6 * by_left);
		else						  type = CHAR_INVALID, END_SEQ; // stray continuation byte
	}									// header bytes for multibyte character sequences
	else if ((chr >> 5) == 0b110	) type = CHAR_2B_HEAD, NEW_SEQ(2), payload  = (chr &  0b11111) << (6 * by_left);
	else if ((chr >> 4) == 0b1110	) type = CHAR_3B_HEAD, NEW_SEQ(3), payload  = (chr &   0b1111) << (6 * by_left);
	else if ((chr >> 3) == 0b11110	) type = CHAR_4B_HEAD, NEW_SEQ(4), payload  = (chr &	0b111) << (6 * by_left);

	else							  type = CHAR_INVALID, END_SEQ; // invalid byte (too large)

	/* —————————————————————————————————————————————————————— */

	assert(seq_len <= MAX_SEQ_LEN);
	assert(by_left <= MAX_SEQ_LEN - 1);

	/* —————————————————————————————————————————————————————— */

	// continue to the next char if:
	//	a sequence is still in progress (i.e. after a header byte, or after a cont byte which hasn't finished its seq)
	//	or the parsed char was an ASCII char (in which case we would have already processed it)
	if (SEQ_ACTIVE || CHAR_IS_ASCII(type)) return;

	// by this point, the byte has been classified and `by_left` is 0, so either we just parsed:
	//	- a single-byte sequence (ASCII, `0xC0`/`0xC1`, `0xF8 → 0xFF`, a stray continuation byte)
	//	- the last continuation byte of a multi-byte char

	// if we just finished a multibyte char (i.e. just parsed a continuation byte), and the resultant
	//	codepoint isn't valid, then the sequence was invalid, and should be marked as such
	if (type == CHAR_CONTINU && !IS_CODEPOINT_VALID(payload, seq_len)) type = CHAR_INVALID;

	/* —————————————————————————————————————————————————————— */

	processMultibyteChar(seq_buf, seq_len, payload, type);

	// if we've finished a multibyte char, reset the sequence length back to 0
	if (type == CHAR_CONTINU) seq_len = 0;
}

/* —— readFile() ——————————————————————————————————————————————————————————————————————————————————————————————————— */

/**
 * @brief Run `processChar()` on every character in a file.
 *
 * @param pfile[in,out] Pointer to the file which should be read from.
 * @return `int` – A return code to be passed back to this program's caller.
 */
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
	if(!strstr(locale, "UTF-8")) fprintf(stderr, "Warning: Non-UTF8 locale in use: `%s`\n", locale);

	/* —————————————————————————————————————————————————————— */

	FILE *const pfile = getFilePointer(argc, argv);
	if (pfile == NULL) return 1;

	/* —————————————————————————————————————————————————————— */

	const int retcode = readFile(pfile);

	/* —————————————————————————————————————————————————————— */

	// technically, since the program is about to exit, nothing terrible will happen
	//	if we run `fclose` on `stdin`, but it's probably best practice to just ignore it
	if (pfile != stdin) fclose(pfile);

	return retcode;
}

/* ————————————————————————————————————————————————————————————————————————————————————————————————————————————————— */

// spell:ignoreRegexp /\b0b[01]*[a-z]*\b/g
