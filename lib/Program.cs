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

        // Unzip files that have the GZip marker. Convert the
        // stream into a MemoryStream from a GZipStream because
        // GZipStream is not able to supply length or eof indication,
        // nor can it be repositioned. This makes it hard to support
        // it with the Ruby IO class.
        private class GZipDecoder : IStreamDecoder {
            public Stream Decode(Stream stream) {
                const int bufsize = 32768;
                BinaryReader breader = new BinaryReader(stream);
                byte[] bbuffer = breader.ReadBytes(2);
                stream.Position = 0;
                if ((bbuffer[0] == 31) && (bbuffer[1] == 139)) {
                    using (GZipStream zipStream = new GZipStream(stream, CompressionMode.Decompress)) {
                        MemoryStream ms = new MemoryStream();
                        using (BinaryReader zipreader = new BinaryReader(zipStream)) {
                            while (true) {
                                bbuffer = zipreader.ReadBytes(bufsize);
                                ms.Write(bbuffer, 0, bbuffer.Length);
                                if (bbuffer.Length < bufsize) {
                                    break;
                                }
                            }
                        }
                        stream.Close();
                        ms.Position = 0;
                        return ms;
                    }
                }
                return stream;
            }
        }
    }
}

