// hello, world
#include <inc/lib.h>

char *buff = "hello.c::Testing sending of data";

void
umain(void)
{
	cprintf("hello, world\n");
	cprintf("my env id is %d\n", sys_getenvid());
	cprintf("i am environment %08x\n", env->env_id);

        int i;
        for (i = 0; i < 10; ++i) {
            cprintf("i: %d\n", i);
        }

        int r = migrate();
        if (!r) {
            cprintf("I am the CHILD environemnt: %d\n", sys_getenvid());
            for (; i < 20; ++i) {
                cprintf("i: %d\n", i);
            }
        }

}
