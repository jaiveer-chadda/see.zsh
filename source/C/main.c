/// @file main.c

#include <stdio.h>
#include <errno.h>
#include <wchar.h>
#include <string.h>
#include <locale.h>
#include <inttypes.h>

/* —— Definitions —————————————————————————————————————————————————————————————————————————————————————————————————— */

/** @brief `BUFSIZE` == `(1 << 12)` == `4,096 B` == `4 kB` */
#define BUFSIZE (1 << 12)

typedef int errno_t;

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

static inline void processChar(const char chr) {
	switch (chr) {
		case ' ' : putwc( L'·', stdout); return;
		case '\0': fputs("\\0", stdout); return;
		case '\a': fputs("\\a", stdout); return;
		case '\b': fputs("\\b", stdout); return;
		case '\t': fputs("\\t", stdout); return;
		case '\v': fputs("\\v", stdout); return;
		case '\f': fputs("\\f", stdout); return;
		case '\r': fputs("\\r", stdout); return;
		case'\33': fputs("\\e", stdout); return;
		case '\n':	puts("\\n"		  ); return;

		default: {
			if ('\1' <= chr && chr <= '\7') {
				printf("\\%hhu", (uint8_t)chr);
			} else if (('\x8' <= chr && chr <= '\x1F') || chr == '\x7F') {
				printf("\\%02x", (uint8_t)chr);
			} else {
				putchar(chr);
			}
		}
	}
}

/* —— readFile() ——————————————————————————————————————————————————————————————————————————————————————————————————— */

static inline int readFile(FILE *const pfile) {
	char buffer[BUFSIZE];
	size_t read_len;

	/* —————————————————————————————————————————————————————— */

	// read `BUFSIZE` objects, each  `1` byte long
	while (( read_len = fread(buffer, 1, BUFSIZE, pfile) )) {
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
