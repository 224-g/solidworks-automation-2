using System;
using System.Runtime.InteropServices;
using SolidWorks.Interop.sldworks;
using SolidWorks.Interop.swconst;

class SwProbe
{
    static void Main(string[] args)
    {
        string log = "C:\\Users\\zgzgd\\Documents\\DSH\\sw_cs_probe.log";
        Append(log, "start");
        try
        {
            object swObj = Marshal.GetActiveObject("SldWorks.Application");
            Append(log, "got obj " + swObj.GetType().Name);
            ISldWorks swApp = (ISldWorks)swObj;
            Append(log, "attached rev=" + swApp.RevisionNumber());
            swApp.CloseAllDocuments(true);
            System.Threading.Thread.Sleep(500);
            IModelDoc2 doc = (IModelDoc2)swApp.NewDocument("C:\\ProgramData\\SolidWorks\\SOLIDWORKS 2024\\templates\\gb_assembly.asmdot", 0, 0, 0);
            System.Threading.Thread.Sleep(1000);
            Append(log, "newasm type=" + doc.GetType());
            IAssemblyDoc assy = (IAssemblyDoc)doc;
            string full = "C:\\Users\\zgzgd\\Documents\\DSH\\sw_parts8\\plate.SLDPRT";
            Component2 comp = (Component2)assy.AddComponent5(full, (int)swAddComponentConfigOptions_e.swAddComponentConfigOptions_CurrentSelectedConfig, "", false, "", 0.1, 0, 0);
            if (comp == null)
            {
                Append(log, "add5-fullpath NULL");
                Component2 comp2 = (Component2)assy.AddComponent5("plate.SLDPRT", (int)swAddComponentConfigOptions_e.swAddComponentConfigOptions_CurrentSelectedConfig, "", false, "", 0.1, 0, 0);
                if (comp2 == null) Append(log, "add5-name NULL");
                else Append(log, "add5-name OK " + comp2.Name2);
                IModelDoc2 partDoc = (IModelDoc2)swApp.OpenDoc(full, 1);
                Append(log, "partdoc open=" + (partDoc != null));
                Component2 comp3 = (Component2)assy.AddComponent5("plate.SLDPRT", (int)swAddComponentConfigOptions_e.swAddComponentConfigOptions_CurrentSelectedConfig, "", false, "", 0.2, 0, 0);
                if (comp3 == null) Append(log, "add5-open-name NULL");
                else Append(log, "add5-open-name OK " + comp3.Name2);
            }
            else
            {
                MathTransform mt = (MathTransform)comp.Transform2;
                Append(log, "add5 OK name=" + comp.Name2 + " a9=" + ((double[])mt.ArrayData)[9]);
            }
            Append(log, "done");
        }
        catch (Exception ex)
        {
            string hr = "";
            try { hr = " hr=0x" + Marshal.GetHRForException(ex).ToString("X8"); } catch { }
            Append(log, "EX " + ex.GetType().FullName + hr + " " + ex.Message);
        }
    }

    static void Append(string path, string msg)
    {
        try
        {
            System.IO.File.AppendAllText(path, DateTime.Now.ToString("HH:mm:ss") + " " + msg + System.Environment.NewLine);
        }
        catch { }
    }
}
