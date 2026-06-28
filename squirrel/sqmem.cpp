/*
    see copyright notice in squirrel.h
*/
#include "sqpcheader.h"
#ifndef SQ_EXCLUDE_DEFAULT_MEMFUNCTIONS
namespace {

struct SmallAllocFreeBlock {
    SmallAllocFreeBlock *next;
};

static const SQUnsignedInteger kSmallAllocStep = 16;
static const SQUnsignedInteger kSmallAllocMax = 1024;
static const SQUnsignedInteger kSmallAllocClassCount = kSmallAllocMax / kSmallAllocStep;
static const SQUnsignedInteger kSmallAllocCacheLimit = 64;
static thread_local SmallAllocFreeBlock *g_small_alloc_free_lists[kSmallAllocClassCount];
static thread_local SQUnsignedInteger g_small_alloc_free_counts[kSmallAllocClassCount];

static inline SQUnsignedInteger SmallAllocClassIndex(SQUnsignedInteger size)
{
    if(size == 0 || size > kSmallAllocMax) {
        return UINT_MINUS_ONE;
    }
    return ((size + (kSmallAllocStep - 1)) / kSmallAllocStep) - 1;
}

static inline SQUnsignedInteger SmallAllocClassSize(SQUnsignedInteger index)
{
    return (index + 1) * kSmallAllocStep;
}

}

void *sq_vm_malloc(SQUnsignedInteger size)
{
    SQUnsignedInteger index = SmallAllocClassIndex(size);
    if(index != UINT_MINUS_ONE) {
        SmallAllocFreeBlock *block = g_small_alloc_free_lists[index];
        if(block) {
            g_small_alloc_free_lists[index] = block->next;
            g_small_alloc_free_counts[index]--;
            return block;
        }
        size = SmallAllocClassSize(index);
    }
    return malloc(size);
}

void *sq_vm_realloc(void *p, SQUnsignedInteger oldsize, SQUnsignedInteger size)
{
    if(p == NULL) {
        return sq_vm_malloc(size);
    }
    if(size == 0) {
        sq_vm_free(p, oldsize);
        return NULL;
    }

    SQUnsignedInteger old_index = SmallAllocClassIndex(oldsize);
    SQUnsignedInteger new_index = SmallAllocClassIndex(size);
    if(old_index != UINT_MINUS_ONE && old_index == new_index) {
        return p;
    }
    if(old_index == UINT_MINUS_ONE && new_index == UINT_MINUS_ONE) {
        return realloc(p, size);
    }

    void *next = sq_vm_malloc(size);
    if(next) {
        memcpy(next, p, oldsize < size ? oldsize : size);
    }
    sq_vm_free(p, oldsize);
    return next;
}

void sq_vm_free(void *p, SQUnsignedInteger size)
{
    if(!p) {
        return;
    }
    SQUnsignedInteger index = SmallAllocClassIndex(size);
    if(index != UINT_MINUS_ONE && g_small_alloc_free_counts[index] < kSmallAllocCacheLimit) {
        SmallAllocFreeBlock *block = (SmallAllocFreeBlock *)p;
        block->next = g_small_alloc_free_lists[index];
        g_small_alloc_free_lists[index] = block;
        g_small_alloc_free_counts[index]++;
        return;
    }
    free(p);
}
#endif
