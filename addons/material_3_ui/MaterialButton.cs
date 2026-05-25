using Godot;

[Tool] // This makes the script run in the editor!
[GlobalClass, Icon("res://icon.svg")]
public partial class MaterialButton : Button 
{
    private MaterialThemeManager _themeManager;

    public override void _Ready()
    {
        // 1. Safely find the Theme Manager Autoload
        // We use GetNodeOrNull in case the user hasn't enabled the plugin yet
        _themeManager = GetNodeOrNull<MaterialThemeManager>("/root/MaterialThemeManager");

        if (_themeManager != null)
        {
            // 2. Subscribe to the ThemeChanged signal
            _themeManager.ThemeChanged += ApplyTheme;

            // 3. Apply the theme immediately when the button is created
            ApplyTheme();
        }
    }

    public override void _ExitTree()
    {
        // Always unsubscribe from signals when the node is destroyed 
        // to prevent C# memory leaks!
        if (_themeManager != null)
        {
            _themeManager.ThemeChanged -= ApplyTheme;
        }
    }

    private void ApplyTheme()
    {
        // Safety check in case the manager is missing
        if (_themeManager == null) return;

        // Apply the OnPrimary color to the text
        AddThemeColorOverride("font_color", _themeManager.OnPrimary);
        AddThemeColorOverride("font_focus_color", _themeManager.OnPrimary);
        AddThemeColorOverride("font_hover_color", _themeManager.OnPrimary);

        // Create a Material Design style background using StyleBoxFlat
        var normalStyle = new StyleBoxFlat
        {
            BgColor = _themeManager.Primary,
            // Material 3 buttons typically have fully rounded pill shapes
            CornerRadiusTopLeft = 20, 
            CornerRadiusTopRight = 20,
            CornerRadiusBottomLeft = 20,
            CornerRadiusBottomRight = 20
        };

        // Apply the background to the "normal" state
        AddThemeStyleboxOverride("normal", normalStyle);

        // You can duplicate and adjust the StyleBox for hover/pressed states
        var hoverStyle = (StyleBoxFlat)normalStyle.Duplicate();
        hoverStyle.BgColor = _themeManager.Primary.Lightened(0.1f); // Slightly lighter on hover
        AddThemeStyleboxOverride("hover", hoverStyle);
        
        var pressedStyle = (StyleBoxFlat)normalStyle.Duplicate();
        pressedStyle.BgColor = _themeManager.Primary.Darkened(0.1f); // Slightly darker on press
        AddThemeStyleboxOverride("pressed", pressedStyle);
    }
}
