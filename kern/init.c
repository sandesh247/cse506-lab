// -*- c-basic-offset:8; indent-tabs-mode:t -*-
/* See COPYRIGHT for copyright information. */

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/assert.h>

#include <kern/monitor.h>
#include <kern/console.h>
#include <kern/pmap.h>
#include <kern/kclock.h>
#include <kern/env.h>
#include <kern/trap.h>
#include <kern/sched.h>
#include <kern/picirq.h>
#include <kern/time.h>
#include <kern/pci.h>

void
i386_init(void)
{
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();

	cprintf("6828 decimal is %o octal!\n", 6828);

	// Lab 2 memory management initialization functions
	i386_detect_memory();
	i386_vm_init();

	// Lab 3 user environment initialization functions
        cprintf("Before env_init()\n");
	env_init();
        cprintf("After env_init()\n");

	idt_init();

	// Lab 4 multitasking initialization functions
	DPRINTF7("Initializing PIC\n");
	pic_init();
	DPRINTF7("Initializing KCLOCK\n");
	kclock_init();

	DPRINTF7("Initializing TIME\n");
	time_init();
	DPRINTF7("Initializing PCI\n");
	pci_init();

	// Should always have an idle process as first one.
	DPRINTF7("Creating idle environment\n");
	ENV_CREATE(user_idle);

	// Start fs.
	DPRINTF7("Creating FS environment\n");
	ENV_CREATE(fs_fs);

#if !defined(TEST_NO_NS)
	// Start ns.
	// TODO: Uncomment: 
	DPRINTF7("Creating NET environment\n");
	ENV_CREATE(net_ns);
#endif

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE2(TEST, TESTSIZE);
#else
	// Touch all you want.
	ENV_CREATE(user_testpteshare);

	// ENV_CREATE(user_hello);
	// ENV_CREATE(net_testinput);

	// ENV_CREATE(user_testtime);
	// ENV_CREATE(net_testoutput);
	// ENV_CREATE(user_echosrv);
	// ENV_CREATE(user_httpd);

	// ENV_CREATE(user_writemotd);
	// ENV_CREATE(user_testfile);
	// ENV_CREATE(user_icode);
        // ENV_CREATE(user_yield);
	// ENV_CREATE(user_yield);
	// ENV_CREATE(user_yield);
	// ENV_CREATE(user_yield);
        // ENV_CREATE(user_dumbfork);
        // ENV_CREATE(user_faultdie);
        // ENV_CREATE(user_faultalloc);
        // ENV_CREATE(user_faultallocbad);
        // ENV_CREATE(user_faultregs);
        // ENV_CREATE(user_faultnostack);
	// ENV_CREATE(user_forktree);
        // ENV_CREATE(user_spin);
	// ENV_CREATE(user_pingpong);
	// ENV_CREATE(user_primes);
	// ENV_CREATE(user_testfile);
	// ENV_CREATE(user_icode);
#endif // TEST*

	// Should not be necessary - drains keyboard because interrupt has given up.
	kbd_intr();

	// Schedule and run the first user environment!
	sched_yield();
}


/*
 * Variable panicstr contains argument to first call to panic; used as flag
 * to indicate that the kernel has already called panic.
 */
static const char *panicstr;

/*
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
	va_list ap;

	if (panicstr)
		goto dead;
	panicstr = fmt;

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
	vcprintf(fmt, ap);
	cprintf("\n");
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
	vcprintf(fmt, ap);
	cprintf("\n");
	va_end(ap);
}
