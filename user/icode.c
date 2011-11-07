#include <inc/lib.h>

void
umain(void)
{
	int fd, n, r;
	char buf[512+1];

	binaryname = "icode";

	cprintf("icode startup\n");

	cprintf("icode: open /motd\n");
	if ((fd = open("/motd", O_RDONLY)) < 0)
		panic("icode: open /motd: %e", fd);

	cprintf("icode: read /motd\n");
	while ((n = read(fd, buf, sizeof buf-1)) > 0)
		sys_cputs(buf, n);

	cprintf("icode: close /motd\n");
	close(fd);

        // TODO: ADDED
        if ((fd = open("/init", O_RDONLY)) < 0) {
            panic("[1] Error opening /init\n");
        }
        int o = 0;
	while ((n = read(fd, buf, sizeof buf-1)) > 0) {
        }
        close(fd);
        if ((fd = open("/init", O_RDONLY)) < 0) {
            panic("[1] Error opening /init\n");
        }
	while ((n = read(fd, buf, sizeof buf-1)) > 0) {
            o += n;
            cprintf("Showing ASCII for offset: %d: ", o - n);
            int j;
            for (j = 0; j < n; ++j) {
                if (buf[j] >= '0' && buf[j] <= 'z') {
                    sys_cputs(buf + j, 1);
                }
            }
            cprintf("--DONE\n");
        }
	close(fd);
        // /ADDED

	cprintf("icode: spawn /init\n");
	if ((r = spawnl("/init", "init", "initarg1", "initarg2", (char*)0)) < 0)
		panic("icode: spawn /init: %e", r);

	cprintf("icode: exiting\n");
}
