using Godot;
using System;
using Material3.Core;

namespace Material3.Components;

public enum M3CardType
{
    Elevated,
    Filled,
    Outlined
}

/// <summary>
/// A native Godot PanelContainer representing a Material 3 Card.
/// Acts as a container for arbitrary controls, applying spec styling.
/// </summary>
[Tool]
[GlobalClass]
public partial class M3Card : PanelContainer
{
    private M3CardType _cardType = M3CardType.Elevated;

    private M3Theme CurrentTheme
    {
        get
        {
            if (M3ThemeManager.Instance == null)
            {
                return new M3Theme(); // Fail-safe default fallback in tool mode
            }
            return M3ThemeManager.Instance.CurrentTheme;
        }
    }

    [Export]
    public M3CardType CardType
    {
        get => _cardType;
        set
        {
            _cardType = value;
            ApplyCardTheme();
        }
    }

    public override void _EnterTree()
    {
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged += ApplyCardTheme;
        }
    }

    public override void _ExitTree()
    {
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged -= ApplyCardTheme;
        }
    }

    public override void _Ready()
    {
        ApplyCardTheme();
    }

    private void ApplyCardTheme()
    {
        if (CurrentTheme == null) return;

        float scaleFactor = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;

        StyleBoxFlat styleBox = new StyleBoxFlat();
        styleBox.SetCornerRadiusAll((int)(CurrentTheme.CornerMedium * scaleFactor)); // Standard M3 Card corners (12dp) scaled

        Color bgColor = CurrentTheme.Surface;
        float borderWidth = 0.0f;
        Color borderColor = Color.FromHtml("#00000000");
        float shadowSize = 0.0f;

        switch (_cardType)
        {
            case M3CardType.Elevated:
                bgColor = CurrentTheme.Surface;
                shadowSize = 1.0f * scaleFactor; // Elevation Level 1 scaled
                break;
            case M3CardType.Filled:
                bgColor = CurrentTheme.SurfaceVariant;
                break;
            case M3CardType.Outlined:
                bgColor = CurrentTheme.Surface;
                borderWidth = 1.0f * scaleFactor;
                borderColor = CurrentTheme.OutlineVariant;
                break;
        }

        styleBox.BgColor = bgColor;
        styleBox.BorderWidthLeft = (int)borderWidth;
        styleBox.BorderWidthTop = (int)borderWidth;
        styleBox.BorderWidthRight = (int)borderWidth;
        styleBox.BorderWidthBottom = (int)borderWidth;
        styleBox.BorderColor = borderColor;

        if (shadowSize > 0.0f)
        {
            styleBox.ShadowColor = new Color(0, 0, 0, 0.15f);
            styleBox.ShadowSize = (int)shadowSize;
            styleBox.ShadowOffset = new Vector2(0, (int)shadowSize);
        }

        // Apply custom StyleBoxFlat to PanelContainer
        AddThemeStyleboxOverride("panel", styleBox);
    }
}
