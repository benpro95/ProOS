#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

/*
 * 'slurp' reads the file identified by 'path' into a character buffer
 * pointed at by 'buf', optionally adding a terminating NUL if
 * 'add_nul' is true. On success, the size of the file is returned; on
 * failure, -1 is returned and ERRNO is set by the underlying system
 * or library call that failed.
 *
 * WARNING: 'slurp' malloc()s memory to '*buf' which must be freed by
 * the caller.
 */
long slurp(char const* path, char **buf, bool add_nul)
{
    FILE  *fp;
    size_t fsz;
    long   off_end;
    int    rc;

    /* Open the file */
    fp = fopen(path, "rb");
    if( NULL == fp ) {
        return -1L;
    }

    /* Seek to the end of the file */
    rc = fseek(fp, 0L, SEEK_END);
    if( 0 != rc ) {
        return -1L;
    }

    /* Byte offset to the end of the file (size) */
    if( 0 > (off_end = ftell(fp)) ) {
        return -1L;
    }
    fsz = (size_t)off_end;

    /* Allocate a buffer to hold the whole file */
    *buf = malloc( fsz+(int)add_nul );
    if( NULL == *buf ) {
        return -1L;
    }

    /* Rewind file pointer to start of file */
    rewind(fp);

    /* Slurp file into buffer */
    if( fsz != fread(*buf, 1, fsz, fp) ) {
        free(*buf);
        return -1L;
    }

    /* Close the file */
    if( EOF == fclose(fp) ) {
        free(*buf);
        return -1L;
    }

    if( add_nul ) {
        /* Make sure the buffer is NUL-terminated, just in case */
        buf[fsz] = '\0';
    }

    /* Return the file size */
    return (long)fsz;
}


/*
 * Usage message for demo (in main(), below)
 */
void usage(void) {
    fputs("USAGE: ./slurp <filename>\n", stderr);
    exit(1);
}


/*
 * Demonstrates a call to 'slurp'.
 */
int main(int argc, char *argv[]) {
    long  file_size;
    char *buf;

    /* Make sure there is at least one command-line argument */
    if( argc < 2 ) {
        usage();
    }

    /* Try the first command-line argument as a file name */
    file_size = slurp(argv[1], &buf, false);

    /* Bail if we get a negative file size back from slurp() */
    if( file_size < 0L ) {
        perror("File read failed");
        usage();
    }

    /* Write to stdout whatever slurp() read in */
    (void)fwrite(buf, 1, file_size, stdout);

    /* Remember to free() memory allocated by slurp() */
    free( buf );
    return 0;
}