Add-Type -AssemblyName System.Drawing

$code = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections.Generic;

public class ZombieCutter {
    public static void Cut(string srcPath, string outPath, int minXInner, int maxXInner, int minYInner, int maxYInner, int textYStart) {
        using (Bitmap src = new Bitmap(srcPath)) {
            int w = src.Width;
            int h = src.Height;
            bool[,] isBg = new bool[w, h];
            bool[,] visited = new bool[w, h];
            Queue<Point> q = new Queue<Point>();

            Func<Color, int, int, bool> isGrassOrFrame = (c, x, y) => {
                // Outside inner window or at text area
                if (x < minXInner || x > maxXInner || y < minYInner || y >= textYStart) return true;
                if (y > maxYInner) return true;

                // Frame colors (dark purple/grey stone)
                if ((x < minXInner + 10 || x > maxXInner - 10 || y < minYInner + 10 || y > maxYInner - 10) &&
                    (c.R < 75 && c.G < 75 && c.B < 75)) return true;
                if (c.B > c.G + 5 && c.R > c.G + 5 && c.G < 80) return true;

                // Bright grass: high G, low B
                if (c.G > c.B + 35 && c.G > c.R + 15) return true;

                // Dark grass / shadow: green dominant over blue, low blue
                if (c.G > c.B + 20 && c.G > c.R && c.B < 55) return true;
                if (c.G > 35 && c.G > c.B + 18 && c.R < 80 && c.B < 45) return true;

                // Grass flower / yellow fleck
                if (c.R > 140 && c.G > 140 && c.B < 80 && y > 150) return true;

                return false;
            };

            // Seed outer border
            for (int x = 0; x < w; x++) {
                for (int y = 0; y < h; y++) {
                    if (x <= 1 || x >= w - 2 || y <= 1 || y >= h - 2 || y >= textYStart) {
                        visited[x, y] = true;
                        isBg[x, y] = true;
                        q.Enqueue(new Point(x, y));
                    }
                }
            }

            int[] dx = { 0, 0, 1, -1, 1, -1, 1, -1 };
            int[] dy = { 1, -1, 0, 0, 1, -1, -1, 1 };

            while (q.Count > 0) {
                Point p = q.Dequeue();
                for (int i = 0; i < 8; i++) {
                    int nx = p.X + dx[i];
                    int ny = p.Y + dy[i];
                    if (nx >= 0 && nx < w && ny >= 0 && ny < h && !visited[nx, ny]) {
                        if (isGrassOrFrame(src.GetPixel(nx, ny), nx, ny)) {
                            visited[nx, ny] = true;
                            isBg[nx, ny] = true;
                            q.Enqueue(new Point(nx, ny));
                        }
                    }
                }
            }

            // Also check inner pockets (e.g. between horse legs)
            for (int x = minXInner; x <= maxXInner; x++) {
                for (int y = minYInner; y <= maxYInner; y++) {
                    if (!visited[x, y]) {
                        Color c = src.GetPixel(x, y);
                        // Clear grass inside inner pocket
                        if (c.G > c.B + 40 && c.G > c.R + 20) {
                            visited[x, y] = true;
                            isBg[x, y] = true;
                            q.Enqueue(new Point(x, y));
                            while (q.Count > 0) {
                                Point p = q.Dequeue();
                                for (int i = 0; i < 8; i++) {
                                    int nx = p.X + dx[i];
                                    int ny = p.Y + dy[i];
                                    if (nx >= minXInner && nx <= maxXInner && ny >= minYInner && ny <= maxYInner && !visited[nx, ny]) {
                                        if (isGrassOrFrame(src.GetPixel(nx, ny), nx, ny)) {
                                            visited[nx, ny] = true;
                                            isBg[nx, ny] = true;
                                            q.Enqueue(new Point(nx, ny));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Find character bounding box
            int minCharX = w, maxCharX = 0, minCharY = h, maxCharY = 0;
            for (int x = 0; x < w; x++) {
                for (int y = 0; y < h; y++) {
                    if (!isBg[x, y]) {
                        if (x < minCharX) minCharX = x;
                        if (x > maxCharX) maxCharX = x;
                        if (y < minCharY) minCharY = y;
                        if (y > maxCharY) maxCharY = y;
                    }
                }
            }

            int charW = Math.Max(1, maxCharX - minCharX + 1);
            int charH = Math.Max(1, maxCharY - minCharY + 1);
            int pad = 10;
            int outW = charW + pad * 2;
            int outH = charH + pad * 2;
            int size = Math.Max(outW, outH);

            using (Bitmap res = new Bitmap(size, size, PixelFormat.Format32bppArgb)) {
                using (Graphics g = Graphics.FromImage(res)) {
                    g.Clear(Color.Transparent);
                }
                int offsetX = (size - charW) / 2;
                int offsetY = (size - charH) / 2;

                for (int cy = 0; cy < charH; cy++) {
                    for (int cx = 0; cx < charW; cx++) {
                        int srcX = minCharX + cx;
                        int srcY = minCharY + cy;
                        if (!isBg[srcX, srcY]) {
                            res.SetPixel(offsetX + cx, offsetY + cy, src.GetPixel(srcX, srcY));
                        }
                    }
                }
                res.Save(outPath, ImageFormat.Png);
            }
        }
    }
}
"@

Add-Type -TypeDefinition $code -ReferencedAssemblies "System.Drawing"

[ZombieCutter]::Cut('C:\Users\pc\.gemini\antigravity-ide\brain\db22d434-58fe-4322-b582-e28e83369379\.user_uploaded\media_1792247079104.png', 'c:\Users\pc\Downloads\ano na\core\images\game-icons\pvz\spawn_black_horse.png', 56, 255, 42, 235, 245)
[ZombieCutter]::Cut('C:\Users\pc\.gemini\antigravity-ide\brain\db22d434-58fe-4322-b582-e28e83369379\.user_uploaded\media_1792247147622.png', 'c:\Users\pc\Downloads\ano na\core\images\game-icons\pvz\spawn_super_black_horse.png', 55, 260, 42, 248, 255)

Write-Host "Cutouts created successfully!"
