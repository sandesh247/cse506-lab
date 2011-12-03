// -*- c-basic-offset:8; indent-tabs-mode:t -*- 
// User-level IPC library routines

#include <inc/lib.h>

// Receive a value via IPC and return it.
// If 'pg' is nonnull, then any page sent by the sender will be mapped at
//	that address.
// If 'from_env_store' is nonnull, then store the IPC sender's envid in
//	*from_env_store.
// If 'perm_store' is nonnull, then store the IPC sender's page permission
//	in *perm_store (this is nonzero iff a page was successfully
//	transferred to 'pg').
// If the system call fails, then store 0 in *fromenv and *perm (if
//	they're nonnull) and return the error.
// Otherwise, return the value sent by the sender
//
// Hint:
//   Use 'env' to discover the value and who sent it.
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
	// LAB 4: Your code here.
	int error;
	error = sys_ipc_recv(pg != NULL ? pg : (void *) ~0);

	if(error < 0) {
		DPRINTF8("Error receiving in environment [user] %d: %e\n", sys_getenvid(), error);
		if(from_env_store) *from_env_store = 0;
		if(perm_store) *perm_store = 0;
		return error;
	}
	
	// DPRINTF8("Received in environment [user] %d.\n", sys_getenvid());
	assert(env->env_ipc_from);

	if(from_env_store) *from_env_store = env->env_ipc_from;
	if(perm_store) *perm_store = env->env_ipc_perm;

	/*
	if(pg) {
		// the value is a page
		error = sys_page_map(env->env_ipc_from, (void *) env->env_ipc_value, 
				     env->env_id, pg, env->env_ipc_perm);
		if (error) {
			if(from_env_store) *from_env_store = 0;
			if(perm_store) *perm_store = 0;
			return error;
		}
	}
	*/

	return env->env_ipc_value;
}

// Send 'val' (and 'pg' with 'perm', if 'pg' is nonnull) to 'toenv'.
// This function keeps trying until it succeeds.
// It should panic() on any error other than -E_IPC_NOT_RECV.
//
// Hint:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
	// LAB 4: Your code here.
	//
	DPRINTF5("ipc_send(%d, %u, %x)\n", to_env, val, pg);
	int error;
	while((error = sys_ipc_try_send(to_env, val, !pg ? (void*)UTOP : pg, perm)) == -E_IPC_NOT_RECV) {
		sys_yield();
		DPRINTF4C("Retrying ipc_send() ...\n");
	}
        if (error) {
		panic("Aiee!! sys_ipc_try_send() returned: %e\n", error);
        }
}
