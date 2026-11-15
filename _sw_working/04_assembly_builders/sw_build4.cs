// sw_build4.cs - FRESH rebuild with minimal mate set + direction fixes.
// Fixes vs original: (1) FixComponent plate (no 3 plane mates); (2) LockRotation on gear/crank concentric;
// (3) rod 3rd mate removed; (4) 6 direction fixes (swapped face order where convention gave wrong side).
using System;
using System.IO;
using System.Threading;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class AB4
{
    static StreamWriter log = new StreamWriter("C:\\Users\\zgzgd\\Documents\\DSH\\sw_build4.log", false);
    static void L(string s) { log.WriteLine(s); log.Flush(); }
    static ISldWorks app;
    static ModelDoc2 ad;
    static AssemblyDoc assy;
    static IMathUtility mu;
    static int mcount = 0;
    static int overdef = 0;
    static double TOL = 0.0008;

    static double[] B(double x1, double y1, double z1, double x2, double y2, double z2)
    { return new double[] { x1, y1, z1, x2, y2, z2 }; }

    static bool Near(double a, double b) { return Math.Abs(a - b) <= TOL; }

    static Face2 FindFace(Component2 c, bool cyl, double[] b)
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

    static bool Mate(Component2 c1, bool cyl1, double[] b1, Component2 c2, bool cyl2, double[] b2,
        int type, int align, double d, double rn, double rd, bool lockRot)
    {
        Face2 f1 = FindFace(c1, cyl1, b1);
        Face2 f2 = FindFace(c2, cyl2, b2);
        if (f1 == null || f2 == null) { L("  FACE-NOT-FOUND " + c1.Name2 + " / " + c2.Name2); return false; }
        bool s1 = ((Entity)f1).Select4(false, null);
        bool s2 = ((Entity)f2).Select4(true, null);
        if (!s1 || !s2) { L("  SELECT-FAIL " + c1.Name2 + " / " + c2.Name2); ad.ClearSelection2(true); return false; }
        int err = 0;
        Feature ft = (Feature)assy.AddMate5(type, align, false, d, 0, 0, rn, rd, 0, 0, 0, false, lockRot, 0, out err);
        ad.ClearSelection2(true);
        mcount++;
        if (err == 5) overdef++;
        L("  mate" + mcount + " " + c1.Name2 + "<->" + c2.Name2 + " t=" + type + " d=" + d + " lock=" + lockRot + " -> " + (ft == null ? "NULL" : "OK") + " err=" + err);
        ad.EditRebuild3();
        return ft != null;
    }

    static void AddComp(string name, double x, double y, double z, string rot)
    {
        Component2 c = (Component2)assy.AddComponent5(name, 0, "", false, "", 0, 0, 0);
        if (c == null) { L("COMP FAIL " + name); return; }
        double[] t = { 1, 0, 0, 0, 1, 0, 0, 0, 1, x, y, z, 1, 0, 0, 0 };
        MathTransform cT = (MathTransform)mu.CreateTransform(t);
        if (rot != "")
        {
            double[] ax = { 1, 0, 0 };
            double ang = -Math.PI / 2;
            if (rot == "RX90") ang = Math.PI / 2;
            if (rot == "RY180") { ax = new double[] { 0, 1, 0 }; ang = Math.PI; }
            MathPoint o = (MathPoint)mu.CreatePoint(new double[] { 0, 0, 0 });
            MathVector av = (MathVector)mu.CreateVector(ax);
            MathTransform rT = (MathTransform)mu.CreateTransformRotateAxis(o, av, ang);
            cT = (MathTransform)rT.Multiply(cT);
        }
        c.Transform2 = cT;
    }

    static void Main()
    {
        try
        {
            app = (ISldWorks)Activator.CreateInstance(Type.GetTypeFromProgID("SldWorks.Application"));
            mu = (IMathUtility)app.GetMathUtility();
            string dir = "C:\\Users\\zgzgd\\Documents\\DSH\\精英联赛_设计包\\装配体\\";
            string save = dir + "齿轮传动曲柄滑块机构.SLDASM";
            string[] files = { "plate", "bracket", "tower", "shaft1", "shaft2", "gear1", "gear2", "crank", "pin", "rod", "slider", "rail", "motor", "anvil", "work", "bolt", "nut" };
            app.CloseAllDocuments(true);
            foreach (string f in files)
            {
                int e = 0, w = 0;
                ModelDoc2 d = (ModelDoc2)app.OpenDoc6(dir + f + ".SLDPRT", 1, (int)swOpenDocOptions_e.swOpenDocOptions_Silent, "", ref e, ref w);
                if (d == null) { L("OPEN FAIL " + f); return; }
            }
            ad = (ModelDoc2)app.NewDocument("C:\\ProgramData\\SolidWorks\\SOLIDWORKS 2024\\templates\\gb_assembly.asmdot", 0, 0, 0);
            assy = (AssemblyDoc)ad;
            L("newasm=ok");

            // === 24 components at design poses ===
            AddComp("plate.SLDPRT", 0, 0, 0, "RX-90");
            AddComp("bracket.SLDPRT", 0.090, 0.012, 0, "");
            AddComp("bracket.SLDPRT", 0.1503, 0.012, 0, "");
            AddComp("tower.SLDPRT", 0.2703, 0.012, 0, "");
            AddComp("shaft1.SLDPRT", 0.090, 0.077, -0.020, "");
            AddComp("shaft2.SLDPRT", 0.1503, 0.077, 0, "");
            AddComp("gear1.SLDPRT", 0.090, 0.077, 0.012, "");
            AddComp("gear2.SLDPRT", 0.1503, 0.077, 0.012, "");
            AddComp("crank.SLDPRT", 0.1503, 0.077, 0.040, "");
            AddComp("pin.SLDPRT", 0.1853, 0.077, 0.044, "");
            AddComp("rod.SLDPRT", 0.1853, 0.077, 0.052, "");
            AddComp("slider.SLDPRT", 0.2703, 0.078, 0.060, "");
            AddComp("rail.SLDPRT", 0.2703, 0.077, 0.084, "RY180");
            AddComp("motor.SLDPRT", 0.090, 0.077, -0.014, "RY180");
            AddComp("anvil.SLDPRT", 0.3508, 0.012, 0.070, "RX-90");
            AddComp("work.SLDPRT", 0.3858, 0.030, 0.045, "RX-90");
            double[] bx = { 0.020, 0.412, 0.020, 0.412 };
            double[] bz = { -0.042, -0.042, 0.088, 0.088 };
            for (int i = 0; i < 4; i++)
            {
                AddComp("bolt.SLDPRT", bx[i], 0.012, bz[i], "RX90");
                AddComp("nut.SLDPRT", bx[i], 0, bz[i], "RX90");
            }
            ad.EditRebuild3();
            L("components placed");

            // === component handles ===
            object[] comps = (object[])assy.GetComponents(false);
            Component2 plate = null, bracketA = null, bracketB = null, tower = null, shaft1 = null, shaft2 = null,
                gear1 = null, gear2 = null, crank = null, pin = null, rod = null, slider = null, rail = null,
                motor = null, anvil = null, work = null;
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
                else if (nm.StartsWith("bolt"))
                {
                    for (int i = 0; i < 4; i++) if (nm.StartsWith("bolt-" + (i + 1))) bolts[i] = c;
                }
                else if (nm.StartsWith("nut"))
                {
                    for (int i = 0; i < 4; i++) if (nm.StartsWith("nut-" + (i + 1))) nuts[i] = c;
                }
            }
            L("resolved: plate=" + (plate != null) + " bA=" + (bracketA != null) + " bB=" + (bracketB != null) +
              " twr=" + (tower != null) + " s1=" + (shaft1 != null) + " s2=" + (shaft2 != null) +
              " g1=" + (gear1 != null) + " g2=" + (gear2 != null) + " crk=" + (crank != null) +
              " pin=" + (pin != null) + " rod=" + (rod != null) + " sl=" + (slider != null) +
              " rail=" + (rail != null) + " mot=" + (motor != null) + " anv=" + (anvil != null) +
              " work=" + (work != null) + " bolts=" + (bolts[0] != null && bolts[3] != null) +
              " nuts=" + (nuts[0] != null && nuts[3] != null));

            // === face specs ===
            double[] PLATE_TOP = B(0, -0.235, 0.012, 0.432, 0.095, 0.012);
            double[] PLATE_BOT = B(0, -0.235, 0, 0.432, 0.095, 0);
            double[] PLATE_BACK = B(0, 0.095, 0, 0.432, 0.095, 0.012);
            double[] PLATE_LEFT = B(0, -0.235, 0, 0, 0.095, 0.012);
            double[] PLATE_H1 = B(0.0168, 0.0388, 0, 0.0232, 0.0452, 0.012);
            double[] PLATE_H2 = B(0.4088, 0.0388, 0, 0.4152, 0.0452, 0.012);
            double[] PLATE_H3 = B(0.0168, -0.0912, 0, 0.0232, -0.0848, 0.012);
            double[] PLATE_H4 = B(0.4088, -0.0912, 0, 0.4152, -0.0848, 0.012);

            double[] BRK_BOT = B(-0.045, 0, 0, 0.045, 0, 0.012);
            double[] BRK_BACK = B(-0.045, 0, 0, 0.045, 0.090, 0);
            double[] BRK_LEFT = B(-0.045, 0, 0, -0.045, 0.015, 0.012);
            double[] BRK_HOLE = B(-0.0051, 0.0599, 0, 0.0051, 0.0701, 0.012);

            double[] TWR_BOT = B(-0.040, 0, 0, 0.040, 0, 0.012);
            double[] TWR_BACK = B(-0.040, 0, 0, 0.040, 0.032, 0);
            double[] TWR_LEFT = B(-0.040, 0, 0, -0.040, 0.032, 0.012);

            double[] SH1_OD = B(-0.005, -0.005, 0, 0.005, 0.0024, 0.056);
            double[] SH1_BACK = B(-0.005, -0.005, 0, 0.005, 0.0024, 0);
            double[] SH2_OD = B(-0.005, -0.005, 0, 0.005, 0.0025, 0.048);
            double[] SH2_BACK = B(-0.005, -0.005, 0, 0.005, 0.0025, 0);

            double[] G1_HOLE = B(-0.0051, -0.0051, 0, 0.0051, 0.0024, 0.024);
            double[] G1_RINGBACK = B(-0.022, -0.022, 0, 0.022, 0.022, 0);
            double[] G2_HOLE = B(-0.0051, -0.0051, 0, 0.0051, 0.0025, 0.024);
            double[] G2_RINGBACK = B(-0.042, -0.042, 0, 0.042, 0.042, 0);
            double[] G1_HUBOD = B(-0.008, -0.008, 0.018, 0.008, 0.008, 0.024);
            double[] G2_HUBOD = B(-0.008, -0.008, 0.018, 0.008, 0.008, 0.024);
            double[] G2_HUBFRONT = B(-0.008, -0.008, 0.024, 0.008, 0.008, 0.024);

            double[] CRK_HOLE = B(-0.0051, -0.0051, 0, 0.0051, 0.0025, 0.008);
            double[] CRK_PINHOLE = B(0.0309, -0.0041, 0, 0.0391, 0.0041, 0.008);
            double[] CRK_FRONT = B(-0.050, -0.050, 0.008, 0.050, 0.050, 0.008);

            double[] PIN_OD = B(-0.004, -0.004, 0, 0.004, 0.004, 0.016);
            double[] PIN_FRONT = B(-0.004, -0.004, 0.016, 0.004, 0.004, 0.016);

            double[] ROD_E1HOLE = B(-0.0041, -0.0041, 0, 0, 0.0041, 0.008);
            double[] ROD_E2HOLE = B(0.085, -0.0041, 0, 0.0891, 0.0041, 0.008);

            double[] SL_HOLE = B(-0.0041, -0.0041, 0, 0.0041, 0.0041, 0.024);
            double[] SL_BACK = B(-0.033, -0.028, 0, 0.033, 0.028, 0);
            double[] SL_TOP = B(-0.033, 0.028, 0, 0.033, 0.028, 0.024);

            double[] RAIL_LEFT = B(0.045, -0.033, 0, 0.045, 0.033, 0.048);
            double[] RAIL_WALLFRONT = B(-0.045, -0.029, 0.024, 0.045, 0.029, 0.024);
            double[] RAIL_BOT = B(-0.045, -0.033, 0, 0.045, -0.033, 0.048);

            double[] MOT_BODY = B(-0.028, -0.028, 0.006, 0.028, 0.028, 0.095);
            double[] MOT_FLGFRONT = B(-0.045, -0.027, 0.006, 0.045, 0.045, 0.006);
            double[] MOT_FOOTLEFT = B(0.045, -0.065, 0, 0.045, 0.045, 0.020);

            double[] ANV_TOP = B(0, 0, 0.018, 0.070, 0.050, 0.018);
            double[] ANV_BACK = B(0, 0.050, 0, 0.070, 0.050, 0.018);
            double[] ANV_LEFT = B(0, 0, 0, 0, 0.050, 0.018);
            double[] ANV_CBWALL = B(0.0195, 0.0095, 0.002, 0.0505, 0.0405, 0.018);

            double[] WORK_OD = B(-0.015, -0.015, 0, 0.015, 0.015, 0.050);
            double[] WORK_TOP = B(-0.015, -0.015, 0.050, 0.015, 0.015, 0.050);

            double[] BOLT_SHANK = B(-0.003, -0.003, 0.005, 0.003, 0.003, 0.021);
            double[] BOLT_HEADBOT = B(-0.0065, -0.0065, 0, 0.0065, 0.0065, 0);
            double[] NUT_HOLE = B(-0.0032, -0.0032, 0, 0.0032, 0.0032, 0.004);
            double[] NUT_TOP = B(-0.0065, -0.0065, 0.004, 0.0065, 0.0065, 0.004);

            // === fix plate ===
            plate.Select(false);
            assy.FixComponent();
            L("plate fixed via FixComponent");
            ad.EditRebuild3();
            Thread.Sleep(200);

            // === brackets A/B ===
            Mate(bracketA, false, BRK_BOT, plate, false, PLATE_TOP, 5, 0, 0, 0, 0, false);
            Mate(bracketA, false, BRK_BACK, plate, false, PLATE_BACK, 5, 0, 0.095, 0, 0, false);
            Mate(bracketA, false, BRK_LEFT, plate, false, PLATE_LEFT, 5, 0, 0.045, 0, 0, false);
            Mate(bracketB, false, BRK_BOT, plate, false, PLATE_TOP, 5, 0, 0, 0, 0, false);
            Mate(bracketB, false, BRK_BACK, plate, false, PLATE_BACK, 5, 0, 0.095, 0, 0, false);
            Mate(bracketB, false, BRK_LEFT, plate, false, PLATE_LEFT, 5, 0, 0.1053, 0, 0, false);

            // === tower ===
            Mate(tower, false, TWR_BOT, plate, false, PLATE_TOP, 5, 0, 0, 0, 0, false);
            Mate(tower, false, TWR_BACK, plate, false, PLATE_BACK, 5, 0, 0.095, 0, 0, false);
            Mate(tower, false, TWR_LEFT, plate, false, PLATE_LEFT, 5, 0, 0.2303, 0, 0, false);

            // === shafts (shaft1 axial DIRECTION FIX: swap) ===
            Mate(shaft1, true, SH1_OD, bracketA, true, BRK_HOLE, 1, 2, 0, 0, 0, false);
            Mate(bracketA, false, BRK_BACK, shaft1, false, SH1_BACK, 5, 0, 0.020, 0, 0, false);
            Mate(shaft2, true, SH2_OD, bracketB, true, BRK_HOLE, 1, 2, 0, 0, 0, false);
            Mate(shaft2, false, SH2_BACK, bracketB, false, BRK_BACK, 5, 0, 0, 0, 0, false);

            // === gears (LockRotation on concentric) ===
            Mate(gear1, true, G1_HOLE, shaft1, true, SH1_OD, 1, 2, 0, 0, 0, true);
            Mate(gear1, false, G1_RINGBACK, bracketA, false, BRK_BACK, 5, 0, 0.012, 0, 0, false);
            Mate(gear2, true, G2_HOLE, shaft2, true, SH2_OD, 1, 2, 0, 0, 0, true);
            Mate(gear2, false, G2_RINGBACK, bracketB, false, BRK_BACK, 5, 0, 0.012, 0, 0, false);
            Mate(gear1, true, G1_HUBOD, gear2, true, G2_HUBOD, 10, 2, 0, 1, 2, false);

            // === crank / pin (DIRECTION FIX: swap front mates) ===
            Mate(crank, true, CRK_HOLE, shaft2, true, SH2_OD, 1, 2, 0, 0, 0, true);
            Mate(gear2, false, G2_HUBFRONT, crank, false, CRK_FRONT, 5, 0, 0.012, 0, 0, false);
            Mate(pin, true, PIN_OD, crank, true, CRK_PINHOLE, 1, 2, 0, 0, 0, false);
            Mate(crank, false, CRK_FRONT, pin, false, PIN_FRONT, 5, 0, 0.012, 0, 0, false);

            // === rod (2 concentric only) ===
            Mate(rod, true, ROD_E1HOLE, pin, true, PIN_OD, 1, 2, 0, 0, 0, false);
            Mate(rod, true, ROD_E2HOLE, slider, true, SL_HOLE, 1, 2, 0, 0, 0, false);

            // === slider (DIRECTION FIX: swap top) ===
            Mate(plate, false, PLATE_TOP, slider, false, SL_TOP, 5, 0, 0.093, 0, 0, false);
            Mate(slider, false, SL_BACK, rail, false, RAIL_WALLFRONT, 5, 0, 0.024, 0, 0, false);

            // === rail ===
            Mate(rail, false, RAIL_BOT, plate, false, PLATE_BOT, 5, 0, 0.044, 0, 0, false);
            Mate(rail, false, RAIL_LEFT, plate, false, PLATE_LEFT, 5, 0, 0.2253, 0, 0, false);

            // === motor ===
            Mate(motor, true, MOT_BODY, shaft1, true, SH1_OD, 1, 2, 0, 0, 0, false);
            Mate(motor, false, MOT_FLGFRONT, shaft1, false, SH1_BACK, 5, 0, 0, 0, 0, false);
            Mate(motor, false, MOT_FOOTLEFT, plate, false, PLATE_LEFT, 5, 0, 0.045, 0, 0, false);

            // === anvil / work (DIRECTION FIX: swap top) ===
            Mate(plate, false, PLATE_TOP, anvil, false, ANV_TOP, 5, 0, 0.018, 0, 0, false);
            Mate(anvil, false, ANV_BACK, plate, false, PLATE_BACK, 5, 0, 0.115, 0, 0, false);
            Mate(anvil, false, ANV_LEFT, plate, false, PLATE_LEFT, 5, 0, 0.3508, 0, 0, false);
            Mate(work, true, WORK_OD, anvil, true, ANV_CBWALL, 1, 2, 0, 0, 0, false);
            Mate(anvil, false, ANV_TOP, work, false, WORK_TOP, 5, 0, 0.034, 0, 0, false);

            // === bolts / nuts ===
            double[][] PHS = { PLATE_H1, PLATE_H2, PLATE_H3, PLATE_H4 };
            for (int i = 0; i < 4; i++)
            {
                Mate(bolts[i], true, BOLT_SHANK, plate, true, PHS[i], 1, 2, 0, 0, 0, false);
                Mate(bolts[i], false, BOLT_HEADBOT, plate, false, PLATE_TOP, 5, 2, 0, 0, 0, false);
                Mate(nuts[i], true, NUT_HOLE, bolts[i], true, BOLT_SHANK, 1, 2, 0, 0, 0, false);
                Mate(nuts[i], false, NUT_TOP, plate, false, PLATE_BOT, 5, 2, 0, 0, 0, false);
            }

            // === walk ===
            L("--- WALK ---");
            object[] comps2 = (object[])assy.GetComponents(false);
            foreach (object co in comps2)
            {
                Component2 c = (Component2)co;
                MathPoint wp = (MathPoint)((MathPoint)mu.CreatePoint(new double[] { 0, 0, 0 })).MultiplyTransform(c.Transform2);
                double[] p = (double[])wp.ArrayData;
                L("WALK " + c.Name2 + " " + p[0].ToString("F4") + "," + p[1].ToString("F4") + "," + p[2].ToString("F4"));
            }

            ad.EditRebuild3();
            ad.SaveAs3(save, 0, 2);
            L("saved");
            L("TOTAL mates=" + mcount + " overdefined=" + overdef);
            L("done");
        }
        catch (Exception ex)
        {
            L("EX " + ex.Message);
            L(ex.StackTrace);
        }
        finally
        {
            log.Close();
        }
    }
}
