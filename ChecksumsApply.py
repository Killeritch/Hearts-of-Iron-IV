import os
import os.path
import time
import sys
import datetime

if len(sys.argv) < 1:
	print("ERROR: missing file argument")
	sys.exit( -1 )
inputfile = sys.argv[ 1 ]

try:
	file = open( inputfile, 'r' )
	filecontent = file.read()
	file.close()

	alllines = filecontent.split( '\n' )
	for line in alllines:
		textpair = str( line ).split( "|" )
		if len( textpair ) < 2:
			print("Error: Missing pair of strings separated by |")
			continue
		elif len( textpair ) > 2:
			print("Error: Too many separators in current line |")
			continue
		dlcpath = textpair[ 0 ]
		checksum = textpair[ 1 ]

		dlcfile = open( dlcpath, 'r' )
		dlccontent = dlcfile.read();
		dlcfile.close()

		dlcreconstructed = ""
		dlclines = dlccontent.split( '\n' )
		for dlcline in dlclines:
			if len( dlcreconstructed ) > 0:
				dlcreconstructed += "\n"

			if dlcline.startswith( "checksum" ):
				dlcreconstructed += "checksum = \"" + checksum + "\""
				print( dlcpath + " = " + checksum )
			else:
				dlcreconstructed += dlcline

		dlcfile = open( dlcpath, 'w' );
		dlcfile.write( dlcreconstructed )
		dlcfile.close()

except Exception as e:
	print( "Error = " + str( e ) )
	sys.exit( 0 )