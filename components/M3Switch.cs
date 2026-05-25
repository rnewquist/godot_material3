using Godot;
using System;
using Material3.Core;

namespace Material3.Components;

/// <summary>
/// A native Godot Control representing a Material 3 Switch toggle.
/// Animates state transitions smoothly using vector math and properties.
/// </summary>
[Tool]
[GlobalClass, Icon("res://icon.svg")]
public partial class M3Switch : M3BaseComponent
{
    private bool _checked = false;
    private float _thumbPosition = 0.0f; // 0.0f = Left, 1.0f = Right
    private float _thumbScale = 1.0f; // Tween factor representing thumb growth when checked

    /// <summary>
    /// Event/Signal emitted when the checked state transitions.
    /// </summary>
    [Signal]
    public delegate void CheckedChangedEventHandler(bool isChecked);

    /// <summary>
    /// Gets or sets whether the toggle switch is checked.
    /// </summary>
    [Export]
    public bool Checked
    {
        get => _checked;
        set
        {
            if (_checked != value)
            {
                _checked = value;
                AnimateState();
                EmitSignal(SignalName.CheckedChanged, _checked);
            }
        }
    }

    /// <summary>
    /// Internal property driven by tweens to update position.
    /// Calls QueueRedraw to implement Property Redraw Pattern.
    /// </summary>
    private float ThumbPosition
    {
        get => _thumbPosition;
        set
        {
            _thumbPosition = value;
            QueueRedraw();
        }
    }

    /// <summary>
    /// Internal property driven by tweens to update thumb size scaling.
    /// Calls QueueRedraw to implement Property Redraw Pattern.
    /// </summary>
    private float ThumbScale
    {
        get => _thumbScale;
        set
        {
            _thumbScale = value;
            QueueRedraw();
        }
    }

    public override void _Ready()
    {
        // Enforce fixed dimensions for the M3 Switch (52dp x 32dp)
        CustomMinimumSize = new Vector2(52, 32) * ScaleFactor;
        
        base._Ready();

        _thumbPosition = _checked ? 1.0f : 0.0f;
        _thumbScale = _checked ? 1.0f : 0.66f; // Unchecked is smaller (16dp vs 24dp)
    }

    public override void _GuiInput(InputEvent @event)
    {
        base._GuiInput(@event);

        if (@event is InputEventMouseButton mouseEvent && mouseEvent.ButtonIndex == MouseButton.Left)
        {
            if (!mouseEvent.Pressed && IsHoveredState())
            {
                Checked = !Checked;
            }
        }
    }

    /// <summary>
    /// Smoothly tweens track and thumb values upon toggle activation.
    /// </summary>
    private void AnimateState()
    {
        float targetPos = _checked ? 1.0f : 0.0f;
        float targetScale = _checked ? 1.0f : 0.66f;

        var tween = CreateTween().SetParallel(true);
        
        // Easing for toggle animation (150ms)
        tween.TweenProperty(this, "ThumbPosition", targetPos, 0.15f)
             .SetTrans(Tween.TransitionType.Quad)
             .SetEase(Tween.EaseType.Out);

        tween.TweenProperty(this, "ThumbScale", targetScale, 0.15f)
             .SetTrans(Tween.TransitionType.Quad)
             .SetEase(Tween.EaseType.Out);
    }

    protected override void ApplyTheme()
    {
        CustomMinimumSize = new Vector2(52, 32) * ScaleFactor;
        if (RippleNode != null && CurrentTheme != null)
        {
            RippleNode.RippleColor = _checked ? CurrentTheme.Primary : CurrentTheme.Outline;
        }
        QueueRedraw();
    }

    public override void _Draw()
    {
        if (CurrentTheme == null) return;

        // --- 1. Draw Track ---
        StyleBoxFlat trackBox = new StyleBoxFlat();
        trackBox.SetCornerRadiusAll((int)(16 * ScaleFactor)); // Full rounded ends scaled

        Color trackBgColor = CurrentTheme.SurfaceVariant;
        float borderWidth = 0.0f;
        Color borderColor = Color.FromHtml("#00000000");

        if (_checked)
        {
            trackBgColor = CurrentTheme.Primary;
        }
        else
        {
            // Unchecked outline variant
            trackBgColor = CurrentTheme.SurfaceContainerLowest;
            borderWidth = 2.0f * ScaleFactor;
            borderColor = CurrentTheme.Outline;
        }

        // Apply interactive hover shifts to track
        if (IsHoveredState())
        {
            Color hoverMask = _checked ? CurrentTheme.OnPrimary : CurrentTheme.OnSurfaceVariant;
            trackBgColor = trackBgColor.Blend(new Color(hoverMask.R, hoverMask.G, hoverMask.B, 0.08f));
        }

        trackBox.BgColor = trackBgColor;
        trackBox.BorderWidthLeft = (int)borderWidth;
        trackBox.BorderWidthTop = (int)borderWidth;
        trackBox.BorderWidthRight = (int)borderWidth;
        trackBox.BorderWidthBottom = (int)borderWidth;
        trackBox.BorderColor = borderColor;

        DrawStyleBox(trackBox, new Rect2(Vector2.Zero, Size));

        // --- 2. Draw Thumb ---
        float baseThumbRadius = 12.0f * ScaleFactor; // Checked radius is 12dp scaled
        float currentRadius = baseThumbRadius * ThumbScale;

        // Calculate horizontal interpolation offset
        float leftLimit = 16.0f * ScaleFactor;
        float rightLimit = Size.X - 16.0f * ScaleFactor;
        float centerX = Mathf.Lerp(leftLimit, rightLimit, ThumbPosition);
        Vector2 thumbCenter = new Vector2(centerX, Size.Y / 2.0f);

        Color thumbColor = _checked ? CurrentTheme.OnPrimary : CurrentTheme.Outline;

        if (IsHoveredState())
        {
            Color hoverMask = _checked ? CurrentTheme.Primary : CurrentTheme.OnSurfaceVariant;
            thumbColor = thumbColor.Blend(new Color(hoverMask.R, hoverMask.G, hoverMask.B, 0.08f));
        }

        DrawCircle(thumbCenter, currentRadius, thumbColor);

        // --- 3. Draw Focus Ring ---
        if (IsFocusedState())
        {
            StyleBoxFlat focusBox = new StyleBoxFlat();
            focusBox.DrawCenter = false;
            focusBox.SetCornerRadiusAll((int)(19 * ScaleFactor));
            focusBox.BorderWidthLeft = (int)(2 * ScaleFactor);
            focusBox.BorderWidthTop = (int)(2 * ScaleFactor);
            focusBox.BorderWidthRight = (int)(2 * ScaleFactor);
            focusBox.BorderWidthBottom = (int)(2 * ScaleFactor);
            focusBox.BorderColor = CurrentTheme.Primary;

            DrawStyleBox(focusBox, new Rect2(new Vector2(-3, -3) * ScaleFactor, Size + new Vector2(6, 6) * ScaleFactor));
        }
    }
}
