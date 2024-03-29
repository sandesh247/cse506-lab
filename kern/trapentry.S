/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

/* The TRAPHANDLER macro defines a globally-visible function for handling
 * a trap.  It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 */ 
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(h_divide    , T_DIVIDE)
TRAPHANDLER_NOEC(h_debug     , T_DEBUG)
TRAPHANDLER_NOEC(h_nmig      , T_NMI)
TRAPHANDLER_NOEC(h_brkptg    , T_BRKPT)
TRAPHANDLER_NOEC(h_oflowg    , T_OFLOW)
TRAPHANDLER_NOEC(h_boundg    , T_BOUND)
TRAPHANDLER_NOEC(h_illopg    , T_ILLOP)
TRAPHANDLER_NOEC(h_deviceg   , T_DEVICE)

TRAPHANDLER(h_dblflt         , T_DBLFLT)
TRAPHANDLER(h_tss            , T_TSS)
TRAPHANDLER(h_segnp          , T_SEGNP)
TRAPHANDLER(h_stack          , T_STACK)
TRAPHANDLER(h_gpflt          , T_GPFLT)
TRAPHANDLER(h_pgflt          , T_PGFLT)

TRAPHANDLER_NOEC(t_fperr     , T_FPERR)
TRAPHANDLER(t_align          , T_ALIGN)
TRAPHANDLER_NOEC(t_mchk      , T_MCHK)
TRAPHANDLER_NOEC(t_simderr   , T_SIMDERR)
TRAPHANDLER_NOEC(t_syscall   , T_SYSCALL)
TRAPHANDLER_NOEC(t_default   , T_DEFAULT)

TRAPHANDLER_NOEC(irq_timer	, IRQ_OFFSET + IRQ_TIMER)
TRAPHANDLER_NOEC(irq_kbd		, IRQ_OFFSET + IRQ_KBD)
TRAPHANDLER_NOEC(irq_serial , IRQ_OFFSET + IRQ_SERIAL)
TRAPHANDLER_NOEC(irq_spurious	, IRQ_OFFSET + IRQ_SPURIOUS)
TRAPHANDLER_NOEC(irq_ide	, IRQ_OFFSET + IRQ_IDE)
TRAPHANDLER_NOEC(irq_e100	, IRQ_OFFSET + IRQ_E100)


/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
        pushl %ds
        pushl %es
        pushal
        mov $GD_KD, %ax
        mov %ax, %es
        mov %ax, %ds
        movl %esp, %eax
        pushl %eax
        call trap
