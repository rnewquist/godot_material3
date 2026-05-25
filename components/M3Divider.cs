using Godot;
using System;
using Material3.Core;

namespace Material3.Components;

/// <summary>
/// A native Godot Control representing a Material 3 Divider.
/// Separates content visually using a thin line token.
/// </summary>
[Tool]
[GlobalClass, Icon("res://icon.svg")]
public partial class M3Divider : Control
{
    private float _thickness = 1.0f;

    [Export]
    public float Thickness
    {
        get => _thickness;
        set { _thickness = value; QueueRedraw(); }
    }

    private M3Theme CurrentTheme
    {
        get
        {
            if (M3ThemeManager.Instance == null)
            {
                return new M3Theme();
            }
            return M3ThemeManager.Instance.CurrentTheme;
        }
    }

    public override void _Ready()
    {
        SizeFlagsHorizontal = SizeFlags.ExpandFill;
        ApplyTheme();
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged += ApplyTheme;
        }
    }

    public override void _ExitTree()
    {
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged -= ApplyTheme;
        }
    }

    private void ApplyTheme()
    {
        float scaleFactor = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;
        CustomMinimumSize = new Vector2(0, (int)(_thickness * scaleFactor));
        QueueRedraw();
    }

    public override void _Draw()
    {
        if (CurrentTheme == null) return;

        float scaleFactor = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;
        float scaledThickness = _thickness * scaleFactor;
        
        float centerY = Size.Y / 2.0f;
        Vector2 start = new Vector2(0, centerY);
        Vector2 end = new Vector2(Size.X, centerY);
        
        DrawLine(start, end, CurrentTheme.OutlineVariant, scaledThickness);
    }
}
