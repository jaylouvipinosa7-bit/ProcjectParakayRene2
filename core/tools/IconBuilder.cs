using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

namespace IconBuilder
{
    class Program
    {
        [DllImport("shell32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);

        const uint SHCNE_ASSOCCHANGED = 0x08000000;
        const uint SHCNF_IDLIST = 0x0000;

        static void Main(string[] args)
        {
            string sourcePng = args.Length > 0 ? args[0] : @"c:\Users\pc\Downloads\ano na\groudon_renearn.png";
            if (!File.Exists(sourcePng)) {
                Console.WriteLine("Source PNG not found: " + sourcePng);
                return;
            }

            Console.WriteLine("Loading source: " + sourcePng);
            using (Bitmap src = new Bitmap(sourcePng))
            {
                byte[] icoData = BuildIco(src);

                string[] outputs = new string[] {
                    @"c:\Users\pc\Downloads\ano na\app_icon.ico",
                    @"c:\Users\pc\Downloads\ano na\renearn.ico",
                    @"c:\Users\pc\Downloads\ano na\core\app_icon.ico",
                    @"c:\Users\pc\Downloads\ano na\core\favicon.ico"
                };

                foreach (var outPath in outputs)
                {
                    File.WriteAllBytes(outPath, icoData);
                    Console.WriteLine("Wrote " + outPath + " (" + icoData.Length + " bytes)");
                }
            }

            // Tell Windows Explorer to refresh its icon cache
            try {
                SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, IntPtr.Zero, IntPtr.Zero);
                Console.WriteLine("Notified Windows Shell of icon association change.");
            } catch { }

            Console.WriteLine("Done!");
        }

        static byte[] BuildIco(Bitmap src)
        {
            // Standard Windows icon dimensions
            int[] sizes = new int[] { 256, 128, 64, 48, 32, 16 };
            byte[][] imagesData = new byte[sizes.Length][];
            bool[] isPng = new bool[sizes.Length];

            for (int i = 0; i < sizes.Length; i++)
            {
                int sz = sizes[i];
                using (Bitmap resized = ResizeImage(src, sz, sz))
                {
                    if (sz == 256)
                    {
                        // 256x256 is stored as PNG
                        using (MemoryStream ms = new MemoryStream())
                        {
                            resized.Save(ms, ImageFormat.Png);
                            imagesData[i] = ms.ToArray();
                            isPng[i] = true;
                        }
                    }
                    else
                    {
                        // Sub-256 sizes stored as standard uncompressed 32bpp DIB
                        imagesData[i] = CreateDibData(resized);
                        isPng[i] = false;
                    }
                }
            }

            using (MemoryStream icoStream = new MemoryStream())
            using (BinaryWriter bw = new BinaryWriter(icoStream))
            {
                // ICONDIR header
                bw.Write((ushort)0); // Reserved
                bw.Write((ushort)1); // Type 1 = Icon
                bw.Write((ushort)sizes.Length); // Image count

                int offset = 6 + (sizes.Length * 16);

                // ICONDIRENTRY list
                for (int i = 0; i < sizes.Length; i++)
                {
                    int sz = sizes[i];
                    byte w = (sz >= 256) ? (byte)0 : (byte)sz;
                    byte h = (sz >= 256) ? (byte)0 : (byte)sz;

                    bw.Write(w);
                    bw.Write(h);
                    bw.Write((byte)0); // Color count
                    bw.Write((byte)0); // Reserved
                    bw.Write((ushort)1); // Color planes
                    bw.Write((ushort)32); // Bits per pixel
                    bw.Write((uint)imagesData[i].Length); // Bytes in resource
                    bw.Write((uint)offset); // Offset

                    offset += imagesData[i].Length;
                }

                // Image data blocks
                for (int i = 0; i < sizes.Length; i++)
                {
                    bw.Write(imagesData[i]);
                }

                bw.Flush();
                return icoStream.ToArray();
            }
        }

        static byte[] CreateDibData(Bitmap bmp)
        {
            int w = bmp.Width;
            int h = bmp.Height;

            int andRowBytes = ((w + 31) / 32) * 4;
            int andMaskSize = andRowBytes * h;
            int xorSize = w * h * 4;
            int totalSize = 40 + xorSize + andMaskSize;

            byte[] data = new byte[totalSize];
            using (MemoryStream ms = new MemoryStream(data))
            using (BinaryWriter bw = new BinaryWriter(ms))
            {
                // BITMAPINFOHEADER (40 bytes)
                bw.Write((uint)40); // biSize
                bw.Write((int)w); // biWidth
                bw.Write((int)(h * 2)); // biHeight (XOR + AND mask height)
                bw.Write((ushort)1); // biPlanes
                bw.Write((ushort)32); // biBitCount
                bw.Write((uint)0); // biCompression (BI_RGB)
                bw.Write((uint)xorSize); // biSizeImage
                bw.Write((int)0); // biXPelsPerMeter
                bw.Write((int)0); // biYPelsPerMeter
                bw.Write((uint)0); // biClrUsed
                bw.Write((uint)0); // biClrImportant

                // Lock bits to read BGRA bottom-up
                BitmapData bmpData = bmp.LockBits(
                    new Rectangle(0, 0, w, h),
                    ImageLockMode.ReadOnly,
                    PixelFormat.Format32bppArgb
                );

                byte[] rowBuffer = new byte[w * 4];
                // Bottom-up: row h-1 down to 0
                for (int y = h - 1; y >= 0; y--)
                {
                    IntPtr rowPtr = new IntPtr(bmpData.Scan0.ToInt64() + (y * bmpData.Stride));
                    Marshal.Copy(rowPtr, rowBuffer, 0, w * 4);
                    bw.Write(rowBuffer);
                }

                bmp.UnlockBits(bmpData);

                // AND mask: all 0 bytes for full alpha transparency support
                byte[] andMask = new byte[andMaskSize];
                bw.Write(andMask);

                bw.Flush();
            }

            return data;
        }

        static Bitmap ResizeImage(Bitmap src, int width, int height)
        {
            Bitmap dest = new Bitmap(width, height, PixelFormat.Format32bppArgb);
            using (Graphics g = Graphics.FromImage(dest))
            {
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.CompositingQuality = CompositingQuality.HighQuality;
                g.Clear(Color.Transparent);
                g.DrawImage(src, 0, 0, width, height);
            }
            return dest;
        }
    }
}
