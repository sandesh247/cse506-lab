// -*- c-basic-offset:8; indent-tabs-mode:t -*-
// LAB 6: Your driver code here
#include <kern/e100.h>
#include <kern/pmap.h>
#include <kern/picirq.h>
#include <inc/string.h>
#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/x86.h>
#include <inc/error.h>

// Bump this up if we run out of them too fast
#define TX_BUFFER_SIZE 32
#define PKT_MAX 1518

#define E100_CMD_TRANSMIT  0x4
#define E100_CMD_INTERRUPT 0x2000
#define E100_CMD_SUSPEND   0x4000
#define E100_SIMPLE_MODE   0x0
#define E100_CMD_START     0x10
#define E100_CMD_RESUME    0x20

struct pci_func e100_func;


struct tx_cb_t {
	volatile uint16_t status;  // <-
	volatile uint16_t command; // <-

	volatile uint32_t link_addr;

	volatile uint32_t tbd_array_addr;

	volatile uint16_t byte_count; // <-
	volatile uint8_t threshold;   // <-
	volatile uint8_t number;      // <-

	char data[PKT_MAX];
};

struct tx_cb_t tx_cbs[TX_BUFFER_SIZE];
struct Page *tx_pages[TX_BUFFER_SIZE];

// All entries between top & bottom are unused. The first unused entry
// is at tx_top. We waste a buffer to simplify the math.
int tx_top = 0, tx_bot = TX_BUFFER_SIZE - 1;
int tx_inited = 0;


void
delay(int us) {
    int i;
    for (i = 0; i < (double)us/1.25 + 1; ++i) {
        inb(0x84);
    }
}

void
e100_send_long_command(int offset, int cmd) {
	outl(e100_func.reg_base[1] + offset, cmd);
}

void
e100_send_byte_command(int offset, int cmd) {
	outb(e100_func.reg_base[1] + offset, cmd);
}

int
e100_wait()
{
	int i;
	for (i = 0; i < 100; ++i) {
		if (inb(e100_func.reg_base[1] + 2) == 0) {
			return 0;
		}
		delay(5);
	}
	return 1;
}

int
e100_transmit(struct Page *pp, int size, int offset) {
	assert(pp);
	assert(offset >= 0 && offset < PGSIZE);
	assert(size < PKT_MAX+1);

	if (tx_top == tx_bot) {
		return -E_NO_MEM;
	}

	int i = tx_top;
	tx_top = (tx_top+1) % TX_BUFFER_SIZE;
	page_incref(pp);
	tx_pages[i] = pp;
	tx_cbs[i].status = 0;
	tx_cbs[i].command = E100_CMD_TRANSMIT | E100_SIMPLE_MODE | E100_CMD_SUSPEND;

	int r = e100_wait();
	if (r) {
		cprintf("Waited for too long without any result\n");
	}

	if (!tx_inited) {
		tx_inited = 1;
		e100_send_long_command(4, PADDR(tx_cbs));
		e100_send_byte_command(2, E100_CMD_START);
	}
	else {
		e100_send_byte_command(2, E100_CMD_RESUME);
	}

	return 0;
}

int
e100_enable(struct pci_func *pcif) {
	DPRINTF6("e100_enable(%x)\n", pcif);
	pci_func_enable(pcif);
	e100_func = *pcif;

	DPRINTF6("registers: %u, %u, %u, %u\n", e100_func.reg_base[0], 
		 e100_func.reg_base[1], e100_func.reg_base[2], 
		 e100_func.reg_base[3]);

	delay(10);
	// Q. How do we know that reg_base[1] contains the address?
	// A. It's given in the manual
	outl(e100_func.reg_base[1] + 0x8, 0 /* Least significant 4
					       bits of this number
					       should be 0 */);
	delay(10);

	// Contruct the transmit buffers
	int i, i1;
	memset(tx_cbs, 0, sizeof(tx_cbs));
	memset(tx_pages, 0, sizeof(tx_pages));

	for (i = 0; i < TX_BUFFER_SIZE; ++i) {
		i1 = (i+1) % TX_BUFFER_SIZE; // Will wrap around
		tx_cbs[i].link_addr = PADDR(tx_cbs + i1);
		tx_cbs[i].tbd_array_addr = 0xFFFFFFFF;
		tx_cbs[i].number = 0;
		tx_cbs[i].threshold = 0xE0;
	}

	// Enable interrupts on our device.
	irq_setmask_8259A(irq_mask_8259A & ~(1 << e100_func.irq_line));
	return -1;
}
