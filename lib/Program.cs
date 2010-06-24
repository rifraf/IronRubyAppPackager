using System;
using System.IO;
using System.IO.Compression;
using System.Text;
using IREmbeddedApp;
using SERFS;

namespace PROJECTNAMEConsole {
    class Program {
        static int Main(string[] args) {
            int exitcode = 0;
            try {
                EmbeddedRuby er = new EmbeddedRuby();
                er.Decoder = new GZipDecoder();
                er.Mount("App");
                exitcode = er.Run("PROJECTNAME.rb", args);
            } catch (Exception e) {
                Console.WriteLine(e.Message);
            }
            Console.WriteLine();
            return exitcode;
        }

        private class GZipDecoder : IStreamDecoder {
            public Stream Decode(Stream stream) {
                BinaryReader breader = new BinaryReader(stream);
                byte[] bbuffer = breader.ReadBytes(2);
                stream.Position = 0;
                if ((bbuffer[0] == 31) && (bbuffer[1] == 139)) {
                    stream = new GZipStream(stream, CompressionMode.Decompress, true);
                }

                StreamReader reader =  new StreamReader(stream);
                return new MemoryStream(Encoding.UTF8.GetBytes(reader.ReadToEnd()));
            }
        }
    }
}

