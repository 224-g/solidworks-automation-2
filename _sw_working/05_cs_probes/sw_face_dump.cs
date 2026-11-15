// sw_face_dump.cs - dump every face (type + local bbox) of every component in a fresh assembly
using System;
using System.IO;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class FD
{
    static StreamWriter log = new StreamWriter("C:\\Users\\zgzgd\\Documents\\DSH\\sw_face_dump.log", false);
    static void L(string s) { log.WriteLine(s); log.Flush(); }

    static void Main()
    {
        try
        {
            ISldWorks app = (ISldWorks)Activator.CreateInstance(Type.GetTypeFromProgID("SldWorks.Application"));
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
            AssemblyDoc assy = (AssemblyDoc)ad;

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
            // NOTE: no rotations applied - dump the LOCAL (identity) faces; the R_x(-90) rotated parts
            // keep their local boxes; the mates run against the LOCAL frame faces so identity is what matters.
            ad.EditRebuild3();
            System.Threading.Thread.Sleep(500);

            object[] comps = (object[])assy.GetComponents(false);
            foreach (object co in comps)
            {
                Component2 c = (Component2)co;
                L("== " + c.Name2);
                Body2 b = (Body2)c.GetBody();
                object[] faces = (object[])b.GetFaces();
                foreach (object fo in faces)
                {
                    Face2 f = (Face2)fo;
                    Surface s = (Surface)f.GetSurface();
                    string kind = s.IsCylinder() ? "CYL" : (s.IsPlane() ? "PLN" : "OTH");
                    double[] bx2 = (double[])f.GetBox();
                    double astr = f.GetArea();
                    L(kind + " " + F(bx2[0]) + ".." + F(bx2[3]) + " " + F(bx2[1]) + ".." + F(bx2[4]) + " " + F(bx2[2]) + ".." + F(bx2[5]) + " A=" + astr);
                }
            }
            L("dump done");
        }
        catch (Exception ex)
        {
            L("EX " + ex.Message);
        }
    }
    static string F(double v) { return v.ToString("F4"); }
}
