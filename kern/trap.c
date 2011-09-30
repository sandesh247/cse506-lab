#include <inc/mmu.h>
#include <inc/x86.h>
#include <inc/assert.h>

#include <kern/pmap.h>
#include <kern/trap.h>
#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/env.h>
#include <kern/syscall.h>

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
        SETGATE(idt[T_DIVIDE], 1, GD_KT, h_divide, 0);
        SETGATE(idt[T_DEBUG], 1, GD_KT, h_debug, 0);
        SETGATE(idt[T_NMI], 1, GD_KT, h_nmig, 0);
        SETGATE(idt[T_BRKPT], 1, GD_KT, h_brkptg, 0);
        SETGATE(idt[T_OFLOW], 1, GD_KT, h_oflowg, 0);
        SETGATE(idt[T_BOUND], 1, GD_KT, h_boundg, 0);
        SETGATE(idt[T_ILLOP], 1, GD_KT, h_illopg, 0);
        SETGATE(idt[T_DEVICE], 1, GD_KT, h_deviceg, 0);

        SETGATE(idt[T_DBLFLT], 1, GD_KT, h_dblflt, 0);
        SETGATE(idt[T_TSS], 1, GD_KT, h_tss, 0);
        SETGATE(idt[T_SEGNP], 1, GD_KT, h_segnp, 0);
        SETGATE(idt[T_STACK], 1, GD_KT, h_stack, 0);
        SETGATE(idt[T_GPFLT], 1, GD_KT, h_gpflt, 0);
        SETGATE(idt[T_PGFLT], 1, GD_KT, h_pgflt, 0);

        SETGATE(idt[T_FPERR], 1, GD_KT, t_fperr, 0);
        SETGATE(idt[T_ALIGN], 1, GD_KT, t_align, 0);
        SETGATE(idt[T_MCHK], 1, GD_KT, t_mchk, 0);
        SETGATE(idt[T_SIMDERR], 1, GD_KT, t_simderr, 0);
        SETGATE(idt[T_SYSCALL], 1, GD_KT, t_syscall, 0);
        SETGATE(idt[T_DEFAULT], 1, GD_KT, t_default, 0);

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
	

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
		panic("unhandled trap in kernel");
	else {
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

	cprintf("Incoming TRAP frame at %p\n", tf);

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

	// Return to the current environment, which should be runnable.
	assert(curenv && curenv->env_status == ENV_RUNNABLE);
	env_run(curenv);
}


void
page_fault_handler(struct Trapframe *tf)
{
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.
	
	// LAB 3: Your code here.

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
	env_destroy(curenv);
}

