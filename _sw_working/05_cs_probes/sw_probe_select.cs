using System;
using SolidWorks.Interop.sldworks;

class Probe
{
    static void Main()
    {
        Face2 f = null;
        // try each selection method signature; the compiler reports which exist
        // f.Select(false);
        // f.Select2(false, 0);
        // f.Select3(false, null);
        // f.Select4(false, null);
        Feature ft = null;
        // string n = ft.Name;
        // string t1 = ft.GetTypeName();
        // string t2 = ft.GetTypeName2;
        // object nx = ft.GetNextFeature();
        Console.WriteLine("probe");
    }
}
