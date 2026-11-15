using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class MateProbe
{
    static StreamWriter log;
    static void Log(string s) { log.WriteLine(DateTime.Now.ToString("HH:mm:ss") + " " + s); log.Flush(); }

    static bool Ray(ModelDoc2 md, SelectionMgr sm, double x, double y, double z, double dx, double dy, double dz, bool append)
    {
        md.ClearSelection2(!append);
        bool b = md.Extension.SelectByRay(x, y, z, dx, dy, dz, 0.0001, (int)swSelectType_e.swSelFACES, append, 0, 0);
        Log("ray (" + x + "," + y + "," + z + ") d(" + dx + "," + dy + "," + dz + ") append=" + append + " -> " + b + " n=" + sm.GetSelectedObjectCount2(-1));
        return b;
    }

    static bool Plane(ModelDoc2 md, string name, bool append)
    {
        bool b = md.Extension.SelectByID2(name, "PLANE", 0, 0, 0, append, 0, null, 0);
        Log("plane " + name + " append=" + append + " -> " + b);
        return b;
    }

    static int Main()
    {
        log = new StreamWriter(@"C:\Users\zgzgd\Documents\DSH\sw_mate_probe.log", true);
        ISldWorks swApp = (ISldWorks)Marshal.GetActiveObject("SldWorks.Application");
        Log("attached " + swApp.RevisionNumber());
        ModelDoc2 md = (ModelDoc2)swApp.ActiveDoc;
        AssemblyDoc assy = (AssemblyDoc)md;
        Log("doc " + md.GetTitle() + " type=" + md.GetType());
        SelectionMgr sm = (SelectionMgr)md.SelectionManager;

        // find asm plane names
        string pf = "", pt = "", pr = "";
        Feature f = (Feature)md.FirstFeature();
        int n = 0;
        while (f != null)
        {
            if (f.GetTypeName2() == "RefPlane") { if (n == 0) pf = f.Name; else if (n == 1) pt = f.Name; else if (n == 2) pr = f.Name; n++; }
            f = (Feature)f.GetNextFeature();
        }
        Log("planes " + pf + "/" + pt + "/" + pr);

        for (int attempt = 1; attempt <= 3; attempt++)
        {
            Log("-- attempt " + attempt + ": plate-bottom + " + pt);
            md.ClearSelection2(true);
            Ray(md, sm, 0.216, -0.05, 0.1, 0, 1, 0, false);
            Plane(md, pt, true);
            int err = 0;
            Mate2 m = (Mate2)assy.AddMate5((int)swMateType_e.swMateDISTANCE, 0, false, 0, 0, 0, 0, 0, 0, 0, 0, false, false, 0, out err);
            Log("AddMate5 dist -> " + (m == null ? "NULL" : "FEATURE") + " err=" + err);
            if (m != null) break;
            Thread.Sleep(1500);
            md.EditRebuild3();
        }

        // try a second pair: bracket bottom + plate top
        for (int attempt = 1; attempt <= 2; attempt++)
        {
            Log("-- attempt " + attempt + ": bracket-bottom + plate-top");
            md.ClearSelection2(true);
            Ray(md, sm, 0.090, 0.05, 0.006, 0, 1, 0, false);
            Ray(md, sm, 0.090, 0.05, 0.006, 0, -1, 0, true);
            int err = 0;
            Mate2 m = (Mate2)assy.AddMate5((int)swMateType_e.swMateCOINCIDENT, 0, false, 0, 0, 0, 0, 0, 0, 0, 0, false, false, 0, out err);
            Log("AddMate5 coinc -> " + (m == null ? "NULL" : "FEATURE") + " err=" + err);
            if (m != null) break;
            Thread.Sleep(1500);
            md.EditRebuild3();
        }
        log.Close();
        return 0;
    }
}
