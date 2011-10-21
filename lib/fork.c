// -*- c-basic-offset: 8; indent-tabs-mode: t -*-
// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

void (*_old_pgfault_handler)(struct UTrapframe *utf)  = NULL;

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at vpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.

	// LAB 4: Your code here.

	panic("pgfault not implemented");
}

#define RETURN_NON_ZERO(r1, r2) 	if (r1) { return r2; }


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

	// LAB 4: Your code here.
	// panic("duppage not implemented");
	void *va = (void*)(pn*PGSIZE);
	uint32_t pentry = vpt[pn];
	int page_perms = pentry & PTE_USER;
	if (page_perms & (PTE_COW | PTE_W)) {
		// Page is writable or COW...
		page_perms = (page_perms | PTE_COW) & (~PTE_W);
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

envid_t
clone(int shared_heap) {
	envid_t new_env = sys_exofork();
	int r;

	if (new_env < 0) {
		panic("sys_exofork: %e", envid);
	}

	if (new_env) {
		// Parent

		// Save old handler
		// _old_pgfault_handler = _pgfault_handler;

		// Set page fault handler to COW handler
		set_pgfault_handler(pgfault);

		// Copy all the page tables to the child
		uint8_t *addr;
		for (addr = (uint8_t*) UTEXT; addr < end; addr += PGSIZE) {
			if (shared_heap) {
				// sfork() use-case
			}
			else {
				// fork() use-case
				duppage(new_env, addr/PGSIZE);
			}
		}

		// Also copy the stack we are currently running on.
		duppage(new_env, ROUNDDOWN(&addr, PGSIZE));

		// Start the child environment running
		if ((r = sys_env_set_status(new_env, ENV_RUNNABLE)) < 0) {
			panic("sys_env_set_status: %e", r);
		}

		return new_env;
	}
	else {
		// Child - do nothing here
		env = &envs[ENVX(sys_getenvid())];
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
