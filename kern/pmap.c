/* -*- tab-width: 8 -*- 
 * See COPYRIGHT for copyright information.
 */

#include <inc/x86.h>
#include <inc/mmu.h>
#include <inc/error.h>
#include <inc/string.h>
#include <inc/assert.h>

#include <kern/pmap.h>
#include <kern/kclock.h>

// These variables are set by i386_detect_memory()
static physaddr_t maxpa;	// Maximum physical address
size_t npage;			// Amount of physical memory (in pages)
static size_t basemem;		// Amount of base memory (in bytes)
static size_t extmem;		// Amount of extended memory (in bytes)

// These variables are set in i386_vm_init()
pde_t* boot_pgdir;		// Virtual address of boot time page directory
physaddr_t boot_cr3;		// Physical address of boot time page directory
static char* boot_freemem;	// Pointer to next byte of free mem

struct Page* pages;		// Virtual address of physical page array
static struct Page_list page_free_list;	// Free list of physical pages

int no_boot_alloc = 0; // non-zero if boot_alloc() should not be called now


// Global descriptor table.
//
// The kernel and user segments are identical (except for the DPL).
// To load the SS register, the CPL must equal the DPL.  Thus,
// we must duplicate the segments for the user and the kernel.
//
struct Segdesc gdt[] =
{
	// 0x0 - unused (always faults -- for trapping NULL far pointers)
	SEG_NULL,

	// 0x8 - kernel code segment
	[GD_KT >> 3] = SEG(STA_X | STA_R, 0x0, 0xffffffff, 0),

	// 0x10 - kernel data segment
	[GD_KD >> 3] = SEG(STA_W, 0x0, 0xffffffff, 0),

	// 0x18 - user code segment
	[GD_UT >> 3] = SEG(STA_X | STA_R, 0x0, 0xffffffff, 3),

	// 0x20 - user data segment
	[GD_UD >> 3] = SEG(STA_W, 0x0, 0xffffffff, 3),

	// 0x28 - tss, initialized in idt_init()
	[GD_TSS >> 3] = SEG_NULL
};

struct Pseudodesc gdt_pd = {
	sizeof(gdt) - 1, (unsigned long) gdt
};

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
}

void
i386_detect_memory(void)
{
	// CMOS tells us how many kilobytes there are
	basemem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PGSIZE);
	extmem = ROUNDDOWN(nvram_read(NVRAM_EXTLO)*1024, PGSIZE);

	// Calculate the maximum physical address based on whether
	// or not there is any extended memory.  See comment in <inc/mmu.h>.
	if (extmem)
		maxpa = EXTPHYSMEM + extmem;
	else
		maxpa = basemem;

	npage = maxpa / PGSIZE;

	cprintf("Physical memory: %dK available, ", (int)(maxpa/1024));
	cprintf("base = %dK, extended = %dK\n", (int)(basemem/1024), (int)(extmem/1024));
}

// --------------------------------------------------------------
// Set up initial memory mappings and turn on MMU.
// --------------------------------------------------------------

static void check_boot_pgdir(void);
static void check_page_alloc();
static void page_check(void);
static void boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, physaddr_t pa, int perm);

//
// A simple physical memory allocator, used only a few times
// in the process of setting up the virtual memory system.
// page_alloc() is the real allocator.
//
// Allocate n bytes of physical memory aligned on an 
// align-byte boundary.  Align must be a power of two.
// Return kernel virtual address.  Returned memory is uninitialized.
//
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list has been set up.
// 
static void*
boot_alloc(uint32_t n, uint32_t align)
{
	extern char end[];
	void *v;

	if (no_boot_alloc) {
	  panic("boot_alloc: Pages already initialized!!\n");
	  return NULL;
	}

	// Initialize boot_freemem if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment -
	// i.e., the first virtual address that the linker
	// did _not_ assign to any kernel code or global variables.
	if (boot_freemem == 0)
		boot_freemem = end;

	// LAB 2: Your code here:
	//	Step 1: round boot_freemem up to be aligned properly
	//		(hint: look in types.h for some handy macros)
	//	Step 2: save current value of boot_freemem as allocated chunk
	//	Step 3: increase boot_freemem to record allocation
	//	Step 4: return allocated chunk
	boot_freemem = ROUNDUP(boot_freemem,  align);
	void *alloc_chunk = boot_freemem;
	boot_freemem += n;
	cprintf("boot_alloc() returning: %x, boot_freemem is: %x\n", alloc_chunk, boot_freemem);
	return alloc_chunk;

	// return NULL;
}

// Set up a two-level page table:
//    boot_pgdir is its linear (virtual) address of the root
//    boot_cr3 is the physical adresss of the root
// Then turn on paging.  Then effectively turn off segmentation.
// (i.e., the segment base addrs are set to zero).
// 
// This function only sets up the kernel part of the address space
// (ie. addresses >= UTOP).  The user part of the address space
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
{
	pde_t* pgdir;
	uint32_t cr0;
	size_t n;

	// Delete this line:
	// panic("i386_vm_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	pgdir = boot_alloc(PGSIZE, PGSIZE);
	memset(pgdir, 0, PGSIZE);
	boot_pgdir = pgdir;
	boot_cr3 = PADDR(pgdir);

	//////////////////////////////////////////////////////////////////////
	// Recursively insert PD in itself as a page table, to form
	// a virtual page table at virtual address VPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel RW, user NONE
	pgdir[PDX(VPT)] = PADDR(pgdir)|PTE_W|PTE_P;

	// same for UVPT
	// Permissions: kernel R, user R 
	pgdir[PDX(UVPT)] = PADDR(pgdir)|PTE_U|PTE_P;

	//////////////////////////////////////////////////////////////////////
	// Allocate an array of npage 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npage' is the number of physical pages in memory.
	// User-level programs will get read-only access to the array as well.
	// Your code goes here:
	pages = boot_alloc(sizeof(struct Page) * npage, PGSIZE);


	//////////////////////////////////////////////////////////////////////
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_segment or page_insert
	page_init();

	cprintf("Calling check_page_alloc()\n");

	check_page_alloc();

	page_check();

	//////////////////////////////////////////////////////////////////////
	// Now we set up virtual memory 
	
	//////////////////////////////////////////////////////////////////////
	// Map 'pages' read-only by the user at linear address UPAGES
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

	//////////////////////////////////////////////////////////////////////
	// Use the physical memory that 'bootstack' refers to as the kernel
	// stack.  The kernel stack grows down from virtual address KSTACKTOP.
	// We consider the entire range from [KSTACKTOP-PTSIZE, KSTACKTOP) 
	// to be the kernel stack, but break this into two pieces:
	//     * [KSTACKTOP-KSTKSIZE, KSTACKTOP) -- backed by physical memory
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	//////////////////////////////////////////////////////////////////////
	// Map all of physical memory at KERNBASE. 
	// Ie.  the VA range [KERNBASE, 2^32) should map to
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	// Check that the initial page directory has been set up correctly.
	check_boot_pgdir();

	//////////////////////////////////////////////////////////////////////
	// On x86, segmentation maps a VA to a LA (linear addr) and
	// paging maps the LA to a PA.  I.e. VA => LA => PA.  If paging is
	// turned off the LA is used as the PA.  Note: there is no way to
	// turn off segmentation.  The closest thing is to set the base
	// address to 0, so the VA => LA mapping is the identity.

	// Current mapping: VA KERNBASE+x => PA x.
	//     (segmentation base=-KERNBASE and paging is off)

	// From here on down we must maintain this VA KERNBASE + x => PA x
	// mapping, even though we are turning on paging and reconfiguring
	// segmentation.

	// Map VA 0:4MB same as VA KERNBASE, i.e. to PA 0:4MB.
	// (Limits our kernel to <4MB)
	pgdir[0] = pgdir[PDX(KERNBASE)];

	// Install page table.
	lcr3(boot_cr3);

	// Turn on paging.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_EM|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Current mapping: KERNBASE+x => x => x.
	// (x < 4MB so uses paging pgdir[0])

	// Reload all segment registers.
	asm volatile("lgdt gdt_pd");
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));  // reload cs
	asm volatile("lldt %%ax" :: "a" (0));

	// Final mapping: KERNBASE+x => KERNBASE+x => x.

	// This mapping was only used after paging was turned on but
	// before the segment registers were reloaded.
	pgdir[0] = 0;

	// Flush the TLB for good measure, to kill the pgdir[0] mapping.
	lcr3(boot_cr3);
}

//
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc()
{
	struct Page *pp, *pp0, *pp1, *pp2;
	struct Page_list fl;

	// if there's a page that shouldn't be on
	// the free list, try to make sure it
	// eventually causes trouble.
	LIST_FOREACH(pp0, &page_free_list, pp_link)
		memset(page2kva(pp0), 0x97, 128);

	// cprintf("After zeroing out all free pages in check_page_alloc()\n");

	LIST_FOREACH(pp0, &page_free_list, pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp0 >= pages);
		assert(pp0 < pages + npage);

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp0) != 0);
		assert(page2pa(pp0) != IOPHYSMEM);
		assert(page2pa(pp0) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp0) != EXTPHYSMEM);
		assert(page2kva(pp0) != ROUNDDOWN(boot_freemem - 1, PGSIZE));
	}

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert(page_alloc(&pp0) == 0);
	assert(page_alloc(&pp1) == 0);
	assert(page_alloc(&pp2) == 0);

	assert(pp0);
	assert(pp1 && pp1 != pp0);
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
	assert(page2pa(pp0) < npage*PGSIZE);
	assert(page2pa(pp1) < npage*PGSIZE);
	assert(page2pa(pp2) < npage*PGSIZE);

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	LIST_INIT(&page_free_list);

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);

	// free and re-allocate?
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);
	pp0 = pp1 = pp2 = 0;
	assert(page_alloc(&pp0) == 0);
	assert(page_alloc(&pp1) == 0);
	assert(page_alloc(&pp2) == 0);
	assert(pp0);
	assert(pp1 && pp1 != pp0);
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
	assert(page_alloc(&pp) == -E_NO_MEM);

	// give free list back
	page_free_list = fl;

	// free the pages we took
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	cprintf("check_page_alloc() succeeded!\n");
}

//
// Checks that the kernel part of virtual address space
// has been setup roughly correctly(by i386_vm_init()).
//
// This function doesn't test every corner case,
// in fact it doesn't test the permission bits at all,
// but it is a pretty good sanity check. 
//
static physaddr_t check_va2pa(pde_t *pgdir, uintptr_t va);

static void
check_boot_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	

	// check phys mem
	for (i = 0; i < npage * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
		case PDX(VPT):
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i]);
			break;
		default:
			if (i >= PDX(KERNBASE))
				assert(pgdir[i]);
			else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_boot_pgdir() succeeded!\n");
}

// This function returns the physical address of the page containing 'va',
// defined by the page directory 'pgdir'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the check_boot_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
		
// --------------------------------------------------------------
// Tracking of physical pages.
// The 'pages' array has one 'struct Page' entry per physical page.
// Pages are reference counted, and free pages are kept on a linked list.
// --------------------------------------------------------------

//
// Initialize page structure and memory free list.
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
	// The example code here marks all physical pages as free.
	// However this is not truly the case.  What memory is free?
	//  1) Mark physical page 0 as in use.
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	//  2) The rest of base memory, [PGSIZE, basemem) is free.
	//  3) Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM).
	//     Mark it as in use so that it can never be allocated.
	//  4) Then extended memory [EXTPHYSMEM, ...).
	//     Some of it is in use, some is free. Where is the kernel
	//     in physical memory?  Which pages are already in use for
	//     page tables and other data structures?
	//
	// Change the code to reflect this.
	int i, ctr = 0;
	
	LIST_INIT(&page_free_list);
	for (i = 0; i < npage; i++) {
	  if ((i == 0) || 
	      ((i > basemem/PGSIZE || i*PGSIZE >= IOPHYSMEM) && i*PGSIZE <= EXTPHYSMEM) || 
	      (i*PGSIZE > EXTPHYSMEM && (char*)(i*PGSIZE + KERNBASE) < boot_freemem)) {
	    pages[i].pp_ref = 1;
	  }
	  else {
	    ++ctr;
	    pages[i].pp_ref = 0;
	    LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
	  }
	}

	no_boot_alloc = 1;
	cprintf("Done with page_init(). Initialized %d/%d pages\n", ctr, i);

}

//
// Initialize a Page structure.
// The result has null links and 0 refcount.
// Note that the corresponding physical page is NOT initialized!
//
static void
page_initpp(struct Page *pp)
{
	memset(pp, 0, sizeof(*pp));
}

//
// Allocates a physical page.
// Does NOT set the contents of the physical page to zero, NOR does it
// increment the reference count of the page - the caller must do
// these if necessary. 
//
// *pp_store -- is set to point to the Page struct of the newly allocated
// page
//
// RETURNS 
//   0 -- on success
//   -E_NO_MEM -- otherwise 
//
// Hint: use LIST_FIRST, LIST_REMOVE, and page_initpp
int
page_alloc(struct Page **pp_store)
{
	*pp_store = LIST_FIRST(&page_free_list);

	if(!(*pp_store)) return -E_NO_MEM;	

	LIST_REMOVE(*pp_store, pp_link);
	page_initpp(*pp_store);

	// Fill this function in
	return 0;
}

//
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
  // Fill this function in
  assert(pp->pp_ref == 0);
  LIST_INSERT_HEAD(&page_free_list, pp, pp_link);
}

//
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
	if (--pp->pp_ref == 0)
		page_free(pp);
}

// Given 'pgdir', a pointer to a page directory, pgdir_walk returns
// a pointer to the page table entry (PTE) for linear address 'va'.
// This requires walking the two-level page table structure.
//
// If the relevant page table doesn't exist in the page directory, then:
//    - If create == 0, pgdir_walk returns NULL.
//    - Otherwise, pgdir_walk tries to allocate a new page table
//	with page_alloc.  If this fails, pgdir_walk returns NULL.
//    - pgdir_walk sets pp_ref to 1 for the new page table.
//    - pgdir_walk clears the new page table.
//    - Finally, pgdir_walk returns a pointer into the new page table.
//
// Hint: you can turn a Page * into the physical address of the
// page it refers to with page2pa() from kern/pmap.h.
//
// Hint 2: the x86 MMU checks permission bits in both the page directory
// and the page table, so it's safe to leave permissions in the page
// more permissive than strictly necessary.
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
  // Fill this function in
  pte_t *pte;

  if (create) {
    pte = pgdir_walk(pgdir, va, 0);
    if (pte) {
      return pte;
    }
    struct Page *ppage;
    int ret = page_alloc(&ppage);
    if (ret) {
      return NULL;
    }
    physaddr_t paddr = page2pa(ppage);

    pgdir[PDX(va)] = paddr | PTE_U |PTE_W | PTE_P;
    // Set reference counter to 1.
    ppage->pp_ref = 1;
    return pgdir_walk(pgdir, va, 0);
  }
  else {
    pgdir = &pgdir[PDX(va)];
    if (!(*pgdir & PTE_P)) {
      return NULL;
    }
    pte = (pte_t*) KADDR(PTE_ADDR(*pgdir));
    return &pte[PTX(va)];
  }
  return NULL;
}


void
page_incref(struct Page *pp) {
  ++(pp->pp_ref);
}

//
// Map the physical page 'pp' at virtual address 'va'.
// The permissions (the low 12 bits) of the page table
//  entry should be set to 'perm|PTE_P'.
//
// Requirements
//   - If there is already a page mapped at 'va', it should be page_remove()d.
//   - If necessary, on demand, a page table should be allocated and inserted
//     into 'pgdir'.
//   - pp->pp_ref should be incremented if the insertion succeeds.
//   - The TLB must be invalidated if a page was formerly present at 'va'.
//
// Corner-case hint: Make sure to consider what happens when the same 
// pp is re-inserted at the same virtual address in the same pgdir.
//
// RETURNS: 
//   0 on success
//   -E_NO_MEM, if page table couldn't be allocated
//
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm) 
{
	struct Page *pprev;
	pte_t *pte; 

	physaddr_t page_addr;
	int tlb_invalid = 0;

	page_addr = page2pa(pp);
  pte = pgdir_walk(pgdir, va, 0);

	if(!pte) {
		pte = pgdir_walk(pgdir, va, 1);
		if(!pte) return -E_NO_MEM;

		pte[PTX(va)] = page_addr;
		page_incref(pp);
	} else {
		pprev = pa2page(pte[PTX(va)]);
		
		if(pp == pprev) {
			// this va was mapped to this page wonly ...
		} else {
			page_remove(pgdir, va);
			pte[PTX(va)] = page_addr;
			page_incref(pp);
		}
	}
	
	return 0;
}

//
// Map [la, la+size) of linear address space to physical [pa, pa+size)
// in the page table rooted at pgdir.  Size is a multiple of PGSIZE.
// Use permission bits perm|PTE_P for the entries.
//
// This function is only intended to set up the ``static'' mappings
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
}

//
// Return the page mapped at virtual address 'va'.
// If pte_store is not zero, then we store in it the address
// of the pte for this page.  This is used by page_remove and
// can be used to verify page permissions for syscall arguments,
// but should not be used by most callers.
//
// Return NULL if there is no page mapped at va.
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
  // Fill this function in
  pte_t *pte = pgdir_walk(pgdir, va, 0);
  return NULL;
}

//
// Unmaps the physical page at virtual address 'va'.
// If there is no physical page at that address, silently does nothing.
//
// Details:
//   - The ref count on the physical page should decrement.
//   - The physical page should be freed if the refcount reaches 0.
//   - The pg table entry corresponding to 'va' should be set to 0.
//     (if such a PTE exists)
//   - The TLB must be invalidated if you remove an entry from
//     the pg dir/pg table.
//
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
	// Fill this function in
}

//
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}

// check page_insert, page_remove, &c
static void
page_check(void)
{
	struct Page *pp, *pp0, *pp1, *pp2;
	struct Page_list fl;
	pte_t *ptep, *ptep1;
	void *va;
	int i;

	cprintf("Starting page_check()\n");

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert(page_alloc(&pp0) == 0);
	assert(page_alloc(&pp1) == 0);
	assert(page_alloc(&pp2) == 0);

	assert(pp0);
	assert(pp1 && pp1 != pp0);
	assert(pp2 && pp2 != pp1 && pp2 != pp0);

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	LIST_INIT(&page_free_list);

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);

	// there is no page allocated at address 0
	assert(page_lookup(boot_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table 
	assert(page_insert(boot_pgdir, pp1, 0x0, 0) < 0);

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
	assert(page_insert(boot_pgdir, pp1, 0x0, 0) == 0);
	assert(PTE_ADDR(boot_pgdir[0]) == page2pa(pp0));
	assert(check_va2pa(boot_pgdir, 0x0) == page2pa(pp1));
	assert(pp1->pp_ref == 1);
	assert(pp0->pp_ref == 1);

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, 0) == 0);
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
	assert(pp2->pp_ref == 1);

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, 0) == 0);
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
	assert(pp2->pp_ref == 1);

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(page_alloc(&pp) == -E_NO_MEM);

	// check that pgdir_walk returns a pointer to the pte
	ptep = KADDR(PTE_ADDR(boot_pgdir[PDX(PGSIZE)]));
	assert(pgdir_walk(boot_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));

	// should be able to change permissions too.
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, PTE_U) == 0);
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
	assert(pp2->pp_ref == 1);
	assert(*pgdir_walk(boot_pgdir, (void*) PGSIZE, 0) & PTE_U);
	assert(boot_pgdir[0] & PTE_U);
	
	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(boot_pgdir, pp0, (void*) PTSIZE, 0) < 0);

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(boot_pgdir, pp1, (void*) PGSIZE, 0) == 0);
	assert(!(*pgdir_walk(boot_pgdir, (void*) PGSIZE, 0) & PTE_U));

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(boot_pgdir, 0) == page2pa(pp1));
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp1));
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
	assert(pp2->pp_ref == 0);

	// pp2 should be returned by page_alloc
	assert(page_alloc(&pp) == 0 && pp == pp2);

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(boot_pgdir, 0x0);
	assert(check_va2pa(boot_pgdir, 0x0) == ~0);
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp1));
	assert(pp1->pp_ref == 1);
	assert(pp2->pp_ref == 0);

	// unmapping pp1 at PGSIZE should free it
	page_remove(boot_pgdir, (void*) PGSIZE);
	assert(check_va2pa(boot_pgdir, 0x0) == ~0);
	assert(check_va2pa(boot_pgdir, PGSIZE) == ~0);
	assert(pp1->pp_ref == 0);
	assert(pp2->pp_ref == 0);

	// so it should be returned by page_alloc
	assert(page_alloc(&pp) == 0 && pp == pp1);

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
	
#if 0
	// should be able to page_insert to change a page
	// and see the new data immediately.
	memset(page2kva(pp1), 1, PGSIZE);
	memset(page2kva(pp2), 2, PGSIZE);
	page_insert(boot_pgdir, pp1, 0x0, 0);
	assert(pp1->pp_ref == 1);
	assert(*(int*)0 == 0x01010101);
	page_insert(boot_pgdir, pp2, 0x0, 0);
	assert(*(int*)0 == 0x02020202);
	assert(pp2->pp_ref == 1);
	assert(pp1->pp_ref == 0);
	page_remove(boot_pgdir, 0x0);
	assert(pp2->pp_ref == 0);
#endif

	// forcibly take pp0 back
	assert(PTE_ADDR(boot_pgdir[0]) == page2pa(pp0));
	boot_pgdir[0] = 0;
	assert(pp0->pp_ref == 1);
	pp0->pp_ref = 0;
	
	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(boot_pgdir, va, 1);
	ptep1 = KADDR(PTE_ADDR(boot_pgdir[PDX(va)]));
	assert(ptep == ptep1 + PTX(va));
	boot_pgdir[PDX(va)] = 0;
	pp0->pp_ref = 0;
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(boot_pgdir, 0x0, 1);
	ptep = page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
	boot_pgdir[0] = 0;
	pp0->pp_ref = 0;

	// give free list back
	page_free_list = fl;

	// free the pages we took
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);
	
	cprintf("page_check() succeeded!\n");
}

