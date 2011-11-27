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
			break;
		}

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

	r = sys_env_set_trapframe(child, &trapframe);
	
	if(r < 0) {
		DPRINTF8("Could not set trapframe (%d): %e\n", r, r);
		sys_env_destroy(child);
	}


	// make the process runnable
	r = sys_env_set_status(child, ENV_RUNNABLE);

	if(r < 0) {
		DPRINTF8("Could not set child to runnable (%d): %e\n", r, r);
		sys_env_destroy(child);
	}

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
		default:
			panic("Invalid migration request: %d\n", preamble);
	}

	close(sock);
}



int
umain(void)
{
	int serversock, clientsock;
	struct sockaddr_in server, client;

	binaryname = "jmigrated";

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

	close(serversock);

	return 0;
}