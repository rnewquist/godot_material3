using Godot;
using System;
using Material3.Core;

namespace Material3.Components;

public enum M3TextFieldStyle
{
    Filled,
    Outlined
}

/// <summary>
/// A native Godot Control representing a Material 3 TextField.
/// Leverages LineEdit composition with dynamic floating label vectors.
/// </summary>
[Tool]
[GlobalClass, Icon("res://icon.svg")]
public partial class M3TextField : M3BaseComponent
{
    private string _text = "";
    private string _labelText = "Label";
    private string _placeholderText = "";
    private string _errorText = "";
    private M3TextFieldStyle _textFieldStyle = M3TextFieldStyle.Outlined;

    private LineEdit _lineEdit;
    private Label _floatingLabel;
    private float _labelFloatPercent = 0.0f; // 0.0f = resting, 1.0f = floated

    [Signal]
    public delegate void TextChangedEventHandler(string newText);

    [Export]
    public string Text
    {
        get => _text;
        set
        {
            _text = value;
            if (_lineEdit != null && _lineEdit.Text != _text)
            {
                _lineEdit.Text = _text;
            }
            AnimateFloatLabel();
            EmitSignal(SignalName.TextChanged, _text);
        }
    }

    [Export]
    public string LabelText
    {
        get => _labelText;
        set
        {
            _labelText = value;
            if (_floatingLabel != null) _floatingLabel.Text = _labelText;
        }
    }

    [Export]
    public string PlaceholderText
    {
        get => _placeholderText;
        set
        {
            _placeholderText = value;
            if (_lineEdit != null) _lineEdit.PlaceholderText = _placeholderText;
        }
    }

    [Export]
    public string ErrorText
    {
        get => _errorText;
        set
        {
            _errorText = value;
            QueueRedraw();
        }
    }

    [Export]
    public M3TextFieldStyle TextFieldStyle
    {
        get => _textFieldStyle;
        set
        {
            _textFieldStyle = value;
            ApplyTheme();
        }
    }

    /// <summary>
    /// Driven by Tweens to update position.
    /// Implements Property Redraw Pattern by calling QueueRedraw.
    /// </summary>
    private float LabelFloatPercent
    {
        get => _labelFloatPercent;
        set
        {
            _labelFloatPercent = value;
            QueueRedraw();
            UpdateLabelLayout();
        }
    }

    public override void _Ready()
    {
        CustomMinimumSize = new Vector2(200, 56);

        // 1. Setup LineEdit child
        _lineEdit = new LineEdit();
        _lineEdit.Text = _text;
        _lineEdit.PlaceholderText = _placeholderText;
        _lineEdit.Flat = true;
        _lineEdit.FocusMode = FocusModeEnum.Click;
        _lineEdit.MouseFilter = MouseFilterEnum.Pass;
        
        // Remove native border styles to make it completely transparent
        _lineEdit.AddThemeStyleboxOverride("normal", new StyleBoxEmpty());
        _lineEdit.AddThemeStyleboxOverride("focus", new StyleBoxEmpty());
        _lineEdit.AddThemeStyleboxOverride("read_only", new StyleBoxEmpty());

        _lineEdit.TextChanged += (txt) => { Text = txt; };
        _lineEdit.FocusEntered += () => { AnimateFloatLabel(); QueueRedraw(); };
        _lineEdit.FocusExited += () => { AnimateFloatLabel(); QueueRedraw(); };
        AddChild(_lineEdit);

        // 2. Setup Label child
        _floatingLabel = new Label();
        _floatingLabel.Text = _labelText;
        _floatingLabel.MouseFilter = MouseFilterEnum.Ignore;
        AddChild(_floatingLabel);

        base._Ready();

        ApplyTheme();
    }

    private void ResetLayout()
    {
        if (_lineEdit == null) return;

        // Position LineEdit inside the text field padding
        _lineEdit.SetAnchorsPreset(LayoutPreset.FullRect);
        
        if (_textFieldStyle == M3TextFieldStyle.Filled)
        {
            _lineEdit.OffsetLeft = 16 * ScaleFactor;
            _lineEdit.OffsetRight = -16 * ScaleFactor;
            _lineEdit.OffsetTop = 20 * ScaleFactor;
            _lineEdit.OffsetBottom = -4 * ScaleFactor;
        }
        else
        {
            _lineEdit.OffsetLeft = 16 * ScaleFactor;
            _lineEdit.OffsetRight = -16 * ScaleFactor;
            _lineEdit.OffsetTop = 16 * ScaleFactor;
            _lineEdit.OffsetBottom = -16 * ScaleFactor;
        }

        AnimateFloatLabel(instant: true);
    }

    private void AnimateFloatLabel(bool instant = false)
    {
        if (_lineEdit == null || _floatingLabel == null) return;

        bool shouldFloat = _lineEdit.HasFocus() || !string.IsNullOrEmpty(_text);
        float target = shouldFloat ? 1.0f : 0.0f;

        if (instant)
        {
            LabelFloatPercent = target;
        }
        else
        {
            var tween = CreateTween();
            tween.TweenProperty(this, "LabelFloatPercent", target, 0.15f)
                 .SetTrans(Tween.TransitionType.Quad)
                 .SetEase(Tween.EaseType.Out);
        }
    }

    private void UpdateLabelLayout()
    {
        if (_floatingLabel == null || CurrentTheme == null) return;

        // Label Large: size 16px, pos y = centered
        // Label Small: size 12px, pos y = floated at top (-8px for Outlined, 6px for Filled)
        float targetSize = Mathf.Lerp(16.0f, 12.0f, _labelFloatPercent) * ScaleFactor;
        float targetY = 0.0f;

        if (_textFieldStyle == M3TextFieldStyle.Filled)
        {
            targetY = Mathf.Lerp((Size.Y - 20 * ScaleFactor) / 2.0f, 6.0f * ScaleFactor, _labelFloatPercent);
        }
        else
        {
            targetY = Mathf.Lerp((Size.Y - 20 * ScaleFactor) / 2.0f, -8.0f * ScaleFactor, _labelFloatPercent);
        }

        _floatingLabel.Position = new Vector2(16.0f * ScaleFactor, targetY);
        
        LabelSettings labelSettings = new LabelSettings();
        labelSettings.FontSize = (int)targetSize;
        
        Color labelColor = CurrentTheme.OnSurfaceVariant;
        if (_lineEdit != null && _lineEdit.HasFocus())
        {
            labelColor = CurrentTheme.Primary;
        }
        if (!string.IsNullOrEmpty(_errorText))
        {
            labelColor = CurrentTheme.Error;
        }
        
        labelSettings.FontColor = labelColor;
        _floatingLabel.LabelSettings = labelSettings;
    }

    protected override void ApplyTheme()
    {
        if (CurrentTheme == null || _lineEdit == null) return;

        CustomMinimumSize = new Vector2(200, 56) * ScaleFactor;
        ResetLayout();

        _lineEdit.AddThemeColorOverride("font_color", CurrentTheme.OnSurface);
        _lineEdit.AddThemeColorOverride("font_placeholder_color", CurrentTheme.OnSurfaceVariant);
        
        int fontSize = (int)(16 * ScaleFactor);
        _lineEdit.AddThemeFontSizeOverride("font_size", fontSize);
        
        UpdateLabelLayout();
        QueueRedraw();
    }

    public override void _Draw()
    {
        if (CurrentTheme == null) return;

        bool hasFocus = _lineEdit != null && _lineEdit.HasFocus();
        bool hasError = !string.IsNullOrEmpty(_errorText);

        Color borderCol = CurrentTheme.Outline;
        float borderWidth = 1.0f * ScaleFactor;

        if (hasFocus)
        {
            borderCol = CurrentTheme.Primary;
            borderWidth = 2.0f * ScaleFactor;
        }
        if (hasError)
        {
            borderCol = CurrentTheme.Error;
            borderWidth = 2.0f * ScaleFactor;
        }

        if (_textFieldStyle == M3TextFieldStyle.Filled)
        {
            // Draw filled card background (M3 Filled Text Field corner radii: top corners 4dp, bottom corners 0dp)
            StyleBoxFlat styleBox = new StyleBoxFlat();
            styleBox.BgColor = CurrentTheme.SurfaceVariant;
            styleBox.SetCornerRadiusAll(0);
            styleBox.CornerRadiusTopLeft = (int)(CurrentTheme.CornerExtraSmall * ScaleFactor);
            styleBox.CornerRadiusTopRight = (int)(CurrentTheme.CornerExtraSmall * ScaleFactor);

            // Draw underlying border strip
            styleBox.BorderWidthBottom = (int)borderWidth;
            styleBox.BorderColor = borderCol;

            DrawStyleBox(styleBox, new Rect2(Vector2.Zero, Size));
        }
        else
        {
            // Draw vector outlines
            StyleBoxFlat styleBox = new StyleBoxFlat();
            styleBox.DrawCenter = false;
            styleBox.SetCornerRadiusAll((int)(CurrentTheme.CornerExtraSmall * ScaleFactor));
            styleBox.BorderWidthLeft = (int)borderWidth;
            styleBox.BorderWidthTop = (int)borderWidth;
            styleBox.BorderWidthRight = (int)borderWidth;
            styleBox.BorderWidthBottom = (int)borderWidth;
            styleBox.BorderColor = borderCol;

            // If label is floated, we carve out a cutout in the outline border!
            if (_labelFloatPercent > 0.0f)
            {
                // To keep vector drawing sharp, we calculate the outline cutout mathematically.
                // Draw outline box parts manually using DrawLine / DrawArc to create a clean visual gap.
                float cutoutWidth = _floatingLabel.Size.X + 8 * ScaleFactor; // Padding gap
                float cutoutLeft = 12.0f * ScaleFactor;
                float cutoutRight = cutoutLeft + cutoutWidth;

                // Border top fragments
                DrawLine(new Vector2(0, 0), new Vector2(cutoutLeft, 0), borderCol, borderWidth);
                DrawLine(new Vector2(cutoutRight, 0), new Vector2(Size.X, 0), borderCol, borderWidth);
                // Border right, bottom, left
                DrawLine(new Vector2(Size.X, 0), new Vector2(Size.X, Size.Y), borderCol, borderWidth);
                DrawLine(new Vector2(Size.X, Size.Y), new Vector2(0, Size.Y), borderCol, borderWidth);
                DrawLine(new Vector2(0, Size.Y), new Vector2(0, 0), borderCol, borderWidth);
            }
            else
            {
                DrawStyleBox(styleBox, new Rect2(Vector2.Zero, Size));
            }
        }
    }
}
