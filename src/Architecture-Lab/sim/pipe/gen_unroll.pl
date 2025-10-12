#!/usr/bin/perl
use strict;
use warnings;

my @unrolls = (2,4,6,8,10);  # 支持循环展开路数
my $template_file = "ncopy.ys";  # 原始模板文件
my $outfile_prefix = "ncopy_";

# 读取模板
open my $tmpl_fh, "<", $template_file or die $!;
my @template = <$tmpl_fh>;
close $tmpl_fh;

# 找到 Loop1 起点和 Update 结束行号
my ($loop_start, $loop_end);
for my $i (0..$#template) {
    $loop_start = $i if $template[$i] =~ /^# Loop header/;
    $loop_end   = $i if $template[$i] =~ /^Root:/;
}
die "未找到 xor/Root 标签" unless defined $loop_start && defined $loop_end;

# 尾部模板（Test1 后到文件末尾）
my @tail_template = @template[$loop_end..$#template];

foreach my $n (@unrolls) {
    my $outfile = "${outfile_prefix}${n}.ys";
    open my $out_fh, ">", $outfile or die $!;

    # 输出 Loop1 前的内容
    for my $i (0..$loop_start-1) {
        print $out_fh $template[$i];
    }

    # 生成 Loop 展开
    my $loop_idx = 1;
    my $offset = 0;

    print $out_fh <<"HEAD";

    #xorq   %rax,%rax
    iaddq   \$-10, %rdx
    jl      Root            # len < 10
HEAD

    while ($offset < $n*8) {
        my $r8_offset = $offset;
        my $r9_offset = $offset + 8;

        print $out_fh <<"LOOP";

Loop$loop_idx:
    mrmovq  $r8_offset(%rdi), %r8
    mrmovq  $r9_offset(%rdi), %r9
    andq    %r8, %r8
    rmmovq  %r8, $r8_offset(%rsi)
    rmmovq  %r9, $r9_offset(%rsi)
    jle     Loop${loop_idx}1
    iaddq   \$1, %rax
Loop${loop_idx}1:
    andq    %r9, %r9
    jle     Loop${loop_idx}2
    iaddq   \$1, %rax
Loop${loop_idx}2:

LOOP

        $offset += 16;
        $loop_idx++;
    }

    # 添加 Update 和 Test1
    my $update_bytes = $n*8;  # 每次循环处理 n*2 个元素，每个元素 8 字节
    print $out_fh <<"UPDATE";
Update:
    iaddq   \$$update_bytes, %rdi
    iaddq   \$$update_bytes, %rsi

Test1:
    iaddq   \$-$n, %rdx
    jge     Loop1
UPDATE

    # 输出尾部模板
    print $out_fh @tail_template;

    close $out_fh;
    print "生成 $outfile 完成\n";
}
