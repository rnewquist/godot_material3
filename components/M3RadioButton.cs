using Godot;
using System;
using Material3.Core;

namespace Material3.Components;

/// <summary>
/// A native Godot Control representing a Material 3 Radio Button.
/// Draws procedural vector concentric circles representing choices.
/// </summary>
[Tool]
[GlobalClass, Icon("res://icon.svg")]
public partial class M3RadioButton : M3BaseComponent
{
    private bool _selected = false;

    [Signal]
    public delegate void SelectedChangedEventHandler(bool isSelected);

    /// <summary>
    /// Gets or sets whether the radio button is selected.
    /// </summary>
    [Export]
    public bool Selected
    {
        get => _selected;
        set
        {
            if (_selected != value)
            {
                _selected = value;
                EmitSignal(SignalName.SelectedChanged, _selected);
                QueueRedraw();
            }
        }
    }

    public override void _Ready()
    {
        // Standarized touch target size (40dp x 40dp, outer concentric circle is 20dp) scaled
        CustomMinimumSize = new Vector2(40, 40) * ScaleFactor;
        base._Ready();
    }

    public override void _GuiInput(InputEvent @event)
    {
        base._GuiInput(@event);

        if (@event is InputEventMouseButton mouseEvent && mouseEvent.ButtonIndex == MouseButton.Left)
        {
            if (!mouseEvent.Pressed && IsHoveredState())
            {
                Selected = true; // Radio buttons toggle active, but can only be toggled off by external selection structures
            }
        }
    }

    protected override void ApplyTheme()
    {
        CustomMinimumSize = new Vector2(40, 40) * ScaleFactor;
        if (RippleNode != null && CurrentTheme != null)
        {
            RippleNode.RippleColor = _selected ? CurrentTheme.Primary : CurrentTheme.OnSurfaceVariant;
        }
        QueueRedraw();
    }

    public override void _Draw()
    {
        if (CurrentTheme == null) return;

        Vector2 center = Size / 2.0f;
        float outerRadius = 10.0f * ScaleFactor; // 20px diameter scaled
        float innerRadius = 5.0f * ScaleFactor;  // 10px diameter scaled

        // --- 1. Draw Outer Concentric Ring ---
        Color ringColor = _selected ? CurrentTheme.Primary : CurrentTheme.Outline;
        
        // Draw anti-aliased vector circle outline
        DrawArc(center, outerRadius, 0, Mathf.Tau, 64, ringColor, 2.0f * ScaleFactor, true);

        // --- 2. Draw Hover state overlays ---
        if (IsHoveredState())
        {
            Color hoverMask = _selected ? CurrentTheme.Primary : CurrentTheme.OnSurfaceVariant;
            Color overlayColor = new Color(hoverMask.R, hoverMask.G, hoverMask.B, 0.08f);
            DrawCircle(center, outerRadius + 4 * ScaleFactor, overlayColor);
        }

        // --- 3. Draw Inner Circle when selected ---
        if (_selected)
        {
            DrawCircle(center, innerRadius, CurrentTheme.Primary);
        }

        // --- 4. Draw Focus Ring ---
        if (IsFocusedState())
        {
            DrawArc(center, outerRadius + 3 * ScaleFactor, 0, Mathf.Tau, 64, CurrentTheme.Primary, 2.0f * ScaleFactor, true);
        }
    }
}
