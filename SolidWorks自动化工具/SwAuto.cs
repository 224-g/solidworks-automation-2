// SwAuto.cs —— SolidWorks 2024 C# 自动化核心库（可复用）
// 用法：与模板文件一起编译（本文件不含 Main）：
//   & "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo ^
//     /r:SolidWorks.Interop.sldworks.dll /r:SolidWorks.Interop.swconst.dll ^
//     /out:run.exe SwAuto.cs 模板_装配.cs
// 运行 exe 前，两个 Interop DLL 必须与 exe 同目录。
//
// 已实测验证的约定（详见同目录 经验手册.md）：
//   - AddMate5 15 参数签名（见 Mate/MateVertex）
//   - err==5 = 过定义(OverDefinedAssembly)，err==1 = 成功(NoError)
//   - 同心配合 轴↔孔 用 align=0 + flip=true（否则 Y 镜像）
//   - 固定件用 FixComponent()，绝不靠 3 平面配合定位
//   - Vertex.GetPoint() 返回 double[]，不是 MathPoint
//   - Edge 用 GetStartVertex()/GetEndVertex()（无 GetTwoVertices）
//   - Vertex 无 Select，须 SelectByID2 + 世界坐标
//   - ModelDoc2.Save() 返回 void；SaveAs3(name, 0, 2) 是 3 参数
using System;
using System.IO;
using System.Threading;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

public static class SwAuto
{
    public static ISldWorks app;
    public static ModelDoc2 doc;
    public static AssemblyDoc assy;
    public static IMathUtility mu;
    public static StreamWriter log;
    public static int mcount = 0;   // 配合计数
    public static int overdef = 0;  // 过定义计数
    public static double TOL = 0.0008;

    public static void L(string s)
    {
        if (log != null) { log.WriteLine(s); log.Flush(); }
    }

    /// 连接（或启动）SolidWorks，打开日志
    public static void Connect(string logPath)
    {
        app = (ISldWorks)Activator.CreateInstance(Type.GetTypeFromProgID("SldWorks.Application"));
        mu = (IMathUtility)app.GetMathUtility();
        log = new StreamWriter(logPath, false);
    }

    /// 包围盒 [x1,y1,z1, x2,y2,z2]
    public static double[] B(double x1, double y1, double z1, double x2, double y2, double z2)
    {
        return new double[] { x1, y1, z1, x2, y2, z2 };
    }

    public static bool Near(double a, double b) { return Math.Abs(a - b) <= TOL; }

    /// 打开零件（文档类型 1 = 零件）
    public static bool OpenPart(string path)
    {
        int e = 0, w = 0;
        ModelDoc2 d = (ModelDoc2)app.OpenDoc6(path, 1, (int)swOpenDocOptions_e.swOpenDocOptions_Silent, "", ref e, ref w);
        if (d == null) { L("OPEN FAIL " + path); return false; }
        return true;
    }

    /// 新建装配
    public static void NewAssembly(string templatePath)
    {
        doc = (ModelDoc2)app.NewDocument(templatePath, 0, 0, 0);
        assy = (AssemblyDoc)doc;
    }

    /// 关闭所有文档（释放文件锁）
    public static void CloseAll()
    {
        if (app != null) app.CloseAllDocuments(false);
    }

    /// 按包围盒找面（cyl=true 找圆柱面，false 找平面）
    public static Face2 FindFace(Component2 c, bool cyl, double[] b)
    {
        try
        {
            Body2 body = (Body2)c.GetBody();
            object[] faces = (object[])body.GetFaces();
            foreach (object fo in faces)
            {
                Face2 f = (Face2)fo;
                Surface s = (Surface)f.GetSurface();
                bool isCyl = s.IsCylinder();
                bool isPln = s.IsPlane();
                if ((cyl && !isCyl) || (!cyl && !isPln)) continue;
                double[] bx = (double[])f.GetBox();
                if (bx == null) continue;
                if (Near(bx[0], b[0]) && Near(bx[1], b[1]) && Near(bx[2], b[2]) &&
                    Near(bx[3], b[3]) && Near(bx[4], b[4]) && Near(bx[5], b[5]))
                    return f;
            }
        }
        catch { }
        return null;
    }

    /// 添加配合（AddMate5 包装，自动记录 err + 过定义计数）
    /// type: 0=重合 1=同心 5=距离 10=齿轮 16=锁定
    /// align: 0=对齐 1=反对齐 2=最近
    /// 轴↔孔同心请传 align=0, flip=true（修 Y 镜像）
    public static bool Mate(Component2 c1, bool cyl1, double[] b1, Component2 c2, bool cyl2, double[] b2,
        int type, int align, bool flip, double d, double rn, double rd, bool lockRot)
    {
        Face2 f1 = FindFace(c1, cyl1, b1);
        Face2 f2 = FindFace(c2, cyl2, b2);
        if (f1 == null || f2 == null) { L("  FACE-NOT-FOUND " + c1.Name2 + " / " + c2.Name2); return false; }
        bool s1 = ((Entity)f1).Select4(false, null);
        bool s2 = ((Entity)f2).Select4(true, null);
        if (!s1 || !s2) { L("  SELECT-FAIL " + c1.Name2 + " / " + c2.Name2); doc.ClearSelection2(true); return false; }
        int err = 0;
        Feature ft = (Feature)assy.AddMate5(type, align, flip, d, 0, 0, rn, rd, 0, 0, 0, false, lockRot, 0, out err);
        doc.ClearSelection2(true);
        mcount++;
        if (err == 5) overdef++;
        L("  mate" + mcount + " " + c1.Name2 + "<->" + c2.Name2 + " t=" + type + " a=" + align +
          " flip=" + flip + " d=" + d + " -> " + (ft == null ? "NULL" : "OK") + " err=" + err);
        doc.EditRebuild3();
        return ft != null;
    }

    /// 点-面配合（顶点 ↔ 平面，只约束一个平动方向，避免平面距离配合的旋转冗余）
    public static bool MateVertex(Component2 c, double[] faceBox, Component2 c2, double[] face2Box, int align, double d)
    {
        Face2 f1 = FindFace(c, false, faceBox);
        Face2 f2 = FindFace(c2, false, face2Box);
        if (f1 == null || f2 == null) { L("  VFACE-NOT-FOUND " + c.Name2 + " / " + c2.Name2); return false; }
        object[] edges = (object[])f1.GetEdges();
        Edge e = (Edge)edges[0];
        Vertex v = (Vertex)e.GetStartVertex();
        double[] lp = (double[])v.GetPoint();          // 局部坐标 double[]
        MathPoint p = (MathPoint)mu.CreatePoint(lp);
        MathPoint wp = (MathPoint)p.MultiplyTransform(c.Transform2);  // 转世界坐标
        double[] wd = (double[])wp.ArrayData;
        bool s1 = doc.Extension.SelectByID2("", "VERTEX", wd[0], wd[1], wd[2], false, 0, null, 0);
        bool s2 = ((Entity)f2).Select4(true, null);
        if (!s1 || !s2) { L("  VSELECT-FAIL " + c.Name2); doc.ClearSelection2(true); return false; }
        int err = 0;
        Feature ft = (Feature)assy.AddMate5(5, align, false, d, 0, 0, 0, 0, 0, 0, 0, false, false, 0, out err);
        doc.ClearSelection2(true);
        mcount++;
        if (err == 5) overdef++;
        L("  mate" + mcount + " VERTEX " + c.Name2 + "<->" + c2.Name2 + " d=" + d + " a=" + align +
          " -> " + (ft == null ? "NULL" : "OK") + " err=" + err);
        doc.EditRebuild3();
        return ft != null;
    }

    /// 添加零件到装配，并置于设计位姿
    /// rot: "" | "RX-90" | "RX90" | "RY180"
    public static Component2 AddComp(string name, double x, double y, double z, string rot)
    {
        Component2 c = (Component2)assy.AddComponent5(name, 0, "", false, "", 0, 0, 0);
        if (c == null) { L("COMP FAIL " + name); return null; }
        // CreateTransform 约定：[0-8]=3x3旋转, [9-11]=平移, [12]=缩放
        double[] t = { 1, 0, 0, 0, 1, 0, 0, 0, 1, x, y, z, 1, 0, 0, 0 };
        MathTransform cT = (MathTransform)mu.CreateTransform(t);
        if (rot != "")
        {
            double[] ax = { 1, 0, 0 };
            double ang = -Math.PI / 2;          // "RX-90" 默认
            if (rot == "RX90") ang = Math.PI / 2;
            if (rot == "RY180") { ax = new double[] { 0, 1, 0 }; ang = Math.PI; }
            MathPoint o = (MathPoint)mu.CreatePoint(new double[] { 0, 0, 0 });
            MathVector av = (MathVector)mu.CreateVector(ax);
            MathTransform rT = (MathTransform)mu.CreateTransformRotateAxis(o, av, ang);
            cT = (MathTransform)rT.Multiply(cT);
        }
        c.Transform2 = cT;
        return c;
    }

    /// 固定零件（固定件定位的唯一可靠方式，替代 3 平面配合）
    public static void FixComp(Component2 c)
    {
        if (c == null) { L("FIX-NULL"); return; }
        c.Select(false);
        assy.FixComponent();
    }

    /// 遍历打印所有零件的世界坐标（验证位姿）
    public static void Walk()
    {
        L("--- WALK ---");
        object[] comps = (object[])assy.GetComponents(false);
        foreach (object co in comps)
        {
            Component2 c = (Component2)co;
            MathPoint wp = (MathPoint)((MathPoint)mu.CreatePoint(new double[] { 0, 0, 0 })).MultiplyTransform(c.Transform2);
            double[] p = (double[])wp.ArrayData;
            L("WALK " + c.Name2 + " " + p[0].ToString("F4") + "," + p[1].ToString("F4") + "," + p[2].ToString("F4"));
        }
    }

    /// 保存装配
    public static void SaveAsm(string path)
    {
        doc.EditRebuild3();
        assy.SaveAs3(path, 0, 2);   // SaveAs3 是 3 参数
        L("saved: " + path);
        L("TOTAL mates=" + mcount + " overdefined=" + overdef);
    }

    public static void Close()
    {
        if (log != null) log.Close();
    }
}
