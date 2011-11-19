// hello, world
#include <inc/lib.h>

char *buff = "hello.c::Testing sending of data";

void
umain(void)
{
	cprintf("hello, world\n");
	cprintf("my env id is %d\n", sys_getenvid());
	cprintf("i am environment %08x\n", env->env_id);

        cprintf("hello.c::buff: %x\n", buff);
        int r = sys_net_send(buff, strlen(buff));
        cprintf("hello.c::sys_net_send returned: %d\n", r);
}
