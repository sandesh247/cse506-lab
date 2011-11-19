// -*- c-basic-offset:8; indent-tabs-mode:t -*-
#include <kern/pci.h>
#include <inc/stdio.h>
#include <kern/pmap.h>

#ifndef JOS_KERN_E100_H
#define JOS_KERN_E100_H


extern struct pci_func e100_func;

void delay(int us);
int e100_enable(struct pci_func *pcif);
int e100_transmit(struct Page *pp, int size, int offset);

#endif	// JOS_KERN_E100_H
