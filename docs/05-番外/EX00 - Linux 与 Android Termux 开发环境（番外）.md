# EX00：Linux / Android Termux 开发环境（番外）

> [[课程总览|返回课程总览]] · [[00-序章/第 01 集 - Windows 开发环境搭建（VSCode）|上一集]] · [[00-序章/第 02 集 - 如何使用 Kristal Wiki、API Reference 与示例项目|下一集]]

## 开场

说明本集面向使用 Linux 或 Android Termux 的观众，展示完成后的基本开发流程。

## 适合的使用场景

介绍 Linux 和 Termux 在 Kristal 开发中的适用场景，以及它们和 Windows 工作流的主要区别。

## 安装love

debian系，红帽系，arch系的安装方式。以及展示这比win简洁的多（直接配置好了环境变量）

## 配置 Kristal 项目

完成项目文件和运行环境的连接，建立可以从终端启动和测试的工作区。

## 使用编辑器开发

展示在 Linux 或 Termux 环境中浏览、修改和管理 Lua 项目的基本方式。

推荐编辑器是helix和emacs，并展示修改他们配置文件带来的快捷键便利。同时说明vscode仍然可用，并可以改到这样的配置。

## 安卓：我知道你们需要，但这真的是困难模式

考虑到社区大众很多都是安卓用户的事实，阐述如何实现这条工作流：

1. 用 acode 写代码，用 love for android 跑游戏。但这需要处理对data文件夹的访问权限问题。也许可以配合shizuku，当然root的设备直接搞就完事儿了。
2. proot。只做简单介绍和相关链接，说明性能可能不好
3. chroot，只做简单介绍和相关链接，说明其可能难配置且必须root。

## 与 Windows 工作流对照

总结不同平台在文件管理、命令行和编辑器使用上的差异，帮助观众选择适合自己的方式。

## 结尾

预告下一集：查阅 Kristal Wiki、API Reference 和示例项目。
