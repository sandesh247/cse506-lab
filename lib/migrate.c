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
	char *addr = va;
	if (env_id != 0) {
		// Map in at a temporary location (assume it will fit
		// into one page.
		// TODO: Maybe fix: return -1;
	}

	int l = len > 1200 ? 1200 : len;
	while (l) {
		if ((r = write(sock, addr, l)) != l) {
			return -1;
		}
		len -= l;
		addr += l;
		l = len > 1200 ? 1200 : len;
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

	int r;
	envid_t child;
	struct Trapframe tf;
	int sock;
	struct sockaddr_in migrated;

	DPRINTF8("migrate() called\n");

	if ((r = sys_exofork()) < 0) {
		DPRINTF8("sys_exofork error::%e\n", r);
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
		DPRINTF8("sys_env_get_trapframe error::%e\n", r);
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
	migrated.sin_addr.s_addr = inet_addr("174.120.183.89");   // IP address // "10.0.2.15" "127.0.0.1"
	migrated.sin_port = htons(10091); // MIG_SERVER_PORT);	     // server port

	DPRINTF8("Before connecting to migrated\n");

	// Establish connection
	if ((r = connect(sock, (struct sockaddr *) &migrated, sizeof(migrated))) < 0) {
		goto cleanup;
	}

	DPRINTF8("!!Connected to migrated!!\n");

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

	// close(sock);
	// Success, return the child's env_id
	r = child;

 cleanup:
	sys_env_destroy(child);
	if (r < 0) {
		DPRINTF8("Exiting due to error: %e\n", r);
	}
	return r;
}

/* Send 'len' bytes starting from 'va' to the remote process with ID
 * 'pid'. Returns 0 if the send() was successful and < 0 otherwise.
 */
int
ripc_send(int pid, void *va, int len) {
	panic("ripc_send() not implemented");
	return -1;
}

/* Receive up to 'len' bytes into 'va'. Returns the number of bytes
 * actually received or < 0 if an error occurred.
 */
int
ripc_recv(void *va, int len) {
	panic("ripc_recv() not implemented");
	return -1;
}
