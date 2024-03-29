// -*- c-basic-offset:8; indent-tabs-mode:t -*-
#include <inc/lib.h>
#include <inc/trap.h>
#include <lwip/sockets.h>
#include <lwip/inet.h>

struct sockaddr_in migrated;

#ifndef MIGRATED_HOST
#define MIGRATED_HOST "127.0.0.1"
#endif

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
		// 
		// Note: We don't used this since we assume that the
		// process with environment ID 'env_id' forked from
		// the current process.
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
migrated_connect() {
	// Create the TCP socket
	int sock, r;
	if ((sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) {
		return sock;
	}

	// Construct the server sockaddr_in structure
	memset(&migrated, 0, sizeof(migrated));              // Clear struct
	migrated.sin_family = AF_INET;                       // Internet/IP
#ifdef USE_PROXY
	migrated.sin_addr.s_addr = inet_addr("174.120.183.89");   // IP address
	migrated.sin_port = htons(10091); // MIG_SERVER_PORT);	     // server port
#else
	migrated.sin_addr.s_addr = inet_addr(MIGRATED_HOST);   // IP
							       // address
	migrated.sin_port = htons(MIG_SERVER_PORT);	     // server
							     // port
#endif

	DPRINTF8("Before connecting to migrated\n");

	// Establish connection
	if ((r = connect(sock, (struct sockaddr *) &migrated, sizeof(migrated))) < 0) {
		return r;
	}
	return sock;
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

	if ((sock = migrated_connect()) < 0) {
		r = sock;
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

		// Skip the page that we share with the file server.
		if (addr == 0xd0000000) {
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

	// Fetch the PID of the child process and return it to the
	// parent.
	if ((r = read(sock, &child, sizeof(child))) < 0) {
		goto cleanup;
	}

	close(sock);

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
 * 'pid'. Returns 0 if the send() was successful and < 0
 * otherwise. Also receive up to *rlen bytes in rbuff. *rlen is set to
 * the number of bytes received. *rlen is valid ONLY if the function
 * returns 0.
 *
 * Packet format:
 * message type (32-bit)
 * pid (32-bit)
 * length (32-bit)
 * data (length bytes)
 *
 */
int
ripc_send(int pid, void *va, int len, char *rbuff, int *rlen) {
	int r, sock;
	sock = migrated_connect();
	if (sock < 0) {
		return -1;
	}

	int code[3] = { MIG_IPC_MESSAGE, pid, len };
	if ((r = send_data(sock, 0, code, sizeof(code))) < 0) {
		goto cleanup;
	}

	if ((r = send_data(sock, 0, va, len)) < 0) {
		goto cleanup;
	}

	memset(code, 0, sizeof(code));
	if ((r = read(sock, code, sizeof(code))) < 0) {
		goto cleanup;
	}

	cprintf("code[0]: %d, code[1]: %d, code[2]: %d\n", code[0], code[1], code[2]);
	if (code[2] > *rlen) {
		r = -1;
		goto cleanup;
	}
	// Read in code[2] bytes.
	if ((r = readn(sock, rbuff, code[2])) < 0) {
		goto cleanup;
	}

	*rlen = r;
	r = 0;

 cleanup:
	close(sock);
	return r;
}

/* Receive 'len' bytes into 'va' - len is set to the actual number of
 * bytes received. Additionally, send slen bytes at address sbuff to
 * the person we received data from.
 *
 * Return 0 on success, < 0 on failure.
 * 
 */
int
ripc_recv(void *va, int *len, char *sbuff, int slen) {
	envid_t migrated_id;
	int perm;
	int r;

	void *temp = (void *) UTEMP + PGSIZE * 3;
	*len = ipc_recv(&migrated_id, temp, &perm);
	memmove(va, temp, *len);

	if(!migrated_id || !perm) {
		DPRINTF8("Could not recev from the mimgrated server");
		return -1;
	}

	sys_page_unmap(0, temp);
	r = sys_page_alloc(0, temp, PTE_U | PTE_W | PTE_P);
	if (r < 0) {
		return -2;
	}

	memmove(temp, sbuff, slen);
	ipc_send(migrated_id, slen, temp, PTE_P | PTE_U);

	return 0;
}
