// -*- c-basic-offset:8; indent-tabs-mode:t -*-
#include <inc/fs.h>
#include <inc/string.h>
#include <inc/lib.h>

#define debug 0

extern union Fsipc fsipcbuf;	// page-aligned, declared in entry.S

// Send an inter-environment request to the file server, and wait for
// a reply.  The request body should be in fsipcbuf, and parts of the
// response may be written back to fsipcbuf.
// type: request code, passed as the simple integer IPC value.
// dstva: virtual address at which to receive reply page, 0 if none.
// Returns result from the file server.
static int
fsipc(unsigned type, void *dstva)
{
	if (debug)
		cprintf("[%08x] fsipc %d %08x\n", env->env_id, type, *(uint32_t *)&fsipcbuf);

	DPRINTF5("[%08x] fsipc(%d, %08x)\n", env->env_id, type, *(uint32_t *)&fsipcbuf);

	ipc_send(envs[1].env_id, type, &fsipcbuf, PTE_P | PTE_W | PTE_U);
	return ipc_recv(NULL, dstva, NULL);
}

static int devfile_flush(struct Fd *fd);
static ssize_t devfile_read(struct Fd *fd, void *buf, size_t n);
static ssize_t devfile_write(struct Fd *fd, const void *buf, size_t n);
static int devfile_stat(struct Fd *fd, struct Stat *stat);
static int devfile_trunc(struct Fd *fd, off_t newsize);

struct Dev devfile =
{
	.dev_id =	'f',
	.dev_name =	"file",
	.dev_read =	devfile_read,
	.dev_write =	devfile_write,
	.dev_close =	devfile_flush,
	.dev_stat =	devfile_stat,
	.dev_trunc =	devfile_trunc
};

// Open a file (or directory).
//
// Returns:
// 	The file descriptor index on success
// 	-E_BAD_PATH if the path is too long (>= MAXPATHLEN)
// 	< 0 for other errors.
int
open(const char *path, int mode)
{
	// Find an unused file descriptor page using fd_alloc.
	// Then send a file-open request to the file server.
	// Include 'path' and 'omode' in request,
	// and map the returned file descriptor page
	// at the appropriate fd address.
	// FSREQ_OPEN returns 0 on success, < 0 on failure.
	//
	// (fd_alloc does not allocate a page, it just returns an
	// unused fd address.  Do you need to allocate a page?)
	//
	// Return the file descriptor index.
	// If any step after fd_alloc fails, use fd_close to free the
	// file descriptor.

	// LAB 5: Your code here.
	// panic("open not implemented");
	if (strlen(path) >= MAXPATHLEN) {
		return -E_BAD_PATH;
	}

	struct Fd *pfd = NULL;
	int r = fd_alloc(&pfd);
	if (r < 0) {
		return r;
	}

	strcpy(fsipcbuf.open.req_path, path);
	fsipcbuf.open.req_omode = mode;
	r = fsipc(FSREQ_OPEN, pfd);

	if (r < 0) {
		goto cleanup;
	}

	// return pfd->fd_file.id;
	return fd2num(pfd);

 cleanup:
	if (pfd) {
		fd_close(pfd, 0);
	}
	return r;
}

// Flush the file descriptor.  After this the fileid is invalid.
//
// This function is called by fd_close.  fd_close will take care of
// unmapping the FD page from this environment.  Since the server uses
// the reference counts on the FD pages to detect which files are
// open, unmapping it is enough to free up server-side resources.
// Other than that, we just have to make sure our changes are flushed
// to disk.
static int
devfile_flush(struct Fd *fd)
{
	fsipcbuf.flush.req_fileid = fd->fd_file.id;
	return fsipc(FSREQ_FLUSH, NULL);
}

// Read at most 'n' bytes from 'fd' at the current position into 'buf'.
//
// Returns:
// 	The number of bytes successfully read.
// 	< 0 on error.
static ssize_t
devfile_read(struct Fd *fd, void *buf, size_t n)
{
	// Make an FSREQ_READ request to the file system server after
	// filling fsipcbuf.read with the request arguments.  The
	// bytes read will be written back to fsipcbuf by the file
	// system server.
	// LAB 5: Your code here
	// panic("devfile_read not implemented");
	DPRINTF5("devfile_read(%x, %x, %d)\n", fd, buf, n);

	int r;
	fsipcbuf.read.req_fileid = fd->fd_file.id;
	fsipcbuf.read.req_n = n;

	// DPRINTF5("devfile_read::fileid: %d, req_n: %d\n", fsipcbuf.read.req_fileid, fsipcbuf.read.req_n);

	r = fsipc(FSREQ_READ, 0);
	// DPRINTF5("devfile_read got %d(%e) from fsipc\n", r, r);

	if (r < 0) {
		return r;
	}
	assert(r >= 0 && r <= PGSIZE);
	memmove(buf, &(fsipcbuf.readRet.ret_buf), r);
	// if (r < PGSIZE) {
	// ((char*)buf)[r] = '\0';
	// }
	// DPRINTF5("Got (buf): %s\n", buf);

	return r;
}

// Write at most 'n' bytes from 'buf' to 'fd' at the current seek position.
//
// Returns:
//	 The number of bytes successfully written.
//	 < 0 on error.
static ssize_t
devfile_write(struct Fd *fd, const void *buf, size_t n)
{
	// Make an FSREQ_WRITE request to the file system server.  Be
	// careful: fsipcbuf.write.req_buf is only so large, but
	// remember that write is always allowed to write *fewer*
	// bytes than requested.
	// LAB 5: Your code here
	DPRINTF5("devfile_write: writing %d bytes\n:", n);
	assert(buf);
	fsipcbuf.write.req_fileid = fd->fd_file.id;

	ssize_t written = 0;
	size_t write_limit = sizeof(fsipcbuf.write.req_buf);

	while (n > 0) {
		size_t part_size = n < write_limit ? n : write_limit;
		memmove(fsipcbuf.write.req_buf, buf + written, part_size);
		fsipcbuf.write.req_n = part_size;

		ssize_t part_written = fsipc(FSREQ_WRITE, NULL);

		if(part_written < 0) {
			DPRINTF5("devfile_write: Error writing: %e.\n", part_written);
			return part_written;
		}

		DPRINTF5("devfile_write: Wrote %d bytes of %d.\n", part_written, n);

		written += part_written;
		n -= part_written;
	}

	return written;
}

static int
devfile_stat(struct Fd *fd, struct Stat *st)
{
	int r;

	fsipcbuf.stat.req_fileid = fd->fd_file.id;
	if ((r = fsipc(FSREQ_STAT, NULL)) < 0)
		return r;
	strcpy(st->st_name, fsipcbuf.statRet.ret_name);
	st->st_size = fsipcbuf.statRet.ret_size;
	st->st_isdir = fsipcbuf.statRet.ret_isdir;
	return 0;
}

// Truncate or extend an open file to 'size' bytes
static int
devfile_trunc(struct Fd *fd, off_t newsize)
{
	fsipcbuf.set_size.req_fileid = fd->fd_file.id;
	fsipcbuf.set_size.req_size = newsize;
	return fsipc(FSREQ_SET_SIZE, NULL);
}

// Delete a file
int
remove(const char *path)
{
	if (strlen(path) >= MAXPATHLEN)
		return -E_BAD_PATH;
	strcpy(fsipcbuf.remove.req_path, path);
	return fsipc(FSREQ_REMOVE, NULL);
}

// Synchronize disk with buffer cache
int
sync(void)
{
	// Ask the file server to update the disk
	// by writing any dirty blocks in the buffer cache.

	return fsipc(FSREQ_SYNC, NULL);
}

