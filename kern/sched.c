// -*- c-basic-offset: 8; indent-tabs-mode: t -*-
#include <inc/assert.h>

#include <kern/env.h>
#include <kern/pmap.h>
#include <kern/monitor.h>


// Choose a user environment to run and run it.
void
sched_yield(void)
{
	// Implement simple round-robin scheduling.
	// Search through 'envs' for a runnable environment,
	// in circular fashion starting after the previously running env,
	// and switch to the first such environment found.
	// It's OK to choose the previously running env if no other env
	// is runnable.
	// But never choose envs[0], the idle environment,
	// unless NOTHING else is runnable.

	// LAB 4: Your code here.
	
	if(curenv) {
		DPRINTF4C("Yielding from %d.\n", curenv->env_id);
	}

	int j;
	DPRINTF4C("Runnable environments:\n");
	for(j = 0; j < NENV; ++j) {
		if(envs[j].env_status == ENV_RUNNABLE) {
			DPRINTF4C("%d\n", envs[j].env_id);
		}
	}


	int i = (curenv ? curenv - envs + 1 : 1);
	for(; i < NENV; ++i) {
		if(envs[i].env_status == ENV_RUNNABLE) {
			DPRINTF4C("Scheduling envid %d.\n", envs[i].env_id);
			env_run(&envs[i]);
		}
	}

	int _i = (curenv ? curenv - envs + 1: NENV);
	for(i = 1; i < _i; ++i) {
		if(envs[i].env_status == ENV_RUNNABLE) {
			DPRINTF4C("Scheduling envid %d.\n", envs[i].env_id);
			env_run(&envs[i]);
		}
	}

	// Run the special idle environment when nothing else is runnable.
	if (envs[0].env_status == ENV_RUNNABLE) {
		DPRINTF4C("scheduling monitor environment.\n");
		env_run(&envs[0]);
	}
	else {
		cprintf("Destroyed all environments - nothing more to do!\n");
		while (1)
			monitor(NULL);
	}
}
