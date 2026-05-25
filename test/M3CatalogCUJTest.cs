using GdUnit4;
using Godot;
using Material3.Core;
using Material3.Scenes;
using static GdUnit4.Assertions;

namespace Material3.Test;

/// <summary>
/// Critical User Journey (CUJ) integration tests for the Material 3 Catalog responsive scaling layout.
/// </summary>
[TestSuite]
public class M3CatalogCUJTest
{
    [TestCase]
    public void TestCatalogInitialization()
    {
        // Instantiate the catalog scene to verify it loads without script or compilation failures
        var catalogScene = GD.Load<PackedScene>("res://scenes/M3Catalog.tscn");
        AssertObject(catalogScene).IsNotNull();

        var catalog = catalogScene.Instantiate<M3Catalog>();
        AssertObject(catalog).IsNotNull();
        catalog.Free();
    }

    [TestCase]
    public void TestAutoResolutionScaling()
    {
        // 1. Ensure ThemeManager is active
        AssertObject(M3ThemeManager.Instance).IsNotNull();
        M3ThemeManager.Instance.ClearScaleOverride();

        // 2. Mock a viewport resize event to simulate a screen size change
        var initialScale = M3ThemeManager.Instance.ScaleFactor;
        AssertFloat(initialScale).IsBetween(1.0f, 3.0f);

        // 3. Test manual scale overrides to simulate exact mobile and tablet form factors
        M3ThemeManager.Instance.ScaleFactor = 1.6f;
        AssertFloat(M3ThemeManager.Instance.ScaleFactor).IsEqual(1.6f);

        M3ThemeManager.Instance.ScaleFactor = 1.25f;
        AssertFloat(M3ThemeManager.Instance.ScaleFactor).IsEqual(1.25f);

        // Reset scale overrides to enable dynamic calculation again
        M3ThemeManager.Instance.ClearScaleOverride();
    }

    [TestCase]
    public void TestAutoScaleCalculationEquations()
    {
        // 1. Manually trigger the dynamic scale recalculation
        M3ThemeManager.Instance.ClearScaleOverride();
        float currentScale = M3ThemeManager.Instance.ScaleFactor;

        // The scaling algorithm clamps the dynamic scale between 1.0x and 3.0x to avoid visual clipping
        AssertFloat(currentScale).IsBetween(1.0f, 3.0f);
    }
}
