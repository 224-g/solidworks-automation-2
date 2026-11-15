using System;
using System.IO;
using System.Runtime.InteropServices;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class PickProbe
{
    static StreamWriter log;
    static void Log(string s) { log.WriteLine(DateTime.Now.ToString("HH:mm:ss") + " " + s); log.Flush(); }

    static void Try(ModelDoc2 md, SelectionMgr sm, string tag, double x, double y, double z, double dx, double dy, double dz)
    {
        md.ClearSelection2(true);
        bool b = md.Extension.SelectByRay(x, y, z, dx, dy, dz, 0.0001, (int)swSelectType_e.swSelFACES, false, 0, 0);
        Log(tag + " sel=" + b + " count=" + sm.GetSelectedObjectCount2(-1));
    }

    static int Main()
    {
        log = new StreamWriter(@"C:\Users\zgzgd\Documents\DSH\sw_pick_probe.log", true);
        ISldWorks swApp = null;
        try { swApp = (ISldWorks)Marshal.GetActiveObject("SldWorks.Application"); }
        catch (Exception ex) { Log("attach FAIL " + ex.Message); return 1; }
        Log("attached " + swApp.RevisionNumber());
        ModelDoc2 md = (ModelDoc2)swApp.ActiveDoc;
        Log("active doc = " + md.GetTitle() + " type=" + md.GetType());
        SelectionMgr sm = (SelectionMgr)md.SelectionManager;

        // assembly-space rays (plate global: x 0..432, y 0..12, z -95..235; bracketA global: x 45..135, y 12..102, z 0..12)
        Try(md, sm, "A plate-bottom  (0.216,-0.05,0.1) -> +y", 0.216, -0.05, 0.1, 0, 1, 0);
        Try(md, sm, "B plate-top     (0.216, 0.05, 0.1) -> -y", 0.216, 0.05, 0.1, 0, -1, 0);
        Try(md, sm, "C plate-front   (0.216, 0.006, 0.3) -> -z", 0.216, 0.006, 0.3, 0, 0, -1);
        Try(md, sm, "D bracket-bottom(0.090, 0.05, 0.006) -> +y", 0.090, 0.05, 0.006, 0, 1, 0);
        Try(md, sm, "E plate-front2  (0.1, 0.006, 0.3) -> -z", 0.1, 0.006, 0.3, 0, 0, -1);
        log.Close();
        return 0;
    }
}
