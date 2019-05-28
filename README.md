# HDWindowLogger

![](./cocoapodTool.png)

iOS端将输出日志log悬浮显示在屏幕上，便于在真机调试信息。

开发微信小程序过程中，小程序的悬浮调试工具用起来很爽啊，找到了一个类似的[HAMLogOutputWindow](https://github.com/DaiYue/HAMLogOutputWindow)，看了下源码，是用的`textview`写的，但是并不能滚动查询和操作。同时考虑到打印网络请求输出量还是很大的，所以用`Tableview`重写了一个。

展示效果gif图:

![](./demo.gif)

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
