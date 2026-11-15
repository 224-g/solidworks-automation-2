// sw_face_probe.cs - dump faces of plate/bracket/shaft1 with whatever compiles
using System;
using System.IO;
using System.Runtime.InteropServices;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class P
{
    static StreamWriter log = new StreamWriter("C:\\Users\\zgzgd\\Documents\\DSH\\sw_face_probe.log", true);
    static void L(string s) { log.WriteLine(DateTime.Now.ToString("HH:mm:ss") + " " + s); log.Flush(); }

    static void Main()
    {
        try
        {
            Type t = Type.GetTypeFromProgID("SldWorks.Application");
            ISldWorks app = (ISldWorks)Activator.CreateInstance(t);
            ModelDoc2 adoc = (ModelDoc2)app.ActiveDoc;
            L("doc=" + (adoc == null ? "NULL" : adoc.GetTitle()));
            AssemblyDoc assy = (AssemblyDoc)adoc;
            object[] comps = (object[])assy.GetComponents(false);
            foreach (object co in comps)
            {
                Component2 c = (Component2)co;
                string nm = c.Name2;
                if (nm != "plate-1" && nm != "bracket-1" && nm != "shaft1-1") continue;
                L("=== " + nm + " ===");
                try
                {
                    Body2 body = (Body2)c.GetBody();
                    if (body == null) { L("  body NULL"); continue; }
                    object[] faces = (object[])body.GetFaces();
                    L("  faces=" + faces.Length);
                    foreach (object fo in faces)
                    {
                        Face2 f = (Face2)fo;
                        Surface s = (Surface)f.GetSurface();
                        double area = f.GetArea();
                        double[] box = (double[])f.GetBox();
                        double[] ctr = new double[3];
                        if (box != null)
                        {
                            ctr[0] = (box[0] + box[3]) / 2; ctr[1] = (box[1] + box[4]) / 2; ctr[2] = (box[2] + box[5]) / 2;
                        }
                        L("  " + (s.IsPlane() ? "PLANE" : (s.IsCylinder() ? "CYL" : "OTHER")) +
                          " area=" + area.ToString("F1") +
                          " box=" + (box == null ? "NULL" : box[0].ToString("F3") + "," + box[1].ToString("F3") + "," + box[2].ToString("F3") + "|" + box[3].ToString("F3") + "," + box[4].ToString("F3") + "," + box[5].ToString("F3")));
                    }
                }
                catch (Exception ex)
                {
                    L("  body EX " + ex.GetType().Name + " " + ex.Message);
                }
            }
            L("done");
        }
        catch (Exception ex)
        {
            L("EX " + ex.GetType().Name + " " + ex.Message);
        }
    }
}
