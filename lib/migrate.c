

int
migrate() {
    // Send all our pages from UTEXT to UXSTACKTOP to the daemon on the
    // other end.
    // 
    // General Strategy: fork() and send all the child's pages across
    // the network. Also send the child's exception & user stack on
    // the network. The daemon on the other end will fork and replace
    // the child's process image with the image it receives.
    // 
    // message type (32-bits)
    // UTrapFrame
    // pages[npages] (32-bit address, PGSIZE data)
    // last page (only 32-bit address: 0xffffffff)
    // number of pages[npages] (32-bits)
    // 

    return -1;
}
