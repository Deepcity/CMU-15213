
examples.o:     file format elf64-x86-64


Disassembly of section .init:

0000000000001000 <_init>:
    1000:	f3 0f 1e fa          	endbr64 
    1004:	48 83 ec 08          	sub    $0x8,%rsp
    1008:	48 8b 05 d9 2f 00 00 	mov    0x2fd9(%rip),%rax        # 3fe8 <__gmon_start__@Base>
    100f:	48 85 c0             	test   %rax,%rax
    1012:	74 02                	je     1016 <_init+0x16>
    1014:	ff d0                	call   *%rax
    1016:	48 83 c4 08          	add    $0x8,%rsp
    101a:	c3                   	ret    

Disassembly of section .plt:

0000000000001020 <.plt>:
    1020:	ff 35 a2 2f 00 00    	push   0x2fa2(%rip)        # 3fc8 <_GLOBAL_OFFSET_TABLE_+0x8>
    1026:	f2 ff 25 a3 2f 00 00 	bnd jmp *0x2fa3(%rip)        # 3fd0 <_GLOBAL_OFFSET_TABLE_+0x10>
    102d:	0f 1f 00             	nopl   (%rax)

Disassembly of section .plt.got:

0000000000001030 <__cxa_finalize@plt>:
    1030:	f3 0f 1e fa          	endbr64 
    1034:	f2 ff 25 bd 2f 00 00 	bnd jmp *0x2fbd(%rip)        # 3ff8 <__cxa_finalize@GLIBC_2.2.5>
    103b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

Disassembly of section .text:

0000000000001040 <_start>:
    1040:	f3 0f 1e fa          	endbr64 
    1044:	31 ed                	xor    %ebp,%ebp
    1046:	49 89 d1             	mov    %rdx,%r9
    1049:	5e                   	pop    %rsi
    104a:	48 89 e2             	mov    %rsp,%rdx
    104d:	48 83 e4 f0          	and    $0xfffffffffffffff0,%rsp
    1051:	50                   	push   %rax
    1052:	54                   	push   %rsp
    1053:	45 31 c0             	xor    %r8d,%r8d
    1056:	31 c9                	xor    %ecx,%ecx
    1058:	48 8d 3d ac 01 00 00 	lea    0x1ac(%rip),%rdi        # 120b <main>
    105f:	ff 15 73 2f 00 00    	call   *0x2f73(%rip)        # 3fd8 <__libc_start_main@GLIBC_2.34>
    1065:	f4                   	hlt    
    1066:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    106d:	00 00 00 

0000000000001070 <deregister_tm_clones>:
    1070:	48 8d 3d 99 2f 00 00 	lea    0x2f99(%rip),%rdi        # 4010 <__TMC_END__>
    1077:	48 8d 05 92 2f 00 00 	lea    0x2f92(%rip),%rax        # 4010 <__TMC_END__>
    107e:	48 39 f8             	cmp    %rdi,%rax
    1081:	74 15                	je     1098 <deregister_tm_clones+0x28>
    1083:	48 8b 05 56 2f 00 00 	mov    0x2f56(%rip),%rax        # 3fe0 <_ITM_deregisterTMCloneTable@Base>
    108a:	48 85 c0             	test   %rax,%rax
    108d:	74 09                	je     1098 <deregister_tm_clones+0x28>
    108f:	ff e0                	jmp    *%rax
    1091:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    1098:	c3                   	ret    
    1099:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

00000000000010a0 <register_tm_clones>:
    10a0:	48 8d 3d 69 2f 00 00 	lea    0x2f69(%rip),%rdi        # 4010 <__TMC_END__>
    10a7:	48 8d 35 62 2f 00 00 	lea    0x2f62(%rip),%rsi        # 4010 <__TMC_END__>
    10ae:	48 29 fe             	sub    %rdi,%rsi
    10b1:	48 89 f0             	mov    %rsi,%rax
    10b4:	48 c1 ee 3f          	shr    $0x3f,%rsi
    10b8:	48 c1 f8 03          	sar    $0x3,%rax
    10bc:	48 01 c6             	add    %rax,%rsi
    10bf:	48 d1 fe             	sar    %rsi
    10c2:	74 14                	je     10d8 <register_tm_clones+0x38>
    10c4:	48 8b 05 25 2f 00 00 	mov    0x2f25(%rip),%rax        # 3ff0 <_ITM_registerTMCloneTable@Base>
    10cb:	48 85 c0             	test   %rax,%rax
    10ce:	74 08                	je     10d8 <register_tm_clones+0x38>
    10d0:	ff e0                	jmp    *%rax
    10d2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    10d8:	c3                   	ret    
    10d9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

00000000000010e0 <__do_global_dtors_aux>:
    10e0:	f3 0f 1e fa          	endbr64 
    10e4:	80 3d 25 2f 00 00 00 	cmpb   $0x0,0x2f25(%rip)        # 4010 <__TMC_END__>
    10eb:	75 2b                	jne    1118 <__do_global_dtors_aux+0x38>
    10ed:	55                   	push   %rbp
    10ee:	48 83 3d 02 2f 00 00 	cmpq   $0x0,0x2f02(%rip)        # 3ff8 <__cxa_finalize@GLIBC_2.2.5>
    10f5:	00 
    10f6:	48 89 e5             	mov    %rsp,%rbp
    10f9:	74 0c                	je     1107 <__do_global_dtors_aux+0x27>
    10fb:	48 8b 3d 06 2f 00 00 	mov    0x2f06(%rip),%rdi        # 4008 <__dso_handle>
    1102:	e8 29 ff ff ff       	call   1030 <__cxa_finalize@plt>
    1107:	e8 64 ff ff ff       	call   1070 <deregister_tm_clones>
    110c:	c6 05 fd 2e 00 00 01 	movb   $0x1,0x2efd(%rip)        # 4010 <__TMC_END__>
    1113:	5d                   	pop    %rbp
    1114:	c3                   	ret    
    1115:	0f 1f 00             	nopl   (%rax)
    1118:	c3                   	ret    
    1119:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

0000000000001120 <frame_dummy>:
    1120:	f3 0f 1e fa          	endbr64 
    1124:	e9 77 ff ff ff       	jmp    10a0 <register_tm_clones>

0000000000001129 <sum_list>:
    1129:	f3 0f 1e fa          	endbr64 
    112d:	55                   	push   %rbp
    112e:	48 89 e5             	mov    %rsp,%rbp
    1131:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
    1135:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
    113c:	00 
    113d:	eb 17                	jmp    1156 <sum_list+0x2d>
    113f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
    1143:	48 8b 00             	mov    (%rax),%rax
    1146:	48 01 45 f8          	add    %rax,-0x8(%rbp)
    114a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
    114e:	48 8b 40 08          	mov    0x8(%rax),%rax
    1152:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
    1156:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
    115b:	75 e2                	jne    113f <sum_list+0x16>
    115d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
    1161:	5d                   	pop    %rbp
    1162:	c3                   	ret    

0000000000001163 <rsum_list>:
    1163:	f3 0f 1e fa          	endbr64 
    1167:	55                   	push   %rbp
    1168:	48 89 e5             	mov    %rsp,%rbp
    116b:	48 83 ec 20          	sub    $0x20,%rsp
    116f:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
    1173:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
    1178:	75 07                	jne    1181 <rsum_list+0x1e>
    117a:	b8 00 00 00 00       	mov    $0x0,%eax
    117f:	eb 2a                	jmp    11ab <rsum_list+0x48>
    1181:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
    1185:	48 8b 00             	mov    (%rax),%rax
    1188:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    118c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
    1190:	48 8b 40 08          	mov    0x8(%rax),%rax
    1194:	48 89 c7             	mov    %rax,%rdi
    1197:	e8 c7 ff ff ff       	call   1163 <rsum_list>
    119c:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
    11a0:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
    11a4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
    11a8:	48 01 d0             	add    %rdx,%rax
    11ab:	c9                   	leave  
    11ac:	c3                   	ret    

00000000000011ad <copy_block>:
    11ad:	f3 0f 1e fa          	endbr64 
    11b1:	55                   	push   %rbp
    11b2:	48 89 e5             	mov    %rsp,%rbp
    11b5:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
    11b9:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
    11bd:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
    11c1:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
    11c8:	00 
    11c9:	eb 33                	jmp    11fe <copy_block+0x51>
    11cb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
    11cf:	48 8d 50 08          	lea    0x8(%rax),%rdx
    11d3:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
    11d7:	48 8b 00             	mov    (%rax),%rax
    11da:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
    11de:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
    11e2:	48 8d 50 08          	lea    0x8(%rax),%rdx
    11e6:	48 89 55 e0          	mov    %rdx,-0x20(%rbp)
    11ea:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
    11ee:	48 89 10             	mov    %rdx,(%rax)
    11f1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
    11f5:	48 31 45 f0          	xor    %rax,-0x10(%rbp)
    11f9:	48 83 6d d8 01       	subq   $0x1,-0x28(%rbp)
    11fe:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
    1203:	7f c6                	jg     11cb <copy_block+0x1e>
    1205:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
    1209:	5d                   	pop    %rbp
    120a:	c3                   	ret    

000000000000120b <main>:
    120b:	f3 0f 1e fa          	endbr64 
    120f:	55                   	push   %rbp
    1210:	48 89 e5             	mov    %rsp,%rbp
    1213:	90                   	nop
    1214:	5d                   	pop    %rbp
    1215:	c3                   	ret    

Disassembly of section .fini:

0000000000001218 <_fini>:
    1218:	f3 0f 1e fa          	endbr64 
    121c:	48 83 ec 08          	sub    $0x8,%rsp
    1220:	48 83 c4 08          	add    $0x8,%rsp
    1224:	c3                   	ret    
