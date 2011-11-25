/* -*- c-basic-offset: 8; indent-tabs-mode: t -*-
 * See COPYRIGHT for copyright information.
 */

#include <inc/x86.h>
#include <inc/error.h>
#include <inc/string.h>
#include <inc/assert.h>

#include <kern/env.h>
#include <kern/pmap.h>
#include <kern/trap.h>
#include <kern/syscall.h>
#include <kern/console.h>
#include <kern/sched.h>
#include <kern/time.h>
#include <kern/e100.h>

// Print a string to the system console.
// The string is exactly 'len' characters long.
// Destroys the environment on memory errors.
static void
sys_cputs(const char *s, size_t len)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.
	DPRINTF("sys_cputs::begin\n");
	
	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
}

// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
}

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
}

// Destroy a given environment (possibly the currently running environment).
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
		return r;
	env_destroy(e);
	return 0;
}

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
}

// Allocate a new environment.
// Returns envid of new environment, or < 0 on error.  Errors are:
//	-E_NO_FREE_ENV if no free environment is available.
//	-E_NO_MEM on memory exhaustion.
static envid_t
sys_exofork(void)
{
	// Create the new environment with env_alloc(), from kern/env.c.
	// It should be left as env_alloc created it, except that
	// status is set to ENV_NOT_RUNNABLE, and the register set is copied
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	struct Env *ne;
	int r;
	if ((r = env_alloc(&ne, curenv->env_id))) {
		return r;
	}

	ne->env_tf = curenv->env_tf;

	// Set return value to 0 in the child
	ne->env_tf.tf_regs.reg_eax = 0;

	// ne->env_tf.tf_esp = e->env_tf.tf_esp;
	ne->env_status = ENV_NOT_RUNNABLE;

	return ne->env_id;
}

// Set envid's env_status to status, which must be ENV_RUNNABLE
// or ENV_NOT_RUNNABLE.
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if status is not a valid status for an environment.
static int
sys_env_set_status(envid_t envid, int status)
{
	// Hint: Use the 'envid2env' function from kern/env.c to translate an
	// envid to a struct Env.
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.

	// LAB 4: Your code here.
	// panic("sys_env_set_status not implemented");
	struct Env *e = NULL;
	int ret = envid2env(envid, &e, 1);
	if (ret) {
		DPRINTF4C("Could not set status of %d: %e.\n", envid, ret);
		return ret;
	}
	if (status != ENV_RUNNABLE && status != ENV_NOT_RUNNABLE) {
		DPRINTF4C("Could not set status of %d: invalid arg %d.\n", envid, status);
		return -E_INVAL;
	}
	e->env_status = (unsigned)status;
	DPRINTF4C("Set %d to %s.\n", e->env_id, status == ENV_RUNNABLE ? "ENV_RUNNABLE" : "ENV_NOT_RUNNABLE");
	return 0;
}

// Set envid's trap frame to 'tf'.
// tf is modified to make sure that user environments always run at code
// protection level 3 (CPL 3) with interrupts enabled.
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int
sys_env_set_trapframe(envid_t envid, struct Trapframe *tf)
{
	// LAB 5: Your code here.
	// Remember to check whether the user has supplied us with a good
	// address!
	int r;
	struct Env *env;
	if((r = envid2env(envid, &env, 1)) < 0) {
		return -E_BAD_ENV;
	}

	if((r = user_mem_check(env, tf, sizeof(struct Trapframe), PTE_U)) < 0) {
		// Question: Is this right? we are only allowed to
		// return -E_BAD_ENV, accroding to the comments.
		return -E_BAD_ENV;
	}

	env->env_tf = *tf;
	env->env_tf.tf_ds |= 3;
	env->env_tf.tf_es |= 3;
	env->env_tf.tf_ss |= 3;
	env->env_tf.tf_cs |= 3;
	env->env_tf.tf_eflags = FL_IF;

	DPRINTF5("sys_env_set_trapframe: returned success.\n");

	return 0;
}

// Set the page fault upcall for 'envid' by modifying the corresponding struct
// Env's 'env_pgfault_upcall' field.  When 'envid' causes a page fault, the
// kernel will push a fault record onto the exception stack, then branch to
// 'func'.
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	// panic("sys_env_set_pgfault_upcall not implemented");
	assert(func);

	struct Env *e = NULL;
	int ret = envid2env(envid, &e, 1);
	if (ret) {
		return -E_BAD_ENV;
	}

	e->env_pgfault_upcall = func;
	return 0;
}

// Allocate a page of memory and map it at 'va' with permission
// 'perm' in the address space of 'envid'.
// The page's contents are set to 0.
// If a page is already mapped at 'va', that page is unmapped as a
// side effect.
//
// perm -- PTE_U | PTE_P must be set, PTE_AVAIL | PTE_W may or may not be set,
//         but no other bits may be set.  See PTE_USER in inc/mmu.h.
//
// Return 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if va >= UTOP, or va is not page-aligned.
//	-E_INVAL if perm is inappropriate (see above).
//	-E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	// Hint: This function is a wrapper around page_alloc() and
	//   page_insert() from kern/pmap.c.
	//   Most of the new code you write should be to check the
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!

	// LAB 4: Your code here.
	// panic("sys_page_alloc not implemented");

	DPRINTF4("sys_page_alloc(%x)\n", va);
	if ((perm & (PTE_P | PTE_U)) != (PTE_P|PTE_U)) {
		DPRINTF4("perm 1\n");
		return -E_INVAL;
	}
	if (perm & ~PTE_USER) {
		DPRINTF4("perm 2\n");
		return -E_INVAL;
	}

	struct Env *e = NULL;
	int ret = envid2env(envid, &e, 1);
	if (ret) {
		return -E_BAD_ENV;
	}

	if ((uint32_t)va > UTOP || 
	    ROUNDDOWN((uint32_t)va, PGSIZE) != (uint32_t)va) {
		DPRINTF4("VA > UTOP OR VA is not Page Aligned\n");
		return -E_INVAL;
	}

	struct Page *page = NULL;
	ret = page_alloc(&page);
	if (ret) {
		return -E_NO_MEM;
	}

	ret = page_insert(e->env_pgdir, page, va, perm);
	DPRINTF4("sys_page_alloc::e: %x, va: %x\n", e, va);

	if (ret) {
		page_decref(page);
	}
	else {
		memset(KADDR(page2pa(page)), 0, PGSIZE);
	}

	return ret;
}

// Map the page of memory at 'srcva' in srcenvid's address space
// at 'dstva' in dstenvid's address space with permission 'perm'.
// Perm has the same restrictions as in sys_page_alloc, except
// that it also must not grant write access to a read-only
// page.
//
// Return 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if srcenvid and/or dstenvid doesn't currently exist,
//		or the caller doesn't have permission to change one of them.
//	-E_INVAL if srcva >= UTOP or srcva is not page-aligned,
//		or dstva >= UTOP or dstva is not page-aligned.
//	-E_INVAL is srcva is not mapped in srcenvid's address space.
//	-E_INVAL if perm is inappropriate (see sys_page_alloc).
//	-E_INVAL if (perm & PTE_W), but srcva is read-only in srcenvid's
//		address space.
//	-E_NO_MEM if there's no memory to allocate any necessary page tables.
static int
sys_page_map(envid_t srcenvid, void *srcva,
	     envid_t dstenvid, void *dstva, int perm)
{
	// Hint: This function is a wrapper around page_lookup() and
	//   page_insert() from kern/pmap.c.
	//   Again, most of the new code you write should be to check the
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	DPRINTF("sys_page_map(%d, %x, %d, %x, %d)\n", 
		srcenvid, srcva, dstenvid, dstva, perm);
	struct Env *se, *de;
	int error;

	error = envid2env(srcenvid, &se, 1);
	if (error) return -E_BAD_ENV;

	error = envid2env(dstenvid, &de, 1);
	if (error) return -E_BAD_ENV;

	if (((uint32_t)srcva >= UTOP || ((uint32_t)srcva % PGSIZE)) || 
	    ((uint32_t)dstva >= UTOP || ((uint32_t)dstva % PGSIZE))) {
		return -E_INVAL;
	}

	pte_t *spte;
	struct Page *spp = page_lookup(se->env_pgdir, srcva, &spte);
	if (spp == 0 || (*spte & PTE_P) == 0) {
		return -E_INVAL;
	}

	if ((PTE_W & perm) && !(PTE_W & *spte)) {
		return -E_INVAL;
	}

	error = page_insert(de->env_pgdir, spp, dstva, perm);
	if (error) return -E_NO_MEM;

	return 0;
}

// Unmap the page of memory at 'va' in the address space of 'envid'.
// If no page is mapped, the function silently succeeds.
//
// Return 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if va >= UTOP, or va is not page-aligned.
static int
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	// panic("sys_page_unmap not implemented");
	struct Env *e;
	int ret;

	ret = envid2env(envid, &e, 1);
	if (ret) {
		return -E_BAD_ENV;
	}

	if ((uint32_t)va >= UTOP || 
	    ROUNDDOWN((uint32_t)va, PGSIZE) != (uint32_t)va) {
		return -E_INVAL;
	}

	page_remove(e->env_pgdir, va);
	return 0;
}

// Try to send 'value' to the target env 'envid'.
// If srcva < UTOP, then also send page currently mapped at 'srcva',
// so that receiver gets a duplicate mapping of the same page.
//
// The send fails with a return value of -E_IPC_NOT_RECV if the
// target is not blocked, waiting for an IPC.
//
// The send also can fail for the other reasons listed below.
//
// Otherwise, the send succeeds, and the target's ipc fields are
// updated as follows:
//    env_ipc_recving is set to 0 to block future sends;
//    env_ipc_from is set to the sending envid;
//    env_ipc_value is set to the 'value' parameter;
//    env_ipc_perm is set to 'perm' if a page was transferred, 0 otherwise.
// The target environment is marked runnable again, returning 0
// from the paused sys_ipc_recv system call.  (Hint: does the
// sys_ipc_recv function ever actually return?)
//
// If the sender wants to send a page but the receiver isn't asking for one,
// then no page mapping is transferred, but no error occurs.
// The ipc only happens when no errors occur.
//
// Returns 0 on success, < 0 on error.
// Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist.
//		(No need to check permissions.)
//	-E_IPC_NOT_RECV if envid is not currently blocked in sys_ipc_recv,
//		or another environment managed to send first.
//	-E_INVAL if srcva < UTOP but srcva is not page-aligned.
//	-E_INVAL if srcva < UTOP and perm is inappropriate
//		(see sys_page_alloc).
//	-E_INVAL if srcva < UTOP but srcva is not mapped in the caller's
//		address space.
//	-E_INVAL if (perm & PTE_W), but srcva is read-only in the
//		current environment's address space.
//	-E_NO_MEM if there's not enough memory to map srcva in envid's
//		address space.
static int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, unsigned perm)
{
	assert(envid);
	// LAB 4: Your code here.
	// panic("sys_ipc_try_send not implemented");
	
	DPRINTF6("Trying to send message %u, %x from %d to %d.\n", value, srcva, curenv->env_id, envid);

	struct Env *env;
	int error;

	if ((error = envid2env(envid, &env, 0)) < 0) {
		DPRINTF6("Bad environment %d.\n", envid);
		return -E_BAD_ENV;
	}

	if (!env->env_ipc_recving) {
		DPRINTF6("Bad environment %d - not receiving.\n", envid);
		return -E_IPC_NOT_RECV;
	}

	env->env_ipc_value = value;
	
	if ((uint32_t) env->env_ipc_dstva < UTOP && 
	    (uint32_t) env->env_ipc_dstva >= 0 && 
	    (uint32_t) srcva < UTOP) {
		DPRINTF4C("Environment %d looking for mapping in %x.\n", envid, env->env_ipc_dstva);

		if (ROUNDDOWN(srcva, PGSIZE) != srcva) {
			DPRINTF6("[2] Bad va %x for environment %d.\n", srcva, curenv->env_id);
			return -E_INVAL;
		}

		// TODO: Why is this commented out??
		// if ((perm & (PTE_P | PTE_U)) != (PTE_P|PTE_U)) {
		//	return -E_INVAL;
		//}
		
		//if (perm & ~PTE_USER) {
	//		return -E_INVAL;
	//	}
		
		pte_t *spte;
		struct Page *spp;
		
		spp = page_lookup(curenv->env_pgdir, srcva, &spte);
		if (spp == 0 || (*spte & PTE_P) == 0) {
			DPRINTF6("[3] Bad va %x for environment %d: Not mapped. spp: %x, spte: %d\n", srcva, curenv->env_id, spp, *spte);
			return -E_INVAL;
		}

		if (perm & PTE_W && !(*spte & PTE_W)) {
			DPRINTF6("[4] Bad va %x for environment %d: permission mismatch.\n", srcva, curenv->env_id);
			return -E_INVAL;
		}

		// Map page in target's address space
		if ((error = page_insert(env->env_pgdir, spp, env->env_ipc_dstva, perm)) != 0) {
			DPRINTF6("Could not insert page at VA %x in environment %x: %e\n", env->env_ipc_dstva, env->env_id, error);
			return -E_INVAL;
		}
	}

	// TODO: How do we check for no memory? We are sharing a page.
	
	env->env_ipc_recving = 0;
	env->env_ipc_from = curenv->env_id;
	env->env_ipc_perm = perm;

	env->env_tf.tf_regs.reg_eax = 0;
	DPRINTF4C("Value sent - setting %d to runnable.\n", envid);
	DPRINTF4C("from, perm, value: %d, %d, %d.\n", env->env_ipc_from, env->env_ipc_perm, env->env_ipc_value);
	
	// sys_env_set_status(envid, ENV_RUNNABLE);
	// TODO: Setting this manually for now, since we know env to be good.
	env->env_status = ENV_RUNNABLE;

	return 0;
}

// Block until a value is ready.  Record that you want to receive
// using the env_ipc_recving and env_ipc_dstva fields of struct Env,
// mark yourself not runnable, and then give up the CPU.
//
// If 'dstva' is < UTOP, then you are willing to receive a page of data.
// 'dstva' is the virtual address at which the sent page should be mapped.
//
// This function only returns on error, but the system call will eventually
// return 0 on success.
// Return < 0 on error.  Errors are:
//	-E_INVAL if dstva < UTOP but dstva is not page-aligned.
static int
sys_ipc_recv(void *dstva)
{
	// LAB 4: Your code here.
	//
	DPRINTF6("Environment %d looking for data on %x.\n", curenv->env_id, dstva);
	
	if (ROUNDDOWN(dstva, PGSIZE) != dstva && (uint32_t)dstva < UTOP) {
		return -E_INVAL;
	}
	curenv->env_ipc_recving = 1;
	curenv->env_ipc_dstva = dstva;
	sys_env_set_status(0, ENV_NOT_RUNNABLE);
	curenv->env_tf.tf_regs.reg_eax = 0;
	DPRINTF4C("Blocking on sys_recv: %d.\n", curenv->env_id);
	sys_yield();

	// never called
	assert(0);
	return 0;
}

// Return the current time.
static int
sys_time_msec(void) 
{
	// LAB 6: Your code here.
	// panic("sys_time_msec not implemented");
	return time_msec();
}


static struct Page*
check_(struct Env* e, void* va, int size, int perm) {
	struct Page *page;
	int r;


	uint32_t _va = (uint32_t)va;
	if ((_va >> 12) != ((_va + size) >> 12)) {
		DPRINTF6("[2] _va2pa::across pages check failed\n");
		return NULL;
	}

	page = page_lookup(e->env_pgdir, va, 0);
	if (!page) {
		DPRINTF6("[3] _va2pa::page_lookup failed\n");
		return NULL;
	}
	return page;
}

static int
sys_net_send(void *va, int size) {
	DPRINTF6("sys_net_send(%x, %d)\n", va, size);
	int r;
	if ((r = user_mem_check(curenv, va, size, PTE_P|PTE_U))) {
		DPRINTF6("sys_net_send::user_mem_check failed\n");
		return -1;
	}

	r = e100_transmit(va, size);
	DPRINTF6("sys_net_send::r == %d\n", r);
	return r;
}

static int
sys_net_recv(void *va, int size) {
	DPRINTF6("sys_net_recv(%x, %d)\n", va, size);
	int r;
	if ((r = user_mem_check(curenv, va, size, PTE_P|PTE_U|PTE_W))) {
		DPRINTF6("sys_net_recv::user_mem_check failed with error: %e\n", r);
		return -1;
	}

	r = e100_receive(va, size);
	DPRINTF6("sys_net_recv::r == %d\n", r);
	if (r < 0) {
		r = 0;
	}
	return r;
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	DPRINTF("syscall(%u, %u, %u)\n", syscallno, a1, a2);

	switch (syscallno) {
	case SYS_cputs:
		sys_cputs((const char*)a1, (size_t)a2);
		return 0;
		break;

	case SYS_cgetc:
		return sys_cgetc();
		break;

	case SYS_getenvid:
		return sys_getenvid();
		break;

	case SYS_env_destroy:
		return sys_env_destroy((envid_t)a1);
		break;

	case SYS_yield:
		sys_yield();
		return 0;
		break;

        case SYS_exofork:
		return sys_exofork();
		break;

	case SYS_page_alloc:
		return (int32_t)sys_page_alloc((envid_t)a1, (void*)a2, (int)a3);
		break;

	case SYS_page_map:
		return sys_page_map((envid_t)a1, (void*)a2, 
				    (envid_t)a3, (void*)a4, (int)a5);
		break;

	case SYS_page_unmap:
		return sys_page_unmap((envid_t)a1, (void*)a2);
		break;

	case SYS_env_set_status:
		return sys_env_set_status((envid_t)a1, (int)a2);
		break;

	case SYS_env_set_pgfault_upcall:
		return sys_env_set_pgfault_upcall((envid_t)a1, (void*)a2);
		break;
	
	case SYS_ipc_recv:
		return sys_ipc_recv((void *) a1);

	case SYS_ipc_try_send:
		return sys_ipc_try_send((envid_t) a1, (uint32_t) a2, (void *) a3, (int) a4);

	case SYS_env_set_trapframe:
		return sys_env_set_trapframe((envid_t) a1, (struct Trapframe *) a2);

	case SYS_time_msec:
		return sys_time_msec();

	case SYS_net_send:
		return sys_net_send((void*)a1, (int)a2);

	case SYS_net_recv:
		return sys_net_recv((void*)a1, (int)a2);

	}

	DPRINTF4("syscall number '%d' not yet implemented\n", syscallno);
	panic("syscall not implemented");
	return 0;
}

