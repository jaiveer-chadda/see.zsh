/// @file main.c

#include <stdio.h>
#include <errno.h>
#include <string.h>

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

/* —— readFile() ——————————————————————————————————————————————————————————————————————————————————————————————————— */

static inline int readFile(FILE *const pfile) {
	char buffer[BUFSIZE];
	size_t read_len;

	/* —————————————————————————————————————————————————————— */

	// read `BUFSIZE` objects, each  `1` byte long
	while (( read_len = fread(buffer, 1, BUFSIZE, pfile) )) {
		for (size_t i = 0; i < read_len; i++) {
			putchar(buffer[i]);
		}
	}

	/* —————————————————————————————————————————————————————— */

	return 0;
}

/* —— main() ——————————————————————————————————————————————————————————————————————————————————————————————————————— */

int main(const int argc, const char *const *const argv) {

	FILE *const pfile = getFilePointer(argc, argv);
	if (pfile == NULL) return 1;

	/* —————————————————————————————————————————————————————— */

	const int retcode = readFile(pfile);

	/* —————————————————————————————————————————————————————— */

	if (pfile != stdin) fclose(pfile);
	return retcode;
}

/* ————————————————————————————————————————————————————————————————————————————————————————————————————————————————— */
