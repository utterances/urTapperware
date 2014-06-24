#!/usr/bin/env python

'''
reader for recorded interactions
'''

import sys, pprint

WAIT_THRES = 0.2

def main(argv=None):
	inputFile = argv[1]
	try:
		input = open(inputFile, 'r')
	except:
		print 'error reading', inputFile
		return 1
	
	# now read the file, save each line and filter drag etc.
	timeZero = 0
	saveLog = []
	tempDragHist = {}
	# counters
	numTouchDowns = 0
	numDrag = 0
	
	# UI
	numMenuCmd = 0
	numMenuActivate = 0
	
	numSimCmd = 0
	numSimActivate = 0
	
	# program
	numRegionCmds = {}
	numRegion = 0
	
	numLinkCmds = {}
	
	numGroupCreation = 0
	
	lastR = None
	lastTime = 0
	waitTime = 0
	
	for l in open(inputFile, 'r').readlines():
		l = l.split()
		if timeZero == 0:
			timeZero = float(l[0])
		
		# l[0] = round(float(l[0]),3)
		l[0] = round(float(l[0])-timeZero,3)
		# print l
		
		if l[0]-lastTime > WAIT_THRES:
			waitTime += l[0]-lastTime
		lastTime = l[0]
		
		if l[1] == 'mk' and l[2] == 'done':
			#we are done
			break
		
		if l[1] == 'bg':
			if l[2] == 'move':
				# start saving drag history
				tempDragHist[l[1]] = tempDragHist.get(l[1], [])+[l]
			else:
				#save previous drag history
				if saveDrag(tempDragHist, saveLog):
					numDrag += 1
				if l[2] not in ['touchdown', 'touchup']:
					saveLog += [l]
				elif l[2] == 'touchdown':
					numTouchDowns += 1
		elif l[1][0] == 'R': 
			# we are dealing with region here
			lastR = l[1]
			
			# count all:
			numRegionCmds[l[2]] = numRegionCmds.get(l[2], 0) + 1
			
			
			if l[2] == 'drag' or l[2] == 'move' or l[2] == 'resized':
				# start saving drag history
				key = l[1]+l[2]
				tempDragHist[key] = tempDragHist.get(key, [])+[l]
			else:
				# save previous drag history
				
				if saveDrag(tempDragHist, saveLog):
					numDrag += 1
				if l[2] == 'touchup' and l[2] in tempDragHist.keys():
					#reset drag if we get a touch up
					tempDragHist.pop(l[1])
				
				if l[2] not in ['touchdown', 'touchup']:
					saveLog += [l]
				elif l[2] == 'touchdown':
					numTouchDowns += 1
				
				if l[2] == 'created':
					numRegion += 1
				elif l[2] == 'deleted':
					numRegion -= 1
		elif l[1] == 'link':
			# count all:
			numLinkCmds[l[2]] = numLinkCmds.get(l[2], 0) + 1
		
		elif l[1] == 'menu': #menu simple version
			if l[2] == 'show':
				numMenuActivate += 1
				
			
			numMenuCmd += 1
		else:
			saveLog += [l]
			
	# cleaning steps, remove multi-touch resizing drag:
	for i in xrange(len(saveLog)):
		if saveLog[i][2] == 'resize':
			# search for corresponding drag and remove it
			for j in [i-1,i+1]:
				if saveLog[j][2] == 'drag'\
					and saveLog[j][1] == saveLog[i][1]\
					and saveLog[j][0] - saveLog[i][0]<.005:
					saveLog[j] = None
					
	saveLog = [x for x in saveLog if x != None]
	
	# sorting:
	saveLog.sort(key=lambda x: x[0])
	
	pprint.pprint(saveLog)
	pprint.pprint(numRegionCmds)
	pprint.pprint(numLinkCmds)
	print 'menu cmd count:', numMenuCmd
	print 'touchdown:', numTouchDowns, 'drag:', numDrag, 'wait:', waitTime
	# compute average drag speed:
	avgSpeed, avgDur = dragStats(saveLog)
	print 'avg drag speed', round(avgSpeed,2),'avg duration:',round(avgDur,3)
		
	
def dragStats(saveLog):
	totalTime = 0
	totalDist = 0
	count = 0
	for l in saveLog:
		if len(l) == 9:
			totalTime += l[7]
			totalDist += l[7]*l[8]
			count += 1
	return totalDist/totalTime, totalTime/count
	
def saveDrag(dict, out):
	for k in dict.keys():
		temp = mergeDrag(dict[k])
		if not temp:
			return False
		else:
			dict.pop(k)
			out += temp
			return True
	
def mergeDrag(list):
	# TODO: later we can do alternative way to store drag history
	# for now let's compute some stats first and cut the actual history
	if len(list) < 2:
		return None
	
	dist = 0
	startx, starty = float(list[0][3]), float(list[0][4])
	oldx, oldy = startx, starty

	for item in list[1:]:
		# print float(oldx), float(oldy)
		item[3], item[4] = float(item[3]), float(item[4])
		dist += ((item[3] - oldx)**2 + (item[4] - oldy)**2)**.5
		oldx, oldy = item[3], item[4]

	l = list[0]
	l[3], l[4] = round(float(l[3]),2), round(float(l[4]),2)
	if (list[-1][0]-l[0]) != 0:
		speed = round(dist/(list[-1][0]-l[0]),2)
	else:
		speed = 0
	l += [round(list[-1][3],2), round(list[-1][4],2), round(list[-1][0]-l[0],2), speed]
	return [l]

if __name__ == "__main__":
	sys.exit(main(sys.argv))