// hello, world
#include <inc/lib.h>

char *buff = "hello.c::Testing sending of data";
char ib[1024];

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
            // Child
            cprintf("I am the CHILD environemnt: %d\n", sys_getenvid());
            for (; i < 20; ++i) {
                cprintf("i: %d\n", i);
            }

            int len = 1023;
            ib[0] = '\0';
            cprintf("About to receive from parent\n");
            r = ripc_recv(ib, &len, buff, strlen(buff));
            ib[len] = '\0';
            cprintf("Received from parent: %s\n", ib);
        }
        else {
            // Parent
            int len = 1023;
            ib[0] = '\0';
            cprintf("About to send to child\n");
            r = ripc_send(r, buff, strlen(buff), ib, &len);
            cprintf("len: %d\n", len);
            ib[len] = '\0';
            cprintf("Received from child: %s\n", ib);
        }

}
