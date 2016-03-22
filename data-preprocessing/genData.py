#!/usr/bin/python2
"""
    NOTE: MAKE sure the opcode list is unique and sorted
	Create a merged Opcode List
	Go to each file set the corresponding opcode freq
	Add the file details to the CSV
	
"""
import os
import sys
master_opcode_list = set()

class csv_row:
	def __init__(self,filename,data_set,label,size,diss_size,num_opcode,opcode_list):
		self.filename = filename
		self.data_set = data_set
		self.label = label
		self.size = size
		self.diss_size = diss_size
		self.num_opcode = num_opcode
		self.opcode_list = opcode_list
	
	def writeToFile(self, fp, master_opcode_list):
		row = self.filename
		row = row+","+str(self.data_set)
		row = row+","+str(self.label)
		row = row+","+str(self.size)
		row = row+","+str(self.diss_size)
		row = row+","+str(self.num_opcode)

		for x in master_opcode_list:
			row = row+","+str(self.opcode_list[x])
			#print(" opcode {} freq {} ".format(x, self.opcode_list[x]))	

		fp.write(row+"\n")

def create_csvrow(path, opcode_list):
	fh = open(path)
	lines = fh.readlines()
	fh.close

	finename =  lines[0].split('\n')[0]
	data_set =  lines[1].split('\n')[0]
	label =  lines[2].split('\n')[0]
	size =  lines[3].split('\n')[0]
	diss_size =  lines[4].split('\n')[0]
	num_opcode =  lines[5].split('\n')[0]

	l_opcode_list = opcode_list.copy()

	for x in range(6, len(lines)):
		freq, opc = lines[x].split(" ")
		opc = opc.split('\n')[0]
		if opc in l_opcode_list :
			l_opcode_list[opc] = freq
		#else:
			#print("opcode {} not found \n".format(opc))
	
	row = csv_row(finename, data_set, label, size, diss_size, num_opcode, l_opcode_list)
	return row




def populateOpcodeLists(template_opcode_list, filename):
	fh = open(filename)
	opcodes = fh.readlines()
	fh.close()

	for opcode in opcodes:
		opcode = opcode.split('\n')
		if opcode[0] not in template_opcode_list:
			template_opcode_list.setdefault(opcode[0],0)
			master_opcode_list.add(opcode[0])

def collectData(sourcepath, datasink, opcode_list):
	for root, dirs, files in os.walk(sourcepath):
		for file in files:
			if( file.find(".freq") > -1):
				datasink.append( create_csvrow(os.path.join(root,file) , opcode_list) )	

def spildata(datasink, filename):
	fp = open(filename, "w")
	for row in datasink:
		row.writeToFile(fp, master_opcode_list)

if len(sys.argv) < 4 :
	print("Usage: ./genData.py <source_folder> <uniqe_master_opcode_list> <output_csv_file_name>\n")
	quit()

template_op_list = {}
data_sink = []

sourcepath = sys.argv[1]
unique_master_opcode_list = sys.argv[2]
output_csv_name = sys.argv[3]

populateOpcodeLists(template_op_list, unique_master_opcode_list)
collectData(sourcepath, data_sink, template_op_list)
spildata(data_sink, output_csv_name)
