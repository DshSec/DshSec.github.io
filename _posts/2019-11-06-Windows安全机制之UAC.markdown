---
title: "Windows安全机制之UAC"
layout: post
date: 2019-11-06
image: /assets/images/markdown.jpg
headerImage: false
tag:
- Windows
- UAC
category: blog
blog: true
author: DshSec
description: goDoh
---

# UAC
UAC (User Account Control)是微软在Windows vista及更高版本采取的一种控制机制，UAC 中的管理员批准模式有助于防止恶意软件在管理员不知情的情况下静默安装。 它还有助于防止意外的系统范围的更改。 它可以用于强制执行更高级别的合规性，其中管理员必须主动同意或为每个管理进程提供凭据。UAC能够避免恶意软件的自动安装、自动运行和更改系统重要信息(其实是可绕过的)。但是并不能阻断手动触发的恶意软件。因此UAC不能替代防病毒软件。UAC只是众多Windows安全机制中的一种。

## 工作原理
UAC主要的优点在于当用管理员用户登陆并进行操作时，执行权限依旧是标准用户权限，当需要用管理员权限执行某些进程时再单独对该进程提供凭据。因为需要二次确认，有效的避免了管理员误操作。由于在未进行单独授权时即使管理员用户依旧是标准用户权限，也有效避免了恶意软件的静默安装和各种非法敏感操作。
可通过下图来理解使用了UAC时的管理员登陆过程。
![Full-width image](/assets/img/docs/UAC/1.png)  
当用户登录到windows时系统会为该用户创建访问令牌，访问令牌包含安全标识符SID和用户权限。当具备管理员权限的账号进行登陆时系统会创建两个token,一个是带有完全管理员权限的token,一个是标准用户的token。标准用户访问令牌包含与管理员访问令牌相同的特定于用户的信息，但会删除管理 Windows 权限和 Sid。使用标准用户的token来给Explorer.exe提供凭据，由于Explorer.exe作为父进程，因此所有子进程都会运行在标准用户权限下。除非用户提供同意或凭据来批准应用以使用完整的管理访问令牌。  
因此管理员可以使用管理员账号来安全的使用系统进行日常活动，当需要管理权限时windows会自动提醒要求同意和授权。标准用户通过UAC提升到管理员需要输入管理员凭据，管理员用户提升到管理权限仅仅需要点击同意。  
下图是管理员用户申请管理权限时的提醒：
![Full-width image](/assets/img/docs/UAC/2.png)  
下图是标准用户申请到管理权限时的提醒：
![Full-width image](/assets/img/docs/UAC/3.png)    
管理权限最常见的不必要用法是将应用程序设置或用户数据存储在注册表或文件系统中供系统使用的区域中。例如，某些旧版应用程序将其设置存储在注册表的系统范围部分（HKEY_LOCAL_MACHINE \ Software）中，而不是在用户部分（HKEY_CURRENT_USER \ Software）中存储，并且注册表虚拟化将尝试写入系统位置的尝试转移到另一位置。 HKEY_CURRENT_USER（HKCU），同时保留应用程序兼容性。

## UAC体系结构
![Full-width image](/assets/img/docs/UAC/4.gif)   
1. 当用户执行需要特权的操作时，如果操作更改了文件系统或注册表，则会调用虚拟化。 所有其他操作都调用 ShellExecute。  
2. 然后会到应用程序信息服务，应用程序信息服务可通过为应用程序创建新进程来帮助启动此类应用，方法是在需要提升时使用管理员用户's full 访问令牌，并且由用户提供的（取决于组策略）同意。
3. 检查ActiveX是否安装，若安装了则直接跳转到安全桌面判断。 若未安装则检查UAC滑块等级，然后根据UAC滑块的等级不同跳转到对应的支线。为低时直接创建进程、和进行安装行为检测。为中时经过当前当前签名检查决定是跳转到安全桌面还是创建进程。
>安全桌面：当可执行文件请求提升时，交互式桌面（也称为用户桌面）将切换到安全桌面。 安全桌面使用户桌面变暗，并显示在继续操作之前必须响应的提升提示。 当用户单击 "是" 或 " 否" 时，桌面将切换回用户桌面  

## Auto-Elevation
当执行部分程序时并不会出现UAC提示，例如控制面板中管理工具中的大部分程序。这是因为系统“自动提升”了该程序的执行权限。一般只有windows程序才会存在自动提示权限，存在自动提升权限的windows程序必须满足以下两个条件：它必须由Windows发布者进行数字签名，这是用于对Windows随附的所有代码进行签名的证书（仅由Microsoft签名是不够的，因此Microsoft软件不能不包括Windows中附带的内容）；并且它必须位于少数“安全”目录之一中。安全目录是标准用户无法修改的目录，其中包括%SystemRoot%\System32 (e.g.\Windows\System32)及其大部分子目录，%SystemRoot%\Ehome。另外，根据可执行文件是普通的.exe，Mmc.exe还是COM对象，自动提升具有其他规则。如果.exe品种的Windows可执行文件（如刚刚定义）在清单中指定autoElevate属性，则它们将自动提升，这也是应用程序向UAC指示其需要管理权限的地方。  
检查程序是否存在AutoElevation属性:
1. findstr /C:"<autoElevate>true" [ProgramPATH]  
2. sigcheck –m  [ProgramPATH] | findstr autoElevate  
结果如下图所示：  
![Full-width image](/assets/img/docs/UAC/4.png)
![Full-width image](/assets/img/docs/UAC/5.png)      
sigcheck下载链接：https://docs.microsoft.com/zh-cn/sysinternals/downloads/sigcheck    

## UACbypass
### 通过DLL劫持进行UAC绕过
#### 通过SystemPropertiesAdvanced.exe的DLL劫持进行UAC绕过
“SystemPropertiesAdvanced.exe”和其他SystemProperties*二进制文件可用于通过DLL劫持绕过Windows Server 2019上的UAC。  
查询程序具有autoElevate属性。
![Full-width image](/assets/img/docs/UAC/5.png)
通过process monitor对该程序进行监控在筛选过程中可以设定如下筛选条件快速定位。  
![Full-width image](/assets/img/docs/UAC/7.png)  
发现该程序会在AppData路径下寻找srrstr.dll文件。  
![Full-width image](/assets/img/docs/UAC/6.png)  
C:\Users\XXXX\AppData是可操作目录。因此我们可以通过替换srrstr.dll来进行一个dll劫持。可以通过Cacls 加文件夹路径来查看ACL信息，F表示完全控制，可见当前用户是对这个文件夹有完全控制权限的。     
![Full-width image](/assets/img/docs/UAC/8.png)  
利用msfvenom生成一个打开cmd的dll。然后将其放到上图中SystemPropertiesAdvanced.exe想要调用dll的路径去。  
![Full-width image](/assets/img/docs/UAC/9.png)    
放入dll文件后再运行SystemPropertiesAdvanced.exe即可弹出一个管理员的cmd，无需UAC确认。  

通过在安全与维护-用户账户控制设置中设置始终弹出可有效缓解此漏洞。windows18362已修复。
####

## 相关链接
1. 微软官方文档：https://docs.microsoft.com/zh-cn/windows/security/identity-protection/user-account-control/how-user-account-control-works   
2. 通过SystemPropertiesAdvanced.exe和DLL劫持进行的UAC绕过：https://egre55.github.io/system-properties-uac-bypass/  
3. QQ拼音输入法6.0最新版DLL劫持 - 可利用于提权：https://payloads.online/archivers/2018-06-09/1
