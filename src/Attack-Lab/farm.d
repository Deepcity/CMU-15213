
farm.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <start_farm>:
   0:	f3 0f 1e fa          	endbr64 
   4:	b8 01 00 00 00       	mov    $0x1,%eax
   9:	c3                   	ret    
   a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000000010 <getval_142>:
  10:	f3 0f 1e fa          	endbr64 
  14:	b8 fb 78 90 90       	mov    $0x909078fb,%eax
  19:	c3                   	ret    
  1a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000000020 <addval_273>:
  20:	f3 0f 1e fa          	endbr64 
  24:	8d 87 48 89 c7 c3    	lea    -0x3c3876b8(%rdi),%eax
  2a:	c3                   	ret    
  2b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000030 <addval_219>:
  30:	f3 0f 1e fa          	endbr64 
  34:	8d 87 51 73 58 90    	lea    -0x6fa78caf(%rdi),%eax
  3a:	c3                   	ret    
  3b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000040 <setval_237>:
  40:	f3 0f 1e fa          	endbr64 
  44:	c7 07 48 89 c7 c7    	movl   $0xc7c78948,(%rdi)
  4a:	c3                   	ret    
  4b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000050 <setval_424>:
  50:	f3 0f 1e fa          	endbr64 
  54:	c7 07 54 c2 58 92    	movl   $0x9258c254,(%rdi)
  5a:	c3                   	ret    
  5b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000060 <setval_470>:
  60:	f3 0f 1e fa          	endbr64 
  64:	c7 07 63 48 8d c7    	movl   $0xc78d4863,(%rdi)
  6a:	c3                   	ret    
  6b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000070 <setval_426>:
  70:	f3 0f 1e fa          	endbr64 
  74:	c7 07 48 89 c7 90    	movl   $0x90c78948,(%rdi)
  7a:	c3                   	ret    
  7b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000080 <getval_280>:
  80:	f3 0f 1e fa          	endbr64 
  84:	b8 29 58 90 c3       	mov    $0xc3905829,%eax
  89:	c3                   	ret    
  8a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000000090 <mid_farm>:
  90:	f3 0f 1e fa          	endbr64 
  94:	b8 01 00 00 00       	mov    $0x1,%eax
  99:	c3                   	ret    
  9a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

00000000000000a0 <add_xy>:
  a0:	f3 0f 1e fa          	endbr64 
  a4:	48 8d 04 37          	lea    (%rdi,%rsi,1),%rax
  a8:	c3                   	ret    
  a9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

00000000000000b0 <getval_481>:
  b0:	f3 0f 1e fa          	endbr64 
  b4:	b8 5c 89 c2 90       	mov    $0x90c2895c,%eax
  b9:	c3                   	ret    
  ba:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

00000000000000c0 <setval_296>:
  c0:	f3 0f 1e fa          	endbr64 
  c4:	c7 07 99 d1 90 90    	movl   $0x9090d199,(%rdi)
  ca:	c3                   	ret    
  cb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000000d0 <addval_113>:
  d0:	f3 0f 1e fa          	endbr64 
  d4:	8d 87 89 ce 78 c9    	lea    -0x36873177(%rdi),%eax
  da:	c3                   	ret    
  db:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000000e0 <addval_490>:
  e0:	f3 0f 1e fa          	endbr64 
  e4:	8d 87 8d d1 20 db    	lea    -0x24df2e73(%rdi),%eax
  ea:	c3                   	ret    
  eb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000000f0 <getval_226>:
  f0:	f3 0f 1e fa          	endbr64 
  f4:	b8 89 d1 48 c0       	mov    $0xc048d189,%eax
  f9:	c3                   	ret    
  fa:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000000100 <setval_384>:
 100:	f3 0f 1e fa          	endbr64 
 104:	c7 07 81 d1 84 c0    	movl   $0xc084d181,(%rdi)
 10a:	c3                   	ret    
 10b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000110 <addval_190>:
 110:	f3 0f 1e fa          	endbr64 
 114:	8d 87 41 48 89 e0    	lea    -0x1f76b7bf(%rdi),%eax
 11a:	c3                   	ret    
 11b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000120 <setval_276>:
 120:	f3 0f 1e fa          	endbr64 
 124:	c7 07 88 c2 08 c9    	movl   $0xc908c288,(%rdi)
 12a:	c3                   	ret    
 12b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000130 <addval_436>:
 130:	f3 0f 1e fa          	endbr64 
 134:	8d 87 89 ce 90 90    	lea    -0x6f6f3177(%rdi),%eax
 13a:	c3                   	ret    
 13b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000140 <getval_345>:
 140:	f3 0f 1e fa          	endbr64 
 144:	b8 48 89 e0 c1       	mov    $0xc1e08948,%eax
 149:	c3                   	ret    
 14a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000000150 <addval_479>:
 150:	f3 0f 1e fa          	endbr64 
 154:	8d 87 89 c2 00 c9    	lea    -0x36ff3d77(%rdi),%eax
 15a:	c3                   	ret    
 15b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000160 <addval_187>:
 160:	f3 0f 1e fa          	endbr64 
 164:	8d 87 89 ce 38 c0    	lea    -0x3fc73177(%rdi),%eax
 16a:	c3                   	ret    
 16b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000170 <setval_248>:
 170:	f3 0f 1e fa          	endbr64 
 174:	c7 07 81 ce 08 db    	movl   $0xdb08ce81,(%rdi)
 17a:	c3                   	ret    
 17b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000180 <getval_159>:
 180:	f3 0f 1e fa          	endbr64 
 184:	b8 89 d1 38 c9       	mov    $0xc938d189,%eax
 189:	c3                   	ret    
 18a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000000190 <addval_110>:
 190:	f3 0f 1e fa          	endbr64 
 194:	8d 87 c8 89 e0 c3    	lea    -0x3c1f7638(%rdi),%eax
 19a:	c3                   	ret    
 19b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000001a0 <addval_487>:
 1a0:	f3 0f 1e fa          	endbr64 
 1a4:	8d 87 89 c2 84 c0    	lea    -0x3f7b3d77(%rdi),%eax
 1aa:	c3                   	ret    
 1ab:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000001b0 <addval_201>:
 1b0:	f3 0f 1e fa          	endbr64 
 1b4:	8d 87 48 89 e0 c7    	lea    -0x381f76b8(%rdi),%eax
 1ba:	c3                   	ret    
 1bb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000001c0 <getval_272>:
 1c0:	f3 0f 1e fa          	endbr64 
 1c4:	b8 99 d1 08 d2       	mov    $0xd208d199,%eax
 1c9:	c3                   	ret    
 1ca:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

00000000000001d0 <getval_155>:
 1d0:	f3 0f 1e fa          	endbr64 
 1d4:	b8 89 c2 c4 c9       	mov    $0xc9c4c289,%eax
 1d9:	c3                   	ret    
 1da:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

00000000000001e0 <setval_299>:
 1e0:	f3 0f 1e fa          	endbr64 
 1e4:	c7 07 48 89 e0 91    	movl   $0x91e08948,(%rdi)
 1ea:	c3                   	ret    
 1eb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000001f0 <addval_404>:
 1f0:	f3 0f 1e fa          	endbr64 
 1f4:	8d 87 89 ce 92 c3    	lea    -0x3c6d3177(%rdi),%eax
 1fa:	c3                   	ret    
 1fb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000200 <getval_311>:
 200:	f3 0f 1e fa          	endbr64 
 204:	b8 89 d1 08 db       	mov    $0xdb08d189,%eax
 209:	c3                   	ret    
 20a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000000210 <setval_167>:
 210:	f3 0f 1e fa          	endbr64 
 214:	c7 07 89 d1 91 c3    	movl   $0xc391d189,(%rdi)
 21a:	c3                   	ret    
 21b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000220 <setval_328>:
 220:	f3 0f 1e fa          	endbr64 
 224:	c7 07 81 c2 38 d2    	movl   $0xd238c281,(%rdi)
 22a:	c3                   	ret    
 22b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000230 <setval_450>:
 230:	f3 0f 1e fa          	endbr64 
 234:	c7 07 09 ce 08 c9    	movl   $0xc908ce09,(%rdi)
 23a:	c3                   	ret    
 23b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000240 <addval_358>:
 240:	f3 0f 1e fa          	endbr64 
 244:	8d 87 08 89 e0 90    	lea    -0x6f1f76f8(%rdi),%eax
 24a:	c3                   	ret    
 24b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000250 <addval_124>:
 250:	f3 0f 1e fa          	endbr64 
 254:	8d 87 89 c2 c7 3c    	lea    0x3cc7c289(%rdi),%eax
 25a:	c3                   	ret    
 25b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000260 <getval_169>:
 260:	f3 0f 1e fa          	endbr64 
 264:	b8 88 ce 20 c0       	mov    $0xc020ce88,%eax
 269:	c3                   	ret    
 26a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000000270 <setval_181>:
 270:	f3 0f 1e fa          	endbr64 
 274:	c7 07 48 89 e0 c2    	movl   $0xc2e08948,(%rdi)
 27a:	c3                   	ret    
 27b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000280 <addval_184>:
 280:	f3 0f 1e fa          	endbr64 
 284:	8d 87 89 c2 60 d2    	lea    -0x2d9f3d77(%rdi),%eax
 28a:	c3                   	ret    
 28b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000000290 <getval_472>:
 290:	f3 0f 1e fa          	endbr64 
 294:	b8 8d ce 20 d2       	mov    $0xd220ce8d,%eax
 299:	c3                   	ret    
 29a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

00000000000002a0 <setval_350>:
 2a0:	f3 0f 1e fa          	endbr64 
 2a4:	c7 07 48 89 e0 90    	movl   $0x90e08948,(%rdi)
 2aa:	c3                   	ret    
 2ab:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000002b0 <end_farm>:
 2b0:	f3 0f 1e fa          	endbr64 
 2b4:	b8 01 00 00 00       	mov    $0x1,%eax
 2b9:	c3                   	ret    

Disassembly of section .text.startup:

0000000000000000 <main>:
   0:	f3 0f 1e fa          	endbr64 
   4:	c3                   	ret    
