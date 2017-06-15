//
//  MBESafeArray.m
//  MetalByExample
//
//  Created by Vivek Seth on 6/14/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import "MBESafeArray.h"

MBESafeArray MBESafeArrayCreate(size_t count, size_t size) {
	assert(count >= 0);
	MBESafeArray newArr;
	newArr.pointer = calloc(count, size);
	newArr.count = count;
	newArr.size = size;
	newArr.ref_count = 1;
	return newArr;
}

void MBESafeArrayFree(MBESafeArray arr) {
	arr.ref_count = arr.ref_count - 1;
	if (arr.ref_count <= 0) {
		free(arr.pointer);
	}
}

void * MBESafeArrayGetPointer(MBESafeArray arr, size_t i) {
	assert(i < arr.count);
	return arr.pointer + i * arr.size;
}

MBESafeArray MBESafeArrayCreateOffsetArray(MBESafeArray arr, size_t i) {
	assert(i < arr.count);

	MBESafeArray newArr;
	newArr.pointer = arr.pointer + i * arr.size;
	newArr.count = arr.count - i;
	newArr.size = arr.size;
	newArr.ref_count = arr.ref_count + 1;

	return newArr;
}

