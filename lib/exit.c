// -*- c-basic-offset:8; indent-tabs-mode:t -*-
#include <inc/lib.h>

void
exit(void)
{
	close_all();
	sys_env_destroy(0);
}

