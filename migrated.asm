
obj/user/migrated:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 77 05 00 00       	call   8005a8 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
	...

00800034 <die>:
 *
 */

static void
die(char *m)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	83 ec 18             	sub    $0x18,%esp
	cprintf("%s\n", m);
  80003a:	8b 45 08             	mov    0x8(%ebp),%eax
  80003d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800041:	c7 04 24 a0 35 80 00 	movl   $0x8035a0,(%esp)
  800048:	e8 04 07 00 00       	call   800751 <cprintf>
	exit();
  80004d:	e8 b2 05 00 00       	call   800604 <exit>
}
  800052:	c9                   	leave  
  800053:	c3                   	ret    

00800054 <handle_migrate>:
uint32_t	addr;
char			data[PGSIZE];
uint32_t	npages;

static void 
handle_migrate(int sock) {
  800054:	55                   	push   %ebp
  800055:	89 e5                	mov    %esp,%ebp
  800057:	53                   	push   %ebx
  800058:	83 ec 44             	sub    $0x44,%esp
	int r;
	int seen_pages = 0;
  80005b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
static __inline envid_t sys_exofork(void) __attribute__((always_inline));
static __inline envid_t
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  800062:	c7 45 e4 07 00 00 00 	movl   $0x7,-0x1c(%ebp)
  800069:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80006c:	cd 30                	int    $0x30
  80006e:	89 c3                	mov    %eax,%ebx
  800070:	89 5d e8             	mov    %ebx,-0x18(%ebp)
		: "=a" (ret)
		: "a" (SYS_exofork),
		  "i" (T_SYSCALL)
	);
	return ret;
  800073:	8b 45 e8             	mov    -0x18(%ebp),%eax

	if ((r = sys_exofork()) < 0) {
  800076:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800079:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  80007d:	79 1f                	jns    80009e <handle_migrate+0x4a>
		DPRINTF8("Could not fork (%d): %e\n", r, r);
  80007f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  800082:	89 44 24 08          	mov    %eax,0x8(%esp)
  800086:	8b 45 f0             	mov    -0x10(%ebp),%eax
  800089:	89 44 24 04          	mov    %eax,0x4(%esp)
  80008d:	c7 04 24 a4 35 80 00 	movl   $0x8035a4,(%esp)
  800094:	e8 b8 06 00 00       	call   800751 <cprintf>
		return;
  800099:	e9 43 03 00 00       	jmp    8003e1 <handle_migrate+0x38d>
	}
	int child = r;
  80009e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8000a1:	89 45 ec             	mov    %eax,-0x14(%ebp)

	DPRINTF8("Receiving trapframe ...\n");
  8000a4:	c7 04 24 bd 35 80 00 	movl   $0x8035bd,(%esp)
  8000ab:	e8 a1 06 00 00       	call   800751 <cprintf>
	r = readn(sock, &trapframe, sizeof(trapframe));
  8000b0:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
  8000b7:	00 
  8000b8:	c7 44 24 04 e0 70 80 	movl   $0x8070e0,0x4(%esp)
  8000bf:	00 
  8000c0:	8b 45 08             	mov    0x8(%ebp),%eax
  8000c3:	89 04 24             	mov    %eax,(%esp)
  8000c6:	e8 24 1b 00 00       	call   801bef <readn>
  8000cb:	89 45 f0             	mov    %eax,-0x10(%ebp)

	if(r < 0) {
  8000ce:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  8000d2:	79 1f                	jns    8000f3 <handle_migrate+0x9f>
		DPRINTF8("Error while trying to receive trapframe (%d): %e\n", r, r);
  8000d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8000d7:	89 44 24 08          	mov    %eax,0x8(%esp)
  8000db:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8000de:	89 44 24 04          	mov    %eax,0x4(%esp)
  8000e2:	c7 04 24 d8 35 80 00 	movl   $0x8035d8,(%esp)
  8000e9:	e8 63 06 00 00       	call   800751 <cprintf>
		return;
  8000ee:	e9 ee 02 00 00       	jmp    8003e1 <handle_migrate+0x38d>
	}

	while(1) {
		r = readn(sock, &addr, sizeof(addr));
  8000f3:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  8000fa:	00 
  8000fb:	c7 44 24 04 24 71 80 	movl   $0x807124,0x4(%esp)
  800102:	00 
  800103:	8b 45 08             	mov    0x8(%ebp),%eax
  800106:	89 04 24             	mov    %eax,(%esp)
  800109:	e8 e1 1a 00 00       	call   801bef <readn>
  80010e:	89 45 f0             	mov    %eax,-0x10(%ebp)

		if(r < 0) {
  800111:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  800115:	79 1f                	jns    800136 <handle_migrate+0xe2>
			DPRINTF8("Error while trying to receive virtual address (%d): %e\n", r, r);
  800117:	8b 45 f0             	mov    -0x10(%ebp),%eax
  80011a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80011e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  800121:	89 44 24 04          	mov    %eax,0x4(%esp)
  800125:	c7 04 24 0c 36 80 00 	movl   $0x80360c,(%esp)
  80012c:	e8 20 06 00 00       	call   800751 <cprintf>
			return;
  800131:	e9 ab 02 00 00       	jmp    8003e1 <handle_migrate+0x38d>
		}

		if(addr == MIG_LAST_ADDR) {
  800136:	a1 24 71 80 00       	mov    0x807124,%eax
  80013b:	83 f8 ff             	cmp    $0xffffffff,%eax
  80013e:	75 39                	jne    800179 <handle_migrate+0x125>
			DPRINTF8("Received all pages.");
  800140:	c7 04 24 44 36 80 00 	movl   $0x803644,(%esp)
  800147:	e8 05 06 00 00       	call   800751 <cprintf>
		}

		DPRINTF8("Mapped page!\n");
	}

	r = readn(sock, &npages, sizeof(npages));
  80014c:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  800153:	00 
  800154:	c7 44 24 04 40 81 80 	movl   $0x808140,0x4(%esp)
  80015b:	00 
  80015c:	8b 45 08             	mov    0x8(%ebp),%eax
  80015f:	89 04 24             	mov    %eax,(%esp)
  800162:	e8 88 1a 00 00       	call   801bef <readn>
  800167:	89 45 f0             	mov    %eax,-0x10(%ebp)

	if(r < 0) {
  80016a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  80016e:	0f 88 6e 01 00 00    	js     8002e2 <handle_migrate+0x28e>
  800174:	e9 93 01 00 00       	jmp    80030c <handle_migrate+0x2b8>
		if(addr == MIG_LAST_ADDR) {
			DPRINTF8("Received all pages.");
			break;
		}

		DPRINTF8("About to map address %x ...\n", addr);
  800179:	a1 24 71 80 00       	mov    0x807124,%eax
  80017e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800182:	c7 04 24 58 36 80 00 	movl   $0x803658,(%esp)
  800189:	e8 c3 05 00 00       	call   800751 <cprintf>

		r = readn(sock, data, sizeof(data));
  80018e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  800195:	00 
  800196:	c7 44 24 04 40 71 80 	movl   $0x807140,0x4(%esp)
  80019d:	00 
  80019e:	8b 45 08             	mov    0x8(%ebp),%eax
  8001a1:	89 04 24             	mov    %eax,(%esp)
  8001a4:	e8 46 1a 00 00       	call   801bef <readn>
  8001a9:	89 45 f0             	mov    %eax,-0x10(%ebp)
		
		if(r < 0) {
  8001ac:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  8001b0:	79 1f                	jns    8001d1 <handle_migrate+0x17d>
			DPRINTF8("Error while trying to receive data at va (%d): %e\n", r, r);
  8001b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8001b5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8001bc:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001c0:	c7 04 24 78 36 80 00 	movl   $0x803678,(%esp)
  8001c7:	e8 85 05 00 00       	call   800751 <cprintf>
			return;
  8001cc:	e9 10 02 00 00       	jmp    8003e1 <handle_migrate+0x38d>
		}

		++seen_pages;
  8001d1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

		// at this point, we have the address and the va, map it on to the process
		
		if((r = sys_page_alloc(0, PFTEMP, PTE_P | PTE_U | PTE_W)) < 0) {
  8001d5:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  8001dc:	00 
  8001dd:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  8001e4:	00 
  8001e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8001ec:	e8 85 12 00 00       	call   801476 <sys_page_alloc>
  8001f1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  8001f4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  8001f8:	79 23                	jns    80021d <handle_migrate+0x1c9>
			panic("sys_page_alloc: %e", r);
  8001fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8001fd:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800201:	c7 44 24 08 ab 36 80 	movl   $0x8036ab,0x8(%esp)
  800208:	00 
  800209:	c7 44 24 04 4c 00 00 	movl   $0x4c,0x4(%esp)
  800210:	00 
  800211:	c7 04 24 be 36 80 00 	movl   $0x8036be,(%esp)
  800218:	e8 03 04 00 00       	call   800620 <_panic>
		}

		// Copy contents from addr to PFTEMP
		memmove(PFTEMP, data, PGSIZE);
  80021d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  800224:	00 
  800225:	c7 44 24 04 40 71 80 	movl   $0x807140,0x4(%esp)
  80022c:	00 
  80022d:	c7 04 24 00 f0 7f 00 	movl   $0x7ff000,(%esp)
  800234:	e8 ef 0d 00 00       	call   801028 <memmove>

		// Map *our* PFTEMP to child's *addr*
		// TODO: Need proper page permissions
		if((r = sys_page_map(0, PFTEMP, child, (void *) addr, PTE_W|PTE_P|PTE_U)) < 0) {
  800239:	a1 24 71 80 00       	mov    0x807124,%eax
  80023e:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  800245:	00 
  800246:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80024a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80024d:	89 44 24 08          	mov    %eax,0x8(%esp)
  800251:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800258:	00 
  800259:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800260:	e8 52 12 00 00       	call   8014b7 <sys_page_map>
  800265:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800268:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  80026c:	79 23                	jns    800291 <handle_migrate+0x23d>
			panic("sys_page_map: %e", r);
  80026e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  800271:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800275:	c7 44 24 08 ce 36 80 	movl   $0x8036ce,0x8(%esp)
  80027c:	00 
  80027d:	c7 44 24 04 55 00 00 	movl   $0x55,0x4(%esp)
  800284:	00 
  800285:	c7 04 24 be 36 80 00 	movl   $0x8036be,(%esp)
  80028c:	e8 8f 03 00 00       	call   800620 <_panic>
		}

		if ((r = sys_page_unmap(0, PFTEMP)) < 0) {
  800291:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800298:	00 
  800299:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8002a0:	e8 58 12 00 00       	call   8014fd <sys_page_unmap>
  8002a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  8002a8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  8002ac:	79 23                	jns    8002d1 <handle_migrate+0x27d>
			panic("sys_page_unmap: %e", r);
  8002ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8002b1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002b5:	c7 44 24 08 df 36 80 	movl   $0x8036df,0x8(%esp)
  8002bc:	00 
  8002bd:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  8002c4:	00 
  8002c5:	c7 04 24 be 36 80 00 	movl   $0x8036be,(%esp)
  8002cc:	e8 4f 03 00 00       	call   800620 <_panic>
		}

		DPRINTF8("Mapped page!\n");
  8002d1:	c7 04 24 f2 36 80 00 	movl   $0x8036f2,(%esp)
  8002d8:	e8 74 04 00 00       	call   800751 <cprintf>
	}
  8002dd:	e9 11 fe ff ff       	jmp    8000f3 <handle_migrate+0x9f>

	r = readn(sock, &npages, sizeof(npages));

	if(r < 0) {
		DPRINTF8("Error while trying to receive npages (%d): %e\n", r, r);
  8002e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8002e5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8002ec:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002f0:	c7 04 24 00 37 80 00 	movl   $0x803700,(%esp)
  8002f7:	e8 55 04 00 00       	call   800751 <cprintf>
		sys_env_destroy(child);
  8002fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8002ff:	89 04 24             	mov    %eax,(%esp)
  800302:	e8 a4 10 00 00       	call   8013ab <sys_env_destroy>
		return;
  800307:	e9 d5 00 00 00       	jmp    8003e1 <handle_migrate+0x38d>
	}

	if(seen_pages != npages) {
  80030c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  80030f:	a1 40 81 80 00       	mov    0x808140,%eax
  800314:	39 c2                	cmp    %eax,%edx
  800316:	74 2c                	je     800344 <handle_migrate+0x2f0>
		DPRINTF8("Not seen the right number of pages: expected %d, got %d.\n", npages, seen_pages);
  800318:	a1 40 81 80 00       	mov    0x808140,%eax
  80031d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  800320:	89 54 24 08          	mov    %edx,0x8(%esp)
  800324:	89 44 24 04          	mov    %eax,0x4(%esp)
  800328:	c7 04 24 30 37 80 00 	movl   $0x803730,(%esp)
  80032f:	e8 1d 04 00 00       	call   800751 <cprintf>
		sys_env_destroy(child);
  800334:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800337:	89 04 24             	mov    %eax,(%esp)
  80033a:	e8 6c 10 00 00       	call   8013ab <sys_env_destroy>
		return;
  80033f:	e9 9d 00 00 00       	jmp    8003e1 <handle_migrate+0x38d>
	}

	DPRINTF8("Setting trapframe ...\n");
  800344:	c7 04 24 6a 37 80 00 	movl   $0x80376a,(%esp)
  80034b:	e8 01 04 00 00       	call   800751 <cprintf>
	r = sys_env_set_trapframe(child, &trapframe);
  800350:	c7 44 24 04 e0 70 80 	movl   $0x8070e0,0x4(%esp)
  800357:	00 
  800358:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80035b:	89 04 24             	mov    %eax,(%esp)
  80035e:	e8 1e 12 00 00       	call   801581 <sys_env_set_trapframe>
  800363:	89 45 f0             	mov    %eax,-0x10(%ebp)
	
	if(r < 0) {
  800366:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  80036a:	79 25                	jns    800391 <handle_migrate+0x33d>
		DPRINTF8("Could not set trapframe (%d): %e\n", r, r);
  80036c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  80036f:	89 44 24 08          	mov    %eax,0x8(%esp)
  800373:	8b 45 f0             	mov    -0x10(%ebp),%eax
  800376:	89 44 24 04          	mov    %eax,0x4(%esp)
  80037a:	c7 04 24 84 37 80 00 	movl   $0x803784,(%esp)
  800381:	e8 cb 03 00 00       	call   800751 <cprintf>
		sys_env_destroy(child);
  800386:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800389:	89 04 24             	mov    %eax,(%esp)
  80038c:	e8 1a 10 00 00       	call   8013ab <sys_env_destroy>
	}


	// make the process runnable
	DPRINTF8("Run lola, run!\n");
  800391:	c7 04 24 a6 37 80 00 	movl   $0x8037a6,(%esp)
  800398:	e8 b4 03 00 00       	call   800751 <cprintf>
	r = sys_env_set_status(child, ENV_RUNNABLE);
  80039d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  8003a4:	00 
  8003a5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8003a8:	89 04 24             	mov    %eax,(%esp)
  8003ab:	e8 8f 11 00 00       	call   80153f <sys_env_set_status>
  8003b0:	89 45 f0             	mov    %eax,-0x10(%ebp)

	if(r < 0) {
  8003b3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  8003b7:	79 27                	jns    8003e0 <handle_migrate+0x38c>
		DPRINTF8("Could not set child to runnable (%d): %e\n", r, r);
  8003b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8003bc:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8003c3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003c7:	c7 04 24 b8 37 80 00 	movl   $0x8037b8,(%esp)
  8003ce:	e8 7e 03 00 00       	call   800751 <cprintf>
		sys_env_destroy(child);
  8003d3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8003d6:	89 04 24             	mov    %eax,(%esp)
  8003d9:	e8 cd 0f 00 00       	call   8013ab <sys_env_destroy>
	}

	return;
  8003de:	eb 01                	jmp    8003e1 <handle_migrate+0x38d>
  8003e0:	90                   	nop
}
  8003e1:	83 c4 44             	add    $0x44,%esp
  8003e4:	5b                   	pop    %ebx
  8003e5:	5d                   	pop    %ebp
  8003e6:	c3                   	ret    

008003e7 <handle_client>:

static void
handle_client(int sock)
{
  8003e7:	55                   	push   %ebp
  8003e8:	89 e5                	mov    %esp,%ebp
  8003ea:	83 ec 28             	sub    $0x28,%esp
	int r = readn(sock, &preamble, sizeof(preamble));
  8003ed:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  8003f4:	00 
  8003f5:	c7 44 24 04 c0 70 80 	movl   $0x8070c0,0x4(%esp)
  8003fc:	00 
  8003fd:	8b 45 08             	mov    0x8(%ebp),%eax
  800400:	89 04 24             	mov    %eax,(%esp)
  800403:	e8 e7 17 00 00       	call   801bef <readn>
  800408:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(r < 0) {
  80040b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  80040f:	79 27                	jns    800438 <handle_client+0x51>
		DPRINTF8("Error while trying to read preamble (%d): %e\n", r, r);
  800411:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800414:	89 44 24 08          	mov    %eax,0x8(%esp)
  800418:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80041b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80041f:	c7 04 24 e4 37 80 00 	movl   $0x8037e4,(%esp)
  800426:	e8 26 03 00 00       	call   800751 <cprintf>
		close(sock);
  80042b:	8b 45 08             	mov    0x8(%ebp),%eax
  80042e:	89 04 24             	mov    %eax,(%esp)
  800431:	e8 73 15 00 00       	call   8019a9 <close>
		return;
  800436:	eb 51                	jmp    800489 <handle_client+0xa2>
	}

	// the handle_* functions for each 
	switch(preamble) {
  800438:	a1 c0 70 80 00       	mov    0x8070c0,%eax
  80043d:	85 c0                	test   %eax,%eax
  80043f:	74 07                	je     800448 <handle_client+0x61>
  800441:	83 f8 01             	cmp    $0x1,%eax
  800444:	74 10                	je     800456 <handle_client+0x6f>
  800446:	eb 1c                	jmp    800464 <handle_client+0x7d>
		case MIG_HEARTBEAT:
			DPRINTF8("Received heartbeat <3\n");
  800448:	c7 04 24 12 38 80 00 	movl   $0x803812,(%esp)
  80044f:	e8 fd 02 00 00       	call   800751 <cprintf>
			break;
  800454:	eb 33                	jmp    800489 <handle_client+0xa2>
		case MIG_PROC_MIGRATE:
			handle_migrate(sock);
  800456:	8b 45 08             	mov    0x8(%ebp),%eax
  800459:	89 04 24             	mov    %eax,(%esp)
  80045c:	e8 f3 fb ff ff       	call   800054 <handle_migrate>
			break;
  800461:	90                   	nop
  800462:	eb 25                	jmp    800489 <handle_client+0xa2>
		default:
			panic("Invalid migration request: %d\n", preamble);
  800464:	a1 c0 70 80 00       	mov    0x8070c0,%eax
  800469:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80046d:	c7 44 24 08 2c 38 80 	movl   $0x80382c,0x8(%esp)
  800474:	00 
  800475:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
  80047c:	00 
  80047d:	c7 04 24 be 36 80 00 	movl   $0x8036be,(%esp)
  800484:	e8 97 01 00 00       	call   800620 <_panic>
	}

	// TODO: Uncomment: close(sock);
}
  800489:	c9                   	leave  
  80048a:	c3                   	ret    

0080048b <umain>:



int
umain(void)
{
  80048b:	55                   	push   %ebp
  80048c:	89 e5                	mov    %esp,%ebp
  80048e:	83 ec 48             	sub    $0x48,%esp
	int serversock, clientsock;
	struct sockaddr_in server, client;

	binaryname = "jmigrated";
  800491:	c7 05 00 70 80 00 4b 	movl   $0x80384b,0x807000
  800498:	38 80 00 

	// Create the TCP socket
	if ((serversock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0)
  80049b:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
  8004a2:	00 
  8004a3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  8004aa:	00 
  8004ab:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  8004b2:	e8 dc 1f 00 00       	call   802493 <socket>
  8004b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  8004ba:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  8004be:	79 0c                	jns    8004cc <umain+0x41>
		die("Failed to create socket");
  8004c0:	c7 04 24 55 38 80 00 	movl   $0x803855,(%esp)
  8004c7:	e8 68 fb ff ff       	call   800034 <die>

	// Construct the server sockaddr_in structure
	memset(&server, 0, sizeof(server));		// Clear struct
  8004cc:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
  8004d3:	00 
  8004d4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8004db:	00 
  8004dc:	8d 45 e0             	lea    -0x20(%ebp),%eax
  8004df:	89 04 24             	mov    %eax,(%esp)
  8004e2:	e8 10 0b 00 00       	call   800ff7 <memset>
	server.sin_family = AF_INET;			// Internet/IP
  8004e7:	c6 45 e1 02          	movb   $0x2,-0x1f(%ebp)
	server.sin_addr.s_addr = htonl(INADDR_ANY);	// IP address
  8004eb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8004f2:	e8 f6 2d 00 00       	call   8032ed <htonl>
  8004f7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	server.sin_port = htons(MIG_SERVER_PORT);			// server port
  8004fa:	c7 04 24 e1 10 00 00 	movl   $0x10e1,(%esp)
  800501:	e8 aa 2d 00 00       	call   8032b0 <htons>
  800506:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)

	// Bind the server socket
	if (bind(serversock, (struct sockaddr *) &server,
  80050a:	8d 45 e0             	lea    -0x20(%ebp),%eax
  80050d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
  800514:	00 
  800515:	89 44 24 04          	mov    %eax,0x4(%esp)
  800519:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80051c:	89 04 24             	mov    %eax,(%esp)
  80051f:	e8 07 1e 00 00       	call   80232b <bind>
  800524:	85 c0                	test   %eax,%eax
  800526:	79 0c                	jns    800534 <umain+0xa9>
		 sizeof(server)) < 0) 
	{
		die("Failed to bind the server socket");
  800528:	c7 04 24 70 38 80 00 	movl   $0x803870,(%esp)
  80052f:	e8 00 fb ff ff       	call   800034 <die>
	}

	// Listen on the server socket
	if (listen(serversock, MAXPENDING) < 0)
  800534:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
  80053b:	00 
  80053c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80053f:	89 04 24             	mov    %eax,(%esp)
  800542:	e8 a1 1e 00 00       	call   8023e8 <listen>
  800547:	85 c0                	test   %eax,%eax
  800549:	79 0c                	jns    800557 <umain+0xcc>
		die("Failed to listen on server socket");
  80054b:	c7 04 24 94 38 80 00 	movl   $0x803894,(%esp)
  800552:	e8 dd fa ff ff       	call   800034 <die>

	cprintf("Waiting for migration requests ...\n");
  800557:	c7 04 24 b8 38 80 00 	movl   $0x8038b8,(%esp)
  80055e:	e8 ee 01 00 00       	call   800751 <cprintf>

	while (1) {
		unsigned int clientlen = sizeof(client);
  800563:	c7 45 cc 10 00 00 00 	movl   $0x10,-0x34(%ebp)
		// Wait for client connection
		if ((clientsock = accept(serversock,
					 (struct sockaddr *) &client,
  80056a:	8d 45 d0             	lea    -0x30(%ebp),%eax
					 &clientlen)) < 0) 
  80056d:	8d 55 cc             	lea    -0x34(%ebp),%edx
  800570:	89 54 24 08          	mov    %edx,0x8(%esp)
	cprintf("Waiting for migration requests ...\n");

	while (1) {
		unsigned int clientlen = sizeof(client);
		// Wait for client connection
		if ((clientsock = accept(serversock,
  800574:	89 44 24 04          	mov    %eax,0x4(%esp)
  800578:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80057b:	89 04 24             	mov    %eax,(%esp)
  80057e:	e8 55 1d 00 00       	call   8022d8 <accept>
  800583:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800586:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  80058a:	79 0c                	jns    800598 <umain+0x10d>
					 (struct sockaddr *) &client,
					 &clientlen)) < 0) 
		{
			die("Failed to accept client connection");
  80058c:	c7 04 24 dc 38 80 00 	movl   $0x8038dc,(%esp)
  800593:	e8 9c fa ff ff       	call   800034 <die>
		}
		handle_client(clientsock);
  800598:	8b 45 f0             	mov    -0x10(%ebp),%eax
  80059b:	89 04 24             	mov    %eax,(%esp)
  80059e:	e8 44 fe ff ff       	call   8003e7 <handle_client>
	}
  8005a3:	eb be                	jmp    800563 <umain+0xd8>
  8005a5:	00 00                	add    %al,(%eax)
	...

008005a8 <libmain>:
volatile struct Env *env;
char *binaryname = "(PROGRAM NAME UNKNOWN)";

void
libmain(int argc, char **argv)
{
  8005a8:	55                   	push   %ebp
  8005a9:	89 e5                	mov    %esp,%ebp
  8005ab:	83 ec 18             	sub    $0x18,%esp
	// set env to point at our env structure in envs[].
	// LAB 3: Your code here.
	DPRINTF("libmain::sys_getenvid(): %d, ENVX: %d\n", sys_getenvid(), ENVX(sys_getenvid()));
  8005ae:	e8 3b 0e 00 00       	call   8013ee <sys_getenvid>
  8005b3:	e8 36 0e 00 00       	call   8013ee <sys_getenvid>
	env = &envs[ENVX(sys_getenvid())];
  8005b8:	e8 31 0e 00 00       	call   8013ee <sys_getenvid>
  8005bd:	25 ff 03 00 00       	and    $0x3ff,%eax
  8005c2:	c1 e0 02             	shl    $0x2,%eax
  8005c5:	89 c2                	mov    %eax,%edx
  8005c7:	c1 e2 05             	shl    $0x5,%edx
  8005ca:	89 d1                	mov    %edx,%ecx
  8005cc:	29 c1                	sub    %eax,%ecx
  8005ce:	89 c8                	mov    %ecx,%eax
  8005d0:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8005d5:	a3 44 81 80 00       	mov    %eax,0x808144

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8005da:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  8005de:	7e 0a                	jle    8005ea <libmain+0x42>
		binaryname = argv[0];
  8005e0:	8b 45 0c             	mov    0xc(%ebp),%eax
  8005e3:	8b 00                	mov    (%eax),%eax
  8005e5:	a3 00 70 80 00       	mov    %eax,0x807000

	// call user main routine
	umain(argc, argv);
  8005ea:	8b 45 0c             	mov    0xc(%ebp),%eax
  8005ed:	89 44 24 04          	mov    %eax,0x4(%esp)
  8005f1:	8b 45 08             	mov    0x8(%ebp),%eax
  8005f4:	89 04 24             	mov    %eax,(%esp)
  8005f7:	e8 8f fe ff ff       	call   80048b <umain>

	// exit gracefully
	exit();
  8005fc:	e8 03 00 00 00       	call   800604 <exit>
}
  800601:	c9                   	leave  
  800602:	c3                   	ret    
	...

00800604 <exit>:
// -*- c-basic-offset:8; indent-tabs-mode:t -*-
#include <inc/lib.h>

void
exit(void)
{
  800604:	55                   	push   %ebp
  800605:	89 e5                	mov    %esp,%ebp
  800607:	83 ec 18             	sub    $0x18,%esp
	close_all();
  80060a:	e8 d5 13 00 00       	call   8019e4 <close_all>
	sys_env_destroy(0);
  80060f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800616:	e8 90 0d 00 00       	call   8013ab <sys_env_destroy>
}
  80061b:	c9                   	leave  
  80061c:	c3                   	ret    
  80061d:	00 00                	add    %al,(%eax)
	...

00800620 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
  800620:	55                   	push   %ebp
  800621:	89 e5                	mov    %esp,%ebp
  800623:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  800626:	8d 45 14             	lea    0x14(%ebp),%eax
  800629:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Print the panic message
	if (argv0)
  80062c:	a1 48 81 80 00       	mov    0x808148,%eax
  800631:	85 c0                	test   %eax,%eax
  800633:	74 15                	je     80064a <_panic+0x2a>
		cprintf("%s: ", argv0);
  800635:	a1 48 81 80 00       	mov    0x808148,%eax
  80063a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80063e:	c7 04 24 16 39 80 00 	movl   $0x803916,(%esp)
  800645:	e8 07 01 00 00       	call   800751 <cprintf>
	cprintf("user panic in %s at %s:%d: ", binaryname, file, line);
  80064a:	a1 00 70 80 00       	mov    0x807000,%eax
  80064f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800652:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800656:	8b 55 08             	mov    0x8(%ebp),%edx
  800659:	89 54 24 08          	mov    %edx,0x8(%esp)
  80065d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800661:	c7 04 24 1b 39 80 00 	movl   $0x80391b,(%esp)
  800668:	e8 e4 00 00 00       	call   800751 <cprintf>
	vcprintf(fmt, ap);
  80066d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800670:	89 44 24 04          	mov    %eax,0x4(%esp)
  800674:	8b 45 10             	mov    0x10(%ebp),%eax
  800677:	89 04 24             	mov    %eax,(%esp)
  80067a:	e8 6d 00 00 00       	call   8006ec <vcprintf>
	cprintf("\n");
  80067f:	c7 04 24 37 39 80 00 	movl   $0x803937,(%esp)
  800686:	e8 c6 00 00 00       	call   800751 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80068b:	cc                   	int3   
  80068c:	eb fd                	jmp    80068b <_panic+0x6b>
	...

00800690 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800690:	55                   	push   %ebp
  800691:	89 e5                	mov    %esp,%ebp
  800693:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  800696:	8b 45 0c             	mov    0xc(%ebp),%eax
  800699:	8b 00                	mov    (%eax),%eax
  80069b:	8b 55 08             	mov    0x8(%ebp),%edx
  80069e:	89 d1                	mov    %edx,%ecx
  8006a0:	8b 55 0c             	mov    0xc(%ebp),%edx
  8006a3:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  8006a7:	8d 50 01             	lea    0x1(%eax),%edx
  8006aa:	8b 45 0c             	mov    0xc(%ebp),%eax
  8006ad:	89 10                	mov    %edx,(%eax)
	if (b->idx == 256-1) {
  8006af:	8b 45 0c             	mov    0xc(%ebp),%eax
  8006b2:	8b 00                	mov    (%eax),%eax
  8006b4:	3d ff 00 00 00       	cmp    $0xff,%eax
  8006b9:	75 20                	jne    8006db <putch+0x4b>
		sys_cputs(b->buf, b->idx);
  8006bb:	8b 45 0c             	mov    0xc(%ebp),%eax
  8006be:	8b 00                	mov    (%eax),%eax
  8006c0:	8b 55 0c             	mov    0xc(%ebp),%edx
  8006c3:	83 c2 08             	add    $0x8,%edx
  8006c6:	89 44 24 04          	mov    %eax,0x4(%esp)
  8006ca:	89 14 24             	mov    %edx,(%esp)
  8006cd:	e8 53 0c 00 00       	call   801325 <sys_cputs>
		b->idx = 0;
  8006d2:	8b 45 0c             	mov    0xc(%ebp),%eax
  8006d5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  8006db:	8b 45 0c             	mov    0xc(%ebp),%eax
  8006de:	8b 40 04             	mov    0x4(%eax),%eax
  8006e1:	8d 50 01             	lea    0x1(%eax),%edx
  8006e4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8006e7:	89 50 04             	mov    %edx,0x4(%eax)
}
  8006ea:	c9                   	leave  
  8006eb:	c3                   	ret    

008006ec <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8006ec:	55                   	push   %ebp
  8006ed:	89 e5                	mov    %esp,%ebp
  8006ef:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8006f5:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8006fc:	00 00 00 
	b.cnt = 0;
  8006ff:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800706:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800709:	b8 90 06 80 00       	mov    $0x800690,%eax
  80070e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800711:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800715:	8b 55 08             	mov    0x8(%ebp),%edx
  800718:	89 54 24 08          	mov    %edx,0x8(%esp)
  80071c:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  800722:	89 54 24 04          	mov    %edx,0x4(%esp)
  800726:	89 04 24             	mov    %eax,(%esp)
  800729:	e8 c6 01 00 00       	call   8008f4 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80072e:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800734:	89 44 24 04          	mov    %eax,0x4(%esp)
  800738:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80073e:	83 c0 08             	add    $0x8,%eax
  800741:	89 04 24             	mov    %eax,(%esp)
  800744:	e8 dc 0b 00 00       	call   801325 <sys_cputs>

	return b.cnt;
  800749:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  80074f:	c9                   	leave  
  800750:	c3                   	ret    

00800751 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800751:	55                   	push   %ebp
  800752:	89 e5                	mov    %esp,%ebp
  800754:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800757:	8d 45 0c             	lea    0xc(%ebp),%eax
  80075a:	89 45 f0             	mov    %eax,-0x10(%ebp)
        cnt = vcprintf(fmt, ap);
  80075d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  800760:	89 44 24 04          	mov    %eax,0x4(%esp)
  800764:	8b 45 08             	mov    0x8(%ebp),%eax
  800767:	89 04 24             	mov    %eax,(%esp)
  80076a:	e8 7d ff ff ff       	call   8006ec <vcprintf>
  80076f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  800772:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  800775:	c9                   	leave  
  800776:	c3                   	ret    
	...

00800778 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800778:	55                   	push   %ebp
  800779:	89 e5                	mov    %esp,%ebp
  80077b:	53                   	push   %ebx
  80077c:	83 ec 34             	sub    $0x34,%esp
  80077f:	8b 45 10             	mov    0x10(%ebp),%eax
  800782:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800785:	8b 45 14             	mov    0x14(%ebp),%eax
  800788:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80078b:	8b 45 18             	mov    0x18(%ebp),%eax
  80078e:	ba 00 00 00 00       	mov    $0x0,%edx
  800793:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  800796:	77 72                	ja     80080a <printnum+0x92>
  800798:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  80079b:	72 05                	jb     8007a2 <printnum+0x2a>
  80079d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  8007a0:	77 68                	ja     80080a <printnum+0x92>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8007a2:	8b 45 1c             	mov    0x1c(%ebp),%eax
  8007a5:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8007a8:	8b 45 18             	mov    0x18(%ebp),%eax
  8007ab:	ba 00 00 00 00       	mov    $0x0,%edx
  8007b0:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007b4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8007b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8007bb:	8b 55 f4             	mov    -0xc(%ebp),%edx
  8007be:	89 04 24             	mov    %eax,(%esp)
  8007c1:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007c5:	e8 66 2b 00 00       	call   803330 <__udivdi3>
  8007ca:	8b 4d 20             	mov    0x20(%ebp),%ecx
  8007cd:	89 4c 24 18          	mov    %ecx,0x18(%esp)
  8007d1:	89 5c 24 14          	mov    %ebx,0x14(%esp)
  8007d5:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8007d8:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8007dc:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007e0:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8007e4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8007e7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007eb:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ee:	89 04 24             	mov    %eax,(%esp)
  8007f1:	e8 82 ff ff ff       	call   800778 <printnum>
  8007f6:	eb 1c                	jmp    800814 <printnum+0x9c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8007f8:	8b 45 0c             	mov    0xc(%ebp),%eax
  8007fb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007ff:	8b 45 20             	mov    0x20(%ebp),%eax
  800802:	89 04 24             	mov    %eax,(%esp)
  800805:	8b 45 08             	mov    0x8(%ebp),%eax
  800808:	ff d0                	call   *%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80080a:	83 6d 1c 01          	subl   $0x1,0x1c(%ebp)
  80080e:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
  800812:	7f e4                	jg     8007f8 <printnum+0x80>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800814:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800817:	bb 00 00 00 00       	mov    $0x0,%ebx
  80081c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  80081f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  800822:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800826:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  80082a:	89 04 24             	mov    %eax,(%esp)
  80082d:	89 54 24 04          	mov    %edx,0x4(%esp)
  800831:	e8 0a 2c 00 00       	call   803440 <__umoddi3>
  800836:	05 c0 3a 80 00       	add    $0x803ac0,%eax
  80083b:	0f b6 00             	movzbl (%eax),%eax
  80083e:	0f be c0             	movsbl %al,%eax
  800841:	8b 55 0c             	mov    0xc(%ebp),%edx
  800844:	89 54 24 04          	mov    %edx,0x4(%esp)
  800848:	89 04 24             	mov    %eax,(%esp)
  80084b:	8b 45 08             	mov    0x8(%ebp),%eax
  80084e:	ff d0                	call   *%eax
}
  800850:	83 c4 34             	add    $0x34,%esp
  800853:	5b                   	pop    %ebx
  800854:	5d                   	pop    %ebp
  800855:	c3                   	ret    

00800856 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800856:	55                   	push   %ebp
  800857:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800859:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  80085d:	7e 14                	jle    800873 <getuint+0x1d>
		return va_arg(*ap, unsigned long long);
  80085f:	8b 45 08             	mov    0x8(%ebp),%eax
  800862:	8b 00                	mov    (%eax),%eax
  800864:	8d 48 08             	lea    0x8(%eax),%ecx
  800867:	8b 55 08             	mov    0x8(%ebp),%edx
  80086a:	89 0a                	mov    %ecx,(%edx)
  80086c:	8b 50 04             	mov    0x4(%eax),%edx
  80086f:	8b 00                	mov    (%eax),%eax
  800871:	eb 30                	jmp    8008a3 <getuint+0x4d>
	else if (lflag)
  800873:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800877:	74 16                	je     80088f <getuint+0x39>
		return va_arg(*ap, unsigned long);
  800879:	8b 45 08             	mov    0x8(%ebp),%eax
  80087c:	8b 00                	mov    (%eax),%eax
  80087e:	8d 48 04             	lea    0x4(%eax),%ecx
  800881:	8b 55 08             	mov    0x8(%ebp),%edx
  800884:	89 0a                	mov    %ecx,(%edx)
  800886:	8b 00                	mov    (%eax),%eax
  800888:	ba 00 00 00 00       	mov    $0x0,%edx
  80088d:	eb 14                	jmp    8008a3 <getuint+0x4d>
	else
		return va_arg(*ap, unsigned int);
  80088f:	8b 45 08             	mov    0x8(%ebp),%eax
  800892:	8b 00                	mov    (%eax),%eax
  800894:	8d 48 04             	lea    0x4(%eax),%ecx
  800897:	8b 55 08             	mov    0x8(%ebp),%edx
  80089a:	89 0a                	mov    %ecx,(%edx)
  80089c:	8b 00                	mov    (%eax),%eax
  80089e:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8008a3:	5d                   	pop    %ebp
  8008a4:	c3                   	ret    

008008a5 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  8008a5:	55                   	push   %ebp
  8008a6:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8008a8:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  8008ac:	7e 14                	jle    8008c2 <getint+0x1d>
		return va_arg(*ap, long long);
  8008ae:	8b 45 08             	mov    0x8(%ebp),%eax
  8008b1:	8b 00                	mov    (%eax),%eax
  8008b3:	8d 48 08             	lea    0x8(%eax),%ecx
  8008b6:	8b 55 08             	mov    0x8(%ebp),%edx
  8008b9:	89 0a                	mov    %ecx,(%edx)
  8008bb:	8b 50 04             	mov    0x4(%eax),%edx
  8008be:	8b 00                	mov    (%eax),%eax
  8008c0:	eb 30                	jmp    8008f2 <getint+0x4d>
	else if (lflag)
  8008c2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8008c6:	74 16                	je     8008de <getint+0x39>
		return va_arg(*ap, long);
  8008c8:	8b 45 08             	mov    0x8(%ebp),%eax
  8008cb:	8b 00                	mov    (%eax),%eax
  8008cd:	8d 48 04             	lea    0x4(%eax),%ecx
  8008d0:	8b 55 08             	mov    0x8(%ebp),%edx
  8008d3:	89 0a                	mov    %ecx,(%edx)
  8008d5:	8b 00                	mov    (%eax),%eax
  8008d7:	89 c2                	mov    %eax,%edx
  8008d9:	c1 fa 1f             	sar    $0x1f,%edx
  8008dc:	eb 14                	jmp    8008f2 <getint+0x4d>
	else
		return va_arg(*ap, int);
  8008de:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e1:	8b 00                	mov    (%eax),%eax
  8008e3:	8d 48 04             	lea    0x4(%eax),%ecx
  8008e6:	8b 55 08             	mov    0x8(%ebp),%edx
  8008e9:	89 0a                	mov    %ecx,(%edx)
  8008eb:	8b 00                	mov    (%eax),%eax
  8008ed:	89 c2                	mov    %eax,%edx
  8008ef:	c1 fa 1f             	sar    $0x1f,%edx
}
  8008f2:	5d                   	pop    %ebp
  8008f3:	c3                   	ret    

008008f4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8008f4:	55                   	push   %ebp
  8008f5:	89 e5                	mov    %esp,%ebp
  8008f7:	56                   	push   %esi
  8008f8:	53                   	push   %ebx
  8008f9:	83 ec 40             	sub    $0x40,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8008fc:	eb 17                	jmp    800915 <vprintfmt+0x21>
			if (ch == '\0')
  8008fe:	85 db                	test   %ebx,%ebx
  800900:	0f 84 db 03 00 00    	je     800ce1 <vprintfmt+0x3ed>
				return;
			putch(ch, putdat);
  800906:	8b 45 0c             	mov    0xc(%ebp),%eax
  800909:	89 44 24 04          	mov    %eax,0x4(%esp)
  80090d:	89 1c 24             	mov    %ebx,(%esp)
  800910:	8b 45 08             	mov    0x8(%ebp),%eax
  800913:	ff d0                	call   *%eax
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800915:	8b 45 10             	mov    0x10(%ebp),%eax
  800918:	0f b6 00             	movzbl (%eax),%eax
  80091b:	0f b6 d8             	movzbl %al,%ebx
  80091e:	83 fb 25             	cmp    $0x25,%ebx
  800921:	0f 95 c0             	setne  %al
  800924:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  800928:	84 c0                	test   %al,%al
  80092a:	75 d2                	jne    8008fe <vprintfmt+0xa>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
  80092c:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
		width = -1;
  800930:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
		precision = -1;
  800937:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
  80093e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
		altflag = 0;
  800945:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  80094c:	eb 04                	jmp    800952 <vprintfmt+0x5e>
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
			goto reswitch;
  80094e:	90                   	nop
  80094f:	eb 01                	jmp    800952 <vprintfmt+0x5e>
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
			goto reswitch;
  800951:	90                   	nop
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800952:	8b 45 10             	mov    0x10(%ebp),%eax
  800955:	0f b6 00             	movzbl (%eax),%eax
  800958:	0f b6 d8             	movzbl %al,%ebx
  80095b:	89 d8                	mov    %ebx,%eax
  80095d:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  800961:	83 e8 23             	sub    $0x23,%eax
  800964:	83 f8 55             	cmp    $0x55,%eax
  800967:	0f 87 43 03 00 00    	ja     800cb0 <vprintfmt+0x3bc>
  80096d:	8b 04 85 e4 3a 80 00 	mov    0x803ae4(,%eax,4),%eax
  800974:	ff e0                	jmp    *%eax

		// flag to pad on the right
		case '-':
			padc = '-';
  800976:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
			goto reswitch;
  80097a:	eb d6                	jmp    800952 <vprintfmt+0x5e>
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80097c:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
			goto reswitch;
  800980:	eb d0                	jmp    800952 <vprintfmt+0x5e>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800982:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
				precision = precision * 10 + ch - '0';
  800989:	8b 55 e0             	mov    -0x20(%ebp),%edx
  80098c:	89 d0                	mov    %edx,%eax
  80098e:	c1 e0 02             	shl    $0x2,%eax
  800991:	01 d0                	add    %edx,%eax
  800993:	01 c0                	add    %eax,%eax
  800995:	01 d8                	add    %ebx,%eax
  800997:	83 e8 30             	sub    $0x30,%eax
  80099a:	89 45 e0             	mov    %eax,-0x20(%ebp)
				ch = *fmt;
  80099d:	8b 45 10             	mov    0x10(%ebp),%eax
  8009a0:	0f b6 00             	movzbl (%eax),%eax
  8009a3:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  8009a6:	83 fb 2f             	cmp    $0x2f,%ebx
  8009a9:	7e 39                	jle    8009e4 <vprintfmt+0xf0>
  8009ab:	83 fb 39             	cmp    $0x39,%ebx
  8009ae:	7f 37                	jg     8009e7 <vprintfmt+0xf3>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8009b0:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8009b4:	eb d3                	jmp    800989 <vprintfmt+0x95>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8009b6:	8b 45 14             	mov    0x14(%ebp),%eax
  8009b9:	8d 50 04             	lea    0x4(%eax),%edx
  8009bc:	89 55 14             	mov    %edx,0x14(%ebp)
  8009bf:	8b 00                	mov    (%eax),%eax
  8009c1:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto process_precision;
  8009c4:	eb 22                	jmp    8009e8 <vprintfmt+0xf4>

		case '.':
			if (width < 0)
  8009c6:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8009ca:	79 82                	jns    80094e <vprintfmt+0x5a>
				width = 0;
  8009cc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			goto reswitch;
  8009d3:	e9 7a ff ff ff       	jmp    800952 <vprintfmt+0x5e>

		case '#':
			altflag = 1;
  8009d8:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
  8009df:	e9 6e ff ff ff       	jmp    800952 <vprintfmt+0x5e>
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto process_precision;
  8009e4:	90                   	nop
  8009e5:	eb 01                	jmp    8009e8 <vprintfmt+0xf4>
  8009e7:	90                   	nop
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  8009e8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8009ec:	0f 89 5f ff ff ff    	jns    800951 <vprintfmt+0x5d>
				width = precision, precision = -1;
  8009f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8009f5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8009f8:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
			goto reswitch;
  8009ff:	e9 4e ff ff ff       	jmp    800952 <vprintfmt+0x5e>

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800a04:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
			goto reswitch;
  800a08:	e9 45 ff ff ff       	jmp    800952 <vprintfmt+0x5e>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800a0d:	8b 45 14             	mov    0x14(%ebp),%eax
  800a10:	8d 50 04             	lea    0x4(%eax),%edx
  800a13:	89 55 14             	mov    %edx,0x14(%ebp)
  800a16:	8b 00                	mov    (%eax),%eax
  800a18:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a1b:	89 54 24 04          	mov    %edx,0x4(%esp)
  800a1f:	89 04 24             	mov    %eax,(%esp)
  800a22:	8b 45 08             	mov    0x8(%ebp),%eax
  800a25:	ff d0                	call   *%eax
			break;
  800a27:	e9 af 02 00 00       	jmp    800cdb <vprintfmt+0x3e7>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800a2c:	8b 45 14             	mov    0x14(%ebp),%eax
  800a2f:	8d 50 04             	lea    0x4(%eax),%edx
  800a32:	89 55 14             	mov    %edx,0x14(%ebp)
  800a35:	8b 18                	mov    (%eax),%ebx
			if (err < 0)
  800a37:	85 db                	test   %ebx,%ebx
  800a39:	79 02                	jns    800a3d <vprintfmt+0x149>
				err = -err;
  800a3b:	f7 db                	neg    %ebx
			if (err > MAXERROR || (p = error_string[err]) == NULL)
  800a3d:	83 fb 0f             	cmp    $0xf,%ebx
  800a40:	7f 0b                	jg     800a4d <vprintfmt+0x159>
  800a42:	8b 34 9d 80 3a 80 00 	mov    0x803a80(,%ebx,4),%esi
  800a49:	85 f6                	test   %esi,%esi
  800a4b:	75 23                	jne    800a70 <vprintfmt+0x17c>
				printfmt(putch, putdat, "error %d", err);
  800a4d:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800a51:	c7 44 24 08 d1 3a 80 	movl   $0x803ad1,0x8(%esp)
  800a58:	00 
  800a59:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a5c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a60:	8b 45 08             	mov    0x8(%ebp),%eax
  800a63:	89 04 24             	mov    %eax,(%esp)
  800a66:	e8 7d 02 00 00       	call   800ce8 <printfmt>
			else
				printfmt(putch, putdat, "%s", p);
			break;
  800a6b:	e9 6b 02 00 00       	jmp    800cdb <vprintfmt+0x3e7>
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
  800a70:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800a74:	c7 44 24 08 da 3a 80 	movl   $0x803ada,0x8(%esp)
  800a7b:	00 
  800a7c:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a7f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a83:	8b 45 08             	mov    0x8(%ebp),%eax
  800a86:	89 04 24             	mov    %eax,(%esp)
  800a89:	e8 5a 02 00 00       	call   800ce8 <printfmt>
			break;
  800a8e:	e9 48 02 00 00       	jmp    800cdb <vprintfmt+0x3e7>

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800a93:	8b 45 14             	mov    0x14(%ebp),%eax
  800a96:	8d 50 04             	lea    0x4(%eax),%edx
  800a99:	89 55 14             	mov    %edx,0x14(%ebp)
  800a9c:	8b 30                	mov    (%eax),%esi
  800a9e:	85 f6                	test   %esi,%esi
  800aa0:	75 05                	jne    800aa7 <vprintfmt+0x1b3>
				p = "(null)";
  800aa2:	be dd 3a 80 00       	mov    $0x803add,%esi
			if (width > 0 && padc != '-')
  800aa7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800aab:	7e 73                	jle    800b20 <vprintfmt+0x22c>
  800aad:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
  800ab1:	74 70                	je     800b23 <vprintfmt+0x22f>
				for (width -= strnlen(p, precision); width > 0; width--)
  800ab3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800ab6:	89 44 24 04          	mov    %eax,0x4(%esp)
  800aba:	89 34 24             	mov    %esi,(%esp)
  800abd:	e8 44 03 00 00       	call   800e06 <strnlen>
  800ac2:	29 45 e4             	sub    %eax,-0x1c(%ebp)
  800ac5:	eb 17                	jmp    800ade <vprintfmt+0x1ea>
					putch(padc, putdat);
  800ac7:	0f be 45 db          	movsbl -0x25(%ebp),%eax
  800acb:	8b 55 0c             	mov    0xc(%ebp),%edx
  800ace:	89 54 24 04          	mov    %edx,0x4(%esp)
  800ad2:	89 04 24             	mov    %eax,(%esp)
  800ad5:	8b 45 08             	mov    0x8(%ebp),%eax
  800ad8:	ff d0                	call   *%eax
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800ada:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
  800ade:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800ae2:	7f e3                	jg     800ac7 <vprintfmt+0x1d3>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800ae4:	eb 3e                	jmp    800b24 <vprintfmt+0x230>
				if (altflag && (ch < ' ' || ch > '~'))
  800ae6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800aea:	74 1f                	je     800b0b <vprintfmt+0x217>
  800aec:	83 fb 1f             	cmp    $0x1f,%ebx
  800aef:	7e 05                	jle    800af6 <vprintfmt+0x202>
  800af1:	83 fb 7e             	cmp    $0x7e,%ebx
  800af4:	7e 15                	jle    800b0b <vprintfmt+0x217>
					putch('?', putdat);
  800af6:	8b 45 0c             	mov    0xc(%ebp),%eax
  800af9:	89 44 24 04          	mov    %eax,0x4(%esp)
  800afd:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800b04:	8b 45 08             	mov    0x8(%ebp),%eax
  800b07:	ff d0                	call   *%eax
  800b09:	eb 0f                	jmp    800b1a <vprintfmt+0x226>
				else
					putch(ch, putdat);
  800b0b:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b0e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b12:	89 1c 24             	mov    %ebx,(%esp)
  800b15:	8b 45 08             	mov    0x8(%ebp),%eax
  800b18:	ff d0                	call   *%eax
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800b1a:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
  800b1e:	eb 04                	jmp    800b24 <vprintfmt+0x230>
  800b20:	90                   	nop
  800b21:	eb 01                	jmp    800b24 <vprintfmt+0x230>
  800b23:	90                   	nop
  800b24:	0f b6 06             	movzbl (%esi),%eax
  800b27:	0f be d8             	movsbl %al,%ebx
  800b2a:	85 db                	test   %ebx,%ebx
  800b2c:	0f 95 c0             	setne  %al
  800b2f:	83 c6 01             	add    $0x1,%esi
  800b32:	84 c0                	test   %al,%al
  800b34:	74 29                	je     800b5f <vprintfmt+0x26b>
  800b36:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800b3a:	78 aa                	js     800ae6 <vprintfmt+0x1f2>
  800b3c:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
  800b40:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800b44:	79 a0                	jns    800ae6 <vprintfmt+0x1f2>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800b46:	eb 17                	jmp    800b5f <vprintfmt+0x26b>
				putch(' ', putdat);
  800b48:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b4b:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b4f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800b56:	8b 45 08             	mov    0x8(%ebp),%eax
  800b59:	ff d0                	call   *%eax
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800b5b:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
  800b5f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800b63:	7f e3                	jg     800b48 <vprintfmt+0x254>
				putch(' ', putdat);
			break;
  800b65:	e9 71 01 00 00       	jmp    800cdb <vprintfmt+0x3e7>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800b6a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  800b6d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b71:	8d 45 14             	lea    0x14(%ebp),%eax
  800b74:	89 04 24             	mov    %eax,(%esp)
  800b77:	e8 29 fd ff ff       	call   8008a5 <getint>
  800b7c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800b7f:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((long long) num < 0) {
  800b82:	8b 45 f0             	mov    -0x10(%ebp),%eax
  800b85:	8b 55 f4             	mov    -0xc(%ebp),%edx
  800b88:	85 d2                	test   %edx,%edx
  800b8a:	79 26                	jns    800bb2 <vprintfmt+0x2be>
				putch('-', putdat);
  800b8c:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b8f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b93:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800b9a:	8b 45 08             	mov    0x8(%ebp),%eax
  800b9d:	ff d0                	call   *%eax
				num = -(long long) num;
  800b9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  800ba2:	8b 55 f4             	mov    -0xc(%ebp),%edx
  800ba5:	f7 d8                	neg    %eax
  800ba7:	83 d2 00             	adc    $0x0,%edx
  800baa:	f7 da                	neg    %edx
  800bac:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800baf:	89 55 f4             	mov    %edx,-0xc(%ebp)
			}
			base = 10;
  800bb2:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
  800bb9:	e9 a9 00 00 00       	jmp    800c67 <vprintfmt+0x373>

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800bbe:	8b 45 e8             	mov    -0x18(%ebp),%eax
  800bc1:	89 44 24 04          	mov    %eax,0x4(%esp)
  800bc5:	8d 45 14             	lea    0x14(%ebp),%eax
  800bc8:	89 04 24             	mov    %eax,(%esp)
  800bcb:	e8 86 fc ff ff       	call   800856 <getuint>
  800bd0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800bd3:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 10;
  800bd6:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
  800bdd:	e9 85 00 00 00       	jmp    800c67 <vprintfmt+0x373>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800be2:	8b 45 e8             	mov    -0x18(%ebp),%eax
  800be5:	89 44 24 04          	mov    %eax,0x4(%esp)
  800be9:	8d 45 14             	lea    0x14(%ebp),%eax
  800bec:	89 04 24             	mov    %eax,(%esp)
  800bef:	e8 62 fc ff ff       	call   800856 <getuint>
  800bf4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800bf7:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 8;
  800bfa:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
			goto number;
  800c01:	eb 64                	jmp    800c67 <vprintfmt+0x373>
			// putch('X', putdat);
			// break;

		// pointer
		case 'p':
			putch('0', putdat);
  800c03:	8b 45 0c             	mov    0xc(%ebp),%eax
  800c06:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c0a:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800c11:	8b 45 08             	mov    0x8(%ebp),%eax
  800c14:	ff d0                	call   *%eax
			putch('x', putdat);
  800c16:	8b 45 0c             	mov    0xc(%ebp),%eax
  800c19:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c1d:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800c24:	8b 45 08             	mov    0x8(%ebp),%eax
  800c27:	ff d0                	call   *%eax
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800c29:	8b 45 14             	mov    0x14(%ebp),%eax
  800c2c:	8d 50 04             	lea    0x4(%eax),%edx
  800c2f:	89 55 14             	mov    %edx,0x14(%ebp)
  800c32:	8b 00                	mov    (%eax),%eax

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800c34:	ba 00 00 00 00       	mov    $0x0,%edx
  800c39:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800c3c:	89 55 f4             	mov    %edx,-0xc(%ebp)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800c3f:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
			goto number;
  800c46:	eb 1f                	jmp    800c67 <vprintfmt+0x373>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800c48:	8b 45 e8             	mov    -0x18(%ebp),%eax
  800c4b:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c4f:	8d 45 14             	lea    0x14(%ebp),%eax
  800c52:	89 04 24             	mov    %eax,(%esp)
  800c55:	e8 fc fb ff ff       	call   800856 <getuint>
  800c5a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800c5d:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 16;
  800c60:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
		number:
			printnum(putch, putdat, num, base, width, padc);
  800c67:	0f be 55 db          	movsbl -0x25(%ebp),%edx
  800c6b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800c6e:	89 54 24 18          	mov    %edx,0x18(%esp)
  800c72:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800c75:	89 54 24 14          	mov    %edx,0x14(%esp)
  800c79:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  800c80:	8b 55 f4             	mov    -0xc(%ebp),%edx
  800c83:	89 44 24 08          	mov    %eax,0x8(%esp)
  800c87:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800c8b:	8b 45 0c             	mov    0xc(%ebp),%eax
  800c8e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c92:	8b 45 08             	mov    0x8(%ebp),%eax
  800c95:	89 04 24             	mov    %eax,(%esp)
  800c98:	e8 db fa ff ff       	call   800778 <printnum>
			break;
  800c9d:	eb 3c                	jmp    800cdb <vprintfmt+0x3e7>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800c9f:	8b 45 0c             	mov    0xc(%ebp),%eax
  800ca2:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ca6:	89 1c 24             	mov    %ebx,(%esp)
  800ca9:	8b 45 08             	mov    0x8(%ebp),%eax
  800cac:	ff d0                	call   *%eax
			break;
  800cae:	eb 2b                	jmp    800cdb <vprintfmt+0x3e7>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800cb0:	8b 45 0c             	mov    0xc(%ebp),%eax
  800cb3:	89 44 24 04          	mov    %eax,0x4(%esp)
  800cb7:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800cbe:	8b 45 08             	mov    0x8(%ebp),%eax
  800cc1:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  800cc3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  800cc7:	eb 04                	jmp    800ccd <vprintfmt+0x3d9>
  800cc9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  800ccd:	8b 45 10             	mov    0x10(%ebp),%eax
  800cd0:	83 e8 01             	sub    $0x1,%eax
  800cd3:	0f b6 00             	movzbl (%eax),%eax
  800cd6:	3c 25                	cmp    $0x25,%al
  800cd8:	75 ef                	jne    800cc9 <vprintfmt+0x3d5>
				/* do nothing */;
			break;
  800cda:	90                   	nop
		}
	}
  800cdb:	90                   	nop
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800cdc:	e9 34 fc ff ff       	jmp    800915 <vprintfmt+0x21>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  800ce1:	83 c4 40             	add    $0x40,%esp
  800ce4:	5b                   	pop    %ebx
  800ce5:	5e                   	pop    %esi
  800ce6:	5d                   	pop    %ebp
  800ce7:	c3                   	ret    

00800ce8 <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800ce8:	55                   	push   %ebp
  800ce9:	89 e5                	mov    %esp,%ebp
  800ceb:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  800cee:	8d 45 14             	lea    0x14(%ebp),%eax
  800cf1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	vprintfmt(putch, putdat, fmt, ap);
  800cf4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800cf7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800cfb:	8b 45 10             	mov    0x10(%ebp),%eax
  800cfe:	89 44 24 08          	mov    %eax,0x8(%esp)
  800d02:	8b 45 0c             	mov    0xc(%ebp),%eax
  800d05:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d09:	8b 45 08             	mov    0x8(%ebp),%eax
  800d0c:	89 04 24             	mov    %eax,(%esp)
  800d0f:	e8 e0 fb ff ff       	call   8008f4 <vprintfmt>
	va_end(ap);
}
  800d14:	c9                   	leave  
  800d15:	c3                   	ret    

00800d16 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800d16:	55                   	push   %ebp
  800d17:	89 e5                	mov    %esp,%ebp
	b->cnt++;
  800d19:	8b 45 0c             	mov    0xc(%ebp),%eax
  800d1c:	8b 40 08             	mov    0x8(%eax),%eax
  800d1f:	8d 50 01             	lea    0x1(%eax),%edx
  800d22:	8b 45 0c             	mov    0xc(%ebp),%eax
  800d25:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
  800d28:	8b 45 0c             	mov    0xc(%ebp),%eax
  800d2b:	8b 10                	mov    (%eax),%edx
  800d2d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800d30:	8b 40 04             	mov    0x4(%eax),%eax
  800d33:	39 c2                	cmp    %eax,%edx
  800d35:	73 12                	jae    800d49 <sprintputch+0x33>
		*b->buf++ = ch;
  800d37:	8b 45 0c             	mov    0xc(%ebp),%eax
  800d3a:	8b 00                	mov    (%eax),%eax
  800d3c:	8b 55 08             	mov    0x8(%ebp),%edx
  800d3f:	88 10                	mov    %dl,(%eax)
  800d41:	8d 50 01             	lea    0x1(%eax),%edx
  800d44:	8b 45 0c             	mov    0xc(%ebp),%eax
  800d47:	89 10                	mov    %edx,(%eax)
}
  800d49:	5d                   	pop    %ebp
  800d4a:	c3                   	ret    

00800d4b <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800d4b:	55                   	push   %ebp
  800d4c:	89 e5                	mov    %esp,%ebp
  800d4e:	83 ec 28             	sub    $0x28,%esp
	struct sprintbuf b = {buf, buf+n-1, 0};
  800d51:	8b 45 0c             	mov    0xc(%ebp),%eax
  800d54:	83 e8 01             	sub    $0x1,%eax
  800d57:	03 45 08             	add    0x8(%ebp),%eax
  800d5a:	8b 55 08             	mov    0x8(%ebp),%edx
  800d5d:	89 55 ec             	mov    %edx,-0x14(%ebp)
  800d60:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800d63:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800d6a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  800d6e:	74 06                	je     800d76 <vsnprintf+0x2b>
  800d70:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800d74:	7f 07                	jg     800d7d <vsnprintf+0x32>
		return -E_INVAL;
  800d76:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  800d7b:	eb 2b                	jmp    800da8 <vsnprintf+0x5d>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800d7d:	b8 16 0d 80 00       	mov    $0x800d16,%eax
  800d82:	8b 55 14             	mov    0x14(%ebp),%edx
  800d85:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800d89:	8b 55 10             	mov    0x10(%ebp),%edx
  800d8c:	89 54 24 08          	mov    %edx,0x8(%esp)
  800d90:	8d 55 ec             	lea    -0x14(%ebp),%edx
  800d93:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d97:	89 04 24             	mov    %eax,(%esp)
  800d9a:	e8 55 fb ff ff       	call   8008f4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800d9f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800da2:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800da5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  800da8:	c9                   	leave  
  800da9:	c3                   	ret    

00800daa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800daa:	55                   	push   %ebp
  800dab:	89 e5                	mov    %esp,%ebp
  800dad:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800db0:	8d 45 14             	lea    0x14(%ebp),%eax
  800db3:	89 45 f0             	mov    %eax,-0x10(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
  800db6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  800db9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800dbd:	8b 45 10             	mov    0x10(%ebp),%eax
  800dc0:	89 44 24 08          	mov    %eax,0x8(%esp)
  800dc4:	8b 45 0c             	mov    0xc(%ebp),%eax
  800dc7:	89 44 24 04          	mov    %eax,0x4(%esp)
  800dcb:	8b 45 08             	mov    0x8(%ebp),%eax
  800dce:	89 04 24             	mov    %eax,(%esp)
  800dd1:	e8 75 ff ff ff       	call   800d4b <vsnprintf>
  800dd6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return rc;
  800dd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  800ddc:	c9                   	leave  
  800ddd:	c3                   	ret    
	...

00800de0 <strlen>:
// #define ASM 1
#define ASM 0

int
strlen(const char *s)
{
  800de0:	55                   	push   %ebp
  800de1:	89 e5                	mov    %esp,%ebp
  800de3:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  800de6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  800ded:	eb 08                	jmp    800df7 <strlen+0x17>
		n++;
  800def:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800df3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  800df7:	8b 45 08             	mov    0x8(%ebp),%eax
  800dfa:	0f b6 00             	movzbl (%eax),%eax
  800dfd:	84 c0                	test   %al,%al
  800dff:	75 ee                	jne    800def <strlen+0xf>
		n++;
	return n;
  800e01:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  800e04:	c9                   	leave  
  800e05:	c3                   	ret    

00800e06 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800e06:	55                   	push   %ebp
  800e07:	89 e5                	mov    %esp,%ebp
  800e09:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800e0c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  800e13:	eb 0c                	jmp    800e21 <strnlen+0x1b>
		n++;
  800e15:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800e19:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  800e1d:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
  800e21:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800e25:	74 0a                	je     800e31 <strnlen+0x2b>
  800e27:	8b 45 08             	mov    0x8(%ebp),%eax
  800e2a:	0f b6 00             	movzbl (%eax),%eax
  800e2d:	84 c0                	test   %al,%al
  800e2f:	75 e4                	jne    800e15 <strnlen+0xf>
		n++;
	return n;
  800e31:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  800e34:	c9                   	leave  
  800e35:	c3                   	ret    

00800e36 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800e36:	55                   	push   %ebp
  800e37:	89 e5                	mov    %esp,%ebp
  800e39:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  800e3c:	8b 45 08             	mov    0x8(%ebp),%eax
  800e3f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  800e42:	90                   	nop
  800e43:	8b 45 0c             	mov    0xc(%ebp),%eax
  800e46:	0f b6 10             	movzbl (%eax),%edx
  800e49:	8b 45 08             	mov    0x8(%ebp),%eax
  800e4c:	88 10                	mov    %dl,(%eax)
  800e4e:	8b 45 08             	mov    0x8(%ebp),%eax
  800e51:	0f b6 00             	movzbl (%eax),%eax
  800e54:	84 c0                	test   %al,%al
  800e56:	0f 95 c0             	setne  %al
  800e59:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  800e5d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  800e61:	84 c0                	test   %al,%al
  800e63:	75 de                	jne    800e43 <strcpy+0xd>
		/* do nothing */;
	return ret;
  800e65:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  800e68:	c9                   	leave  
  800e69:	c3                   	ret    

00800e6a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800e6a:	55                   	push   %ebp
  800e6b:	89 e5                	mov    %esp,%ebp
  800e6d:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  800e70:	8b 45 08             	mov    0x8(%ebp),%eax
  800e73:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
  800e76:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  800e7d:	eb 21                	jmp    800ea0 <strncpy+0x36>
		*dst++ = *src;
  800e7f:	8b 45 0c             	mov    0xc(%ebp),%eax
  800e82:	0f b6 10             	movzbl (%eax),%edx
  800e85:	8b 45 08             	mov    0x8(%ebp),%eax
  800e88:	88 10                	mov    %dl,(%eax)
  800e8a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  800e8e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800e91:	0f b6 00             	movzbl (%eax),%eax
  800e94:	84 c0                	test   %al,%al
  800e96:	74 04                	je     800e9c <strncpy+0x32>
			src++;
  800e98:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800e9c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  800ea0:	8b 45 fc             	mov    -0x4(%ebp),%eax
  800ea3:	3b 45 10             	cmp    0x10(%ebp),%eax
  800ea6:	72 d7                	jb     800e7f <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  800ea8:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  800eab:	c9                   	leave  
  800eac:	c3                   	ret    

00800ead <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800ead:	55                   	push   %ebp
  800eae:	89 e5                	mov    %esp,%ebp
  800eb0:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  800eb3:	8b 45 08             	mov    0x8(%ebp),%eax
  800eb6:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  800eb9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  800ebd:	74 2f                	je     800eee <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  800ebf:	eb 13                	jmp    800ed4 <strlcpy+0x27>
			*dst++ = *src++;
  800ec1:	8b 45 0c             	mov    0xc(%ebp),%eax
  800ec4:	0f b6 10             	movzbl (%eax),%edx
  800ec7:	8b 45 08             	mov    0x8(%ebp),%eax
  800eca:	88 10                	mov    %dl,(%eax)
  800ecc:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  800ed0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800ed4:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  800ed8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  800edc:	74 0a                	je     800ee8 <strlcpy+0x3b>
  800ede:	8b 45 0c             	mov    0xc(%ebp),%eax
  800ee1:	0f b6 00             	movzbl (%eax),%eax
  800ee4:	84 c0                	test   %al,%al
  800ee6:	75 d9                	jne    800ec1 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  800ee8:	8b 45 08             	mov    0x8(%ebp),%eax
  800eeb:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800eee:	8b 55 08             	mov    0x8(%ebp),%edx
  800ef1:	8b 45 fc             	mov    -0x4(%ebp),%eax
  800ef4:	89 d1                	mov    %edx,%ecx
  800ef6:	29 c1                	sub    %eax,%ecx
  800ef8:	89 c8                	mov    %ecx,%eax
}
  800efa:	c9                   	leave  
  800efb:	c3                   	ret    

00800efc <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800efc:	55                   	push   %ebp
  800efd:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  800eff:	eb 08                	jmp    800f09 <strcmp+0xd>
		p++, q++;
  800f01:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  800f05:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800f09:	8b 45 08             	mov    0x8(%ebp),%eax
  800f0c:	0f b6 00             	movzbl (%eax),%eax
  800f0f:	84 c0                	test   %al,%al
  800f11:	74 10                	je     800f23 <strcmp+0x27>
  800f13:	8b 45 08             	mov    0x8(%ebp),%eax
  800f16:	0f b6 10             	movzbl (%eax),%edx
  800f19:	8b 45 0c             	mov    0xc(%ebp),%eax
  800f1c:	0f b6 00             	movzbl (%eax),%eax
  800f1f:	38 c2                	cmp    %al,%dl
  800f21:	74 de                	je     800f01 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800f23:	8b 45 08             	mov    0x8(%ebp),%eax
  800f26:	0f b6 00             	movzbl (%eax),%eax
  800f29:	0f b6 d0             	movzbl %al,%edx
  800f2c:	8b 45 0c             	mov    0xc(%ebp),%eax
  800f2f:	0f b6 00             	movzbl (%eax),%eax
  800f32:	0f b6 c0             	movzbl %al,%eax
  800f35:	89 d1                	mov    %edx,%ecx
  800f37:	29 c1                	sub    %eax,%ecx
  800f39:	89 c8                	mov    %ecx,%eax
}
  800f3b:	5d                   	pop    %ebp
  800f3c:	c3                   	ret    

00800f3d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800f3d:	55                   	push   %ebp
  800f3e:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  800f40:	eb 0c                	jmp    800f4e <strncmp+0x11>
		n--, p++, q++;
  800f42:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  800f46:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  800f4a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800f4e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  800f52:	74 1a                	je     800f6e <strncmp+0x31>
  800f54:	8b 45 08             	mov    0x8(%ebp),%eax
  800f57:	0f b6 00             	movzbl (%eax),%eax
  800f5a:	84 c0                	test   %al,%al
  800f5c:	74 10                	je     800f6e <strncmp+0x31>
  800f5e:	8b 45 08             	mov    0x8(%ebp),%eax
  800f61:	0f b6 10             	movzbl (%eax),%edx
  800f64:	8b 45 0c             	mov    0xc(%ebp),%eax
  800f67:	0f b6 00             	movzbl (%eax),%eax
  800f6a:	38 c2                	cmp    %al,%dl
  800f6c:	74 d4                	je     800f42 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  800f6e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  800f72:	75 07                	jne    800f7b <strncmp+0x3e>
		return 0;
  800f74:	b8 00 00 00 00       	mov    $0x0,%eax
  800f79:	eb 18                	jmp    800f93 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800f7b:	8b 45 08             	mov    0x8(%ebp),%eax
  800f7e:	0f b6 00             	movzbl (%eax),%eax
  800f81:	0f b6 d0             	movzbl %al,%edx
  800f84:	8b 45 0c             	mov    0xc(%ebp),%eax
  800f87:	0f b6 00             	movzbl (%eax),%eax
  800f8a:	0f b6 c0             	movzbl %al,%eax
  800f8d:	89 d1                	mov    %edx,%ecx
  800f8f:	29 c1                	sub    %eax,%ecx
  800f91:	89 c8                	mov    %ecx,%eax
}
  800f93:	5d                   	pop    %ebp
  800f94:	c3                   	ret    

00800f95 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800f95:	55                   	push   %ebp
  800f96:	89 e5                	mov    %esp,%ebp
  800f98:	83 ec 04             	sub    $0x4,%esp
  800f9b:	8b 45 0c             	mov    0xc(%ebp),%eax
  800f9e:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
  800fa1:	eb 14                	jmp    800fb7 <strchr+0x22>
		if (*s == c)
  800fa3:	8b 45 08             	mov    0x8(%ebp),%eax
  800fa6:	0f b6 00             	movzbl (%eax),%eax
  800fa9:	3a 45 fc             	cmp    -0x4(%ebp),%al
  800fac:	75 05                	jne    800fb3 <strchr+0x1e>
			return (char *) s;
  800fae:	8b 45 08             	mov    0x8(%ebp),%eax
  800fb1:	eb 13                	jmp    800fc6 <strchr+0x31>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800fb3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  800fb7:	8b 45 08             	mov    0x8(%ebp),%eax
  800fba:	0f b6 00             	movzbl (%eax),%eax
  800fbd:	84 c0                	test   %al,%al
  800fbf:	75 e2                	jne    800fa3 <strchr+0xe>
		if (*s == c)
			return (char *) s;
	return 0;
  800fc1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800fc6:	c9                   	leave  
  800fc7:	c3                   	ret    

00800fc8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800fc8:	55                   	push   %ebp
  800fc9:	89 e5                	mov    %esp,%ebp
  800fcb:	83 ec 04             	sub    $0x4,%esp
  800fce:	8b 45 0c             	mov    0xc(%ebp),%eax
  800fd1:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
  800fd4:	eb 0f                	jmp    800fe5 <strfind+0x1d>
		if (*s == c)
  800fd6:	8b 45 08             	mov    0x8(%ebp),%eax
  800fd9:	0f b6 00             	movzbl (%eax),%eax
  800fdc:	3a 45 fc             	cmp    -0x4(%ebp),%al
  800fdf:	74 10                	je     800ff1 <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800fe1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  800fe5:	8b 45 08             	mov    0x8(%ebp),%eax
  800fe8:	0f b6 00             	movzbl (%eax),%eax
  800feb:	84 c0                	test   %al,%al
  800fed:	75 e7                	jne    800fd6 <strfind+0xe>
  800fef:	eb 01                	jmp    800ff2 <strfind+0x2a>
		if (*s == c)
			break;
  800ff1:	90                   	nop
	return (char *) s;
  800ff2:	8b 45 08             	mov    0x8(%ebp),%eax
}
  800ff5:	c9                   	leave  
  800ff6:	c3                   	ret    

00800ff7 <memset>:

#else

void *
memset(void *v, int c, size_t n)
{
  800ff7:	55                   	push   %ebp
  800ff8:	89 e5                	mov    %esp,%ebp
  800ffa:	83 ec 10             	sub    $0x10,%esp
	char *p;
	int m;

	p = v;
  800ffd:	8b 45 08             	mov    0x8(%ebp),%eax
  801000:	89 45 fc             	mov    %eax,-0x4(%ebp)
	m = n;
  801003:	8b 45 10             	mov    0x10(%ebp),%eax
  801006:	89 45 f8             	mov    %eax,-0x8(%ebp)
	while (--m >= 0)
  801009:	eb 0e                	jmp    801019 <memset+0x22>
		*p++ = c;
  80100b:	8b 45 0c             	mov    0xc(%ebp),%eax
  80100e:	89 c2                	mov    %eax,%edx
  801010:	8b 45 fc             	mov    -0x4(%ebp),%eax
  801013:	88 10                	mov    %dl,(%eax)
  801015:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
  801019:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
  80101d:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
  801021:	79 e8                	jns    80100b <memset+0x14>
		*p++ = c;

	return v;
  801023:	8b 45 08             	mov    0x8(%ebp),%eax
}
  801026:	c9                   	leave  
  801027:	c3                   	ret    

00801028 <memmove>:

/* no memcpy - use memmove instead */

void *
memmove(void *dst, const void *src, size_t n)
{
  801028:	55                   	push   %ebp
  801029:	89 e5                	mov    %esp,%ebp
  80102b:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  80102e:	8b 45 0c             	mov    0xc(%ebp),%eax
  801031:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
  801034:	8b 45 08             	mov    0x8(%ebp),%eax
  801037:	89 45 f8             	mov    %eax,-0x8(%ebp)
	if (s < d && s + n > d) {
  80103a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  80103d:	3b 45 f8             	cmp    -0x8(%ebp),%eax
  801040:	73 55                	jae    801097 <memmove+0x6f>
  801042:	8b 45 10             	mov    0x10(%ebp),%eax
  801045:	8b 55 fc             	mov    -0x4(%ebp),%edx
  801048:	8d 04 02             	lea    (%edx,%eax,1),%eax
  80104b:	3b 45 f8             	cmp    -0x8(%ebp),%eax
  80104e:	76 4a                	jbe    80109a <memmove+0x72>
		s += n;
  801050:	8b 45 10             	mov    0x10(%ebp),%eax
  801053:	01 45 fc             	add    %eax,-0x4(%ebp)
		d += n;
  801056:	8b 45 10             	mov    0x10(%ebp),%eax
  801059:	01 45 f8             	add    %eax,-0x8(%ebp)
		while (n-- > 0)
  80105c:	eb 13                	jmp    801071 <memmove+0x49>
			*--d = *--s;
  80105e:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
  801062:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
  801066:	8b 45 fc             	mov    -0x4(%ebp),%eax
  801069:	0f b6 10             	movzbl (%eax),%edx
  80106c:	8b 45 f8             	mov    -0x8(%ebp),%eax
  80106f:	88 10                	mov    %dl,(%eax)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
  801071:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  801075:	0f 95 c0             	setne  %al
  801078:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  80107c:	84 c0                	test   %al,%al
  80107e:	75 de                	jne    80105e <memmove+0x36>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  801080:	eb 28                	jmp    8010aa <memmove+0x82>
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
  801082:	8b 45 fc             	mov    -0x4(%ebp),%eax
  801085:	0f b6 10             	movzbl (%eax),%edx
  801088:	8b 45 f8             	mov    -0x8(%ebp),%eax
  80108b:	88 10                	mov    %dl,(%eax)
  80108d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  801091:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  801095:	eb 04                	jmp    80109b <memmove+0x73>
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
  801097:	90                   	nop
  801098:	eb 01                	jmp    80109b <memmove+0x73>
  80109a:	90                   	nop
  80109b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  80109f:	0f 95 c0             	setne  %al
  8010a2:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  8010a6:	84 c0                	test   %al,%al
  8010a8:	75 d8                	jne    801082 <memmove+0x5a>
			*d++ = *s++;

	return dst;
  8010aa:	8b 45 08             	mov    0x8(%ebp),%eax
}
  8010ad:	c9                   	leave  
  8010ae:	c3                   	ret    

008010af <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  8010af:	55                   	push   %ebp
  8010b0:	89 e5                	mov    %esp,%ebp
  8010b2:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  8010b5:	8b 45 10             	mov    0x10(%ebp),%eax
  8010b8:	89 44 24 08          	mov    %eax,0x8(%esp)
  8010bc:	8b 45 0c             	mov    0xc(%ebp),%eax
  8010bf:	89 44 24 04          	mov    %eax,0x4(%esp)
  8010c3:	8b 45 08             	mov    0x8(%ebp),%eax
  8010c6:	89 04 24             	mov    %eax,(%esp)
  8010c9:	e8 5a ff ff ff       	call   801028 <memmove>
}
  8010ce:	c9                   	leave  
  8010cf:	c3                   	ret    

008010d0 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8010d0:	55                   	push   %ebp
  8010d1:	89 e5                	mov    %esp,%ebp
  8010d3:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  8010d6:	8b 45 08             	mov    0x8(%ebp),%eax
  8010d9:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  8010dc:	8b 45 0c             	mov    0xc(%ebp),%eax
  8010df:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
  8010e2:	eb 32                	jmp    801116 <memcmp+0x46>
		if (*s1 != *s2)
  8010e4:	8b 45 fc             	mov    -0x4(%ebp),%eax
  8010e7:	0f b6 10             	movzbl (%eax),%edx
  8010ea:	8b 45 f8             	mov    -0x8(%ebp),%eax
  8010ed:	0f b6 00             	movzbl (%eax),%eax
  8010f0:	38 c2                	cmp    %al,%dl
  8010f2:	74 1a                	je     80110e <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  8010f4:	8b 45 fc             	mov    -0x4(%ebp),%eax
  8010f7:	0f b6 00             	movzbl (%eax),%eax
  8010fa:	0f b6 d0             	movzbl %al,%edx
  8010fd:	8b 45 f8             	mov    -0x8(%ebp),%eax
  801100:	0f b6 00             	movzbl (%eax),%eax
  801103:	0f b6 c0             	movzbl %al,%eax
  801106:	89 d1                	mov    %edx,%ecx
  801108:	29 c1                	sub    %eax,%ecx
  80110a:	89 c8                	mov    %ecx,%eax
  80110c:	eb 1c                	jmp    80112a <memcmp+0x5a>
		s1++, s2++;
  80110e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  801112:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  801116:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  80111a:	0f 95 c0             	setne  %al
  80111d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  801121:	84 c0                	test   %al,%al
  801123:	75 bf                	jne    8010e4 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  801125:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80112a:	c9                   	leave  
  80112b:	c3                   	ret    

0080112c <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  80112c:	55                   	push   %ebp
  80112d:	89 e5                	mov    %esp,%ebp
  80112f:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  801132:	8b 45 10             	mov    0x10(%ebp),%eax
  801135:	8b 55 08             	mov    0x8(%ebp),%edx
  801138:	8d 04 02             	lea    (%edx,%eax,1),%eax
  80113b:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  80113e:	eb 11                	jmp    801151 <memfind+0x25>
		if (*(const unsigned char *) s == (unsigned char) c)
  801140:	8b 45 08             	mov    0x8(%ebp),%eax
  801143:	0f b6 10             	movzbl (%eax),%edx
  801146:	8b 45 0c             	mov    0xc(%ebp),%eax
  801149:	38 c2                	cmp    %al,%dl
  80114b:	74 0e                	je     80115b <memfind+0x2f>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  80114d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  801151:	8b 45 08             	mov    0x8(%ebp),%eax
  801154:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  801157:	72 e7                	jb     801140 <memfind+0x14>
  801159:	eb 01                	jmp    80115c <memfind+0x30>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
  80115b:	90                   	nop
	return (void *) s;
  80115c:	8b 45 08             	mov    0x8(%ebp),%eax
}
  80115f:	c9                   	leave  
  801160:	c3                   	ret    

00801161 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  801161:	55                   	push   %ebp
  801162:	89 e5                	mov    %esp,%ebp
  801164:	83 ec 10             	sub    $0x10,%esp
	int neg = 0;
  801167:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	long val = 0;
  80116e:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  801175:	eb 04                	jmp    80117b <strtol+0x1a>
		s++;
  801177:	83 45 08 01          	addl   $0x1,0x8(%ebp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  80117b:	8b 45 08             	mov    0x8(%ebp),%eax
  80117e:	0f b6 00             	movzbl (%eax),%eax
  801181:	3c 20                	cmp    $0x20,%al
  801183:	74 f2                	je     801177 <strtol+0x16>
  801185:	8b 45 08             	mov    0x8(%ebp),%eax
  801188:	0f b6 00             	movzbl (%eax),%eax
  80118b:	3c 09                	cmp    $0x9,%al
  80118d:	74 e8                	je     801177 <strtol+0x16>
		s++;

	// plus/minus sign
	if (*s == '+')
  80118f:	8b 45 08             	mov    0x8(%ebp),%eax
  801192:	0f b6 00             	movzbl (%eax),%eax
  801195:	3c 2b                	cmp    $0x2b,%al
  801197:	75 06                	jne    80119f <strtol+0x3e>
		s++;
  801199:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  80119d:	eb 15                	jmp    8011b4 <strtol+0x53>
	else if (*s == '-')
  80119f:	8b 45 08             	mov    0x8(%ebp),%eax
  8011a2:	0f b6 00             	movzbl (%eax),%eax
  8011a5:	3c 2d                	cmp    $0x2d,%al
  8011a7:	75 0b                	jne    8011b4 <strtol+0x53>
		s++, neg = 1;
  8011a9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  8011ad:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  8011b4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  8011b8:	74 06                	je     8011c0 <strtol+0x5f>
  8011ba:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
  8011be:	75 24                	jne    8011e4 <strtol+0x83>
  8011c0:	8b 45 08             	mov    0x8(%ebp),%eax
  8011c3:	0f b6 00             	movzbl (%eax),%eax
  8011c6:	3c 30                	cmp    $0x30,%al
  8011c8:	75 1a                	jne    8011e4 <strtol+0x83>
  8011ca:	8b 45 08             	mov    0x8(%ebp),%eax
  8011cd:	83 c0 01             	add    $0x1,%eax
  8011d0:	0f b6 00             	movzbl (%eax),%eax
  8011d3:	3c 78                	cmp    $0x78,%al
  8011d5:	75 0d                	jne    8011e4 <strtol+0x83>
		s += 2, base = 16;
  8011d7:	83 45 08 02          	addl   $0x2,0x8(%ebp)
  8011db:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
  8011e2:	eb 2a                	jmp    80120e <strtol+0xad>
	else if (base == 0 && s[0] == '0')
  8011e4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  8011e8:	75 17                	jne    801201 <strtol+0xa0>
  8011ea:	8b 45 08             	mov    0x8(%ebp),%eax
  8011ed:	0f b6 00             	movzbl (%eax),%eax
  8011f0:	3c 30                	cmp    $0x30,%al
  8011f2:	75 0d                	jne    801201 <strtol+0xa0>
		s++, base = 8;
  8011f4:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  8011f8:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
  8011ff:	eb 0d                	jmp    80120e <strtol+0xad>
	else if (base == 0)
  801201:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  801205:	75 07                	jne    80120e <strtol+0xad>
		base = 10;
  801207:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  80120e:	8b 45 08             	mov    0x8(%ebp),%eax
  801211:	0f b6 00             	movzbl (%eax),%eax
  801214:	3c 2f                	cmp    $0x2f,%al
  801216:	7e 1b                	jle    801233 <strtol+0xd2>
  801218:	8b 45 08             	mov    0x8(%ebp),%eax
  80121b:	0f b6 00             	movzbl (%eax),%eax
  80121e:	3c 39                	cmp    $0x39,%al
  801220:	7f 11                	jg     801233 <strtol+0xd2>
			dig = *s - '0';
  801222:	8b 45 08             	mov    0x8(%ebp),%eax
  801225:	0f b6 00             	movzbl (%eax),%eax
  801228:	0f be c0             	movsbl %al,%eax
  80122b:	83 e8 30             	sub    $0x30,%eax
  80122e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801231:	eb 48                	jmp    80127b <strtol+0x11a>
		else if (*s >= 'a' && *s <= 'z')
  801233:	8b 45 08             	mov    0x8(%ebp),%eax
  801236:	0f b6 00             	movzbl (%eax),%eax
  801239:	3c 60                	cmp    $0x60,%al
  80123b:	7e 1b                	jle    801258 <strtol+0xf7>
  80123d:	8b 45 08             	mov    0x8(%ebp),%eax
  801240:	0f b6 00             	movzbl (%eax),%eax
  801243:	3c 7a                	cmp    $0x7a,%al
  801245:	7f 11                	jg     801258 <strtol+0xf7>
			dig = *s - 'a' + 10;
  801247:	8b 45 08             	mov    0x8(%ebp),%eax
  80124a:	0f b6 00             	movzbl (%eax),%eax
  80124d:	0f be c0             	movsbl %al,%eax
  801250:	83 e8 57             	sub    $0x57,%eax
  801253:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801256:	eb 23                	jmp    80127b <strtol+0x11a>
		else if (*s >= 'A' && *s <= 'Z')
  801258:	8b 45 08             	mov    0x8(%ebp),%eax
  80125b:	0f b6 00             	movzbl (%eax),%eax
  80125e:	3c 40                	cmp    $0x40,%al
  801260:	7e 38                	jle    80129a <strtol+0x139>
  801262:	8b 45 08             	mov    0x8(%ebp),%eax
  801265:	0f b6 00             	movzbl (%eax),%eax
  801268:	3c 5a                	cmp    $0x5a,%al
  80126a:	7f 2e                	jg     80129a <strtol+0x139>
			dig = *s - 'A' + 10;
  80126c:	8b 45 08             	mov    0x8(%ebp),%eax
  80126f:	0f b6 00             	movzbl (%eax),%eax
  801272:	0f be c0             	movsbl %al,%eax
  801275:	83 e8 37             	sub    $0x37,%eax
  801278:	89 45 f4             	mov    %eax,-0xc(%ebp)
		else
			break;
		if (dig >= base)
  80127b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80127e:	3b 45 10             	cmp    0x10(%ebp),%eax
  801281:	7d 16                	jge    801299 <strtol+0x138>
			break;
		s++, val = (val * base) + dig;
  801283:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  801287:	8b 45 f8             	mov    -0x8(%ebp),%eax
  80128a:	0f af 45 10          	imul   0x10(%ebp),%eax
  80128e:	03 45 f4             	add    -0xc(%ebp),%eax
  801291:	89 45 f8             	mov    %eax,-0x8(%ebp)
		// we don't properly detect overflow!
	}
  801294:	e9 75 ff ff ff       	jmp    80120e <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
			break;
  801299:	90                   	nop
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  80129a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  80129e:	74 08                	je     8012a8 <strtol+0x147>
		*endptr = (char *) s;
  8012a0:	8b 45 0c             	mov    0xc(%ebp),%eax
  8012a3:	8b 55 08             	mov    0x8(%ebp),%edx
  8012a6:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
  8012a8:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
  8012ac:	74 07                	je     8012b5 <strtol+0x154>
  8012ae:	8b 45 f8             	mov    -0x8(%ebp),%eax
  8012b1:	f7 d8                	neg    %eax
  8012b3:	eb 03                	jmp    8012b8 <strtol+0x157>
  8012b5:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  8012b8:	c9                   	leave  
  8012b9:	c3                   	ret    
	...

008012bc <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  8012bc:	55                   	push   %ebp
  8012bd:	89 e5                	mov    %esp,%ebp
  8012bf:	57                   	push   %edi
  8012c0:	56                   	push   %esi
  8012c1:	53                   	push   %ebx
  8012c2:	83 ec 4c             	sub    $0x4c,%esp
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8012c5:	8b 45 08             	mov    0x8(%ebp),%eax
  8012c8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8012cb:	8b 55 10             	mov    0x10(%ebp),%edx
  8012ce:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8012d1:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8012d4:	8b 7d 1c             	mov    0x1c(%ebp),%edi
  8012d7:	8b 75 20             	mov    0x20(%ebp),%esi
  8012da:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8012dd:	cd 30                	int    $0x30
  8012df:	89 c3                	mov    %eax,%ebx
  8012e1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");
	
	if(check && ret > 0)
  8012e4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8012e8:	74 30                	je     80131a <syscall+0x5e>
  8012ea:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8012ee:	7e 2a                	jle    80131a <syscall+0x5e>
		panic("syscall %d returned %d (> 0)", num, ret);
  8012f0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8012f3:	89 44 24 10          	mov    %eax,0x10(%esp)
  8012f7:	8b 45 08             	mov    0x8(%ebp),%eax
  8012fa:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8012fe:	c7 44 24 08 3c 3c 80 	movl   $0x803c3c,0x8(%esp)
  801305:	00 
  801306:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  80130d:	00 
  80130e:	c7 04 24 59 3c 80 00 	movl   $0x803c59,(%esp)
  801315:	e8 06 f3 ff ff       	call   800620 <_panic>

	return ret;
  80131a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
}
  80131d:	83 c4 4c             	add    $0x4c,%esp
  801320:	5b                   	pop    %ebx
  801321:	5e                   	pop    %esi
  801322:	5f                   	pop    %edi
  801323:	5d                   	pop    %ebp
  801324:	c3                   	ret    

00801325 <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  801325:	55                   	push   %ebp
  801326:	89 e5                	mov    %esp,%ebp
  801328:	83 ec 28             	sub    $0x28,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  80132b:	8b 45 08             	mov    0x8(%ebp),%eax
  80132e:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  801335:	00 
  801336:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  80133d:	00 
  80133e:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  801345:	00 
  801346:	8b 55 0c             	mov    0xc(%ebp),%edx
  801349:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80134d:	89 44 24 08          	mov    %eax,0x8(%esp)
  801351:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  801358:	00 
  801359:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801360:	e8 57 ff ff ff       	call   8012bc <syscall>
}
  801365:	c9                   	leave  
  801366:	c3                   	ret    

00801367 <sys_cgetc>:

int
sys_cgetc(void)
{
  801367:	55                   	push   %ebp
  801368:	89 e5                	mov    %esp,%ebp
  80136a:	83 ec 28             	sub    $0x28,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  80136d:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  801374:	00 
  801375:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  80137c:	00 
  80137d:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  801384:	00 
  801385:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  80138c:	00 
  80138d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  801394:	00 
  801395:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  80139c:	00 
  80139d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  8013a4:	e8 13 ff ff ff       	call   8012bc <syscall>
}
  8013a9:	c9                   	leave  
  8013aa:	c3                   	ret    

008013ab <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8013ab:	55                   	push   %ebp
  8013ac:	89 e5                	mov    %esp,%ebp
  8013ae:	83 ec 28             	sub    $0x28,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  8013b1:	8b 45 08             	mov    0x8(%ebp),%eax
  8013b4:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  8013bb:	00 
  8013bc:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  8013c3:	00 
  8013c4:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  8013cb:	00 
  8013cc:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8013d3:	00 
  8013d4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8013d8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  8013df:	00 
  8013e0:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
  8013e7:	e8 d0 fe ff ff       	call   8012bc <syscall>
}
  8013ec:	c9                   	leave  
  8013ed:	c3                   	ret    

008013ee <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  8013ee:	55                   	push   %ebp
  8013ef:	89 e5                	mov    %esp,%ebp
  8013f1:	83 ec 28             	sub    $0x28,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  8013f4:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  8013fb:	00 
  8013fc:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  801403:	00 
  801404:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  80140b:	00 
  80140c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  801413:	00 
  801414:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  80141b:	00 
  80141c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  801423:	00 
  801424:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  80142b:	e8 8c fe ff ff       	call   8012bc <syscall>
}
  801430:	c9                   	leave  
  801431:	c3                   	ret    

00801432 <sys_yield>:

void
sys_yield(void)
{
  801432:	55                   	push   %ebp
  801433:	89 e5                	mov    %esp,%ebp
  801435:	83 ec 28             	sub    $0x28,%esp
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
  801438:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  80143f:	00 
  801440:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  801447:	00 
  801448:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  80144f:	00 
  801450:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  801457:	00 
  801458:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  80145f:	00 
  801460:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  801467:	00 
  801468:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
  80146f:	e8 48 fe ff ff       	call   8012bc <syscall>
}
  801474:	c9                   	leave  
  801475:	c3                   	ret    

00801476 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  801476:	55                   	push   %ebp
  801477:	89 e5                	mov    %esp,%ebp
  801479:	83 ec 28             	sub    $0x28,%esp
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
  80147c:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80147f:	8b 55 0c             	mov    0xc(%ebp),%edx
  801482:	8b 45 08             	mov    0x8(%ebp),%eax
  801485:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  80148c:	00 
  80148d:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  801494:	00 
  801495:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  801499:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80149d:	89 44 24 08          	mov    %eax,0x8(%esp)
  8014a1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  8014a8:	00 
  8014a9:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  8014b0:	e8 07 fe ff ff       	call   8012bc <syscall>
}
  8014b5:	c9                   	leave  
  8014b6:	c3                   	ret    

008014b7 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8014b7:	55                   	push   %ebp
  8014b8:	89 e5                	mov    %esp,%ebp
  8014ba:	56                   	push   %esi
  8014bb:	53                   	push   %ebx
  8014bc:	83 ec 20             	sub    $0x20,%esp
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
  8014bf:	8b 75 18             	mov    0x18(%ebp),%esi
  8014c2:	8b 5d 14             	mov    0x14(%ebp),%ebx
  8014c5:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8014c8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8014cb:	8b 45 08             	mov    0x8(%ebp),%eax
  8014ce:	89 74 24 18          	mov    %esi,0x18(%esp)
  8014d2:	89 5c 24 14          	mov    %ebx,0x14(%esp)
  8014d6:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8014da:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8014de:	89 44 24 08          	mov    %eax,0x8(%esp)
  8014e2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  8014e9:	00 
  8014ea:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
  8014f1:	e8 c6 fd ff ff       	call   8012bc <syscall>
}
  8014f6:	83 c4 20             	add    $0x20,%esp
  8014f9:	5b                   	pop    %ebx
  8014fa:	5e                   	pop    %esi
  8014fb:	5d                   	pop    %ebp
  8014fc:	c3                   	ret    

008014fd <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8014fd:	55                   	push   %ebp
  8014fe:	89 e5                	mov    %esp,%ebp
  801500:	83 ec 28             	sub    $0x28,%esp
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
  801503:	8b 55 0c             	mov    0xc(%ebp),%edx
  801506:	8b 45 08             	mov    0x8(%ebp),%eax
  801509:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  801510:	00 
  801511:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  801518:	00 
  801519:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  801520:	00 
  801521:	89 54 24 0c          	mov    %edx,0xc(%esp)
  801525:	89 44 24 08          	mov    %eax,0x8(%esp)
  801529:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  801530:	00 
  801531:	c7 04 24 06 00 00 00 	movl   $0x6,(%esp)
  801538:	e8 7f fd ff ff       	call   8012bc <syscall>
}
  80153d:	c9                   	leave  
  80153e:	c3                   	ret    

0080153f <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  80153f:	55                   	push   %ebp
  801540:	89 e5                	mov    %esp,%ebp
  801542:	83 ec 28             	sub    $0x28,%esp
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
  801545:	8b 55 0c             	mov    0xc(%ebp),%edx
  801548:	8b 45 08             	mov    0x8(%ebp),%eax
  80154b:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  801552:	00 
  801553:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  80155a:	00 
  80155b:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  801562:	00 
  801563:	89 54 24 0c          	mov    %edx,0xc(%esp)
  801567:	89 44 24 08          	mov    %eax,0x8(%esp)
  80156b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  801572:	00 
  801573:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  80157a:	e8 3d fd ff ff       	call   8012bc <syscall>
}
  80157f:	c9                   	leave  
  801580:	c3                   	ret    

00801581 <sys_env_set_trapframe>:

int
sys_env_set_trapframe(envid_t envid, struct Trapframe *tf)
{
  801581:	55                   	push   %ebp
  801582:	89 e5                	mov    %esp,%ebp
  801584:	83 ec 28             	sub    $0x28,%esp
	return syscall(SYS_env_set_trapframe, 1, envid, (uint32_t) tf, 0, 0, 0);
  801587:	8b 55 0c             	mov    0xc(%ebp),%edx
  80158a:	8b 45 08             	mov    0x8(%ebp),%eax
  80158d:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  801594:	00 
  801595:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  80159c:	00 
  80159d:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  8015a4:	00 
  8015a5:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8015a9:	89 44 24 08          	mov    %eax,0x8(%esp)
  8015ad:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  8015b4:	00 
  8015b5:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
  8015bc:	e8 fb fc ff ff       	call   8012bc <syscall>
}
  8015c1:	c9                   	leave  
  8015c2:	c3                   	ret    

008015c3 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  8015c3:	55                   	push   %ebp
  8015c4:	89 e5                	mov    %esp,%ebp
  8015c6:	83 ec 28             	sub    $0x28,%esp
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
  8015c9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8015cc:	8b 45 08             	mov    0x8(%ebp),%eax
  8015cf:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  8015d6:	00 
  8015d7:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  8015de:	00 
  8015df:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  8015e6:	00 
  8015e7:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8015eb:	89 44 24 08          	mov    %eax,0x8(%esp)
  8015ef:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  8015f6:	00 
  8015f7:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
  8015fe:	e8 b9 fc ff ff       	call   8012bc <syscall>
}
  801603:	c9                   	leave  
  801604:	c3                   	ret    

00801605 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  801605:	55                   	push   %ebp
  801606:	89 e5                	mov    %esp,%ebp
  801608:	83 ec 28             	sub    $0x28,%esp
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
  80160b:	8b 4d 14             	mov    0x14(%ebp),%ecx
  80160e:	8b 55 10             	mov    0x10(%ebp),%edx
  801611:	8b 45 08             	mov    0x8(%ebp),%eax
  801614:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  80161b:	00 
  80161c:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  801620:	89 54 24 10          	mov    %edx,0x10(%esp)
  801624:	8b 55 0c             	mov    0xc(%ebp),%edx
  801627:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80162b:	89 44 24 08          	mov    %eax,0x8(%esp)
  80162f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  801636:	00 
  801637:	c7 04 24 0c 00 00 00 	movl   $0xc,(%esp)
  80163e:	e8 79 fc ff ff       	call   8012bc <syscall>
}
  801643:	c9                   	leave  
  801644:	c3                   	ret    

00801645 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  801645:	55                   	push   %ebp
  801646:	89 e5                	mov    %esp,%ebp
  801648:	83 ec 28             	sub    $0x28,%esp
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
  80164b:	8b 45 08             	mov    0x8(%ebp),%eax
  80164e:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  801655:	00 
  801656:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  80165d:	00 
  80165e:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  801665:	00 
  801666:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  80166d:	00 
  80166e:	89 44 24 08          	mov    %eax,0x8(%esp)
  801672:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  801679:	00 
  80167a:	c7 04 24 0d 00 00 00 	movl   $0xd,(%esp)
  801681:	e8 36 fc ff ff       	call   8012bc <syscall>
}
  801686:	c9                   	leave  
  801687:	c3                   	ret    

00801688 <sys_time_msec>:

unsigned int
sys_time_msec(void)
{
  801688:	55                   	push   %ebp
  801689:	89 e5                	mov    %esp,%ebp
  80168b:	83 ec 28             	sub    $0x28,%esp
	return (unsigned int) syscall(SYS_time_msec, 0, 0, 0, 0, 0, 0);
  80168e:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  801695:	00 
  801696:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  80169d:	00 
  80169e:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  8016a5:	00 
  8016a6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8016ad:	00 
  8016ae:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8016b5:	00 
  8016b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8016bd:	00 
  8016be:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
  8016c5:	e8 f2 fb ff ff       	call   8012bc <syscall>
}
  8016ca:	c9                   	leave  
  8016cb:	c3                   	ret    

008016cc <sys_net_send>:

int
sys_net_send(void *va, int size) {
  8016cc:	55                   	push   %ebp
  8016cd:	89 e5                	mov    %esp,%ebp
  8016cf:	83 ec 38             	sub    $0x38,%esp
	int r = syscall(SYS_net_send, 0, (uint32_t)va, (uint32_t)size, 0, 0, 0);
  8016d2:	8b 55 0c             	mov    0xc(%ebp),%edx
  8016d5:	8b 45 08             	mov    0x8(%ebp),%eax
  8016d8:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  8016df:	00 
  8016e0:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  8016e7:	00 
  8016e8:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  8016ef:	00 
  8016f0:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8016f4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8016f8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8016ff:	00 
  801700:	c7 04 24 0f 00 00 00 	movl   $0xf,(%esp)
  801707:	e8 b0 fb ff ff       	call   8012bc <syscall>
  80170c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	DPRINTF6("lib/syscall.c::sys_net_send returning: %d\n", r);
	return r;
  80170f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  801712:	c9                   	leave  
  801713:	c3                   	ret    

00801714 <sys_net_recv>:

int
sys_net_recv(void *va, int size) {
  801714:	55                   	push   %ebp
  801715:	89 e5                	mov    %esp,%ebp
  801717:	83 ec 28             	sub    $0x28,%esp
	return syscall(SYS_net_recv, 0, (uint32_t)va, (uint32_t)size, 0, 0, 0);
  80171a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80171d:	8b 45 08             	mov    0x8(%ebp),%eax
  801720:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  801727:	00 
  801728:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  80172f:	00 
  801730:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  801737:	00 
  801738:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80173c:	89 44 24 08          	mov    %eax,0x8(%esp)
  801740:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  801747:	00 
  801748:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
  80174f:	e8 68 fb ff ff       	call   8012bc <syscall>
}
  801754:	c9                   	leave  
  801755:	c3                   	ret    

00801756 <sys_env_get_trapframe>:

int
sys_env_get_trapframe(envid_t envid, struct Trapframe *tf)
{
  801756:	55                   	push   %ebp
  801757:	89 e5                	mov    %esp,%ebp
  801759:	83 ec 28             	sub    $0x28,%esp
	return syscall(SYS_env_get_trapframe, 1, envid, (uint32_t) tf, 0, 0, 0);
  80175c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80175f:	8b 45 08             	mov    0x8(%ebp),%eax
  801762:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  801769:	00 
  80176a:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  801771:	00 
  801772:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
  801779:	00 
  80177a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80177e:	89 44 24 08          	mov    %eax,0x8(%esp)
  801782:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  801789:	00 
  80178a:	c7 04 24 11 00 00 00 	movl   $0x11,(%esp)
  801791:	e8 26 fb ff ff       	call   8012bc <syscall>
}
  801796:	c9                   	leave  
  801797:	c3                   	ret    

00801798 <fd2num>:
// File descriptor manipulators
// --------------------------------------------------------------

int
fd2num(struct Fd *fd)
{
  801798:	55                   	push   %ebp
  801799:	89 e5                	mov    %esp,%ebp
	return ((uintptr_t) fd - FDTABLE) / PGSIZE;
  80179b:	8b 45 08             	mov    0x8(%ebp),%eax
  80179e:	05 00 00 00 30       	add    $0x30000000,%eax
  8017a3:	c1 e8 0c             	shr    $0xc,%eax
}
  8017a6:	5d                   	pop    %ebp
  8017a7:	c3                   	ret    

008017a8 <fd2data>:

char*
fd2data(struct Fd *fd)
{
  8017a8:	55                   	push   %ebp
  8017a9:	89 e5                	mov    %esp,%ebp
  8017ab:	83 ec 04             	sub    $0x4,%esp
	return INDEX2DATA(fd2num(fd));
  8017ae:	8b 45 08             	mov    0x8(%ebp),%eax
  8017b1:	89 04 24             	mov    %eax,(%esp)
  8017b4:	e8 df ff ff ff       	call   801798 <fd2num>
  8017b9:	05 20 00 0d 00       	add    $0xd0020,%eax
  8017be:	c1 e0 0c             	shl    $0xc,%eax
}
  8017c1:	c9                   	leave  
  8017c2:	c3                   	ret    

008017c3 <fd_alloc>:
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_MAX_FD: no more file descriptors
// On error, *fd_store is set to 0.
int
fd_alloc(struct Fd **fd_store)
{
  8017c3:	55                   	push   %ebp
  8017c4:	89 e5                	mov    %esp,%ebp
  8017c6:	83 ec 10             	sub    $0x10,%esp
	int i;
	struct Fd *fd;

	for (i = 0; i < MAXFD; i++) {
  8017c9:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  8017d0:	eb 49                	jmp    80181b <fd_alloc+0x58>
		fd = INDEX2FD(i);
  8017d2:	8b 45 fc             	mov    -0x4(%ebp),%eax
  8017d5:	05 00 00 0d 00       	add    $0xd0000,%eax
  8017da:	c1 e0 0c             	shl    $0xc,%eax
  8017dd:	89 45 f8             	mov    %eax,-0x8(%ebp)
		if ((vpd[PDX(fd)] & PTE_P) == 0 || (vpt[VPN(fd)] & PTE_P) == 0) {
  8017e0:	8b 45 f8             	mov    -0x8(%ebp),%eax
  8017e3:	c1 e8 16             	shr    $0x16,%eax
  8017e6:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  8017ed:	83 e0 01             	and    $0x1,%eax
  8017f0:	85 c0                	test   %eax,%eax
  8017f2:	74 14                	je     801808 <fd_alloc+0x45>
  8017f4:	8b 45 f8             	mov    -0x8(%ebp),%eax
  8017f7:	c1 e8 0c             	shr    $0xc,%eax
  8017fa:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  801801:	83 e0 01             	and    $0x1,%eax
  801804:	85 c0                	test   %eax,%eax
  801806:	75 0f                	jne    801817 <fd_alloc+0x54>
			*fd_store = fd;
  801808:	8b 45 08             	mov    0x8(%ebp),%eax
  80180b:	8b 55 f8             	mov    -0x8(%ebp),%edx
  80180e:	89 10                	mov    %edx,(%eax)
			return 0;
  801810:	b8 00 00 00 00       	mov    $0x0,%eax
  801815:	eb 18                	jmp    80182f <fd_alloc+0x6c>
fd_alloc(struct Fd **fd_store)
{
	int i;
	struct Fd *fd;

	for (i = 0; i < MAXFD; i++) {
  801817:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  80181b:	83 7d fc 1f          	cmpl   $0x1f,-0x4(%ebp)
  80181f:	7e b1                	jle    8017d2 <fd_alloc+0xf>
		if ((vpd[PDX(fd)] & PTE_P) == 0 || (vpt[VPN(fd)] & PTE_P) == 0) {
			*fd_store = fd;
			return 0;
		}
	}
	*fd_store = 0;
  801821:	8b 45 08             	mov    0x8(%ebp),%eax
  801824:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return -E_MAX_OPEN;
  80182a:	b8 f6 ff ff ff       	mov    $0xfffffff6,%eax
}
  80182f:	c9                   	leave  
  801830:	c3                   	ret    

00801831 <fd_lookup>:
// Returns 0 on success (the page is in range and mapped), < 0 on error.
// Errors are:
//	-E_INVAL: fdnum was either not in range or not mapped.
int
fd_lookup(int fdnum, struct Fd **fd_store)
{
  801831:	55                   	push   %ebp
  801832:	89 e5                	mov    %esp,%ebp
  801834:	83 ec 10             	sub    $0x10,%esp
	struct Fd *fd;

	if (fdnum < 0 || fdnum >= MAXFD) {
  801837:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  80183b:	78 06                	js     801843 <fd_lookup+0x12>
  80183d:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  801841:	7e 07                	jle    80184a <fd_lookup+0x19>
		if (debug)
			cprintf("[%08x] bad fd %d\n", env->env_id, fd);
		return -E_INVAL;
  801843:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  801848:	eb 4a                	jmp    801894 <fd_lookup+0x63>
	}
	fd = INDEX2FD(fdnum);
  80184a:	8b 45 08             	mov    0x8(%ebp),%eax
  80184d:	05 00 00 0d 00       	add    $0xd0000,%eax
  801852:	c1 e0 0c             	shl    $0xc,%eax
  801855:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (!(vpd[PDX(fd)] & PTE_P) || !(vpt[VPN(fd)] & PTE_P)) {
  801858:	8b 45 fc             	mov    -0x4(%ebp),%eax
  80185b:	c1 e8 16             	shr    $0x16,%eax
  80185e:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  801865:	83 e0 01             	and    $0x1,%eax
  801868:	85 c0                	test   %eax,%eax
  80186a:	74 14                	je     801880 <fd_lookup+0x4f>
  80186c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  80186f:	c1 e8 0c             	shr    $0xc,%eax
  801872:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  801879:	83 e0 01             	and    $0x1,%eax
  80187c:	85 c0                	test   %eax,%eax
  80187e:	75 07                	jne    801887 <fd_lookup+0x56>
		if (debug)
			cprintf("[%08x] closed fd %d\n", env->env_id, fd);
		return -E_INVAL;
  801880:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  801885:	eb 0d                	jmp    801894 <fd_lookup+0x63>
	}
	*fd_store = fd;
  801887:	8b 45 0c             	mov    0xc(%ebp),%eax
  80188a:	8b 55 fc             	mov    -0x4(%ebp),%edx
  80188d:	89 10                	mov    %edx,(%eax)
	return 0;
  80188f:	b8 00 00 00 00       	mov    $0x0,%eax
}
  801894:	c9                   	leave  
  801895:	c3                   	ret    

00801896 <fd_close>:
// If 'must_exist' is 1, then fd_close returns -E_INVAL when passed a
// closed or nonexistent file descriptor.
// Returns 0 on success, < 0 on error.
int
fd_close(struct Fd *fd, bool must_exist)
{
  801896:	55                   	push   %ebp
  801897:	89 e5                	mov    %esp,%ebp
  801899:	83 ec 28             	sub    $0x28,%esp
	struct Fd *fd2;
	struct Dev *dev;
	int r;
	if ((r = fd_lookup(fd2num(fd), &fd2)) < 0
  80189c:	8b 45 08             	mov    0x8(%ebp),%eax
  80189f:	89 04 24             	mov    %eax,(%esp)
  8018a2:	e8 f1 fe ff ff       	call   801798 <fd2num>
  8018a7:	8d 55 f0             	lea    -0x10(%ebp),%edx
  8018aa:	89 54 24 04          	mov    %edx,0x4(%esp)
  8018ae:	89 04 24             	mov    %eax,(%esp)
  8018b1:	e8 7b ff ff ff       	call   801831 <fd_lookup>
  8018b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  8018b9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  8018bd:	78 08                	js     8018c7 <fd_close+0x31>
	    || fd != fd2)
  8018bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8018c2:	39 45 08             	cmp    %eax,0x8(%ebp)
  8018c5:	74 12                	je     8018d9 <fd_close+0x43>
		return (must_exist ? r : 0);
  8018c7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8018cb:	74 05                	je     8018d2 <fd_close+0x3c>
  8018cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8018d0:	eb 05                	jmp    8018d7 <fd_close+0x41>
  8018d2:	b8 00 00 00 00       	mov    $0x0,%eax
  8018d7:	eb 57                	jmp    801930 <fd_close+0x9a>
	if ((r = dev_lookup(fd->fd_dev_id, &dev)) >= 0) {
  8018d9:	8b 45 08             	mov    0x8(%ebp),%eax
  8018dc:	8b 00                	mov    (%eax),%eax
  8018de:	8d 55 ec             	lea    -0x14(%ebp),%edx
  8018e1:	89 54 24 04          	mov    %edx,0x4(%esp)
  8018e5:	89 04 24             	mov    %eax,(%esp)
  8018e8:	e8 45 00 00 00       	call   801932 <dev_lookup>
  8018ed:	89 45 f4             	mov    %eax,-0xc(%ebp)
  8018f0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  8018f4:	78 24                	js     80191a <fd_close+0x84>
		if (dev->dev_close)
  8018f6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8018f9:	8b 40 10             	mov    0x10(%eax),%eax
  8018fc:	85 c0                	test   %eax,%eax
  8018fe:	74 13                	je     801913 <fd_close+0x7d>
			r = (*dev->dev_close)(fd);
  801900:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801903:	8b 50 10             	mov    0x10(%eax),%edx
  801906:	8b 45 08             	mov    0x8(%ebp),%eax
  801909:	89 04 24             	mov    %eax,(%esp)
  80190c:	ff d2                	call   *%edx
  80190e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801911:	eb 07                	jmp    80191a <fd_close+0x84>
		else
			r = 0;
  801913:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	}
	// Make sure fd is unmapped.  Might be a no-op if
	// (*dev->dev_close)(fd) already unmapped it.
	(void) sys_page_unmap(0, fd);
  80191a:	8b 45 08             	mov    0x8(%ebp),%eax
  80191d:	89 44 24 04          	mov    %eax,0x4(%esp)
  801921:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801928:	e8 d0 fb ff ff       	call   8014fd <sys_page_unmap>
	return r;
  80192d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  801930:	c9                   	leave  
  801931:	c3                   	ret    

00801932 <dev_lookup>:
	0
};

int
dev_lookup(int dev_id, struct Dev **dev)
{
  801932:	55                   	push   %ebp
  801933:	89 e5                	mov    %esp,%ebp
  801935:	83 ec 28             	sub    $0x28,%esp
	int i;
	for (i = 0; devtab[i]; i++)
  801938:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  80193f:	eb 2b                	jmp    80196c <dev_lookup+0x3a>
		if (devtab[i]->dev_id == dev_id) {
  801941:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801944:	8b 04 85 04 70 80 00 	mov    0x807004(,%eax,4),%eax
  80194b:	8b 00                	mov    (%eax),%eax
  80194d:	3b 45 08             	cmp    0x8(%ebp),%eax
  801950:	75 16                	jne    801968 <dev_lookup+0x36>
			*dev = devtab[i];
  801952:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801955:	8b 14 85 04 70 80 00 	mov    0x807004(,%eax,4),%edx
  80195c:	8b 45 0c             	mov    0xc(%ebp),%eax
  80195f:	89 10                	mov    %edx,(%eax)
			return 0;
  801961:	b8 00 00 00 00       	mov    $0x0,%eax
  801966:	eb 3f                	jmp    8019a7 <dev_lookup+0x75>

int
dev_lookup(int dev_id, struct Dev **dev)
{
	int i;
	for (i = 0; devtab[i]; i++)
  801968:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  80196c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80196f:	8b 04 85 04 70 80 00 	mov    0x807004(,%eax,4),%eax
  801976:	85 c0                	test   %eax,%eax
  801978:	75 c7                	jne    801941 <dev_lookup+0xf>
		if (devtab[i]->dev_id == dev_id) {
			*dev = devtab[i];
			return 0;
		}
	cprintf("[%08x] unknown device type %d\n", env->env_id, dev_id);
  80197a:	a1 44 81 80 00       	mov    0x808144,%eax
  80197f:	8b 40 4c             	mov    0x4c(%eax),%eax
  801982:	8b 55 08             	mov    0x8(%ebp),%edx
  801985:	89 54 24 08          	mov    %edx,0x8(%esp)
  801989:	89 44 24 04          	mov    %eax,0x4(%esp)
  80198d:	c7 04 24 68 3c 80 00 	movl   $0x803c68,(%esp)
  801994:	e8 b8 ed ff ff       	call   800751 <cprintf>
	*dev = 0;
  801999:	8b 45 0c             	mov    0xc(%ebp),%eax
  80199c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return -E_INVAL;
  8019a2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
  8019a7:	c9                   	leave  
  8019a8:	c3                   	ret    

008019a9 <close>:

int
close(int fdnum)
{
  8019a9:	55                   	push   %ebp
  8019aa:	89 e5                	mov    %esp,%ebp
  8019ac:	83 ec 28             	sub    $0x28,%esp
	struct Fd *fd;
	int r;

	if ((r = fd_lookup(fdnum, &fd)) < 0)
  8019af:	8d 45 f0             	lea    -0x10(%ebp),%eax
  8019b2:	89 44 24 04          	mov    %eax,0x4(%esp)
  8019b6:	8b 45 08             	mov    0x8(%ebp),%eax
  8019b9:	89 04 24             	mov    %eax,(%esp)
  8019bc:	e8 70 fe ff ff       	call   801831 <fd_lookup>
  8019c1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  8019c4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  8019c8:	79 05                	jns    8019cf <close+0x26>
		return r;
  8019ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8019cd:	eb 13                	jmp    8019e2 <close+0x39>
	else
		return fd_close(fd, 1);
  8019cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8019d2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  8019d9:	00 
  8019da:	89 04 24             	mov    %eax,(%esp)
  8019dd:	e8 b4 fe ff ff       	call   801896 <fd_close>
}
  8019e2:	c9                   	leave  
  8019e3:	c3                   	ret    

008019e4 <close_all>:

void
close_all(void)
{
  8019e4:	55                   	push   %ebp
  8019e5:	89 e5                	mov    %esp,%ebp
  8019e7:	83 ec 28             	sub    $0x28,%esp
	int i;
	for (i = 0; i < MAXFD; i++)
  8019ea:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  8019f1:	eb 0f                	jmp    801a02 <close_all+0x1e>
		close(i);
  8019f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8019f6:	89 04 24             	mov    %eax,(%esp)
  8019f9:	e8 ab ff ff ff       	call   8019a9 <close>

void
close_all(void)
{
	int i;
	for (i = 0; i < MAXFD; i++)
  8019fe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  801a02:	83 7d f4 1f          	cmpl   $0x1f,-0xc(%ebp)
  801a06:	7e eb                	jle    8019f3 <close_all+0xf>
		close(i);
}
  801a08:	c9                   	leave  
  801a09:	c3                   	ret    

00801a0a <dup>:
// file and the file offset of the other.
// Closes any previously open file descriptor at 'newfdnum'.
// This is implemented using virtual memory tricks (of course!).
int
dup(int oldfdnum, int newfdnum)
{
  801a0a:	55                   	push   %ebp
  801a0b:	89 e5                	mov    %esp,%ebp
  801a0d:	83 ec 48             	sub    $0x48,%esp
	int r;
	char *ova, *nva;
	pte_t pte;
	struct Fd *oldfd, *newfd;

	if ((r = fd_lookup(oldfdnum, &oldfd)) < 0)
  801a10:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  801a13:	89 44 24 04          	mov    %eax,0x4(%esp)
  801a17:	8b 45 08             	mov    0x8(%ebp),%eax
  801a1a:	89 04 24             	mov    %eax,(%esp)
  801a1d:	e8 0f fe ff ff       	call   801831 <fd_lookup>
  801a22:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801a25:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801a29:	79 08                	jns    801a33 <dup+0x29>
		return r;
  801a2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801a2e:	e9 14 01 00 00       	jmp    801b47 <dup+0x13d>
	close(newfdnum);
  801a33:	8b 45 0c             	mov    0xc(%ebp),%eax
  801a36:	89 04 24             	mov    %eax,(%esp)
  801a39:	e8 6b ff ff ff       	call   8019a9 <close>

	newfd = INDEX2FD(newfdnum);
  801a3e:	8b 45 0c             	mov    0xc(%ebp),%eax
  801a41:	05 00 00 0d 00       	add    $0xd0000,%eax
  801a46:	c1 e0 0c             	shl    $0xc,%eax
  801a49:	89 45 f0             	mov    %eax,-0x10(%ebp)
	ova = fd2data(oldfd);
  801a4c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801a4f:	89 04 24             	mov    %eax,(%esp)
  801a52:	e8 51 fd ff ff       	call   8017a8 <fd2data>
  801a57:	89 45 ec             	mov    %eax,-0x14(%ebp)
	nva = fd2data(newfd);
  801a5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801a5d:	89 04 24             	mov    %eax,(%esp)
  801a60:	e8 43 fd ff ff       	call   8017a8 <fd2data>
  801a65:	89 45 e8             	mov    %eax,-0x18(%ebp)

	if ((vpd[PDX(ova)] & PTE_P) && (vpt[VPN(ova)] & PTE_P))
  801a68:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801a6b:	c1 e8 16             	shr    $0x16,%eax
  801a6e:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  801a75:	83 e0 01             	and    $0x1,%eax
  801a78:	84 c0                	test   %al,%al
  801a7a:	74 55                	je     801ad1 <dup+0xc7>
  801a7c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801a7f:	c1 e8 0c             	shr    $0xc,%eax
  801a82:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  801a89:	83 e0 01             	and    $0x1,%eax
  801a8c:	84 c0                	test   %al,%al
  801a8e:	74 41                	je     801ad1 <dup+0xc7>
		if ((r = sys_page_map(0, ova, 0, nva, vpt[VPN(ova)] & PTE_USER)) < 0)
  801a90:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801a93:	c1 e8 0c             	shr    $0xc,%eax
  801a96:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  801a9d:	25 07 0e 00 00       	and    $0xe07,%eax
  801aa2:	89 44 24 10          	mov    %eax,0x10(%esp)
  801aa6:	8b 45 e8             	mov    -0x18(%ebp),%eax
  801aa9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801aad:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  801ab4:	00 
  801ab5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801ab8:	89 44 24 04          	mov    %eax,0x4(%esp)
  801abc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801ac3:	e8 ef f9 ff ff       	call   8014b7 <sys_page_map>
  801ac8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801acb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801acf:	78 49                	js     801b1a <dup+0x110>
			goto err;
	if ((r = sys_page_map(0, oldfd, 0, newfd, vpt[VPN(oldfd)] & PTE_USER)) < 0)
  801ad1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801ad4:	c1 e8 0c             	shr    $0xc,%eax
  801ad7:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  801ade:	89 c2                	mov    %eax,%edx
  801ae0:	81 e2 07 0e 00 00    	and    $0xe07,%edx
  801ae6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801ae9:	89 54 24 10          	mov    %edx,0x10(%esp)
  801aed:	8b 55 f0             	mov    -0x10(%ebp),%edx
  801af0:	89 54 24 0c          	mov    %edx,0xc(%esp)
  801af4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  801afb:	00 
  801afc:	89 44 24 04          	mov    %eax,0x4(%esp)
  801b00:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801b07:	e8 ab f9 ff ff       	call   8014b7 <sys_page_map>
  801b0c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801b0f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801b13:	78 08                	js     801b1d <dup+0x113>
		goto err;

	return newfdnum;
  801b15:	8b 45 0c             	mov    0xc(%ebp),%eax
  801b18:	eb 2d                	jmp    801b47 <dup+0x13d>
	ova = fd2data(oldfd);
	nva = fd2data(newfd);

	if ((vpd[PDX(ova)] & PTE_P) && (vpt[VPN(ova)] & PTE_P))
		if ((r = sys_page_map(0, ova, 0, nva, vpt[VPN(ova)] & PTE_USER)) < 0)
			goto err;
  801b1a:	90                   	nop
  801b1b:	eb 01                	jmp    801b1e <dup+0x114>
	if ((r = sys_page_map(0, oldfd, 0, newfd, vpt[VPN(oldfd)] & PTE_USER)) < 0)
		goto err;
  801b1d:	90                   	nop

	return newfdnum;

err:
	sys_page_unmap(0, newfd);
  801b1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801b21:	89 44 24 04          	mov    %eax,0x4(%esp)
  801b25:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801b2c:	e8 cc f9 ff ff       	call   8014fd <sys_page_unmap>
	sys_page_unmap(0, nva);
  801b31:	8b 45 e8             	mov    -0x18(%ebp),%eax
  801b34:	89 44 24 04          	mov    %eax,0x4(%esp)
  801b38:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801b3f:	e8 b9 f9 ff ff       	call   8014fd <sys_page_unmap>
	return r;
  801b44:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  801b47:	c9                   	leave  
  801b48:	c3                   	ret    

00801b49 <read>:

ssize_t
read(int fdnum, void *buf, size_t n)
{
  801b49:	55                   	push   %ebp
  801b4a:	89 e5                	mov    %esp,%ebp
  801b4c:	83 ec 28             	sub    $0x28,%esp
	int r;
	struct Dev *dev;
	struct Fd *fd;

	if ((r = fd_lookup(fdnum, &fd)) < 0
  801b4f:	8d 45 ec             	lea    -0x14(%ebp),%eax
  801b52:	89 44 24 04          	mov    %eax,0x4(%esp)
  801b56:	8b 45 08             	mov    0x8(%ebp),%eax
  801b59:	89 04 24             	mov    %eax,(%esp)
  801b5c:	e8 d0 fc ff ff       	call   801831 <fd_lookup>
  801b61:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801b64:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801b68:	78 1d                	js     801b87 <read+0x3e>
	    || (r = dev_lookup(fd->fd_dev_id, &dev)) < 0)
  801b6a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801b6d:	8b 00                	mov    (%eax),%eax
  801b6f:	8d 55 f0             	lea    -0x10(%ebp),%edx
  801b72:	89 54 24 04          	mov    %edx,0x4(%esp)
  801b76:	89 04 24             	mov    %eax,(%esp)
  801b79:	e8 b4 fd ff ff       	call   801932 <dev_lookup>
  801b7e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801b81:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801b85:	79 05                	jns    801b8c <read+0x43>
		return r;
  801b87:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801b8a:	eb 61                	jmp    801bed <read+0xa4>
	if ((fd->fd_omode & O_ACCMODE) == O_WRONLY) {
  801b8c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801b8f:	8b 40 08             	mov    0x8(%eax),%eax
  801b92:	83 e0 03             	and    $0x3,%eax
  801b95:	83 f8 01             	cmp    $0x1,%eax
  801b98:	75 26                	jne    801bc0 <read+0x77>
		cprintf("[%08x] read %d -- bad mode\n", env->env_id, fdnum); 
  801b9a:	a1 44 81 80 00       	mov    0x808144,%eax
  801b9f:	8b 40 4c             	mov    0x4c(%eax),%eax
  801ba2:	8b 55 08             	mov    0x8(%ebp),%edx
  801ba5:	89 54 24 08          	mov    %edx,0x8(%esp)
  801ba9:	89 44 24 04          	mov    %eax,0x4(%esp)
  801bad:	c7 04 24 87 3c 80 00 	movl   $0x803c87,(%esp)
  801bb4:	e8 98 eb ff ff       	call   800751 <cprintf>
		return -E_INVAL;
  801bb9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  801bbe:	eb 2d                	jmp    801bed <read+0xa4>
	}
	if (!dev->dev_read)
  801bc0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801bc3:	8b 40 08             	mov    0x8(%eax),%eax
  801bc6:	85 c0                	test   %eax,%eax
  801bc8:	75 07                	jne    801bd1 <read+0x88>
		return -E_NOT_SUPP;
  801bca:	b8 f1 ff ff ff       	mov    $0xfffffff1,%eax
  801bcf:	eb 1c                	jmp    801bed <read+0xa4>
	return (*dev->dev_read)(fd, buf, n);
  801bd1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801bd4:	8b 48 08             	mov    0x8(%eax),%ecx
  801bd7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801bda:	8b 55 10             	mov    0x10(%ebp),%edx
  801bdd:	89 54 24 08          	mov    %edx,0x8(%esp)
  801be1:	8b 55 0c             	mov    0xc(%ebp),%edx
  801be4:	89 54 24 04          	mov    %edx,0x4(%esp)
  801be8:	89 04 24             	mov    %eax,(%esp)
  801beb:	ff d1                	call   *%ecx
}
  801bed:	c9                   	leave  
  801bee:	c3                   	ret    

00801bef <readn>:

ssize_t
readn(int fdnum, void *buf, size_t n)
{
  801bef:	55                   	push   %ebp
  801bf0:	89 e5                	mov    %esp,%ebp
  801bf2:	83 ec 28             	sub    $0x28,%esp
	int m, tot;

	for (tot = 0; tot < n; tot += m) {
  801bf5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  801bfc:	eb 52                	jmp    801c50 <readn+0x61>
		int bytes_to_receive = (n - tot) > 1024 ? 1024 : (n - tot);
  801bfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801c01:	8b 55 10             	mov    0x10(%ebp),%edx
  801c04:	89 d1                	mov    %edx,%ecx
  801c06:	29 c1                	sub    %eax,%ecx
  801c08:	89 c8                	mov    %ecx,%eax
  801c0a:	ba 00 04 00 00       	mov    $0x400,%edx
  801c0f:	3d 00 04 00 00       	cmp    $0x400,%eax
  801c14:	0f 47 c2             	cmova  %edx,%eax
  801c17:	89 45 f0             	mov    %eax,-0x10(%ebp)

		m = read(fdnum, (char*)buf + tot, bytes_to_receive);
  801c1a:	8b 55 f0             	mov    -0x10(%ebp),%edx
  801c1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801c20:	03 45 0c             	add    0xc(%ebp),%eax
  801c23:	89 54 24 08          	mov    %edx,0x8(%esp)
  801c27:	89 44 24 04          	mov    %eax,0x4(%esp)
  801c2b:	8b 45 08             	mov    0x8(%ebp),%eax
  801c2e:	89 04 24             	mov    %eax,(%esp)
  801c31:	e8 13 ff ff ff       	call   801b49 <read>
  801c36:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (m < 0)
  801c39:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  801c3d:	79 05                	jns    801c44 <readn+0x55>
			return m;
  801c3f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801c42:	eb 1a                	jmp    801c5e <readn+0x6f>
		if (m == 0)
  801c44:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  801c48:	74 10                	je     801c5a <readn+0x6b>
ssize_t
readn(int fdnum, void *buf, size_t n)
{
	int m, tot;

	for (tot = 0; tot < n; tot += m) {
  801c4a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801c4d:	01 45 f4             	add    %eax,-0xc(%ebp)
  801c50:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801c53:	3b 45 10             	cmp    0x10(%ebp),%eax
  801c56:	72 a6                	jb     801bfe <readn+0xf>
  801c58:	eb 01                	jmp    801c5b <readn+0x6c>

		m = read(fdnum, (char*)buf + tot, bytes_to_receive);
		if (m < 0)
			return m;
		if (m == 0)
			break;
  801c5a:	90                   	nop
	}
	return tot;
  801c5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  801c5e:	c9                   	leave  
  801c5f:	c3                   	ret    

00801c60 <write>:

ssize_t
write(int fdnum, const void *buf, size_t n)
{
  801c60:	55                   	push   %ebp
  801c61:	89 e5                	mov    %esp,%ebp
  801c63:	83 ec 28             	sub    $0x28,%esp
	int r;
	struct Dev *dev;
	struct Fd *fd;

	if ((r = fd_lookup(fdnum, &fd)) < 0
  801c66:	8d 45 ec             	lea    -0x14(%ebp),%eax
  801c69:	89 44 24 04          	mov    %eax,0x4(%esp)
  801c6d:	8b 45 08             	mov    0x8(%ebp),%eax
  801c70:	89 04 24             	mov    %eax,(%esp)
  801c73:	e8 b9 fb ff ff       	call   801831 <fd_lookup>
  801c78:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801c7b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801c7f:	78 1d                	js     801c9e <write+0x3e>
	    || (r = dev_lookup(fd->fd_dev_id, &dev)) < 0)
  801c81:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801c84:	8b 00                	mov    (%eax),%eax
  801c86:	8d 55 f0             	lea    -0x10(%ebp),%edx
  801c89:	89 54 24 04          	mov    %edx,0x4(%esp)
  801c8d:	89 04 24             	mov    %eax,(%esp)
  801c90:	e8 9d fc ff ff       	call   801932 <dev_lookup>
  801c95:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801c98:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801c9c:	79 05                	jns    801ca3 <write+0x43>
		return r;
  801c9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801ca1:	eb 60                	jmp    801d03 <write+0xa3>
	if ((fd->fd_omode & O_ACCMODE) == O_RDONLY) {
  801ca3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801ca6:	8b 40 08             	mov    0x8(%eax),%eax
  801ca9:	83 e0 03             	and    $0x3,%eax
  801cac:	85 c0                	test   %eax,%eax
  801cae:	75 26                	jne    801cd6 <write+0x76>
		cprintf("[%08x] write %d -- bad mode\n", env->env_id, fdnum);
  801cb0:	a1 44 81 80 00       	mov    0x808144,%eax
  801cb5:	8b 40 4c             	mov    0x4c(%eax),%eax
  801cb8:	8b 55 08             	mov    0x8(%ebp),%edx
  801cbb:	89 54 24 08          	mov    %edx,0x8(%esp)
  801cbf:	89 44 24 04          	mov    %eax,0x4(%esp)
  801cc3:	c7 04 24 a3 3c 80 00 	movl   $0x803ca3,(%esp)
  801cca:	e8 82 ea ff ff       	call   800751 <cprintf>
		return -E_INVAL;
  801ccf:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  801cd4:	eb 2d                	jmp    801d03 <write+0xa3>
	}
	if (debug)
		cprintf("write %d %p %d via dev %s\n",
			fdnum, buf, n, dev->dev_name);
	if (!dev->dev_write)
  801cd6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801cd9:	8b 40 0c             	mov    0xc(%eax),%eax
  801cdc:	85 c0                	test   %eax,%eax
  801cde:	75 07                	jne    801ce7 <write+0x87>
		return -E_NOT_SUPP;
  801ce0:	b8 f1 ff ff ff       	mov    $0xfffffff1,%eax
  801ce5:	eb 1c                	jmp    801d03 <write+0xa3>
	return (*dev->dev_write)(fd, buf, n);
  801ce7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801cea:	8b 48 0c             	mov    0xc(%eax),%ecx
  801ced:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801cf0:	8b 55 10             	mov    0x10(%ebp),%edx
  801cf3:	89 54 24 08          	mov    %edx,0x8(%esp)
  801cf7:	8b 55 0c             	mov    0xc(%ebp),%edx
  801cfa:	89 54 24 04          	mov    %edx,0x4(%esp)
  801cfe:	89 04 24             	mov    %eax,(%esp)
  801d01:	ff d1                	call   *%ecx
}
  801d03:	c9                   	leave  
  801d04:	c3                   	ret    

00801d05 <seek>:

int
seek(int fdnum, off_t offset)
{
  801d05:	55                   	push   %ebp
  801d06:	89 e5                	mov    %esp,%ebp
  801d08:	83 ec 18             	sub    $0x18,%esp
	int r;
	struct Fd *fd;

	if ((r = fd_lookup(fdnum, &fd)) < 0)
  801d0b:	8d 45 f8             	lea    -0x8(%ebp),%eax
  801d0e:	89 44 24 04          	mov    %eax,0x4(%esp)
  801d12:	8b 45 08             	mov    0x8(%ebp),%eax
  801d15:	89 04 24             	mov    %eax,(%esp)
  801d18:	e8 14 fb ff ff       	call   801831 <fd_lookup>
  801d1d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  801d20:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
  801d24:	79 05                	jns    801d2b <seek+0x26>
		return r;
  801d26:	8b 45 fc             	mov    -0x4(%ebp),%eax
  801d29:	eb 0e                	jmp    801d39 <seek+0x34>
	fd->fd_offset = offset;
  801d2b:	8b 45 f8             	mov    -0x8(%ebp),%eax
  801d2e:	8b 55 0c             	mov    0xc(%ebp),%edx
  801d31:	89 50 04             	mov    %edx,0x4(%eax)
	return 0;
  801d34:	b8 00 00 00 00       	mov    $0x0,%eax
}
  801d39:	c9                   	leave  
  801d3a:	c3                   	ret    

00801d3b <ftruncate>:

int
ftruncate(int fdnum, off_t newsize)
{
  801d3b:	55                   	push   %ebp
  801d3c:	89 e5                	mov    %esp,%ebp
  801d3e:	83 ec 28             	sub    $0x28,%esp
	int r;
	struct Dev *dev;
	struct Fd *fd;
	if ((r = fd_lookup(fdnum, &fd)) < 0
  801d41:	8d 45 ec             	lea    -0x14(%ebp),%eax
  801d44:	89 44 24 04          	mov    %eax,0x4(%esp)
  801d48:	8b 45 08             	mov    0x8(%ebp),%eax
  801d4b:	89 04 24             	mov    %eax,(%esp)
  801d4e:	e8 de fa ff ff       	call   801831 <fd_lookup>
  801d53:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801d56:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801d5a:	78 1d                	js     801d79 <ftruncate+0x3e>
	    || (r = dev_lookup(fd->fd_dev_id, &dev)) < 0)
  801d5c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801d5f:	8b 00                	mov    (%eax),%eax
  801d61:	8d 55 f0             	lea    -0x10(%ebp),%edx
  801d64:	89 54 24 04          	mov    %edx,0x4(%esp)
  801d68:	89 04 24             	mov    %eax,(%esp)
  801d6b:	e8 c2 fb ff ff       	call   801932 <dev_lookup>
  801d70:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801d73:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801d77:	79 05                	jns    801d7e <ftruncate+0x43>
		return r;
  801d79:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801d7c:	eb 59                	jmp    801dd7 <ftruncate+0x9c>
	if ((fd->fd_omode & O_ACCMODE) == O_RDONLY) {
  801d7e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801d81:	8b 40 08             	mov    0x8(%eax),%eax
  801d84:	83 e0 03             	and    $0x3,%eax
  801d87:	85 c0                	test   %eax,%eax
  801d89:	75 26                	jne    801db1 <ftruncate+0x76>
		cprintf("[%08x] ftruncate %d -- bad mode\n",
			env->env_id, fdnum); 
  801d8b:	a1 44 81 80 00       	mov    0x808144,%eax
	struct Fd *fd;
	if ((r = fd_lookup(fdnum, &fd)) < 0
	    || (r = dev_lookup(fd->fd_dev_id, &dev)) < 0)
		return r;
	if ((fd->fd_omode & O_ACCMODE) == O_RDONLY) {
		cprintf("[%08x] ftruncate %d -- bad mode\n",
  801d90:	8b 40 4c             	mov    0x4c(%eax),%eax
  801d93:	8b 55 08             	mov    0x8(%ebp),%edx
  801d96:	89 54 24 08          	mov    %edx,0x8(%esp)
  801d9a:	89 44 24 04          	mov    %eax,0x4(%esp)
  801d9e:	c7 04 24 c0 3c 80 00 	movl   $0x803cc0,(%esp)
  801da5:	e8 a7 e9 ff ff       	call   800751 <cprintf>
			env->env_id, fdnum); 
		return -E_INVAL;
  801daa:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  801daf:	eb 26                	jmp    801dd7 <ftruncate+0x9c>
	}
	if (!dev->dev_trunc)
  801db1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801db4:	8b 40 18             	mov    0x18(%eax),%eax
  801db7:	85 c0                	test   %eax,%eax
  801db9:	75 07                	jne    801dc2 <ftruncate+0x87>
		return -E_NOT_SUPP;
  801dbb:	b8 f1 ff ff ff       	mov    $0xfffffff1,%eax
  801dc0:	eb 15                	jmp    801dd7 <ftruncate+0x9c>
	return (*dev->dev_trunc)(fd, newsize);
  801dc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801dc5:	8b 48 18             	mov    0x18(%eax),%ecx
  801dc8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801dcb:	8b 55 0c             	mov    0xc(%ebp),%edx
  801dce:	89 54 24 04          	mov    %edx,0x4(%esp)
  801dd2:	89 04 24             	mov    %eax,(%esp)
  801dd5:	ff d1                	call   *%ecx
}
  801dd7:	c9                   	leave  
  801dd8:	c3                   	ret    

00801dd9 <fstat>:

int
fstat(int fdnum, struct Stat *stat)
{
  801dd9:	55                   	push   %ebp
  801dda:	89 e5                	mov    %esp,%ebp
  801ddc:	83 ec 28             	sub    $0x28,%esp
	int r;
	struct Dev *dev;
	struct Fd *fd;

	if ((r = fd_lookup(fdnum, &fd)) < 0
  801ddf:	8d 45 ec             	lea    -0x14(%ebp),%eax
  801de2:	89 44 24 04          	mov    %eax,0x4(%esp)
  801de6:	8b 45 08             	mov    0x8(%ebp),%eax
  801de9:	89 04 24             	mov    %eax,(%esp)
  801dec:	e8 40 fa ff ff       	call   801831 <fd_lookup>
  801df1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801df4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801df8:	78 1d                	js     801e17 <fstat+0x3e>
	    || (r = dev_lookup(fd->fd_dev_id, &dev)) < 0)
  801dfa:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801dfd:	8b 00                	mov    (%eax),%eax
  801dff:	8d 55 f0             	lea    -0x10(%ebp),%edx
  801e02:	89 54 24 04          	mov    %edx,0x4(%esp)
  801e06:	89 04 24             	mov    %eax,(%esp)
  801e09:	e8 24 fb ff ff       	call   801932 <dev_lookup>
  801e0e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801e11:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801e15:	79 05                	jns    801e1c <fstat+0x43>
		return r;
  801e17:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801e1a:	eb 52                	jmp    801e6e <fstat+0x95>
	if (!dev->dev_stat)
  801e1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801e1f:	8b 40 14             	mov    0x14(%eax),%eax
  801e22:	85 c0                	test   %eax,%eax
  801e24:	75 07                	jne    801e2d <fstat+0x54>
		return -E_NOT_SUPP;
  801e26:	b8 f1 ff ff ff       	mov    $0xfffffff1,%eax
  801e2b:	eb 41                	jmp    801e6e <fstat+0x95>
	stat->st_name[0] = 0;
  801e2d:	8b 45 0c             	mov    0xc(%ebp),%eax
  801e30:	c6 00 00             	movb   $0x0,(%eax)
	stat->st_size = 0;
  801e33:	8b 45 0c             	mov    0xc(%ebp),%eax
  801e36:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
  801e3d:	00 00 00 
	stat->st_isdir = 0;
  801e40:	8b 45 0c             	mov    0xc(%ebp),%eax
  801e43:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
  801e4a:	00 00 00 
	stat->st_dev = dev;
  801e4d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  801e50:	8b 45 0c             	mov    0xc(%ebp),%eax
  801e53:	89 90 88 00 00 00    	mov    %edx,0x88(%eax)
	return (*dev->dev_stat)(fd, stat);
  801e59:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801e5c:	8b 48 14             	mov    0x14(%eax),%ecx
  801e5f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  801e62:	8b 55 0c             	mov    0xc(%ebp),%edx
  801e65:	89 54 24 04          	mov    %edx,0x4(%esp)
  801e69:	89 04 24             	mov    %eax,(%esp)
  801e6c:	ff d1                	call   *%ecx
}
  801e6e:	c9                   	leave  
  801e6f:	c3                   	ret    

00801e70 <stat>:

int
stat(const char *path, struct Stat *stat)
{
  801e70:	55                   	push   %ebp
  801e71:	89 e5                	mov    %esp,%ebp
  801e73:	83 ec 28             	sub    $0x28,%esp
	int fd, r;

	if ((fd = open(path, O_RDONLY)) < 0)
  801e76:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  801e7d:	00 
  801e7e:	8b 45 08             	mov    0x8(%ebp),%eax
  801e81:	89 04 24             	mov    %eax,(%esp)
  801e84:	e8 82 00 00 00       	call   801f0b <open>
  801e89:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801e8c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801e90:	79 05                	jns    801e97 <stat+0x27>
		return fd;
  801e92:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801e95:	eb 23                	jmp    801eba <stat+0x4a>
	r = fstat(fd, stat);
  801e97:	8b 45 0c             	mov    0xc(%ebp),%eax
  801e9a:	89 44 24 04          	mov    %eax,0x4(%esp)
  801e9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801ea1:	89 04 24             	mov    %eax,(%esp)
  801ea4:	e8 30 ff ff ff       	call   801dd9 <fstat>
  801ea9:	89 45 f0             	mov    %eax,-0x10(%ebp)
	close(fd);
  801eac:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801eaf:	89 04 24             	mov    %eax,(%esp)
  801eb2:	e8 f2 fa ff ff       	call   8019a9 <close>
	return r;
  801eb7:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  801eba:	c9                   	leave  
  801ebb:	c3                   	ret    

00801ebc <fsipc>:
// type: request code, passed as the simple integer IPC value.
// dstva: virtual address at which to receive reply page, 0 if none.
// Returns result from the file server.
static int
fsipc(unsigned type, void *dstva)
{
  801ebc:	55                   	push   %ebp
  801ebd:	89 e5                	mov    %esp,%ebp
  801ebf:	83 ec 18             	sub    $0x18,%esp
	if (debug)
		cprintf("[%08x] fsipc %d %08x\n", env->env_id, type, *(uint32_t *)&fsipcbuf);

	DPRINTF5("[%08x] fsipc(%d, %08x)\n", env->env_id, type, *(uint32_t *)&fsipcbuf);
  801ec2:	a1 44 81 80 00       	mov    0x808144,%eax
  801ec7:	8b 40 4c             	mov    0x4c(%eax),%eax

	ipc_send(envs[1].env_id, type, &fsipcbuf, PTE_P | PTE_W | PTE_U);
  801eca:	a1 c8 00 c0 ee       	mov    0xeec000c8,%eax
  801ecf:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
  801ed6:	00 
  801ed7:	c7 44 24 08 00 40 80 	movl   $0x804000,0x8(%esp)
  801ede:	00 
  801edf:	8b 55 08             	mov    0x8(%ebp),%edx
  801ee2:	89 54 24 04          	mov    %edx,0x4(%esp)
  801ee6:	89 04 24             	mov    %eax,(%esp)
  801ee9:	e8 75 0f 00 00       	call   802e63 <ipc_send>
	return ipc_recv(NULL, dstva, NULL);
  801eee:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  801ef5:	00 
  801ef6:	8b 45 0c             	mov    0xc(%ebp),%eax
  801ef9:	89 44 24 04          	mov    %eax,0x4(%esp)
  801efd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801f04:	e8 ab 0e 00 00       	call   802db4 <ipc_recv>
}
  801f09:	c9                   	leave  
  801f0a:	c3                   	ret    

00801f0b <open>:
// 	The file descriptor index on success
// 	-E_BAD_PATH if the path is too long (>= MAXPATHLEN)
// 	< 0 for other errors.
int
open(const char *path, int mode)
{
  801f0b:	55                   	push   %ebp
  801f0c:	89 e5                	mov    %esp,%ebp
  801f0e:	83 ec 28             	sub    $0x28,%esp
	// If any step after fd_alloc fails, use fd_close to free the
	// file descriptor.

	// LAB 5: Your code here.
	// panic("open not implemented");
	if (strlen(path) >= MAXPATHLEN) {
  801f11:	8b 45 08             	mov    0x8(%ebp),%eax
  801f14:	89 04 24             	mov    %eax,(%esp)
  801f17:	e8 c4 ee ff ff       	call   800de0 <strlen>
  801f1c:	3d ff 03 00 00       	cmp    $0x3ff,%eax
  801f21:	7e 0a                	jle    801f2d <open+0x22>
		return -E_BAD_PATH;
  801f23:	b8 f4 ff ff ff       	mov    $0xfffffff4,%eax
  801f28:	e9 82 00 00 00       	jmp    801faf <open+0xa4>
	}

	struct Fd *pfd = NULL;
  801f2d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	int r = fd_alloc(&pfd);
  801f34:	8d 45 f0             	lea    -0x10(%ebp),%eax
  801f37:	89 04 24             	mov    %eax,(%esp)
  801f3a:	e8 84 f8 ff ff       	call   8017c3 <fd_alloc>
  801f3f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (r < 0) {
  801f42:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801f46:	79 05                	jns    801f4d <open+0x42>
		return r;
  801f48:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801f4b:	eb 62                	jmp    801faf <open+0xa4>
	}

	strcpy(fsipcbuf.open.req_path, path);
  801f4d:	8b 45 08             	mov    0x8(%ebp),%eax
  801f50:	89 44 24 04          	mov    %eax,0x4(%esp)
  801f54:	c7 04 24 00 40 80 00 	movl   $0x804000,(%esp)
  801f5b:	e8 d6 ee ff ff       	call   800e36 <strcpy>
	fsipcbuf.open.req_omode = mode;
  801f60:	8b 45 0c             	mov    0xc(%ebp),%eax
  801f63:	a3 00 44 80 00       	mov    %eax,0x804400
	r = fsipc(FSREQ_OPEN, pfd);
  801f68:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801f6b:	89 44 24 04          	mov    %eax,0x4(%esp)
  801f6f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  801f76:	e8 41 ff ff ff       	call   801ebc <fsipc>
  801f7b:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if (r < 0) {
  801f7e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801f82:	78 0d                	js     801f91 <open+0x86>
		goto cleanup;
	}

	// return pfd->fd_file.id;
	return fd2num(pfd);
  801f84:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801f87:	89 04 24             	mov    %eax,(%esp)
  801f8a:	e8 09 f8 ff ff       	call   801798 <fd2num>
  801f8f:	eb 1e                	jmp    801faf <open+0xa4>
	strcpy(fsipcbuf.open.req_path, path);
	fsipcbuf.open.req_omode = mode;
	r = fsipc(FSREQ_OPEN, pfd);

	if (r < 0) {
		goto cleanup;
  801f91:	90                   	nop

	// return pfd->fd_file.id;
	return fd2num(pfd);

 cleanup:
	if (pfd) {
  801f92:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801f95:	85 c0                	test   %eax,%eax
  801f97:	74 13                	je     801fac <open+0xa1>
		fd_close(pfd, 0);
  801f99:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801f9c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  801fa3:	00 
  801fa4:	89 04 24             	mov    %eax,(%esp)
  801fa7:	e8 ea f8 ff ff       	call   801896 <fd_close>
	}
	return r;
  801fac:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  801faf:	c9                   	leave  
  801fb0:	c3                   	ret    

00801fb1 <devfile_flush>:
// open, unmapping it is enough to free up server-side resources.
// Other than that, we just have to make sure our changes are flushed
// to disk.
static int
devfile_flush(struct Fd *fd)
{
  801fb1:	55                   	push   %ebp
  801fb2:	89 e5                	mov    %esp,%ebp
  801fb4:	83 ec 18             	sub    $0x18,%esp
	fsipcbuf.flush.req_fileid = fd->fd_file.id;
  801fb7:	8b 45 08             	mov    0x8(%ebp),%eax
  801fba:	8b 40 0c             	mov    0xc(%eax),%eax
  801fbd:	a3 00 40 80 00       	mov    %eax,0x804000
	return fsipc(FSREQ_FLUSH, NULL);
  801fc2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  801fc9:	00 
  801fca:	c7 04 24 06 00 00 00 	movl   $0x6,(%esp)
  801fd1:	e8 e6 fe ff ff       	call   801ebc <fsipc>
}
  801fd6:	c9                   	leave  
  801fd7:	c3                   	ret    

00801fd8 <devfile_read>:
// Returns:
// 	The number of bytes successfully read.
// 	< 0 on error.
static ssize_t
devfile_read(struct Fd *fd, void *buf, size_t n)
{
  801fd8:	55                   	push   %ebp
  801fd9:	89 e5                	mov    %esp,%ebp
  801fdb:	83 ec 28             	sub    $0x28,%esp
	// LAB 5: Your code here
	// panic("devfile_read not implemented");
	DPRINTF5("devfile_read(%x, %x, %d)\n", fd, buf, n);

	int r;
	fsipcbuf.read.req_fileid = fd->fd_file.id;
  801fde:	8b 45 08             	mov    0x8(%ebp),%eax
  801fe1:	8b 40 0c             	mov    0xc(%eax),%eax
  801fe4:	a3 00 40 80 00       	mov    %eax,0x804000
	fsipcbuf.read.req_n = n;
  801fe9:	8b 45 10             	mov    0x10(%ebp),%eax
  801fec:	a3 04 40 80 00       	mov    %eax,0x804004

	// DPRINTF5("devfile_read::fileid: %d, req_n: %d\n", fsipcbuf.read.req_fileid, fsipcbuf.read.req_n);

	r = fsipc(FSREQ_READ, 0);
  801ff1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  801ff8:	00 
  801ff9:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
  802000:	e8 b7 fe ff ff       	call   801ebc <fsipc>
  802005:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// DPRINTF5("devfile_read got %d(%e) from fsipc\n", r, r);

	if (r < 0) {
  802008:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  80200c:	79 05                	jns    802013 <devfile_read+0x3b>
		return r;
  80200e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802011:	eb 50                	jmp    802063 <devfile_read+0x8b>
	}
	assert(r >= 0 && r <= PGSIZE);
  802013:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802017:	78 09                	js     802022 <devfile_read+0x4a>
  802019:	81 7d f4 00 10 00 00 	cmpl   $0x1000,-0xc(%ebp)
  802020:	7e 24                	jle    802046 <devfile_read+0x6e>
  802022:	c7 44 24 0c e6 3c 80 	movl   $0x803ce6,0xc(%esp)
  802029:	00 
  80202a:	c7 44 24 08 fc 3c 80 	movl   $0x803cfc,0x8(%esp)
  802031:	00 
  802032:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  802039:	00 
  80203a:	c7 04 24 11 3d 80 00 	movl   $0x803d11,(%esp)
  802041:	e8 da e5 ff ff       	call   800620 <_panic>
	memmove(buf, &(fsipcbuf.readRet.ret_buf), r);
  802046:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802049:	89 44 24 08          	mov    %eax,0x8(%esp)
  80204d:	c7 44 24 04 00 40 80 	movl   $0x804000,0x4(%esp)
  802054:	00 
  802055:	8b 45 0c             	mov    0xc(%ebp),%eax
  802058:	89 04 24             	mov    %eax,(%esp)
  80205b:	e8 c8 ef ff ff       	call   801028 <memmove>
	// if (r < PGSIZE) {
	// ((char*)buf)[r] = '\0';
	// }
	// DPRINTF5("Got (buf): %s\n", buf);

	return r;
  802060:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  802063:	c9                   	leave  
  802064:	c3                   	ret    

00802065 <devfile_write>:
// Returns:
//	 The number of bytes successfully written.
//	 < 0 on error.
static ssize_t
devfile_write(struct Fd *fd, const void *buf, size_t n)
{
  802065:	55                   	push   %ebp
  802066:	89 e5                	mov    %esp,%ebp
  802068:	83 ec 28             	sub    $0x28,%esp
	// careful: fsipcbuf.write.req_buf is only so large, but
	// remember that write is always allowed to write *fewer*
	// bytes than requested.
	// LAB 5: Your code here
	DPRINTF5("devfile_write: writing %d bytes\n:", n);
	assert(buf);
  80206b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  80206f:	75 24                	jne    802095 <devfile_write+0x30>
  802071:	c7 44 24 0c 1c 3d 80 	movl   $0x803d1c,0xc(%esp)
  802078:	00 
  802079:	c7 44 24 08 fc 3c 80 	movl   $0x803cfc,0x8(%esp)
  802080:	00 
  802081:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  802088:	00 
  802089:	c7 04 24 11 3d 80 00 	movl   $0x803d11,(%esp)
  802090:	e8 8b e5 ff ff       	call   800620 <_panic>
	fsipcbuf.write.req_fileid = fd->fd_file.id;
  802095:	8b 45 08             	mov    0x8(%ebp),%eax
  802098:	8b 40 0c             	mov    0xc(%eax),%eax
  80209b:	a3 00 40 80 00       	mov    %eax,0x804000

	ssize_t written = 0;
  8020a0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	size_t write_limit = sizeof(fsipcbuf.write.req_buf);
  8020a7:	c7 45 f0 f8 0f 00 00 	movl   $0xff8,-0x10(%ebp)

	while (n > 0) {
  8020ae:	eb 60                	jmp    802110 <devfile_write+0xab>
		size_t part_size = n < write_limit ? n : write_limit;
  8020b0:	8b 45 10             	mov    0x10(%ebp),%eax
  8020b3:	39 45 f0             	cmp    %eax,-0x10(%ebp)
  8020b6:	0f 46 45 f0          	cmovbe -0x10(%ebp),%eax
  8020ba:	89 45 ec             	mov    %eax,-0x14(%ebp)
		memmove(fsipcbuf.write.req_buf, buf + written, part_size);
  8020bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8020c0:	03 45 0c             	add    0xc(%ebp),%eax
  8020c3:	8b 55 ec             	mov    -0x14(%ebp),%edx
  8020c6:	89 54 24 08          	mov    %edx,0x8(%esp)
  8020ca:	89 44 24 04          	mov    %eax,0x4(%esp)
  8020ce:	c7 04 24 08 40 80 00 	movl   $0x804008,(%esp)
  8020d5:	e8 4e ef ff ff       	call   801028 <memmove>
		fsipcbuf.write.req_n = part_size;
  8020da:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8020dd:	a3 04 40 80 00       	mov    %eax,0x804004

		ssize_t part_written = fsipc(FSREQ_WRITE, NULL);
  8020e2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8020e9:	00 
  8020ea:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  8020f1:	e8 c6 fd ff ff       	call   801ebc <fsipc>
  8020f6:	89 45 e8             	mov    %eax,-0x18(%ebp)

		if(part_written < 0) {
  8020f9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  8020fd:	79 05                	jns    802104 <devfile_write+0x9f>
			DPRINTF5("devfile_write: Error writing: %e.\n", part_written);
			return part_written;
  8020ff:	8b 45 e8             	mov    -0x18(%ebp),%eax
  802102:	eb 15                	jmp    802119 <devfile_write+0xb4>
		}

		DPRINTF5("devfile_write: Wrote %d bytes of %d.\n", part_written, n);

		written += part_written;
  802104:	8b 45 e8             	mov    -0x18(%ebp),%eax
  802107:	01 45 f4             	add    %eax,-0xc(%ebp)
		n -= part_written;
  80210a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  80210d:	29 45 10             	sub    %eax,0x10(%ebp)
	fsipcbuf.write.req_fileid = fd->fd_file.id;

	ssize_t written = 0;
	size_t write_limit = sizeof(fsipcbuf.write.req_buf);

	while (n > 0) {
  802110:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  802114:	75 9a                	jne    8020b0 <devfile_write+0x4b>

		written += part_written;
		n -= part_written;
	}

	return written;
  802116:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  802119:	c9                   	leave  
  80211a:	c3                   	ret    

0080211b <devfile_stat>:

static int
devfile_stat(struct Fd *fd, struct Stat *st)
{
  80211b:	55                   	push   %ebp
  80211c:	89 e5                	mov    %esp,%ebp
  80211e:	83 ec 28             	sub    $0x28,%esp
	int r;

	fsipcbuf.stat.req_fileid = fd->fd_file.id;
  802121:	8b 45 08             	mov    0x8(%ebp),%eax
  802124:	8b 40 0c             	mov    0xc(%eax),%eax
  802127:	a3 00 40 80 00       	mov    %eax,0x804000
	if ((r = fsipc(FSREQ_STAT, NULL)) < 0)
  80212c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  802133:	00 
  802134:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
  80213b:	e8 7c fd ff ff       	call   801ebc <fsipc>
  802140:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802143:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802147:	79 05                	jns    80214e <devfile_stat+0x33>
		return r;
  802149:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80214c:	eb 36                	jmp    802184 <devfile_stat+0x69>
	strcpy(st->st_name, fsipcbuf.statRet.ret_name);
  80214e:	8b 45 0c             	mov    0xc(%ebp),%eax
  802151:	c7 44 24 04 00 40 80 	movl   $0x804000,0x4(%esp)
  802158:	00 
  802159:	89 04 24             	mov    %eax,(%esp)
  80215c:	e8 d5 ec ff ff       	call   800e36 <strcpy>
	st->st_size = fsipcbuf.statRet.ret_size;
  802161:	8b 15 80 40 80 00    	mov    0x804080,%edx
  802167:	8b 45 0c             	mov    0xc(%ebp),%eax
  80216a:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
	st->st_isdir = fsipcbuf.statRet.ret_isdir;
  802170:	8b 15 84 40 80 00    	mov    0x804084,%edx
  802176:	8b 45 0c             	mov    0xc(%ebp),%eax
  802179:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
	return 0;
  80217f:	b8 00 00 00 00       	mov    $0x0,%eax
}
  802184:	c9                   	leave  
  802185:	c3                   	ret    

00802186 <devfile_trunc>:

// Truncate or extend an open file to 'size' bytes
static int
devfile_trunc(struct Fd *fd, off_t newsize)
{
  802186:	55                   	push   %ebp
  802187:	89 e5                	mov    %esp,%ebp
  802189:	83 ec 18             	sub    $0x18,%esp
	fsipcbuf.set_size.req_fileid = fd->fd_file.id;
  80218c:	8b 45 08             	mov    0x8(%ebp),%eax
  80218f:	8b 40 0c             	mov    0xc(%eax),%eax
  802192:	a3 00 40 80 00       	mov    %eax,0x804000
	fsipcbuf.set_size.req_size = newsize;
  802197:	8b 45 0c             	mov    0xc(%ebp),%eax
  80219a:	a3 04 40 80 00       	mov    %eax,0x804004
	return fsipc(FSREQ_SET_SIZE, NULL);
  80219f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8021a6:	00 
  8021a7:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  8021ae:	e8 09 fd ff ff       	call   801ebc <fsipc>
}
  8021b3:	c9                   	leave  
  8021b4:	c3                   	ret    

008021b5 <remove>:

// Delete a file
int
remove(const char *path)
{
  8021b5:	55                   	push   %ebp
  8021b6:	89 e5                	mov    %esp,%ebp
  8021b8:	83 ec 18             	sub    $0x18,%esp
	if (strlen(path) >= MAXPATHLEN)
  8021bb:	8b 45 08             	mov    0x8(%ebp),%eax
  8021be:	89 04 24             	mov    %eax,(%esp)
  8021c1:	e8 1a ec ff ff       	call   800de0 <strlen>
  8021c6:	3d ff 03 00 00       	cmp    $0x3ff,%eax
  8021cb:	7e 07                	jle    8021d4 <remove+0x1f>
		return -E_BAD_PATH;
  8021cd:	b8 f4 ff ff ff       	mov    $0xfffffff4,%eax
  8021d2:	eb 27                	jmp    8021fb <remove+0x46>
	strcpy(fsipcbuf.remove.req_path, path);
  8021d4:	8b 45 08             	mov    0x8(%ebp),%eax
  8021d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8021db:	c7 04 24 00 40 80 00 	movl   $0x804000,(%esp)
  8021e2:	e8 4f ec ff ff       	call   800e36 <strcpy>
	return fsipc(FSREQ_REMOVE, NULL);
  8021e7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8021ee:	00 
  8021ef:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
  8021f6:	e8 c1 fc ff ff       	call   801ebc <fsipc>
}
  8021fb:	c9                   	leave  
  8021fc:	c3                   	ret    

008021fd <sync>:

// Synchronize disk with buffer cache
int
sync(void)
{
  8021fd:	55                   	push   %ebp
  8021fe:	89 e5                	mov    %esp,%ebp
  802200:	83 ec 18             	sub    $0x18,%esp
	// Ask the file server to update the disk
	// by writing any dirty blocks in the buffer cache.

	return fsipc(FSREQ_SYNC, NULL);
  802203:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  80220a:	00 
  80220b:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  802212:	e8 a5 fc ff ff       	call   801ebc <fsipc>
}
  802217:	c9                   	leave  
  802218:	c3                   	ret    
  802219:	00 00                	add    %al,(%eax)
	...

0080221c <fd2sockid>:
	.dev_stat =	devsock_stat,
};

static int
fd2sockid(int fd)
{
  80221c:	55                   	push   %ebp
  80221d:	89 e5                	mov    %esp,%ebp
  80221f:	83 ec 28             	sub    $0x28,%esp
	struct Fd *sfd;
	int r;

	if ((r = fd_lookup(fd, &sfd)) < 0)
  802222:	8d 45 f0             	lea    -0x10(%ebp),%eax
  802225:	89 44 24 04          	mov    %eax,0x4(%esp)
  802229:	8b 45 08             	mov    0x8(%ebp),%eax
  80222c:	89 04 24             	mov    %eax,(%esp)
  80222f:	e8 fd f5 ff ff       	call   801831 <fd_lookup>
  802234:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802237:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  80223b:	79 05                	jns    802242 <fd2sockid+0x26>
		return r;
  80223d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802240:	eb 1b                	jmp    80225d <fd2sockid+0x41>
	if (sfd->fd_dev_id != devsock.dev_id)
  802242:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802245:	8b 10                	mov    (%eax),%edx
  802247:	a1 34 70 80 00       	mov    0x807034,%eax
  80224c:	39 c2                	cmp    %eax,%edx
  80224e:	74 07                	je     802257 <fd2sockid+0x3b>
		return -E_NOT_SUPP;
  802250:	b8 f1 ff ff ff       	mov    $0xfffffff1,%eax
  802255:	eb 06                	jmp    80225d <fd2sockid+0x41>
	return sfd->fd_sock.sockid;
  802257:	8b 45 f0             	mov    -0x10(%ebp),%eax
  80225a:	8b 40 0c             	mov    0xc(%eax),%eax
}
  80225d:	c9                   	leave  
  80225e:	c3                   	ret    

0080225f <alloc_sockfd>:

static int
alloc_sockfd(int sockid)
{
  80225f:	55                   	push   %ebp
  802260:	89 e5                	mov    %esp,%ebp
  802262:	83 ec 28             	sub    $0x28,%esp
	struct Fd *sfd;
	int r;

	if ((r = fd_alloc(&sfd)) < 0
  802265:	8d 45 f0             	lea    -0x10(%ebp),%eax
  802268:	89 04 24             	mov    %eax,(%esp)
  80226b:	e8 53 f5 ff ff       	call   8017c3 <fd_alloc>
  802270:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802273:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802277:	78 24                	js     80229d <alloc_sockfd+0x3e>
	    || (r = sys_page_alloc(0, sfd, PTE_P|PTE_W|PTE_U)) < 0) {
  802279:	8b 45 f0             	mov    -0x10(%ebp),%eax
  80227c:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  802283:	00 
  802284:	89 44 24 04          	mov    %eax,0x4(%esp)
  802288:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80228f:	e8 e2 f1 ff ff       	call   801476 <sys_page_alloc>
  802294:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802297:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  80229b:	79 10                	jns    8022ad <alloc_sockfd+0x4e>
		nsipc_close(sockid);
  80229d:	8b 45 08             	mov    0x8(%ebp),%eax
  8022a0:	89 04 24             	mov    %eax,(%esp)
  8022a3:	e8 28 03 00 00       	call   8025d0 <nsipc_close>
		return r;
  8022a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8022ab:	eb 29                	jmp    8022d6 <alloc_sockfd+0x77>
	}

	sfd->fd_dev_id = devsock.dev_id;
  8022ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8022b0:	8b 15 34 70 80 00    	mov    0x807034,%edx
  8022b6:	89 10                	mov    %edx,(%eax)
	sfd->fd_omode = O_RDWR;
  8022b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8022bb:	c7 40 08 02 00 00 00 	movl   $0x2,0x8(%eax)
	sfd->fd_sock.sockid = sockid;
  8022c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8022c5:	8b 55 08             	mov    0x8(%ebp),%edx
  8022c8:	89 50 0c             	mov    %edx,0xc(%eax)
	return fd2num(sfd);
  8022cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8022ce:	89 04 24             	mov    %eax,(%esp)
  8022d1:	e8 c2 f4 ff ff       	call   801798 <fd2num>
}
  8022d6:	c9                   	leave  
  8022d7:	c3                   	ret    

008022d8 <accept>:

int
accept(int s, struct sockaddr *addr, socklen_t *addrlen)
{
  8022d8:	55                   	push   %ebp
  8022d9:	89 e5                	mov    %esp,%ebp
  8022db:	83 ec 28             	sub    $0x28,%esp
	int r;
	if ((r = fd2sockid(s)) < 0)
  8022de:	8b 45 08             	mov    0x8(%ebp),%eax
  8022e1:	89 04 24             	mov    %eax,(%esp)
  8022e4:	e8 33 ff ff ff       	call   80221c <fd2sockid>
  8022e9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  8022ec:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  8022f0:	79 05                	jns    8022f7 <accept+0x1f>
		return r;
  8022f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8022f5:	eb 32                	jmp    802329 <accept+0x51>
	if ((r = nsipc_accept(r, addr, addrlen)) < 0)
  8022f7:	8b 45 10             	mov    0x10(%ebp),%eax
  8022fa:	89 44 24 08          	mov    %eax,0x8(%esp)
  8022fe:	8b 45 0c             	mov    0xc(%ebp),%eax
  802301:	89 44 24 04          	mov    %eax,0x4(%esp)
  802305:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802308:	89 04 24             	mov    %eax,(%esp)
  80230b:	e8 08 02 00 00       	call   802518 <nsipc_accept>
  802310:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802313:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802317:	79 05                	jns    80231e <accept+0x46>
		return r;
  802319:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80231c:	eb 0b                	jmp    802329 <accept+0x51>
	return alloc_sockfd(r);
  80231e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802321:	89 04 24             	mov    %eax,(%esp)
  802324:	e8 36 ff ff ff       	call   80225f <alloc_sockfd>
}
  802329:	c9                   	leave  
  80232a:	c3                   	ret    

0080232b <bind>:

int
bind(int s, struct sockaddr *name, socklen_t namelen)
{
  80232b:	55                   	push   %ebp
  80232c:	89 e5                	mov    %esp,%ebp
  80232e:	83 ec 28             	sub    $0x28,%esp
	int r;
	if ((r = fd2sockid(s)) < 0)
  802331:	8b 45 08             	mov    0x8(%ebp),%eax
  802334:	89 04 24             	mov    %eax,(%esp)
  802337:	e8 e0 fe ff ff       	call   80221c <fd2sockid>
  80233c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  80233f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802343:	79 05                	jns    80234a <bind+0x1f>
		return r;
  802345:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802348:	eb 19                	jmp    802363 <bind+0x38>
	return nsipc_bind(r, name, namelen);
  80234a:	8b 45 10             	mov    0x10(%ebp),%eax
  80234d:	89 44 24 08          	mov    %eax,0x8(%esp)
  802351:	8b 45 0c             	mov    0xc(%ebp),%eax
  802354:	89 44 24 04          	mov    %eax,0x4(%esp)
  802358:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80235b:	89 04 24             	mov    %eax,(%esp)
  80235e:	e8 0b 02 00 00       	call   80256e <nsipc_bind>
}
  802363:	c9                   	leave  
  802364:	c3                   	ret    

00802365 <shutdown>:

int
shutdown(int s, int how)
{
  802365:	55                   	push   %ebp
  802366:	89 e5                	mov    %esp,%ebp
  802368:	83 ec 28             	sub    $0x28,%esp
	int r;
	if ((r = fd2sockid(s)) < 0)
  80236b:	8b 45 08             	mov    0x8(%ebp),%eax
  80236e:	89 04 24             	mov    %eax,(%esp)
  802371:	e8 a6 fe ff ff       	call   80221c <fd2sockid>
  802376:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802379:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  80237d:	79 05                	jns    802384 <shutdown+0x1f>
		return r;
  80237f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802382:	eb 12                	jmp    802396 <shutdown+0x31>
	return nsipc_shutdown(r, how);
  802384:	8b 45 0c             	mov    0xc(%ebp),%eax
  802387:	89 44 24 04          	mov    %eax,0x4(%esp)
  80238b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80238e:	89 04 24             	mov    %eax,(%esp)
  802391:	e8 16 02 00 00       	call   8025ac <nsipc_shutdown>
}
  802396:	c9                   	leave  
  802397:	c3                   	ret    

00802398 <devsock_close>:

static int
devsock_close(struct Fd *fd)
{
  802398:	55                   	push   %ebp
  802399:	89 e5                	mov    %esp,%ebp
  80239b:	83 ec 18             	sub    $0x18,%esp
	return nsipc_close(fd->fd_sock.sockid);
  80239e:	8b 45 08             	mov    0x8(%ebp),%eax
  8023a1:	8b 40 0c             	mov    0xc(%eax),%eax
  8023a4:	89 04 24             	mov    %eax,(%esp)
  8023a7:	e8 24 02 00 00       	call   8025d0 <nsipc_close>
}
  8023ac:	c9                   	leave  
  8023ad:	c3                   	ret    

008023ae <connect>:

int
connect(int s, const struct sockaddr *name, socklen_t namelen)
{
  8023ae:	55                   	push   %ebp
  8023af:	89 e5                	mov    %esp,%ebp
  8023b1:	83 ec 28             	sub    $0x28,%esp
	int r;
	if ((r = fd2sockid(s)) < 0)
  8023b4:	8b 45 08             	mov    0x8(%ebp),%eax
  8023b7:	89 04 24             	mov    %eax,(%esp)
  8023ba:	e8 5d fe ff ff       	call   80221c <fd2sockid>
  8023bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  8023c2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  8023c6:	79 05                	jns    8023cd <connect+0x1f>
		return r;
  8023c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8023cb:	eb 19                	jmp    8023e6 <connect+0x38>
	return nsipc_connect(r, name, namelen);
  8023cd:	8b 45 10             	mov    0x10(%ebp),%eax
  8023d0:	89 44 24 08          	mov    %eax,0x8(%esp)
  8023d4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8023d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8023db:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8023de:	89 04 24             	mov    %eax,(%esp)
  8023e1:	e8 06 02 00 00       	call   8025ec <nsipc_connect>
}
  8023e6:	c9                   	leave  
  8023e7:	c3                   	ret    

008023e8 <listen>:

int
listen(int s, int backlog)
{
  8023e8:	55                   	push   %ebp
  8023e9:	89 e5                	mov    %esp,%ebp
  8023eb:	83 ec 28             	sub    $0x28,%esp
	int r;
	if ((r = fd2sockid(s)) < 0)
  8023ee:	8b 45 08             	mov    0x8(%ebp),%eax
  8023f1:	89 04 24             	mov    %eax,(%esp)
  8023f4:	e8 23 fe ff ff       	call   80221c <fd2sockid>
  8023f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  8023fc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802400:	79 05                	jns    802407 <listen+0x1f>
		return r;
  802402:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802405:	eb 12                	jmp    802419 <listen+0x31>
	return nsipc_listen(r, backlog);
  802407:	8b 45 0c             	mov    0xc(%ebp),%eax
  80240a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80240e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802411:	89 04 24             	mov    %eax,(%esp)
  802414:	e8 11 02 00 00       	call   80262a <nsipc_listen>
}
  802419:	c9                   	leave  
  80241a:	c3                   	ret    

0080241b <devsock_read>:

static ssize_t
devsock_read(struct Fd *fd, void *buf, size_t n)
{
  80241b:	55                   	push   %ebp
  80241c:	89 e5                	mov    %esp,%ebp
  80241e:	83 ec 18             	sub    $0x18,%esp
	return nsipc_recv(fd->fd_sock.sockid, buf, n, 0);
  802421:	8b 55 10             	mov    0x10(%ebp),%edx
  802424:	8b 45 08             	mov    0x8(%ebp),%eax
  802427:	8b 40 0c             	mov    0xc(%eax),%eax
  80242a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  802431:	00 
  802432:	89 54 24 08          	mov    %edx,0x8(%esp)
  802436:	8b 55 0c             	mov    0xc(%ebp),%edx
  802439:	89 54 24 04          	mov    %edx,0x4(%esp)
  80243d:	89 04 24             	mov    %eax,(%esp)
  802440:	e8 09 02 00 00       	call   80264e <nsipc_recv>
}
  802445:	c9                   	leave  
  802446:	c3                   	ret    

00802447 <devsock_write>:

static ssize_t
devsock_write(struct Fd *fd, const void *buf, size_t n)
{
  802447:	55                   	push   %ebp
  802448:	89 e5                	mov    %esp,%ebp
  80244a:	83 ec 18             	sub    $0x18,%esp
	return nsipc_send(fd->fd_sock.sockid, buf, n, 0);
  80244d:	8b 55 10             	mov    0x10(%ebp),%edx
  802450:	8b 45 08             	mov    0x8(%ebp),%eax
  802453:	8b 40 0c             	mov    0xc(%eax),%eax
  802456:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  80245d:	00 
  80245e:	89 54 24 08          	mov    %edx,0x8(%esp)
  802462:	8b 55 0c             	mov    0xc(%ebp),%edx
  802465:	89 54 24 04          	mov    %edx,0x4(%esp)
  802469:	89 04 24             	mov    %eax,(%esp)
  80246c:	e8 64 02 00 00       	call   8026d5 <nsipc_send>
}
  802471:	c9                   	leave  
  802472:	c3                   	ret    

00802473 <devsock_stat>:

static int
devsock_stat(struct Fd *fd, struct Stat *stat)
{
  802473:	55                   	push   %ebp
  802474:	89 e5                	mov    %esp,%ebp
  802476:	83 ec 18             	sub    $0x18,%esp
	strcpy(stat->st_name, "<sock>");
  802479:	8b 45 0c             	mov    0xc(%ebp),%eax
  80247c:	c7 44 24 04 25 3d 80 	movl   $0x803d25,0x4(%esp)
  802483:	00 
  802484:	89 04 24             	mov    %eax,(%esp)
  802487:	e8 aa e9 ff ff       	call   800e36 <strcpy>
	return 0;
  80248c:	b8 00 00 00 00       	mov    $0x0,%eax
}
  802491:	c9                   	leave  
  802492:	c3                   	ret    

00802493 <socket>:

int
socket(int domain, int type, int protocol)
{
  802493:	55                   	push   %ebp
  802494:	89 e5                	mov    %esp,%ebp
  802496:	83 ec 28             	sub    $0x28,%esp
	int r;
	if ((r = nsipc_socket(domain, type, protocol)) < 0)
  802499:	8b 45 10             	mov    0x10(%ebp),%eax
  80249c:	89 44 24 08          	mov    %eax,0x8(%esp)
  8024a0:	8b 45 0c             	mov    0xc(%ebp),%eax
  8024a3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8024a7:	8b 45 08             	mov    0x8(%ebp),%eax
  8024aa:	89 04 24             	mov    %eax,(%esp)
  8024ad:	e8 96 02 00 00       	call   802748 <nsipc_socket>
  8024b2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  8024b5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  8024b9:	79 05                	jns    8024c0 <socket+0x2d>
		return r;
  8024bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8024be:	eb 0b                	jmp    8024cb <socket+0x38>
	return alloc_sockfd(r);
  8024c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8024c3:	89 04 24             	mov    %eax,(%esp)
  8024c6:	e8 94 fd ff ff       	call   80225f <alloc_sockfd>
}
  8024cb:	c9                   	leave  
  8024cc:	c3                   	ret    
  8024cd:	00 00                	add    %al,(%eax)
	...

008024d0 <nsipc>:
// may be written back to nsipcbuf.
// type: request code, passed as the simple integer IPC value.
// Returns 0 if successful, < 0 on failure.
static int
nsipc(unsigned type)
{
  8024d0:	55                   	push   %ebp
  8024d1:	89 e5                	mov    %esp,%ebp
  8024d3:	83 ec 18             	sub    $0x18,%esp
	if (debug)
		cprintf("[%08x] nsipc %d\n", env->env_id, type);

	ipc_send(envs[2].env_id, type, &nsipcbuf, PTE_P|PTE_W|PTE_U);
  8024d6:	a1 44 01 c0 ee       	mov    0xeec00144,%eax
  8024db:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
  8024e2:	00 
  8024e3:	c7 44 24 08 00 60 80 	movl   $0x806000,0x8(%esp)
  8024ea:	00 
  8024eb:	8b 55 08             	mov    0x8(%ebp),%edx
  8024ee:	89 54 24 04          	mov    %edx,0x4(%esp)
  8024f2:	89 04 24             	mov    %eax,(%esp)
  8024f5:	e8 69 09 00 00       	call   802e63 <ipc_send>
	return ipc_recv(NULL, NULL, NULL);
  8024fa:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  802501:	00 
  802502:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  802509:	00 
  80250a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  802511:	e8 9e 08 00 00       	call   802db4 <ipc_recv>
}
  802516:	c9                   	leave  
  802517:	c3                   	ret    

00802518 <nsipc_accept>:

int
nsipc_accept(int s, struct sockaddr *addr, socklen_t *addrlen)
{
  802518:	55                   	push   %ebp
  802519:	89 e5                	mov    %esp,%ebp
  80251b:	83 ec 28             	sub    $0x28,%esp
	int r;
	
	nsipcbuf.accept.req_s = s;
  80251e:	8b 45 08             	mov    0x8(%ebp),%eax
  802521:	a3 00 60 80 00       	mov    %eax,0x806000
	if ((r = nsipc(NSREQ_ACCEPT)) >= 0) {
  802526:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  80252d:	e8 9e ff ff ff       	call   8024d0 <nsipc>
  802532:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802535:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802539:	78 2e                	js     802569 <nsipc_accept+0x51>
		struct Nsret_accept *ret = &nsipcbuf.acceptRet;
  80253b:	c7 45 f0 00 60 80 00 	movl   $0x806000,-0x10(%ebp)
		memmove(addr, &ret->ret_addr, ret->ret_addrlen);
  802542:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802545:	8b 50 10             	mov    0x10(%eax),%edx
  802548:	8b 45 f0             	mov    -0x10(%ebp),%eax
  80254b:	89 54 24 08          	mov    %edx,0x8(%esp)
  80254f:	89 44 24 04          	mov    %eax,0x4(%esp)
  802553:	8b 45 0c             	mov    0xc(%ebp),%eax
  802556:	89 04 24             	mov    %eax,(%esp)
  802559:	e8 ca ea ff ff       	call   801028 <memmove>
		*addrlen = ret->ret_addrlen;
  80255e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802561:	8b 50 10             	mov    0x10(%eax),%edx
  802564:	8b 45 10             	mov    0x10(%ebp),%eax
  802567:	89 10                	mov    %edx,(%eax)
	}
	return r;
  802569:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  80256c:	c9                   	leave  
  80256d:	c3                   	ret    

0080256e <nsipc_bind>:

int
nsipc_bind(int s, struct sockaddr *name, socklen_t namelen)
{
  80256e:	55                   	push   %ebp
  80256f:	89 e5                	mov    %esp,%ebp
  802571:	83 ec 18             	sub    $0x18,%esp
	nsipcbuf.bind.req_s = s;
  802574:	8b 45 08             	mov    0x8(%ebp),%eax
  802577:	a3 00 60 80 00       	mov    %eax,0x806000
	memmove(&nsipcbuf.bind.req_name, name, namelen);
  80257c:	8b 45 10             	mov    0x10(%ebp),%eax
  80257f:	89 44 24 08          	mov    %eax,0x8(%esp)
  802583:	8b 45 0c             	mov    0xc(%ebp),%eax
  802586:	89 44 24 04          	mov    %eax,0x4(%esp)
  80258a:	c7 04 24 04 60 80 00 	movl   $0x806004,(%esp)
  802591:	e8 92 ea ff ff       	call   801028 <memmove>
	nsipcbuf.bind.req_namelen = namelen;
  802596:	8b 45 10             	mov    0x10(%ebp),%eax
  802599:	a3 14 60 80 00       	mov    %eax,0x806014
	return nsipc(NSREQ_BIND);
  80259e:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  8025a5:	e8 26 ff ff ff       	call   8024d0 <nsipc>
}
  8025aa:	c9                   	leave  
  8025ab:	c3                   	ret    

008025ac <nsipc_shutdown>:

int
nsipc_shutdown(int s, int how)
{
  8025ac:	55                   	push   %ebp
  8025ad:	89 e5                	mov    %esp,%ebp
  8025af:	83 ec 18             	sub    $0x18,%esp
	nsipcbuf.shutdown.req_s = s;
  8025b2:	8b 45 08             	mov    0x8(%ebp),%eax
  8025b5:	a3 00 60 80 00       	mov    %eax,0x806000
	nsipcbuf.shutdown.req_how = how;
  8025ba:	8b 45 0c             	mov    0xc(%ebp),%eax
  8025bd:	a3 04 60 80 00       	mov    %eax,0x806004
	return nsipc(NSREQ_SHUTDOWN);
  8025c2:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
  8025c9:	e8 02 ff ff ff       	call   8024d0 <nsipc>
}
  8025ce:	c9                   	leave  
  8025cf:	c3                   	ret    

008025d0 <nsipc_close>:

int
nsipc_close(int s)
{
  8025d0:	55                   	push   %ebp
  8025d1:	89 e5                	mov    %esp,%ebp
  8025d3:	83 ec 18             	sub    $0x18,%esp
	nsipcbuf.close.req_s = s;
  8025d6:	8b 45 08             	mov    0x8(%ebp),%eax
  8025d9:	a3 00 60 80 00       	mov    %eax,0x806000
	return nsipc(NSREQ_CLOSE);
  8025de:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  8025e5:	e8 e6 fe ff ff       	call   8024d0 <nsipc>
}
  8025ea:	c9                   	leave  
  8025eb:	c3                   	ret    

008025ec <nsipc_connect>:

int
nsipc_connect(int s, const struct sockaddr *name, socklen_t namelen)
{
  8025ec:	55                   	push   %ebp
  8025ed:	89 e5                	mov    %esp,%ebp
  8025ef:	83 ec 18             	sub    $0x18,%esp
	nsipcbuf.connect.req_s = s;
  8025f2:	8b 45 08             	mov    0x8(%ebp),%eax
  8025f5:	a3 00 60 80 00       	mov    %eax,0x806000
	memmove(&nsipcbuf.connect.req_name, name, namelen);
  8025fa:	8b 45 10             	mov    0x10(%ebp),%eax
  8025fd:	89 44 24 08          	mov    %eax,0x8(%esp)
  802601:	8b 45 0c             	mov    0xc(%ebp),%eax
  802604:	89 44 24 04          	mov    %eax,0x4(%esp)
  802608:	c7 04 24 04 60 80 00 	movl   $0x806004,(%esp)
  80260f:	e8 14 ea ff ff       	call   801028 <memmove>
	nsipcbuf.connect.req_namelen = namelen;
  802614:	8b 45 10             	mov    0x10(%ebp),%eax
  802617:	a3 14 60 80 00       	mov    %eax,0x806014
	return nsipc(NSREQ_CONNECT);
  80261c:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
  802623:	e8 a8 fe ff ff       	call   8024d0 <nsipc>
}
  802628:	c9                   	leave  
  802629:	c3                   	ret    

0080262a <nsipc_listen>:

int
nsipc_listen(int s, int backlog)
{
  80262a:	55                   	push   %ebp
  80262b:	89 e5                	mov    %esp,%ebp
  80262d:	83 ec 18             	sub    $0x18,%esp
	nsipcbuf.listen.req_s = s;
  802630:	8b 45 08             	mov    0x8(%ebp),%eax
  802633:	a3 00 60 80 00       	mov    %eax,0x806000
	nsipcbuf.listen.req_backlog = backlog;
  802638:	8b 45 0c             	mov    0xc(%ebp),%eax
  80263b:	a3 04 60 80 00       	mov    %eax,0x806004
	return nsipc(NSREQ_LISTEN);
  802640:	c7 04 24 06 00 00 00 	movl   $0x6,(%esp)
  802647:	e8 84 fe ff ff       	call   8024d0 <nsipc>
}
  80264c:	c9                   	leave  
  80264d:	c3                   	ret    

0080264e <nsipc_recv>:

int
nsipc_recv(int s, void *mem, int len, unsigned int flags)
{
  80264e:	55                   	push   %ebp
  80264f:	89 e5                	mov    %esp,%ebp
  802651:	83 ec 28             	sub    $0x28,%esp
	int r;

	nsipcbuf.recv.req_s = s;
  802654:	8b 45 08             	mov    0x8(%ebp),%eax
  802657:	a3 00 60 80 00       	mov    %eax,0x806000
	nsipcbuf.recv.req_len = len;
  80265c:	8b 45 10             	mov    0x10(%ebp),%eax
  80265f:	a3 04 60 80 00       	mov    %eax,0x806004
	nsipcbuf.recv.req_flags = flags;
  802664:	8b 45 14             	mov    0x14(%ebp),%eax
  802667:	a3 08 60 80 00       	mov    %eax,0x806008

	if ((r = nsipc(NSREQ_RECV)) >= 0) {
  80266c:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
  802673:	e8 58 fe ff ff       	call   8024d0 <nsipc>
  802678:	89 45 f4             	mov    %eax,-0xc(%ebp)
  80267b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  80267f:	78 4f                	js     8026d0 <nsipc_recv+0x82>
		assert(r < 1600 && r <= len);
  802681:	81 7d f4 3f 06 00 00 	cmpl   $0x63f,-0xc(%ebp)
  802688:	7f 08                	jg     802692 <nsipc_recv+0x44>
  80268a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80268d:	3b 45 10             	cmp    0x10(%ebp),%eax
  802690:	7e 24                	jle    8026b6 <nsipc_recv+0x68>
  802692:	c7 44 24 0c 2c 3d 80 	movl   $0x803d2c,0xc(%esp)
  802699:	00 
  80269a:	c7 44 24 08 41 3d 80 	movl   $0x803d41,0x8(%esp)
  8026a1:	00 
  8026a2:	c7 44 24 04 5b 00 00 	movl   $0x5b,0x4(%esp)
  8026a9:	00 
  8026aa:	c7 04 24 56 3d 80 00 	movl   $0x803d56,(%esp)
  8026b1:	e8 6a df ff ff       	call   800620 <_panic>
		memmove(mem, nsipcbuf.recvRet.ret_buf, r);
  8026b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8026b9:	89 44 24 08          	mov    %eax,0x8(%esp)
  8026bd:	c7 44 24 04 00 60 80 	movl   $0x806000,0x4(%esp)
  8026c4:	00 
  8026c5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8026c8:	89 04 24             	mov    %eax,(%esp)
  8026cb:	e8 58 e9 ff ff       	call   801028 <memmove>
	}

	return r;
  8026d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  8026d3:	c9                   	leave  
  8026d4:	c3                   	ret    

008026d5 <nsipc_send>:

int
nsipc_send(int s, const void *buf, int size, unsigned int flags)
{
  8026d5:	55                   	push   %ebp
  8026d6:	89 e5                	mov    %esp,%ebp
  8026d8:	83 ec 18             	sub    $0x18,%esp
	nsipcbuf.send.req_s = s;
  8026db:	8b 45 08             	mov    0x8(%ebp),%eax
  8026de:	a3 00 60 80 00       	mov    %eax,0x806000
	assert(size < 1600);
  8026e3:	81 7d 10 3f 06 00 00 	cmpl   $0x63f,0x10(%ebp)
  8026ea:	7e 24                	jle    802710 <nsipc_send+0x3b>
  8026ec:	c7 44 24 0c 62 3d 80 	movl   $0x803d62,0xc(%esp)
  8026f3:	00 
  8026f4:	c7 44 24 08 41 3d 80 	movl   $0x803d41,0x8(%esp)
  8026fb:	00 
  8026fc:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  802703:	00 
  802704:	c7 04 24 56 3d 80 00 	movl   $0x803d56,(%esp)
  80270b:	e8 10 df ff ff       	call   800620 <_panic>
	memmove(&nsipcbuf.send.req_buf, buf, size);
  802710:	8b 45 10             	mov    0x10(%ebp),%eax
  802713:	89 44 24 08          	mov    %eax,0x8(%esp)
  802717:	8b 45 0c             	mov    0xc(%ebp),%eax
  80271a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80271e:	c7 04 24 0c 60 80 00 	movl   $0x80600c,(%esp)
  802725:	e8 fe e8 ff ff       	call   801028 <memmove>
	nsipcbuf.send.req_size = size;
  80272a:	8b 45 10             	mov    0x10(%ebp),%eax
  80272d:	a3 04 60 80 00       	mov    %eax,0x806004
	nsipcbuf.send.req_flags = flags;
  802732:	8b 45 14             	mov    0x14(%ebp),%eax
  802735:	a3 08 60 80 00       	mov    %eax,0x806008
	return nsipc(NSREQ_SEND);
  80273a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  802741:	e8 8a fd ff ff       	call   8024d0 <nsipc>
}
  802746:	c9                   	leave  
  802747:	c3                   	ret    

00802748 <nsipc_socket>:

int
nsipc_socket(int domain, int type, int protocol)
{
  802748:	55                   	push   %ebp
  802749:	89 e5                	mov    %esp,%ebp
  80274b:	83 ec 18             	sub    $0x18,%esp
	nsipcbuf.socket.req_domain = domain;
  80274e:	8b 45 08             	mov    0x8(%ebp),%eax
  802751:	a3 00 60 80 00       	mov    %eax,0x806000
	nsipcbuf.socket.req_type = type;
  802756:	8b 45 0c             	mov    0xc(%ebp),%eax
  802759:	a3 04 60 80 00       	mov    %eax,0x806004
	nsipcbuf.socket.req_protocol = protocol;
  80275e:	8b 45 10             	mov    0x10(%ebp),%eax
  802761:	a3 08 60 80 00       	mov    %eax,0x806008
	return nsipc(NSREQ_SOCKET);
  802766:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
  80276d:	e8 5e fd ff ff       	call   8024d0 <nsipc>
}
  802772:	c9                   	leave  
  802773:	c3                   	ret    

00802774 <pipe>:
	uint8_t p_buf[PIPEBUFSIZ];	// data buffer
};

int
pipe(int pfd[2])
{
  802774:	55                   	push   %ebp
  802775:	89 e5                	mov    %esp,%ebp
  802777:	53                   	push   %ebx
  802778:	83 ec 34             	sub    $0x34,%esp
	int r;
	struct Fd *fd0, *fd1;
	void *va;

	// allocate the file descriptor table entries
	if ((r = fd_alloc(&fd0)) < 0
  80277b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80277e:	89 04 24             	mov    %eax,(%esp)
  802781:	e8 3d f0 ff ff       	call   8017c3 <fd_alloc>
  802786:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802789:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  80278d:	0f 88 6a 01 00 00    	js     8028fd <pipe+0x189>
	    || (r = sys_page_alloc(0, fd0, PTE_P|PTE_W|PTE_U|PTE_SHARE)) < 0)
  802793:	8b 45 ec             	mov    -0x14(%ebp),%eax
  802796:	c7 44 24 08 07 04 00 	movl   $0x407,0x8(%esp)
  80279d:	00 
  80279e:	89 44 24 04          	mov    %eax,0x4(%esp)
  8027a2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8027a9:	e8 c8 ec ff ff       	call   801476 <sys_page_alloc>
  8027ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
  8027b1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  8027b5:	0f 88 42 01 00 00    	js     8028fd <pipe+0x189>
		goto err;

	if ((r = fd_alloc(&fd1)) < 0
  8027bb:	8d 45 e8             	lea    -0x18(%ebp),%eax
  8027be:	89 04 24             	mov    %eax,(%esp)
  8027c1:	e8 fd ef ff ff       	call   8017c3 <fd_alloc>
  8027c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  8027c9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  8027cd:	0f 88 17 01 00 00    	js     8028ea <pipe+0x176>
	    || (r = sys_page_alloc(0, fd1, PTE_P|PTE_W|PTE_U|PTE_SHARE)) < 0)
  8027d3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  8027d6:	c7 44 24 08 07 04 00 	movl   $0x407,0x8(%esp)
  8027dd:	00 
  8027de:	89 44 24 04          	mov    %eax,0x4(%esp)
  8027e2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8027e9:	e8 88 ec ff ff       	call   801476 <sys_page_alloc>
  8027ee:	89 45 f4             	mov    %eax,-0xc(%ebp)
  8027f1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  8027f5:	0f 88 ef 00 00 00    	js     8028ea <pipe+0x176>
		goto err1;

	// allocate the pipe structure as first data page in both
	va = fd2data(fd0);
  8027fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8027fe:	89 04 24             	mov    %eax,(%esp)
  802801:	e8 a2 ef ff ff       	call   8017a8 <fd2data>
  802806:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if ((r = sys_page_alloc(0, va, PTE_P|PTE_W|PTE_U|PTE_SHARE)) < 0)
  802809:	c7 44 24 08 07 04 00 	movl   $0x407,0x8(%esp)
  802810:	00 
  802811:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802814:	89 44 24 04          	mov    %eax,0x4(%esp)
  802818:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80281f:	e8 52 ec ff ff       	call   801476 <sys_page_alloc>
  802824:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802827:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  80282b:	0f 88 a5 00 00 00    	js     8028d6 <pipe+0x162>
		goto err2;
	if ((r = sys_page_map(0, va, 0, fd2data(fd1), PTE_P|PTE_W|PTE_U|PTE_SHARE)) < 0)
  802831:	8b 45 e8             	mov    -0x18(%ebp),%eax
  802834:	89 04 24             	mov    %eax,(%esp)
  802837:	e8 6c ef ff ff       	call   8017a8 <fd2data>
  80283c:	c7 44 24 10 07 04 00 	movl   $0x407,0x10(%esp)
  802843:	00 
  802844:	89 44 24 0c          	mov    %eax,0xc(%esp)
  802848:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  80284f:	00 
  802850:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802853:	89 44 24 04          	mov    %eax,0x4(%esp)
  802857:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80285e:	e8 54 ec ff ff       	call   8014b7 <sys_page_map>
  802863:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802866:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  80286a:	78 54                	js     8028c0 <pipe+0x14c>
		goto err3;

	// set up fd structures
	fd0->fd_dev_id = devpipe.dev_id;
  80286c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80286f:	8b 15 50 70 80 00    	mov    0x807050,%edx
  802875:	89 10                	mov    %edx,(%eax)
	fd0->fd_omode = O_RDONLY;
  802877:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80287a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	fd1->fd_dev_id = devpipe.dev_id;
  802881:	8b 45 e8             	mov    -0x18(%ebp),%eax
  802884:	8b 15 50 70 80 00    	mov    0x807050,%edx
  80288a:	89 10                	mov    %edx,(%eax)
	fd1->fd_omode = O_WRONLY;
  80288c:	8b 45 e8             	mov    -0x18(%ebp),%eax
  80288f:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)

	if (debug)
		cprintf("[%08x] pipecreate %08x\n", env->env_id, vpt[VPN(va)]);

	pfd[0] = fd2num(fd0);
  802896:	8b 45 ec             	mov    -0x14(%ebp),%eax
  802899:	89 04 24             	mov    %eax,(%esp)
  80289c:	e8 f7 ee ff ff       	call   801798 <fd2num>
  8028a1:	8b 55 08             	mov    0x8(%ebp),%edx
  8028a4:	89 02                	mov    %eax,(%edx)
	pfd[1] = fd2num(fd1);
  8028a6:	8b 45 08             	mov    0x8(%ebp),%eax
  8028a9:	8d 58 04             	lea    0x4(%eax),%ebx
  8028ac:	8b 45 e8             	mov    -0x18(%ebp),%eax
  8028af:	89 04 24             	mov    %eax,(%esp)
  8028b2:	e8 e1 ee ff ff       	call   801798 <fd2num>
  8028b7:	89 03                	mov    %eax,(%ebx)
	return 0;
  8028b9:	b8 00 00 00 00       	mov    $0x0,%eax
  8028be:	eb 40                	jmp    802900 <pipe+0x18c>
	// allocate the pipe structure as first data page in both
	va = fd2data(fd0);
	if ((r = sys_page_alloc(0, va, PTE_P|PTE_W|PTE_U|PTE_SHARE)) < 0)
		goto err2;
	if ((r = sys_page_map(0, va, 0, fd2data(fd1), PTE_P|PTE_W|PTE_U|PTE_SHARE)) < 0)
		goto err3;
  8028c0:	90                   	nop
	pfd[0] = fd2num(fd0);
	pfd[1] = fd2num(fd1);
	return 0;

    err3:
	sys_page_unmap(0, va);
  8028c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8028c4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8028c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8028cf:	e8 29 ec ff ff       	call   8014fd <sys_page_unmap>
  8028d4:	eb 01                	jmp    8028d7 <pipe+0x163>
		goto err1;

	// allocate the pipe structure as first data page in both
	va = fd2data(fd0);
	if ((r = sys_page_alloc(0, va, PTE_P|PTE_W|PTE_U|PTE_SHARE)) < 0)
		goto err2;
  8028d6:	90                   	nop
	return 0;

    err3:
	sys_page_unmap(0, va);
    err2:
	sys_page_unmap(0, fd1);
  8028d7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  8028da:	89 44 24 04          	mov    %eax,0x4(%esp)
  8028de:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8028e5:	e8 13 ec ff ff       	call   8014fd <sys_page_unmap>
    err1:
	sys_page_unmap(0, fd0);
  8028ea:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8028ed:	89 44 24 04          	mov    %eax,0x4(%esp)
  8028f1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8028f8:	e8 00 ec ff ff       	call   8014fd <sys_page_unmap>
    err:
	return r;
  8028fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  802900:	83 c4 34             	add    $0x34,%esp
  802903:	5b                   	pop    %ebx
  802904:	5d                   	pop    %ebp
  802905:	c3                   	ret    

00802906 <_pipeisclosed>:

static int
_pipeisclosed(struct Fd *fd, struct Pipe *p)
{
  802906:	55                   	push   %ebp
  802907:	89 e5                	mov    %esp,%ebp
  802909:	53                   	push   %ebx
  80290a:	83 ec 24             	sub    $0x24,%esp
  80290d:	eb 04                	jmp    802913 <_pipeisclosed+0xd>
		nn = env->env_runs;
		if (n == nn)
			return ret;
		if (n != nn && ret == 1)
			cprintf("pipe race avoided\n", n, env->env_runs, ret);
	}
  80290f:	90                   	nop
  802910:	eb 01                	jmp    802913 <_pipeisclosed+0xd>
  802912:	90                   	nop
_pipeisclosed(struct Fd *fd, struct Pipe *p)
{
	int n, nn, ret;

	while (1) {
		n = env->env_runs;
  802913:	a1 44 81 80 00       	mov    0x808144,%eax
  802918:	8b 40 58             	mov    0x58(%eax),%eax
  80291b:	89 45 f4             	mov    %eax,-0xc(%ebp)
		ret = pageref(fd) == pageref(p);
  80291e:	8b 45 08             	mov    0x8(%ebp),%eax
  802921:	89 04 24             	mov    %eax,(%esp)
  802924:	e8 ab 05 00 00       	call   802ed4 <pageref>
  802929:	89 c3                	mov    %eax,%ebx
  80292b:	8b 45 0c             	mov    0xc(%ebp),%eax
  80292e:	89 04 24             	mov    %eax,(%esp)
  802931:	e8 9e 05 00 00       	call   802ed4 <pageref>
  802936:	39 c3                	cmp    %eax,%ebx
  802938:	0f 94 c0             	sete   %al
  80293b:	0f b6 c0             	movzbl %al,%eax
  80293e:	89 45 f0             	mov    %eax,-0x10(%ebp)
		nn = env->env_runs;
  802941:	a1 44 81 80 00       	mov    0x808144,%eax
  802946:	8b 40 58             	mov    0x58(%eax),%eax
  802949:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (n == nn)
  80294c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80294f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  802952:	75 09                	jne    80295d <_pipeisclosed+0x57>
			return ret;
  802954:	8b 45 f0             	mov    -0x10(%ebp),%eax
		if (n != nn && ret == 1)
			cprintf("pipe race avoided\n", n, env->env_runs, ret);
	}
}
  802957:	83 c4 24             	add    $0x24,%esp
  80295a:	5b                   	pop    %ebx
  80295b:	5d                   	pop    %ebp
  80295c:	c3                   	ret    
		n = env->env_runs;
		ret = pageref(fd) == pageref(p);
		nn = env->env_runs;
		if (n == nn)
			return ret;
		if (n != nn && ret == 1)
  80295d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802960:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  802963:	74 aa                	je     80290f <_pipeisclosed+0x9>
  802965:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
  802969:	75 a7                	jne    802912 <_pipeisclosed+0xc>
			cprintf("pipe race avoided\n", n, env->env_runs, ret);
  80296b:	a1 44 81 80 00       	mov    0x808144,%eax
  802970:	8b 40 58             	mov    0x58(%eax),%eax
  802973:	8b 55 f0             	mov    -0x10(%ebp),%edx
  802976:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80297a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80297e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802981:	89 44 24 04          	mov    %eax,0x4(%esp)
  802985:	c7 04 24 73 3d 80 00 	movl   $0x803d73,(%esp)
  80298c:	e8 c0 dd ff ff       	call   800751 <cprintf>
	}
  802991:	eb 80                	jmp    802913 <_pipeisclosed+0xd>

00802993 <pipeisclosed>:
}

int
pipeisclosed(int fdnum)
{
  802993:	55                   	push   %ebp
  802994:	89 e5                	mov    %esp,%ebp
  802996:	83 ec 28             	sub    $0x28,%esp
	struct Fd *fd;
	struct Pipe *p;
	int r;

	if ((r = fd_lookup(fdnum, &fd)) < 0)
  802999:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80299c:	89 44 24 04          	mov    %eax,0x4(%esp)
  8029a0:	8b 45 08             	mov    0x8(%ebp),%eax
  8029a3:	89 04 24             	mov    %eax,(%esp)
  8029a6:	e8 86 ee ff ff       	call   801831 <fd_lookup>
  8029ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
  8029ae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  8029b2:	79 05                	jns    8029b9 <pipeisclosed+0x26>
		return r;
  8029b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8029b7:	eb 20                	jmp    8029d9 <pipeisclosed+0x46>
	p = (struct Pipe*) fd2data(fd);
  8029b9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8029bc:	89 04 24             	mov    %eax,(%esp)
  8029bf:	e8 e4 ed ff ff       	call   8017a8 <fd2data>
  8029c4:	89 45 f0             	mov    %eax,-0x10(%ebp)
	return _pipeisclosed(fd, p);
  8029c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8029ca:	8b 55 f0             	mov    -0x10(%ebp),%edx
  8029cd:	89 54 24 04          	mov    %edx,0x4(%esp)
  8029d1:	89 04 24             	mov    %eax,(%esp)
  8029d4:	e8 2d ff ff ff       	call   802906 <_pipeisclosed>
}
  8029d9:	c9                   	leave  
  8029da:	c3                   	ret    

008029db <devpipe_read>:

static ssize_t
devpipe_read(struct Fd *fd, void *vbuf, size_t n)
{
  8029db:	55                   	push   %ebp
  8029dc:	89 e5                	mov    %esp,%ebp
  8029de:	83 ec 28             	sub    $0x28,%esp
	uint8_t *buf;
	size_t i;
	struct Pipe *p;

	p = (struct Pipe*)fd2data(fd);
  8029e1:	8b 45 08             	mov    0x8(%ebp),%eax
  8029e4:	89 04 24             	mov    %eax,(%esp)
  8029e7:	e8 bc ed ff ff       	call   8017a8 <fd2data>
  8029ec:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (debug)
		cprintf("[%08x] devpipe_read %08x %d rpos %d wpos %d\n",
			env->env_id, vpt[VPN(p)], n, p->p_rpos, p->p_wpos);

	buf = vbuf;
  8029ef:	8b 45 0c             	mov    0xc(%ebp),%eax
  8029f2:	89 45 ec             	mov    %eax,-0x14(%ebp)
	for (i = 0; i < n; i++) {
  8029f5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  8029fc:	eb 77                	jmp    802a75 <devpipe_read+0x9a>
		while (p->p_rpos == p->p_wpos) {
			// pipe is empty
			// if we got any data, return it
			if (i > 0)
  8029fe:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802a02:	74 05                	je     802a09 <devpipe_read+0x2e>
				return i;
  802a04:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802a07:	eb 77                	jmp    802a80 <devpipe_read+0xa5>
			// if all the writers are gone, note eof
			if (_pipeisclosed(fd, p))
  802a09:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802a0c:	89 44 24 04          	mov    %eax,0x4(%esp)
  802a10:	8b 45 08             	mov    0x8(%ebp),%eax
  802a13:	89 04 24             	mov    %eax,(%esp)
  802a16:	e8 eb fe ff ff       	call   802906 <_pipeisclosed>
  802a1b:	85 c0                	test   %eax,%eax
  802a1d:	74 07                	je     802a26 <devpipe_read+0x4b>
				return 0;
  802a1f:	b8 00 00 00 00       	mov    $0x0,%eax
  802a24:	eb 5a                	jmp    802a80 <devpipe_read+0xa5>
			// yield and see what happens
			if (debug)
				cprintf("devpipe_read yield\n");
			sys_yield();
  802a26:	e8 07 ea ff ff       	call   801432 <sys_yield>
  802a2b:	eb 01                	jmp    802a2e <devpipe_read+0x53>
		cprintf("[%08x] devpipe_read %08x %d rpos %d wpos %d\n",
			env->env_id, vpt[VPN(p)], n, p->p_rpos, p->p_wpos);

	buf = vbuf;
	for (i = 0; i < n; i++) {
		while (p->p_rpos == p->p_wpos) {
  802a2d:	90                   	nop
  802a2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802a31:	8b 10                	mov    (%eax),%edx
  802a33:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802a36:	8b 40 04             	mov    0x4(%eax),%eax
  802a39:	39 c2                	cmp    %eax,%edx
  802a3b:	74 c1                	je     8029fe <devpipe_read+0x23>
				cprintf("devpipe_read yield\n");
			sys_yield();
		}
		// there's a byte.  take it.
		// wait to increment rpos until the byte is taken!
		buf[i] = p->p_buf[p->p_rpos % PIPEBUFSIZ];
  802a3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802a40:	8b 55 ec             	mov    -0x14(%ebp),%edx
  802a43:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
  802a46:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802a49:	8b 00                	mov    (%eax),%eax
  802a4b:	89 c2                	mov    %eax,%edx
  802a4d:	c1 fa 1f             	sar    $0x1f,%edx
  802a50:	c1 ea 1b             	shr    $0x1b,%edx
  802a53:	01 d0                	add    %edx,%eax
  802a55:	83 e0 1f             	and    $0x1f,%eax
  802a58:	29 d0                	sub    %edx,%eax
  802a5a:	8b 55 f0             	mov    -0x10(%ebp),%edx
  802a5d:	0f b6 44 02 08       	movzbl 0x8(%edx,%eax,1),%eax
  802a62:	88 01                	mov    %al,(%ecx)
		p->p_rpos++;
  802a64:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802a67:	8b 00                	mov    (%eax),%eax
  802a69:	8d 50 01             	lea    0x1(%eax),%edx
  802a6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802a6f:	89 10                	mov    %edx,(%eax)
	if (debug)
		cprintf("[%08x] devpipe_read %08x %d rpos %d wpos %d\n",
			env->env_id, vpt[VPN(p)], n, p->p_rpos, p->p_wpos);

	buf = vbuf;
	for (i = 0; i < n; i++) {
  802a71:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  802a75:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802a78:	3b 45 10             	cmp    0x10(%ebp),%eax
  802a7b:	72 b0                	jb     802a2d <devpipe_read+0x52>
		// there's a byte.  take it.
		// wait to increment rpos until the byte is taken!
		buf[i] = p->p_buf[p->p_rpos % PIPEBUFSIZ];
		p->p_rpos++;
	}
	return i;
  802a7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  802a80:	c9                   	leave  
  802a81:	c3                   	ret    

00802a82 <devpipe_write>:

static ssize_t
devpipe_write(struct Fd *fd, const void *vbuf, size_t n)
{
  802a82:	55                   	push   %ebp
  802a83:	89 e5                	mov    %esp,%ebp
  802a85:	83 ec 28             	sub    $0x28,%esp
	const uint8_t *buf;
	size_t i;
	struct Pipe *p;

	p = (struct Pipe*) fd2data(fd);
  802a88:	8b 45 08             	mov    0x8(%ebp),%eax
  802a8b:	89 04 24             	mov    %eax,(%esp)
  802a8e:	e8 15 ed ff ff       	call   8017a8 <fd2data>
  802a93:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (debug)
		cprintf("[%08x] devpipe_write %08x %d rpos %d wpos %d\n",
			env->env_id, vpt[VPN(p)], n, p->p_rpos, p->p_wpos);

	buf = vbuf;
  802a96:	8b 45 0c             	mov    0xc(%ebp),%eax
  802a99:	89 45 ec             	mov    %eax,-0x14(%ebp)
	for (i = 0; i < n; i++) {
  802a9c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  802aa3:	eb 74                	jmp    802b19 <devpipe_write+0x97>
		while (p->p_wpos >= p->p_rpos + sizeof(p->p_buf)) {
			// pipe is full
			// if all the readers are gone
			// (it's only writers like us now),
			// note eof
			if (_pipeisclosed(fd, p))
  802aa5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802aa8:	89 44 24 04          	mov    %eax,0x4(%esp)
  802aac:	8b 45 08             	mov    0x8(%ebp),%eax
  802aaf:	89 04 24             	mov    %eax,(%esp)
  802ab2:	e8 4f fe ff ff       	call   802906 <_pipeisclosed>
  802ab7:	85 c0                	test   %eax,%eax
  802ab9:	74 07                	je     802ac2 <devpipe_write+0x40>
				return 0;
  802abb:	b8 00 00 00 00       	mov    $0x0,%eax
  802ac0:	eb 62                	jmp    802b24 <devpipe_write+0xa2>
			// yield and see what happens
			if (debug)
				cprintf("devpipe_write yield\n");
			sys_yield();
  802ac2:	e8 6b e9 ff ff       	call   801432 <sys_yield>
  802ac7:	eb 01                	jmp    802aca <devpipe_write+0x48>
		cprintf("[%08x] devpipe_write %08x %d rpos %d wpos %d\n",
			env->env_id, vpt[VPN(p)], n, p->p_rpos, p->p_wpos);

	buf = vbuf;
	for (i = 0; i < n; i++) {
		while (p->p_wpos >= p->p_rpos + sizeof(p->p_buf)) {
  802ac9:	90                   	nop
  802aca:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802acd:	8b 40 04             	mov    0x4(%eax),%eax
  802ad0:	89 c2                	mov    %eax,%edx
  802ad2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802ad5:	8b 00                	mov    (%eax),%eax
  802ad7:	83 c0 20             	add    $0x20,%eax
  802ada:	39 c2                	cmp    %eax,%edx
  802adc:	73 c7                	jae    802aa5 <devpipe_write+0x23>
				cprintf("devpipe_write yield\n");
			sys_yield();
		}
		// there's room for a byte.  store it.
		// wait to increment wpos until the byte is stored!
		p->p_buf[p->p_wpos % PIPEBUFSIZ] = buf[i];
  802ade:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802ae1:	8b 40 04             	mov    0x4(%eax),%eax
  802ae4:	89 c2                	mov    %eax,%edx
  802ae6:	c1 fa 1f             	sar    $0x1f,%edx
  802ae9:	c1 ea 1b             	shr    $0x1b,%edx
  802aec:	01 d0                	add    %edx,%eax
  802aee:	83 e0 1f             	and    $0x1f,%eax
  802af1:	29 d0                	sub    %edx,%eax
  802af3:	8b 55 f4             	mov    -0xc(%ebp),%edx
  802af6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
  802af9:	8d 14 11             	lea    (%ecx,%edx,1),%edx
  802afc:	0f b6 0a             	movzbl (%edx),%ecx
  802aff:	8b 55 f0             	mov    -0x10(%ebp),%edx
  802b02:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
		p->p_wpos++;
  802b06:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802b09:	8b 40 04             	mov    0x4(%eax),%eax
  802b0c:	8d 50 01             	lea    0x1(%eax),%edx
  802b0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802b12:	89 50 04             	mov    %edx,0x4(%eax)
	if (debug)
		cprintf("[%08x] devpipe_write %08x %d rpos %d wpos %d\n",
			env->env_id, vpt[VPN(p)], n, p->p_rpos, p->p_wpos);

	buf = vbuf;
	for (i = 0; i < n; i++) {
  802b15:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  802b19:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802b1c:	3b 45 10             	cmp    0x10(%ebp),%eax
  802b1f:	72 a8                	jb     802ac9 <devpipe_write+0x47>
		// wait to increment wpos until the byte is stored!
		p->p_buf[p->p_wpos % PIPEBUFSIZ] = buf[i];
		p->p_wpos++;
	}
	
	return i;
  802b21:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  802b24:	c9                   	leave  
  802b25:	c3                   	ret    

00802b26 <devpipe_stat>:

static int
devpipe_stat(struct Fd *fd, struct Stat *stat)
{
  802b26:	55                   	push   %ebp
  802b27:	89 e5                	mov    %esp,%ebp
  802b29:	83 ec 28             	sub    $0x28,%esp
	struct Pipe *p = (struct Pipe*) fd2data(fd);
  802b2c:	8b 45 08             	mov    0x8(%ebp),%eax
  802b2f:	89 04 24             	mov    %eax,(%esp)
  802b32:	e8 71 ec ff ff       	call   8017a8 <fd2data>
  802b37:	89 45 f4             	mov    %eax,-0xc(%ebp)
	strcpy(stat->st_name, "<pipe>");
  802b3a:	8b 45 0c             	mov    0xc(%ebp),%eax
  802b3d:	c7 44 24 04 86 3d 80 	movl   $0x803d86,0x4(%esp)
  802b44:	00 
  802b45:	89 04 24             	mov    %eax,(%esp)
  802b48:	e8 e9 e2 ff ff       	call   800e36 <strcpy>
	stat->st_size = p->p_wpos - p->p_rpos;
  802b4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802b50:	8b 50 04             	mov    0x4(%eax),%edx
  802b53:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802b56:	8b 00                	mov    (%eax),%eax
  802b58:	29 c2                	sub    %eax,%edx
  802b5a:	8b 45 0c             	mov    0xc(%ebp),%eax
  802b5d:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
	stat->st_isdir = 0;
  802b63:	8b 45 0c             	mov    0xc(%ebp),%eax
  802b66:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
  802b6d:	00 00 00 
	stat->st_dev = &devpipe;
  802b70:	8b 45 0c             	mov    0xc(%ebp),%eax
  802b73:	c7 80 88 00 00 00 50 	movl   $0x807050,0x88(%eax)
  802b7a:	70 80 00 
	return 0;
  802b7d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  802b82:	c9                   	leave  
  802b83:	c3                   	ret    

00802b84 <devpipe_close>:

static int
devpipe_close(struct Fd *fd)
{
  802b84:	55                   	push   %ebp
  802b85:	89 e5                	mov    %esp,%ebp
  802b87:	83 ec 18             	sub    $0x18,%esp
	(void) sys_page_unmap(0, fd);
  802b8a:	8b 45 08             	mov    0x8(%ebp),%eax
  802b8d:	89 44 24 04          	mov    %eax,0x4(%esp)
  802b91:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  802b98:	e8 60 e9 ff ff       	call   8014fd <sys_page_unmap>
	return sys_page_unmap(0, fd2data(fd));
  802b9d:	8b 45 08             	mov    0x8(%ebp),%eax
  802ba0:	89 04 24             	mov    %eax,(%esp)
  802ba3:	e8 00 ec ff ff       	call   8017a8 <fd2data>
  802ba8:	89 44 24 04          	mov    %eax,0x4(%esp)
  802bac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  802bb3:	e8 45 e9 ff ff       	call   8014fd <sys_page_unmap>
}
  802bb8:	c9                   	leave  
  802bb9:	c3                   	ret    
	...

00802bbc <cputchar>:
#include <inc/string.h>
#include <inc/lib.h>

void
cputchar(int ch)
{
  802bbc:	55                   	push   %ebp
  802bbd:	89 e5                	mov    %esp,%ebp
  802bbf:	83 ec 28             	sub    $0x28,%esp
	char c = ch;
  802bc2:	8b 45 08             	mov    0x8(%ebp),%eax
  802bc5:	88 45 f7             	mov    %al,-0x9(%ebp)

	// Unlike standard Unix's putchar,
	// the cputchar function _always_ outputs to the system console.
	sys_cputs(&c, 1);
  802bc8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  802bcf:	00 
  802bd0:	8d 45 f7             	lea    -0x9(%ebp),%eax
  802bd3:	89 04 24             	mov    %eax,(%esp)
  802bd6:	e8 4a e7 ff ff       	call   801325 <sys_cputs>
}
  802bdb:	c9                   	leave  
  802bdc:	c3                   	ret    

00802bdd <getchar>:

int
getchar(void)
{
  802bdd:	55                   	push   %ebp
  802bde:	89 e5                	mov    %esp,%ebp
  802be0:	83 ec 28             	sub    $0x28,%esp
	int r;

	// JOS does, however, support standard _input_ redirection,
	// allowing the user to redirect script files to the shell and such.
	// getchar() reads a character from file descriptor 0.
	r = read(0, &c, 1);
  802be3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  802bea:	00 
  802beb:	8d 45 f3             	lea    -0xd(%ebp),%eax
  802bee:	89 44 24 04          	mov    %eax,0x4(%esp)
  802bf2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  802bf9:	e8 4b ef ff ff       	call   801b49 <read>
  802bfe:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (r < 0)
  802c01:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802c05:	79 05                	jns    802c0c <getchar+0x2f>
		return r;
  802c07:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802c0a:	eb 14                	jmp    802c20 <getchar+0x43>
	if (r < 1)
  802c0c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802c10:	7f 07                	jg     802c19 <getchar+0x3c>
		return -E_EOF;
  802c12:	b8 f8 ff ff ff       	mov    $0xfffffff8,%eax
  802c17:	eb 07                	jmp    802c20 <getchar+0x43>
	return c;
  802c19:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  802c1d:	0f b6 c0             	movzbl %al,%eax
}
  802c20:	c9                   	leave  
  802c21:	c3                   	ret    

00802c22 <iscons>:
	.dev_stat =	devcons_stat
};

int
iscons(int fdnum)
{
  802c22:	55                   	push   %ebp
  802c23:	89 e5                	mov    %esp,%ebp
  802c25:	83 ec 28             	sub    $0x28,%esp
	int r;
	struct Fd *fd;

	if ((r = fd_lookup(fdnum, &fd)) < 0)
  802c28:	8d 45 f0             	lea    -0x10(%ebp),%eax
  802c2b:	89 44 24 04          	mov    %eax,0x4(%esp)
  802c2f:	8b 45 08             	mov    0x8(%ebp),%eax
  802c32:	89 04 24             	mov    %eax,(%esp)
  802c35:	e8 f7 eb ff ff       	call   801831 <fd_lookup>
  802c3a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802c3d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802c41:	79 05                	jns    802c48 <iscons+0x26>
		return r;
  802c43:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802c46:	eb 12                	jmp    802c5a <iscons+0x38>
	return fd->fd_dev_id == devcons.dev_id;
  802c48:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802c4b:	8b 10                	mov    (%eax),%edx
  802c4d:	a1 6c 70 80 00       	mov    0x80706c,%eax
  802c52:	39 c2                	cmp    %eax,%edx
  802c54:	0f 94 c0             	sete   %al
  802c57:	0f b6 c0             	movzbl %al,%eax
}
  802c5a:	c9                   	leave  
  802c5b:	c3                   	ret    

00802c5c <opencons>:

int
opencons(void)
{
  802c5c:	55                   	push   %ebp
  802c5d:	89 e5                	mov    %esp,%ebp
  802c5f:	83 ec 28             	sub    $0x28,%esp
	int r;
	struct Fd* fd;

	if ((r = fd_alloc(&fd)) < 0)
  802c62:	8d 45 f0             	lea    -0x10(%ebp),%eax
  802c65:	89 04 24             	mov    %eax,(%esp)
  802c68:	e8 56 eb ff ff       	call   8017c3 <fd_alloc>
  802c6d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802c70:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802c74:	79 05                	jns    802c7b <opencons+0x1f>
		return r;
  802c76:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802c79:	eb 49                	jmp    802cc4 <opencons+0x68>
	if ((r = sys_page_alloc(0, fd, PTE_P|PTE_U|PTE_W|PTE_SHARE)) < 0)
  802c7b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802c7e:	c7 44 24 08 07 04 00 	movl   $0x407,0x8(%esp)
  802c85:	00 
  802c86:	89 44 24 04          	mov    %eax,0x4(%esp)
  802c8a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  802c91:	e8 e0 e7 ff ff       	call   801476 <sys_page_alloc>
  802c96:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802c99:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802c9d:	79 05                	jns    802ca4 <opencons+0x48>
		return r;
  802c9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802ca2:	eb 20                	jmp    802cc4 <opencons+0x68>
	fd->fd_dev_id = devcons.dev_id;
  802ca4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802ca7:	8b 15 6c 70 80 00    	mov    0x80706c,%edx
  802cad:	89 10                	mov    %edx,(%eax)
	fd->fd_omode = O_RDWR;
  802caf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802cb2:	c7 40 08 02 00 00 00 	movl   $0x2,0x8(%eax)
	return fd2num(fd);
  802cb9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802cbc:	89 04 24             	mov    %eax,(%esp)
  802cbf:	e8 d4 ea ff ff       	call   801798 <fd2num>
}
  802cc4:	c9                   	leave  
  802cc5:	c3                   	ret    

00802cc6 <devcons_read>:

static ssize_t
devcons_read(struct Fd *fd, void *vbuf, size_t n)
{
  802cc6:	55                   	push   %ebp
  802cc7:	89 e5                	mov    %esp,%ebp
  802cc9:	83 ec 18             	sub    $0x18,%esp
	int c;

	if (n == 0)
  802ccc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  802cd0:	75 0c                	jne    802cde <devcons_read+0x18>
		return 0;
  802cd2:	b8 00 00 00 00       	mov    $0x0,%eax
  802cd7:	eb 38                	jmp    802d11 <devcons_read+0x4b>

	while ((c = sys_cgetc()) == 0)
		sys_yield();
  802cd9:	e8 54 e7 ff ff       	call   801432 <sys_yield>
	int c;

	if (n == 0)
		return 0;

	while ((c = sys_cgetc()) == 0)
  802cde:	e8 84 e6 ff ff       	call   801367 <sys_cgetc>
  802ce3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802ce6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802cea:	74 ed                	je     802cd9 <devcons_read+0x13>
		sys_yield();
	if (c < 0)
  802cec:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802cf0:	79 05                	jns    802cf7 <devcons_read+0x31>
		return c;
  802cf2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802cf5:	eb 1a                	jmp    802d11 <devcons_read+0x4b>
	if (c == 0x04)	// ctl-d is eof
  802cf7:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  802cfb:	75 07                	jne    802d04 <devcons_read+0x3e>
		return 0;
  802cfd:	b8 00 00 00 00       	mov    $0x0,%eax
  802d02:	eb 0d                	jmp    802d11 <devcons_read+0x4b>
	*(char*)vbuf = c;
  802d04:	8b 45 0c             	mov    0xc(%ebp),%eax
  802d07:	8b 55 f4             	mov    -0xc(%ebp),%edx
  802d0a:	88 10                	mov    %dl,(%eax)
	return 1;
  802d0c:	b8 01 00 00 00       	mov    $0x1,%eax
}
  802d11:	c9                   	leave  
  802d12:	c3                   	ret    

00802d13 <devcons_write>:

static ssize_t
devcons_write(struct Fd *fd, const void *vbuf, size_t n)
{
  802d13:	55                   	push   %ebp
  802d14:	89 e5                	mov    %esp,%ebp
  802d16:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	int tot, m;
	char buf[128];

	// mistake: have to nul-terminate arg to sys_cputs, 
	// so we have to copy vbuf into buf in chunks and nul-terminate.
	for (tot = 0; tot < n; tot += m) {
  802d1c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  802d23:	eb 58                	jmp    802d7d <devcons_write+0x6a>
		m = n - tot;
  802d25:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802d28:	8b 55 10             	mov    0x10(%ebp),%edx
  802d2b:	89 d1                	mov    %edx,%ecx
  802d2d:	29 c1                	sub    %eax,%ecx
  802d2f:	89 c8                	mov    %ecx,%eax
  802d31:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if (m > sizeof(buf) - 1)
  802d34:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802d37:	83 f8 7f             	cmp    $0x7f,%eax
  802d3a:	76 07                	jbe    802d43 <devcons_write+0x30>
			m = sizeof(buf) - 1;
  802d3c:	c7 45 f0 7f 00 00 00 	movl   $0x7f,-0x10(%ebp)
		memmove(buf, (char*)vbuf + tot, m);
  802d43:	8b 55 f0             	mov    -0x10(%ebp),%edx
  802d46:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802d49:	03 45 0c             	add    0xc(%ebp),%eax
  802d4c:	89 54 24 08          	mov    %edx,0x8(%esp)
  802d50:	89 44 24 04          	mov    %eax,0x4(%esp)
  802d54:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
  802d5a:	89 04 24             	mov    %eax,(%esp)
  802d5d:	e8 c6 e2 ff ff       	call   801028 <memmove>
		sys_cputs(buf, m);
  802d62:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802d65:	89 44 24 04          	mov    %eax,0x4(%esp)
  802d69:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
  802d6f:	89 04 24             	mov    %eax,(%esp)
  802d72:	e8 ae e5 ff ff       	call   801325 <sys_cputs>
	int tot, m;
	char buf[128];

	// mistake: have to nul-terminate arg to sys_cputs, 
	// so we have to copy vbuf into buf in chunks and nul-terminate.
	for (tot = 0; tot < n; tot += m) {
  802d77:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802d7a:	01 45 f4             	add    %eax,-0xc(%ebp)
  802d7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802d80:	3b 45 10             	cmp    0x10(%ebp),%eax
  802d83:	72 a0                	jb     802d25 <devcons_write+0x12>
		if (m > sizeof(buf) - 1)
			m = sizeof(buf) - 1;
		memmove(buf, (char*)vbuf + tot, m);
		sys_cputs(buf, m);
	}
	return tot;
  802d85:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  802d88:	c9                   	leave  
  802d89:	c3                   	ret    

00802d8a <devcons_close>:

static int
devcons_close(struct Fd *fd)
{
  802d8a:	55                   	push   %ebp
  802d8b:	89 e5                	mov    %esp,%ebp
	USED(fd);

	return 0;
  802d8d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  802d92:	5d                   	pop    %ebp
  802d93:	c3                   	ret    

00802d94 <devcons_stat>:

static int
devcons_stat(struct Fd *fd, struct Stat *stat)
{
  802d94:	55                   	push   %ebp
  802d95:	89 e5                	mov    %esp,%ebp
  802d97:	83 ec 18             	sub    $0x18,%esp
	strcpy(stat->st_name, "<cons>");
  802d9a:	8b 45 0c             	mov    0xc(%ebp),%eax
  802d9d:	c7 44 24 04 92 3d 80 	movl   $0x803d92,0x4(%esp)
  802da4:	00 
  802da5:	89 04 24             	mov    %eax,(%esp)
  802da8:	e8 89 e0 ff ff       	call   800e36 <strcpy>
	return 0;
  802dad:	b8 00 00 00 00       	mov    $0x0,%eax
}
  802db2:	c9                   	leave  
  802db3:	c3                   	ret    

00802db4 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  802db4:	55                   	push   %ebp
  802db5:	89 e5                	mov    %esp,%ebp
  802db7:	83 ec 28             	sub    $0x28,%esp
	// LAB 4: Your code here.
	int error;
	error = sys_ipc_recv(pg != NULL ? pg : (void *) ~0);
  802dba:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  802dbe:	74 05                	je     802dc5 <ipc_recv+0x11>
  802dc0:	8b 45 0c             	mov    0xc(%ebp),%eax
  802dc3:	eb 05                	jmp    802dca <ipc_recv+0x16>
  802dc5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  802dca:	89 04 24             	mov    %eax,(%esp)
  802dcd:	e8 73 e8 ff ff       	call   801645 <sys_ipc_recv>
  802dd2:	89 45 f4             	mov    %eax,-0xc(%ebp)

	DPRINTF4C("Received in environment [user] %d.\n", sys_getenvid());
  802dd5:	e8 14 e6 ff ff       	call   8013ee <sys_getenvid>
	assert(env->env_ipc_from);
  802dda:	a1 44 81 80 00       	mov    0x808144,%eax
  802ddf:	8b 40 74             	mov    0x74(%eax),%eax
  802de2:	85 c0                	test   %eax,%eax
  802de4:	75 24                	jne    802e0a <ipc_recv+0x56>
  802de6:	c7 44 24 0c 9c 3d 80 	movl   $0x803d9c,0xc(%esp)
  802ded:	00 
  802dee:	c7 44 24 08 ae 3d 80 	movl   $0x803dae,0x8(%esp)
  802df5:	00 
  802df6:	c7 44 24 04 1f 00 00 	movl   $0x1f,0x4(%esp)
  802dfd:	00 
  802dfe:	c7 04 24 c3 3d 80 00 	movl   $0x803dc3,(%esp)
  802e05:	e8 16 d8 ff ff       	call   800620 <_panic>

	if(error < 0) {
  802e0a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802e0e:	79 23                	jns    802e33 <ipc_recv+0x7f>
		if(from_env_store) *from_env_store = 0;
  802e10:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  802e14:	74 09                	je     802e1f <ipc_recv+0x6b>
  802e16:	8b 45 08             	mov    0x8(%ebp),%eax
  802e19:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		if(perm_store) *perm_store = 0;
  802e1f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  802e23:	74 09                	je     802e2e <ipc_recv+0x7a>
  802e25:	8b 45 10             	mov    0x10(%ebp),%eax
  802e28:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return error;
  802e2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802e31:	eb 2e                	jmp    802e61 <ipc_recv+0xad>
	}

	if(from_env_store) *from_env_store = env->env_ipc_from;
  802e33:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  802e37:	74 0d                	je     802e46 <ipc_recv+0x92>
  802e39:	a1 44 81 80 00       	mov    0x808144,%eax
  802e3e:	8b 50 74             	mov    0x74(%eax),%edx
  802e41:	8b 45 08             	mov    0x8(%ebp),%eax
  802e44:	89 10                	mov    %edx,(%eax)
	if(perm_store) *perm_store = env->env_ipc_perm;
  802e46:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  802e4a:	74 0d                	je     802e59 <ipc_recv+0xa5>
  802e4c:	a1 44 81 80 00       	mov    0x808144,%eax
  802e51:	8b 50 78             	mov    0x78(%eax),%edx
  802e54:	8b 45 10             	mov    0x10(%ebp),%eax
  802e57:	89 10                	mov    %edx,(%eax)
			return error;
		}
	}
	*/

	return env->env_ipc_value;
  802e59:	a1 44 81 80 00       	mov    0x808144,%eax
  802e5e:	8b 40 70             	mov    0x70(%eax),%eax
}
  802e61:	c9                   	leave  
  802e62:	c3                   	ret    

00802e63 <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  802e63:	55                   	push   %ebp
  802e64:	89 e5                	mov    %esp,%ebp
  802e66:	83 ec 28             	sub    $0x28,%esp
	// LAB 4: Your code here.
	//
	DPRINTF5("ipc_send(%d, %u, %x)\n", to_env, val, pg);
	int error;
	while((error = sys_ipc_try_send(to_env, val, !pg ? (void*)UTOP : pg, perm)) == -E_IPC_NOT_RECV) {
  802e69:	eb 05                	jmp    802e70 <ipc_send+0xd>
		sys_yield();
  802e6b:	e8 c2 e5 ff ff       	call   801432 <sys_yield>
{
	// LAB 4: Your code here.
	//
	DPRINTF5("ipc_send(%d, %u, %x)\n", to_env, val, pg);
	int error;
	while((error = sys_ipc_try_send(to_env, val, !pg ? (void*)UTOP : pg, perm)) == -E_IPC_NOT_RECV) {
  802e70:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  802e74:	74 05                	je     802e7b <ipc_send+0x18>
  802e76:	8b 45 10             	mov    0x10(%ebp),%eax
  802e79:	eb 05                	jmp    802e80 <ipc_send+0x1d>
  802e7b:	b8 00 00 c0 ee       	mov    $0xeec00000,%eax
  802e80:	8b 55 14             	mov    0x14(%ebp),%edx
  802e83:	89 54 24 0c          	mov    %edx,0xc(%esp)
  802e87:	89 44 24 08          	mov    %eax,0x8(%esp)
  802e8b:	8b 45 0c             	mov    0xc(%ebp),%eax
  802e8e:	89 44 24 04          	mov    %eax,0x4(%esp)
  802e92:	8b 45 08             	mov    0x8(%ebp),%eax
  802e95:	89 04 24             	mov    %eax,(%esp)
  802e98:	e8 68 e7 ff ff       	call   801605 <sys_ipc_try_send>
  802e9d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  802ea0:	83 7d f4 f9          	cmpl   $0xfffffff9,-0xc(%ebp)
  802ea4:	74 c5                	je     802e6b <ipc_send+0x8>
		sys_yield();
		DPRINTF4C("Retrying ipc_send() ...\n");
	}
        if (error) {
  802ea6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  802eaa:	74 23                	je     802ecf <ipc_send+0x6c>
		panic("Aiee!! sys_ipc_try_send() returned: %e\n", error);
  802eac:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802eaf:	89 44 24 0c          	mov    %eax,0xc(%esp)
  802eb3:	c7 44 24 08 d0 3d 80 	movl   $0x803dd0,0x8(%esp)
  802eba:	00 
  802ebb:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  802ec2:	00 
  802ec3:	c7 04 24 c3 3d 80 00 	movl   $0x803dc3,(%esp)
  802eca:	e8 51 d7 ff ff       	call   800620 <_panic>
        }
}
  802ecf:	c9                   	leave  
  802ed0:	c3                   	ret    
  802ed1:	00 00                	add    %al,(%eax)
	...

00802ed4 <pageref>:
#include <inc/lib.h>

int
pageref(void *v)
{
  802ed4:	55                   	push   %ebp
  802ed5:	89 e5                	mov    %esp,%ebp
  802ed7:	83 ec 10             	sub    $0x10,%esp
	pte_t pte;

	if (!(vpd[PDX(v)] & PTE_P))
  802eda:	8b 45 08             	mov    0x8(%ebp),%eax
  802edd:	c1 e8 16             	shr    $0x16,%eax
  802ee0:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  802ee7:	83 e0 01             	and    $0x1,%eax
  802eea:	85 c0                	test   %eax,%eax
  802eec:	75 07                	jne    802ef5 <pageref+0x21>
		return 0;
  802eee:	b8 00 00 00 00       	mov    $0x0,%eax
  802ef3:	eb 3e                	jmp    802f33 <pageref+0x5f>
	pte = vpt[VPN(v)];
  802ef5:	8b 45 08             	mov    0x8(%ebp),%eax
  802ef8:	c1 e8 0c             	shr    $0xc,%eax
  802efb:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  802f02:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (!(pte & PTE_P))
  802f05:	8b 45 fc             	mov    -0x4(%ebp),%eax
  802f08:	83 e0 01             	and    $0x1,%eax
  802f0b:	85 c0                	test   %eax,%eax
  802f0d:	75 07                	jne    802f16 <pageref+0x42>
		return 0;
  802f0f:	b8 00 00 00 00       	mov    $0x0,%eax
  802f14:	eb 1d                	jmp    802f33 <pageref+0x5f>
	return pages[PPN(pte)].pp_ref;
  802f16:	8b 45 fc             	mov    -0x4(%ebp),%eax
  802f19:	89 c2                	mov    %eax,%edx
  802f1b:	c1 ea 0c             	shr    $0xc,%edx
  802f1e:	89 d0                	mov    %edx,%eax
  802f20:	01 c0                	add    %eax,%eax
  802f22:	01 d0                	add    %edx,%eax
  802f24:	c1 e0 02             	shl    $0x2,%eax
  802f27:	05 00 00 00 ef       	add    $0xef000000,%eax
  802f2c:	0f b7 40 08          	movzwl 0x8(%eax),%eax
  802f30:	0f b7 c0             	movzwl %ax,%eax
}
  802f33:	c9                   	leave  
  802f34:	c3                   	ret    
  802f35:	00 00                	add    %al,(%eax)
	...

00802f38 <inet_addr>:
 * @param cp IP address in ascii represenation (e.g. "127.0.0.1")
 * @return ip address in network order
 */
u32_t
inet_addr(const char *cp)
{
  802f38:	55                   	push   %ebp
  802f39:	89 e5                	mov    %esp,%ebp
  802f3b:	83 ec 28             	sub    $0x28,%esp
  struct in_addr val;

  if (inet_aton(cp, &val)) {
  802f3e:	8d 45 f4             	lea    -0xc(%ebp),%eax
  802f41:	89 44 24 04          	mov    %eax,0x4(%esp)
  802f45:	8b 45 08             	mov    0x8(%ebp),%eax
  802f48:	89 04 24             	mov    %eax,(%esp)
  802f4b:	e8 10 00 00 00       	call   802f60 <inet_aton>
  802f50:	85 c0                	test   %eax,%eax
  802f52:	74 05                	je     802f59 <inet_addr+0x21>
    return (val.s_addr);
  802f54:	8b 45 f4             	mov    -0xc(%ebp),%eax
  802f57:	eb 05                	jmp    802f5e <inet_addr+0x26>
  }
  return (INADDR_NONE);
  802f59:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  802f5e:	c9                   	leave  
  802f5f:	c3                   	ret    

00802f60 <inet_aton>:
 * @param addr pointer to which to save the ip address in network order
 * @return 1 if cp could be converted to addr, 0 on failure
 */
int
inet_aton(const char *cp, struct in_addr *addr)
{
  802f60:	55                   	push   %ebp
  802f61:	89 e5                	mov    %esp,%ebp
  802f63:	53                   	push   %ebx
  802f64:	83 ec 44             	sub    $0x44,%esp
  u32_t val;
  int base, n, c;
  u32_t parts[4];
  u32_t *pp = parts;
  802f67:	8d 45 d4             	lea    -0x2c(%ebp),%eax
  802f6a:	89 45 e8             	mov    %eax,-0x18(%ebp)

  c = *cp;
  802f6d:	8b 45 08             	mov    0x8(%ebp),%eax
  802f70:	0f b6 00             	movzbl (%eax),%eax
  802f73:	0f be c0             	movsbl %al,%eax
  802f76:	89 45 ec             	mov    %eax,-0x14(%ebp)
    /*
     * Collect number up to ``.''.
     * Values are specified as for C:
     * 0x=hex, 0=octal, 1-9=decimal.
     */
    if (!isdigit(c))
  802f79:	8b 45 ec             	mov    -0x14(%ebp),%eax
  802f7c:	3c 2f                	cmp    $0x2f,%al
  802f7e:	76 07                	jbe    802f87 <inet_aton+0x27>
  802f80:	8b 45 ec             	mov    -0x14(%ebp),%eax
  802f83:	3c 39                	cmp    $0x39,%al
  802f85:	76 0a                	jbe    802f91 <inet_aton+0x31>
      return (0);
  802f87:	b8 00 00 00 00       	mov    $0x0,%eax
  802f8c:	e9 3c 02 00 00       	jmp    8031cd <inet_aton+0x26d>
    val = 0;
  802f91:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    base = 10;
  802f98:	c7 45 f0 0a 00 00 00 	movl   $0xa,-0x10(%ebp)
    if (c == '0') {
  802f9f:	83 7d ec 30          	cmpl   $0x30,-0x14(%ebp)
  802fa3:	75 3c                	jne    802fe1 <inet_aton+0x81>
      c = *++cp;
  802fa5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  802fa9:	8b 45 08             	mov    0x8(%ebp),%eax
  802fac:	0f b6 00             	movzbl (%eax),%eax
  802faf:	0f be c0             	movsbl %al,%eax
  802fb2:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if (c == 'x' || c == 'X') {
  802fb5:	83 7d ec 78          	cmpl   $0x78,-0x14(%ebp)
  802fb9:	74 06                	je     802fc1 <inet_aton+0x61>
  802fbb:	83 7d ec 58          	cmpl   $0x58,-0x14(%ebp)
  802fbf:	75 19                	jne    802fda <inet_aton+0x7a>
        base = 16;
  802fc1:	c7 45 f0 10 00 00 00 	movl   $0x10,-0x10(%ebp)
        c = *++cp;
  802fc8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  802fcc:	8b 45 08             	mov    0x8(%ebp),%eax
  802fcf:	0f b6 00             	movzbl (%eax),%eax
  802fd2:	0f be c0             	movsbl %al,%eax
  802fd5:	89 45 ec             	mov    %eax,-0x14(%ebp)
  802fd8:	eb 07                	jmp    802fe1 <inet_aton+0x81>
      } else
        base = 8;
  802fda:	c7 45 f0 08 00 00 00 	movl   $0x8,-0x10(%ebp)
    }
    for (;;) {
      if (isdigit(c)) {
  802fe1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  802fe4:	3c 2f                	cmp    $0x2f,%al
  802fe6:	76 2e                	jbe    803016 <inet_aton+0xb6>
  802fe8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  802feb:	3c 39                	cmp    $0x39,%al
  802fed:	77 27                	ja     803016 <inet_aton+0xb6>
        val = (val * base) + (int)(c - '0');
  802fef:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802ff2:	89 c2                	mov    %eax,%edx
  802ff4:	0f af 55 f4          	imul   -0xc(%ebp),%edx
  802ff8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  802ffb:	8d 04 02             	lea    (%edx,%eax,1),%eax
  802ffe:	83 e8 30             	sub    $0x30,%eax
  803001:	89 45 f4             	mov    %eax,-0xc(%ebp)
        c = *++cp;
  803004:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  803008:	8b 45 08             	mov    0x8(%ebp),%eax
  80300b:	0f b6 00             	movzbl (%eax),%eax
  80300e:	0f be c0             	movsbl %al,%eax
  803011:	89 45 ec             	mov    %eax,-0x14(%ebp)
      } else if (base == 16 && isxdigit(c)) {
        val = (val << 4) | (int)(c + 10 - (islower(c) ? 'a' : 'A'));
        c = *++cp;
      } else
        break;
    }
  803014:	eb cb                	jmp    802fe1 <inet_aton+0x81>
    }
    for (;;) {
      if (isdigit(c)) {
        val = (val * base) + (int)(c - '0');
        c = *++cp;
      } else if (base == 16 && isxdigit(c)) {
  803016:	83 7d f0 10          	cmpl   $0x10,-0x10(%ebp)
  80301a:	75 72                	jne    80308e <inet_aton+0x12e>
  80301c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80301f:	3c 2f                	cmp    $0x2f,%al
  803021:	76 07                	jbe    80302a <inet_aton+0xca>
  803023:	8b 45 ec             	mov    -0x14(%ebp),%eax
  803026:	3c 39                	cmp    $0x39,%al
  803028:	76 1c                	jbe    803046 <inet_aton+0xe6>
  80302a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80302d:	3c 60                	cmp    $0x60,%al
  80302f:	76 07                	jbe    803038 <inet_aton+0xd8>
  803031:	8b 45 ec             	mov    -0x14(%ebp),%eax
  803034:	3c 66                	cmp    $0x66,%al
  803036:	76 0e                	jbe    803046 <inet_aton+0xe6>
  803038:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80303b:	3c 40                	cmp    $0x40,%al
  80303d:	76 4f                	jbe    80308e <inet_aton+0x12e>
  80303f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  803042:	3c 46                	cmp    $0x46,%al
  803044:	77 48                	ja     80308e <inet_aton+0x12e>
        val = (val << 4) | (int)(c + 10 - (islower(c) ? 'a' : 'A'));
  803046:	8b 45 f4             	mov    -0xc(%ebp),%eax
  803049:	89 c2                	mov    %eax,%edx
  80304b:	c1 e2 04             	shl    $0x4,%edx
  80304e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  803051:	8d 48 0a             	lea    0xa(%eax),%ecx
  803054:	8b 45 ec             	mov    -0x14(%ebp),%eax
  803057:	3c 60                	cmp    $0x60,%al
  803059:	76 0e                	jbe    803069 <inet_aton+0x109>
  80305b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80305e:	3c 7a                	cmp    $0x7a,%al
  803060:	77 07                	ja     803069 <inet_aton+0x109>
  803062:	b8 61 00 00 00       	mov    $0x61,%eax
  803067:	eb 05                	jmp    80306e <inet_aton+0x10e>
  803069:	b8 41 00 00 00       	mov    $0x41,%eax
  80306e:	89 cb                	mov    %ecx,%ebx
  803070:	29 c3                	sub    %eax,%ebx
  803072:	89 d8                	mov    %ebx,%eax
  803074:	09 d0                	or     %edx,%eax
  803076:	89 45 f4             	mov    %eax,-0xc(%ebp)
        c = *++cp;
  803079:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  80307d:	8b 45 08             	mov    0x8(%ebp),%eax
  803080:	0f b6 00             	movzbl (%eax),%eax
  803083:	0f be c0             	movsbl %al,%eax
  803086:	89 45 ec             	mov    %eax,-0x14(%ebp)
      } else
        break;
    }
  803089:	e9 53 ff ff ff       	jmp    802fe1 <inet_aton+0x81>
    if (c == '.') {
  80308e:	83 7d ec 2e          	cmpl   $0x2e,-0x14(%ebp)
  803092:	75 36                	jne    8030ca <inet_aton+0x16a>
       * Internet format:
       *  a.b.c.d
       *  a.b.c   (with c treated as 16 bits)
       *  a.b (with b treated as 24 bits)
       */
      if (pp >= parts + 3)
  803094:	8d 45 d4             	lea    -0x2c(%ebp),%eax
  803097:	83 c0 0c             	add    $0xc,%eax
  80309a:	39 45 e8             	cmp    %eax,-0x18(%ebp)
  80309d:	72 0a                	jb     8030a9 <inet_aton+0x149>
        return (0);
  80309f:	b8 00 00 00 00       	mov    $0x0,%eax
  8030a4:	e9 24 01 00 00       	jmp    8031cd <inet_aton+0x26d>
      *pp++ = val;
  8030a9:	8b 45 e8             	mov    -0x18(%ebp),%eax
  8030ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
  8030af:	89 10                	mov    %edx,(%eax)
  8030b1:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
      c = *++cp;
  8030b5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  8030b9:	8b 45 08             	mov    0x8(%ebp),%eax
  8030bc:	0f b6 00             	movzbl (%eax),%eax
  8030bf:	0f be c0             	movsbl %al,%eax
  8030c2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    } else
      break;
  }
  8030c5:	e9 af fe ff ff       	jmp    802f79 <inet_aton+0x19>
  /*
   * Check for trailing characters.
   */
  if (c != '\0' && (!isprint(c) || !isspace(c)))
  8030ca:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  8030ce:	74 3c                	je     80310c <inet_aton+0x1ac>
  8030d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8030d3:	3c 1f                	cmp    $0x1f,%al
  8030d5:	76 2b                	jbe    803102 <inet_aton+0x1a2>
  8030d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8030da:	84 c0                	test   %al,%al
  8030dc:	78 24                	js     803102 <inet_aton+0x1a2>
  8030de:	83 7d ec 20          	cmpl   $0x20,-0x14(%ebp)
  8030e2:	74 28                	je     80310c <inet_aton+0x1ac>
  8030e4:	83 7d ec 0c          	cmpl   $0xc,-0x14(%ebp)
  8030e8:	74 22                	je     80310c <inet_aton+0x1ac>
  8030ea:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
  8030ee:	74 1c                	je     80310c <inet_aton+0x1ac>
  8030f0:	83 7d ec 0d          	cmpl   $0xd,-0x14(%ebp)
  8030f4:	74 16                	je     80310c <inet_aton+0x1ac>
  8030f6:	83 7d ec 09          	cmpl   $0x9,-0x14(%ebp)
  8030fa:	74 10                	je     80310c <inet_aton+0x1ac>
  8030fc:	83 7d ec 0b          	cmpl   $0xb,-0x14(%ebp)
  803100:	74 0a                	je     80310c <inet_aton+0x1ac>
    return (0);
  803102:	b8 00 00 00 00       	mov    $0x0,%eax
  803107:	e9 c1 00 00 00       	jmp    8031cd <inet_aton+0x26d>
  /*
   * Concoct the address according to
   * the number of parts specified.
   */
  n = pp - parts + 1;
  80310c:	8b 55 e8             	mov    -0x18(%ebp),%edx
  80310f:	8d 45 d4             	lea    -0x2c(%ebp),%eax
  803112:	89 d1                	mov    %edx,%ecx
  803114:	29 c1                	sub    %eax,%ecx
  803116:	89 c8                	mov    %ecx,%eax
  803118:	c1 f8 02             	sar    $0x2,%eax
  80311b:	83 c0 01             	add    $0x1,%eax
  80311e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  switch (n) {
  803121:	83 7d e4 04          	cmpl   $0x4,-0x1c(%ebp)
  803125:	0f 87 87 00 00 00    	ja     8031b2 <inet_aton+0x252>
  80312b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80312e:	c1 e0 02             	shl    $0x2,%eax
  803131:	05 f8 3d 80 00       	add    $0x803df8,%eax
  803136:	8b 00                	mov    (%eax),%eax
  803138:	ff e0                	jmp    *%eax

  case 0:
    return (0);       /* initial nondigit */
  80313a:	b8 00 00 00 00       	mov    $0x0,%eax
  80313f:	e9 89 00 00 00       	jmp    8031cd <inet_aton+0x26d>

  case 1:             /* a -- 32 bits */
    break;

  case 2:             /* a.b -- 8.24 bits */
    if (val > 0xffffffUL)
  803144:	81 7d f4 ff ff ff 00 	cmpl   $0xffffff,-0xc(%ebp)
  80314b:	76 07                	jbe    803154 <inet_aton+0x1f4>
      return (0);
  80314d:	b8 00 00 00 00       	mov    $0x0,%eax
  803152:	eb 79                	jmp    8031cd <inet_aton+0x26d>
    val |= parts[0] << 24;
  803154:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  803157:	c1 e0 18             	shl    $0x18,%eax
  80315a:	09 45 f4             	or     %eax,-0xc(%ebp)
    break;
  80315d:	eb 53                	jmp    8031b2 <inet_aton+0x252>

  case 3:             /* a.b.c -- 8.8.16 bits */
    if (val > 0xffff)
  80315f:	81 7d f4 ff ff 00 00 	cmpl   $0xffff,-0xc(%ebp)
  803166:	76 07                	jbe    80316f <inet_aton+0x20f>
      return (0);
  803168:	b8 00 00 00 00       	mov    $0x0,%eax
  80316d:	eb 5e                	jmp    8031cd <inet_aton+0x26d>
    val |= (parts[0] << 24) | (parts[1] << 16);
  80316f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  803172:	89 c2                	mov    %eax,%edx
  803174:	c1 e2 18             	shl    $0x18,%edx
  803177:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80317a:	c1 e0 10             	shl    $0x10,%eax
  80317d:	09 d0                	or     %edx,%eax
  80317f:	09 45 f4             	or     %eax,-0xc(%ebp)
    break;
  803182:	eb 2e                	jmp    8031b2 <inet_aton+0x252>

  case 4:             /* a.b.c.d -- 8.8.8.8 bits */
    if (val > 0xff)
  803184:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
  80318b:	76 07                	jbe    803194 <inet_aton+0x234>
      return (0);
  80318d:	b8 00 00 00 00       	mov    $0x0,%eax
  803192:	eb 39                	jmp    8031cd <inet_aton+0x26d>
    val |= (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8);
  803194:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  803197:	89 c2                	mov    %eax,%edx
  803199:	c1 e2 18             	shl    $0x18,%edx
  80319c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80319f:	c1 e0 10             	shl    $0x10,%eax
  8031a2:	09 c2                	or     %eax,%edx
  8031a4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8031a7:	c1 e0 08             	shl    $0x8,%eax
  8031aa:	09 d0                	or     %edx,%eax
  8031ac:	09 45 f4             	or     %eax,-0xc(%ebp)
    break;
  8031af:	eb 01                	jmp    8031b2 <inet_aton+0x252>

  case 0:
    return (0);       /* initial nondigit */

  case 1:             /* a -- 32 bits */
    break;
  8031b1:	90                   	nop
    if (val > 0xff)
      return (0);
    val |= (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8);
    break;
  }
  if (addr)
  8031b2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8031b6:	74 10                	je     8031c8 <inet_aton+0x268>
    addr->s_addr = htonl(val);
  8031b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8031bb:	89 04 24             	mov    %eax,(%esp)
  8031be:	e8 2a 01 00 00       	call   8032ed <htonl>
  8031c3:	8b 55 0c             	mov    0xc(%ebp),%edx
  8031c6:	89 02                	mov    %eax,(%edx)
  return (1);
  8031c8:	b8 01 00 00 00       	mov    $0x1,%eax
}
  8031cd:	83 c4 44             	add    $0x44,%esp
  8031d0:	5b                   	pop    %ebx
  8031d1:	5d                   	pop    %ebp
  8031d2:	c3                   	ret    

008031d3 <inet_ntoa>:
 * @return pointer to a global static (!) buffer that holds the ASCII
 *         represenation of addr
 */
char *
inet_ntoa(struct in_addr addr)
{
  8031d3:	55                   	push   %ebp
  8031d4:	89 e5                	mov    %esp,%ebp
  8031d6:	83 ec 20             	sub    $0x20,%esp
  static char str[16];
  u32_t s_addr = addr.s_addr;
  8031d9:	8b 45 08             	mov    0x8(%ebp),%eax
  8031dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  u8_t *ap;
  u8_t rem;
  u8_t n;
  u8_t i;

  rp = str;
  8031df:	c7 45 fc a0 70 80 00 	movl   $0x8070a0,-0x4(%ebp)
  ap = (u8_t *)&s_addr;
  8031e6:	8d 45 f0             	lea    -0x10(%ebp),%eax
  8031e9:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(n = 0; n < 4; n++) {
  8031ec:	c6 45 f7 00          	movb   $0x0,-0x9(%ebp)
  8031f0:	e9 a0 00 00 00       	jmp    803295 <inet_ntoa+0xc2>
    i = 0;
  8031f5:	c6 45 f6 00          	movb   $0x0,-0xa(%ebp)
    do {
      rem = *ap % (u8_t)10;
  8031f9:	8b 45 f8             	mov    -0x8(%ebp),%eax
  8031fc:	0f b6 10             	movzbl (%eax),%edx
  8031ff:	b9 cd ff ff ff       	mov    $0xffffffcd,%ecx
  803204:	89 d0                	mov    %edx,%eax
  803206:	f6 e1                	mul    %cl
  803208:	66 c1 e8 08          	shr    $0x8,%ax
  80320c:	c0 e8 03             	shr    $0x3,%al
  80320f:	88 45 f5             	mov    %al,-0xb(%ebp)
  803212:	0f b6 4d f5          	movzbl -0xb(%ebp),%ecx
  803216:	89 c8                	mov    %ecx,%eax
  803218:	c1 e0 02             	shl    $0x2,%eax
  80321b:	01 c8                	add    %ecx,%eax
  80321d:	01 c0                	add    %eax,%eax
  80321f:	89 d1                	mov    %edx,%ecx
  803221:	28 c1                	sub    %al,%cl
  803223:	89 c8                	mov    %ecx,%eax
  803225:	88 45 f5             	mov    %al,-0xb(%ebp)
      *ap /= (u8_t)10;
  803228:	8b 45 f8             	mov    -0x8(%ebp),%eax
  80322b:	0f b6 00             	movzbl (%eax),%eax
  80322e:	ba cd ff ff ff       	mov    $0xffffffcd,%edx
  803233:	f6 e2                	mul    %dl
  803235:	66 c1 e8 08          	shr    $0x8,%ax
  803239:	89 c2                	mov    %eax,%edx
  80323b:	c0 ea 03             	shr    $0x3,%dl
  80323e:	8b 45 f8             	mov    -0x8(%ebp),%eax
  803241:	88 10                	mov    %dl,(%eax)
      inv[i++] = '0' + rem;
  803243:	0f b6 45 f6          	movzbl -0xa(%ebp),%eax
  803247:	0f b6 55 f5          	movzbl -0xb(%ebp),%edx
  80324b:	83 c2 30             	add    $0x30,%edx
  80324e:	88 54 05 ed          	mov    %dl,-0x13(%ebp,%eax,1)
  803252:	80 45 f6 01          	addb   $0x1,-0xa(%ebp)
    } while(*ap);
  803256:	8b 45 f8             	mov    -0x8(%ebp),%eax
  803259:	0f b6 00             	movzbl (%eax),%eax
  80325c:	84 c0                	test   %al,%al
  80325e:	75 99                	jne    8031f9 <inet_ntoa+0x26>
    while(i--)
  803260:	eb 12                	jmp    803274 <inet_ntoa+0xa1>
      *rp++ = inv[i];
  803262:	0f b6 45 f6          	movzbl -0xa(%ebp),%eax
  803266:	0f b6 54 05 ed       	movzbl -0x13(%ebp,%eax,1),%edx
  80326b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  80326e:	88 10                	mov    %dl,(%eax)
  803270:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
    do {
      rem = *ap % (u8_t)10;
      *ap /= (u8_t)10;
      inv[i++] = '0' + rem;
    } while(*ap);
    while(i--)
  803274:	80 7d f6 00          	cmpb   $0x0,-0xa(%ebp)
  803278:	0f 95 c0             	setne  %al
  80327b:	80 6d f6 01          	subb   $0x1,-0xa(%ebp)
  80327f:	84 c0                	test   %al,%al
  803281:	75 df                	jne    803262 <inet_ntoa+0x8f>
      *rp++ = inv[i];
    *rp++ = '.';
  803283:	8b 45 fc             	mov    -0x4(%ebp),%eax
  803286:	c6 00 2e             	movb   $0x2e,(%eax)
  803289:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
    ap++;
  80328d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  u8_t n;
  u8_t i;

  rp = str;
  ap = (u8_t *)&s_addr;
  for(n = 0; n < 4; n++) {
  803291:	80 45 f7 01          	addb   $0x1,-0x9(%ebp)
  803295:	80 7d f7 03          	cmpb   $0x3,-0x9(%ebp)
  803299:	0f 86 56 ff ff ff    	jbe    8031f5 <inet_ntoa+0x22>
    while(i--)
      *rp++ = inv[i];
    *rp++ = '.';
    ap++;
  }
  *--rp = 0;
  80329f:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
  8032a3:	8b 45 fc             	mov    -0x4(%ebp),%eax
  8032a6:	c6 00 00             	movb   $0x0,(%eax)
  return str;
  8032a9:	b8 a0 70 80 00       	mov    $0x8070a0,%eax
}
  8032ae:	c9                   	leave  
  8032af:	c3                   	ret    

008032b0 <htons>:
 * @param n u16_t in host byte order
 * @return n in network byte order
 */
u16_t
htons(u16_t n)
{
  8032b0:	55                   	push   %ebp
  8032b1:	89 e5                	mov    %esp,%ebp
  8032b3:	83 ec 04             	sub    $0x4,%esp
  8032b6:	8b 45 08             	mov    0x8(%ebp),%eax
  8032b9:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  return ((n & 0xff) << 8) | ((n & 0xff00) >> 8);
  8032bd:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
  8032c1:	c1 e0 08             	shl    $0x8,%eax
  8032c4:	89 c2                	mov    %eax,%edx
  8032c6:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
  8032ca:	66 c1 e8 08          	shr    $0x8,%ax
  8032ce:	09 d0                	or     %edx,%eax
}
  8032d0:	c9                   	leave  
  8032d1:	c3                   	ret    

008032d2 <ntohs>:
 * @param n u16_t in network byte order
 * @return n in host byte order
 */
u16_t
ntohs(u16_t n)
{
  8032d2:	55                   	push   %ebp
  8032d3:	89 e5                	mov    %esp,%ebp
  8032d5:	83 ec 08             	sub    $0x8,%esp
  8032d8:	8b 45 08             	mov    0x8(%ebp),%eax
  8032db:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  return htons(n);
  8032df:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
  8032e3:	89 04 24             	mov    %eax,(%esp)
  8032e6:	e8 c5 ff ff ff       	call   8032b0 <htons>
}
  8032eb:	c9                   	leave  
  8032ec:	c3                   	ret    

008032ed <htonl>:
 * @param n u32_t in host byte order
 * @return n in network byte order
 */
u32_t
htonl(u32_t n)
{
  8032ed:	55                   	push   %ebp
  8032ee:	89 e5                	mov    %esp,%ebp
  return ((n & 0xff) << 24) |
  8032f0:	8b 45 08             	mov    0x8(%ebp),%eax
  8032f3:	89 c2                	mov    %eax,%edx
  8032f5:	c1 e2 18             	shl    $0x18,%edx
    ((n & 0xff00) << 8) |
  8032f8:	8b 45 08             	mov    0x8(%ebp),%eax
  8032fb:	25 00 ff 00 00       	and    $0xff00,%eax
  803300:	c1 e0 08             	shl    $0x8,%eax
 * @return n in network byte order
 */
u32_t
htonl(u32_t n)
{
  return ((n & 0xff) << 24) |
  803303:	09 c2                	or     %eax,%edx
    ((n & 0xff00) << 8) |
    ((n & 0xff0000UL) >> 8) |
  803305:	8b 45 08             	mov    0x8(%ebp),%eax
  803308:	25 00 00 ff 00       	and    $0xff0000,%eax
  80330d:	c1 e8 08             	shr    $0x8,%eax
 */
u32_t
htonl(u32_t n)
{
  return ((n & 0xff) << 24) |
    ((n & 0xff00) << 8) |
  803310:	09 c2                	or     %eax,%edx
    ((n & 0xff0000UL) >> 8) |
    ((n & 0xff000000UL) >> 24);
  803312:	8b 45 08             	mov    0x8(%ebp),%eax
  803315:	c1 e8 18             	shr    $0x18,%eax
 * @return n in network byte order
 */
u32_t
htonl(u32_t n)
{
  return ((n & 0xff) << 24) |
  803318:	09 d0                	or     %edx,%eax
    ((n & 0xff00) << 8) |
    ((n & 0xff0000UL) >> 8) |
    ((n & 0xff000000UL) >> 24);
}
  80331a:	5d                   	pop    %ebp
  80331b:	c3                   	ret    

0080331c <ntohl>:
 * @param n u32_t in network byte order
 * @return n in host byte order
 */
u32_t
ntohl(u32_t n)
{
  80331c:	55                   	push   %ebp
  80331d:	89 e5                	mov    %esp,%ebp
  80331f:	83 ec 04             	sub    $0x4,%esp
  return htonl(n);
  803322:	8b 45 08             	mov    0x8(%ebp),%eax
  803325:	89 04 24             	mov    %eax,(%esp)
  803328:	e8 c0 ff ff ff       	call   8032ed <htonl>
}
  80332d:	c9                   	leave  
  80332e:	c3                   	ret    
	...

00803330 <__udivdi3>:
  803330:	55                   	push   %ebp
  803331:	89 e5                	mov    %esp,%ebp
  803333:	57                   	push   %edi
  803334:	56                   	push   %esi
  803335:	83 ec 20             	sub    $0x20,%esp
  803338:	8b 45 14             	mov    0x14(%ebp),%eax
  80333b:	8b 75 08             	mov    0x8(%ebp),%esi
  80333e:	8b 4d 10             	mov    0x10(%ebp),%ecx
  803341:	8b 7d 0c             	mov    0xc(%ebp),%edi
  803344:	85 c0                	test   %eax,%eax
  803346:	89 75 e8             	mov    %esi,-0x18(%ebp)
  803349:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80334c:	75 3a                	jne    803388 <__udivdi3+0x58>
  80334e:	39 f9                	cmp    %edi,%ecx
  803350:	77 66                	ja     8033b8 <__udivdi3+0x88>
  803352:	85 c9                	test   %ecx,%ecx
  803354:	75 0b                	jne    803361 <__udivdi3+0x31>
  803356:	b8 01 00 00 00       	mov    $0x1,%eax
  80335b:	31 d2                	xor    %edx,%edx
  80335d:	f7 f1                	div    %ecx
  80335f:	89 c1                	mov    %eax,%ecx
  803361:	89 f8                	mov    %edi,%eax
  803363:	31 d2                	xor    %edx,%edx
  803365:	f7 f1                	div    %ecx
  803367:	89 c7                	mov    %eax,%edi
  803369:	89 f0                	mov    %esi,%eax
  80336b:	f7 f1                	div    %ecx
  80336d:	89 fa                	mov    %edi,%edx
  80336f:	89 c6                	mov    %eax,%esi
  803371:	89 75 f0             	mov    %esi,-0x10(%ebp)
  803374:	89 55 f4             	mov    %edx,-0xc(%ebp)
  803377:	8b 45 f0             	mov    -0x10(%ebp),%eax
  80337a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  80337d:	83 c4 20             	add    $0x20,%esp
  803380:	5e                   	pop    %esi
  803381:	5f                   	pop    %edi
  803382:	5d                   	pop    %ebp
  803383:	c3                   	ret    
  803384:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  803388:	31 d2                	xor    %edx,%edx
  80338a:	31 f6                	xor    %esi,%esi
  80338c:	39 f8                	cmp    %edi,%eax
  80338e:	77 e1                	ja     803371 <__udivdi3+0x41>
  803390:	0f bd d0             	bsr    %eax,%edx
  803393:	83 f2 1f             	xor    $0x1f,%edx
  803396:	89 55 ec             	mov    %edx,-0x14(%ebp)
  803399:	75 2d                	jne    8033c8 <__udivdi3+0x98>
  80339b:	8b 4d e8             	mov    -0x18(%ebp),%ecx
  80339e:	39 4d f0             	cmp    %ecx,-0x10(%ebp)
  8033a1:	76 06                	jbe    8033a9 <__udivdi3+0x79>
  8033a3:	39 f8                	cmp    %edi,%eax
  8033a5:	89 f2                	mov    %esi,%edx
  8033a7:	73 c8                	jae    803371 <__udivdi3+0x41>
  8033a9:	31 d2                	xor    %edx,%edx
  8033ab:	be 01 00 00 00       	mov    $0x1,%esi
  8033b0:	eb bf                	jmp    803371 <__udivdi3+0x41>
  8033b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8033b8:	89 f0                	mov    %esi,%eax
  8033ba:	89 fa                	mov    %edi,%edx
  8033bc:	f7 f1                	div    %ecx
  8033be:	31 d2                	xor    %edx,%edx
  8033c0:	89 c6                	mov    %eax,%esi
  8033c2:	eb ad                	jmp    803371 <__udivdi3+0x41>
  8033c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8033c8:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  8033cc:	89 c2                	mov    %eax,%edx
  8033ce:	b8 20 00 00 00       	mov    $0x20,%eax
  8033d3:	8b 75 f0             	mov    -0x10(%ebp),%esi
  8033d6:	2b 45 ec             	sub    -0x14(%ebp),%eax
  8033d9:	d3 e2                	shl    %cl,%edx
  8033db:	89 c1                	mov    %eax,%ecx
  8033dd:	d3 ee                	shr    %cl,%esi
  8033df:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  8033e3:	09 d6                	or     %edx,%esi
  8033e5:	89 fa                	mov    %edi,%edx
  8033e7:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8033ea:	8b 75 f0             	mov    -0x10(%ebp),%esi
  8033ed:	d3 e6                	shl    %cl,%esi
  8033ef:	89 c1                	mov    %eax,%ecx
  8033f1:	d3 ea                	shr    %cl,%edx
  8033f3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  8033f7:	89 75 f0             	mov    %esi,-0x10(%ebp)
  8033fa:	8b 75 e8             	mov    -0x18(%ebp),%esi
  8033fd:	d3 e7                	shl    %cl,%edi
  8033ff:	89 c1                	mov    %eax,%ecx
  803401:	d3 ee                	shr    %cl,%esi
  803403:	09 fe                	or     %edi,%esi
  803405:	89 f0                	mov    %esi,%eax
  803407:	f7 75 e4             	divl   -0x1c(%ebp)
  80340a:	89 d7                	mov    %edx,%edi
  80340c:	89 c6                	mov    %eax,%esi
  80340e:	f7 65 f0             	mull   -0x10(%ebp)
  803411:	39 d7                	cmp    %edx,%edi
  803413:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  803416:	72 12                	jb     80342a <__udivdi3+0xfa>
  803418:	8b 55 e8             	mov    -0x18(%ebp),%edx
  80341b:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  80341f:	d3 e2                	shl    %cl,%edx
  803421:	39 c2                	cmp    %eax,%edx
  803423:	73 08                	jae    80342d <__udivdi3+0xfd>
  803425:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
  803428:	75 03                	jne    80342d <__udivdi3+0xfd>
  80342a:	83 ee 01             	sub    $0x1,%esi
  80342d:	31 d2                	xor    %edx,%edx
  80342f:	e9 3d ff ff ff       	jmp    803371 <__udivdi3+0x41>
	...

00803440 <__umoddi3>:
  803440:	55                   	push   %ebp
  803441:	89 e5                	mov    %esp,%ebp
  803443:	57                   	push   %edi
  803444:	56                   	push   %esi
  803445:	83 ec 20             	sub    $0x20,%esp
  803448:	8b 7d 14             	mov    0x14(%ebp),%edi
  80344b:	8b 45 08             	mov    0x8(%ebp),%eax
  80344e:	8b 4d 10             	mov    0x10(%ebp),%ecx
  803451:	8b 75 0c             	mov    0xc(%ebp),%esi
  803454:	85 ff                	test   %edi,%edi
  803456:	89 45 e8             	mov    %eax,-0x18(%ebp)
  803459:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  80345c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  80345f:	89 f2                	mov    %esi,%edx
  803461:	75 15                	jne    803478 <__umoddi3+0x38>
  803463:	39 f1                	cmp    %esi,%ecx
  803465:	76 41                	jbe    8034a8 <__umoddi3+0x68>
  803467:	f7 f1                	div    %ecx
  803469:	89 d0                	mov    %edx,%eax
  80346b:	31 d2                	xor    %edx,%edx
  80346d:	83 c4 20             	add    $0x20,%esp
  803470:	5e                   	pop    %esi
  803471:	5f                   	pop    %edi
  803472:	5d                   	pop    %ebp
  803473:	c3                   	ret    
  803474:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  803478:	39 f7                	cmp    %esi,%edi
  80347a:	77 4c                	ja     8034c8 <__umoddi3+0x88>
  80347c:	0f bd c7             	bsr    %edi,%eax
  80347f:	83 f0 1f             	xor    $0x1f,%eax
  803482:	89 45 ec             	mov    %eax,-0x14(%ebp)
  803485:	75 51                	jne    8034d8 <__umoddi3+0x98>
  803487:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  80348a:	0f 87 e8 00 00 00    	ja     803578 <__umoddi3+0x138>
  803490:	89 f2                	mov    %esi,%edx
  803492:	8b 75 f0             	mov    -0x10(%ebp),%esi
  803495:	29 ce                	sub    %ecx,%esi
  803497:	19 fa                	sbb    %edi,%edx
  803499:	89 75 f0             	mov    %esi,-0x10(%ebp)
  80349c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  80349f:	83 c4 20             	add    $0x20,%esp
  8034a2:	5e                   	pop    %esi
  8034a3:	5f                   	pop    %edi
  8034a4:	5d                   	pop    %ebp
  8034a5:	c3                   	ret    
  8034a6:	66 90                	xchg   %ax,%ax
  8034a8:	85 c9                	test   %ecx,%ecx
  8034aa:	75 0b                	jne    8034b7 <__umoddi3+0x77>
  8034ac:	b8 01 00 00 00       	mov    $0x1,%eax
  8034b1:	31 d2                	xor    %edx,%edx
  8034b3:	f7 f1                	div    %ecx
  8034b5:	89 c1                	mov    %eax,%ecx
  8034b7:	89 f0                	mov    %esi,%eax
  8034b9:	31 d2                	xor    %edx,%edx
  8034bb:	f7 f1                	div    %ecx
  8034bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8034c0:	eb a5                	jmp    803467 <__umoddi3+0x27>
  8034c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8034c8:	89 f2                	mov    %esi,%edx
  8034ca:	83 c4 20             	add    $0x20,%esp
  8034cd:	5e                   	pop    %esi
  8034ce:	5f                   	pop    %edi
  8034cf:	5d                   	pop    %ebp
  8034d0:	c3                   	ret    
  8034d1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8034d8:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  8034dc:	89 f2                	mov    %esi,%edx
  8034de:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8034e1:	c7 45 f0 20 00 00 00 	movl   $0x20,-0x10(%ebp)
  8034e8:	29 45 f0             	sub    %eax,-0x10(%ebp)
  8034eb:	d3 e7                	shl    %cl,%edi
  8034ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8034f0:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  8034f4:	d3 e8                	shr    %cl,%eax
  8034f6:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  8034fa:	09 f8                	or     %edi,%eax
  8034fc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8034ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
  803502:	d3 e0                	shl    %cl,%eax
  803504:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  803508:	89 45 f4             	mov    %eax,-0xc(%ebp)
  80350b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  80350e:	d3 ea                	shr    %cl,%edx
  803510:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  803514:	d3 e6                	shl    %cl,%esi
  803516:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  80351a:	d3 e8                	shr    %cl,%eax
  80351c:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  803520:	09 f0                	or     %esi,%eax
  803522:	8b 75 e8             	mov    -0x18(%ebp),%esi
  803525:	f7 75 e4             	divl   -0x1c(%ebp)
  803528:	d3 e6                	shl    %cl,%esi
  80352a:	89 75 e8             	mov    %esi,-0x18(%ebp)
  80352d:	89 d6                	mov    %edx,%esi
  80352f:	f7 65 f4             	mull   -0xc(%ebp)
  803532:	89 d7                	mov    %edx,%edi
  803534:	89 c2                	mov    %eax,%edx
  803536:	39 fe                	cmp    %edi,%esi
  803538:	89 f9                	mov    %edi,%ecx
  80353a:	72 30                	jb     80356c <__umoddi3+0x12c>
  80353c:	39 45 e8             	cmp    %eax,-0x18(%ebp)
  80353f:	72 27                	jb     803568 <__umoddi3+0x128>
  803541:	8b 45 e8             	mov    -0x18(%ebp),%eax
  803544:	29 d0                	sub    %edx,%eax
  803546:	19 ce                	sbb    %ecx,%esi
  803548:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  80354c:	89 f2                	mov    %esi,%edx
  80354e:	d3 e8                	shr    %cl,%eax
  803550:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  803554:	d3 e2                	shl    %cl,%edx
  803556:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  80355a:	09 d0                	or     %edx,%eax
  80355c:	89 f2                	mov    %esi,%edx
  80355e:	d3 ea                	shr    %cl,%edx
  803560:	83 c4 20             	add    $0x20,%esp
  803563:	5e                   	pop    %esi
  803564:	5f                   	pop    %edi
  803565:	5d                   	pop    %ebp
  803566:	c3                   	ret    
  803567:	90                   	nop
  803568:	39 fe                	cmp    %edi,%esi
  80356a:	75 d5                	jne    803541 <__umoddi3+0x101>
  80356c:	89 f9                	mov    %edi,%ecx
  80356e:	89 c2                	mov    %eax,%edx
  803570:	2b 55 f4             	sub    -0xc(%ebp),%edx
  803573:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
  803576:	eb c9                	jmp    803541 <__umoddi3+0x101>
  803578:	39 f7                	cmp    %esi,%edi
  80357a:	0f 82 10 ff ff ff    	jb     803490 <__umoddi3+0x50>
  803580:	e9 17 ff ff ff       	jmp    80349c <__umoddi3+0x5c>
