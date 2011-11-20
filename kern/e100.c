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
#include <inc/ns.h>


// Bump this up if we run out of them too fast
#define TX_BUFFER_SIZE 32
#define PKT_MAX 1518

#define E100_CMD_TRANSMIT       0x4
#define E100_CMD_INTERRUPT      0x2000
#define E100_CMD_SUSPEND        0x4000
#define E100_SIMPLE_MODE        0x0
#define E100_CMD_START          0x10
#define E100_CMD_RESUME         0x20
#define E100_STATUS_COMPLETE    0x8000
#define E100_STATUS_OK          0x2000
#define E100_CMD_RECEIVE_START  0x1
#define E100_CMD_RECEIVE_RESUME 0x2


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

struct rx_rfd_t {
	volatile uint16_t status;
	volatile uint16_t command;
	volatile uint32_t link_addr;
	volatile uint32_t reserved;
	volatile uint16_t actual_count;
	volatile uint16_t size;
	char data[PKT_MAX];
};


struct tx_cb_t tx_cbs[TX_BUFFER_SIZE];
struct rx_rfd_t rx_rfd;

// All entries between top & bottom are unused. The first unused entry
// is at tx_top. We waste a buffer to simplify the math.
volatile int tx_top = 0, tx_bot = TX_BUFFER_SIZE - 1;
volatile int tx_inited = 0, rx_inited = 0;


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

void
e100_wait_for_0(volatile uint16_t *status) {
	while (!((*status) & E100_STATUS_COMPLETE)) {
		DPRINTF6("waiting...\n");
		delay(3);
	}
}

void
e100_free_transmit_buffers() {
	DPRINTF6("e100_free_transmit_buffers::before::tx_top: %d, tx_bot: %d\n", tx_top, tx_bot);
	int i = tx_top;
	int i1 = (i + 1) % TX_BUFFER_SIZE;
	for (; i != tx_bot && i1 != tx_bot; ++i) {
		if (!(tx_cbs[i].status & E100_STATUS_COMPLETE)) {
			break;
		}
		tx_cbs[i].command = 0;
		i1 = (i + 1) % TX_BUFFER_SIZE;
	}
	tx_top = i;
	tx_bot = (tx_top - 1);
	tx_bot = tx_bot < 0 ? TX_BUFFER_SIZE + tx_bot : tx_bot;
	DPRINTF6("e100_free_transmit_buffers::after::tx_top: %d, tx_bot: %d\n", tx_top, tx_bot);
}

int
e100_receive(void *va, int size) {
	DPRINTF6("e100_receive(%x, %d)\n", va, size);
	rx_rfd.command = E100_CMD_SUSPEND;

	int r = 0;
	r = e100_wait();
	if (r) {
		cprintf("Waited for too long without any result\n");
	}

	if (!rx_inited) {
		rx_inited = 1;
		rx_rfd.status = 0;

		e100_send_long_command(4, PADDR(&rx_rfd));
		DPRINTF6("E100::sending receive start command\n");
		e100_send_byte_command(2, E100_CMD_RECEIVE_START);
		return 0;
	}
	else {
		if (!(rx_rfd.status & E100_STATUS_COMPLETE)) {
			return 0;
		}

		int ac = rx_rfd.actual_count & ((1<<14)-1);
		DPRINTF6("e100_receive::actual_count: %d, size: %d, addr: %x\n", ac, rx_rfd.size, rx_rfd.data);
		struct jif_pkt *p = (struct jif_pkt*)va;
		p->jp_len = ac;
		memmove(p->jp_data, rx_rfd.data, ac);

		// TODO: This is a hack.
		p->jp_data[ac] = '\0';
		cprintf("e100_receive::got(%d): %s\n", p->jp_len, p->jp_data+54);

		rx_rfd.status = 0;
		e100_send_byte_command(2, E100_CMD_RECEIVE_RESUME);
		return ac;
	}
}

int
e100_transmit(void *va, int size) {
	DPRINTF6("e100_transmit(%x, %d)\n", va, size);
	assert(va);
	assert(size < PKT_MAX+1);

	// e100_free_transmit_buffers();

	/* This is the Rajnikanth kernel. We never run out of memory!
	if (tx_top == tx_bot) {
		return -E_NO_MEM;
	}
	*/

	int i = 0; // tx_top;
	tx_top = (tx_top+1) % TX_BUFFER_SIZE;
	tx_cbs[i].command = E100_CMD_TRANSMIT | E100_SIMPLE_MODE | E100_CMD_SUSPEND;
	tx_cbs[i].byte_count = size;
	cprintf("sending data: %s\n", va);
	memmove(tx_cbs[0].data, va, size);

	int r = 0;
	r = e100_wait();
	if (r) {
		cprintf("Waited for too long without any result\n");
	}

	if (!tx_inited) {
		tx_inited = 1;
		tx_cbs[i].status = 0;
		e100_send_long_command(4, PADDR(tx_cbs));
		DPRINTF6("E100::sending send start command\n");
		e100_send_byte_command(2, E100_CMD_START);
	}
	else {
		e100_wait_for_0(&(tx_cbs[0].status));
		tx_cbs[i].status = 0;
		e100_send_byte_command(2, E100_CMD_RESUME);
	}

	return 0;
}

int
e100_enable(struct pci_func *pcif) {
	DPRINTF6("e100_enable(%x)\n", pcif);
	pci_func_enable(pcif);
	e100_func = *pcif;

	int i, i1;

	DPRINTF6("registers: %u, %u, %u, %u\n", e100_func.reg_base[0], 
		 e100_func.reg_base[1], e100_func.reg_base[2], 
		 e100_func.reg_base[3]);
	DPRINTF6("E100 IRQ offset: %d\n", e100_func.irq_line);

	delay(10);
	// Q. How do we know that reg_base[1] contains the address?
	// A. It's given in the manual
	outl(e100_func.reg_base[1] + 0x8, 0 /* Least significant 4
					       bits of this number
					       should be 0 */);
	delay(10);

	// Contruct the transmit buffers
	memset(tx_cbs, 0, sizeof(tx_cbs));

	for (i = 0; i < TX_BUFFER_SIZE; ++i) {
		i1 = (i+1) % TX_BUFFER_SIZE; // Will wrap around
		tx_cbs[i].link_addr = PADDR((tx_cbs+i)); // PADDR((tx_cbs + i1));
		tx_cbs[i].tbd_array_addr = 0xFFFFFFFF;
		tx_cbs[i].number = 0;
		tx_cbs[i].threshold = 0xE0;
	}

	memset(&rx_rfd, 0, sizeof(rx_rfd));

	rx_rfd.link_addr = PADDR(&rx_rfd);
	rx_rfd.command = 0;
	rx_rfd.size = PKT_MAX;

	return -1;
}
