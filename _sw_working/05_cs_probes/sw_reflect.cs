// sw_reflect.cs - list Surface + Face2 + Body2 members from the interop (compile-time ref)
using System;
using SolidWorks.Interop.sldworks;

class R
{
    static void Main()
    {
        foreach (Type t in new Type[] { typeof(Surface), typeof(Face2), typeof(Body2) })
        {
            Console.WriteLine("=== " + t.FullName + " ===");
            foreach (System.Reflection.MethodInfo m in t.GetMethods())
            {
                if (m.Name.StartsWith("get_") || m.Name.StartsWith("set_")) continue;
                Console.WriteLine("  " + m.ReturnType.Name + " " + m.Name + "(" + string.Join(", ", Array.ConvertAll(m.GetParameters(), p => p.ParameterType.Name + " " + p.Name)) + ")");
            }
        }
    }
}
