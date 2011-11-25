/* -*- c-basic-offset: 8; indent-tabs-mode: t -*- */
#include <inc/mmu.h>
#include <inc/x86.h>
#include <inc/assert.h>
#include <inc/string.h>

#include <kern/pmap.h>
#include <kern/trap.h>
#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/env.h>
#include <kern/syscall.h>
#include <kern/sched.h>
#include <kern/kclock.h>
#include <kern/picirq.h>
#include <kern/time.h>
#include <kern/e100.h>

static struct Taskstate ts;

/* Interrupt descriptor table.  (Must be built at run time because
 * shifted function addresses can't be represented in relocation records.)
 */
struct Gatedesc idt[256] = { { 0 } };
struct Pseudodesc idt_pd = {
	sizeof(idt) - 1, (uint32_t) idt
};

extern void h_divide();
extern void h_debug();
extern void h_nmig();
extern void h_brkptg();
extern void h_oflowg();
extern void h_boundg();
extern void h_illopg();
extern void h_deviceg();
extern void h_dblflt();
extern void h_tss();
extern void h_segnp();
extern void h_stack();
extern void h_gpflt();
extern void h_pgflt();
extern void t_fperr();
extern void t_align();
extern void t_mchk();
extern void t_simderr();
extern void t_syscall();
extern void t_default();

extern void irq_timer();
extern void irq_kbd();
extern void irq_serial();
extern void irq_spurious();
extern void irq_ide();
extern void irq_e100();


static const char *trapname(int trapno)
{
	static const char * const excnames[] = {
		"Divide error",
		"Debug",
		"Non-Maskable Interrupt",
		"Breakpoint",
		"Overflow",
		"BOUND Range Exceeded",
		"Invalid Opcode",
		"Device Not Available",
		"Double Fault",
		"Coprocessor Segment Overrun",
		"Invalid TSS",
		"Segment Not Present",
		"Stack Fault",
		"General Protection",
		"Page Fault",
		"(unknown trap)",
		"x87 FPU Floating-Point Error",
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
		return "Hardware Interrupt";
	return "(unknown trap)";
}


void
random_function() {
    cprintf("random_function()\n");
}

void
idt_init(void)
{
	extern struct Segdesc gdt[];
	
        DPRINTF("idt_init()\n");

        // DPRINTF("addressof(h_divide) = %x\n", h_divide);
        // DPRINTF("addressof(h_debug) = %x\n", h_debug);

	// LAB 3: Your code here.
        SETGATE(idt[T_DIVIDE], 0, GD_KT, h_divide, 0);
        SETGATE(idt[T_DEBUG], 0, GD_KT, h_debug, 3);
        SETGATE(idt[T_NMI], 0, GD_KT, h_nmig, 0);
        SETGATE(idt[T_BRKPT], 0, GD_KT, h_brkptg, 3);
        SETGATE(idt[T_OFLOW], 0, GD_KT, h_oflowg, 0);
        SETGATE(idt[T_BOUND], 0, GD_KT, h_boundg, 0);
        SETGATE(idt[T_ILLOP], 0, GD_KT, h_illopg, 0);
        SETGATE(idt[T_DEVICE], 0, GD_KT, h_deviceg, 0);

        SETGATE(idt[T_DBLFLT], 0, GD_KT, h_dblflt, 0);
        SETGATE(idt[T_TSS], 0, GD_KT, h_tss, 0);
        SETGATE(idt[T_SEGNP], 0, GD_KT, h_segnp, 0);
        SETGATE(idt[T_STACK], 0, GD_KT, h_stack, 0);
        SETGATE(idt[T_GPFLT], 0, GD_KT, h_gpflt, 0);
        SETGATE(idt[T_PGFLT], 0, GD_KT, h_pgflt, 0);

        SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
        SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
        SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
        SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
        SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
        SETGATE(idt[T_DEFAULT], 0, GD_KT, t_default, 0);


        SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 0, GD_KT, irq_timer, 0);
        SETGATE(idt[IRQ_OFFSET + IRQ_KBD], 0, GD_KT, irq_kbd, 0);
        SETGATE(idt[IRQ_OFFSET + IRQ_SERIAL], 0, GD_KT, irq_serial, 0);
        SETGATE(idt[IRQ_OFFSET + IRQ_SPURIOUS], 0, GD_KT, irq_spurious, 0);
        SETGATE(idt[IRQ_OFFSET + IRQ_IDE], 0, GD_KT, irq_ide, 0);
        SETGATE(idt[IRQ_OFFSET + IRQ_E100], 0, GD_KT, irq_ide, 3);

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
	ts.ts_ss0 = GD_KD;

	// Initialize the TSS field of the gdt.
	gdt[GD_TSS >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS >> 3].sd_s = 0;

	// Load the TSS
	ltr(GD_TSS);

	// Load the IDT
	asm volatile("lidt idt_pd");
}

void
print_trapframe(struct Trapframe *tf)
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
	cprintf("  err  0x%08x\n", tf->tf_err);
	cprintf("  eip  0x%08x\n", tf->tf_eip);
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
	cprintf("  esp  0x%08x\n", tf->tf_esp);
	cprintf("  ss   0x----%04x\n", tf->tf_ss);
}

void
print_regs(struct PushRegs *regs)
{
	cprintf("  edi  0x%08x\n", regs->reg_edi);
	cprintf("  esi  0x%08x\n", regs->reg_esi);
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
	cprintf("  edx  0x%08x\n", regs->reg_edx);
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}

static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	
	// Handle clock interrupts.
	// LAB 4: Your code here.
	if(tf->tf_trapno == IRQ_OFFSET + IRQ_TIMER) {
		// TODO: Uncomment: cprintf("Handling timer interrrupt\n");
		time_tick();
		sched_yield();
	}

	// Add time tick increment to clock interrupts.
	// LAB 6: Your code here.

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
		cprintf("Spurious interrupt on irq 7\n");
		print_trapframe(tf);
		return;
	}

	if (tf->tf_trapno == T_PGFLT) {
		page_fault_handler(tf);
		return;
	}
	else if (tf->tf_trapno == T_BRKPT) {
		monitor(tf);
		return;
	}
	else if (tf->tf_trapno == T_SYSCALL) {
		struct PushRegs *pr = &(tf->tf_regs);
		pr->reg_eax = syscall(pr->reg_eax, pr->reg_edx, pr->reg_ecx, 
				      pr->reg_ebx, pr->reg_edi, pr->reg_esi);
		return;
	}
	else if (tf->tf_trapno == IRQ_OFFSET + e100_func.irq_line) {
		DPRINTF6("E100 Interrupt!!\n");
	}

	// Handle keyboard and serial interrupts.
	// LAB 7: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	DPRINTF6("trap_dispatch(%x):tf_trapno: %d\n", tf, tf->tf_trapno);
	print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
		panic("unhandled trap in kernel");
	else {
		DPRINTF4C("Destroying environment.\n");
		env_destroy(curenv);
		return;
	}
}

void
trap(struct Trapframe *tf)
{
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));

	if ((tf->tf_cs & 3) == 3) {
		// Trapped from user mode.
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		assert(curenv);
		curenv->env_tf = *tf;
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
	}
	
	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNABLE)
		env_run(curenv);
	else
		sched_yield();
}

unsigned int getCR3(void)
{
   unsigned int _cr3;

   asm ("mov %%cr3, %0":"=r" (_cr3));
   return _cr3;
}

void
page_fault_handler(struct Trapframe *tf)
{
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & ((1 << 16) - 1)) == GD_KT) {
		panic("Page fault in kernel mode!! at VA: %x\n", fault_va);
		return;
	}

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Call the environment's page fault upcall, if one exists.  Set up a
	// page fault stack frame on the user exception stack (below
	// UXSTACKTOP), then branch to curenv->env_pgfault_upcall.
	//
	// The page fault upcall might cause another page fault, in which case
	// we branch to the page fault upcall recursively, pushing another
	// page fault stack frame on top of the user exception stack.
	//
	// The trap handler needs one word of scratch space at the top of the
	// trap-time stack in order to return.  In the non-recursive case, we
	// don't have to worry about this because the top of the regular user
	// stack is free.  In the recursive case, this means we have to leave
	// an extra word between the current top of the exception stack and
	// the new stack frame because the exception stack _is_ the trap-time
	// stack.
	//
	// If there's no page fault upcall, the environment didn't allocate a
	// page for its exception stack or can't write to it, or the exception
	// stack overflows, then destroy the environment that caused the fault.
	// Note that the grade script assumes you will first check for the page
	// fault upcall and print the "user fault va" message below if there is
	// none.  The remaining three checks can be combined into a single test.
	//
	// Hints:
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	DPRINTF4("Page fault at address: %x, curenv: %x, envid: %d, EIP: %x\n", fault_va, curenv, curenv->env_id, curenv->env_tf.tf_eip);
	DPRINTF4("curenv->env_tf.tf_esp: %x, UXSTACKTOP - PGSIZE: %x, USTACKTOP: %x, UXSTACKTOP: %x\n", tf->tf_esp, UXSTACKTOP - PGSIZE, USTACKTOP, UXSTACKTOP);

	struct Trapframe orig_tf = curenv->env_tf;

	if (!(curenv->env_tf.tf_esp < UXSTACKTOP - PGSIZE && curenv->env_tf.tf_esp > USTACKTOP)) {
		DPRINTF4("Upcall is: %x\n", curenv->env_pgfault_upcall);

		if (curenv->env_pgfault_upcall) {
			int offset = sizeof(uint32_t);

			if (curenv->env_tf.tf_esp <= USTACKTOP) {
				// we are in the normal user stack
				DPRINTF4("ESP does NOT point to the Trap-Time Stack\n");
				curenv->env_tf.tf_esp = UXSTACKTOP - 4;

				// First exception, w
				offset = 0;
			}

			struct UTrapframe* utf = (struct UTrapframe *) 
				(curenv->env_tf.tf_esp - offset - sizeof(struct UTrapframe));
			user_mem_assert(curenv, utf, sizeof(struct UTrapframe), PTE_P | PTE_W | PTE_U);
			DPRINTF4("utf: %x, current CR3: %x, boot_cr3: %x, curenv->env_cr3: %x\n", utf, getCR3(), boot_cr3, curenv->env_cr3);

			utf->utf_fault_va = fault_va;
			utf->utf_err = orig_tf.tf_err;
			utf->utf_regs = orig_tf.tf_regs;
			utf->utf_eip = orig_tf.tf_eip;
			utf->utf_eflags = orig_tf.tf_eflags;
			utf->utf_esp = orig_tf.tf_esp;

			curenv->env_tf.tf_eip = (uintptr_t) curenv->env_pgfault_upcall;
			curenv->env_tf.tf_esp = (uintptr_t) utf;
			
			// DPRINTF4("Original Trapframe:\n");
			// print_trapframe(&orig_tf);
			DPRINTF4("page_fault_handler::about to run environment: %x, New EIP: %x, orig EIP: %x\n", curenv, curenv->env_tf.tf_eip, utf->utf_eip);
			env_run(curenv);
		}
	} else {
		// We've overrun the user exception stack
	}

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
	env_destroy(curenv);
}

