using Godot;
using System;
using Material3.Core;

namespace Material3.Components;

/// <summary>
/// A native Godot Control representing a Material 3 Slider.
/// Supports horizontal dragging, continuous/discrete steps, and custom vector tracks.
/// </summary>
[Tool]
[GlobalClass, Icon("res://icon.svg")]
public partial class M3Slider : M3BaseComponent
{
    private float _value = 0.0f;
    private float _minValue = 0.0f;
    private float _maxValue = 100.0f;
    private float _step = 1.0f;
    private bool _dragging = false;

    [Signal]
    public delegate void ValueChangedEventHandler(float newValue);

    /// <summary>
    /// The current slider value.
    /// </summary>
    [Export]
    public float Value
    {
        get => _value;
        set
        {
            float clamped = Math.Clamp(value, _minValue, _maxValue);
            if (_step > 0.0f)
            {
                clamped = MathF.Round(clamped / _step) * _step;
            }
            if (_value != clamped)
            {
                _value = clamped;
                EmitSignal(SignalName.ValueChanged, _value);
                QueueRedraw();
            }
        }
    }

    [Export]
    public float MinValue
    {
        get => _minValue;
        set { _minValue = value; Value = _value; QueueRedraw(); }
    }

    [Export]
    public float MaxValue
    {
        get => _maxValue;
        set { _maxValue = value; Value = _value; QueueRedraw(); }
    }

    [Export]
    public float Step
    {
        get => _step;
        set { _step = value; Value = _value; QueueRedraw(); }
    }

    public override void _Ready()
    {
        // Standard slider dimensions (height 44px touch target) scaled
        CustomMinimumSize = new Vector2(150, 44) * ScaleFactor;
        base._Ready();
    }

    public override void _GuiInput(InputEvent @event)
    {
        base._GuiInput(@event);

        if (@event is InputEventMouseButton mouseEvent && mouseEvent.ButtonIndex == MouseButton.Left)
        {
            if (mouseEvent.Pressed)
            {
                _dragging = true;
                UpdateValueFromMouse(mouseEvent.Position.X);
            }
            else
            {
                _dragging = false;
            }
        }
        else if (@event is InputEventMouseMotion motionEvent && _dragging)
        {
            UpdateValueFromMouse(motionEvent.Position.X);
        }
    }

    private void UpdateValueFromMouse(float mouseX)
    {
        float padding = 10.0f * ScaleFactor; // Thumb radius padding offset scaled
        float trackWidth = Size.X - (padding * 2.0f);
        float relativeX = mouseX - padding;
        float percent = Math.Clamp(relativeX / trackWidth, 0.0f, 1.0f);
        Value = _minValue + (percent * (_maxValue - _minValue));
    }

    protected override void ApplyTheme()
    {
        CustomMinimumSize = new Vector2(150, 44) * ScaleFactor;
        if (RippleNode != null && CurrentTheme != null)
        {
            RippleNode.RippleColor = CurrentTheme.Primary;
        }
        QueueRedraw();
    }

    public override void _Draw()
    {
        if (CurrentTheme == null) return;

        float padding = 10.0f * ScaleFactor; // Thumb radius scaled
        float centerY = Size.Y / 2.0f;
        float trackWidth = Size.X - (padding * 2.0f);
        
        // Calculate thumb center X position
        float percent = (_value - _minValue) / (_maxValue - _minValue);
        if (float.IsNaN(percent) || float.IsInfinity(percent)) percent = 0.0f;
        float thumbX = padding + (percent * trackWidth);
        Vector2 thumbCenter = new Vector2(thumbX, centerY);

        // --- 1. Draw Inactive Track (Right of Thumb) ---
        Vector2 inactiveStart = new Vector2(thumbX, centerY);
        Vector2 inactiveEnd = new Vector2(Size.X - padding, centerY);
        if (inactiveStart.X < inactiveEnd.X)
        {
            DrawLine(inactiveStart, inactiveEnd, CurrentTheme.SurfaceVariant, 4.0f * ScaleFactor, true);
        }

        // --- 2. Draw Active Track (Left of Thumb) ---
        Vector2 activeStart = new Vector2(padding, centerY);
        Vector2 activeEnd = new Vector2(thumbX, centerY);
        if (activeStart.X < activeEnd.X)
        {
            DrawLine(activeStart, activeEnd, CurrentTheme.Primary, 6.0f * ScaleFactor, true);
        }

        // --- 3. Draw State/Hover Overlays on Thumb ---
        if (IsHoveredState() || _dragging)
        {
            Color overlayColor = new Color(CurrentTheme.Primary.R, CurrentTheme.Primary.G, CurrentTheme.Primary.B, 0.08f);
            DrawCircle(thumbCenter, padding + 6 * ScaleFactor, overlayColor);
        }

        // --- 4. Draw Thumb Circle ---
        DrawCircle(thumbCenter, padding, CurrentTheme.Primary);

        // --- 5. Draw Focus Ring Outline ---
        if (IsFocusedState())
        {
            DrawArc(thumbCenter, padding + 3 * ScaleFactor, 0, Mathf.Tau, 64, CurrentTheme.Primary, 2.0f * ScaleFactor, true);
        }
    }
}
