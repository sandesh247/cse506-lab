#ifndef JOS_INC_TRAP_H
#define JOS_INC_TRAP_H

// Trap numbers
// These are processor defined:
#define T_DIVIDE     0		// [NO ERR COD] divide error 
#define T_DEBUG      1		// [NO ERR COD] debug exception
#define T_NMI        2		// [NO ERR COD] non-maskable interrupt
#define T_BRKPT      3		// [NO ERR COD] breakpoint
#define T_OFLOW      4		// [NO ERR COD] overflow
#define T_BOUND      5		// [NO ERR COD] bounds check
#define T_ILLOP      6		// [NO ERR COD] illegal opcode
#define T_DEVICE     7		// [NO ERR COD] device not available 
#define T_DBLFLT     8		// [ERR COD  0] double fault
/* #define T_COPROC  9 */	// reserved (not generated by recent processors)
#define T_TSS       10		// [ERR COD   ] invalid task switch segment
#define T_SEGNP     11		// [ERR COD   ] segment not present
#define T_STACK     12		// [ERR COD   ] stack exception
#define T_GPFLT     13		// [ERR COD   ] general protection fault
#define T_PGFLT     14		// [ERR COD   ] page fault
/* #define T_RES    15 */	// reserved
#define T_FPERR     16		// [NO ERR COD] floating point error
#define T_ALIGN     17		// [ERR COD  0] aligment check
#define T_MCHK      18		// [NO ERR COD] machine check
#define T_SIMDERR   19		// [NO ERR COD] SIMD floating point error

// These are arbitrarily chosen, but with care not to overlap
// processor defined exceptions or interrupt vectors.
#define T_SYSCALL   48		// [NO ERR COD] system call
#define T_DEFAULT   500		// [NO ERR COD] catchall

// Hardware IRQ numbers. We receive these as (IRQ_OFFSET+IRQ_WHATEVER)
#define IRQ_TIMER        0
#define IRQ_KBD          1
#define IRQ_SERIAL       4
#define IRQ_SPURIOUS     7
#define IRQ_E100        11
#define IRQ_IDE         14
#define IRQ_ERROR       19

#ifndef __ASSEMBLER__

#include <inc/types.h>

struct PushRegs {
	/* registers as pushed by pusha */
	uint32_t reg_edi;
	uint32_t reg_esi;
	uint32_t reg_ebp;
	uint32_t reg_oesp;		/* Useless */
	uint32_t reg_ebx;
	uint32_t reg_edx;
	uint32_t reg_ecx;
	uint32_t reg_eax;
} __attribute__((packed));

struct Trapframe {
	struct PushRegs tf_regs;
	uint16_t tf_es;
	uint16_t tf_padding1;
	uint16_t tf_ds;
	uint16_t tf_padding2;
	uint32_t tf_trapno;
	/* below here defined by x86 hardware */
	uint32_t tf_err;
	uintptr_t tf_eip;
	uint16_t tf_cs;
	uint16_t tf_padding3;
	uint32_t tf_eflags;
	/* below here only when crossing rings, such as from user to kernel */
	uintptr_t tf_esp;
	uint16_t tf_ss;
	uint16_t tf_padding4;
} __attribute__((packed));

struct UTrapframe {
	/* information about the fault */
	uint32_t utf_fault_va;	/* va for T_PGFLT, 0 otherwise */
	uint32_t utf_err;
	/* trap-time return state */
	struct PushRegs utf_regs;
	uintptr_t utf_eip;
	uint32_t utf_eflags;
	/* the trap-time stack to return to */
	uintptr_t utf_esp;
} __attribute__((packed));

#endif /* !__ASSEMBLER__ */

// Must equal 'sizeof(struct Trapframe)'.
// A static_assert in kern/trap.c checks this.
#define SIZEOF_STRUCT_TRAPFRAME	0x44

#endif /* !JOS_INC_TRAP_H */
