	.arch armv7-a 
	@ 使用 ARMv7-a 指令集
	.text
	@ 接下来是代码区
	.global main
	.type main, %function
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

	mov r4, #0 @a = 0
	mov r5, #1 @b = 1
	mov r7, #1 @i = 1
	@ r4中存a的值，r5中存b的值，r7中存i的值，r6中存n的值

	@ 输出a的值
	ldr r0, =_str
	mov r1, r4
	@ 将a的值赋给r1
	bl printf
	@ 打印a的值

	@ 输出b的值
	ldr r0, =_str2
	mov r1, r5
	@ 将b的值赋给r1
	bl printf
	@ 打印b的值

	@ 输出b的值
	ldr r0, =_str3
	mov r1, r5
	@ 将b的值赋给r1
	bl printf
	@ 打印b的值

Loop:
	cmp r6, r7
	ble RETURN
	@ 比较n和i的大小用于跳转
	mov r8, r5 
	@ r8为临时变量的寄存器t，存b
	add r5, r5, r4
	@ b = a + b
	ldr r0, =_str3
	mov r1, r5
	@ 将r5中的值即b的值赋予r1
	bl printf
	mov r4, r8
	@ a = t
	add r7, r7, #1
	@ i = i + 1
	b Loop
RETURN:
	mov r0, #0
	pop {fp, lr} 
.data
_scanfformat:
	.asciz "%d"

_str:
	.asciz "a is %d\n"

_str2:
	.asciz "b is %d\n"

_str3:
        .asciz "%d\n"

.section .note.GNU-stack,"",%progbits @ do you know what's the use of this :-)
