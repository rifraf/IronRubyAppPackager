using System;
using IREmbeddedApp;

namespace IronRubyConsole {
    class Program {
        static int Main(string[] args) {
            int exitcode = 0;
            try {
                EmbeddedRuby er = new EmbeddedRuby();
                er.Mount("App");
                exitcode = er.Run("PROJECTNAME.rb", args);
            } catch (Exception e) {
                Console.WriteLine(e.Message);
            }
            Console.WriteLine();
            return exitcode;
        }
    }
}

