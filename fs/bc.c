// -*- c-basic-offset: 8; indent-tabs-mode: t -*-
#include "fs.h"

// Return the virtual address of this disk block.
void*
diskaddr(uint32_t blockno)
{
	if (blockno == 0 || (super && blockno >= super->s_nblocks))
		panic("bad block number %08x in diskaddr", blockno);
	return (char*) (DISKMAP + blockno * BLKSIZE);
}

// Is this virtual address mapped?
bool
va_is_mapped(void *va)
{
	return (vpd[PDX(va)] & PTE_P) && (vpt[VPN(va)] & PTE_P);
}

// Is this virtual address dirty?
bool
va_is_dirty(void *va)
{
	return (vpt[VPN(va)] & PTE_D) != 0;
}

// Fault any disk block that is read or written in to memory by
// loading it from disk.
// Hint: Use ide_read and BLKSECTS.
static void
bc_pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	DPRINTF5("Faulted at va %x.\n", addr);
	uint32_t blockno = ((uint32_t)addr - DISKMAP) / BLKSIZE;
	int r;

	// Check that the fault was within the block cache region
	if (addr < (void*)DISKMAP || addr >= (void*)(DISKMAP + DISKSIZE))
		panic("page fault in FS: eip %08x, va %08x, err %04x\n",
		      utf->utf_eip, addr, utf->utf_err);

	// Allocate a page in the disk map region and read the
	// contents of the block from the disk into that page.
	//
	// LAB 5: Your code here
	if ((r = sys_page_alloc(0, ROUNDDOWN(addr, PGSIZE), PTE_USER)) != 0) {
		panic("bc_pgfault::Error allocating page: %e\n", r);
	}

	uint32_t secno = (uint32_t)ROUNDDOWN(addr - DISKMAP, PGSIZE) / SECTSIZE;
	char *dst = (char*)ROUNDDOWN(addr, PGSIZE);

	ide_read(secno, dst, BLKSECTS);

	// Sanity check the block number. (exercise for the reader:
	// why do we do this *after* reading the block in?)
	if (super && blockno >= super->s_nblocks)
		panic("reading non-existent block %08x\n", blockno);

	// Check that the block we read was allocated.
	if (bitmap && block_is_free(blockno))
		panic("reading free block %08x\n", blockno);
		
	DPRINTF5("Done reading va %x.\n", addr);
}

// Flush the contents of the block containing VA out to disk if
// necessary, then clear the PTE_D bit using sys_page_map.
// If the block is not in the block cache or is not dirty, does
// nothing.
// Hint: Use va_is_mapped, va_is_dirty, and ide_write.
// Hint: Use the PTE_USER constant when calling sys_page_map.
// Hint: Don't forget to round addr down.
void
flush_block(void *addr)
{
	uint32_t blockno = ((uint32_t)addr - DISKMAP) / BLKSIZE;

	if (addr < (void*)DISKMAP || addr >= (void*)(DISKMAP + DISKSIZE))
		panic("flush_block of bad va %08x", addr);

	if(!va_is_mapped(addr) || !va_is_dirty(addr)) {
		return;
	}

	uint32_t secno = (uint32_t)ROUNDDOWN(addr - DISKMAP, PGSIZE) / SECTSIZE;
	char *dst = (char*)ROUNDDOWN(addr, PGSIZE);
	int r;

	// Read in the page
	if ((r = ide_write(secno, dst, BLKSECTS)) != 0) {
		panic("bc_pgfault::Error write sector from disk: %e\n", r);
	}

	if((r = sys_page_map(0, ROUNDDOWN(addr, PGSIZE), 0, ROUNDDOWN(addr, PGSIZE), PTE_USER)) != 0) {
		panic("Could not update status of page in va: %e.", r);
	}

	// panic("flush_block not implemented");
}

// Test that the block cache works, by smashing the superblock and
// reading it back.
static void
check_bc(void)
{
	struct Super backup;

	// back up super block
	memmove(&backup, diskaddr(1), sizeof backup);

	// smash it 
	strcpy(diskaddr(1), "OOPS!\n");
	flush_block(diskaddr(1));
	assert(va_is_mapped(diskaddr(1)));
	assert(!va_is_dirty(diskaddr(1)));

	// clear it out
	sys_page_unmap(0, diskaddr(1));
	assert(!va_is_mapped(diskaddr(1)));

	// read it back in
	assert(strcmp(diskaddr(1), "OOPS!\n") == 0);

	// fix it
	memmove(diskaddr(1), &backup, sizeof backup);
	flush_block(diskaddr(1));

	cprintf("block cache is good\n");
}

void
bc_init(void)
{
	set_pgfault_handler(bc_pgfault);
	check_bc();
}

