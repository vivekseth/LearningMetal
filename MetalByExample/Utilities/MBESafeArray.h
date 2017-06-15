//
//  MBESafeArray.h
//  MetalByExample
//
//  Created by Vivek Seth on 6/14/17.
//  Copyright © 2017 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
	void *pointer;
	size_t count;
	size_t size;
	size_t ref_count;
} MBESafeArray;

MBESafeArray MBESafeArrayCreate(size_t count, size_t size);

void MBESafeArrayFree(MBESafeArray arr);

void * MBESafeArrayGetPointer(MBESafeArray arr, size_t i);

MBESafeArray MBESafeArrayCreateOffsetArray(MBESafeArray arr, size_t i);
