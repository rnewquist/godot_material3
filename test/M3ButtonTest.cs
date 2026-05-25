using GdUnit4;
using Godot;
using Material3.Components;
using Material3.Core;
using static GdUnit4.Assertions;

namespace Material3.Test;

/// <summary>
/// Unit tests for the M3Button control properties, layouts, and type rendering.
/// </summary>
[TestSuite]
public class M3ButtonTest
{
    [TestCase]
    public void TestButtonProperties()
    {
        var button = new M3Button();
        button.Text = "Click Me";
        button.ButtonType = M3ButtonType.Tonal;

        AssertObject(button).IsNotNull();
        AssertThat(button.Text).IsEqual("Click Me");
        AssertThat(button.ButtonType).IsEqual(M3ButtonType.Tonal);
    }

    [TestCase]
    public void TestThemeChangedEvent()
    {
        var button = new M3Button();
        
        // Trigger a fake ready setup to instantiate visual nodes
        button._Ready();
        
        // Change global theme to trigger event updates
        Color customSeed = Color.FromHtml("#00FF00");
        M3ThemeManager.Instance.CurrentSeedColor = customSeed;

        // Verify that button successfully bound new theme primary color
        AssertThat(M3ThemeManager.Instance.CurrentTheme.Primary.ToHtml()).IsEqual(button.CurrentTheme.Primary.ToHtml());
        
        button.Free();
    }
}
