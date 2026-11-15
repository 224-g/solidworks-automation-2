using System;
using System.IO;
using System.Runtime.InteropServices;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class RayRetest
{
    static StreamWriter log;
    static void Log(string s) { log.WriteLine(DateTime.Now.ToString("HH:mm:ss") + " " + s); log.Flush(); }

    static int Main()
    {
        log = new StreamWriter(@"C:\Users\zgzgd\Documents\DSH\sw_ray_retest.log", true);
        ISldWorks swApp = (ISldWorks)Marshal.GetActiveObject("SldWorks.Application");
        Log("attached " + swApp.RevisionNumber());
        ModelDoc2 md = (ModelDoc2)swApp.ActiveDoc;
        Log("doc = " + md.GetTitle());
        SelectionMgr sm = (SelectionMgr)md.SelectionManager;

        double[,] rays = {
            {0.2703, 0.02, -0.01, 0.2703, 0.02, 0.05},   // tower back (z=0)
            {0.22, 0.02, 0.006, 0.24, 0.02, 0.006},      // tower left (x=230.3)
            {0.09, 0.04, -0.01, 0.09, 0.04, 0.05},       // bracketA back (z=0)
            {0.12, 0.08205, 0.02, 0.18, 0.08205, 0.02},  // gear2 D-hole wall z20
            {0.12, 0.077, -0.01, 0.18, 0.077, -0.01},    // shaft2 OD z=-10 (WRONG z per analysis)
            {0.142, 0.0803, 0.024, 0.242, 0.0803, 0.024},// gear2 tip face (gear mate)
            {0.1503, 0.077, 0.044, 0.1203, 0.107, 0.044},// crank D-hole wall
            {0.23, 0.077, 0.03, 0.23, 0.077, 0.07},      // rod eye2 wall z30..70
            {0.2703, 0.077, -0.014, 0.2703, 0.077, 0.086},// rail inner (front-back)
            {0.2703, 0.06, 0.07, 0.2703, 0.14, 0.07},    // slider side y60..140
            {0.382, -0.002, -0.042, 0.442, -0.002, -0.042}, // bolt2 shank y=-2,z=-42
            {0.412, -0.01, -0.042, 0.412, 0.002, -0.042},   // nut2 hole wall
            {0.02, -0.01, 0.088, 0.02, 0.002, 0.088},    // nut3 hole wall z=88
        };
        string[] names = {
            "tower-back", "tower-left", "bracketA-back", "gear2-dhole-z20",
            "shaft2-OD-z-10", "gear2-tipface", "crank-dhole", "rod-eye2",
            "rail-inner", "slider-side", "bolt2-shank", "nut2-hole", "nut3-hole"
        };
        for (int i = 0; i < 13; i++)
        {
            md.ClearSelection2(true);
            bool b = md.Extension.SelectByRay(rays[i, 0], rays[i, 1], rays[i, 2], rays[i, 3] - rays[i, 0], rays[i, 4] - rays[i, 1], rays[i, 5] - rays[i, 2], 0.0001, (int)swSelectType_e.swSelFACES, false, 0, 0);
            Log(names[i] + " -> " + b + " n=" + sm.GetSelectedObjectCount2(-1));
        }
        log.Close();
        return 0;
    }
}
