#!/usr/bin/python2
import sys
import os

if len(sys.argv) < 3:
     print("Usage: ./genOpcode.py <source_folder> <dest_folder> <data_type> <label>\n")
     quit()
srcdir =  sys.argv[1]
destdir = sys.argv[2]
data_set = sys.argv[3]
label = sys.argv[4]

master_opcode_map = {}

def genrateOpcFile(fname, outfname):
    retval = os.system("objdump -d " + fname + "> " + outfname)

    if(retval):
         print("[ Error ] : Objdump failed !!!\n")
         print("[ Error ] File "+fname+"\n")
         return 1
    return 0

def genMasterOpcodeList(fname):
     fp = open(fname,"w")
     print("[ Log ] Found "+str(len(master_opcode_list))+" opcodes\n")
     for opcode in master_opcode_list:
        fp.write(str(master_opcode_list[opcode])+" "+opcode+"\n")
     fp.close

def genFreqFile(opcfname, freqfname):
    fp = open(opcfname)
    lines = fp.readlines()
    fp.close()
    opcode_map={}

    for line in lines:
         line = line.split('\t')
         if(len(line) == 3):
              line = line[2].split(' ')
              if(len(line) != 0):
                   line=line[0].rstrip("\n ")
                   if len(line)>0 and (line not in opcode_map):
                        opcode_map.setdefault(line,1)
                   else:
                        opcode_map[line] += 1

    fp2 = open(freqfname,"w")
    fp2.write(opcfname+"\n")
    fp2.write(data_set+"\n")
    fp2.write(label+"\n")
    fp2.write(str(len(opcode_map))+"\n")

    for opcode in opcode_map:
        fp2.write(str(opcode_map[opcode])+" "+opcode+"\n")
        if opcode not in master_opcode_map:
                master_opcode_map.setdefault(opcode,opcode_map[opcode])
        else:
                 master_opcode_map[opcode] += opcode_map[opcode]

    fp2.close()
    print("[ Success ] File processed "+opcfname+"\n")

def traverseDir():
     list_of_files = os.listdir(srcdir)
     num_of_files = len(list_of_files)
     for entry in list_of_files:
          print("[ Log ] " +str(num_of_files)+" files to be processed\n")
          fname = srcdir+"/"+entry
          opcfname = destdir+"/"+entry+".opc"
          freqfname = destdir+"/"+entry+".opc.freq"
          if genrateOpcFile(fname, opcfname):
              num_of_files -= 1
              continue
          genFreqFile(opcfname, freqfname)
          num_of_files -= 1
     genMasterOpcodeList(master_opcode_file)

traverseDir()
