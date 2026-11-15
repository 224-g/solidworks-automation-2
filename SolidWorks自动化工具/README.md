# SolidWorks 自动化工具包

一套可复用的 SolidWorks 2024 C# API 自动化方案，把「齿轮传动曲柄滑块机构」项目踩过的所有坑、最终跑通的代码沉淀下来。**未来在任意对话里，只要提出零件/装配需求，即可照此完成建模 + 装配 + 配合。**

## 目录

| 文件 | 作用 |
|---|---|
| `经验手册.md` | **最重要**。全部问题 → 根因 → 方案，API 参考，方向约定，最终架构，设计参数 |
| `SwAuto.cs` | 可复用核心库（连接/找面/配合/点面配合/放件/固定/校验/保存，全套助手函数） |
| `模板_装配.cs` | 装配构建模板（固定件 FixComponent + 运动链最小配合，0 过定义） |
| `模板_零件.cs` | 零件建模模板（拉伸建模，避开失灵的切除 API + 渐开线齿轮要点） |

## 使用流程（未来做新设计时照此）

1. **提需求** → 明确零件清单、尺寸、装配关系、配合要求。
2. **零件建模**：改 `模板_零件.cs`，用 `SwAuto` 的草图 + 拉伸助手，逐个生成 `.SLDPRT`。**一律拉伸，不用切除**。
3. **装配**：改 `模板_装配.cs`：
   - 填零件路径、放置位姿（`AddComp`）；
   - 填面规格（局部包围盒，供 `FindFace` 匹配）；
   - **固定件用 `FixComp()`**，运动链只加最小配合。
4. **编译运行**（见下），读日志查 `err`：`err==5` 即过定义，按手册排查。
5. **校验**：日志末尾 `TOTAL mates=N overdefined=0` 且 `WALK` 位姿符合设计 = 成功。

## 编译 / 运行命令（模板）

```powershell
# 装配
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo `
  /r:SolidWorks.Interop.sldworks.dll /r:SolidWorks.Interop.swconst.dll `
  /out:build.exe SwAuto.cs 模板_装配.cs

# 零件
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo `
  /r:SolidWorks.Interop.sldworks.dll /r:SolidWorks.Interop.swconst.dll `
  /out:part.exe SwAuto.cs 模板_零件.cs
```

**运行前提**：`SolidWorks.Interop.sldworks.dll` + `SolidWorks.Interop.swconst.dll` 必须与 exe 同目录；SolidWorks 需在本机运行（或由脚本自动启动）。

## 五个必记的硬结论

1. **固定件用 `FixComponent()`，绝不用 3 平面配合定位** —— 这是消除过定义的唯一可靠办法。
2. **同心配合 轴↔孔 用 `align=0 + flip=true`** —— 否则零件会 180° 翻转（镜像到错误一侧）。
3. **重跑脚本要「全新装配重建」**，`DeleteMateGroup` 不可靠会累积配合。
4. **点-面配合（`MateVertex`）用于"只约束一个平动方向"**，避免平面距离配合的旋转冗余。
5. **`err==5` = 过定义，`err==1` = 成功**；每次配合后检查 `err` 自检。

## 关键路径

- Interop DLL：`C:\Users\zgzgd\Documents\DSH\_sw_working\01_interop_dll\`
- 实测通过装配脚本：`C:\Users\zgzgd\Documents\DSH\_sw_working\04_assembly_builders\sw_build6.cs`
- 零件+装配体交付：`C:\Users\zgzgd\Documents\DSH\精英联赛_设计包\装配体\`
- 面规格全集：`C:\Users\zgzgd\Documents\DSH\_sw_working\04_assembly_builders\sw_asm_build3.cs`

详细问题与解决方案见 `经验手册.md`。
