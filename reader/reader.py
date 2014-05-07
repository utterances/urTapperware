#!/usr/bin/env python

'''
reader for recorded interactions
'''

import sys

def main(argv=None):
	inputFile = argv[1]
	try:
		input = open(inputFile, 'r')
	except:
		print 'error reading', inputFile
		return 1
	
	print 'parsing', inputFile
	for l in open(inputFile, 'r').readlines():
		l = l.split()
		print l
		return
		
if __name__ == "__main__":
	sys.exit(main(sys.argv))