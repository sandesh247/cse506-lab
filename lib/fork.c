// -*- c-basic-offset: 8; indent-tabs-mode: t -*-
// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>
#include <inc/mmu.h>
#include <inc/x86.h>


// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

#define RETURN_NON_ZERO(r1, r2) 	if (r1) { return r2; }


void (*_old_pgfault_handler)(struct UTrapframe *utf)  = NULL;
extern void (*_pgfault_handler)(struct UTrapframe *utf);


// 
// Copy a page at 'addr' in OUR address space to 'addr' in destid's address
// space. Use *our* PFTEMP as a temporary buffer
//
void
copypage(envid_t destid, void *addr, int perm) {
	int r;
	DPRINTF4("copypage::addr: %x, ROUNDDOWN(addr, %d): %x\n", addr, PGSIZE, ROUNDDOWN(addr, PGSIZE));
	// assert(ROUNDDOWN(addr, PGSIZE) == addr);
	addr = ROUNDDOWN(addr, PGSIZE);
	// Map a page at PFTEMP in *our* address space

	if((r = sys_page_alloc(0, PFTEMP, PTE_P | PTE_U | PTE_W)) < 0) {
		panic("sys_page_alloc: %e", r);
	}

	// Copy contents from addr to PFTEMP
	memmove(PFTEMP, addr, PGSIZE);

	cprintf("&copypage: %x, addr: %x\n", &copypage, addr);

	// Map *our* PFTEMP to destid's *addr*
	if((r = sys_page_map(0, PFTEMP, destid, addr, PTE_W|PTE_P|PTE_U /*perm*/)) < 0) {
		panic("sys_page_map: %e", r);
	}

	if ((r = sys_page_unmap(0, PFTEMP)) < 0) {
		panic("sys_page_unmap: %e", r);
	}

	DPRINTF4("copypage::done!\n");
}

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	DPRINTF4("pgfault() called\n");
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	cprintf("pgfault(va: %x, err: %d)\n", addr, err);

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at vpt
	//   (see <inc/memlayout.h>).
	// LAB 4: Your code here.
	int pn = (uint32_t)addr / PGSIZE;

	// maybe use constants FEC_* in mmu.h ?
	// if(!((err & 0x7) == 0x7)) {
	if (!(err & FEC_WR)) {
		panic("pgfault error. write not set. Got: %d\n", (err & 0x7));
	}

	if(!(vpt[pn] & PTE_COW)) {
		panic("write fault on a non-COW page");
	}

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.

	// LAB 4: Your code here.
	int eid = sys_getenvid();
	// DPRINTF4("pgfault::envid: %d, env: %x\n", eid, &envs[ENVX(eid)]);
	int perm = PTE_U|PTE_W|PTE_P; 
	// (PTE_PERM(vpt[pn]) | PTE_W) & (~PTE_COW);
	DPRINTF4("pgfault::Copying page at address: %x with permissions %d\n", addr, perm);
	copypage(0, addr, perm);

	// panic("pgfault not implemented");
}


//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
// 
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// copypage(envid, (void*)(pn*PGSIZE), PTE_U|PTE_P|PTE_W);
	// return 0;

	// LAB 4: Your code here.
	// panic("duppage not implemented");
	void *va = (void*)(pn*PGSIZE);
	uint32_t pentry = vpt[pn];
	int page_perms = PTE_PERM(pentry); // & PTE_USER;
	if (page_perms & (PTE_COW | PTE_W)) {
		// Page is writable or COW...
		DPRINTF4("page_perms: %d\n", page_perms);
		page_perms |= PTE_COW;
		page_perms &= (~PTE_W);

		// TODO: Remove the line below
		page_perms = PTE_U|PTE_P|PTE_COW;

		r = sys_page_map(0, va, envid, va, page_perms);
		RETURN_NON_ZERO(r, r);

		// Also set self to COW
		r = sys_page_map(0, va, 0, va, page_perms);

		RETURN_NON_ZERO(r, r);
	}
	else {
		r = sys_page_map(0, va, envid, va, page_perms);
		RETURN_NON_ZERO(r, r);
	}

	return 0;
}


extern void _pgfault_upcall(void);
int ctr = 0;

envid_t
clone(int shared_heap) {
	DPRINTF4("clone(%d), PFTEMP: %x\n", shared_heap, PFTEMP);

	int eid = sys_getenvid();
	DPRINTF4("clone::envid: %d, env: %x\n", eid, &envs[ENVX(eid)]);

	// Save old handler
	// _old_pgfault_handler = _pgfault_handler;

	// Set page fault handler to COW handler in the parent process
	set_pgfault_handler(pgfault);
	DPRINTF4("Successfully set the pgfault_handler in parent\n");

	// sys_yield();

	envid_t cur_env = sys_getenvid();
	envid_t new_env = sys_exofork();
	int r;
	DPRINTF4("clone::new_env: %d\n", new_env);

	// sys_yield();

	if (new_env < 0) {
		panic("sys_exofork: %e", new_env);
	}

	// return new_env;

	if (new_env) {
		// Parent

		// sys_yield();

		DPRINTF4("clone::[1] Parent: _pgfault_handler: %x\n", _pgfault_handler);

		// Copy all the page tables to the child
		uint8_t *addr;
		extern unsigned char end[];
		for (addr = (uint8_t*) UTEXT; addr <= end /* Check < */; addr += PGSIZE) {
			DPRINTF4("[%d<-%d] Mapping page at address: %x\n", new_env, cur_env, addr);
			if (0 /*shared_heap*/) {
				// sfork() use-case
			}
			else {
				// fork() use-case
#if 0
				copypage(new_env, addr, (PTE_P|PTE_U|PTE_W));
#else
				r = duppage(new_env, ((uint32_t)addr)/PGSIZE);
				if (r) {
					panic("duppage: %e\n");
				}
#endif
			}
		}

		DPRINTF4("RD(&addr): %x, USTACKTOP-PGSIZE: %x\n", ROUNDDOWN(&addr, PGSIZE), USTACKTOP-PGSIZE);
		// Also copy the stack we are currently running on.
		copypage(new_env, (void*)ROUNDDOWN(&addr, PGSIZE), PTE_P|PTE_W|PTE_U);

		// Allocate a new trap-time stack.
		copypage(new_env, (void*)(UXSTACKTOP - PGSIZE), PTE_P|PTE_W|PTE_U);

		// Set the upcall in the child process.
		sys_env_set_pgfault_upcall(new_env, _pgfault_upcall);

		if (++ctr > 0) {
			// Start the child environment running
			if ((r = sys_env_set_status(new_env, ENV_RUNNABLE)) < 0) {
				panic("sys_env_set_status: %e", r);
			}
		}

		DPRINTF4("clone::returning: %d\n", new_env);
		return new_env;
	}
	else {
		cprintf("[1] In Child (%d), _pgfault_handler: %x\n", sys_getenvid(), _pgfault_handler);

		// Child - do nothing here
		env = &envs[ENVX(sys_getenvid())];

		cprintf("[2] In Child (%d)\n", sys_getenvid());

		return 0;
	}
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use vpd, vpt, and duppage.
//   Remember to fix "env" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
	// panic("fork not implemented");
	return clone(0);
}


// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
