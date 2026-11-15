using System;
using System.Runtime.InteropServices;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class AsmBuilder
{
    static ISldWorks swApp;
    static IAssemblyDoc assy;
    static IModelDoc2 adoc;
    static int mateCount = 0;
    static string planeFront, planeTop, planeRight;

    static void Log(string msg)
    {
        try { System.IO.File.AppendAllText("C:\\Users\\zgzgd\\Documents\\DSH\\sw_asm_build.log", DateTime.Now.ToString("HH:mm:ss") + " " + msg + System.Environment.NewLine); }
        catch { }
    }

    static bool SelRay(double x1, double y1, double z1, double x2, double y2, double z2, bool append)
    {
        if (!append) adoc.ClearSelection2(true);
        bool ok = adoc.Extension.SelectByRay(x1, y1, z1, x2 - x1, y2 - y1, z2 - z1, 0.0001, (int)swSelectType_e.swSelFACES, append, 0, 0);
        if (!ok) Log("  SELRAY-FAIL " + x1 + "," + y1 + "," + z1 + " -> " + x2 + "," + y2 + "," + z2);
        return ok;
    }

    static bool SelPlane(string name, bool append)
    {
        if (!append) adoc.ClearSelection2(true);
        bool ok = adoc.Extension.SelectByID2(name, "PLANE", 0, 0, 0, append, 0, null, 0);
        if (!ok) Log("  SELPLANE-FAIL " + name);
        return ok;
    }

    static void GetPlaneNames()
    {
        Feature f = (Feature)adoc.FirstFeature();
        int n = 0;
        while (f != null && n < 3)
        {
            if (f.GetTypeName2() == "RefPlane")
            {
                if (n == 0) planeFront = f.Name;
                else if (n == 1) planeTop = f.Name;
                else planeRight = f.Name;
                n++;
            }
            f = (Feature)f.GetNextFeature();
        }
        Log("planes " + planeFront + "/" + planeTop + "/" + planeRight);
    }

    static void AddDist(int align, double dist)
    {
        int err = -1;
        Mate2 m = (Mate2)assy.AddMate5((int)swMateType_e.swMateDISTANCE, align, false, dist, 0, 0, 0, 0, 0, 0, 0, false, false, 0, out err);
        mateCount++;
        Log("mate" + mateCount + " dist=" + dist + " align=" + align + " -> " + (m == null ? "NULL" : "OK") + " err=" + err);
        adoc.EditRebuild3();
    }

    static void AddConc()
    {
        int err = -1;
        Mate2 m = (Mate2)assy.AddMate5((int)swMateType_e.swMateCONCENTRIC, 2, false, 0, 0, 0, 0, 0, 0, 0, 0, false, false, 0, out err);
        mateCount++;
        Log("mate" + mateCount + " conc -> " + (m == null ? "NULL" : "OK") + " err=" + err);
        adoc.EditRebuild3();
    }

    static void AddLock()
    {
        int err = -1;
        Mate2 m = (Mate2)assy.AddMate5((int)swMateType_e.swMateLOCK, 0, false, 0, 0, 0, 0, 0, 0, 0, 0, false, false, 0, out err);
        mateCount++;
        Log("mate" + mateCount + " LOCK -> " + (m == null ? "NULL" : "OK") + " err=" + err);
        adoc.EditRebuild3();
    }

    static void AddGear()
    {
        int err = -1;
        Mate2 m = (Mate2)assy.AddMate5((int)swMateType_e.swMateGEAR, 2, false, 0, 0, 0, 1, 2, 0, 0, 0, false, false, 0, out err);
        mateCount++;
        Log("mate" + mateCount + " gear 1:2 -> " + (m == null ? "NULL" : "OK") + " err=" + err);
        adoc.EditRebuild3();
    }

    static Component2 AddComp(string name, double x, double y, double z, string rotMode)
    {
        Component2 c = (Component2)assy.AddComponent5(name, (int)swAddComponentConfigOptions_e.swAddComponentConfigOptions_CurrentSelectedConfig, "", false, "", 0, 0, 0);
        if (c != null)
        {
            IMathUtility mu = (IMathUtility)swApp.GetMathUtility();
            double[] ca = new double[16];
            ca[0] = 1; ca[4] = 1; ca[8] = 1; ca[12] = 1;
            ca[9] = x; ca[10] = y; ca[11] = z;
            MathTransform cT = (MathTransform)mu.CreateTransform(ca);
            if (rotMode == "")
            {
                c.Transform2 = cT;
            }
            else
            {
                double[] ax = rotMode == "RX-90" ? new double[] { 1, 0, 0 } : new double[] { 0, 1, 0 };
                double ang = rotMode == "RX-90" ? -Math.PI / 2 : Math.PI;
                MathTransform rT = (MathTransform)mu.CreateTransformRotateAxis(mu.CreatePoint(new double[] { 0, 0, 0 }), mu.CreateVector(ax), ang);
                MathTransform t = (MathTransform)rT.Multiply(cT);
                c.Transform2 = t;
            }
        }
        Log("comp " + name + " -> " + (c == null ? "NULL" : c.Name2));
        return c;
    }

    static void Main(string[] args)
    {
        try
        {
            swApp = (ISldWorks)Marshal.GetActiveObject("SldWorks.Application");
            Log("attached " + swApp.RevisionNumber());
            Log("LOCK enum=" + (int)swMateType_e.swMateLOCK + " GEAR enum=" + (int)swMateType_e.swMateGEAR);
            swApp.CloseAllDocuments(true);
            System.Threading.Thread.Sleep(300);
            string pdir = "C:\\Users\\zgzgd\\Documents\\DSH\\sw_parts8\\";
            string[] parts = { "plate", "bracket", "tower", "shaft1", "shaft2", "gear1", "gear2", "crank", "pin", "rod", "slider", "rail", "motor", "anvil", "work", "bolt", "nut" };
            foreach (string p in parts)
            {
                int e = 0, w = 0;
                IModelDoc2 pd = (IModelDoc2)swApp.OpenDoc6(pdir + p + ".SLDPRT", 1, (int)swOpenDocOptions_e.swOpenDocOptions_Silent, "", ref e, ref w);
                Log("open " + p + " -> " + (pd != null) + " err=" + e + " warn=" + w);
                if (pd == null) { Log("FATAL cannot open " + p); return; }
            }
            adoc = (IModelDoc2)swApp.NewDocument("C:\\ProgramData\\SolidWorks\\SOLIDWORKS 2024\\templates\\gb_assembly.asmdot", 0, 0, 0);
            System.Threading.Thread.Sleep(1000);
            assy = (IAssemblyDoc)adoc;
            GetPlaneNames();

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
            AddComp("motor.SLDPRT", 0.090, 0.077, -0.020, "");
            AddComp("anvil.SLDPRT", 0.3508, 0.032, 0.070, "RX-90");
            AddComp("work.SLDPRT", 0.3858, 0.028, 0.045, "RX-90");
            AddComp("bolt.SLDPRT", 0.020, 0.017, -0.042, "RX-90");
            AddComp("bolt.SLDPRT", 0.412, 0.017, -0.042, "RX-90");
            AddComp("bolt.SLDPRT", 0.020, 0.017, 0.088, "RX-90");
            AddComp("bolt.SLDPRT", 0.412, 0.017, 0.088, "RX-90");
            AddComp("nut.SLDPRT", 0.020, 0, -0.042, "RX-90");
            AddComp("nut.SLDPRT", 0.412, 0, -0.042, "RX-90");
            AddComp("nut.SLDPRT", 0.020, 0, 0.088, "RX-90");
            AddComp("nut.SLDPRT", 0.412, 0, 0.088, "RX-90");

            // ===== MATES (ray-based picks, skip on pick failure) =====
            // plate fix (3): back face (z=-95, from behind), left face (x=0), bottom (y=0, from below)
            if (SelRay(0.216, 0.006, -0.145, 0.216, 0.006, -0.045, false) && SelPlane(planeFront, true)) AddDist(2, 0.095);
            if (SelRay(-0.050, 0.006, 0.100, 0.050, 0.006, 0.100, false) && SelPlane(planeRight, true)) AddDist(2, 0);
            if (SelRay(0.216, -0.050, 0.100, 0.216, 0.050, 0.100, false) && SelPlane(planeTop, true)) AddDist(2, 0);

            // bracket A (3): top face (y=102) + back (z=0) + left (x=45)
            if (SelRay(0.090, 0.150, 0.006, 0.090, -0.010, 0.006, false) && SelRay(0.216, -0.050, 0.100, 0.216, 0.050, 0.100, true)) AddDist(2, 0.102);
            if (SelRay(0.090, 0.040, -0.010, 0.090, 0.040, 0.050, false) && SelRay(0.216, 0.006, -0.145, 0.216, 0.006, -0.045, true)) AddDist(2, 0.095);
            if (SelRay(0.040, 0.040, 0.006, 0.060, 0.040, 0.006, false) && SelRay(-0.050, 0.006, 0.100, 0.050, 0.006, 0.100, true)) AddDist(2, 0.045);

            // bracket B (3)
            if (SelRay(0.1503, 0.150, 0.006, 0.1503, -0.010, 0.006, false) && SelRay(0.216, -0.050, 0.100, 0.216, 0.050, 0.100, true)) AddDist(2, 0.102);
            if (SelRay(0.1503, 0.040, -0.010, 0.1503, 0.040, 0.050, false) && SelRay(0.216, 0.006, -0.145, 0.216, 0.006, -0.045, true)) AddDist(2, 0.095);
            if (SelRay(0.102, 0.040, 0.006, 0.120, 0.040, 0.006, false) && SelRay(-0.050, 0.006, 0.100, 0.050, 0.006, 0.100, true)) AddDist(2, 0.1053);

            // tower (3): top (y=44) + back (z=0) + left (x=230.3)
            if (SelRay(0.2703, 0.090, 0.006, 0.2703, -0.010, 0.006, false) && SelRay(0.216, -0.050, 0.100, 0.216, 0.050, 0.100, true)) AddDist(2, 0.044);
            if (SelRay(0.2703, 0.020, -0.010, 0.2703, 0.020, 0.050, false) && SelRay(0.216, 0.006, -0.145, 0.216, 0.006, -0.045, true)) AddDist(2, 0.095);
            if (SelRay(0.220, 0.020, 0.006, 0.240, 0.020, 0.006, false) && SelRay(-0.050, 0.006, 0.100, 0.050, 0.006, 0.100, true)) AddDist(2, 0.2303);

            // shaft1 (2): concentric via axis-ray inside bracket hole (shaft OD at r=5, hole wall at r=5.1); axial = shaft front (z=36) to bracketA back
            if (SelRay(0.090, 0.077, 0.006, 0.140, 0.077, 0.006, false) && SelRay(0.09505, 0.077, 0.006, 0.140, 0.077, 0.006, true)) AddConc();
            if (SelRay(0.094, 0.077, 0.060, 0.094, 0.077, 0.020, false) && SelRay(0.090, 0.040, -0.010, 0.090, 0.040, 0.050, true)) AddDist(2, 0.036);

            // shaft2 (2)
            if (SelRay(0.1503, 0.077, 0.006, 0.210, 0.077, 0.006, false) && SelRay(0.15535, 0.077, 0.006, 0.210, 0.077, 0.006, true)) AddConc();
            if (SelRay(0.1543, 0.077, 0.060, 0.1543, 0.077, 0.020, false) && SelRay(0.1503, 0.040, -0.010, 0.1503, 0.040, 0.050, true)) AddDist(2, 0.048);

            // gear1 (2 + LOCK): concentric shaft1-in-hole; axial hub front (z=36) to bracketA back; LOCK gear1->shaft1 (hub front face + shaft front face)
            if (SelRay(0.090, 0.077, 0.020, 0.140, 0.077, 0.020, false) && SelRay(0.09505, 0.077, 0.020, 0.140, 0.077, 0.020, true)) AddConc();
            if (SelRay(0.084, 0.077, 0.060, 0.084, 0.077, 0.020, false) && SelRay(0.090, 0.040, -0.010, 0.090, 0.040, 0.050, true)) AddDist(2, 0.036);
            if (SelRay(0.096, 0.077, 0.040, 0.096, 0.077, 0.032, false) && SelRay(0.094, 0.077, 0.040, 0.094, 0.077, 0.032, true)) AddLock();

            // gear2 (2 + LOCK)
            if (SelRay(0.1503, 0.077, 0.020, 0.210, 0.077, 0.020, false) && SelRay(0.15535, 0.077, 0.020, 0.210, 0.077, 0.020, true)) AddConc();
            if (SelRay(0.1443, 0.077, 0.060, 0.1443, 0.077, 0.020, false) && SelRay(0.1503, 0.040, -0.010, 0.1503, 0.040, 0.050, true)) AddDist(2, 0.036);
            if (SelRay(0.1563, 0.077, 0.040, 0.1563, 0.077, 0.032, false) && SelRay(0.1543, 0.077, 0.040, 0.1543, 0.077, 0.032, true)) AddLock();

            // gear mate: gear1 top tooth (from above x=90) + gear2 top tooth (from above x=150.3)
            if (SelRay(0.090, 0.140, 0.024, 0.090, 0.060, 0.024, false) && SelRay(0.1503, 0.160, 0.024, 0.1503, 0.060, 0.024, true)) AddGear();

            // crank (2 + LOCK): concentric shaft2-in-hole at z=44; axial crank front (z=48) to gear2 hub front (z=36); LOCK crank->shaft2
            if (SelRay(0.1503, 0.077, 0.044, 0.210, 0.077, 0.044, false) && SelRay(0.15535, 0.077, 0.044, 0.210, 0.077, 0.044, true)) AddConc();
            if (SelRay(0.1503, 0.122, 0.060, 0.1503, 0.122, 0.030, false) && SelRay(0.1443, 0.077, 0.060, 0.1443, 0.077, 0.020, true)) AddDist(2, 0.012);
            if (SelRay(0.1503, 0.122, 0.060, 0.1503, 0.122, 0.030, false) && SelRay(0.1543, 0.077, 0.060, 0.1543, 0.077, 0.020, true)) AddLock();

            // pin (2): concentric in crank hole at z=46; axial pin front (z=60) to crank front (z=48)
            if (SelRay(0.1853, 0.077, 0.046, 0.225, 0.077, 0.046, false) && SelRay(0.18935, 0.077, 0.046, 0.225, 0.077, 0.046, true)) AddConc();
            if (SelRay(0.1853, 0.077, 0.070, 0.1853, 0.077, 0.040, false) && SelRay(0.1503, 0.122, 0.060, 0.1503, 0.122, 0.030, true)) AddDist(2, 0.012);

            // rod (4): eye1 concentric on pin at z=56; eye1 back (z=52) to crank front dist 4; eye2 concentric on slider hole; eye2 back (z=52) to slider back (z=60) dist 8
            if (SelRay(0.1853, 0.077, 0.056, 0.225, 0.077, 0.056, false) && SelRay(0.18935, 0.077, 0.056, 0.225, 0.077, 0.056, true)) AddConc();
            if (SelRay(0.230, 0.077, 0.030, 0.230, 0.077, 0.070, false) && SelRay(0.1503, 0.122, 0.060, 0.1503, 0.122, 0.030, true)) AddDist(2, 0.004);
            if (SelRay(0.27435, 0.077, 0.056, 0.310, 0.077, 0.056, false) && SelRay(0.27435, 0.077, 0.070, 0.310, 0.077, 0.070, true)) AddConc();
            if (SelRay(0.2783, 0.077, 0.030, 0.2783, 0.077, 0.070, false) && SelRay(0.2903, 0.077, 0.030, 0.2903, 0.077, 0.070, true)) AddDist(2, 0.008);

            // slider (2): back face (z=60) to rail back (z=36) dist 24; bottom (y=50) to plate bottom dist 50
            if (SelRay(0.2403, 0.077, 0.110, 0.2403, 0.077, 0.010, false) && SelRay(0.2703, 0.108, -0.014, 0.2703, 0.108, 0.086, true)) AddDist(2, 0.024);
            if (SelRay(0.2703, 0.070, 0.070, 0.2703, 0.040, 0.070, false) && SelRay(0.216, -0.050, 0.100, 0.216, 0.050, 0.100, true)) AddDist(2, 0.050);

            // rail (3): back wall face (z=60) to slider front (z=84) dist 24; top (y=110) to plate bottom dist 110; left (x=225.3) to plate left dist 225.3
            if (SelRay(0.2703, 0.108, -0.014, 0.2703, 0.108, 0.086, false) && SelRay(0.2703, 0.020, 0.090, 0.2703, 0.020, 0.040, true)) AddDist(2, 0.024);
            if (SelRay(0.2703, 0.140, 0.070, 0.2703, 0.010, 0.070, false) && SelRay(0.216, -0.050, 0.100, 0.216, 0.050, 0.100, true)) AddDist(2, 0.110);
            if (SelRay(0.200, 0.077, 0.070, 0.250, 0.077, 0.070, false) && SelRay(0.050, 0.006, 0.100, -0.050, 0.006, 0.100, true)) AddDist(2, 0.2253);

            // motor (4): body OD to shaft1 OD (axis-ray); foot back (z=-40) to plate back dist 55; foot bottom (y=12) to plate bottom dist 12; foot left (x=45) to plate left dist 45
            if (SelRay(0.030, 0.077, -0.060, 0.150, 0.077, -0.060, false) && SelRay(0.090, 0.077, 0.006, 0.140, 0.077, 0.006, true)) AddConc();
            if (SelRay(0.090, 0.030, -0.090, 0.090, 0.030, 0.010, false) && SelRay(0.216, 0.006, -0.145, 0.216, 0.006, -0.045, true)) AddDist(2, 0.055);
            if (SelRay(0.090, -0.050, -0.030, 0.090, 0.050, -0.030, false) && SelRay(0.216, -0.050, 0.100, 0.216, 0.050, 0.100, true)) AddDist(2, 0.012);
            if (SelRay(0.040, 0.030, -0.030, 0.060, 0.030, -0.030, false) && SelRay(-0.050, 0.006, 0.100, 0.050, 0.006, 0.100, true)) AddDist(2, 0.045);

            // anvil (3): top (y=32) to plate bottom dist 32 (pick at x=360 avoids the work's OD at x>=370.8); back (z=20) to plate back dist 115; left (x=350.8) to plate left dist 350.8
            if (SelRay(0.360, 0.050, 0.060, 0.360, 0.010, 0.060, false) && SelRay(0.216, -0.050, 0.100, 0.216, 0.050, 0.100, true)) AddDist(2, 0.032);
            if (SelRay(0.360, 0.020, -0.030, 0.360, 0.020, 0.070, false) && SelRay(0.216, 0.006, -0.145, 0.216, 0.006, -0.045, true)) AddDist(2, 0.115);
            if (SelRay(0.330, 0.020, 0.045, 0.370, 0.020, 0.045, false) && SelRay(-0.050, 0.006, 0.100, 0.050, 0.006, 0.100, true)) AddDist(2, 0.3508);

            // work (2): concentric in counterbore (z=45 at y=31); axial work top (y=78) to counterbore bottom (y=30) dist 48
            if (SelRay(0.3858, 0.055, 0.045, 0.425, 0.055, 0.045, false) && SelRay(0.4009, 0.031, 0.045, 0.425, 0.031, 0.045, true)) AddConc();
            if (SelRay(0.3858, 0.100, 0.045, 0.3858, 0.040, 0.045, false) && SelRay(0.3858, 0.020, 0.045, 0.3858, 0.040, 0.045, true)) AddDist(2, 0.048);

            // bolts (8): head OD to plate hole wall; head top (y=17) to plate bottom dist 17
            double[] bx = { 0.020, 0.412, 0.020, 0.412 };
            double[] bz = { -0.042, -0.042, 0.088, 0.088 };
            for (int i = 0; i < 4; i++)
            {
                if (SelRay(bx[i] - 0.030, 0.015, bz[i], bx[i] + 0.030, 0.015, bz[i], false) && SelRay(bx[i] + 0.00315, 0.005, bz[i], bx[i] + 0.040, 0.005, bz[i], true)) AddConc();
                if (SelRay(bx[i], 0.030, bz[i], bx[i], 0.010, bz[i], false) && SelRay(0.216, -0.050, 0.100, 0.216, 0.050, 0.100, true)) AddDist(2, 0.017);
            }
            // nuts (8): nut hole wall to plate hole wall; nut bottom (y=-4) to plate bottom dist 4
            for (int i = 0; i < 4; i++)
            {
                if (SelRay(bx[i] + 0.00315, -0.002, bz[i], bx[i] + 0.040, -0.002, bz[i], false) && SelRay(bx[i] + 0.00315, 0.005, bz[i], bx[i] + 0.040, 0.005, bz[i], true)) AddConc();
                if (SelRay(bx[i], -0.010, bz[i], bx[i], 0.002, bz[i], false) && SelRay(0.216, -0.050, 0.100, 0.216, 0.050, 0.100, true)) AddDist(2, 0.004);
            }

            // ---- position walk ----
            IMathUtility mu2 = (IMathUtility)swApp.GetMathUtility();
            object[] comps2 = (object[])assy.GetComponents(false);
            foreach (object co in comps2)
            {
                Component2 cc = (Component2)co;
                MathPoint pp = (MathPoint)mu2.CreatePoint(new double[] { 0, 0, 0 });
                pp = (MathPoint)pp.MultiplyTransform(cc.Transform2);
                double[] d = (double[])pp.ArrayData;
                Log("WALK " + cc.Name2 + " " + d[0].ToString("F1") + "," + d[1].ToString("F1") + "," + d[2].ToString("F1"));
            }

            adoc.ViewZoomtofit2();
            string savePath = "C:\\Users\\zgzgd\\Documents\\DSH\\\u7CBE\u82F1\u8054\u8D5B_\u8BBE\u8BA1\u5305\\CAD\\\u9F7F\u8F6E\u4F20\u52A8\u66F2\u67C4\u6ED1\u5757\u673A\u6784.SLDASM";
            int sv = adoc.SaveAs3(savePath, 0, 2);
            Log("save res=" + sv);
            adoc.ShowNamedView2("*Isometric", 7);
            System.Threading.Thread.Sleep(500);
            adoc.SaveBMP("C:\\Users\\zgzgd\\Documents\\DSH\\asm_view.bmp", 1280, 960);
            Log("done mates=" + mateCount);
        }
        catch (Exception ex)
        {
            Log("EX " + ex.GetType().Name + " " + ex.Message);
        }
    }
}
