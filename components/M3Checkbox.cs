using Godot;
using System;
using Material3.Core;

namespace Material3.Components;

/// <summary>
/// A native Godot Control representing a Material 3 Checkbox.
/// Draws procedural vector checkmarks and backgrounds.
/// </summary>
[Tool]
[GlobalClass]
public partial class M3Checkbox : M3BaseComponent
{
    private bool _checked = false;

    [Signal]
    public delegate void CheckedChangedEventHandler(bool isChecked);

    /// <summary>
    /// Gets or sets whether the checkbox is checked.
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
                EmitSignal(SignalName.CheckedChanged, _checked);
                QueueRedraw();
            }
        }
    }

    public override void _Ready()
    {
        // Standarized M3 checkbox dimensions (18dp x 18dp frame inside 40dp interactive target) scaled
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
                Checked = !Checked;
            }
        }
    }

    protected override void ApplyTheme()
    {
        CustomMinimumSize = new Vector2(40, 40) * ScaleFactor;
        if (RippleNode != null && CurrentTheme != null)
        {
            RippleNode.RippleColor = _checked ? CurrentTheme.Primary : CurrentTheme.OnSurfaceVariant;
        }
        QueueRedraw();
    }

    public override void _Draw()
    {
        if (CurrentTheme == null) return;

        // Position checkbox container in the center of the 40x40 touch target
        Vector2 innerBoxSize = new Vector2(18, 18) * ScaleFactor;
        Vector2 offset = (Size - innerBoxSize) / 2.0f;
        Rect2 boxRect = new Rect2(offset, innerBoxSize);

        StyleBoxFlat styleBox = new StyleBoxFlat();
        styleBox.SetCornerRadiusAll((int)(2 * ScaleFactor)); // Small rounded corners scaled

        Color borderCol = _checked ? CurrentTheme.Primary : CurrentTheme.Outline;
        Color bgCol = _checked ? CurrentTheme.Primary : Color.FromHtml("#00000000");

        if (IsHoveredState())
        {
            Color hoverMask = _checked ? CurrentTheme.Primary : CurrentTheme.OnSurfaceVariant;
            bgCol = bgCol.Blend(new Color(hoverMask.R, hoverMask.G, hoverMask.B, 0.08f));
        }

        styleBox.BgColor = bgCol;
        styleBox.BorderWidthLeft = (int)(2 * ScaleFactor);
        styleBox.BorderWidthTop = (int)(2 * ScaleFactor);
        styleBox.BorderWidthRight = (int)(2 * ScaleFactor);
        styleBox.BorderWidthBottom = (int)(2 * ScaleFactor);
        styleBox.BorderColor = borderCol;

        DrawStyleBox(styleBox, boxRect);

        // Draw dynamic checkmark inside when Checked
        if (_checked)
        {
            Vector2[] checkPoints = new Vector2[]
            {
                offset + new Vector2(4, 9) * ScaleFactor,
                offset + new Vector2(8, 13) * ScaleFactor,
                offset + new Vector2(14, 5) * ScaleFactor
            };
            
            DrawPolyline(checkPoints, CurrentTheme.OnPrimary, 2.0f * ScaleFactor, true);
        }

        // Draw Focus Ring
        if (IsFocusedState())
        {
            StyleBoxFlat focusBox = new StyleBoxFlat();
            focusBox.DrawCenter = false;
            focusBox.SetCornerRadiusAll((int)(6 * ScaleFactor));
            focusBox.BorderWidthLeft = (int)(2 * ScaleFactor);
            focusBox.BorderWidthTop = (int)(2 * ScaleFactor);
            focusBox.BorderWidthRight = (int)(2 * ScaleFactor);
            focusBox.BorderWidthBottom = (int)(2 * ScaleFactor);
            focusBox.BorderColor = CurrentTheme.Primary;

            DrawStyleBox(focusBox, new Rect2(offset - new Vector2(3, 3) * ScaleFactor, innerBoxSize + new Vector2(6, 6) * ScaleFactor));
        }
    }
}
