// -*- c-basic-offset:8; indent-tabs-mode:t -*-
#include "ns.h"

extern union Nsipc nsipcbuf;

void
output(envid_t ns_envid)
{
	binaryname = "ns_output";

	// LAB 6: Your code here:
	// 	- read a packet from the network server
	//	- send the packet to the device driver

	struct jif_pkt *pkt = &(nsipcbuf.pkt);
	int perm, r;
	envid_t sender_id;

	while (1) {
		r = ipc_recv(&sender_id, pkt, &perm);

		if (!(perm & PTE_P)) {
			DPRINTF6("output::Wanted a page, but didn't get any from %d\n", sender_id);
			continue;
		}

		if (r != NSREQ_OUTPUT) {
			DPRINTF6("output::Was expecting %d, got %d\n", NSREQ_OUTPUT, r);
			continue;
		}

		if (ns_envid != sender_id) {
			DPRINTF6("output::Expecting message from %d, got from %d\n", ns_envid, sender_id);
			continue;
		}

		if ((r = sys_net_send(pkt->jp_data, pkt->jp_len))) {
			cprintf("output::Error '%e' sending data with length %d to the E100 device\n", r, pkt->jp_len);
		}
	}
}
