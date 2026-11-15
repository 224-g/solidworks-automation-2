// 模板_装配.cs —— 装配体构建模板（基于实测通过的 sw_build6.cs，0 过定义）
// 本模板演示「固定件 FixComponent + 运动链最小配合」的完整流程。
// 编译（与 SwAuto.cs 一起）：
//   & "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo ^
//     /r:SolidWorks.Interop.sldworks.dll /r:SolidWorks.Interop.swconst.dll ^
//     /out:build.exe SwAuto.cs 模板_装配.cs
// 运行：build.exe 必须与两个 Interop DLL 同目录。
//
// 自定义步骤（未来做新装配时照此改）：
//   1) 改 dir / save / files（零件路径与文件名）
//   2) 改 AddComp 的位姿（x,y,z,rot）
//   3) 改 face specs（局部包围盒，用 FindFace 匹配）
//   4) 改固定件清单 + 运动链配合
using System;
using System.IO;
using System.Threading;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class AsmBuild
{
    static void Main()
    {
        try
        {
            // ===== 1. 连接 + 打开零件 + 新建装配 =====
            SwAuto.Connect("C:\\Users\\zgzgd\\Documents\\DSH\\build.log");

            string dir = "C:\\Users\\zgzgd\\Documents\\DSH\\精英联赛_设计包\\装配体\\";
            string save = dir + "齿轮传动曲柄滑块机构.SLDASM";
            string[] files = { "plate", "bracket", "tower", "shaft1", "shaft2", "gear1", "gear2",
                               "crank", "pin", "rod", "slider", "rail", "motor", "anvil", "work", "bolt", "nut" };

            SwAuto.app.CloseAllDocuments(true);
            foreach (string f in files)
                if (!SwAuto.OpenPart(dir + f + ".SLDPRT")) return;

            SwAuto.NewAssembly("C:\\ProgramData\\SolidWorks\\SOLIDWORKS 2024\\templates\\gb_assembly.asmdot");
            SwAuto.L("newasm=ok");

            // ===== 2. 放置 24 个零件到设计位姿 =====
            SwAuto.AddComp("plate.SLDPRT", 0, 0, 0, "RX-90");
            SwAuto.AddComp("bracket.SLDPRT", 0.090, 0.012, 0, "");
            SwAuto.AddComp("bracket.SLDPRT", 0.1503, 0.012, 0, "");
            SwAuto.AddComp("tower.SLDPRT", 0.2703, 0.012, 0, "");
            SwAuto.AddComp("shaft1.SLDPRT", 0.090, 0.077, -0.020, "");
            SwAuto.AddComp("shaft2.SLDPRT", 0.1503, 0.077, 0, "");
            SwAuto.AddComp("gear1.SLDPRT", 0.090, 0.077, 0.012, "");
            SwAuto.AddComp("gear2.SLDPRT", 0.1503, 0.077, 0.012, "");
            SwAuto.AddComp("crank.SLDPRT", 0.1503, 0.077, 0.040, "");
            SwAuto.AddComp("pin.SLDPRT", 0.1853, 0.077, 0.044, "");
            SwAuto.AddComp("rod.SLDPRT", 0.1853, 0.077, 0.052, "");
            SwAuto.AddComp("slider.SLDPRT", 0.2703, 0.078, 0.060, "");
            SwAuto.AddComp("rail.SLDPRT", 0.2703, 0.077, 0.084, "RY180");
            SwAuto.AddComp("motor.SLDPRT", 0.090, 0.077, -0.014, "RY180");
            SwAuto.AddComp("anvil.SLDPRT", 0.3508, 0.012, 0.070, "RX-90");
            SwAuto.AddComp("work.SLDPRT", 0.3858, 0.030, 0.045, "RX-90");
            double[] bx = { 0.020, 0.412, 0.020, 0.412 };
            double[] bz = { -0.042, -0.042, 0.088, 0.088 };
            for (int i = 0; i < 4; i++)
            {
                SwAuto.AddComp("bolt.SLDPRT", bx[i], 0.012, bz[i], "RX90");
                SwAuto.AddComp("nut.SLDPRT", bx[i], 0, bz[i], "RX90");
            }
            SwAuto.doc.EditRebuild3();
            SwAuto.L("components placed");

            // ===== 3. 取组件句柄 =====
            object[] comps = (object[])SwAuto.assy.GetComponents(false);
            Component2 plate = null, bracketA = null, bracketB = null, tower = null,
                shaft1 = null, shaft2 = null, gear1 = null, gear2 = null, crank = null,
                pin = null, rod = null, slider = null, rail = null, motor = null, anvil = null, work = null;
            Component2[] bolts = new Component2[4], nuts = new Component2[4];
            foreach (object co in comps)
            {
                Component2 c = (Component2)co;
                string nm = c.Name2;
                if (nm.StartsWith("plate")) plate = c;
                else if (nm.StartsWith("bracket-1")) bracketA = c;
                else if (nm.StartsWith("bracket-2")) bracketB = c;
                else if (nm.StartsWith("tower")) tower = c;
                else if (nm.StartsWith("shaft1")) shaft1 = c;
                else if (nm.StartsWith("shaft2")) shaft2 = c;
                else if (nm.StartsWith("gear1")) gear1 = c;
                else if (nm.StartsWith("gear2")) gear2 = c;
                else if (nm.StartsWith("crank")) crank = c;
                else if (nm.StartsWith("pin")) pin = c;
                else if (nm.StartsWith("rod")) rod = c;
                else if (nm.StartsWith("slider")) slider = c;
                else if (nm.StartsWith("rail")) rail = c;
                else if (nm.StartsWith("motor")) motor = c;
                else if (nm.StartsWith("anvil")) anvil = c;
                else if (nm.StartsWith("work")) work = c;
                else if (nm.StartsWith("bolt")) for (int i = 0; i < 4; i++) if (nm.StartsWith("bolt-" + (i + 1))) bolts[i] = c;
                else if (nm.StartsWith("nut")) for (int i = 0; i < 4; i++) if (nm.StartsWith("nut-" + (i + 1))) nuts[i] = c;
            }

            // ===== 4. 面规格（局部包围盒，用 FindFace 匹配）=====
            double[] PLATE_TOP = SwAuto.B(0, -0.235, 0.012, 0.432, 0.095, 0.012);
            double[] BRK_BACK = SwAuto.B(-0.045, 0, 0, 0.045, 0.090, 0);
            double[] BRK_HOLE = SwAuto.B(-0.0051, 0.0599, 0, 0.0051, 0.0701, 0.012);
            double[] SH1_OD = SwAuto.B(-0.005, -0.005, 0, 0.005, 0.0024, 0.056);
            double[] SH1_BACK = SwAuto.B(-0.005, -0.005, 0, 0.005, 0.0024, 0);
            double[] SH2_OD = SwAuto.B(-0.005, -0.005, 0, 0.005, 0.0025, 0.048);
            double[] SH2_BACK = SwAuto.B(-0.005, -0.005, 0, 0.005, 0.0025, 0);
            double[] G1_HOLE = SwAuto.B(-0.0051, -0.0051, 0, 0.0051, 0.0024, 0.024);
            double[] G1_RINGBACK = SwAuto.B(-0.022, -0.022, 0, 0.022, 0.022, 0);
            double[] G2_HOLE = SwAuto.B(-0.0051, -0.0051, 0, 0.0051, 0.0025, 0.024);
            double[] G2_RINGBACK = SwAuto.B(-0.042, -0.042, 0, 0.042, 0.042, 0);
            double[] G1_HUBOD = SwAuto.B(-0.008, -0.008, 0.018, 0.008, 0.008, 0.024);
            double[] G2_HUBOD = SwAuto.B(-0.008, -0.008, 0.018, 0.008, 0.008, 0.024);
            double[] G2_HUBFRONT = SwAuto.B(-0.008, -0.008, 0.024, 0.008, 0.008, 0.024);
            double[] CRK_HOLE = SwAuto.B(-0.0051, -0.0051, 0, 0.0051, 0.0025, 0.008);
            double[] CRK_PINHOLE = SwAuto.B(0.0309, -0.0041, 0, 0.0391, 0.0041, 0.008);
            double[] CRK_FRONT = SwAuto.B(-0.050, -0.050, 0.008, 0.050, 0.050, 0.008);
            double[] PIN_OD = SwAuto.B(-0.004, -0.004, 0, 0.004, 0.004, 0.016);
            double[] PIN_FRONT = SwAuto.B(-0.004, -0.004, 0.016, 0.004, 0.004, 0.016);
            double[] ROD_E1HOLE = SwAuto.B(-0.0041, -0.0041, 0, 0, 0.0041, 0.008);
            double[] ROD_E2HOLE = SwAuto.B(0.085, -0.0041, 0, 0.0891, 0.0041, 0.008);
            double[] SL_HOLE = SwAuto.B(-0.0041, -0.0041, 0, 0.0041, 0.0041, 0.024);
            double[] SL_BACK = SwAuto.B(-0.033, -0.028, 0, 0.033, 0.028, 0);
            double[] SL_TOP = SwAuto.B(-0.033, 0.028, 0, 0.033, 0.028, 0.024);
            double[] RAIL_WALLFRONT = SwAuto.B(-0.045, -0.029, 0.024, 0.045, 0.029, 0.024);

            // ===== 5. 固定所有固定件（0 个配合）=====
            SwAuto.FixComp(plate);
            SwAuto.FixComp(bracketA);
            SwAuto.FixComp(bracketB);
            SwAuto.FixComp(tower);
            SwAuto.FixComp(rail);
            SwAuto.FixComp(motor);
            SwAuto.FixComp(anvil);
            SwAuto.FixComp(work);
            for (int i = 0; i < 4; i++) { SwAuto.FixComp(bolts[i]); SwAuto.FixComp(nuts[i]); }
            SwAuto.L("fixed parts");
            SwAuto.doc.EditRebuild3();
            Thread.Sleep(200);

            // ===== 6. 运动链最小配合（17 个）=====
            // 轴：同心(flip=true 修 Y 镜像) + 轴向 Z
            SwAuto.Mate(shaft1, true, SH1_OD, bracketA, true, BRK_HOLE, 1, 0, true, 0, 0, 0, false);
            SwAuto.Mate(bracketA, false, BRK_BACK, shaft1, false, SH1_BACK, 5, 0, false, 0.020, 0, 0, false);
            SwAuto.Mate(shaft2, true, SH2_OD, bracketB, true, BRK_HOLE, 1, 0, true, 0, 0, 0, false);
            SwAuto.Mate(shaft2, false, SH2_BACK, bracketB, false, BRK_BACK, 5, 0, false, 0, 0, 0, false);

            // 齿轮：同心+LockRotation + 轴向 + 齿轮配合(1:2)
            SwAuto.Mate(gear1, true, G1_HOLE, shaft1, true, SH1_OD, 1, 2, false, 0, 0, 0, true);
            SwAuto.Mate(gear1, false, G1_RINGBACK, bracketA, false, BRK_BACK, 5, 0, false, 0.012, 0, 0, false);
            SwAuto.Mate(gear2, true, G2_HOLE, shaft2, true, SH2_OD, 1, 2, false, 0, 0, 0, true);
            SwAuto.Mate(gear2, false, G2_RINGBACK, bracketB, false, BRK_BACK, 5, 0, false, 0.012, 0, 0, false);
            SwAuto.Mate(gear1, true, G1_HUBOD, gear2, true, G2_HUBOD, 10, 2, false, 0, 1, 2, false);

            // 曲柄：同心+LockRotation + 轴向；销：同心 + 轴向
            SwAuto.Mate(crank, true, CRK_HOLE, shaft2, true, SH2_OD, 1, 2, false, 0, 0, 0, true);
            SwAuto.Mate(gear2, false, G2_HUBFRONT, crank, false, CRK_FRONT, 5, 0, false, 0.012, 0, 0, false);
            SwAuto.Mate(pin, true, PIN_OD, crank, true, CRK_PINHOLE, 1, 2, false, 0, 0, 0, false);
            SwAuto.Mate(crank, false, CRK_FRONT, pin, false, PIN_FRONT, 5, 0, false, 0.012, 0, 0, false);

            // 连杆：2 个同心
            SwAuto.Mate(rod, true, ROD_E1HOLE, pin, true, PIN_OD, 1, 2, false, 0, 0, 0, false);
            SwAuto.Mate(rod, true, ROD_E2HOLE, slider, true, SL_HOLE, 1, 2, false, 0, 0, 0, false);

            // 滑块：TOP 到底板(距离) + BACK 到导轨壁(点-面 Z)
            SwAuto.Mate(plate, false, PLATE_TOP, slider, false, SL_TOP, 5, 0, false, 0.093, 0, 0, false);
            SwAuto.MateVertex(slider, SL_BACK, rail, RAIL_WALLFRONT, 0, 0);

            // ===== 7. 校验 + 保存 =====
            SwAuto.Walk();
            SwAuto.SaveAsm(save);
            SwAuto.L("done");
        }
        catch (Exception ex)
        {
            SwAuto.L("EX " + ex.Message);
            SwAuto.L(ex.StackTrace);
        }
        finally
        {
            SwAuto.Close();
        }
    }
}
