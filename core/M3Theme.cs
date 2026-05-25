using Godot;
using System;

namespace Material3.Core;

/// <summary>
/// Represents a Material 3 design theme containing the standard color roles,
/// typography settings, and shape scales.
/// </summary>
[GlobalClass]
public partial class M3Theme : Resource
{
    // --- Color Roles (Light / Dark mapped) ---

    [ExportGroup("Color Roles")]
    [Export] public Color Primary { get; set; } = Color.FromHtml("#6750A4");
    [Export] public Color OnPrimary { get; set; } = Color.FromHtml("#FFFFFF");
    [Export] public Color PrimaryContainer { get; set; } = Color.FromHtml("#EADDFF");
    [Export] public Color OnPrimaryContainer { get; set; } = Color.FromHtml("#21005D");

    [Export] public Color Secondary { get; set; } = Color.FromHtml("#625B71");
    [Export] public Color OnSecondary { get; set; } = Color.FromHtml("#FFFFFF");
    [Export] public Color SecondaryContainer { get; set; } = Color.FromHtml("#E8DEF8");
    [Export] public Color OnSecondaryContainer { get; set; } = Color.FromHtml("#1D192B");

    [Export] public Color Tertiary { get; set; } = Color.FromHtml("#7D5260");
    [Export] public Color OnTertiary { get; set; } = Color.FromHtml("#FFFFFF");
    [Export] public Color TertiaryContainer { get; set; } = Color.FromHtml("#FFD8E4");
    [Export] public Color OnTertiaryContainer { get; set; } = Color.FromHtml("#31111D");

    [Export] public Color Surface { get; set; } = Color.FromHtml("#FEF7FF");
    [Export] public Color OnSurface { get; set; } = Color.FromHtml("#1D1B20");
    [Export] public Color SurfaceVariant { get; set; } = Color.FromHtml("#E7E0EC");
    [Export] public Color OnSurfaceVariant { get; set; } = Color.FromHtml("#49454F");

    [Export] public Color Outline { get; set; } = Color.FromHtml("#79747E");
    [Export] public Color OutlineVariant { get; set; } = Color.FromHtml("#CAC4D0");

    [Export] public Color Background { get; set; } = Color.FromHtml("#FEF7FF");
    [Export] public Color OnBackground { get; set; } = Color.FromHtml("#1D1B20");

    [Export] public Color Error { get; set; } = Color.FromHtml("#B3261E");
    [Export] public Color OnError { get; set; } = Color.FromHtml("#FFFFFF");

    [Export] public Color SurfaceContainerLowest { get; set; } = Color.FromHtml("#FFFFFF");

    // --- Shape Tokens ---

    [ExportGroup("Shape Corner Radii (dp)")]
    [Export] public float CornerNone { get; set; } = 0.0f;
    [Export] public float CornerExtraSmall { get; set; } = 4.0f;
    [Export] public float CornerSmall { get; set; } = 8.0f;
    [Export] public float CornerMedium { get; set; } = 12.0f;
    [Export] public float CornerLarge { get; set; } = 16.0f;
    [Export] public float CornerExtraLarge { get; set; } = 28.0f;

    /// <summary>
    /// Generates a complete Material 3 tonal palette from a single seed color.
    /// Maps the derived tones to light or dark mode roles.
    /// </summary>
    /// <param name="seedColor">The primary seed color.</param>
    /// <param name="isDark">True to generate dark mode colors, false for light mode.</param>
    public void GenerateFromSeed(Color seedColor, bool isDark)
    {
        // Convert to HSL
        ColorToHsl(seedColor, out float h, out float s, out float l);

        if (isDark)
        {
            Primary = HslToColor(h, s, 0.80f);
            OnPrimary = HslToColor(h, s, 0.20f);
            PrimaryContainer = HslToColor(h, s, 0.30f);
            OnPrimaryContainer = HslToColor(h, s, 0.90f);

            Secondary = HslToColor(h, s * 0.3f, 0.80f);
            OnSecondary = HslToColor(h, s * 0.3f, 0.20f);
            SecondaryContainer = HslToColor(h, s * 0.3f, 0.30f);
            OnSecondaryContainer = HslToColor(h, s * 0.3f, 0.90f);

            Tertiary = HslToColor(h + 0.15f, s * 0.5f, 0.80f);
            OnTertiary = HslToColor(h + 0.15f, s * 0.5f, 0.20f);
            TertiaryContainer = HslToColor(h + 0.15f, s * 0.5f, 0.30f);
            OnTertiaryContainer = HslToColor(h + 0.15f, s * 0.5f, 0.90f);

            Surface = HslToColor(h, s * 0.05f, 0.06f);
            OnSurface = HslToColor(h, s * 0.05f, 0.90f);
            SurfaceVariant = HslToColor(h, s * 0.1f, 0.22f);
            OnSurfaceVariant = HslToColor(h, s * 0.1f, 0.80f);

            Outline = HslToColor(h, s * 0.1f, 0.60f);
            OutlineVariant = HslToColor(h, s * 0.1f, 0.30f);

            Background = HslToColor(h, s * 0.05f, 0.06f);
            OnBackground = HslToColor(h, s * 0.05f, 0.90f);
        }
        else
        {
            Primary = HslToColor(h, s, 0.40f);
            OnPrimary = HslToColor(h, s, 1.00f);
            PrimaryContainer = HslToColor(h, s, 0.90f);
            OnPrimaryContainer = HslToColor(h, s, 0.10f);

            Secondary = HslToColor(h, s * 0.3f, 0.40f);
            OnSecondary = HslToColor(h, s * 0.3f, 1.00f);
            SecondaryContainer = HslToColor(h, s * 0.3f, 0.90f);
            OnSecondaryContainer = HslToColor(h, s * 0.3f, 0.10f);

            Tertiary = HslToColor(h + 0.15f, s * 0.5f, 0.40f);
            OnTertiary = HslToColor(h + 0.15f, s * 0.5f, 1.00f);
            TertiaryContainer = HslToColor(h + 0.15f, s * 0.5f, 0.90f);
            OnTertiaryContainer = HslToColor(h + 0.15f, s * 0.5f, 0.10f);

            Surface = HslToColor(h, s * 0.05f, 0.98f);
            OnSurface = HslToColor(h, s * 0.05f, 0.10f);
            SurfaceVariant = HslToColor(h, s * 0.1f, 0.90f);
            OnSurfaceVariant = HslToColor(h, s * 0.1f, 0.30f);

            Outline = HslToColor(h, s * 0.1f, 0.50f);
            OutlineVariant = HslToColor(h, s * 0.1f, 0.80f);

            Background = HslToColor(h, s * 0.05f, 0.98f);
            OnBackground = HslToColor(h, s * 0.05f, 0.10f);
        }
    }

    /// <summary>
    /// Helper method to convert RGB color to HSL (Hue, Saturation, Lightness).
    /// </summary>
    public static void ColorToHsl(Color color, out float h, out float s, out float l)
    {
        float r = color.R;
        float g = color.G;
        float b = color.B;

        float max = Math.Max(r, Math.Max(g, b));
        float min = Math.Min(r, Math.Min(g, b));

        h = s = l = (max + min) / 2.0f;

        if (max == min)
        {
            h = s = 0.0f; // achromatic
        }
        else
        {
            float d = max - min;
            s = l > 0.5f ? d / (2.0f - max - min) : d / (max + min);

            if (max == r)
            {
                h = (g - b) / d + (g < b ? 6.0f : 0.0f);
            }
            else if (max == g)
            {
                h = (b - r) / d + 2.0f;
            }
            else if (max == b)
            {
                h = (r - g) / d + 4.0f;
            }

            h /= 6.0f;
        }
    }

    /// <summary>
    /// Helper method to convert HSL (Hue, Saturation, Lightness) back to a standard RGB Color.
    /// </summary>
    private static Color HslToColor(float h, float s, float l)
    {
        // Wrap Hue
        h = h % 1.0f;
        if (h < 0.0f) h += 1.0f;

        s = Math.Clamp(s, 0.0f, 1.0f);
        l = Math.Clamp(l, 0.0f, 1.0f);

        float r, g, b;

        if (s == 0.0f)
        {
            r = g = b = l; // Gray scale
        }
        else
        {
            float q = l < 0.5f ? l * (1.0f + s) : l + s - (l * s);
            float p = (2.0f * l) - q;

            r = HueToRgb(p, q, h + (1.0f / 3.0f));
            g = HueToRgb(p, q, h);
            b = HueToRgb(p, q, h - (1.0f / 3.0f));
        }

        return new Color(r, g, b);
    }

    private static float HueToRgb(float p, float q, float t)
    {
        if (t < 0.0f) t += 1.0f;
        if (t > 1.0f) t -= 1.0f;
        if (t < 1.0f / 6.0f) return p + ((q - p) * 6.0f * t);
        if (t < 1.0f / 2.0f) return q;
        if (t < 2.0f / 3.0f) return p + ((q - p) * ((2.0f / 3.0f) - t) * 6.0f);
        return p;
    }
}
