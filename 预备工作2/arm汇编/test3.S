	.arch armv7-a 
	@ 使用 ARMv7-a 指令集
	.text
	@ 接下来是代码区
	.align 2
	.global max
min: @ function int max(int a, int b)
	str fp, [sp, #-4]!
	mov fp, sp
	sub sp, sp, #12
	str r0, [fp, #-8]
	str r1, [fp, #-12]
	cmp r1, r0
	blt .L2
	ldr r0, [fp, #-8]
	b .L3
.L2:
	ldr r0, [fp, #-12]
.L3:
	add sp, fp, #0
	ldr fp, [sp], #4
	bx lr

	.global main
main:	
	push {fp, lr}
	@ 将fp的当前值保存在堆栈上，然后将sp寄存器的值保存在fp中，lr中存储的是pc的保存在lr中
	sub sp, sp, #4
	@ 开辟4字节的内存，为后续的函数调用做准备
	ldr r0, =_scanfformat
	@ 在ARM汇编中，"ldr" 用于加载数据到寄存器中，通常用于加载内存中的值到寄存器。
	@ ldr Rd, =label 在这里就是将"%d"这样的格式读入到r0中，作为scanf函数的参数
	mov r1, sp
	@ 将sp的值传输给r1寄存器，使scanf传入的值存储在栈上，即栈顶的值是n
	bl scanf
	@ 分支链接指令，用于跳转到一个名为 "scanf" 的函数
	ldr r6, [sp, #0]
	@ 取出sp指针指向的地址中的内容，即栈顶中的内容（输入的n的值），放在r6中
	add sp, sp, #4
	@ 恢复栈顶，释放内存空间

	sub sp, sp, #4
	@ 开辟4字节的内存，为后续的函数调用做准备
	ldr r0, =_scanfformat
	@ 在ARM汇编中，"ldr" 用于加载数据到寄存器中，通常用于加载内存中的值到寄存器。
	@ ldr Rd, =label 在这里就是将"%d"这样的格式读入到r0中，作为scanf函数的参数
	mov r1, sp
	@ 将sp的值传输给r1寄存器，使scanf传入的值存储在栈上，即栈顶的值是n
	bl scanf
	@ 分支链接指令，用于跳转到一个名为 "scanf" 的函数
	ldr r7, [sp, #0]
	@ 取出sp指针指向的地址中的内容，即栈顶中的内容（输入的n的值），放在r6中
	add sp, sp, #4

	mov r0, r6
	mov r1, r7
	@ 恢复栈顶，释放内存空间
	bl min
	mov r1, r0
	ldr r0, =_str2
	@ 将r5中的值即b的值赋予r1
	bl printf
	mov r0, #0
	pop {fp, lr} 
.data
_scanfformat:
	.asciz "%d"
_str2:
        .asciz "min is: %d\n"
_str3:
        .asciz "%d\n"


.section .note.GNU-stack,"",%progbits @ do you know what's the use of this :-)
