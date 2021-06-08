#include <stdio.h>


/* Take text file smp.dat in a fixed format
   and produce binary file smp.bin
   containing sound effect sample data */

/* Input:
01234567890123456789 prio  per  len L  rst  rln
20 character name    DDDD DDDD XXXX L XXXX XXXXignored

Output:
20 bytes name
priority.w
period.w
start.l		left as zero
length.l
repeat start.l
repeat length.l
*/

void error( char *name )
{
	printf( "Error %s\n", name );
	exit(1);
}

void main(int argc, char *argv[] )
{

	FILE *inf;
	FILE *outf;

	unsigned char name[20];
	unsigned int priority;
	unsigned int period;
	unsigned long length;
	unsigned char loopflag;
	unsigned long repstart;
	unsigned long replen;

	unsigned long zero = 0;

	unsigned char null[50];

	unsigned char InFilename[100];
	unsigned char OutFilename[100];

	if ( argc < 1 )
		error( "insufficient args. Give root file name as only argument\n" );

	strcpy( InFilename, argv[1] );
	strcpy( OutFilename, argv[1] );

	strcat( InFilename, ".dat" );
	strcat( OutFilename, ".bin" );

	inf=fopen( InFilename, "r" );
	if (!inf)
		error( "Opening smp.dat for input" );

	outf=fopen( OutFilename, "wb" );
	if (!outf)
		error( "Opening smp.bin for output" );

	while ( !feof(inf) )
		{
		if ( fscanf( inf, "%20c%hd %hd %04x %1c", name, &priority, &period, &length, &loopflag ) != 5 )
			exit(0);

		if (loopflag == 'L')
			{
			fscanf( inf, "%04x %04x", &repstart, &replen );
			fgets( null, 50, inf );
			}
		else
			{
			fgets( null, 50, inf );
			repstart = 0;
			replen = 0;
			}

		/* now adjust values as required */
		length<<=8;
		replen<<=8;


		/*output values */
		fwrite( name,      1, 20, outf );
		fwrite( &priority, 1,  2, outf );
		fwrite( &period,   1,  2, outf );
		fwrite( &zero,     1,  4, outf );
		fwrite( &length,   1,  4, outf );
		fwrite( &repstart, 1,  4, outf );
		fwrite( &replen,   1,  4, outf );
		}

	fclose( outf );
	fclose( inf );
}
