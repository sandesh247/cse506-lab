// -*- c-basic-offset:8; indent-tabs-mode:t -*-
#include <inc/lib.h>
#include <inc/trap.h>
#include <lwip/sockets.h>
#include <lwip/inet.h>

// Send 'len' bytes from address 'va' from environment 'env_id' to the
// migrated daemon.
int
send_data(envid_t env_id, void *va, int len) {
	int sock;
	struct sockaddr_in echoserver;
	char buffer[BUFFSIZE];
	unsigned int echolen;
	int received = 0;
	
	cprintf("Connecting to:\n");
	cprintf("\tip address %s = %x\n", IPADDR, inet_addr(IPADDR));
	
	// Create the TCP socket
	if ((sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0)
		die("Failed to create socket");
	
	cprintf("opened socket\n");
	
	// Construct the server sockaddr_in structure
	memset(&echoserver, 0, sizeof(echoserver));       // Clear struct
	echoserver.sin_family = AF_INET;                  // Internet/IP
	echoserver.sin_addr.s_addr = inet_addr(IPADDR);   // IP address
	echoserver.sin_port = htons(PORT);		  // server port
	
	cprintf("trying to connect to server\n");
	
	// Establish connection
	if (connect(sock, (struct sockaddr *) &echoserver, sizeof(echoserver)) < 0)
		die("Failed to connect with server");
	
	cprintf("connected to server\n");
	
	// Send the word to the server
	echolen = strlen(msg);
	if (write(sock, msg, echolen) != echolen)
		die("Mismatch in number of sent bytes");
	
	// Receive the word back from the server
	cprintf("Received: \n");
	while (received < echolen) {
		int bytes = 0;
		if ((bytes = read(sock, buffer, BUFFSIZE-1)) < 1) {
			die("Failed to receive bytes from server");
		}
		received += bytes;
		buffer[bytes] = '\0';        // Assure null terminated string
		cprintf(buffer);
	}
	cprintf("\n");
	
	close(sock);
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

	uint32_t temp = MIG_PROC_MIGRATE;
	if ((r = send_data(0, &temp, sizeof(temp))) < 0) {
		goto cleanup;
	}

	if ((r = send_data(0, &tf, sizeof(tf))) < 0) {
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
		if ((r = send_data(0, &addr, sizeof(addr))) < 0) {
			goto cleanup;
		}

		if ((r = send_data(child, (void*)addr, PGSIZE)) < 0) {
			goto cleanup;
		}
		++temp;
	}

	addr = 0xffffffff;
	if ((r = send_data(0, &addr, sizeof(addr))) < 0) {
		goto cleanup;
	}

	if ((r = send_data(0, &temp, sizeof(temp))) < 0) {
		goto cleanup;
	}

	// Success, return the child's env_id
	r = child;

 cleanup:
	sys_env_destroy(child);
	return r;
}
