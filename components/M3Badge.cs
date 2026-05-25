using Godot;
using System;
using Material3.Core;

namespace Material3.Components;

/// <summary>
/// A native Godot Control representing a Material 3 Badge.
/// Renders as a small red notification circle (dot) or text-pill.
/// </summary>
[Tool]
[GlobalClass]
public partial class M3Badge : Control
{
    private string _text = "";
    private Label _label;

    private M3Theme CurrentTheme
    {
        get
        {
            if (M3ThemeManager.Instance == null)
            {
                return new M3Theme(); // Fail-safe fallback in tool mode
            }
            return M3ThemeManager.Instance.CurrentTheme;
        }
    }

    /// <summary>
    /// Badge numeric/character text. If empty, renders as a simple 6dp dot.
    /// </summary>
    [Export]
    public string Text
    {
        get => _text;
        set
        {
            _text = value;
            if (_label != null) _label.Text = _text;
            ResetLayout();
        }
    }

    public override void _Ready()
    {
        _label = new Label();
        _label.Text = _text;
        _label.MouseFilter = MouseFilterEnum.Ignore;
        _label.HorizontalAlignment = HorizontalAlignment.Center;
        _label.VerticalAlignment = VerticalAlignment.Center;
        AddChild(_label);

        ResetLayout();
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

    private void ResetLayout()
    {
        if (_label == null) return;

        float scaleFactor = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;

        if (string.IsNullOrEmpty(_text))
        {
            CustomMinimumSize = new Vector2(6, 6) * scaleFactor;
            _label.Visible = false;
        }
        else
        {
            // Number pill dimensions
            CustomMinimumSize = new Vector2(16, 16) * scaleFactor;
            _label.Visible = true;
            _label.SetAnchorsPreset(LayoutPreset.FullRect);
        }

        ApplyTheme();
    }

    private void ApplyTheme()
    {
        if (CurrentTheme == null || _label == null) return;

        float scaleFactor = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;

        LabelSettings labelSettings = new LabelSettings();
        labelSettings.FontColor = CurrentTheme.OnError;
        labelSettings.FontSize = (int)(10 * scaleFactor); // M3 Badge text scale
        _label.LabelSettings = labelSettings;

        QueueRedraw();
    }

    public override void _Draw()
    {
        if (CurrentTheme == null) return;

        StyleBoxFlat styleBox = new StyleBoxFlat();
        styleBox.BgColor = CurrentTheme.Error;
        styleBox.SetCornerRadiusAll((int)(Size.Y / 2.0f)); // Pill rounded ends

        DrawStyleBox(styleBox, new Rect2(Vector2.Zero, Size));
    }
}
