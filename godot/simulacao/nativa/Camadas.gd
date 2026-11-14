# Copyright (c) 2017 Fabrice Bellard
# Copyright (c) 2018 Charlie Gordon
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
extends RefCounted
## Preserve the previous painter's depth ordering, including its asymmetric
## equal-depth comparison. rqsort partition strategy, QuickJS cutils.h.
static func compare(a: Dictionary,b: Dictionary) -> int:
	if a.depth!=b.depth:return -1 if a.depth<b.depth else 1
	return 1 if a.has("actor") else -1
static func swap(items: Array,a: int,b: int) -> void:
	var value: Variant = items[a];items[a]=items[b];items[b]=value
static func sort(items: Array,start: int = 0,count: int = -1,depth: int = 0) -> void:
	if count<0:count=items.size()
	if count<2:return
	if count>6:
		depth+=1
		if depth>50:heap(items,start,count);return
		var quarter := count>>2
		var a := start+quarter;var b := start+2*quarter;var c := start+3*quarter
		var median: int
		if compare(items[a],items[b])<0:median=b if compare(items[b],items[c])<0 else c if compare(items[a],items[c])<0 else a
		else:median=b if compare(items[b],items[c])>0 else a if compare(items[a],items[c])<0 else c
		swap(items,start,median)
		var left := start+1;var right := start+count
		while true:
			while left<right and compare(items[start],items[left])>=0:left+=1
			right-=1
			while left<right and compare(items[start],items[right])<=0:right-=1
			if left>=right:break
			swap(items,left,right);left+=1
		swap(items,start,left-1)
		sort(items,start,left-start-1,depth)
		sort(items,left,start+count-left,depth)
		return
	for i in range(start+1,start+count):
		var j := i
		while j>start and compare(items[j-1],items[j])>0:swap(items,j,j-1);j-=1
static func heap(items: Array,start: int,count: int) -> void:
	for root in range(count/2-1,-1,-1):sift(items,start,root,count)
	for end in range(count-1,0,-1):swap(items,start,start+end);sift(items,start,0,end)
static func sift(items: Array,start: int,root: int,count: int) -> void:
	while root*2+1<count:
		var child := root*2+1
		if child<count-1 and compare(items[start+child],items[start+child+1])<=0:child+=1
		if compare(items[start+root],items[start+child])>0:return
		swap(items,start+root,start+child);root=child
