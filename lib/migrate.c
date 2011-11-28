// -*- c-basic-offset:8; indent-tabs-mode:t -*-
#include <inc/lib.h>
#include <inc/trap.h>
#include <lwip/sockets.h>
#include <lwip/inet.h>

// Send 'len' bytes from address 'va' from environment 'env_id' to the
// migrated daemon.
int
send_data(int sock, envid_t env_id, void *va, int len) {
	// Send the word to the server
	int r;
	void *addr = va;
	if (env_id != 0) {
		// Map in at a temporary location (assume it will fit
		// into one page.
		return -1;
	}

	if ((r = write(sock, va, len)) != len) {
		return -1;
	}

	return 0;
}


int
migrate() {
	// Send all our pages from UTEXT to UXSTACKTOP to the daemon on
	// the other end.
	// 
	// General Strategy: fork() and send all the child's pages across
	// the network. Also send the child's exception & user stack on
	// the network. The daemon on the other end will fork and replace
	// the child's process image with the image it receives.
	// 
	// message type (32-bits)
	// Trapframe
	// pages[npages] (32-bit address, PGSIZE data)
	// last page (only 32-bit address: 0xffffffff)
	// number of pages[npages] (32-bits)
	// 

	int r, child;
	struct Trapframe tf;
	int sock;
	struct sockaddr_in migrated;

	if ((r = sys_exofork()) < 0) {
		return r;
	}

	child = r;

	if (child == 0) {
		env = envs + ENVX(sys_getenvid());
		return 0;
	}

	// We are in the parent

	// Get the child's trapframe
	r = sys_env_get_trapframe(child, &tf);
	if (r < 0) {
		goto cleanup;
	}

	// The child will never run on the current machine (infanticide of
	// sorts)...

	// Return 0 in the child on the remote machine
	tf.tf_regs.reg_eax = 0;

	// Create the TCP socket
	if ((sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) {
		r = sock;
		goto cleanup;
	}

	// Construct the server sockaddr_in structure
	memset(&migrated, 0, sizeof(migrated));              // Clear struct
	migrated.sin_family = AF_INET;                       // Internet/IP
	migrated.sin_addr.s_addr = inet_addr("10.0.2.15");   // IP address
	migrated.sin_port = htons(MIG_SERVER_PORT);	     // server port
	
	// Establish connection
	if ((r = connect(sock, (struct sockaddr *) &migrated, sizeof(migrated))) < 0) {
		goto cleanup;
	}

	uint32_t temp = MIG_PROC_MIGRATE;
	if ((r = send_data(sock, 0, &temp, sizeof(temp))) < 0) {
		goto cleanup;
	}

	if ((r = send_data(sock, 0, &tf, sizeof(tf))) < 0) {
		goto cleanup;

	}

	temp = 0;
	uint32_t addr;
	for (addr = UTEXT; addr < UTOP; addr += PGSIZE) {
		// Send each page off to the other side.

		int pn = addr/PGSIZE;
		if (!(vpd[pn / NPTENTRIES]&PTE_P) || !(vpt[pn]&PTE_P)) {
			continue;
		}

		DPRINTF8("[%d] Sending page at address: %x\n", child, addr);
		if ((r = send_data(sock, 0, &addr, sizeof(addr))) < 0) {
			goto cleanup;
		}

		if ((r = send_data(sock, child, (void*)addr, PGSIZE)) < 0) {
			goto cleanup;
		}
		++temp;
	}

	addr = 0xffffffff;
	if ((r = send_data(sock, 0, &addr, sizeof(addr))) < 0) {
		goto cleanup;
	}

	if ((r = send_data(sock, 0, &temp, sizeof(temp))) < 0) {
		goto cleanup;
	}

	close(sock);
	// Success, return the child's env_id
	r = child;

 cleanup:
	sys_env_destroy(child);
	return r;
}
