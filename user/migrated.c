// -*- c-basic-offset:8; indent-tabs-mode:t -*-
#include <inc/lib.h>
#include <lwip/sockets.h>
#include <lwip/inet.h>

#define BUFFSIZE 512
#define MAXPENDING 5

/* The migrated daemon, that listems for migration requests, and spawns
 * new processes on this JOS instance.
 *
 */

static void
die(char *m)
{
	cprintf("%s\n", m);
	exit();
}

// common messages
uint32_t	preamble;

// migration messages
struct Trapframe trapframe;
uint32_t	addr;
char			data[PGSIZE];
uint32_t	npages;

static void 
handle_migrate(int sock) {
	int r;
	int seen_pages = 0;

	if ((r = sys_exofork()) < 0) {
		DPRINTF8("Could not fork (%d): %e\n", r, r);
		return;
	}
	int child = r;

	DPRINTF8("Receiving trapframe ...\n");
	r = readn(sock, &trapframe, sizeof(trapframe));

	if(r < 0) {
		DPRINTF8("Error while trying to receive trapframe (%d): %e\n", r, r);
		return;
	}

	while(1) {
		r = readn(sock, &addr, sizeof(addr));

		if(r < 0) {
			DPRINTF8("Error while trying to receive virtual address (%d): %e\n", r, r);
			return;
		}

		if(addr == MIG_LAST_ADDR) {
			DPRINTF8("Received all pages.");
			break;
		}

		DPRINTF8("About to map address %x ...\n", addr);

		r = readn(sock, data, sizeof(data));
		
		if(r < 0) {
			DPRINTF8("Error while trying to receive data at va (%d): %e\n", r, r);
			return;
		}

		++seen_pages;

		// at this point, we have the address and the va, map it on to the process
		
		if((r = sys_page_alloc(0, PFTEMP, PTE_P | PTE_U | PTE_W)) < 0) {
			panic("sys_page_alloc: %e", r);
		}

		// Copy contents from addr to PFTEMP
		memmove(PFTEMP, data, PGSIZE);

		// Map *our* PFTEMP to child's *addr*
		// TODO: Need proper page permissions
		if((r = sys_page_map(0, PFTEMP, child, (void *) addr, PTE_W|PTE_P|PTE_U)) < 0) {
			panic("sys_page_map: %e", r);
		}

		if ((r = sys_page_unmap(0, PFTEMP)) < 0) {
			panic("sys_page_unmap: %e", r);
		}

		DPRINTF8("Mapped page!\n");
	}

	r = readn(sock, &npages, sizeof(npages));

	if(r < 0) {
		DPRINTF8("Error while trying to receive npages (%d): %e\n", r, r);
		sys_env_destroy(child);
		return;
	}

	if(seen_pages != npages) {
		DPRINTF8("Not seen the right number of pages: expected %d, got %d.\n", npages, seen_pages);
		sys_env_destroy(child);
		return;
	}

	DPRINTF8("Setting trapframe ...\n");
	r = sys_env_set_trapframe(child, &trapframe);
	
	if(r < 0) {
		DPRINTF8("Could not set trapframe (%d): %e\n", r, r);
		sys_env_destroy(child);
		return;
	}


	// make the process runnable
	DPRINTF8("Run lola, run!\n");
	r = sys_env_set_status(child, ENV_RUNNABLE);

	if(r < 0) {
		DPRINTF8("Could not set child to runnable (%d): %e\n", r, r);
		sys_env_destroy(child);
		return;
	}

	// return the child process identifier
	write(sock, &child, sizeof(child));

	return;
}

static void
handle_message(int sock) {
	int r;
	envid_t child;
	uint32_t message_length;

	DPRINTF8("At line %d, sock: %d\n", __LINE__, sock);
	
	r = readn(sock, &child, sizeof(child));
	
	if(r < 0) {
		DPRINTF8("Could not read the child identifier (%d): %e\n", r, r);
		return;
	}

	DPRINTF8("At line %d, child id: %d\n", __LINE__, child);

	r = readn(sock, &message_length, sizeof(message_length));
	
	if(r < 0) {
		DPRINTF8("Could not read the message length (%d): %e\n", r, r);
		return;
	}
	
	void *sbuff = (void *)(UTEMP + 3 * PGSIZE);
	r = sys_page_alloc(0, sbuff, PTE_U|PTE_W|PTE_P);

	if(r < 0) {
		DPRINTF8("Could not allocate page at %x (%d): %e\n", sbuff, r, r);
		return;
	}

	DPRINTF8("At line %d, message length: %d\n", __LINE__, message_length);

	r = readn(sock, sbuff, message_length);
	
	if(r < 0) {
		DPRINTF8("Could not read the message (%d): %e\n", r, r);
		return;
	}

	DPRINTF8("At line %d\n", __LINE__);

	ipc_send(child, message_length, sbuff, PTE_P | PTE_U);
	
	sys_page_unmap(0, sbuff);
	
	uint32_t perm, reply_length;
	DPRINTF8("At line %d\n", __LINE__);

	reply_length = ipc_recv((int *) &child, sbuff, (int *) &perm);
	DPRINTF8("At line %d, length: %d, data: %s\n", __LINE__, reply_length, sbuff);

	if(!perm || !child) {
		DPRINTF8("Did not receive valid reply from child.\n");
		return;
	}

	int message_id = MIG_IPC_MESSAGE;
	DPRINTF8("At line %d, sock: %d\n", __LINE__, sock);

	r = write(sock, (const void*) &message_id, sizeof(MIG_IPC_MESSAGE));
	DPRINTF8("At line %d\n", __LINE__);

	envid_t pid = 0;
	r = write(sock, (const void *) &pid, sizeof(pid));
	DPRINTF8("At line %d\n", __LINE__);

	r = write(sock, (const void *) &reply_length, sizeof(reply_length));
	DPRINTF8("At line %d\n", __LINE__);

	r = write(sock, sbuff, reply_length);

	DPRINTF8("At line %d\n", __LINE__);

	return;
}

static void
handle_client(int sock)
{
	int r = readn(sock, &preamble, sizeof(preamble));

	if(r < 0) {
		DPRINTF8("Error while trying to read preamble (%d): %e\n", r, r);
		close(sock);
		return;
	}

	// the handle_* functions for each 
	switch(preamble) {
		case MIG_HEARTBEAT:
			DPRINTF8("Received heartbeat <3\n");
			break;
		case MIG_PROC_MIGRATE:
			handle_migrate(sock);
			break;
		case MIG_IPC_MESSAGE:
			handle_message(sock);
			break;
		default:
			panic("Invalid migration request: %d\n", preamble);
	}

	// TODO: Uncomment: close(sock);
}

#define PROXY_ON 1
#define PROXY_IP "174.120.183.89"
#define PROXY_PORT 10092

int
umain(void)
{
	int serversock, clientsock;
	struct sockaddr_in server, client;

#ifdef PROXY_ON
	struct sockaddr_in proxy;
#endif

	binaryname = "jmigrated";

#ifdef PROXY_ON
	
	memset(&proxy, 0, sizeof(proxy));              // Clear struct
	proxy.sin_family = AF_INET;                       // Internet/IP
	proxy.sin_addr.s_addr = inet_addr(PROXY_IP);   // IP address // "10.0.2.15"
	proxy.sin_port = htons(PROXY_PORT);	     // server port

	int r;

	while (1) {
		if ((clientsock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) {
			die("Could not create socket to proxy.");
		}

		if ((r = connect(clientsock, (struct sockaddr *) &proxy, sizeof(proxy))) < 0) {
			die("Could not connect to proxy.");
		}

		handle_client(clientsock);
		close(clientsock);
	}

#else
	// Create the TCP socket
	if ((serversock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0)
		die("Failed to create socket");

	// Construct the server sockaddr_in structure
	memset(&server, 0, sizeof(server));		// Clear struct
	server.sin_family = AF_INET;			// Internet/IP
	server.sin_addr.s_addr = htonl(INADDR_ANY);	// IP address
	server.sin_port = htons(MIG_SERVER_PORT);			// server port

	// Bind the server socket
	if (bind(serversock, (struct sockaddr *) &server,
		 sizeof(server)) < 0) 
	{
		die("Failed to bind the server socket");
	}

	// Listen on the server socket
	if (listen(serversock, MAXPENDING) < 0)
		die("Failed to listen on server socket");

	cprintf("Waiting for migration requests ...\n");

	while (1) {
		unsigned int clientlen = sizeof(client);
		// Wait for client connection
		if ((clientsock = accept(serversock,
					 (struct sockaddr *) &client,
					 &clientlen)) < 0) 
		{
			die("Failed to accept client connection");
		}
		handle_client(clientsock);
	}
#endif


	close(serversock);

	return 0;
}
