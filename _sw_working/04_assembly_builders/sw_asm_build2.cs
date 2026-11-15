// sw_asm_build2.cs - deterministic face-based mate builder (no rays)
using System;
using System.IO;
using System.Runtime.InteropServices;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class B2
{
    static StreamWriter log = new StreamWriter("C:\\Users\\zgzgd\\Documents\\DSH\\sw_asm_build2.log", false);
    static ISldWorks app;
    static AssemblyDoc assy;
    static ModelDoc2 adoc;
    static int mateCount = 0;

    static void L(string s) { log.WriteLine(DateTime.Now.ToString("HH:mm:ss") + " " + s); log.Flush(); }

    static double[] B(double x0, double y0, double z0, double x1, double y1, double z1)
    { return new double[] { x0, y0, z0, x1, y1, z1 }; }

    static Component2 FindComp(string name)
    {
        object[] comps = (object[])assy.GetComponents(false);
        foreach (object co in comps)
        {
            Component2 c = (Component2)co;
            if (c.Name2 == name) return c;
        }
        return null;
    }

    static Face2 FindFace(Component2 c, bool wantCyl, double[] exp)
    {
        Body2 b = (Body2)c.GetBody();
        object[] faces = (object[])b.GetFaces();
        foreach (object fo in faces)
        {
            Face2 f = (Face2)fo;
            Surface s = (Surface)f.GetSurface();
            bool isCyl = s.IsCylinder();
            if (isCyl != wantCyl) continue;
            if (!isCyl && !s.IsPlane()) continue;
            double[] bx = (double[])f.GetBox();
            if (bx == null) continue;
            bool ok = true;
            for (int i = 0; i < 6; i++)
                if (Math.Abs(bx[i] - exp[i]) > 0.0012) { ok = false; break; }
            if (ok) return f;
        }
        return null;
    }

    static bool Mate(Component2 c1, bool cyl1, double[] b1, Component2 c2, bool cyl2, double[] b2, int type, int align, double dist, double gn, double gd)
    {
        Face2 f1 = FindFace(c1, cyl1, b1);
        Face2 f2 = FindFace(c2, cyl2, b2);
        if (f1 == null || f2 == null) { L("  FACE-NOT-FOUND " + c1.Name2 + " / " + c2.Name2); return false; }
        bool s1 = ((Entity)f1).Select4(false, null);
        bool s2 = ((Entity)f2).Select4(true, null);
        if (!s1 || !s2) { L("  SEL-FAIL " + c1.Name2 + "/" + c2.Name2 + " s1=" + s1 + " s2=" + s2); return false; }
        int err = 0;
        Mate2 m = (Mate2)assy.AddMate5(type, align, false, dist, 0, 0, gn, gd, 0, 0, 0, false, false, 0, out err);
        mateCount++;
        L("  mate" + mateCount + " " + c1.Name2 + "<->" + c2.Name2 + " t=" + type + " d=" + dist + " -> " + (m == null ? "NULL" : "OK") + " err=" + err);
        adoc.EditRebuild3();
        return m != null;
    }

    static string[] planeNames = new string[3];

    static void LoadPlaneNames()
    {
        int n = 0;
        Feature f = (Feature)adoc.FirstFeature();
        while (f != null && n < 3)
        {
            if (f.GetTypeName2() == "RefPlane") { planeNames[n] = f.Name; n++; }
            f = (Feature)f.GetNextFeature();
        }
        L("planes " + planeNames[0] + " / " + planeNames[1] + " / " + planeNames[2]);
    }

    static bool PlaneMate(Component2 c, bool cyl, double[] b, string planeName, int align, double dist)
    {
        Face2 f1 = FindFace(c, cyl, b);
        if (f1 == null) { L("  FACE-NOT-FOUND " + c.Name2 + " (plane)"); return false; }
        bool s1 = ((Entity)f1).Select4(false, null);
        bool s2 = adoc.Extension.SelectByID2(planeName, "PLANE", 0, 0, 0, true, 0, null, 0);
        if (!s1 || !s2) { L("  SEL-FAIL plane " + c.Name2 + "/" + planeName); return false; }
        int err = 0;
        Mate2 m = (Mate2)assy.AddMate5((int)swMateType_e.swMateDISTANCE, align, false, dist, 0, 0, 0, 0, 0, 0, 0, false, false, 0, out err);
        mateCount++;
        L("  mate" + mateCount + " " + c.Name2 + "<->" + planeName + " d=" + dist + " -> " + (m == null ? "NULL" : "OK") + " err=" + err);
        adoc.EditRebuild3();
        return m != null;
    }

    static void Main()
    {
        try
        {
            Type t = Type.GetTypeFromProgID("SldWorks.Application");
            app = (ISldWorks)Activator.CreateInstance(t);
            string dir = "C:\\Users\\zgzgd\\Documents\\DSH\\sw_parts8\\";
            string[] files = { "plate", "bracket", "tower", "shaft1", "shaft2", "gear1", "gear2", "crank", "pin", "rod", "slider", "rail", "motor", "anvil", "work", "bolt", "nut" };
            app.CloseAllDocuments(true);
            foreach (string f in files)
            {
                int e = 0, w = 0;
                ModelDoc2 d = (ModelDoc2)app.OpenDoc6(dir + f + ".SLDPRT", 1, (int)swOpenDocOptions_e.swOpenDocOptions_Silent, "", ref e, ref w);
                if (d == null) { L("OPEN FAIL " + f); return; }
            }
            ModelDoc2 ad = (ModelDoc2)app.NewDocument("C:\\ProgramData\\SolidWorks\\SOLIDWORKS 2024\\templates\\gb_assembly.asmdot", 0, 0, 0);
            adoc = ad;
            assy = (AssemblyDoc)ad;
            L("newasm=" + (ad == null ? "NULL" : "ok"));

            // ---- insert 24 components (identity at final position; rotation applied after) ----
            Component2 plate = (Component2)assy.AddComponent5("plate.SLDPRT", 0, "", false, "", 0, 0, 0);
            Component2 bracketA = (Component2)assy.AddComponent5("bracket.SLDPRT", 0, "", false, "", 0.090, 0.012, 0);
            Component2 bracketB = (Component2)assy.AddComponent5("bracket.SLDPRT", 0, "", false, "", 0.1503, 0.012, 0);
            Component2 tower = (Component2)assy.AddComponent5("tower.SLDPRT", 0, "", false, "", 0.2703, 0.012, 0);
            Component2 shaft1 = (Component2)assy.AddComponent5("shaft1.SLDPRT", 0, "", false, "", 0.090, 0.077, -0.020);
            Component2 shaft2 = (Component2)assy.AddComponent5("shaft2.SLDPRT", 0, "", false, "", 0.1503, 0.077, 0);
            Component2 gear1 = (Component2)assy.AddComponent5("gear1.SLDPRT", 0, "", false, "", 0.090, 0.077, 0.012);
            Component2 gear2 = (Component2)assy.AddComponent5("gear2.SLDPRT", 0, "", false, "", 0.1503, 0.077, 0.012);
            Component2 crank = (Component2)assy.AddComponent5("crank.SLDPRT", 0, "", false, "", 0.1503, 0.077, 0.040);
            Component2 pin = (Component2)assy.AddComponent5("pin.SLDPRT", 0, "", false, "", 0.1853, 0.077, 0.044);
            Component2 rod = (Component2)assy.AddComponent5("rod.SLDPRT", 0, "", false, "", 0.1853, 0.077, 0.052);
            Component2 slider = (Component2)assy.AddComponent5("slider.SLDPRT", 0, "", false, "", 0.2703, 0.078, 0.060);
            Component2 rail = (Component2)assy.AddComponent5("rail.SLDPRT", 0, "", false, "", 0.2703, 0.077, 0.036);
            Component2 motor = (Component2)assy.AddComponent5("motor.SLDPRT", 0, "", false, "", 0.090, 0.077, -0.020);
            Component2 anvil = (Component2)assy.AddComponent5("anvil.SLDPRT", 0, "", false, "", 0.3508, 0.032, 0.020);
            Component2 work = (Component2)assy.AddComponent5("work.SLDPRT", 0, "", false, "", 0.3858, 0.030, 0.045);
            Component2[] bolts = new Component2[4];
            Component2[] nuts = new Component2[4];
            double[] bx = { 0.020, 0.412, 0.020, 0.412 };
            double[] bz = { -0.042, -0.042, 0.088, 0.088 };
            for (int i = 0; i < 4; i++)
            {
                bolts[i] = (Component2)assy.AddComponent5("bolt.SLDPRT", 0, "", false, "", bx[i], 0.017, bz[i]);
                nuts[i] = (Component2)assy.AddComponent5("nut.SLDPRT", 0, "", false, "", bx[i], 0.008, bz[i]);
            }

            // ---- rotations (identity inserts, then rotate about the insert point) ----
            IMathUtility mu = (IMathUtility)app.GetMathUtility();
            MathPoint origin = (MathPoint)mu.CreatePoint(new double[] { 0, 0, 0 });
            MathVector axX = (MathVector)mu.CreateVector(new double[] { 1, 0, 0 });
            MathVector axY = (MathVector)mu.CreateVector(new double[] { 0, 1, 0 });
            MathTransform rxn = (MathTransform)mu.CreateTransformRotateAxis(origin, axX, -Math.PI / 2); // R_x(-90)
            MathTransform ryp = (MathTransform)mu.CreateTransformRotateAxis(origin, axY, Math.PI);      // R_y(180)
            // compose: T = R * trans(insert)  (translation = the AddComponent5 arg)
            double[] mtPlate = (double[])rxn.ArrayData;
            // translation matrix
            MathTransform rxnT = (MathTransform)mu.CreateTransform(new double[] { 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 });
            // NOTE: layout = rot 3x3 at 0-8, tx/ty/tz at 9-11, scale at 12
            double[] plateT = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 }; // will set 9-11
            plateT[9] = 0; plateT[10] = 0; plateT[11] = 0;
            MathTransform cPlate = (MathTransform)mu.CreateTransform(plateT);
            MathTransform fPlate = (MathTransform)rxn.Multiply(cPlate);
            plate.Transform2 = fPlate;
            // anvil: insert (0.3508, 0.032, 0.020), R_x(-90)
            double[] anvT = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };
            anvT[9] = 0.3508; anvT[10] = 0.032; anvT[11] = 0.020;
            anvil.Transform2 = (MathTransform)rxn.Multiply((MathTransform)mu.CreateTransform(anvT));
            // work: insert (0.3858, 0.030, 0.045)
            double[] wrkT = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };
            wrkT[9] = 0.3858; wrkT[10] = 0.030; wrkT[11] = 0.045;
            work.Transform2 = (MathTransform)rxn.Multiply((MathTransform)mu.CreateTransform(wrkT));
            // bolts/nuts: insert (bx, 0.017, bz) + (bx, 0.008, bz)
            for (int i = 0; i < 4; i++)
            {
                double[] bT = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };
                bT[9] = bx[i]; bT[10] = 0.017; bT[11] = bz[i];
                bolts[i].Transform2 = (MathTransform)rxn.Multiply((MathTransform)mu.CreateTransform(bT));
                double[] nT = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };
                nT[9] = bx[i]; nT[10] = 0.008; nT[11] = bz[i];
                nuts[i].Transform2 = (MathTransform)rxn.Multiply((MathTransform)mu.CreateTransform(nT));
            }
            // rail: R_y(180) at insert (0.2703, 0.077, 0.036)
            double[] rlT = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };
            rlT[9] = 0.2703; rlT[10] = 0.077; rlT[11] = 0.036;
            rail.Transform2 = (MathTransform)ryp.Multiply((MathTransform)mu.CreateTransform(rlT));
            // identity-translation for the rest (AddComponent5 already placed them; Transform2 = pure translation at their positions)
            Component2[] ids = { bracketA, bracketB, tower, shaft1, shaft2, gear1, gear2, crank, pin, rod, slider, motor };
            double[] idPos = { 0.090, 0.012, 0, 0.1503, 0.012, 0, 0.2703, 0.012, 0, 0.090, 0.077, -0.020, 0.1503, 0.077, 0, 0.090, 0.077, 0.012, 0.1503, 0.077, 0.012, 0.1503, 0.077, 0.040, 0.1853, 0.077, 0.044, 0.1853, 0.077, 0.052, 0.2703, 0.078, 0.060, 0.090, 0.077, -0.020 };
            for (int i = 0; i < ids.Length; i++)
            {
                double[] t16 = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };
                t16[9] = idPos[i * 3]; t16[10] = idPos[i * 3 + 1]; t16[11] = idPos[i * 3 + 2];
                ids[i].Transform2 = (MathTransform)mu.CreateTransform(t16);
            }
            L("components placed");
            adoc.EditRebuild3();
            System.Threading.Thread.Sleep(1000);
            LoadPlaneNames();

            // ---- face specs (local boxes; from the face probe + part recipes) ----
            double[] PLATE_BOTTOM = B(0, -0.235, 0, 0.432, 0.095, 0);
            double[] PLATE_TOP = B(0, -0.235, 0.012, 0.432, 0.095, 0.012);
            double[] PLATE_BACK = B(0, -0.235, 0, 0.432, -0.235, 0.012);
            double[] PLATE_LEFT = B(0, -0.235, 0, 0, 0.095, 0.012);
            double[] PLATE_HOLE1 = B(0.0168, -0.0452, 0, 0.0232, -0.0388, 0.012);
            double[] PLATE_HOLE2 = B(0.0168, 0.0388, 0, 0.0232, 0.0452, 0.012);
            double[] PLATE_HOLE3 = B(0.4088, -0.0452, 0, 0.4152, -0.0388, 0.012);
            double[] PLATE_HOLE4 = B(0.4088, 0.0388, 0, 0.4152, 0.0452, 0.012);
            double[] BRACKET_TOP = B(-0.045, 0.090, 0, 0.045, 0.090, 0.012);
            double[] BRACKET_BACK = B(-0.045, 0, 0, 0.045, 0.090, 0);
            double[] BRACKET_LEFT = B(-0.045, 0, 0, -0.045, 0.015, 0.012);
            double[] BRACKET_HOLE = B(-0.0051, 0.0599, 0, 0.0051, 0.0701, 0.012);
            double[] TOWER_TOP = B(-0.040, 0.032, 0, 0.040, 0.032, 0.012);
            double[] TOWER_BACK = B(-0.040, 0, 0, 0.040, 0.032, 0);
            double[] TOWER_LEFT = B(-0.040, 0, 0, -0.040, 0.032, 0.012);
            double[] SHAFT1_OD = B(-0.005, -0.005, 0, 0.005, 0.002, 0.056);
            double[] SHAFT2_OD = B(-0.005, -0.005, 0, 0.005, 0.002, 0.048);
            double[] SHAFT1_FRONT = B(-0.005, -0.005, 0.056, 0.005, 0.002, 0.056);
            double[] SHAFT2_FRONT = B(-0.005, -0.005, 0.048, 0.005, 0.002, 0.048);
            double[] GEAR_HOLE = B(-0.0051, -0.0051, 0, 0.0051, 0.0051, 0.024);
            double[] GEAR_HUBFRONT = B(-0.008, -0.008, 0.024, 0.008, 0.008, 0.024);
            double[] GEAR_OD = B(-0.022, -0.022, 0, 0.022, 0.022, 0.018);
            double[] GEAR2_OD = B(-0.042, -0.042, 0, 0.042, 0.042, 0.018);
            double[] CRANK_HOLE = B(-0.0051, -0.0051, 0, 0.0051, 0.0051, 0.008);
            double[] CRANK_PINHOLE = B(0.0309, -0.0041, 0, 0.0391, 0.0041, 0.008);
            double[] CRANK_FRONT = B(-0.050, -0.050, 0.008, 0.050, 0.050, 0.008);
            double[] PIN_OD = B(-0.004, -0.004, 0, 0.004, 0.004, 0.016);
            double[] PIN_FRONT = B(-0.004, -0.004, 0.016, 0.004, 0.004, 0.016);
            double[] ROD_EYE1_HOLE = B(-0.0041, -0.0041, 0, 0.0041, 0.0041, 0.008);
            double[] ROD_EYE2_HOLE = B(0.0809, -0.0041, 0, 0.0891, 0.0041, 0.008);
            double[] ROD_EYE1_BACK = B(-0.011, -0.011, 0, 0.011, 0.011, 0);
            double[] ROD_EYE2_BACK = B(0.074, -0.011, 0, 0.096, 0.011, 0);
            double[] SLIDER_HOLE = B(-0.0041, -0.0051, 0, 0.0041, 0.0031, 0.024);
            double[] SLIDER_BACK = B(-0.033, -0.028, 0, 0.033, 0.028, 0);
            double[] SLIDER_FRONT = B(-0.033, -0.028, 0.024, 0.033, 0.028, 0.024);
            double[] SLIDER_BOTTOM = B(-0.033, -0.028, 0, 0.033, -0.028, 0.024);
            double[] RAIL_WALLFRONT = B(-0.045, -0.033, 0.024, 0.045, 0.033, 0.024);
            double[] RAIL_TOP = B(-0.045, 0.033, 0, 0.045, 0.033, 0.024);
            double[] RAIL_LEFT = B(-0.045, -0.033, 0, -0.045, 0.033, 0.048);
            double[] MOTOR_OD = B(-0.028, -0.028, -0.095, 0.028, 0.028, 0);
            double[] MOTOR_FOOTBACK = B(-0.045, -0.065, -0.020, 0.045, -0.027, -0.020);
            double[] MOTOR_FOOTBOTTOM = B(-0.045, -0.065, -0.020, 0.045, -0.065, 0);
            double[] MOTOR_FOOTLEFT = B(-0.045, -0.065, -0.020, -0.045, -0.027, 0);
            double[] ANVIL_TOP = B(0, 0, 0, 0.070, 0.050, 0);
            double[] ANVIL_BACK = B(0, 0.050, -0.018, 0.070, 0.050, 0);
            double[] ANVIL_LEFT = B(0, 0, -0.018, 0, 0.050, 0);
            double[] ANVIL_CBWALL = B(0.0195, 0.0095, -0.002, 0.0505, 0.0405, 0);
            double[] WORK_OD = B(-0.015, -0.015, 0, 0.015, 0.015, 0.050);
            double[] WORK_TOP = B(-0.015, -0.015, 0.050, 0.015, 0.015, 0.050);
            double[] BOLT_HEADOD = B(-0.0065, -0.0065, -0.005, 0.0065, 0.0065, 0);
            double[] BOLT_HEADTOP = B(-0.0065, -0.0065, 0, 0.0065, 0.0065, 0);
            double[] NUT_HOLE = B(-0.0032, -0.0032, -0.004, 0.0032, 0.0032, 0);
            double[] NUT_BOTTOM = B(-0.0065, -0.0065, -0.004, 0.0065, 0.0065, -0.004);

            const int DIST = (int)swMateType_e.swMateDISTANCE;
            const int CONC = (int)swMateType_e.swMateCONCENTRIC;
            const int LOCK = (int)swMateType_e.swMateLOCK;
            const int GEAR = (int)swMateType_e.swMateGEAR;
            const int CLOSEST = (int)swMateAlign_e.swMateAlignCLOSEST;

            // plate fix (3 plane mates)
            PlaneMate(plate, false, PLATE_BACK, planeNames[0], 1, 0.095);
            PlaneMate(plate, false, PLATE_LEFT, planeNames[2], 0, 0);
            PlaneMate(plate, false, PLATE_BOTTOM, planeNames[1], 0, 0);

            // brackets + tower
            Mate(bracketA, false, BRACKET_TOP, plate, false, PLATE_BOTTOM, DIST, CLOSEST, 0.102, 0, 0);
            Mate(bracketA, false, BRACKET_BACK, plate, false, PLATE_BACK, DIST, CLOSEST, 0.095, 0, 0);
            Mate(bracketA, false, BRACKET_LEFT, plate, false, PLATE_LEFT, DIST, CLOSEST, 0.045, 0, 0);
            Mate(bracketB, false, BRACKET_TOP, plate, false, PLATE_BOTTOM, DIST, CLOSEST, 0.102, 0, 0);
            Mate(bracketB, false, BRACKET_BACK, plate, false, PLATE_BACK, DIST, CLOSEST, 0.095, 0, 0);
            Mate(bracketB, false, BRACKET_LEFT, plate, false, PLATE_LEFT, DIST, CLOSEST, 0.1053, 0, 0);
            Mate(tower, false, TOWER_TOP, plate, false, PLATE_BOTTOM, DIST, CLOSEST, 0.044, 0, 0);
            Mate(tower, false, TOWER_BACK, plate, false, PLATE_BACK, DIST, CLOSEST, 0.095, 0, 0);
            Mate(tower, false, TOWER_LEFT, plate, false, PLATE_LEFT, DIST, CLOSEST, 0.2303, 0, 0);

            // shafts
            Mate(shaft1, true, SHAFT1_OD, bracketA, true, BRACKET_HOLE, CONC, CLOSEST, 0, 0, 0);
            Mate(shaft1, false, SHAFT1_FRONT, bracketA, false, BRACKET_BACK, DIST, CLOSEST, 0.036, 0, 0);
            Mate(shaft2, true, SHAFT2_OD, bracketB, true, BRACKET_HOLE, CONC, CLOSEST, 0, 0, 0);
            Mate(shaft2, false, SHAFT2_FRONT, bracketB, false, BRACKET_BACK, DIST, CLOSEST, 0.048, 0, 0);

            // gears + locks + gear mate
            Mate(gear1, true, GEAR_HOLE, shaft1, true, SHAFT1_OD, CONC, CLOSEST, 0, 0, 0);
            Mate(gear1, false, GEAR_HUBFRONT, bracketA, false, BRACKET_BACK, DIST, CLOSEST, 0.036, 0, 0);
            Mate(gear1, false, GEAR_HUBFRONT, shaft1, false, SHAFT1_FRONT, LOCK, CLOSEST, 0, 0, 0);
            Mate(gear2, true, GEAR_HOLE, shaft2, true, SHAFT2_OD, CONC, CLOSEST, 0, 0, 0);
            Mate(gear2, false, GEAR_HUBFRONT, bracketB, false, BRACKET_BACK, DIST, CLOSEST, 0.036, 0, 0);
            Mate(gear2, false, GEAR_HUBFRONT, shaft2, false, SHAFT2_FRONT, LOCK, CLOSEST, 0, 0, 0);
            Mate(gear2, true, GEAR2_OD, gear1, true, GEAR_OD, GEAR, 1, 0, 1, 2);

            // crank + pin + rod
            Mate(crank, true, CRANK_HOLE, shaft2, true, SHAFT2_OD, CONC, CLOSEST, 0, 0, 0);
            Mate(crank, false, CRANK_FRONT, gear2, false, GEAR_HUBFRONT, DIST, CLOSEST, 0.012, 0, 0);
            Mate(crank, false, CRANK_FRONT, shaft2, false, SHAFT2_FRONT, LOCK, CLOSEST, 0, 0, 0);
            Mate(pin, true, PIN_OD, crank, true, CRANK_PINHOLE, CONC, CLOSEST, 0, 0, 0);
            Mate(pin, false, PIN_FRONT, crank, false, CRANK_FRONT, DIST, CLOSEST, 0.012, 0, 0);
            Mate(rod, true, ROD_EYE1_HOLE, pin, true, PIN_OD, CONC, CLOSEST, 0, 0, 0);
            Mate(rod, false, ROD_EYE1_BACK, crank, false, CRANK_FRONT, DIST, CLOSEST, 0.004, 0, 0);
            Mate(rod, true, ROD_EYE2_HOLE, slider, true, SLIDER_HOLE, CONC, CLOSEST, 0, 0, 0);
            Mate(rod, false, ROD_EYE2_BACK, slider, false, SLIDER_BACK, DIST, CLOSEST, 0.008, 0, 0);

            // slider + rail
            Mate(slider, false, SLIDER_BACK, rail, false, RAIL_WALLFRONT, DIST, CLOSEST, 0.024, 0, 0);
            Mate(slider, false, SLIDER_BOTTOM, plate, false, PLATE_BOTTOM, DIST, CLOSEST, 0.050, 0, 0);
            Mate(rail, false, RAIL_TOP, plate, false, PLATE_BOTTOM, DIST, CLOSEST, 0.110, 0, 0);
            Mate(rail, false, RAIL_LEFT, plate, false, PLATE_LEFT, DIST, CLOSEST, 0.2253, 0, 0);

            // motor
            Mate(motor, true, MOTOR_OD, shaft1, true, SHAFT1_OD, CONC, CLOSEST, 0, 0, 0);
            Mate(motor, false, MOTOR_FOOTBACK, plate, false, PLATE_BACK, DIST, CLOSEST, 0.055, 0, 0);
            Mate(motor, false, MOTOR_FOOTBOTTOM, plate, false, PLATE_BOTTOM, DIST, CLOSEST, 0.012, 0, 0);
            Mate(motor, false, MOTOR_FOOTLEFT, plate, false, PLATE_LEFT, DIST, CLOSEST, 0.045, 0, 0);

            // anvil + work
            Mate(anvil, false, ANVIL_TOP, plate, false, PLATE_BOTTOM, DIST, CLOSEST, 0.032, 0, 0);
            Mate(anvil, false, ANVIL_BACK, plate, false, PLATE_BACK, DIST, CLOSEST, 0.115, 0, 0);
            Mate(anvil, false, ANVIL_LEFT, plate, false, PLATE_LEFT, DIST, CLOSEST, 0.3508, 0, 0);
            Mate(work, true, WORK_OD, anvil, true, ANVIL_CBWALL, CONC, CLOSEST, 0, 0, 0);
            Mate(work, false, WORK_TOP, anvil, false, ANVIL_TOP, DIST, CLOSEST, 0.048, 0, 0);

            // bolts + nuts
            double[][] plateHoles = { PLATE_HOLE1, PLATE_HOLE2, PLATE_HOLE3, PLATE_HOLE4 };
            for (int i = 0; i < 4; i++)
            {
                Mate(bolts[i], true, BOLT_HEADOD, plate, true, plateHoles[i], CONC, CLOSEST, 0, 0, 0);
                Mate(bolts[i], false, BOLT_HEADTOP, plate, false, PLATE_BOTTOM, DIST, CLOSEST, 0.017, 0, 0);
                Mate(nuts[i], true, NUT_HOLE, plate, true, plateHoles[i], CONC, CLOSEST, 0, 0, 0);
                Mate(nuts[i], false, NUT_BOTTOM, plate, false, PLATE_BOTTOM, DIST, CLOSEST, 0.004, 0, 0);
            }

            // ---- position walk ----
            object[] comps2 = (object[])assy.GetComponents(false);
            foreach (object co in comps2)
            {
                Component2 cc = (Component2)co;
                MathPoint pp = (MathPoint)mu.CreatePoint(new double[] { 0, 0, 0 });
                pp = (MathPoint)pp.MultiplyTransform(cc.Transform2);
                double[] d = (double[])pp.ArrayData;
                L("WALK " + cc.Name2 + " " + d[0].ToString("F4") + "," + d[1].ToString("F4") + "," + d[2].ToString("F4"));
            }

            adoc.ViewZoomtofit2();
            string savePath = "C:\\Users\\zgzgd\\Documents\\DSH\\\u7CBE\u82F1\u8054\u8D5B_\u8BBE\u8BA1\u5305\\CAD\\\u9F7F\u8F6E\u4F20\u52A8\u66F2\u67C4\u6ED1\u5757\u673A\u6784.SLDASM";
            int sv = adoc.SaveAs3(savePath, 0, 2);
            L("save res=" + sv);
            adoc.ShowNamedView2("*Isometric", 7);
            System.Threading.Thread.Sleep(500);
            adoc.SaveBMP("C:\\Users\\zgzgd\\Documents\\DSH\\asm_view.bmp", 1280, 960);
            L("done mates=" + mateCount);
        }
        catch (Exception ex)
        {
            L("EX " + ex.GetType().Name + " " + ex.Message);
        }
    }
}
