// -*- c-basic-offset:8; indent-tabs-mode:t -*-
#include "ns.h"

extern union Nsipc nsipcbuf;

// char in_buff[PGSIZE * 2];

void
delay(int us) {
	int i, j;
    for (i = 0; i < 10000000; ++i) {
	    j += 20;
    }
}

void
input(envid_t ns_envid)
{
	binaryname = "ns_input";

	// LAB 6: Your code here:
	// 	- read a packet from the device driver
	//	- send it to the network server
	// Hint: When you IPC a page to the network server, it will be
	// reading from it for a while, so don't immediately receive
	// another packet in to the same physical page.

        DPRINTF6("input(%d)\n", ns_envid);
        int r;
	void *pkt = &(nsipcbuf.pkt);
	// in_buff[0] = in_buff[PGSIZE] = 'x';
        // void *pkt = (void*)(UTEMP + PGSIZE*2);
	// r = sys_page_alloc(0, pkt, PTE_U|PTE_W|PTE_P);
	// assert(r == 0);

        while (1) {
		DPRINTF6("env_id: %d, pkt: %x\n", env->env_id, pkt);
		r = sys_net_recv(pkt, PGSIZE);
		DPRINTF6("input::sys_net_recv returned %d\n", r);
		struct jif_pkt *p = (struct jif_pkt*)pkt;
		DPRINTF6("input::p->jp_len: %d\n", p->jp_len);

		assert(r >= 0);
		// int eq = in_buff[0] == in_buff[1];
		if (r > 0) {
			ipc_send(ns_envid, NSREQ_INPUT, pkt, PTE_P|PTE_W|PTE_U);
			// sys_yield();
		}
		else {
			// sys_yield();
			delay(100);
		}
        }
}
