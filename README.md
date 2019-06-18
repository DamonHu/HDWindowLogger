# HDWindowLogger

![](./ReadmeImage/cocoapodTool.png)

iOS端将输出日志log悬浮显示在屏幕上，可以生成日志文件分享，便于在真机没有连接xcode的情况下调试信息。可以分享、筛选log等操作

The iOS side displays the output log log on the screen, and can generate log file sharing, which is convenient for debugging information when the real machine is not connected to xcode. Log information can be filtered and shared

### [Document for English](#english)

### [中文文档](#chinese)

<span id = "english"></span>

## Introduction to English


Project address: [https://github.com/DamonHu/HDWindowLogger] (https://github.com/DamonHu/HDWindowLogger)

I am looking for an iOS and found a similar [HAMLogOutputWindow] (https://github.com/DaiYue/HAMLogOutputWindow). The source code is written by `textview`, but it cannot scroll queries and operations. At the same time, considering that the print network request output is still very large, for performance and subsequent expansion, so I rewrote one with `Tableview`.

Display effect gif:

![](./ReadmeImage/demo.gif)

In addition to displaying on the screen, you can set whether to automatically scroll the log for debugging, or you can share the output log to WeChat, twitter, etc. for offline viewing.

![](./ReadmeImage/2.png)

## I. Installation

You can choose to install using cocoaPod, or you can download the source file directly into the project.

### 1.1, cocoaPod installation

```
Pod 'HDWindowLogger'
```

### 1.2, file installation

You can drag the files in the `HDWindowLogger` folder to the project under the project.

## II. Use

Import header file

```
#import "HDWindowLogger.h"
```

Then feel free to use the following features

```
@property (strong, nonatomic, readonly) NSMutableArray *mLogDataArray;  //logData
/**
 According to the output type of the log, the corresponding log is output, and the different log types are different in color.

 @param log log content
 @param logType log type
 */
+ (void)printLog:(id)log withLogType:(HDLogType)logType;

/**
 Delete log log
 */
+ (void)cleanLog;

/**
 Display log window
 */
+ (void)show;


/**
 Hide the entire log window
 */
+ (void)hide;


/**
 Hide only the log output window, keep the hover icon
 */
+ (void)hideLogWindow;
```

For the convenience of output, a three macro definition is encapsulated, corresponding to the different types of printLog.

```
HDNormalLog(log)

HDWarnLog(log)

HDErrorLog(log)
```

### 2.1, use example

The following two ways of using the output log are equivalent.

```
HDWarnLog(@"click button");
[HDWindowLogger printLog:@"Click the button "withLogType:kHDLogTypeWarn];
```

## III. Other instructions

1. For the convenience of viewing, it is divided into three types: normal, warning and error. It corresponds to three different colors for easy viewing.
2. Click the corresponding cell to copy the output log directly to the system clipboard.
3. Share the system share you are calling. Which software you can share depends on which files are installed on your phone.

<span id = "chinese"></span>

## 简体中文介绍

项目地址:[https://github.com/DamonHu/HDWindowLogger](https://github.com/DamonHu/HDWindowLogger)

开发微信小程序过程中，小程序的悬浮调试工具用起来调试特别舒服，想找一个iOS上的，找到了一个类似的[HAMLogOutputWindow](https://github.com/DaiYue/HAMLogOutputWindow)，看了下源码，是用的`textview`写的，但是并不能滚动查询和操作。同时考虑到打印网络请求输出量还是很大的，为了性能和后续拓展，所以用`Tableview`重写了一个。

展示效果gif图:

![](./ReadmeImage/demo.gif)

除了在屏幕上显示，可以设置是否自动滚动日志便于调试，也可以将输出的日志分享到微信、twitter等程序，以便离线查看。同时可以搜索输出内容，自己处理等

![](./ReadmeImage/2.png)

## 一、安装

你可以选择使用cocoaPod安装，也可以直接下载源文件拖入项目中

### 1.1、cocoaPod安装

```
pod 'HDWindowLogger'
```

### 1.2、文件安装

可以将工程底下，`HDWindowLogger`文件夹内的文件拖入项目即可

## 二、使用

导入头文件

```
#import "HDWindowLogger.h"
```

然后可以随意使用以下功能

```
@property (strong, nonatomic, readonly) NSMutableArray *mLogDataArray;  //log信息内容

/**
 根据日志的输出类型去输出相应的日志，不同日志类型颜色不一样

 @param log 日志内容
 @param logType 日志类型
 */
+ (void)printLog:(id)log withLogType:(HDLogType)logType;

/**
 删除log日志
 */
+ (void)cleanLog;

/**
 显示log窗口
 */
+ (void)show;


/**
 隐藏整个log窗口
 */
+ (void)hide;


/**
 只隐藏log的输出窗口，保留悬浮图标
 */
+ (void)hideLogWindow;
```

为了输出方便，封装了一个三个宏定义，对应的printLog不同的类型

```
HDNormalLog(log)

HDWarnLog(log)

HDErrorLog(log)
```

### 2.1、使用示例

输出日志下面两种使用方式是等效的

```
HDWarnLog(@"点击按钮");
[HDWindowLogger printLog:@"点击按钮" withLogType:kHDLogTypeWarn];
```

## 三、其他说明

1. 为了查看方便，分为普通、警告、错误三种类型，对应了三种不同的颜色，方便查看
2. 点击对应的cell可以直接将输出log复制到系统剪贴板
3. 分享调用的系统分享，可以分享到哪个软件取决于你手机上安装的有哪些软件。