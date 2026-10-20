/// @file main.c

#include <stdio.h>
#include <errno.h>
#include <string.h>

#define BUFSIZE 256

typedef int errno_t;

/* ————————————————————————————————————————————————————————————————————————————————————————————————————————————————— */

FILE *getFilePointer(const int argc, const char *const *const argv) {

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

/* ————————————————————————————————————————————————————————————————————————————————————————————————————————————————— */

int main(const int argc, const char *const *const argv) {

	FILE *const pfile = getFilePointer(argc, argv);
	if (pfile == NULL) return 1;

	/* —————————————————————————————————————————————————————— */

	char buffer[BUFSIZE];

	// `fgets` reads until a newline, `EOF`, or `BUFSIZE` is reached
	while (fgets(buffer, BUFSIZE, pfile)) {
		printf("%s", buffer);
	}

	/* —————————————————————————————————————————————————————— */

	if (pfile != stdin) fclose(pfile);
	return 0;
}
