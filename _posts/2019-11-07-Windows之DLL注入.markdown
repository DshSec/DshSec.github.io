---
title: "Windows之DLL注入"
layout: post
date: 2019-11-07
image: /assets/images/markdown.jpg
headerImage: false
tag:
- Windows
- DLL注入
category: blog
blog: true
author: DshSec
description: goDoh
---

# Windows DLL注入基础

## .dll
.dll文件为动态链接库文件，Dynamic Link Library的缩写。DLL是一个包含可由多个程序，同时使用的代码和数据的库，这有助于避免代码重用和促进内存的有效使用。 通过使用 DLL，程序可以实现模块化，由相对独立的组件组成。  
常见的dll文件：  
1. USER32.DLL  Windows用户界面相关应用程序接口，用于包括Windows处理，基本用户界面等特性，如创建窗口和发送消息。
2. kernel32.dll Windows中非常重要的32位动态链接库文件，属于内核级文件。它控制着系统的内存管理、数据的输入输出操作和中断处理

## DLL注入
DLL注入是将代码插入正在运行的进程的过程。我们通常插入的代码是动态链接库（DLL）的形式，因为DLL是在运行时根据需要加载的。但是，这并不意味着我们不能以其他形式（可执行文件，手写文件等）注入程序集。需要注意的是您需要在系统上具有适当级别的特权才能使用其他程序的内存。  
Windows API实际上提供了许多功能，这些功能使我们可以为调试目的将其附加和处理到其他程序中。我们将利用这些方法来执行DLL注入。DLL注入的流程：
1. 附加到进程  
2. 在进程内分配内存  
3. 将DLL或DLL路径复制到进程内存中，并确定适当的内存地址    
4. 指示进程执行您的DLL  
![Full-width image](/assets/img/docs/DLL/DLLInjection-overview.png)



## 相关链接
1. dll注入基础：http://blog.opensecurityresearch.com/2013/01/windows-dll-injection-basics.html   
2. 改进的反射型DLL注入：https://disman.tl/2015/01/30/an-improved-reflective-dll-injection-technique.html  
3. 反射DLL注入的Shellcode实现：https://github.com/monoxgas/sRDI  
4. 使用直接系统调用和API脱钩实现AVbypass:https://github.com/outflanknl/Dumpert  
5. 利用直接系统调用和sRDI实现AVbypass(第4个github项目的博客地址):https://outflank.nl/blog/2019/06/19/red-team-tactics-combining-direct-system-calls-and-srdi-to-bypass-av-edr/
