// 模板_零件.cs —— 零件建模模板（拉伸建模，避开切除 API）
// 关键约定：本机 SolidWorks 的切除(cut) API 失灵，所有零件一律用【拉伸(FeatureExtrusion)】建模。
//   - 外轮廓：草图 → 拉伸
//   - 孔：可以先画外轮廓拉伸成实体，再用【画"孔所在位置"的草图 → 拉伸切除】——若切除失灵，
//     则改成【分两段拉伸拼出带孔结构】或用旋转特征。本项目 17 个零件最终全部用纯拉伸+旋转完成。
//
// 编译（与 SwAuto.cs 一起）：
//   & "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo ^
//     /r:SolidWorks.Interop.sldworks.dll /r:SolidWorks.Interop.swconst.dll ^
//     /out:part.exe SwAuto.cs 模板_零件.cs
using System;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class PartBuild
{
    static void Main()
    {
        try
        {
            SwAuto.Connect("C:\\Users\\zgzgd\\Documents\\DSH\\part.log");
            string tpl = "C:\\ProgramData\\SolidWorks\\SOLIDWORKS 2024\\templates\\gb_part.prtdot";

            // ===== 示例：一根 Ø10×56 轴（主动轴）=====
            SwAuto.doc = (ModelDoc2)SwAuto.app.NewDocument(tpl, 0, 0, 0);
            BuildShaft(SwAuto.doc, SwAuto.mu, 0.005, 0.056);   // 半径 5mm，长 56mm
            SwAuto.doc.SaveAs3("C:\\Users\\zgzgd\\Documents\\DSH\\demo_shaft.SLDPRT", 0, 2);

            SwAuto.L("part done");
        }
        catch (Exception ex)
        {
            SwAuto.L("EX " + ex.Message);
            SwAuto.L(ex.StackTrace);
        }
        finally { SwAuto.Close(); }
    }

    /// 画草图圆 → 拉伸成圆柱（轴类零件）
    static void BuildShaft(ModelDoc2 doc, IMathUtility mu, double r, double len)
    {
        // 1. 选前视基准面，进入草图
        doc.Extension.SelectByID2("前视基准面", "PLANE", 0, 0, 0, false, 0, null, 0);
        doc.SketchManager.InsertSketch(true);

        // 2. 画圆心在原点、半径 r 的圆
        doc.SketchManager.CreateCircleByRadius(0, 0, 0, r);

        // 3. 退出草图
        doc.SketchManager.InsertSketch(true);

        // 4. 拉伸（盲孔/盲拉伸，深度 len）
        //    FeatureExtrusion2 关键参数：单方向、不翻转、盲拉(len)、合并
        doc.FeatureManager.FeatureExtrusion2(
            true,   // Sd 单方向
            false,  // Flip
            false,  // Dir
            0, 0,   // 末端条件：swEndCondBlind
            len, 0, // D1=深度, D2
            false, false, false, false,  // 拔模
            0, 0, false, false, false, false,
            true,   // Merge 合并
            false,  // UseFeatScope
            false,  // UseAutoSelect
            0, 0,   // 起始条件
            0, 0);
    }

    /// 画矩形草图 → 拉伸成板（板类零件）
    static void BuildPlate(ModelDoc2 doc, IMathUtility mu, double w, double h, double t)
    {
        doc.Extension.SelectByID2("前视基准面", "PLANE", 0, 0, 0, false, 0, null, 0);
        doc.SketchManager.InsertSketch(true);
        // 中心矩形（左下 -w/2,-h/2 到右上 w/2,h/2）
        doc.SketchManager.CreateLine(-w / 2, -h / 2, 0, w / 2, -h / 2, 0);
        doc.SketchManager.CreateLine(w / 2, -h / 2, 0, w / 2, h / 2, 0);
        doc.SketchManager.CreateLine(w / 2, h / 2, 0, -w / 2, h / 2, 0);
        doc.SketchManager.CreateLine(-w / 2, h / 2, 0, -w / 2, -h / 2, 0);
        doc.SketchManager.InsertSketch(true);
        doc.FeatureManager.FeatureExtrusion2(
            true, false, false, 0, 0, t, 0,
            false, false, false, false, 0, 0, false, false, false, false,
            true, false, false, 0, 0, 0, 0);
    }

    // ===== 渐开线齿轮建模要点（供参考，本项目主动/从动齿轮用此法）=====
    // 1. 渐开线齿廓点列：对每个齿，从基圆到齿顶圆按角度步进，生成左右两条渐开线点列：
    //      x = rb*(cosθ + θ·sinθ),  y = rb*(sinθ - θ·cosθ)   （θ 从 0 到 sqrt((ra/rb)^2-1)）
    //    左齿廓 = 右齿廓关于齿中心线镜像。
    // 2. 用 SketchManager.CreateSpline / 逐点 CreateLine 连成封闭单齿轮廓。
    // 3. 齿顶圆、齿根圆用 CreateArc 补齐，组成一个齿的封闭草图 → 拉伸成单齿。
    // 4. 圆周阵列 z 个齿：FeatureManager.FeatureCircularPattern4 或逐个旋转草图重画。
    //    齿轮参数：m=2, α=20°, z1=20/z2=40；分度圆 d=m·z，齿顶 da=m(z+2)，齿根 df=m(z-2.5)。
    //    中心孔：直接画在轮廓里一起拉伸（避免切除）。
}
