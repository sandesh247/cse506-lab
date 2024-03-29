#ifndef JOS_INC_STDIO_H
#define JOS_INC_STDIO_H

#include <inc/stdarg.h>

#ifndef NULL
#define NULL	((void *) 0)
#endif /* !NULL */


#define DPRINTF2 // cprintf
#define DPRINTF //  cprintf
#define DPRINTF4 // cprintf
#define DPRINTF4C // cprintf
#define DPRINTF5 // cprintf
#define DPRINTF6 // cprintf
#define DPRINTF7 // cprintf
#define DPRINTF8 cprintf
#define SHOUT6 cprintf
//#define SHOUT6(M, ...) cprintf("SHOUT6 %s:%d:%s: " M, __FILE__, __LINE__, __FUNCTION__, ##__VA_ARGS__)
// #define DPRINTF7(M, ...) cprintf("DPRINTF7 %s:%d:%s: " M, __FILE__, __LINE__, __FUNCTION__, ##__VA_ARGS__)

// lib/stdio.c
void	cputchar(int c);
int	getchar(void);
int	iscons(int fd);

// lib/printfmt.c
void	printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);
void	vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list);
int	snprintf(char *str, int size, const char *fmt, ...);
int	vsnprintf(char *str, int size, const char *fmt, va_list);

// lib/printf.c
int	cprintf(const char *fmt, ...);
int	vcprintf(const char *fmt, va_list);

// lib/fprintf.c
int	printf(const char *fmt, ...);
int	fprintf(int fd, const char *fmt, ...);
int	vfprintf(int fd, const char *fmt, va_list);

// lib/readline.c
char*	readline(const char *prompt);

#endif /* !JOS_INC_STDIO_H */
