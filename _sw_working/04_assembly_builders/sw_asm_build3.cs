// sw_asm_build3.cs - final assembly builder with EXACT face specs from sw_face_dump.log
using System;
using System.IO;
using System.Threading;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class AB3
{
    static StreamWriter log = new StreamWriter("C:\\Users\\zgzgd\\Documents\\DSH\\sw_asm_build3.log", false);
    static void L(string s) { log.WriteLine(s); log.Flush(); }
    static ISldWorks app;
    static ModelDoc2 ad;
    static AssemblyDoc assy;
    static IMathUtility mu;
    static string[] pn = new string[3];
    static int mcount = 0;
    static double TOL = 0.0008;

    static double[] B(double x1, double y1, double z1, double x2, double y2, double z2)
    { return new double[] { x1, y1, z1, x2, y2, z2 }; }

    static bool Near(double a, double b) { return Math.Abs(a - b) <= TOL; }
    static bool In(double v, double a, double b) { return v >= a - TOL && v <= b + TOL; }

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
        int type, int align, double d, double rn, double rd)
    {
        Face2 f1 = FindFace(c1, cyl1, b1);
        Face2 f2 = FindFace(c2, cyl2, b2);
        if (f1 == null || f2 == null) { L("  FACE-NOT-FOUND " + c1.Name2 + " / " + c2.Name2); return false; }
        bool s1 = ((Entity)f1).Select4(false, null);
        bool s2 = ((Entity)f2).Select4(true, null);
        if (!s1 || !s2) { L("  SELECT-FAIL " + c1.Name2 + " / " + c2.Name2); ad.ClearSelection2(true); return false; }
        int err = 0;
        Feature ft = (Feature)assy.AddMate5(type, align, false, d, 0, 0, rn, rd, 0, 0, 0, false, false, 0, out err);
        ad.ClearSelection2(true);
        mcount++;
        L("  mate" + mcount + " " + c1.Name2 + "<->" + c2.Name2 + " t=" + type + " d=" + d + " -> " + (ft == null ? "NULL" : "OK") + " err=" + err);
        ad.EditRebuild3();
        return ft != null;
    }

    static bool PlaneMate(Component2 c, bool cyl, double[] b, int pidx, int align, double d)
    {
        Face2 f1 = FindFace(c, cyl, b);
        if (f1 == null) { L("  FACE-NOT-FOUND " + c.Name2 + " (plane)"); return false; }
        bool s1 = ((Entity)f1).Select4(false, null);
        bool s2 = ad.Extension.SelectByID2(pn[pidx], "PLANE", 0, 0, 0, true, 0, null, 0);
        if (!s1 || !s2) { L("  SELECT-FAIL plane"); ad.ClearSelection2(true); return false; }
        int err = 0;
        Feature ft = (Feature)assy.AddMate5(5, align, false, d, 0, 0, 0, 0, 0, 0, 0, false, false, 0, out err);
        ad.ClearSelection2(true);
        mcount++;
        L("  mate" + mcount + " " + c.Name2 + "<->" + pn[pidx] + " d=" + d + " -> " + (ft == null ? "NULL" : "OK") + " err=" + err);
        ad.EditRebuild3();
        return ft != null;
    }

    static void AddComp(string name, double x, double y, double z, string rot)
    {
        Component2 c = (Component2)assy.AddComponent5(name, 0, "", false, "", 0, 0, 0);
        if (c == null) { L("COMP FAIL " + name); return; }
        // translation matrix: identity rows 0-8 (1s at 0,4,8,12), translation at 9-11
        double[] t = { 1, 0, 0, 0, 1, 0, 0, 0, 1, x, y, z, 1, 0, 0, 0 };
        MathTransform cT = (MathTransform)mu.CreateTransform(t);
        if (rot == "")
        {
            c.Transform2 = cT;
        }
        else
        {
            double[] ax = { 1, 0, 0 };
            double ang = -Math.PI / 2;
            if (rot == "RX90") { ang = Math.PI / 2; }
            if (rot == "RY180") { ax = new double[] { 0, 1, 0 }; ang = Math.PI; }
            MathPoint o = (MathPoint)mu.CreatePoint(new double[] { 0, 0, 0 });
            MathVector av = (MathVector)mu.CreateVector(ax);
            MathTransform rT = (MathTransform)mu.CreateTransformRotateAxis(o, av, ang);
            c.Transform2 = (MathTransform)rT.Multiply(cT);
        }
    }

    static void Main()
    {
        try
        {
            app = (ISldWorks)Activator.CreateInstance(Type.GetTypeFromProgID("SldWorks.Application"));
            mu = (IMathUtility)app.GetMathUtility();
            string dir = "C:\\Users\\zgzgd\\Documents\\DSH\\sw_parts8\\";
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

            int n = 0;
            Feature pf = (Feature)ad.FirstFeature();
            while (pf != null && n < 3)
            {
                if (pf.GetTypeName2() == "RefPlane") { pn[n] = pf.Name; n++; }
                pf = (Feature)pf.GetNextFeature();
            }

            // === 24 components at final poses ===
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
            Thread.Sleep(500);

            // === face specs (from sw_face_dump.log, local boxes) ===
            double[] PLATE_TOP = B(0, -0.235, 0.012, 0.432, 0.095, 0.012);
            double[] PLATE_BOT = B(0, -0.235, 0, 0.432, 0.095, 0);
            double[] PLATE_BACK = B(0, 0.095, 0, 0.432, 0.095, 0.012);   // side face y=0.095 -> world z=-0.095
            double[] PLATE_FRONT = B(0, -0.235, 0, 0.432, -0.235, 0.012); // -> world z=+0.235
            double[] PLATE_LEFT = B(0, -0.235, 0, 0, 0.095, 0.012);
            double[] PLATE_H1 = B(0.0168, 0.0388, 0, 0.0232, 0.0452, 0.012);
            double[] PLATE_H2 = B(0.4088, 0.0388, 0, 0.4152, 0.0452, 0.012);
            double[] PLATE_H3 = B(0.0168, -0.0912, 0, 0.0232, -0.0848, 0.012);
            double[] PLATE_H4 = B(0.4088, -0.0912, 0, 0.4152, -0.0848, 0.012);

            double[] BRK_TOP = B(-0.010, 0.090, 0, 0.010, 0.090, 0.012);
            double[] BRK_BOT = B(-0.045, 0, 0, 0.045, 0, 0.012);        // y=0 face
            double[] BRK_BACK = B(-0.045, 0, 0, 0.045, 0.090, 0);       // z=0 face
            double[] BRK_LEFT = B(-0.045, 0, 0, -0.045, 0.015, 0.012);
            double[] BRK_RIGHT = B(0.045, 0, 0, 0.045, 0.015, 0.012);
            double[] BRK_HOLE = B(-0.0051, 0.0599, 0, 0.0051, 0.0701, 0.012);

            double[] TWR_BOT = B(-0.040, 0, 0, 0.040, 0, 0.012);      // y=0 face (the base)
            double[] TWR_BACK = B(-0.040, 0, 0, 0.040, 0.032, 0);     // z=0 face
            double[] TWR_LEFT = B(-0.040, 0, 0, -0.040, 0.032, 0.012);

            double[] SH1_OD = B(-0.005, -0.005, 0, 0.005, 0.0024, 0.056);
            double[] SH1_BACK = B(-0.005, -0.005, 0, 0.005, 0.0024, 0);
            double[] SH1_FRONT = B(-0.005, -0.005, 0.056, 0.005, 0.0024, 0.056);
            double[] SH2_OD = B(-0.005, -0.005, 0, 0.005, 0.0025, 0.048);
            double[] SH2_BACK = B(-0.005, -0.005, 0, 0.005, 0.0025, 0);
            double[] SH2_FRONT = B(-0.005, -0.005, 0.048, 0.005, 0.0025, 0.048);

            double[] G1_HOLE = B(-0.0051, -0.0051, 0, 0.0051, 0.0024, 0.024);
            double[] G1_RINGBACK = B(-0.022, -0.022, 0, 0.022, 0.022, 0);
            double[] G1_HUBFRONT = B(-0.008, -0.008, 0.024, 0.008, 0.008, 0.024);
            double[] G2_HOLE = B(-0.0051, -0.0051, 0, 0.0051, 0.0025, 0.024);
            double[] G2_RINGBACK = B(-0.042, -0.042, 0, 0.042, 0.042, 0);
            double[] G2_HUBFRONT = B(-0.008, -0.008, 0.024, 0.008, 0.008, 0.024);
            // gear-mate faces: the ring-front annulus (use the ring-front PLN spec) - the GEAR mate needs the tip faces but ring front works as a proxy

            double[] CRK_OD = B(-0.050, -0.050, 0, 0.050, 0.050, 0.008);
            double[] CRK_HOLE = B(-0.0051, -0.0051, 0, 0.0051, 0.0025, 0.008);
            double[] CRK_PINHOLE = B(0.0309, -0.0041, 0, 0.0391, 0.0041, 0.008);
            double[] CRK_FRONT = B(-0.050, -0.050, 0.008, 0.050, 0.050, 0.008);

            double[] PIN_OD = B(-0.004, -0.004, 0, 0.004, 0.004, 0.016);
            double[] PIN_FRONT = B(-0.004, -0.004, 0.016, 0.004, 0.004, 0.016);

            double[] ROD_E1HOLE = B(-0.0041, -0.0041, 0, 0, 0.0041, 0.008);
            double[] ROD_E2HOLE = B(0.085, -0.0041, 0, 0.0891, 0.0041, 0.008);
            double[] ROD_FRONT = B(-0.011, -0.011, 0.008, 0.096, 0.011, 0.008);
            double[] ROD_BACK = B(-0.011, -0.011, 0, 0.096, 0.011, 0);

            double[] SL_HOLE = B(-0.0041, -0.0041, 0, 0.0041, 0.0041, 0.024);
            double[] SL_BACK = B(-0.033, -0.028, 0, 0.033, 0.028, 0);
            double[] SL_TOP = B(-0.033, 0.028, 0, 0.033, 0.028, 0.024);
            double[] SL_FRONT = B(-0.033, -0.028, 0.024, 0.033, 0.028, 0.024);
            double[] SL_BOT = B(-0.033, -0.028, 0, 0.033, -0.028, 0.024);

            double[] RAIL_TOP = B(-0.045, 0.033, 0, 0.045, 0.033, 0.048);
            double[] RAIL_LEFT = B(0.045, -0.033, 0, 0.045, 0.033, 0.048);   // local x=+45 face = world LEFT under R_y(180)
            double[] RAIL_WALLFRONT = B(-0.045, -0.029, 0.024, 0.045, 0.029, 0.024);
            double[] RAIL_BOT = B(-0.045, -0.033, 0, 0.045, -0.033, 0.048);

            double[] MOT_BODY = B(-0.028, -0.028, 0.006, 0.028, 0.028, 0.095);
            double[] MOT_FLGFRONT = B(-0.045, -0.027, 0.006, 0.045, 0.045, 0.006);
            double[] MOT_FOOTBOT = B(-0.045, -0.065, 0, 0.045, -0.065, 0.020);
            double[] MOT_FOOTLEFT = B(0.045, -0.065, 0, 0.045, 0.045, 0.020);  // local x=+45 = world LEFT under R_y(180)

            double[] ANV_TOP = B(0, 0, 0.018, 0.070, 0.050, 0.018);
            double[] ANV_BACK = B(0, 0.050, 0, 0.070, 0.050, 0.018);
            double[] ANV_LEFT = B(0, 0, 0, 0, 0.050, 0.018);
            double[] ANV_CBWALL = B(0.0195, 0.0095, 0.002, 0.0505, 0.0405, 0.018);
            double[] ANV_CB = B(0.0195, 0.0095, 0.002, 0.0505, 0.0405, 0.002);
            double[] G1_RINGOD = B(-0.022, -0.022, 0.006, 0.022, 0.022, 0.018);
            double[] G2_RINGOD = B(-0.042, -0.042, 0.006, 0.042, 0.042, 0.018);
            double[] G1_HUBOD = B(-0.008, -0.008, 0.018, 0.008, 0.008, 0.024);
            double[] G2_HUBOD = B(-0.008, -0.008, 0.018, 0.008, 0.008, 0.024);

            double[] WORK_OD = B(-0.015, -0.015, 0, 0.015, 0.015, 0.050);
            double[] WORK_TOP = B(-0.015, -0.015, 0.050, 0.015, 0.015, 0.050);
            double[] WORK_BOT = B(-0.015, -0.015, 0, 0.015, 0.015, 0);

            double[] BOLT_SHANK = B(-0.003, -0.003, 0.005, 0.003, 0.003, 0.021);
            double[] BOLT_HEADBOT = B(-0.0065, -0.0065, 0, 0.0065, 0.0065, 0);
            double[] NUT_HOLE = B(-0.0032, -0.0032, 0, 0.0032, 0.0032, 0.004);
            double[] NUT_TOP = B(-0.0065, -0.0065, 0.004, 0.0065, 0.0065, 0.004);

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
                    for (int i = 0; i < 4; i++)
                    {
                        if (nm.StartsWith("bolt-" + (i + 1))) bolts[i] = c;
                    }
                }
                else if (nm.StartsWith("nut"))
                {
                    for (int i = 0; i < 4; i++)
                    {
                        if (nm.StartsWith("nut-" + (i + 1))) nuts[i] = c;
                    }
                }
            }

            // === plate fix (3 plane mates) ===
            PlaneMate(plate, false, PLATE_LEFT, 2, 0, 0);       // plate left (world x=0) to Right plane (x=0) dist 0
            PlaneMate(plate, false, PLATE_BOT, 1, 0, 0);        // plate bottom (world y=0) to Top plane (y=0) dist 0
            PlaneMate(plate, false, PLATE_BACK, 0, 2, 0.095);   // plate back (world z=-0.095) to Front plane (z=0) dist 0.095, closest-align

            // === brackets A/B ===
            Mate(bracketA, false, BRK_BOT, plate, false, PLATE_TOP, 5, 0, 0, 0, 0);
            Mate(bracketA, false, BRK_BACK, plate, false, PLATE_BACK, 5, 0, 0.095, 0, 0);
            Mate(bracketA, false, BRK_LEFT, plate, false, PLATE_LEFT, 5, 0, 0.045, 0, 0);
            Mate(bracketB, false, BRK_BOT, plate, false, PLATE_TOP, 5, 0, 0, 0, 0);
            Mate(bracketB, false, BRK_BACK, plate, false, PLATE_BACK, 5, 0, 0.095, 0, 0);
            Mate(bracketB, false, BRK_LEFT, plate, false, PLATE_LEFT, 5, 0, 0.1053, 0, 0);

            // === tower (2 mates: back + left — the y is fixed by the pre-position) ===
            Mate(tower, false, TWR_BACK, plate, false, PLATE_BACK, 5, 0, 0.095, 0, 0);
            Mate(tower, false, TWR_LEFT, plate, false, PLATE_LEFT, 5, 0, 0.2303, 0, 0);

            // === shafts ===
            Mate(shaft1, true, SH1_OD, bracketA, true, BRK_HOLE, 1, 2, 0, 0, 0);
            Mate(shaft1, false, SH1_BACK, bracketA, false, BRK_BACK, 5, 0, -0.020, 0, 0);
            Mate(shaft2, true, SH2_OD, bracketB, true, BRK_HOLE, 1, 2, 0, 0, 0);
            Mate(shaft2, false, SH2_BACK, bracketB, false, BRK_BACK, 5, 0, 0, 0, 0);

            // === gears ===
            Mate(gear1, true, G1_HOLE, shaft1, true, SH1_OD, 1, 2, 0, 0, 0);
            Mate(gear1, false, G1_RINGBACK, bracketA, false, BRK_BACK, 5, 0, 0.012, 0, 0);
            Mate(gear2, true, G2_HOLE, shaft2, true, SH2_OD, 1, 2, 0, 0, 0);
            Mate(gear2, false, G2_RINGBACK, bracketB, false, BRK_BACK, 5, 0, 0.012, 0, 0);
            // gear mate 1:2 on the hub OD walls
            Mate(gear1, true, G1_HUBOD, gear2, true, G2_HUBOD, 10, 2, 0, 1, 2);

            // === crank / pin / rod ===
            Mate(crank, true, CRK_HOLE, shaft2, true, SH2_OD, 1, 2, 0, 0, 0);
            Mate(crank, false, CRK_FRONT, gear2, false, G2_HUBFRONT, 5, 0, 0.012, 0, 0);
            Mate(pin, true, PIN_OD, crank, true, CRK_PINHOLE, 1, 2, 0, 0, 0);
            Mate(pin, false, PIN_FRONT, crank, false, CRK_FRONT, 5, 0, 0.012, 0, 0);
            Mate(rod, true, ROD_E1HOLE, pin, true, PIN_OD, 1, 2, 0, 0, 0);
            Mate(rod, true, ROD_E2HOLE, slider, true, SL_HOLE, 1, 2, 0, 0, 0);
            Mate(rod, false, ROD_FRONT, slider, false, SL_FRONT, 5, 0, 0.024, 0, 0);

            // === slider / rail ===
            Mate(slider, false, SL_TOP, plate, false, PLATE_TOP, 5, 0, 0.093, 0, 0);
            Mate(slider, false, SL_BACK, rail, false, RAIL_WALLFRONT, 5, 0, 0.024, 0, 0);
            Mate(rail, false, RAIL_BOT, plate, false, PLATE_BOT, 5, 0, 0.044, 0, 0);
            Mate(rail, false, RAIL_LEFT, plate, false, PLATE_LEFT, 5, 0, 0.2253, 0, 0);

            // === motor (3 mates: concentric + axial + left — the y follows the concentric) ===
            Mate(motor, true, MOT_BODY, shaft1, true, SH1_OD, 1, 2, 0, 0, 0);
            Mate(motor, false, MOT_FLGFRONT, shaft1, false, SH1_BACK, 5, 0, 0, 0, 0);
            Mate(motor, false, MOT_FOOTLEFT, plate, false, PLATE_LEFT, 5, 0, 0.045, 0, 0);

            // === anvil / work ===
            Mate(anvil, false, ANV_TOP, plate, false, PLATE_TOP, 5, 0, 0.018, 0, 0);
            Mate(anvil, false, ANV_BACK, plate, false, PLATE_BACK, 5, 0, 0.115, 0, 0);
            Mate(anvil, false, ANV_LEFT, plate, false, PLATE_LEFT, 5, 0, 0.3508, 0, 0);
            Mate(work, true, WORK_OD, anvil, true, ANV_CBWALL, 1, 2, 0, 0, 0);
            Mate(work, false, WORK_TOP, anvil, false, ANV_TOP, 5, 0, 0.034, 0, 0);

            // === bolts / nuts ===
            double[][] PHS = { PLATE_H1, PLATE_H2, PLATE_H3, PLATE_H4 };
            for (int i = 0; i < 4; i++)
            {
                Mate(bolts[i], true, BOLT_SHANK, plate, true, PHS[i], 1, 2, 0, 0, 0);
                Mate(bolts[i], false, BOLT_HEADBOT, plate, false, PLATE_TOP, 5, 2, 0, 0, 0);
                Mate(nuts[i], true, NUT_HOLE, bolts[i], true, BOLT_SHANK, 1, 2, 0, 0, 0);
                Mate(nuts[i], false, NUT_TOP, plate, false, PLATE_BOT, 5, 2, 0, 0, 0);
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

            // === save ===
            string outName = "C:\\Users\\zgzgd\\Documents\\DSH\\精英联赛_设计包\\CAD\\齿轮传动曲柄滑块机构.SLDASM";
            int swErr = 0, swWarn = 0;
            ad.SaveAs3(outName, 0, 2);
            ad.ShowNamedView2("*Isometric", 7);
            Thread.Sleep(500);
            ad.SaveBMP("C:\\Users\\zgzgd\\Documents\\DSH\\sw_asm_view3.bmp", 1280, 960);
            L("saved " + outName);
            L("done");
        }
        catch (Exception ex)
        {
            L("EX " + ex.Message);
        }
    }
}
