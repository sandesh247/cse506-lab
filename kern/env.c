/* -*- c-basic-offset: 8; indent-tabs-mode: t -*- */
/* See COPYRIGHT for copyright information. */

#include <inc/x86.h>
#include <inc/mmu.h>
#include <inc/error.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/elf.h>

#include <kern/env.h>
#include <kern/pmap.h>
#include <kern/trap.h>
#include <kern/monitor.h>
#include <kern/sched.h>

struct Env *envs = NULL;		// All environments
struct Env *curenv = NULL;		// The current env
static struct Env_list env_free_list;	// Free list

#define ENVGENSHIFT	12		// >= LOGNENV

//
// Converts an envid to an env pointer.
// If checkperm is set, the specified environment must be either the
// current environment or an immediate child of the current environment.
//
// RETURNS
//   0 on success, -E_BAD_ENV on error.
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
		*env_store = curenv;
		return 0;
	}

	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
	if (e->env_status == ENV_FREE || e->env_id != envid) {
		*env_store = 0;
		return -E_BAD_ENV;
	}

	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
		*env_store = 0;
		return -E_BAD_ENV;
	}

	*env_store = e;
	return 0;
}

//
// Mark all environments in 'envs' as free, set their env_ids to 0,
// and insert them into the env_free_list.
// Insert in reverse order, so that the first call to env_alloc()
// returns envs[0].
//
void
env_init(void)
{
	int e;
	for(e = NENV - 1; e >= 0; --e) {
		envs[e].env_status = ENV_FREE;
		envs[e].env_id = 0;
		LIST_INSERT_HEAD(&env_free_list, &envs[e], env_link);
	}
}

//
// Initialize the kernel virtual memory layout for environment e.
// Allocate a page directory, set e->env_pgdir and e->env_cr3 accordingly,
// and initialize the kernel portion of the new environment's address space.
// Do NOT (yet) map anything into the user portion
// of the environment's virtual address space.
//
// Returns 0 on success, < 0 on error.  Errors include:
//	-E_NO_MEM if page directory or table could not be allocated.
//
static int
env_setup_vm(struct Env *e)
{
	int i, r;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if ((r = page_alloc(&p)) < 0)
		return r;

	// Now, set e->env_pgdir and e->env_cr3,
	// and initialize the page directory.
	//
	// Hint:
	//    - Remember that page_alloc doesn't zero the page.
	// 
	//    - The VA space of all envs is identical above UTOP
	//	(except at VPT and UVPT, which we've set below).
	//	See inc/memlayout.h for permissions and layout.
	//	Can you use boot_pgdir as a template?  Hint: Yes.
	//	(Make sure you got the permissions right in Lab 2.)
	// 
	//    - The initial VA below UTOP is empty.
	// 
	//    - You do not need to make any more calls to page_alloc.
	// 
	//    - Note: In general, pp_ref is not maintained for
	//	physical pages mapped only above UTOP, but env_pgdir
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	// 
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = page2kva(p);
	e->env_cr3 = page2pa(p);

        // Initialize pgdir
	memmove(e->env_pgdir, boot_pgdir, PGSIZE);

	// TODO: Map memory - Sandy says that I said that memmove() takes
	// care of everything.

	// VPT and UVPT map the env's own page table, with
	// different permissions.
	e->env_pgdir[PDX(VPT)]  = e->env_cr3 | PTE_P | PTE_W;
	e->env_pgdir[PDX(UVPT)] = e->env_cr3 | PTE_P | PTE_U;

	return 0;
}

//
// Allocates and initializes a new environment.
// On success, the new environment is stored in *newenv_store.
//
// Returns 0 on success, < 0 on failure.  Errors include:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = LIST_FIRST(&env_free_list)))
		return -E_NO_FREE_ENV;

	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
	if (generation <= 0)	// Don't create a negative env_id.
		generation = 1 << ENVGENSHIFT;
	e->env_id = generation | (e - envs);
	
	// Set the basic status variables.
	e->env_parent_id = parent_id;
	e->env_status = ENV_RUNNABLE;
	e->env_runs = 0;

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));

	// Set up appropriate initial values for the segment registers.
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.
	e->env_tf.tf_ds = GD_UD | 3;
	e->env_tf.tf_es = GD_UD | 3;
	e->env_tf.tf_ss = GD_UD | 3;
	e->env_tf.tf_esp = USTACKTOP;
	e->env_tf.tf_cs = GD_UT | 3;
	e->env_tf.tf_eflags = FL_IF; 
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;

	// If this is the file server (e == &envs[1]) or net server(I added this), give it I/O privileges.
	// LAB 5: Your code here.
	// TODO: Remove - we are giving every proces I/O privileges.
	if (1 == 1 || e == envs + 1 || e == envs + 2) {
		e->env_tf.tf_eflags |= FL_IOPL_MASK;
	}

	// commit the allocation
	LIST_REMOVE(e, env_link);
	*newenv_store = e;

	// cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}

//
// Allocate len bytes of physical memory for environment env,
// and map it at virtual address va in the environment's address space.
// Does not zero or otherwise initialize the mapped pages in any way.
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
segment_alloc(struct Env *e, void *va, size_t len)
{
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	//
	// Hint: It is easier to use segment_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.

	DPRINTF("segment_alloc(%x, %x, %u)\n", e, va, len);

	void 
		*start = ROUNDDOWN(va, PGSIZE),
		*end   = ROUNDUP(va + len, PGSIZE);

	uintptr_t mem;
	for (mem = (uintptr_t)start; mem < (uintptr_t)end; mem += PGSIZE) {
		pte_t *pte = pgdir_walk(e->env_pgdir, (const void*)mem, 0);
		if (pte && (*pte & PTE_P)) {
			DPRINTF("VA %x is already backed by PA %x\n", mem, PTE_ADDR(*pte));
			continue;
		}

		// allocate a new page
		struct Page *newp;
		int fail = page_alloc(&newp);

		if (fail < 0) {
			panic("FAILED to allocate a page (%e). We can't expect much more", fail);
			return;
		}
		page_insert(e->env_pgdir, newp, (void*)mem, PTE_W | PTE_P | PTE_U);
	}
	DPRINTF("segment_alloc::done allocating segments\n");
}

//
// Set up the initial program binary, stack, and processor flags
// for a user process.
// This function is ONLY called during kernel initialization,
// before running the first user-mode environment.
//
// This function loads all loadable segments from the ELF binary image
// into the environment's user memory, starting at the appropriate
// virtual addresses indicated in the ELF program header.
// 
// At the same time it clears to zero any portions of these segments
// that are marked in the program header as being mapped
// but not actually present in the ELF file - i.e., the program's bss section.
//
// All this is very similar to what our boot loader does, except the boot
// loader also needs to read the code from disk.  Take a look at
// boot/main.c to get ideas.
//
// Finally, this function maps one page for the program's initial stack.
//
// load_icode panics if it encounters problems.
//  - How might load_icode fail?  What might be wrong with the given input?
//
static void
load_icode(struct Env *e, uint8_t *binary, size_t size)
{
	// Hints: 
	//  Load each program segment into virtual memory
	//  at the address specified in the ELF section header.
	//
	//  [1] You should only load segments with ph->p_type == ELF_PROG_LOAD.
	// 
	//  [2] Each segment's virtual address can be found in ph->p_va
	//  and its size in memory can be found in ph->p_memsz.
	// 
	//  [3] The ph->p_filesz bytes from the ELF binary, starting at
	//  'binary + ph->p_offset', should be copied to virtual address
	//  ph->p_va.  Any remaining memory bytes should be cleared to zero.
	//  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
	//  Use functions from the previous lab to allocate and map pages.
	//
	//  All page protection bits should be user read/write for now.
	//  ELF segments are not necessarily page-aligned, but you can
	//  assume for this function that no two segments will touch
	//  the same virtual page.
	//
	//  You may find a function like segment_alloc useful.
	//
	//  Loading the segments is much simpler if you can move data
	//  directly into the virtual addresses stored in the ELF binary.
	//  So which page directory should be in force during
	//  this function?
	//
	//  You must also do something with the program's entry point,
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	DPRINTF("load_icode(%x, %x, %d)\n", e, binary, size);

	struct Elf *elf = (struct Elf*)binary;
	struct Proghdr *ph, *eph;
	struct Secthdr *sh, *esh;

	// is this a valid ELF?
	if (elf->e_magic != ELF_MAGIC) {
		panic("Invalid ELF magic. Expected %d, got %d\n", ELF_MAGIC, elf->e_magic);
		return;
	}

	pde_t *old_cr3 = (pde_t*)rcr3();
	DPRINTF("Before loading CR3 with %u\n", e->env_cr3);
	lcr3(e->env_cr3);
	DPRINTF("After loading CR3 with %u\n", e->env_cr3);

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
	eph = ph + elf->e_phnum;
	for (; ph < eph; ph++) {
		if (ph->p_type == ELF_PROG_LOAD) {
			DPRINTF("Loading ELF header at %x\n", ph);

			// Copy ph->p_memsz bytes from binary +
			// ph->p_offset into the virtual address
			// ph->p_va as mapped in the new
			// program. Check if ph->p_filesz <=
			// ph->p_memsz for each header entry.
			// 
			// Any remaining memory bytes should be
			// cleared to zero.

			assert(ph->p_filesz <= ph->p_memsz);
			segment_alloc(e, (void*)ph->p_va, ph->p_memsz);

			DPRINTF("Before memset(%x, 0, %u)\n", ROUNDDOWN(ph->p_va, PGSIZE), ROUNDUP(ph->p_memsz, PGSIZE));
			// Zero out the segment
			lcr3(e->env_cr3);

			memset((void*)ROUNDDOWN(ph->p_va, PGSIZE), 0, ROUNDUP(ph->p_memsz, PGSIZE));

			DPRINTF("Before memmove\n");
			// Copy the data.
			memmove((void*)ph->p_va, binary + ph->p_offset, ph->p_filesz);
		}
	}

	// At the same time it clears to zero any portions of these segments
	// that are marked in the program header as being mapped
	// but not actually present in the ELF file - i.e., the
	// program's bss section.

	/*
	// Load all the ELF sections as well
	sh = (struct Secthdr *) ((uint8_t *) elf + elf->e_shoff);
	esh = sh + elf->e_shnum;
	for (; sh < esh; sh++) {
		if (sh->sh_type != ELF_SHT_NULL) {
			assert(sh->sh_filesz <= sh->sh_memsz);
			segment_alloc(e, sh->sh_va, sh->sh_memsz);

			// Zero out the segment
			memset(ROUNDDOWN(sh->sh_va, PGSIZE), 0, ROUNDUP(sh->sh_memsz, PGSIZE));

			// Copy the data.
			memmove(ah->sh_va, binary + sh->sh_offset, sh->sh_filesz);
		}
	}
	*/

	e->env_tf.tf_eip = (elf->e_entry & 0xFFFFFF);
	assert(e->env_tf.tf_eip != 0);

	// LAB 3: Your code here.
	segment_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	DPRINTF("Before loading CR3 with old_cr3 %u\n", old_cr3);
	lcr3((uint32_t)old_cr3);
	DPRINTF("After loading CR3 with old_cr3 %u\n", old_cr3);
}

//
// Allocates a new env with env_alloc and loads the named elf
// binary into it with load_icode.
// This function is ONLY called during kernel initialization,
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, size_t size)
{
	// LAB 3: Your code here.
	struct Env *e;
	int ret = env_alloc(&e, 0);
	if (ret < 0) {
		panic("env_alloc failed with: %e\n", ret);
		return;
	}
	load_icode(e, binary, size);
}

//
// Frees env e and all memory it uses.
// 
void
env_free(struct Env *e)
{
	pte_t *pt;
	uint32_t pdeno, pteno;
	physaddr_t pa;
	
	// If freeing the current environment, switch to boot_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
		lcr3(boot_cr3);

	// Note the environment's demise.
	// cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = e->env_cr3;
	e->env_pgdir = 0;
	e->env_cr3 = 0;
	page_decref(pa2page(pa));

	// return the environment to the free list
	e->env_status = ENV_FREE;
	LIST_INSERT_HEAD(&env_free_list, e, env_link);
}

//
// Frees environment e.
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e) 
{
	env_free(e);

	if (curenv == e) {
		curenv = NULL;
		sched_yield();
	}
}


//
// Restores the register values in the Trapframe with the 'iret' instruction.
// This exits the kernel and starts executing some environment's code.
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
	__asm __volatile("movl %0,%%esp\n"
		"\tpopal\n"
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
}

//
// Context switch from curenv to env e.
// Note: if this is the first call to env_run, curenv is NULL.
//
// This function does not return.
//
void
env_run(struct Env *e)
{
	// Step 1: If this is a context switch (a new environment is running),
	//	   then set 'curenv' to the new environment,
	//	   update its 'env_runs' counter, and
	//	   and use lcr3() to switch to its address space.
	// Step 2: Use env_pop_tf() to restore the environment's
	//	   registers and drop into user mode in the
	//	   environment.

	// Hint: This function loads the new environment's state from
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	DPRINTF("About to run %x\n", e);

	if(curenv != e) {
		curenv = e;
		++(e->env_runs);
	}

	lcr3(e->env_cr3);

	DPRINTF("About to pop Trapframe (%x), EIP: %x\n", &(e->env_tf), e->env_tf.tf_eip);
	env_pop_tf(&(e->env_tf));
}

