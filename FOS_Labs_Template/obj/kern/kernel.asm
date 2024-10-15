
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <start_of_kernel-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		start_of_kernel
start_of_kernel:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fb                   	sti    
f0100009:	4f                   	dec    %edi
f010000a:	52                   	push   %edx
f010000b:	e4                   	.byte 0xe4

f010000c <start_of_kernel>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 

	# Establish our own GDT in place of the boot loader's temporary GDT.
	lgdt	RELOC(mygdtdesc)		# load descriptor table
f0100015:	0f 01 15 18 b0 11 00 	lgdtl  0x11b018

	# Immediately reload all segment registers (including CS!)
	# with segment selectors from the new GDT.
	movl	$DATA_SEL, %eax			# Data segment selector
f010001c:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax,%ds				# -> DS: Data Segment
f0100021:	8e d8                	mov    %eax,%ds
	movw	%ax,%es				# -> ES: Extra Segment
f0100023:	8e c0                	mov    %eax,%es
	movw	%ax,%ss				# -> SS: Stack Segment
f0100025:	8e d0                	mov    %eax,%ss
	ljmp	$CODE_SEL,$relocated		# reload CS by jumping
f0100027:	ea 2e 00 10 f0 08 00 	ljmp   $0x8,$0xf010002e

f010002e <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002e:	bd 00 00 00 00       	mov    $0x0,%ebp

        # Leave a few words on the stack for the user trap frame
	movl	$(ptr_stack_top-SIZEOF_STRUCT_TRAPFRAME),%esp
f0100033:	bc bc af 11 f0       	mov    $0xf011afbc,%esp

	# now to C code
	call	FOS_initialize
f0100038:	e8 02 00 00 00       	call   f010003f <FOS_initialize>

f010003d <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003d:	eb fe                	jmp    f010003d <spin>

f010003f <FOS_initialize>:



//First ever function called in FOS kernel
void FOS_initialize()
{
f010003f:	55                   	push   %ebp
f0100040:	89 e5                	mov    %esp,%ebp
f0100042:	83 ec 08             	sub    $0x8,%esp
	extern char start_of_uninitialized_data_section[], end_of_kernel[];

	// Before doing anything else,
	// clear the uninitialized global data (BSS) section of our program, from start_of_uninitialized_data_section to end_of_kernel 
	// This ensures that all static/global variables start with zero value.
	memset(start_of_uninitialized_data_section, 0, end_of_kernel - start_of_uninitialized_data_section);
f0100045:	ba cc e7 14 f0       	mov    $0xf014e7cc,%edx
f010004a:	b8 d2 dc 14 f0       	mov    $0xf014dcd2,%eax
f010004f:	29 c2                	sub    %eax,%edx
f0100051:	89 d0                	mov    %edx,%eax
f0100053:	83 ec 04             	sub    $0x4,%esp
f0100056:	50                   	push   %eax
f0100057:	6a 00                	push   $0x0
f0100059:	68 d2 dc 14 f0       	push   $0xf014dcd2
f010005e:	e8 d2 46 00 00       	call   f0104735 <memset>
f0100063:	83 c4 10             	add    $0x10,%esp

	// Initialize the console.
	// Can't call cprintf until after we do this!
	console_initialize();
f0100066:	e8 7b 08 00 00       	call   f01008e6 <console_initialize>

	//print welcome message
	print_welcome_message();
f010006b:	e8 45 00 00 00       	call   f01000b5 <print_welcome_message>

	// Lab 2 memory management initialization functions
	detect_memory();
f0100070:	e8 50 0e 00 00       	call   f0100ec5 <detect_memory>
	initialize_kernel_VM();
f0100075:	e8 d6 1c 00 00       	call   f0101d50 <initialize_kernel_VM>
	initialize_paging();
f010007a:	e8 95 20 00 00       	call   f0102114 <initialize_paging>
	page_check();
f010007f:	e8 0d 12 00 00       	call   f0101291 <page_check>

	
	// Lab 3 user environment initialization functions
	env_init();
f0100084:	e8 82 28 00 00       	call   f010290b <env_init>
	idt_init();
f0100089:	e8 16 30 00 00       	call   f01030a4 <idt_init>

	
	// start the kernel command prompt.
	while (1==1)
	{
		cprintf("\nWelcome to the FOS kernel command prompt!\n");
f010008e:	83 ec 0c             	sub    $0xc,%esp
f0100091:	68 40 4d 10 f0       	push   $0xf0104d40
f0100096:	e8 b8 2f 00 00       	call   f0103053 <cprintf>
f010009b:	83 c4 10             	add    $0x10,%esp
		cprintf("Type 'help' for a list of commands.\n");	
f010009e:	83 ec 0c             	sub    $0xc,%esp
f01000a1:	68 6c 4d 10 f0       	push   $0xf0104d6c
f01000a6:	e8 a8 2f 00 00       	call   f0103053 <cprintf>
f01000ab:	83 c4 10             	add    $0x10,%esp
		run_command_prompt();
f01000ae:	e8 9e 08 00 00       	call   f0100951 <run_command_prompt>
	}
f01000b3:	eb d9                	jmp    f010008e <FOS_initialize+0x4f>

f01000b5 <print_welcome_message>:
}


void print_welcome_message()
{
f01000b5:	55                   	push   %ebp
f01000b6:	89 e5                	mov    %esp,%ebp
f01000b8:	83 ec 08             	sub    $0x8,%esp
	cprintf("\n\n\n");
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	68 91 4d 10 f0       	push   $0xf0104d91
f01000c3:	e8 8b 2f 00 00       	call   f0103053 <cprintf>
f01000c8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
f01000cb:	83 ec 0c             	sub    $0xc,%esp
f01000ce:	68 98 4d 10 f0       	push   $0xf0104d98
f01000d3:	e8 7b 2f 00 00       	call   f0103053 <cprintf>
f01000d8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                                                             !!\n");
f01000db:	83 ec 0c             	sub    $0xc,%esp
f01000de:	68 e0 4d 10 f0       	push   $0xf0104de0
f01000e3:	e8 6b 2f 00 00       	call   f0103053 <cprintf>
f01000e8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                   !! FCIS says HELLO !!                     !!\n");
f01000eb:	83 ec 0c             	sub    $0xc,%esp
f01000ee:	68 28 4e 10 f0       	push   $0xf0104e28
f01000f3:	e8 5b 2f 00 00       	call   f0103053 <cprintf>
f01000f8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                                                             !!\n");
f01000fb:	83 ec 0c             	sub    $0xc,%esp
f01000fe:	68 e0 4d 10 f0       	push   $0xf0104de0
f0100103:	e8 4b 2f 00 00       	call   f0103053 <cprintf>
f0100108:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
f010010b:	83 ec 0c             	sub    $0xc,%esp
f010010e:	68 98 4d 10 f0       	push   $0xf0104d98
f0100113:	e8 3b 2f 00 00       	call   f0103053 <cprintf>
f0100118:	83 c4 10             	add    $0x10,%esp
	cprintf("\n\n\n\n");	
f010011b:	83 ec 0c             	sub    $0xc,%esp
f010011e:	68 6d 4e 10 f0       	push   $0xf0104e6d
f0100123:	e8 2b 2f 00 00       	call   f0103053 <cprintf>
f0100128:	83 c4 10             	add    $0x10,%esp
}
f010012b:	90                   	nop
f010012c:	c9                   	leave  
f010012d:	c3                   	ret    

f010012e <_panic>:
/*
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel command prompt.
 */
void _panic(const char *file, int line, const char *fmt,...)
{
f010012e:	55                   	push   %ebp
f010012f:	89 e5                	mov    %esp,%ebp
f0100131:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	if (panicstr)
f0100134:	a1 e0 dc 14 f0       	mov    0xf014dce0,%eax
f0100139:	85 c0                	test   %eax,%eax
f010013b:	74 02                	je     f010013f <_panic+0x11>
		goto dead;
f010013d:	eb 49                	jmp    f0100188 <_panic+0x5a>
	panicstr = fmt;
f010013f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100142:	a3 e0 dc 14 f0       	mov    %eax,0xf014dce0

	va_start(ap, fmt);
f0100147:	8d 45 10             	lea    0x10(%ebp),%eax
f010014a:	83 c0 04             	add    $0x4,%eax
f010014d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
f0100150:	83 ec 04             	sub    $0x4,%esp
f0100153:	ff 75 0c             	pushl  0xc(%ebp)
f0100156:	ff 75 08             	pushl  0x8(%ebp)
f0100159:	68 72 4e 10 f0       	push   $0xf0104e72
f010015e:	e8 f0 2e 00 00       	call   f0103053 <cprintf>
f0100163:	83 c4 10             	add    $0x10,%esp
	vcprintf(fmt, ap);
f0100166:	8b 45 10             	mov    0x10(%ebp),%eax
f0100169:	83 ec 08             	sub    $0x8,%esp
f010016c:	ff 75 f4             	pushl  -0xc(%ebp)
f010016f:	50                   	push   %eax
f0100170:	e8 b5 2e 00 00       	call   f010302a <vcprintf>
f0100175:	83 c4 10             	add    $0x10,%esp
	cprintf("\n");
f0100178:	83 ec 0c             	sub    $0xc,%esp
f010017b:	68 8a 4e 10 f0       	push   $0xf0104e8a
f0100180:	e8 ce 2e 00 00       	call   f0103053 <cprintf>
f0100185:	83 c4 10             	add    $0x10,%esp
	va_end(ap);

dead:
	/* break into the kernel command prompt */
	while (1==1)
		run_command_prompt();
f0100188:	e8 c4 07 00 00       	call   f0100951 <run_command_prompt>
f010018d:	eb f9                	jmp    f0100188 <_panic+0x5a>

f010018f <_warn>:
}

/* like panic, but don't enters the kernel command prompt*/
void _warn(const char *file, int line, const char *fmt,...)
{
f010018f:	55                   	push   %ebp
f0100190:	89 e5                	mov    %esp,%ebp
f0100192:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100195:	8d 45 10             	lea    0x10(%ebp),%eax
f0100198:	83 c0 04             	add    $0x4,%eax
f010019b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
f010019e:	83 ec 04             	sub    $0x4,%esp
f01001a1:	ff 75 0c             	pushl  0xc(%ebp)
f01001a4:	ff 75 08             	pushl  0x8(%ebp)
f01001a7:	68 8c 4e 10 f0       	push   $0xf0104e8c
f01001ac:	e8 a2 2e 00 00       	call   f0103053 <cprintf>
f01001b1:	83 c4 10             	add    $0x10,%esp
	vcprintf(fmt, ap);
f01001b4:	8b 45 10             	mov    0x10(%ebp),%eax
f01001b7:	83 ec 08             	sub    $0x8,%esp
f01001ba:	ff 75 f4             	pushl  -0xc(%ebp)
f01001bd:	50                   	push   %eax
f01001be:	e8 67 2e 00 00       	call   f010302a <vcprintf>
f01001c3:	83 c4 10             	add    $0x10,%esp
	cprintf("\n");
f01001c6:	83 ec 0c             	sub    $0xc,%esp
f01001c9:	68 8a 4e 10 f0       	push   $0xf0104e8a
f01001ce:	e8 80 2e 00 00       	call   f0103053 <cprintf>
f01001d3:	83 c4 10             	add    $0x10,%esp
	va_end(ap);
}
f01001d6:	90                   	nop
f01001d7:	c9                   	leave  
f01001d8:	c3                   	ret    

f01001d9 <serial_proc_data>:

static bool serial_exists;

int
serial_proc_data(void)
{
f01001d9:	55                   	push   %ebp
f01001da:	89 e5                	mov    %esp,%ebp
f01001dc:	83 ec 10             	sub    $0x10,%esp
f01001df:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e6:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01001e9:	89 c2                	mov    %eax,%edx
f01001eb:	ec                   	in     (%dx),%al
f01001ec:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f01001ef:	8a 45 f7             	mov    -0x9(%ebp),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001f2:	0f b6 c0             	movzbl %al,%eax
f01001f5:	83 e0 01             	and    $0x1,%eax
f01001f8:	85 c0                	test   %eax,%eax
f01001fa:	75 07                	jne    f0100203 <serial_proc_data+0x2a>
		return -1;
f01001fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100201:	eb 16                	jmp    f0100219 <serial_proc_data+0x40>
f0100203:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010020a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010020d:	89 c2                	mov    %eax,%edx
f010020f:	ec                   	in     (%dx),%al
f0100210:	88 45 f6             	mov    %al,-0xa(%ebp)
	return data;
f0100213:	8a 45 f6             	mov    -0xa(%ebp),%al
	return inb(COM1+COM_RX);
f0100216:	0f b6 c0             	movzbl %al,%eax
}
f0100219:	c9                   	leave  
f010021a:	c3                   	ret    

f010021b <serial_intr>:

void
serial_intr(void)
{
f010021b:	55                   	push   %ebp
f010021c:	89 e5                	mov    %esp,%ebp
f010021e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100221:	a1 00 dd 14 f0       	mov    0xf014dd00,%eax
f0100226:	85 c0                	test   %eax,%eax
f0100228:	74 10                	je     f010023a <serial_intr+0x1f>
		cons_intr(serial_proc_data);
f010022a:	83 ec 0c             	sub    $0xc,%esp
f010022d:	68 d9 01 10 f0       	push   $0xf01001d9
f0100232:	e8 e4 05 00 00       	call   f010081b <cons_intr>
f0100237:	83 c4 10             	add    $0x10,%esp
}
f010023a:	90                   	nop
f010023b:	c9                   	leave  
f010023c:	c3                   	ret    

f010023d <serial_init>:

void
serial_init(void)
{
f010023d:	55                   	push   %ebp
f010023e:	89 e5                	mov    %esp,%ebp
f0100240:	83 ec 40             	sub    $0x40,%esp
f0100243:	c7 45 fc fa 03 00 00 	movl   $0x3fa,-0x4(%ebp)
f010024a:	c6 45 ce 00          	movb   $0x0,-0x32(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010024e:	8a 45 ce             	mov    -0x32(%ebp),%al
f0100251:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100254:	ee                   	out    %al,(%dx)
f0100255:	c7 45 f8 fb 03 00 00 	movl   $0x3fb,-0x8(%ebp)
f010025c:	c6 45 cf 80          	movb   $0x80,-0x31(%ebp)
f0100260:	8a 45 cf             	mov    -0x31(%ebp),%al
f0100263:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0100266:	ee                   	out    %al,(%dx)
f0100267:	c7 45 f4 f8 03 00 00 	movl   $0x3f8,-0xc(%ebp)
f010026e:	c6 45 d0 0c          	movb   $0xc,-0x30(%ebp)
f0100272:	8a 45 d0             	mov    -0x30(%ebp),%al
f0100275:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100278:	ee                   	out    %al,(%dx)
f0100279:	c7 45 f0 f9 03 00 00 	movl   $0x3f9,-0x10(%ebp)
f0100280:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
f0100284:	8a 45 d1             	mov    -0x2f(%ebp),%al
f0100287:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010028a:	ee                   	out    %al,(%dx)
f010028b:	c7 45 ec fb 03 00 00 	movl   $0x3fb,-0x14(%ebp)
f0100292:	c6 45 d2 03          	movb   $0x3,-0x2e(%ebp)
f0100296:	8a 45 d2             	mov    -0x2e(%ebp),%al
f0100299:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010029c:	ee                   	out    %al,(%dx)
f010029d:	c7 45 e8 fc 03 00 00 	movl   $0x3fc,-0x18(%ebp)
f01002a4:	c6 45 d3 00          	movb   $0x0,-0x2d(%ebp)
f01002a8:	8a 45 d3             	mov    -0x2d(%ebp),%al
f01002ab:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01002ae:	ee                   	out    %al,(%dx)
f01002af:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
f01002b6:	c6 45 d4 01          	movb   $0x1,-0x2c(%ebp)
f01002ba:	8a 45 d4             	mov    -0x2c(%ebp),%al
f01002bd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01002c0:	ee                   	out    %al,(%dx)
f01002c1:	c7 45 e0 fd 03 00 00 	movl   $0x3fd,-0x20(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01002cb:	89 c2                	mov    %eax,%edx
f01002cd:	ec                   	in     (%dx),%al
f01002ce:	88 45 d5             	mov    %al,-0x2b(%ebp)
	return data;
f01002d1:	8a 45 d5             	mov    -0x2b(%ebp),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01002d4:	3c ff                	cmp    $0xff,%al
f01002d6:	0f 95 c0             	setne  %al
f01002d9:	0f b6 c0             	movzbl %al,%eax
f01002dc:	a3 00 dd 14 f0       	mov    %eax,0xf014dd00
f01002e1:	c7 45 dc fa 03 00 00 	movl   $0x3fa,-0x24(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01002eb:	89 c2                	mov    %eax,%edx
f01002ed:	ec                   	in     (%dx),%al
f01002ee:	88 45 d6             	mov    %al,-0x2a(%ebp)
f01002f1:	c7 45 d8 f8 03 00 00 	movl   $0x3f8,-0x28(%ebp)
f01002f8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01002fb:	89 c2                	mov    %eax,%edx
f01002fd:	ec                   	in     (%dx),%al
f01002fe:	88 45 d7             	mov    %al,-0x29(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
f0100301:	90                   	nop
f0100302:	c9                   	leave  
f0100303:	c3                   	ret    

f0100304 <delay>:
// page.

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100304:	55                   	push   %ebp
f0100305:	89 e5                	mov    %esp,%ebp
f0100307:	83 ec 20             	sub    $0x20,%esp
f010030a:	c7 45 fc 84 00 00 00 	movl   $0x84,-0x4(%ebp)
f0100311:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100314:	89 c2                	mov    %eax,%edx
f0100316:	ec                   	in     (%dx),%al
f0100317:	88 45 ec             	mov    %al,-0x14(%ebp)
f010031a:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)
f0100321:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100324:	89 c2                	mov    %eax,%edx
f0100326:	ec                   	in     (%dx),%al
f0100327:	88 45 ed             	mov    %al,-0x13(%ebp)
f010032a:	c7 45 f4 84 00 00 00 	movl   $0x84,-0xc(%ebp)
f0100331:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100334:	89 c2                	mov    %eax,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	88 45 ee             	mov    %al,-0x12(%ebp)
f010033a:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)
f0100341:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100344:	89 c2                	mov    %eax,%edx
f0100346:	ec                   	in     (%dx),%al
f0100347:	88 45 ef             	mov    %al,-0x11(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010034a:	90                   	nop
f010034b:	c9                   	leave  
f010034c:	c3                   	ret    

f010034d <lpt_putc>:

static void
lpt_putc(int c)
{
f010034d:	55                   	push   %ebp
f010034e:	89 e5                	mov    %esp,%ebp
f0100350:	83 ec 20             	sub    $0x20,%esp
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 2800; i++) //12800
f0100353:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f010035a:	eb 08                	jmp    f0100364 <lpt_putc+0x17>
		delay();
f010035c:	e8 a3 ff ff ff       	call   f0100304 <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 2800; i++) //12800
f0100361:	ff 45 fc             	incl   -0x4(%ebp)
f0100364:	c7 45 ec 79 03 00 00 	movl   $0x379,-0x14(%ebp)
f010036b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010036e:	89 c2                	mov    %eax,%edx
f0100370:	ec                   	in     (%dx),%al
f0100371:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
f0100374:	8a 45 eb             	mov    -0x15(%ebp),%al
f0100377:	84 c0                	test   %al,%al
f0100379:	78 09                	js     f0100384 <lpt_putc+0x37>
f010037b:	81 7d fc ef 0a 00 00 	cmpl   $0xaef,-0x4(%ebp)
f0100382:	7e d8                	jle    f010035c <lpt_putc+0xf>
		delay();
	outb(0x378+0, c);
f0100384:	8b 45 08             	mov    0x8(%ebp),%eax
f0100387:	0f b6 c0             	movzbl %al,%eax
f010038a:	c7 45 f4 78 03 00 00 	movl   $0x378,-0xc(%ebp)
f0100391:	88 45 e8             	mov    %al,-0x18(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100394:	8a 45 e8             	mov    -0x18(%ebp),%al
f0100397:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010039a:	ee                   	out    %al,(%dx)
f010039b:	c7 45 f0 7a 03 00 00 	movl   $0x37a,-0x10(%ebp)
f01003a2:	c6 45 e9 0d          	movb   $0xd,-0x17(%ebp)
f01003a6:	8a 45 e9             	mov    -0x17(%ebp),%al
f01003a9:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01003ac:	ee                   	out    %al,(%dx)
f01003ad:	c7 45 f8 7a 03 00 00 	movl   $0x37a,-0x8(%ebp)
f01003b4:	c6 45 ea 08          	movb   $0x8,-0x16(%ebp)
f01003b8:	8a 45 ea             	mov    -0x16(%ebp),%al
f01003bb:	8b 55 f8             	mov    -0x8(%ebp),%edx
f01003be:	ee                   	out    %al,(%dx)
	outb(0x378+2, 0x08|0x04|0x01);
	outb(0x378+2, 0x08);
}
f01003bf:	90                   	nop
f01003c0:	c9                   	leave  
f01003c1:	c3                   	ret    

f01003c2 <cga_init>:
static uint16 *crt_buf;
static uint16 crt_pos;

void
cga_init(void)
{
f01003c2:	55                   	push   %ebp
f01003c3:	89 e5                	mov    %esp,%ebp
f01003c5:	83 ec 20             	sub    $0x20,%esp
	volatile uint16 *cp;
	uint16 was;
	unsigned pos;

	cp = (uint16*) (KERNEL_BASE + CGA_BUF);
f01003c8:	c7 45 fc 00 80 0b f0 	movl   $0xf00b8000,-0x4(%ebp)
	was = *cp;
f01003cf:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01003d2:	66 8b 00             	mov    (%eax),%ax
f01003d5:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
	*cp = (uint16) 0xA55A;
f01003d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01003dc:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f01003e1:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01003e4:	66 8b 00             	mov    (%eax),%ax
f01003e7:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01003eb:	74 13                	je     f0100400 <cga_init+0x3e>
		cp = (uint16*) (KERNEL_BASE + MONO_BUF);
f01003ed:	c7 45 fc 00 00 0b f0 	movl   $0xf00b0000,-0x4(%ebp)
		addr_6845 = MONO_BASE;
f01003f4:	c7 05 04 dd 14 f0 b4 	movl   $0x3b4,0xf014dd04
f01003fb:	03 00 00 
f01003fe:	eb 14                	jmp    f0100414 <cga_init+0x52>
	} else {
		*cp = was;
f0100400:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100403:	66 8b 45 fa          	mov    -0x6(%ebp),%ax
f0100407:	66 89 02             	mov    %ax,(%edx)
		addr_6845 = CGA_BASE;
f010040a:	c7 05 04 dd 14 f0 d4 	movl   $0x3d4,0xf014dd04
f0100411:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100414:	a1 04 dd 14 f0       	mov    0xf014dd04,%eax
f0100419:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010041c:	c6 45 e0 0e          	movb   $0xe,-0x20(%ebp)
f0100420:	8a 45 e0             	mov    -0x20(%ebp),%al
f0100423:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100426:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100427:	a1 04 dd 14 f0       	mov    0xf014dd04,%eax
f010042c:	40                   	inc    %eax
f010042d:	89 45 ec             	mov    %eax,-0x14(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100430:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100433:	89 c2                	mov    %eax,%edx
f0100435:	ec                   	in     (%dx),%al
f0100436:	88 45 e1             	mov    %al,-0x1f(%ebp)
	return data;
f0100439:	8a 45 e1             	mov    -0x1f(%ebp),%al
f010043c:	0f b6 c0             	movzbl %al,%eax
f010043f:	c1 e0 08             	shl    $0x8,%eax
f0100442:	89 45 f0             	mov    %eax,-0x10(%ebp)
	outb(addr_6845, 15);
f0100445:	a1 04 dd 14 f0       	mov    0xf014dd04,%eax
f010044a:	89 45 e8             	mov    %eax,-0x18(%ebp)
f010044d:	c6 45 e2 0f          	movb   $0xf,-0x1e(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100451:	8a 45 e2             	mov    -0x1e(%ebp),%al
f0100454:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100457:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
f0100458:	a1 04 dd 14 f0       	mov    0xf014dd04,%eax
f010045d:	40                   	inc    %eax
f010045e:	89 45 e4             	mov    %eax,-0x1c(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100461:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100464:	89 c2                	mov    %eax,%edx
f0100466:	ec                   	in     (%dx),%al
f0100467:	88 45 e3             	mov    %al,-0x1d(%ebp)
	return data;
f010046a:	8a 45 e3             	mov    -0x1d(%ebp),%al
f010046d:	0f b6 c0             	movzbl %al,%eax
f0100470:	09 45 f0             	or     %eax,-0x10(%ebp)

	crt_buf = (uint16*) cp;
f0100473:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100476:	a3 08 dd 14 f0       	mov    %eax,0xf014dd08
	crt_pos = pos;
f010047b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010047e:	66 a3 0c dd 14 f0    	mov    %ax,0xf014dd0c
}
f0100484:	90                   	nop
f0100485:	c9                   	leave  
f0100486:	c3                   	ret    

f0100487 <cga_putc>:



void
cga_putc(int c)
{
f0100487:	55                   	push   %ebp
f0100488:	89 e5                	mov    %esp,%ebp
f010048a:	53                   	push   %ebx
f010048b:	83 ec 24             	sub    $0x24,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010048e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100491:	b0 00                	mov    $0x0,%al
f0100493:	85 c0                	test   %eax,%eax
f0100495:	75 07                	jne    f010049e <cga_putc+0x17>
		c |= 0x0700;
f0100497:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
f010049e:	8b 45 08             	mov    0x8(%ebp),%eax
f01004a1:	0f b6 c0             	movzbl %al,%eax
f01004a4:	83 f8 09             	cmp    $0x9,%eax
f01004a7:	0f 84 94 00 00 00    	je     f0100541 <cga_putc+0xba>
f01004ad:	83 f8 09             	cmp    $0x9,%eax
f01004b0:	7f 0a                	jg     f01004bc <cga_putc+0x35>
f01004b2:	83 f8 08             	cmp    $0x8,%eax
f01004b5:	74 14                	je     f01004cb <cga_putc+0x44>
f01004b7:	e9 c8 00 00 00       	jmp    f0100584 <cga_putc+0xfd>
f01004bc:	83 f8 0a             	cmp    $0xa,%eax
f01004bf:	74 49                	je     f010050a <cga_putc+0x83>
f01004c1:	83 f8 0d             	cmp    $0xd,%eax
f01004c4:	74 53                	je     f0100519 <cga_putc+0x92>
f01004c6:	e9 b9 00 00 00       	jmp    f0100584 <cga_putc+0xfd>
	case '\b':
		if (crt_pos > 0) {
f01004cb:	66 a1 0c dd 14 f0    	mov    0xf014dd0c,%ax
f01004d1:	66 85 c0             	test   %ax,%ax
f01004d4:	0f 84 d0 00 00 00    	je     f01005aa <cga_putc+0x123>
			crt_pos--;
f01004da:	66 a1 0c dd 14 f0    	mov    0xf014dd0c,%ax
f01004e0:	48                   	dec    %eax
f01004e1:	66 a3 0c dd 14 f0    	mov    %ax,0xf014dd0c
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004e7:	8b 15 08 dd 14 f0    	mov    0xf014dd08,%edx
f01004ed:	66 a1 0c dd 14 f0    	mov    0xf014dd0c,%ax
f01004f3:	0f b7 c0             	movzwl %ax,%eax
f01004f6:	01 c0                	add    %eax,%eax
f01004f8:	01 c2                	add    %eax,%edx
f01004fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01004fd:	b0 00                	mov    $0x0,%al
f01004ff:	83 c8 20             	or     $0x20,%eax
f0100502:	66 89 02             	mov    %ax,(%edx)
		}
		break;
f0100505:	e9 a0 00 00 00       	jmp    f01005aa <cga_putc+0x123>
	case '\n':
		crt_pos += CRT_COLS;
f010050a:	66 a1 0c dd 14 f0    	mov    0xf014dd0c,%ax
f0100510:	83 c0 50             	add    $0x50,%eax
f0100513:	66 a3 0c dd 14 f0    	mov    %ax,0xf014dd0c
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100519:	66 8b 0d 0c dd 14 f0 	mov    0xf014dd0c,%cx
f0100520:	66 a1 0c dd 14 f0    	mov    0xf014dd0c,%ax
f0100526:	bb 50 00 00 00       	mov    $0x50,%ebx
f010052b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100530:	66 f7 f3             	div    %bx
f0100533:	89 d0                	mov    %edx,%eax
f0100535:	29 c1                	sub    %eax,%ecx
f0100537:	89 c8                	mov    %ecx,%eax
f0100539:	66 a3 0c dd 14 f0    	mov    %ax,0xf014dd0c
		break;
f010053f:	eb 6a                	jmp    f01005ab <cga_putc+0x124>
	case '\t':
		cons_putc(' ');
f0100541:	83 ec 0c             	sub    $0xc,%esp
f0100544:	6a 20                	push   $0x20
f0100546:	e8 79 03 00 00       	call   f01008c4 <cons_putc>
f010054b:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f010054e:	83 ec 0c             	sub    $0xc,%esp
f0100551:	6a 20                	push   $0x20
f0100553:	e8 6c 03 00 00       	call   f01008c4 <cons_putc>
f0100558:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f010055b:	83 ec 0c             	sub    $0xc,%esp
f010055e:	6a 20                	push   $0x20
f0100560:	e8 5f 03 00 00       	call   f01008c4 <cons_putc>
f0100565:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f0100568:	83 ec 0c             	sub    $0xc,%esp
f010056b:	6a 20                	push   $0x20
f010056d:	e8 52 03 00 00       	call   f01008c4 <cons_putc>
f0100572:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f0100575:	83 ec 0c             	sub    $0xc,%esp
f0100578:	6a 20                	push   $0x20
f010057a:	e8 45 03 00 00       	call   f01008c4 <cons_putc>
f010057f:	83 c4 10             	add    $0x10,%esp
		break;
f0100582:	eb 27                	jmp    f01005ab <cga_putc+0x124>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100584:	8b 0d 08 dd 14 f0    	mov    0xf014dd08,%ecx
f010058a:	66 a1 0c dd 14 f0    	mov    0xf014dd0c,%ax
f0100590:	8d 50 01             	lea    0x1(%eax),%edx
f0100593:	66 89 15 0c dd 14 f0 	mov    %dx,0xf014dd0c
f010059a:	0f b7 c0             	movzwl %ax,%eax
f010059d:	01 c0                	add    %eax,%eax
f010059f:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f01005a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01005a5:	66 89 02             	mov    %ax,(%edx)
		break;
f01005a8:	eb 01                	jmp    f01005ab <cga_putc+0x124>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
f01005aa:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005ab:	66 a1 0c dd 14 f0    	mov    0xf014dd0c,%ax
f01005b1:	66 3d cf 07          	cmp    $0x7cf,%ax
f01005b5:	76 58                	jbe    f010060f <cga_putc+0x188>
		int i;

		memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16));
f01005b7:	a1 08 dd 14 f0       	mov    0xf014dd08,%eax
f01005bc:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005c2:	a1 08 dd 14 f0       	mov    0xf014dd08,%eax
f01005c7:	83 ec 04             	sub    $0x4,%esp
f01005ca:	68 00 0f 00 00       	push   $0xf00
f01005cf:	52                   	push   %edx
f01005d0:	50                   	push   %eax
f01005d1:	e8 8f 41 00 00       	call   f0104765 <memcpy>
f01005d6:	83 c4 10             	add    $0x10,%esp
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005d9:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
f01005e0:	eb 15                	jmp    f01005f7 <cga_putc+0x170>
			crt_buf[i] = 0x0700 | ' ';
f01005e2:	8b 15 08 dd 14 f0    	mov    0xf014dd08,%edx
f01005e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01005eb:	01 c0                	add    %eax,%eax
f01005ed:	01 d0                	add    %edx,%eax
f01005ef:	66 c7 00 20 07       	movw   $0x720,(%eax)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005f4:	ff 45 f4             	incl   -0xc(%ebp)
f01005f7:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
f01005fe:	7e e2                	jle    f01005e2 <cga_putc+0x15b>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100600:	66 a1 0c dd 14 f0    	mov    0xf014dd0c,%ax
f0100606:	83 e8 50             	sub    $0x50,%eax
f0100609:	66 a3 0c dd 14 f0    	mov    %ax,0xf014dd0c
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010060f:	a1 04 dd 14 f0       	mov    0xf014dd04,%eax
f0100614:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100617:	c6 45 e0 0e          	movb   $0xe,-0x20(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010061b:	8a 45 e0             	mov    -0x20(%ebp),%al
f010061e:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100621:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100622:	66 a1 0c dd 14 f0    	mov    0xf014dd0c,%ax
f0100628:	66 c1 e8 08          	shr    $0x8,%ax
f010062c:	0f b6 c0             	movzbl %al,%eax
f010062f:	8b 15 04 dd 14 f0    	mov    0xf014dd04,%edx
f0100635:	42                   	inc    %edx
f0100636:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0100639:	88 45 e1             	mov    %al,-0x1f(%ebp)
f010063c:	8a 45 e1             	mov    -0x1f(%ebp),%al
f010063f:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0100642:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
f0100643:	a1 04 dd 14 f0       	mov    0xf014dd04,%eax
f0100648:	89 45 e8             	mov    %eax,-0x18(%ebp)
f010064b:	c6 45 e2 0f          	movb   $0xf,-0x1e(%ebp)
f010064f:	8a 45 e2             	mov    -0x1e(%ebp),%al
f0100652:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100655:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
f0100656:	66 a1 0c dd 14 f0    	mov    0xf014dd0c,%ax
f010065c:	0f b6 c0             	movzbl %al,%eax
f010065f:	8b 15 04 dd 14 f0    	mov    0xf014dd04,%edx
f0100665:	42                   	inc    %edx
f0100666:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100669:	88 45 e3             	mov    %al,-0x1d(%ebp)
f010066c:	8a 45 e3             	mov    -0x1d(%ebp),%al
f010066f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100672:	ee                   	out    %al,(%dx)
}
f0100673:	90                   	nop
f0100674:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100677:	c9                   	leave  
f0100678:	c3                   	ret    

f0100679 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100679:	55                   	push   %ebp
f010067a:	89 e5                	mov    %esp,%ebp
f010067c:	83 ec 28             	sub    $0x28,%esp
f010067f:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100686:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100689:	89 c2                	mov    %eax,%edx
f010068b:	ec                   	in     (%dx),%al
f010068c:	88 45 e3             	mov    %al,-0x1d(%ebp)
	return data;
f010068f:	8a 45 e3             	mov    -0x1d(%ebp),%al
	int c;
	uint8 data;
	static uint32 shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100692:	0f b6 c0             	movzbl %al,%eax
f0100695:	83 e0 01             	and    $0x1,%eax
f0100698:	85 c0                	test   %eax,%eax
f010069a:	75 0a                	jne    f01006a6 <kbd_proc_data+0x2d>
		return -1;
f010069c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01006a1:	e9 54 01 00 00       	jmp    f01007fa <kbd_proc_data+0x181>
f01006a6:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01006b0:	89 c2                	mov    %eax,%edx
f01006b2:	ec                   	in     (%dx),%al
f01006b3:	88 45 e2             	mov    %al,-0x1e(%ebp)
	return data;
f01006b6:	8a 45 e2             	mov    -0x1e(%ebp),%al

	data = inb(KBDATAP);
f01006b9:	88 45 f3             	mov    %al,-0xd(%ebp)

	if (data == 0xE0) {
f01006bc:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
f01006c0:	75 17                	jne    f01006d9 <kbd_proc_data+0x60>
		// E0 escape character
		shift |= E0ESC;
f01006c2:	a1 28 df 14 f0       	mov    0xf014df28,%eax
f01006c7:	83 c8 40             	or     $0x40,%eax
f01006ca:	a3 28 df 14 f0       	mov    %eax,0xf014df28
		return 0;
f01006cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d4:	e9 21 01 00 00       	jmp    f01007fa <kbd_proc_data+0x181>
	} else if (data & 0x80) {
f01006d9:	8a 45 f3             	mov    -0xd(%ebp),%al
f01006dc:	84 c0                	test   %al,%al
f01006de:	79 44                	jns    f0100724 <kbd_proc_data+0xab>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01006e0:	a1 28 df 14 f0       	mov    0xf014df28,%eax
f01006e5:	83 e0 40             	and    $0x40,%eax
f01006e8:	85 c0                	test   %eax,%eax
f01006ea:	75 08                	jne    f01006f4 <kbd_proc_data+0x7b>
f01006ec:	8a 45 f3             	mov    -0xd(%ebp),%al
f01006ef:	83 e0 7f             	and    $0x7f,%eax
f01006f2:	eb 03                	jmp    f01006f7 <kbd_proc_data+0x7e>
f01006f4:	8a 45 f3             	mov    -0xd(%ebp),%al
f01006f7:	88 45 f3             	mov    %al,-0xd(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
f01006fa:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01006fe:	8a 80 20 b0 11 f0    	mov    -0xfee4fe0(%eax),%al
f0100704:	83 c8 40             	or     $0x40,%eax
f0100707:	0f b6 c0             	movzbl %al,%eax
f010070a:	f7 d0                	not    %eax
f010070c:	89 c2                	mov    %eax,%edx
f010070e:	a1 28 df 14 f0       	mov    0xf014df28,%eax
f0100713:	21 d0                	and    %edx,%eax
f0100715:	a3 28 df 14 f0       	mov    %eax,0xf014df28
		return 0;
f010071a:	b8 00 00 00 00       	mov    $0x0,%eax
f010071f:	e9 d6 00 00 00       	jmp    f01007fa <kbd_proc_data+0x181>
	} else if (shift & E0ESC) {
f0100724:	a1 28 df 14 f0       	mov    0xf014df28,%eax
f0100729:	83 e0 40             	and    $0x40,%eax
f010072c:	85 c0                	test   %eax,%eax
f010072e:	74 11                	je     f0100741 <kbd_proc_data+0xc8>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100730:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
		shift &= ~E0ESC;
f0100734:	a1 28 df 14 f0       	mov    0xf014df28,%eax
f0100739:	83 e0 bf             	and    $0xffffffbf,%eax
f010073c:	a3 28 df 14 f0       	mov    %eax,0xf014df28
	}

	shift |= shiftcode[data];
f0100741:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100745:	8a 80 20 b0 11 f0    	mov    -0xfee4fe0(%eax),%al
f010074b:	0f b6 d0             	movzbl %al,%edx
f010074e:	a1 28 df 14 f0       	mov    0xf014df28,%eax
f0100753:	09 d0                	or     %edx,%eax
f0100755:	a3 28 df 14 f0       	mov    %eax,0xf014df28
	shift ^= togglecode[data];
f010075a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f010075e:	8a 80 20 b1 11 f0    	mov    -0xfee4ee0(%eax),%al
f0100764:	0f b6 d0             	movzbl %al,%edx
f0100767:	a1 28 df 14 f0       	mov    0xf014df28,%eax
f010076c:	31 d0                	xor    %edx,%eax
f010076e:	a3 28 df 14 f0       	mov    %eax,0xf014df28

	c = charcode[shift & (CTL | SHIFT)][data];
f0100773:	a1 28 df 14 f0       	mov    0xf014df28,%eax
f0100778:	83 e0 03             	and    $0x3,%eax
f010077b:	8b 14 85 20 b5 11 f0 	mov    -0xfee4ae0(,%eax,4),%edx
f0100782:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100786:	01 d0                	add    %edx,%eax
f0100788:	8a 00                	mov    (%eax),%al
f010078a:	0f b6 c0             	movzbl %al,%eax
f010078d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (shift & CAPSLOCK) {
f0100790:	a1 28 df 14 f0       	mov    0xf014df28,%eax
f0100795:	83 e0 08             	and    $0x8,%eax
f0100798:	85 c0                	test   %eax,%eax
f010079a:	74 22                	je     f01007be <kbd_proc_data+0x145>
		if ('a' <= c && c <= 'z')
f010079c:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
f01007a0:	7e 0c                	jle    f01007ae <kbd_proc_data+0x135>
f01007a2:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
f01007a6:	7f 06                	jg     f01007ae <kbd_proc_data+0x135>
			c += 'A' - 'a';
f01007a8:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
f01007ac:	eb 10                	jmp    f01007be <kbd_proc_data+0x145>
		else if ('A' <= c && c <= 'Z')
f01007ae:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
f01007b2:	7e 0a                	jle    f01007be <kbd_proc_data+0x145>
f01007b4:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
f01007b8:	7f 04                	jg     f01007be <kbd_proc_data+0x145>
			c += 'a' - 'A';
f01007ba:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01007be:	a1 28 df 14 f0       	mov    0xf014df28,%eax
f01007c3:	f7 d0                	not    %eax
f01007c5:	83 e0 06             	and    $0x6,%eax
f01007c8:	85 c0                	test   %eax,%eax
f01007ca:	75 2b                	jne    f01007f7 <kbd_proc_data+0x17e>
f01007cc:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
f01007d3:	75 22                	jne    f01007f7 <kbd_proc_data+0x17e>
		cprintf("Rebooting!\n");
f01007d5:	83 ec 0c             	sub    $0xc,%esp
f01007d8:	68 a6 4e 10 f0       	push   $0xf0104ea6
f01007dd:	e8 71 28 00 00       	call   f0103053 <cprintf>
f01007e2:	83 c4 10             	add    $0x10,%esp
f01007e5:	c7 45 e8 92 00 00 00 	movl   $0x92,-0x18(%ebp)
f01007ec:	c6 45 e1 03          	movb   $0x3,-0x1f(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01007f0:	8a 45 e1             	mov    -0x1f(%ebp),%al
f01007f3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01007f6:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01007f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01007fa:	c9                   	leave  
f01007fb:	c3                   	ret    

f01007fc <kbd_intr>:

void
kbd_intr(void)
{
f01007fc:	55                   	push   %ebp
f01007fd:	89 e5                	mov    %esp,%ebp
f01007ff:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100802:	83 ec 0c             	sub    $0xc,%esp
f0100805:	68 79 06 10 f0       	push   $0xf0100679
f010080a:	e8 0c 00 00 00       	call   f010081b <cons_intr>
f010080f:	83 c4 10             	add    $0x10,%esp
}
f0100812:	90                   	nop
f0100813:	c9                   	leave  
f0100814:	c3                   	ret    

f0100815 <kbd_init>:

void
kbd_init(void)
{
f0100815:	55                   	push   %ebp
f0100816:	89 e5                	mov    %esp,%ebp
}
f0100818:	90                   	nop
f0100819:	5d                   	pop    %ebp
f010081a:	c3                   	ret    

f010081b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
f010081b:	55                   	push   %ebp
f010081c:	89 e5                	mov    %esp,%ebp
f010081e:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
f0100821:	eb 35                	jmp    f0100858 <cons_intr+0x3d>
		if (c == 0)
f0100823:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100827:	75 02                	jne    f010082b <cons_intr+0x10>
			continue;
f0100829:	eb 2d                	jmp    f0100858 <cons_intr+0x3d>
		cons.buf[cons.wpos++] = c;
f010082b:	a1 24 df 14 f0       	mov    0xf014df24,%eax
f0100830:	8d 50 01             	lea    0x1(%eax),%edx
f0100833:	89 15 24 df 14 f0    	mov    %edx,0xf014df24
f0100839:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010083c:	88 90 20 dd 14 f0    	mov    %dl,-0xfeb22e0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f0100842:	a1 24 df 14 f0       	mov    0xf014df24,%eax
f0100847:	3d 00 02 00 00       	cmp    $0x200,%eax
f010084c:	75 0a                	jne    f0100858 <cons_intr+0x3d>
			cons.wpos = 0;
f010084e:	c7 05 24 df 14 f0 00 	movl   $0x0,0xf014df24
f0100855:	00 00 00 
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100858:	8b 45 08             	mov    0x8(%ebp),%eax
f010085b:	ff d0                	call   *%eax
f010085d:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100860:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
f0100864:	75 bd                	jne    f0100823 <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100866:	90                   	nop
f0100867:	c9                   	leave  
f0100868:	c3                   	ret    

f0100869 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100869:	55                   	push   %ebp
f010086a:	89 e5                	mov    %esp,%ebp
f010086c:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010086f:	e8 a7 f9 ff ff       	call   f010021b <serial_intr>
	kbd_intr();
f0100874:	e8 83 ff ff ff       	call   f01007fc <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100879:	8b 15 20 df 14 f0    	mov    0xf014df20,%edx
f010087f:	a1 24 df 14 f0       	mov    0xf014df24,%eax
f0100884:	39 c2                	cmp    %eax,%edx
f0100886:	74 35                	je     f01008bd <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
f0100888:	a1 20 df 14 f0       	mov    0xf014df20,%eax
f010088d:	8d 50 01             	lea    0x1(%eax),%edx
f0100890:	89 15 20 df 14 f0    	mov    %edx,0xf014df20
f0100896:	8a 80 20 dd 14 f0    	mov    -0xfeb22e0(%eax),%al
f010089c:	0f b6 c0             	movzbl %al,%eax
f010089f:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if (cons.rpos == CONSBUFSIZE)
f01008a2:	a1 20 df 14 f0       	mov    0xf014df20,%eax
f01008a7:	3d 00 02 00 00       	cmp    $0x200,%eax
f01008ac:	75 0a                	jne    f01008b8 <cons_getc+0x4f>
			cons.rpos = 0;
f01008ae:	c7 05 20 df 14 f0 00 	movl   $0x0,0xf014df20
f01008b5:	00 00 00 
		return c;
f01008b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008bb:	eb 05                	jmp    f01008c2 <cons_getc+0x59>
	}
	return 0;
f01008bd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01008c2:	c9                   	leave  
f01008c3:	c3                   	ret    

f01008c4 <cons_putc>:

// output a character to the console
void
cons_putc(int c)
{
f01008c4:	55                   	push   %ebp
f01008c5:	89 e5                	mov    %esp,%ebp
f01008c7:	83 ec 08             	sub    $0x8,%esp
	lpt_putc(c);
f01008ca:	ff 75 08             	pushl  0x8(%ebp)
f01008cd:	e8 7b fa ff ff       	call   f010034d <lpt_putc>
f01008d2:	83 c4 04             	add    $0x4,%esp
	cga_putc(c);
f01008d5:	83 ec 0c             	sub    $0xc,%esp
f01008d8:	ff 75 08             	pushl  0x8(%ebp)
f01008db:	e8 a7 fb ff ff       	call   f0100487 <cga_putc>
f01008e0:	83 c4 10             	add    $0x10,%esp
}
f01008e3:	90                   	nop
f01008e4:	c9                   	leave  
f01008e5:	c3                   	ret    

f01008e6 <console_initialize>:

// initialize the console devices
void
console_initialize(void)
{
f01008e6:	55                   	push   %ebp
f01008e7:	89 e5                	mov    %esp,%ebp
f01008e9:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f01008ec:	e8 d1 fa ff ff       	call   f01003c2 <cga_init>
	kbd_init();
f01008f1:	e8 1f ff ff ff       	call   f0100815 <kbd_init>
	serial_init();
f01008f6:	e8 42 f9 ff ff       	call   f010023d <serial_init>

	if (!serial_exists)
f01008fb:	a1 00 dd 14 f0       	mov    0xf014dd00,%eax
f0100900:	85 c0                	test   %eax,%eax
f0100902:	75 10                	jne    f0100914 <console_initialize+0x2e>
		cprintf("Serial port does not exist!\n");
f0100904:	83 ec 0c             	sub    $0xc,%esp
f0100907:	68 b2 4e 10 f0       	push   $0xf0104eb2
f010090c:	e8 42 27 00 00       	call   f0103053 <cprintf>
f0100911:	83 c4 10             	add    $0x10,%esp
}
f0100914:	90                   	nop
f0100915:	c9                   	leave  
f0100916:	c3                   	ret    

f0100917 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100917:	55                   	push   %ebp
f0100918:	89 e5                	mov    %esp,%ebp
f010091a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010091d:	83 ec 0c             	sub    $0xc,%esp
f0100920:	ff 75 08             	pushl  0x8(%ebp)
f0100923:	e8 9c ff ff ff       	call   f01008c4 <cons_putc>
f0100928:	83 c4 10             	add    $0x10,%esp
}
f010092b:	90                   	nop
f010092c:	c9                   	leave  
f010092d:	c3                   	ret    

f010092e <getchar>:

int
getchar(void)
{
f010092e:	55                   	push   %ebp
f010092f:	89 e5                	mov    %esp,%ebp
f0100931:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100934:	e8 30 ff ff ff       	call   f0100869 <cons_getc>
f0100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010093c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100940:	74 f2                	je     f0100934 <getchar+0x6>
		/* do nothing */;
	return c;
f0100942:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100945:	c9                   	leave  
f0100946:	c3                   	ret    

f0100947 <iscons>:

int
iscons(int fdnum)
{
f0100947:	55                   	push   %ebp
f0100948:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
f010094a:	b8 01 00 00 00       	mov    $0x1,%eax
}
f010094f:	5d                   	pop    %ebp
f0100950:	c3                   	ret    

f0100951 <run_command_prompt>:
#define NUM_OF_COMMANDS (sizeof(commands)/sizeof(commands[0]))


//invoke the command prompt
void run_command_prompt()
{
f0100951:	55                   	push   %ebp
f0100952:	89 e5                	mov    %esp,%ebp
f0100954:	81 ec 08 04 00 00    	sub    $0x408,%esp
	char command_line[1024];

	while (1==1)
	{
		//get command line
		readline("FOS> ", command_line);
f010095a:	83 ec 08             	sub    $0x8,%esp
f010095d:	8d 85 f8 fb ff ff    	lea    -0x408(%ebp),%eax
f0100963:	50                   	push   %eax
f0100964:	68 2c 53 10 f0       	push   $0xf010532c
f0100969:	e8 db 3a 00 00       	call   f0104449 <readline>
f010096e:	83 c4 10             	add    $0x10,%esp

		//parse and execute the command
		if (command_line != NULL)
			if (execute_command(command_line) < 0)
f0100971:	83 ec 0c             	sub    $0xc,%esp
f0100974:	8d 85 f8 fb ff ff    	lea    -0x408(%ebp),%eax
f010097a:	50                   	push   %eax
f010097b:	e8 0d 00 00 00       	call   f010098d <execute_command>
f0100980:	83 c4 10             	add    $0x10,%esp
f0100983:	85 c0                	test   %eax,%eax
f0100985:	78 02                	js     f0100989 <run_command_prompt+0x38>
				break;
	}
f0100987:	eb d1                	jmp    f010095a <run_command_prompt+0x9>
		readline("FOS> ", command_line);

		//parse and execute the command
		if (command_line != NULL)
			if (execute_command(command_line) < 0)
				break;
f0100989:	90                   	nop
	}
}
f010098a:	90                   	nop
f010098b:	c9                   	leave  
f010098c:	c3                   	ret    

f010098d <execute_command>:
#define WHITESPACE "\t\r\n "

//Function to parse any command and execute it
//(simply by calling its corresponding function)
int execute_command(char *command_string)
{
f010098d:	55                   	push   %ebp
f010098e:	89 e5                	mov    %esp,%ebp
f0100990:	83 ec 58             	sub    $0x58,%esp
	int number_of_arguments;
	//allocate array of char * of size MAX_ARGUMENTS = 16 found in string.h
	char *arguments[MAX_ARGUMENTS];


	strsplit(command_string, WHITESPACE, arguments, &number_of_arguments) ;
f0100993:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0100996:	50                   	push   %eax
f0100997:	8d 45 a8             	lea    -0x58(%ebp),%eax
f010099a:	50                   	push   %eax
f010099b:	68 32 53 10 f0       	push   $0xf0105332
f01009a0:	ff 75 08             	pushl  0x8(%ebp)
f01009a3:	e8 45 40 00 00       	call   f01049ed <strsplit>
f01009a8:	83 c4 10             	add    $0x10,%esp
	if (number_of_arguments == 0)
f01009ab:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009ae:	85 c0                	test   %eax,%eax
f01009b0:	75 0a                	jne    f01009bc <execute_command+0x2f>
		return 0;
f01009b2:	b8 00 00 00 00       	mov    $0x0,%eax
f01009b7:	e9 95 00 00 00       	jmp    f0100a51 <execute_command+0xc4>

	// Lookup in the commands array and execute the command
	int command_found = 0;
f01009bc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int i ;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f01009c3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f01009ca:	eb 33                	jmp    f01009ff <execute_command+0x72>
	{
		if (strcmp(arguments[0], commands[i].name) == 0)
f01009cc:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01009cf:	89 d0                	mov    %edx,%eax
f01009d1:	01 c0                	add    %eax,%eax
f01009d3:	01 d0                	add    %edx,%eax
f01009d5:	c1 e0 02             	shl    $0x2,%eax
f01009d8:	05 40 b5 11 f0       	add    $0xf011b540,%eax
f01009dd:	8b 10                	mov    (%eax),%edx
f01009df:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009e2:	83 ec 08             	sub    $0x8,%esp
f01009e5:	52                   	push   %edx
f01009e6:	50                   	push   %eax
f01009e7:	e8 67 3c 00 00       	call   f0104653 <strcmp>
f01009ec:	83 c4 10             	add    $0x10,%esp
f01009ef:	85 c0                	test   %eax,%eax
f01009f1:	75 09                	jne    f01009fc <execute_command+0x6f>
		{
			command_found = 1;
f01009f3:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
			break;
f01009fa:	eb 0b                	jmp    f0100a07 <execute_command+0x7a>
		return 0;

	// Lookup in the commands array and execute the command
	int command_found = 0;
	int i ;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f01009fc:	ff 45 f0             	incl   -0x10(%ebp)
f01009ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a02:	83 f8 12             	cmp    $0x12,%eax
f0100a05:	76 c5                	jbe    f01009cc <execute_command+0x3f>
			command_found = 1;
			break;
		}
	}

	if(command_found)
f0100a07:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100a0b:	74 2b                	je     f0100a38 <execute_command+0xab>
	{
		int return_value;
		return_value = commands[i].function_to_execute(number_of_arguments, arguments);
f0100a0d:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100a10:	89 d0                	mov    %edx,%eax
f0100a12:	01 c0                	add    %eax,%eax
f0100a14:	01 d0                	add    %edx,%eax
f0100a16:	c1 e0 02             	shl    $0x2,%eax
f0100a19:	05 48 b5 11 f0       	add    $0xf011b548,%eax
f0100a1e:	8b 00                	mov    (%eax),%eax
f0100a20:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a23:	83 ec 08             	sub    $0x8,%esp
f0100a26:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100a29:	51                   	push   %ecx
f0100a2a:	52                   	push   %edx
f0100a2b:	ff d0                	call   *%eax
f0100a2d:	83 c4 10             	add    $0x10,%esp
f0100a30:	89 45 ec             	mov    %eax,-0x14(%ebp)
		return return_value;
f0100a33:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a36:	eb 19                	jmp    f0100a51 <execute_command+0xc4>
	}
	else
	{
		//if not found, then it's unknown command
		cprintf("Unknown command '%s'\n", arguments[0]);
f0100a38:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a3b:	83 ec 08             	sub    $0x8,%esp
f0100a3e:	50                   	push   %eax
f0100a3f:	68 37 53 10 f0       	push   $0xf0105337
f0100a44:	e8 0a 26 00 00       	call   f0103053 <cprintf>
f0100a49:	83 c4 10             	add    $0x10,%esp
		return 0;
f0100a4c:	b8 00 00 00 00       	mov    $0x0,%eax
	}
}
f0100a51:	c9                   	leave  
f0100a52:	c3                   	ret    

f0100a53 <command_help>:

/***** Implementations of basic kernel command prompt commands *****/

//print name and description of each command
int command_help(int number_of_arguments, char **arguments)
{
f0100a53:	55                   	push   %ebp
f0100a54:	89 e5                	mov    %esp,%ebp
f0100a56:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f0100a59:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0100a60:	eb 3b                	jmp    f0100a9d <command_help+0x4a>
		cprintf("%s - %s\n", commands[i].name, commands[i].description);
f0100a62:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100a65:	89 d0                	mov    %edx,%eax
f0100a67:	01 c0                	add    %eax,%eax
f0100a69:	01 d0                	add    %edx,%eax
f0100a6b:	c1 e0 02             	shl    $0x2,%eax
f0100a6e:	05 44 b5 11 f0       	add    $0xf011b544,%eax
f0100a73:	8b 10                	mov    (%eax),%edx
f0100a75:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0100a78:	89 c8                	mov    %ecx,%eax
f0100a7a:	01 c0                	add    %eax,%eax
f0100a7c:	01 c8                	add    %ecx,%eax
f0100a7e:	c1 e0 02             	shl    $0x2,%eax
f0100a81:	05 40 b5 11 f0       	add    $0xf011b540,%eax
f0100a86:	8b 00                	mov    (%eax),%eax
f0100a88:	83 ec 04             	sub    $0x4,%esp
f0100a8b:	52                   	push   %edx
f0100a8c:	50                   	push   %eax
f0100a8d:	68 4d 53 10 f0       	push   $0xf010534d
f0100a92:	e8 bc 25 00 00       	call   f0103053 <cprintf>
f0100a97:	83 c4 10             	add    $0x10,%esp

//print name and description of each command
int command_help(int number_of_arguments, char **arguments)
{
	int i;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f0100a9a:	ff 45 f4             	incl   -0xc(%ebp)
f0100a9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100aa0:	83 f8 12             	cmp    $0x12,%eax
f0100aa3:	76 bd                	jbe    f0100a62 <command_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].description);

	cprintf("-------------------\n");
f0100aa5:	83 ec 0c             	sub    $0xc,%esp
f0100aa8:	68 56 53 10 f0       	push   $0xf0105356
f0100aad:	e8 a1 25 00 00       	call   f0103053 <cprintf>
f0100ab2:	83 c4 10             	add    $0x10,%esp

	return 0;
f0100ab5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100aba:	c9                   	leave  
f0100abb:	c3                   	ret    

f0100abc <command_kernel_info>:

//print information about kernel addresses and kernel size
int command_kernel_info(int number_of_arguments, char **arguments )
{
f0100abc:	55                   	push   %ebp
f0100abd:	89 e5                	mov    %esp,%ebp
f0100abf:	83 ec 08             	sub    $0x8,%esp
	extern char start_of_kernel[], end_of_kernel_code_section[], start_of_uninitialized_data_section[], end_of_kernel[];

	cprintf("Special kernel symbols:\n");
f0100ac2:	83 ec 0c             	sub    $0xc,%esp
f0100ac5:	68 6b 53 10 f0       	push   $0xf010536b
f0100aca:	e8 84 25 00 00       	call   f0103053 <cprintf>
f0100acf:	83 c4 10             	add    $0x10,%esp
	cprintf("  Start Address of the kernel 			%08x (virt)  %08x (phys)\n", start_of_kernel, start_of_kernel - KERNEL_BASE);
f0100ad2:	b8 0c 00 10 00       	mov    $0x10000c,%eax
f0100ad7:	83 ec 04             	sub    $0x4,%esp
f0100ada:	50                   	push   %eax
f0100adb:	68 0c 00 10 f0       	push   $0xf010000c
f0100ae0:	68 84 53 10 f0       	push   $0xf0105384
f0100ae5:	e8 69 25 00 00       	call   f0103053 <cprintf>
f0100aea:	83 c4 10             	add    $0x10,%esp
	cprintf("  End address of kernel code  			%08x (virt)  %08x (phys)\n", end_of_kernel_code_section, end_of_kernel_code_section - KERNEL_BASE);
f0100aed:	b8 25 4d 10 00       	mov    $0x104d25,%eax
f0100af2:	83 ec 04             	sub    $0x4,%esp
f0100af5:	50                   	push   %eax
f0100af6:	68 25 4d 10 f0       	push   $0xf0104d25
f0100afb:	68 c0 53 10 f0       	push   $0xf01053c0
f0100b00:	e8 4e 25 00 00       	call   f0103053 <cprintf>
f0100b05:	83 c4 10             	add    $0x10,%esp
	cprintf("  Start addr. of uninitialized data section 	%08x (virt)  %08x (phys)\n", start_of_uninitialized_data_section, start_of_uninitialized_data_section - KERNEL_BASE);
f0100b08:	b8 d2 dc 14 00       	mov    $0x14dcd2,%eax
f0100b0d:	83 ec 04             	sub    $0x4,%esp
f0100b10:	50                   	push   %eax
f0100b11:	68 d2 dc 14 f0       	push   $0xf014dcd2
f0100b16:	68 fc 53 10 f0       	push   $0xf01053fc
f0100b1b:	e8 33 25 00 00       	call   f0103053 <cprintf>
f0100b20:	83 c4 10             	add    $0x10,%esp
	cprintf("  End address of the kernel   			%08x (virt)  %08x (phys)\n", end_of_kernel, end_of_kernel - KERNEL_BASE);
f0100b23:	b8 cc e7 14 00       	mov    $0x14e7cc,%eax
f0100b28:	83 ec 04             	sub    $0x4,%esp
f0100b2b:	50                   	push   %eax
f0100b2c:	68 cc e7 14 f0       	push   $0xf014e7cc
f0100b31:	68 44 54 10 f0       	push   $0xf0105444
f0100b36:	e8 18 25 00 00       	call   f0103053 <cprintf>
f0100b3b:	83 c4 10             	add    $0x10,%esp
	cprintf("Kernel executable memory footprint: %d KB\n",
			(end_of_kernel-start_of_kernel+1023)/1024);
f0100b3e:	b8 cc e7 14 f0       	mov    $0xf014e7cc,%eax
f0100b43:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100b49:	b8 0c 00 10 f0       	mov    $0xf010000c,%eax
f0100b4e:	29 c2                	sub    %eax,%edx
f0100b50:	89 d0                	mov    %edx,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  Start Address of the kernel 			%08x (virt)  %08x (phys)\n", start_of_kernel, start_of_kernel - KERNEL_BASE);
	cprintf("  End address of kernel code  			%08x (virt)  %08x (phys)\n", end_of_kernel_code_section, end_of_kernel_code_section - KERNEL_BASE);
	cprintf("  Start addr. of uninitialized data section 	%08x (virt)  %08x (phys)\n", start_of_uninitialized_data_section, start_of_uninitialized_data_section - KERNEL_BASE);
	cprintf("  End address of the kernel   			%08x (virt)  %08x (phys)\n", end_of_kernel, end_of_kernel - KERNEL_BASE);
	cprintf("Kernel executable memory footprint: %d KB\n",
f0100b52:	85 c0                	test   %eax,%eax
f0100b54:	79 05                	jns    f0100b5b <command_kernel_info+0x9f>
f0100b56:	05 ff 03 00 00       	add    $0x3ff,%eax
f0100b5b:	c1 f8 0a             	sar    $0xa,%eax
f0100b5e:	83 ec 08             	sub    $0x8,%esp
f0100b61:	50                   	push   %eax
f0100b62:	68 80 54 10 f0       	push   $0xf0105480
f0100b67:	e8 e7 24 00 00       	call   f0103053 <cprintf>
f0100b6c:	83 c4 10             	add    $0x10,%esp
			(end_of_kernel-start_of_kernel+1023)/1024);
	return 0;
f0100b6f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100b74:	c9                   	leave  
f0100b75:	c3                   	ret    

f0100b76 <command_readmem>:


int command_readmem(int number_of_arguments, char **arguments)
{
f0100b76:	55                   	push   %ebp
f0100b77:	89 e5                	mov    %esp,%ebp
f0100b79:	83 ec 18             	sub    $0x18,%esp
	unsigned int address = strtol(arguments[1], NULL, 16);
f0100b7c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100b7f:	83 c0 04             	add    $0x4,%eax
f0100b82:	8b 00                	mov    (%eax),%eax
f0100b84:	83 ec 04             	sub    $0x4,%esp
f0100b87:	6a 10                	push   $0x10
f0100b89:	6a 00                	push   $0x0
f0100b8b:	50                   	push   %eax
f0100b8c:	e8 16 3d 00 00       	call   f01048a7 <strtol>
f0100b91:	83 c4 10             	add    $0x10,%esp
f0100b94:	89 45 f4             	mov    %eax,-0xc(%ebp)
	unsigned char *ptr = (unsigned char *)(address ) ;
f0100b97:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b9a:	89 45 f0             	mov    %eax,-0x10(%ebp)

	cprintf("value at address %x = %c\n", ptr, *ptr);
f0100b9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ba0:	8a 00                	mov    (%eax),%al
f0100ba2:	0f b6 c0             	movzbl %al,%eax
f0100ba5:	83 ec 04             	sub    $0x4,%esp
f0100ba8:	50                   	push   %eax
f0100ba9:	ff 75 f0             	pushl  -0x10(%ebp)
f0100bac:	68 ab 54 10 f0       	push   $0xf01054ab
f0100bb1:	e8 9d 24 00 00       	call   f0103053 <cprintf>
f0100bb6:	83 c4 10             	add    $0x10,%esp

	return 0;
f0100bb9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bbe:	c9                   	leave  
f0100bbf:	c3                   	ret    

f0100bc0 <command_writemem>:

int command_writemem(int number_of_arguments, char **arguments)
{
f0100bc0:	55                   	push   %ebp
f0100bc1:	89 e5                	mov    %esp,%ebp
f0100bc3:	83 ec 18             	sub    $0x18,%esp
	unsigned int address = strtol(arguments[1], NULL, 16);
f0100bc6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bc9:	83 c0 04             	add    $0x4,%eax
f0100bcc:	8b 00                	mov    (%eax),%eax
f0100bce:	83 ec 04             	sub    $0x4,%esp
f0100bd1:	6a 10                	push   $0x10
f0100bd3:	6a 00                	push   $0x0
f0100bd5:	50                   	push   %eax
f0100bd6:	e8 cc 3c 00 00       	call   f01048a7 <strtol>
f0100bdb:	83 c4 10             	add    $0x10,%esp
f0100bde:	89 45 f4             	mov    %eax,-0xc(%ebp)
	unsigned char *ptr = (unsigned char *)(address) ;
f0100be1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100be4:	89 45 f0             	mov    %eax,-0x10(%ebp)

	*ptr = arguments[2][0];
f0100be7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bea:	83 c0 08             	add    $0x8,%eax
f0100bed:	8b 00                	mov    (%eax),%eax
f0100bef:	8a 00                	mov    (%eax),%al
f0100bf1:	88 c2                	mov    %al,%dl
f0100bf3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100bf6:	88 10                	mov    %dl,(%eax)

	return 0;
f0100bf8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bfd:	c9                   	leave  
f0100bfe:	c3                   	ret    

f0100bff <command_meminfo>:

int command_meminfo(int number_of_arguments, char **arguments)
{
f0100bff:	55                   	push   %ebp
f0100c00:	89 e5                	mov    %esp,%ebp
f0100c02:	83 ec 08             	sub    $0x8,%esp
	cprintf("Free frames = %d\n", calculate_free_frames());
f0100c05:	e8 59 1b 00 00       	call   f0102763 <calculate_free_frames>
f0100c0a:	83 ec 08             	sub    $0x8,%esp
f0100c0d:	50                   	push   %eax
f0100c0e:	68 c5 54 10 f0       	push   $0xf01054c5
f0100c13:	e8 3b 24 00 00       	call   f0103053 <cprintf>
f0100c18:	83 c4 10             	add    $0x10,%esp
	return 0;
f0100c1b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c20:	c9                   	leave  
f0100c21:	c3                   	ret    

f0100c22 <command_kernel_base_info>:

//===========================================================================
//Lab3.Examples
//=============
int command_kernel_base_info(int number_of_arguments, char **arguments)
{
f0100c22:	55                   	push   %ebp
f0100c23:	89 e5                	mov    %esp,%ebp
f0100c25:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB3 Example: fill this function. corresponding command name is "ikb"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100c28:	83 ec 04             	sub    $0x4,%esp
f0100c2b:	68 d8 54 10 f0       	push   $0xf01054d8
f0100c30:	68 ff 00 00 00       	push   $0xff
f0100c35:	68 f9 54 10 f0       	push   $0xf01054f9
f0100c3a:	e8 ef f4 ff ff       	call   f010012e <_panic>

f0100c3f <command_del_kernel_base>:
	return 0;
}


int command_del_kernel_base(int number_of_arguments, char **arguments)
{
f0100c3f:	55                   	push   %ebp
f0100c40:	89 e5                	mov    %esp,%ebp
f0100c42:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB3 Example: fill this function. corresponding command name is "dkb"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100c45:	83 ec 04             	sub    $0x4,%esp
f0100c48:	68 d8 54 10 f0       	push   $0xf01054d8
f0100c4d:	68 09 01 00 00       	push   $0x109
f0100c52:	68 f9 54 10 f0       	push   $0xf01054f9
f0100c57:	e8 d2 f4 ff ff       	call   f010012e <_panic>

f0100c5c <command_share_page>:

	return 0;
}

int command_share_page(int number_of_arguments, char **arguments)
{
f0100c5c:	55                   	push   %ebp
f0100c5d:	89 e5                	mov    %esp,%ebp
f0100c5f:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB3 Example: fill this function. corresponding command name is "shr"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100c62:	83 ec 04             	sub    $0x4,%esp
f0100c65:	68 d8 54 10 f0       	push   $0xf01054d8
f0100c6a:	68 12 01 00 00       	push   $0x112
f0100c6f:	68 f9 54 10 f0       	push   $0xf01054f9
f0100c74:	e8 b5 f4 ff ff       	call   f010012e <_panic>

f0100c79 <command_show_mapping>:

//===========================================================================
//Lab4.Hands.On
//=============
int command_show_mapping(int number_of_arguments, char **arguments)
{
f0100c79:	55                   	push   %ebp
f0100c7a:	89 e5                	mov    %esp,%ebp
f0100c7c:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sm"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100c7f:	83 ec 04             	sub    $0x4,%esp
f0100c82:	68 d8 54 10 f0       	push   $0xf01054d8
f0100c87:	68 1e 01 00 00       	push   $0x11e
f0100c8c:	68 f9 54 10 f0       	push   $0xf01054f9
f0100c91:	e8 98 f4 ff ff       	call   f010012e <_panic>

f0100c96 <command_set_permission>:

	return 0 ;
}

int command_set_permission(int number_of_arguments, char **arguments)
{
f0100c96:	55                   	push   %ebp
f0100c97:	89 e5                	mov    %esp,%ebp
f0100c99:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sp"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100c9c:	83 ec 04             	sub    $0x4,%esp
f0100c9f:	68 d8 54 10 f0       	push   $0xf01054d8
f0100ca4:	68 27 01 00 00       	push   $0x127
f0100ca9:	68 f9 54 10 f0       	push   $0xf01054f9
f0100cae:	e8 7b f4 ff ff       	call   f010012e <_panic>

f0100cb3 <command_share_range>:

	return 0 ;
}

int command_share_range(int number_of_arguments, char **arguments)
{
f0100cb3:	55                   	push   %ebp
f0100cb4:	89 e5                	mov    %esp,%ebp
f0100cb6:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sr"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100cb9:	83 ec 04             	sub    $0x4,%esp
f0100cbc:	68 d8 54 10 f0       	push   $0xf01054d8
f0100cc1:	68 30 01 00 00       	push   $0x130
f0100cc6:	68 f9 54 10 f0       	push   $0xf01054f9
f0100ccb:	e8 5e f4 ff ff       	call   f010012e <_panic>

f0100cd0 <command_nr>:
//===========================================================================
//Lab5.Examples
//==============
//[1] Number of references on the given physical address
int command_nr(int number_of_arguments, char **arguments)
{
f0100cd0:	55                   	push   %ebp
f0100cd1:	89 e5                	mov    %esp,%ebp
f0100cd3:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "nr"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100cd6:	83 ec 04             	sub    $0x4,%esp
f0100cd9:	68 d8 54 10 f0       	push   $0xf01054d8
f0100cde:	68 3d 01 00 00       	push   $0x13d
f0100ce3:	68 f9 54 10 f0       	push   $0xf01054f9
f0100ce8:	e8 41 f4 ff ff       	call   f010012e <_panic>

f0100ced <command_ap>:
	return 0;
}

//[2] Allocate Page: If the given user virtual address is mapped, do nothing. Else, allocate a single frame and map it to a given virtual address in the user space
int command_ap(int number_of_arguments, char **arguments)
{
f0100ced:	55                   	push   %ebp
f0100cee:	89 e5                	mov    %esp,%ebp
f0100cf0:	83 ec 18             	sub    $0x18,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "ap"
	//Comment the following line
	//panic("Function is not implemented yet!");
	
	uint32 va = strtol(arguments[1], NULL, 16);
f0100cf3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100cf6:	83 c0 04             	add    $0x4,%eax
f0100cf9:	8b 00                	mov    (%eax),%eax
f0100cfb:	83 ec 04             	sub    $0x4,%esp
f0100cfe:	6a 10                	push   $0x10
f0100d00:	6a 00                	push   $0x0
f0100d02:	50                   	push   %eax
f0100d03:	e8 9f 3b 00 00       	call   f01048a7 <strtol>
f0100d08:	83 c4 10             	add    $0x10,%esp
f0100d0b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	struct Frame_Info* ptr_frame_info;
	int ret = allocate_frame(&ptr_frame_info) ;
f0100d0e:	83 ec 0c             	sub    $0xc,%esp
f0100d11:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0100d14:	50                   	push   %eax
f0100d15:	e8 84 16 00 00       	call   f010239e <allocate_frame>
f0100d1a:	83 c4 10             	add    $0x10,%esp
f0100d1d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	map_frame(ptr_page_directory, ptr_frame_info, (void*)va, PERM_USER | PERM_WRITEABLE);
f0100d20:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0100d23:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0100d26:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0100d2b:	6a 06                	push   $0x6
f0100d2d:	51                   	push   %ecx
f0100d2e:	52                   	push   %edx
f0100d2f:	50                   	push   %eax
f0100d30:	e8 76 18 00 00       	call   f01025ab <map_frame>
f0100d35:	83 c4 10             	add    $0x10,%esp

	return 0 ;
f0100d38:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d3d:	c9                   	leave  
f0100d3e:	c3                   	ret    

f0100d3f <command_fp>:

//[3] Free Page: Un-map a single page at the given virtual address in the user space
int command_fp(int number_of_arguments, char **arguments)
{
f0100d3f:	55                   	push   %ebp
f0100d40:	89 e5                	mov    %esp,%ebp
f0100d42:	83 ec 18             	sub    $0x18,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "fp"
	//Comment the following line
	//panic("Function is not implemented yet!");
	
	uint32 va = strtol(arguments[1], NULL, 16);
f0100d45:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d48:	83 c0 04             	add    $0x4,%eax
f0100d4b:	8b 00                	mov    (%eax),%eax
f0100d4d:	83 ec 04             	sub    $0x4,%esp
f0100d50:	6a 10                	push   $0x10
f0100d52:	6a 00                	push   $0x0
f0100d54:	50                   	push   %eax
f0100d55:	e8 4d 3b 00 00       	call   f01048a7 <strtol>
f0100d5a:	83 c4 10             	add    $0x10,%esp
f0100d5d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// Un-map the page at this address
	unmap_frame(ptr_page_directory, (void*)va);
f0100d60:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100d63:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0100d68:	83 ec 08             	sub    $0x8,%esp
f0100d6b:	52                   	push   %edx
f0100d6c:	50                   	push   %eax
f0100d6d:	e8 57 19 00 00       	call   f01026c9 <unmap_frame>
f0100d72:	83 c4 10             	add    $0x10,%esp

	return 0;
f0100d75:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d7a:	c9                   	leave  
f0100d7b:	c3                   	ret    

f0100d7c <command_asp>:
//===========================================================================
//Lab5.Hands-on
//==============
//[1] Allocate Shared Pages
int command_asp(int number_of_arguments, char **arguments)
{
f0100d7c:	55                   	push   %ebp
f0100d7d:	89 e5                	mov    %esp,%ebp
f0100d7f:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Hands-on: fill this function. corresponding command name is "asp"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100d82:	83 ec 04             	sub    $0x4,%esp
f0100d85:	68 d8 54 10 f0       	push   $0xf01054d8
f0100d8a:	68 67 01 00 00       	push   $0x167
f0100d8f:	68 f9 54 10 f0       	push   $0xf01054f9
f0100d94:	e8 95 f3 ff ff       	call   f010012e <_panic>

f0100d99 <command_cfp>:
}


//[2] Count Free Pages in Range
int command_cfp(int number_of_arguments, char **arguments)
{
f0100d99:	55                   	push   %ebp
f0100d9a:	89 e5                	mov    %esp,%ebp
f0100d9c:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Hands-on: fill this function. corresponding command name is "cfp"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100d9f:	83 ec 04             	sub    $0x4,%esp
f0100da2:	68 d8 54 10 f0       	push   $0xf01054d8
f0100da7:	68 72 01 00 00       	push   $0x172
f0100dac:	68 f9 54 10 f0       	push   $0xf01054f9
f0100db1:	e8 78 f3 ff ff       	call   f010012e <_panic>

f0100db6 <command_run>:

//===========================================================================
//Lab6.Examples
//=============
int command_run(int number_of_arguments, char **arguments)
{
f0100db6:	55                   	push   %ebp
f0100db7:	89 e5                	mov    %esp,%ebp
f0100db9:	83 ec 18             	sub    $0x18,%esp
	//[1] Create and initialize a new environment for the program to be run
	struct UserProgramInfo* ptr_program_info = env_create(arguments[1]);
f0100dbc:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100dbf:	83 c0 04             	add    $0x4,%eax
f0100dc2:	8b 00                	mov    (%eax),%eax
f0100dc4:	83 ec 0c             	sub    $0xc,%esp
f0100dc7:	50                   	push   %eax
f0100dc8:	e8 6f 1a 00 00       	call   f010283c <env_create>
f0100dcd:	83 c4 10             	add    $0x10,%esp
f0100dd0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if(ptr_program_info == 0) return 0;
f0100dd3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100dd7:	75 07                	jne    f0100de0 <command_run+0x2a>
f0100dd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dde:	eb 0f                	jmp    f0100def <command_run+0x39>

	//[2] Run the created environment using "env_run" function
	env_run(ptr_program_info->environment);
f0100de0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100de3:	8b 40 0c             	mov    0xc(%eax),%eax
f0100de6:	83 ec 0c             	sub    $0xc,%esp
f0100de9:	50                   	push   %eax
f0100dea:	e8 bc 1a 00 00       	call   f01028ab <env_run>
	return 0;
}
f0100def:	c9                   	leave  
f0100df0:	c3                   	ret    

f0100df1 <command_kill>:

int command_kill(int number_of_arguments, char **arguments)
{
f0100df1:	55                   	push   %ebp
f0100df2:	89 e5                	mov    %esp,%ebp
f0100df4:	83 ec 18             	sub    $0x18,%esp
	//[1] Get the user program info of the program (by searching in the "userPrograms" array
	struct UserProgramInfo* ptr_program_info = get_user_program_info(arguments[1]) ;
f0100df7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100dfa:	83 c0 04             	add    $0x4,%eax
f0100dfd:	8b 00                	mov    (%eax),%eax
f0100dff:	83 ec 0c             	sub    $0xc,%esp
f0100e02:	50                   	push   %eax
f0100e03:	e8 74 1f 00 00       	call   f0102d7c <get_user_program_info>
f0100e08:	83 c4 10             	add    $0x10,%esp
f0100e0b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if(ptr_program_info == 0) return 0;
f0100e0e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100e12:	75 07                	jne    f0100e1b <command_kill+0x2a>
f0100e14:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e19:	eb 21                	jmp    f0100e3c <command_kill+0x4b>

	//[2] Kill its environment using "env_free" function
	env_free(ptr_program_info->environment);
f0100e1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e1e:	8b 40 0c             	mov    0xc(%eax),%eax
f0100e21:	83 ec 0c             	sub    $0xc,%esp
f0100e24:	50                   	push   %eax
f0100e25:	e8 c4 1a 00 00       	call   f01028ee <env_free>
f0100e2a:	83 c4 10             	add    $0x10,%esp
	ptr_program_info->environment = NULL;
f0100e2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e30:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	return 0;
f0100e37:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e3c:	c9                   	leave  
f0100e3d:	c3                   	ret    

f0100e3e <command_ft>:

int command_ft(int number_of_arguments, char **arguments)
{
f0100e3e:	55                   	push   %ebp
f0100e3f:	89 e5                	mov    %esp,%ebp
	//TODO: LAB6 Example: fill this function. corresponding command name is "ft"
	//Comment the following line

	return 0;
f0100e41:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e46:	5d                   	pop    %ebp
f0100e47:	c3                   	ret    

f0100e48 <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f0100e48:	55                   	push   %ebp
f0100e49:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f0100e4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e4e:	8b 15 bc e7 14 f0    	mov    0xf014e7bc,%edx
f0100e54:	29 d0                	sub    %edx,%eax
f0100e56:	c1 f8 02             	sar    $0x2,%eax
f0100e59:	89 c2                	mov    %eax,%edx
f0100e5b:	89 d0                	mov    %edx,%eax
f0100e5d:	c1 e0 02             	shl    $0x2,%eax
f0100e60:	01 d0                	add    %edx,%eax
f0100e62:	c1 e0 02             	shl    $0x2,%eax
f0100e65:	01 d0                	add    %edx,%eax
f0100e67:	c1 e0 02             	shl    $0x2,%eax
f0100e6a:	01 d0                	add    %edx,%eax
f0100e6c:	89 c1                	mov    %eax,%ecx
f0100e6e:	c1 e1 08             	shl    $0x8,%ecx
f0100e71:	01 c8                	add    %ecx,%eax
f0100e73:	89 c1                	mov    %eax,%ecx
f0100e75:	c1 e1 10             	shl    $0x10,%ecx
f0100e78:	01 c8                	add    %ecx,%eax
f0100e7a:	01 c0                	add    %eax,%eax
f0100e7c:	01 d0                	add    %edx,%eax
}
f0100e7e:	5d                   	pop    %ebp
f0100e7f:	c3                   	ret    

f0100e80 <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f0100e80:	55                   	push   %ebp
f0100e81:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f0100e83:	ff 75 08             	pushl  0x8(%ebp)
f0100e86:	e8 bd ff ff ff       	call   f0100e48 <to_frame_number>
f0100e8b:	83 c4 04             	add    $0x4,%esp
f0100e8e:	c1 e0 0c             	shl    $0xc,%eax
}
f0100e91:	c9                   	leave  
f0100e92:	c3                   	ret    

f0100e93 <nvram_read>:
{
	sizeof(gdt) - 1, (unsigned long) gdt
};

int nvram_read(int r)
{	
f0100e93:	55                   	push   %ebp
f0100e94:	89 e5                	mov    %esp,%ebp
f0100e96:	53                   	push   %ebx
f0100e97:	83 ec 04             	sub    $0x4,%esp
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100e9a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e9d:	83 ec 0c             	sub    $0xc,%esp
f0100ea0:	50                   	push   %eax
f0100ea1:	e8 f8 20 00 00       	call   f0102f9e <mc146818_read>
f0100ea6:	83 c4 10             	add    $0x10,%esp
f0100ea9:	89 c3                	mov    %eax,%ebx
f0100eab:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eae:	40                   	inc    %eax
f0100eaf:	83 ec 0c             	sub    $0xc,%esp
f0100eb2:	50                   	push   %eax
f0100eb3:	e8 e6 20 00 00       	call   f0102f9e <mc146818_read>
f0100eb8:	83 c4 10             	add    $0x10,%esp
f0100ebb:	c1 e0 08             	shl    $0x8,%eax
f0100ebe:	09 d8                	or     %ebx,%eax
}
f0100ec0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ec3:	c9                   	leave  
f0100ec4:	c3                   	ret    

f0100ec5 <detect_memory>:
	
void detect_memory()
{
f0100ec5:	55                   	push   %ebp
f0100ec6:	89 e5                	mov    %esp,%ebp
f0100ec8:	83 ec 18             	sub    $0x18,%esp
	// CMOS tells us how many kilobytes there are
	size_of_base_mem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PAGE_SIZE);
f0100ecb:	83 ec 0c             	sub    $0xc,%esp
f0100ece:	6a 15                	push   $0x15
f0100ed0:	e8 be ff ff ff       	call   f0100e93 <nvram_read>
f0100ed5:	83 c4 10             	add    $0x10,%esp
f0100ed8:	c1 e0 0a             	shl    $0xa,%eax
f0100edb:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100ede:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ee1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ee6:	a3 b4 e7 14 f0       	mov    %eax,0xf014e7b4
	size_of_extended_mem = ROUNDDOWN(nvram_read(NVRAM_EXTLO)*1024, PAGE_SIZE);
f0100eeb:	83 ec 0c             	sub    $0xc,%esp
f0100eee:	6a 17                	push   $0x17
f0100ef0:	e8 9e ff ff ff       	call   f0100e93 <nvram_read>
f0100ef5:	83 c4 10             	add    $0x10,%esp
f0100ef8:	c1 e0 0a             	shl    $0xa,%eax
f0100efb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100efe:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f01:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100f06:	a3 ac e7 14 f0       	mov    %eax,0xf014e7ac

	// Calculate the maxmium physical address based on whether
	// or not there is any extended memory.  See comment in ../inc/mmu.h.
	if (size_of_extended_mem)
f0100f0b:	a1 ac e7 14 f0       	mov    0xf014e7ac,%eax
f0100f10:	85 c0                	test   %eax,%eax
f0100f12:	74 11                	je     f0100f25 <detect_memory+0x60>
		maxpa = PHYS_EXTENDED_MEM + size_of_extended_mem;
f0100f14:	a1 ac e7 14 f0       	mov    0xf014e7ac,%eax
f0100f19:	05 00 00 10 00       	add    $0x100000,%eax
f0100f1e:	a3 b0 e7 14 f0       	mov    %eax,0xf014e7b0
f0100f23:	eb 0a                	jmp    f0100f2f <detect_memory+0x6a>
	else
		maxpa = size_of_extended_mem;
f0100f25:	a1 ac e7 14 f0       	mov    0xf014e7ac,%eax
f0100f2a:	a3 b0 e7 14 f0       	mov    %eax,0xf014e7b0

	number_of_frames = maxpa / PAGE_SIZE;
f0100f2f:	a1 b0 e7 14 f0       	mov    0xf014e7b0,%eax
f0100f34:	c1 e8 0c             	shr    $0xc,%eax
f0100f37:	a3 a8 e7 14 f0       	mov    %eax,0xf014e7a8

	cprintf("Physical memory: %dK available, ", (int)(maxpa/1024));
f0100f3c:	a1 b0 e7 14 f0       	mov    0xf014e7b0,%eax
f0100f41:	c1 e8 0a             	shr    $0xa,%eax
f0100f44:	83 ec 08             	sub    $0x8,%esp
f0100f47:	50                   	push   %eax
f0100f48:	68 10 55 10 f0       	push   $0xf0105510
f0100f4d:	e8 01 21 00 00       	call   f0103053 <cprintf>
f0100f52:	83 c4 10             	add    $0x10,%esp
	cprintf("base = %dK, extended = %dK\n", (int)(size_of_base_mem/1024), (int)(size_of_extended_mem/1024));
f0100f55:	a1 ac e7 14 f0       	mov    0xf014e7ac,%eax
f0100f5a:	c1 e8 0a             	shr    $0xa,%eax
f0100f5d:	89 c2                	mov    %eax,%edx
f0100f5f:	a1 b4 e7 14 f0       	mov    0xf014e7b4,%eax
f0100f64:	c1 e8 0a             	shr    $0xa,%eax
f0100f67:	83 ec 04             	sub    $0x4,%esp
f0100f6a:	52                   	push   %edx
f0100f6b:	50                   	push   %eax
f0100f6c:	68 31 55 10 f0       	push   $0xf0105531
f0100f71:	e8 dd 20 00 00       	call   f0103053 <cprintf>
f0100f76:	83 c4 10             	add    $0x10,%esp
}
f0100f79:	90                   	nop
f0100f7a:	c9                   	leave  
f0100f7b:	c3                   	ret    

f0100f7c <check_boot_pgdir>:
// but it is a pretty good check.
//
uint32 check_va2pa(uint32 *ptr_page_directory, uint32 va);

void check_boot_pgdir()
{
f0100f7c:	55                   	push   %ebp
f0100f7d:	89 e5                	mov    %esp,%ebp
f0100f7f:	83 ec 28             	sub    $0x28,%esp
	uint32 i, n;

	// check frames_info array
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
f0100f82:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f0100f89:	8b 15 a8 e7 14 f0    	mov    0xf014e7a8,%edx
f0100f8f:	89 d0                	mov    %edx,%eax
f0100f91:	01 c0                	add    %eax,%eax
f0100f93:	01 d0                	add    %edx,%eax
f0100f95:	c1 e0 02             	shl    $0x2,%eax
f0100f98:	89 c2                	mov    %eax,%edx
f0100f9a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f9d:	01 d0                	add    %edx,%eax
f0100f9f:	48                   	dec    %eax
f0100fa0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100fa3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100fa6:	ba 00 00 00 00       	mov    $0x0,%edx
f0100fab:	f7 75 f0             	divl   -0x10(%ebp)
f0100fae:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100fb1:	29 d0                	sub    %edx,%eax
f0100fb3:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for (i = 0; i < n; i += PAGE_SIZE)
f0100fb6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0100fbd:	eb 71                	jmp    f0101030 <check_boot_pgdir+0xb4>
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);
f0100fbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fc2:	8d 90 00 00 00 ef    	lea    -0x11000000(%eax),%edx
f0100fc8:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0100fcd:	83 ec 08             	sub    $0x8,%esp
f0100fd0:	52                   	push   %edx
f0100fd1:	50                   	push   %eax
f0100fd2:	e8 f4 01 00 00       	call   f01011cb <check_va2pa>
f0100fd7:	83 c4 10             	add    $0x10,%esp
f0100fda:	89 c2                	mov    %eax,%edx
f0100fdc:	a1 bc e7 14 f0       	mov    0xf014e7bc,%eax
f0100fe1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fe4:	81 7d e4 ff ff ff ef 	cmpl   $0xefffffff,-0x1c(%ebp)
f0100feb:	77 14                	ja     f0101001 <check_boot_pgdir+0x85>
f0100fed:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100ff0:	68 50 55 10 f0       	push   $0xf0105550
f0100ff5:	6a 5e                	push   $0x5e
f0100ff7:	68 81 55 10 f0       	push   $0xf0105581
f0100ffc:	e8 2d f1 ff ff       	call   f010012e <_panic>
f0101001:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101004:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f010100a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010100d:	01 c8                	add    %ecx,%eax
f010100f:	39 c2                	cmp    %eax,%edx
f0101011:	74 16                	je     f0101029 <check_boot_pgdir+0xad>
f0101013:	68 90 55 10 f0       	push   $0xf0105590
f0101018:	68 f2 55 10 f0       	push   $0xf01055f2
f010101d:	6a 5e                	push   $0x5e
f010101f:	68 81 55 10 f0       	push   $0xf0105581
f0101024:	e8 05 f1 ff ff       	call   f010012e <_panic>
{
	uint32 i, n;

	// check frames_info array
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
	for (i = 0; i < n; i += PAGE_SIZE)
f0101029:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f0101030:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101033:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0101036:	72 87                	jb     f0100fbf <check_boot_pgdir+0x43>
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);

	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
f0101038:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010103f:	eb 3d                	jmp    f010107e <check_boot_pgdir+0x102>
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);
f0101041:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101044:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f010104a:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f010104f:	83 ec 08             	sub    $0x8,%esp
f0101052:	52                   	push   %edx
f0101053:	50                   	push   %eax
f0101054:	e8 72 01 00 00       	call   f01011cb <check_va2pa>
f0101059:	83 c4 10             	add    $0x10,%esp
f010105c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f010105f:	74 16                	je     f0101077 <check_boot_pgdir+0xfb>
f0101061:	68 08 56 10 f0       	push   $0xf0105608
f0101066:	68 f2 55 10 f0       	push   $0xf01055f2
f010106b:	6a 62                	push   $0x62
f010106d:	68 81 55 10 f0       	push   $0xf0105581
f0101072:	e8 b7 f0 ff ff       	call   f010012e <_panic>
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
	for (i = 0; i < n; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);

	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
f0101077:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f010107e:	81 7d f4 00 00 00 10 	cmpl   $0x10000000,-0xc(%ebp)
f0101085:	75 ba                	jne    f0101041 <check_boot_pgdir+0xc5>
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);

	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
f0101087:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010108e:	eb 6e                	jmp    f01010fe <check_boot_pgdir+0x182>
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);
f0101090:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101093:	8d 90 00 80 bf ef    	lea    -0x10408000(%eax),%edx
f0101099:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f010109e:	83 ec 08             	sub    $0x8,%esp
f01010a1:	52                   	push   %edx
f01010a2:	50                   	push   %eax
f01010a3:	e8 23 01 00 00       	call   f01011cb <check_va2pa>
f01010a8:	83 c4 10             	add    $0x10,%esp
f01010ab:	c7 45 e0 00 30 11 f0 	movl   $0xf0113000,-0x20(%ebp)
f01010b2:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f01010b9:	77 14                	ja     f01010cf <check_boot_pgdir+0x153>
f01010bb:	ff 75 e0             	pushl  -0x20(%ebp)
f01010be:	68 50 55 10 f0       	push   $0xf0105550
f01010c3:	6a 66                	push   $0x66
f01010c5:	68 81 55 10 f0       	push   $0xf0105581
f01010ca:	e8 5f f0 ff ff       	call   f010012e <_panic>
f01010cf:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01010d2:	8d 8a 00 00 00 10    	lea    0x10000000(%edx),%ecx
f01010d8:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01010db:	01 ca                	add    %ecx,%edx
f01010dd:	39 d0                	cmp    %edx,%eax
f01010df:	74 16                	je     f01010f7 <check_boot_pgdir+0x17b>
f01010e1:	68 40 56 10 f0       	push   $0xf0105640
f01010e6:	68 f2 55 10 f0       	push   $0xf01055f2
f01010eb:	6a 66                	push   $0x66
f01010ed:	68 81 55 10 f0       	push   $0xf0105581
f01010f2:	e8 37 f0 ff ff       	call   f010012e <_panic>
	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);

	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
f01010f7:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f01010fe:	81 7d f4 ff 7f 00 00 	cmpl   $0x7fff,-0xc(%ebp)
f0101105:	76 89                	jbe    f0101090 <check_boot_pgdir+0x114>
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f0101107:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010110e:	e9 98 00 00 00       	jmp    f01011ab <check_boot_pgdir+0x22f>
		switch (i) {
f0101113:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101116:	2d bb 03 00 00       	sub    $0x3bb,%eax
f010111b:	83 f8 04             	cmp    $0x4,%eax
f010111e:	77 29                	ja     f0101149 <check_boot_pgdir+0x1cd>
		case PDX(VPT):
		case PDX(UVPT):
		case PDX(KERNEL_STACK_TOP-1):
		case PDX(UENVS):
		case PDX(READ_ONLY_FRAMES_INFO):			
			assert(ptr_page_directory[i]);
f0101120:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101125:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101128:	c1 e2 02             	shl    $0x2,%edx
f010112b:	01 d0                	add    %edx,%eax
f010112d:	8b 00                	mov    (%eax),%eax
f010112f:	85 c0                	test   %eax,%eax
f0101131:	75 71                	jne    f01011a4 <check_boot_pgdir+0x228>
f0101133:	68 b6 56 10 f0       	push   $0xf01056b6
f0101138:	68 f2 55 10 f0       	push   $0xf01055f2
f010113d:	6a 70                	push   $0x70
f010113f:	68 81 55 10 f0       	push   $0xf0105581
f0101144:	e8 e5 ef ff ff       	call   f010012e <_panic>
			break;
		default:
			if (i >= PDX(KERNEL_BASE))
f0101149:	81 7d f4 bf 03 00 00 	cmpl   $0x3bf,-0xc(%ebp)
f0101150:	76 29                	jbe    f010117b <check_boot_pgdir+0x1ff>
				assert(ptr_page_directory[i]);
f0101152:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101157:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010115a:	c1 e2 02             	shl    $0x2,%edx
f010115d:	01 d0                	add    %edx,%eax
f010115f:	8b 00                	mov    (%eax),%eax
f0101161:	85 c0                	test   %eax,%eax
f0101163:	75 42                	jne    f01011a7 <check_boot_pgdir+0x22b>
f0101165:	68 b6 56 10 f0       	push   $0xf01056b6
f010116a:	68 f2 55 10 f0       	push   $0xf01055f2
f010116f:	6a 74                	push   $0x74
f0101171:	68 81 55 10 f0       	push   $0xf0105581
f0101176:	e8 b3 ef ff ff       	call   f010012e <_panic>
			else				
				assert(ptr_page_directory[i] == 0);
f010117b:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101180:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101183:	c1 e2 02             	shl    $0x2,%edx
f0101186:	01 d0                	add    %edx,%eax
f0101188:	8b 00                	mov    (%eax),%eax
f010118a:	85 c0                	test   %eax,%eax
f010118c:	74 19                	je     f01011a7 <check_boot_pgdir+0x22b>
f010118e:	68 cc 56 10 f0       	push   $0xf01056cc
f0101193:	68 f2 55 10 f0       	push   $0xf01055f2
f0101198:	6a 76                	push   $0x76
f010119a:	68 81 55 10 f0       	push   $0xf0105581
f010119f:	e8 8a ef ff ff       	call   f010012e <_panic>
		case PDX(UVPT):
		case PDX(KERNEL_STACK_TOP-1):
		case PDX(UENVS):
		case PDX(READ_ONLY_FRAMES_INFO):			
			assert(ptr_page_directory[i]);
			break;
f01011a4:	90                   	nop
f01011a5:	eb 01                	jmp    f01011a8 <check_boot_pgdir+0x22c>
		default:
			if (i >= PDX(KERNEL_BASE))
				assert(ptr_page_directory[i]);
			else				
				assert(ptr_page_directory[i] == 0);
			break;
f01011a7:	90                   	nop
	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f01011a8:	ff 45 f4             	incl   -0xc(%ebp)
f01011ab:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
f01011b2:	0f 86 5b ff ff ff    	jbe    f0101113 <check_boot_pgdir+0x197>
			else				
				assert(ptr_page_directory[i] == 0);
			break;
		}
	}
	cprintf("check_boot_pgdir() succeeded!\n");
f01011b8:	83 ec 0c             	sub    $0xc,%esp
f01011bb:	68 e8 56 10 f0       	push   $0xf01056e8
f01011c0:	e8 8e 1e 00 00       	call   f0103053 <cprintf>
f01011c5:	83 c4 10             	add    $0x10,%esp
}
f01011c8:	90                   	nop
f01011c9:	c9                   	leave  
f01011ca:	c3                   	ret    

f01011cb <check_va2pa>:
// defined by the page directory 'ptr_page_directory'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the check_boot_pgdir() function; it shouldn't be used elsewhere.

uint32 check_va2pa(uint32 *ptr_page_directory, uint32 va)
{
f01011cb:	55                   	push   %ebp
f01011cc:	89 e5                	mov    %esp,%ebp
f01011ce:	83 ec 18             	sub    $0x18,%esp
	uint32 *p;

	ptr_page_directory = &ptr_page_directory[PDX(va)];
f01011d1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011d4:	c1 e8 16             	shr    $0x16,%eax
f01011d7:	c1 e0 02             	shl    $0x2,%eax
f01011da:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*ptr_page_directory & PERM_PRESENT))
f01011dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01011e0:	8b 00                	mov    (%eax),%eax
f01011e2:	83 e0 01             	and    $0x1,%eax
f01011e5:	85 c0                	test   %eax,%eax
f01011e7:	75 0a                	jne    f01011f3 <check_va2pa+0x28>
		return ~0;
f01011e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01011ee:	e9 87 00 00 00       	jmp    f010127a <check_va2pa+0xaf>
	p = (uint32*) K_VIRTUAL_ADDRESS(EXTRACT_ADDRESS(*ptr_page_directory));
f01011f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01011f6:	8b 00                	mov    (%eax),%eax
f01011f8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01011fd:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101200:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101203:	c1 e8 0c             	shr    $0xc,%eax
f0101206:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101209:	a1 a8 e7 14 f0       	mov    0xf014e7a8,%eax
f010120e:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0101211:	72 17                	jb     f010122a <check_va2pa+0x5f>
f0101213:	ff 75 f4             	pushl  -0xc(%ebp)
f0101216:	68 08 57 10 f0       	push   $0xf0105708
f010121b:	68 89 00 00 00       	push   $0x89
f0101220:	68 81 55 10 f0       	push   $0xf0105581
f0101225:	e8 04 ef ff ff       	call   f010012e <_panic>
f010122a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010122d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101232:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!(p[PTX(va)] & PERM_PRESENT))
f0101235:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101238:	c1 e8 0c             	shr    $0xc,%eax
f010123b:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101240:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101247:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010124a:	01 d0                	add    %edx,%eax
f010124c:	8b 00                	mov    (%eax),%eax
f010124e:	83 e0 01             	and    $0x1,%eax
f0101251:	85 c0                	test   %eax,%eax
f0101253:	75 07                	jne    f010125c <check_va2pa+0x91>
		return ~0;
f0101255:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010125a:	eb 1e                	jmp    f010127a <check_va2pa+0xaf>
	return EXTRACT_ADDRESS(p[PTX(va)]);
f010125c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010125f:	c1 e8 0c             	shr    $0xc,%eax
f0101262:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101267:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010126e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101271:	01 d0                	add    %edx,%eax
f0101273:	8b 00                	mov    (%eax),%eax
f0101275:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
f010127a:	c9                   	leave  
f010127b:	c3                   	ret    

f010127c <tlb_invalidate>:
		
void tlb_invalidate(uint32 *ptr_page_directory, void *virtual_address)
{
f010127c:	55                   	push   %ebp
f010127d:	89 e5                	mov    %esp,%ebp
f010127f:	83 ec 10             	sub    $0x10,%esp
f0101282:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101285:	89 45 fc             	mov    %eax,-0x4(%ebp)
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101288:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010128b:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(virtual_address);
}
f010128e:	90                   	nop
f010128f:	c9                   	leave  
f0101290:	c3                   	ret    

f0101291 <page_check>:

void page_check()
{
f0101291:	55                   	push   %ebp
f0101292:	89 e5                	mov    %esp,%ebp
f0101294:	53                   	push   %ebx
f0101295:	83 ec 24             	sub    $0x24,%esp
	struct Frame_Info *pp, *pp0, *pp1, *pp2;
	struct Linked_List fl;

	// should be able to allocate three frames_info
	pp0 = pp1 = pp2 = 0;
f0101298:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
f010129f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01012a2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012a5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012a8:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(allocate_frame(&pp0) == 0);
f01012ab:	83 ec 0c             	sub    $0xc,%esp
f01012ae:	8d 45 f0             	lea    -0x10(%ebp),%eax
f01012b1:	50                   	push   %eax
f01012b2:	e8 e7 10 00 00       	call   f010239e <allocate_frame>
f01012b7:	83 c4 10             	add    $0x10,%esp
f01012ba:	85 c0                	test   %eax,%eax
f01012bc:	74 19                	je     f01012d7 <page_check+0x46>
f01012be:	68 37 57 10 f0       	push   $0xf0105737
f01012c3:	68 f2 55 10 f0       	push   $0xf01055f2
f01012c8:	68 9d 00 00 00       	push   $0x9d
f01012cd:	68 81 55 10 f0       	push   $0xf0105581
f01012d2:	e8 57 ee ff ff       	call   f010012e <_panic>
	assert(allocate_frame(&pp1) == 0);
f01012d7:	83 ec 0c             	sub    $0xc,%esp
f01012da:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01012dd:	50                   	push   %eax
f01012de:	e8 bb 10 00 00       	call   f010239e <allocate_frame>
f01012e3:	83 c4 10             	add    $0x10,%esp
f01012e6:	85 c0                	test   %eax,%eax
f01012e8:	74 19                	je     f0101303 <page_check+0x72>
f01012ea:	68 51 57 10 f0       	push   $0xf0105751
f01012ef:	68 f2 55 10 f0       	push   $0xf01055f2
f01012f4:	68 9e 00 00 00       	push   $0x9e
f01012f9:	68 81 55 10 f0       	push   $0xf0105581
f01012fe:	e8 2b ee ff ff       	call   f010012e <_panic>
	assert(allocate_frame(&pp2) == 0);
f0101303:	83 ec 0c             	sub    $0xc,%esp
f0101306:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0101309:	50                   	push   %eax
f010130a:	e8 8f 10 00 00       	call   f010239e <allocate_frame>
f010130f:	83 c4 10             	add    $0x10,%esp
f0101312:	85 c0                	test   %eax,%eax
f0101314:	74 19                	je     f010132f <page_check+0x9e>
f0101316:	68 6b 57 10 f0       	push   $0xf010576b
f010131b:	68 f2 55 10 f0       	push   $0xf01055f2
f0101320:	68 9f 00 00 00       	push   $0x9f
f0101325:	68 81 55 10 f0       	push   $0xf0105581
f010132a:	e8 ff ed ff ff       	call   f010012e <_panic>

	assert(pp0);
f010132f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101332:	85 c0                	test   %eax,%eax
f0101334:	75 19                	jne    f010134f <page_check+0xbe>
f0101336:	68 85 57 10 f0       	push   $0xf0105785
f010133b:	68 f2 55 10 f0       	push   $0xf01055f2
f0101340:	68 a1 00 00 00       	push   $0xa1
f0101345:	68 81 55 10 f0       	push   $0xf0105581
f010134a:	e8 df ed ff ff       	call   f010012e <_panic>
	assert(pp1 && pp1 != pp0);
f010134f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101352:	85 c0                	test   %eax,%eax
f0101354:	74 0a                	je     f0101360 <page_check+0xcf>
f0101356:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101359:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010135c:	39 c2                	cmp    %eax,%edx
f010135e:	75 19                	jne    f0101379 <page_check+0xe8>
f0101360:	68 89 57 10 f0       	push   $0xf0105789
f0101365:	68 f2 55 10 f0       	push   $0xf01055f2
f010136a:	68 a2 00 00 00       	push   $0xa2
f010136f:	68 81 55 10 f0       	push   $0xf0105581
f0101374:	e8 b5 ed ff ff       	call   f010012e <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101379:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010137c:	85 c0                	test   %eax,%eax
f010137e:	74 14                	je     f0101394 <page_check+0x103>
f0101380:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101383:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101386:	39 c2                	cmp    %eax,%edx
f0101388:	74 0a                	je     f0101394 <page_check+0x103>
f010138a:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010138d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101390:	39 c2                	cmp    %eax,%edx
f0101392:	75 19                	jne    f01013ad <page_check+0x11c>
f0101394:	68 9c 57 10 f0       	push   $0xf010579c
f0101399:	68 f2 55 10 f0       	push   $0xf01055f2
f010139e:	68 a3 00 00 00       	push   $0xa3
f01013a3:	68 81 55 10 f0       	push   $0xf0105581
f01013a8:	e8 81 ed ff ff       	call   f010012e <_panic>

	// temporarily steal the rest of the free frames_info
	fl = free_frame_list;
f01013ad:	a1 b8 e7 14 f0       	mov    0xf014e7b8,%eax
f01013b2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	LIST_INIT(&free_frame_list);
f01013b5:	c7 05 b8 e7 14 f0 00 	movl   $0x0,0xf014e7b8
f01013bc:	00 00 00 

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f01013bf:	83 ec 0c             	sub    $0xc,%esp
f01013c2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01013c5:	50                   	push   %eax
f01013c6:	e8 d3 0f 00 00       	call   f010239e <allocate_frame>
f01013cb:	83 c4 10             	add    $0x10,%esp
f01013ce:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01013d1:	74 19                	je     f01013ec <page_check+0x15b>
f01013d3:	68 bc 57 10 f0       	push   $0xf01057bc
f01013d8:	68 f2 55 10 f0       	push   $0xf01055f2
f01013dd:	68 aa 00 00 00       	push   $0xaa
f01013e2:	68 81 55 10 f0       	push   $0xf0105581
f01013e7:	e8 42 ed ff ff       	call   f010012e <_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(map_frame(ptr_page_directory, pp1, 0x0, 0) < 0);
f01013ec:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01013ef:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f01013f4:	6a 00                	push   $0x0
f01013f6:	6a 00                	push   $0x0
f01013f8:	52                   	push   %edx
f01013f9:	50                   	push   %eax
f01013fa:	e8 ac 11 00 00       	call   f01025ab <map_frame>
f01013ff:	83 c4 10             	add    $0x10,%esp
f0101402:	85 c0                	test   %eax,%eax
f0101404:	78 19                	js     f010141f <page_check+0x18e>
f0101406:	68 dc 57 10 f0       	push   $0xf01057dc
f010140b:	68 f2 55 10 f0       	push   $0xf01055f2
f0101410:	68 ad 00 00 00       	push   $0xad
f0101415:	68 81 55 10 f0       	push   $0xf0105581
f010141a:	e8 0f ed ff ff       	call   f010012e <_panic>

	// free pp0 and try again: pp0 should be used for page table
	free_frame(pp0);
f010141f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101422:	83 ec 0c             	sub    $0xc,%esp
f0101425:	50                   	push   %eax
f0101426:	e8 da 0f 00 00       	call   f0102405 <free_frame>
f010142b:	83 c4 10             	add    $0x10,%esp
	assert(map_frame(ptr_page_directory, pp1, 0x0, 0) == 0);
f010142e:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101431:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101436:	6a 00                	push   $0x0
f0101438:	6a 00                	push   $0x0
f010143a:	52                   	push   %edx
f010143b:	50                   	push   %eax
f010143c:	e8 6a 11 00 00       	call   f01025ab <map_frame>
f0101441:	83 c4 10             	add    $0x10,%esp
f0101444:	85 c0                	test   %eax,%eax
f0101446:	74 19                	je     f0101461 <page_check+0x1d0>
f0101448:	68 0c 58 10 f0       	push   $0xf010580c
f010144d:	68 f2 55 10 f0       	push   $0xf01055f2
f0101452:	68 b1 00 00 00       	push   $0xb1
f0101457:	68 81 55 10 f0       	push   $0xf0105581
f010145c:	e8 cd ec ff ff       	call   f010012e <_panic>
	assert(EXTRACT_ADDRESS(ptr_page_directory[0]) == to_physical_address(pp0));
f0101461:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101466:	8b 00                	mov    (%eax),%eax
f0101468:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010146d:	89 c3                	mov    %eax,%ebx
f010146f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101472:	83 ec 0c             	sub    $0xc,%esp
f0101475:	50                   	push   %eax
f0101476:	e8 05 fa ff ff       	call   f0100e80 <to_physical_address>
f010147b:	83 c4 10             	add    $0x10,%esp
f010147e:	39 c3                	cmp    %eax,%ebx
f0101480:	74 19                	je     f010149b <page_check+0x20a>
f0101482:	68 3c 58 10 f0       	push   $0xf010583c
f0101487:	68 f2 55 10 f0       	push   $0xf01055f2
f010148c:	68 b2 00 00 00       	push   $0xb2
f0101491:	68 81 55 10 f0       	push   $0xf0105581
f0101496:	e8 93 ec ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, 0x0) == to_physical_address(pp1));
f010149b:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f01014a0:	83 ec 08             	sub    $0x8,%esp
f01014a3:	6a 00                	push   $0x0
f01014a5:	50                   	push   %eax
f01014a6:	e8 20 fd ff ff       	call   f01011cb <check_va2pa>
f01014ab:	83 c4 10             	add    $0x10,%esp
f01014ae:	89 c3                	mov    %eax,%ebx
f01014b0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01014b3:	83 ec 0c             	sub    $0xc,%esp
f01014b6:	50                   	push   %eax
f01014b7:	e8 c4 f9 ff ff       	call   f0100e80 <to_physical_address>
f01014bc:	83 c4 10             	add    $0x10,%esp
f01014bf:	39 c3                	cmp    %eax,%ebx
f01014c1:	74 19                	je     f01014dc <page_check+0x24b>
f01014c3:	68 80 58 10 f0       	push   $0xf0105880
f01014c8:	68 f2 55 10 f0       	push   $0xf01055f2
f01014cd:	68 b3 00 00 00       	push   $0xb3
f01014d2:	68 81 55 10 f0       	push   $0xf0105581
f01014d7:	e8 52 ec ff ff       	call   f010012e <_panic>
	assert(pp1->references == 1);
f01014dc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01014df:	8b 40 08             	mov    0x8(%eax),%eax
f01014e2:	66 83 f8 01          	cmp    $0x1,%ax
f01014e6:	74 19                	je     f0101501 <page_check+0x270>
f01014e8:	68 c1 58 10 f0       	push   $0xf01058c1
f01014ed:	68 f2 55 10 f0       	push   $0xf01055f2
f01014f2:	68 b4 00 00 00       	push   $0xb4
f01014f7:	68 81 55 10 f0       	push   $0xf0105581
f01014fc:	e8 2d ec ff ff       	call   f010012e <_panic>
	assert(pp0->references == 1);
f0101501:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101504:	8b 40 08             	mov    0x8(%eax),%eax
f0101507:	66 83 f8 01          	cmp    $0x1,%ax
f010150b:	74 19                	je     f0101526 <page_check+0x295>
f010150d:	68 d6 58 10 f0       	push   $0xf01058d6
f0101512:	68 f2 55 10 f0       	push   $0xf01055f2
f0101517:	68 b5 00 00 00       	push   $0xb5
f010151c:	68 81 55 10 f0       	push   $0xf0105581
f0101521:	e8 08 ec ff ff       	call   f010012e <_panic>

	// should be able to map pp2 at PAGE_SIZE because pp0 is already allocated for page table
	assert(map_frame(ptr_page_directory, pp2, (void*) PAGE_SIZE, 0) == 0);
f0101526:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101529:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f010152e:	6a 00                	push   $0x0
f0101530:	68 00 10 00 00       	push   $0x1000
f0101535:	52                   	push   %edx
f0101536:	50                   	push   %eax
f0101537:	e8 6f 10 00 00       	call   f01025ab <map_frame>
f010153c:	83 c4 10             	add    $0x10,%esp
f010153f:	85 c0                	test   %eax,%eax
f0101541:	74 19                	je     f010155c <page_check+0x2cb>
f0101543:	68 ec 58 10 f0       	push   $0xf01058ec
f0101548:	68 f2 55 10 f0       	push   $0xf01055f2
f010154d:	68 b8 00 00 00       	push   $0xb8
f0101552:	68 81 55 10 f0       	push   $0xf0105581
f0101557:	e8 d2 eb ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp2));
f010155c:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101561:	83 ec 08             	sub    $0x8,%esp
f0101564:	68 00 10 00 00       	push   $0x1000
f0101569:	50                   	push   %eax
f010156a:	e8 5c fc ff ff       	call   f01011cb <check_va2pa>
f010156f:	83 c4 10             	add    $0x10,%esp
f0101572:	89 c3                	mov    %eax,%ebx
f0101574:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101577:	83 ec 0c             	sub    $0xc,%esp
f010157a:	50                   	push   %eax
f010157b:	e8 00 f9 ff ff       	call   f0100e80 <to_physical_address>
f0101580:	83 c4 10             	add    $0x10,%esp
f0101583:	39 c3                	cmp    %eax,%ebx
f0101585:	74 19                	je     f01015a0 <page_check+0x30f>
f0101587:	68 2c 59 10 f0       	push   $0xf010592c
f010158c:	68 f2 55 10 f0       	push   $0xf01055f2
f0101591:	68 b9 00 00 00       	push   $0xb9
f0101596:	68 81 55 10 f0       	push   $0xf0105581
f010159b:	e8 8e eb ff ff       	call   f010012e <_panic>
	assert(pp2->references == 1);
f01015a0:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01015a3:	8b 40 08             	mov    0x8(%eax),%eax
f01015a6:	66 83 f8 01          	cmp    $0x1,%ax
f01015aa:	74 19                	je     f01015c5 <page_check+0x334>
f01015ac:	68 73 59 10 f0       	push   $0xf0105973
f01015b1:	68 f2 55 10 f0       	push   $0xf01055f2
f01015b6:	68 ba 00 00 00       	push   $0xba
f01015bb:	68 81 55 10 f0       	push   $0xf0105581
f01015c0:	e8 69 eb ff ff       	call   f010012e <_panic>

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f01015c5:	83 ec 0c             	sub    $0xc,%esp
f01015c8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01015cb:	50                   	push   %eax
f01015cc:	e8 cd 0d 00 00       	call   f010239e <allocate_frame>
f01015d1:	83 c4 10             	add    $0x10,%esp
f01015d4:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01015d7:	74 19                	je     f01015f2 <page_check+0x361>
f01015d9:	68 bc 57 10 f0       	push   $0xf01057bc
f01015de:	68 f2 55 10 f0       	push   $0xf01055f2
f01015e3:	68 bd 00 00 00       	push   $0xbd
f01015e8:	68 81 55 10 f0       	push   $0xf0105581
f01015ed:	e8 3c eb ff ff       	call   f010012e <_panic>

	// should be able to map pp2 at PAGE_SIZE because it's already there
	assert(map_frame(ptr_page_directory, pp2, (void*) PAGE_SIZE, 0) == 0);
f01015f2:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01015f5:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f01015fa:	6a 00                	push   $0x0
f01015fc:	68 00 10 00 00       	push   $0x1000
f0101601:	52                   	push   %edx
f0101602:	50                   	push   %eax
f0101603:	e8 a3 0f 00 00       	call   f01025ab <map_frame>
f0101608:	83 c4 10             	add    $0x10,%esp
f010160b:	85 c0                	test   %eax,%eax
f010160d:	74 19                	je     f0101628 <page_check+0x397>
f010160f:	68 ec 58 10 f0       	push   $0xf01058ec
f0101614:	68 f2 55 10 f0       	push   $0xf01055f2
f0101619:	68 c0 00 00 00       	push   $0xc0
f010161e:	68 81 55 10 f0       	push   $0xf0105581
f0101623:	e8 06 eb ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp2));
f0101628:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f010162d:	83 ec 08             	sub    $0x8,%esp
f0101630:	68 00 10 00 00       	push   $0x1000
f0101635:	50                   	push   %eax
f0101636:	e8 90 fb ff ff       	call   f01011cb <check_va2pa>
f010163b:	83 c4 10             	add    $0x10,%esp
f010163e:	89 c3                	mov    %eax,%ebx
f0101640:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101643:	83 ec 0c             	sub    $0xc,%esp
f0101646:	50                   	push   %eax
f0101647:	e8 34 f8 ff ff       	call   f0100e80 <to_physical_address>
f010164c:	83 c4 10             	add    $0x10,%esp
f010164f:	39 c3                	cmp    %eax,%ebx
f0101651:	74 19                	je     f010166c <page_check+0x3db>
f0101653:	68 2c 59 10 f0       	push   $0xf010592c
f0101658:	68 f2 55 10 f0       	push   $0xf01055f2
f010165d:	68 c1 00 00 00       	push   $0xc1
f0101662:	68 81 55 10 f0       	push   $0xf0105581
f0101667:	e8 c2 ea ff ff       	call   f010012e <_panic>
	assert(pp2->references == 1);
f010166c:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010166f:	8b 40 08             	mov    0x8(%eax),%eax
f0101672:	66 83 f8 01          	cmp    $0x1,%ax
f0101676:	74 19                	je     f0101691 <page_check+0x400>
f0101678:	68 73 59 10 f0       	push   $0xf0105973
f010167d:	68 f2 55 10 f0       	push   $0xf01055f2
f0101682:	68 c2 00 00 00       	push   $0xc2
f0101687:	68 81 55 10 f0       	push   $0xf0105581
f010168c:	e8 9d ea ff ff       	call   f010012e <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in map_frame
	assert(allocate_frame(&pp) == E_NO_MEM);
f0101691:	83 ec 0c             	sub    $0xc,%esp
f0101694:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101697:	50                   	push   %eax
f0101698:	e8 01 0d 00 00       	call   f010239e <allocate_frame>
f010169d:	83 c4 10             	add    $0x10,%esp
f01016a0:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01016a3:	74 19                	je     f01016be <page_check+0x42d>
f01016a5:	68 bc 57 10 f0       	push   $0xf01057bc
f01016aa:	68 f2 55 10 f0       	push   $0xf01055f2
f01016af:	68 c6 00 00 00       	push   $0xc6
f01016b4:	68 81 55 10 f0       	push   $0xf0105581
f01016b9:	e8 70 ea ff ff       	call   f010012e <_panic>

	// should not be able to map at PTSIZE because need free frame for page table
	assert(map_frame(ptr_page_directory, pp0, (void*) PTSIZE, 0) < 0);
f01016be:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01016c1:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f01016c6:	6a 00                	push   $0x0
f01016c8:	68 00 00 40 00       	push   $0x400000
f01016cd:	52                   	push   %edx
f01016ce:	50                   	push   %eax
f01016cf:	e8 d7 0e 00 00       	call   f01025ab <map_frame>
f01016d4:	83 c4 10             	add    $0x10,%esp
f01016d7:	85 c0                	test   %eax,%eax
f01016d9:	78 19                	js     f01016f4 <page_check+0x463>
f01016db:	68 88 59 10 f0       	push   $0xf0105988
f01016e0:	68 f2 55 10 f0       	push   $0xf01055f2
f01016e5:	68 c9 00 00 00       	push   $0xc9
f01016ea:	68 81 55 10 f0       	push   $0xf0105581
f01016ef:	e8 3a ea ff ff       	call   f010012e <_panic>

	// insert pp1 at PAGE_SIZE (replacing pp2)
	assert(map_frame(ptr_page_directory, pp1, (void*) PAGE_SIZE, 0) == 0);
f01016f4:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01016f7:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f01016fc:	6a 00                	push   $0x0
f01016fe:	68 00 10 00 00       	push   $0x1000
f0101703:	52                   	push   %edx
f0101704:	50                   	push   %eax
f0101705:	e8 a1 0e 00 00       	call   f01025ab <map_frame>
f010170a:	83 c4 10             	add    $0x10,%esp
f010170d:	85 c0                	test   %eax,%eax
f010170f:	74 19                	je     f010172a <page_check+0x499>
f0101711:	68 c4 59 10 f0       	push   $0xf01059c4
f0101716:	68 f2 55 10 f0       	push   $0xf01055f2
f010171b:	68 cc 00 00 00       	push   $0xcc
f0101720:	68 81 55 10 f0       	push   $0xf0105581
f0101725:	e8 04 ea ff ff       	call   f010012e <_panic>

	// should have pp1 at both 0 and PAGE_SIZE, pp2 nowhere, ...
	assert(check_va2pa(ptr_page_directory, 0) == to_physical_address(pp1));
f010172a:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f010172f:	83 ec 08             	sub    $0x8,%esp
f0101732:	6a 00                	push   $0x0
f0101734:	50                   	push   %eax
f0101735:	e8 91 fa ff ff       	call   f01011cb <check_va2pa>
f010173a:	83 c4 10             	add    $0x10,%esp
f010173d:	89 c3                	mov    %eax,%ebx
f010173f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101742:	83 ec 0c             	sub    $0xc,%esp
f0101745:	50                   	push   %eax
f0101746:	e8 35 f7 ff ff       	call   f0100e80 <to_physical_address>
f010174b:	83 c4 10             	add    $0x10,%esp
f010174e:	39 c3                	cmp    %eax,%ebx
f0101750:	74 19                	je     f010176b <page_check+0x4da>
f0101752:	68 04 5a 10 f0       	push   $0xf0105a04
f0101757:	68 f2 55 10 f0       	push   $0xf01055f2
f010175c:	68 cf 00 00 00       	push   $0xcf
f0101761:	68 81 55 10 f0       	push   $0xf0105581
f0101766:	e8 c3 e9 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp1));
f010176b:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101770:	83 ec 08             	sub    $0x8,%esp
f0101773:	68 00 10 00 00       	push   $0x1000
f0101778:	50                   	push   %eax
f0101779:	e8 4d fa ff ff       	call   f01011cb <check_va2pa>
f010177e:	83 c4 10             	add    $0x10,%esp
f0101781:	89 c3                	mov    %eax,%ebx
f0101783:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101786:	83 ec 0c             	sub    $0xc,%esp
f0101789:	50                   	push   %eax
f010178a:	e8 f1 f6 ff ff       	call   f0100e80 <to_physical_address>
f010178f:	83 c4 10             	add    $0x10,%esp
f0101792:	39 c3                	cmp    %eax,%ebx
f0101794:	74 19                	je     f01017af <page_check+0x51e>
f0101796:	68 44 5a 10 f0       	push   $0xf0105a44
f010179b:	68 f2 55 10 f0       	push   $0xf01055f2
f01017a0:	68 d0 00 00 00       	push   $0xd0
f01017a5:	68 81 55 10 f0       	push   $0xf0105581
f01017aa:	e8 7f e9 ff ff       	call   f010012e <_panic>
	// ... and ref counts should reflect this
	assert(pp1->references == 2);
f01017af:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01017b2:	8b 40 08             	mov    0x8(%eax),%eax
f01017b5:	66 83 f8 02          	cmp    $0x2,%ax
f01017b9:	74 19                	je     f01017d4 <page_check+0x543>
f01017bb:	68 8b 5a 10 f0       	push   $0xf0105a8b
f01017c0:	68 f2 55 10 f0       	push   $0xf01055f2
f01017c5:	68 d2 00 00 00       	push   $0xd2
f01017ca:	68 81 55 10 f0       	push   $0xf0105581
f01017cf:	e8 5a e9 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f01017d4:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01017d7:	8b 40 08             	mov    0x8(%eax),%eax
f01017da:	66 85 c0             	test   %ax,%ax
f01017dd:	74 19                	je     f01017f8 <page_check+0x567>
f01017df:	68 a0 5a 10 f0       	push   $0xf0105aa0
f01017e4:	68 f2 55 10 f0       	push   $0xf01055f2
f01017e9:	68 d3 00 00 00       	push   $0xd3
f01017ee:	68 81 55 10 f0       	push   $0xf0105581
f01017f3:	e8 36 e9 ff ff       	call   f010012e <_panic>

	// pp2 should be returned by allocate_frame
	assert(allocate_frame(&pp) == 0 && pp == pp2);
f01017f8:	83 ec 0c             	sub    $0xc,%esp
f01017fb:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01017fe:	50                   	push   %eax
f01017ff:	e8 9a 0b 00 00       	call   f010239e <allocate_frame>
f0101804:	83 c4 10             	add    $0x10,%esp
f0101807:	85 c0                	test   %eax,%eax
f0101809:	75 0a                	jne    f0101815 <page_check+0x584>
f010180b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010180e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101811:	39 c2                	cmp    %eax,%edx
f0101813:	74 19                	je     f010182e <page_check+0x59d>
f0101815:	68 b8 5a 10 f0       	push   $0xf0105ab8
f010181a:	68 f2 55 10 f0       	push   $0xf01055f2
f010181f:	68 d6 00 00 00       	push   $0xd6
f0101824:	68 81 55 10 f0       	push   $0xf0105581
f0101829:	e8 00 e9 ff ff       	call   f010012e <_panic>

	// unmapping pp1 at 0 should keep pp1 at PAGE_SIZE
	unmap_frame(ptr_page_directory, 0x0);
f010182e:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101833:	83 ec 08             	sub    $0x8,%esp
f0101836:	6a 00                	push   $0x0
f0101838:	50                   	push   %eax
f0101839:	e8 8b 0e 00 00       	call   f01026c9 <unmap_frame>
f010183e:	83 c4 10             	add    $0x10,%esp
	assert(check_va2pa(ptr_page_directory, 0x0) == ~0);
f0101841:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101846:	83 ec 08             	sub    $0x8,%esp
f0101849:	6a 00                	push   $0x0
f010184b:	50                   	push   %eax
f010184c:	e8 7a f9 ff ff       	call   f01011cb <check_va2pa>
f0101851:	83 c4 10             	add    $0x10,%esp
f0101854:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101857:	74 19                	je     f0101872 <page_check+0x5e1>
f0101859:	68 e0 5a 10 f0       	push   $0xf0105ae0
f010185e:	68 f2 55 10 f0       	push   $0xf01055f2
f0101863:	68 da 00 00 00       	push   $0xda
f0101868:	68 81 55 10 f0       	push   $0xf0105581
f010186d:	e8 bc e8 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp1));
f0101872:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101877:	83 ec 08             	sub    $0x8,%esp
f010187a:	68 00 10 00 00       	push   $0x1000
f010187f:	50                   	push   %eax
f0101880:	e8 46 f9 ff ff       	call   f01011cb <check_va2pa>
f0101885:	83 c4 10             	add    $0x10,%esp
f0101888:	89 c3                	mov    %eax,%ebx
f010188a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010188d:	83 ec 0c             	sub    $0xc,%esp
f0101890:	50                   	push   %eax
f0101891:	e8 ea f5 ff ff       	call   f0100e80 <to_physical_address>
f0101896:	83 c4 10             	add    $0x10,%esp
f0101899:	39 c3                	cmp    %eax,%ebx
f010189b:	74 19                	je     f01018b6 <page_check+0x625>
f010189d:	68 44 5a 10 f0       	push   $0xf0105a44
f01018a2:	68 f2 55 10 f0       	push   $0xf01055f2
f01018a7:	68 db 00 00 00       	push   $0xdb
f01018ac:	68 81 55 10 f0       	push   $0xf0105581
f01018b1:	e8 78 e8 ff ff       	call   f010012e <_panic>
	assert(pp1->references == 1);
f01018b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01018b9:	8b 40 08             	mov    0x8(%eax),%eax
f01018bc:	66 83 f8 01          	cmp    $0x1,%ax
f01018c0:	74 19                	je     f01018db <page_check+0x64a>
f01018c2:	68 c1 58 10 f0       	push   $0xf01058c1
f01018c7:	68 f2 55 10 f0       	push   $0xf01055f2
f01018cc:	68 dc 00 00 00       	push   $0xdc
f01018d1:	68 81 55 10 f0       	push   $0xf0105581
f01018d6:	e8 53 e8 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f01018db:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01018de:	8b 40 08             	mov    0x8(%eax),%eax
f01018e1:	66 85 c0             	test   %ax,%ax
f01018e4:	74 19                	je     f01018ff <page_check+0x66e>
f01018e6:	68 a0 5a 10 f0       	push   $0xf0105aa0
f01018eb:	68 f2 55 10 f0       	push   $0xf01055f2
f01018f0:	68 dd 00 00 00       	push   $0xdd
f01018f5:	68 81 55 10 f0       	push   $0xf0105581
f01018fa:	e8 2f e8 ff ff       	call   f010012e <_panic>

	// unmapping pp1 at PAGE_SIZE should free it
	unmap_frame(ptr_page_directory, (void*) PAGE_SIZE);
f01018ff:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101904:	83 ec 08             	sub    $0x8,%esp
f0101907:	68 00 10 00 00       	push   $0x1000
f010190c:	50                   	push   %eax
f010190d:	e8 b7 0d 00 00       	call   f01026c9 <unmap_frame>
f0101912:	83 c4 10             	add    $0x10,%esp
	assert(check_va2pa(ptr_page_directory, 0x0) == ~0);
f0101915:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f010191a:	83 ec 08             	sub    $0x8,%esp
f010191d:	6a 00                	push   $0x0
f010191f:	50                   	push   %eax
f0101920:	e8 a6 f8 ff ff       	call   f01011cb <check_va2pa>
f0101925:	83 c4 10             	add    $0x10,%esp
f0101928:	83 f8 ff             	cmp    $0xffffffff,%eax
f010192b:	74 19                	je     f0101946 <page_check+0x6b5>
f010192d:	68 e0 5a 10 f0       	push   $0xf0105ae0
f0101932:	68 f2 55 10 f0       	push   $0xf01055f2
f0101937:	68 e1 00 00 00       	push   $0xe1
f010193c:	68 81 55 10 f0       	push   $0xf0105581
f0101941:	e8 e8 e7 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == ~0);
f0101946:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f010194b:	83 ec 08             	sub    $0x8,%esp
f010194e:	68 00 10 00 00       	push   $0x1000
f0101953:	50                   	push   %eax
f0101954:	e8 72 f8 ff ff       	call   f01011cb <check_va2pa>
f0101959:	83 c4 10             	add    $0x10,%esp
f010195c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010195f:	74 19                	je     f010197a <page_check+0x6e9>
f0101961:	68 0c 5b 10 f0       	push   $0xf0105b0c
f0101966:	68 f2 55 10 f0       	push   $0xf01055f2
f010196b:	68 e2 00 00 00       	push   $0xe2
f0101970:	68 81 55 10 f0       	push   $0xf0105581
f0101975:	e8 b4 e7 ff ff       	call   f010012e <_panic>
	assert(pp1->references == 0);
f010197a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010197d:	8b 40 08             	mov    0x8(%eax),%eax
f0101980:	66 85 c0             	test   %ax,%ax
f0101983:	74 19                	je     f010199e <page_check+0x70d>
f0101985:	68 3d 5b 10 f0       	push   $0xf0105b3d
f010198a:	68 f2 55 10 f0       	push   $0xf01055f2
f010198f:	68 e3 00 00 00       	push   $0xe3
f0101994:	68 81 55 10 f0       	push   $0xf0105581
f0101999:	e8 90 e7 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f010199e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01019a1:	8b 40 08             	mov    0x8(%eax),%eax
f01019a4:	66 85 c0             	test   %ax,%ax
f01019a7:	74 19                	je     f01019c2 <page_check+0x731>
f01019a9:	68 a0 5a 10 f0       	push   $0xf0105aa0
f01019ae:	68 f2 55 10 f0       	push   $0xf01055f2
f01019b3:	68 e4 00 00 00       	push   $0xe4
f01019b8:	68 81 55 10 f0       	push   $0xf0105581
f01019bd:	e8 6c e7 ff ff       	call   f010012e <_panic>

	// so it should be returned by allocate_frame
	assert(allocate_frame(&pp) == 0 && pp == pp1);
f01019c2:	83 ec 0c             	sub    $0xc,%esp
f01019c5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01019c8:	50                   	push   %eax
f01019c9:	e8 d0 09 00 00       	call   f010239e <allocate_frame>
f01019ce:	83 c4 10             	add    $0x10,%esp
f01019d1:	85 c0                	test   %eax,%eax
f01019d3:	75 0a                	jne    f01019df <page_check+0x74e>
f01019d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01019d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01019db:	39 c2                	cmp    %eax,%edx
f01019dd:	74 19                	je     f01019f8 <page_check+0x767>
f01019df:	68 54 5b 10 f0       	push   $0xf0105b54
f01019e4:	68 f2 55 10 f0       	push   $0xf01055f2
f01019e9:	68 e7 00 00 00       	push   $0xe7
f01019ee:	68 81 55 10 f0       	push   $0xf0105581
f01019f3:	e8 36 e7 ff ff       	call   f010012e <_panic>

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f01019f8:	83 ec 0c             	sub    $0xc,%esp
f01019fb:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01019fe:	50                   	push   %eax
f01019ff:	e8 9a 09 00 00       	call   f010239e <allocate_frame>
f0101a04:	83 c4 10             	add    $0x10,%esp
f0101a07:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101a0a:	74 19                	je     f0101a25 <page_check+0x794>
f0101a0c:	68 bc 57 10 f0       	push   $0xf01057bc
f0101a11:	68 f2 55 10 f0       	push   $0xf01055f2
f0101a16:	68 ea 00 00 00       	push   $0xea
f0101a1b:	68 81 55 10 f0       	push   $0xf0105581
f0101a20:	e8 09 e7 ff ff       	call   f010012e <_panic>

	// forcibly take pp0 back
	assert(EXTRACT_ADDRESS(ptr_page_directory[0]) == to_physical_address(pp0));
f0101a25:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101a2a:	8b 00                	mov    (%eax),%eax
f0101a2c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101a31:	89 c3                	mov    %eax,%ebx
f0101a33:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101a36:	83 ec 0c             	sub    $0xc,%esp
f0101a39:	50                   	push   %eax
f0101a3a:	e8 41 f4 ff ff       	call   f0100e80 <to_physical_address>
f0101a3f:	83 c4 10             	add    $0x10,%esp
f0101a42:	39 c3                	cmp    %eax,%ebx
f0101a44:	74 19                	je     f0101a5f <page_check+0x7ce>
f0101a46:	68 3c 58 10 f0       	push   $0xf010583c
f0101a4b:	68 f2 55 10 f0       	push   $0xf01055f2
f0101a50:	68 ed 00 00 00       	push   $0xed
f0101a55:	68 81 55 10 f0       	push   $0xf0105581
f0101a5a:	e8 cf e6 ff ff       	call   f010012e <_panic>
	ptr_page_directory[0] = 0;
f0101a5f:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101a64:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->references == 1);
f0101a6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101a6d:	8b 40 08             	mov    0x8(%eax),%eax
f0101a70:	66 83 f8 01          	cmp    $0x1,%ax
f0101a74:	74 19                	je     f0101a8f <page_check+0x7fe>
f0101a76:	68 d6 58 10 f0       	push   $0xf01058d6
f0101a7b:	68 f2 55 10 f0       	push   $0xf01055f2
f0101a80:	68 ef 00 00 00       	push   $0xef
f0101a85:	68 81 55 10 f0       	push   $0xf0105581
f0101a8a:	e8 9f e6 ff ff       	call   f010012e <_panic>
	pp0->references = 0;
f0101a8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101a92:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)

	// give free list back
	free_frame_list = fl;
f0101a98:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101a9b:	a3 b8 e7 14 f0       	mov    %eax,0xf014e7b8

	// free the frames_info we took
	free_frame(pp0);
f0101aa0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101aa3:	83 ec 0c             	sub    $0xc,%esp
f0101aa6:	50                   	push   %eax
f0101aa7:	e8 59 09 00 00       	call   f0102405 <free_frame>
f0101aac:	83 c4 10             	add    $0x10,%esp
	free_frame(pp1);
f0101aaf:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101ab2:	83 ec 0c             	sub    $0xc,%esp
f0101ab5:	50                   	push   %eax
f0101ab6:	e8 4a 09 00 00       	call   f0102405 <free_frame>
f0101abb:	83 c4 10             	add    $0x10,%esp
	free_frame(pp2);
f0101abe:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101ac1:	83 ec 0c             	sub    $0xc,%esp
f0101ac4:	50                   	push   %eax
f0101ac5:	e8 3b 09 00 00       	call   f0102405 <free_frame>
f0101aca:	83 c4 10             	add    $0x10,%esp

	cprintf("page_check() succeeded!\n");
f0101acd:	83 ec 0c             	sub    $0xc,%esp
f0101ad0:	68 7a 5b 10 f0       	push   $0xf0105b7a
f0101ad5:	e8 79 15 00 00       	call   f0103053 <cprintf>
f0101ada:	83 c4 10             	add    $0x10,%esp
}
f0101add:	90                   	nop
f0101ade:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101ae1:	c9                   	leave  
f0101ae2:	c3                   	ret    

f0101ae3 <turn_on_paging>:

void turn_on_paging()
{
f0101ae3:	55                   	push   %ebp
f0101ae4:	89 e5                	mov    %esp,%ebp
f0101ae6:	83 ec 20             	sub    $0x20,%esp
	// mapping, even though we are turning on paging and reconfiguring
	// segmentation.

	// Map VA 0:4MB same as VA (KERNEL_BASE), i.e. to PA 0:4MB.
	// (Limits our kernel to <4MB)
	ptr_page_directory[0] = ptr_page_directory[PDX(KERNEL_BASE)];
f0101ae9:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101aee:	8b 15 c4 e7 14 f0    	mov    0xf014e7c4,%edx
f0101af4:	8b 92 00 0f 00 00    	mov    0xf00(%edx),%edx
f0101afa:	89 10                	mov    %edx,(%eax)

	// Install page table.
	lcr3(phys_page_directory);
f0101afc:	a1 c8 e7 14 f0       	mov    0xf014e7c8,%eax
f0101b01:	89 45 fc             	mov    %eax,-0x4(%ebp)
}

static __inline void
lcr3(uint32 val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0101b04:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101b07:	0f 22 d8             	mov    %eax,%cr3

static __inline uint32
rcr0(void)
{
	uint32 val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0101b0a:	0f 20 c0             	mov    %cr0,%eax
f0101b0d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return val;
f0101b10:	8b 45 f4             	mov    -0xc(%ebp),%eax

	// Turn on paging.
	uint32 cr0;
	cr0 = rcr0();
f0101b13:	89 45 f8             	mov    %eax,-0x8(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_EM|CR0_MP;
f0101b16:	81 4d f8 2f 00 05 80 	orl    $0x8005002f,-0x8(%ebp)
	cr0 &= ~(CR0_TS|CR0_EM);
f0101b1d:	83 65 f8 f3          	andl   $0xfffffff3,-0x8(%ebp)
f0101b21:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101b24:	89 45 f0             	mov    %eax,-0x10(%ebp)
}

static __inline void
lcr0(uint32 val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0101b27:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101b2a:	0f 22 c0             	mov    %eax,%cr0

	// Current mapping: KERNEL_BASE+x => x => x.
	// (x < 4MB so uses paging ptr_page_directory[0])

	// Reload all segment registers.
	asm volatile("lgdt gdt_pd");
f0101b2d:	0f 01 15 70 b6 11 f0 	lgdtl  0xf011b670
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0101b34:	b8 23 00 00 00       	mov    $0x23,%eax
f0101b39:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0101b3b:	b8 23 00 00 00       	mov    $0x23,%eax
f0101b40:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0101b42:	b8 10 00 00 00       	mov    $0x10,%eax
f0101b47:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0101b49:	b8 10 00 00 00       	mov    $0x10,%eax
f0101b4e:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0101b50:	b8 10 00 00 00       	mov    $0x10,%eax
f0101b55:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));  // reload cs
f0101b57:	ea 5e 1b 10 f0 08 00 	ljmp   $0x8,$0xf0101b5e
	asm volatile("lldt %%ax" :: "a" (0));
f0101b5e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b63:	0f 00 d0             	lldt   %ax

	// Final mapping: KERNEL_BASE + x => KERNEL_BASE + x => x.

	// This mapping was only used after paging was turned on but
	// before the segment registers were reloaded.
	ptr_page_directory[0] = 0;
f0101b66:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101b6b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// Flush the TLB for good measure, to kill the ptr_page_directory[0] mapping.
	lcr3(phys_page_directory);
f0101b71:	a1 c8 e7 14 f0       	mov    0xf014e7c8,%eax
f0101b76:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

static __inline void
lcr3(uint32 val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0101b79:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101b7c:	0f 22 d8             	mov    %eax,%cr3
}
f0101b7f:	90                   	nop
f0101b80:	c9                   	leave  
f0101b81:	c3                   	ret    

f0101b82 <setup_listing_to_all_page_tables_entries>:

void setup_listing_to_all_page_tables_entries()
{
f0101b82:	55                   	push   %ebp
f0101b83:	89 e5                	mov    %esp,%ebp
f0101b85:	83 ec 18             	sub    $0x18,%esp
	//////////////////////////////////////////////////////////////////////
	// Recursively insert PD in itself as a page table, to form
	// a virtual page table at virtual address VPT.

	// Permissions: kernel RW, user NONE
	uint32 phys_frame_address = K_PHYSICAL_ADDRESS(ptr_page_directory);
f0101b88:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101b8d:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101b90:	81 7d f4 ff ff ff ef 	cmpl   $0xefffffff,-0xc(%ebp)
f0101b97:	77 17                	ja     f0101bb0 <setup_listing_to_all_page_tables_entries+0x2e>
f0101b99:	ff 75 f4             	pushl  -0xc(%ebp)
f0101b9c:	68 50 55 10 f0       	push   $0xf0105550
f0101ba1:	68 39 01 00 00       	push   $0x139
f0101ba6:	68 81 55 10 f0       	push   $0xf0105581
f0101bab:	e8 7e e5 ff ff       	call   f010012e <_panic>
f0101bb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101bb3:	05 00 00 00 10       	add    $0x10000000,%eax
f0101bb8:	89 45 f0             	mov    %eax,-0x10(%ebp)
	ptr_page_directory[PDX(VPT)] = CONSTRUCT_ENTRY(phys_frame_address , PERM_PRESENT | PERM_WRITEABLE);
f0101bbb:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101bc0:	05 fc 0e 00 00       	add    $0xefc,%eax
f0101bc5:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101bc8:	83 ca 03             	or     $0x3,%edx
f0101bcb:	89 10                	mov    %edx,(%eax)

	// same for UVPT
	//Permissions: kernel R, user R
	ptr_page_directory[PDX(UVPT)] = K_PHYSICAL_ADDRESS(ptr_page_directory)|PERM_USER|PERM_PRESENT;
f0101bcd:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101bd2:	8d 90 f4 0e 00 00    	lea    0xef4(%eax),%edx
f0101bd8:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101bdd:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101be0:	81 7d ec ff ff ff ef 	cmpl   $0xefffffff,-0x14(%ebp)
f0101be7:	77 17                	ja     f0101c00 <setup_listing_to_all_page_tables_entries+0x7e>
f0101be9:	ff 75 ec             	pushl  -0x14(%ebp)
f0101bec:	68 50 55 10 f0       	push   $0xf0105550
f0101bf1:	68 3e 01 00 00       	push   $0x13e
f0101bf6:	68 81 55 10 f0       	push   $0xf0105581
f0101bfb:	e8 2e e5 ff ff       	call   f010012e <_panic>
f0101c00:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101c03:	05 00 00 00 10       	add    $0x10000000,%eax
f0101c08:	83 c8 05             	or     $0x5,%eax
f0101c0b:	89 02                	mov    %eax,(%edx)

}
f0101c0d:	90                   	nop
f0101c0e:	c9                   	leave  
f0101c0f:	c3                   	ret    

f0101c10 <envid2env>:
//   0 on success, -E_BAD_ENV on error.
//   On success, sets *penv to the environment.
//   On error, sets *penv to NULL.
//
int envid2env(int32  envid, struct Env **env_store, bool checkperm)
{
f0101c10:	55                   	push   %ebp
f0101c11:	89 e5                	mov    %esp,%ebp
f0101c13:	83 ec 10             	sub    $0x10,%esp
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0101c16:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0101c1a:	75 15                	jne    f0101c31 <envid2env+0x21>
		*env_store = curenv;
f0101c1c:	8b 15 30 df 14 f0    	mov    0xf014df30,%edx
f0101c22:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c25:	89 10                	mov    %edx,(%eax)
		return 0;
f0101c27:	b8 00 00 00 00       	mov    $0x0,%eax
f0101c2c:	e9 8c 00 00 00       	jmp    f0101cbd <envid2env+0xad>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0101c31:	8b 15 2c df 14 f0    	mov    0xf014df2c,%edx
f0101c37:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c3a:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101c3f:	89 c1                	mov    %eax,%ecx
f0101c41:	89 c8                	mov    %ecx,%eax
f0101c43:	c1 e0 02             	shl    $0x2,%eax
f0101c46:	01 c8                	add    %ecx,%eax
f0101c48:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f0101c4f:	01 c8                	add    %ecx,%eax
f0101c51:	c1 e0 02             	shl    $0x2,%eax
f0101c54:	01 d0                	add    %edx,%eax
f0101c56:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0101c59:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101c5c:	8b 40 54             	mov    0x54(%eax),%eax
f0101c5f:	85 c0                	test   %eax,%eax
f0101c61:	74 0b                	je     f0101c6e <envid2env+0x5e>
f0101c63:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101c66:	8b 40 4c             	mov    0x4c(%eax),%eax
f0101c69:	3b 45 08             	cmp    0x8(%ebp),%eax
f0101c6c:	74 10                	je     f0101c7e <envid2env+0x6e>
		*env_store = 0;
f0101c6e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c71:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0101c77:	b8 02 00 00 00       	mov    $0x2,%eax
f0101c7c:	eb 3f                	jmp    f0101cbd <envid2env+0xad>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0101c7e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101c82:	74 2c                	je     f0101cb0 <envid2env+0xa0>
f0101c84:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f0101c89:	39 45 fc             	cmp    %eax,-0x4(%ebp)
f0101c8c:	74 22                	je     f0101cb0 <envid2env+0xa0>
f0101c8e:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101c91:	8b 50 50             	mov    0x50(%eax),%edx
f0101c94:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f0101c99:	8b 40 4c             	mov    0x4c(%eax),%eax
f0101c9c:	39 c2                	cmp    %eax,%edx
f0101c9e:	74 10                	je     f0101cb0 <envid2env+0xa0>
		*env_store = 0;
f0101ca0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101ca3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0101ca9:	b8 02 00 00 00       	mov    $0x2,%eax
f0101cae:	eb 0d                	jmp    f0101cbd <envid2env+0xad>
	}

	*env_store = e;
f0101cb0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101cb3:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0101cb6:	89 10                	mov    %edx,(%eax)
	return 0;
f0101cb8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101cbd:	c9                   	leave  
f0101cbe:	c3                   	ret    

f0101cbf <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f0101cbf:	55                   	push   %ebp
f0101cc0:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f0101cc2:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cc5:	8b 15 bc e7 14 f0    	mov    0xf014e7bc,%edx
f0101ccb:	29 d0                	sub    %edx,%eax
f0101ccd:	c1 f8 02             	sar    $0x2,%eax
f0101cd0:	89 c2                	mov    %eax,%edx
f0101cd2:	89 d0                	mov    %edx,%eax
f0101cd4:	c1 e0 02             	shl    $0x2,%eax
f0101cd7:	01 d0                	add    %edx,%eax
f0101cd9:	c1 e0 02             	shl    $0x2,%eax
f0101cdc:	01 d0                	add    %edx,%eax
f0101cde:	c1 e0 02             	shl    $0x2,%eax
f0101ce1:	01 d0                	add    %edx,%eax
f0101ce3:	89 c1                	mov    %eax,%ecx
f0101ce5:	c1 e1 08             	shl    $0x8,%ecx
f0101ce8:	01 c8                	add    %ecx,%eax
f0101cea:	89 c1                	mov    %eax,%ecx
f0101cec:	c1 e1 10             	shl    $0x10,%ecx
f0101cef:	01 c8                	add    %ecx,%eax
f0101cf1:	01 c0                	add    %eax,%eax
f0101cf3:	01 d0                	add    %edx,%eax
}
f0101cf5:	5d                   	pop    %ebp
f0101cf6:	c3                   	ret    

f0101cf7 <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f0101cf7:	55                   	push   %ebp
f0101cf8:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f0101cfa:	ff 75 08             	pushl  0x8(%ebp)
f0101cfd:	e8 bd ff ff ff       	call   f0101cbf <to_frame_number>
f0101d02:	83 c4 04             	add    $0x4,%esp
f0101d05:	c1 e0 0c             	shl    $0xc,%eax
}
f0101d08:	c9                   	leave  
f0101d09:	c3                   	ret    

f0101d0a <to_frame_info>:

static inline struct Frame_Info* to_frame_info(uint32 physical_address)
{
f0101d0a:	55                   	push   %ebp
f0101d0b:	89 e5                	mov    %esp,%ebp
f0101d0d:	83 ec 08             	sub    $0x8,%esp
	if (PPN(physical_address) >= number_of_frames)
f0101d10:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d13:	c1 e8 0c             	shr    $0xc,%eax
f0101d16:	89 c2                	mov    %eax,%edx
f0101d18:	a1 a8 e7 14 f0       	mov    0xf014e7a8,%eax
f0101d1d:	39 c2                	cmp    %eax,%edx
f0101d1f:	72 14                	jb     f0101d35 <to_frame_info+0x2b>
		panic("to_frame_info called with invalid pa");
f0101d21:	83 ec 04             	sub    $0x4,%esp
f0101d24:	68 94 5b 10 f0       	push   $0xf0105b94
f0101d29:	6a 39                	push   $0x39
f0101d2b:	68 b9 5b 10 f0       	push   $0xf0105bb9
f0101d30:	e8 f9 e3 ff ff       	call   f010012e <_panic>
	return &frames_info[PPN(physical_address)];
f0101d35:	8b 15 bc e7 14 f0    	mov    0xf014e7bc,%edx
f0101d3b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d3e:	c1 e8 0c             	shr    $0xc,%eax
f0101d41:	89 c1                	mov    %eax,%ecx
f0101d43:	89 c8                	mov    %ecx,%eax
f0101d45:	01 c0                	add    %eax,%eax
f0101d47:	01 c8                	add    %ecx,%eax
f0101d49:	c1 e0 02             	shl    $0x2,%eax
f0101d4c:	01 d0                	add    %edx,%eax
}
f0101d4e:	c9                   	leave  
f0101d4f:	c3                   	ret    

f0101d50 <initialize_kernel_VM>:
//
// From USER_TOP to USER_LIMIT, the user is allowed to read but not write.
// Above USER_LIMIT the user cannot read (or write).

void initialize_kernel_VM()
{
f0101d50:	55                   	push   %ebp
f0101d51:	89 e5                	mov    %esp,%ebp
f0101d53:	83 ec 28             	sub    $0x28,%esp
	//panic("initialize_kernel_VM: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.

	ptr_page_directory = boot_allocate_space(PAGE_SIZE, PAGE_SIZE);
f0101d56:	83 ec 08             	sub    $0x8,%esp
f0101d59:	68 00 10 00 00       	push   $0x1000
f0101d5e:	68 00 10 00 00       	push   $0x1000
f0101d63:	e8 ca 01 00 00       	call   f0101f32 <boot_allocate_space>
f0101d68:	83 c4 10             	add    $0x10,%esp
f0101d6b:	a3 c4 e7 14 f0       	mov    %eax,0xf014e7c4
	memset(ptr_page_directory, 0, PAGE_SIZE);
f0101d70:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101d75:	83 ec 04             	sub    $0x4,%esp
f0101d78:	68 00 10 00 00       	push   $0x1000
f0101d7d:	6a 00                	push   $0x0
f0101d7f:	50                   	push   %eax
f0101d80:	e8 b0 29 00 00       	call   f0104735 <memset>
f0101d85:	83 c4 10             	add    $0x10,%esp
	phys_page_directory = K_PHYSICAL_ADDRESS(ptr_page_directory);
f0101d88:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101d8d:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101d90:	81 7d f4 ff ff ff ef 	cmpl   $0xefffffff,-0xc(%ebp)
f0101d97:	77 14                	ja     f0101dad <initialize_kernel_VM+0x5d>
f0101d99:	ff 75 f4             	pushl  -0xc(%ebp)
f0101d9c:	68 d4 5b 10 f0       	push   $0xf0105bd4
f0101da1:	6a 3c                	push   $0x3c
f0101da3:	68 05 5c 10 f0       	push   $0xf0105c05
f0101da8:	e8 81 e3 ff ff       	call   f010012e <_panic>
f0101dad:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101db0:	05 00 00 00 10       	add    $0x10000000,%eax
f0101db5:	a3 c8 e7 14 f0       	mov    %eax,0xf014e7c8
	// Map the kernel stack with VA range :
	//  [KERNEL_STACK_TOP-KERNEL_STACK_SIZE, KERNEL_STACK_TOP), 
	// to physical address : "phys_stack_bottom".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_range(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE, KERNEL_STACK_SIZE, K_PHYSICAL_ADDRESS(ptr_stack_bottom), PERM_WRITEABLE) ;
f0101dba:	c7 45 f0 00 30 11 f0 	movl   $0xf0113000,-0x10(%ebp)
f0101dc1:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
f0101dc8:	77 14                	ja     f0101dde <initialize_kernel_VM+0x8e>
f0101dca:	ff 75 f0             	pushl  -0x10(%ebp)
f0101dcd:	68 d4 5b 10 f0       	push   $0xf0105bd4
f0101dd2:	6a 44                	push   $0x44
f0101dd4:	68 05 5c 10 f0       	push   $0xf0105c05
f0101dd9:	e8 50 e3 ff ff       	call   f010012e <_panic>
f0101dde:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101de1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101de7:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101dec:	83 ec 0c             	sub    $0xc,%esp
f0101def:	6a 02                	push   $0x2
f0101df1:	52                   	push   %edx
f0101df2:	68 00 80 00 00       	push   $0x8000
f0101df7:	68 00 80 bf ef       	push   $0xefbf8000
f0101dfc:	50                   	push   %eax
f0101dfd:	e8 92 01 00 00       	call   f0101f94 <boot_map_range>
f0101e02:	83 c4 20             	add    $0x20,%esp
	//      the PA range [0, 2^32 - KERNEL_BASE)
	// We might not have 2^32 - KERNEL_BASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here: 
	boot_map_range(ptr_page_directory, KERNEL_BASE, 0xFFFFFFFF - KERNEL_BASE, 0, PERM_WRITEABLE) ;
f0101e05:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101e0a:	83 ec 0c             	sub    $0xc,%esp
f0101e0d:	6a 02                	push   $0x2
f0101e0f:	6a 00                	push   $0x0
f0101e11:	68 ff ff ff 0f       	push   $0xfffffff
f0101e16:	68 00 00 00 f0       	push   $0xf0000000
f0101e1b:	50                   	push   %eax
f0101e1c:	e8 73 01 00 00       	call   f0101f94 <boot_map_range>
f0101e21:	83 c4 20             	add    $0x20,%esp
	// Permissions:
	//    - frames_info -- kernel RW, user NONE
	//    - the image mapped at READ_ONLY_FRAMES_INFO  -- kernel R, user R
	// Your code goes here:
	uint32 array_size;
	array_size = number_of_frames * sizeof(struct Frame_Info) ;
f0101e24:	8b 15 a8 e7 14 f0    	mov    0xf014e7a8,%edx
f0101e2a:	89 d0                	mov    %edx,%eax
f0101e2c:	01 c0                	add    %eax,%eax
f0101e2e:	01 d0                	add    %edx,%eax
f0101e30:	c1 e0 02             	shl    $0x2,%eax
f0101e33:	89 45 ec             	mov    %eax,-0x14(%ebp)
	frames_info = boot_allocate_space(array_size, PAGE_SIZE);
f0101e36:	83 ec 08             	sub    $0x8,%esp
f0101e39:	68 00 10 00 00       	push   $0x1000
f0101e3e:	ff 75 ec             	pushl  -0x14(%ebp)
f0101e41:	e8 ec 00 00 00       	call   f0101f32 <boot_allocate_space>
f0101e46:	83 c4 10             	add    $0x10,%esp
f0101e49:	a3 bc e7 14 f0       	mov    %eax,0xf014e7bc
	boot_map_range(ptr_page_directory, READ_ONLY_FRAMES_INFO, array_size, K_PHYSICAL_ADDRESS(frames_info), PERM_USER) ;
f0101e4e:	a1 bc e7 14 f0       	mov    0xf014e7bc,%eax
f0101e53:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0101e56:	81 7d e8 ff ff ff ef 	cmpl   $0xefffffff,-0x18(%ebp)
f0101e5d:	77 14                	ja     f0101e73 <initialize_kernel_VM+0x123>
f0101e5f:	ff 75 e8             	pushl  -0x18(%ebp)
f0101e62:	68 d4 5b 10 f0       	push   $0xf0105bd4
f0101e67:	6a 5f                	push   $0x5f
f0101e69:	68 05 5c 10 f0       	push   $0xf0105c05
f0101e6e:	e8 bb e2 ff ff       	call   f010012e <_panic>
f0101e73:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101e76:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101e7c:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101e81:	83 ec 0c             	sub    $0xc,%esp
f0101e84:	6a 04                	push   $0x4
f0101e86:	52                   	push   %edx
f0101e87:	ff 75 ec             	pushl  -0x14(%ebp)
f0101e8a:	68 00 00 00 ef       	push   $0xef000000
f0101e8f:	50                   	push   %eax
f0101e90:	e8 ff 00 00 00       	call   f0101f94 <boot_map_range>
f0101e95:	83 c4 20             	add    $0x20,%esp


	// This allows the kernel & user to access any page table entry using a
	// specified VA for each: VPT for kernel and UVPT for User.
	setup_listing_to_all_page_tables_entries();
f0101e98:	e8 e5 fc ff ff       	call   f0101b82 <setup_listing_to_all_page_tables_entries>
	// Permissions:
	//    - envs itself -- kernel RW, user NONE
	//    - the image of envs mapped at UENVS  -- kernel R, user R

	// LAB 3: Your code here.
	int envs_size = NENV * sizeof(struct Env) ;
f0101e9d:	c7 45 e4 00 90 01 00 	movl   $0x19000,-0x1c(%ebp)

	//allocate space for "envs" array aligned on 4KB boundary
	envs = boot_allocate_space(envs_size, PAGE_SIZE);
f0101ea4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101ea7:	83 ec 08             	sub    $0x8,%esp
f0101eaa:	68 00 10 00 00       	push   $0x1000
f0101eaf:	50                   	push   %eax
f0101eb0:	e8 7d 00 00 00       	call   f0101f32 <boot_allocate_space>
f0101eb5:	83 c4 10             	add    $0x10,%esp
f0101eb8:	a3 2c df 14 f0       	mov    %eax,0xf014df2c

	//make the user to access this array by mapping it to UPAGES linear address (UPAGES is in User/Kernel space)
	boot_map_range(ptr_page_directory, UENVS, envs_size, K_PHYSICAL_ADDRESS(envs), PERM_USER) ;
f0101ebd:	a1 2c df 14 f0       	mov    0xf014df2c,%eax
f0101ec2:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101ec5:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f0101ecc:	77 14                	ja     f0101ee2 <initialize_kernel_VM+0x192>
f0101ece:	ff 75 e0             	pushl  -0x20(%ebp)
f0101ed1:	68 d4 5b 10 f0       	push   $0xf0105bd4
f0101ed6:	6a 75                	push   $0x75
f0101ed8:	68 05 5c 10 f0       	push   $0xf0105c05
f0101edd:	e8 4c e2 ff ff       	call   f010012e <_panic>
f0101ee2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101ee5:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0101eeb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101eee:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101ef3:	83 ec 0c             	sub    $0xc,%esp
f0101ef6:	6a 04                	push   $0x4
f0101ef8:	51                   	push   %ecx
f0101ef9:	52                   	push   %edx
f0101efa:	68 00 00 c0 ee       	push   $0xeec00000
f0101eff:	50                   	push   %eax
f0101f00:	e8 8f 00 00 00       	call   f0101f94 <boot_map_range>
f0101f05:	83 c4 20             	add    $0x20,%esp

	//update permissions of the corresponding entry in page directory to make it USER with PERMISSION read only
	ptr_page_directory[PDX(UENVS)] = ptr_page_directory[PDX(UENVS)]|(PERM_USER|(PERM_PRESENT & (~PERM_WRITEABLE)));
f0101f08:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0101f0d:	05 ec 0e 00 00       	add    $0xeec,%eax
f0101f12:	8b 15 c4 e7 14 f0    	mov    0xf014e7c4,%edx
f0101f18:	81 c2 ec 0e 00 00    	add    $0xeec,%edx
f0101f1e:	8b 12                	mov    (%edx),%edx
f0101f20:	83 ca 05             	or     $0x5,%edx
f0101f23:	89 10                	mov    %edx,(%eax)


	// Check that the initial page directory has been set up correctly.
	check_boot_pgdir();
f0101f25:	e8 52 f0 ff ff       	call   f0100f7c <check_boot_pgdir>

	// NOW: Turn off the segmentation by setting the segments' base to 0, and
	// turn on the paging by setting the corresponding flags in control register 0 (cr0)
	turn_on_paging() ;
f0101f2a:	e8 b4 fb ff ff       	call   f0101ae3 <turn_on_paging>
}
f0101f2f:	90                   	nop
f0101f30:	c9                   	leave  
f0101f31:	c3                   	ret    

f0101f32 <boot_allocate_space>:
// It's too early to run out of memory.
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
// 
void* boot_allocate_space(uint32 size, uint32 align)
		{
f0101f32:	55                   	push   %ebp
f0101f33:	89 e5                	mov    %esp,%ebp
f0101f35:	83 ec 10             	sub    $0x10,%esp
	// Initialize ptr_free_mem if this is the first time.
	// 'end_of_kernel' is a symbol automatically generated by the linker,
	// which points to the end of the kernel-
	// i.e., the first virtual address that the linker
	// did not assign to any kernel code or global variables.
	if (ptr_free_mem == 0)
f0101f38:	a1 c0 e7 14 f0       	mov    0xf014e7c0,%eax
f0101f3d:	85 c0                	test   %eax,%eax
f0101f3f:	75 0a                	jne    f0101f4b <boot_allocate_space+0x19>
		ptr_free_mem = end_of_kernel;
f0101f41:	c7 05 c0 e7 14 f0 cc 	movl   $0xf014e7cc,0xf014e7c0
f0101f48:	e7 14 f0 

	// Your code here:
	//	Step 1: round ptr_free_mem up to be aligned properly
	ptr_free_mem = ROUNDUP(ptr_free_mem, PAGE_SIZE) ;
f0101f4b:	c7 45 fc 00 10 00 00 	movl   $0x1000,-0x4(%ebp)
f0101f52:	a1 c0 e7 14 f0       	mov    0xf014e7c0,%eax
f0101f57:	89 c2                	mov    %eax,%edx
f0101f59:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101f5c:	01 d0                	add    %edx,%eax
f0101f5e:	48                   	dec    %eax
f0101f5f:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0101f62:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101f65:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f6a:	f7 75 fc             	divl   -0x4(%ebp)
f0101f6d:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101f70:	29 d0                	sub    %edx,%eax
f0101f72:	a3 c0 e7 14 f0       	mov    %eax,0xf014e7c0

	//	Step 2: save current value of ptr_free_mem as allocated space
	void *ptr_allocated_mem;
	ptr_allocated_mem = ptr_free_mem ;
f0101f77:	a1 c0 e7 14 f0       	mov    0xf014e7c0,%eax
f0101f7c:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//	Step 3: increase ptr_free_mem to record allocation
	ptr_free_mem += size ;
f0101f7f:	8b 15 c0 e7 14 f0    	mov    0xf014e7c0,%edx
f0101f85:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f88:	01 d0                	add    %edx,%eax
f0101f8a:	a3 c0 e7 14 f0       	mov    %eax,0xf014e7c0

	//	Step 4: return allocated space
	return ptr_allocated_mem ;
f0101f8f:	8b 45 f4             	mov    -0xc(%ebp),%eax

		}
f0101f92:	c9                   	leave  
f0101f93:	c3                   	ret    

f0101f94 <boot_map_range>:
//
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
//
void boot_map_range(uint32 *ptr_page_directory, uint32 virtual_address, uint32 size, uint32 physical_address, int perm)
{
f0101f94:	55                   	push   %ebp
f0101f95:	89 e5                	mov    %esp,%ebp
f0101f97:	83 ec 28             	sub    $0x28,%esp
	int i = 0 ;
f0101f9a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	physical_address = ROUNDUP(physical_address, PAGE_SIZE) ;
f0101fa1:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f0101fa8:	8b 55 14             	mov    0x14(%ebp),%edx
f0101fab:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101fae:	01 d0                	add    %edx,%eax
f0101fb0:	48                   	dec    %eax
f0101fb1:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101fb4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101fb7:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fbc:	f7 75 f0             	divl   -0x10(%ebp)
f0101fbf:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101fc2:	29 d0                	sub    %edx,%eax
f0101fc4:	89 45 14             	mov    %eax,0x14(%ebp)
	for (i = 0 ; i < size ; i += PAGE_SIZE)
f0101fc7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0101fce:	eb 53                	jmp    f0102023 <boot_map_range+0x8f>
	{
		uint32 *ptr_page_table = boot_get_page_table(ptr_page_directory, virtual_address, 1) ;
f0101fd0:	83 ec 04             	sub    $0x4,%esp
f0101fd3:	6a 01                	push   $0x1
f0101fd5:	ff 75 0c             	pushl  0xc(%ebp)
f0101fd8:	ff 75 08             	pushl  0x8(%ebp)
f0101fdb:	e8 4e 00 00 00       	call   f010202e <boot_get_page_table>
f0101fe0:	83 c4 10             	add    $0x10,%esp
f0101fe3:	89 45 e8             	mov    %eax,-0x18(%ebp)
		uint32 index_page_table = PTX(virtual_address);
f0101fe6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101fe9:	c1 e8 0c             	shr    $0xc,%eax
f0101fec:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101ff1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		ptr_page_table[index_page_table] = CONSTRUCT_ENTRY(physical_address, perm | PERM_PRESENT) ;
f0101ff4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101ff7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101ffe:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102001:	01 c2                	add    %eax,%edx
f0102003:	8b 45 18             	mov    0x18(%ebp),%eax
f0102006:	0b 45 14             	or     0x14(%ebp),%eax
f0102009:	83 c8 01             	or     $0x1,%eax
f010200c:	89 02                	mov    %eax,(%edx)
		physical_address += PAGE_SIZE ;
f010200e:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
		virtual_address += PAGE_SIZE ;
f0102015:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
//
void boot_map_range(uint32 *ptr_page_directory, uint32 virtual_address, uint32 size, uint32 physical_address, int perm)
{
	int i = 0 ;
	physical_address = ROUNDUP(physical_address, PAGE_SIZE) ;
	for (i = 0 ; i < size ; i += PAGE_SIZE)
f010201c:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f0102023:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102026:	3b 45 10             	cmp    0x10(%ebp),%eax
f0102029:	72 a5                	jb     f0101fd0 <boot_map_range+0x3c>
		uint32 index_page_table = PTX(virtual_address);
		ptr_page_table[index_page_table] = CONSTRUCT_ENTRY(physical_address, perm | PERM_PRESENT) ;
		physical_address += PAGE_SIZE ;
		virtual_address += PAGE_SIZE ;
	}
}
f010202b:	90                   	nop
f010202c:	c9                   	leave  
f010202d:	c3                   	ret    

f010202e <boot_get_page_table>:
// boot_get_page_table cannot fail.  It's too early to fail.
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
//
uint32* boot_get_page_table(uint32 *ptr_page_directory, uint32 virtual_address, int create)
		{
f010202e:	55                   	push   %ebp
f010202f:	89 e5                	mov    %esp,%ebp
f0102031:	83 ec 28             	sub    $0x28,%esp
	uint32 index_page_directory = PDX(virtual_address);
f0102034:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102037:	c1 e8 16             	shr    $0x16,%eax
f010203a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32 page_directory_entry = ptr_page_directory[index_page_directory];
f010203d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102040:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102047:	8b 45 08             	mov    0x8(%ebp),%eax
f010204a:	01 d0                	add    %edx,%eax
f010204c:	8b 00                	mov    (%eax),%eax
f010204e:	89 45 f0             	mov    %eax,-0x10(%ebp)

	uint32 phys_page_table = EXTRACT_ADDRESS(page_directory_entry);
f0102051:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102054:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102059:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32 *ptr_page_table = K_VIRTUAL_ADDRESS(phys_page_table);
f010205c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010205f:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0102062:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102065:	c1 e8 0c             	shr    $0xc,%eax
f0102068:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010206b:	a1 a8 e7 14 f0       	mov    0xf014e7a8,%eax
f0102070:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0102073:	72 17                	jb     f010208c <boot_get_page_table+0x5e>
f0102075:	ff 75 e8             	pushl  -0x18(%ebp)
f0102078:	68 1c 5c 10 f0       	push   $0xf0105c1c
f010207d:	68 db 00 00 00       	push   $0xdb
f0102082:	68 05 5c 10 f0       	push   $0xf0105c05
f0102087:	e8 a2 e0 ff ff       	call   f010012e <_panic>
f010208c:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010208f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102094:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if (phys_page_table == 0)
f0102097:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f010209b:	75 72                	jne    f010210f <boot_get_page_table+0xe1>
	{
		if (create)
f010209d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01020a1:	74 65                	je     f0102108 <boot_get_page_table+0xda>
		{
			ptr_page_table = boot_allocate_space(PAGE_SIZE, PAGE_SIZE) ;
f01020a3:	83 ec 08             	sub    $0x8,%esp
f01020a6:	68 00 10 00 00       	push   $0x1000
f01020ab:	68 00 10 00 00       	push   $0x1000
f01020b0:	e8 7d fe ff ff       	call   f0101f32 <boot_allocate_space>
f01020b5:	83 c4 10             	add    $0x10,%esp
f01020b8:	89 45 e0             	mov    %eax,-0x20(%ebp)
			phys_page_table = K_PHYSICAL_ADDRESS(ptr_page_table);
f01020bb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01020be:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01020c1:	81 7d dc ff ff ff ef 	cmpl   $0xefffffff,-0x24(%ebp)
f01020c8:	77 17                	ja     f01020e1 <boot_get_page_table+0xb3>
f01020ca:	ff 75 dc             	pushl  -0x24(%ebp)
f01020cd:	68 d4 5b 10 f0       	push   $0xf0105bd4
f01020d2:	68 e1 00 00 00       	push   $0xe1
f01020d7:	68 05 5c 10 f0       	push   $0xf0105c05
f01020dc:	e8 4d e0 ff ff       	call   f010012e <_panic>
f01020e1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01020e4:	05 00 00 00 10       	add    $0x10000000,%eax
f01020e9:	89 45 ec             	mov    %eax,-0x14(%ebp)
			ptr_page_directory[index_page_directory] = CONSTRUCT_ENTRY(phys_page_table, PERM_PRESENT | PERM_WRITEABLE);
f01020ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01020ef:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01020f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01020f9:	01 d0                	add    %edx,%eax
f01020fb:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01020fe:	83 ca 03             	or     $0x3,%edx
f0102101:	89 10                	mov    %edx,(%eax)
			return ptr_page_table ;
f0102103:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102106:	eb 0a                	jmp    f0102112 <boot_get_page_table+0xe4>
		}
		else
			return 0 ;
f0102108:	b8 00 00 00 00       	mov    $0x0,%eax
f010210d:	eb 03                	jmp    f0102112 <boot_get_page_table+0xe4>
	}
	return ptr_page_table ;
f010210f:	8b 45 e0             	mov    -0x20(%ebp),%eax
		}
f0102112:	c9                   	leave  
f0102113:	c3                   	ret    

f0102114 <initialize_paging>:
// After this point, ONLY use the functions below
// to allocate and deallocate physical memory via the free_frame_list,
// and NEVER use boot_allocate_space() or the related boot-time functions above.
//
void initialize_paging()
{
f0102114:	55                   	push   %ebp
f0102115:	89 e5                	mov    %esp,%ebp
f0102117:	53                   	push   %ebx
f0102118:	83 ec 24             	sub    $0x24,%esp
	//     Some of it is in use, some is free. Where is the kernel?
	//     Which frames are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&free_frame_list);
f010211b:	c7 05 b8 e7 14 f0 00 	movl   $0x0,0xf014e7b8
f0102122:	00 00 00 

	frames_info[0].references = 1;
f0102125:	a1 bc e7 14 f0       	mov    0xf014e7bc,%eax
f010212a:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)

	int range_end = ROUNDUP(PHYS_IO_MEM,PAGE_SIZE);
f0102130:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f0102137:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010213a:	05 ff ff 09 00       	add    $0x9ffff,%eax
f010213f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102142:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102145:	ba 00 00 00 00       	mov    $0x0,%edx
f010214a:	f7 75 f0             	divl   -0x10(%ebp)
f010214d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102150:	29 d0                	sub    %edx,%eax
f0102152:	89 45 e8             	mov    %eax,-0x18(%ebp)

	for (i = 1; i < range_end/PAGE_SIZE; i++)
f0102155:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
f010215c:	e9 90 00 00 00       	jmp    f01021f1 <initialize_paging+0xdd>
	{
		frames_info[i].references = 0;
f0102161:	8b 0d bc e7 14 f0    	mov    0xf014e7bc,%ecx
f0102167:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010216a:	89 d0                	mov    %edx,%eax
f010216c:	01 c0                	add    %eax,%eax
f010216e:	01 d0                	add    %edx,%eax
f0102170:	c1 e0 02             	shl    $0x2,%eax
f0102173:	01 c8                	add    %ecx,%eax
f0102175:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
f010217b:	8b 0d bc e7 14 f0    	mov    0xf014e7bc,%ecx
f0102181:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102184:	89 d0                	mov    %edx,%eax
f0102186:	01 c0                	add    %eax,%eax
f0102188:	01 d0                	add    %edx,%eax
f010218a:	c1 e0 02             	shl    $0x2,%eax
f010218d:	01 c8                	add    %ecx,%eax
f010218f:	8b 15 b8 e7 14 f0    	mov    0xf014e7b8,%edx
f0102195:	89 10                	mov    %edx,(%eax)
f0102197:	8b 00                	mov    (%eax),%eax
f0102199:	85 c0                	test   %eax,%eax
f010219b:	74 1d                	je     f01021ba <initialize_paging+0xa6>
f010219d:	8b 15 b8 e7 14 f0    	mov    0xf014e7b8,%edx
f01021a3:	8b 1d bc e7 14 f0    	mov    0xf014e7bc,%ebx
f01021a9:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f01021ac:	89 c8                	mov    %ecx,%eax
f01021ae:	01 c0                	add    %eax,%eax
f01021b0:	01 c8                	add    %ecx,%eax
f01021b2:	c1 e0 02             	shl    $0x2,%eax
f01021b5:	01 d8                	add    %ebx,%eax
f01021b7:	89 42 04             	mov    %eax,0x4(%edx)
f01021ba:	8b 0d bc e7 14 f0    	mov    0xf014e7bc,%ecx
f01021c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01021c3:	89 d0                	mov    %edx,%eax
f01021c5:	01 c0                	add    %eax,%eax
f01021c7:	01 d0                	add    %edx,%eax
f01021c9:	c1 e0 02             	shl    $0x2,%eax
f01021cc:	01 c8                	add    %ecx,%eax
f01021ce:	a3 b8 e7 14 f0       	mov    %eax,0xf014e7b8
f01021d3:	8b 0d bc e7 14 f0    	mov    0xf014e7bc,%ecx
f01021d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01021dc:	89 d0                	mov    %edx,%eax
f01021de:	01 c0                	add    %eax,%eax
f01021e0:	01 d0                	add    %edx,%eax
f01021e2:	c1 e0 02             	shl    $0x2,%eax
f01021e5:	01 c8                	add    %ecx,%eax
f01021e7:	c7 40 04 b8 e7 14 f0 	movl   $0xf014e7b8,0x4(%eax)

	frames_info[0].references = 1;

	int range_end = ROUNDUP(PHYS_IO_MEM,PAGE_SIZE);

	for (i = 1; i < range_end/PAGE_SIZE; i++)
f01021ee:	ff 45 f4             	incl   -0xc(%ebp)
f01021f1:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01021f4:	85 c0                	test   %eax,%eax
f01021f6:	79 05                	jns    f01021fd <initialize_paging+0xe9>
f01021f8:	05 ff 0f 00 00       	add    $0xfff,%eax
f01021fd:	c1 f8 0c             	sar    $0xc,%eax
f0102200:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0102203:	0f 8f 58 ff ff ff    	jg     f0102161 <initialize_paging+0x4d>
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}

	for (i = PHYS_IO_MEM/PAGE_SIZE ; i < PHYS_EXTENDED_MEM/PAGE_SIZE; i++)
f0102209:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
f0102210:	eb 1d                	jmp    f010222f <initialize_paging+0x11b>
	{
		frames_info[i].references = 1;
f0102212:	8b 0d bc e7 14 f0    	mov    0xf014e7bc,%ecx
f0102218:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010221b:	89 d0                	mov    %edx,%eax
f010221d:	01 c0                	add    %eax,%eax
f010221f:	01 d0                	add    %edx,%eax
f0102221:	c1 e0 02             	shl    $0x2,%eax
f0102224:	01 c8                	add    %ecx,%eax
f0102226:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}

	for (i = PHYS_IO_MEM/PAGE_SIZE ; i < PHYS_EXTENDED_MEM/PAGE_SIZE; i++)
f010222c:	ff 45 f4             	incl   -0xc(%ebp)
f010222f:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
f0102236:	7e da                	jle    f0102212 <initialize_paging+0xfe>
	{
		frames_info[i].references = 1;
	}

	range_end = ROUNDUP(K_PHYSICAL_ADDRESS(ptr_free_mem), PAGE_SIZE);
f0102238:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
f010223f:	a1 c0 e7 14 f0       	mov    0xf014e7c0,%eax
f0102244:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102247:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f010224e:	77 17                	ja     f0102267 <initialize_paging+0x153>
f0102250:	ff 75 e0             	pushl  -0x20(%ebp)
f0102253:	68 d4 5b 10 f0       	push   $0xf0105bd4
f0102258:	68 1e 01 00 00       	push   $0x11e
f010225d:	68 05 5c 10 f0       	push   $0xf0105c05
f0102262:	e8 c7 de ff ff       	call   f010012e <_panic>
f0102267:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010226a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102270:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102273:	01 d0                	add    %edx,%eax
f0102275:	48                   	dec    %eax
f0102276:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102279:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010227c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102281:	f7 75 e4             	divl   -0x1c(%ebp)
f0102284:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102287:	29 d0                	sub    %edx,%eax
f0102289:	89 45 e8             	mov    %eax,-0x18(%ebp)

	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
f010228c:	c7 45 f4 00 01 00 00 	movl   $0x100,-0xc(%ebp)
f0102293:	eb 1d                	jmp    f01022b2 <initialize_paging+0x19e>
	{
		frames_info[i].references = 1;
f0102295:	8b 0d bc e7 14 f0    	mov    0xf014e7bc,%ecx
f010229b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010229e:	89 d0                	mov    %edx,%eax
f01022a0:	01 c0                	add    %eax,%eax
f01022a2:	01 d0                	add    %edx,%eax
f01022a4:	c1 e0 02             	shl    $0x2,%eax
f01022a7:	01 c8                	add    %ecx,%eax
f01022a9:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
		frames_info[i].references = 1;
	}

	range_end = ROUNDUP(K_PHYSICAL_ADDRESS(ptr_free_mem), PAGE_SIZE);

	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
f01022af:	ff 45 f4             	incl   -0xc(%ebp)
f01022b2:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01022b5:	85 c0                	test   %eax,%eax
f01022b7:	79 05                	jns    f01022be <initialize_paging+0x1aa>
f01022b9:	05 ff 0f 00 00       	add    $0xfff,%eax
f01022be:	c1 f8 0c             	sar    $0xc,%eax
f01022c1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f01022c4:	7f cf                	jg     f0102295 <initialize_paging+0x181>
	{
		frames_info[i].references = 1;
	}

	for (i = range_end/PAGE_SIZE ; i < number_of_frames; i++)
f01022c6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01022c9:	85 c0                	test   %eax,%eax
f01022cb:	79 05                	jns    f01022d2 <initialize_paging+0x1be>
f01022cd:	05 ff 0f 00 00       	add    $0xfff,%eax
f01022d2:	c1 f8 0c             	sar    $0xc,%eax
f01022d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01022d8:	e9 90 00 00 00       	jmp    f010236d <initialize_paging+0x259>
	{
		frames_info[i].references = 0;
f01022dd:	8b 0d bc e7 14 f0    	mov    0xf014e7bc,%ecx
f01022e3:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01022e6:	89 d0                	mov    %edx,%eax
f01022e8:	01 c0                	add    %eax,%eax
f01022ea:	01 d0                	add    %edx,%eax
f01022ec:	c1 e0 02             	shl    $0x2,%eax
f01022ef:	01 c8                	add    %ecx,%eax
f01022f1:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
f01022f7:	8b 0d bc e7 14 f0    	mov    0xf014e7bc,%ecx
f01022fd:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102300:	89 d0                	mov    %edx,%eax
f0102302:	01 c0                	add    %eax,%eax
f0102304:	01 d0                	add    %edx,%eax
f0102306:	c1 e0 02             	shl    $0x2,%eax
f0102309:	01 c8                	add    %ecx,%eax
f010230b:	8b 15 b8 e7 14 f0    	mov    0xf014e7b8,%edx
f0102311:	89 10                	mov    %edx,(%eax)
f0102313:	8b 00                	mov    (%eax),%eax
f0102315:	85 c0                	test   %eax,%eax
f0102317:	74 1d                	je     f0102336 <initialize_paging+0x222>
f0102319:	8b 15 b8 e7 14 f0    	mov    0xf014e7b8,%edx
f010231f:	8b 1d bc e7 14 f0    	mov    0xf014e7bc,%ebx
f0102325:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0102328:	89 c8                	mov    %ecx,%eax
f010232a:	01 c0                	add    %eax,%eax
f010232c:	01 c8                	add    %ecx,%eax
f010232e:	c1 e0 02             	shl    $0x2,%eax
f0102331:	01 d8                	add    %ebx,%eax
f0102333:	89 42 04             	mov    %eax,0x4(%edx)
f0102336:	8b 0d bc e7 14 f0    	mov    0xf014e7bc,%ecx
f010233c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010233f:	89 d0                	mov    %edx,%eax
f0102341:	01 c0                	add    %eax,%eax
f0102343:	01 d0                	add    %edx,%eax
f0102345:	c1 e0 02             	shl    $0x2,%eax
f0102348:	01 c8                	add    %ecx,%eax
f010234a:	a3 b8 e7 14 f0       	mov    %eax,0xf014e7b8
f010234f:	8b 0d bc e7 14 f0    	mov    0xf014e7bc,%ecx
f0102355:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102358:	89 d0                	mov    %edx,%eax
f010235a:	01 c0                	add    %eax,%eax
f010235c:	01 d0                	add    %edx,%eax
f010235e:	c1 e0 02             	shl    $0x2,%eax
f0102361:	01 c8                	add    %ecx,%eax
f0102363:	c7 40 04 b8 e7 14 f0 	movl   $0xf014e7b8,0x4(%eax)
	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
	{
		frames_info[i].references = 1;
	}

	for (i = range_end/PAGE_SIZE ; i < number_of_frames; i++)
f010236a:	ff 45 f4             	incl   -0xc(%ebp)
f010236d:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102370:	a1 a8 e7 14 f0       	mov    0xf014e7a8,%eax
f0102375:	39 c2                	cmp    %eax,%edx
f0102377:	0f 82 60 ff ff ff    	jb     f01022dd <initialize_paging+0x1c9>
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}
}
f010237d:	90                   	nop
f010237e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102381:	c9                   	leave  
f0102382:	c3                   	ret    

f0102383 <initialize_frame_info>:
// Initialize a Frame_Info structure.
// The result has null links and 0 references.
// Note that the corresponding physical frame is NOT initialized!
//
void initialize_frame_info(struct Frame_Info *ptr_frame_info)
{
f0102383:	55                   	push   %ebp
f0102384:	89 e5                	mov    %esp,%ebp
f0102386:	83 ec 08             	sub    $0x8,%esp
	memset(ptr_frame_info, 0, sizeof(*ptr_frame_info));
f0102389:	83 ec 04             	sub    $0x4,%esp
f010238c:	6a 0c                	push   $0xc
f010238e:	6a 00                	push   $0x0
f0102390:	ff 75 08             	pushl  0x8(%ebp)
f0102393:	e8 9d 23 00 00       	call   f0104735 <memset>
f0102398:	83 c4 10             	add    $0x10,%esp
}
f010239b:	90                   	nop
f010239c:	c9                   	leave  
f010239d:	c3                   	ret    

f010239e <allocate_frame>:
//   E_NO_MEM -- otherwise
//
// Hint: use LIST_FIRST, LIST_REMOVE, and initialize_frame_info
// Hint: references should not be incremented
int allocate_frame(struct Frame_Info **ptr_frame_info)
{
f010239e:	55                   	push   %ebp
f010239f:	89 e5                	mov    %esp,%ebp
f01023a1:	83 ec 08             	sub    $0x8,%esp
	// Fill this function in	
	*ptr_frame_info = LIST_FIRST(&free_frame_list);
f01023a4:	8b 15 b8 e7 14 f0    	mov    0xf014e7b8,%edx
f01023aa:	8b 45 08             	mov    0x8(%ebp),%eax
f01023ad:	89 10                	mov    %edx,(%eax)
	if(*ptr_frame_info == NULL)
f01023af:	8b 45 08             	mov    0x8(%ebp),%eax
f01023b2:	8b 00                	mov    (%eax),%eax
f01023b4:	85 c0                	test   %eax,%eax
f01023b6:	75 07                	jne    f01023bf <allocate_frame+0x21>
		return E_NO_MEM;
f01023b8:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01023bd:	eb 44                	jmp    f0102403 <allocate_frame+0x65>

	LIST_REMOVE(*ptr_frame_info);
f01023bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01023c2:	8b 00                	mov    (%eax),%eax
f01023c4:	8b 00                	mov    (%eax),%eax
f01023c6:	85 c0                	test   %eax,%eax
f01023c8:	74 12                	je     f01023dc <allocate_frame+0x3e>
f01023ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01023cd:	8b 00                	mov    (%eax),%eax
f01023cf:	8b 00                	mov    (%eax),%eax
f01023d1:	8b 55 08             	mov    0x8(%ebp),%edx
f01023d4:	8b 12                	mov    (%edx),%edx
f01023d6:	8b 52 04             	mov    0x4(%edx),%edx
f01023d9:	89 50 04             	mov    %edx,0x4(%eax)
f01023dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01023df:	8b 00                	mov    (%eax),%eax
f01023e1:	8b 40 04             	mov    0x4(%eax),%eax
f01023e4:	8b 55 08             	mov    0x8(%ebp),%edx
f01023e7:	8b 12                	mov    (%edx),%edx
f01023e9:	8b 12                	mov    (%edx),%edx
f01023eb:	89 10                	mov    %edx,(%eax)
	initialize_frame_info(*ptr_frame_info);
f01023ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01023f0:	8b 00                	mov    (%eax),%eax
f01023f2:	83 ec 0c             	sub    $0xc,%esp
f01023f5:	50                   	push   %eax
f01023f6:	e8 88 ff ff ff       	call   f0102383 <initialize_frame_info>
f01023fb:	83 c4 10             	add    $0x10,%esp
	return 0;
f01023fe:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102403:	c9                   	leave  
f0102404:	c3                   	ret    

f0102405 <free_frame>:
//
// Return a frame to the free_frame_list.
// (This function should only be called when ptr_frame_info->references reaches 0.)
//
void free_frame(struct Frame_Info *ptr_frame_info)
{
f0102405:	55                   	push   %ebp
f0102406:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	LIST_INSERT_HEAD(&free_frame_list, ptr_frame_info);
f0102408:	8b 15 b8 e7 14 f0    	mov    0xf014e7b8,%edx
f010240e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102411:	89 10                	mov    %edx,(%eax)
f0102413:	8b 45 08             	mov    0x8(%ebp),%eax
f0102416:	8b 00                	mov    (%eax),%eax
f0102418:	85 c0                	test   %eax,%eax
f010241a:	74 0b                	je     f0102427 <free_frame+0x22>
f010241c:	a1 b8 e7 14 f0       	mov    0xf014e7b8,%eax
f0102421:	8b 55 08             	mov    0x8(%ebp),%edx
f0102424:	89 50 04             	mov    %edx,0x4(%eax)
f0102427:	8b 45 08             	mov    0x8(%ebp),%eax
f010242a:	a3 b8 e7 14 f0       	mov    %eax,0xf014e7b8
f010242f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102432:	c7 40 04 b8 e7 14 f0 	movl   $0xf014e7b8,0x4(%eax)
}
f0102439:	90                   	nop
f010243a:	5d                   	pop    %ebp
f010243b:	c3                   	ret    

f010243c <decrement_references>:
//
// Decrement the reference count on a frame
// freeing it if there are no more references.
//
void decrement_references(struct Frame_Info* ptr_frame_info)
{
f010243c:	55                   	push   %ebp
f010243d:	89 e5                	mov    %esp,%ebp
	if (--(ptr_frame_info->references) == 0)
f010243f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102442:	8b 40 08             	mov    0x8(%eax),%eax
f0102445:	48                   	dec    %eax
f0102446:	8b 55 08             	mov    0x8(%ebp),%edx
f0102449:	66 89 42 08          	mov    %ax,0x8(%edx)
f010244d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102450:	8b 40 08             	mov    0x8(%eax),%eax
f0102453:	66 85 c0             	test   %ax,%ax
f0102456:	75 0b                	jne    f0102463 <decrement_references+0x27>
		free_frame(ptr_frame_info);
f0102458:	ff 75 08             	pushl  0x8(%ebp)
f010245b:	e8 a5 ff ff ff       	call   f0102405 <free_frame>
f0102460:	83 c4 04             	add    $0x4,%esp
}
f0102463:	90                   	nop
f0102464:	c9                   	leave  
f0102465:	c3                   	ret    

f0102466 <get_page_table>:
//
// Hint: you can use "to_physical_address()" to turn a Frame_Info*
// into the physical address of the frame it refers to. 

int get_page_table(uint32 *ptr_page_directory, const void *virtual_address, int create, uint32 **ptr_page_table)
{
f0102466:	55                   	push   %ebp
f0102467:	89 e5                	mov    %esp,%ebp
f0102469:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	uint32 page_directory_entry = ptr_page_directory[PDX(virtual_address)];
f010246c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010246f:	c1 e8 16             	shr    $0x16,%eax
f0102472:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102479:	8b 45 08             	mov    0x8(%ebp),%eax
f010247c:	01 d0                	add    %edx,%eax
f010247e:	8b 00                	mov    (%eax),%eax
f0102480:	89 45 f4             	mov    %eax,-0xc(%ebp)

	*ptr_page_table = K_VIRTUAL_ADDRESS(EXTRACT_ADDRESS(page_directory_entry)) ;
f0102483:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102486:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010248b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010248e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102491:	c1 e8 0c             	shr    $0xc,%eax
f0102494:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102497:	a1 a8 e7 14 f0       	mov    0xf014e7a8,%eax
f010249c:	39 45 ec             	cmp    %eax,-0x14(%ebp)
f010249f:	72 17                	jb     f01024b8 <get_page_table+0x52>
f01024a1:	ff 75 f0             	pushl  -0x10(%ebp)
f01024a4:	68 1c 5c 10 f0       	push   $0xf0105c1c
f01024a9:	68 79 01 00 00       	push   $0x179
f01024ae:	68 05 5c 10 f0       	push   $0xf0105c05
f01024b3:	e8 76 dc ff ff       	call   f010012e <_panic>
f01024b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01024bb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024c0:	89 c2                	mov    %eax,%edx
f01024c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01024c5:	89 10                	mov    %edx,(%eax)

	if (page_directory_entry == 0)
f01024c7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01024cb:	0f 85 d3 00 00 00    	jne    f01025a4 <get_page_table+0x13e>
	{
		if (create)
f01024d1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01024d5:	0f 84 b9 00 00 00    	je     f0102594 <get_page_table+0x12e>
		{
			struct Frame_Info* ptr_frame_info;
			int err = allocate_frame(&ptr_frame_info) ;
f01024db:	83 ec 0c             	sub    $0xc,%esp
f01024de:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01024e1:	50                   	push   %eax
f01024e2:	e8 b7 fe ff ff       	call   f010239e <allocate_frame>
f01024e7:	83 c4 10             	add    $0x10,%esp
f01024ea:	89 45 e8             	mov    %eax,-0x18(%ebp)
			if(err == E_NO_MEM)
f01024ed:	83 7d e8 fc          	cmpl   $0xfffffffc,-0x18(%ebp)
f01024f1:	75 13                	jne    f0102506 <get_page_table+0xa0>
			{
				*ptr_page_table = 0;
f01024f3:	8b 45 14             	mov    0x14(%ebp),%eax
f01024f6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
				return E_NO_MEM;
f01024fc:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0102501:	e9 a3 00 00 00       	jmp    f01025a9 <get_page_table+0x143>
			}

			uint32 phys_page_table = to_physical_address(ptr_frame_info);
f0102506:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102509:	83 ec 0c             	sub    $0xc,%esp
f010250c:	50                   	push   %eax
f010250d:	e8 e5 f7 ff ff       	call   f0101cf7 <to_physical_address>
f0102512:	83 c4 10             	add    $0x10,%esp
f0102515:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			*ptr_page_table = K_VIRTUAL_ADDRESS(phys_page_table) ;
f0102518:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010251b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010251e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102521:	c1 e8 0c             	shr    $0xc,%eax
f0102524:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102527:	a1 a8 e7 14 f0       	mov    0xf014e7a8,%eax
f010252c:	39 45 dc             	cmp    %eax,-0x24(%ebp)
f010252f:	72 17                	jb     f0102548 <get_page_table+0xe2>
f0102531:	ff 75 e0             	pushl  -0x20(%ebp)
f0102534:	68 1c 5c 10 f0       	push   $0xf0105c1c
f0102539:	68 88 01 00 00       	push   $0x188
f010253e:	68 05 5c 10 f0       	push   $0xf0105c05
f0102543:	e8 e6 db ff ff       	call   f010012e <_panic>
f0102548:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010254b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102550:	89 c2                	mov    %eax,%edx
f0102552:	8b 45 14             	mov    0x14(%ebp),%eax
f0102555:	89 10                	mov    %edx,(%eax)

			//initialize new page table by 0's
			memset(*ptr_page_table , 0, PAGE_SIZE);
f0102557:	8b 45 14             	mov    0x14(%ebp),%eax
f010255a:	8b 00                	mov    (%eax),%eax
f010255c:	83 ec 04             	sub    $0x4,%esp
f010255f:	68 00 10 00 00       	push   $0x1000
f0102564:	6a 00                	push   $0x0
f0102566:	50                   	push   %eax
f0102567:	e8 c9 21 00 00       	call   f0104735 <memset>
f010256c:	83 c4 10             	add    $0x10,%esp

			ptr_frame_info->references = 1;
f010256f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102572:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
			ptr_page_directory[PDX(virtual_address)] = CONSTRUCT_ENTRY(phys_page_table, PERM_PRESENT | PERM_USER | PERM_WRITEABLE);
f0102578:	8b 45 0c             	mov    0xc(%ebp),%eax
f010257b:	c1 e8 16             	shr    $0x16,%eax
f010257e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102585:	8b 45 08             	mov    0x8(%ebp),%eax
f0102588:	01 d0                	add    %edx,%eax
f010258a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010258d:	83 ca 07             	or     $0x7,%edx
f0102590:	89 10                	mov    %edx,(%eax)
f0102592:	eb 10                	jmp    f01025a4 <get_page_table+0x13e>
		}
		else
		{
			*ptr_page_table = 0;
f0102594:	8b 45 14             	mov    0x14(%ebp),%eax
f0102597:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			return 0;
f010259d:	b8 00 00 00 00       	mov    $0x0,%eax
f01025a2:	eb 05                	jmp    f01025a9 <get_page_table+0x143>
		}
	}	
	return 0;
f01025a4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01025a9:	c9                   	leave  
f01025aa:	c3                   	ret    

f01025ab <map_frame>:
//   E_NO_MEM, if page table couldn't be allocated
//
// Hint: implement using get_page_table() and unmap_frame().
//
int map_frame(uint32 *ptr_page_directory, struct Frame_Info *ptr_frame_info, void *virtual_address, int perm)
{
f01025ab:	55                   	push   %ebp
f01025ac:	89 e5                	mov    %esp,%ebp
f01025ae:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	uint32 physical_address = to_physical_address(ptr_frame_info);
f01025b1:	ff 75 0c             	pushl  0xc(%ebp)
f01025b4:	e8 3e f7 ff ff       	call   f0101cf7 <to_physical_address>
f01025b9:	83 c4 04             	add    $0x4,%esp
f01025bc:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32 *ptr_page_table;
	if( get_page_table(ptr_page_directory, virtual_address, 1, &ptr_page_table) == 0)
f01025bf:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01025c2:	50                   	push   %eax
f01025c3:	6a 01                	push   $0x1
f01025c5:	ff 75 10             	pushl  0x10(%ebp)
f01025c8:	ff 75 08             	pushl  0x8(%ebp)
f01025cb:	e8 96 fe ff ff       	call   f0102466 <get_page_table>
f01025d0:	83 c4 10             	add    $0x10,%esp
f01025d3:	85 c0                	test   %eax,%eax
f01025d5:	75 7c                	jne    f0102653 <map_frame+0xa8>
	{
		uint32 page_table_entry = ptr_page_table[PTX(virtual_address)];
f01025d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01025da:	8b 55 10             	mov    0x10(%ebp),%edx
f01025dd:	c1 ea 0c             	shr    $0xc,%edx
f01025e0:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01025e6:	c1 e2 02             	shl    $0x2,%edx
f01025e9:	01 d0                	add    %edx,%eax
f01025eb:	8b 00                	mov    (%eax),%eax
f01025ed:	89 45 f0             	mov    %eax,-0x10(%ebp)

		//If already mapped
		if ((page_table_entry & PERM_PRESENT) == PERM_PRESENT)
f01025f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01025f3:	83 e0 01             	and    $0x1,%eax
f01025f6:	85 c0                	test   %eax,%eax
f01025f8:	74 25                	je     f010261f <map_frame+0x74>
		{
			//on this pa, then do nothing
			if (EXTRACT_ADDRESS(page_table_entry) == physical_address)
f01025fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01025fd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102602:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0102605:	75 07                	jne    f010260e <map_frame+0x63>
				return 0;
f0102607:	b8 00 00 00 00       	mov    $0x0,%eax
f010260c:	eb 4a                	jmp    f0102658 <map_frame+0xad>
			//on another pa, then unmap it
			else
				unmap_frame(ptr_page_directory , virtual_address);
f010260e:	83 ec 08             	sub    $0x8,%esp
f0102611:	ff 75 10             	pushl  0x10(%ebp)
f0102614:	ff 75 08             	pushl  0x8(%ebp)
f0102617:	e8 ad 00 00 00       	call   f01026c9 <unmap_frame>
f010261c:	83 c4 10             	add    $0x10,%esp
		}
		ptr_frame_info->references++;
f010261f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102622:	8b 40 08             	mov    0x8(%eax),%eax
f0102625:	40                   	inc    %eax
f0102626:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102629:	66 89 42 08          	mov    %ax,0x8(%edx)
		ptr_page_table[PTX(virtual_address)] = CONSTRUCT_ENTRY(physical_address , perm | PERM_PRESENT);
f010262d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102630:	8b 55 10             	mov    0x10(%ebp),%edx
f0102633:	c1 ea 0c             	shr    $0xc,%edx
f0102636:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010263c:	c1 e2 02             	shl    $0x2,%edx
f010263f:	01 c2                	add    %eax,%edx
f0102641:	8b 45 14             	mov    0x14(%ebp),%eax
f0102644:	0b 45 f4             	or     -0xc(%ebp),%eax
f0102647:	83 c8 01             	or     $0x1,%eax
f010264a:	89 02                	mov    %eax,(%edx)

		return 0;
f010264c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102651:	eb 05                	jmp    f0102658 <map_frame+0xad>
	}	
	return E_NO_MEM;
f0102653:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f0102658:	c9                   	leave  
f0102659:	c3                   	ret    

f010265a <get_frame_info>:
// Return 0 if there is no frame mapped at virtual_address.
//
// Hint: implement using get_page_table() and get_frame_info().
//
struct Frame_Info * get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table)
		{
f010265a:	55                   	push   %ebp
f010265b:	89 e5                	mov    %esp,%ebp
f010265d:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in	
	uint32 ret =  get_page_table(ptr_page_directory, virtual_address, 0, ptr_page_table) ;
f0102660:	ff 75 10             	pushl  0x10(%ebp)
f0102663:	6a 00                	push   $0x0
f0102665:	ff 75 0c             	pushl  0xc(%ebp)
f0102668:	ff 75 08             	pushl  0x8(%ebp)
f010266b:	e8 f6 fd ff ff       	call   f0102466 <get_page_table>
f0102670:	83 c4 10             	add    $0x10,%esp
f0102673:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if((*ptr_page_table) != 0)
f0102676:	8b 45 10             	mov    0x10(%ebp),%eax
f0102679:	8b 00                	mov    (%eax),%eax
f010267b:	85 c0                	test   %eax,%eax
f010267d:	74 43                	je     f01026c2 <get_frame_info+0x68>
	{	
		uint32 index_page_table = PTX(virtual_address);
f010267f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102682:	c1 e8 0c             	shr    $0xc,%eax
f0102685:	25 ff 03 00 00       	and    $0x3ff,%eax
f010268a:	89 45 f0             	mov    %eax,-0x10(%ebp)
		uint32 page_table_entry = (*ptr_page_table)[index_page_table];
f010268d:	8b 45 10             	mov    0x10(%ebp),%eax
f0102690:	8b 00                	mov    (%eax),%eax
f0102692:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0102695:	c1 e2 02             	shl    $0x2,%edx
f0102698:	01 d0                	add    %edx,%eax
f010269a:	8b 00                	mov    (%eax),%eax
f010269c:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if( page_table_entry != 0)	
f010269f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01026a3:	74 16                	je     f01026bb <get_frame_info+0x61>
			return to_frame_info( EXTRACT_ADDRESS ( page_table_entry ) );
f01026a5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01026a8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01026ad:	83 ec 0c             	sub    $0xc,%esp
f01026b0:	50                   	push   %eax
f01026b1:	e8 54 f6 ff ff       	call   f0101d0a <to_frame_info>
f01026b6:	83 c4 10             	add    $0x10,%esp
f01026b9:	eb 0c                	jmp    f01026c7 <get_frame_info+0x6d>
		return 0;
f01026bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01026c0:	eb 05                	jmp    f01026c7 <get_frame_info+0x6d>
	}
	return 0;
f01026c2:	b8 00 00 00 00       	mov    $0x0,%eax
		}
f01026c7:	c9                   	leave  
f01026c8:	c3                   	ret    

f01026c9 <unmap_frame>:
//
// Hint: implement using get_frame_info(),
// 	tlb_invalidate(), and decrement_references().
//
void unmap_frame(uint32 *ptr_page_directory, void *virtual_address)
{
f01026c9:	55                   	push   %ebp
f01026ca:	89 e5                	mov    %esp,%ebp
f01026cc:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	uint32 *ptr_page_table;
	struct Frame_Info* ptr_frame_info = get_frame_info(ptr_page_directory, virtual_address, &ptr_page_table);
f01026cf:	83 ec 04             	sub    $0x4,%esp
f01026d2:	8d 45 f0             	lea    -0x10(%ebp),%eax
f01026d5:	50                   	push   %eax
f01026d6:	ff 75 0c             	pushl  0xc(%ebp)
f01026d9:	ff 75 08             	pushl  0x8(%ebp)
f01026dc:	e8 79 ff ff ff       	call   f010265a <get_frame_info>
f01026e1:	83 c4 10             	add    $0x10,%esp
f01026e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( ptr_frame_info != 0 )
f01026e7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01026eb:	74 39                	je     f0102726 <unmap_frame+0x5d>
	{
		decrement_references(ptr_frame_info);
f01026ed:	83 ec 0c             	sub    $0xc,%esp
f01026f0:	ff 75 f4             	pushl  -0xc(%ebp)
f01026f3:	e8 44 fd ff ff       	call   f010243c <decrement_references>
f01026f8:	83 c4 10             	add    $0x10,%esp
		ptr_page_table[PTX(virtual_address)] = 0;
f01026fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01026fe:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102701:	c1 ea 0c             	shr    $0xc,%edx
f0102704:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010270a:	c1 e2 02             	shl    $0x2,%edx
f010270d:	01 d0                	add    %edx,%eax
f010270f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate(ptr_page_directory, virtual_address);
f0102715:	83 ec 08             	sub    $0x8,%esp
f0102718:	ff 75 0c             	pushl  0xc(%ebp)
f010271b:	ff 75 08             	pushl  0x8(%ebp)
f010271e:	e8 59 eb ff ff       	call   f010127c <tlb_invalidate>
f0102723:	83 c4 10             	add    $0x10,%esp
	}	
}
f0102726:	90                   	nop
f0102727:	c9                   	leave  
f0102728:	c3                   	ret    

f0102729 <get_page>:
//		or to allocate any necessary page tables.
// 	HINT: 	remember to free the allocated frame if there is no space 
//		for the necessary page tables

int get_page(uint32* ptr_page_directory, void *virtual_address, int perm)
{
f0102729:	55                   	push   %ebp
f010272a:	89 e5                	mov    %esp,%ebp
f010272c:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("get_page function is not completed yet") ;
f010272f:	83 ec 04             	sub    $0x4,%esp
f0102732:	68 4c 5c 10 f0       	push   $0xf0105c4c
f0102737:	68 14 02 00 00       	push   $0x214
f010273c:	68 05 5c 10 f0       	push   $0xf0105c05
f0102741:	e8 e8 d9 ff ff       	call   f010012e <_panic>

f0102746 <calculate_required_frames>:
	return 0 ;
}

//[2] calculate_required_frames: 
uint32 calculate_required_frames(uint32* ptr_page_directory, uint32 start_virtual_address, uint32 size)
{
f0102746:	55                   	push   %ebp
f0102747:	89 e5                	mov    %esp,%ebp
f0102749:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("calculate_required_frames function is not completed yet") ;
f010274c:	83 ec 04             	sub    $0x4,%esp
f010274f:	68 74 5c 10 f0       	push   $0xf0105c74
f0102754:	68 2b 02 00 00       	push   $0x22b
f0102759:	68 05 5c 10 f0       	push   $0xf0105c05
f010275e:	e8 cb d9 ff ff       	call   f010012e <_panic>

f0102763 <calculate_free_frames>:


//[3] calculate_free_frames:

uint32 calculate_free_frames()
{
f0102763:	55                   	push   %ebp
f0102764:	89 e5                	mov    %esp,%ebp
f0102766:	83 ec 10             	sub    $0x10,%esp
	// PROJECT 2008: Your code here.
	//panic("calculate_free_frames function is not completed yet") ;

	//calculate the free frames from the free frame list
	struct Frame_Info *ptr;
	uint32 cnt = 0 ; 
f0102769:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	LIST_FOREACH(ptr, &free_frame_list)
f0102770:	a1 b8 e7 14 f0       	mov    0xf014e7b8,%eax
f0102775:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0102778:	eb 0b                	jmp    f0102785 <calculate_free_frames+0x22>
	{
		cnt++ ;
f010277a:	ff 45 f8             	incl   -0x8(%ebp)
	//panic("calculate_free_frames function is not completed yet") ;

	//calculate the free frames from the free frame list
	struct Frame_Info *ptr;
	uint32 cnt = 0 ; 
	LIST_FOREACH(ptr, &free_frame_list)
f010277d:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102780:	8b 00                	mov    (%eax),%eax
f0102782:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0102785:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0102789:	75 ef                	jne    f010277a <calculate_free_frames+0x17>
	{
		cnt++ ;
	}
	return cnt;
f010278b:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f010278e:	c9                   	leave  
f010278f:	c3                   	ret    

f0102790 <freeMem>:
//	Steps:
//		1) Unmap all mapped pages in the range [virtual_address, virtual_address + size ]
//		2) Free all mapped page tables in this range

void freeMem(uint32* ptr_page_directory, void *virtual_address, uint32 size)
{
f0102790:	55                   	push   %ebp
f0102791:	89 e5                	mov    %esp,%ebp
f0102793:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("freeMem function is not completed yet") ;
f0102796:	83 ec 04             	sub    $0x4,%esp
f0102799:	68 ac 5c 10 f0       	push   $0xf0105cac
f010279e:	68 52 02 00 00       	push   $0x252
f01027a3:	68 05 5c 10 f0       	push   $0xf0105c05
f01027a8:	e8 81 d9 ff ff       	call   f010012e <_panic>

f01027ad <allocate_environment>:
//
// Returns 0 on success, < 0 on failure.  Errors include:
//	E_NO_FREE_ENV if all NENVS environments are allocated
//
int allocate_environment(struct Env** e)
{	
f01027ad:	55                   	push   %ebp
f01027ae:	89 e5                	mov    %esp,%ebp
	if (!(*e = LIST_FIRST(&env_free_list)))
f01027b0:	8b 15 34 df 14 f0    	mov    0xf014df34,%edx
f01027b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01027b9:	89 10                	mov    %edx,(%eax)
f01027bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01027be:	8b 00                	mov    (%eax),%eax
f01027c0:	85 c0                	test   %eax,%eax
f01027c2:	75 07                	jne    f01027cb <allocate_environment+0x1e>
		return E_NO_FREE_ENV;
f01027c4:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01027c9:	eb 05                	jmp    f01027d0 <allocate_environment+0x23>
	return 0;
f01027cb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01027d0:	5d                   	pop    %ebp
f01027d1:	c3                   	ret    

f01027d2 <free_environment>:

// Free the given environment "e", simply by adding it to the free environment list.
void free_environment(struct Env* e)
{
f01027d2:	55                   	push   %ebp
f01027d3:	89 e5                	mov    %esp,%ebp
	curenv = NULL;	
f01027d5:	c7 05 30 df 14 f0 00 	movl   $0x0,0xf014df30
f01027dc:	00 00 00 
	// return the environment to the free list
	e->env_status = ENV_FREE;
f01027df:	8b 45 08             	mov    0x8(%ebp),%eax
f01027e2:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	LIST_INSERT_HEAD(&env_free_list, e);
f01027e9:	8b 15 34 df 14 f0    	mov    0xf014df34,%edx
f01027ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01027f2:	89 50 44             	mov    %edx,0x44(%eax)
f01027f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01027f8:	8b 40 44             	mov    0x44(%eax),%eax
f01027fb:	85 c0                	test   %eax,%eax
f01027fd:	74 0e                	je     f010280d <free_environment+0x3b>
f01027ff:	a1 34 df 14 f0       	mov    0xf014df34,%eax
f0102804:	8b 55 08             	mov    0x8(%ebp),%edx
f0102807:	83 c2 44             	add    $0x44,%edx
f010280a:	89 50 48             	mov    %edx,0x48(%eax)
f010280d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102810:	a3 34 df 14 f0       	mov    %eax,0xf014df34
f0102815:	8b 45 08             	mov    0x8(%ebp),%eax
f0102818:	c7 40 48 34 df 14 f0 	movl   $0xf014df34,0x48(%eax)
}
f010281f:	90                   	nop
f0102820:	5d                   	pop    %ebp
f0102821:	c3                   	ret    

f0102822 <program_segment_alloc_map>:
//
// if the allocation failed, return E_NO_MEM 
// otherwise return 0
//
static int program_segment_alloc_map(struct Env *e, void *va, uint32 length)
{
f0102822:	55                   	push   %ebp
f0102823:	89 e5                	mov    %esp,%ebp
f0102825:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB6 Hands-on: fill this function. 
	//Comment the following line
	panic("Function is not implemented yet!");
f0102828:	83 ec 04             	sub    $0x4,%esp
f010282b:	68 30 5d 10 f0       	push   $0xf0105d30
f0102830:	6a 7b                	push   $0x7b
f0102832:	68 51 5d 10 f0       	push   $0xf0105d51
f0102837:	e8 f2 d8 ff ff       	call   f010012e <_panic>

f010283c <env_create>:
}

//
// Allocates a new env and loads the named user program into it.
struct UserProgramInfo* env_create(char* user_program_name)
{
f010283c:	55                   	push   %ebp
f010283d:	89 e5                	mov    %esp,%ebp
f010283f:	83 ec 38             	sub    $0x38,%esp
	//[1] get pointer to the start of the "user_program_name" program in memory
	// Hint: use "get_user_program_info" function, 
	// you should set the following "ptr_program_start" by the start address of the user program 
	uint8* ptr_program_start = 0; 
f0102842:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	struct UserProgramInfo* ptr_user_program_info =get_user_program_info(user_program_name);
f0102849:	83 ec 0c             	sub    $0xc,%esp
f010284c:	ff 75 08             	pushl  0x8(%ebp)
f010284f:	e8 28 05 00 00       	call   f0102d7c <get_user_program_info>
f0102854:	83 c4 10             	add    $0x10,%esp
f0102857:	89 45 f0             	mov    %eax,-0x10(%ebp)

	if (ptr_user_program_info == 0)
f010285a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f010285e:	75 07                	jne    f0102867 <env_create+0x2b>
		return NULL ;
f0102860:	b8 00 00 00 00       	mov    $0x0,%eax
f0102865:	eb 42                	jmp    f01028a9 <env_create+0x6d>

	ptr_program_start = ptr_user_program_info->ptr_start ;
f0102867:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010286a:	8b 40 08             	mov    0x8(%eax),%eax
f010286d:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//[2] allocate new environment, (from the free environment list)
	//if there's no one, return NULL
	// Hint: use "allocate_environment" function
	struct Env* e = NULL;
f0102870:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	if(allocate_environment(&e) == E_NO_FREE_ENV)
f0102877:	83 ec 0c             	sub    $0xc,%esp
f010287a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010287d:	50                   	push   %eax
f010287e:	e8 2a ff ff ff       	call   f01027ad <allocate_environment>
f0102883:	83 c4 10             	add    $0x10,%esp
f0102886:	83 f8 fb             	cmp    $0xfffffffb,%eax
f0102889:	75 07                	jne    f0102892 <env_create+0x56>
	{
		return 0;
f010288b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102890:	eb 17                	jmp    f01028a9 <env_create+0x6d>
	}

	//=========================================================
	//TODO: LAB6 Hands-on: fill this part. 
	//Comment the following line
	panic("env_create: directory creation is not implemented yet!");
f0102892:	83 ec 04             	sub    $0x4,%esp
f0102895:	68 6c 5d 10 f0       	push   $0xf0105d6c
f010289a:	68 9f 00 00 00       	push   $0x9f
f010289f:	68 51 5d 10 f0       	push   $0xf0105d51
f01028a4:	e8 85 d8 ff ff       	call   f010012e <_panic>

	//[11] switch back to the page directory exists before segment loading
	lcr3(kern_phys_pgdir) ;

	return ptr_user_program_info;
}
f01028a9:	c9                   	leave  
f01028aa:	c3                   	ret    

f01028ab <env_run>:
// Used to run the given environment "e", simply by 
// context switch from curenv to env e.
//  (This function does not return.)
//
void env_run(struct Env *e)
{
f01028ab:	55                   	push   %ebp
f01028ac:	89 e5                	mov    %esp,%ebp
f01028ae:	83 ec 18             	sub    $0x18,%esp
	if(curenv != e)
f01028b1:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f01028b6:	3b 45 08             	cmp    0x8(%ebp),%eax
f01028b9:	74 25                	je     f01028e0 <env_run+0x35>
	{		
		curenv = e ;
f01028bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01028be:	a3 30 df 14 f0       	mov    %eax,0xf014df30
		curenv->env_runs++ ;
f01028c3:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f01028c8:	8b 50 58             	mov    0x58(%eax),%edx
f01028cb:	42                   	inc    %edx
f01028cc:	89 50 58             	mov    %edx,0x58(%eax)
		lcr3(curenv->env_cr3) ;	
f01028cf:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f01028d4:	8b 40 60             	mov    0x60(%eax),%eax
f01028d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01028da:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01028dd:	0f 22 d8             	mov    %eax,%cr3
	}	
	env_pop_tf(&(curenv->env_tf));
f01028e0:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f01028e5:	83 ec 0c             	sub    $0xc,%esp
f01028e8:	50                   	push   %eax
f01028e9:	e8 89 06 00 00       	call   f0102f77 <env_pop_tf>

f01028ee <env_free>:

//
// Frees environment "e" and all memory it uses.
// 
void env_free(struct Env *e)
{
f01028ee:	55                   	push   %ebp
f01028ef:	89 e5                	mov    %esp,%ebp
f01028f1:	83 ec 08             	sub    $0x8,%esp
	panic("env_free function is not completed yet") ;
f01028f4:	83 ec 04             	sub    $0x4,%esp
f01028f7:	68 a4 5d 10 f0       	push   $0xf0105da4
f01028fc:	68 2f 01 00 00       	push   $0x12f
f0102901:	68 51 5d 10 f0       	push   $0xf0105d51
f0102906:	e8 23 d8 ff ff       	call   f010012e <_panic>

f010290b <env_init>:
// Insert in reverse order, so that the first call to allocate_environment()
// returns envs[0].
//
void
env_init(void)
{	
f010290b:	55                   	push   %ebp
f010290c:	89 e5                	mov    %esp,%ebp
f010290e:	53                   	push   %ebx
f010290f:	83 ec 10             	sub    $0x10,%esp
	int iEnv = NENV-1;
f0102912:	c7 45 f8 ff 03 00 00 	movl   $0x3ff,-0x8(%ebp)
	for(; iEnv >= 0; iEnv--)
f0102919:	e9 ed 00 00 00       	jmp    f0102a0b <env_init+0x100>
	{
		envs[iEnv].env_status = ENV_FREE;
f010291e:	8b 0d 2c df 14 f0    	mov    0xf014df2c,%ecx
f0102924:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102927:	89 d0                	mov    %edx,%eax
f0102929:	c1 e0 02             	shl    $0x2,%eax
f010292c:	01 d0                	add    %edx,%eax
f010292e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102935:	01 d0                	add    %edx,%eax
f0102937:	c1 e0 02             	shl    $0x2,%eax
f010293a:	01 c8                	add    %ecx,%eax
f010293c:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[iEnv].env_id = 0;
f0102943:	8b 0d 2c df 14 f0    	mov    0xf014df2c,%ecx
f0102949:	8b 55 f8             	mov    -0x8(%ebp),%edx
f010294c:	89 d0                	mov    %edx,%eax
f010294e:	c1 e0 02             	shl    $0x2,%eax
f0102951:	01 d0                	add    %edx,%eax
f0102953:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010295a:	01 d0                	add    %edx,%eax
f010295c:	c1 e0 02             	shl    $0x2,%eax
f010295f:	01 c8                	add    %ecx,%eax
f0102961:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
		LIST_INSERT_HEAD(&env_free_list, &envs[iEnv]);	
f0102968:	8b 0d 2c df 14 f0    	mov    0xf014df2c,%ecx
f010296e:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102971:	89 d0                	mov    %edx,%eax
f0102973:	c1 e0 02             	shl    $0x2,%eax
f0102976:	01 d0                	add    %edx,%eax
f0102978:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010297f:	01 d0                	add    %edx,%eax
f0102981:	c1 e0 02             	shl    $0x2,%eax
f0102984:	01 c8                	add    %ecx,%eax
f0102986:	8b 15 34 df 14 f0    	mov    0xf014df34,%edx
f010298c:	89 50 44             	mov    %edx,0x44(%eax)
f010298f:	8b 40 44             	mov    0x44(%eax),%eax
f0102992:	85 c0                	test   %eax,%eax
f0102994:	74 2a                	je     f01029c0 <env_init+0xb5>
f0102996:	8b 15 34 df 14 f0    	mov    0xf014df34,%edx
f010299c:	8b 1d 2c df 14 f0    	mov    0xf014df2c,%ebx
f01029a2:	8b 4d f8             	mov    -0x8(%ebp),%ecx
f01029a5:	89 c8                	mov    %ecx,%eax
f01029a7:	c1 e0 02             	shl    $0x2,%eax
f01029aa:	01 c8                	add    %ecx,%eax
f01029ac:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f01029b3:	01 c8                	add    %ecx,%eax
f01029b5:	c1 e0 02             	shl    $0x2,%eax
f01029b8:	01 d8                	add    %ebx,%eax
f01029ba:	83 c0 44             	add    $0x44,%eax
f01029bd:	89 42 48             	mov    %eax,0x48(%edx)
f01029c0:	8b 0d 2c df 14 f0    	mov    0xf014df2c,%ecx
f01029c6:	8b 55 f8             	mov    -0x8(%ebp),%edx
f01029c9:	89 d0                	mov    %edx,%eax
f01029cb:	c1 e0 02             	shl    $0x2,%eax
f01029ce:	01 d0                	add    %edx,%eax
f01029d0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01029d7:	01 d0                	add    %edx,%eax
f01029d9:	c1 e0 02             	shl    $0x2,%eax
f01029dc:	01 c8                	add    %ecx,%eax
f01029de:	a3 34 df 14 f0       	mov    %eax,0xf014df34
f01029e3:	8b 0d 2c df 14 f0    	mov    0xf014df2c,%ecx
f01029e9:	8b 55 f8             	mov    -0x8(%ebp),%edx
f01029ec:	89 d0                	mov    %edx,%eax
f01029ee:	c1 e0 02             	shl    $0x2,%eax
f01029f1:	01 d0                	add    %edx,%eax
f01029f3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01029fa:	01 d0                	add    %edx,%eax
f01029fc:	c1 e0 02             	shl    $0x2,%eax
f01029ff:	01 c8                	add    %ecx,%eax
f0102a01:	c7 40 48 34 df 14 f0 	movl   $0xf014df34,0x48(%eax)
//
void
env_init(void)
{	
	int iEnv = NENV-1;
	for(; iEnv >= 0; iEnv--)
f0102a08:	ff 4d f8             	decl   -0x8(%ebp)
f0102a0b:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f0102a0f:	0f 89 09 ff ff ff    	jns    f010291e <env_init+0x13>
	{
		envs[iEnv].env_status = ENV_FREE;
		envs[iEnv].env_id = 0;
		LIST_INSERT_HEAD(&env_free_list, &envs[iEnv]);	
	}
}
f0102a15:	90                   	nop
f0102a16:	83 c4 10             	add    $0x10,%esp
f0102a19:	5b                   	pop    %ebx
f0102a1a:	5d                   	pop    %ebp
f0102a1b:	c3                   	ret    

f0102a1c <complete_environment_initialization>:

void complete_environment_initialization(struct Env* e)
{	
f0102a1c:	55                   	push   %ebp
f0102a1d:	89 e5                	mov    %esp,%ebp
f0102a1f:	83 ec 18             	sub    $0x18,%esp
	//VPT and UVPT map the env's own page table, with
	//different permissions.
	e->env_pgdir[PDX(VPT)]  = e->env_cr3 | PERM_PRESENT | PERM_WRITEABLE;
f0102a22:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a25:	8b 40 5c             	mov    0x5c(%eax),%eax
f0102a28:	8d 90 fc 0e 00 00    	lea    0xefc(%eax),%edx
f0102a2e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a31:	8b 40 60             	mov    0x60(%eax),%eax
f0102a34:	83 c8 03             	or     $0x3,%eax
f0102a37:	89 02                	mov    %eax,(%edx)
	e->env_pgdir[PDX(UVPT)] = e->env_cr3 | PERM_PRESENT | PERM_USER;
f0102a39:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a3c:	8b 40 5c             	mov    0x5c(%eax),%eax
f0102a3f:	8d 90 f4 0e 00 00    	lea    0xef4(%eax),%edx
f0102a45:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a48:	8b 40 60             	mov    0x60(%eax),%eax
f0102a4b:	83 c8 05             	or     $0x5,%eax
f0102a4e:	89 02                	mov    %eax,(%edx)

	int32 generation;	
	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102a50:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a53:	8b 40 4c             	mov    0x4c(%eax),%eax
f0102a56:	05 00 10 00 00       	add    $0x1000,%eax
f0102a5b:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0102a60:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (generation <= 0)	// Don't create a negative env_id.
f0102a63:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0102a67:	7f 07                	jg     f0102a70 <complete_environment_initialization+0x54>
		generation = 1 << ENVGENSHIFT;
f0102a69:	c7 45 f4 00 10 00 00 	movl   $0x1000,-0xc(%ebp)
	e->env_id = generation | (e - envs);
f0102a70:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a73:	8b 15 2c df 14 f0    	mov    0xf014df2c,%edx
f0102a79:	29 d0                	sub    %edx,%eax
f0102a7b:	c1 f8 02             	sar    $0x2,%eax
f0102a7e:	89 c1                	mov    %eax,%ecx
f0102a80:	89 c8                	mov    %ecx,%eax
f0102a82:	c1 e0 02             	shl    $0x2,%eax
f0102a85:	01 c8                	add    %ecx,%eax
f0102a87:	c1 e0 07             	shl    $0x7,%eax
f0102a8a:	29 c8                	sub    %ecx,%eax
f0102a8c:	c1 e0 03             	shl    $0x3,%eax
f0102a8f:	01 c8                	add    %ecx,%eax
f0102a91:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102a98:	01 d0                	add    %edx,%eax
f0102a9a:	c1 e0 02             	shl    $0x2,%eax
f0102a9d:	01 c8                	add    %ecx,%eax
f0102a9f:	c1 e0 03             	shl    $0x3,%eax
f0102aa2:	01 c8                	add    %ecx,%eax
f0102aa4:	89 c2                	mov    %eax,%edx
f0102aa6:	c1 e2 06             	shl    $0x6,%edx
f0102aa9:	29 c2                	sub    %eax,%edx
f0102aab:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0102aae:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f0102ab1:	8d 04 95 00 00 00 00 	lea    0x0(,%edx,4),%eax
f0102ab8:	01 c2                	add    %eax,%edx
f0102aba:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0102abd:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f0102ac0:	89 d0                	mov    %edx,%eax
f0102ac2:	f7 d8                	neg    %eax
f0102ac4:	0b 45 f4             	or     -0xc(%ebp),%eax
f0102ac7:	89 c2                	mov    %eax,%edx
f0102ac9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102acc:	89 50 4c             	mov    %edx,0x4c(%eax)

	// Set the basic status variables.
	e->env_parent_id = 0;//parent_id;
f0102acf:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ad2:	c7 40 50 00 00 00 00 	movl   $0x0,0x50(%eax)
	e->env_status = ENV_RUNNABLE;
f0102ad9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102adc:	c7 40 54 01 00 00 00 	movl   $0x1,0x54(%eax)
	e->env_runs = 0;
f0102ae3:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ae6:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102aed:	8b 45 08             	mov    0x8(%ebp),%eax
f0102af0:	83 ec 04             	sub    $0x4,%esp
f0102af3:	6a 44                	push   $0x44
f0102af5:	6a 00                	push   $0x0
f0102af7:	50                   	push   %eax
f0102af8:	e8 38 1c 00 00       	call   f0104735 <memset>
f0102afd:	83 c4 10             	add    $0x10,%esp
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.

	e->env_tf.tf_ds = GD_UD | 3;
f0102b00:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b03:	66 c7 40 24 23 00    	movw   $0x23,0x24(%eax)
	e->env_tf.tf_es = GD_UD | 3;
f0102b09:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b0c:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
	e->env_tf.tf_ss = GD_UD | 3;
f0102b12:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b15:	66 c7 40 40 23 00    	movw   $0x23,0x40(%eax)
	e->env_tf.tf_esp = (uint32*)USTACKTOP;
f0102b1b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b1e:	c7 40 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%eax)
	e->env_tf.tf_cs = GD_UT | 3;
f0102b25:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b28:	66 c7 40 34 1b 00    	movw   $0x1b,0x34(%eax)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	LIST_REMOVE(e);	
f0102b2e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b31:	8b 40 44             	mov    0x44(%eax),%eax
f0102b34:	85 c0                	test   %eax,%eax
f0102b36:	74 0f                	je     f0102b47 <complete_environment_initialization+0x12b>
f0102b38:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b3b:	8b 40 44             	mov    0x44(%eax),%eax
f0102b3e:	8b 55 08             	mov    0x8(%ebp),%edx
f0102b41:	8b 52 48             	mov    0x48(%edx),%edx
f0102b44:	89 50 48             	mov    %edx,0x48(%eax)
f0102b47:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b4a:	8b 40 48             	mov    0x48(%eax),%eax
f0102b4d:	8b 55 08             	mov    0x8(%ebp),%edx
f0102b50:	8b 52 44             	mov    0x44(%edx),%edx
f0102b53:	89 10                	mov    %edx,(%eax)
	return ;
f0102b55:	90                   	nop
}
f0102b56:	c9                   	leave  
f0102b57:	c3                   	ret    

f0102b58 <PROGRAM_SEGMENT_NEXT>:

struct ProgramSegment* PROGRAM_SEGMENT_NEXT(struct ProgramSegment* seg, uint8* ptr_program_start)
				{
f0102b58:	55                   	push   %ebp
f0102b59:	89 e5                	mov    %esp,%ebp
f0102b5b:	83 ec 18             	sub    $0x18,%esp
	int index = (*seg).segment_id++;
f0102b5e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b61:	8b 40 10             	mov    0x10(%eax),%eax
f0102b64:	8d 48 01             	lea    0x1(%eax),%ecx
f0102b67:	8b 55 08             	mov    0x8(%ebp),%edx
f0102b6a:	89 4a 10             	mov    %ecx,0x10(%edx)
f0102b6d:	89 45 f4             	mov    %eax,-0xc(%ebp)

	struct Proghdr *ph, *eph; 
	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f0102b70:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b73:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f0102b76:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102b79:	8b 00                	mov    (%eax),%eax
f0102b7b:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f0102b80:	74 17                	je     f0102b99 <PROGRAM_SEGMENT_NEXT+0x41>
		panic("Matafa2nash 3ala Keda"); 
f0102b82:	83 ec 04             	sub    $0x4,%esp
f0102b85:	68 cb 5d 10 f0       	push   $0xf0105dcb
f0102b8a:	68 88 01 00 00       	push   $0x188
f0102b8f:	68 51 5d 10 f0       	push   $0xf0105d51
f0102b94:	e8 95 d5 ff ff       	call   f010012e <_panic>
	ph = (struct Proghdr *) ( ((uint8 *) ptr_program_start) + pELFHDR->e_phoff);
f0102b99:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102b9c:	8b 50 1c             	mov    0x1c(%eax),%edx
f0102b9f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ba2:	01 d0                	add    %edx,%eax
f0102ba4:	89 45 ec             	mov    %eax,-0x14(%ebp)

	while (ph[(*seg).segment_id].p_type != ELF_PROG_LOAD && ((*seg).segment_id < pELFHDR->e_phnum)) (*seg).segment_id++;	
f0102ba7:	eb 0f                	jmp    f0102bb8 <PROGRAM_SEGMENT_NEXT+0x60>
f0102ba9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bac:	8b 40 10             	mov    0x10(%eax),%eax
f0102baf:	8d 50 01             	lea    0x1(%eax),%edx
f0102bb2:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bb5:	89 50 10             	mov    %edx,0x10(%eax)
f0102bb8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bbb:	8b 40 10             	mov    0x10(%eax),%eax
f0102bbe:	c1 e0 05             	shl    $0x5,%eax
f0102bc1:	89 c2                	mov    %eax,%edx
f0102bc3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102bc6:	01 d0                	add    %edx,%eax
f0102bc8:	8b 00                	mov    (%eax),%eax
f0102bca:	83 f8 01             	cmp    $0x1,%eax
f0102bcd:	74 13                	je     f0102be2 <PROGRAM_SEGMENT_NEXT+0x8a>
f0102bcf:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bd2:	8b 50 10             	mov    0x10(%eax),%edx
f0102bd5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102bd8:	8b 40 2c             	mov    0x2c(%eax),%eax
f0102bdb:	0f b7 c0             	movzwl %ax,%eax
f0102bde:	39 c2                	cmp    %eax,%edx
f0102be0:	72 c7                	jb     f0102ba9 <PROGRAM_SEGMENT_NEXT+0x51>
	index = (*seg).segment_id;
f0102be2:	8b 45 08             	mov    0x8(%ebp),%eax
f0102be5:	8b 40 10             	mov    0x10(%eax),%eax
f0102be8:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(index < pELFHDR->e_phnum)
f0102beb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102bee:	8b 40 2c             	mov    0x2c(%eax),%eax
f0102bf1:	0f b7 c0             	movzwl %ax,%eax
f0102bf4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0102bf7:	7e 63                	jle    f0102c5c <PROGRAM_SEGMENT_NEXT+0x104>
	{
		(*seg).ptr_start = (uint8 *) ptr_program_start + ph[index].p_offset;
f0102bf9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102bfc:	c1 e0 05             	shl    $0x5,%eax
f0102bff:	89 c2                	mov    %eax,%edx
f0102c01:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102c04:	01 d0                	add    %edx,%eax
f0102c06:	8b 50 04             	mov    0x4(%eax),%edx
f0102c09:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c0c:	01 c2                	add    %eax,%edx
f0102c0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c11:	89 10                	mov    %edx,(%eax)
		(*seg).size_in_memory =  ph[index].p_memsz;
f0102c13:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102c16:	c1 e0 05             	shl    $0x5,%eax
f0102c19:	89 c2                	mov    %eax,%edx
f0102c1b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102c1e:	01 d0                	add    %edx,%eax
f0102c20:	8b 50 14             	mov    0x14(%eax),%edx
f0102c23:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c26:	89 50 08             	mov    %edx,0x8(%eax)
		(*seg).size_in_file = ph[index].p_filesz;
f0102c29:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102c2c:	c1 e0 05             	shl    $0x5,%eax
f0102c2f:	89 c2                	mov    %eax,%edx
f0102c31:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102c34:	01 d0                	add    %edx,%eax
f0102c36:	8b 50 10             	mov    0x10(%eax),%edx
f0102c39:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c3c:	89 50 04             	mov    %edx,0x4(%eax)
		(*seg).virtual_address = (uint8*)ph[index].p_va;
f0102c3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102c42:	c1 e0 05             	shl    $0x5,%eax
f0102c45:	89 c2                	mov    %eax,%edx
f0102c47:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102c4a:	01 d0                	add    %edx,%eax
f0102c4c:	8b 40 08             	mov    0x8(%eax),%eax
f0102c4f:	89 c2                	mov    %eax,%edx
f0102c51:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c54:	89 50 0c             	mov    %edx,0xc(%eax)
		return seg;
f0102c57:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c5a:	eb 05                	jmp    f0102c61 <PROGRAM_SEGMENT_NEXT+0x109>
	}
	return 0;
f0102c5c:	b8 00 00 00 00       	mov    $0x0,%eax
				}
f0102c61:	c9                   	leave  
f0102c62:	c3                   	ret    

f0102c63 <PROGRAM_SEGMENT_FIRST>:

struct ProgramSegment PROGRAM_SEGMENT_FIRST( uint8* ptr_program_start)
{
f0102c63:	55                   	push   %ebp
f0102c64:	89 e5                	mov    %esp,%ebp
f0102c66:	57                   	push   %edi
f0102c67:	56                   	push   %esi
f0102c68:	53                   	push   %ebx
f0102c69:	83 ec 2c             	sub    $0x2c,%esp
	struct ProgramSegment seg;
	seg.segment_id = 0;
f0102c6c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

	struct Proghdr *ph, *eph; 
	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f0102c73:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c76:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f0102c79:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c7c:	8b 00                	mov    (%eax),%eax
f0102c7e:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f0102c83:	74 17                	je     f0102c9c <PROGRAM_SEGMENT_FIRST+0x39>
		panic("Matafa2nash 3ala Keda"); 
f0102c85:	83 ec 04             	sub    $0x4,%esp
f0102c88:	68 cb 5d 10 f0       	push   $0xf0105dcb
f0102c8d:	68 a1 01 00 00       	push   $0x1a1
f0102c92:	68 51 5d 10 f0       	push   $0xf0105d51
f0102c97:	e8 92 d4 ff ff       	call   f010012e <_panic>
	ph = (struct Proghdr *) ( ((uint8 *) ptr_program_start) + pELFHDR->e_phoff);
f0102c9c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c9f:	8b 50 1c             	mov    0x1c(%eax),%edx
f0102ca2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ca5:	01 d0                	add    %edx,%eax
f0102ca7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	while (ph[(seg).segment_id].p_type != ELF_PROG_LOAD && ((seg).segment_id < pELFHDR->e_phnum)) (seg).segment_id++;
f0102caa:	eb 07                	jmp    f0102cb3 <PROGRAM_SEGMENT_FIRST+0x50>
f0102cac:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102caf:	40                   	inc    %eax
f0102cb0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102cb3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102cb6:	c1 e0 05             	shl    $0x5,%eax
f0102cb9:	89 c2                	mov    %eax,%edx
f0102cbb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102cbe:	01 d0                	add    %edx,%eax
f0102cc0:	8b 00                	mov    (%eax),%eax
f0102cc2:	83 f8 01             	cmp    $0x1,%eax
f0102cc5:	74 10                	je     f0102cd7 <PROGRAM_SEGMENT_FIRST+0x74>
f0102cc7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102cca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ccd:	8b 40 2c             	mov    0x2c(%eax),%eax
f0102cd0:	0f b7 c0             	movzwl %ax,%eax
f0102cd3:	39 c2                	cmp    %eax,%edx
f0102cd5:	72 d5                	jb     f0102cac <PROGRAM_SEGMENT_FIRST+0x49>
	int index = (seg).segment_id;
f0102cd7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102cda:	89 45 dc             	mov    %eax,-0x24(%ebp)

	if(index < pELFHDR->e_phnum)
f0102cdd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ce0:	8b 40 2c             	mov    0x2c(%eax),%eax
f0102ce3:	0f b7 c0             	movzwl %ax,%eax
f0102ce6:	3b 45 dc             	cmp    -0x24(%ebp),%eax
f0102ce9:	7e 68                	jle    f0102d53 <PROGRAM_SEGMENT_FIRST+0xf0>
	{	
		(seg).ptr_start = (uint8 *) ptr_program_start + ph[index].p_offset;
f0102ceb:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102cee:	c1 e0 05             	shl    $0x5,%eax
f0102cf1:	89 c2                	mov    %eax,%edx
f0102cf3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102cf6:	01 d0                	add    %edx,%eax
f0102cf8:	8b 50 04             	mov    0x4(%eax),%edx
f0102cfb:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cfe:	01 d0                	add    %edx,%eax
f0102d00:	89 45 c8             	mov    %eax,-0x38(%ebp)
		(seg).size_in_memory =  ph[index].p_memsz;
f0102d03:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102d06:	c1 e0 05             	shl    $0x5,%eax
f0102d09:	89 c2                	mov    %eax,%edx
f0102d0b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d0e:	01 d0                	add    %edx,%eax
f0102d10:	8b 40 14             	mov    0x14(%eax),%eax
f0102d13:	89 45 d0             	mov    %eax,-0x30(%ebp)
		(seg).size_in_file = ph[index].p_filesz;
f0102d16:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102d19:	c1 e0 05             	shl    $0x5,%eax
f0102d1c:	89 c2                	mov    %eax,%edx
f0102d1e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d21:	01 d0                	add    %edx,%eax
f0102d23:	8b 40 10             	mov    0x10(%eax),%eax
f0102d26:	89 45 cc             	mov    %eax,-0x34(%ebp)
		(seg).virtual_address = (uint8*)ph[index].p_va;
f0102d29:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102d2c:	c1 e0 05             	shl    $0x5,%eax
f0102d2f:	89 c2                	mov    %eax,%edx
f0102d31:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d34:	01 d0                	add    %edx,%eax
f0102d36:	8b 40 08             	mov    0x8(%eax),%eax
f0102d39:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		return seg;
f0102d3c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d3f:	89 c3                	mov    %eax,%ebx
f0102d41:	8d 45 c8             	lea    -0x38(%ebp),%eax
f0102d44:	ba 05 00 00 00       	mov    $0x5,%edx
f0102d49:	89 df                	mov    %ebx,%edi
f0102d4b:	89 c6                	mov    %eax,%esi
f0102d4d:	89 d1                	mov    %edx,%ecx
f0102d4f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102d51:	eb 1c                	jmp    f0102d6f <PROGRAM_SEGMENT_FIRST+0x10c>
	}
	seg.segment_id = -1;
f0102d53:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
	return seg;
f0102d5a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d5d:	89 c3                	mov    %eax,%ebx
f0102d5f:	8d 45 c8             	lea    -0x38(%ebp),%eax
f0102d62:	ba 05 00 00 00       	mov    $0x5,%edx
f0102d67:	89 df                	mov    %ebx,%edi
f0102d69:	89 c6                	mov    %eax,%esi
f0102d6b:	89 d1                	mov    %edx,%ecx
f0102d6d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
}
f0102d6f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d72:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d75:	5b                   	pop    %ebx
f0102d76:	5e                   	pop    %esi
f0102d77:	5f                   	pop    %edi
f0102d78:	5d                   	pop    %ebp
f0102d79:	c2 04 00             	ret    $0x4

f0102d7c <get_user_program_info>:

struct UserProgramInfo* get_user_program_info(char* user_program_name)
				{
f0102d7c:	55                   	push   %ebp
f0102d7d:	89 e5                	mov    %esp,%ebp
f0102d7f:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f0102d82:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0102d89:	eb 23                	jmp    f0102dae <get_user_program_info+0x32>
		if (strcmp(user_program_name, userPrograms[i].name) == 0)
f0102d8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d8e:	c1 e0 04             	shl    $0x4,%eax
f0102d91:	05 80 b6 11 f0       	add    $0xf011b680,%eax
f0102d96:	8b 00                	mov    (%eax),%eax
f0102d98:	83 ec 08             	sub    $0x8,%esp
f0102d9b:	50                   	push   %eax
f0102d9c:	ff 75 08             	pushl  0x8(%ebp)
f0102d9f:	e8 af 18 00 00       	call   f0104653 <strcmp>
f0102da4:	83 c4 10             	add    $0x10,%esp
f0102da7:	85 c0                	test   %eax,%eax
f0102da9:	74 0f                	je     f0102dba <get_user_program_info+0x3e>
}

struct UserProgramInfo* get_user_program_info(char* user_program_name)
				{
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f0102dab:	ff 45 f4             	incl   -0xc(%ebp)
f0102dae:	a1 d4 b6 11 f0       	mov    0xf011b6d4,%eax
f0102db3:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0102db6:	7c d3                	jl     f0102d8b <get_user_program_info+0xf>
f0102db8:	eb 01                	jmp    f0102dbb <get_user_program_info+0x3f>
		if (strcmp(user_program_name, userPrograms[i].name) == 0)
			break;
f0102dba:	90                   	nop
	}
	if(i==NUM_USER_PROGS) 
f0102dbb:	a1 d4 b6 11 f0       	mov    0xf011b6d4,%eax
f0102dc0:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0102dc3:	75 1a                	jne    f0102ddf <get_user_program_info+0x63>
	{
		cprintf("Unknown user program '%s'\n", user_program_name);
f0102dc5:	83 ec 08             	sub    $0x8,%esp
f0102dc8:	ff 75 08             	pushl  0x8(%ebp)
f0102dcb:	68 e1 5d 10 f0       	push   $0xf0105de1
f0102dd0:	e8 7e 02 00 00       	call   f0103053 <cprintf>
f0102dd5:	83 c4 10             	add    $0x10,%esp
		return 0;
f0102dd8:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ddd:	eb 0b                	jmp    f0102dea <get_user_program_info+0x6e>
	}

	return &userPrograms[i];
f0102ddf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102de2:	c1 e0 04             	shl    $0x4,%eax
f0102de5:	05 80 b6 11 f0       	add    $0xf011b680,%eax
				}
f0102dea:	c9                   	leave  
f0102deb:	c3                   	ret    

f0102dec <get_user_program_info_by_env>:

struct UserProgramInfo* get_user_program_info_by_env(struct Env* e)
				{
f0102dec:	55                   	push   %ebp
f0102ded:	89 e5                	mov    %esp,%ebp
f0102def:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f0102df2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0102df9:	eb 15                	jmp    f0102e10 <get_user_program_info_by_env+0x24>
		if (e== userPrograms[i].environment)
f0102dfb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102dfe:	c1 e0 04             	shl    $0x4,%eax
f0102e01:	05 8c b6 11 f0       	add    $0xf011b68c,%eax
f0102e06:	8b 00                	mov    (%eax),%eax
f0102e08:	3b 45 08             	cmp    0x8(%ebp),%eax
f0102e0b:	74 0f                	je     f0102e1c <get_user_program_info_by_env+0x30>
				}

struct UserProgramInfo* get_user_program_info_by_env(struct Env* e)
				{
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f0102e0d:	ff 45 f4             	incl   -0xc(%ebp)
f0102e10:	a1 d4 b6 11 f0       	mov    0xf011b6d4,%eax
f0102e15:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0102e18:	7c e1                	jl     f0102dfb <get_user_program_info_by_env+0xf>
f0102e1a:	eb 01                	jmp    f0102e1d <get_user_program_info_by_env+0x31>
		if (e== userPrograms[i].environment)
			break;
f0102e1c:	90                   	nop
	}
	if(i==NUM_USER_PROGS) 
f0102e1d:	a1 d4 b6 11 f0       	mov    0xf011b6d4,%eax
f0102e22:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0102e25:	75 17                	jne    f0102e3e <get_user_program_info_by_env+0x52>
	{
		cprintf("Unknown user program \n");
f0102e27:	83 ec 0c             	sub    $0xc,%esp
f0102e2a:	68 fc 5d 10 f0       	push   $0xf0105dfc
f0102e2f:	e8 1f 02 00 00       	call   f0103053 <cprintf>
f0102e34:	83 c4 10             	add    $0x10,%esp
		return 0;
f0102e37:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e3c:	eb 0b                	jmp    f0102e49 <get_user_program_info_by_env+0x5d>
	}

	return &userPrograms[i];
f0102e3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e41:	c1 e0 04             	shl    $0x4,%eax
f0102e44:	05 80 b6 11 f0       	add    $0xf011b680,%eax
				}
f0102e49:	c9                   	leave  
f0102e4a:	c3                   	ret    

f0102e4b <set_environment_entry_point>:

void set_environment_entry_point(struct UserProgramInfo* ptr_user_program)
{
f0102e4b:	55                   	push   %ebp
f0102e4c:	89 e5                	mov    %esp,%ebp
f0102e4e:	83 ec 18             	sub    $0x18,%esp
	uint8* ptr_program_start=ptr_user_program->ptr_start;
f0102e51:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e54:	8b 40 08             	mov    0x8(%eax),%eax
f0102e57:	89 45 f4             	mov    %eax,-0xc(%ebp)
	struct Env* e = ptr_user_program->environment;
f0102e5a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e5d:	8b 40 0c             	mov    0xc(%eax),%eax
f0102e60:	89 45 f0             	mov    %eax,-0x10(%ebp)

	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f0102e63:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e66:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f0102e69:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102e6c:	8b 00                	mov    (%eax),%eax
f0102e6e:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f0102e73:	74 17                	je     f0102e8c <set_environment_entry_point+0x41>
		panic("Matafa2nash 3ala Keda"); 
f0102e75:	83 ec 04             	sub    $0x4,%esp
f0102e78:	68 cb 5d 10 f0       	push   $0xf0105dcb
f0102e7d:	68 d9 01 00 00       	push   $0x1d9
f0102e82:	68 51 5d 10 f0       	push   $0xf0105d51
f0102e87:	e8 a2 d2 ff ff       	call   f010012e <_panic>
	e->env_tf.tf_eip = (uint32*)pELFHDR->e_entry ;
f0102e8c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102e8f:	8b 40 18             	mov    0x18(%eax),%eax
f0102e92:	89 c2                	mov    %eax,%edx
f0102e94:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102e97:	89 50 30             	mov    %edx,0x30(%eax)
}
f0102e9a:	90                   	nop
f0102e9b:	c9                   	leave  
f0102e9c:	c3                   	ret    

f0102e9d <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e) 
{
f0102e9d:	55                   	push   %ebp
f0102e9e:	89 e5                	mov    %esp,%ebp
f0102ea0:	83 ec 08             	sub    $0x8,%esp
	env_free(e);
f0102ea3:	83 ec 0c             	sub    $0xc,%esp
f0102ea6:	ff 75 08             	pushl  0x8(%ebp)
f0102ea9:	e8 40 fa ff ff       	call   f01028ee <env_free>
f0102eae:	83 c4 10             	add    $0x10,%esp

	//cprintf("Destroyed the only environment - nothing more to do!\n");
	while (1)
		run_command_prompt();
f0102eb1:	e8 9b da ff ff       	call   f0100951 <run_command_prompt>
f0102eb6:	eb f9                	jmp    f0102eb1 <env_destroy+0x14>

f0102eb8 <env_run_cmd_prmpt>:
}

void env_run_cmd_prmpt()
{
f0102eb8:	55                   	push   %ebp
f0102eb9:	89 e5                	mov    %esp,%ebp
f0102ebb:	83 ec 18             	sub    $0x18,%esp
	struct UserProgramInfo* upi= get_user_program_info_by_env(curenv);	
f0102ebe:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f0102ec3:	83 ec 0c             	sub    $0xc,%esp
f0102ec6:	50                   	push   %eax
f0102ec7:	e8 20 ff ff ff       	call   f0102dec <get_user_program_info_by_env>
f0102ecc:	83 c4 10             	add    $0x10,%esp
f0102ecf:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&curenv->env_tf, 0, sizeof(curenv->env_tf));
f0102ed2:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f0102ed7:	83 ec 04             	sub    $0x4,%esp
f0102eda:	6a 44                	push   $0x44
f0102edc:	6a 00                	push   $0x0
f0102ede:	50                   	push   %eax
f0102edf:	e8 51 18 00 00       	call   f0104735 <memset>
f0102ee4:	83 c4 10             	add    $0x10,%esp
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.

	curenv->env_tf.tf_ds = GD_UD | 3;
f0102ee7:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f0102eec:	66 c7 40 24 23 00    	movw   $0x23,0x24(%eax)
	curenv->env_tf.tf_es = GD_UD | 3;
f0102ef2:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f0102ef7:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
	curenv->env_tf.tf_ss = GD_UD | 3;
f0102efd:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f0102f02:	66 c7 40 40 23 00    	movw   $0x23,0x40(%eax)
	curenv->env_tf.tf_esp = (uint32*)USTACKTOP;
f0102f08:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f0102f0d:	c7 40 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%eax)
	curenv->env_tf.tf_cs = GD_UT | 3;
f0102f14:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f0102f19:	66 c7 40 34 1b 00    	movw   $0x1b,0x34(%eax)
	set_environment_entry_point(upi);
f0102f1f:	83 ec 0c             	sub    $0xc,%esp
f0102f22:	ff 75 f4             	pushl  -0xc(%ebp)
f0102f25:	e8 21 ff ff ff       	call   f0102e4b <set_environment_entry_point>
f0102f2a:	83 c4 10             	add    $0x10,%esp

	lcr3(K_PHYSICAL_ADDRESS(ptr_page_directory));
f0102f2d:	a1 c4 e7 14 f0       	mov    0xf014e7c4,%eax
f0102f32:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102f35:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
f0102f3c:	77 17                	ja     f0102f55 <env_run_cmd_prmpt+0x9d>
f0102f3e:	ff 75 f0             	pushl  -0x10(%ebp)
f0102f41:	68 14 5e 10 f0       	push   $0xf0105e14
f0102f46:	68 04 02 00 00       	push   $0x204
f0102f4b:	68 51 5d 10 f0       	push   $0xf0105d51
f0102f50:	e8 d9 d1 ff ff       	call   f010012e <_panic>
f0102f55:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102f58:	05 00 00 00 10       	add    $0x10000000,%eax
f0102f5d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f60:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f63:	0f 22 d8             	mov    %eax,%cr3

	curenv = NULL;
f0102f66:	c7 05 30 df 14 f0 00 	movl   $0x0,0xf014df30
f0102f6d:	00 00 00 

	while (1)
		run_command_prompt();
f0102f70:	e8 dc d9 ff ff       	call   f0100951 <run_command_prompt>
f0102f75:	eb f9                	jmp    f0102f70 <env_run_cmd_prmpt+0xb8>

f0102f77 <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102f77:	55                   	push   %ebp
f0102f78:	89 e5                	mov    %esp,%ebp
f0102f7a:	83 ec 08             	sub    $0x8,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102f7d:	8b 65 08             	mov    0x8(%ebp),%esp
f0102f80:	61                   	popa   
f0102f81:	07                   	pop    %es
f0102f82:	1f                   	pop    %ds
f0102f83:	83 c4 08             	add    $0x8,%esp
f0102f86:	cf                   	iret   
			"\tpopl %%es\n"
			"\tpopl %%ds\n"
			"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
			"\tiret"
			: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102f87:	83 ec 04             	sub    $0x4,%esp
f0102f8a:	68 45 5e 10 f0       	push   $0xf0105e45
f0102f8f:	68 1b 02 00 00       	push   $0x21b
f0102f94:	68 51 5d 10 f0       	push   $0xf0105d51
f0102f99:	e8 90 d1 ff ff       	call   f010012e <_panic>

f0102f9e <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102f9e:	55                   	push   %ebp
f0102f9f:	89 e5                	mov    %esp,%ebp
f0102fa1:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f0102fa4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fa7:	0f b6 c0             	movzbl %al,%eax
f0102faa:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
f0102fb1:	88 45 f6             	mov    %al,-0xa(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102fb4:	8a 45 f6             	mov    -0xa(%ebp),%al
f0102fb7:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0102fba:	ee                   	out    %al,(%dx)
f0102fbb:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102fc2:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0102fc5:	89 c2                	mov    %eax,%edx
f0102fc7:	ec                   	in     (%dx),%al
f0102fc8:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f0102fcb:	8a 45 f7             	mov    -0x9(%ebp),%al
	return inb(IO_RTC+1);
f0102fce:	0f b6 c0             	movzbl %al,%eax
}
f0102fd1:	c9                   	leave  
f0102fd2:	c3                   	ret    

f0102fd3 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102fd3:	55                   	push   %ebp
f0102fd4:	89 e5                	mov    %esp,%ebp
f0102fd6:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f0102fd9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fdc:	0f b6 c0             	movzbl %al,%eax
f0102fdf:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
f0102fe6:	88 45 f6             	mov    %al,-0xa(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102fe9:	8a 45 f6             	mov    -0xa(%ebp),%al
f0102fec:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0102fef:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
f0102ff0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ff3:	0f b6 c0             	movzbl %al,%eax
f0102ff6:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)
f0102ffd:	88 45 f7             	mov    %al,-0x9(%ebp)
f0103000:	8a 45 f7             	mov    -0x9(%ebp),%al
f0103003:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0103006:	ee                   	out    %al,(%dx)
}
f0103007:	90                   	nop
f0103008:	c9                   	leave  
f0103009:	c3                   	ret    

f010300a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010300a:	55                   	push   %ebp
f010300b:	89 e5                	mov    %esp,%ebp
f010300d:	83 ec 08             	sub    $0x8,%esp
	cputchar(ch);
f0103010:	83 ec 0c             	sub    $0xc,%esp
f0103013:	ff 75 08             	pushl  0x8(%ebp)
f0103016:	e8 fc d8 ff ff       	call   f0100917 <cputchar>
f010301b:	83 c4 10             	add    $0x10,%esp
	*cnt++;
f010301e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103021:	83 c0 04             	add    $0x4,%eax
f0103024:	89 45 0c             	mov    %eax,0xc(%ebp)
}
f0103027:	90                   	nop
f0103028:	c9                   	leave  
f0103029:	c3                   	ret    

f010302a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010302a:	55                   	push   %ebp
f010302b:	89 e5                	mov    %esp,%ebp
f010302d:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103030:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103037:	ff 75 0c             	pushl  0xc(%ebp)
f010303a:	ff 75 08             	pushl  0x8(%ebp)
f010303d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103040:	50                   	push   %eax
f0103041:	68 0a 30 10 f0       	push   $0xf010300a
f0103046:	e8 56 0f 00 00       	call   f0103fa1 <vprintfmt>
f010304b:	83 c4 10             	add    $0x10,%esp
	return cnt;
f010304e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0103051:	c9                   	leave  
f0103052:	c3                   	ret    

f0103053 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103053:	55                   	push   %ebp
f0103054:	89 e5                	mov    %esp,%ebp
f0103056:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103059:	8d 45 0c             	lea    0xc(%ebp),%eax
f010305c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
f010305f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103062:	83 ec 08             	sub    $0x8,%esp
f0103065:	ff 75 f4             	pushl  -0xc(%ebp)
f0103068:	50                   	push   %eax
f0103069:	e8 bc ff ff ff       	call   f010302a <vcprintf>
f010306e:	83 c4 10             	add    $0x10,%esp
f0103071:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
f0103074:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
f0103077:	c9                   	leave  
f0103078:	c3                   	ret    

f0103079 <trapname>:
};
extern  void (*PAGE_FAULT)();
extern  void (*SYSCALL_HANDLER)();

static const char *trapname(int trapno)
{
f0103079:	55                   	push   %ebp
f010307a:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f010307c:	8b 45 08             	mov    0x8(%ebp),%eax
f010307f:	83 f8 13             	cmp    $0x13,%eax
f0103082:	77 0c                	ja     f0103090 <trapname+0x17>
		return excnames[trapno];
f0103084:	8b 45 08             	mov    0x8(%ebp),%eax
f0103087:	8b 04 85 80 61 10 f0 	mov    -0xfef9e80(,%eax,4),%eax
f010308e:	eb 12                	jmp    f01030a2 <trapname+0x29>
	if (trapno == T_SYSCALL)
f0103090:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
f0103094:	75 07                	jne    f010309d <trapname+0x24>
		return "System call";
f0103096:	b8 60 5e 10 f0       	mov    $0xf0105e60,%eax
f010309b:	eb 05                	jmp    f01030a2 <trapname+0x29>
	return "(unknown trap)";
f010309d:	b8 6c 5e 10 f0       	mov    $0xf0105e6c,%eax
}
f01030a2:	5d                   	pop    %ebp
f01030a3:	c3                   	ret    

f01030a4 <idt_init>:


void
idt_init(void)
{
f01030a4:	55                   	push   %ebp
f01030a5:	89 e5                	mov    %esp,%ebp
f01030a7:	83 ec 10             	sub    $0x10,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	//initialize idt
	SETGATE(idt[T_PGFLT], 0, GD_KT , &PAGE_FAULT, 0) ;
f01030aa:	b8 02 36 10 f0       	mov    $0xf0103602,%eax
f01030af:	66 a3 b0 df 14 f0    	mov    %ax,0xf014dfb0
f01030b5:	66 c7 05 b2 df 14 f0 	movw   $0x8,0xf014dfb2
f01030bc:	08 00 
f01030be:	a0 b4 df 14 f0       	mov    0xf014dfb4,%al
f01030c3:	83 e0 e0             	and    $0xffffffe0,%eax
f01030c6:	a2 b4 df 14 f0       	mov    %al,0xf014dfb4
f01030cb:	a0 b4 df 14 f0       	mov    0xf014dfb4,%al
f01030d0:	83 e0 1f             	and    $0x1f,%eax
f01030d3:	a2 b4 df 14 f0       	mov    %al,0xf014dfb4
f01030d8:	a0 b5 df 14 f0       	mov    0xf014dfb5,%al
f01030dd:	83 e0 f0             	and    $0xfffffff0,%eax
f01030e0:	83 c8 0e             	or     $0xe,%eax
f01030e3:	a2 b5 df 14 f0       	mov    %al,0xf014dfb5
f01030e8:	a0 b5 df 14 f0       	mov    0xf014dfb5,%al
f01030ed:	83 e0 ef             	and    $0xffffffef,%eax
f01030f0:	a2 b5 df 14 f0       	mov    %al,0xf014dfb5
f01030f5:	a0 b5 df 14 f0       	mov    0xf014dfb5,%al
f01030fa:	83 e0 9f             	and    $0xffffff9f,%eax
f01030fd:	a2 b5 df 14 f0       	mov    %al,0xf014dfb5
f0103102:	a0 b5 df 14 f0       	mov    0xf014dfb5,%al
f0103107:	83 c8 80             	or     $0xffffff80,%eax
f010310a:	a2 b5 df 14 f0       	mov    %al,0xf014dfb5
f010310f:	b8 02 36 10 f0       	mov    $0xf0103602,%eax
f0103114:	c1 e8 10             	shr    $0x10,%eax
f0103117:	66 a3 b6 df 14 f0    	mov    %ax,0xf014dfb6
	SETGATE(idt[T_SYSCALL], 0, GD_KT , &SYSCALL_HANDLER, 3) ;
f010311d:	b8 06 36 10 f0       	mov    $0xf0103606,%eax
f0103122:	66 a3 c0 e0 14 f0    	mov    %ax,0xf014e0c0
f0103128:	66 c7 05 c2 e0 14 f0 	movw   $0x8,0xf014e0c2
f010312f:	08 00 
f0103131:	a0 c4 e0 14 f0       	mov    0xf014e0c4,%al
f0103136:	83 e0 e0             	and    $0xffffffe0,%eax
f0103139:	a2 c4 e0 14 f0       	mov    %al,0xf014e0c4
f010313e:	a0 c4 e0 14 f0       	mov    0xf014e0c4,%al
f0103143:	83 e0 1f             	and    $0x1f,%eax
f0103146:	a2 c4 e0 14 f0       	mov    %al,0xf014e0c4
f010314b:	a0 c5 e0 14 f0       	mov    0xf014e0c5,%al
f0103150:	83 e0 f0             	and    $0xfffffff0,%eax
f0103153:	83 c8 0e             	or     $0xe,%eax
f0103156:	a2 c5 e0 14 f0       	mov    %al,0xf014e0c5
f010315b:	a0 c5 e0 14 f0       	mov    0xf014e0c5,%al
f0103160:	83 e0 ef             	and    $0xffffffef,%eax
f0103163:	a2 c5 e0 14 f0       	mov    %al,0xf014e0c5
f0103168:	a0 c5 e0 14 f0       	mov    0xf014e0c5,%al
f010316d:	83 c8 60             	or     $0x60,%eax
f0103170:	a2 c5 e0 14 f0       	mov    %al,0xf014e0c5
f0103175:	a0 c5 e0 14 f0       	mov    0xf014e0c5,%al
f010317a:	83 c8 80             	or     $0xffffff80,%eax
f010317d:	a2 c5 e0 14 f0       	mov    %al,0xf014e0c5
f0103182:	b8 06 36 10 f0       	mov    $0xf0103606,%eax
f0103187:	c1 e8 10             	shr    $0x10,%eax
f010318a:	66 a3 c6 e0 14 f0    	mov    %ax,0xf014e0c6

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KERNEL_STACK_TOP;
f0103190:	c7 05 44 e7 14 f0 00 	movl   $0xefc00000,0xf014e744
f0103197:	00 c0 ef 
	ts.ts_ss0 = GD_KD;
f010319a:	66 c7 05 48 e7 14 f0 	movw   $0x10,0xf014e748
f01031a1:	10 00 

	// Initialize the TSS field of the gdt.
	gdt[GD_TSS >> 3] = SEG16(STS_T32A, (uint32) (&ts),
f01031a3:	66 c7 05 68 b6 11 f0 	movw   $0x68,0xf011b668
f01031aa:	68 00 
f01031ac:	b8 40 e7 14 f0       	mov    $0xf014e740,%eax
f01031b1:	66 a3 6a b6 11 f0    	mov    %ax,0xf011b66a
f01031b7:	b8 40 e7 14 f0       	mov    $0xf014e740,%eax
f01031bc:	c1 e8 10             	shr    $0x10,%eax
f01031bf:	a2 6c b6 11 f0       	mov    %al,0xf011b66c
f01031c4:	a0 6d b6 11 f0       	mov    0xf011b66d,%al
f01031c9:	83 e0 f0             	and    $0xfffffff0,%eax
f01031cc:	83 c8 09             	or     $0x9,%eax
f01031cf:	a2 6d b6 11 f0       	mov    %al,0xf011b66d
f01031d4:	a0 6d b6 11 f0       	mov    0xf011b66d,%al
f01031d9:	83 c8 10             	or     $0x10,%eax
f01031dc:	a2 6d b6 11 f0       	mov    %al,0xf011b66d
f01031e1:	a0 6d b6 11 f0       	mov    0xf011b66d,%al
f01031e6:	83 e0 9f             	and    $0xffffff9f,%eax
f01031e9:	a2 6d b6 11 f0       	mov    %al,0xf011b66d
f01031ee:	a0 6d b6 11 f0       	mov    0xf011b66d,%al
f01031f3:	83 c8 80             	or     $0xffffff80,%eax
f01031f6:	a2 6d b6 11 f0       	mov    %al,0xf011b66d
f01031fb:	a0 6e b6 11 f0       	mov    0xf011b66e,%al
f0103200:	83 e0 f0             	and    $0xfffffff0,%eax
f0103203:	a2 6e b6 11 f0       	mov    %al,0xf011b66e
f0103208:	a0 6e b6 11 f0       	mov    0xf011b66e,%al
f010320d:	83 e0 ef             	and    $0xffffffef,%eax
f0103210:	a2 6e b6 11 f0       	mov    %al,0xf011b66e
f0103215:	a0 6e b6 11 f0       	mov    0xf011b66e,%al
f010321a:	83 e0 df             	and    $0xffffffdf,%eax
f010321d:	a2 6e b6 11 f0       	mov    %al,0xf011b66e
f0103222:	a0 6e b6 11 f0       	mov    0xf011b66e,%al
f0103227:	83 c8 40             	or     $0x40,%eax
f010322a:	a2 6e b6 11 f0       	mov    %al,0xf011b66e
f010322f:	a0 6e b6 11 f0       	mov    0xf011b66e,%al
f0103234:	83 e0 7f             	and    $0x7f,%eax
f0103237:	a2 6e b6 11 f0       	mov    %al,0xf011b66e
f010323c:	b8 40 e7 14 f0       	mov    $0xf014e740,%eax
f0103241:	c1 e8 18             	shr    $0x18,%eax
f0103244:	a2 6f b6 11 f0       	mov    %al,0xf011b66f
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS >> 3].sd_s = 0;
f0103249:	a0 6d b6 11 f0       	mov    0xf011b66d,%al
f010324e:	83 e0 ef             	and    $0xffffffef,%eax
f0103251:	a2 6d b6 11 f0       	mov    %al,0xf011b66d
f0103256:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
}

static __inline void
ltr(uint16 sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f010325c:	66 8b 45 fe          	mov    -0x2(%ebp),%ax
f0103260:	0f 00 d8             	ltr    %ax

	// Load the TSS
	ltr(GD_TSS);

	// Load the IDT
	asm volatile("lidt idt_pd");
f0103263:	0f 01 1d d8 b6 11 f0 	lidtl  0xf011b6d8
}
f010326a:	90                   	nop
f010326b:	c9                   	leave  
f010326c:	c3                   	ret    

f010326d <print_trapframe>:

void
print_trapframe(struct Trapframe *tf)
{
f010326d:	55                   	push   %ebp
f010326e:	89 e5                	mov    %esp,%ebp
f0103270:	83 ec 08             	sub    $0x8,%esp
	cprintf("TRAP frame at %p\n", tf);
f0103273:	83 ec 08             	sub    $0x8,%esp
f0103276:	ff 75 08             	pushl  0x8(%ebp)
f0103279:	68 7b 5e 10 f0       	push   $0xf0105e7b
f010327e:	e8 d0 fd ff ff       	call   f0103053 <cprintf>
f0103283:	83 c4 10             	add    $0x10,%esp
	print_regs(&tf->tf_regs);
f0103286:	8b 45 08             	mov    0x8(%ebp),%eax
f0103289:	83 ec 0c             	sub    $0xc,%esp
f010328c:	50                   	push   %eax
f010328d:	e8 f6 00 00 00       	call   f0103388 <print_regs>
f0103292:	83 c4 10             	add    $0x10,%esp
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103295:	8b 45 08             	mov    0x8(%ebp),%eax
f0103298:	8b 40 20             	mov    0x20(%eax),%eax
f010329b:	0f b7 c0             	movzwl %ax,%eax
f010329e:	83 ec 08             	sub    $0x8,%esp
f01032a1:	50                   	push   %eax
f01032a2:	68 8d 5e 10 f0       	push   $0xf0105e8d
f01032a7:	e8 a7 fd ff ff       	call   f0103053 <cprintf>
f01032ac:	83 c4 10             	add    $0x10,%esp
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01032af:	8b 45 08             	mov    0x8(%ebp),%eax
f01032b2:	8b 40 24             	mov    0x24(%eax),%eax
f01032b5:	0f b7 c0             	movzwl %ax,%eax
f01032b8:	83 ec 08             	sub    $0x8,%esp
f01032bb:	50                   	push   %eax
f01032bc:	68 a0 5e 10 f0       	push   $0xf0105ea0
f01032c1:	e8 8d fd ff ff       	call   f0103053 <cprintf>
f01032c6:	83 c4 10             	add    $0x10,%esp
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01032c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01032cc:	8b 40 28             	mov    0x28(%eax),%eax
f01032cf:	83 ec 0c             	sub    $0xc,%esp
f01032d2:	50                   	push   %eax
f01032d3:	e8 a1 fd ff ff       	call   f0103079 <trapname>
f01032d8:	83 c4 10             	add    $0x10,%esp
f01032db:	89 c2                	mov    %eax,%edx
f01032dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01032e0:	8b 40 28             	mov    0x28(%eax),%eax
f01032e3:	83 ec 04             	sub    $0x4,%esp
f01032e6:	52                   	push   %edx
f01032e7:	50                   	push   %eax
f01032e8:	68 b3 5e 10 f0       	push   $0xf0105eb3
f01032ed:	e8 61 fd ff ff       	call   f0103053 <cprintf>
f01032f2:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x\n", tf->tf_err);
f01032f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01032f8:	8b 40 2c             	mov    0x2c(%eax),%eax
f01032fb:	83 ec 08             	sub    $0x8,%esp
f01032fe:	50                   	push   %eax
f01032ff:	68 c5 5e 10 f0       	push   $0xf0105ec5
f0103304:	e8 4a fd ff ff       	call   f0103053 <cprintf>
f0103309:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010330c:	8b 45 08             	mov    0x8(%ebp),%eax
f010330f:	8b 40 30             	mov    0x30(%eax),%eax
f0103312:	83 ec 08             	sub    $0x8,%esp
f0103315:	50                   	push   %eax
f0103316:	68 d4 5e 10 f0       	push   $0xf0105ed4
f010331b:	e8 33 fd ff ff       	call   f0103053 <cprintf>
f0103320:	83 c4 10             	add    $0x10,%esp
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103323:	8b 45 08             	mov    0x8(%ebp),%eax
f0103326:	8b 40 34             	mov    0x34(%eax),%eax
f0103329:	0f b7 c0             	movzwl %ax,%eax
f010332c:	83 ec 08             	sub    $0x8,%esp
f010332f:	50                   	push   %eax
f0103330:	68 e3 5e 10 f0       	push   $0xf0105ee3
f0103335:	e8 19 fd ff ff       	call   f0103053 <cprintf>
f010333a:	83 c4 10             	add    $0x10,%esp
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010333d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103340:	8b 40 38             	mov    0x38(%eax),%eax
f0103343:	83 ec 08             	sub    $0x8,%esp
f0103346:	50                   	push   %eax
f0103347:	68 f6 5e 10 f0       	push   $0xf0105ef6
f010334c:	e8 02 fd ff ff       	call   f0103053 <cprintf>
f0103351:	83 c4 10             	add    $0x10,%esp
	cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103354:	8b 45 08             	mov    0x8(%ebp),%eax
f0103357:	8b 40 3c             	mov    0x3c(%eax),%eax
f010335a:	83 ec 08             	sub    $0x8,%esp
f010335d:	50                   	push   %eax
f010335e:	68 05 5f 10 f0       	push   $0xf0105f05
f0103363:	e8 eb fc ff ff       	call   f0103053 <cprintf>
f0103368:	83 c4 10             	add    $0x10,%esp
	cprintf("  ss   0x----%04x\n", tf->tf_ss);
f010336b:	8b 45 08             	mov    0x8(%ebp),%eax
f010336e:	8b 40 40             	mov    0x40(%eax),%eax
f0103371:	0f b7 c0             	movzwl %ax,%eax
f0103374:	83 ec 08             	sub    $0x8,%esp
f0103377:	50                   	push   %eax
f0103378:	68 14 5f 10 f0       	push   $0xf0105f14
f010337d:	e8 d1 fc ff ff       	call   f0103053 <cprintf>
f0103382:	83 c4 10             	add    $0x10,%esp
}
f0103385:	90                   	nop
f0103386:	c9                   	leave  
f0103387:	c3                   	ret    

f0103388 <print_regs>:

void
print_regs(struct PushRegs *regs)
{
f0103388:	55                   	push   %ebp
f0103389:	89 e5                	mov    %esp,%ebp
f010338b:	83 ec 08             	sub    $0x8,%esp
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010338e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103391:	8b 00                	mov    (%eax),%eax
f0103393:	83 ec 08             	sub    $0x8,%esp
f0103396:	50                   	push   %eax
f0103397:	68 27 5f 10 f0       	push   $0xf0105f27
f010339c:	e8 b2 fc ff ff       	call   f0103053 <cprintf>
f01033a1:	83 c4 10             	add    $0x10,%esp
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01033a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01033a7:	8b 40 04             	mov    0x4(%eax),%eax
f01033aa:	83 ec 08             	sub    $0x8,%esp
f01033ad:	50                   	push   %eax
f01033ae:	68 36 5f 10 f0       	push   $0xf0105f36
f01033b3:	e8 9b fc ff ff       	call   f0103053 <cprintf>
f01033b8:	83 c4 10             	add    $0x10,%esp
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01033bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01033be:	8b 40 08             	mov    0x8(%eax),%eax
f01033c1:	83 ec 08             	sub    $0x8,%esp
f01033c4:	50                   	push   %eax
f01033c5:	68 45 5f 10 f0       	push   $0xf0105f45
f01033ca:	e8 84 fc ff ff       	call   f0103053 <cprintf>
f01033cf:	83 c4 10             	add    $0x10,%esp
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01033d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01033d5:	8b 40 0c             	mov    0xc(%eax),%eax
f01033d8:	83 ec 08             	sub    $0x8,%esp
f01033db:	50                   	push   %eax
f01033dc:	68 54 5f 10 f0       	push   $0xf0105f54
f01033e1:	e8 6d fc ff ff       	call   f0103053 <cprintf>
f01033e6:	83 c4 10             	add    $0x10,%esp
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01033e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01033ec:	8b 40 10             	mov    0x10(%eax),%eax
f01033ef:	83 ec 08             	sub    $0x8,%esp
f01033f2:	50                   	push   %eax
f01033f3:	68 63 5f 10 f0       	push   $0xf0105f63
f01033f8:	e8 56 fc ff ff       	call   f0103053 <cprintf>
f01033fd:	83 c4 10             	add    $0x10,%esp
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103400:	8b 45 08             	mov    0x8(%ebp),%eax
f0103403:	8b 40 14             	mov    0x14(%eax),%eax
f0103406:	83 ec 08             	sub    $0x8,%esp
f0103409:	50                   	push   %eax
f010340a:	68 72 5f 10 f0       	push   $0xf0105f72
f010340f:	e8 3f fc ff ff       	call   f0103053 <cprintf>
f0103414:	83 c4 10             	add    $0x10,%esp
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103417:	8b 45 08             	mov    0x8(%ebp),%eax
f010341a:	8b 40 18             	mov    0x18(%eax),%eax
f010341d:	83 ec 08             	sub    $0x8,%esp
f0103420:	50                   	push   %eax
f0103421:	68 81 5f 10 f0       	push   $0xf0105f81
f0103426:	e8 28 fc ff ff       	call   f0103053 <cprintf>
f010342b:	83 c4 10             	add    $0x10,%esp
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010342e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103431:	8b 40 1c             	mov    0x1c(%eax),%eax
f0103434:	83 ec 08             	sub    $0x8,%esp
f0103437:	50                   	push   %eax
f0103438:	68 90 5f 10 f0       	push   $0xf0105f90
f010343d:	e8 11 fc ff ff       	call   f0103053 <cprintf>
f0103442:	83 c4 10             	add    $0x10,%esp
}
f0103445:	90                   	nop
f0103446:	c9                   	leave  
f0103447:	c3                   	ret    

f0103448 <trap_dispatch>:

static void
trap_dispatch(struct Trapframe *tf)
{
f0103448:	55                   	push   %ebp
f0103449:	89 e5                	mov    %esp,%ebp
f010344b:	57                   	push   %edi
f010344c:	56                   	push   %esi
f010344d:	53                   	push   %ebx
f010344e:	83 ec 1c             	sub    $0x1c,%esp
	// Handle processor exceptions.
	// LAB 3: Your code here.

	if(tf->tf_trapno == T_PGFLT)
f0103451:	8b 45 08             	mov    0x8(%ebp),%eax
f0103454:	8b 40 28             	mov    0x28(%eax),%eax
f0103457:	83 f8 0e             	cmp    $0xe,%eax
f010345a:	75 13                	jne    f010346f <trap_dispatch+0x27>
	{
		page_fault_handler(tf);
f010345c:	83 ec 0c             	sub    $0xc,%esp
f010345f:	ff 75 08             	pushl  0x8(%ebp)
f0103462:	e8 47 01 00 00       	call   f01035ae <page_fault_handler>
f0103467:	83 c4 10             	add    $0x10,%esp
		else {
			env_destroy(curenv);
			return;
		}
	}
	return;
f010346a:	e9 90 00 00 00       	jmp    f01034ff <trap_dispatch+0xb7>

	if(tf->tf_trapno == T_PGFLT)
	{
		page_fault_handler(tf);
	}
	else if (tf->tf_trapno == T_SYSCALL)
f010346f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103472:	8b 40 28             	mov    0x28(%eax),%eax
f0103475:	83 f8 30             	cmp    $0x30,%eax
f0103478:	75 42                	jne    f01034bc <trap_dispatch+0x74>
	{
		uint32 ret = syscall(tf->tf_regs.reg_eax
f010347a:	8b 45 08             	mov    0x8(%ebp),%eax
f010347d:	8b 78 04             	mov    0x4(%eax),%edi
f0103480:	8b 45 08             	mov    0x8(%ebp),%eax
f0103483:	8b 30                	mov    (%eax),%esi
f0103485:	8b 45 08             	mov    0x8(%ebp),%eax
f0103488:	8b 58 10             	mov    0x10(%eax),%ebx
f010348b:	8b 45 08             	mov    0x8(%ebp),%eax
f010348e:	8b 48 18             	mov    0x18(%eax),%ecx
f0103491:	8b 45 08             	mov    0x8(%ebp),%eax
f0103494:	8b 50 14             	mov    0x14(%eax),%edx
f0103497:	8b 45 08             	mov    0x8(%ebp),%eax
f010349a:	8b 40 1c             	mov    0x1c(%eax),%eax
f010349d:	83 ec 08             	sub    $0x8,%esp
f01034a0:	57                   	push   %edi
f01034a1:	56                   	push   %esi
f01034a2:	53                   	push   %ebx
f01034a3:	51                   	push   %ecx
f01034a4:	52                   	push   %edx
f01034a5:	50                   	push   %eax
f01034a6:	e8 47 04 00 00       	call   f01038f2 <syscall>
f01034ab:	83 c4 20             	add    $0x20,%esp
f01034ae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			,tf->tf_regs.reg_edx
			,tf->tf_regs.reg_ecx
			,tf->tf_regs.reg_ebx
			,tf->tf_regs.reg_edi
					,tf->tf_regs.reg_esi);
		tf->tf_regs.reg_eax = ret;
f01034b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01034b4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01034b7:	89 50 1c             	mov    %edx,0x1c(%eax)
		else {
			env_destroy(curenv);
			return;
		}
	}
	return;
f01034ba:	eb 43                	jmp    f01034ff <trap_dispatch+0xb7>
		tf->tf_regs.reg_eax = ret;
	}
	else
	{
		// Unexpected trap: The user process or the kernel has a bug.
		print_trapframe(tf);
f01034bc:	83 ec 0c             	sub    $0xc,%esp
f01034bf:	ff 75 08             	pushl  0x8(%ebp)
f01034c2:	e8 a6 fd ff ff       	call   f010326d <print_trapframe>
f01034c7:	83 c4 10             	add    $0x10,%esp
		if (tf->tf_cs == GD_KT)
f01034ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01034cd:	8b 40 34             	mov    0x34(%eax),%eax
f01034d0:	66 83 f8 08          	cmp    $0x8,%ax
f01034d4:	75 17                	jne    f01034ed <trap_dispatch+0xa5>
			panic("unhandled trap in kernel");
f01034d6:	83 ec 04             	sub    $0x4,%esp
f01034d9:	68 9f 5f 10 f0       	push   $0xf0105f9f
f01034de:	68 8a 00 00 00       	push   $0x8a
f01034e3:	68 b8 5f 10 f0       	push   $0xf0105fb8
f01034e8:	e8 41 cc ff ff       	call   f010012e <_panic>
		else {
			env_destroy(curenv);
f01034ed:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f01034f2:	83 ec 0c             	sub    $0xc,%esp
f01034f5:	50                   	push   %eax
f01034f6:	e8 a2 f9 ff ff       	call   f0102e9d <env_destroy>
f01034fb:	83 c4 10             	add    $0x10,%esp
			return;
f01034fe:	90                   	nop
		}
	}
	return;
}
f01034ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103502:	5b                   	pop    %ebx
f0103503:	5e                   	pop    %esi
f0103504:	5f                   	pop    %edi
f0103505:	5d                   	pop    %ebp
f0103506:	c3                   	ret    

f0103507 <trap>:

void
trap(struct Trapframe *tf)
{
f0103507:	55                   	push   %ebp
f0103508:	89 e5                	mov    %esp,%ebp
f010350a:	57                   	push   %edi
f010350b:	56                   	push   %esi
f010350c:	53                   	push   %ebx
f010350d:	83 ec 0c             	sub    $0xc,%esp
	//cprintf("Incoming TRAP frame at %p\n", tf);

	if ((tf->tf_cs & 3) == 3) {
f0103510:	8b 45 08             	mov    0x8(%ebp),%eax
f0103513:	8b 40 34             	mov    0x34(%eax),%eax
f0103516:	0f b7 c0             	movzwl %ax,%eax
f0103519:	83 e0 03             	and    $0x3,%eax
f010351c:	83 f8 03             	cmp    $0x3,%eax
f010351f:	75 42                	jne    f0103563 <trap+0x5c>
		// Trapped from user mode.
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		assert(curenv);
f0103521:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f0103526:	85 c0                	test   %eax,%eax
f0103528:	75 19                	jne    f0103543 <trap+0x3c>
f010352a:	68 c4 5f 10 f0       	push   $0xf0105fc4
f010352f:	68 cb 5f 10 f0       	push   $0xf0105fcb
f0103534:	68 9d 00 00 00       	push   $0x9d
f0103539:	68 b8 5f 10 f0       	push   $0xf0105fb8
f010353e:	e8 eb cb ff ff       	call   f010012e <_panic>
		curenv->env_tf = *tf;
f0103543:	8b 15 30 df 14 f0    	mov    0xf014df30,%edx
f0103549:	8b 45 08             	mov    0x8(%ebp),%eax
f010354c:	89 c3                	mov    %eax,%ebx
f010354e:	b8 11 00 00 00       	mov    $0x11,%eax
f0103553:	89 d7                	mov    %edx,%edi
f0103555:	89 de                	mov    %ebx,%esi
f0103557:	89 c1                	mov    %eax,%ecx
f0103559:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f010355b:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f0103560:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);
f0103563:	83 ec 0c             	sub    $0xc,%esp
f0103566:	ff 75 08             	pushl  0x8(%ebp)
f0103569:	e8 da fe ff ff       	call   f0103448 <trap_dispatch>
f010356e:	83 c4 10             	add    $0x10,%esp

        // Return to the current environment, which should be runnable.
        assert(curenv && curenv->env_status == ENV_RUNNABLE);
f0103571:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f0103576:	85 c0                	test   %eax,%eax
f0103578:	74 0d                	je     f0103587 <trap+0x80>
f010357a:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f010357f:	8b 40 54             	mov    0x54(%eax),%eax
f0103582:	83 f8 01             	cmp    $0x1,%eax
f0103585:	74 19                	je     f01035a0 <trap+0x99>
f0103587:	68 e0 5f 10 f0       	push   $0xf0105fe0
f010358c:	68 cb 5f 10 f0       	push   $0xf0105fcb
f0103591:	68 a7 00 00 00       	push   $0xa7
f0103596:	68 b8 5f 10 f0       	push   $0xf0105fb8
f010359b:	e8 8e cb ff ff       	call   f010012e <_panic>
        env_run(curenv);
f01035a0:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f01035a5:	83 ec 0c             	sub    $0xc,%esp
f01035a8:	50                   	push   %eax
f01035a9:	e8 fd f2 ff ff       	call   f01028ab <env_run>

f01035ae <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01035ae:	55                   	push   %ebp
f01035af:	89 e5                	mov    %esp,%ebp
f01035b1:	83 ec 18             	sub    $0x18,%esp

static __inline uint32
rcr2(void)
{
	uint32 val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f01035b4:	0f 20 d0             	mov    %cr2,%eax
f01035b7:	89 45 f0             	mov    %eax,-0x10(%ebp)
	return val;
f01035ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
	uint32 fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();
f01035bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01035c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01035c3:	8b 50 30             	mov    0x30(%eax),%edx
	curenv->env_id, fault_va, tf->tf_eip);
f01035c6:	a1 30 df 14 f0       	mov    0xf014df30,%eax
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01035cb:	8b 40 4c             	mov    0x4c(%eax),%eax
f01035ce:	52                   	push   %edx
f01035cf:	ff 75 f4             	pushl  -0xc(%ebp)
f01035d2:	50                   	push   %eax
f01035d3:	68 10 60 10 f0       	push   $0xf0106010
f01035d8:	e8 76 fa ff ff       	call   f0103053 <cprintf>
f01035dd:	83 c4 10             	add    $0x10,%esp
	curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01035e0:	83 ec 0c             	sub    $0xc,%esp
f01035e3:	ff 75 08             	pushl  0x8(%ebp)
f01035e6:	e8 82 fc ff ff       	call   f010326d <print_trapframe>
f01035eb:	83 c4 10             	add    $0x10,%esp
	env_destroy(curenv);
f01035ee:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f01035f3:	83 ec 0c             	sub    $0xc,%esp
f01035f6:	50                   	push   %eax
f01035f7:	e8 a1 f8 ff ff       	call   f0102e9d <env_destroy>
f01035fc:	83 c4 10             	add    $0x10,%esp

}
f01035ff:	90                   	nop
f0103600:	c9                   	leave  
f0103601:	c3                   	ret    

f0103602 <PAGE_FAULT>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER(PAGE_FAULT, T_PGFLT)		
f0103602:	6a 0e                	push   $0xe
f0103604:	eb 06                	jmp    f010360c <_alltraps>

f0103606 <SYSCALL_HANDLER>:

TRAPHANDLER_NOEC(SYSCALL_HANDLER, T_SYSCALL)
f0103606:	6a 00                	push   $0x0
f0103608:	6a 30                	push   $0x30
f010360a:	eb 00                	jmp    f010360c <_alltraps>

f010360c <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:

push %ds 
f010360c:	1e                   	push   %ds
push %es 
f010360d:	06                   	push   %es
pushal 	
f010360e:	60                   	pusha  

mov $(GD_KD), %ax 
f010360f:	66 b8 10 00          	mov    $0x10,%ax
mov %ax,%ds
f0103613:	8e d8                	mov    %eax,%ds
mov %ax,%es
f0103615:	8e c0                	mov    %eax,%es

push %esp
f0103617:	54                   	push   %esp

call trap
f0103618:	e8 ea fe ff ff       	call   f0103507 <trap>

pop %ecx /* poping the pointer to the tf from the stack so that the stack top is at the values of the registers posuhed by pusha*/
f010361d:	59                   	pop    %ecx
popal 	
f010361e:	61                   	popa   
pop %es 
f010361f:	07                   	pop    %es
pop %ds    
f0103620:	1f                   	pop    %ds

/*skipping the trap_no and the error code so that the stack top is at the old eip value*/
add $(8),%esp
f0103621:	83 c4 08             	add    $0x8,%esp

iret
f0103624:	cf                   	iret   

f0103625 <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f0103625:	55                   	push   %ebp
f0103626:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f0103628:	8b 45 08             	mov    0x8(%ebp),%eax
f010362b:	8b 15 bc e7 14 f0    	mov    0xf014e7bc,%edx
f0103631:	29 d0                	sub    %edx,%eax
f0103633:	c1 f8 02             	sar    $0x2,%eax
f0103636:	89 c2                	mov    %eax,%edx
f0103638:	89 d0                	mov    %edx,%eax
f010363a:	c1 e0 02             	shl    $0x2,%eax
f010363d:	01 d0                	add    %edx,%eax
f010363f:	c1 e0 02             	shl    $0x2,%eax
f0103642:	01 d0                	add    %edx,%eax
f0103644:	c1 e0 02             	shl    $0x2,%eax
f0103647:	01 d0                	add    %edx,%eax
f0103649:	89 c1                	mov    %eax,%ecx
f010364b:	c1 e1 08             	shl    $0x8,%ecx
f010364e:	01 c8                	add    %ecx,%eax
f0103650:	89 c1                	mov    %eax,%ecx
f0103652:	c1 e1 10             	shl    $0x10,%ecx
f0103655:	01 c8                	add    %ecx,%eax
f0103657:	01 c0                	add    %eax,%eax
f0103659:	01 d0                	add    %edx,%eax
}
f010365b:	5d                   	pop    %ebp
f010365c:	c3                   	ret    

f010365d <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f010365d:	55                   	push   %ebp
f010365e:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f0103660:	ff 75 08             	pushl  0x8(%ebp)
f0103663:	e8 bd ff ff ff       	call   f0103625 <to_frame_number>
f0103668:	83 c4 04             	add    $0x4,%esp
f010366b:	c1 e0 0c             	shl    $0xc,%eax
}
f010366e:	c9                   	leave  
f010366f:	c3                   	ret    

f0103670 <sys_cputs>:

// Print a string to the system console.
// The string is exactly 'len' characters long.
// Destroys the environment on memory errors.
static void sys_cputs(const char *s, uint32 len)
{
f0103670:	55                   	push   %ebp
f0103671:	89 e5                	mov    %esp,%ebp
f0103673:	83 ec 08             	sub    $0x8,%esp
	// Destroy the environment if not.
	
	// LAB 3: Your code here.

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103676:	83 ec 04             	sub    $0x4,%esp
f0103679:	ff 75 08             	pushl  0x8(%ebp)
f010367c:	ff 75 0c             	pushl  0xc(%ebp)
f010367f:	68 d0 61 10 f0       	push   $0xf01061d0
f0103684:	e8 ca f9 ff ff       	call   f0103053 <cprintf>
f0103689:	83 c4 10             	add    $0x10,%esp
}
f010368c:	90                   	nop
f010368d:	c9                   	leave  
f010368e:	c3                   	ret    

f010368f <sys_cgetc>:

// Read a character from the system console.
// Returns the character.
static int
sys_cgetc(void)
{
f010368f:	55                   	push   %ebp
f0103690:	89 e5                	mov    %esp,%ebp
f0103692:	83 ec 18             	sub    $0x18,%esp
	int c;

	// The cons_getc() primitive doesn't wait for a character,
	// but the sys_cgetc() system call does.
	while ((c = cons_getc()) == 0)
f0103695:	e8 cf d1 ff ff       	call   f0100869 <cons_getc>
f010369a:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010369d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01036a1:	74 f2                	je     f0103695 <sys_cgetc+0x6>
		/* do nothing */;

	return c;
f01036a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01036a6:	c9                   	leave  
f01036a7:	c3                   	ret    

f01036a8 <sys_getenvid>:

// Returns the current environment's envid.
static int32 sys_getenvid(void)
{
f01036a8:	55                   	push   %ebp
f01036a9:	89 e5                	mov    %esp,%ebp
	return curenv->env_id;
f01036ab:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f01036b0:	8b 40 4c             	mov    0x4c(%eax),%eax
}
f01036b3:	5d                   	pop    %ebp
f01036b4:	c3                   	ret    

f01036b5 <sys_env_destroy>:
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int sys_env_destroy(int32  envid)
{
f01036b5:	55                   	push   %ebp
f01036b6:	89 e5                	mov    %esp,%ebp
f01036b8:	83 ec 18             	sub    $0x18,%esp
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01036bb:	83 ec 04             	sub    $0x4,%esp
f01036be:	6a 01                	push   $0x1
f01036c0:	8d 45 f0             	lea    -0x10(%ebp),%eax
f01036c3:	50                   	push   %eax
f01036c4:	ff 75 08             	pushl  0x8(%ebp)
f01036c7:	e8 44 e5 ff ff       	call   f0101c10 <envid2env>
f01036cc:	83 c4 10             	add    $0x10,%esp
f01036cf:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01036d2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01036d6:	79 05                	jns    f01036dd <sys_env_destroy+0x28>
		return r;
f01036d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036db:	eb 5b                	jmp    f0103738 <sys_env_destroy+0x83>
	if (e == curenv)
f01036dd:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01036e0:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f01036e5:	39 c2                	cmp    %eax,%edx
f01036e7:	75 1b                	jne    f0103704 <sys_env_destroy+0x4f>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01036e9:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f01036ee:	8b 40 4c             	mov    0x4c(%eax),%eax
f01036f1:	83 ec 08             	sub    $0x8,%esp
f01036f4:	50                   	push   %eax
f01036f5:	68 d5 61 10 f0       	push   $0xf01061d5
f01036fa:	e8 54 f9 ff ff       	call   f0103053 <cprintf>
f01036ff:	83 c4 10             	add    $0x10,%esp
f0103702:	eb 20                	jmp    f0103724 <sys_env_destroy+0x6f>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103704:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103707:	8b 50 4c             	mov    0x4c(%eax),%edx
f010370a:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f010370f:	8b 40 4c             	mov    0x4c(%eax),%eax
f0103712:	83 ec 04             	sub    $0x4,%esp
f0103715:	52                   	push   %edx
f0103716:	50                   	push   %eax
f0103717:	68 f0 61 10 f0       	push   $0xf01061f0
f010371c:	e8 32 f9 ff ff       	call   f0103053 <cprintf>
f0103721:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0103724:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103727:	83 ec 0c             	sub    $0xc,%esp
f010372a:	50                   	push   %eax
f010372b:	e8 6d f7 ff ff       	call   f0102e9d <env_destroy>
f0103730:	83 c4 10             	add    $0x10,%esp
	return 0;
f0103733:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103738:	c9                   	leave  
f0103739:	c3                   	ret    

f010373a <sys_env_sleep>:

static void sys_env_sleep()
{
f010373a:	55                   	push   %ebp
f010373b:	89 e5                	mov    %esp,%ebp
f010373d:	83 ec 08             	sub    $0x8,%esp
	env_run_cmd_prmpt();
f0103740:	e8 73 f7 ff ff       	call   f0102eb8 <env_run_cmd_prmpt>
}
f0103745:	90                   	nop
f0103746:	c9                   	leave  
f0103747:	c3                   	ret    

f0103748 <sys_allocate_page>:
//	E_INVAL if va >= UTOP, or va is not page-aligned.
//	E_INVAL if perm is inappropriate (see above).
//	E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_allocate_page(void *va, int perm)
{
f0103748:	55                   	push   %ebp
f0103749:	89 e5                	mov    %esp,%ebp
f010374b:	83 ec 28             	sub    $0x28,%esp
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!
	
	int r;
	struct Env *e = curenv;
f010374e:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f0103753:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//if ((r = envid2env(envid, &e, 1)) < 0)
		//return r;
	
	struct Frame_Info *ptr_frame_info ;
	r = allocate_frame(&ptr_frame_info) ;
f0103756:	83 ec 0c             	sub    $0xc,%esp
f0103759:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010375c:	50                   	push   %eax
f010375d:	e8 3c ec ff ff       	call   f010239e <allocate_frame>
f0103762:	83 c4 10             	add    $0x10,%esp
f0103765:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (r == E_NO_MEM)
f0103768:	83 7d f0 fc          	cmpl   $0xfffffffc,-0x10(%ebp)
f010376c:	75 08                	jne    f0103776 <sys_allocate_page+0x2e>
		return r ;
f010376e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103771:	e9 cc 00 00 00       	jmp    f0103842 <sys_allocate_page+0xfa>
	
	//check virtual address to be paged_aligned and < USER_TOP
	if ((uint32)va >= USER_TOP || (uint32)va % PAGE_SIZE != 0)
f0103776:	8b 45 08             	mov    0x8(%ebp),%eax
f0103779:	3d ff ff bf ee       	cmp    $0xeebfffff,%eax
f010377e:	77 0c                	ja     f010378c <sys_allocate_page+0x44>
f0103780:	8b 45 08             	mov    0x8(%ebp),%eax
f0103783:	25 ff 0f 00 00       	and    $0xfff,%eax
f0103788:	85 c0                	test   %eax,%eax
f010378a:	74 0a                	je     f0103796 <sys_allocate_page+0x4e>
		return E_INVAL;
f010378c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103791:	e9 ac 00 00 00       	jmp    f0103842 <sys_allocate_page+0xfa>
	
	//check permissions to be appropriatess
	if ((perm & (~PERM_AVAILABLE & ~PERM_WRITEABLE)) != (PERM_USER))
f0103796:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103799:	25 fd f1 ff ff       	and    $0xfffff1fd,%eax
f010379e:	83 f8 04             	cmp    $0x4,%eax
f01037a1:	74 0a                	je     f01037ad <sys_allocate_page+0x65>
		return E_INVAL;
f01037a3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01037a8:	e9 95 00 00 00       	jmp    f0103842 <sys_allocate_page+0xfa>
	
			
	uint32 physical_address = to_physical_address(ptr_frame_info) ;
f01037ad:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037b0:	83 ec 0c             	sub    $0xc,%esp
f01037b3:	50                   	push   %eax
f01037b4:	e8 a4 fe ff ff       	call   f010365d <to_physical_address>
f01037b9:	83 c4 10             	add    $0x10,%esp
f01037bc:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	memset(K_VIRTUAL_ADDRESS(physical_address), 0, PAGE_SIZE);
f01037bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01037c2:	89 45 e8             	mov    %eax,-0x18(%ebp)
f01037c5:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01037c8:	c1 e8 0c             	shr    $0xc,%eax
f01037cb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01037ce:	a1 a8 e7 14 f0       	mov    0xf014e7a8,%eax
f01037d3:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01037d6:	72 14                	jb     f01037ec <sys_allocate_page+0xa4>
f01037d8:	ff 75 e8             	pushl  -0x18(%ebp)
f01037db:	68 08 62 10 f0       	push   $0xf0106208
f01037e0:	6a 7a                	push   $0x7a
f01037e2:	68 37 62 10 f0       	push   $0xf0106237
f01037e7:	e8 42 c9 ff ff       	call   f010012e <_panic>
f01037ec:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01037ef:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01037f4:	83 ec 04             	sub    $0x4,%esp
f01037f7:	68 00 10 00 00       	push   $0x1000
f01037fc:	6a 00                	push   $0x0
f01037fe:	50                   	push   %eax
f01037ff:	e8 31 0f 00 00       	call   f0104735 <memset>
f0103804:	83 c4 10             	add    $0x10,%esp
		
	r = map_frame(e->env_pgdir, ptr_frame_info, va, perm) ;
f0103807:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010380a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010380d:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103810:	ff 75 0c             	pushl  0xc(%ebp)
f0103813:	ff 75 08             	pushl  0x8(%ebp)
f0103816:	52                   	push   %edx
f0103817:	50                   	push   %eax
f0103818:	e8 8e ed ff ff       	call   f01025ab <map_frame>
f010381d:	83 c4 10             	add    $0x10,%esp
f0103820:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (r == E_NO_MEM)
f0103823:	83 7d f0 fc          	cmpl   $0xfffffffc,-0x10(%ebp)
f0103827:	75 14                	jne    f010383d <sys_allocate_page+0xf5>
	{
		decrement_references(ptr_frame_info);
f0103829:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010382c:	83 ec 0c             	sub    $0xc,%esp
f010382f:	50                   	push   %eax
f0103830:	e8 07 ec ff ff       	call   f010243c <decrement_references>
f0103835:	83 c4 10             	add    $0x10,%esp
		return r;
f0103838:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010383b:	eb 05                	jmp    f0103842 <sys_allocate_page+0xfa>
	}
	return 0 ;
f010383d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103842:	c9                   	leave  
f0103843:	c3                   	ret    

f0103844 <sys_get_page>:
//	E_INVAL if va >= UTOP, or va is not page-aligned.
//	E_INVAL if perm is inappropriate (see above).
//	E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_get_page(void *va, int perm)
{
f0103844:	55                   	push   %ebp
f0103845:	89 e5                	mov    %esp,%ebp
f0103847:	83 ec 08             	sub    $0x8,%esp
	return get_page(curenv->env_pgdir, va, perm) ;
f010384a:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f010384f:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103852:	83 ec 04             	sub    $0x4,%esp
f0103855:	ff 75 0c             	pushl  0xc(%ebp)
f0103858:	ff 75 08             	pushl  0x8(%ebp)
f010385b:	50                   	push   %eax
f010385c:	e8 c8 ee ff ff       	call   f0102729 <get_page>
f0103861:	83 c4 10             	add    $0x10,%esp
}
f0103864:	c9                   	leave  
f0103865:	c3                   	ret    

f0103866 <sys_map_frame>:
//	-E_INVAL if (perm & PTE_W), but srcva is read-only in srcenvid's
//		address space.
//	-E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_map_frame(int32 srcenvid, void *srcva, int32 dstenvid, void *dstva, int perm)
{
f0103866:	55                   	push   %ebp
f0103867:	89 e5                	mov    %esp,%ebp
f0103869:	83 ec 08             	sub    $0x8,%esp
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	panic("sys_map_frame not implemented");
f010386c:	83 ec 04             	sub    $0x4,%esp
f010386f:	68 46 62 10 f0       	push   $0xf0106246
f0103874:	68 b1 00 00 00       	push   $0xb1
f0103879:	68 37 62 10 f0       	push   $0xf0106237
f010387e:	e8 ab c8 ff ff       	call   f010012e <_panic>

f0103883 <sys_unmap_frame>:
// Return 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if va >= UTOP, or va is not page-aligned.
static int sys_unmap_frame(int32 envid, void *va)
{
f0103883:	55                   	push   %ebp
f0103884:	89 e5                	mov    %esp,%ebp
f0103886:	83 ec 08             	sub    $0x8,%esp
	// Hint: This function is a wrapper around page_remove().
	
	// LAB 4: Your code here.
	panic("sys_page_unmap not implemented");
f0103889:	83 ec 04             	sub    $0x4,%esp
f010388c:	68 64 62 10 f0       	push   $0xf0106264
f0103891:	68 c0 00 00 00       	push   $0xc0
f0103896:	68 37 62 10 f0       	push   $0xf0106237
f010389b:	e8 8e c8 ff ff       	call   f010012e <_panic>

f01038a0 <sys_calculate_required_frames>:
}

uint32 sys_calculate_required_frames(uint32 start_virtual_address, uint32 size)
{
f01038a0:	55                   	push   %ebp
f01038a1:	89 e5                	mov    %esp,%ebp
f01038a3:	83 ec 08             	sub    $0x8,%esp
	return calculate_required_frames(curenv->env_pgdir, start_virtual_address, size); 
f01038a6:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f01038ab:	8b 40 5c             	mov    0x5c(%eax),%eax
f01038ae:	83 ec 04             	sub    $0x4,%esp
f01038b1:	ff 75 0c             	pushl  0xc(%ebp)
f01038b4:	ff 75 08             	pushl  0x8(%ebp)
f01038b7:	50                   	push   %eax
f01038b8:	e8 89 ee ff ff       	call   f0102746 <calculate_required_frames>
f01038bd:	83 c4 10             	add    $0x10,%esp
}
f01038c0:	c9                   	leave  
f01038c1:	c3                   	ret    

f01038c2 <sys_calculate_free_frames>:

uint32 sys_calculate_free_frames()
{
f01038c2:	55                   	push   %ebp
f01038c3:	89 e5                	mov    %esp,%ebp
f01038c5:	83 ec 08             	sub    $0x8,%esp
	return calculate_free_frames();
f01038c8:	e8 96 ee ff ff       	call   f0102763 <calculate_free_frames>
}
f01038cd:	c9                   	leave  
f01038ce:	c3                   	ret    

f01038cf <sys_freeMem>:
void sys_freeMem(void* start_virtual_address, uint32 size)
{
f01038cf:	55                   	push   %ebp
f01038d0:	89 e5                	mov    %esp,%ebp
f01038d2:	83 ec 08             	sub    $0x8,%esp
	freeMem((uint32*)curenv->env_pgdir, (void*)start_virtual_address, size);
f01038d5:	a1 30 df 14 f0       	mov    0xf014df30,%eax
f01038da:	8b 40 5c             	mov    0x5c(%eax),%eax
f01038dd:	83 ec 04             	sub    $0x4,%esp
f01038e0:	ff 75 0c             	pushl  0xc(%ebp)
f01038e3:	ff 75 08             	pushl  0x8(%ebp)
f01038e6:	50                   	push   %eax
f01038e7:	e8 a4 ee ff ff       	call   f0102790 <freeMem>
f01038ec:	83 c4 10             	add    $0x10,%esp
	return;
f01038ef:	90                   	nop
}
f01038f0:	c9                   	leave  
f01038f1:	c3                   	ret    

f01038f2 <syscall>:
// Dispatches to the correct kernel function, passing the arguments.
uint32
syscall(uint32 syscallno, uint32 a1, uint32 a2, uint32 a3, uint32 a4, uint32 a5)
{
f01038f2:	55                   	push   %ebp
f01038f3:	89 e5                	mov    %esp,%ebp
f01038f5:	56                   	push   %esi
f01038f6:	53                   	push   %ebx
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	switch(syscallno)
f01038f7:	83 7d 08 0c          	cmpl   $0xc,0x8(%ebp)
f01038fb:	0f 87 19 01 00 00    	ja     f0103a1a <syscall+0x128>
f0103901:	8b 45 08             	mov    0x8(%ebp),%eax
f0103904:	c1 e0 02             	shl    $0x2,%eax
f0103907:	05 84 62 10 f0       	add    $0xf0106284,%eax
f010390c:	8b 00                	mov    (%eax),%eax
f010390e:	ff e0                	jmp    *%eax
	{
		case SYS_cputs:
			sys_cputs((const char*)a1,a2);
f0103910:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103913:	83 ec 08             	sub    $0x8,%esp
f0103916:	ff 75 10             	pushl  0x10(%ebp)
f0103919:	50                   	push   %eax
f010391a:	e8 51 fd ff ff       	call   f0103670 <sys_cputs>
f010391f:	83 c4 10             	add    $0x10,%esp
			return 0;
f0103922:	b8 00 00 00 00       	mov    $0x0,%eax
f0103927:	e9 f3 00 00 00       	jmp    f0103a1f <syscall+0x12d>
			break;
		case SYS_cgetc:
			return sys_cgetc();
f010392c:	e8 5e fd ff ff       	call   f010368f <sys_cgetc>
f0103931:	e9 e9 00 00 00       	jmp    f0103a1f <syscall+0x12d>
			break;
		case SYS_getenvid:
			return sys_getenvid();
f0103936:	e8 6d fd ff ff       	call   f01036a8 <sys_getenvid>
f010393b:	e9 df 00 00 00       	jmp    f0103a1f <syscall+0x12d>
			break;
		case SYS_env_destroy:
			return sys_env_destroy(a1);
f0103940:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103943:	83 ec 0c             	sub    $0xc,%esp
f0103946:	50                   	push   %eax
f0103947:	e8 69 fd ff ff       	call   f01036b5 <sys_env_destroy>
f010394c:	83 c4 10             	add    $0x10,%esp
f010394f:	e9 cb 00 00 00       	jmp    f0103a1f <syscall+0x12d>
			break;
		case SYS_env_sleep:
			sys_env_sleep();
f0103954:	e8 e1 fd ff ff       	call   f010373a <sys_env_sleep>
			return 0;
f0103959:	b8 00 00 00 00       	mov    $0x0,%eax
f010395e:	e9 bc 00 00 00       	jmp    f0103a1f <syscall+0x12d>
			break;
		case SYS_calc_req_frames:
			return sys_calculate_required_frames(a1, a2);			
f0103963:	83 ec 08             	sub    $0x8,%esp
f0103966:	ff 75 10             	pushl  0x10(%ebp)
f0103969:	ff 75 0c             	pushl  0xc(%ebp)
f010396c:	e8 2f ff ff ff       	call   f01038a0 <sys_calculate_required_frames>
f0103971:	83 c4 10             	add    $0x10,%esp
f0103974:	e9 a6 00 00 00       	jmp    f0103a1f <syscall+0x12d>
			break;
		case SYS_calc_free_frames:
			return sys_calculate_free_frames();			
f0103979:	e8 44 ff ff ff       	call   f01038c2 <sys_calculate_free_frames>
f010397e:	e9 9c 00 00 00       	jmp    f0103a1f <syscall+0x12d>
			break;
		case SYS_freeMem:
			sys_freeMem((void*)a1, a2);
f0103983:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103986:	83 ec 08             	sub    $0x8,%esp
f0103989:	ff 75 10             	pushl  0x10(%ebp)
f010398c:	50                   	push   %eax
f010398d:	e8 3d ff ff ff       	call   f01038cf <sys_freeMem>
f0103992:	83 c4 10             	add    $0x10,%esp
			return 0;			
f0103995:	b8 00 00 00 00       	mov    $0x0,%eax
f010399a:	e9 80 00 00 00       	jmp    f0103a1f <syscall+0x12d>
			break;
		//======================
		
		case SYS_allocate_page:
			sys_allocate_page((void*)a1, a2);
f010399f:	8b 55 10             	mov    0x10(%ebp),%edx
f01039a2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039a5:	83 ec 08             	sub    $0x8,%esp
f01039a8:	52                   	push   %edx
f01039a9:	50                   	push   %eax
f01039aa:	e8 99 fd ff ff       	call   f0103748 <sys_allocate_page>
f01039af:	83 c4 10             	add    $0x10,%esp
			return 0;
f01039b2:	b8 00 00 00 00       	mov    $0x0,%eax
f01039b7:	eb 66                	jmp    f0103a1f <syscall+0x12d>
			break;
		case SYS_get_page:
			sys_get_page((void*)a1, a2);
f01039b9:	8b 55 10             	mov    0x10(%ebp),%edx
f01039bc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039bf:	83 ec 08             	sub    $0x8,%esp
f01039c2:	52                   	push   %edx
f01039c3:	50                   	push   %eax
f01039c4:	e8 7b fe ff ff       	call   f0103844 <sys_get_page>
f01039c9:	83 c4 10             	add    $0x10,%esp
			return 0;
f01039cc:	b8 00 00 00 00       	mov    $0x0,%eax
f01039d1:	eb 4c                	jmp    f0103a1f <syscall+0x12d>
		break;case SYS_map_frame:
			sys_map_frame(a1, (void*)a2, a3, (void*)a4, a5);
f01039d3:	8b 75 1c             	mov    0x1c(%ebp),%esi
f01039d6:	8b 5d 18             	mov    0x18(%ebp),%ebx
f01039d9:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01039dc:	8b 55 10             	mov    0x10(%ebp),%edx
f01039df:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039e2:	83 ec 0c             	sub    $0xc,%esp
f01039e5:	56                   	push   %esi
f01039e6:	53                   	push   %ebx
f01039e7:	51                   	push   %ecx
f01039e8:	52                   	push   %edx
f01039e9:	50                   	push   %eax
f01039ea:	e8 77 fe ff ff       	call   f0103866 <sys_map_frame>
f01039ef:	83 c4 20             	add    $0x20,%esp
			return 0;
f01039f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01039f7:	eb 26                	jmp    f0103a1f <syscall+0x12d>
			break;
		case SYS_unmap_frame:
			sys_unmap_frame(a1, (void*)a2);
f01039f9:	8b 55 10             	mov    0x10(%ebp),%edx
f01039fc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039ff:	83 ec 08             	sub    $0x8,%esp
f0103a02:	52                   	push   %edx
f0103a03:	50                   	push   %eax
f0103a04:	e8 7a fe ff ff       	call   f0103883 <sys_unmap_frame>
f0103a09:	83 c4 10             	add    $0x10,%esp
			return 0;
f0103a0c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a11:	eb 0c                	jmp    f0103a1f <syscall+0x12d>
			break;
		case NSYSCALLS:	
			return 	-E_INVAL;
f0103a13:	b8 03 00 00 00       	mov    $0x3,%eax
f0103a18:	eb 05                	jmp    f0103a1f <syscall+0x12d>
			break;
	}
	//panic("syscall not implemented");
	return -E_INVAL;
f0103a1a:	b8 03 00 00 00       	mov    $0x3,%eax
}
f0103a1f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103a22:	5b                   	pop    %ebx
f0103a23:	5e                   	pop    %esi
f0103a24:	5d                   	pop    %ebp
f0103a25:	c3                   	ret    

f0103a26 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uint32*  addr)
{
f0103a26:	55                   	push   %ebp
f0103a27:	89 e5                	mov    %esp,%ebp
f0103a29:	83 ec 20             	sub    $0x20,%esp
	int l = *region_left, r = *region_right, any_matches = 0;
f0103a2c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a2f:	8b 00                	mov    (%eax),%eax
f0103a31:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0103a34:	8b 45 10             	mov    0x10(%ebp),%eax
f0103a37:	8b 00                	mov    (%eax),%eax
f0103a39:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0103a3c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	
	while (l <= r) {
f0103a43:	e9 ca 00 00 00       	jmp    f0103b12 <stab_binsearch+0xec>
		int true_m = (l + r) / 2, m = true_m;
f0103a48:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0103a4b:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0103a4e:	01 d0                	add    %edx,%eax
f0103a50:	89 c2                	mov    %eax,%edx
f0103a52:	c1 ea 1f             	shr    $0x1f,%edx
f0103a55:	01 d0                	add    %edx,%eax
f0103a57:	d1 f8                	sar    %eax
f0103a59:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103a5c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103a5f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103a62:	eb 03                	jmp    f0103a67 <stab_binsearch+0x41>
			m--;
f0103a64:	ff 4d f0             	decl   -0x10(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103a67:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103a6a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0103a6d:	7c 1e                	jl     f0103a8d <stab_binsearch+0x67>
f0103a6f:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103a72:	89 d0                	mov    %edx,%eax
f0103a74:	01 c0                	add    %eax,%eax
f0103a76:	01 d0                	add    %edx,%eax
f0103a78:	c1 e0 02             	shl    $0x2,%eax
f0103a7b:	89 c2                	mov    %eax,%edx
f0103a7d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a80:	01 d0                	add    %edx,%eax
f0103a82:	8a 40 04             	mov    0x4(%eax),%al
f0103a85:	0f b6 c0             	movzbl %al,%eax
f0103a88:	3b 45 14             	cmp    0x14(%ebp),%eax
f0103a8b:	75 d7                	jne    f0103a64 <stab_binsearch+0x3e>
			m--;
		if (m < l) {	// no match in [l, m]
f0103a8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103a90:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0103a93:	7d 09                	jge    f0103a9e <stab_binsearch+0x78>
			l = true_m + 1;
f0103a95:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103a98:	40                   	inc    %eax
f0103a99:	89 45 fc             	mov    %eax,-0x4(%ebp)
			continue;
f0103a9c:	eb 74                	jmp    f0103b12 <stab_binsearch+0xec>
		}

		// actual binary search
		any_matches = 1;
f0103a9e:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
		if (stabs[m].n_value < addr) {
f0103aa5:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103aa8:	89 d0                	mov    %edx,%eax
f0103aaa:	01 c0                	add    %eax,%eax
f0103aac:	01 d0                	add    %edx,%eax
f0103aae:	c1 e0 02             	shl    $0x2,%eax
f0103ab1:	89 c2                	mov    %eax,%edx
f0103ab3:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ab6:	01 d0                	add    %edx,%eax
f0103ab8:	8b 40 08             	mov    0x8(%eax),%eax
f0103abb:	3b 45 18             	cmp    0x18(%ebp),%eax
f0103abe:	73 11                	jae    f0103ad1 <stab_binsearch+0xab>
			*region_left = m;
f0103ac0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ac3:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103ac6:	89 10                	mov    %edx,(%eax)
			l = true_m + 1;
f0103ac8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103acb:	40                   	inc    %eax
f0103acc:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0103acf:	eb 41                	jmp    f0103b12 <stab_binsearch+0xec>
		} else if (stabs[m].n_value > addr) {
f0103ad1:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103ad4:	89 d0                	mov    %edx,%eax
f0103ad6:	01 c0                	add    %eax,%eax
f0103ad8:	01 d0                	add    %edx,%eax
f0103ada:	c1 e0 02             	shl    $0x2,%eax
f0103add:	89 c2                	mov    %eax,%edx
f0103adf:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ae2:	01 d0                	add    %edx,%eax
f0103ae4:	8b 40 08             	mov    0x8(%eax),%eax
f0103ae7:	3b 45 18             	cmp    0x18(%ebp),%eax
f0103aea:	76 14                	jbe    f0103b00 <stab_binsearch+0xda>
			*region_right = m - 1;
f0103aec:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103aef:	8d 50 ff             	lea    -0x1(%eax),%edx
f0103af2:	8b 45 10             	mov    0x10(%ebp),%eax
f0103af5:	89 10                	mov    %edx,(%eax)
			r = m - 1;
f0103af7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103afa:	48                   	dec    %eax
f0103afb:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0103afe:	eb 12                	jmp    f0103b12 <stab_binsearch+0xec>
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103b00:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b03:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103b06:	89 10                	mov    %edx,(%eax)
			l = m;
f0103b08:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103b0b:	89 45 fc             	mov    %eax,-0x4(%ebp)
			addr++;
f0103b0e:	83 45 18 04          	addl   $0x4,0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uint32*  addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0103b12:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0103b15:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f0103b18:	0f 8e 2a ff ff ff    	jle    f0103a48 <stab_binsearch+0x22>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103b1e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0103b22:	75 0f                	jne    f0103b33 <stab_binsearch+0x10d>
		*region_right = *region_left - 1;
f0103b24:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b27:	8b 00                	mov    (%eax),%eax
f0103b29:	8d 50 ff             	lea    -0x1(%eax),%edx
f0103b2c:	8b 45 10             	mov    0x10(%ebp),%eax
f0103b2f:	89 10                	mov    %edx,(%eax)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0103b31:	eb 3d                	jmp    f0103b70 <stab_binsearch+0x14a>

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103b33:	8b 45 10             	mov    0x10(%ebp),%eax
f0103b36:	8b 00                	mov    (%eax),%eax
f0103b38:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0103b3b:	eb 03                	jmp    f0103b40 <stab_binsearch+0x11a>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103b3d:	ff 4d fc             	decl   -0x4(%ebp)
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0103b40:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b43:	8b 00                	mov    (%eax),%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103b45:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0103b48:	7d 1e                	jge    f0103b68 <stab_binsearch+0x142>
		     l > *region_left && stabs[l].n_type != type;
f0103b4a:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0103b4d:	89 d0                	mov    %edx,%eax
f0103b4f:	01 c0                	add    %eax,%eax
f0103b51:	01 d0                	add    %edx,%eax
f0103b53:	c1 e0 02             	shl    $0x2,%eax
f0103b56:	89 c2                	mov    %eax,%edx
f0103b58:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b5b:	01 d0                	add    %edx,%eax
f0103b5d:	8a 40 04             	mov    0x4(%eax),%al
f0103b60:	0f b6 c0             	movzbl %al,%eax
f0103b63:	3b 45 14             	cmp    0x14(%ebp),%eax
f0103b66:	75 d5                	jne    f0103b3d <stab_binsearch+0x117>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103b68:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b6b:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0103b6e:	89 10                	mov    %edx,(%eax)
	}
}
f0103b70:	90                   	nop
f0103b71:	c9                   	leave  
f0103b72:	c3                   	ret    

f0103b73 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uint32*  addr, struct Eipdebuginfo *info)
{
f0103b73:	55                   	push   %ebp
f0103b74:	89 e5                	mov    %esp,%ebp
f0103b76:	83 ec 38             	sub    $0x38,%esp
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103b79:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b7c:	c7 00 b8 62 10 f0    	movl   $0xf01062b8,(%eax)
	info->eip_line = 0;
f0103b82:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b85:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	info->eip_fn_name = "<unknown>";
f0103b8c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b8f:	c7 40 08 b8 62 10 f0 	movl   $0xf01062b8,0x8(%eax)
	info->eip_fn_namelen = 9;
f0103b96:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b99:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
	info->eip_fn_addr = addr;
f0103ba0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ba3:	8b 55 08             	mov    0x8(%ebp),%edx
f0103ba6:	89 50 10             	mov    %edx,0x10(%eax)
	info->eip_fn_narg = 0;
f0103ba9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103bac:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

	// Find the relevant set of stabs
	if ((uint32)addr >= USER_LIMIT) {
f0103bb3:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bb6:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0103bbb:	76 1e                	jbe    f0103bdb <debuginfo_eip+0x68>
		stabs = __STAB_BEGIN__;
f0103bbd:	c7 45 f4 10 65 10 f0 	movl   $0xf0106510,-0xc(%ebp)
		stab_end = __STAB_END__;
f0103bc4:	c7 45 f0 30 ed 10 f0 	movl   $0xf010ed30,-0x10(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0103bcb:	c7 45 ec 31 ed 10 f0 	movl   $0xf010ed31,-0x14(%ebp)
		stabstr_end = __STABSTR_END__;
f0103bd2:	c7 45 e8 cb 25 11 f0 	movl   $0xf01125cb,-0x18(%ebp)
f0103bd9:	eb 2a                	jmp    f0103c05 <debuginfo_eip+0x92>
		// The user-application linker script, user/user.ld,
		// puts information about the application's stabs (equivalent
		// to __STAB_BEGIN__, __STAB_END__, __STABSTR_BEGIN__, and
		// __STABSTR_END__) in a structure located at virtual address
		// USTABDATA.
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;
f0103bdb:	c7 45 e0 00 00 20 00 	movl   $0x200000,-0x20(%ebp)

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		
		stabs = usd->stabs;
f0103be2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103be5:	8b 00                	mov    (%eax),%eax
f0103be7:	89 45 f4             	mov    %eax,-0xc(%ebp)
		stab_end = usd->stab_end;
f0103bea:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103bed:	8b 40 04             	mov    0x4(%eax),%eax
f0103bf0:	89 45 f0             	mov    %eax,-0x10(%ebp)
		stabstr = usd->stabstr;
f0103bf3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103bf6:	8b 40 08             	mov    0x8(%eax),%eax
f0103bf9:	89 45 ec             	mov    %eax,-0x14(%ebp)
		stabstr_end = usd->stabstr_end;
f0103bfc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103bff:	8b 40 0c             	mov    0xc(%eax),%eax
f0103c02:	89 45 e8             	mov    %eax,-0x18(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103c05:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103c08:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f0103c0b:	76 0a                	jbe    f0103c17 <debuginfo_eip+0xa4>
f0103c0d:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103c10:	48                   	dec    %eax
f0103c11:	8a 00                	mov    (%eax),%al
f0103c13:	84 c0                	test   %al,%al
f0103c15:	74 0a                	je     f0103c21 <debuginfo_eip+0xae>
		return -1;
f0103c17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c1c:	e9 01 02 00 00       	jmp    f0103e22 <debuginfo_eip+0x2af>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103c21:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103c28:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103c2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103c2e:	29 c2                	sub    %eax,%edx
f0103c30:	89 d0                	mov    %edx,%eax
f0103c32:	c1 f8 02             	sar    $0x2,%eax
f0103c35:	89 c2                	mov    %eax,%edx
f0103c37:	89 d0                	mov    %edx,%eax
f0103c39:	c1 e0 02             	shl    $0x2,%eax
f0103c3c:	01 d0                	add    %edx,%eax
f0103c3e:	c1 e0 02             	shl    $0x2,%eax
f0103c41:	01 d0                	add    %edx,%eax
f0103c43:	c1 e0 02             	shl    $0x2,%eax
f0103c46:	01 d0                	add    %edx,%eax
f0103c48:	89 c1                	mov    %eax,%ecx
f0103c4a:	c1 e1 08             	shl    $0x8,%ecx
f0103c4d:	01 c8                	add    %ecx,%eax
f0103c4f:	89 c1                	mov    %eax,%ecx
f0103c51:	c1 e1 10             	shl    $0x10,%ecx
f0103c54:	01 c8                	add    %ecx,%eax
f0103c56:	01 c0                	add    %eax,%eax
f0103c58:	01 d0                	add    %edx,%eax
f0103c5a:	48                   	dec    %eax
f0103c5b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103c5e:	ff 75 08             	pushl  0x8(%ebp)
f0103c61:	6a 64                	push   $0x64
f0103c63:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0103c66:	50                   	push   %eax
f0103c67:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0103c6a:	50                   	push   %eax
f0103c6b:	ff 75 f4             	pushl  -0xc(%ebp)
f0103c6e:	e8 b3 fd ff ff       	call   f0103a26 <stab_binsearch>
f0103c73:	83 c4 14             	add    $0x14,%esp
	if (lfile == 0)
f0103c76:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103c79:	85 c0                	test   %eax,%eax
f0103c7b:	75 0a                	jne    f0103c87 <debuginfo_eip+0x114>
		return -1;
f0103c7d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c82:	e9 9b 01 00 00       	jmp    f0103e22 <debuginfo_eip+0x2af>

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103c87:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103c8a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	rfun = rfile;
f0103c8d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103c90:	89 45 cc             	mov    %eax,-0x34(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103c93:	ff 75 08             	pushl  0x8(%ebp)
f0103c96:	6a 24                	push   $0x24
f0103c98:	8d 45 cc             	lea    -0x34(%ebp),%eax
f0103c9b:	50                   	push   %eax
f0103c9c:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0103c9f:	50                   	push   %eax
f0103ca0:	ff 75 f4             	pushl  -0xc(%ebp)
f0103ca3:	e8 7e fd ff ff       	call   f0103a26 <stab_binsearch>
f0103ca8:	83 c4 14             	add    $0x14,%esp

	if (lfun <= rfun) {
f0103cab:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0103cae:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103cb1:	39 c2                	cmp    %eax,%edx
f0103cb3:	0f 8f 86 00 00 00    	jg     f0103d3f <debuginfo_eip+0x1cc>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103cb9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103cbc:	89 c2                	mov    %eax,%edx
f0103cbe:	89 d0                	mov    %edx,%eax
f0103cc0:	01 c0                	add    %eax,%eax
f0103cc2:	01 d0                	add    %edx,%eax
f0103cc4:	c1 e0 02             	shl    $0x2,%eax
f0103cc7:	89 c2                	mov    %eax,%edx
f0103cc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103ccc:	01 d0                	add    %edx,%eax
f0103cce:	8b 00                	mov    (%eax),%eax
f0103cd0:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0103cd3:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0103cd6:	29 d1                	sub    %edx,%ecx
f0103cd8:	89 ca                	mov    %ecx,%edx
f0103cda:	39 d0                	cmp    %edx,%eax
f0103cdc:	73 22                	jae    f0103d00 <debuginfo_eip+0x18d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103cde:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103ce1:	89 c2                	mov    %eax,%edx
f0103ce3:	89 d0                	mov    %edx,%eax
f0103ce5:	01 c0                	add    %eax,%eax
f0103ce7:	01 d0                	add    %edx,%eax
f0103ce9:	c1 e0 02             	shl    $0x2,%eax
f0103cec:	89 c2                	mov    %eax,%edx
f0103cee:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103cf1:	01 d0                	add    %edx,%eax
f0103cf3:	8b 10                	mov    (%eax),%edx
f0103cf5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103cf8:	01 c2                	add    %eax,%edx
f0103cfa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103cfd:	89 50 08             	mov    %edx,0x8(%eax)
		info->eip_fn_addr = (uint32*) stabs[lfun].n_value;
f0103d00:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103d03:	89 c2                	mov    %eax,%edx
f0103d05:	89 d0                	mov    %edx,%eax
f0103d07:	01 c0                	add    %eax,%eax
f0103d09:	01 d0                	add    %edx,%eax
f0103d0b:	c1 e0 02             	shl    $0x2,%eax
f0103d0e:	89 c2                	mov    %eax,%edx
f0103d10:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103d13:	01 d0                	add    %edx,%eax
f0103d15:	8b 50 08             	mov    0x8(%eax),%edx
f0103d18:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d1b:	89 50 10             	mov    %edx,0x10(%eax)
		addr = (uint32*)(addr - (info->eip_fn_addr));
f0103d1e:	8b 55 08             	mov    0x8(%ebp),%edx
f0103d21:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d24:	8b 40 10             	mov    0x10(%eax),%eax
f0103d27:	29 c2                	sub    %eax,%edx
f0103d29:	89 d0                	mov    %edx,%eax
f0103d2b:	c1 f8 02             	sar    $0x2,%eax
f0103d2e:	89 45 08             	mov    %eax,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0103d31:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103d34:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		rline = rfun;
f0103d37:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103d3a:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103d3d:	eb 15                	jmp    f0103d54 <debuginfo_eip+0x1e1>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103d3f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d42:	8b 55 08             	mov    0x8(%ebp),%edx
f0103d45:	89 50 10             	mov    %edx,0x10(%eax)
		lline = lfile;
f0103d48:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103d4b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		rline = rfile;
f0103d4e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103d51:	89 45 dc             	mov    %eax,-0x24(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103d54:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d57:	8b 40 08             	mov    0x8(%eax),%eax
f0103d5a:	83 ec 08             	sub    $0x8,%esp
f0103d5d:	6a 3a                	push   $0x3a
f0103d5f:	50                   	push   %eax
f0103d60:	e8 a4 09 00 00       	call   f0104709 <strfind>
f0103d65:	83 c4 10             	add    $0x10,%esp
f0103d68:	89 c2                	mov    %eax,%edx
f0103d6a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d6d:	8b 40 08             	mov    0x8(%eax),%eax
f0103d70:	29 c2                	sub    %eax,%edx
f0103d72:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d75:	89 50 0c             	mov    %edx,0xc(%eax)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103d78:	eb 03                	jmp    f0103d7d <debuginfo_eip+0x20a>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103d7a:	ff 4d e4             	decl   -0x1c(%ebp)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103d7d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103d80:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0103d83:	7c 4e                	jl     f0103dd3 <debuginfo_eip+0x260>
	       && stabs[lline].n_type != N_SOL
f0103d85:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103d88:	89 d0                	mov    %edx,%eax
f0103d8a:	01 c0                	add    %eax,%eax
f0103d8c:	01 d0                	add    %edx,%eax
f0103d8e:	c1 e0 02             	shl    $0x2,%eax
f0103d91:	89 c2                	mov    %eax,%edx
f0103d93:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103d96:	01 d0                	add    %edx,%eax
f0103d98:	8a 40 04             	mov    0x4(%eax),%al
f0103d9b:	3c 84                	cmp    $0x84,%al
f0103d9d:	74 34                	je     f0103dd3 <debuginfo_eip+0x260>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103d9f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103da2:	89 d0                	mov    %edx,%eax
f0103da4:	01 c0                	add    %eax,%eax
f0103da6:	01 d0                	add    %edx,%eax
f0103da8:	c1 e0 02             	shl    $0x2,%eax
f0103dab:	89 c2                	mov    %eax,%edx
f0103dad:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103db0:	01 d0                	add    %edx,%eax
f0103db2:	8a 40 04             	mov    0x4(%eax),%al
f0103db5:	3c 64                	cmp    $0x64,%al
f0103db7:	75 c1                	jne    f0103d7a <debuginfo_eip+0x207>
f0103db9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103dbc:	89 d0                	mov    %edx,%eax
f0103dbe:	01 c0                	add    %eax,%eax
f0103dc0:	01 d0                	add    %edx,%eax
f0103dc2:	c1 e0 02             	shl    $0x2,%eax
f0103dc5:	89 c2                	mov    %eax,%edx
f0103dc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103dca:	01 d0                	add    %edx,%eax
f0103dcc:	8b 40 08             	mov    0x8(%eax),%eax
f0103dcf:	85 c0                	test   %eax,%eax
f0103dd1:	74 a7                	je     f0103d7a <debuginfo_eip+0x207>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103dd3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103dd6:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0103dd9:	7c 42                	jl     f0103e1d <debuginfo_eip+0x2aa>
f0103ddb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103dde:	89 d0                	mov    %edx,%eax
f0103de0:	01 c0                	add    %eax,%eax
f0103de2:	01 d0                	add    %edx,%eax
f0103de4:	c1 e0 02             	shl    $0x2,%eax
f0103de7:	89 c2                	mov    %eax,%edx
f0103de9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103dec:	01 d0                	add    %edx,%eax
f0103dee:	8b 00                	mov    (%eax),%eax
f0103df0:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0103df3:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0103df6:	29 d1                	sub    %edx,%ecx
f0103df8:	89 ca                	mov    %ecx,%edx
f0103dfa:	39 d0                	cmp    %edx,%eax
f0103dfc:	73 1f                	jae    f0103e1d <debuginfo_eip+0x2aa>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103dfe:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103e01:	89 d0                	mov    %edx,%eax
f0103e03:	01 c0                	add    %eax,%eax
f0103e05:	01 d0                	add    %edx,%eax
f0103e07:	c1 e0 02             	shl    $0x2,%eax
f0103e0a:	89 c2                	mov    %eax,%edx
f0103e0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103e0f:	01 d0                	add    %edx,%eax
f0103e11:	8b 10                	mov    (%eax),%edx
f0103e13:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103e16:	01 c2                	add    %eax,%edx
f0103e18:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103e1b:	89 10                	mov    %edx,(%eax)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f0103e1d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103e22:	c9                   	leave  
f0103e23:	c3                   	ret    

f0103e24 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103e24:	55                   	push   %ebp
f0103e25:	89 e5                	mov    %esp,%ebp
f0103e27:	53                   	push   %ebx
f0103e28:	83 ec 14             	sub    $0x14,%esp
f0103e2b:	8b 45 10             	mov    0x10(%ebp),%eax
f0103e2e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103e31:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e34:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103e37:	8b 45 18             	mov    0x18(%ebp),%eax
f0103e3a:	ba 00 00 00 00       	mov    $0x0,%edx
f0103e3f:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f0103e42:	77 55                	ja     f0103e99 <printnum+0x75>
f0103e44:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f0103e47:	72 05                	jb     f0103e4e <printnum+0x2a>
f0103e49:	3b 45 f0             	cmp    -0x10(%ebp),%eax
f0103e4c:	77 4b                	ja     f0103e99 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103e4e:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0103e51:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103e54:	8b 45 18             	mov    0x18(%ebp),%eax
f0103e57:	ba 00 00 00 00       	mov    $0x0,%edx
f0103e5c:	52                   	push   %edx
f0103e5d:	50                   	push   %eax
f0103e5e:	ff 75 f4             	pushl  -0xc(%ebp)
f0103e61:	ff 75 f0             	pushl  -0x10(%ebp)
f0103e64:	e8 5b 0c 00 00       	call   f0104ac4 <__udivdi3>
f0103e69:	83 c4 10             	add    $0x10,%esp
f0103e6c:	83 ec 04             	sub    $0x4,%esp
f0103e6f:	ff 75 20             	pushl  0x20(%ebp)
f0103e72:	53                   	push   %ebx
f0103e73:	ff 75 18             	pushl  0x18(%ebp)
f0103e76:	52                   	push   %edx
f0103e77:	50                   	push   %eax
f0103e78:	ff 75 0c             	pushl  0xc(%ebp)
f0103e7b:	ff 75 08             	pushl  0x8(%ebp)
f0103e7e:	e8 a1 ff ff ff       	call   f0103e24 <printnum>
f0103e83:	83 c4 20             	add    $0x20,%esp
f0103e86:	eb 1a                	jmp    f0103ea2 <printnum+0x7e>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103e88:	83 ec 08             	sub    $0x8,%esp
f0103e8b:	ff 75 0c             	pushl  0xc(%ebp)
f0103e8e:	ff 75 20             	pushl  0x20(%ebp)
f0103e91:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e94:	ff d0                	call   *%eax
f0103e96:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103e99:	ff 4d 1c             	decl   0x1c(%ebp)
f0103e9c:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
f0103ea0:	7f e6                	jg     f0103e88 <printnum+0x64>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103ea2:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103ea5:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103eaa:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103ead:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103eb0:	53                   	push   %ebx
f0103eb1:	51                   	push   %ecx
f0103eb2:	52                   	push   %edx
f0103eb3:	50                   	push   %eax
f0103eb4:	e8 1b 0d 00 00       	call   f0104bd4 <__umoddi3>
f0103eb9:	83 c4 10             	add    $0x10,%esp
f0103ebc:	05 80 63 10 f0       	add    $0xf0106380,%eax
f0103ec1:	8a 00                	mov    (%eax),%al
f0103ec3:	0f be c0             	movsbl %al,%eax
f0103ec6:	83 ec 08             	sub    $0x8,%esp
f0103ec9:	ff 75 0c             	pushl  0xc(%ebp)
f0103ecc:	50                   	push   %eax
f0103ecd:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ed0:	ff d0                	call   *%eax
f0103ed2:	83 c4 10             	add    $0x10,%esp
}
f0103ed5:	90                   	nop
f0103ed6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103ed9:	c9                   	leave  
f0103eda:	c3                   	ret    

f0103edb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103edb:	55                   	push   %ebp
f0103edc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103ede:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f0103ee2:	7e 1c                	jle    f0103f00 <getuint+0x25>
		return va_arg(*ap, unsigned long long);
f0103ee4:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ee7:	8b 00                	mov    (%eax),%eax
f0103ee9:	8d 50 08             	lea    0x8(%eax),%edx
f0103eec:	8b 45 08             	mov    0x8(%ebp),%eax
f0103eef:	89 10                	mov    %edx,(%eax)
f0103ef1:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ef4:	8b 00                	mov    (%eax),%eax
f0103ef6:	83 e8 08             	sub    $0x8,%eax
f0103ef9:	8b 50 04             	mov    0x4(%eax),%edx
f0103efc:	8b 00                	mov    (%eax),%eax
f0103efe:	eb 40                	jmp    f0103f40 <getuint+0x65>
	else if (lflag)
f0103f00:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103f04:	74 1e                	je     f0103f24 <getuint+0x49>
		return va_arg(*ap, unsigned long);
f0103f06:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f09:	8b 00                	mov    (%eax),%eax
f0103f0b:	8d 50 04             	lea    0x4(%eax),%edx
f0103f0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f11:	89 10                	mov    %edx,(%eax)
f0103f13:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f16:	8b 00                	mov    (%eax),%eax
f0103f18:	83 e8 04             	sub    $0x4,%eax
f0103f1b:	8b 00                	mov    (%eax),%eax
f0103f1d:	ba 00 00 00 00       	mov    $0x0,%edx
f0103f22:	eb 1c                	jmp    f0103f40 <getuint+0x65>
	else
		return va_arg(*ap, unsigned int);
f0103f24:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f27:	8b 00                	mov    (%eax),%eax
f0103f29:	8d 50 04             	lea    0x4(%eax),%edx
f0103f2c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f2f:	89 10                	mov    %edx,(%eax)
f0103f31:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f34:	8b 00                	mov    (%eax),%eax
f0103f36:	83 e8 04             	sub    $0x4,%eax
f0103f39:	8b 00                	mov    (%eax),%eax
f0103f3b:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103f40:	5d                   	pop    %ebp
f0103f41:	c3                   	ret    

f0103f42 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0103f42:	55                   	push   %ebp
f0103f43:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103f45:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f0103f49:	7e 1c                	jle    f0103f67 <getint+0x25>
		return va_arg(*ap, long long);
f0103f4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f4e:	8b 00                	mov    (%eax),%eax
f0103f50:	8d 50 08             	lea    0x8(%eax),%edx
f0103f53:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f56:	89 10                	mov    %edx,(%eax)
f0103f58:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f5b:	8b 00                	mov    (%eax),%eax
f0103f5d:	83 e8 08             	sub    $0x8,%eax
f0103f60:	8b 50 04             	mov    0x4(%eax),%edx
f0103f63:	8b 00                	mov    (%eax),%eax
f0103f65:	eb 38                	jmp    f0103f9f <getint+0x5d>
	else if (lflag)
f0103f67:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103f6b:	74 1a                	je     f0103f87 <getint+0x45>
		return va_arg(*ap, long);
f0103f6d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f70:	8b 00                	mov    (%eax),%eax
f0103f72:	8d 50 04             	lea    0x4(%eax),%edx
f0103f75:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f78:	89 10                	mov    %edx,(%eax)
f0103f7a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f7d:	8b 00                	mov    (%eax),%eax
f0103f7f:	83 e8 04             	sub    $0x4,%eax
f0103f82:	8b 00                	mov    (%eax),%eax
f0103f84:	99                   	cltd   
f0103f85:	eb 18                	jmp    f0103f9f <getint+0x5d>
	else
		return va_arg(*ap, int);
f0103f87:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f8a:	8b 00                	mov    (%eax),%eax
f0103f8c:	8d 50 04             	lea    0x4(%eax),%edx
f0103f8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f92:	89 10                	mov    %edx,(%eax)
f0103f94:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f97:	8b 00                	mov    (%eax),%eax
f0103f99:	83 e8 04             	sub    $0x4,%eax
f0103f9c:	8b 00                	mov    (%eax),%eax
f0103f9e:	99                   	cltd   
}
f0103f9f:	5d                   	pop    %ebp
f0103fa0:	c3                   	ret    

f0103fa1 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103fa1:	55                   	push   %ebp
f0103fa2:	89 e5                	mov    %esp,%ebp
f0103fa4:	56                   	push   %esi
f0103fa5:	53                   	push   %ebx
f0103fa6:	83 ec 20             	sub    $0x20,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103fa9:	eb 17                	jmp    f0103fc2 <vprintfmt+0x21>
			if (ch == '\0')
f0103fab:	85 db                	test   %ebx,%ebx
f0103fad:	0f 84 af 03 00 00    	je     f0104362 <vprintfmt+0x3c1>
				return;
			putch(ch, putdat);
f0103fb3:	83 ec 08             	sub    $0x8,%esp
f0103fb6:	ff 75 0c             	pushl  0xc(%ebp)
f0103fb9:	53                   	push   %ebx
f0103fba:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fbd:	ff d0                	call   *%eax
f0103fbf:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103fc2:	8b 45 10             	mov    0x10(%ebp),%eax
f0103fc5:	8d 50 01             	lea    0x1(%eax),%edx
f0103fc8:	89 55 10             	mov    %edx,0x10(%ebp)
f0103fcb:	8a 00                	mov    (%eax),%al
f0103fcd:	0f b6 d8             	movzbl %al,%ebx
f0103fd0:	83 fb 25             	cmp    $0x25,%ebx
f0103fd3:	75 d6                	jne    f0103fab <vprintfmt+0xa>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
f0103fd5:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
		width = -1;
f0103fd9:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
		precision = -1;
f0103fe0:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0103fe7:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
		altflag = 0;
f0103fee:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ff5:	8b 45 10             	mov    0x10(%ebp),%eax
f0103ff8:	8d 50 01             	lea    0x1(%eax),%edx
f0103ffb:	89 55 10             	mov    %edx,0x10(%ebp)
f0103ffe:	8a 00                	mov    (%eax),%al
f0104000:	0f b6 d8             	movzbl %al,%ebx
f0104003:	8d 43 dd             	lea    -0x23(%ebx),%eax
f0104006:	83 f8 55             	cmp    $0x55,%eax
f0104009:	0f 87 2b 03 00 00    	ja     f010433a <vprintfmt+0x399>
f010400f:	8b 04 85 a4 63 10 f0 	mov    -0xfef9c5c(,%eax,4),%eax
f0104016:	ff e0                	jmp    *%eax

		// flag to pad on the right
		case '-':
			padc = '-';
f0104018:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
			goto reswitch;
f010401c:	eb d7                	jmp    f0103ff5 <vprintfmt+0x54>
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010401e:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
			goto reswitch;
f0104022:	eb d1                	jmp    f0103ff5 <vprintfmt+0x54>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104024:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
				precision = precision * 10 + ch - '0';
f010402b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010402e:	89 d0                	mov    %edx,%eax
f0104030:	c1 e0 02             	shl    $0x2,%eax
f0104033:	01 d0                	add    %edx,%eax
f0104035:	01 c0                	add    %eax,%eax
f0104037:	01 d8                	add    %ebx,%eax
f0104039:	83 e8 30             	sub    $0x30,%eax
f010403c:	89 45 e0             	mov    %eax,-0x20(%ebp)
				ch = *fmt;
f010403f:	8b 45 10             	mov    0x10(%ebp),%eax
f0104042:	8a 00                	mov    (%eax),%al
f0104044:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
f0104047:	83 fb 2f             	cmp    $0x2f,%ebx
f010404a:	7e 3e                	jle    f010408a <vprintfmt+0xe9>
f010404c:	83 fb 39             	cmp    $0x39,%ebx
f010404f:	7f 39                	jg     f010408a <vprintfmt+0xe9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104051:	ff 45 10             	incl   0x10(%ebp)
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104054:	eb d5                	jmp    f010402b <vprintfmt+0x8a>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104056:	8b 45 14             	mov    0x14(%ebp),%eax
f0104059:	83 c0 04             	add    $0x4,%eax
f010405c:	89 45 14             	mov    %eax,0x14(%ebp)
f010405f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104062:	83 e8 04             	sub    $0x4,%eax
f0104065:	8b 00                	mov    (%eax),%eax
f0104067:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto process_precision;
f010406a:	eb 1f                	jmp    f010408b <vprintfmt+0xea>

		case '.':
			if (width < 0)
f010406c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104070:	79 83                	jns    f0103ff5 <vprintfmt+0x54>
				width = 0;
f0104072:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			goto reswitch;
f0104079:	e9 77 ff ff ff       	jmp    f0103ff5 <vprintfmt+0x54>

		case '#':
			altflag = 1;
f010407e:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0104085:	e9 6b ff ff ff       	jmp    f0103ff5 <vprintfmt+0x54>
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto process_precision;
f010408a:	90                   	nop
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010408b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010408f:	0f 89 60 ff ff ff    	jns    f0103ff5 <vprintfmt+0x54>
				width = precision, precision = -1;
f0104095:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104098:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010409b:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
			goto reswitch;
f01040a2:	e9 4e ff ff ff       	jmp    f0103ff5 <vprintfmt+0x54>

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01040a7:	ff 45 e8             	incl   -0x18(%ebp)
			goto reswitch;
f01040aa:	e9 46 ff ff ff       	jmp    f0103ff5 <vprintfmt+0x54>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01040af:	8b 45 14             	mov    0x14(%ebp),%eax
f01040b2:	83 c0 04             	add    $0x4,%eax
f01040b5:	89 45 14             	mov    %eax,0x14(%ebp)
f01040b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01040bb:	83 e8 04             	sub    $0x4,%eax
f01040be:	8b 00                	mov    (%eax),%eax
f01040c0:	83 ec 08             	sub    $0x8,%esp
f01040c3:	ff 75 0c             	pushl  0xc(%ebp)
f01040c6:	50                   	push   %eax
f01040c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01040ca:	ff d0                	call   *%eax
f01040cc:	83 c4 10             	add    $0x10,%esp
			break;
f01040cf:	e9 89 02 00 00       	jmp    f010435d <vprintfmt+0x3bc>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01040d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01040d7:	83 c0 04             	add    $0x4,%eax
f01040da:	89 45 14             	mov    %eax,0x14(%ebp)
f01040dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01040e0:	83 e8 04             	sub    $0x4,%eax
f01040e3:	8b 18                	mov    (%eax),%ebx
			if (err < 0)
f01040e5:	85 db                	test   %ebx,%ebx
f01040e7:	79 02                	jns    f01040eb <vprintfmt+0x14a>
				err = -err;
f01040e9:	f7 db                	neg    %ebx
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f01040eb:	83 fb 07             	cmp    $0x7,%ebx
f01040ee:	7f 0b                	jg     f01040fb <vprintfmt+0x15a>
f01040f0:	8b 34 9d 60 63 10 f0 	mov    -0xfef9ca0(,%ebx,4),%esi
f01040f7:	85 f6                	test   %esi,%esi
f01040f9:	75 19                	jne    f0104114 <vprintfmt+0x173>
				printfmt(putch, putdat, "error %d", err);
f01040fb:	53                   	push   %ebx
f01040fc:	68 91 63 10 f0       	push   $0xf0106391
f0104101:	ff 75 0c             	pushl  0xc(%ebp)
f0104104:	ff 75 08             	pushl  0x8(%ebp)
f0104107:	e8 5e 02 00 00       	call   f010436a <printfmt>
f010410c:	83 c4 10             	add    $0x10,%esp
			else
				printfmt(putch, putdat, "%s", p);
			break;
f010410f:	e9 49 02 00 00       	jmp    f010435d <vprintfmt+0x3bc>
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0104114:	56                   	push   %esi
f0104115:	68 9a 63 10 f0       	push   $0xf010639a
f010411a:	ff 75 0c             	pushl  0xc(%ebp)
f010411d:	ff 75 08             	pushl  0x8(%ebp)
f0104120:	e8 45 02 00 00       	call   f010436a <printfmt>
f0104125:	83 c4 10             	add    $0x10,%esp
			break;
f0104128:	e9 30 02 00 00       	jmp    f010435d <vprintfmt+0x3bc>

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010412d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104130:	83 c0 04             	add    $0x4,%eax
f0104133:	89 45 14             	mov    %eax,0x14(%ebp)
f0104136:	8b 45 14             	mov    0x14(%ebp),%eax
f0104139:	83 e8 04             	sub    $0x4,%eax
f010413c:	8b 30                	mov    (%eax),%esi
f010413e:	85 f6                	test   %esi,%esi
f0104140:	75 05                	jne    f0104147 <vprintfmt+0x1a6>
				p = "(null)";
f0104142:	be 9d 63 10 f0       	mov    $0xf010639d,%esi
			if (width > 0 && padc != '-')
f0104147:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010414b:	7e 6d                	jle    f01041ba <vprintfmt+0x219>
f010414d:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
f0104151:	74 67                	je     f01041ba <vprintfmt+0x219>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104153:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104156:	83 ec 08             	sub    $0x8,%esp
f0104159:	50                   	push   %eax
f010415a:	56                   	push   %esi
f010415b:	e8 0a 04 00 00       	call   f010456a <strnlen>
f0104160:	83 c4 10             	add    $0x10,%esp
f0104163:	29 45 e4             	sub    %eax,-0x1c(%ebp)
f0104166:	eb 16                	jmp    f010417e <vprintfmt+0x1dd>
					putch(padc, putdat);
f0104168:	0f be 45 db          	movsbl -0x25(%ebp),%eax
f010416c:	83 ec 08             	sub    $0x8,%esp
f010416f:	ff 75 0c             	pushl  0xc(%ebp)
f0104172:	50                   	push   %eax
f0104173:	8b 45 08             	mov    0x8(%ebp),%eax
f0104176:	ff d0                	call   *%eax
f0104178:	83 c4 10             	add    $0x10,%esp
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010417b:	ff 4d e4             	decl   -0x1c(%ebp)
f010417e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104182:	7f e4                	jg     f0104168 <vprintfmt+0x1c7>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104184:	eb 34                	jmp    f01041ba <vprintfmt+0x219>
				if (altflag && (ch < ' ' || ch > '~'))
f0104186:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010418a:	74 1c                	je     f01041a8 <vprintfmt+0x207>
f010418c:	83 fb 1f             	cmp    $0x1f,%ebx
f010418f:	7e 05                	jle    f0104196 <vprintfmt+0x1f5>
f0104191:	83 fb 7e             	cmp    $0x7e,%ebx
f0104194:	7e 12                	jle    f01041a8 <vprintfmt+0x207>
					putch('?', putdat);
f0104196:	83 ec 08             	sub    $0x8,%esp
f0104199:	ff 75 0c             	pushl  0xc(%ebp)
f010419c:	6a 3f                	push   $0x3f
f010419e:	8b 45 08             	mov    0x8(%ebp),%eax
f01041a1:	ff d0                	call   *%eax
f01041a3:	83 c4 10             	add    $0x10,%esp
f01041a6:	eb 0f                	jmp    f01041b7 <vprintfmt+0x216>
				else
					putch(ch, putdat);
f01041a8:	83 ec 08             	sub    $0x8,%esp
f01041ab:	ff 75 0c             	pushl  0xc(%ebp)
f01041ae:	53                   	push   %ebx
f01041af:	8b 45 08             	mov    0x8(%ebp),%eax
f01041b2:	ff d0                	call   *%eax
f01041b4:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01041b7:	ff 4d e4             	decl   -0x1c(%ebp)
f01041ba:	89 f0                	mov    %esi,%eax
f01041bc:	8d 70 01             	lea    0x1(%eax),%esi
f01041bf:	8a 00                	mov    (%eax),%al
f01041c1:	0f be d8             	movsbl %al,%ebx
f01041c4:	85 db                	test   %ebx,%ebx
f01041c6:	74 24                	je     f01041ec <vprintfmt+0x24b>
f01041c8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01041cc:	78 b8                	js     f0104186 <vprintfmt+0x1e5>
f01041ce:	ff 4d e0             	decl   -0x20(%ebp)
f01041d1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01041d5:	79 af                	jns    f0104186 <vprintfmt+0x1e5>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01041d7:	eb 13                	jmp    f01041ec <vprintfmt+0x24b>
				putch(' ', putdat);
f01041d9:	83 ec 08             	sub    $0x8,%esp
f01041dc:	ff 75 0c             	pushl  0xc(%ebp)
f01041df:	6a 20                	push   $0x20
f01041e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01041e4:	ff d0                	call   *%eax
f01041e6:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01041e9:	ff 4d e4             	decl   -0x1c(%ebp)
f01041ec:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01041f0:	7f e7                	jg     f01041d9 <vprintfmt+0x238>
				putch(' ', putdat);
			break;
f01041f2:	e9 66 01 00 00       	jmp    f010435d <vprintfmt+0x3bc>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01041f7:	83 ec 08             	sub    $0x8,%esp
f01041fa:	ff 75 e8             	pushl  -0x18(%ebp)
f01041fd:	8d 45 14             	lea    0x14(%ebp),%eax
f0104200:	50                   	push   %eax
f0104201:	e8 3c fd ff ff       	call   f0103f42 <getint>
f0104206:	83 c4 10             	add    $0x10,%esp
f0104209:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010420c:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((long long) num < 0) {
f010420f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104212:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104215:	85 d2                	test   %edx,%edx
f0104217:	79 23                	jns    f010423c <vprintfmt+0x29b>
				putch('-', putdat);
f0104219:	83 ec 08             	sub    $0x8,%esp
f010421c:	ff 75 0c             	pushl  0xc(%ebp)
f010421f:	6a 2d                	push   $0x2d
f0104221:	8b 45 08             	mov    0x8(%ebp),%eax
f0104224:	ff d0                	call   *%eax
f0104226:	83 c4 10             	add    $0x10,%esp
				num = -(long long) num;
f0104229:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010422c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010422f:	f7 d8                	neg    %eax
f0104231:	83 d2 00             	adc    $0x0,%edx
f0104234:	f7 da                	neg    %edx
f0104236:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104239:	89 55 f4             	mov    %edx,-0xc(%ebp)
			}
			base = 10;
f010423c:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f0104243:	e9 bc 00 00 00       	jmp    f0104304 <vprintfmt+0x363>

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104248:	83 ec 08             	sub    $0x8,%esp
f010424b:	ff 75 e8             	pushl  -0x18(%ebp)
f010424e:	8d 45 14             	lea    0x14(%ebp),%eax
f0104251:	50                   	push   %eax
f0104252:	e8 84 fc ff ff       	call   f0103edb <getuint>
f0104257:	83 c4 10             	add    $0x10,%esp
f010425a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010425d:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 10;
f0104260:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f0104267:	e9 98 00 00 00       	jmp    f0104304 <vprintfmt+0x363>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f010426c:	83 ec 08             	sub    $0x8,%esp
f010426f:	ff 75 0c             	pushl  0xc(%ebp)
f0104272:	6a 58                	push   $0x58
f0104274:	8b 45 08             	mov    0x8(%ebp),%eax
f0104277:	ff d0                	call   *%eax
f0104279:	83 c4 10             	add    $0x10,%esp
			putch('X', putdat);
f010427c:	83 ec 08             	sub    $0x8,%esp
f010427f:	ff 75 0c             	pushl  0xc(%ebp)
f0104282:	6a 58                	push   $0x58
f0104284:	8b 45 08             	mov    0x8(%ebp),%eax
f0104287:	ff d0                	call   *%eax
f0104289:	83 c4 10             	add    $0x10,%esp
			putch('X', putdat);
f010428c:	83 ec 08             	sub    $0x8,%esp
f010428f:	ff 75 0c             	pushl  0xc(%ebp)
f0104292:	6a 58                	push   $0x58
f0104294:	8b 45 08             	mov    0x8(%ebp),%eax
f0104297:	ff d0                	call   *%eax
f0104299:	83 c4 10             	add    $0x10,%esp
			break;
f010429c:	e9 bc 00 00 00       	jmp    f010435d <vprintfmt+0x3bc>

		// pointer
		case 'p':
			putch('0', putdat);
f01042a1:	83 ec 08             	sub    $0x8,%esp
f01042a4:	ff 75 0c             	pushl  0xc(%ebp)
f01042a7:	6a 30                	push   $0x30
f01042a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01042ac:	ff d0                	call   *%eax
f01042ae:	83 c4 10             	add    $0x10,%esp
			putch('x', putdat);
f01042b1:	83 ec 08             	sub    $0x8,%esp
f01042b4:	ff 75 0c             	pushl  0xc(%ebp)
f01042b7:	6a 78                	push   $0x78
f01042b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01042bc:	ff d0                	call   *%eax
f01042be:	83 c4 10             	add    $0x10,%esp
			num = (unsigned long long)
				(uint32) va_arg(ap, void *);
f01042c1:	8b 45 14             	mov    0x14(%ebp),%eax
f01042c4:	83 c0 04             	add    $0x4,%eax
f01042c7:	89 45 14             	mov    %eax,0x14(%ebp)
f01042ca:	8b 45 14             	mov    0x14(%ebp),%eax
f01042cd:	83 e8 04             	sub    $0x4,%eax
f01042d0:	8b 00                	mov    (%eax),%eax

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01042d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01042d5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
				(uint32) va_arg(ap, void *);
			base = 16;
f01042dc:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
			goto number;
f01042e3:	eb 1f                	jmp    f0104304 <vprintfmt+0x363>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01042e5:	83 ec 08             	sub    $0x8,%esp
f01042e8:	ff 75 e8             	pushl  -0x18(%ebp)
f01042eb:	8d 45 14             	lea    0x14(%ebp),%eax
f01042ee:	50                   	push   %eax
f01042ef:	e8 e7 fb ff ff       	call   f0103edb <getuint>
f01042f4:	83 c4 10             	add    $0x10,%esp
f01042f7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01042fa:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 16;
f01042fd:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104304:	0f be 55 db          	movsbl -0x25(%ebp),%edx
f0104308:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010430b:	83 ec 04             	sub    $0x4,%esp
f010430e:	52                   	push   %edx
f010430f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104312:	50                   	push   %eax
f0104313:	ff 75 f4             	pushl  -0xc(%ebp)
f0104316:	ff 75 f0             	pushl  -0x10(%ebp)
f0104319:	ff 75 0c             	pushl  0xc(%ebp)
f010431c:	ff 75 08             	pushl  0x8(%ebp)
f010431f:	e8 00 fb ff ff       	call   f0103e24 <printnum>
f0104324:	83 c4 20             	add    $0x20,%esp
			break;
f0104327:	eb 34                	jmp    f010435d <vprintfmt+0x3bc>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104329:	83 ec 08             	sub    $0x8,%esp
f010432c:	ff 75 0c             	pushl  0xc(%ebp)
f010432f:	53                   	push   %ebx
f0104330:	8b 45 08             	mov    0x8(%ebp),%eax
f0104333:	ff d0                	call   *%eax
f0104335:	83 c4 10             	add    $0x10,%esp
			break;
f0104338:	eb 23                	jmp    f010435d <vprintfmt+0x3bc>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010433a:	83 ec 08             	sub    $0x8,%esp
f010433d:	ff 75 0c             	pushl  0xc(%ebp)
f0104340:	6a 25                	push   $0x25
f0104342:	8b 45 08             	mov    0x8(%ebp),%eax
f0104345:	ff d0                	call   *%eax
f0104347:	83 c4 10             	add    $0x10,%esp
			for (fmt--; fmt[-1] != '%'; fmt--)
f010434a:	ff 4d 10             	decl   0x10(%ebp)
f010434d:	eb 03                	jmp    f0104352 <vprintfmt+0x3b1>
f010434f:	ff 4d 10             	decl   0x10(%ebp)
f0104352:	8b 45 10             	mov    0x10(%ebp),%eax
f0104355:	48                   	dec    %eax
f0104356:	8a 00                	mov    (%eax),%al
f0104358:	3c 25                	cmp    $0x25,%al
f010435a:	75 f3                	jne    f010434f <vprintfmt+0x3ae>
				/* do nothing */;
			break;
f010435c:	90                   	nop
		}
	}
f010435d:	e9 47 fc ff ff       	jmp    f0103fa9 <vprintfmt+0x8>
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
f0104362:	90                   	nop
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f0104363:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0104366:	5b                   	pop    %ebx
f0104367:	5e                   	pop    %esi
f0104368:	5d                   	pop    %ebp
f0104369:	c3                   	ret    

f010436a <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010436a:	55                   	push   %ebp
f010436b:	89 e5                	mov    %esp,%ebp
f010436d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0104370:	8d 45 10             	lea    0x10(%ebp),%eax
f0104373:	83 c0 04             	add    $0x4,%eax
f0104376:	89 45 f4             	mov    %eax,-0xc(%ebp)
	vprintfmt(putch, putdat, fmt, ap);
f0104379:	8b 45 10             	mov    0x10(%ebp),%eax
f010437c:	ff 75 f4             	pushl  -0xc(%ebp)
f010437f:	50                   	push   %eax
f0104380:	ff 75 0c             	pushl  0xc(%ebp)
f0104383:	ff 75 08             	pushl  0x8(%ebp)
f0104386:	e8 16 fc ff ff       	call   f0103fa1 <vprintfmt>
f010438b:	83 c4 10             	add    $0x10,%esp
	va_end(ap);
}
f010438e:	90                   	nop
f010438f:	c9                   	leave  
f0104390:	c3                   	ret    

f0104391 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104391:	55                   	push   %ebp
f0104392:	89 e5                	mov    %esp,%ebp
	b->cnt++;
f0104394:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104397:	8b 40 08             	mov    0x8(%eax),%eax
f010439a:	8d 50 01             	lea    0x1(%eax),%edx
f010439d:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043a0:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
f01043a3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043a6:	8b 10                	mov    (%eax),%edx
f01043a8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043ab:	8b 40 04             	mov    0x4(%eax),%eax
f01043ae:	39 c2                	cmp    %eax,%edx
f01043b0:	73 12                	jae    f01043c4 <sprintputch+0x33>
		*b->buf++ = ch;
f01043b2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043b5:	8b 00                	mov    (%eax),%eax
f01043b7:	8d 48 01             	lea    0x1(%eax),%ecx
f01043ba:	8b 55 0c             	mov    0xc(%ebp),%edx
f01043bd:	89 0a                	mov    %ecx,(%edx)
f01043bf:	8b 55 08             	mov    0x8(%ebp),%edx
f01043c2:	88 10                	mov    %dl,(%eax)
}
f01043c4:	90                   	nop
f01043c5:	5d                   	pop    %ebp
f01043c6:	c3                   	ret    

f01043c7 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01043c7:	55                   	push   %ebp
f01043c8:	89 e5                	mov    %esp,%ebp
f01043ca:	83 ec 18             	sub    $0x18,%esp
	struct sprintbuf b = {buf, buf+n-1, 0};
f01043cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01043d0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01043d3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043d6:	8d 50 ff             	lea    -0x1(%eax),%edx
f01043d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01043dc:	01 d0                	add    %edx,%eax
f01043de:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01043e1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01043e8:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01043ec:	74 06                	je     f01043f4 <vsnprintf+0x2d>
f01043ee:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01043f2:	7f 07                	jg     f01043fb <vsnprintf+0x34>
		return -E_INVAL;
f01043f4:	b8 03 00 00 00       	mov    $0x3,%eax
f01043f9:	eb 20                	jmp    f010441b <vsnprintf+0x54>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01043fb:	ff 75 14             	pushl  0x14(%ebp)
f01043fe:	ff 75 10             	pushl  0x10(%ebp)
f0104401:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104404:	50                   	push   %eax
f0104405:	68 91 43 10 f0       	push   $0xf0104391
f010440a:	e8 92 fb ff ff       	call   f0103fa1 <vprintfmt>
f010440f:	83 c4 10             	add    $0x10,%esp

	// null terminate the buffer
	*b.buf = '\0';
f0104412:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104415:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104418:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f010441b:	c9                   	leave  
f010441c:	c3                   	ret    

f010441d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010441d:	55                   	push   %ebp
f010441e:	89 e5                	mov    %esp,%ebp
f0104420:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104423:	8d 45 10             	lea    0x10(%ebp),%eax
f0104426:	83 c0 04             	add    $0x4,%eax
f0104429:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
f010442c:	8b 45 10             	mov    0x10(%ebp),%eax
f010442f:	ff 75 f4             	pushl  -0xc(%ebp)
f0104432:	50                   	push   %eax
f0104433:	ff 75 0c             	pushl  0xc(%ebp)
f0104436:	ff 75 08             	pushl  0x8(%ebp)
f0104439:	e8 89 ff ff ff       	call   f01043c7 <vsnprintf>
f010443e:	83 c4 10             	add    $0x10,%esp
f0104441:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
f0104444:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
f0104447:	c9                   	leave  
f0104448:	c3                   	ret    

f0104449 <readline>:

#define BUFLEN 1024
//static char buf[BUFLEN];

void readline(const char *prompt, char* buf)
{
f0104449:	55                   	push   %ebp
f010444a:	89 e5                	mov    %esp,%ebp
f010444c:	83 ec 18             	sub    $0x18,%esp
	int i, c, echoing;
	
	if (prompt != NULL)
f010444f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0104453:	74 13                	je     f0104468 <readline+0x1f>
		cprintf("%s", prompt);
f0104455:	83 ec 08             	sub    $0x8,%esp
f0104458:	ff 75 08             	pushl  0x8(%ebp)
f010445b:	68 fc 64 10 f0       	push   $0xf01064fc
f0104460:	e8 ee eb ff ff       	call   f0103053 <cprintf>
f0104465:	83 c4 10             	add    $0x10,%esp

	
	i = 0;
f0104468:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	echoing = iscons(0);	
f010446f:	83 ec 0c             	sub    $0xc,%esp
f0104472:	6a 00                	push   $0x0
f0104474:	e8 ce c4 ff ff       	call   f0100947 <iscons>
f0104479:	83 c4 10             	add    $0x10,%esp
f010447c:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while (1) {
		c = getchar();
f010447f:	e8 aa c4 ff ff       	call   f010092e <getchar>
f0104484:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (c < 0) {
f0104487:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f010448b:	79 22                	jns    f01044af <readline+0x66>
			if (c != -E_EOF)
f010448d:	83 7d ec 07          	cmpl   $0x7,-0x14(%ebp)
f0104491:	0f 84 ad 00 00 00    	je     f0104544 <readline+0xfb>
				cprintf("read error: %e\n", c);			
f0104497:	83 ec 08             	sub    $0x8,%esp
f010449a:	ff 75 ec             	pushl  -0x14(%ebp)
f010449d:	68 ff 64 10 f0       	push   $0xf01064ff
f01044a2:	e8 ac eb ff ff       	call   f0103053 <cprintf>
f01044a7:	83 c4 10             	add    $0x10,%esp
			return;
f01044aa:	e9 95 00 00 00       	jmp    f0104544 <readline+0xfb>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01044af:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%ebp)
f01044b3:	7e 34                	jle    f01044e9 <readline+0xa0>
f01044b5:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
f01044bc:	7f 2b                	jg     f01044e9 <readline+0xa0>
			if (echoing)
f01044be:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f01044c2:	74 0e                	je     f01044d2 <readline+0x89>
				cputchar(c);
f01044c4:	83 ec 0c             	sub    $0xc,%esp
f01044c7:	ff 75 ec             	pushl  -0x14(%ebp)
f01044ca:	e8 48 c4 ff ff       	call   f0100917 <cputchar>
f01044cf:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01044d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01044d5:	8d 50 01             	lea    0x1(%eax),%edx
f01044d8:	89 55 f4             	mov    %edx,-0xc(%ebp)
f01044db:	89 c2                	mov    %eax,%edx
f01044dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01044e0:	01 d0                	add    %edx,%eax
f01044e2:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01044e5:	88 10                	mov    %dl,(%eax)
f01044e7:	eb 56                	jmp    f010453f <readline+0xf6>
		} else if (c == '\b' && i > 0) {
f01044e9:	83 7d ec 08          	cmpl   $0x8,-0x14(%ebp)
f01044ed:	75 1f                	jne    f010450e <readline+0xc5>
f01044ef:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01044f3:	7e 19                	jle    f010450e <readline+0xc5>
			if (echoing)
f01044f5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f01044f9:	74 0e                	je     f0104509 <readline+0xc0>
				cputchar(c);
f01044fb:	83 ec 0c             	sub    $0xc,%esp
f01044fe:	ff 75 ec             	pushl  -0x14(%ebp)
f0104501:	e8 11 c4 ff ff       	call   f0100917 <cputchar>
f0104506:	83 c4 10             	add    $0x10,%esp
			i--;
f0104509:	ff 4d f4             	decl   -0xc(%ebp)
f010450c:	eb 31                	jmp    f010453f <readline+0xf6>
		} else if (c == '\n' || c == '\r') {
f010450e:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
f0104512:	74 0a                	je     f010451e <readline+0xd5>
f0104514:	83 7d ec 0d          	cmpl   $0xd,-0x14(%ebp)
f0104518:	0f 85 61 ff ff ff    	jne    f010447f <readline+0x36>
			if (echoing)
f010451e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0104522:	74 0e                	je     f0104532 <readline+0xe9>
				cputchar(c);
f0104524:	83 ec 0c             	sub    $0xc,%esp
f0104527:	ff 75 ec             	pushl  -0x14(%ebp)
f010452a:	e8 e8 c3 ff ff       	call   f0100917 <cputchar>
f010452f:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;	
f0104532:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104535:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104538:	01 d0                	add    %edx,%eax
f010453a:	c6 00 00             	movb   $0x0,(%eax)
			return;		
f010453d:	eb 06                	jmp    f0104545 <readline+0xfc>
		}
	}
f010453f:	e9 3b ff ff ff       	jmp    f010447f <readline+0x36>
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);			
			return;
f0104544:	90                   	nop
				cputchar(c);
			buf[i] = 0;	
			return;		
		}
	}
}
f0104545:	c9                   	leave  
f0104546:	c3                   	ret    

f0104547 <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f0104547:	55                   	push   %ebp
f0104548:	89 e5                	mov    %esp,%ebp
f010454a:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
f010454d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0104554:	eb 06                	jmp    f010455c <strlen+0x15>
		n++;
f0104556:	ff 45 fc             	incl   -0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104559:	ff 45 08             	incl   0x8(%ebp)
f010455c:	8b 45 08             	mov    0x8(%ebp),%eax
f010455f:	8a 00                	mov    (%eax),%al
f0104561:	84 c0                	test   %al,%al
f0104563:	75 f1                	jne    f0104556 <strlen+0xf>
		n++;
	return n;
f0104565:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0104568:	c9                   	leave  
f0104569:	c3                   	ret    

f010456a <strnlen>:

int
strnlen(const char *s, uint32 size)
{
f010456a:	55                   	push   %ebp
f010456b:	89 e5                	mov    %esp,%ebp
f010456d:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104570:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0104577:	eb 09                	jmp    f0104582 <strnlen+0x18>
		n++;
f0104579:	ff 45 fc             	incl   -0x4(%ebp)
int
strnlen(const char *s, uint32 size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010457c:	ff 45 08             	incl   0x8(%ebp)
f010457f:	ff 4d 0c             	decl   0xc(%ebp)
f0104582:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104586:	74 09                	je     f0104591 <strnlen+0x27>
f0104588:	8b 45 08             	mov    0x8(%ebp),%eax
f010458b:	8a 00                	mov    (%eax),%al
f010458d:	84 c0                	test   %al,%al
f010458f:	75 e8                	jne    f0104579 <strnlen+0xf>
		n++;
	return n;
f0104591:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0104594:	c9                   	leave  
f0104595:	c3                   	ret    

f0104596 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104596:	55                   	push   %ebp
f0104597:	89 e5                	mov    %esp,%ebp
f0104599:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
f010459c:	8b 45 08             	mov    0x8(%ebp),%eax
f010459f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
f01045a2:	90                   	nop
f01045a3:	8b 45 08             	mov    0x8(%ebp),%eax
f01045a6:	8d 50 01             	lea    0x1(%eax),%edx
f01045a9:	89 55 08             	mov    %edx,0x8(%ebp)
f01045ac:	8b 55 0c             	mov    0xc(%ebp),%edx
f01045af:	8d 4a 01             	lea    0x1(%edx),%ecx
f01045b2:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f01045b5:	8a 12                	mov    (%edx),%dl
f01045b7:	88 10                	mov    %dl,(%eax)
f01045b9:	8a 00                	mov    (%eax),%al
f01045bb:	84 c0                	test   %al,%al
f01045bd:	75 e4                	jne    f01045a3 <strcpy+0xd>
		/* do nothing */;
	return ret;
f01045bf:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f01045c2:	c9                   	leave  
f01045c3:	c3                   	ret    

f01045c4 <strncpy>:

char *
strncpy(char *dst, const char *src, uint32 size) {
f01045c4:	55                   	push   %ebp
f01045c5:	89 e5                	mov    %esp,%ebp
f01045c7:	83 ec 10             	sub    $0x10,%esp
	uint32 i;
	char *ret;

	ret = dst;
f01045ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01045cd:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
f01045d0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f01045d7:	eb 1f                	jmp    f01045f8 <strncpy+0x34>
		*dst++ = *src;
f01045d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01045dc:	8d 50 01             	lea    0x1(%eax),%edx
f01045df:	89 55 08             	mov    %edx,0x8(%ebp)
f01045e2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01045e5:	8a 12                	mov    (%edx),%dl
f01045e7:	88 10                	mov    %dl,(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
f01045e9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01045ec:	8a 00                	mov    (%eax),%al
f01045ee:	84 c0                	test   %al,%al
f01045f0:	74 03                	je     f01045f5 <strncpy+0x31>
			src++;
f01045f2:	ff 45 0c             	incl   0xc(%ebp)
strncpy(char *dst, const char *src, uint32 size) {
	uint32 i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01045f5:	ff 45 fc             	incl   -0x4(%ebp)
f01045f8:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01045fb:	3b 45 10             	cmp    0x10(%ebp),%eax
f01045fe:	72 d9                	jb     f01045d9 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
f0104600:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0104603:	c9                   	leave  
f0104604:	c3                   	ret    

f0104605 <strlcpy>:

uint32
strlcpy(char *dst, const char *src, uint32 size)
{
f0104605:	55                   	push   %ebp
f0104606:	89 e5                	mov    %esp,%ebp
f0104608:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
f010460b:	8b 45 08             	mov    0x8(%ebp),%eax
f010460e:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
f0104611:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104615:	74 30                	je     f0104647 <strlcpy+0x42>
		while (--size > 0 && *src != '\0')
f0104617:	eb 16                	jmp    f010462f <strlcpy+0x2a>
			*dst++ = *src++;
f0104619:	8b 45 08             	mov    0x8(%ebp),%eax
f010461c:	8d 50 01             	lea    0x1(%eax),%edx
f010461f:	89 55 08             	mov    %edx,0x8(%ebp)
f0104622:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104625:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104628:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f010462b:	8a 12                	mov    (%edx),%dl
f010462d:	88 10                	mov    %dl,(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010462f:	ff 4d 10             	decl   0x10(%ebp)
f0104632:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104636:	74 09                	je     f0104641 <strlcpy+0x3c>
f0104638:	8b 45 0c             	mov    0xc(%ebp),%eax
f010463b:	8a 00                	mov    (%eax),%al
f010463d:	84 c0                	test   %al,%al
f010463f:	75 d8                	jne    f0104619 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
f0104641:	8b 45 08             	mov    0x8(%ebp),%eax
f0104644:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104647:	8b 55 08             	mov    0x8(%ebp),%edx
f010464a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010464d:	29 c2                	sub    %eax,%edx
f010464f:	89 d0                	mov    %edx,%eax
}
f0104651:	c9                   	leave  
f0104652:	c3                   	ret    

f0104653 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104653:	55                   	push   %ebp
f0104654:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
f0104656:	eb 06                	jmp    f010465e <strcmp+0xb>
		p++, q++;
f0104658:	ff 45 08             	incl   0x8(%ebp)
f010465b:	ff 45 0c             	incl   0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010465e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104661:	8a 00                	mov    (%eax),%al
f0104663:	84 c0                	test   %al,%al
f0104665:	74 0e                	je     f0104675 <strcmp+0x22>
f0104667:	8b 45 08             	mov    0x8(%ebp),%eax
f010466a:	8a 10                	mov    (%eax),%dl
f010466c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010466f:	8a 00                	mov    (%eax),%al
f0104671:	38 c2                	cmp    %al,%dl
f0104673:	74 e3                	je     f0104658 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104675:	8b 45 08             	mov    0x8(%ebp),%eax
f0104678:	8a 00                	mov    (%eax),%al
f010467a:	0f b6 d0             	movzbl %al,%edx
f010467d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104680:	8a 00                	mov    (%eax),%al
f0104682:	0f b6 c0             	movzbl %al,%eax
f0104685:	29 c2                	sub    %eax,%edx
f0104687:	89 d0                	mov    %edx,%eax
}
f0104689:	5d                   	pop    %ebp
f010468a:	c3                   	ret    

f010468b <strncmp>:

int
strncmp(const char *p, const char *q, uint32 n)
{
f010468b:	55                   	push   %ebp
f010468c:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
f010468e:	eb 09                	jmp    f0104699 <strncmp+0xe>
		n--, p++, q++;
f0104690:	ff 4d 10             	decl   0x10(%ebp)
f0104693:	ff 45 08             	incl   0x8(%ebp)
f0104696:	ff 45 0c             	incl   0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint32 n)
{
	while (n > 0 && *p && *p == *q)
f0104699:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010469d:	74 17                	je     f01046b6 <strncmp+0x2b>
f010469f:	8b 45 08             	mov    0x8(%ebp),%eax
f01046a2:	8a 00                	mov    (%eax),%al
f01046a4:	84 c0                	test   %al,%al
f01046a6:	74 0e                	je     f01046b6 <strncmp+0x2b>
f01046a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01046ab:	8a 10                	mov    (%eax),%dl
f01046ad:	8b 45 0c             	mov    0xc(%ebp),%eax
f01046b0:	8a 00                	mov    (%eax),%al
f01046b2:	38 c2                	cmp    %al,%dl
f01046b4:	74 da                	je     f0104690 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
f01046b6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01046ba:	75 07                	jne    f01046c3 <strncmp+0x38>
		return 0;
f01046bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01046c1:	eb 14                	jmp    f01046d7 <strncmp+0x4c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01046c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01046c6:	8a 00                	mov    (%eax),%al
f01046c8:	0f b6 d0             	movzbl %al,%edx
f01046cb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01046ce:	8a 00                	mov    (%eax),%al
f01046d0:	0f b6 c0             	movzbl %al,%eax
f01046d3:	29 c2                	sub    %eax,%edx
f01046d5:	89 d0                	mov    %edx,%eax
}
f01046d7:	5d                   	pop    %ebp
f01046d8:	c3                   	ret    

f01046d9 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01046d9:	55                   	push   %ebp
f01046da:	89 e5                	mov    %esp,%ebp
f01046dc:	83 ec 04             	sub    $0x4,%esp
f01046df:	8b 45 0c             	mov    0xc(%ebp),%eax
f01046e2:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f01046e5:	eb 12                	jmp    f01046f9 <strchr+0x20>
		if (*s == c)
f01046e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01046ea:	8a 00                	mov    (%eax),%al
f01046ec:	3a 45 fc             	cmp    -0x4(%ebp),%al
f01046ef:	75 05                	jne    f01046f6 <strchr+0x1d>
			return (char *) s;
f01046f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01046f4:	eb 11                	jmp    f0104707 <strchr+0x2e>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01046f6:	ff 45 08             	incl   0x8(%ebp)
f01046f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01046fc:	8a 00                	mov    (%eax),%al
f01046fe:	84 c0                	test   %al,%al
f0104700:	75 e5                	jne    f01046e7 <strchr+0xe>
		if (*s == c)
			return (char *) s;
	return 0;
f0104702:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104707:	c9                   	leave  
f0104708:	c3                   	ret    

f0104709 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104709:	55                   	push   %ebp
f010470a:	89 e5                	mov    %esp,%ebp
f010470c:	83 ec 04             	sub    $0x4,%esp
f010470f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104712:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0104715:	eb 0d                	jmp    f0104724 <strfind+0x1b>
		if (*s == c)
f0104717:	8b 45 08             	mov    0x8(%ebp),%eax
f010471a:	8a 00                	mov    (%eax),%al
f010471c:	3a 45 fc             	cmp    -0x4(%ebp),%al
f010471f:	74 0e                	je     f010472f <strfind+0x26>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104721:	ff 45 08             	incl   0x8(%ebp)
f0104724:	8b 45 08             	mov    0x8(%ebp),%eax
f0104727:	8a 00                	mov    (%eax),%al
f0104729:	84 c0                	test   %al,%al
f010472b:	75 ea                	jne    f0104717 <strfind+0xe>
f010472d:	eb 01                	jmp    f0104730 <strfind+0x27>
		if (*s == c)
			break;
f010472f:	90                   	nop
	return (char *) s;
f0104730:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0104733:	c9                   	leave  
f0104734:	c3                   	ret    

f0104735 <memset>:


void *
memset(void *v, int c, uint32 n)
{
f0104735:	55                   	push   %ebp
f0104736:	89 e5                	mov    %esp,%ebp
f0104738:	83 ec 10             	sub    $0x10,%esp
	char *p;
	int m;

	p = v;
f010473b:	8b 45 08             	mov    0x8(%ebp),%eax
f010473e:	89 45 fc             	mov    %eax,-0x4(%ebp)
	m = n;
f0104741:	8b 45 10             	mov    0x10(%ebp),%eax
f0104744:	89 45 f8             	mov    %eax,-0x8(%ebp)
	while (--m >= 0)
f0104747:	eb 0e                	jmp    f0104757 <memset+0x22>
		*p++ = c;
f0104749:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010474c:	8d 50 01             	lea    0x1(%eax),%edx
f010474f:	89 55 fc             	mov    %edx,-0x4(%ebp)
f0104752:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104755:	88 10                	mov    %dl,(%eax)
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f0104757:	ff 4d f8             	decl   -0x8(%ebp)
f010475a:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f010475e:	79 e9                	jns    f0104749 <memset+0x14>
		*p++ = c;

	return v;
f0104760:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0104763:	c9                   	leave  
f0104764:	c3                   	ret    

f0104765 <memcpy>:

void *
memcpy(void *dst, const void *src, uint32 n)
{
f0104765:	55                   	push   %ebp
f0104766:	89 e5                	mov    %esp,%ebp
f0104768:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;

	s = src;
f010476b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010476e:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
f0104771:	8b 45 08             	mov    0x8(%ebp),%eax
f0104774:	89 45 f8             	mov    %eax,-0x8(%ebp)
	while (n-- > 0)
f0104777:	eb 16                	jmp    f010478f <memcpy+0x2a>
		*d++ = *s++;
f0104779:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010477c:	8d 50 01             	lea    0x1(%eax),%edx
f010477f:	89 55 f8             	mov    %edx,-0x8(%ebp)
f0104782:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0104785:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104788:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f010478b:	8a 12                	mov    (%edx),%dl
f010478d:	88 10                	mov    %dl,(%eax)
	const char *s;
	char *d;

	s = src;
	d = dst;
	while (n-- > 0)
f010478f:	8b 45 10             	mov    0x10(%ebp),%eax
f0104792:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104795:	89 55 10             	mov    %edx,0x10(%ebp)
f0104798:	85 c0                	test   %eax,%eax
f010479a:	75 dd                	jne    f0104779 <memcpy+0x14>
		*d++ = *s++;

	return dst;
f010479c:	8b 45 08             	mov    0x8(%ebp),%eax
}
f010479f:	c9                   	leave  
f01047a0:	c3                   	ret    

f01047a1 <memmove>:

void *
memmove(void *dst, const void *src, uint32 n)
{
f01047a1:	55                   	push   %ebp
f01047a2:	89 e5                	mov    %esp,%ebp
f01047a4:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
f01047a7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01047aa:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
f01047ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01047b0:	89 45 f8             	mov    %eax,-0x8(%ebp)
	if (s < d && s + n > d) {
f01047b3:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01047b6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f01047b9:	73 50                	jae    f010480b <memmove+0x6a>
f01047bb:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01047be:	8b 45 10             	mov    0x10(%ebp),%eax
f01047c1:	01 d0                	add    %edx,%eax
f01047c3:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f01047c6:	76 43                	jbe    f010480b <memmove+0x6a>
		s += n;
f01047c8:	8b 45 10             	mov    0x10(%ebp),%eax
f01047cb:	01 45 fc             	add    %eax,-0x4(%ebp)
		d += n;
f01047ce:	8b 45 10             	mov    0x10(%ebp),%eax
f01047d1:	01 45 f8             	add    %eax,-0x8(%ebp)
		while (n-- > 0)
f01047d4:	eb 10                	jmp    f01047e6 <memmove+0x45>
			*--d = *--s;
f01047d6:	ff 4d f8             	decl   -0x8(%ebp)
f01047d9:	ff 4d fc             	decl   -0x4(%ebp)
f01047dc:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01047df:	8a 10                	mov    (%eax),%dl
f01047e1:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01047e4:	88 10                	mov    %dl,(%eax)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f01047e6:	8b 45 10             	mov    0x10(%ebp),%eax
f01047e9:	8d 50 ff             	lea    -0x1(%eax),%edx
f01047ec:	89 55 10             	mov    %edx,0x10(%ebp)
f01047ef:	85 c0                	test   %eax,%eax
f01047f1:	75 e3                	jne    f01047d6 <memmove+0x35>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01047f3:	eb 23                	jmp    f0104818 <memmove+0x77>
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f01047f5:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01047f8:	8d 50 01             	lea    0x1(%eax),%edx
f01047fb:	89 55 f8             	mov    %edx,-0x8(%ebp)
f01047fe:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0104801:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104804:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f0104807:	8a 12                	mov    (%edx),%dl
f0104809:	88 10                	mov    %dl,(%eax)
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f010480b:	8b 45 10             	mov    0x10(%ebp),%eax
f010480e:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104811:	89 55 10             	mov    %edx,0x10(%ebp)
f0104814:	85 c0                	test   %eax,%eax
f0104816:	75 dd                	jne    f01047f5 <memmove+0x54>
			*d++ = *s++;

	return dst;
f0104818:	8b 45 08             	mov    0x8(%ebp),%eax
}
f010481b:	c9                   	leave  
f010481c:	c3                   	ret    

f010481d <memcmp>:

int
memcmp(const void *v1, const void *v2, uint32 n)
{
f010481d:	55                   	push   %ebp
f010481e:	89 e5                	mov    %esp,%ebp
f0104820:	83 ec 10             	sub    $0x10,%esp
	const uint8 *s1 = (const uint8 *) v1;
f0104823:	8b 45 08             	mov    0x8(%ebp),%eax
f0104826:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8 *s2 = (const uint8 *) v2;
f0104829:	8b 45 0c             	mov    0xc(%ebp),%eax
f010482c:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
f010482f:	eb 2a                	jmp    f010485b <memcmp+0x3e>
		if (*s1 != *s2)
f0104831:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104834:	8a 10                	mov    (%eax),%dl
f0104836:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104839:	8a 00                	mov    (%eax),%al
f010483b:	38 c2                	cmp    %al,%dl
f010483d:	74 16                	je     f0104855 <memcmp+0x38>
			return (int) *s1 - (int) *s2;
f010483f:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104842:	8a 00                	mov    (%eax),%al
f0104844:	0f b6 d0             	movzbl %al,%edx
f0104847:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010484a:	8a 00                	mov    (%eax),%al
f010484c:	0f b6 c0             	movzbl %al,%eax
f010484f:	29 c2                	sub    %eax,%edx
f0104851:	89 d0                	mov    %edx,%eax
f0104853:	eb 18                	jmp    f010486d <memcmp+0x50>
		s1++, s2++;
f0104855:	ff 45 fc             	incl   -0x4(%ebp)
f0104858:	ff 45 f8             	incl   -0x8(%ebp)
memcmp(const void *v1, const void *v2, uint32 n)
{
	const uint8 *s1 = (const uint8 *) v1;
	const uint8 *s2 = (const uint8 *) v2;

	while (n-- > 0) {
f010485b:	8b 45 10             	mov    0x10(%ebp),%eax
f010485e:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104861:	89 55 10             	mov    %edx,0x10(%ebp)
f0104864:	85 c0                	test   %eax,%eax
f0104866:	75 c9                	jne    f0104831 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104868:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010486d:	c9                   	leave  
f010486e:	c3                   	ret    

f010486f <memfind>:

void *
memfind(const void *s, int c, uint32 n)
{
f010486f:	55                   	push   %ebp
f0104870:	89 e5                	mov    %esp,%ebp
f0104872:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
f0104875:	8b 55 08             	mov    0x8(%ebp),%edx
f0104878:	8b 45 10             	mov    0x10(%ebp),%eax
f010487b:	01 d0                	add    %edx,%eax
f010487d:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
f0104880:	eb 15                	jmp    f0104897 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104882:	8b 45 08             	mov    0x8(%ebp),%eax
f0104885:	8a 00                	mov    (%eax),%al
f0104887:	0f b6 d0             	movzbl %al,%edx
f010488a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010488d:	0f b6 c0             	movzbl %al,%eax
f0104890:	39 c2                	cmp    %eax,%edx
f0104892:	74 0d                	je     f01048a1 <memfind+0x32>

void *
memfind(const void *s, int c, uint32 n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104894:	ff 45 08             	incl   0x8(%ebp)
f0104897:	8b 45 08             	mov    0x8(%ebp),%eax
f010489a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f010489d:	72 e3                	jb     f0104882 <memfind+0x13>
f010489f:	eb 01                	jmp    f01048a2 <memfind+0x33>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
f01048a1:	90                   	nop
	return (void *) s;
f01048a2:	8b 45 08             	mov    0x8(%ebp),%eax
}
f01048a5:	c9                   	leave  
f01048a6:	c3                   	ret    

f01048a7 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01048a7:	55                   	push   %ebp
f01048a8:	89 e5                	mov    %esp,%ebp
f01048aa:	83 ec 10             	sub    $0x10,%esp
	int neg = 0;
f01048ad:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	long val = 0;
f01048b4:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01048bb:	eb 03                	jmp    f01048c0 <strtol+0x19>
		s++;
f01048bd:	ff 45 08             	incl   0x8(%ebp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01048c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01048c3:	8a 00                	mov    (%eax),%al
f01048c5:	3c 20                	cmp    $0x20,%al
f01048c7:	74 f4                	je     f01048bd <strtol+0x16>
f01048c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01048cc:	8a 00                	mov    (%eax),%al
f01048ce:	3c 09                	cmp    $0x9,%al
f01048d0:	74 eb                	je     f01048bd <strtol+0x16>
		s++;

	// plus/minus sign
	if (*s == '+')
f01048d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01048d5:	8a 00                	mov    (%eax),%al
f01048d7:	3c 2b                	cmp    $0x2b,%al
f01048d9:	75 05                	jne    f01048e0 <strtol+0x39>
		s++;
f01048db:	ff 45 08             	incl   0x8(%ebp)
f01048de:	eb 13                	jmp    f01048f3 <strtol+0x4c>
	else if (*s == '-')
f01048e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01048e3:	8a 00                	mov    (%eax),%al
f01048e5:	3c 2d                	cmp    $0x2d,%al
f01048e7:	75 0a                	jne    f01048f3 <strtol+0x4c>
		s++, neg = 1;
f01048e9:	ff 45 08             	incl   0x8(%ebp)
f01048ec:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01048f3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01048f7:	74 06                	je     f01048ff <strtol+0x58>
f01048f9:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
f01048fd:	75 20                	jne    f010491f <strtol+0x78>
f01048ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0104902:	8a 00                	mov    (%eax),%al
f0104904:	3c 30                	cmp    $0x30,%al
f0104906:	75 17                	jne    f010491f <strtol+0x78>
f0104908:	8b 45 08             	mov    0x8(%ebp),%eax
f010490b:	40                   	inc    %eax
f010490c:	8a 00                	mov    (%eax),%al
f010490e:	3c 78                	cmp    $0x78,%al
f0104910:	75 0d                	jne    f010491f <strtol+0x78>
		s += 2, base = 16;
f0104912:	83 45 08 02          	addl   $0x2,0x8(%ebp)
f0104916:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f010491d:	eb 28                	jmp    f0104947 <strtol+0xa0>
	else if (base == 0 && s[0] == '0')
f010491f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104923:	75 15                	jne    f010493a <strtol+0x93>
f0104925:	8b 45 08             	mov    0x8(%ebp),%eax
f0104928:	8a 00                	mov    (%eax),%al
f010492a:	3c 30                	cmp    $0x30,%al
f010492c:	75 0c                	jne    f010493a <strtol+0x93>
		s++, base = 8;
f010492e:	ff 45 08             	incl   0x8(%ebp)
f0104931:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f0104938:	eb 0d                	jmp    f0104947 <strtol+0xa0>
	else if (base == 0)
f010493a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010493e:	75 07                	jne    f0104947 <strtol+0xa0>
		base = 10;
f0104940:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104947:	8b 45 08             	mov    0x8(%ebp),%eax
f010494a:	8a 00                	mov    (%eax),%al
f010494c:	3c 2f                	cmp    $0x2f,%al
f010494e:	7e 19                	jle    f0104969 <strtol+0xc2>
f0104950:	8b 45 08             	mov    0x8(%ebp),%eax
f0104953:	8a 00                	mov    (%eax),%al
f0104955:	3c 39                	cmp    $0x39,%al
f0104957:	7f 10                	jg     f0104969 <strtol+0xc2>
			dig = *s - '0';
f0104959:	8b 45 08             	mov    0x8(%ebp),%eax
f010495c:	8a 00                	mov    (%eax),%al
f010495e:	0f be c0             	movsbl %al,%eax
f0104961:	83 e8 30             	sub    $0x30,%eax
f0104964:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0104967:	eb 42                	jmp    f01049ab <strtol+0x104>
		else if (*s >= 'a' && *s <= 'z')
f0104969:	8b 45 08             	mov    0x8(%ebp),%eax
f010496c:	8a 00                	mov    (%eax),%al
f010496e:	3c 60                	cmp    $0x60,%al
f0104970:	7e 19                	jle    f010498b <strtol+0xe4>
f0104972:	8b 45 08             	mov    0x8(%ebp),%eax
f0104975:	8a 00                	mov    (%eax),%al
f0104977:	3c 7a                	cmp    $0x7a,%al
f0104979:	7f 10                	jg     f010498b <strtol+0xe4>
			dig = *s - 'a' + 10;
f010497b:	8b 45 08             	mov    0x8(%ebp),%eax
f010497e:	8a 00                	mov    (%eax),%al
f0104980:	0f be c0             	movsbl %al,%eax
f0104983:	83 e8 57             	sub    $0x57,%eax
f0104986:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0104989:	eb 20                	jmp    f01049ab <strtol+0x104>
		else if (*s >= 'A' && *s <= 'Z')
f010498b:	8b 45 08             	mov    0x8(%ebp),%eax
f010498e:	8a 00                	mov    (%eax),%al
f0104990:	3c 40                	cmp    $0x40,%al
f0104992:	7e 39                	jle    f01049cd <strtol+0x126>
f0104994:	8b 45 08             	mov    0x8(%ebp),%eax
f0104997:	8a 00                	mov    (%eax),%al
f0104999:	3c 5a                	cmp    $0x5a,%al
f010499b:	7f 30                	jg     f01049cd <strtol+0x126>
			dig = *s - 'A' + 10;
f010499d:	8b 45 08             	mov    0x8(%ebp),%eax
f01049a0:	8a 00                	mov    (%eax),%al
f01049a2:	0f be c0             	movsbl %al,%eax
f01049a5:	83 e8 37             	sub    $0x37,%eax
f01049a8:	89 45 f4             	mov    %eax,-0xc(%ebp)
		else
			break;
		if (dig >= base)
f01049ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01049ae:	3b 45 10             	cmp    0x10(%ebp),%eax
f01049b1:	7d 19                	jge    f01049cc <strtol+0x125>
			break;
		s++, val = (val * base) + dig;
f01049b3:	ff 45 08             	incl   0x8(%ebp)
f01049b6:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01049b9:	0f af 45 10          	imul   0x10(%ebp),%eax
f01049bd:	89 c2                	mov    %eax,%edx
f01049bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01049c2:	01 d0                	add    %edx,%eax
f01049c4:	89 45 f8             	mov    %eax,-0x8(%ebp)
		// we don't properly detect overflow!
	}
f01049c7:	e9 7b ff ff ff       	jmp    f0104947 <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
			break;
f01049cc:	90                   	nop
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01049cd:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01049d1:	74 08                	je     f01049db <strtol+0x134>
		*endptr = (char *) s;
f01049d3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01049d6:	8b 55 08             	mov    0x8(%ebp),%edx
f01049d9:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f01049db:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f01049df:	74 07                	je     f01049e8 <strtol+0x141>
f01049e1:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01049e4:	f7 d8                	neg    %eax
f01049e6:	eb 03                	jmp    f01049eb <strtol+0x144>
f01049e8:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f01049eb:	c9                   	leave  
f01049ec:	c3                   	ret    

f01049ed <strsplit>:

int strsplit(char *string, char *SPLIT_CHARS, char **argv, int * argc)
{
f01049ed:	55                   	push   %ebp
f01049ee:	89 e5                	mov    %esp,%ebp
	// Parse the command string into splitchars-separated arguments
	*argc = 0;
f01049f0:	8b 45 14             	mov    0x14(%ebp),%eax
f01049f3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	(argv)[*argc] = 0;
f01049f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01049fc:	8b 00                	mov    (%eax),%eax
f01049fe:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0104a05:	8b 45 10             	mov    0x10(%ebp),%eax
f0104a08:	01 d0                	add    %edx,%eax
f0104a0a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	while (1) 
	{
		// trim splitchars
		while (*string && strchr(SPLIT_CHARS, *string))
f0104a10:	eb 0c                	jmp    f0104a1e <strsplit+0x31>
			*string++ = 0;
f0104a12:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a15:	8d 50 01             	lea    0x1(%eax),%edx
f0104a18:	89 55 08             	mov    %edx,0x8(%ebp)
f0104a1b:	c6 00 00             	movb   $0x0,(%eax)
	*argc = 0;
	(argv)[*argc] = 0;
	while (1) 
	{
		// trim splitchars
		while (*string && strchr(SPLIT_CHARS, *string))
f0104a1e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a21:	8a 00                	mov    (%eax),%al
f0104a23:	84 c0                	test   %al,%al
f0104a25:	74 18                	je     f0104a3f <strsplit+0x52>
f0104a27:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a2a:	8a 00                	mov    (%eax),%al
f0104a2c:	0f be c0             	movsbl %al,%eax
f0104a2f:	50                   	push   %eax
f0104a30:	ff 75 0c             	pushl  0xc(%ebp)
f0104a33:	e8 a1 fc ff ff       	call   f01046d9 <strchr>
f0104a38:	83 c4 08             	add    $0x8,%esp
f0104a3b:	85 c0                	test   %eax,%eax
f0104a3d:	75 d3                	jne    f0104a12 <strsplit+0x25>
			*string++ = 0;
		
		//if the command string is finished, then break the loop
		if (*string == 0)
f0104a3f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a42:	8a 00                	mov    (%eax),%al
f0104a44:	84 c0                	test   %al,%al
f0104a46:	74 5a                	je     f0104aa2 <strsplit+0xb5>
			break;

		//check current number of arguments
		if (*argc == MAX_ARGUMENTS-1) 
f0104a48:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a4b:	8b 00                	mov    (%eax),%eax
f0104a4d:	83 f8 0f             	cmp    $0xf,%eax
f0104a50:	75 07                	jne    f0104a59 <strsplit+0x6c>
		{
			return 0;
f0104a52:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a57:	eb 66                	jmp    f0104abf <strsplit+0xd2>
		}
		
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
f0104a59:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a5c:	8b 00                	mov    (%eax),%eax
f0104a5e:	8d 48 01             	lea    0x1(%eax),%ecx
f0104a61:	8b 55 14             	mov    0x14(%ebp),%edx
f0104a64:	89 0a                	mov    %ecx,(%edx)
f0104a66:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0104a6d:	8b 45 10             	mov    0x10(%ebp),%eax
f0104a70:	01 c2                	add    %eax,%edx
f0104a72:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a75:	89 02                	mov    %eax,(%edx)
		while (*string && !strchr(SPLIT_CHARS, *string))
f0104a77:	eb 03                	jmp    f0104a7c <strsplit+0x8f>
			string++;
f0104a79:	ff 45 08             	incl   0x8(%ebp)
			return 0;
		}
		
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
		while (*string && !strchr(SPLIT_CHARS, *string))
f0104a7c:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a7f:	8a 00                	mov    (%eax),%al
f0104a81:	84 c0                	test   %al,%al
f0104a83:	74 8b                	je     f0104a10 <strsplit+0x23>
f0104a85:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a88:	8a 00                	mov    (%eax),%al
f0104a8a:	0f be c0             	movsbl %al,%eax
f0104a8d:	50                   	push   %eax
f0104a8e:	ff 75 0c             	pushl  0xc(%ebp)
f0104a91:	e8 43 fc ff ff       	call   f01046d9 <strchr>
f0104a96:	83 c4 08             	add    $0x8,%esp
f0104a99:	85 c0                	test   %eax,%eax
f0104a9b:	74 dc                	je     f0104a79 <strsplit+0x8c>
			string++;
	}
f0104a9d:	e9 6e ff ff ff       	jmp    f0104a10 <strsplit+0x23>
		while (*string && strchr(SPLIT_CHARS, *string))
			*string++ = 0;
		
		//if the command string is finished, then break the loop
		if (*string == 0)
			break;
f0104aa2:	90                   	nop
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
		while (*string && !strchr(SPLIT_CHARS, *string))
			string++;
	}
	(argv)[*argc] = 0;
f0104aa3:	8b 45 14             	mov    0x14(%ebp),%eax
f0104aa6:	8b 00                	mov    (%eax),%eax
f0104aa8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0104aaf:	8b 45 10             	mov    0x10(%ebp),%eax
f0104ab2:	01 d0                	add    %edx,%eax
f0104ab4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return 1 ;
f0104aba:	b8 01 00 00 00       	mov    $0x1,%eax
}
f0104abf:	c9                   	leave  
f0104ac0:	c3                   	ret    
f0104ac1:	66 90                	xchg   %ax,%ax
f0104ac3:	90                   	nop

f0104ac4 <__udivdi3>:
f0104ac4:	55                   	push   %ebp
f0104ac5:	57                   	push   %edi
f0104ac6:	56                   	push   %esi
f0104ac7:	53                   	push   %ebx
f0104ac8:	83 ec 1c             	sub    $0x1c,%esp
f0104acb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0104acf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104ad3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104ad7:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104adb:	89 ca                	mov    %ecx,%edx
f0104add:	89 f8                	mov    %edi,%eax
f0104adf:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0104ae3:	85 f6                	test   %esi,%esi
f0104ae5:	75 2d                	jne    f0104b14 <__udivdi3+0x50>
f0104ae7:	39 cf                	cmp    %ecx,%edi
f0104ae9:	77 65                	ja     f0104b50 <__udivdi3+0x8c>
f0104aeb:	89 fd                	mov    %edi,%ebp
f0104aed:	85 ff                	test   %edi,%edi
f0104aef:	75 0b                	jne    f0104afc <__udivdi3+0x38>
f0104af1:	b8 01 00 00 00       	mov    $0x1,%eax
f0104af6:	31 d2                	xor    %edx,%edx
f0104af8:	f7 f7                	div    %edi
f0104afa:	89 c5                	mov    %eax,%ebp
f0104afc:	31 d2                	xor    %edx,%edx
f0104afe:	89 c8                	mov    %ecx,%eax
f0104b00:	f7 f5                	div    %ebp
f0104b02:	89 c1                	mov    %eax,%ecx
f0104b04:	89 d8                	mov    %ebx,%eax
f0104b06:	f7 f5                	div    %ebp
f0104b08:	89 cf                	mov    %ecx,%edi
f0104b0a:	89 fa                	mov    %edi,%edx
f0104b0c:	83 c4 1c             	add    $0x1c,%esp
f0104b0f:	5b                   	pop    %ebx
f0104b10:	5e                   	pop    %esi
f0104b11:	5f                   	pop    %edi
f0104b12:	5d                   	pop    %ebp
f0104b13:	c3                   	ret    
f0104b14:	39 ce                	cmp    %ecx,%esi
f0104b16:	77 28                	ja     f0104b40 <__udivdi3+0x7c>
f0104b18:	0f bd fe             	bsr    %esi,%edi
f0104b1b:	83 f7 1f             	xor    $0x1f,%edi
f0104b1e:	75 40                	jne    f0104b60 <__udivdi3+0x9c>
f0104b20:	39 ce                	cmp    %ecx,%esi
f0104b22:	72 0a                	jb     f0104b2e <__udivdi3+0x6a>
f0104b24:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104b28:	0f 87 9e 00 00 00    	ja     f0104bcc <__udivdi3+0x108>
f0104b2e:	b8 01 00 00 00       	mov    $0x1,%eax
f0104b33:	89 fa                	mov    %edi,%edx
f0104b35:	83 c4 1c             	add    $0x1c,%esp
f0104b38:	5b                   	pop    %ebx
f0104b39:	5e                   	pop    %esi
f0104b3a:	5f                   	pop    %edi
f0104b3b:	5d                   	pop    %ebp
f0104b3c:	c3                   	ret    
f0104b3d:	8d 76 00             	lea    0x0(%esi),%esi
f0104b40:	31 ff                	xor    %edi,%edi
f0104b42:	31 c0                	xor    %eax,%eax
f0104b44:	89 fa                	mov    %edi,%edx
f0104b46:	83 c4 1c             	add    $0x1c,%esp
f0104b49:	5b                   	pop    %ebx
f0104b4a:	5e                   	pop    %esi
f0104b4b:	5f                   	pop    %edi
f0104b4c:	5d                   	pop    %ebp
f0104b4d:	c3                   	ret    
f0104b4e:	66 90                	xchg   %ax,%ax
f0104b50:	89 d8                	mov    %ebx,%eax
f0104b52:	f7 f7                	div    %edi
f0104b54:	31 ff                	xor    %edi,%edi
f0104b56:	89 fa                	mov    %edi,%edx
f0104b58:	83 c4 1c             	add    $0x1c,%esp
f0104b5b:	5b                   	pop    %ebx
f0104b5c:	5e                   	pop    %esi
f0104b5d:	5f                   	pop    %edi
f0104b5e:	5d                   	pop    %ebp
f0104b5f:	c3                   	ret    
f0104b60:	bd 20 00 00 00       	mov    $0x20,%ebp
f0104b65:	89 eb                	mov    %ebp,%ebx
f0104b67:	29 fb                	sub    %edi,%ebx
f0104b69:	89 f9                	mov    %edi,%ecx
f0104b6b:	d3 e6                	shl    %cl,%esi
f0104b6d:	89 c5                	mov    %eax,%ebp
f0104b6f:	88 d9                	mov    %bl,%cl
f0104b71:	d3 ed                	shr    %cl,%ebp
f0104b73:	89 e9                	mov    %ebp,%ecx
f0104b75:	09 f1                	or     %esi,%ecx
f0104b77:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104b7b:	89 f9                	mov    %edi,%ecx
f0104b7d:	d3 e0                	shl    %cl,%eax
f0104b7f:	89 c5                	mov    %eax,%ebp
f0104b81:	89 d6                	mov    %edx,%esi
f0104b83:	88 d9                	mov    %bl,%cl
f0104b85:	d3 ee                	shr    %cl,%esi
f0104b87:	89 f9                	mov    %edi,%ecx
f0104b89:	d3 e2                	shl    %cl,%edx
f0104b8b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104b8f:	88 d9                	mov    %bl,%cl
f0104b91:	d3 e8                	shr    %cl,%eax
f0104b93:	09 c2                	or     %eax,%edx
f0104b95:	89 d0                	mov    %edx,%eax
f0104b97:	89 f2                	mov    %esi,%edx
f0104b99:	f7 74 24 0c          	divl   0xc(%esp)
f0104b9d:	89 d6                	mov    %edx,%esi
f0104b9f:	89 c3                	mov    %eax,%ebx
f0104ba1:	f7 e5                	mul    %ebp
f0104ba3:	39 d6                	cmp    %edx,%esi
f0104ba5:	72 19                	jb     f0104bc0 <__udivdi3+0xfc>
f0104ba7:	74 0b                	je     f0104bb4 <__udivdi3+0xf0>
f0104ba9:	89 d8                	mov    %ebx,%eax
f0104bab:	31 ff                	xor    %edi,%edi
f0104bad:	e9 58 ff ff ff       	jmp    f0104b0a <__udivdi3+0x46>
f0104bb2:	66 90                	xchg   %ax,%ax
f0104bb4:	8b 54 24 08          	mov    0x8(%esp),%edx
f0104bb8:	89 f9                	mov    %edi,%ecx
f0104bba:	d3 e2                	shl    %cl,%edx
f0104bbc:	39 c2                	cmp    %eax,%edx
f0104bbe:	73 e9                	jae    f0104ba9 <__udivdi3+0xe5>
f0104bc0:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0104bc3:	31 ff                	xor    %edi,%edi
f0104bc5:	e9 40 ff ff ff       	jmp    f0104b0a <__udivdi3+0x46>
f0104bca:	66 90                	xchg   %ax,%ax
f0104bcc:	31 c0                	xor    %eax,%eax
f0104bce:	e9 37 ff ff ff       	jmp    f0104b0a <__udivdi3+0x46>
f0104bd3:	90                   	nop

f0104bd4 <__umoddi3>:
f0104bd4:	55                   	push   %ebp
f0104bd5:	57                   	push   %edi
f0104bd6:	56                   	push   %esi
f0104bd7:	53                   	push   %ebx
f0104bd8:	83 ec 1c             	sub    $0x1c,%esp
f0104bdb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0104bdf:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104be3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104be7:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0104beb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104bef:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104bf3:	89 f3                	mov    %esi,%ebx
f0104bf5:	89 fa                	mov    %edi,%edx
f0104bf7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104bfb:	89 34 24             	mov    %esi,(%esp)
f0104bfe:	85 c0                	test   %eax,%eax
f0104c00:	75 1a                	jne    f0104c1c <__umoddi3+0x48>
f0104c02:	39 f7                	cmp    %esi,%edi
f0104c04:	0f 86 a2 00 00 00    	jbe    f0104cac <__umoddi3+0xd8>
f0104c0a:	89 c8                	mov    %ecx,%eax
f0104c0c:	89 f2                	mov    %esi,%edx
f0104c0e:	f7 f7                	div    %edi
f0104c10:	89 d0                	mov    %edx,%eax
f0104c12:	31 d2                	xor    %edx,%edx
f0104c14:	83 c4 1c             	add    $0x1c,%esp
f0104c17:	5b                   	pop    %ebx
f0104c18:	5e                   	pop    %esi
f0104c19:	5f                   	pop    %edi
f0104c1a:	5d                   	pop    %ebp
f0104c1b:	c3                   	ret    
f0104c1c:	39 f0                	cmp    %esi,%eax
f0104c1e:	0f 87 ac 00 00 00    	ja     f0104cd0 <__umoddi3+0xfc>
f0104c24:	0f bd e8             	bsr    %eax,%ebp
f0104c27:	83 f5 1f             	xor    $0x1f,%ebp
f0104c2a:	0f 84 ac 00 00 00    	je     f0104cdc <__umoddi3+0x108>
f0104c30:	bf 20 00 00 00       	mov    $0x20,%edi
f0104c35:	29 ef                	sub    %ebp,%edi
f0104c37:	89 fe                	mov    %edi,%esi
f0104c39:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104c3d:	89 e9                	mov    %ebp,%ecx
f0104c3f:	d3 e0                	shl    %cl,%eax
f0104c41:	89 d7                	mov    %edx,%edi
f0104c43:	89 f1                	mov    %esi,%ecx
f0104c45:	d3 ef                	shr    %cl,%edi
f0104c47:	09 c7                	or     %eax,%edi
f0104c49:	89 e9                	mov    %ebp,%ecx
f0104c4b:	d3 e2                	shl    %cl,%edx
f0104c4d:	89 14 24             	mov    %edx,(%esp)
f0104c50:	89 d8                	mov    %ebx,%eax
f0104c52:	d3 e0                	shl    %cl,%eax
f0104c54:	89 c2                	mov    %eax,%edx
f0104c56:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104c5a:	d3 e0                	shl    %cl,%eax
f0104c5c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c60:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104c64:	89 f1                	mov    %esi,%ecx
f0104c66:	d3 e8                	shr    %cl,%eax
f0104c68:	09 d0                	or     %edx,%eax
f0104c6a:	d3 eb                	shr    %cl,%ebx
f0104c6c:	89 da                	mov    %ebx,%edx
f0104c6e:	f7 f7                	div    %edi
f0104c70:	89 d3                	mov    %edx,%ebx
f0104c72:	f7 24 24             	mull   (%esp)
f0104c75:	89 c6                	mov    %eax,%esi
f0104c77:	89 d1                	mov    %edx,%ecx
f0104c79:	39 d3                	cmp    %edx,%ebx
f0104c7b:	0f 82 87 00 00 00    	jb     f0104d08 <__umoddi3+0x134>
f0104c81:	0f 84 91 00 00 00    	je     f0104d18 <__umoddi3+0x144>
f0104c87:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104c8b:	29 f2                	sub    %esi,%edx
f0104c8d:	19 cb                	sbb    %ecx,%ebx
f0104c8f:	89 d8                	mov    %ebx,%eax
f0104c91:	8a 4c 24 0c          	mov    0xc(%esp),%cl
f0104c95:	d3 e0                	shl    %cl,%eax
f0104c97:	89 e9                	mov    %ebp,%ecx
f0104c99:	d3 ea                	shr    %cl,%edx
f0104c9b:	09 d0                	or     %edx,%eax
f0104c9d:	89 e9                	mov    %ebp,%ecx
f0104c9f:	d3 eb                	shr    %cl,%ebx
f0104ca1:	89 da                	mov    %ebx,%edx
f0104ca3:	83 c4 1c             	add    $0x1c,%esp
f0104ca6:	5b                   	pop    %ebx
f0104ca7:	5e                   	pop    %esi
f0104ca8:	5f                   	pop    %edi
f0104ca9:	5d                   	pop    %ebp
f0104caa:	c3                   	ret    
f0104cab:	90                   	nop
f0104cac:	89 fd                	mov    %edi,%ebp
f0104cae:	85 ff                	test   %edi,%edi
f0104cb0:	75 0b                	jne    f0104cbd <__umoddi3+0xe9>
f0104cb2:	b8 01 00 00 00       	mov    $0x1,%eax
f0104cb7:	31 d2                	xor    %edx,%edx
f0104cb9:	f7 f7                	div    %edi
f0104cbb:	89 c5                	mov    %eax,%ebp
f0104cbd:	89 f0                	mov    %esi,%eax
f0104cbf:	31 d2                	xor    %edx,%edx
f0104cc1:	f7 f5                	div    %ebp
f0104cc3:	89 c8                	mov    %ecx,%eax
f0104cc5:	f7 f5                	div    %ebp
f0104cc7:	89 d0                	mov    %edx,%eax
f0104cc9:	e9 44 ff ff ff       	jmp    f0104c12 <__umoddi3+0x3e>
f0104cce:	66 90                	xchg   %ax,%ax
f0104cd0:	89 c8                	mov    %ecx,%eax
f0104cd2:	89 f2                	mov    %esi,%edx
f0104cd4:	83 c4 1c             	add    $0x1c,%esp
f0104cd7:	5b                   	pop    %ebx
f0104cd8:	5e                   	pop    %esi
f0104cd9:	5f                   	pop    %edi
f0104cda:	5d                   	pop    %ebp
f0104cdb:	c3                   	ret    
f0104cdc:	3b 04 24             	cmp    (%esp),%eax
f0104cdf:	72 06                	jb     f0104ce7 <__umoddi3+0x113>
f0104ce1:	3b 7c 24 04          	cmp    0x4(%esp),%edi
f0104ce5:	77 0f                	ja     f0104cf6 <__umoddi3+0x122>
f0104ce7:	89 f2                	mov    %esi,%edx
f0104ce9:	29 f9                	sub    %edi,%ecx
f0104ceb:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0104cef:	89 14 24             	mov    %edx,(%esp)
f0104cf2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104cf6:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104cfa:	8b 14 24             	mov    (%esp),%edx
f0104cfd:	83 c4 1c             	add    $0x1c,%esp
f0104d00:	5b                   	pop    %ebx
f0104d01:	5e                   	pop    %esi
f0104d02:	5f                   	pop    %edi
f0104d03:	5d                   	pop    %ebp
f0104d04:	c3                   	ret    
f0104d05:	8d 76 00             	lea    0x0(%esi),%esi
f0104d08:	2b 04 24             	sub    (%esp),%eax
f0104d0b:	19 fa                	sbb    %edi,%edx
f0104d0d:	89 d1                	mov    %edx,%ecx
f0104d0f:	89 c6                	mov    %eax,%esi
f0104d11:	e9 71 ff ff ff       	jmp    f0104c87 <__umoddi3+0xb3>
f0104d16:	66 90                	xchg   %ax,%ax
f0104d18:	39 44 24 04          	cmp    %eax,0x4(%esp)
f0104d1c:	72 ea                	jb     f0104d08 <__umoddi3+0x134>
f0104d1e:	89 d9                	mov    %ebx,%ecx
f0104d20:	e9 62 ff ff ff       	jmp    f0104c87 <__umoddi3+0xb3>
