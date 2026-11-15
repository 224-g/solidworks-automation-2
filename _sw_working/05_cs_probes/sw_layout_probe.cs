using System;
using System.IO;
using System.Runtime.InteropServices;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class LayoutProbe
{
    static StreamWriter log;
    static void Log(string s) { log.WriteLine(DateTime.Now.ToString("HH:mm:ss") + " " + s); log.Flush(); }

    static double[] Pt(IMathUtility mu, MathTransform t, double x, double y, double z)
    {
        MathPoint p = (MathPoint)mu.CreatePoint(new double[] { x, y, z });
        MathPoint q = (MathPoint)p.MultiplyTransform(t);
        return (double[])q.ArrayData;
    }

    static int Main()
    {
        log = new StreamWriter(@"C:\Users\zgzgd\Documents\DSH\sw_layout_probe.log", true);
        ISldWorks swApp = (ISldWorks)Marshal.GetActiveObject("SldWorks.Application");
        IMathUtility mu = (IMathUtility)swApp.GetMathUtility();

        // C = identity rotation + translation (0.02, 0.017, -0.042), scale 1
        double[] ca = new double[16];
        ca[0] = 1; ca[4] = 1; ca[8] = 1; ca[12] = 1;
        ca[9] = 0.02; ca[10] = 0.017; ca[11] = -0.042;
        MathTransform C = (MathTransform)mu.CreateTransform(ca);
        double[] c0 = Pt(mu, C, 0, 0, 0);
        Log("C(0,0,0) = (" + Math.Round(c0[0] * 1000, 2) + "," + Math.Round(c0[1] * 1000, 2) + "," + Math.Round(c0[2] * 1000, 2) + ")");

        // R = R_x(-90) about origin
        MathTransform R = (MathTransform)mu.CreateTransformRotateAxis(mu.CreatePoint(new double[] { 0, 0, 0 }), mu.CreateVector(new double[] { 1, 0, 0 }), -Math.PI / 2);
        double[] r1 = Pt(mu, R, 0, 0, 1);
        Log("R_x-90(0,0,1) = (" + Math.Round(r1[0], 3) + "," + Math.Round(r1[1], 3) + "," + Math.Round(r1[2], 3) + ") expect (0,1,0)");

        // T1 = C.Multiply(R): applies R first then C?
        MathTransform T1 = (MathTransform)C.Multiply(R);
        double[] t1a = Pt(mu, T1, 0, 0, 0);
        double[] t1b = Pt(mu, T1, 0, 0, 0.012);
        Log("C*R(0,0,0) = (" + Math.Round(t1a[0] * 1000, 2) + "," + Math.Round(t1a[1] * 1000, 2) + "," + Math.Round(t1a[2] * 1000, 2) + ")");
        Log("C*R(0,0,0.012) = (" + Math.Round(t1b[0] * 1000, 2) + "," + Math.Round(t1b[1] * 1000, 2) + "," + Math.Round(t1b[2] * 1000, 2) + ") expect (20,29, -42)");

        // T2 = R.Multiply(C)
        MathTransform T2 = (MathTransform)R.Multiply(C);
        double[] t2a = Pt(mu, T2, 0, 0, 0);
        double[] t2b = Pt(mu, T2, 0, 0, 0.012);
        Log("R*C(0,0,0) = (" + Math.Round(t2a[0] * 1000, 2) + "," + Math.Round(t2a[1] * 1000, 2) + "," + Math.Round(t2a[2] * 1000, 2) + ")");
        Log("R*C(0,0,0.012) = (" + Math.Round(t2b[0] * 1000, 2) + "," + Math.Round(t2b[1] * 1000, 2) + "," + Math.Round(t2b[2] * 1000, 2) + ")");
        log.Close();
        return 0;
    }
}
