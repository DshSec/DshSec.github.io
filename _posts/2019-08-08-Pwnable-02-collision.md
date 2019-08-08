---
layout: post
title: Pwnable-01-fd
description: >
  这是pwnable的第二题collision的解析过程
tags: [技术]
author: author1
accent_image:          /assets/img/sidebar-bg.jpg
accent_color:          '#4fb1ba'
---
# pwnable的第二题collision
  ['pwnable.kr'](https://pwnable.kr/index.php)is a non-commercial wargame site which provides various pwn challenges regarding system exploitation. the main purpose of pwnable.kr is 'fun'.    please consider each of the challenges as a game. while playing pwnable.kr, you could learn/improve system hacking skills but that shouldn't be your only purpose.

## 源代码：
```c++
  #include <stdio.h>
  #include <string.h>
  unsigned long hashcode = 0x21DD09EC;
  unsigned long check_password(const char* p){
  	int* ip = (int*)p;                      
  	int i;
  	int res=0;
  	for(i=0; i<5; i++){
  		res += ip[i];                       
  	}
  	return res;
  }
  /* res=ip[0]+res
  res=ip[1]+res
  res=ip[2]+res
  res=ip[3]+res
  res=ip[4]+res
  res=hashcode
  system("/bin/cat flag");
  */

  int main(int argc, char* argv[]){
  	if(argc<2){
  		printf("usage : %s [passcode]\n", argv[0]);                                //带第二个参数
  		return 0;
  	}

  	if(strlen(argv[1]) != 20){
  		printf("passcode length should be 20 bytes\n");                            //第二个参数为20字节
  		return 0;
  	}

  	if(hashcode == check_password( argv[1] )){                                      //由函数代码可知，argv为5部分，且加起来等于hashcode
  		system("/bin/cat flag");
  		return 0;
  	}
  	else
  		printf("wrong passcode.\n");
  	return 0;
  }

  ```
## 解题思路：
  1. 要输入一个字符串使得argv的五部分加起来等于hashcode，即 0x21DD09EC；
  2. 将 0x21DD09EC拆分成五部分，可以转换成10进制后进行随意拆分，拆成a*4+b这样的格式(更方便)；例如a=0x01020304 b=shellcode-a*4=0x1dd4fddc
  ![Full-width image](/assets/img/docs/Pwnable_2_collision.png)
  3. 利用python -c  来执行拆出来的shellcode；在用$将程序结果结果引入程序
  4. 注意小段序输入，低位在前高位在后；

## 解答：
  ./col $(python -c 'print "\x04\x03\x02\x01" * 4+"\xdc\xfd\xd4\x1d"')
## poc
```python

  from pwn import *
  pwn_ssh=ssh(host='pwnable.kr',user='col',password='guest',port=2222)
  print(pwn_ssh.connected())
  sh=pwn_ssh.process(argv=['collision','\x04\x03\x02\x01'* 4 + '\xdc\xfd\xd4\x1d'],executable='./col')
  print(sh.recvall())

```

> **NOTE**：['大小端模式'](https://baike.baidu.com/item/%E5%A4%A7%E5%B0%8F%E7%AB%AF%E6%A8%A1%E5%BC%8F/6750542?fr=aladdin)大端模式，是指数据的高字节保存在内存的低地址中，而数据的低字节保存在内存的高地址中，这样的存储模式有点儿类似于把数据当作字符串顺序处理：地址由小向大增加，而数据从高位往低位放；这和我们的阅读习惯一致。小端模式，是指数据的高字节保存在内存的高地址中，而数据的低字节保存在内存的低地址中，这种存储模式将地址的高低和数据位权有效地结合起来，高地址部分权值高，低地址部分权值低.
