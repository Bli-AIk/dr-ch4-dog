# 开发说明

## 初始化

使用递归方式克隆仓库并初始化所有子模块：

```sh
git clone --recurse-submodules https://github.com/Bli-AIk/dr-ch4-dog.git
cd dr-ch4-dog
git submodule update --init --recursive
```

本项目的 Mod 代码使用 Lua，并以 Kristal v0.10.0 为运行基线。请确保本机已安装 LÖVE 11.5、LuaJIT、`just`、`rsync`、`zip`、`unzip` 和 Python 3。

## 检查与运行

运行静态检查、调试工具检查和文档检查：

```sh
make test
```

设置 Kristal 根目录后，可以启动开发模式：

```sh
KRISTAL_ROOT=/path/to/Kristal just run
```

独立运行 Kristal 启动 smoke test：

```sh
KRISTAL=/path/to/Kristal make test-kristal
```

## 构建

构建独立发行包和 Mod ZIP：

```sh
just build
just build-mod
```

发行包会排除开发期工具、编辑器配置、测试和构建文件。提交前请确认构建产物中的 `mod.json`、子模块和语言库均完整。
