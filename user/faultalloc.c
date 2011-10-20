// test user-level fault handler -- alloc pages to fix faults

#include <inc/lib.h>

void
handler(struct UTrapframe *utf)
{
	int r;
	void *addr = (void*)utf->utf_fault_va;

	cprintf("fault %x\n", addr);
	if ((r = sys_page_alloc(0, ROUNDDOWN(addr, PGSIZE),
				PTE_P|PTE_U|PTE_W)) < 0)
		panic("allocating at %x in page fault handler: %e", addr, r);
        cprintf("faultalloc::after allocating page at address: %x (r = %d)\n", addr, r);
	snprintf((char*) addr, 100, "this string was faulted in at %x", addr);
}

char str1[] = "sandy, boo\n";
char str2[] = "ESP: %x\n";

unsigned int getESP(void)
{
   unsigned int _esp;

   asm ("mov %%esp, %0":"=r" (_esp));
   return _esp;
}

void
umain(void)
{
	set_pgfault_handler(handler);
        cprintf("%s\n", (char*)0xDeadBeef);
        cprintf("getESP() = %x\n", getESP());

        /*
        *(char*)0xDeadBeef = 'c';
        str1[0] = 'd';
        cprintf(str1);
        str1[0] = 'x';
        cprintf(str2, 33);
        */

	cprintf("%s\n", (char*)0xCafeBffe);
}
