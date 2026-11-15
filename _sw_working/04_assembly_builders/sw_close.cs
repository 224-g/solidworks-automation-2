using System;
using SolidWorks.Interop.sldworks;
class Close
{
    static void Main()
    {
        try
        {
            var app = (ISldWorks)Activator.CreateInstance(Type.GetTypeFromProgID("SldWorks.Application"));
            app.CloseAllDocuments(false);
            Console.WriteLine("CLOSED");
        }
        catch (Exception ex) { Console.WriteLine("EX " + ex.Message); }
    }
}
