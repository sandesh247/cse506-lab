/* -*- Mode: C; c-basic-offset: 8; indent-tabs-mode: t -*- */
// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>
#include <inc/types.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/pmap.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "backtrace", "Display backtrace information", mon_backtrace },
	{ "page_status", "Display the status of a physical page", mon_page_status },
	{ "showmappings", "Display mappings for a virtual address range", mon_showmappings },
	{ "chperm", "Change permissions of a virtual address range", mon_chperm },
	{ "dumpmem", "Dump virtual or physical address ranges", mon_dumpmem },
	{ "free_page", "Free the page at the physical address.", mon_free_page },
	{ "alloc_page", "Allocate the page at the physical address.", mon_alloc_page },
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-_start+1023)/1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
  // Your code here.
  int *ebp = (int*)read_ebp(); // This gets us the value of esp when THIS function was entered
  uintptr_t eip = read_eip();

  cprintf("Stack backtrace:\n");

  while (ebp) {
    cprintf("ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", 
	    ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
    struct Eipdebuginfo info;
    debuginfo_eip(eip, &info);

    int fn_namelen = info.eip_fn_namelen < 255 ? info.eip_fn_namelen : 255;
    char fn_name[256];
    int i = 0;

    memmove(fn_name, info.eip_fn_name, fn_namelen);
    fn_name[fn_namelen] = '\0';

    cprintf("\t%c[1;31m%s%c[0m:%d: %c[1;33m%s%c[0m+%d\n", 
	    0x1B, info.eip_file, 0x1B, info.eip_line, 0x1B, fn_name, 0x1B, eip-info.eip_fn_addr);

    eip = ebp[1];
    ebp = (int*)(*ebp);
  }

  return 0;
}

uint32_t parse_hex(char *str) {
	assert(str);

	uint32_t res = 0, pow16 = 1;

	char *loc = str;
	while(*loc) ++loc;

	while(loc != str) {
	  char c = *(--loc);

		uint32_t d;

		if(c >= '0' && c <= '9') {
			d = c - '0';
		} else if(c >= 'a' && c <= 'f') {
			d = 10 + c - 'a';
		} else if(c >= 'A' && c <= 'F') {
			d = 10 + c - 'A';
		} else {
			return res;
		}

		res += (d * pow16);
		pow16 = pow16 << 4;
	}

	return res;
}

int
mon_page_status(int argc, char **argv, struct Trapframe *tf)
{

	if(argc != 2) {
		cprintf("usage: page_status <physical addr>\n");
		return -1;
	}

	struct Page* ipp = pa2page(parse_hex(argv[1]));

	if(ipp) {
		cprintf("Index %d, Ref count: %d.\n", page2ppn(ipp), ipp->pp_ref);
	} else {
		cprintf("Page not found.\n");
	}

	return 0;
}

int
mon_free_page(int argc, char** argv, struct Trapframe *tf) {

	if(argc != 2) {
		cprintf("usage: free_page <physical addr>\n");
		return -1;
	}

	struct Page* ipp = pa2page(parse_hex(argv[1]));

	if(ipp) {
		cprintf("Index %d, Ref count: %d.\n", page2ppn(ipp), ipp->pp_ref);
		void *page_addr = page2kva(ipp);

		// break off mappings
		uintptr_t va;
		for(va = 0; va < 0xFFFFFFFF; va += PGSIZE) {
			pte_t *pte = pgdir_walk(boot_pgdir, (void *) va, 0);

			if(!pte || !PTE_ADDR(*pte)) continue;

			if(KADDR(PTE_ADDR(*pte)) == page_addr) {
				DPRINTF("Unmapping page from VA %x.\n", va);
				page_remove(boot_pgdir, (void *) va);	
			}
		}
	
		assert(ipp->pp_ref == 0);

		DPRINTF("Freeing page.");
		page_free(ipp);
	} else {
		cprintf("Page not found.\n");
	}
	
	return 0;
}

int
mon_alloc_page(int argc, char** argv, struct Trapframe *tf) {

	if(argc != 2) {
		cprintf("usage: alloc_page <physical addr>\n");
		return -1;
	}

	struct Page* ipp = pa2page(parse_hex(argv[1]));

	if(ipp) {
		DPRINTF("Allocating page.");
		LIST_REMOVE(ipp, pp_link);
	} else {
		cprintf("Page not found.\n");
	}
	
	return 0;
}

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf) {
	if(argc != 3) {
		cprintf("usage: showmappings <virtual address start> <virtual address end>\n");
		return -1;
	}

	uint32_t virt_start = ROUNDDOWN(parse_hex(argv[1]), PGSIZE);
	uint32_t virt_end   = ROUNDDOWN(parse_hex(argv[2]), PGSIZE);

	cprintf("VS, VE: %x, %x\n", virt_start, virt_end);


	cprintf("Virtual Address, Physical Address\n");
	cprintf("---------------------------------\n");
	for (; virt_start <= virt_end; virt_start += PGSIZE) {
	    uint32_t *pte = pgdir_walk(boot_pgdir, (const void*)virt_start, 0);
	    cprintf(    "0x%08x     , "  "0x%08x\n", virt_start, pte ? PTE_ADDR(*pte) : 0);
	}

	return 0;
}


int
mon_chperm(int argc, char **argv, struct Trapframe *tf) {
	if(argc != 4) {
		cprintf("usage: chperm <virtual address start> <virtual address end> <permission bits (hex)>\n");
		return -1;
	}

	uint32_t virt_start = ROUNDDOWN(parse_hex(argv[1]), PGSIZE);
	uint32_t virt_end   = ROUNDDOWN(parse_hex(argv[2]), PGSIZE);
	uint32_t perms      = parse_hex(argv[3]);

	uint32_t ctr = 0;
	for (; virt_start <= virt_end; virt_start += PGSIZE) {
	    uint32_t *pte = pgdir_walk(boot_pgdir, (const void*)virt_start, 0);
	    if (pte) {
		*pte |= perms;
		++ctr;
	    }
	}
	cprintf("Changed permissions for %d pages\n", ctr);

	return 0;
}

int
mon_dumpmem(int argc, char **argv, struct Trapframe *tf) {
	if(argc != 3) {
		cprintf("usage: showmappings <virtual address start> <virtual address end>\n");
		return -1;
	}

	uint32_t virt_start = parse_hex(argv[1]);
	uint32_t virt_end   = parse_hex(argv[2]);

	int bs = 6;
	for (; virt_start <= virt_end; virt_start += sizeof(uint32_t)*bs) {
	    uint32_t va = virt_start;
	    cprintf("0x%08x: ", va);
	    while (va <= virt_start + sizeof(uint32_t)*bs) {
		uint32_t pa = ROUNDDOWN(va, PGSIZE);
		uint32_t *pte = pgdir_walk(boot_pgdir, (const void*)pa, 0);
		uint32_t data = -1;
		if (pte && PTE_ADDR(*pte)) {
		    data = ((uint32_t*)KADDR(PTE_ADDR(*pte)))[(va - pa) / sizeof(uint32_t)];
		}
		cprintf("0x%08x  ", data);
		va += sizeof(uint32_t);
	    }
	    cprintf("\n");
	}

	return 0;
}



/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}

// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
	return callerpc;
}
