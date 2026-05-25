using Godot;
using System;
using Material3.Core;

namespace Material3.Components;

/// <summary>
/// M3 Button variations conforming to Material Design 3 guidelines.
/// </summary>
public enum M3ButtonType
{
    Filled,
    Elevated,
    Tonal,
    Outlined,
    Text
}

/// <summary>
/// A native Godot Control representing a Material 3 Button with dynamic styles,
/// state layers, and fluid vector layouts.
/// </summary>
[Tool]
[GlobalClass]
public partial class M3Button : M3BaseComponent
{
    private string _text = "Button";
    private M3ButtonType _buttonType = M3ButtonType.Filled;
    private Texture2D _iconTexture;

    private HBoxContainer _container;
    private TextureRect _iconRect;
    private Label _label;

    /// <summary>
    /// Event fired when the button is clicked and released.
    /// </summary>
    [Signal]
    public delegate void PressedEventHandler();

    /// <summary>
    /// The button text.
    /// </summary>
    [Export]
    public string Text
    {
        get => _text;
        set
        {
            _text = value;
            if (_label != null) _label.Text = _text;
            UpdateLayout();
        }
    }

    /// <summary>
    /// The Material 3 Button style type.
    /// </summary>
    [Export]
    public M3ButtonType ButtonType
    {
        get => _buttonType;
        set
        {
            _buttonType = value;
            ApplyTheme();
        }
    }

    /// <summary>
    /// Optional leading icon texture.
    /// </summary>
    [Export]
    public Texture2D IconTexture
    {
        get => _iconTexture;
        set
        {
            _iconTexture = value;
            if (_iconRect != null) _iconRect.Texture = _iconTexture;
            UpdateLayout();
        }
    }

    public override void _Ready()
    {
        // Construct visual children
        _container = new HBoxContainer();
        _container.Alignment = BoxContainer.AlignmentMode.Center;
        _container.MouseFilter = MouseFilterEnum.Ignore;
        _container.SetAnchorsPreset(LayoutPreset.FullRect);
        AddChild(_container);

        _iconRect = new TextureRect();
        _iconRect.CustomMinimumSize = new Vector2(18, 18);
        _iconRect.ExpandMode = TextureRect.ExpandModeEnum.IgnoreSize;
        _iconRect.StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered;
        _iconRect.MouseFilter = MouseFilterEnum.Ignore;
        _iconRect.Texture = _iconTexture;
        _container.AddChild(_iconRect);

        _label = new Label();
        _label.Text = _text;
        _label.MouseFilter = MouseFilterEnum.Ignore;
        _container.AddChild(_label);

        // Set default minimum heights
        CustomMinimumSize = new Vector2(100, 40);

        // Complete base ready wiring (attaches ripple, states)
        base._Ready();

        UpdateLayout();
    }

    public override void _GuiInput(InputEvent @event)
    {
        base._GuiInput(@event);

        if (@event is InputEventMouseButton mouseEvent && mouseEvent.ButtonIndex == MouseButton.Left)
        {
            if (!mouseEvent.Pressed && IsHoveredState())
            {
                EmitSignal(SignalName.Pressed);
            }
        }
    }

    /// <summary>
    /// Update layout alignments and padding margins based on text and icon states.
    /// </summary>
    private void UpdateLayout()
    {
        if (_container == null || _iconRect == null || _label == null) return;

        // Toggle icon visibility
        _iconRect.Visible = _iconTexture != null;

        // Apply standard M3 button spacing margins
        int leftMargin = (int)((_iconTexture != null ? 16 : 24) * ScaleFactor);
        int rightMargin = (int)(24 * ScaleFactor);

        _container.AddThemeConstantOverride("separation", (int)(8 * ScaleFactor));
        
        // Dynamic horizontal layout configuration
        _container.SetAnchorsPreset(LayoutPreset.FullRect);
        _container.OffsetLeft = leftMargin;
        _container.OffsetRight = -rightMargin;
    }

    protected override void ApplyTheme()
    {
        if (CurrentTheme == null || _label == null || _iconRect == null || RippleNode == null) return;

        // Apply DPI ScaleFactor to sizes dynamically
        CustomMinimumSize = new Vector2(100, 40) * ScaleFactor;
        _iconRect.CustomMinimumSize = new Vector2(18, 18) * ScaleFactor;
        UpdateLayout();

        // 1. Resolve Color Tokens based on Button Type
        Color bgColor = Color.FromHtml("#00000000");
        Color textColor = CurrentTheme.Primary;
        float borderWidth = 0.0f;
        Color borderColor = Color.FromHtml("#00000000");
        float shadowSize = 0.0f;

        switch (_buttonType)
        {
            case M3ButtonType.Filled:
                bgColor = CurrentTheme.Primary;
                textColor = CurrentTheme.OnPrimary;
                break;
            case M3ButtonType.Elevated:
                bgColor = CurrentTheme.Surface;
                textColor = CurrentTheme.Primary;
                shadowSize = 1.0f;
                break;
            case M3ButtonType.Tonal:
                bgColor = CurrentTheme.SecondaryContainer;
                textColor = CurrentTheme.OnSecondaryContainer;
                break;
            case M3ButtonType.Outlined:
                bgColor = Color.FromHtml("#00000000");
                textColor = CurrentTheme.Primary;
                borderWidth = 1.0f;
                borderColor = CurrentTheme.Outline;
                break;
            case M3ButtonType.Text:
                bgColor = Color.FromHtml("#00000000");
                textColor = CurrentTheme.Primary;
                break;
        }

        // Apply visual updates to child Label settings
        LabelSettings labelSettings = new LabelSettings();
        labelSettings.FontColor = textColor;
        labelSettings.FontSize = (int)(14 * ScaleFactor); // M3 Label Large scaled
        _label.LabelSettings = labelSettings;

        // Setup Ripple visual modulation
        _iconRect.SelfModulate = textColor;
        RippleNode.RippleColor = textColor;

        // Force a procedural canvas draw
        QueueRedraw();
    }

    public override void _Draw()
    {
        if (CurrentTheme == null) return;

        // 2. Compute dynamic StyleBoxFlat properties procedurally
        StyleBoxFlat styleBox = new StyleBoxFlat();
        
        // Rounded corners conforming to M3 Full corners
        float cornerRadius = Size.Y / 2.0f;
        styleBox.SetCornerRadiusAll((int)cornerRadius);

        Color bgColor = Color.FromHtml("#00000000");
        Color textColor = CurrentTheme.Primary;
        float borderWidth = 0.0f;
        Color borderColor = Color.FromHtml("#00000000");
        float shadowSize = 0.0f;

        switch (_buttonType)
        {
            case M3ButtonType.Filled:
                bgColor = CurrentTheme.Primary;
                textColor = CurrentTheme.OnPrimary;
                break;
            case M3ButtonType.Elevated:
                bgColor = CurrentTheme.Surface;
                textColor = CurrentTheme.Primary;
                shadowSize = IsHoveredState() ? 3.0f : 1.0f;
                break;
            case M3ButtonType.Tonal:
                bgColor = CurrentTheme.SecondaryContainer;
                textColor = CurrentTheme.OnSecondaryContainer;
                break;
            case M3ButtonType.Outlined:
                bgColor = Color.FromHtml("#00000000");
                textColor = CurrentTheme.Primary;
                borderWidth = 1.0f * ScaleFactor;
                borderColor = CurrentTheme.Outline;
                break;
            case M3ButtonType.Text:
                bgColor = Color.FromHtml("#00000000");
                textColor = CurrentTheme.Primary;
                break;
        }

        // Apply interactive state layer opacities
        if (IsHoveredState())
        {
            bgColor = bgColor.Blend(new Color(textColor.R, textColor.G, textColor.B, 0.08f));
        }
        if (IsPressedState())
        {
            bgColor = bgColor.Blend(new Color(textColor.R, textColor.G, textColor.B, 0.12f));
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
            styleBox.ShadowSize = (int)(shadowSize * ScaleFactor);
            styleBox.ShadowOffset = new Vector2(0, (int)(shadowSize * ScaleFactor));
        }

        // Draw background box
        DrawStyleBox(styleBox, new Rect2(Vector2.Zero, Size));

        // Draw vector-level Focus Ring if state is active
        if (IsFocusedState())
        {
            StyleBoxFlat focusBox = new StyleBoxFlat();
            focusBox.DrawCenter = false;
            focusBox.SetCornerRadiusAll((int)(cornerRadius + 3 * ScaleFactor));
            focusBox.BorderWidthLeft = (int)(2 * ScaleFactor);
            focusBox.BorderWidthTop = (int)(2 * ScaleFactor);
            focusBox.BorderWidthRight = (int)(2 * ScaleFactor);
            focusBox.BorderWidthBottom = (int)(2 * ScaleFactor);
            focusBox.BorderColor = CurrentTheme.Primary;

            // Offset outline slightly outwards
            DrawStyleBox(focusBox, new Rect2(new Vector2(-3, -3) * ScaleFactor, Size + new Vector2(6, 6) * ScaleFactor));
        }
    }
}
