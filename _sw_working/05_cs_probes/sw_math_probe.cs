using System;
using System.Runtime.InteropServices;
using SolidWorks.Interop.sldworks;

class SwMathProbe
{
    [STAThread]
    static int Main()
    {
        var log = new System.IO.StreamWriter("C:\\Users\\zgzgd\\Documents\\DSH\\sw_math_probe.log", true, System.Text.Encoding.UTF8);
        try
        {
            ISldWorks swApp = (ISldWorks)Marshal.GetActiveObject("SldWorks.Application");
            log.WriteLine("attach rev=" + swApp.RevisionNumber());
            IMathUtility mu = (IMathUtility)swApp.GetMathUtility();

            // my R_x(-90) row-major: {1,0,0,0, 0,0,1,0, 0,-1,0,0, 0,0,0,1}
            double[] rx = { 1, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1 };
            IMathTransform t1 = (IMathTransform)mu.CreateTransform(rx);
            double[] back = (double[])t1.ArrayData;
            log.WriteLine("rx roundtrip: " + string.Join(",", Array.ConvertAll(back, d => d.ToString("F3"))));

            // apply to point (1,2,3): expect (1,3,-2) if my convention is right
            IMathPoint p = (IMathPoint)mu.CreatePoint(new double[] { 1, 2, 3 });
            IMathPoint q = (IMathPoint)p.MultiplyTransform(t1);
            double[] qa = (double[])q.ArrayData;
            log.WriteLine("rx(1,2,3) = " + string.Join(",", Array.ConvertAll(qa, d => d.ToString("F3"))));

            // identity + translate test: translation in which slots?
            double[] tid = { 1, 0, 0, 0.5, 0, 1, 0, 0.25, 0, 0, 1, -0.75, 0, 0, 0, 1 };
            IMathTransform t2 = (IMathTransform)mu.CreateTransform(tid);
            IMathPoint p2 = (IMathPoint)mu.CreatePoint(new double[] { 1, 1, 1 });
            IMathPoint q2 = (IMathPoint)p2.MultiplyTransform(t2);
            double[] q2a = (double[])q2.ArrayData;
            log.WriteLine("tid(1,1,1) = " + string.Join(",", Array.ConvertAll(q2a, d => d.ToString("F3"))));

            // CreateTransformRotateAxis behavior
            IMathPoint axpt = (IMathPoint)mu.CreatePoint(new double[] { 0, 0, 0 });
            IMathVector axv = (IMathVector)mu.CreateVector(new double[] { 1, 0, 0 });
            IMathTransform tr = (IMathTransform)mu.CreateTransformRotateAxis(axpt, axv, Math.PI / 2);
            IMathPoint p3 = (IMathPoint)mu.CreatePoint(new double[] { 1, 2, 3 });
            IMathPoint q3 = (IMathPoint)p3.MultiplyTransform(tr);
            double[] q3a = (double[])q3.ArrayData;
            log.WriteLine("rotX90(1,2,3) = " + string.Join(",", Array.ConvertAll(q3a, d => d.ToString("F3"))));
            log.WriteLine("OK");
        }
        catch (Exception e)
        {
            log.WriteLine("EX " + e.GetType().Name + " " + e.Message);
        }
        log.Close();
        return 0;
    }
}
