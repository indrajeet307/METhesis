#!/usr/bin/python2
""" This code contains regex,
For more description of regex, please go through 
1. vim regex
2. perl regex
3. python regex
4. man -k regex

Certainly I have not gone through all these,completely , but each of them has a subtle difference.
It is good to know how regex works.
"""

import re
import sys
import os
if len(sys.argv) < 3:
	print("Usage: ./temp.py <source_folder> <dest_folder> <data_type> <label> <master_opcode_list_file>\n")
	quit()

srcdir = sys.argv[1]
destdir = sys.argv[2]
data_set = sys.argv[3]
label = sys.argv[4]
master_opcode_list_file= sys.argv[5]

master_opcode_list = {}

def genOpcFile(fname, outfname):
	#take a file
	fp = open(fname)
	#read all lines
	lines = fp.readlines()
	#close file
	fp.close()

	# create a fie with only .text section
	fp = open(outfname,"w")
	pattern=re.compile(r'^\.text:[0-9A-F]*([\ \t][0-9A-F][0-9A-F])+[\t\ ]*(?P<opcode>[0-9a-z\.\,]*).*$')
	for line in lines:
		flist = pattern.findall(line)	
		if flist:
			if flist[0][1] != "db" and flist[0][1] != "" and flist[0][1] != "align"and flist[0][1] != "\n":
				fp.write(flist[0][1]+"\n")
	fp.close()

def genFreqFile(fname, outfname):
	fp = open(fname)
	lines = fp.read()
	fp.close()
	local_opcode_list={}

	opcodes = lines.split('\n')
	for opcode in opcodes:
		opcode = opcode.rstrip(' ')
		if opcode not in local_opcode_list:
			local_opcode_list.setdefault(opcode,1)
		else:
			local_opcode_list[opcode]+=1
	
	fp=open(outfname, "w")
	fp.write( fname.split('/')[3] +"\n")
	fp.write(data_set+"\n")
	fp.write(label+"\n")
	fp.write(str(len(local_opcode_list))+"\n")

	for opcode in local_opcode_list:
		fp.write(str(local_opcode_list[opcode])+" "+opcode+"\n")
		if opcode not in master_opcode_list:
			master_opcode_list.setdefault(opcode,1)
		else:
			master_opcode_list[opcode] += local_opcode_list[opcode]
	fp.close()
	print("[ Success ] File processed " + fname + "\n")


def genMasterOpcodeList(fname):
	fp = open(fname,"w")
	print("[ Log ] Found "+str(len(master_opcode_list))+" opcodes\n")
	for opcode in master_opcode_list:
		fp.write(str(master_opcode_list[opcode])+" "+opcode+"\n")
	fp.close

def traverseDir():
	list_of_files = os.listdir(srcdir)
	number_of_files = len(list_of_files)
	for entry in list_of_files:
		print("[ Log ] " +str(number_of_files)+" files to be processed\n")
		srcfile = srcdir+"/"+entry
		destfile = destdir+"/"+entry+".opc"
		freqfile = destdir+"/"+entry+".opc.freq"
		genOpcFile(srcfile, destfile)
		genFreqFile(destfile, freqfile)
		number_of_files -= 1
	genMasterOpcodeList(master_opcode_list_file)

traverseDir()
