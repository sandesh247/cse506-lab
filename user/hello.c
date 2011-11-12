// hello, world
#include <inc/lib.h>

void
umain(void)
{
	cprintf("hello, world\n");
	cprintf("my env id is %d\n", sys_getenvid());
	cprintf("i am environment %08x\n", env->env_id);
}
