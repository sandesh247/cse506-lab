#include <inc/lib.h>
#include <inc/trap.h>

int
migrate() {
    // Send all our pages from UTEXT to UXSTACKTOP to the daemon on the
    // other end.
    // 
    // General Strategy: fork() and send all the child's pages across
    // the network. Also send the child's exception & user stack on
    // the network. The daemon on the other end will fork and replace
    // the child's process image with the image it receives.
    // 
    // message type (32-bits)
    // TrapFrame
    // pages[npages] (32-bit address, PGSIZE data)
    // last page (only 32-bit address: 0xffffffff)
    // number of pages[npages] (32-bits)
    // 

    int r, child;
    if ((r = sys_exofork()) < 0) {
        return r;
    }

    child = r;

    // The child will never run (infanticide of sorts)...

    // Get the child's trapframe
    struct Trapframe tf;
    r = sys_env_get_trapframe(child, &tf);
    if (r < 0) {
        goto cleanup;
    }

    // Return 0 in the child on the remote machine
    tf.tf_regs.reg_eax = 0;

    int addr;
    for (addr = UTEXT; addr < UTOP; addr += PGSIZE) {
        // Send each page off to the other side.
    }


    // Success, return the child's env_id
    r = child;

 cleanup:
    sys_env_destroy(child);
    return r;
}
