using GdUnit4;
using Godot;
using Material3.Core;
using static GdUnit4.Assertions;

namespace Material3.Test;

/// <summary>
/// Unit tests for the M3Theme color token configuration and tonal palette generation.
/// </summary>
[TestSuite]
public class M3ThemeTest
{
    [TestCase]
    public void TestDefaultConstructor()
    {
        var theme = new M3Theme();
        
        // Assert that default colors are initialized and not empty/black by default
        AssertObject(theme).IsNotNull();
        AssertThat(theme.Primary.ToHtml()).IsEqual("6750a4");
        AssertThat(theme.OnPrimary.ToHtml()).IsEqual("ffffff");
    }

    [TestCase]
    public void TestLightModeTonalGeneration()
    {
        var theme = new M3Theme();
        Color seed = Color.FromHtml("#6750A4");
        
        theme.GenerateFromSeed(seed, isDark: false);

        // Verify primary color lightness matches light mode standard (approx. 0.40f)
        M3Theme.ColorToHsl(theme.Primary, out _, out _, out float primaryL);
        AssertFloat(primaryL).IsBetween(0.35f, 0.45f);

        // OnPrimary should be bright white (lightness 1.0f)
        M3Theme.ColorToHsl(theme.OnPrimary, out _, out _, out float onPrimaryL);
        AssertFloat(onPrimaryL).IsBetween(0.95f, 1.05f);

        // PrimaryContainer should be soft light (lightness 0.90f)
        M3Theme.ColorToHsl(theme.PrimaryContainer, out _, out _, out float primaryContainerL);
        AssertFloat(primaryContainerL).IsBetween(0.85f, 0.95f);
    }

    [TestCase]
    public void TestDarkModeTonalGeneration()
    {
        var theme = new M3Theme();
        Color seed = Color.FromHtml("#6750A4");
        
        theme.GenerateFromSeed(seed, isDark: true);

        // Verify primary color lightness matches dark mode standard (approx. 0.80f)
        M3Theme.ColorToHsl(theme.Primary, out _, out _, out float primaryL);
        AssertFloat(primaryL).IsBetween(0.75f, 0.85f);

        // OnPrimary should be dark (lightness 0.20f)
        M3Theme.ColorToHsl(theme.OnPrimary, out _, out _, out float onPrimaryL);
        AssertFloat(onPrimaryL).IsBetween(0.15f, 0.25f);

        // Surface should be dark background (lightness 0.06f)
        M3Theme.ColorToHsl(theme.Surface, out _, out _, out float surfaceL);
        AssertFloat(surfaceL).IsBetween(0.04f, 0.08f);
    }
}
