using System;
using System.IO;
using System.Runtime.InteropServices;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class CompWalk
{
    static StreamWriter log;
    static void Log(string s) { log.WriteLine(DateTime.Now.ToString("HH:mm:ss") + " " + s); log.Flush(); }

    static int Main()
    {
        log = new StreamWriter(@"C:\Users\zgzgd\Documents\DSH\sw_comp_walk.log", true);
        ISldWorks swApp = (ISldWorks)Marshal.GetActiveObject("SldWorks.Application");
        Log("attached");
        ModelDoc2 md = (ModelDoc2)swApp.ActiveDoc;
        AssemblyDoc assy = (AssemblyDoc)md;
        Log("doc = " + md.GetTitle());
        IMathUtility mu = (IMathUtility)swApp.GetMathUtility();
        object[] comps = (object[])assy.GetComponents(false);
        Log("comp count = " + (comps == null ? -1 : comps.Length));
        if (comps != null)
        {
            foreach (object o in comps)
            {
                Component2 c = (Component2)o;
                MathPoint p = (MathPoint)mu.CreatePoint(new double[] { 0, 0, 0 });
                MathTransform t = (MathTransform)c.Transform2;
                p = (MathPoint)p.MultiplyTransform(t);
                double[] a = (double[])p.ArrayData;
                Log("comp " + c.Name2 + " pos=(" + Math.Round(a[0] * 1000, 1) + "," + Math.Round(a[1] * 1000, 1) + "," + Math.Round(a[2] * 1000, 1) + ")");
            }
        }
        log.Close();
        return 0;
    }
}
